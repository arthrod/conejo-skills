#!/usr/bin/env bash
# update-skills.sh — Refresh vendored skills from upstream, then publish to ~/.agents + ~/.claude.
#
# DEFAULT (publish):
#   1. Refresh vendored skills from their ORIGINAL UPSTREAM remotes
#      (via scripts/update-vendored.sh — uses `gh api github.com/<repo>`).
#      NOT from local, NOT from this repo's remote — from the original remote.
#   2. Copy  ./skills/<name>/           → ~/.agents/skills/<name>/   (overwrite)
#   3. Symlink ~/.claude/skills/<name>  → ../../.agents/skills/<name>
#      (skip if already correct; warn + skip if it's a real dir or points elsewhere)
#
# --reverse (subscribe — the OLD default):
#   Pulls the OTHER direction: ~/.claude/skills/ → ./skills/ (additive, or --yolo to wipe).
#   Regenerates marketplace.json + README.md, creates a branch, commits, pushes.
#
# Flags:
#   --reverse            subscribe: ~/.claude/skills → ./skills (additive)
#   --yolo               (subscribe only) wipe ./skills/ before re-copying
#   --skip-vendored      (publish only) skip step 1, the upstream refresh
#   --help | -h          show this help
#
# Env:
#   DRY_RUN=1            don't write, don't commit, just print what would happen
#   AGENTS_DIR=<dir>     override ~/.agents/skills   (publish target)
#   CLAUDE_DIR=<dir>     override ~/.claude/skills   (publish symlink location / subscribe source)
#   SOURCE=<dir>         (subscribe only) alias for CLAUDE_DIR
#
# Usage:
#   ./scripts/update-skills.sh                   # publish (default)
#   ./scripts/update-skills.sh --skip-vendored   # publish, skip upstream refresh
#   ./scripts/update-skills.sh --reverse         # subscribe, additive
#   ./scripts/update-skills.sh --reverse --yolo  # subscribe, wipe + replace
#   DRY_RUN=1 ./scripts/update-skills.sh         # dry run

set -euo pipefail

# ---------- args ----------
MODE="publish"           # default direction: ./skills → ~/.agents + ~/.claude
YOLO=0
SKIP_VENDORED=0
for arg in "$@"; do
  case "$arg" in
    --reverse)        MODE="subscribe" ;;
    --yolo)           YOLO=1 ;;
    --skip-vendored)  SKIP_VENDORED=1 ;;
    --help|-h)        sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ---------- config ----------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents/skills}"
CLAUDE_DIR="${CLAUDE_DIR:-${SOURCE:-$HOME/.claude/skills}}"
DRY_RUN="${DRY_RUN:-0}"

# ---------- preflight ----------
cd "$REPO_ROOT"
[ -d ".git" ]        || { echo "ERROR: $REPO_ROOT is not a git repo" >&2; exit 1; }
[ -d "$SKILLS_DIR" ] || { echo "ERROR: $SKILLS_DIR not found" >&2; exit 1; }

# Computes the relative path from $CLAUDE_DIR to $AGENTS_DIR/<name>.
rel_agents() {
  python3 -c "import os.path,sys; print(os.path.relpath(os.path.join(sys.argv[1], sys.argv[2]), sys.argv[3]))" \
    "$AGENTS_DIR" "$1" "$CLAUDE_DIR"
}

