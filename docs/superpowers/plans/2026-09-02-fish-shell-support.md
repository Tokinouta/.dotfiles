# Fish Shell Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fish-shell configuration tree (`config/fish/`) that mirrors the bash/zsh setup, loaded via a one-line `~/.config/fish/config.fish`, with zero changes to the existing POSIX chain.

**Architecture:** Fish is not POSIX-compatible and never reads `~/.bashrc`/`~/.zshrc`, so it gets a parallel fish-syntax tree in the repo. `~/.config/fish/config.fish` (host) sources `config/fish/init.fish`, which — in interactive sessions only — loads `env.fish`, `aliases.fish`, `functions.fish`, `extras/*.fish` (globbed), then `post-init.fish`. The bash/zsh chain under `config/shell/` is untouched.

**Tech Stack:** fish 4.2.1 (host Dayong), starship, zoxide, conda (fish hook), git. No test framework — verification is shell-based checks (`fish -n`, `fish -i -c`, `bash -ic`, `git diff`).

**Spec:** `docs/superpowers/specs/2026-09-02-fish-shell-support-design.md` — the plan argues from the spec; executors read both.

## Global Constraints

- **Zero modifications** to `config/shell/**`, `~/.bashrc`, or any existing `*.sh` file. Bash/zsh stay byte-identical — proven in Task 7 via `git diff a71d401..HEAD --stat -- config/shell/` printing nothing (`a71d401` was HEAD before this feature).
- All new fish files live under `config/fish/` and are **pure fish syntax**; fish never sources anything POSIX.
- nvm and openclaw get **no fish port** (spec decision).
- Host fish dirs (`~/.config/fish/{conf.d,functions,completions,fish_variables}`) remain untouched; only the content of `~/.config/fish/config.fish` is replaced (Task 6).
- `extras/*.fish` must stay auto-discovered by glob — no `init.fish` edit needed for new tools.
- Every `fish_add_path` call in config files uses `--path` (session-scoped `$PATH` writes only — never the default persistent `fish_user_paths`, which would bake per-host state that survives config edits). See the spec's "fish_add_path semantics" section.
- Repo has no test framework. "Tests" are the explicit verification commands with expected outputs in each task. **TDD note:** for config files the cycle is write → syntax-check (`fish -n`) → functional check → commit; there is no failing-test-first step because the artifact is configuration, not code.
- Commit style: `feat(fish): ...` / `docs: ...`, each ending with `Co-Authored-By: Claude Code <noreply@anthropic.com>`. Commit to the current branch (`main`), matching this repo's convention.
- Host facts (verified 2026-09-02): hostname is `Dayong`, fish 4.2.1, zsh not installed, all `env.sh` PATH dirs exist under `$HOME`, `~/.bun` does not exist, miniconda at `/home/dayong/workspace/others/miniconda3`, starship + zoxide + conda installed.

---

### Task 1: `config/fish/env.fish`

**Files:**
- Create: `config/fish/env.fish`

**Interfaces:**
- Consumes: nothing (first file in the chain).
- Produces: exported `EDITOR`, `PAGER`; PATH entries prepended in this order (last call ends up first): `~/.local/bin`, `~/.dotfiles/scripts`, Android SDK chain, `~/go/bin`. Later tasks assume `env.fish` is idempotent and safe to source repeatedly.

- [ ] **Step 1: Create `config/fish/env.fish`**

