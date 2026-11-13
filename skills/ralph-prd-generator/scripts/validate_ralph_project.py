#!/usr/bin/env python3
"""
Validate Ralph Project Structure

Checks that a Ralph project has required files and proper structure.

Usage:
    python validate_ralph_project.py <project_path>
    python validate_ralph_project.py .

Exit codes:
    0 - All validations passed
    1 - Validation errors found
"""

import sys
import re
from pathlib import Path
from typing import List, Tuple


class ValidationResult:
    def __init__(self):
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.passed: List[str] = []

    def add_error(self, message: str):
        self.errors.append(f"ERROR: {message}")

    def add_warning(self, message: str):
        self.warnings.append(f"WARNING: {message}")

    def add_pass(self, message: str):
        self.passed.append(f"PASS: {message}")

    def is_valid(self) -> bool:
        return len(self.errors) == 0


def validate_prompt_md(path: Path) -> ValidationResult:
    """Validate PROMPT.md file."""
    result = ValidationResult()
    prompt_file = path / "PROMPT.md"

    if not prompt_file.exists():
        result.add_error("PROMPT.md not found (required)")
        return result

    result.add_pass("PROMPT.md exists")
    content = prompt_file.read_text()

    # Check for title
    if re.search(r'^#\s+.+Development Instructions', content, re.MULTILINE):
        result.add_pass("Has title with 'Development Instructions'")
    else:
        result.add_warning("Title should include 'Development Instructions'")

    # Check for Ralph role definition
    if "You are Ralph" in content:
        result.add_pass("Contains Ralph role definition")
    else:
        result.add_warning("Should include 'You are Ralph' role definition")

    # Check for Mission section
    if re.search(r'^##\s+.*Mission', content, re.MULTILINE | re.IGNORECASE):
        result.add_pass("Has Mission section")
    else:
        result.add_warning("Missing Mission section")

    # Check for Technical Requirements
    if re.search(r'^##\s+.*Technical.*Requirements?', content, re.MULTILINE | re.IGNORECASE):
        result.add_pass("Has Technical Requirements section")
    else:
        result.add_warning("Missing Technical Requirements section")

    # Check for Process section
    if re.search(r'^##\s+Process', content, re.MULTILINE):
        result.add_pass("Has Process section")
    else:
        result.add_warning("Missing Process section")

    # Check for RALPH_STATUS (critical)
    if "RALPH_STATUS" in content:
        result.add_pass("Contains RALPH_STATUS block")
    else:
        result.add_error("Missing RALPH_STATUS block (required for exit detection)")

    # Check for EXIT_SIGNAL (critical)
    if "EXIT_SIGNAL" in content:
        result.add_pass("Contains EXIT_SIGNAL definition")
    else:
        result.add_error("Missing EXIT_SIGNAL (required for loop termination)")

    # Check for @fix_plan.md reference
    if "@fix_plan.md" in content:
        result.add_pass("References @fix_plan.md")
    else:
        result.add_warning("Should reference @fix_plan.md in Process section")

    return result


def validate_fix_plan(path: Path) -> ValidationResult:
    """Validate @fix_plan.md file."""
    result = ValidationResult()
    fix_plan = path / "@fix_plan.md"

    if not fix_plan.exists():
        result.add_error("@fix_plan.md not found (required)")
        return result

    result.add_pass("@fix_plan.md exists")
    content = fix_plan.read_text()

    # Check for title
    if re.search(r'^#\s+Fix Plan', content, re.MULTILINE):
        result.add_pass("Has 'Fix Plan' title")
    else:
        result.add_warning("Should have 'Fix Plan' title")

    # Check for phases
    phases = re.findall(r'^##\s+Phase\s+\d+', content, re.MULTILINE)
    if phases:
        result.add_pass(f"Has {len(phases)} phase(s)")
    else:
        result.add_warning("No 'Phase N:' sections found")

    # Check for task markers
    incomplete_tasks = re.findall(r'^\s*-\s+\[\s*\]', content, re.MULTILINE)
    complete_tasks = re.findall(r'^\s*-\s+\[x\]', content, re.MULTILINE | re.IGNORECASE)

    if incomplete_tasks or complete_tasks:
        result.add_pass(f"Has task markers ({len(incomplete_tasks)} incomplete, {len(complete_tasks)} complete)")
    else:
        result.add_error("No task markers found (use - [ ] for tasks)")

    # Check for Completed section
    if re.search(r'^##\s+Completed', content, re.MULTILINE):
        result.add_pass("Has Completed section")
    else:
        result.add_warning("Missing '## Completed' section for finished tasks")

    # Check task granularity (warn if tasks look too broad)
    broad_patterns = [
        r'-\s+\[\s*\]\s+Build\s+\w+\s*$',
        r'-\s+\[\s*\]\s+Create\s+entire',
        r'-\s+\[\s*\]\s+Implement\s+all',
    ]
    for pattern in broad_patterns:
        if re.search(pattern, content, re.MULTILINE | re.IGNORECASE):
            result.add_warning("Some tasks may be too broad (should take 5-30 min each)")
            break

    return result