# =====================================================================
# PUBLISH MODE (default): ./skills → ~/.agents (copy) + ~/.claude (symlink)
# =====================================================================
publish() {
  if [ -n "$(git status --porcelain)" ]; then
    echo "==> WARNING: working tree is dirty. Continuing because publish only touches ./skills/"
    git status --short | head -20
    echo
  fi

  # Step 1: refresh vendored skills from upstream remotes
  if [ "$SKIP_VENDORED" = "1" ]; then
    echo "==> Step 1: --skip-vendored; skipping upstream refresh"
  elif [ ! -x "$REPO_ROOT/scripts/update-vendored.sh" ] && [ ! -f "$REPO_ROOT/scripts/update-vendored.sh" ]; then
    echo "==> Step 1: scripts/update-vendored.sh missing; skipping upstream refresh"
  else
    echo "==> Step 1: refreshing vendored skills from upstream remotes (scripts/update-vendored.sh)"
    if [ "$DRY_RUN" = "1" ]; then
      DRY_RUN=1 bash "$REPO_ROOT/scripts/update-vendored.sh" || true
    else
      bash "$REPO_ROOT/scripts/update-vendored.sh" || true
    fi
  fi

  mkdir -p "$AGENTS_DIR" "$CLAUDE_DIR"

  # Step 2: copy ./skills → ~/.agents (real files)
  echo "==> Step 2: copying ./skills/ → $AGENTS_DIR"
  local copied=0 skipped_no_skillmd=0
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    if [ ! -f "$d/SKILL.md" ]; then
      skipped_no_skillmd=$((skipped_no_skillmd+1))
      continue
    fi
    if [ "$DRY_RUN" = "1" ]; then
      echo "    DRY: copy  $name → $AGENTS_DIR/$name"
    else
      rm -rf "$AGENTS_DIR/$name"
      cp -r "$d" "$AGENTS_DIR/$name"
    fi
    copied=$((copied+1))
  done
  echo "    Copied: $copied"
  [ "$skipped_no_skillmd" -gt 0 ] && echo "    Skipped (no SKILL.md): $skipped_no_skillmd"

  # Step 3: symlink ~/.claude/skills/<name> → <relative>/.agents/skills/<name>
  echo "==> Step 3: symlinking $CLAUDE_DIR/<name> → $AGENTS_DIR/<name>"
  local linked=0 already=0 warned=0
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    [ -f "$d/SKILL.md" ] || continue

    target="$CLAUDE_DIR/$name"
    want="$(rel_agents "$name")"

    if [ -L "$target" ]; then
      current="$(readlink "$target")"
      if [ "$current" = "$want" ]; then
        already=$((already+1))
        continue
      fi
      echo "    RETARGET  $name  ('$current' → '$want')"
      if [ "$DRY_RUN" != "1" ]; then
        rm -f "$target"
        ln -s "$want" "$target"
      fi
      linked=$((linked+1))
      continue
    fi

    if [ -e "$target" ]; then
      echo "    WARN  $target exists and is not a symlink; skipping (resolve manually)"
      warned=$((warned+1))
      continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
      echo "    DRY: link  $name → $want"
    else
      ln -s "$want" "$target"
    fi
    linked=$((linked+1))
  done
  echo "    Linked: $linked"
  echo "    Already correct: $already"
  [ "$warned" -gt 0 ] && echo "    Warnings (resolve manually): $warned"

  # Step 4: vendored refresh may have left ./skills/ dirty — surface it, don't auto-commit
  if [ -n "$(git status --porcelain skills)" ]; then
    echo
    echo "==> NOTE: ./skills/ has uncommitted changes from the vendored refresh."
    echo "    Review with:  git status skills/  &&  git diff skills/"
    echo "    Commit with:  git add skills && git commit -m 'chore(skills): refresh vendored from upstream'"
  fi

  echo
  echo "==> Publish complete"
  echo "    ./skills/        → $AGENTS_DIR/   (copies)"
  echo "    $CLAUDE_DIR/ → $AGENTS_DIR/   (symlinks)"
}

