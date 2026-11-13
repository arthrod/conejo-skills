#!/usr/bin/env python3
"""
Spec-Kit to Ralph Converter

Converts a Spec-Kit project structure to Ralph-compatible format.

Usage:
    python speckit_to_ralph.py <speckit_project> <output_dir>
    python speckit_to_ralph.py ./my-project ./ralph-output

Exit codes:
    0 - Conversion successful
    1 - Error during conversion
"""

import sys
import re
import shutil
from pathlib import Path
from typing import Optional, Dict, List
from datetime import datetime


def find_speckit_files(project_path: Path) -> Dict[str, Optional[Path]]:
    """Find Spec-Kit files in the project."""
    specify_dir = project_path / ".specify"

    files = {
        "constitution": None,
        "spec": None,
        "plan": None,
        "tasks": None,
        "data_model": None,
        "research": None,
    }

    # Find constitution in memory/
    memory_dir = specify_dir / "memory"
    if memory_dir.exists():
        constitution = memory_dir / "constitution.md"
        if constitution.exists():
            files["constitution"] = constitution

    # Find spec files in specs/
    specs_dir = specify_dir / "specs"
    if specs_dir.exists():
        # Find first feature directory (001-*, etc.)
        feature_dirs = sorted(specs_dir.glob("*"))
        for feature_dir in feature_dirs:
            if feature_dir.is_dir():
                # Look for standard Spec-Kit files
                for name, filename in [
                    ("spec", "spec.md"),
                    ("plan", "plan.md"),
                    ("tasks", "tasks.md"),
                    ("data_model", "data-model.md"),
                    ("research", "research.md"),
                ]:
                    file_path = feature_dir / filename
                    if file_path.exists() and files[name] is None:
                        files[name] = file_path

    return files


def extract_tech_stack(plan_content: str) -> str:
    """Extract technology stack from plan.md content."""
    # Look for technology/tech stack section
    tech_match = re.search(
        r'(?:##\s*(?:Technology|Tech\s*Stack|Technical|Stack).*?\n)(.*?)(?=\n##|\Z)',
        plan_content,
        re.IGNORECASE | re.DOTALL
    )

    if tech_match:
        return tech_match.group(1).strip()

    # Fallback: look for bullet points with common tech
    tech_patterns = [
        r'(?:React|Vue|Angular|Next\.js|TypeScript|JavaScript)',
        r'(?:Express|FastAPI|Django|Flask|Node\.js)',
        r'(?:PostgreSQL|MySQL|MongoDB|SQLite|Prisma)',
    ]

    found_tech = []
    for pattern in tech_patterns:
        matches = re.findall(pattern, plan_content, re.IGNORECASE)
        found_tech.extend(matches)

    if found_tech:
        return "- " + "\n- ".join(set(found_tech))

    return "Technology stack not specified in plan.md"


def extract_quality_standards(constitution_content: str) -> str:
    """Extract quality standards from constitution.md."""
    # Look for principles or standards section
    standards_match = re.search(
        r'(?:##\s*(?:Principles|Standards|Quality|Guidelines).*?\n)(.*?)(?=\n##|\Z)',
        constitution_content,
        re.IGNORECASE | re.DOTALL
    )

    if standards_match:
        return standards_match.group(1).strip()

    # Return full content if no specific section found
    # Remove title and return
    lines = constitution_content.strip().split('\n')
    if lines and lines[0].startswith('#'):
        return '\n'.join(lines[1:]).strip()

    return constitution_content.strip()


