# shared helpers, sourced by provision.sh and modules
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOFTWARE="$REPO/software"
CONFIGS="$REPO/configs"

# lab identity — matches whale (NIS/NFS master)
NIS_DOMAIN="waxlab"
YP_SERVER="136.244.170.66"
NFS_SERVER="whale.conncoll.edu"
NFS_EXPORT="/home"
NFS_MOUNT="/home/CS_data"
TIMEZONE="America/New_York"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

need_root() { [ "$(id -u)" -eq 0 ] || die "run as root (sudo)"; }

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}
