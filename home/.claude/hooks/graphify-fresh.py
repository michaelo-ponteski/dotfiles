#!/usr/bin/env python3
"""PreToolUse(Bash): before a graphify read (query/path/explain/affected/god-nodes),
rebuild graphify-out/graph.json if any git-visible file changed since the last build.

Exit 0 = graph fresh (or not applicable). Exit 2 = refresh failed; stderr goes to Claude,
the stale query is blocked, Claude falls back to grep/LSP.
"""
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time

READ_CMD = re.compile(r"(?:^|[\s;&|(])graphify\s+(?:query|path|explain|affected|god-nodes)\b")
# Session cwd is often ~, so graphify runs as `cd <repo> && graphify ...`; `cd` is zoxide, hence builtin/command.
CD_PREFIX = re.compile(r"""^\s*(?:builtin\s+|command\s+)?cd\s+("[^"]+"|'[^']+'|[^\s;&|]+)\s*&&""")


def scan(root: str) -> tuple[str, float]:
    """Hash of (path, mtime, size) for every tracked + untracked-not-ignored file, and the newest mtime."""
    names = subprocess.run(
        ["git", "-C", root, "ls-files", "-co", "--exclude-standard", "-z"],
        capture_output=True, check=True,
    ).stdout.split(b"\0")
    h, newest = hashlib.sha1(), 0.0
    for name in sorted(n for n in names if n and not n.startswith(b"graphify-out/")):
        try:
            st = os.stat(os.path.join(root, os.fsdecode(name)))
        except FileNotFoundError:
            continue  # deleted but still tracked: dropping it from the hash marks the change
        h.update(name + b"\0%d\0%d\n" % (st.st_mtime_ns, st.st_size))
        newest = max(newest, st.st_mtime)
    return h.hexdigest(), newest


def main() -> int:
    data = json.load(sys.stdin)
    cmd = data.get("tool_input", {}).get("command", "")
    # shortcut: custom --graph paths are not tracked, add if ever used
    if not READ_CMD.search(cmd) or "--graph" in cmd:
        return 0
    root = data.get("cwd") or os.getcwd()
    if m := CD_PREFIX.match(cmd):
        root = os.path.join(root, os.path.expanduser(m.group(1).strip("\"'")))
    out = os.path.join(root, "graphify-out")
    graph = os.path.join(out, "graph.json")
    if not os.path.isfile(graph):
        return 0
    # shortcut: non-git dirs are never refreshed, no cheap change signal there
    if subprocess.run(["git", "-C", root, "rev-parse"], capture_output=True).returncode:
        return 0

    stamp = os.path.join(out, ".claude-fresh")
    with open(os.path.join(out, ".claude-fresh.lock"), "w") as lock:
        # Parallel queries: one rebuilds, the others wait here and then find the stamp current.
        fcntl.flock(lock, fcntl.LOCK_EX)
        fp, newest = scan(root)
        try:
            with open(stamp) as f:
                old = f.read()
        except FileNotFoundError:
            old = None
        if old == fp:
            return 0
        if old is None and newest <= os.stat(graph).st_mtime:
            # First run on a graph built after the last change: just record it.
            with open(stamp, "w") as f:
                f.write(fp)
            return 0

        started = time.monotonic()
        exe = shutil.which("graphify") or os.path.expanduser("~/.local/bin/graphify")
        # Exits 1 on any failure, incl. the "would drop nodes" refusal; exits 0 without
        # rewriting graph.json when the code change does not alter the graph (e.g. comments).
        r = subprocess.run([exe, "update", "."], cwd=root, capture_output=True, text=True)
        if r.returncode:
            tail = (r.stderr.strip() or r.stdout.strip())[-1500:]
            print(
                "graphify-fresh: the graph is stale and `graphify update .` did not rebuild it "
                f"(exit {r.returncode}). Do not trust graphify results for this repo now: use grep/LSP. "
                "If code was deleted on purpose, run `GRAPHIFY_FORCE=1 graphify update .` and retry.\n"
                + tail,
                file=sys.stderr,
            )
            return 2
        # Files edited during the rebuild keep a newer fingerprint, so the next read rebuilds again.
        with open(stamp, "w") as f:
            f.write(fp)
        print(json.dumps({"systemMessage": f"graphify: graph refreshed ({time.monotonic() - started:.0f}s)"}))
        return 0


if __name__ == "__main__":
    sys.exit(main())
