# GitHub submission protocol

## Required branch

All subsequent work products should be committed to the Git branch:

`Sea_Surface_Simulation`

## Required artifact format

When the assistant produces substantive written output, the content should also be saved as a Markdown file under the project workspace, preferably in `Writing/` unless another location is more appropriate.

Examples:

- Research memory and paper-positioning notes: `Writing/*.md`
- Draft abstracts, introductions, method sections, experiment plans, and response text: `Writing/*.md`
- Generated code, figures, tables, scripts, or data files: saved under the project workspace with a clear filename, then included in the same Git branch.

## Commit expectation

Each meaningful step should be committed to the `Sea_Surface_Simulation` branch after files are created or updated.

Before committing, verify:

1. The working directory is inside the intended repository.
2. The current branch is `Sea_Surface_Simulation`.
3. Only files relevant to the current step are staged.
4. The commit message briefly describes the completed step.

## Current blocker

At the time this protocol file was created, the workspace contained an empty `.git` directory without `HEAD` or `config`, so it was not a valid Git repository yet. A valid local Git repository and GitHub remote are required before commits can be made and pushed.

