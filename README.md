# dotfiles

Personal config for macOS / zsh setup. Targets a fresh laptop bootstrap.

## What's here

```
home/
├── .zshrc                  shell config, aliases, plugin sourcing
├── .tmux.conf              tmux core
├── .wezterm.lua            terminal
├── .gitconfig              personal git identity
├── .gitconfig-work         work git identity (loaded by includeIf for ~/Personal/Inigra/*)
├── .condarc                conda channels
├── .claude/                Claude Code config (curated — see below)
│   ├── CLAUDE.md           global instructions
│   ├── settings.json       hooks, plugins, statusline, skill overrides
│   ├── settings.local.json local UI prefs
│   ├── statusline.sh       custom 2-line statusline (model, ctx %, rate limits)
│   ├── agents/             custom subagents
│   └── hooks/              SessionStart skill pruner, PreToolUse remote-safety gate
└── .config/
    ├── starship.toml       prompt
    ├── git.plugin.zsh      custom zsh git plugin
    ├── nvim/               LazyVim config
    ├── tmux/               tmux plugins, themes
    ├── bat/themes/         Catppuccin themes
    ├── micro/              micro editor (settings, keybinds)
    ├── htop/htoprc
    └── lazygit/config.yml
```

## Install on a new machine

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # preview
./install.sh             # symlink everything into $HOME
```

The installer:
- creates symlinks from `$HOME/.foo` to `~/dotfiles/home/.foo`
- backs up any pre-existing files to `<path>.bak`
- skips files that are already correctly linked (safe to re-run)

## Dependencies (install separately)

These are referenced in configs but not tracked here (install via Homebrew or similar):

| Tool | Reason |
|---|---|
| `zsh-autosuggestions` `zsh-syntax-highlighting` `zsh-completions` `zsh-you-should-use` | sourced from `.zshrc` |
| `fzf` `fzf-tab` `fd` | shell completion + file finding |
| `starship` | prompt (configured by `~/.config/starship.toml`) |
| `eza` `bat` `zoxide` `lazygit` `micro` `neovim` `tmux` `wezterm` `htop` | aliased / sourced commands |
| `miniforge3` (mamba/conda) | `.zshrc` references it; `mamba shell init` regenerates the init block |
| `gh` `gh-copilot` | GitHub CLI + Copilot CLI |
| `claude` (Claude Code) | `.claude/` is its config; install separately, then `claude plugin marketplace add` + `claude plugin install` for each entry in `settings.json` → `extraKnownMarketplaces` / `enabledPlugins` |

Suggested one-liner for Homebrew:

```bash
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  fzf fd starship eza bat zoxide lazygit micro neovim tmux wezterm htop \
  gh gh-copilot miniforge
```

## What's NOT included (and why)

- `~/.claude.json`, `~/.claude/sessions/`, `~/.claude/projects/`, `~/.claude/history.jsonl` — local state, auth tokens, conversation logs
- `~/.claude/plugins/cache/` and `marketplaces/` — re-downloaded by `claude plugin install`
- `~/.claude/plugins/installed_plugins.json`, `known_marketplaces.json` — Claude Code rewrites them as regular files (breaking the symlink), so a tracked copy goes stale and `install.sh` would overwrite the live registry with it
- `autoMode` in `settings.json` — machine-local (client hosts, prod paths); stripped from commits by the `strip-private` git filter (`.gitattributes`, configured by `install.sh`)
- `~/.config/gh/`, `~/.config/github-copilot/`, `~/.config/gh-copilot/` — auth tokens
- `~/.config/miniforge3/`, `~/.config/fzf-tab/`, `~/.config/zsh-*/` — installed via Homebrew; would bloat the repo
- `~/.ssh/`, `~/.gnupg/` — secrets
- Per-tool runtime data (yarn cache, npm cache, vscode workspace state, etc.)

## Update flow

When you change a config file in `$HOME`, the symlink writes back through to `~/dotfiles/home/...` — just commit from inside `~/dotfiles/`.

```bash
cd ~/dotfiles
git status
git add -p        # review hunks: this repo is public
git commit -m "..."
```

## Two GitHub accounts

This repo doesn't pin which account to push to. Decide before adding a remote:
- `github-private` SSH alias for personal
- `github-work` SSH alias for work

Personal dotfiles → `github-private`:

```bash
git remote add origin git@github-private:<user>/dotfiles.git
git push -u origin main
```
