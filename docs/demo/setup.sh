#!/usr/bin/env bash
#
# vhs 데모 녹화용 샌드박스 환경을 /tmp/ccpick-demo 에 만든다.
# 실제 토큰·설정이 화면에 노출되지 않도록 가짜 plans.env 와
# 가짜 claude(실제 Claude Code 입력 UI를 흉내 낸 미니 REPL)를 사용한다.
#
set -euo pipefail

demo=/tmp/ccpick-demo
rm -rf "$demo"
mkdir -p "$demo/bin"

cat > "$demo/plans.env" <<'EOF'
pro=sk-ant-oat01-DEMO-TOKEN
max=sk-ant-oat01-DEMO-TOKEN
work=sk-ant-oat01-DEMO-TOKEN
EOF
chmod 600 "$demo/plans.env"

# 데모용 가짜 claude.
# 실제 Claude Code 의 입력 UI(구분선·❯ 프롬프트·단축키 힌트, '!' 입력 시
# shell mode 전환, 실행 결과 트랜스크립트 행)를 ANSI 로 재현한다.
# 네트워크 접근·실제 토큰 사용은 없다. '!' 명령은 eval 로 실제 실행하므로
# CCPICK_PLAN 값은 ccpick 이 진짜로 주입한 환경변수에서 나온다.
cat > "$demo/bin/claude" <<'EOF'
#!/usr/bin/env bash
ESC=$'\033'
ORANGE="${ESC}[38;2;217;119;87m"
PINK="${ESC}[38;5;205m"
GRAY="${ESC}[38;5;242m"
DGRAY="${ESC}[38;5;238m"
DARK="${ESC}[38;5;235m"
BGROW="${ESC}[48;5;254m"
BOLD="${ESC}[1m"
R="${ESC}[0m"

# 명령 치환 안에서는 tput 이 tty 를 찾지 못해 80을 돌려주므로,
# stdin(tty) 기준으로 동작하는 stty 로 실제 폭을 얻는다.
cols="$(stty size 2>/dev/null | awk '{print $2}')"
[[ -n "$cols" ]] || cols=80
sep_line="$(printf '─%.0s' $(seq 1 "$cols"))"

sep() { printf '%s%s%s\n' "$DGRAY" "$sep_line" "$R"; }

# 입력 영역(구분선/프롬프트/구분선/힌트)을 그리고 커서를 프롬프트 뒤에 둔다.
draw_input() {
  sep
  printf '%s❯%s \n' "$BOLD" "$R"
  sep
  printf '  %s? for shortcuts · ← for agents%s' "$GRAY" "$R"
  printf '%s[2A%s[3G' "$ESC" "$ESC"
}

# 시작: 실제 claude 처럼 화면을 차지한다.
printf '%s[2J%s[H' "$ESC" "$ESC"
printf ' %s✻%s Welcome to Claude Code!\n\n' "$ORANGE" "$R"
printf '%*s%s◉ xhigh · /effort%s\n' "$(( cols - 18 ))" '' "$GRAY" "$R"
first_screen=1

while true; do
  draw_input
  IFS= read -r -n1 first || break

  if [[ "$first" == "!" ]]; then
    # shell mode 전환: 프롬프트·힌트를 핑크로 바꾼다.
    printf '%s[1G%s!%s %s[0K' "$ESC" "$PINK" "$R" "$ESC"
    printf '%s[s%s[2B%s[1G%s[2K' "$ESC" "$ESC" "$ESC" "$ESC"
    printf '  %s! for shell mode%s' "$PINK" "$R"
    printf '%s[u' "$ESC"
    if [[ "$first_screen" == 1 ]]; then
      # 입력이 시작되면 effort 표시줄은 사라진다.
      printf '%s[s%s[2A%s[2K%s[u' "$ESC" "$ESC" "$ESC" "$ESC"
      first_screen=0
    fi
    IFS= read -r rest || break

    # 입력 영역을 지우고 실행 결과 트랜스크립트로 치환한다.
    cmd="${rest# }"
    out="$(eval "$cmd" 2>&1 || true)"
    pad=$(( cols - 2 - ${#rest} ))
    printf '%s[2A%s[1G%s[0J' "$ESC" "$ESC" "$ESC"
    printf '%s %s!%s%s%*s%s\n' "$BGROW" "$PINK" "$DARK$rest" '' "$pad" '' "$R"
    printf '  %s⎿%s  %s\n\n' "$GRAY" "$R" "$out"
  else
    IFS= read -r _ || break
    printf '%s[2A%s[1G%s[0J' "$ESC" "$ESC" "$ESC"
  fi
done
EOF
chmod +x "$demo/bin/claude"
