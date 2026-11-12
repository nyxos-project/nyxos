#!/usr/bin/env python3
"""Build issues.md, the issue register, from every finding in the audit's reports.

Usage (from the audit folder): evidence/scripts/issues.py > issues.md
A finding is a heading `### NYX-AREA-NNN: Title` followed by a `**Severity:** Pn` line.
"""
import collections
import glob
import os
import re
import sys

root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
files = sorted(glob.glob(os.path.join(root, "*.md")) + glob.glob(os.path.join(root, "apps/*.md")))
head = re.compile(r"^#{2,4}\s+(NYX-[A-Z0-9]+(?:-[A-Z0-9]+)*-\d{3})\s*[:—–-]\s*(.+?)\s*$")
sev = re.compile(r"\*\*Severity:\*\*\s*(P[0-3])")
comp = re.compile(r"\*\*Component:\*\*\s*(.+)")


def anchor(text):
    a = text.strip().lower()
    a = re.sub(r"[^\w\- ]", "", a)
    return a.replace(" ", "-")


found = []
for path in files:
    rel = os.path.relpath(path, root)
    if rel in ("issues.md", "apps/TEMPLATE.md", "README.md", "remediation.md", "gates.md"):
        continue
    lines = open(path).read().splitlines()
    for i, line in enumerate(lines):
        m = head.match(line)
        if not m:
            continue
        s, c = "?", ""
        for nxt in lines[i + 1 : i + 16]:
            if nxt.startswith("#"):
                break
            ms = sev.search(nxt)
            if ms and s == "?":
                s = ms.group(1)
            mc = comp.search(nxt)
            if mc and not c:
                c = mc.group(1)
        heading = line.lstrip("#").strip()
        found.append((s, m.group(1), m.group(2), rel, anchor(heading), c))

order = {"P0": 0, "P1": 1, "P2": 2, "P3": 3, "?": 4}
ids = collections.Counter(f[1] for f in found)
counts = collections.Counter(f[0] for f in found)

out = sys.stdout
out.write("# Issue register\n\n")
out.write("Every finding in this audit, generated from the reports by "
          "[evidence/scripts/issues.py](evidence/scripts/issues.py). Severity follows "
          "[evidence/FINDINGS-FORMAT.md](evidence/FINDINGS-FORMAT.md); each ID links to "
          "the full finding (description, evidence, reproduction, fix, verification).\n\n")
out.write("| Severity | Count |\n| --- | ---: |\n")
for k in ("P0", "P1", "P2", "P3"):
    out.write(f"| {k} | {counts.get(k, 0)} |\n")
if counts.get("?"):
    out.write(f"| unparsed | {counts['?']} |\n")
out.write(f"| **Total** | **{len(found)}** |\n\n")
dups = [k for k, v in ids.items() if v > 1]
if dups:
    out.write("Duplicate IDs (same ID used twice): " + ", ".join(sorted(dups)) + "\n\n")
for level in ("P0", "P1", "P2", "P3", "?"):
    rows = [f for f in found if f[0] == level]
    if not rows:
        continue
    out.write(f"## {level}\n\n| ID | Title | Report |\n| --- | --- | --- |\n")
    for s, i, t, rel, a, c in sorted(rows, key=lambda f: f[1]):
        t = t.replace("|", "\\|")
        out.write(f"| [{i}]({rel}#{a}) | {t} | {rel} |\n")
    out.write("\n")
