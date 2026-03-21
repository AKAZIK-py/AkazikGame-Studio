## Summary

Bootstrap multi-agent workflow templates for this repository.

## What Changed

| Type | Path | Description |
|------|------|-------------|
| `new` | `docs/runs/README.md` | Agent run log index |
| `new` | `docs/templates/spec.md` | Spec template for formal specs |
| `new` | `docs/templates/plan.md` | Execution plan template |
| `new` | `docs/templates/evidence.md` | Acceptance evidence template |
| `new` | `docs/templates/control.json` | Machine-readable run control file |
| `new` | `.github/ISSUE_TEMPLATE/gameplay-feedback.yml` | Gameplay feedback issue template |
| `new` | `.github/pull_request_template.md` | PR description template |

## Rationale

These templates establish the baseline workflow for:

- **spec → plan → evidence → control** lifecycle for agent tasks
- **UX feedback collection** via GitHub Issues (gameplay-feedback template)
- **Consistent PR descriptions** using the PR template
- **Run log persistence** in `docs/runs/` for self-improving-agent to reference

## Next Steps

- Fill out `docs/runs/README.md` with first run entry
- Install `self-improving-agent` and `proactive-agent` skills (already installed)
- Configure `GITHUB_TOKEN` in environment for CI runs

## Testing

- [x] All files created via shell heredoc (no `gh api`)
- [x] Branch created off `main` / current HEAD
- [x] No existing files modified
- [x] Minimal self-check passed (`ls`, `git diff --stat`)