def convert_tasks_to_fix_plan(tasks_content: str, project_name: str) -> str:
    """Convert Spec-Kit tasks.md to Ralph @fix_plan.md format."""
    lines = tasks_content.strip().split('\n')
    output_lines = [f"# Fix Plan - {project_name}", ""]

    phase_num = 1
    in_tasks = False
    current_section = None

    for line in lines:
        stripped = line.strip()

        # Skip title
        if stripped.startswith('# ') and not current_section:
            continue

        # Convert section headers to phases
        if stripped.startswith('## '):
            section_name = stripped[3:].strip()
            # Remove "User Story N:" prefix if present
            section_name = re.sub(r'^User Story\s*\d*:\s*', '', section_name)
            output_lines.append(f"## Phase {phase_num}: {section_name}")
            phase_num += 1
            in_tasks = True
            current_section = section_name
            continue

        # Convert task markers
        # Spec-Kit uses [P] for in-progress, [ ] for incomplete
        if re.match(r'^\s*-\s*\[[Pp]\]', stripped):
            # Convert [P] to [ ] (Ralph tracks progress differently)
            converted = re.sub(r'\[[Pp]\]', '[ ]', line)
            output_lines.append(converted)
        elif re.match(r'^\s*-\s*\[[ xX]\]', stripped):
            output_lines.append(line)
        elif stripped.startswith('- ') and in_tasks:
            # Add task marker if missing
            output_lines.append(line.replace('- ', '- [ ] ', 1))
        elif stripped:
            output_lines.append(line)

    # Add Completed section
    output_lines.append("")
    output_lines.append("## Completed")
    output_lines.append("(Tasks moved here when done)")
    output_lines.append("")

    return '\n'.join(output_lines)


def generate_prompt_md(
    project_name: str,
    spec_content: Optional[str],
    plan_content: Optional[str],
    constitution_content: Optional[str],
) -> str:
    """Generate PROMPT.md from Spec-Kit files."""

    # Extract mission from spec
    mission = "Build the application as specified."
    if spec_content:
        # Try to find overview or first section
        overview_match = re.search(
            r'(?:##\s*(?:Overview|Summary|Description).*?\n)(.*?)(?=\n##|\Z)',
            spec_content,
            re.IGNORECASE | re.DOTALL
        )
        if overview_match:
            mission = overview_match.group(1).strip()[:500]  # Limit length
        else:
            # Use first paragraph after title
            lines = spec_content.strip().split('\n')
            for i, line in enumerate(lines):
                if line.strip() and not line.startswith('#'):
                    mission = line.strip()[:500]
                    break

    # Extract tech stack
    tech_stack = "Technology stack not specified"
    if plan_content:
        tech_stack = extract_tech_stack(plan_content)

    # Extract quality standards
    quality_standards = ""
    if constitution_content:
        standards = extract_quality_standards(constitution_content)
        quality_standards = f"""
## Quality Standards

{standards}
"""

    prompt_content = f"""# {project_name} Development Instructions

You are Ralph, an autonomous AI development agent building {project_name}.

## Your Mission

{mission}

## Technical Requirements

{tech_stack}
{quality_standards}
## Process

1. Read @fix_plan.md and select the highest priority incomplete task
2. Implement the task following specs in specs/
3. Write tests for the implementation
4. Update @fix_plan.md to mark the task complete
5. Commit with a meaningful message

## RALPH_STATUS Format

At the end of each response, include:

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
- PROGRESS: [What was accomplished]
- NEXT_STEPS: [What remains]

Set EXIT_SIGNAL to true ONLY when ALL tasks complete and tests pass.
"""

    return prompt_content


def generate_agent_md(project_name: str) -> str:
    """Generate stub @AGENT.md file."""
    return f"""# Build & Run Instructions

## Prerequisites

- Node.js 18+
- npm or pnpm

## Setup

```bash
npm install
cp .env.example .env
# Edit .env with your configuration
```

## Development

```bash
npm run dev
```

## Testing

```bash
npm test
```

## Build

```bash
npm run build
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| DATABASE_URL | Database connection string | Yes |
| NODE_ENV | Environment (development/production) | No |
"""


