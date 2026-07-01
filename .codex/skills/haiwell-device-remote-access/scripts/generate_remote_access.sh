#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  generate_remote_access.sh --pn PN [options]

Options:
  --device-type auto|enterprise|personal  Default: auto
  --access read-only|control              Default: read-only
  --platform VALUE                        Default: web
  --allow-offline                         Generate even when DB state is offline
  --skip-http-check                       Skip /test and /index checks
  -h, --help                              Show this help
USAGE
}

pn=""
device_type="auto"
access="read-only"
platform="web"
allow_offline=0
http_check=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pn)
      pn="${2:-}"
      shift 2
      ;;
    --device-type)
      device_type="${2:-}"
      shift 2
      ;;
    --access)
      access="${2:-}"
      shift 2
      ;;
    --platform)
      platform="${2:-}"
      shift 2
      ;;
    --allow-offline)
      allow_offline=1
      shift
      ;;
    --skip-http-check)
      http_check=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! "$pn" =~ ^[0-9]{19}$ ]]; then
  echo "PN must contain exactly 19 digits" >&2
  exit 2
fi

case "$device_type" in
  auto|enterprise|personal) ;;
  *) echo "Invalid --device-type: $device_type" >&2; exit 2 ;;
esac

case "$access" in
  read-only|control) ;;
  *) echo "Invalid --access: $access" >&2; exit 2 ;;
esac

if [[ ! "$platform" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Platform contains unsupported characters" >&2
  exit 2
fi

mysql_cli="${CODEX_MYSQL_CLI:-$HOME/.codex/bin/codex-mysql}"
if [[ ! -x "$mysql_cli" ]]; then
  echo "Missing MySQL helper: $mysql_cli" >&2
  exit 2
fi

for command_name in openssl xxd curl; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 2
  fi
done

cloud_row="$($mysql_cli mysql -- --batch --raw --skip-column-names --execute "
SELECT a.id,
       COALESCE(ms.state, 0),
       COALESCE(ms.server_id, 0),
       COALESCE(s.domain, ''),
       COALESCE(s.area, '')
FROM all_machines AS a
LEFT JOIN machine_server AS ms ON ms.machine_code = a.machine_code
LEFT JOIN server AS s ON s.id = ms.server_id
WHERE a.machine_code = '$pn'
LIMIT 1;
")"

if [[ -z "$cloud_row" ]]; then
  echo "Device not found in production hwcloud2: $pn" >&2
  exit 4
fi

IFS=$'\t' read -r machine_id route_online server_id domain area <<<"$cloud_row"

enterprise_row="$($mysql_cli mysql-enterprise -- --batch --raw --skip-column-names --execute "
SELECT deviceid, eid, online
FROM device
WHERE pn = '$pn'
LIMIT 1;
")"

enterprise_id=""
eid=""
enterprise_online=""
if [[ -n "$enterprise_row" ]]; then
  IFS=$'\t' read -r enterprise_id eid enterprise_online <<<"$enterprise_row"
fi

detected_type="$device_type"
if [[ "$device_type" == "auto" ]]; then
  if [[ -n "$enterprise_id" && "${eid:-0}" != "0" ]]; then
    detected_type="enterprise"
  else
    detected_type="personal"
  fi
elif [[ "$device_type" == "enterprise" && -z "$enterprise_id" ]]; then
  echo "Device has no production enterprise.device record: $pn" >&2
  exit 4
fi

online="$route_online"
if [[ "$detected_type" == "enterprise" && -n "$enterprise_online" ]]; then
  online="$enterprise_online"
fi

if [[ "$online" != "1" && "$allow_offline" -ne 1 ]]; then
  echo "Device is offline in production (type=$detected_type, route_state=$route_online, enterprise_online=${enterprise_online:-missing})" >&2
  exit 5
fi

if [[ -n "$domain" && "$server_id" != "0" ]]; then
  base_url="https://${pn}.${domain}"
else
  base_url="http://${pn}.machine.haiwell.com:8000"
fi

subject="-1"
if [[ "$access" == "control" ]]; then
  subject="0"
fi

platform_code='cUNtl2OZTIJgyLwuiN5K'
timestamp_ms="$(($(date +%s) * 1000))"
sign="$(printf '%s' "0${pn}${timestamp_ms}${platform_code}" | openssl dgst -md5 -binary | xxd -p -c 256)"
plaintext="${sign},${subject},${pn},${platform_code},${timestamp_ms}"
key_hex="$(printf '%s' '0123456789abcd0123456789' | xxd -p -c 256)"
iv_hex="$(printf '%s' '12345678' | xxd -p -c 256)"
passid="$(printf '%s' "$plaintext" | openssl enc -des-ede3-cbc -K "$key_hex" -iv "$iv_hex" | xxd -p -c 10000)"
decoded="$(printf '%s' "$passid" | xxd -r -p | openssl enc -d -des-ede3-cbc -K "$key_hex" -iv "$iv_hex")"

if [[ "$decoded" != "$plaintext" ]]; then
  echo "PassID encryption round-trip failed" >&2
  exit 6
fi

url="${base_url}/index?passid=${passid}&platform=${platform}"
test_http="skipped"
entry_http="skipped"
verified="skipped"

if [[ "$http_check" -eq 1 ]]; then
  test_http="$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "${base_url}/test" || true)"
  entry_http="$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' "$url" || true)"
  verified="false"
  if [[ "$test_http" == "200" && "$entry_http" =~ ^(200|301|302|307|308)$ ]]; then
    verified="true"
  fi
fi

printf 'pn=%s\n' "$pn"
printf 'device_type=%s\n' "$detected_type"
printf 'access=%s\n' "$access"
printf 'online=%s\n' "$online"
printf 'route_state=%s\n' "$route_online"
printf 'enterprise_online=%s\n' "${enterprise_online:-missing}"
printf 'server_id=%s\n' "$server_id"
printf 'domain=%s\n' "${domain:-legacy-fallback}"
printf 'area=%s\n' "${area:-unknown}"
printf 'encryption_roundtrip=ok\n'
printf 'test_http=%s\n' "$test_http"
printf 'entry_http=%s\n' "$entry_http"
printf 'verified=%s\n' "$verified"
printf 'url=%s\n' "$url"

if [[ "$http_check" -eq 1 && "$verified" != "true" ]]; then
  echo "Remote tunnel verification did not pass" >&2
  exit 7
fi
