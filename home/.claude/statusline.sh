#!/usr/bin/env bash

input=$(</dev/stdin)

model_raw=$(echo "$input" | jq -r '.model.display_name // "?"')

# Claude Code may embed the context-size annotation inside display_name
# (e.g. "Opus 4.7 (1M context)"). Strip it so we control its styling, and
# capture it as ctx_size_label_from_name to use as the annotation.
ctx_size_label_from_name=""
model="$model_raw"
if [[ "$model_raw" =~ [[:space:]]\(([^\)]*context)\)$ ]]; then
    ctx_size_label_from_name="(${BASH_REMATCH[1]})"
    model="${model_raw% (*}"
fi
ctx=$(echo "$input" | jq -r '(.context_window.used_percentage // 0) | floor')
ctx_left=$((100 - ctx))

s_used=$(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage // 0) | floor')
s_reset=$(echo "$input" | jq -r '(.rate_limits.five_hour.resets_at // 0)')
s_left=$((100 - s_used))

w_used=$(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage // 0) | floor')
w_left=$((100 - w_used))

# Working directory + git (branch / dirty / ahead-behind vs upstream).
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
folder=""
[ -n "$cwd" ] && folder=$(basename "$cwd")
branch="" git_dirty="" git_ab=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) # detached HEAD
    [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] && git_dirty="●"
    ab=$(git -C "$cwd" rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)
    if [ -n "$ab" ]; then
        behind=$(echo "$ab" | awk '{print $1}')
        ahead=$(echo "$ab" | awk '{print $2}')
        { [ "${ahead:-0}" -gt 0 ]; } 2>/dev/null && git_ab="$git_ab ↑$ahead"
        { [ "${behind:-0}" -gt 0 ]; } 2>/dev/null && git_ab="$git_ab ↓$behind"
    fi
fi

color() {
    local left=$1
    if [ "$left" -gt 50 ]; then
        printf '\033[32m' # green
    elif [ "$left" -gt 20 ]; then
        printf '\033[33m' # yellow
    else
        printf '\033[31m' # red
    fi
}
reset_color=$'\033[0m'
dim=$'\033[2m'
model_color=$'\033[1;38;5;117m'       # bold sky blue (256-color)
model_annot_color=$'\033[2;38;5;117m' # dim sky blue — context-size annotation
folder_color=$'\033[38;5;180m'        # tan — current folder
branch_color=$'\033[1;38;5;176m'      # purple — git branch
dirty_color=$'\033[33m'               # yellow — uncommitted changes
branch_icon_color=$'\033[32m'         # green — git branch icon

fmt_reset() {
    local epoch=$1
    [ "$epoch" -eq 0 ] && {
        echo "?"
        return
    }
    local now diff d h m
    now=$(date +%s)
    diff=$((epoch - now))
    [ "$diff" -lt 0 ] && {
        echo "now"
        return
    }
    d=$((diff / 86400))
    h=$(((diff % 86400) / 3600))
    m=$(((diff % 3600) / 60))
    if [ "$d" -gt 0 ]; then
        printf "%dd%dh" "$d" "$h"
    elif [ "$h" -gt 0 ]; then
        printf "%dh%dm" "$h" "$m"
    else
        printf "%dm" "$m"
    fi
}

s_reset_str=$(fmt_reset "$s_reset")

# Detect model context-window size for the dimmed annotation next to the name.
# Prefer the label already in display_name (if any); else try other JSON paths.
if [ -n "$ctx_size_label_from_name" ]; then
    ctx_size_label="$ctx_size_label_from_name"
else
    ctx_size_label=$(echo "$input" | jq -r '
      if (.context_window.size // 0) >= 1000000 then "(\((.context_window.size / 1000000 | floor))M context)"
      elif (.context_window.size // 0) >= 1000 then "(\((.context_window.size / 1000 | floor))K context)"
      elif (.model.context_window // 0) >= 1000000 then "(\((.model.context_window / 1000000 | floor))M context)"
      elif (.model.context_window // 0) >= 1000 then "(\((.model.context_window / 1000 | floor))K context)"
      elif ((.model.id // "") | test("\\[1m\\]"; "i")) then "(1M context)"
      elif ((.model.id // "") | test("\\[200k\\]"; "i")) then "(200K context)"
      else "" end
    ')
fi

# Build the model display segment with optional dimmed context-size annotation.
model_segment="${model_color}${model}${reset_color}"
[ -n "$ctx_size_label" ] &&
    model_segment="${model_segment} ${model_annot_color}${ctx_size_label}${reset_color}"

# ── Render: 2 lines × up to 3 columns; │ separators aligned top↔bottom ──
# display width = chars (wc -m) + 1 per wide emoji (🤖 🧠 📁 render as 2 cells).
dwidth() {
    local s=$1 chars extra=0 e c
    chars=$(printf '%s' "$s" | wc -m | tr -d ' ')
    for e in "🤖" "🧠" "📁"; do
        c=$(printf '%s' "$s" | grep -oF "$e" 2>/dev/null | wc -l | tr -d ' ')
        extra=$((extra + c))
    done
    echo $((chars + extra))
}
pad() {
    local w
    w=$(dwidth "$1")
    printf '%*s' "$(($2 - w > 0 ? $2 - w : 0))" ''
}

# plain column text (for width calc); colored versions printed below
a1p="🤖 $model"
[ -n "$ctx_size_label" ] && a1p="$a1p $ctx_size_label"
a2p="5h: ${s_left}% left (reset ${s_reset_str})"
b1p="🧠 ${ctx}%"
b2p="7d: ${w_left}% left"
wa=$(dwidth "$a1p")
t=$(dwidth "$a2p")
[ "$t" -gt "$wa" ] && wa=$t
wb=$(dwidth "$b1p")
t=$(dwidth "$b2p")
[ "$t" -gt "$wb" ] && wb=$t

# right column: 📁 folder (line 1) / ⎇ branch (line 2). Present only inside a dir.
c1="" c2=""
if [ -n "$folder" ]; then
    c1="  │  📁 ${folder_color}${folder}${reset_color}"
    if [ -n "$branch" ]; then
        c2="  │  ${branch_icon_color}${reset_color}  ${branch_color}${branch}${reset_color}"
        [ -n "$git_dirty" ] && c2="${c2} ${dirty_color}${git_dirty}${reset_color}"
        [ -n "$git_ab" ] && c2="${c2}${dim}${git_ab}${reset_color}"
    else
        c2="  │"
    fi
fi

# Line 1: 🤖 model  │  🧠 context  │  📁 folder
printf "🤖 %s%s  │  🧠 %s%s%%%s%s%s\n" \
    "$model_segment" "$(pad "$a1p" "$wa")" \
    "$(color $ctx_left)" "$ctx" "$reset_color" \
    "$(pad "$b1p" "$wb")" "$c1"

# Line 2: 5h  │  7d  │  ⎇ branch
printf "5h: %s%s%%%s left %s(reset %s)%s%s  │  7d: %s%s%%%s left%s%s\n" \
    "$(color $s_left)" "$s_left" "$reset_color" "$dim" "$s_reset_str" "$reset_color" \
    "$(pad "$a2p" "$wa")" \
    "$(color $w_left)" "$w_left" "$reset_color" \
    "$(pad "$b2p" "$wb")" "$c2"
