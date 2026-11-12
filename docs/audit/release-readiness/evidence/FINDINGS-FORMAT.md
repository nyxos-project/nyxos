# Finding format

Every finding in this audit uses this block. IDs are `NYX-<AREA>-NNN`, numbered within
the area; areas are ARCH, SHELL, HYPR, THEME, AI, VOICE, CONN, SYS, UPD, SET, SEC, PRIV,
PKG, CI, DEP, DOC, UX, A11Y, PERF, REL, INST, HW, and APP-<APPNAME> for app scorecards.

```markdown
### NYX-SEC-001: Short title

- **Component:** repository and path
- **Category:** security | privacy | architecture | reliability | UX | accessibility | packaging | CI | docs | performance | functionality
- **Severity:** P0 | P1 | P2 | P3
- **Status of feature:** verified | implemented, not verified | partial | approved, not implemented | exploratory | deprecated
- **Description:** what is wrong
- **Expected:** what should be true (cite the handoff section or standard)
- **Actual:** what is true, with file:line references
- **Reproduce / verify:** commands or steps
- **Evidence:** source references (`repo/path:line`), logs under evidence/
- **Affected versions:** commit(s)
- **User impact:**
- **Recommended correction:**
- **Effort:** S (hours) | M (days) | L (weeks)
- **Dependencies:** other findings or handoffs
- **Verification criteria:** how to confirm the fix
```

## Severity

- **P0 release blocker:** unbootable system, critical authentication bypass, reproducible
  data loss, broken installation, no viable recovery path for a critical failure.
- **P1 high:** core desktop functionality unreliable, serious security weakness, major
  advertised workflow broken, frequent shell crashes, significant config corruption.
- **P2 medium:** important UX inconsistency, feature-specific reliability problem,
  accessibility issue with a workaround, noncritical performance regression.
- **P3 low:** minor visual inconsistency, small documentation gap, cosmetic defect.

Feature requests are not bugs. A planned feature that isn't implemented is "approved, not
implemented", not a regression; it blocks release only if it is advertised or needed for
core desktop, security, data integrity, installation or recovery.

## Rules

- Evidence over assumptions: cite `repo/path:line` for every claim from source.
- Static findings that need runtime confirmation say "static; confirm at runtime".
- No invented measurements. No credentials in reports (say "a test password exists").
- Don't modify any repository other than writing your assigned report files.
