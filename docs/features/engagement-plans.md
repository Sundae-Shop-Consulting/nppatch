# Engagement Plans

Engagement Plans provide task-based workflow templates that enable nonprofits to automate multi-step engagement processes. When an engagement plan is applied to a contact, account, opportunity, or campaign, the system automatically creates a set of tasks with configurable timing, assignments, and dependencies.

## Overview

Engagement Plans enable standardized, repeatable engagement workflows:

- **Templates**: Reusable task templates with timing and assignment rules
- **Plans**: Instances of templates applied to specific records (contacts, accounts, etc.)
- **Dependent Tasks**: Chain tasks so some don't start until others complete
- **Automated Assignment**: Assign tasks to specific users or to the record owner
- **Email Notifications**: Send task assignment emails automatically
- **Progress Tracking**: Monitor completion across multiple engagement plans

## Core Objects

### Engagement_Plan_Template__c

Reusable workflow templates:

| Field | Purpose |
|-------|---------|
| `Name` | Template name |
| `Description__c` | Template purpose and use cases |
| `Owner__c` | Template creator/owner |
| `Default_Assignee__c` | Who gets tasks (user, record owner, etc.) |
| `Status__c` | Active, Inactive, Archived |
| `Send_Email_On_Create__c` | Whether to email assignees when tasks created |

### Engagement_Plan_Task__c

Task definition within a template:

| Field | Purpose |
|-------|---------|
| `Engagement_Plan_Template__c` | Parent template |
| `Name` | Task name |
| `Description__c` | Task details |
| `Subject__c` | Task subject line |
| `Comments__c` | Notes for assignee |
| `Days_After_Plan_Start__c` | How many days after plan creation this task starts |
| `Send_Email__c` | Send email to assignee when created |
| `Parent_Task__c` | Task that must complete before this |
| `Priority__c` | High, Normal, Low |
| `Type__c` | Task type (call, email, meeting, etc.) |
| `Reminder_Days__c` | Days before due date to remind assignee |

### Engagement_Plan__c

Instance of a template applied to a record:

| Field | Purpose |
|-------|---------|
| `Engagement_Plan_Template__c` | Which template this plan uses |
| `Contact__c` | Contact this plan applies to |
| `Account__c` | Account this plan applies to |
| `Opportunity__c` | Opportunity this plan applies to |
| `Campaign__c` | Campaign this plan applies to |
| `Start_Date__c` | When the plan started |
| `Status__c` | In Progress, Completed, Cancelled |
| `Comments__c` | Notes about this plan instance |

Only one of Contact, Account, Opportunity, or Campaign should be populated.

## Template Builder

### Managing Templates

Engagement plan templates are created and managed through the `EP_ManageEPTemplate_CTRL` controller and related LWC components:

**Features:**

- Create and edit templates without code
- Add tasks to templates
- Set task sequence and timing
- Configure task assignments and email options
- Preview task hierarchy
- Activate/deactivate templates

### Template Structure

Templates follow a hierarchical structure:

```
Engagement Plan Template: "New Donor Stewardship"
├── Task 1: "Initial Thank You Call" (due immediately)
├── Task 2: "Send Donation Receipt" (due day 2)
├── Task 3: "Schedule Second Meeting" (due day 7, depends on Task 2)
├── Task 4: "Annual Giving Proposal" (due day 30, depends on Task 3)
└── Task 5: "Follow-up Call" (due day 45, depends on Task 4)
```

Tasks within a template are processed in:
1. **Days offset** order (day 0, day 2, day 7, etc.)
2. **Dependency** order (parents before children)

## Task Creation and Assignment

### Automatic Task Generation

When an Engagement_Plan__c is inserted, the `EP_EngagementPlans_TDTM` trigger:

1. **Validate Plan**: Ensures exactly one lookup field is populated (Contact, Account, Opportunity, or Campaign)
2. **Load Template**: Retrieves Engagement_Plan_Template__c and related Engagement_Plan_Task__c records
3. **Create Tasks**: For each task in template, creates a Task record:
   - Sets subject and description
   - Calculates due date based on plan start date + Days_After_Plan_Start__c
   - Assigns task based on template Default_Assignee__c
   - Sets task type/priority from template task

### Task Assignment Rules

The `EP_EngagementPlans_UTIL` class determines task ownership:

| Assignment | Behavior |
|-----------|----------|
| Specific User | Task assigned to that user |
| Record Owner | Task assigned to owner of Contact/Account/Opportunity/Campaign |
| User Creating | Task assigned to user who created the engagement plan |
| Blank | Task assigned to default user or current user |

### Email Notification

For tasks with `Send_Email__c` enabled:

1. Task is created with email option
2. Salesforce sends email to assignee with task details
3. Email includes task subject, description, and due date
4. Parent tasks (dependencies) don't send emails automatically

## Dependent Tasks and Sequencing

### Task Dependencies

The `Parent_Task__c` field creates task dependencies:

```
Task 1: "Send Proposal" (Parent_Task__c = null)
Task 2: "Follow-up Call" (Parent_Task__c = Task 1)
Task 3: "Close Meeting" (Parent_Task__c = Task 2)
```

Dependencies prevent parallel task execution:

1. Task 1 must complete before Task 2 is created
2. Task 2 must complete before Task 3 is created
3. This ensures sequential workflows

