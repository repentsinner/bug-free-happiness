"""Runs bug-free-happiness's Python correctness checks on a uv project.

The steps and tool versions are python-correctness.yml's: ``uv sync --locked``,
ruff's lint and format checks, a type checker, and the project's tests. The
versions come from this distribution's own pinned dependencies, the same
pyproject.toml the workflow reads, so a local run agrees with CI.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from importlib.metadata import requires

DISTRIBUTION = "python-correctness-tools"
TOOLS = ("ruff", "pyright", "mypy")
CHECKS = ("lint", "format", "types", "tests")


def pinned_versions() -> dict[str, str]:
    """Returns the exact version this distribution pins for each tool."""
    versions: dict[str, str] = {}
    for requirement in requires(DISTRIBUTION) or []:
        match = re.fullmatch(r"\s*([A-Za-z0-9_.-]+)\s*==\s*([^;\s]+).*", requirement)
        if match:
            versions[match.group(1).lower()] = match.group(2)
    missing = [tool for tool in TOOLS if tool not in versions]
    if missing:
        raise SystemExit(f"bfh-check: no pinned version for {', '.join(missing)}")
    return versions


def parse_arguments(argv: list[str] | None) -> argparse.Namespace:
    """Returns the command line, parsed."""
    parser = argparse.ArgumentParser(
        prog="bfh-check",
        description="Run the Python correctness checks CI runs: uv sync --locked, "
        "ruff lint and format, a type checker, and pytest, at the same versions.",
    )
    parser.add_argument(
        "--path", default=".", help="the uv project to check (default: here)"
    )
    parser.add_argument(
        "--type-checker",
        choices=("pyright", "mypy", "none"),
        default="pyright",
        help="the checker your quality.yml names (default: pyright)",
    )
    parser.add_argument("pytest_args", nargs="*", help="arguments for pytest, after --")
    return parser.parse_args(argv)


def type_check_command(
    uv: str, checker: str, versions: dict[str, str]
) -> list[str] | None:
    """Returns the type-check command, or None when checking is disabled."""
    if checker == "none":
        print("warning: type checking is disabled; adopters run pyright")
        return None
    if checker == "mypy":
        print("warning: mypy is deprecated here; migrate to pyright")
    return [uv, "run", "--with", f"{checker}=={versions[checker]}", checker]


def main(argv: list[str] | None = None) -> int:
    """Runs every check, reports each, and returns 1 when any failed."""
    arguments = parse_arguments(argv)
    versions = pinned_versions()
    uv = shutil.which("uv")
    if uv is None:
        raise SystemExit("bfh-check: uv is not on PATH; install uv and run again")
    # ruff is installed beside this script at its pinned version, so it runs
    # from here rather than from the project's environment.
    ruff = shutil.which("ruff", path=os.path.dirname(sys.executable))
    if ruff is None:
        raise SystemExit("bfh-check: ruff is missing from bfh-check's environment")

    print(f"== sync ({arguments.path})", flush=True)
    sync = subprocess.run([uv, "sync", "--locked"], check=False, cwd=arguments.path)
    if sync.returncode:
        print("sync: failed; the checks need the locked environment")
        return 1

    commands: dict[str, list[str] | None] = {
        "lint": [ruff, "check", "."],
        "format": [ruff, "format", "--check", "."],
        "types": type_check_command(uv, arguments.type_checker, versions),
        "tests": [uv, "run", "pytest", *arguments.pytest_args],
    }
    results: dict[str, str] = {}
    for check in CHECKS:
        command = commands[check]
        print(f"== {check}", flush=True)
        if command is None:
            results[check] = "skipped"
            continue
        failed = subprocess.run(command, check=False, cwd=arguments.path).returncode
        results[check] = "failed" if failed else "passed"

    print("== summary")
    for check in CHECKS:
        print(f"{check}: {results[check]}")
    return 1 if "failed" in results.values() else 0


if __name__ == "__main__":
    sys.exit(main())
