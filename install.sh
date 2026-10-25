#!/data/data/com.termux/files/usr/bin/bash
# OpenWRT on Your phone! - Termux QEMU installer
# Tested target: OpenWrt armsr/armv8 initramfs under qemu-system-aarch64
set -Eeuo pipefail

APP_NAME="OpenWRT-on-Your-phone"
BASE_DIR="${HOME}/openwrt-vm"
VERSION="25.12.6"
IMAGE_NAME="openwrt-${VERSION}-armsr-armv8-generic-initramfs-kernel.bin"
IMAGE_URL="https://downloads.openwrt.org/releases/${VERSION}/targets/armsr/armv8/${IMAGE_NAME}"
RAM_MB="${RAM_MB:-512}"
CPUS="${CPUS:-2}"
HTTP_PORT="${HTTP_PORT:-8080}"
SSH_PORT="${SSH_PORT:-2222}"
PID_FILE="${BASE_DIR}/qemu.pid"
LOG_FILE="${BASE_DIR}/qemu.log"
QEMU_BIN="qemu-system-aarch64"

die() { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }
info() { printf '\n[INFO] %s\n' "$*"; }
ok() { printf '[ OK ] %s\n' "$*"; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

need_termux() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] || {
    printf 'This script is intended for Termux.\n'
    printf 'Install Termux from F-Droid or the official GitHub releases.\n'
    exit 1
  }
}

install_dependencies() {
  info "Updating Termux packages..."
  pkg update -y
  info "Installing QEMU and download tools..."
  pkg install -y qemu-system-aarch64-headless wget curl tar coreutils
  command_exists "$QEMU_BIN" || die "QEMU binary not found after package installation."
  command_exists wget || die "wget was not installed."
  ok "Dependencies installed."
}

download_image() {
  mkdir -p "$BASE_DIR"
  if [[ -s "${BASE_DIR}/${IMAGE_NAME}" ]]; then
    ok "Using existing image: ${IMAGE_NAME}"
    return
  fi
  info "Downloading OpenWrt ${VERSION} ARM64 initramfs image..."
  wget -O "${BASE_DIR}/${IMAGE_NAME}.part" "$IMAGE_URL" || {
    rm -f "${BASE_DIR}/${IMAGE_NAME}.part"
    die "Download failed. Check your connection and OpenWrt download URL."
  }
  [[ -s "${BASE_DIR}/${IMAGE_NAME}.part" ]] || die "Downloaded image is empty."
  mv "${BASE_DIR}/${IMAGE_NAME}.part" "${BASE_DIR}/${IMAGE_NAME}"
  ok "Image downloaded."
}

