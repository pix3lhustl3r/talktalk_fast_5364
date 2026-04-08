#!/bin/zsh

setopt NO_BEEP
autoload -Uz colors && colors

REPO_EXPECTED="talktalk_fast_5364"
WORK_FW_OLD="firmware/working/fw-2600t.img.gsdf"
WORK_FW_NEW="firmware/working/fw-2816t.img.gsdf"
NOTES_DIR="notes"
PLAN_FILE="${NOTES_DIR}/plan.txt"
CHECKSUM_FILE="${NOTES_DIR}/firmware-sha256.txt"

C_RESET="%f%k%b"
C_RED="%F{196}"
C_GREEN="%F{46}"
C_YELLOW="%F{220}"
C_BLUE="%F{39}"
C_MAG="%F{135}"
C_CYAN="%F{51}"
C_WHITE="%F{15}"
C_GREY="%F{244}"

banner() {
  clear
  print -P "${C_CYAN}"
  print "╔══════════════════════════════════════════════════════════════════════╗"
  print "║                ⚡ FAST 5364 LAB / SSH CONTROL PANEL ⚡              ║"
  print "║                  Sagemcom F@ST 5364-3.T8 helper                    ║"
  print "║----------------------------------------------------------------------║"
  print "║  1. Repo / firmware status      7. Double-NAT quick guide          ║"
  print "║  2. Show local network info      8. Browser + JS SSH reminder       ║"
  print "║  3. Find default gateway         9. SSH / root / TR-069 commands    ║"
  print "║  4. Guess main-router subnet     10. Create notes / checklist       ║"
  print "║  5. Double-NAT IP planner        11. Safety reminders               ║"
  print "║  6. Show firmware evidence       0. Exit                            ║"
  print "╚══════════════════════════════════════════════════════════════════════╝"
  print -P "${C_RESET}"
}

pause() {
  print -P "\n${C_MAG}Press Enter to continue...${C_RESET}"
  read
}

die() {
  print -P "${C_RED}ERROR:${C_RESET} $1"
  exit 1
}

repo_check() {
  [[ -d .git ]] || die "Not inside a git repo."
  [[ "${PWD:t}" == "$REPO_EXPECTED" ]] || print -P "${C_YELLOW}Warning:${C_RESET} current folder is ${PWD:t}, expected ${REPO_EXPECTED}."
  mkdir -p firmware/working notes backups
}

status_block() {
  print -P "${C_BLUE}== Repo ==${C_RESET}"
  pwd
  print
  git remote -v | sed -n '1,4p'
  print

  print -P "${C_BLUE}== Working firmware ==${C_RESET}"
  if [[ -f "$WORK_FW_OLD" || -f "$WORK_FW_NEW" ]]; then
    ls -lh firmware/working
  else
    print -P "${C_YELLOW}No prepared firmware copies found in firmware/working yet.${C_RESET}"
  fi
  print

  print -P "${C_BLUE}== Checksums ==${C_RESET}"
  if [[ -f "$CHECKSUM_FILE" ]]; then
    cat "$CHECKSUM_FILE"
  else
    print -P "${C_YELLOW}No checksum file yet.${C_RESET}"
  fi
}

network_info() {
  print -P "${C_BLUE}== Interfaces ==${C_RESET}"
  ip -brief addr
  print
  print -P "${C_BLUE}== Routes ==${C_RESET}"
  ip route
  print
  print -P "${C_BLUE}== Wi-Fi status (if available) ==${C_RESET}"
  command -v iw >/dev/null 2>&1 && iw dev 2>/dev/null || print "iw not installed or no wireless info available."
}

default_gateway() {
  local gw iface
  gw="$(ip route | awk '/default/ {print $3; exit}')"
  iface="$(ip route | awk '/default/ {print $5; exit}')"
  if [[ -n "$gw" ]]; then
    print -P "${C_GREEN}Default gateway:${C_RESET} $gw"
    print -P "${C_GREEN}Interface:${C_RESET} $iface"
    print
    print -P "${C_YELLOW}This is usually your main router IP if you are on family Wi-Fi.${C_RESET}"
  else
    print -P "${C_RED}No default gateway found.${C_RESET}"
  fi
}

guess_main_router() {
  local gw
  gw="$(ip route | awk '/default/ {print $3; exit}')"
  if [[ -z "$gw" ]]; then
    print -P "${C_RED}No default gateway found.${C_RESET}"
    return
  fi
  local base="${gw%.*}"
  print -P "${C_GREEN}Likely main router IP:${C_RESET} $gw"
  print -P "${C_GREEN}Likely main subnet:${C_RESET} ${base}.0/24"
  print
  print -P "${C_YELLOW}Safe double-NAT idea:${C_RESET} leave main router alone, put FAST 5364 LAN on ${C_CYAN}192.168.99.1/24${C_RESET}."
}

double_nat_planner() {
  local gw base
  gw="$(ip route | awk '/default/ {print $3; exit}')"
  base="${gw%.*}"
  print -P "${C_BLUE}== Double-NAT planner ==${C_RESET}"
  print -P "Main router currently appears to be: ${C_GREEN}${gw:-unknown}${C_RESET}"
  print
  print -P "${C_WHITE}Recommended layout:${C_RESET}"
  print "Main router LAN: ${gw:-192.168.1.1}"
  print "FAST 5364 WAN/outer side: gets IP from main router"
  print "FAST 5364 LAN/inner side: 192.168.99.1"
  print "FAST 5364 DHCP pool: 192.168.99.100 - 192.168.99.200"
  print
  print -P "${C_YELLOW}Why:${C_RESET} avoids overlap with the common 192.168.1.0/24 or 192.168.0.0/24 family network."
  print
  print -P "${C_CYAN}Use this if you want a clean lab network without breaking family Wi-Fi.${C_RESET}"
}