def convert_project(source_path: Path, output_path: Path) -> bool:
    """Convert Spec-Kit project to Ralph format."""

    print(f"Converting Spec-Kit project: {source_path}")
    print(f"Output directory: {output_path}")
    print()

    # Find Spec-Kit files
    files = find_speckit_files(source_path)

    found_files = [k for k, v in files.items() if v is not None]
    if not found_files:
        print("ERROR: No Spec-Kit files found in .specify/ directory")
        print("Make sure you've run the Spec-Kit workflow first:")
        print("  /speckit.constitution")
        print("  /speckit.specify")
        print("  /speckit.plan")
        print("  /speckit.tasks")
        return False

    print(f"Found Spec-Kit files: {', '.join(found_files)}")

    # Create output directory
    output_path.mkdir(parents=True, exist_ok=True)

    # Determine project name
    project_name = source_path.name
    if project_name == ".":
        project_name = Path.cwd().name
    project_name = project_name.replace("-", " ").replace("_", " ").title()

    # Read file contents
    spec_content = files["spec"].read_text() if files["spec"] else None
    plan_content = files["plan"].read_text() if files["plan"] else None
    constitution_content = files["constitution"].read_text() if files["constitution"] else None
    tasks_content = files["tasks"].read_text() if files["tasks"] else None

    # Generate PROMPT.md
    print("Generating PROMPT.md...")
    prompt_content = generate_prompt_md(
        project_name, spec_content, plan_content, constitution_content
    )
    (output_path / "PROMPT.md").write_text(prompt_content)

    # Generate @fix_plan.md
    print("Generating @fix_plan.md...")
    if tasks_content:
        fix_plan_content = convert_tasks_to_fix_plan(tasks_content, project_name)
    else:
        fix_plan_content = f"""# Fix Plan - {project_name}

## Phase 1: Foundation
- [ ] Initialize project structure
- [ ] Set up development environment
- [ ] Configure build tools

## Phase 2: Core Features
- [ ] Implement core functionality
- [ ] Add tests

## Completed
(Tasks moved here when done)
"""
    (output_path / "@fix_plan.md").write_text(fix_plan_content)

    # Create specs/ directory and copy relevant files
    print("Creating specs/ directory...")
    specs_dir = output_path / "specs"
    specs_dir.mkdir(exist_ok=True)

    if spec_content:
        (specs_dir / "requirements.md").write_text(spec_content)
        print("  - Copied spec.md -> specs/requirements.md")

    if files["data_model"]:
        shutil.copy(files["data_model"], specs_dir / "data-models.md")
        print("  - Copied data-model.md -> specs/data-models.md")

    if files["research"]:
        shutil.copy(files["research"], specs_dir / "research.md")
        print("  - Copied research.md -> specs/research.md")

    # Generate @AGENT.md
    print("Generating @AGENT.md...")
    agent_content = generate_agent_md(project_name)
    (output_path / "@AGENT.md").write_text(agent_content)

    print()
    print("=" * 60)
    print("CONVERSION COMPLETE")
    print("=" * 60)
    print()
    print(f"Output directory: {output_path.absolute()}")
    print()
    print("Generated files:")
    for f in sorted(output_path.rglob("*")):
        if f.is_file():
            rel_path = f.relative_to(output_path)
            print(f"  - {rel_path}")
    print()
    print("Next steps:")
    print("  1. Review and customize PROMPT.md")
    print("  2. Review @fix_plan.md task granularity")
    print("  3. Validate: python scripts/validate_ralph_project.py", output_path)
    print("  4. Start Ralph: cd", output_path, "&& ralph --monitor")
    print()

    return True


def main():
    if len(sys.argv) < 3:
        print("Usage: python speckit_to_ralph.py <speckit_project> <output_dir>")
        print()
        print("Example:")
        print("  python speckit_to_ralph.py ./my-project ./ralph-output")
        print("  python speckit_to_ralph.py . ./ralph-output")
        sys.exit(1)

    source_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    if not source_path.exists():
        print(f"Error: Source path does not exist: {source_path}")
        sys.exit(1)

    if not source_path.is_dir():
        print(f"Error: Source path is not a directory: {source_path}")
        sys.exit(1)

    if output_path.exists() and any(output_path.iterdir()):
        print(f"Warning: Output directory exists and is not empty: {output_path}")
        response = input("Continue and overwrite? (y/N): ")
        if response.lower() != 'y':
            print("Aborted.")
            sys.exit(0)

    success = convert_project(source_path, output_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
