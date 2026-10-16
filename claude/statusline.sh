#!/bin/bash
# Claude Code status line. Reads the session JSON on stdin, prints one line.
# Colours are ANSI slots so the bar follows the terminal's mate dark/light theme.
set -u

input=$(cat)

IFS=$'\x1f' read -r model dir cost duration added removed five week < <(
  jq -r '[
    .model.display_name // "",
    .workspace.current_dir // .cwd // "",
    .cost.total_cost_usd // "",
    .cost.total_duration_ms // "",
    .cost.total_lines_added // "",
    .cost.total_lines_removed // "",
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.seven_day.used_percentage // ""
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

bold=$'\033[1m'
reset=$'\033[0m'
dim=$'\033[38;5;248m'
white=$'\033[97m'
green=$'\033[32m'
yellow=$'\033[33m'
red=$'\033[31m'
bright_red=$'\033[91m'
purple=$'\033[38;5;139m'

segments=()

[ -n "$model" ] && segments+=("${bold}${red}${model}${reset}")

if [ -n "$dir" ]; then
  tilde="~"
  short="${dir/#$HOME/$tilde}"
  IFS='/' read -ra comps <<<"${short#/}"
  n=${#comps[@]}
  if [ "$n" -gt 2 ]; then
    short="${comps[n - 2]}/${comps[n - 1]}"
  fi
  seg="${white}${short}${reset}"
  if branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null) \
    || branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
    seg="$seg ${green}${branch}${reset}"
    if [ -n "$(git -C "$dir" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
      seg="$seg${yellow}*${reset}"
    fi
  fi
  segments+=("$seg")
fi

if [ -n "$cost" ]; then
  seg="${yellow}$(printf '$%.2f' "$cost")${reset}"
  if [ -n "$duration" ]; then
    mins=$(( ${duration%.*} / 60000 ))
    if [ "$mins" -ge 60 ]; then
      time="$((mins / 60))h $(printf '%02d' $((mins % 60)))m"
    else
      time="${mins}m"
    fi
    seg="$seg ${dim}·${reset} ${purple}${time}${reset}"
  fi
  segments+=("$seg")
fi

if [ -n "$added" ] || [ -n "$removed" ]; then
  segments+=("${green}+${added:-0}${reset} ${bright_red}-${removed:-0}${reset}")
fi

limits=()
for entry in "5h:$five" "7d:$week"; do
  label=${entry%%:*}
  value=${entry#*:}
  [ -z "$value" ] && continue
  pct=$(printf '%.0f' "$value")
  if [ "$pct" -ge 80 ]; then
    color="${bold}${bright_red}"
  elif [ "$pct" -ge 50 ]; then
    color="$yellow"
  else
    color="$purple"
  fi
  limits+=("${label} ${color}${pct}%${reset}")
done
if [ ${#limits[@]} -gt 0 ]; then
  seg="${limits[0]}"
  [ ${#limits[@]} -gt 1 ] && seg="$seg ${dim}·${reset} ${limits[1]}"
  segments+=("$seg")
fi

sep=" ${dim}│${reset} "
line=""
for seg in "${segments[@]}"; do
  line="${line:+$line$sep}$seg"
done
printf ' %s\n' "$line"
exit 0