# =====================================================================
# SUBSCRIBE MODE (--reverse): ~/.claude/skills → ./skills
# =====================================================================
subscribe() {
  if [ ! -d "$CLAUDE_DIR" ]; then
    echo "ERROR: source skills directory not found: $CLAUDE_DIR" >&2
    exit 1
  fi
  if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: working tree is dirty. Commit or stash first:" >&2
    git status --short >&2
    exit 1
  fi

  echo "==> Mode: subscribe (--reverse)   Source: $CLAUDE_DIR"
  echo "==> Fetching origin"
  git fetch origin --quiet

  RAND_SUFFIX="$(date +%Y%m%d-%H%M%S)-$(LC_ALL=C head -c 32 /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | cut -c1-6)"
  BRANCH="update-skills-$RAND_SUFFIX"
  echo "==> Creating branch: $BRANCH (from origin/main)"
  git checkout -B "$BRANCH" origin/main

  mkdir -p skills

  local copied=0 skipped_no_skillmd=0 skipped_exists=0
  if [ "$YOLO" = "1" ]; then
    existing_count=$(ls -d skills/*/ 2>/dev/null | wc -l)
    echo "==> --yolo: WIPING $existing_count existing skills"
    if [ "$existing_count" -gt 0 ]; then
      echo "    sample: $(ls -d skills/*/ | head -5 | xargs -n1 basename | tr '\n' ' ')..."
    fi
    rm -rf skills
    mkdir -p skills
  fi

  echo "==> Copying from $CLAUDE_DIR (following symlinks)"
  for d in "$CLAUDE_DIR"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    if [ ! -f "$d/SKILL.md" ]; then
      skipped_no_skillmd=$((skipped_no_skillmd+1))
      continue
    fi
    if [ "$YOLO" = "0" ] && [ -d "skills/$name" ]; then
      skipped_exists=$((skipped_exists+1))
      continue
    fi
    cp -rL "$d" "skills/$name"
    copied=$((copied+1))
  done

  echo "    Copied: $copied"
  [ "$skipped_exists" -gt 0 ]    && echo "    Skipped (already exist, additive): $skipped_exists"
  [ "$skipped_no_skillmd" -gt 0 ] && echo "    Skipped (no SKILL.md): $skipped_no_skillmd"

  TOTAL=$(ls -d skills/*/ 2>/dev/null | wc -l)
  echo "    Total skills now in ./skills/: $TOTAL"

  regen_manifest_and_readme

  if [ "$DRY_RUN" = "1" ]; then
    echo "==> DRY_RUN=1: skipping commit/push"
    echo "    Changes are staged in branch $BRANCH; review with 'git status' and 'git diff'"
    exit 0
  fi

  git add -A skills .claude-plugin/marketplace.json README.md
  if git diff --cached --quiet; then
    echo "==> No changes to commit (probably additive mode found nothing new)"
    exit 0
  fi

  SKILL_COUNT=$(ls -d skills/*/ 2>/dev/null | wc -l)
  SUBMODE=$([ "$YOLO" = "1" ] && echo "yolo" || echo "additive")
  COMMIT_MSG="sync(subscribe/$SUBMODE): $SKILL_COUNT skills from \$CLAUDE_DIR

Mode: subscribe (--reverse), $SUBMODE
Source: $CLAUDE_DIR
Branch: $BRANCH
Synced: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Copied this run: $copied
"

  echo "==> Committing"
  git commit -m "$COMMIT_MSG"
  echo "==> Pushing to origin $BRANCH"
  git push -u origin "$BRANCH"

  echo
  echo "==> Done"
  echo "    Branch: $BRANCH"
  echo "    PR:     gh pr create --base main --head $BRANCH --title 'sync(subscribe/$SUBMODE): $SKILL_COUNT skills' --body 'Auto-sync from $CLAUDE_DIR'"
}

