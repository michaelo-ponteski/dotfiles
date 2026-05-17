#!/usr/bin/env bash

input=$(</dev/stdin)

model=$(echo "$input" | jq -r '.model.display_name // "?"')
ctx=$(echo "$input" | jq -r '(.context_window.used_percentage // 0) | floor')
ctx_left=$((100 - ctx))

s_used=$(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage // 0) | floor')
s_reset=$(echo "$input" | jq -r '(.rate_limits.five_hour.resets_at // 0)')
s_left=$((100 - s_used))

w_used=$(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage // 0) | floor')
w_reset=$(echo "$input" | jq -r '(.rate_limits.seven_day.resets_at // 0)')
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
w_reset_str=$(fmt_reset "$w_reset")

# Compute display widths of left segments so the │ separators align across lines.
# 🤖 takes 2 display cells but wc -m counts it as 1 char → +1 offset.
vis1="🤖 $model"
vis2="5h: ${s_left}% left (reset ${s_reset_str})"
chars1=$(printf '%s' "$vis1" | wc -m | tr -d ' ')
chars2=$(printf '%s' "$vis2" | wc -m | tr -d ' ')
w1=$((chars1 + 1))
w2=$chars2
max_w=$((w1 > w2 ? w1 : w2))
pad1=$((max_w - w1))
pad2=$((max_w - w2))

printf "🤖 %s%*s  │  🧠 %s%s%%%s\n" \
    "$model" "$pad1" "" \
    "$(color $ctx_left)" "$ctx" "$reset_color"

printf "5h: %s%s%%%s left %s(reset %s)%s%*s  │  7d: %s%s%%%s left %s(reset %s)%s" \
    "$(color $s_left)" "$s_left" "$reset_color" "$dim" "$s_reset_str" "$reset_color" \
    "$pad2" "" \
    "$(color $w_left)" "$w_left" "$reset_color" "$dim" "$w_reset_str" "$reset_color"