```fish
# Common environment variables
set -gx EDITOR nvim
set -gx PAGER bat

# Expose scripts shipped with the dotfiles (e.g. update-zen) as commands.
# Scripts here must be executable and self-contained — they are run, not sourced.
# fish_add_path --path prepends to $PATH only (no persistent fish_user_paths
# state) and is idempotent. Single-entry exports in env.sh map to single
# calls; env.sh's grouped Android export maps to one multi-arg call that
# keeps the group's line order — reproducing bash's final PATH order exactly.
fish_add_path --path ~/.local/bin
fish_add_path --path ~/.dotfiles/scripts

# Android tools (Linux work PC only)
switch (hostname)
    case Dayong
        # env.sh prepends this group in one export, so keep the group's line
        # order with a single multi-arg call (argument order is preserved).
        fish_add_path --path ~/android-sdk-linux/ndk/28.0.13004108/toolchains/llvm/prebuilt/linux-x86_64/bin ~/android-sdk-linux/platform-tools ~/android-sdk-linux/tools ~/android-sdk-linux/build-tools/33.0.0 ~/installed_softwares/gdb-11-xiaomi/bin
        # add go binary path to $PATH
        fish_add_path --path ~/go/bin
end
```

- [ ] **Step 2: Syntax check**

Run: `fish -n ~/.dotfiles/config/fish/env.fish && echo syntax-ok`
Expected: `syntax-ok`

- [ ] **Step 3: Functional check (scrubbed PATH for determinism)**

Run:
```bash
fish -c 'set -gx PATH /usr/bin:/bin; source ~/.dotfiles/config/fish/env.fish; echo $EDITOR; echo $PAGER; printf "%s\n" $PATH'
```
Expected (exactly, on host Dayong — every dir exists so nothing is skipped):
```
nvim
bat
/home/dayong/go/bin
/home/dayong/android-sdk-linux/ndk/28.0.13004108/toolchains/llvm/prebuilt/linux-x86_64/bin
/home/dayong/android-sdk-linux/platform-tools
/home/dayong/android-sdk-linux/tools
/home/dayong/android-sdk-linux/build-tools/33.0.0
/home/dayong/installed_softwares/gdb-11-xiaomi/bin
/home/dayong/.dotfiles/scripts
/home/dayong/.local/bin
/usr/bin
/bin
```
This also proves the PATH *order* matches bash's `env.sh` result exactly: env.sh prepends local/bin, then scripts, then the Android group (ndk→gdb) in one export, then go — so go ends up first and the group keeps its line order. `bash -ic 'echo $PATH'` shows the same sequence.

- [ ] **Step 4: Commit**

```bash
git add config/fish/env.fish
git commit -m "feat(fish): add env.fish (PATH, EDITOR/PAGER, host-specific paths)

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: `config/fish/aliases.fish` + `config/fish/functions.fish`

**Files:**
- Create: `config/fish/aliases.fish`
- Create: `config/fish/functions.fish`

**Interfaces:**
- Consumes: nothing at definition time. `alias cd 'z'` resolves `z` lazily at call time — `z` is defined later by `post-init.fish` (Task 5), which is fine.
- Produces: functions `ls`, `ll`, `grep`, `cat`, `find`, `du`, `cd` (wraps `z`), `..`, `...`, `lldb` (Dayong only), `claude`, `extract`, `cl`, `check_inotify`.

- [ ] **Step 1: Create `config/fish/aliases.fish`**

```fish
# Aliases for modern replacements
alias ls 'eza --group-directories-first'
alias ll 'eza -lah --git'
alias grep 'rg'
alias cat 'bat'
alias find 'fd'
alias du 'dust'
alias cd 'z'
alias .. 'cd ..'
alias ... 'cd ../..'

# Host-specific aliases
switch (hostname)
    case Dayong
        alias lldb '/usr/bin/lldb'
end

alias claude 'claude --permission-mode bypassPermissions'
```

- [ ] **Step 2: Create `config/fish/functions.fish`**

```fish
# Extract files
function extract
    switch $argv[1]
        case '*.tar.bz2'
            tar xjf $argv[1]
        case '*.tar.gz'
            tar xzf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*'
            echo "Cannot extract '$argv[1]'"
    end
end

# Cross-platform clear
function cl
    if type -q clear
        clear
    else
        printf '\033c'
    end
end

# Check inotify watchers
function check_inotify
    lsof | awk '/inotify$/ {print $1, $2}' | sort | uniq -c | sort -nr
