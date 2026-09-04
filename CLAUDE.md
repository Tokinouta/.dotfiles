# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Universal shell dotfiles (bash, zsh, fish). The repo is cloned/symlinked at `~/.dotfiles` and sourced live by `~/.bashrc`, `~/.zshrc`, and `~/.config/fish/config.fish` — there is no build, test, or lint step. Changes take effect by opening a new shell or re-sourcing the appropriate rc file. Bash and zsh share the POSIX chain under `config/shell/`; fish is not POSIX-compatible and loads a parallel fish-syntax tree from `config/fish/` (see "Load order").

## Shell detection

`config/shell/init.sh` detects the running shell at startup and exports `SHELL_TYPE` (`bash` or `zsh`). All downstream POSIX files use this variable to branch on shell-specific behavior (e.g., `shopt` for bash, `setopt` for zsh). `config/fish/init.fish` sets `SHELL_TYPE=fish` itself — fish never sources `init.sh`, because fish is not POSIX-compatible and does not read `~/.bashrc`/`~/.zshrc`.

To add support for a new POSIX shell (e.g. ksh), add its detection in `init.sh` and guard shell-specific code with `if [ "$SHELL_TYPE" = "ksh" ]`. A non-POSIX shell (like fish) cannot reuse `init.sh` — it needs a parallel tree under `config/<shell>/` plus a one-line host rc file sourcing its init.

## Load order

`~/.bashrc` or `~/.zshrc` sources `config/shell/init.sh`, which loads (in order):
1. `config/shell/config.sh` — shell options (bash: `shopt`, zsh: `setopt`)
2. `config/shell/env.sh` — env vars, `PATH` (tool inits live in `extras/`; starship/zoxide in `post-init.sh`)
3. `config/shell/aliases.sh` — aliases (mostly modern CLI replacements)
4. `config/shell/functions.sh` — shell functions
5. `config/shell/extras/*.sh` — auto-globbed; each file is a self-contained tool init (`conda.sh`, `nvm.sh`)

Fish loads a parallel chain: `~/.config/fish/config.fish` sources `config/fish/init.fish`, which — in interactive sessions only — loads `config/fish/env.fish`, `config/fish/aliases.fish`, `config/fish/functions.fish`, `config/fish/extras/*.fish` (auto-globbed, same drop-in pattern), then `config/fish/post-init.fish`. Non-interactive fish only gets `SHELL_TYPE=fish`.

To add a new tool's shell integration, drop `config/shell/extras/<tool>.sh` (bash/zsh) and/or `config/fish/extras/<tool>.fish` (fish) — the globs pick them up automatically. No edit to either init file is needed.

## Tool ecosystem

These tools are initialized on shell startup via the load chain above:

| Tool | Where | Purpose |
|------|-------|---------|
| starship | `post-init.sh` / `post-init.fish` | Prompt (minimal config in `starship.toml`) |
| zoxide | `post-init.sh` / `post-init.fish` | `z`/`cd` jump (`cd` aliased to `z` in both `aliases.sh` and `aliases.fish`) |
| cargo/rustup | `extras/cargo.sh` / `extras/cargo.fish` | Rust toolchain (mirrored via Tsinghua) |
| brew | `extras/brew.sh` / `extras/brew.fish` | Homebrew (macOS only) |
| bun | `extras/bun.sh` / `extras/bun.fish` | JavaScript runtime |
| conda | `extras/conda.sh` / `extras/conda.fish` | Python environment management |
| nvm | `extras/nvm.sh` / `extras/nvm.fish` | Node.js version management — bash/zsh source nvm.sh; fish only resolves the default alias onto `PATH` (nvm is a bash function library fish cannot source) |

`starship.toml` lives in the repo but is **not** symlinked into `$HOME` — starship finds it via its own lookup path.

## Shell functions

Defined in `config/shell/functions.sh` (bash/zsh) and `config/fish/functions.fish` (fish):
- `extract <archive>` — unpack `.tar.bz2`, `.tar.gz`, or `.zip`
- `cl` — cross-platform terminal clear
- `check_inotify` — show processes with active inotify watchers (sorted by count)

## Host detection

Several files branch on the host name — `case "$(hostname)"` in bash/zsh files, `switch (hostname)` in fish files. `Dayong` is the work PC:
- `env.sh` / `env.fish` — adds Android NDK/platform-tools/gdb + Go binary paths (Dayong only)
- `aliases.sh` / `aliases.fish` — adds `lldb` alias pointing to `/usr/bin/lldb` (Dayong only)
- `extras/conda.sh` / `extras/conda.fish` — Dayong's miniconda path

When adding host-specific config, follow the `case "$(hostname)"` (bash/zsh) or `switch (hostname)` (fish) pattern rather than hardcoding paths that don't exist on other machines.

## Aliases shadow standard commands

`aliases.sh` rebinds core commands to modern replacements: `ls→eza`, `grep→rg`, `cat→bat`, `find→fd`, `du→dust`, `cd→z` (zoxide). `cd` is **not** the builtin — use `builtin cd` or `command cd` in scripts where real `cd` behavior matters. The `claude` alias forces `--permission-mode bypassPermissions`. The same shadowing applies in fish (`config/fish/aliases.fish`); `cd` there is likewise not the builtin (it wraps zoxide's `z`).

## Scripts on PATH

`env.sh` (bash/zsh) and `env.fish` (fish) prepend `$HOME/.dotfiles/scripts` to `PATH`, so any executable script dropped in `scripts/` becomes runnable by name — the same drop-in pattern `extras/` uses for sourced inits. **Scripts are run, not sourced**: they must be executable (`chmod +x`) and self-contained. Don't add scripts that execute side effects on `source`, or every new shell will run them.

Current scripts:
- `download_and_try_parse_issues.sh` — work-related issue downloader/parser
- `extract.sh` — multi-format archive extractor (separate from the `extract` shell function)
- `skip-boot-guide` — ADB commands to skip Android setup wizard on a connected device
- `update-zen` — third-party MIT-licensed Zen Browser AppImage installer (preserve its license/credits when editing)
