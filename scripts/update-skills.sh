#!/usr/bin/env bash
# update-skills.sh — Sync ~/.claude/skills/ → ./skills/, regenerate manifests, commit, push.
#
# DEFAULT (additive): copies only NEW skills (folders not already in ./skills/).
#   Existing skills are left untouched. Safe — no overwrites.
#
# --yolo (substitute): WIPES ./skills/ and replaces everything from $SOURCE.
#   Use when you want a clean snapshot of the canonical source.
#
# Both modes: regenerate .claude-plugin/marketplace.json, regenerate README.md,
# create a randomly-named branch from origin/main, commit, and push.
#
# Usage:
#   ./scripts/update-skills.sh                   # additive (default)
#   ./scripts/update-skills.sh --yolo            # wipe + replace
#   DRY_RUN=1 ./scripts/update-skills.sh         # local only, no commit/push
#   DRY_RUN=1 ./scripts/update-skills.sh --yolo
#   SOURCE=/path/to/skills ./scripts/update-skills.sh
#
# Safety:
# - Refuses to run if your working tree is dirty.
# - Refuses to overwrite main directly; always creates a new branch.
# - --yolo is verbose about what it's wiping (count + sample).

set -euo pipefail

# ---------- args ----------
MODE="additive"
for arg in "$@"; do
  case "$arg" in
    --yolo)    MODE="yolo" ;;
    --help|-h) sed -n '1,30p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ---------- config ----------
SOURCE="${SOURCE:-$HOME/.claude/skills}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"

# ---------- preflight ----------
cd "$REPO_ROOT"

if [ ! -d "$SOURCE" ]; then
  echo "ERROR: source skills directory not found: $SOURCE" >&2
  exit 1
fi

if [ ! -d ".git" ]; then
  echo "ERROR: $REPO_ROOT is not a git repo" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is dirty. Commit or stash first:" >&2
  git status --short >&2
  exit 1
fi

echo "==> Mode: $MODE   Source: $SOURCE"
echo "==> Fetching origin"
git fetch origin --quiet

# ---------- branch name ----------
RAND_SUFFIX="$(date +%Y%m%d-%H%M%S)-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
BRANCH="update-skills-$RAND_SUFFIX"
echo "==> Creating branch: $BRANCH (from origin/main)"
git checkout -B "$BRANCH" origin/main

mkdir -p skills

# ---------- copy phase ----------
copied=0
skipped_no_skillmd=0
skipped_exists=0

if [ "$MODE" = "yolo" ]; then
  existing_count=$(ls -d skills/*/ 2>/dev/null | wc -l)
  echo "==> --yolo: WIPING $existing_count existing skills"
  if [ "$existing_count" -gt 0 ]; then
    echo "    sample: $(ls -d skills/*/ | head -5 | xargs -n1 basename | tr '\n' ' ')..."
  fi
  rm -rf skills
  mkdir -p skills
fi

echo "==> Copying from $SOURCE"
for d in "$SOURCE"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  if [ ! -f "$d/SKILL.md" ]; then
    skipped_no_skillmd=$((skipped_no_skillmd+1))
    continue
  fi
  if [ "$MODE" = "additive" ] && [ -d "skills/$name" ]; then
    skipped_exists=$((skipped_exists+1))
    continue
  fi
  cp -r "$d" "skills/$name"
  copied=$((copied+1))
done

echo "    Copied: $copied"
[ "$skipped_exists" -gt 0 ]    && echo "    Skipped (already exist, additive mode): $skipped_exists"
[ "$skipped_no_skillmd" -gt 0 ] && echo "    Skipped (no SKILL.md): $skipped_no_skillmd"

TOTAL=$(ls -d skills/*/ 2>/dev/null | wc -l)
echo "    Total skills now in ./skills/: $TOTAL"

# ---------- regenerate marketplace.json ----------
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

# ---------- regenerate README.md ----------
echo "==> Regenerating README.md"
MODE="$MODE" python3 - <<'PYEOF'
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
mode = os.environ.get("MODE", "additive")

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
    "./scripts/update-skills.sh            # additive — only adds NEW skills (default, safe)",
    "./scripts/update-skills.sh --yolo     # substitute — wipes ./skills/ and re-copies everything",
    "DRY_RUN=1 ./scripts/update-skills.sh  # local only, no commit/push",
    "SOURCE=/path ./scripts/update-skills.sh",
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

# ---------- commit + push ----------
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
COMMIT_MSG="sync($MODE): $SKILL_COUNT skills from \$SOURCE

Mode: $MODE
Source: $SOURCE
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
echo "    PR:     gh pr create --base main --head $BRANCH --title 'sync($MODE): $SKILL_COUNT skills' --body 'Auto-sync from \$SOURCE'"
