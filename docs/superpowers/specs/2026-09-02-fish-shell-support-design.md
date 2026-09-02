# Fish Shell Support — Design

- **Date:** 2026-09-02
- **Status:** Approved in design review
- **Scope:** Add fish shell configuration to the dotfiles repo, mirroring the bash/zsh setup, without modifying the existing POSIX chain.

## Problem

The repo configures bash and zsh through a POSIX chain: `~/.bashrc` / `~/.zshrc` source `config/shell/init.sh`, which loads `config.sh`, `env.sh`, `aliases.sh`, `functions.sh`, `extras/*.sh`, then `post-init.sh`.

Fish 4.2.1 is installed on Dayong and needs the same environment, but fish cannot participate in that chain:

- Fish is not POSIX-compatible. `export VAR=x`, `alias x='y'`, and `case ... esac` are syntax errors in fish.
- Fish never reads `~/.bashrc` / `~/.zshrc`. Its entry point is `~/.config/fish/config.fish`.

**Hard constraint:** the existing bash/zsh chain stays byte-for-byte untouched (documentation excepted). Fish support must be purely additive.

## Decision Summary

| Decision | Choice |
|---|---|
| Layout | Parallel tree `config/fish/` in the repo, fish syntax throughout |
| Host entry point | `~/.config/fish/config.fish` becomes a one-liner sourcing the repo entry — the exact pattern `~/.bashrc` uses |
| nvm | Skipped in fish — no native fish support (user decision, 2026-09-02) |
| openclaw | Skipped — `openclaw.sh` only sources a zsh completion; no fish completion ships with the tool |
| Existing files | Zero edits to `config/shell/**` and `~/.bashrc` |

## Architecture

```
~/.config/fish/config.fish              # host file, one line (mirrors ~/.bashrc)
└── source $HOME/.dotfiles/config/fish/init.fish
    ├── set -gx SHELL_TYPE fish         # parity with init.sh's SHELL_TYPE export
    └── if status is-interactive
        ├── env.fish                    # PATH, EDITOR/PAGER, host-specific paths
        ├── aliases.fish                # same alias set as aliases.sh
        ├── functions.fish              # extract, cl, check_inotify
        ├── extras/*.fish               # globbed, same drop-in pattern as init.sh
        └── post-init.fish              # starship + zoxide init
```

