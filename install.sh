#!/usr/bin/env bash
#
# ccpick 설치 스크립트
#   curl -fsSL https://raw.githubusercontent.com/rapidia/ccpick/main/install.sh | bash
#
# bin/ccpick 한 파일을 받아 ~/.local/bin (CCPICK_BIN_DIR 로 변경 가능)에 둔다.
# 임시 파일로 받은 뒤 셔뱅을 확인하고 이동해, 부분 다운로드로 깨진
# 파일이 PATH 에 남지 않게 한다.
#
set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/rapidia/ccpick/main/bin/ccpick"
BIN_DIR="${CCPICK_BIN_DIR:-$HOME/.local/bin}"
TARGET="$BIN_DIR/ccpick"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"

mkdir -p "$BIN_DIR"

tmp="$(mktemp "${TMPDIR:-/tmp}/ccpick-install.XXXXXX")" || die "failed to create temp file"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$RAW_URL" -o "$tmp" || die "download failed: $RAW_URL"
IFS= read -r first_line < "$tmp" || true
[[ "$first_line" == '#!/usr/bin/env bash' ]] || die "downloaded file doesn't look like ccpick (got: ${first_line:0:40})"

chmod 755 "$tmp"
mv "$tmp" "$TARGET"
trap - EXIT

printf '✔ ccpick installed: %s\n' "$TARGET"

# PATH 점검 — 설치 디렉터리가 PATH 에 없으면 안내한다.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    printf '\nnote: %s is not on your PATH. Add this to your shell profile:\n' "$BIN_DIR"
    printf '  export PATH="%s:$PATH"\n' "$BIN_DIR"
    ;;
esac

# 런타임 의존성 안내 (설치는 막지 않는다).
command -v claude >/dev/null 2>&1 \
  || printf '\nnote: the `claude` CLI was not found — ccpick needs it at runtime.\n'
command -v fzf >/dev/null 2>&1 \
  || printf 'note: `fzf` not found — ccpick will fall back to a plain select menu. (brew install fzf)\n'

printf '\nNext steps:\n'
printf '  ccpick add pro   # register a plan (runs `claude setup-token`)\n'
printf '  ccpick           # pick a plan and launch claude\n'