end
```

- [ ] **Step 3: Syntax check both files**

Run: `fish -n ~/.dotfiles/config/fish/aliases.fish && fish -n ~/.dotfiles/config/fish/functions.fish && echo syntax-ok`
Expected: `syntax-ok`

- [ ] **Step 4: Functional check — all names defined as functions**

Run:
```bash
fish -i -c 'source ~/.dotfiles/config/fish/aliases.fish; source ~/.dotfiles/config/fish/functions.fish; for f in ls cd .. ... lldb claude extract cl check_inotify; functions -q $f; and echo $f-ok; end'
```
Expected (fish `alias` creates functions, so `functions -q` is the right probe; `lldb-ok` appears only on host Dayong):
```
ls-ok
cd-ok
..-ok
...-ok
lldb-ok
claude-ok
extract-ok
cl-ok
check_inotify-ok
```

- [ ] **Step 5: Verify alias bodies wrap the right commands**

Run:
```bash
fish -i -c 'source ~/.dotfiles/config/fish/aliases.fish; functions ls; functions claude'
```
Expected: output contains `eza --group-directories-first` and `--permission-mode bypassPermissions`.

- [ ] **Step 6: Commit**

```bash
git add config/fish/aliases.fish config/fish/functions.fish
git commit -m "feat(fish): add aliases.fish and functions.fish

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: Simple extras — `cargo.fish`, `bun.fish`, `brew.fish`

**Files:**
- Create: `config/fish/extras/cargo.fish`
- Create: `config/fish/extras/bun.fish`
- Create: `config/fish/extras/brew.fish`

**Interfaces:**
- Consumes: nothing.
- Produces: exported `RUSTUP_UPDATE_ROOT`, `RUSTUP_DIST_SERVER`, `~/.cargo/bin` on PATH (cargo); `~/.bun/bin` on PATH when it exists (bun); `HOMEBREW_*` exports on macOS only (brew).

- [ ] **Step 1: Create `config/fish/extras/cargo.fish`**

```fish
# modify rustup source and add cargo to PATH
# (~/.cargo/env is POSIX; its only effect is this PATH entry)
set -gx RUSTUP_UPDATE_ROOT "https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
set -gx RUSTUP_DIST_SERVER "https://mirrors.tuna.tsinghua.edu.cn/rustup"
fish_add_path --path ~/.cargo/bin
```

- [ ] **Step 2: Create `config/fish/extras/bun.fish`**

```fish
# JavaScript runtimes: bun
# fish_add_path --path skips non-existent dirs, so a missing ~/.bun can't pollute PATH
fish_add_path --path ~/.bun/bin
```

- [ ] **Step 3: Create `config/fish/extras/brew.fish`**

```fish
# Homebrew (macOS only) — brew shellenv emits POSIX syntax, so translate manually
if test (uname -s) = Darwin; and test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX "/opt/homebrew"
    set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar"
    set -gx HOMEBREW_REPOSITORY "/opt/homebrew"
    fish_add_path --path /opt/homebrew/bin /opt/homebrew/sbin
    set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirror.nju.edu.cn/git/homebrew/brew.git"
    set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git"
    fish_add_path --path /opt/homebrew/opt/ffmpeg-full/bin
end
```

- [ ] **Step 4: Syntax check all three**

Run: `for f in ~/.dotfiles/config/fish/extras/cargo.fish ~/.dotfiles/config/fish/extras/bun.fish ~/.dotfiles/config/fish/extras/brew.fish; do fish -n "$f" || exit 1; done && echo syntax-ok`
Expected: `syntax-ok`

- [ ] **Step 5: Functional check — cargo (scrubbed PATH)**