`init.fish` mirrors `init.sh`: it sets `SHELL_TYPE`, sources each downstream file behind an existence test, globs `extras/*.fish` (alphabetical, same as the bash glob), then sources `post-init.fish`. Use `set -l DOTFILES $HOME/.dotfiles/config/fish` for the base path (file-scoped, no cleanup needed — unlike init.sh's export-then-unset).

## File Mapping

| Existing (bash/zsh) | New (fish) | Translation |
|---|---|---|
| `init.sh` | `init.fish` | Entry point; sources chain, globs `extras/*.fish` |
| `config.sh` | *(no equivalent)* | Fish natively dedups and appends history and auto-tracks window size; `HISTCONTROL`/`HISTSIZE`/`shopt`/`setopt` have no fish counterparts worth setting |
| `env.sh` | `env.fish` | `set -gx EDITOR nvim`, `set -gx PAGER bat`; `fish_add_path` for `~/.local/bin`, `~/.dotfiles/scripts`; Dayong Android-SDK + `go/bin` paths under `switch (hostname)` |
| `aliases.sh` | `aliases.fish` | `alias ls 'eza --group-directories-first'` etc. (`..` and `...` are valid fish function names); `lldb` alias under hostname switch; `claude` alias |
| `functions.sh` | `functions.fish` | `function extract ... end` with `switch $argv[1]`; same bodies for `cl` and `check_inotify` |
| `post-init.sh` | `post-init.fish` | `command -q starship; and starship init fish \| source`; same for zoxide |
| `extras/cargo.sh` | `extras/cargo.fish` | `RUSTUP_UPDATE_ROOT` / `RUSTUP_DIST_SERVER` Tsinghua mirrors + `fish_add_path ~/.cargo/bin` (`~/.cargo/env` is POSIX; its only effect is that PATH entry) |
| `extras/conda.sh` | `extras/conda.fish` | Same hostname-based base detection (Dayong path, then common fallbacks); then conda's official fish hook: `eval "$CONDA_BASE/bin/conda" shell.fish hook \| source` |
| `extras/brew.sh` | `extras/brew.fish` | `Darwin` + `-x` guard; manual `set -gx HOMEBREW_PREFIX/CELLAR/REPOSITORY` + NJU mirror vars + `fish_add_path` for `bin`, `sbin`, `ffmpeg-full/bin` (`brew shellenv` emits POSIX syntax) |
| `extras/bun.sh` | `extras/bun.fish` | `fish_add_path ~/.bun/bin` — no guard needed, see `fish_add_path` semantics below |
| `extras/nvm.sh` | *(skipped)* | No native fish support (decision above) |
| `extras/openclaw.sh` | *(skipped)* | zsh completion only |

## Behavioral Decisions

### Interactive guard

Everything except the `SHELL_TYPE` export is wrapped in `if status is-interactive` inside `init.fish`. Rationale: bash only loads `.bashrc` in interactive shells, so this reproduces bash semantics exactly. (Fish, by contrast, always runs `config.fish`, so without the guard fish would do strictly more than bash does.)

### SHELL_TYPE

`init.fish` sets `set -gx SHELL_TYPE fish` unconditionally, for parity with `init.sh`. Harmless to child shells: a bash launched from fish re-detects via `~/.bashrc` → `init.sh`.

### zoxide and `cd`

`post-init.fish` runs `zoxide init fish | source`, and `aliases.fish` defines `alias cd z` — matching bash/zsh, where both `z` and `cd` are zoxide-powered.

Verified against the generated zoxide fish code (zoxide on this host): it defines `__zoxide_cd_internal` as a copy of fish's internal `cd` specifically "to make it possible to use `alias cd=z` without causing an infinite loop". The `zoxide: infinite loop detected` warning only fires when a real loop occurs. The alternative (`zoxide init fish --cmd cd`) would drop the `z` command entirely, breaking parity.

### fish_add_path semantics

Verified empirically on fish 4.2.1:

- **Prepends** each path to the front of `$PATH`.
- **Multi-argument order is preserved**: `fish_add_path a b` yields `a b <existing>`.
- **Idempotent** — already-present paths are not duplicated.
- **Silently skips non-existent directories** — a missing `~/.bun/bin` cannot pollute PATH, which is why `bun.fish` needs no existence guard.

To reproduce the exact bash PATH order (call order `~/.local/bin`, `scripts/`, Android paths, `go/bin` — each bash `export PATH=x:$PATH` prepends, so the last one ends up first), `env.fish` calls `fish_add_path` once per path in the same statement order as `env.sh`. The final PATH order is identical to bash's.

### History / window size

No port of `config.sh`. Fish's defaults already cover `HISTCONTROL=ignoreboth` (dedup + ignore space-prefixed), history append, and window-size tracking. Fish caps history by size rather than count; there is no `HISTSIZE` equivalent and none is needed.

## Host-Side and Docs Changes

### `~/.config/fish/config.fish` (host, outside repo)

Replace the 3-line default stub with:

```fish
source $HOME/.dotfiles/config/fish/init.fish
```

The user's other fish dirs (`~/.config/fish/conf.d/`, `functions/`, `completions/`, `fish_variables`) are untouched.

### `CLAUDE.md`

- Document the fish tree and its load order alongside the bash/zsh chain.
- Fix the "Shell detection" guidance: it currently says adding a shell (e.g. fish) means extending `init.sh` — impossible for fish, which never sources `init.sh`. New rule: bash/zsh inits live in `config/shell/extras/*.sh`; fish inits live in `config/fish/extras/*.fish`. A new tool may need one of each.
- Note that `nvm` is bash/zsh-only in the tool table.
- Extend the "Aliases shadow standard commands" caveat: in fish, `cd` is likewise not the builtin.

### `README.md`

Untouched (two lines, by design).

## Testing

1. **Syntax:** `fish -n` on every new `.fish` file.
2. **Functional** (`fish -i -c '...'`, which loads `config.fish` first):
   - `$SHELL_TYPE` is `fish`
   - PATH contains `~/.local/bin`, `~/.dotfiles/scripts`, and on Dayong the Android SDK + `go/bin` paths, in bash-equivalent order
   - `type extract`, `functions cl check_inotify` resolve
   - `alias`-created functions resolve: `ls` → eza, `cat` → bat, `cd` → `z`-wrapping function
   - `functions starship_prompt` and `type conda` resolve (starship + conda hooks loaded)
3. **Regression:**
   - `bash -ic 'echo $SHELL_TYPE; type extract; echo $PATH'` behaves exactly as before
   - zsh smoke test if zsh is installed on the host
   - `git status` shows only new files under `config/fish/`, `docs/`, and the modified `CLAUDE.md` — nothing under `config/shell/`
4. **Startup time:** `time fish -i -c exit` stays in the same ballpark as bash's interactive startup (the conda hook is the heavy part in both).

## Non-Goals

- Making fish the default login shell
- Porting nvm or openclaw to fish
- Touching `~/.config/fish/{conf.d,functions,completions,fish_variables}`
- Any refactor of the bash/zsh chain, including the empty `install/` directory
- A symlink/bootstrap script (the one host-side edit is a single line)
