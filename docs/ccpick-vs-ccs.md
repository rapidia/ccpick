# ccpick vs ccs

ccpick과 [ccs (Claude Code Switch)](https://ccs.kaitran.ca/) 의 차이, 그리고 ccs를 ccpick처럼
"같은 계정의 여러 플랜을 전환하며 세션·설정을 공유" 하는 용도로 쓰는 방법을 정리한다.

> 출처 표기
> - ✅ **소스/실측**: 이 저장소 소스(`bin/ccpick`) 또는 이번에 직접 실행해 확인한 사실
> - 📄 **문서 기준**: ccs 공식 문서(docs.ccs.kaitran.ca) 기준. 직접 실측하지 않음
> - ⚠️ **미검증**: 문서에도 없거나 확인하지 못한 사항

## 한 줄 요약

둘 다 `claude` CLI를 감싸 여러 계정/플랜을 전환하는 wrapper다.
ccpick은 **토큰만 분리하고 `~/.claude`(설정·히스토리)는 통째 공유**하는 단일 bash 스크립트이고,
ccs는 **프로필 단위로 격리**하는 게 기본이며 멀티 모델 라우팅까지 얹은 더 큰 도구다.

## 핵심 차이

| 항목 | ccpick | ccs |
|------|--------|-----|
| 형태 | bash 단일 스크립트(~8KB) ✅ | bun/npm 글로벌 패키지 + cliproxy 인프라 📄 |
| 무엇을 분리하나 | **토큰(인증)만** ✅ | **프로필(인스턴스) 전체**가 기본 📄 |
| 설정/히스토리(`~/.claude`) | 통째 **공유**(config_dir 분리 안 함) ✅ | 프로필별 `~/.ccs/instances/<name>`로 **격리**가 기본 📄 |
| 기존 세션 연속성 | 도입 **전** `~/.claude` 세션도 그대로 `--resume` ✅ | 프로필 생성 **이후** 세션만 보임(기본) 📄 |
| 대상 모델 | **Claude 전용** ✅ | Claude + GLM·Kimi·Gemini·Codex 멀티 모델 📄 |
| 토큰 관리 | 가진 `sk-ant-oat...`를 직접 저장/주입 ✅ | OAuth 브라우저 로그인. 토큰 직접 주입 경로 없음 📄 |
| 선택 UI | `fzf`(없으면 `select`)로 목록에서 선택 ✅ | `ccs <프로필명>` 이름 직접 지정 📄 |
| 신뢰 경계 | `env` 주입 후 `exec claude` — 토큰 흐름이 투명 ✅ | 로컬 프록시(cliproxy) 경유 📄 / 토큰 처리 상세는 ⚠️ |
| 플랫폼 | macOS·Linux(`stat` GNU/BSD 문법 모두 처리) ✅ | 크로스 플랫폼 표방 📄 |

## ccpick의 동작 (소스 기준 ✅)

- `~/.config/ccpick/plans.env` 에 `<이름>=<토큰>` 한 줄씩 평문 저장(권한 600 권장/경고).
- `ccpick` → fzf로 플랜 선택 → 해당 토큰을 `CLAUDE_CODE_OAUTH_TOKEN` 으로 `export` 후 `exec claude "$@"`.
- `~/.claude` 를 그대로 공유하므로 **설정·히스토리·프로젝트가 항상 공유**된다.
  한 플랜에서 시작한 대화를 다른 플랜에서 `claude --resume` 으로 그대로 이어갈 수 있다.
- `ccpick add <이름>` → `claude setup-token` 출력을 캡처해 `plans.env` 에 추가.

## ccs로 ccpick처럼 쓰기

ccs는 프로필을 **격리**하는 게 기본이라, 그냥 쓰면 세션 히스토리가 프로필 간 공유되지 않는다
(`claude --resume` 목록이 서로 안 보임). 원인과 해법은 아래와 같다.

### 왜 기본값으로는 resume이 공유 안 되나 📄

- ccs는 프로필마다 별도 `config_dir`(`~/.ccs/instances/<name>`)를 두고 기본 `context_mode: isolated`.
- 세션 히스토리(`~/.claude/projects`, `--resume` 이 읽는 대화 목록)가 프로필별로 갈린다.
- `ccs auth resources <profile> --mode shared` 의 `shared` 모드는 **settings·plugins·skills·agents·commands만**
  공유한다. **히스토리는 별개**다.

### 해법: 생성 시 context group + share-context ✅(실측)

`ccs auth create` 에 히스토리 공유용 플래그가 있다:

```
ccs auth create <name> [--bare] [--force] [--share-context] [--context-group <name>] [--deeper-continuity]
```

두 프로필을 **같은 context group + `--share-context`** 로 만들면 세션 히스토리가 묶여
`--resume` 이 프로필 간에 공유된다. 아래 형태로 실제로 동작 확인됨:

```bash
ccs auth create pro --share-context --context-group shared --force
ccs auth create max --share-context --context-group shared --force

ccs pro            # pro 플랜으로 실행
ccs max --resume   # pro에서 만든 세션도 보임 (인자는 claude 로 패스스루)
```

검증: `ccs auth create pro --share-context --context-group shared --force` 로 같은 계정 로그인 +
세션 resume 공유가 정상 동작함을 확인.

### 주의점

- ⚠️ `--share-context` / `--context-group` 은 **생성 시점에만** 적용된다. 이미 만든 프로필을 사후에 같은 그룹으로
  넣는 명령이 문서에 없어, 기존 프로필을 `ccs auth remove <name> --force` 후 **재생성**해야 할 수 있다.
- 📄 `ccs auth resources` 는 히스토리가 아니라 plugins/settings 공유를 제어한다. 히스토리 공유는 context group 소관.
- ⚠️ 같은 Claude 계정에 두 프로필을 동시 로그인했을 때 **세션 한도가 실제로 분리되는지**는 문서에 명시가 없고
  이번에 확인하지 않았다(로그인 자체가 되는 것과 별개 문제).
- ⚠️ cliproxy가 토큰/트래픽을 어떻게 다루는지는 검증하지 않았다.
- ccs 프로필은 **그 프로필 생성 이후 세션만** `--resume` 에 보인다(기본 config_dir 격리 때문). ccs 도입 전
  `~/.claude/projects` 세션을 끌어오려면 `ccs auth backup default` / native lane 같은 마이그레이션이 필요해 보이나
  (문서 암시 📄) 확인하지 않았다 ⚠️. 반면 ccpick은 `~/.claude` 를 그대로 써서 **도입 전 세션까지 그대로 resume**된다 ✅.

## 언제 무엇을 쓰나

- **같은 계정 멀티 플랜 + 세션 공유**가 목적이라면: ccs도 위 플래그로 충족된다(✅ 확인). 멀티 모델까지 필요하면 ccs.
- **무거운 런타임(bun)·프록시를 환경에 안 들이고, 8KB bash로 토큰 흐름을 완전히 투명하게** 두고 싶다면 ccpick.
- ccpick은 본래 학습용 연습 프로젝트(`practice/ccpick`)로, "가볍고 투명한 토큰 스위처"라는 좁은 틈새에서 의미가 있다.
