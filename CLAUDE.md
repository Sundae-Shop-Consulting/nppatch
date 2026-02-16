# Project Instructions

## DO NOT
- Do not run `cci flow run dev_org` or `cci flow run release_unlocked_beta` without explicit permission
- Do not run long-running deployment or package commands automatically
- Do not push to git without explicit permission

## Preferences
- When making changes, describe what to test but let me run the commands
- Summarize changes made and provide the commands I should run to verify

## Pull Requests
- When creating PRs, use the template in `.github/PULL_REQUEST_TEMPLATE.md`
- PR descriptions MUST use H1 headings (`# Changes`, `# Critical Changes`, `# Issues Closed`) for CumulusCI release notes parsing
- Do NOT use `## Summary` or other H2 headings as the primary structure