Run:
```bash
fish -c 'set -gx PATH /usr/bin:/bin; source ~/.dotfiles/config/fish/extras/cargo.fish; printf "%s\n" $PATH | head -3; echo $RUSTUP_DIST_SERVER; echo $RUSTUP_UPDATE_ROOT'
```
Expected:
```
/home/dayong/.cargo/bin
/usr/bin
/bin
https://mirrors.tuna.tsinghua.edu.cn/rustup
https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
```

- [ ] **Step 6: Functional check — bun skips missing dir, brew is a Linux no-op**

Run:
```bash
fish -c 'set -gx PATH /usr/bin:/bin; source ~/.dotfiles/config/fish/extras/bun.fish; contains ~/.bun/bin $PATH; and echo bun-present; or echo bun-absent'
fish -c 'source ~/.dotfiles/config/fish/extras/brew.fish; echo status=$status; set -q HOMEBREW_PREFIX; and echo homebrew-set; or echo homebrew-not-set'
```
Expected (on this Linux host, `~/.bun` does not exist):
```
bun-absent
status=0
homebrew-not-set
```

- [ ] **Step 7: Commit**

```bash
git add config/fish/extras/cargo.fish config/fish/extras/bun.fish config/fish/extras/brew.fish
git commit -m "feat(fish): add cargo, bun, brew extras

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: `config/fish/extras/conda.fish`

**Files:**
- Create: `config/fish/extras/conda.fish`

**Interfaces:**
- Consumes: `$HOME`, `hostname`.
- Produces: `conda` function (via conda's official fish hook) when a conda base is found; nothing otherwise. No fallback to POSIX `profile.d/conda.sh` (it is bash syntax; conda on this host is modern — spec: YAGNI).

- [ ] **Step 1: Create `config/fish/extras/conda.fish`**

```fish
# >>> conda initialize >>>
# Host-specific conda paths
set -l CONDA_BASE ""
switch (hostname)
    case Dayong
        set CONDA_BASE /home/dayong/workspace/others/miniconda3
    case '*'
        # macOS / other hosts — try common locations
        if test -d "$HOME/miniconda3"
            set CONDA_BASE "$HOME/miniconda3"
        else if test -d "$HOME/anaconda3"
            set CONDA_BASE "$HOME/anaconda3"
        else if test -d /opt/miniconda3
            set CONDA_BASE /opt/miniconda3
        end
end

# conda's official fish hook (same shape `conda init fish` generates)
if test -n "$CONDA_BASE"; and test -x "$CONDA_BASE/bin/conda"
    eval "$CONDA_BASE/bin/conda" "shell.fish" "hook" | source
end
# <<< conda initialize <<<
```

- [ ] **Step 2: Syntax check**

Run: `fish -n ~/.dotfiles/config/fish/extras/conda.fish && echo syntax-ok`
Expected: `syntax-ok`

- [ ] **Step 3: Functional check — hook loads and conda works**

Run:
```bash
fish -i -c 'source ~/.dotfiles/config/fish/extras/conda.fish; functions -q conda; and echo conda-function-ok; conda info --base'
```
Expected:
```
conda-function-ok
/home/dayong/workspace/others/miniconda3
```

- [ ] **Step 4: Functional check — env activation works**

Run:
```bash
fish -i -c 'source ~/.dotfiles/config/fish/extras/conda.fish; conda activate base; echo $CONDA_DEFAULT_ENV'
```
Expected: `base`

- [ ] **Step 5: Commit**

```bash
git add config/fish/extras/conda.fish
git commit -m "feat(fish): add conda extra with host detection

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: `config/fish/post-init.fish`

**Files:**
- Create: `config/fish/post-init.fish`

**Interfaces:**
- Consumes: `starship` and `zoxide` on PATH (guarded with `command -q`); the `cd` alias from `aliases.fish` (Task 2) resolves the `z` this file defines — lazily, so definition order does not matter.
- Produces: starship-managed `fish_prompt`/`fish_right_prompt` plus exported `STARSHIP_SHELL` (modern starship no longer defines a `starship_prompt` function), and `z`/`zi` functions (zoxide). Verified fact from zoxide's generated code: it defines `__zoxide_cd_internal` (a copy of fish's internal `cd`) precisely so `alias cd=z` cannot loop.

