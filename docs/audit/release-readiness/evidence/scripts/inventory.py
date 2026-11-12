#!/usr/bin/env python3
"""Collect repository facts for the release-readiness inventory.

Usage: inventory.py [PROJECTS_DIR] > inventory.json

Read-only apart from `git fetch` of each repository's origin.
"""
import json
import os
import re
import subprocess
import sys

projects = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/Projects")
pkgs_lock = json.load(open(os.path.join(projects, "nyx-packages/flake.lock")))["nodes"]
nyxos_lock = json.load(open(os.path.join(projects, "nyxos/flake.lock")))["nodes"]

INCLUDE = re.compile(r"^(nyx.*|Hyprland|hyprland-fs-.*|flux|umbra-icons)$")


def git(repo, *args):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    return r.stdout.strip()


def count(repo, pattern, globs):
    args = ["rg", "-c", pattern, repo, "--no-messages"]
    for g in globs:
        args += ["-g", g]
    args += ["-g", "!target", "-g", "!vendor"]
    r = subprocess.run(args, capture_output=True, text=True)
    return sum(int(l.rsplit(":", 1)[1]) for l in r.stdout.splitlines() if ":" in l)


def files(repo, glob):
    r = subprocess.run(
        ["rg", "--files", repo, "-g", glob, "-g", "!target", "-g", "!vendor", "--no-messages"],
        capture_output=True,
        text=True,
    )
    return [l for l in r.stdout.splitlines() if l]


def lines(paths):
    total = 0
    for p in paths:
        try:
            with open(p, "rb") as f:
                total += sum(1 for _ in f)
        except OSError:
            pass
    return total


out = []
for name in sorted(os.listdir(projects)):
    repo = os.path.join(projects, name)
    if not INCLUDE.match(name) or not os.path.isdir(os.path.join(repo, ".git")):
        continue
    subprocess.run(["git", "-C", repo, "fetch", "-q", "origin"], capture_output=True)
    branch = git(repo, "branch", "--show-current")
    default = git(repo, "symbolic-ref", "--short", "refs/remotes/origin/HEAD") or "origin/main"
    head = git(repo, "rev-parse", "HEAD")
    origin_head = git(repo, "rev-parse", default)
    ahead_behind = git(repo, "rev-list", "--left-right", "--count", f"HEAD...{default}")
    pin = pkgs_lock.get(name, {}).get("locked", {})
    pin_rev = pin.get("rev")
    pin_behind = None
    if pin_rev and origin_head:
        c = git(repo, "rev-list", "--count", f"{pin_rev}..{default}")
        pin_behind = int(c) if c.isdigit() else None
    rs = files(repo, "*.rs")
    qml = files(repo, "*.qml")
    nix = files(repo, "*.nix")
    py = files(repo, "*.py")
    cpp = files(repo, "*.{cpp,hpp,cc,h}")
    go = files(repo, "*.go")
    crates = files(repo, "Cargo.toml")
    wf_dir = os.path.join(repo, ".github/workflows")
    workflows = sorted(os.listdir(wf_dir)) if os.path.isdir(wf_dir) else []
    readme = os.path.join(repo, "README.md")
    entry = {
        "name": name,
        "origin": git(repo, "remote", "get-url", "origin"),
        "branch": branch,
        "head": head[:10],
        "head_date": git(repo, "log", "-1", "--format=%cs"),
        "head_subject": git(repo, "log", "-1", "--format=%s")[:120],
        "commits": int(git(repo, "rev-list", "--count", "HEAD") or 0),
        "dirty": len([l for l in git(repo, "status", "--porcelain").splitlines() if l]),
        "default_branch": default,
        "ahead_behind_origin": ahead_behind,
        "pinned_in_nyx_packages": pin_rev[:10] if pin_rev else None,
        "pin_commits_behind_origin": pin_behind,
        "rust_files": len(rs),
        "rust_lines": lines(rs),
        "cargo_manifests": len(crates),
        "qml_files": len(qml),
        "qml_lines": lines(qml),
        "nix_files": len(nix),
        "python_files": len(py),
        "cpp_files": len(cpp),
        "go_files": len(go),
        "rust_tests": count(repo, r"#\[(tokio::)?test", ["*.rs"]) if rs else 0,
        "workflows": workflows,
        "readme_lines": lines([readme]) if os.path.exists(readme) else 0,
        "has_docs_dir": os.path.isdir(os.path.join(repo, "docs")),
        "has_install_sh": os.path.exists(os.path.join(repo, "install.sh")),
        "has_license": any(f.upper().startswith(("LICENSE", "COPYING")) for f in os.listdir(repo)),
        "omarchy_refs": count(repo, r"omarchy", ["*.rs", "*.qml", "*.sh", "*.nix", "*.py"]),
    }
    out.append(entry)

nyxos_pin = nyxos_lock["nyx-packages"]["locked"]["rev"]
pkgs_main = git(os.path.join(projects, "nyx-packages"), "rev-parse", "origin/main")
json.dump(
    {
        "nyxos_pins_nyx_packages": nyxos_pin[:10],
        "nyx_packages_origin_main": pkgs_main[:10],
        "repos": out,
    },
    sys.stdout,
    indent=1,
)