def validate_specs(path: Path) -> ValidationResult:
    """Validate specs/ directory."""
    result = ValidationResult()
    specs_dir = path / "specs"

    if not specs_dir.exists():
        result.add_warning("specs/ directory not found (recommended for complex projects)")
        return result

    result.add_pass("specs/ directory exists")

    spec_files = list(specs_dir.glob("*.md"))
    if spec_files:
        result.add_pass(f"Found {len(spec_files)} spec file(s): {', '.join(f.name for f in spec_files)}")
    else:
        result.add_warning("specs/ directory is empty")

    # Check for common spec files
    recommended_specs = ["data-models.md", "api-endpoints.md", "ui-components.md"]
    for spec in recommended_specs:
        spec_file = specs_dir / spec
        if spec_file.exists():
            result.add_pass(f"Has {spec}")

    return result


def validate_agent_md(path: Path) -> ValidationResult:
    """Validate @AGENT.md file (optional)."""
    result = ValidationResult()
    agent_file = path / "@AGENT.md"

    if not agent_file.exists():
        result.add_warning("@AGENT.md not found (optional but helpful for setup instructions)")
        return result

    result.add_pass("@AGENT.md exists")
    content = agent_file.read_text()

    # Check for standard sections
    sections = ["Prerequisites", "Setup", "Development", "Testing"]
    for section in sections:
        if re.search(rf'^##\s+{section}', content, re.MULTILINE | re.IGNORECASE):
            result.add_pass(f"Has {section} section")

    return result


def validate_project(path: Path) -> Tuple[bool, str]:
    """Run all validations and return summary."""
    results = {
        "PROMPT.md": validate_prompt_md(path),
        "@fix_plan.md": validate_fix_plan(path),
        "specs/": validate_specs(path),
        "@AGENT.md": validate_agent_md(path),
    }

    output_lines = []
    output_lines.append(f"\n{'='*60}")
    output_lines.append(f"Ralph Project Validation: {path.absolute()}")
    output_lines.append(f"{'='*60}\n")

    total_errors = 0
    total_warnings = 0
    total_passed = 0

    for file_name, result in results.items():
        output_lines.append(f"\n--- {file_name} ---")

        for msg in result.passed:
            output_lines.append(f"  {msg}")
            total_passed += 1

        for msg in result.warnings:
            output_lines.append(f"  {msg}")
            total_warnings += 1

        for msg in result.errors:
            output_lines.append(f"  {msg}")
            total_errors += 1

    output_lines.append(f"\n{'='*60}")
    output_lines.append("SUMMARY")
    output_lines.append(f"{'='*60}")
    output_lines.append(f"  Passed:   {total_passed}")
    output_lines.append(f"  Warnings: {total_warnings}")
    output_lines.append(f"  Errors:   {total_errors}")

    if total_errors == 0:
        output_lines.append(f"\nRESULT: VALID - Project structure is ready for Ralph")
        is_valid = True
    else:
        output_lines.append(f"\nRESULT: INVALID - Fix errors before using with Ralph")
        is_valid = False

    output_lines.append("")
    return is_valid, "\n".join(output_lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_ralph_project.py <project_path>")
        print("Example: python validate_ralph_project.py .")
        sys.exit(1)

    project_path = Path(sys.argv[1])

    if not project_path.exists():
        print(f"Error: Path does not exist: {project_path}")
        sys.exit(1)

    if not project_path.is_dir():
        print(f"Error: Path is not a directory: {project_path}")
        sys.exit(1)

    is_valid, output = validate_project(project_path)
    print(output)

    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
