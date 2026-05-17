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
[ -n "$ctx_size_label" ] && \
    model_segment="${model_segment} ${model_annot_color}${ctx_size_label}${reset_color}"

# Compute display widths of left segments so the │ separators align across lines.
# 🤖 takes 2 display cells but wc -m counts it as 1 char → +1 offset.
vis1="🤖 $model"
[ -n "$ctx_size_label" ] && vis1="$vis1 $ctx_size_label"
vis2="5h: ${s_left}% left (reset ${s_reset_str})"
chars1=$(printf '%s' "$vis1" | wc -m | tr -d ' ')
chars2=$(printf '%s' "$vis2" | wc -m | tr -d ' ')
w1=$((chars1 + 1))
w2=$chars2
max_w=$((w1 > w2 ? w1 : w2))
pad1=$((max_w - w1))
pad2=$((max_w - w2))

printf "🤖 %s%*s  │  🧠 %s%s%%%s\n" \
    "$model_segment" "$pad1" "" \
    "$(color $ctx_left)" "$ctx" "$reset_color"

printf "5h: %s%s%%%s left %s(reset %s)%s%*s  │  7d: %s%s%%%s left" \
    "$(color $s_left)" "$s_left" "$reset_color" "$dim" "$s_reset_str" "$reset_color" \
    "$pad2" "" \
    "$(color $w_left)" "$w_left" "$reset_color"
