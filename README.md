<div align="center">

# ccpick

**Pick a plan. Launch Claude.**

A tiny fzf-powered plan switcher for [Claude Code](https://claude.com/claude-code) —
keep multiple OAuth tokens (Pro, Max, work…) and pick one per terminal, sharing a
single config and history.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Shell: Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![Platform: macOS · Linux](https://img.shields.io/badge/platform-macOS%20·%20Linux-lightgrey)

</div>

---

<p align="center">
  <img src="docs/demo.gif" alt="ccpick demo — pick a plan with fzf, claude launches on it, and CCPICK_PLAN tells you which one" width="800">
</p>

Different plans, side by side:

```text
┌─ Terminal A ───────────────┐   ┌─ Terminal B ───────────────┐
│ $ ccpick                   │   │ $ ccpick                   │
│ ▶ plan: pro                │   │ ▶ plan: max                │
│ claude (Pro) …             │   │ claude (Max) …             │
└────────────────────────────┘   └────────────────────────────┘
```

## Why

Claude Code signs in as **one** account. If you have more than one subscription —
a personal Pro, a Max for heavy sessions, a separate work account — switching means
a `/logout` → `/login` → browser round-trip every single time.

ccpick ends that dance:

- **No re-login.** Each plan's OAuth token is stored once; pick one at launch.
- **Run plans concurrently.** Terminal A on Pro, Terminal B on Max, at the same time.
- **One home.** `~/.claude` is untouched — settings, history, and projects are
  shared across every plan. Only the token differs.

## How it works

```text
~/.config/ccpick/plans.env          fzf (or select)              exec
┌──────────────────────────┐      ┌───────────────┐      ┌──────────────────────┐
│ pro=sk-ant-oat01-…       │ ───▶ │  pick a plan  │ ───▶ │ CLAUDE_CODE_OAUTH_   │
│ max=sk-ant-oat01-…       │      └───────────────┘      │ TOKEN=… exec claude  │
└──────────────────────────┘                             └──────────────────────┘
```

One ~190-line bash script. No daemon, no proxy, no wrapper process left behind —
`exec` replaces ccpick with `claude` itself.

|                                    | Shared | Per-plan |
| ---------------------------------- | :----: | :------: |
| Settings (`~/.claude`)             |   ✅   |          |
| History & projects                 |   ✅   |          |
| MCP servers, hooks, skills         |   ✅   |          |
| OAuth token (subscription)         |        |    ✅    |

## Install

Requires the [`claude`](https://claude.com/claude-code) CLI.
[`fzf`](https://github.com/junegunn/fzf) is optional but recommended (`brew install fzf`) —
without it, ccpick falls back to a plain `select` menu.

```sh
curl -fsSL https://raw.githubusercontent.com/rapidia/ccpick/main/install.sh | bash
```

This drops a single bash script into `~/.local/bin` (override with `CCPICK_BIN_DIR`)
and tells you if that directory isn't on your PATH. Uninstall = `rm ~/.local/bin/ccpick`.

<details>
<summary>Install from source instead</summary>

```sh
git clone https://github.com/rapidia/ccpick.git
cd ccpick
ln -s "$PWD/bin/ccpick" ~/.local/bin/ccpick   # assumes ~/.local/bin is on PATH
```

</details>

Then register your plans — `ccpick add` wraps `claude setup-token`, walks you through
the browser login, and stores the resulting token:

```sh
ccpick add pro
ccpick add max
```

`~/.config/ccpick/plans.env` is created automatically with `600` permissions.

<details>
<summary>Prefer to write the file by hand?</summary>

```sh
mkdir -p ~/.config/ccpick
cp plans.env.example ~/.config/ccpick/plans.env
chmod 600 ~/.config/ccpick/plans.env
```

One `<name>=<token>` per line. `#` comments and blank lines are ignored,
surrounding whitespace is trimmed:

```ini
# personal
pro=sk-ant-oat01-...
max=sk-ant-oat01-...
```

</details>

## Usage

```sh
ccpick               # pick a plan → interactive claude
ccpick add <name>    # create a token via `claude setup-token` and store it
ccpick --resume      # any arguments are passed straight through to claude
```

Inside a running session, check which plan it's on:

```text
! echo $CCPICK_PLAN
max
```

## Security model

- **Tokens live in exactly one place:** `~/.config/ccpick/plans.env`, plaintext,
  `600`. ccpick warns at launch if the permissions are anything else.
- **The parent shell is never touched.** The token is exported only to the
  `exec`'d `claude` process and disappears with it.
- **Nothing in between.** No background process, no local proxy — the token flows
  `plans.env → env → claude`, and that's the whole pipeline. Auditable in one
  screenful of bash: [`bin/ccpick`](bin/ccpick).

## Configuration

| Variable       | Effect                                              | Default                       |
| -------------- | --------------------------------------------------- | ----------------------------- |
| `CCPICK_PLANS` | Path to the plans file                              | `~/.config/ccpick/plans.env`  |
| `CCPICK_PLAN`  | *Set by ccpick* — plan name visible inside the session | —                          |

## FAQ

**I get the theme picker / onboarding screen on launch.**
The token only replaces *authentication*; onboarding state lives in `~/.claude.json`.
Log in to `claude` normally once, finish onboarding, and ccpick sessions won't see
it again. ccpick detects this state and warns before launching.

**Does this touch my existing Claude Code login?**
No. ccpick never writes to `~/.claude` — it only injects an environment variable
for the one process it launches.

**How is this different from account switchers like ccs?**
ccpick is a single bash script that injects a token and `exec`s — no proxy, no
extra runtime. A detailed comparison (in Korean): [docs/ccpick-vs-ccs.md](docs/ccpick-vs-ccs.md).

## License

[MIT](LICENSE)
