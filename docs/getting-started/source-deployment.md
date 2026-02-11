# Source Deployment

This guide covers setting up a development environment and deploying NPPatch from source using CumulusCI. This path is intended for developers contributing to the project, consultants who want to explore the codebase in a scratch org, or anyone who wants to build the package themselves.

## Prerequisites

### Salesforce CLI

Install the Salesforce CLI (sf), which is the foundation for working with Salesforce DX projects.

```bash
npm install -g @salesforce/cli
```

Verify the installation:

```bash
sf version
```

### CumulusCI

NPPatch uses CumulusCI (cci) as its build and automation tool. CumulusCI is a Python-based tool built by Salesforce.org specifically for managing the development lifecycle of Salesforce packages.

Install CumulusCI:

```bash
pip install cumulusci
```

Verify the installation:

```bash
cci version
```

NPPatch requires CumulusCI version 4.6.0 or later.

### Salesforce Dev Hub

You'll need a Salesforce org with Dev Hub enabled to create scratch orgs.

1. If you don't have a Dev Hub, sign up for a [Salesforce Developer Edition](https://developer.salesforce.com/signup)
2. Enable Dev Hub in **Setup > Dev Hub** (toggle it on)
3. Connect CumulusCI to your Dev Hub:

```bash
cci org connect devhub
```

This opens a browser window for OAuth authentication. Log in with your Dev Hub admin credentials.

### Git

Clone the NPPatch repository:

```bash
git clone https://github.com/Sundae-Shop-Consulting/nppatch.git
cd nppatch
```

## Creating a Development Org

The standard development workflow uses CumulusCI scratch orgs. The `dev_org` flow handles creating the org, deploying the code, and running post-deployment configuration.

### Quick Start

```bash
cci flow run dev_org --org dev
```

This command does the following:

1. Creates a scratch org using the default scratch org definition
2. Deploys the NPPatch source code to the org
3. Runs the `config_dev` flow, which:
    - Updates the admin profile with necessary permissions
    - Removes default layouts and profiles that aren't needed
    - Deploys development-specific configuration (custom fields, value sets, profile settings)
    - Initializes all custom settings with default values

The process typically takes 5-10 minutes.

### Opening the Org

Once deployment is complete, open the org in your browser:

```bash
cci org browser dev
```

### Org Definitions

The project includes several scratch org definitions in the `orgs/` directory, each designed for a different purpose:

| File | Edition | Purpose |
|------|---------|---------|
| `dev.json` | Developer | Day-to-day development and testing |
| `feature.json` | Developer | Testing specific features in isolation |
| `beta.json` | Developer | Testing beta package versions |
| `build.json` | Developer | Package builds (includes special API features) |
| `release.json` | Enterprise | Final validation against enterprise edition |

To use a specific org definition, configure a custom org:

```bash
cci org scratch dev my_org --config-file orgs/release.json
cci flow run dev_org --org my_org
```

## Project Structure

Understanding the repository layout helps when navigating and contributing to the codebase.

```
nppatch/
├── force-app/                  # All Salesforce metadata
│   ├── main/                   # Primary package source
│   │   ├── default/            # Standard metadata directory
│   │   │   ├── classes/        # Apex classes (~830)
│   │   │   ├── lwc/            # Lightning Web Components (~99)
│   │   │   ├── aura/           # Aura components (~50)
│   │   │   ├── objects/        # Custom and extended objects
│   │   │   ├── pages/          # Visualforce pages
│   │   │   ├── customMetadata/ # Custom metadata records
│   │   │   ├── labels/         # Custom labels
│   │   │   ├── layouts/        # Page layouts
│   │   │   └── ...
│   │   ├── adapter/            # Hexagonal architecture adapters
│   │   └── selector/           # Custom selector classes
│   ├── tdtm/                   # Trigger framework
│   │   ├── classes/            # TDTM framework classes
│   │   ├── triggers/           # Trigger definitions
│   │   └── triggerHandlers/    # Trigger handler implementations
│   ├── infrastructure/         # Third-party libraries
│   │   ├── apex-common/        # fflib base library
│   │   ├── apex-extensions/    # fflib extensions (dynamic binding)
│   │   └── apex-mocks/         # fflib mocking framework
│   └── test/                   # Shared test utilities
├── unpackaged/                 # Metadata deployed outside the package
│   ├── pre/                    # Deployed before the package
│   ├── config/                 # Development configuration
│   └── post/                   # Deployed after the package
├── scripts/                    # Build and configuration scripts
├── orgs/                       # Scratch org definitions
├── datasets/                   # Sample data for development
├── robot/                      # Robot Framework tests
├── cumulusci.yml               # CumulusCI project configuration
├── sfdx-project.json           # SFDX project configuration
└── mkdocs.yml                  # Documentation configuration
```

## Running Tests

### Apex Tests

Run all Apex tests in the connected org:

```bash
cci task run run_tests --org dev
```

The project requires a minimum of 75% code coverage.

### Robot Framework Tests

The project includes Robot Framework tests for UI and API validation:

```bash
cci task run robot --org dev
```

Test results are output to `robot/nppatch/results/`. To generate HTML documentation of test cases:

```bash
cci task run robot_testdoc
```

## Key CumulusCI Tasks

These are the custom CumulusCI tasks defined in `cumulusci.yml`:

| Task | Description |
|------|-------------|
| `deploy_dev_config` | Deploys development-specific configuration from `unpackaged/config/dev` |
| `deploy_dev_config_delete` | Removes unnecessary default layouts and profiles |
| `default_settings` | Initializes all custom settings with default values via Apex |
| `run_tests` | Runs Apex tests with 75% coverage requirement |
| `robot` | Runs Robot Framework test suites |
| `robot_testdoc` | Generates HTML test documentation |

## Building the Package

To build a new version of the 2GP package (requires appropriate Dev Hub permissions):

```bash
sf package version create --package nppatch --wait 30 --code-coverage
```

!!! note "Build Permissions"
    Package version creation requires a Dev Hub with second-generation packaging enabled and the `nppatch` package already registered. This is typically handled by the project maintainers.

## Common Development Workflows

### Making a Code Change

1. Create a scratch org: `cci flow run dev_org --org dev`
2. Open the org: `cci org browser dev`
3. Make your changes in the local source
4. Push changes to the org: `sf project deploy start --source-dir force-app`
5. Test in the org
6. Run tests: `cci task run run_tests --org dev`

### Refreshing Your Org

Scratch orgs expire after a set period (default 7 days). To start fresh:

```bash
cci org scratch dev dev --delete
cci flow run dev_org --org dev
```

### Loading Sample Data

The project includes a data mapping for loading sample data:

```bash
cci task run load_dataset --org dev
```

This loads sample Account and Contact records using the mapping defined in `datasets/mapping.yml`.

---

*This documentation was generated by AI and still needs human review. If you see something that could be improved, please create an issue or email admin@nppatch.com.*
