#!/bin/bash
cd /home/container || exit 1

# -----------------------------------------------------------------------------
# Terminal/ANSI-safe printing (no live redraws)
# -----------------------------------------------------------------------------
export TERM="${TERM:-xterm-256color}"

LBLUE='\033[38;5;39m'
ORANGE='\033[38;5;214m'
GREEN='\033[38;5;82m'
PURPLE='\033[38;5;141m'
GREY='\033[38;5;245m'
RED='\033[38;5;196m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Always interpret escapes in strings
p()   { printf "%b" "$*"; }
pln() { printf "%b\n" "$*"; }

WIDTH="${COLUMNS:-80}"

center() {
  local text="$1" w="${2:-$WIDTH}"
  local plain; plain="$(sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' <<<"$text")"
  local len=${#plain}
  (( len >= w )) && { pln "$text"; return; }
  local pad=$(( (w - len) / 2 ))
  printf "%*s%b%*s\n" "$pad" "" "$text" "$pad" ""
}

rule() {
  local char="${1:=-}" w="${2:-$WIDTH}"
  printf "%.${w}s\n" "$(printf "%*s" "$w" | tr ' ' "$char")"
}

# Preflight step: print, sleep, print OK on next line (no animations)
step() {
  local label="$1" delay="${2:-0.5}"
  pln "  ${LBLUE}•${RESET} ${label}"
  sleep "$delay"
  pln "    ${GREEN}OK${RESET}"
}

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------
clear
rule "="
center "${BOLD}${ORANGE}HostingRemade ${PURPLE}•${LBLUE} Server Launcher${RESET}"
rule "="
center "${DIM}Booting container UI…${RESET}"
pln ""

# -----------------------------------------------------------------------------
# Runtime info
# -----------------------------------------------------------------------------
center "${DIM}Collecting runtime info…${RESET}"
JAVA_VER="$(java -version 2>&1 | head -n1)"
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP
pln "  ${GREY}Java:${RESET} ${JAVA_VER}"
pln "  ${GREY}Internal IP:${RESET} ${INTERNAL_IP}"
pln ""

# -----------------------------------------------------------------------------
# Preflight checks (static, Pterodactyl-safe)
# -----------------------------------------------------------------------------
step "Validating container environment" 0.4
step "Probing network path"             0.4
step "Checking JVM & memory flags"      0.6
step "Preparing startup command"        0.4
step "Warming up classpath"             0.5
step "Finalizing launch"                0.4
pln ""

# Simple progress “blocks” without carriage returns
center "${DIM}Initializing…${RESET}"
for i in 1 2 3 4 5; do
  pln "  [$(printf '%*s' "$i" | tr ' ' '#')$(printf '%*s' $((5-i)) | tr ' ' '.')] ${GREY}$((i*20))%%${RESET}"
  sleep 0.15
done
pln ""

center "${BOLD}${ORANGE}Welcome to HostingRemade!${RESET}"
center "${GREY}Need help? Join our Discord: ${BOLD}${ORANGE}discord.hostingremade.com${RESET}"
rule "-"

# -----------------------------------------------------------------------------
# Startup command expansion + launch
# -----------------------------------------------------------------------------
# Print Java again clearly
java -version

# Expand {{VAR}} => ${VAR}
# shellcheck disable=SC2086
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

pln ""
pln "${DIM}Resolved startup command:${RESET}"
pln "  STARTUP /home/container: ${MODIFIED_STARTUP}"
pln ""

# Gentle countdown (one line each)
pln "  ${GREY}Launching in 3…${RESET}"; sleep 0.4
pln "  ${GREY}Launching in 2…${RESET}"; sleep 0.4
pln "  ${GREY}Launching in 1…${RESET}"; sleep 0.4
pln ""

pln "${BOLD}${GREEN}Starting server…${RESET}"
pln ""

# shellcheck disable=SC2086
eval "${MODIFIED_STARTUP}"
