# NPPatch

**A community-owned, open-source Salesforce package for nonprofit organizations — built on the Nonprofit Success Pack (NPSP) codebase.**

## What Is NPPatch?

NPPatch consolidates the open-source Nonprofit Success Pack into a single, namespaced, unlocked second-generation package (2GP) that the nonprofit community can install, extend, and maintain independently. The original NPSP was distributed as Salesforce-controlled managed packages — NPPatch changes that by giving organizations the ability to install, upgrade, and modify the package on their own terms.

## Why Does This Exist?

Salesforce has announced end of innovation for NPSP, with no further feature development planned. This has left many organizations — particularly smaller nonprofits and the consultants who serve them — without a clear path forward. NPPatch exists to ensure that continuing on a community-maintained version of the platform they already know remains a viable option.

## What's In the Package?

NPPatch includes the full NPSP feature set, consolidated from the original five managed packages into a single codebase:

- **Household and Organization Account Management** — automatic household creation, account naming, address management
- **Recurring Donations** — schedule management, change tracking, and forecasting
- **Gift Entry and Batch Data Import** — form-based gift entry with template support, plus batch import tools
- **Customizable Rollups** — flexible rollup calculations across Accounts, Contacts, Households, and GAUs
- **GAU Allocations** — allocation of donations across General Accounting Units for fund accounting
- **Relationships and Affiliations** — contact-to-contact relationships with reciprocal tracking, plus organizational affiliations
- **Engagement Plans** — task-based engagement workflows triggered by donor activity
- **Payment Management** — payment scheduling, tracking, and write-off support
- **Levels** — automated donor level assignment based on giving history
- **Error Logging** — centralized error capture and admin notification

## Technical Details

| Detail | Value |
|--------|-------|
| Package Type | Namespaced Unlocked 2GP |
| Namespace | `nppatch` |
| Salesforce API Version | 63.0 |
| Build Tool | CumulusCI 4.6+ |
| Architecture | Apex Enterprise Patterns (fflib) with TDTM trigger framework |
| Custom Objects | 30+ |
| Custom Settings | 21 hierarchy settings for configuration |
| Apex Classes | 800+ |
| Lightning Web Components | 99 |
| Test Coverage Target | 75%+ |

## Getting Started

For guidance on when NPPatch makes sense and what to consider, start with the [Getting Started Overview](docs/getting-started/overview.md).

- [**Package Installation**](docs/getting-started/package-installation.md) — install the package into a Salesforce org using an install link
- [**Source Deployment**](docs/getting-started/source-deployment.md) — clone the repository and deploy from source using CumulusCI
- [**Post-Install Configuration**](docs/getting-started/post-install-configuration.md) — settings to review after installation

## Documentation

Full documentation is available at [`nppatch.readthedocs.io`](https://nppatch.readthedocs.io/en/latest/).

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
3. Run `cci org browser dev` to open the org in your browser.

## License

This project is licensed under the [BSD 3-Clause License](LICENSE).

NPPatch is built on the open-source code from the Salesforce.org Nonprofit Success Pack repositories. The original NPSP code was released under the same BSD-3-Clause license, and NPPatch follows those terms. The five original packages have been consolidated into a single repository and package — the code, objects, and automation are functionally equivalent; what's changed is the packaging and distribution model.

## Contact

For questions, feedback, or to get involved: **admin@nppatch.com**
