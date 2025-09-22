#!/bin/bash
cd /home/container || exit 1

# -----------------------------------------------------------------------------
# Terminal/ANSI detection + color setup
# -----------------------------------------------------------------------------
export TERM="${TERM:-xterm-256color}"

# Colors (only used if ANSI is supported)
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

# Detect ANSI support (Pterodactyl sometimes strips it)
supports_ansi() {
  # If FORCE_COLOR=1, force-enable
  [[ "${FORCE_COLOR:-0}" == "1" ]] && return 0
  # stdout must be a terminal
  [[ -t 1 ]] || return 1
  # basic TERM check
  case "$TERM" in
    dumb|unknown|"") return 1 ;;
  esac
  return 0
}
ANSI_OK=0
if supports_ansi; then ANSI_OK=1; else
  # Disable colors if ANSI not supported
  LBLUE=""; ORANGE=""; GREEN=""; PURPLE=""; GREY=""; RED=""; BOLD=""; DIM=""; RESET=""; HIDE=""; SHOW="";
fi

# Always print with %b so \033 in variables gets interpreted
p() { printf "%b" "$*"; }
pln() { printf "%b\n" "$*"; }

# -----------------------------------------------------------------------------
# UI helpers (ANSI-safe)
# -----------------------------------------------------------------------------
WIDTH="${COLUMNS:-80}"

center() {
  local text="$1" w="${2:-$WIDTH}"
  # strip escape codes for width calc (rough)
  local plain="$(sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' <<<"$text")"
  local len=${#plain}
  (( len >= w )) && { pln "$text"; return; }
  local pad=$(( (w - len) / 2 ))
  printf "%*s%b%*s\n" "$pad" "" "$text" "$pad" ""
}

rule() {
  local char="${1:--}" w="${2:-$WIDTH}"
  printf "%.${w}s\n" "$(printf "%*s" "$w" | tr ' ' "$char")"
}

typewrite() { # typewrite "text" delaySecs
  local s="$1" d="${2:-0.002}" i ch
  if (( ANSI_OK )); then p "${HIDE}"; fi
  for ((i=0;i<${#s}; i++)); do
    ch="${s:$i:1}"
    p "$ch"
    sleep "$d"
  done
  pln ""
  if (( ANSI_OK )); then p "${SHOW}"; fi
}

spinner_start() {
  (( ! ANSI_OK )) && { SPINNER_PID=""; return; }
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  (
    trap "exit 0" TERM
    i=0
    while :; do
      i=$(( (i+1) % ${#frames} ))
      p "\r${GREY}${frames:i:1}${RESET}"
      sleep 0.08
    done
  ) &
  SPINNER_PID=$!
}

spinner_stop() {
  [[ -n "$SPINNER_PID" ]] || return
  kill -TERM "$SPINNER_PID" >/dev/null 2>&1
  wait "$SPINNER_PID" 2>/dev/null
  SPINNER_PID=""
  p "\r \r"
}

progress_bar() { # progress_bar current total width
  local cur="$1" total="$2" w="${3:-40}"
  (( cur<0 )) && cur=0
  (( cur>total )) && cur=$total
  local filled=$(( cur * w / total ))
  local empty=$(( w - filled ))
  printf "%b" "["
  printf "%${filled}s" | tr ' ' '#'
  printf "%${empty}s" | tr ' ' '.'
  printf "%b" "] "
  printf "%3d%%" $(( cur*100/total ))
}

pulse_banner() {
  local msg="$1"
  center "${BOLD}${ORANGE}${msg}${RESET}"
}

cleanup() { spinner_stop; (( ANSI_OK )) && p "${SHOW}${RESET}"; }
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------
clear
rule "="
center "${BOLD}${LBLUE}Hosting${ORANGE}Remade ${PURPLE}•${LBLUE} Server Launcher${RESET}"
rule "="
typewrite "$(center "${GREY}Booting container UI…${RESET}")" 0.0015

# -----------------------------------------------------------------------------
# Env & Info
# -----------------------------------------------------------------------------
pln ""
center "${DIM}Collecting runtime info…${RESET}"
JAVA_VER="$(java -version 2>&1 | head -n1)"
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP
pln "  ${GREY}Java:${RESET} ${JAVA_VER}"
pln "  ${GREY}Internal IP:${RESET} ${INTERNAL_IP}"
pln ""

# -----------------------------------------------------------------------------
# Cosmetic “health checks”
# -----------------------------------------------------------------------------
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
  p "  ${LBLUE}•${RESET} ${labels[i-1]}  "
  spinner_start
  sleep 0.35
  spinner_stop
  pln "${GREEN}OK${RESET}"
done

# -----------------------------------------------------------------------------
# Progress bar
# -----------------------------------------------------------------------------
pln ""
center "${DIM}Initializing…${RESET}"
total=30
for ((n=0;n<=total;n++)); do
  p "\r  "
  progress_bar "$n" "$total" 46
  sleep 0.02
done
pln "" ; pln ""

pulse_banner "Welcome to HostingRemade!"
center "${GREY}Need help? Join our Discord: ${BOLD}${ORANGE}dsc.gg/hostingremade${RESET}"
pln ""
rule "-"

# -----------------------------------------------------------------------------
# Startup command expansion + launch
# -----------------------------------------------------------------------------
# Print current Java version again clearly
java -version

# Expand {{VAR}} => ${VAR}
# shellcheck disable=SC2086
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

pln ""
pln "${DIM}Resolved startup command:${RESET}"
pln "  STARTUP /home/container: ${MODIFIED_STARTUP}"
pln ""

for s in 3 2 1; do
  p "${GREY}Launching in ${BOLD}${s}${RESET}\r"
  sleep 0.6
done
p "                               \r"

pln "${BOLD}${GREEN}Starting server…${RESET}"
pln ""

# shellcheck disable=SC2086
eval "${MODIFIED_STARTUP}"
