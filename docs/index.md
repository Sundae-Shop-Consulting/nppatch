# NPPatch

**A community-owned, open-source Salesforce package for nonprofit organizations — built on the Nonprofit Success Pack (NPSP) codebase.**

## What Is NPPatch?

NPPatch is a Salesforce second-generation package (2GP) that consolidates the open-source Nonprofit Success Pack into a single, namespaced, unlocked package that the nonprofit community can install, extend, and maintain independently.

The original NPSP has been the backbone of Salesforce-based nonprofit operations for over a decade, powering donor management, recurring giving, household tracking, and more for thousands of organizations. But NPSP was always distributed as Salesforce-controlled managed packages, meaning the community could use the code but never truly own the distribution or innovate on it independently.

NPPatch changes that. By repackaging the open-source NPSP code as an unlocked 2GP, NPPatch gives organizations the ability to install, upgrade, and — if they choose — modify the package to meet their specific needs.

## Why Does This Exist?

Salesforce has announced end of innovation for NPSP. There will be no further feature development on the Nonprofit Success Pack. Salesforce's focus has shifted to Nonprofit Cloud (now branded Agentforce for Nonprofits).

This has left many organizations — particularly smaller nonprofits and the consultants who serve them — in a difficult position. Some are moving to Nonprofit Cloud not because they believe it's the best fit, but because they feel it's their only option.

**NPPatch exists to make sure that isn't true.**

This project is not anti-Nonprofit Cloud. There's genuinely exciting work going into that platform. The goal is simply to ensure that organizations can make an informed choice based on the facts: what each product does, what it costs to implement and maintain, what support looks like, and what the long-term trajectory is.

For many smaller organizations with existing NPSP implementations, continuing on a community-maintained version of the platform they already know may be the right answer. NPPatch makes that possible.

## Who Is This For?

NPPatch is designed for three audiences:

**Nonprofit organizations** currently running NPSP who want to continue using their existing platform with a path to community-driven updates and bug fixes, without migrating to Nonprofit Cloud.

**Consultants and implementation partners** who want to offer their clients a genuine choice when evaluating Salesforce platforms for nonprofit work — especially for smaller organizations where Nonprofit Cloud's scope and cost may not be the right fit.

**Developers and contributors** who want to participate in an open-source effort to keep the NPSP platform viable and evolving.

## What's In the Package?

NPPatch includes the full NPSP feature set, consolidated from the original five managed packages into a single codebase:

- **Household and Organization Account Management** — automatic household creation, account naming, address management
- **Recurring Donations** — enhanced recurring donation support with schedule management, change tracking, and forecasting
- **Gift Entry and Batch Data Import** — form-based gift entry with template support, plus batch import tools for migrating or bulk-loading data
- **Customizable Rollups** — flexible rollup calculations across Accounts, Contacts, Households, and General Accounting Units
- **GAU Allocations** — allocation of donations across General Accounting Units for fund accounting
- **Relationships and Affiliations** — contact-to-contact relationships with reciprocal tracking, plus organizational affiliations
- **Engagement Plans** — task-based engagement workflows triggered by donor activity
- **Payment Management** — payment scheduling, tracking, and write-off support tied to opportunities
- **Levels** — automated donor level assignment based on giving history
- **Error Logging** — centralized error capture and admin notification

## Technical Details at a Glance

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

If you're a consultant evaluating NPPatch for a client, start with the [Getting Started Overview](getting-started/overview.md) for guidance on when NPPatch makes sense and what to consider.

For installation, you have two paths:

- [**Package Installation**](getting-started/package-installation.md) — install the package into a Salesforce org using an install link
- [**Source Deployment**](getting-started/source-deployment.md) — clone the repository and deploy from source using CumulusCI (for development or contributing)

After installation, see [Post-Install Configuration](getting-started/post-install-configuration.md) for the settings you'll need to review.

## Open-Source Lineage

NPPatch is built on the open-source code from the Salesforce.org Nonprofit Success Pack repositories. The original NPSP code was released under open-source licensing, and NPPatch follows those same license terms.

The five original NPSP packages — TDTM (trigger framework), Contacts & Organizations, Households, Recurring Donations, and the main Nonprofit Success Pack — have been consolidated into a single repository and single package. The code, objects, and automation are functionally equivalent; what's changed is the packaging and distribution model.

!!! note "On Copyright and Documentation"
    All documentation in this project is original writing based on analysis of the open-source codebase. It describes what the code does, how it's structured, and how to work with it. This documentation is not derived from Salesforce's proprietary documentation.
