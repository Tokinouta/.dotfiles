# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Universal shell dotfiles (bash, zsh, extensible to other shells). The repo is cloned/symlinked at `~/.dotfiles` and sourced live by `~/.bashrc` and `~/.zshrc` — there is no build, test, or lint step. Changes take effect by opening a new shell or re-sourcing the appropriate rc file.

## Shell detection

`config/shell/init.sh` detects the running shell at startup and exports `SHELL_TYPE` (`bash` or `zsh`). All downstream files use this variable to branch on shell-specific behavior (e.g., `shopt` for bash, `setopt` for zsh). To add support for a new shell (e.g. fish), add its detection in `init.sh` and guard shell-specific code with `if [ "$SHELL_TYPE" = "fish" ]`.

## Load order

`~/.bashrc` or `~/.zshrc` sources `config/shell/init.sh`, which loads (in order):
1. `config/shell/config.sh` — shell options (bash: `shopt`, zsh: `setopt`)
2. `config/shell/env.sh` — env vars, `PATH`, rustup mirrors, cargo, bun, starship, zoxide
3. `config/shell/aliases.sh` — aliases (mostly modern CLI replacements)
4. `config/shell/functions.sh` — shell functions
5. `config/shell/extras/*.sh` — auto-globbed; each file is a self-contained tool init (`conda.sh`, `nvm.sh`)

To add a new tool's shell integration, drop a new `config/shell/extras/<tool>.sh` — `init.sh` picks it up automatically via glob. No edit to `init.sh` needed.

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

Defined in `config/shell/functions.sh`:
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
