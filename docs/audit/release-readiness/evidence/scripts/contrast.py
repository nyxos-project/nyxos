#!/usr/bin/env python3
"""WCAG 2.2 contrast of every built-in theme's resolved tokens.

Usage: contrast.py PATH/TO/nyx-design/crates/nyx-theme-core/builtin-themes.json

Pairs and thresholds follow WCAG 2.2 AA: 4.5:1 for normal-size text (1.4.3), 3:1 for
large text and for non-text UI parts such as focus rings and input borders (1.4.11).
nyx-theme-core's own check (src/contrast.rs) asks only 3:1 of secondary text and of
labels on accent buttons; those rows are marked "(Nyx asks 3.0)".
"""
import json
import sys


def lum(hexc):
    h = hexc.lstrip("#")[:6]
    rgb = [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


PAIRS = [
    ("text.primary", "surface.primary", 4.5, "body text"),
    ("text.primary", "surface.elevated", 4.5, "text on raised surfaces"),
    ("text.secondary", "surface.primary", 4.5, "secondary text (Nyx asks 3.0)"),
    ("text.secondary", "surface.secondary", 4.5, "secondary text in sidebars"),
    ("text.tertiary", "surface.primary", 4.5, "tertiary text (captions)"),
    ("text.onAccent", "accent.primary", 4.5, "label on accent button (Nyx asks 3.0)"),
    ("selection.foreground", "selection.background", 4.5, "selected text"),
    ("border.focus", "surface.primary", 3.0, "focus ring (1.4.11)"),
    ("border.default", "surface.primary", 3.0, "input/control border (1.4.11)"),
    ("border.strong", "surface.primary", 3.0, "strong border (1.4.11)"),
    ("status.error", "surface.primary", 4.5, "error text"),
    ("status.warning", "surface.primary", 4.5, "warning text"),
    ("status.success", "surface.primary", 4.5, "success text"),
]

themes = json.load(open(sys.argv[1]))
fails = {}
print("| Theme | " + " | ".join(f"{fg.split('.')[1]} / {bg.split('.')[1]}" for fg, bg, _, _ in PAIRS) + " |")
print("| --- | " + " | ".join("---:" for _ in PAIRS) + " |")
for tid, t in themes.items():
    c = t["colors"]
    cells = []
    for fg, bg, need, what in PAIRS:
        r = ratio(c[fg], c[bg])
        ok = r + 1e-6 >= need
        cells.append(f"{r:.1f}" + ("" if ok else " **x**"))
        if not ok:
            fails.setdefault(what, []).append(tid)
    print(f"| {tid} | " + " | ".join(cells) + " |")
print()
print("Thresholds: " + "; ".join(f"{fg} on {bg} >= {need} ({what})" for fg, bg, need, what in PAIRS))
print()
for what, ids in fails.items():
    print(f"- {what}: below threshold in {len(ids)} of {len(themes)} themes ({', '.join(ids)})")
