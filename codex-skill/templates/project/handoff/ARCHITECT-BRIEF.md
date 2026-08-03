# Architect Brief
*Written by Architect. Read by Builder and Reviewer.*
*Overwrite this file each step — it is not a log, it is the current active brief.*

---

## Step [N] — [What is being built]

### Decisions
- [Decision or constraint]
- [Decision or constraint]

### Build Order
1. [First thing to build]
2. [Second thing]

### Out of Scope
- [What this step must not touch. Draw the boundary — Builder cannot respect a line that was never drawn.]

### Flags
- Flag: [anything Builder must not guess at]

### Cost Budget
- Architect: warning 85K / fresh-session checkpoint 100K; Builder: 75K / 90K; Reviewer: 50K / 60K.
- Stable prompt prefixes are encouraged; Codex manages caching automatically and Three Man Team cannot set cache keys or retention.

### Owner Validation Batch
- Disposition: no device-only validation is required unless this step changes device behavior. When it is required, collect findings once after review: one crop per defect, ~20 relevant log lines, and file references—not transcripts.

### Definition of Done
*At least one criterion must be a command in backticks that exits 0 when the step is done.
A criterion you cannot write as a command, a click-path, or a diff assertion means the step is
not specified sharply enough to build — sharpen it or split it before spinning up the Builder.
`scripts/check-handoff.sh brief` enforces this.*

- [ ] [`command that exits 0 when this step is done`]
- [ ] [Click-path or diff assertion — "works" is not a criterion]

---

## Builder Plan
*Builder adds their plan here before building. Architect reviews and approves.*

[Builder writes plan here]

Architect approval: [ ] Approved / [ ] Redirect — see notes below
