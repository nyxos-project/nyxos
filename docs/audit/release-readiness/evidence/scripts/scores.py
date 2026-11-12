#!/usr/bin/env python3
"""Print a Markdown table of every app scorecard's seven scores (for README.md)."""
import glob, os, re
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
areas = ["Functionality", "UX", "Accessibility", "Reliability", "Integration", "Packaging", "Maintainability"]
tier = re.compile(r"\*\*Release tier:\*\*\s*([a-z ]+)", re.I)
print("| App | Tier | " + " | ".join(a[:5] + "." if len(a) > 6 else a for a in areas) + " | P0/P1 |")
print("| --- | --- | " + " | ".join("---:" for _ in areas) + " | --- |")
for p in sorted(glob.glob(os.path.join(root, "apps/*.md"))):
    n = os.path.basename(p)[:-3]
    if n == "TEMPLATE": continue
    t = open(p).read()
    row = []
    for a in areas:
        m = re.search(rf"^\|\s*{a}\s*\|\s*([0-3]|n/v)\s*\|", t, re.M)
        row.append(m.group(1) if m else "?")
    tm = tier.search(t)
    hi = sorted(set(re.findall(r"^### (NYX-APP-[A-Z-]+-\d+).*\n(?:.*\n){0,6}?- \*\*Severity:\*\* (P[01])", t, re.M)))
    print(f"| [{n}](apps/{n}.md) | {tm.group(1).strip() if tm else '?'} | " + " | ".join(row) + f" | {', '.join(f'{i[0].split('-')[-1]} {i[1]}' for i in hi) or '-'} |")
