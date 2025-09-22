#!/bin/bash
cd /home/container || exit 1

# =========================
# Colors & Styling
# =========================
LBLUE='\033[38;5;39m'
ORANGE='\033[38;5;214m'
GREEN='\033[38;5;82m'
PURPLE='\033[38;5;141m'
GREY='\033[38;5;245m'
RED='\033[38;5;196m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
HIDE='\033[?25l'
SHOW='\033[?25h'

# Width fallback (Ptero console usually gives COLUMNS)
WIDTH="${COLUMNS:-80}"

# =========================
# Tiny UI Helpers
# =========================
center() {
  local text="$1" pad left
  local w="${2:-$WIDTH}"
  local len=${#text}
  (( len >= w )) && { echo "$text"; return; }
  pad=$(( (w - len) / 2 ))
  printf "%*s%s%*s\n" "$pad" "" "$text" "$pad" ""
}

rule() {
  local char="${1:--}" w="${2:-$WIDTH}"
  printf "%s\n" "$(printf "%${w}s" | tr ' ' "$char")"
}

typewrite() { # typewrite "text" delaySecs
  local s="$1" d="${2:-0.002}"
  local i ch
  for ((i=0; i<${#s}; i++)); do
    ch="${s:$i:1}"
    printf "%s" "$ch"
    sleep "$d"
  done
  printf "\n"
}

spinner_start() { # sets SPINNER_PID
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  (
    trap "exit 0" TERM
    while :; do
      i=$(( (i+1) % ${#frames} ))
      printf "\r%s" "${GREY}${frames:i:1}${RESET}"
      sleep 0.08
    done
  ) &
  SPINNER_PID=$!
}

spinner_stop() {
  if [[ -n "$SPINNER_PID" ]]; then
    kill -TERM "$SPINNER_PID" >/dev/null 2>&1
    wait "$SPINNER_PID" 2>/dev/null
    unset SPINNER_PID
    printf "\r \r"
  fi
}

progress_bar() { # progress_bar current total width
  local cur="$1" total="$2" w="${3:-40}"
  (( cur<0 )) && cur=0
  (( cur>total )) && cur=$total
  local filled=$(( cur * w / total ))
  local empty=$(( w - filled ))
  printf "[%s%s] %3d%%" \
    "$(printf "%${filled}s" | tr ' ' '#')" \
    "$(printf "%${empty}s" | tr ' ' '.')" \
    $(( cur*100/total ))
}

pulse_banner() { # subtle color pulse once
  local msg="$1"
  local cycles=1 i
  for ((i=0;i<cycles;i++)); do
    center "${BOLD}${ORANGE}${msg}${RESET}"
    sleep 0.08
  done
}

# Clean up cursor on exit
cleanup() { spinner_stop; printf "${SHOW}${RESET}"; }
trap cleanup EXIT

printf "${HIDE}"

# =========================
# Header Animation
# =========================
clear
rule "="
center "${BOLD}${LBLUE}Hosting${ORANGE}Remade ${PURPLE}•${LBLUE} Server Launcher${RESET}"
rule "="
typewrite "$(center "${GREY}Booting container UI…${RESET}")" 0.0015

# =========================
# Environment & Info
# =========================
printf "\n"
center "${DIM}Collecting runtime info…${RESET}"
JAVA_VER="$(java -version 2>&1 | head -n1 | sed 's/^/  /')"
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP
printf "  ${GREY}Java:${RESET} %s\n" "${JAVA_VER#  }"
printf "  ${GREY}Internal IP:${RESET} %s\n" "${INTERNAL_IP}"
printf "\n"

# =========================
# Fun Health Checks (cosmetic)
# =========================
steps=6
labels=(
  "Validating container environment"
  "Probing network path"
  "Checking JVM & memory flags"
  "Preparing startup command"
  "Warming up classpath"
  "Finalizing launch"
)

for ((i=1;i<=steps;i++)); do
  printf "  ${LBLUE}•${RESET} %s  " "${labels[i-1]}"
  spinner_start
  # tiny fake work
  sleep 0.35
  spinner_stop
  printf "${GREEN}OK${RESET}\n"
done

# =========================
# Pretty Progress Bar
# =========================
printf "\n"
center "${DIM}Initializing…${RESET}"
total=30
for ((n=0;n<=total;n++)); do
  printf "\r  "
  progress_bar "$n" "$total" 46
  sleep 0.02
done
printf "\n\n"

pulse_banner "Welcome to HostingRemade!"
center "${GREY}Need help? Join our Discord: ${BOLD}${ORANGE}dsc.gg/hostingremade${RESET}"
printf "\n"
rule "-"

# =========================
# Startup Variable Expansion
# =========================
# Print Current Java Version (explicit echo below for clarity)
java -version

# Replace Startup Variables
# shellcheck disable=SC2086
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

printf "\n${DIM}Resolved startup command:${RESET}\n"
printf "  %s\n\n" "STARTUP /home/container: ${MODIFIED_STARTUP}"

# Friendly countdown
for s in 3 2 1; do
  printf "${GREY}Launching in ${BOLD}%s${RESET}\r" "$s"
  sleep 0.6
done
printf "                               \r"

# =========================
# Launch
# =========================
printf "${BOLD}${GREEN}Starting server…${RESET}\n\n"

# Remove old ASCII; clean, readable output instead.
# shellcheck disable=SC2086
eval "${MODIFIED_STARTUP}"
