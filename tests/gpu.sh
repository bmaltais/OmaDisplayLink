#!/usr/bin/env bash
# Tests for scripts/displaylink-gpu.sh with stubbed pacman, vercmp and pidof and a fake /proc, /sys and
# /usr/lib tree (DISPLAYLINK_TEST_ROOT). The real hardware paths (AMD/Intel, old Aquamarine) cannot be
# run here, so this checks the decision logic only.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gpu=$repo/scripts/displaylink-gpu.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

# Stubs. pacman reads PKG_INSTALLED (a space-separated list of packages), AQ_VERSION and SYNC_VERSION.
mkdir "$work/bin"
cat >"$work/bin/pacman" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  -Q)
    shift
    for p in "$@"; do [[ " $PKG_INSTALLED " == *" $p "* ]] || exit 1; done
    [[ $1 == aquamarine ]] && echo "aquamarine ${AQ_VERSION}-1"
    exit 0 ;;
  -Si)
    [[ -n ${SYNC_VERSION:-} ]] || exit 1
    printf 'Repository      : extra\nName            : aquamarine\nVersion         : %s-1\n' "$SYNC_VERSION" ;;
esac
STUB
cat >"$work/bin/vercmp" <<'STUB'
#!/usr/bin/env bash
# Enough of vercmp for dotted numeric versions.
if [[ $1 == "$2" ]]; then echo 0; elif [[ $(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1) == "$1" ]]; then echo -1; else echo 1; fi
STUB
cat >"$work/bin/pidof" <<'STUB'
#!/usr/bin/env bash
[[ -n ${FAKE_PID:-} ]] && echo "$FAKE_PID"
STUB
chmod +x "$work/bin/"*

# scenario DRIVER|none LIB_HAS_FIX(0|1): a fresh fake tree; DRIVER is the kernel driver of the primary GPU.
scenario() {
  local driver=$1 fix=$2 root=$work/root
  rm -rf "$root"
  mkdir -p "$root/proc/42" "$root/usr/lib" "$root/dev/dri" "$root/sys/class/drm/card0/device" "$root/sys/bus/$driver"
  if [[ $driver != none ]]; then
    printf 'AQ_DRM_DEVICES=%s/dev/dri/card0:%s/dev/dri/card1\0HOME=x\0' "$root" "$root" >"$root/proc/42/environ"
    touch "$root/dev/dri/card0"
    ln -s "$root/sys/bus/$driver" "$root/sys/class/drm/card0/device/driver"
  fi
  if ((fix)); then echo 'dumb-buffer CPU copy' >"$root/usr/lib/libaquamarine.so"; else : >"$root/usr/lib/libaquamarine.so"; fi
  export DISPLAYLINK_TEST_ROOT=$root FAKE_PID=42
  [[ $driver == none ]] && unset FAKE_PID
}

# expect NAME WANT_RC MODE: run the script in the current scenario and compare the exit status.
expect() {
  local name=$1 want=$2 mode=$3 rc
  PATH="$work/bin:$PATH" "$gpu" "$mode" >/dev/null 2>&1
  rc=$?
  if ((rc == want)); then echo "ok    $name"; else echo "FAIL  $name (exit $rc, wanted $want)"; fails=1; fi
}

export PKG_INSTALLED="displaylink aquamarine"
export AQ_VERSION=0.15.1 SYNC_VERSION=0.16.0

scenario nvidia 0
expect "NVIDIA, 0.15.1, no fix: stale" 0 --stale
expect "NVIDIA, 0.15.1, no fix: is NVIDIA" 0 --nvidia
scenario nvidia 1
expect "NVIDIA, 0.15.1, carries the fix: not stale" 1 --stale
scenario nvidia 0
AQ_VERSION=0.16.0 expect "NVIDIA, 0.16.0: not stale" 1 --stale
AQ_VERSION=0.16.1 expect "NVIDIA, 0.16.1: not stale" 1 --stale
AQ_VERSION=0.9.9 expect "NVIDIA, 0.9.9: stale (not a string compare)" 0 --stale
scenario amdgpu 0
expect "AMD primary, 0.15.1: never stale" 1 --stale
expect "AMD primary: not NVIDIA" 1 --nvidia
scenario i915 0
expect "Intel primary, 0.15.1: never stale" 1 --stale
scenario none 0
expect "no session, no nvidia_drm module (fallback): not NVIDIA" 1 --nvidia
mkdir -p "$work/root/sys/module/nvidia_drm"
expect "no session, nvidia_drm loaded (fallback): NVIDIA" 0 --nvidia
PKG_INSTALLED="displaylink" expect "no aquamarine package: not stale" 1 --stale
scenario nvidia 0
PKG_INSTALLED="aquamarine" expect "DisplayLink not installed: not stale" 1 --stale
SYNC_VERSION=0.15.1 expect "mirror still 0.15.1: behind" 0 --mirror-behind
SYNC_VERSION=0.16.0 expect "mirror has 0.16.0: not behind" 1 --mirror-behind
SYNC_VERSION=0.17.2 expect "mirror has 0.17.2: not behind" 1 --mirror-behind
SYNC_VERSION="" expect "no sync database entry: not behind (offer the update)" 1 --mirror-behind
expect "bad mode: exit 2" 2 --bogus

PATH="$work/bin:$PATH" AQ_VERSION=0.15.1 out=$("$gpu" --version)
[[ $out == 0.15.1 ]] && echo "ok    --version strips the pkgrel" || { echo "FAIL  --version printed '$out'"; fails=1; }

exit "$fails"
