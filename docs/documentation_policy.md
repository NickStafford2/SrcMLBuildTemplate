# Documentation Policy

This policy defines documentation roles across `SrcMLBuildTemplate`, `srcMove`,
and `srcVisual`. The repositories remain independent, but readers should be able
to navigate them using the same expectations.

## Core Rule

Humans and AI agents share the same technical source of truth. Durable facts
belong in normal project documentation. AI-specific files contain operating
instructions, not a second description of the software.

Write each durable fact once in the most specific canonical document. Link to
that document when another location needs the same context.

## Document Roles

| Location | Purpose |
| --- | --- |
| `README.md` | Human entry point: what the project is, why it exists, current capabilities, quick start, and major limitations. |
| `docs/README.md` or `doc/README.md` | Short index that directs readers to canonical documents. It should not become a scratchpad. |
| `docs/*.md` or `doc/*.md` | Durable architecture, development, testing, formats, and research methodology. |
| `AGENTS.md` | AI operating instructions: scope, required reading, commands, editing constraints, and links to canonical docs. |
| `notes/` or `user-notes/` | Exploratory and non-authoritative material, clearly separated from verified documentation. |
| `backlog.md` or issue tracker | Planned work, open questions, and candidate improvements. |
| `handoffs/` | Temporary task state. Preserve verified discoveries elsewhere and retire obsolete handoffs. |

`srcMove` currently uses `doc/`; the other repositories use `docs/`. Consistent
document roles matter more than renaming directories and creating unnecessary
link churn.

## README Standard

Use this order when the sections are relevant:

1. one-sentence project identity
2. motivation and project role
3. current behavior
4. relationship to the srcML ecosystem
5. quick start and prerequisites
6. build, run, and test entry points
7. current limitations
8. links to detailed documentation

Keep implementation detail in a dedicated technical document when it would
overwhelm the entry point.

## AGENTS.md Standard

Keep agent guidance operational and concise:

1. repository scope and boundaries
2. required reading
3. preferred build and test commands
4. editing and generated-file constraints
5. documentation and source-of-truth rules
6. repository-specific Git rules

Do not place product history, architecture, or research claims only in
`AGENTS.md`. Link to the human-facing canonical document instead.

## Notes, Plans, and Handoffs

Notes may contain incomplete ideas, uncertainty, and personal research context;
they are not evidence of current behavior. Plans describe intended work, not
implemented features. Mark both accordingly.

Handoffs should be short-lived. When an investigation establishes a durable
fact, move that fact into the appropriate README, architecture, development,
testing, or methodology document. Do not accumulate handoffs as a parallel
documentation system.

## Updating Documentation

Before adding documentation:

1. search for an existing canonical home
2. update that document instead of repeating it
3. distinguish verified behavior from plans or research hypotheses
4. add a link from the repository's documentation index when creating a new
   durable document
5. remove or correct stale statements when the implementation changes

Prefer small corrections and consolidation over broad rewrites.