- [ ] **Step 1: Create `config/fish/post-init.fish`**

```fish
# These depend on anything being loaded before initializing themselves

# Starship prompt
command -q starship; and starship init fish | source

# zoxide init (defines z; aliases.fish maps cd to it)
command -q zoxide; and zoxide init fish | source
```

- [ ] **Step 2: Syntax check**

Run: `fish -n ~/.dotfiles/config/fish/post-init.fish && echo syntax-ok`
Expected: `syntax-ok`

- [ ] **Step 3: Functional check — both inits load, and `cd` does not recurse**

Run:
```bash
fish -i -c 'source ~/.dotfiles/config/fish/aliases.fish; source ~/.dotfiles/config/fish/post-init.fish; set -q STARSHIP_SHELL; and echo starship-ok; functions -q z; and echo z-ok; cd /tmp; and pwd'
```
Expected:
```
starship-ok
z-ok
/tmp
```
If `cd` recursed, zoxide would print `zoxide: infinite loop detected` and the command would fail — reaching `/tmp` proves the no-recursion guarantee.

- [ ] **Step 4: Commit**

```bash
git add config/fish/post-init.fish
git commit -m "feat(fish): add post-init.fish for starship and zoxide

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: `config/fish/init.fish` + host `~/.config/fish/config.fish` wiring

**Files:**
- Create: `config/fish/init.fish` (repo)
- Modify: `~/.config/fish/config.fish` (host, **outside the repo** — replace the 3-line default stub `if status is-interactive ... end`; not committed to git)

**Interfaces:**
- Consumes: every file from Tasks 1–5.
- Produces: the complete fish load chain. `SHELL_TYPE` is exported as `fish` unconditionally (parity with `init.sh`; a bash child shell re-detects via its own `~/.bashrc`).

- [ ] **Step 1: Create `config/fish/init.fish`**

```fish
# Dotfiles main entry point — fish config (bash/zsh live in config/shell/)
# Fish cannot source POSIX scripts, so it gets its own parallel tree.
set -gx SHELL_TYPE fish

