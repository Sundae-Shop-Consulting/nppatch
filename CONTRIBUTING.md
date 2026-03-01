# Contributing to NPPatch

Thanks for your interest in contributing. NPPatch is a community-maintained project and we welcome contributions — bug fixes, improvements, and new features that serve the nonprofit Salesforce ecosystem.

## Before You Start

- Check open issues to avoid duplicating work in progress
- For significant changes, open an issue first to discuss the approach before writing code
- All contributions must be compatible with the [BSD 3-Clause License](LICENSE)

## Development Setup

1. Install [CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Install Node.js 20+ (required for linting)
3. Clone the repo and run `npm install` to set up linting dependencies
4. Run `cci flow run dev_org --org dev` to spin up a scratch org
5. Run `cci org browser dev` to open it

## Architecture

This codebase follows **Apex Enterprise Patterns** (fflib) with the **TDTM trigger framework**. Before contributing Apex, familiarize yourself with these patterns — new code should fit the existing architecture rather than work around it.

The main layers are:

- `domain/` — trigger handlers and domain logic (fflib Domain layer)
- `selector/` — SOQL queries (fflib Selector layer)
- `service/` — business logic (fflib Service layer)
- `tdtm/` — TDTM trigger dispatch
- `bdi/` — Batch Data Import
- `adapter/` — integration adapters

LWC components live in `force-app/nppatch-main/default/lwc/`.

## Code Standards

**Linting is enforced in CI.** Before submitting a PR, run:

```bash
npm run lint          # ESLint for JavaScript/LWC
npm run prettier      # Prettier formatting check for JS, HTML, CSS, and Apex
```

To auto-fix what can be fixed automatically:

```bash
npm run lint:fix
npm run prettier:fix
```

PMD static analysis runs on all Apex in CI. Fix violations before submitting — don't suppress warnings without a comment explaining why.

Beyond what the linters enforce:

- Follow separation of concerns — keep business logic in service classes, queries in selectors, trigger logic in domain classes
- Use clear, descriptive names. Abbreviations are fine when they're idiomatic to Salesforce (e.g. `opp`, `acct`), not when they obscure meaning
- Don't replicate patterns from older parts of the codebase — some of it predates the fflib refactor. When in doubt, look at the service and domain layers for examples of the current approach

## Tests

- All new Apex must have test coverage
- Tests live in `force-app/nppatch-main/test/` and follow the `_TEST` suffix convention (e.g. `ContactServiceTests_TEST.cls`)
- Target 75%+ coverage; aim higher for complex logic
- Tests should assert behavior, not just exercise code for coverage

## Submitting a Pull Request

PRs should target the `main` branch. Use the PR template — the section headings (`# Critical Changes`, `# Changes`, `# Issues Closed`) are required as-is because CumulusCI uses them to generate release notes.

Keep PRs focused. A PR that does one thing is easier to review and faster to merge than one that bundles multiple changes.

CI must pass before a PR will be reviewed. This includes the existing feature test workflow and the new lint checks.

## Questions

Open an issue or reach out at admin@nppatch.com.