write_launcher() {
  cat > "${BASE_DIR}/start.sh" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
BASE_DIR="${HOME}/openwrt-vm"
VERSION="25.12.6"
IMAGE_NAME="openwrt-${VERSION}-armsr-armv8-generic-initramfs-kernel.bin"
QEMU_BIN="qemu-system-aarch64"
RAM_MB="${RAM_MB:-512}"
CPUS="${CPUS:-2}"
HTTP_PORT="${HTTP_PORT:-8080}"
SSH_PORT="${SSH_PORT:-2222}"
PID_FILE="${BASE_DIR}/qemu.pid"
LOG_FILE="${BASE_DIR}/qemu.log"

if ! command -v "$QEMU_BIN" >/dev/null 2>&1; then
  echo "QEMU is missing. Run: bash ~/openwrt-vm/install.sh"
  exit 1
fi
if [[ ! -s "${BASE_DIR}/${IMAGE_NAME}" ]]; then
  echo "OpenWrt image is missing. Run: bash ~/openwrt-vm/install.sh"
  exit 1
fi
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "OpenWrt QEMU is already running (PID $(cat "$PID_FILE"))."
  echo "LuCI: http://127.0.0.1:${HTTP_PORT}"
  exit 0
fi

# The OpenWrt armsr/armv8 initramfs boots with eth0 on the virt machine.
# User-mode networking exposes the VM's HTTP/SSH ports on Android localhost.
nohup "$QEMU_BIN" \
  -machine virt \
  -cpu cortex-a57 \
  -m "$RAM_MB" \
  -smp "$CPUS" \
  -kernel "${BASE_DIR}/${IMAGE_NAME}" \
  -append "console=ttyAMA0" \
  -nographic \
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${HTTP_PORT}-10.0.2.15:80,hostfwd=tcp:127.0.0.1:${SSH_PORT}-10.0.2.15:22" \
  -device virtio-net-device,netdev=net0 \
  >"$LOG_FILE" 2>&1 &
echo "$!" > "$PID_FILE"
sleep 2
if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "OpenWrt QEMU started (PID $(cat "$PID_FILE"))."
  echo "LuCI: http://127.0.0.1:${HTTP_PORT}"
  echo "SSH forwarding: 127.0.0.1:${SSH_PORT} -> VM port 22"
  echo "Log: $LOG_FILE"
else
  rm -f "$PID_FILE"
  echo "QEMU did not stay running. Last log lines:"
  tail -n 50 "$LOG_FILE" 2>/dev/null || true
  exit 1
fi
LAUNCHER

  cat > "${BASE_DIR}/stop.sh" <<'STOPPER'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
PID_FILE="${HOME}/openwrt-vm/qemu.pid"
if [[ ! -f "$PID_FILE" ]]; then
  echo "No QEMU PID file found; OpenWrt may already be stopped."
  exit 0
fi
PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID" 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
  done
  kill -9 "$PID" 2>/dev/null || true
  echo "Stopped QEMU (PID $PID)."
else
  echo "QEMU is not running."
fi
rm -f "$PID_FILE"
STOPPER

  cat > "${BASE_DIR}/status.sh" <<'STATUS'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
PID_FILE="${HOME}/openwrt-vm/qemu.pid"
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Status: RUNNING (PID $(cat "$PID_FILE"))"
  echo "LuCI: http://127.0.0.1:${HTTP_PORT:-8080}"
  echo "Log: ${HOME}/openwrt-vm/qemu.log"
else
  echo "Status: STOPPED"
fi
STATUS

  chmod +x "${BASE_DIR}/start.sh" "${BASE_DIR}/stop.sh" "${BASE_DIR}/status.sh"
  ok "Created start.sh, stop.sh, status.sh."
}

write_readme() {
  cat > "${BASE_DIR}/README.txt" <<EOF
${APP_NAME}
==========================
OpenWrt ${VERSION} ARM64 in QEMU on Android/Termux.

Commands:
  bash ~/openwrt-vm/start.sh
  bash ~/openwrt-vm/status.sh
  bash ~/openwrt-vm/stop.sh
  tail -f ~/openwrt-vm/qemu.log

LuCI URL:
  http://127.0.0.1:${HTTP_PORT}

Default resources:
  RAM: ${RAM_MB} MB
  vCPUs: ${CPUS}

Important:
- This is a virtual machine, not native OpenWrt on the phone's Wi-Fi chipset.
- Initramfs is temporary; configuration/package changes may disappear after shutdown.
- The host-forwarded web port works only when OpenWrt inside the VM has IP 10.0.2.15.
- If LuCI does not load, inspect ~/openwrt-vm/qemu.log and confirm the VM has booted.
EOF
}

main() {
  need_termux
  install_dependencies
  download_image
  write_launcher
  write_readme
  printf '\n============================================\n'
  printf ' OpenWrt installer completed!\n'
  printf '============================================\n'
  printf 'Start VM : bash ~/openwrt-vm/start.sh\n'
  printf 'Stop VM  : bash ~/openwrt-vm/stop.sh\n'
  printf 'Status   : bash ~/openwrt-vm/status.sh\n'
  printf 'LuCI     : http://127.0.0.1:%s\n' "$HTTP_PORT"
  printf '\nRAM/CPU overrides for a run:\n'
  printf '  RAM_MB=256 CPUS=4 bash ~/openwrt-vm/start.sh\n'
  printf '\nNote: LuCI is available only if the downloaded image already contains it.\n'
}
main "$@"