if status is-interactive
    set -l DOTFILES "$HOME/.dotfiles/config/fish"

    for file in env aliases functions
        test -f "$DOTFILES/$file.fish"; and source "$DOTFILES/$file.fish"
    end

    # Load extras (like conda, cargo, etc.)
    for file in "$DOTFILES"/extras/*.fish
        test -f "$file"; and source "$file"
    end

    test -f "$DOTFILES/post-init.fish"; and source "$DOTFILES/post-init.fish"
end
```

Note: if `extras/` has no `.fish` files, the glob stays literal, `test -f` fails, and it is skipped — same safety net as `init.sh`.

- [ ] **Step 2: Replace host `~/.config/fish/config.fish` content**

Write exactly this as the entire file content (replacing the default `if status is-interactive` stub):

```fish
source $HOME/.dotfiles/config/fish/init.fish
```

- [ ] **Step 3: Syntax check**

Run: `fish -n ~/.dotfiles/config/fish/init.fish && echo syntax-ok`
Expected: `syntax-ok`

- [ ] **Step 4: Integration check — full interactive chain**

Run:
```bash
fish -i -c 'echo SHELL_TYPE=$SHELL_TYPE; for f in ls cd .. ... lldb claude extract cl check_inotify z conda; functions -q $f; and echo $f-ok; end; set -q STARSHIP_SHELL; and echo starship-ok'
```
Expected (11 function `-ok` lines plus `starship-ok`, which probes the `STARSHIP_SHELL` env var — modern starship defines `fish_prompt`/`fish_right_prompt`, not `starship_prompt`; `lldb-ok` is Dayong-only):
```
SHELL_TYPE=fish
ls-ok
cd-ok
..-ok
...-ok
lldb-ok
claude-ok
extract-ok
cl-ok
check_inotify-ok
z-ok
conda-ok
starship-ok
```

- [ ] **Step 5: Integration check — interactive guard and PATH**

Run:
```bash
fish -c 'echo SHELL_TYPE=$SHELL_TYPE; functions -q extract; or echo no-functions-noninteractive'
fish -i -c 'set -l p (string join : $PATH); string match -q "*go/bin*ndk/28.0.13004108*platform-tools*android-sdk-linux/tools*build-tools/33.0.0*gdb-11-xiaomi*dotfiles/scripts*.local/bin*" $p; and echo path-order-ok; contains ~/.cargo/bin $PATH; and echo cargo-ok'
```
Expected:
```
SHELL_TYPE=fish
no-functions-noninteractive
path-order-ok
cargo-ok
```

- [ ] **Step 6: Startup time sanity**

Run:
```bash
time fish -i -c exit
time bash -ic exit
```
Expected: same ballpark (the conda hook dominates both); record both numbers. No hard threshold — this catches gross regressions like accidentally re-running init loops.

- [ ] **Step 7: Commit (repo file only — the host file is not in git)**

```bash
git add config/fish/init.fish
git commit -m "feat(fish): add init.fish entry point and wire host config.fish

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: Update `CLAUDE.md` + final regression

**Files:**
- Modify: `CLAUDE.md` (repo root)

**Interfaces:**
- Consumes: everything from Tasks 1–6 (documents them).
- Produces: accurate project instructions for both shell trees.

- [ ] **Step 1: Update the "What this is" section**

Replace the first paragraph:

> Universal shell dotfiles (bash, zsh, extensible to other shells). The repo is cloned/symlinked at `~/.dotfiles` and sourced live by `~/.bashrc` and `~/.zshrc` — there is no build, test, or lint step. Changes take effect by opening a new shell or re-sourcing the appropriate rc file.

with:

> Universal shell dotfiles (bash, zsh, fish). The repo is cloned/symlinked at `~/.dotfiles` and sourced live by `~/.bashrc`, `~/.zshrc`, and `~/.config/fish/config.fish` — there is no build, test, or lint step. Changes take effect by opening a new shell or re-sourcing the appropriate rc file. Bash and zsh share the POSIX chain under `config/shell/`; fish is not POSIX-compatible and loads a parallel fish-syntax tree from `config/fish/` (see "Load order").

- [ ] **Step 2: Rewrite the "Shell detection" section**

Replace the whole section (current text: "`config/shell/init.sh` detects the running shell … add its detection in `init.sh` and guard shell-specific code with `if [ "$SHELL_TYPE" = "fish" ]`.") with:

> `config/shell/init.sh` detects the running shell at startup and exports `SHELL_TYPE` (`bash` or `zsh`). All downstream POSIX files use this variable to branch on shell-specific behavior (e.g., `shopt` for bash, `setopt` for zsh). `config/fish/init.fish` sets `SHELL_TYPE=fish` itself — fish never sources `init.sh`, because fish is not POSIX-compatible and does not read `~/.bashrc`/`~/.zshrc`.
>
> To add support for a new POSIX shell (e.g. ksh), add its detection in `init.sh` and guard shell-specific code with `if [ "$SHELL_TYPE" = "ksh" ]`. A non-POSIX shell (like fish) cannot reuse `init.sh` — it needs a parallel tree under `config/<shell>/` plus a one-line host rc file sourcing its init.

- [ ] **Step 3: Extend the "Load order" section**

After the existing numbered list (items 1–5), replace the paragraph:

> To add a new tool's shell integration, drop a new `config/shell/extras/<tool>.sh` — `init.sh` picks it up automatically via glob. No edit to `init.sh` needed.

with:

> Fish loads a parallel chain: `~/.config/fish/config.fish` sources `config/fish/init.fish`, which — in interactive sessions only — loads `config/fish/env.fish`, `config/fish/aliases.fish`, `config/fish/functions.fish`, `config/fish/extras/*.fish` (auto-globbed, same drop-in pattern), then `config/fish/post-init.fish`. Non-interactive fish only gets `SHELL_TYPE=fish`.
>
> To add a new tool's shell integration, drop `config/shell/extras/<tool>.sh` (bash/zsh) and/or `config/fish/extras/<tool>.fish` (fish) — the globs pick them up automatically. No edit to either init file is needed.

- [ ] **Step 4: Update the "Tool ecosystem" table**

Replace the table (also correcting stale `env.sh` values from the recent starship/cargo/bun extractions) with:

> | Tool | Where | Purpose |
> |------|-------|---------|
> | starship | `post-init.sh` / `post-init.fish` | Prompt (minimal config in `starship.toml`) |
> | zoxide | `post-init.sh` / `post-init.fish` | `z`/`cd` jump (`cd` aliased to `z` in both `aliases.sh` and `aliases.fish`) |
> | cargo/rustup | `extras/cargo.sh` / `extras/cargo.fish` | Rust toolchain (mirrored via Tsinghua) |
> | brew | `extras/brew.sh` / `extras/brew.fish` | Homebrew (macOS only) |
> | bun | `extras/bun.sh` / `extras/bun.fish` | JavaScript runtime |
> | conda | `extras/conda.sh` / `extras/conda.fish` | Python environment management |
> | nvm | `extras/nvm.sh` (bash/zsh only) | Node.js version management — nvm has no fish support |
>
> `starship.toml` lives in the repo but is **not** symlinked into `$HOME` — starship finds it via its own lookup path.

- [ ] **Step 5: Touch up the remaining sections**

- "Shell functions" intro line → `Defined in `config/shell/functions.sh` (bash/zsh) and `config/fish/functions.fish` (fish):`
- "Host detection" intro line → `Several files branch on the host name — `case "$(hostname)"` in bash/zsh files, `switch (hostname)` in fish files. `Dayong` is the work PC:` and append a third bullet: `- `extras/conda.sh` / `extras/conda.fish` — Dayong's miniconda path`
- "Aliases shadow standard commands" — append: `The same shadowing applies in fish (`config/fish/aliases.fish`); `cd` there is likewise not the builtin (it wraps zoxide's `z`).`
- "Scripts on PATH" first sentence → `` `env.sh` (bash/zsh) and `env.fish` (fish) prepend `$HOME/.dotfiles/scripts` to `PATH`, so any executable script dropped in `scripts/` becomes runnable by name — the same drop-in pattern `extras/` uses for sourced inits. ``

- [ ] **Step 6: Final regression — bash untouched and working**

Run:
```bash
bash -ic 'echo $SHELL_TYPE; type extract | head -1; echo $EDITOR $PAGER'
```
Expected:
```
bash
extract is a function
nvim bat
```

- [ ] **Step 7: Final regression — structural no-break proof**

Run:
```bash
git status --porcelain
git diff a71d401..HEAD --stat -- config/shell/ scripts/ starship.toml README.md
```
Expected: first command prints nothing (working tree clean — everything committed); second prints nothing (zero changes to the bash/zsh chain, scripts, starship config, or README since `a71d401`, the pre-feature HEAD).

- [ ] **Step 8: Final regression — zsh**

Run: `command -v zsh || echo zsh-not-installed`
Expected: `zsh-not-installed` on this host — nothing to functionally test; the structural guarantee from Step 7 (zero edits under `config/shell/`) covers zsh, and no `~/.zshrc` exists here.

- [ ] **Step 9: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: document fish tree in CLAUDE.md

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Post-Implementation

No build/deploy step — the config is live the moment files land (fish picks up `config/fish/` on the next shell start). Optional manual smoke test for the user: open a new fish shell and confirm the starship prompt renders and `z <dir>` jumps.
