# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal bash dotfiles. The repo is cloned/symlinked at `~/.dotfiles` and sourced live by `~/.bashrc` — there is no build, test, or lint step. Changes take effect by opening a new shell or re-sourcing `~/.bashrc`.

## Load order

`~/.bashrc` sources `config/bash/init.sh`, which loads (in order):
1. `config/bash/config.sh` — bash history/shopt options
2. `config/bash/env.sh` — env vars, `PATH`, rustup mirrors, cargo, bun, starship, zoxide
3. `config/bash/aliases.sh` — aliases (mostly modern CLI replacements)
4. `config/bash/functions.sh` — shell functions
5. `config/bash/extras/*.sh` — auto-globbed; each file is a self-contained tool init (`conda.sh`, `nvm.sh`)

To add a new tool's shell integration, drop a new `config/bash/extras/<tool>.sh` — `init.sh` picks it up automatically via glob. No edit to `init.sh` needed.

## Tool ecosystem

These tools are initialized on shell startup via the load chain above:

| Tool | Where | Purpose |
|------|-------|---------|
| starship | `env.sh` | Prompt (minimal config in `starship.toml`) |
| zoxide | `env.sh` | `z`/`cd` jump (aliased to `cd` in `aliases.sh`) |
| cargo/rustup | `env.sh` | Rust toolchain (mirrored via Tsinghua) |
| bun | `env.sh` | JavaScript runtime |
| conda | `extras/conda.sh` | Python environment management |
| nvm | `extras/nvm.sh` | Node.js version management |

`starship.toml` lives in the repo but is **not** symlinked into `$HOME` — starship finds it via its own lookup path.

## Shell functions

Defined in `config/bash/functions.sh`:
- `extract <archive>` — unpack `.tar.bz2`, `.tar.gz`, or `.zip`
- `cl` — cross-platform terminal clear
- `check_inotify` — show processes with active inotify watchers (sorted by count)

## Host detection

Several files branch on `$(hostname)` with `Dayong` being the work PC:
- `env.sh` — adds Android NDK/platform-tools/gdb + Go binary paths (Dayong only)
- `aliases.sh` — adds `lldb` alias pointing to `/usr/bin/lldb` (Dayong only)

When adding host-specific config, follow the `case "$(hostname)"` pattern rather than hardcoding paths that don't exist on other machines.

## Aliases shadow standard commands

`aliases.sh` rebinds core commands to modern replacements: `ls→eza`, `grep→rg`, `cat→bat`, `find→fd`, `du→dust`, `cd→z` (zoxide). `cd` is **not** the builtin — use `builtin cd` or `command cd` in scripts where real `cd` behavior matters. The `claude` alias forces `--permission-mode bypassPermissions`.

## Scripts on PATH

`env.sh` prepends `$HOME/.dotfiles/scripts` to `PATH` (if the dir exists), so any executable script dropped in `scripts/` becomes runnable by name — the same drop-in pattern `extras/` uses for sourced inits. **Scripts are run, not sourced**: they must be executable (`chmod +x`) and self-contained. Don't add scripts that execute side effects on `source`, or every new shell will run them.

Current scripts:
- `download_and_try_parse_issues.sh` — work-related issue downloader/parser
- `extract.sh` — multi-format archive extractor (separate from the `extract` shell function)
- `skip-boot-guide` — ADB commands to skip Android setup wizard on a connected device
- `update-zen` — third-party MIT-licensed Zen Browser AppImage installer (preserve its license/credits when editing)