# ---------- regenerate marketplace.json + README.md (subscribe mode only) ----------
regen_manifest_and_readme() {
  echo "==> Regenerating .claude-plugin/marketplace.json"
  python3 - <<'PYEOF'
import json
from pathlib import Path

repo = Path(".")
skills_dir = repo / "skills"
manifest_path = repo / ".claude-plugin" / "marketplace.json"

skills = sorted(d.name for d in skills_dir.iterdir() if d.is_dir() and (d / "SKILL.md").is_file())

manifest = {
    "name": "arthrod-skills",
    "owner": {"name": "arthrod", "email": "arthursrodrigues@gmail.com"},
    "metadata": {
        "description": "arthrod's curated skill set — Pydantic AI, Plate/DOCX, Tauri/better-auth, Rust, Pi terminal agent, GLiNER training, design family with Stitch-first mandate, Conejo PR workflow.",
        "version": "2.0.0",
    },
    "plugins": [
        {
            "name": "arthrod-skills",
            "description": f"All {len(skills)} skills as one bundle. See README.md for the family map.",
            "source": "./",
            "strict": False,
            "skills": [f"./skills/{s}" for s in skills],
        }
    ],
}

manifest_path.parent.mkdir(exist_ok=True)
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
print(f"    wrote {manifest_path} with {len(skills)} skills")
PYEOF

  echo "==> Regenerating README.md"
  MODE="subscribe" python3 - <<'PYEOF'
import os, re
from datetime import date
from pathlib import Path

repo = Path(".")
skills_dir = repo / "skills"
skills = sorted(d for d in skills_dir.iterdir() if d.is_dir() and (d / "SKILL.md").is_file())

def desc(p: Path) -> str:
    text = p.read_text()
    m = re.search(r"^description:\s*(.+?)(?:\n\w|\n---|\Z)", text, re.MULTILINE | re.DOTALL)
    if not m:
        return "_(no description)_"
    s = " ".join(m.group(1).split()).strip("\"' ")
    return s[:220] + "…" if len(s) > 220 else s

FAMILIES = {
    "PR / code review workflow": ["conejo", "proud-zanahoria", "zanahoria-plans", "zanahoria-multi-assumptions", "zanahoria-decisions", "receiving-code-review", "requesting-code-review"],
    "Design (Stitch-first)": ["impeccable", "ui-ux-pro-max", "ux-design-brief", "shadcn-parity", "stitch-design-taste", "refine-distill-frontend", "increase-impact-personality-frontend", "typeset", "adapt", "layout", "colorize"],
    "Pydantic AI": ["pydantic-ai-agent-builder", "pydanticai-docs", "pydantic-ai-common-pitfalls", "pydantic-ai-testing"],
    "Better Auth": ["better-auth", "better-auth-best-practices", "better-auth-security", "better-auth-providers", "better-auth-explain-error", "better-auth-tauri-setup", "better-auth-tauri-pitfalls"],
    "Rust": ["rust-author", "rust-review"],
    "Pi terminal agent": ["pi-using", "pi-extending"],
    "Testing / QA": ["testing-strategy", "testing-review", "plate-testing-strategy", "browser-test-agent", "desktop-test-agent-tauri", "dogfood", "dogfood-quirks"],
    "AI SDKs / Agents": ["llm-chat-sdks", "ag-ui-copilotkit", "ag-ui-pydantic", "mcp-builder", "agent-architecture-analysis", "computer-use-agents", "orchestrating-swarms", "deepagents"],
    "ML / GPU": ["ml-gpu-training"],
    "i18n / Docs / Blog / Releases": ["i18n-inlang-localization", "blog-handoff", "blog-writing", "adr", "changeset", "pr-docx"],
    "Process discipline (local copies — also exist in superpowers plugin)": ["brainstorming", "writing-plans", "executing-plans", "subagent-driven-development", "dispatching-parallel-agents", "systematic-debugging", "verification-before-completion", "test-driven-development", "using-superpowers", "using-git-worktrees", "writing-skills", "finishing-a-development-branch"],
    "Frontend stacks": ["react", "react-best-practices", "react-composables", "tailwind-v4", "tanstack-router", "tanstack-router-best-practices", "hono"],
    "Infra / env / sandbox / Val Town": ["env-dogma", "val-town", "agent-sandbox"],
}
known = {s for ss in FAMILIES.values() for s in ss}
all_names = {d.name for d in skills}
FAMILIES["Other"] = sorted(all_names - known)

today = date.today().isoformat()
mode = os.environ.get("MODE", "subscribe")

out = [
    "# arthrod's Skill Registry",
    "",
    f"**{len(skills)} skills** — last sync `{today}` ({mode} mode). **v2.0.0**",
    "",
    "Major restructure: families collapsed (Pi → 2 skills, Pydantic AI → 1 with `references/`,",
    "Rust → `rust-author` + `rust-review`, Better Auth slimmed, design dials folded into `impeccable`),",
    "new combined skills (`conejo` absorbs code-review + autofix + pr-triage-gh, `marimo` absorbs 4",
    "marimo skills, `ml-gpu-training` absorbs CUDA setup). All design tools include a Stitch-first",
    "mandate (`STITCH-DESIGN.md` in each design-skill folder).",
    "",
    "## Sync",
    "",
    "```bash",
    "./scripts/update-skills.sh                   # publish (default): refresh vendored from upstream,",
    "                                             #                   then ./skills/ → ~/.agents + ~/.claude",
    "./scripts/update-skills.sh --skip-vendored   # publish, skip the upstream refresh step",
    "./scripts/update-skills.sh --reverse         # subscribe: ~/.claude/skills → ./skills/ (additive)",
    "./scripts/update-skills.sh --reverse --yolo  # subscribe, wipe ./skills/ first",
    "DRY_RUN=1 ./scripts/update-skills.sh         # dry run, no writes anywhere",
    "```",
    "",
    "## Install",
    "",
    "```bash",
    "/plugin marketplace add arthrod/conejo-skills",
    "/plugin install arthrod-skills",
    "```",
    "",
    "## Family Map",
    "",
    "| Family | Skills |",
    "|---|---|",
]

for fam, names in FAMILIES.items():
    present = [n for n in names if n in all_names]
    if present:
        out.append(f"| **{fam}** | {', '.join(f'`{n}`' for n in present)} |")

out += ["", "## Full Index", ""]
for d in skills:
    out.append(f"### `{d.name}`")
    out.append("")
    out.append(desc(d / "SKILL.md"))
    out.append("")

(repo / "README.md").write_text("\n".join(out) + "\n")
print(f"    wrote README.md ({len(skills)} skills indexed)")
PYEOF
}

# ---------- dispatch ----------
case "$MODE" in
  publish)   publish ;;
  subscribe) subscribe ;;
esac
