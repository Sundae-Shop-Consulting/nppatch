# Household Management

Household Management in nppatch provides automated organization and administration of contact groupings, enabling nonprofits to consolidate individual family members or organizational members into a single household unit with shared addresses and contact information.

## Overview

The Household Management system supports two deployment models:

- **Household Accounts**: Contacts are linked to a standard Account record designated as a household, with shared billing address and donation rolling
- **Household Objects**: Organizations can use a custom Household__c object instead, providing an alternative data model for household organization

### Automatic Household Creation and Naming

When the Household feature is enabled, the system can automatically:

1. Create household records when new contacts are added
2. Generate household names based on configurable naming rules
3. Apply formal and informal greetings derived from household members
4. Update household membership counts

The `HH_Households` class defines processing modes that control when household creation occurs:

- `ALL_PROCESSOR`: All new or edited contacts are processed
- `ALL_INDIVIDUALS_PROCESSOR`: Only individual contacts (not organizations) are processed
- `NO_HOUSEHOLDS_PROCESSOR`: Household creation is disabled

## Address Management

The Address__c object provides sophisticated address handling across household members, supporting:

### Address Types and Features

- **Default Household Address**: The primary mailing address for the entire household
- **Contact Addresses**: Individual addresses for household members who have different addresses
- **Seasonal Addresses**: Support for seasonal variations with configurable start/end months and days
- **Address Override**: Contacts can have their own address distinct from the household default
- **Address History**: Addresses associated with households are tracked separately from contact mailing addresses

### Address Resolution

The system deduplicates and consolidates addresses through the `NPSP_Address` utility, which normalizes addresses for comparison. Key fields tracked:

- Street (including street2 fields for multi-line addresses)
- City, State, Postal Code, Country
- Undeliverable status for postal validation
- Latitude/Longitude for geospatial data

### Address Sync

When households use the Account model, the Account's billing address serves as the default household address. Changes to household addresses trigger synchronization:

1. Contacts without address overrides are marked as undeliverable if the household address is marked undeliverable
2. Address cleanup processes refresh address associations after household operations like merges

## Contact-to-Household Relationships

The `HH_Container_LCTRL` class powers the Manage Household user interface and enforces the following relationships:

### Household Membership Management

Each contact belongs to a single household (via AccountId for Account model, or Household__c for Household Object model). The system maintains:

- **Household_Naming_Order__c**: Integer field controlling the sequence in which contact names appear in household naming
- **Primary_Contact__c**: Boolean flag identifying the primary contact for the household
- **Household_Naming_Order Sorting**: Contacts are ordered by naming order (ascending), then by primary contact status (descending), then by creation date

### Contact Fields Affecting Household

The following contact fields directly influence household naming and greetings:

| Field | Purpose |
|-------|---------|
| `Exclude_from_Household_Name__c` | Removes contact from household name generation |
| `Exclude_from_Household_Formal_Greeting__c` | Removes contact from formal greeting |
| `Exclude_from_Household_Informal_Greeting__c` | Removes contact from informal greeting |
| `Naming_Exclusions__c` | Stores serialized exclusion data |
| `is_Address_Override__c` | Indicates contact uses a different address than household |
| `Current_Address__c` | Reference to the address record the contact currently uses |
| `Primary_Address_Type__c` | Categorizes the contact's address type |
| `Undeliverable_Address__c` | Synced from household if contact has no override |

## Household Naming

The household naming system is highly configurable and supports multiple naming strategies:

### Naming Configuration

Settings are stored in `Household_Naming_Settings__c` custom setting and support:

- **Custom Format Strings**: Templates using contact field values (e.g., "FirstName LastName" or "LastName Household")
- **Standard Formats**: Pre-built naming patterns for common scenarios
- **Formal Greetings**: Personalized salutations (e.g., "Dear Mr. and Mrs. Smith")
- **Informal Greetings**: Casual greetings (e.g., "Hi John and Jane")

### Naming Service

The `HouseholdNamingService` class processes naming through:

1. **Contact Field Extraction**: Reads all contact fields specified in naming rules
2. **Exclusion Evaluation**: Applies per-contact and per-field exclusions
3. **Name Generation**: Builds names from included contacts using the format template
4. **Greeting Generation**: Constructs formal and informal greetings

### Batch Naming Operations

The `HH_HouseholdNaming_BATCH` class handles:

- **Initial Activation**: When naming is first turned on, marks existing household names as custom-named (preventing auto-update)
- **Bulk Refresh**: Recalculates all household names when naming rules change
- **Selective Refresh**: Updates specific households

## Household Merging

The Manage Household UI supports merging multiple household Accounts into a single winning household. The merge operation:

1. Consolidates all contacts from losing households into the winner
2. Preserves contact relationships and history
3. Updates sustainer tracking if recurring donations are enabled
4. Refreshes address associations through cleanup processes

## Household Settings

Configuration is managed through `Households_Settings__c`, which controls:

| Setting | Effect |
|---------|--------|
| Automatic Household Creation | Enables/disables auto-creation; selects processor mode |
| Advanced Household Naming | Enables custom naming formats vs. standard approach |
| Household Naming Format | Format string for name generation |
| Custom Field Sync | Whether custom fields sync across reciprocal relationships |

## Key Classes and Controllers

### HH_Container_LCTRL
Server-side controller for the Manage Household Lightning component. Responsibilities:

- Load household and contact records with field-level security checks
- Retrieve household and contact addresses (merged from Address__c and contact fields)
- Process contact and household updates
- Handle household merges
- Calculate household names and greetings

### HH_Households
Constants defining household processor modes and system behavior flags.

### HH_HouseholdNaming_BATCH
Batchable class for bulk household naming operations during activation or rule changes.

### HouseholdNamingService
Core service for generating household names and greetings based on contact and naming rule data.

## Use Cases

**Consolidating Family Giving**: Create a household for each family, view aggregate donation history and engagement across family members while maintaining individual contact records.

**Organizational Relationships**: Group staff members or board members within an organization account, tracking which individuals have primary roles.

**Address Management**: Maintain a single household mailing address while allowing individuals to opt in to receiving mail at their personal address.

**Bulk Naming Updates**: Change household naming rules organization-wide (e.g., from last names to formal "The [Last Name] Family" format) with a single batch operation.

## Integration Points

- **Opportunity Contact Roles**: Household management preserves opportunity contact role associations during merges
- **Recurring Donations**: Sustainer status on household accounts is updated after merges to reflect all active recurring donations
- **Address Validation**: Integration with undeliverable address tracking ensures mail synchronization across household