firmware_evidence() {
  print -P "${C_BLUE}== Firmware evidence ==${C_RESET}"
  print -P "${C_GREEN}Repo README says:${C_RESET} install older default firmware 2600t, run the browser console JS, then re-upgrade to latest 2816t."
  print -P "${C_GREEN}Guide says:${C_RESET} versions above SG4K10002600t have the SSH loophole patched, so downgrade to 2600t or below first."
  print
  print -P "${C_BLUE}Local firmware files found:${C_RESET}"
  find . -maxdepth 1 -type f | grep -E '2600t|2816t|2808t|2810t|1E00t' | sort
  print
  print -P "${C_BLUE}Prepared copies:${C_RESET}"
  ls -lh firmware/working 2>/dev/null || true
}

double_nat_guide() {
  print -P "${C_BLUE}== Double-NAT quick guide ==${C_RESET}"
  print "1. Keep family router exactly as it is."
  print "2. Connect FAST 5364 WAN/Internet port to a LAN port on the main router."
  print "3. On FAST 5364, use a different LAN subnet, e.g. 192.168.99.1/24."
  print "4. Keep FAST 5364 DHCP on for your own lab devices only."
  print "5. Do not change family router DHCP, SSID, or WAN settings."
  print
  print -P "${C_YELLOW}If you only want SSH tinkering, you can delay bridge-mode stuff until later.${C_RESET}"
}

browser_js_reminder() {
  print -P "${C_BLUE}== Browser / JS SSH reminder ==${C_RESET}"
  print "1. Log in to http://192.168.1.1"
  print "2. Check firmware version near bottom of page."
  print "3. If above 2600t, downgrade to fw-2600t.img.gsdf first."
  print "4. Press F12 -> Console"
  print "5. Paste exactly:"
  print
  print -P "${C_CYAN}\$.xmo.setValuesTree(true,\"Device/UserAccounts/Users/User[@uid=3]/RemoteAccesses/RemoteAccess[@uid=3]/Enabled\")${C_RESET}"
  print
  print "6. Press Enter"
  print "7. Reboot router"
  print
  print -P "${C_YELLOW}After reboot, test SSH with admin + your router GUI password.${C_RESET}"
}

ssh_notes() {
  print -P "${C_BLUE}== SSH / root / TR-069 notes ==${C_RESET}"
  print -P "${C_GREEN}SSH login:${C_RESET}"
  print "ssh admin@192.168.1.1"
  print
  print -P "${C_GREEN}Root login inside SSH:${C_RESET}"
  print "login"
  print "user: root"
  print "pass: root"
  print
  print -P "${C_GREEN}Disable automatic updates / TR-069:${C_RESET}"
  print 'xmo-client -p "Device/ManagementServer/URL" -s ""'
  print 'xmo-client -p "Device/ManagementServer/TR69InternalData/Settings/Port" -s 0'
  print
  print -P "${C_GREEN}Check URL value:${C_RESET}"
  print 'xmo-client -p "Device/ManagementServer/URL"'
  print
  print -P "${C_YELLOW}These command examples are listed in the repo README.${C_RESET}"
}

create_notes() {
  cat > "$PLAN_FILE" <<'EOF2'
FAST 5364 lab checklist

A) Info to collect first
- Main router IP:
- Main router subnet:
- FAST 5364 current firmware:
- FAST 5364 LAN IP target:
- FAST 5364 DHCP pool:

B) Safe double-NAT plan
- Main router unchanged
- FAST 5364 WAN -> main router LAN
- FAST 5364 LAN -> 192.168.99.1/24
- FAST 5364 DHCP -> 192.168.99.100-192.168.99.200

C) Firmware / SSH steps
1. Upload fw-2600t.img.gsdf
2. Wait 3-5 minutes for reboot
3. Browser console:
   $.xmo.setValuesTree(true,"Device/UserAccounts/Users/User[@uid=3]/RemoteAccesses/RemoteAccess[@uid=3]/Enabled")
4. Reboot
5. ssh admin@192.168.1.1
6. Optional: upgrade to fw-2816t.img.gsdf

D) After SSH
- login -> root / root
- disable TR-069
EOF2
  print -P "${C_GREEN}Created ${PLAN_FILE}${C_RESET}"
  print
  cat "$PLAN_FILE"
}

safety_notes() {
  print -P "${C_BLUE}== Safety reminders ==${C_RESET}"
  print "- Do not factory reset unless you mean to lose the SSH-enabled setting."
  print "- Do not flash random firmware versions just because they are newer."
  print "- For the published SSH path, 2600t is the downgrade target and 2816t is the known re-upgrade target."
  print "- Wait a full 3-5 minutes after firmware changes."
  print "- Keep one browser tab only for the router so you do not lose track."
  print "- Write down passwords and IPs before changing network settings."
}

main() {
  repo_check
  while true; do
    banner
    print -P "${C_GREY}Tip:${C_RESET} choose one thing, finish it, then come back to the menu."
    print
    read "choice?Enter option number: "
    print
    case "$choice" in
      1) status_block; pause ;;
      2) network_info; pause ;;
      3) default_gateway; pause ;;
      4) guess_main_router; pause ;;
      5) double_nat_planner; pause ;;
      6) firmware_evidence; pause ;;
      7) double_nat_guide; pause ;;
      8) browser_js_reminder; pause ;;
      9) ssh_notes; pause ;;
      10) create_notes; pause ;;
      11) safety_notes; pause ;;
      0) print -P "${C_GREEN}Bye. Stay patient and flash slowly.${C_RESET}"; exit 0 ;;
      *) print -P "${C_RED}Invalid option.${C_RESET}"; sleep 1 ;;
    esac
  done
}

main