### Dependency Logic

The `EP_TaskDependency_TDTM` trigger:

1. Monitors task completion on related tasks
2. When a parent task is marked complete, creates child task
3. Calculates child task due date relative to completion
4. Sends emails if configured

### No Parallel Tasks

Unlike some workflow systems, dependent tasks are sequential:

- Parent task must be `Completed` status
- Child task creation is triggered by parent completion
- Organization controls timing through task due dates

## Task Status and Rollup

### Task Status Tracking

Tasks created from engagement plans have standard Salesforce status values:

- **Open**: Task not started
- **In Progress**: Task actively worked
- **Completed**: Task finished
- **Deferred**: Task postponed
- **Waiting on Someone Else**: Task blocked

### Engagement Plan Completion

The `EP_EngagementPlans_TDTM` tracks engagement plan completion:

- Engagement plan is "Completed" when all tasks are completed
- "In Progress" while tasks are open
- Can be manually set to "Cancelled"

### Task Rollup

The `EP_TaskRollup_TDTM` provides:

- Count of open tasks on each engagement plan
- Count of completed tasks
- Task completion percentage
- Last activity date

## Engagement Plan Validation

### Validation Rules

The `EP_EngagementPlanTaskValidation_TDTM` enforces:

1. **Single Lookup**: Exactly one of Contact, Account, Opportunity, Campaign is populated
2. **No Duplicate Types**: Can't have both Contact and Account populated
3. **Valid Template**: Referenced template exists and is active
4. **No Update of Lookups**: After creation, can't change which record the plan applies to

### Duplicate Task Prevention

Tasks are not automatically deduped, but:

- Organizations should carefully plan templates to avoid redundant tasks
- Task descriptions should clearly distinguish similar tasks
- Template testing should validate no unintended duplicates

## Template Examples

### New Donor Stewardship Template

```
"New Donor Stewardship"
├── Day 0: "Send Thank You Email" (assigned to record owner)
├── Day 3: "Log Donor Call" (depends on email)
├── Day 7: "Submit Donation Profile" (depends on call)
├── Day 14: "Schedule Next Meeting" (depends on profile)
└── Day 30: "Send Annual Report" (depends on meeting)
```

### Campaign Execution Template

```
"Campaign Execution Workflow"
├── Day 0: "Create Campaign Materials" (assigned to marketing)
├── Day 5: "Review Materials" (depends on creation)
├── Day 10: "Launch Campaign" (depends on review)
├── Day 21: "Report Results" (depends on launch)
└── Day 45: "Post-Campaign Analysis" (assigned to director)
```

### Volunteer Onboarding Template

```
"Volunteer Orientation"
├── Day 0: "Send Welcome Kit" (assigned to volunteer manager)
├── Day 1: "Schedule Training" (depends on welcome)
├── Day 3: "Conduct Training Session" (depends on scheduling)
├── Day 5: "Assign First Task" (depends on training)
└── Day 30: "30-Day Check-in" (depends on first task)
```

## Key Classes

### EP_EngagementPlans_TDTM

Main trigger handler for engagement plans:

1. BeforeInsert: Validates single lookup field populated
2. AfterInsert: Creates tasks from template
3. BeforeUpdate: Prevents changing target record (Contact, Account, etc.)

### EP_Task_UTIL

Task creation utility:

- `createTask(Engagement_Plan_Task__c, Engagement_Plan__c)`: Creates task record with timing
- `assignTask(Task, targetId)`: Sets WhoId or WhatId based on target object
- Task due date calculation from Days_After_Plan_Start__c
- Email sending logic

### EP_EngagementPlans_UTIL

Engagement plan utilities:

- `getTargetObjectField()`: Determines which field (Contact, Account, etc.) is populated
- `targetObjectIdMap`: Maps engagement plans to their target record IDs
- `targetOwnerMap`: Maps target records to owners for task assignment
- `templateMap`: Cache of templates and related tasks

### EP_TaskDependency_TDTM

Dependency management trigger handler:

- Monitors task status changes
- Creates dependent child tasks when parent completes
- Calculates child task due dates

### EP_TaskRollup_TDTM

Task rollup trigger handler:

- Counts open/completed tasks
- Updates engagement plan status
- Calculates completion percentage

## Integration Points

- **Contacts/Accounts/Opportunities/Campaigns**: Engagement plans apply to any of these
- **Tasks**: Creates Salesforce task records
- **User Assignments**: Assigns tasks to users/record owners
- **Email**: Sends notifications to assignees
- **Completion Tracking**: Task status drives engagement plan completion

## Use Cases

**Major Donor Cultivation**: Create multi-step engagement plan ensuring consistent stewardship touches (thank you call, newsletter, annual meeting invite, proposal).

**Event Workflow**: Apply engagement plan to event campaign to automate pre-event setup (send invitations, confirm attendance, prepare materials) and post-event follow-up.

**Volunteer Onboarding**: New volunteers get engagement plan that sequences training, background check, assignment, and 30-day check-in.

**Grant Management**: Track grant application workflow from prospect research through proposal, submission, award notification, and project kickoff.

**New Member Integration**: Membership organizations create engagement plans that sequence welcome, orientation, benefit enrollment, and first event invitation.
