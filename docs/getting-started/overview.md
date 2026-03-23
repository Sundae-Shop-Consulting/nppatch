# Getting Started Overview

This guide is written for Salesforce consultants and implementation partners evaluating NPPatch as a platform option for nonprofit clients. It covers what NPPatch provides, when it's a good fit, and what to consider when making a recommendation.

## When NPPatch Makes Sense

NPPatch is a strong fit for organizations that meet some or all of these criteria:

**Already running NPSP.** Organizations with an existing NPSP implementation have staff trained on the platform, data already structured around NPSP objects, and workflows built on NPSP automation. NPPatch preserves that functional knowledge. A migration is required since NPPatch operates under a different namespace (`nppatch` vs `npsp`), but the migration is relatively straightforward — there's a direct mapping between NPSP and NPPatch objects, fields, and automation in most cases. Staff won't need to relearn the platform, and existing workflows translate directly.

**Smaller organizations with straightforward needs.** Organizations that primarily need donor management, recurring giving, household tracking, and basic reporting may find that the NPSP feature set already covers their requirements. NPPatch keeps that feature set available without requiring a move to a more complex platform.

**Cost-sensitive implementations.** For organizations where the implementation and ongoing license costs of Nonprofit Cloud are a concern, NPPatch provides a fully functional alternative at the cost of community-maintained support rather than vendor-backed support.

**Organizations that want control.** Because NPPatch is an unlocked package, the community — not Salesforce — controls what gets built and when it ships. If an organization needs a fix, they can contribute it through the community repository, commission someone to build it, or wait for the community to address it. That's a meaningful difference from the original NPSP managed packages, where Salesforce controlled the release process. Organizations can also extend the package with their own customizations deployed on top.

## When Nonprofit Cloud May Be the Better Choice

Being fair about this: there are cases where Nonprofit Cloud is the right answer.

**Organizations needing features beyond NPSP's scope.** Nonprofit Cloud includes program management, outcome tracking, case management, and other capabilities that NPSP was never designed to handle. If a client needs these, Nonprofit Cloud offers them as part of the platform.

**Organizations that require vendor-backed support.** NPPatch is community-maintained. There is no Salesforce support contract, no guaranteed SLA, and no vendor standing behind the product. For organizations that need that level of support assurance, Nonprofit Cloud provides it.

**New implementations starting from scratch.** For a greenfield Salesforce implementation with no existing NPSP data or workflows, the calculus is different. Evaluate both platforms on their current merits rather than defaulting to either one.

**Organizations on a trajectory toward enterprise complexity.** If a client is growing rapidly and will likely need the broader Nonprofit Cloud feature set within 1-2 years, starting there may avoid a future migration.

## What Consultants Should Know

### It's the Same Code

The NPPatch codebase is the open-source NPSP code, consolidated from five repositories into one. The objects, fields, automation, Apex classes, and Lightning components are functionally the same as what your clients are already running if they're on NPSP.

### The Namespace Is Different

NPPatch uses the `nppatch` namespace rather than `npsp`. This means that custom fields, objects, and Apex classes will be prefixed with `nppatch__` rather than `npsp__`. For existing NPSP orgs, this is significant — it means NPPatch is not a drop-in replacement that can simply upgrade over an existing NPSP managed package installation. A migration path would need to account for the namespace difference.

!!! warning "Namespace Implications"
    Because NPPatch uses a different namespace (`nppatch`) than the original NPSP (`npsp`), migrating an existing NPSP org to NPPatch requires data migration and reconfiguration — not a simple package swap. This is a critical consideration when advising clients.

### It's an Unlocked Package

Unlike the original NPSP (which was a managed package), NPPatch is an unlocked package. This has practical implications:

**Advantages:**

- The community controls the release process: what gets built, what gets fixed, and when new versions ship
- No dependency on Salesforce for bug fixes — contributors can address issues through the repository without waiting for a vendor roadmap
- Organizations can deploy customizations and extensions on top of the package (custom fields on package objects, new TDTM trigger handlers, companion packages)

**Tradeoffs:**

- Community-maintained means there is no vendor-backed support contract or guaranteed SLA
- Organizations take on responsibility for evaluating and applying upgrades
- The freedom is in the release process, not in-org editing — to change package code, contributors work from the source repository

See the [Customization Guide](../customization/unlocked-package-guide.md) for detailed guidance on managing these tradeoffs.

### The Upgrade Path

NPPatch's namespace means new versions of the package can be published and installed as upgrades to existing NPPatch installations. This is the mechanism for distributing bug fixes and new features to the community.

Organizations that haven't modified the package code can upgrade normally. Organizations that have modified package code should review release notes carefully before upgrading, as their customizations could be overwritten.

## Evaluation Checklist for Consultants

When evaluating NPPatch for a client, consider:

1. **Current state**: Is the client currently on NPSP? If so, how heavily customized is their implementation?
2. **Feature requirements**: Does the client need capabilities that exist only in Nonprofit Cloud (program management, case management, outcome tracking)?
3. **Support expectations**: Is the client comfortable with community-maintained software, or do they require vendor-backed support?
4. **Technical capacity**: Does the client (or their consultant) have the technical skills to manage an unlocked package, apply upgrades, and troubleshoot issues?
5. **Budget**: What are the comparative costs of Nonprofit Cloud licensing and implementation vs. NPPatch (which has no license cost but requires community or consultant support)?
6. **Timeline**: If the client needs new capabilities now, which platform delivers them sooner?
7. **Migration complexity**: If migrating from NPSP, what's the effort involved in moving to the `nppatch` namespace vs. moving to Nonprofit Cloud's data model?

## Next Steps

Once you've decided NPPatch is worth exploring for a client:

- **To test it yourself**, follow the [Package Installation](package-installation.md) guide to install NPPatch in a sandbox or developer org
- **To set up a development environment**, follow the [Source Deployment](source-deployment.md) guide to deploy from the repository using CumulusCI
- **To understand the technical architecture**, see the [Architecture Overview](../architecture/overview.md)

---

*If you see something that could be improved, please create an issue or email admin@nppatch.com.*
