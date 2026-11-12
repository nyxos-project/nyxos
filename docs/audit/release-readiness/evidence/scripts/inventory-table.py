#!/usr/bin/env python3
"""Render evidence/inventory.json as the Markdown table in inventory.md."""
import json
import sys

d = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "inventory.json"))


def lang(r):
    parts = []
    if r["rust_lines"]:
        parts.append(f"Rust {r['rust_lines'] // 1000}k")
    if r["qml_lines"]:
        parts.append(f"QML {r['qml_lines'] // 1000 or '<1'}k")
    if r["cpp_files"] and r["name"] == "Hyprland":
        parts.append("C++")
    if r["go_files"]:
        parts.append("Go")
    if not parts and r["nix_files"]:
        parts.append("Nix")
    return ", ".join(parts) or "data"


print("| Repository | Origin | HEAD (date) | Languages | Rust tests | CI workflows | Pin vs origin | Omarchy refs | Dirty |")
print("| --- | --- | --- | --- | ---: | ---: | --- | ---: | ---: |")
for r in d["repos"]:
    origin = r["origin"].replace("https://github.com/", "").replace("git@github.com:", "").removesuffix(".git")
    pin = r["pinned_in_nyx_packages"]
    if pin is None:
        pinc = "not pinned"
    elif r["pin_commits_behind_origin"] == 0:
        pinc = "current"
    else:
        pinc = f"{r['pin_commits_behind_origin']} behind"
    print(
        f"| `{r['name']}` | {origin} | `{r['head'][:7]}` ({r['head_date']}) | {lang(r)} | "
        f"{r['rust_tests']} | {len(r['workflows'])} | {pinc} | {r['omarchy_refs']} | {r['dirty']} |"
    )
