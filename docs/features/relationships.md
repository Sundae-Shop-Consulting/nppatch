# Relationships

The Relationships feature enables nonprofits to model and track connections between people within their organization. Organizations can define relationships such as family connections, professional affiliations, and organizational roles while automatically maintaining reciprocal relationships and generating relationship views for staff.

## Overview

Relationships provide a flexible way to represent how people connect to each other:

- **Family Relationships**: Parent, child, spouse, sibling
- **Professional Relationships**: Manager, colleague, mentor, advisor
- **Organizational Roles**: Board member, volunteer coordinator, campaign lead
- **Custom Relationships**: Any relationship type defined by the organization

The system automatically creates reciprocal relationships (if you're someone's boss, they're automatically your employee) and provides organization-wide relationship mapping.

## Relationship Object

### Relationship__c

Individual relationship records:

| Field | Purpose |
|-------|---------|
| `Contact__c` | The initiating contact |
| `Related_Contact__c` | The other contact in the relationship |
| `Type__c` | Relationship type (spouse, parent, employee, etc.) |
| `Reciprocal_Relationship__c` | Link to the reverse relationship |
| `Status__c` | Active, Inactive, Terminated |
| `Status_Change_Date__c` | When status last changed |
| `Description__c` | Additional context about relationship |
| `Start_Date__c` | When relationship began |
| `End_Date__c` | When relationship ended |
| `Primary__c` | Whether this is primary relationship of type |
| `System_Created__c` | Whether auto-created vs. manual |

## Reciprocal Relationships

### Automatic Reciprocal Creation

When a relationship is created, the system automatically creates the reverse:

**Example: Creating a Parent Relationship**

```
Relationship 1: Mary (Contact__c) → John (Related_Contact__c), Type = Parent
Relationship 2: John (Contact__c) → Mary (Related_Contact__c), Type = Child
(Reciprocal_Relationship__c links them together)
```

The `REL_Relationships_TDTM` trigger handler manages:

1. **BeforeInsert**: Validates relationship data
2. **AfterInsert**: Creates reciprocal relationship
3. **BeforeUpdate**: Prevents changing relationship direction
4. **AfterUpdate**: Syncs field changes to reciprocal

### Reciprocal Pairing

Two relationships always form a pair:

- Contact A → Contact B has `Reciprocal_Relationship__c` pointing to B → A
- Contact B → Contact A has `Reciprocal_Relationship__c` pointing to A → B
- Deleting one automatically deletes the reciprocal

### Field Syncing Across Reciprocals

Custom fields sync across reciprocal pairs (if enabled):

| Synced Fields | Non-Synced Fields |
|---------------|------------------|
| Custom text fields | Contact and Related Contact |
| Custom picklists | Reciprocal Relationship link |
| Custom numbers | Relationship Type |
| Custom dates | System Created flag |

Excluded fields prevent modification on reciprocal. Field sync is configurable via:

- `Relationship_Field_Sync_Settings__c`: Custom setting for field exclusions
- `Enable_Custom_Field_Sync__c`: Toggle on/off in Relationship_Settings__c

## Relationship Types and Mapping

### Relationship_Lookup__c

Defines available relationship types:

| Field | Purpose |
|-------|---------|
| `Name` | Relationship type name |
| `Reciprocal_Type__c` | Corresponding type for reciprocal |
| `Is_Reciprocal__c` | Whether this type has reciprocal |
| `Male_Suffix__c` | Suffix for male version (if gender-specific) |
| `Female_Suffix__c` | Suffix for female version |
| `Neutral_Suffix__c` | Suffix for non-binary/unspecified |

### Standard Relationship Types

Common relationship types included:

| Type | Reciprocal | Common Use |
|------|-----------|-----------|
| Parent | Child | Family relationships |
| Spouse | Spouse | Marriage |
| Sibling | Sibling | Family connections |
| Manager | Employee | Workplace hierarchy |
| Colleague | Colleague | Professional teams |
| Board Member | Board Member | Board relationships |
| Mentor | Mentee | Professional development |
| Donor | Recipient | Charitable giving |

### Type Mapping Configuration

Organizations can customize or disable relationship types through the `Relationship_Lookup__c` configuration. Example customization:

**Create a custom "Volunteer Coordinator" type:**

```
Name: Volunteer Coordinator
Reciprocal_Type__c: Volunteer
Is_Reciprocal__c: true
```

## Relationship Auto-Creation

### Relationship_Auto_Create__c

Configuration for automatically creating relationships from contact fields:

| Field | Purpose |
|-------|---------|
| `Contact_Field_Name__c` | Contact field to monitor |
| `Related_Contact_Field__c` | Field on related contact |
| `Relationship_Type__c` | Type of relationship to create |
| `Auto_Create_Enabled__c` | Whether auto-creation is active |

### Auto-Creation Rules

Auto-creation can monitor standard and custom contact fields:

**Example: Relationship from Spouse field**

When a contact's `Spouse__c` field is populated, automatically:
1. Create relationship: Contact A → Spouse Contact, Type = Spouse
2. Create reciprocal: Spouse Contact → Contact A, Type = Spouse

### Preventing Duplicate Auto-Creation

If a relationship already exists between two contacts:
- Auto-creation skips if reciprocal pair already exists
- Manual relationships are not replaced
- Field changes that would create duplicates are ignored

## Relationship Auto-Create Trigger Handler

The `REL_Relationships_Cm_TDTM` trigger handler:

1. Monitors contact field changes
2. Evaluates auto-create rules
3. Creates relationships for newly linked contacts
4. Deletes relationships when contact field is cleared

Example: If a contact's "Spouse__c" field is set to a spouse contact ID:
1. Check if Spouse auto-create rule exists
2. Create Relationship: Contact → Spouse, Type = Spouse
3. Reciprocal auto-creates: Spouse → Contact, Type = Spouse

## Affiliations

### Affiliation__c

Organizational relationships tracking affiliation with accounts/organizations:

| Field | Purpose |
|-------|---------|
| `Contact__c` | The person |
| `Organization__c` | The organization (Account) |
| `Role__c` | Person's role in organization |
| `Status__c` | Active, Inactive, Terminated |
| `Start_Date__c` | When affiliation began |
| `End_Date__c` | When affiliation ended |
| `Primary_Org__c` | Whether primary affiliation |
| `Type__c` | Staff, Volunteer, Donor, Partner |

### Affiliation vs. Relationship

- **Relationships**: Contact-to-Contact connections
- **Affiliations**: Contact-to-Organization connections

Organizations can track:

- Staff members and their roles
- Volunteer affiliations with organizations
- Board service history
- Donor affiliation with organizations they support

### Affiliations Settings

`Affiliations_Settings__c` controls:

- Affiliation auto-creation from contact account field
- Default role for auto-created affiliations
- Affiliation type defaults

## Relationships Viewer Component

### Relationships Viewer UI

The `relRelationshipViewer` Lightning component displays relationships graphically:

- **Network Visualization**: Shows connected contacts
- **Relationship Details**: Lists all relationships for a contact
- **Quick Actions**: Add/edit/delete relationships from component
- **Filtering**: Filter by relationship type
- **Search**: Find specific contacts in relationship network

### Relationship Viewer Features

- **Two-Way View**: See how contact relates to others and vice versa
- **Depth Control**: Display 1st degree or multi-degree connections
- **Visual Clustering**: Groups related connections
- **Tooltips**: Hover for relationship details
- **Mobile Support**: Responsive design on phone/tablet

## Relationship Settings

### Relationship_Settings__c

Organization-wide relationship configuration:

| Setting | Purpose |
|---------|---------|
| Relationships Enabled | Activates the relationships feature |
| Relationship Auto Create | Enables auto-creation from contact fields |
| Allow Custom Field Sync | Whether custom fields sync across reciprocals |
| Default Reciprocal Type | Default type when creating relationships |
| Enable Multiple Relationships | Allow multiple same-type relationships |
| Prevent Same-Contact Relationships | Prevent someone relating to themselves |

### Affiliations_Settings__c

Organization-specific affiliation settings:

| Setting | Purpose |
|---------|---------|
| Affiliations Enabled | Activates organizational affiliations |
| Auto Create Affiliation | Auto-create from contact account field |
| Primary Org | Default organization for affiliations |
| Default Affiliation Role | Default role when auto-creating |
| Default Affiliation Type | Employment type vs. volunteer, etc. |

## Key Classes

### REL_Relationships_TDTM

Trigger handler managing relationship creation and updates:

1. **BeforeInsert**: Validates relationship values
2. **AfterInsert**: Creates reciprocal relationship
3. **BeforeUpdate**: Prevents relationship direction changes
4. **AfterUpdate**: Syncs custom field changes to reciprocal
5. **BeforeDelete**: Prevents orphaning reciprocal
6. **AfterDelete**: Cleans up reciprocal relationship

### REL_Relationships_Cm_TDTM

Contact trigger handler managing auto-creation:

1. Monitors contact field changes
2. Evaluates auto-create rules
3. Creates/deletes relationships based on field values

### RelationshipsService

Service class for relationship operations:

- Creating relationships with validation
- Querying relationship networks
- Building relationship hierarchies
- Relationship statistics (e.g., number of connections)

## Integration Points

- **Contacts**: Relationships link two contacts together
- **Accounts**: Affiliations link contacts to organizations
- **Opportunities**: Can track relationship between contact and opportunity (through OpportunityContactRole)
- **Campaigns**: Relationship data can segment campaigns by family/team

## Use Cases

**Family Giving Program**: Track family relationships and identify family members to include in annual fund solicitations.

**Board and Committee Management**: Use relationships and affiliations to track board member roles, committee assignments, and organizational history.

**Referral Tracking**: Create relationships to track which donors referred other donors, enabling referral-based stewardship.

**Staff Directory**: Implement organizational hierarchy with manager-employee relationships and role affiliations.

**Volunteer Coordination**: Affiliations track volunteer history, roles, and active assignments across organization.

**Wealth Screening**: Relationships identify family networks for prospect research and cultivation planning.

**Contact Merge Safety**: Before merging duplicate contacts, review relationships to avoid losing connection data.
