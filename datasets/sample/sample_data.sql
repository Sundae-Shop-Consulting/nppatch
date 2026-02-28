-- ==========================================================================
-- NPPatch Sample Dataset: Meadowlark Youth Literacy
-- ==========================================================================
-- A fictional youth literacy nonprofit in Portland, Oregon.
-- Demonstrates both fundraising (NPSP) and program management (PMM):
--
-- FUNDRAISING:
--   - Household and organization accounts
--   - Individual donations, recurring gifts, major gifts
--   - Foundation grants with deadlines
--   - Memberships, matching gifts, in-kind gifts, memorial gifts
--   - Pledges with scheduled payments
--   - Fund accounting with split allocations (GAUs)
--   - Soft credits (account and partial)
--   - Contact relationships and organizational affiliations
--   - Engagement plan templates and tasks
--   - Campaign hierarchy
--
-- PROGRAM MANAGEMENT:
--   - Literacy programs (tutoring, storytime, writing, family nights)
--   - Program cohorts (spring 2026 semester)
--   - Program engagements (clients, volunteers, service providers)
--   - Services with schedules and sessions
--   - Service participants and attendance tracking (service deliveries)
--
-- CROSSOVER (contacts who bridge fundraising and programs):
--   - Carlos Martinez: donor AND volunteer tutor
--   - Patricia Johnson: donor AND family literacy night volunteer
--   - James Johnson: donor AND family literacy night participant
--   - Elena Reyes: program parent AND connected to donor network
--
-- Load with:
--   cci task run load_dataset --mapping datasets/sample/mapping.yml --sql_path datasets/sample/sample_data.sql
--
-- Notes:
--   - load_dataset uses Bulk API by default, so NPSP triggers won't fire.
--     Rollup fields, reciprocal relationships, and household naming won't
--     auto-populate. Run rollup batches after loading if needed.
--   - Do_Not_Automatically_Create_Payment__c is set true on all Opportunities
--     since payments are loaded explicitly.
--   - RecordTypeId values are developer names; CCI resolves them to IDs.
--   - Dates are set relative to early 2026.
-- ==========================================================================


-- ============================================================
-- Campaigns
-- ============================================================
CREATE TABLE "Campaign" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "IsActive" VARCHAR(255),
    "Status" VARCHAR(255),
    "Type" VARCHAR(255),
    "StartDate" VARCHAR(255),
    "EndDate" VARCHAR(255),
    "Description" VARCHAR(255),
    "ExpectedRevenue" VARCHAR(255),
    "ParentId" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Campaign" VALUES('Campaign-1','Annual Fund 2026','true','In Progress','Direct Mail','2026-01-01','2026-12-31','Annual operating fund supporting all Meadowlark literacy programs and services','150000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-2','Spring Gala 2026','true','Planned','Event','2026-04-15','2026-04-15','Annual fundraising gala: dinner, silent auction, and student reading showcase','75000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-3','Year-End Appeal 2025','false','Completed','Email','2025-11-01','2025-12-31','Year-end giving campaign targeting lapsed and current donors','50000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-4','Capital Campaign 2025-2027','true','In Progress','Other','2025-01-01','2027-12-31','Multi-year capital campaign for literacy center renovation','500000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-5','Reading Center Renovation','true','In Progress','Other','2025-03-01','2026-06-30','Literacy center renovation: new reading rooms, tutoring labs, and community space','300000','Campaign-4');


-- ============================================================
-- General Accounting Units (Fund Accounting)
-- ============================================================
CREATE TABLE "General_Accounting_Unit__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Active__c" VARCHAR(255),
    "Description__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-1','General Fund','true','Unrestricted operating fund for day-to-day expenses');
INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-2','Literacy Programs','true','Restricted fund for program delivery: tutoring, book clubs, and literacy camps');
INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-3','Capital Campaign Fund','true','Restricted fund for literacy center renovation and construction');
INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-4','Scholarship & Book Fund','true','Restricted fund for student book stipends and reading materials');


-- ============================================================
-- Engagement Plan Templates
-- ============================================================
CREATE TABLE "Engagement_Plan_Template__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Description__c" VARCHAR(255),
    "Skip_Weekends__c" VARCHAR(255),
    "Default_Assignee__c" VARCHAR(255),
    "Automatically_Update_Child_Task_Due_Date__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Engagement_Plan_Template__c" VALUES('EPT-1','New Donor Welcome','Welcome and stewardship sequence for first-time donors','true','Owner of Object for Engagement Plan','true');
INSERT INTO "Engagement_Plan_Template__c" VALUES('EPT-2','Major Gift Cultivation','Multi-step cultivation plan for major gift prospects','true','Owner of Object for Engagement Plan','false');


-- ============================================================
-- Engagement Plan Tasks
-- ============================================================
CREATE TABLE "Engagement_Plan_Task__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Days_After__c" VARCHAR(255),
    "Priority__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "Type__c" VARCHAR(255),
    "Send_Email__c" VARCHAR(255),
    "Comments__c" VARCHAR(255),
    "Engagement_Plan_Template__c" VARCHAR(255),
    "Parent_Task__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- New Donor Welcome tasks
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-1','Welcome Phone Call','1','High','Not Started','Call','false','Personal thank-you call within 24 hours of first gift','EPT-1',NULL);
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-2','Send Thank-You Letter','3','Medium','Not Started','Other','true','Mail personalized thank-you letter with tax receipt','EPT-1',NULL);
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-3','Send Impact Report','30','Low','Not Started','Email','true','Share quarterly impact report showing how gifts support literacy programs','EPT-1','EPTask-2');

-- Major Gift Cultivation tasks
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-4','Initial Discovery Meeting','1','High','Not Started','Meeting','false','Meet to understand donor interests, capacity, and connection to literacy mission','EPT-2',NULL);
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-5','Follow-Up Call','14','Medium','Not Started','Call','false','Follow up on discovery meeting and answer questions','EPT-2','EPTask-4');
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-6','Present Gift Proposal','30','High','Not Started','Meeting','false','Present formal gift proposal aligned with donor interests','EPT-2','EPTask-5');


-- ============================================================
-- Programs (PMM)
-- ============================================================
CREATE TABLE "Program__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Description__c" VARCHAR(255),
    "ShortSummary__c" VARCHAR(255),
    "StartDate__c" VARCHAR(255),
    "EndDate__c" VARCHAR(255),
    "ProgramIssueArea__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Program__c" VALUES('Prog-1','Read to Lead','After-school reading tutoring pairing trained volunteers and tutors with students in grades 3-5 for one-on-one and small group reading sessions.','Core literacy tutoring for grades 3-5','2024-09-02',NULL,'Education','Active');
INSERT INTO "Program__c" VALUES('Prog-2','Emerging Readers','Early literacy program for Pre-K through grade 2 featuring interactive storytime circles, phonics play, and parent engagement activities.','Early literacy for Pre-K through grade 2','2024-09-02',NULL,'Education','Active');
INSERT INTO "Program__c" VALUES('Prog-3','Teen Writers Workshop','Creative writing program for middle school students (grades 6-8) combining book discussions, journaling, and peer writing workshops.','Creative writing for grades 6-8','2025-09-02',NULL,'Education','Active');
INSERT INTO "Program__c" VALUES('Prog-4','Family Literacy Nights','Monthly community events bringing families together for shared reading, book giveaways, and literacy activities for children ages 3-12.','Monthly family engagement events','2024-01-15',NULL,'Education','Active');


-- ============================================================
-- Program Cohorts (PMM)
-- ============================================================
CREATE TABLE "ProgramCohort__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Description__c" VARCHAR(255),
    "StartDate__c" VARCHAR(255),
    "EndDate__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "Program__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "ProgramCohort__c" VALUES('Cohort-1','Read to Lead - Spring 2026','Spring semester cohort with 8 students','2026-01-13','2026-05-29','Active','Prog-1');
INSERT INTO "ProgramCohort__c" VALUES('Cohort-2','Emerging Readers - Spring 2026','Spring semester storytime group','2026-01-13','2026-05-29','Active','Prog-2');
INSERT INTO "ProgramCohort__c" VALUES('Cohort-3','Teen Writers - Spring 2026','Spring semester writing cohort','2026-01-13','2026-05-29','Active','Prog-3');


-- ============================================================
-- Record Type Mappings (required by CCI load_dataset)
-- ============================================================
CREATE TABLE "Account_rt_mapping" (
    record_type_id VARCHAR(18) NOT NULL,
    developer_name VARCHAR(255),
    PRIMARY KEY (record_type_id)
);

INSERT INTO "Account_rt_mapping" VALUES('HH_Account','HH_Account');
INSERT INTO "Account_rt_mapping" VALUES('Organization','Organization');

CREATE TABLE "Opportunity_rt_mapping" (
    record_type_id VARCHAR(18) NOT NULL,
    developer_name VARCHAR(255),
    PRIMARY KEY (record_type_id)
);

INSERT INTO "Opportunity_rt_mapping" VALUES('Donation','Donation');
INSERT INTO "Opportunity_rt_mapping" VALUES('Grant','Grant');
INSERT INTO "Opportunity_rt_mapping" VALUES('MajorGift','MajorGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('MatchingGift','MatchingGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('InKindGift','InKindGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('Membership','Membership');


-- ============================================================
-- Accounts (Households and Organizations)
-- ============================================================
CREATE TABLE "Account" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "RecordTypeId" VARCHAR(255),
    "Grantmaker__c" VARCHAR(255),
    "Matching_Gift_Company__c" VARCHAR(255),
    "Matching_Gift_Percent__c" VARCHAR(255),
    "ParentId" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Household Accounts (donors and supporters)
INSERT INTO "Account" VALUES('Account-1','Martinez Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-2','Chen Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-3','Johnson Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-4','Williams Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-5','Patel Household','HH_Account','false','false',NULL,NULL);

-- Household Accounts (program participants and staff)
INSERT INTO "Account" VALUES('Account-10','Reyes Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-11','Thompson Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-12','Rivera Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-13','Watanabe Household','HH_Account','false','false',NULL,NULL);

-- Organization Accounts
INSERT INTO "Account" VALUES('Account-6','Acme Corporation','Organization','false','true','100',NULL);
INSERT INTO "Account" VALUES('Account-7','Patel Family Foundation','Organization','true','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-8','Riverside Elementary School','Organization','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-9','State University','Organization','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-14','Portland Public Library','Organization','false','false',NULL,NULL);


-- ============================================================
-- Addresses
-- ============================================================
CREATE TABLE "Address__c" (
    id VARCHAR(255) NOT NULL,
    "Address_Type__c" VARCHAR(255),
    "Default_Address__c" VARCHAR(255),
    "MailingStreet__c" VARCHAR(255),
    "MailingCity__c" VARCHAR(255),
    "MailingState__c" VARCHAR(255),
    "MailingPostalCode__c" VARCHAR(255),
    "MailingCountry__c" VARCHAR(255),
    "Household_Account__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Donor households
INSERT INTO "Address__c" VALUES('Addr-1','Home','true','742 Evergreen Terrace','Portland','Oregon','97201','United States','Account-1');
INSERT INTO "Address__c" VALUES('Addr-2','Home','true','1200 NW Marshall St','Portland','Oregon','97209','United States','Account-2');
INSERT INTO "Address__c" VALUES('Addr-3','Home','true','456 Oak Avenue','Seattle','Washington','98101','United States','Account-3');
INSERT INTO "Address__c" VALUES('Addr-4','Home','true','789 Birch Lane','Portland','Oregon','97214','United States','Account-4');
INSERT INTO "Address__c" VALUES('Addr-5','Home','true','321 Willow Drive','Eugene','Oregon','97401','United States','Account-5');

-- Program participant and staff households
INSERT INTO "Address__c" VALUES('Addr-6','Home','true','1534 NE Prescott St','Portland','Oregon','97211','United States','Account-10');
INSERT INTO "Address__c" VALUES('Addr-7','Home','true','2801 SE Division St','Portland','Oregon','97202','United States','Account-11');
INSERT INTO "Address__c" VALUES('Addr-8','Home','true','4420 N Interstate Ave','Portland','Oregon','97217','United States','Account-12');
INSERT INTO "Address__c" VALUES('Addr-9','Home','true','6225 SE Foster Rd','Portland','Oregon','97206','United States','Account-13');


-- ============================================================
-- Contacts
-- ============================================================
CREATE TABLE "Contact" (
    id VARCHAR(255) NOT NULL,
    "FirstName" VARCHAR(255),
    "LastName" VARCHAR(255),
    "HomeEmail__c" VARCHAR(255),
    "WorkEmail__c" VARCHAR(255),
    "WorkPhone__c" VARCHAR(255),
    "PreferredPhone__c" VARCHAR(255),
    "Preferred_Email__c" VARCHAR(255),
    "Primary_Address_Type__c" VARCHAR(255),
    "AccountId" VARCHAR(255),
    "Current_Address__c" VARCHAR(255),
    "Primary_Affiliation__c" VARCHAR(255),
    "ReportsToId" VARCHAR(255),
    PRIMARY KEY (id)
);

-- === Donors and Supporters ===

-- Martinez Household (Board Chair, major donor, volunteer tutor)
INSERT INTO "Contact" VALUES('Contact-1','Maria','Martinez','maria.martinez@email.com','maria@martinezlaw.com','503-555-0101','Work','Personal','Home','Account-1','Addr-1',NULL,NULL);
INSERT INTO "Contact" VALUES('Contact-2','Carlos','Martinez','carlos.martinez@email.com',NULL,NULL,'Home','Personal','Home','Account-1','Addr-1',NULL,NULL);

-- Chen Household (Education professor, board member, donor)
INSERT INTO "Contact" VALUES('Contact-3','Sarah','Chen','sarah.chen@email.com','schen@stateuniv.edu','503-555-0201','Work','Work','Home','Account-2','Addr-2','Account-9',NULL);

-- Johnson Household (Monthly donors, Patricia volunteers, James attends family nights)
INSERT INTO "Contact" VALUES('Contact-4','James','Johnson','james.johnson@email.com',NULL,'206-555-0301','Home','Personal','Home','Account-3','Addr-3',NULL,NULL);
INSERT INTO "Contact" VALUES('Contact-5','Patricia','Johnson','patricia.johnson@email.com','pjohnson@riversideelem.edu','206-555-0302','Work','Work','Home','Account-3','Addr-3','Account-8',NULL);

-- Williams Household (Corporate donor, Acme matching gifts)
INSERT INTO "Contact" VALUES('Contact-6','Robert','Williams','robert.williams@email.com','rwilliams@acmecorp.com','503-555-0401','Work','Work','Home','Account-4','Addr-4','Account-6',NULL);

-- Patel Household (Foundation grant manager)
INSERT INTO "Contact" VALUES('Contact-7','Aisha','Patel','aisha.patel@email.com','apatel@patelfoundation.org','541-555-0501','Work','Work','Home','Account-5','Addr-5','Account-7',NULL);

-- === Program Staff and Participants ===

-- Lead Tutor (staff)
INSERT INTO "Contact" VALUES('Contact-8','Kenji','Watanabe','kenji.watanabe@email.com','kwatanabe@meadowlarkliteracy.org','503-555-0601','Work','Work','Home','Account-13','Addr-9','Account-14',NULL);

-- Parent of youth participant (also connected to volunteer network)
INSERT INTO "Contact" VALUES('Contact-9','Elena','Reyes','elena.reyes@email.com',NULL,NULL,'Home','Personal','Home','Account-10','Addr-6',NULL,NULL);

-- Youth participant - Read to Lead (Elena's daughter)
INSERT INTO "Contact" VALUES('Contact-10','Sofia','Reyes',NULL,NULL,NULL,NULL,NULL,'Home','Account-10','Addr-6',NULL,'Contact-9');

-- Teen participant - Writers Workshop
INSERT INTO "Contact" VALUES('Contact-11','Destiny','Thompson','destiny.thompson@email.com',NULL,NULL,'Home','Personal','Home','Account-11','Addr-7',NULL,NULL);

-- Youth participant - Read to Lead and Emerging Readers
INSERT INTO "Contact" VALUES('Contact-12','Marcus','Rivera',NULL,NULL,NULL,NULL,NULL,'Home','Account-12','Addr-8',NULL,NULL);


-- ============================================================
-- Affiliations (Contact-to-Organization relationships)
-- ============================================================
CREATE TABLE "Affiliation__c" (
    id VARCHAR(255) NOT NULL,
    "Role__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "Primary__c" VARCHAR(255),
    "StartDate__c" VARCHAR(255),
    "Description__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "Organization__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Affiliation__c" VALUES('Aff-1','Board Member','Current','true','2023-01-15','Board of Directors since 2023','Contact-3','Account-9');
INSERT INTO "Affiliation__c" VALUES('Aff-2','Program Director','Current','true','2020-06-01','Director of Grants Program','Contact-7','Account-7');
INSERT INTO "Affiliation__c" VALUES('Aff-3','Senior Engineer','Current','true','2019-03-15','Engineering department','Contact-6','Account-6');
INSERT INTO "Affiliation__c" VALUES('Aff-4','Volunteer Reading Coach','Current','false','2024-09-01','Weekly reading volunteer at partner school','Contact-5','Account-8');
INSERT INTO "Affiliation__c" VALUES('Aff-5','Part-time Tutor','Current','true','2023-06-01','Adult and youth literacy tutor','Contact-8','Account-14');
INSERT INTO "Affiliation__c" VALUES('Aff-6','Volunteer Tutor','Current','false','2025-09-15','After-school reading program volunteer','Contact-2','Account-8');


-- ============================================================
-- Program Engagements (PMM)
-- ============================================================
CREATE TABLE "ProgramEngagement__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "ApplicationDate__c" VARCHAR(255),
    "AutoName_Override__c" VARCHAR(255),
    "StartDate__c" VARCHAR(255),
    "EndDate__c" VARCHAR(255),
    "Role__c" VARCHAR(255),
    "Stage__c" VARCHAR(255),
    "Account__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "Program__c" VARCHAR(255),
    "ProgramCohort__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Clients (program participants)
INSERT INTO "ProgramEngagement__c" VALUES('PE-1','Sofia Reyes - Read to Lead','2025-12-15','true','2026-01-13',NULL,'Client','Active','Account-10','Contact-10','Prog-1','Cohort-1');
INSERT INTO "ProgramEngagement__c" VALUES('PE-2','Marcus Rivera - Read to Lead','2025-12-18','true','2026-01-13',NULL,'Client','Active','Account-12','Contact-12','Prog-1','Cohort-1');
INSERT INTO "ProgramEngagement__c" VALUES('PE-3','Marcus Rivera - Emerging Readers','2025-12-18','true','2026-01-13',NULL,'Client','Active','Account-12','Contact-12','Prog-2','Cohort-2');
INSERT INTO "ProgramEngagement__c" VALUES('PE-4','Destiny Thompson - Teen Writers Workshop','2025-12-20','true','2026-01-13',NULL,'Client','Active','Account-11','Contact-11','Prog-3','Cohort-3');
INSERT INTO "ProgramEngagement__c" VALUES('PE-5','Elena Reyes - Family Literacy Nights','2025-10-01','true','2025-10-15',NULL,'Client','Active','Account-10','Contact-9','Prog-4',NULL);
INSERT INTO "ProgramEngagement__c" VALUES('PE-9','James Johnson - Family Literacy Nights','2025-09-15','true','2025-10-15',NULL,'Client','Active','Account-3','Contact-4','Prog-4',NULL);

-- Volunteers
INSERT INTO "ProgramEngagement__c" VALUES('PE-6','Carlos Martinez - Read to Lead','2025-11-15','true','2026-01-13',NULL,'Volunteer','Active','Account-1','Contact-2','Prog-1','Cohort-1');
INSERT INTO "ProgramEngagement__c" VALUES('PE-8','Patricia Johnson - Family Literacy Nights','2024-11-01','true','2025-01-15',NULL,'Volunteer','Active','Account-3','Contact-5','Prog-4',NULL);

-- Service Providers (staff)
INSERT INTO "ProgramEngagement__c" VALUES('PE-7','Kenji Watanabe - Read to Lead','2025-08-15','true','2026-01-13',NULL,'Service Provider','Active','Account-13','Contact-8','Prog-1','Cohort-1');


-- ============================================================
-- Services (PMM)
-- ============================================================
CREATE TABLE "Service__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Description__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "UnitOfMeasurement__c" VARCHAR(255),
    "Program__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Service__c" VALUES('Svc-1','One-on-One Tutoring','Individual reading tutoring sessions focused on phonics, comprehension, and fluency','Active','Hours','Prog-1');
INSERT INTO "Service__c" VALUES('Svc-2','Small Group Reading','Small group reading circles (3-5 students) for collaborative reading practice','Active','Hours','Prog-1');
INSERT INTO "Service__c" VALUES('Svc-3','Storytime Circle','Interactive read-aloud sessions with vocabulary building and comprehension activities','Active','Sessions','Prog-2');
INSERT INTO "Service__c" VALUES('Svc-4','Creative Writing Session','Guided writing workshops including journaling, creative fiction, and peer review','Active','Sessions','Prog-3');
INSERT INTO "Service__c" VALUES('Svc-5','Family Reading Night Event','Community events with read-alouds, book giveaways, and literacy activity stations','Active','Attendees','Prog-4');


-- ============================================================
-- Service Schedules (PMM)
-- ============================================================
-- Column order matches mapping: Name, AllDay, CreateServiceSessionRecords,
--   DaysOfWeek, DefaultServiceQuantity, FirstSessionEnd, FirstSessionStart,
--   Frequency, Interval, NumberOfServiceSessions, ParticipantCapacity,
--   ServiceScheduleEndDate, ServiceScheduleEnds,
--   PrimaryServiceProvider, OtherServiceProvider, Service
-- DaysOfWeek: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat
CREATE TABLE "ServiceSchedule__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "AllDay__c" VARCHAR(255),
    "CreateServiceSessionRecords__c" VARCHAR(255),
    "DaysOfWeek__c" VARCHAR(255),
    "DefaultServiceQuantity__c" VARCHAR(255),
    "FirstSessionEnd__c" VARCHAR(255),
    "FirstSessionStart__c" VARCHAR(255),
    "Frequency__c" VARCHAR(255),
    "Interval__c" VARCHAR(255),
    "NumberOfServiceSessions__c" VARCHAR(255),
    "ParticipantCapacity__c" VARCHAR(255),
    "ServiceScheduleEndDate__c" VARCHAR(255),
    "ServiceScheduleEnds__c" VARCHAR(255),
    "PrimaryServiceProvider__c" VARCHAR(255),
    "OtherServiceProvider__c" VARCHAR(255),
    "Service__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Tuesday Tutoring: Kenji primary, Carlos assists
INSERT INTO "ServiceSchedule__c" VALUES('SS-1','Tuesday Tutoring','false','false','3','1.5','2026-01-13T17:30:00.000+0000','2026-01-13T16:00:00.000+0000','Weekly','1','20','10','2026-05-29','On','Contact-8','Contact-2','Svc-1');
-- Thursday Small Groups: Kenji primary
INSERT INTO "ServiceSchedule__c" VALUES('SS-2','Thursday Small Groups','false','false','5','1.0','2026-01-15T17:00:00.000+0000','2026-01-15T16:00:00.000+0000','Weekly','1','20','15','2026-05-29','On','Contact-8',NULL,'Svc-2');
-- Wednesday Storytime: no fixed provider
INSERT INTO "ServiceSchedule__c" VALUES('SS-3','Wednesday Storytime','false','false','4','1.0','2026-01-14T19:00:00.000+0000','2026-01-14T18:00:00.000+0000','Weekly','1','20','12','2026-05-29','On',NULL,NULL,'Svc-3');


-- ============================================================
-- Service Sessions (PMM)
-- ============================================================
CREATE TABLE "ServiceSession__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "SessionStart__c" VARCHAR(255),
    "SessionEnd__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "PrimaryServiceProvider__c" VARCHAR(255),
    "OtherServiceProvider__c" VARCHAR(255),
    "ServiceSchedule__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Tuesday Tutoring sessions (Jan-Feb 2026)
INSERT INTO "ServiceSession__c" VALUES('Ses-1','1/13/2026: Tuesday Tutoring','2026-01-13T16:00:00.000+0000','2026-01-13T17:30:00.000+0000','Complete','Contact-8',NULL,'SS-1');
INSERT INTO "ServiceSession__c" VALUES('Ses-2','1/20/2026: Tuesday Tutoring','2026-01-20T16:00:00.000+0000','2026-01-20T17:30:00.000+0000','Complete','Contact-8',NULL,'SS-1');
INSERT INTO "ServiceSession__c" VALUES('Ses-3','1/27/2026: Tuesday Tutoring','2026-01-27T16:00:00.000+0000','2026-01-27T17:30:00.000+0000','Complete','Contact-8','Contact-2','SS-1');
INSERT INTO "ServiceSession__c" VALUES('Ses-4','2/3/2026: Tuesday Tutoring','2026-02-03T16:00:00.000+0000','2026-02-03T17:30:00.000+0000','Complete','Contact-2',NULL,'SS-1');

-- Thursday Small Groups sessions (Jan-Feb 2026)
INSERT INTO "ServiceSession__c" VALUES('Ses-5','1/15/2026: Thursday Small Groups','2026-01-15T16:00:00.000+0000','2026-01-15T17:00:00.000+0000','Complete','Contact-8',NULL,'SS-2');
INSERT INTO "ServiceSession__c" VALUES('Ses-6','1/22/2026: Thursday Small Groups','2026-01-22T16:00:00.000+0000','2026-01-22T17:00:00.000+0000','Complete','Contact-8',NULL,'SS-2');
INSERT INTO "ServiceSession__c" VALUES('Ses-7','1/29/2026: Thursday Small Groups','2026-01-29T16:00:00.000+0000','2026-01-29T17:00:00.000+0000','Complete','Contact-8',NULL,'SS-2');
INSERT INTO "ServiceSession__c" VALUES('Ses-8','2/5/2026: Thursday Small Groups','2026-02-05T16:00:00.000+0000','2026-02-05T17:00:00.000+0000','Complete','Contact-8',NULL,'SS-2');

-- Wednesday Storytime sessions (Jan-Feb 2026)
INSERT INTO "ServiceSession__c" VALUES('Ses-9','1/14/2026: Wednesday Storytime','2026-01-14T18:00:00.000+0000','2026-01-14T19:00:00.000+0000','Complete',NULL,NULL,'SS-3');
INSERT INTO "ServiceSession__c" VALUES('Ses-10','1/21/2026: Wednesday Storytime','2026-01-21T18:00:00.000+0000','2026-01-21T19:00:00.000+0000','Complete',NULL,NULL,'SS-3');
INSERT INTO "ServiceSession__c" VALUES('Ses-11','1/28/2026: Wednesday Storytime','2026-01-28T18:00:00.000+0000','2026-01-28T19:00:00.000+0000','Complete',NULL,NULL,'SS-3');
INSERT INTO "ServiceSession__c" VALUES('Ses-12','2/4/2026: Wednesday Storytime','2026-02-04T18:00:00.000+0000','2026-02-04T19:00:00.000+0000','Complete',NULL,NULL,'SS-3');


-- ============================================================
-- Service Participants (PMM)
-- ============================================================
CREATE TABLE "ServiceParticipant__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "SignUpDate__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "ProgramEngagement__c" VARCHAR(255),
    "Service__c" VARCHAR(255),
    "ServiceSchedule__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "ServiceParticipant__c" VALUES('SP-1','Sofia Reyes - One-on-One Tutoring','2025-12-20','Enrolled','Contact-10','PE-1','Svc-1','SS-1');
INSERT INTO "ServiceParticipant__c" VALUES('SP-2','Marcus Rivera - One-on-One Tutoring','2025-12-22','Enrolled','Contact-12','PE-2','Svc-1','SS-1');
INSERT INTO "ServiceParticipant__c" VALUES('SP-3','Sofia Reyes - Small Group Reading','2025-12-20','Enrolled','Contact-10','PE-1','Svc-2','SS-2');
INSERT INTO "ServiceParticipant__c" VALUES('SP-4','Marcus Rivera - Small Group Reading','2025-12-22','Enrolled','Contact-12','PE-2','Svc-2','SS-2');
INSERT INTO "ServiceParticipant__c" VALUES('SP-5','Marcus Rivera - Storytime Circle','2025-12-22','Enrolled','Contact-12','PE-3','Svc-3','SS-3');


-- ============================================================
-- Service Deliveries (PMM) — Attendance Tracking
-- ============================================================
-- Column order: Name, AutonameOverride, DeliveryDate, Quantity,
--   AttendanceStatus, Service, Account, Contact, ProgramEngagement,
--   Service_Provider, ServiceSession
CREATE TABLE "ServiceDelivery__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "AutonameOverride__c" VARCHAR(255),
    "DeliveryDate__c" VARCHAR(255),
    "Quantity__c" VARCHAR(255),
    "AttendanceStatus__c" VARCHAR(255),
    "Service__c" VARCHAR(255),
    "Account__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "ProgramEngagement__c" VARCHAR(255),
    "Service_Provider__c" VARCHAR(255),
    "ServiceSession__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- === Tutoring — Sofia Reyes ===
INSERT INTO "ServiceDelivery__c" VALUES('SD-1','Sofia Reyes 2026-01-13: One-on-One Tutoring','true','2026-01-13','1.5','Present','Svc-1','Account-10','Contact-10','PE-1','Contact-8','Ses-1');
INSERT INTO "ServiceDelivery__c" VALUES('SD-2','Sofia Reyes 2026-01-20: One-on-One Tutoring','true','2026-01-20','1.5','Present','Svc-1','Account-10','Contact-10','PE-1','Contact-8','Ses-2');
INSERT INTO "ServiceDelivery__c" VALUES('SD-3','Sofia Reyes 2026-01-27: One-on-One Tutoring','true','2026-01-27','0','Unexcused Absence','Svc-1','Account-10','Contact-10','PE-1','Contact-8','Ses-3');
INSERT INTO "ServiceDelivery__c" VALUES('SD-4','Sofia Reyes 2026-02-03: One-on-One Tutoring','true','2026-02-03','1.5','Present','Svc-1','Account-10','Contact-10','PE-1','Contact-2','Ses-4');

-- === Tutoring — Marcus Rivera ===
INSERT INTO "ServiceDelivery__c" VALUES('SD-5','Marcus Rivera 2026-01-13: One-on-One Tutoring','true','2026-01-13','1.5','Present','Svc-1','Account-12','Contact-12','PE-2','Contact-8','Ses-1');
INSERT INTO "ServiceDelivery__c" VALUES('SD-6','Marcus Rivera 2026-01-20: One-on-One Tutoring','true','2026-01-20','1.5','Present','Svc-1','Account-12','Contact-12','PE-2','Contact-8','Ses-2');
INSERT INTO "ServiceDelivery__c" VALUES('SD-7','Marcus Rivera 2026-01-27: One-on-One Tutoring','true','2026-01-27','1.5','Present','Svc-1','Account-12','Contact-12','PE-2','Contact-2','Ses-3');
INSERT INTO "ServiceDelivery__c" VALUES('SD-8','Marcus Rivera 2026-02-03: One-on-One Tutoring','true','2026-02-03','1.5','Present','Svc-1','Account-12','Contact-12','PE-2','Contact-2','Ses-4');

-- === Small Group Reading — Sofia Reyes ===
INSERT INTO "ServiceDelivery__c" VALUES('SD-9','Sofia Reyes 2026-01-15: Small Group Reading','true','2026-01-15','1.0','Present','Svc-2','Account-10','Contact-10','PE-1','Contact-8','Ses-5');
INSERT INTO "ServiceDelivery__c" VALUES('SD-10','Sofia Reyes 2026-01-22: Small Group Reading','true','2026-01-22','1.0','Present','Svc-2','Account-10','Contact-10','PE-1','Contact-8','Ses-6');
INSERT INTO "ServiceDelivery__c" VALUES('SD-11','Sofia Reyes 2026-01-29: Small Group Reading','true','2026-01-29','1.0','Present','Svc-2','Account-10','Contact-10','PE-1','Contact-8','Ses-7');
INSERT INTO "ServiceDelivery__c" VALUES('SD-12','Sofia Reyes 2026-02-05: Small Group Reading','true','2026-02-05','1.0','Present','Svc-2','Account-10','Contact-10','PE-1','Contact-8','Ses-8');

-- === Small Group Reading — Marcus Rivera ===
INSERT INTO "ServiceDelivery__c" VALUES('SD-13','Marcus Rivera 2026-01-15: Small Group Reading','true','2026-01-15','1.0','Present','Svc-2','Account-12','Contact-12','PE-2','Contact-8','Ses-5');
INSERT INTO "ServiceDelivery__c" VALUES('SD-14','Marcus Rivera 2026-01-22: Small Group Reading','true','2026-01-22','0','Unexcused Absence','Svc-2','Account-12','Contact-12','PE-2','Contact-8','Ses-6');
INSERT INTO "ServiceDelivery__c" VALUES('SD-15','Marcus Rivera 2026-01-29: Small Group Reading','true','2026-01-29','1.0','Present','Svc-2','Account-12','Contact-12','PE-2','Contact-8','Ses-7');
INSERT INTO "ServiceDelivery__c" VALUES('SD-16','Marcus Rivera 2026-02-05: Small Group Reading','true','2026-02-05','1.0','Present','Svc-2','Account-12','Contact-12','PE-2','Contact-8','Ses-8');

-- === Storytime Circle — Marcus Rivera ===
INSERT INTO "ServiceDelivery__c" VALUES('SD-17','Marcus Rivera 2026-01-14: Storytime Circle','true','2026-01-14','1.0','Present','Svc-3','Account-12','Contact-12','PE-3',NULL,'Ses-9');
INSERT INTO "ServiceDelivery__c" VALUES('SD-18','Marcus Rivera 2026-01-21: Storytime Circle','true','2026-01-21','1.0','Present','Svc-3','Account-12','Contact-12','PE-3',NULL,'Ses-10');
INSERT INTO "ServiceDelivery__c" VALUES('SD-19','Marcus Rivera 2026-01-28: Storytime Circle','true','2026-01-28','0','Unexcused Absence','Svc-3','Account-12','Contact-12','PE-3',NULL,'Ses-11');
INSERT INTO "ServiceDelivery__c" VALUES('SD-20','Marcus Rivera 2026-02-04: Storytime Circle','true','2026-02-04','1.0','Present','Svc-3','Account-12','Contact-12','PE-3',NULL,'Ses-12');


-- ============================================================
-- Recurring Donations (Monthly/Annual giving)
-- ============================================================
CREATE TABLE "Recurring_Donation__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Amount__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "RecurringType__c" VARCHAR(255),
    "Installment_Period__c" VARCHAR(255),
    "InstallmentFrequency__c" VARCHAR(255),
    "Day_of_Month__c" VARCHAR(255),
    "StartDate__c" VARCHAR(255),
    "Date_Established__c" VARCHAR(255),
    "PaymentMethod__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "Organization__c" VARCHAR(255),
    "Recurring_Donation_Campaign__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Recurring_Donation__c" VALUES('RD-1','Sarah Chen Monthly Gift','100','Active','Open','Monthly','1','15','2025-06-15','2025-06-15','Credit Card','Contact-3',NULL,'Campaign-1');
INSERT INTO "Recurring_Donation__c" VALUES('RD-2','James Johnson Monthly Gift','50','Active','Open','Monthly','1','1','2024-01-01','2024-01-01','ACH','Contact-4',NULL,NULL);
INSERT INTO "Recurring_Donation__c" VALUES('RD-3','Maria Martinez Monthly Gift','250','Active','Open','Monthly','1','1','2025-01-01','2025-01-01','Credit Card','Contact-1',NULL,'Campaign-1');


-- ============================================================
-- Relationships (Contact-to-Contact)
-- Note: NPSP auto-creates reciprocal relationships via triggers.
-- Since load_dataset uses Bulk API, only one direction is loaded.
-- ============================================================
CREATE TABLE "Relationship__c" (
    id VARCHAR(255) NOT NULL,
    "Type__c" VARCHAR(255),
    "Status__c" VARCHAR(255),
    "Description__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "RelatedContact__c" VARCHAR(255),
    "ReciprocalRelationship__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Relationship__c" VALUES('Rel-1','Spouse','Current',NULL,'Contact-1','Contact-2',NULL);
INSERT INTO "Relationship__c" VALUES('Rel-2','Spouse','Current',NULL,'Contact-4','Contact-5',NULL);
INSERT INTO "Relationship__c" VALUES('Rel-3','Friend','Current','Met through board service','Contact-3','Contact-1',NULL);
INSERT INTO "Relationship__c" VALUES('Rel-4','Friend','Current','Connected through Riverside Elementary volunteer program','Contact-9','Contact-5',NULL);


-- ============================================================
-- Opportunities (Donations, Grants, Memberships, etc.)
-- ============================================================
-- Column order: id, Name, Amount, StageName, CloseDate, RecordTypeId,
--   Acknowledgment_Status__c, Do_Not_Automatically_Create_Payment__c,
--   Fair_Market_Value__c, Gift_Strategy__c,
--   Grant_Period_Start_Date__c, Grant_Period_End_Date__c, Grant_Program_Area_s__c,
--   Honoree_Name__c, In_Kind_Description__c, In_Kind_Type__c, Is_Grant_Renewal__c,
--   Matching_Gift_Status__c, Member_Level__c,
--   Membership_Start_Date__c, Membership_End_Date__c, Membership_Origin__c,
--   Tribute_Type__c,
--   AccountId, CampaignId, Primary_Contact__c, Recurring_Donation__c,
--   Matching_Gift_Account__c, Matching_Gift__c, Honoree_Contact__c
CREATE TABLE "Opportunity" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Amount" VARCHAR(255),
    "StageName" VARCHAR(255),
    "CloseDate" VARCHAR(255),
    "RecordTypeId" VARCHAR(255),
    "Acknowledgment_Status__c" VARCHAR(255),
    "Do_Not_Automatically_Create_Payment__c" VARCHAR(255),
    "Fair_Market_Value__c" VARCHAR(255),
    "Gift_Strategy__c" VARCHAR(255),
    "Grant_Period_Start_Date__c" VARCHAR(255),
    "Grant_Period_End_Date__c" VARCHAR(255),
    "Grant_Program_Area_s__c" VARCHAR(255),
    "Honoree_Name__c" VARCHAR(255),
    "In_Kind_Description__c" VARCHAR(255),
    "In_Kind_Type__c" VARCHAR(255),
    "Is_Grant_Renewal__c" VARCHAR(255),
    "Matching_Gift_Status__c" VARCHAR(255),
    "Member_Level__c" VARCHAR(255),
    "Membership_Start_Date__c" VARCHAR(255),
    "Membership_End_Date__c" VARCHAR(255),
    "Membership_Origin__c" VARCHAR(255),
    "Tribute_Type__c" VARCHAR(255),
    "AccountId" VARCHAR(255),
    "CampaignId" VARCHAR(255),
    "Primary_Contact__c" VARCHAR(255),
    "Recurring_Donation__c" VARCHAR(255),
    "Matching_Gift_Account__c" VARCHAR(255),
    "Matching_Gift__c" VARCHAR(255),
    "Honoree_Contact__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- === Individual Donations ===

-- Maria Martinez: $5,000 pledge for upcoming Spring Gala
INSERT INTO "Opportunity" VALUES('Opp-1','Martinez - Spring Gala 2026 Pledge','5000','Pledged','2026-04-15','Donation','Do Not Acknowledge','true',NULL,'Renewal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-1','Campaign-2','Contact-1',NULL,NULL,NULL,NULL);

-- Robert Williams: $1,000 year-end gift with employer matching gift pending
INSERT INTO "Opportunity" VALUES('Opp-6','Williams Year-End Gift 2025','1000','Closed Won','2025-12-15','Donation','Acknowledged','true',NULL,'New Donor',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Received',NULL,NULL,NULL,NULL,NULL,'Account-4','Campaign-3','Contact-6',NULL,'Account-6',NULL,NULL);

-- Carlos Martinez: $500 annual fund donation
INSERT INTO "Opportunity" VALUES('Opp-7','Martinez Annual Fund 2026','500','Closed Won','2026-01-20','Donation','To Be Acknowledged','true',NULL,'Renewal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-1','Campaign-1','Contact-2',NULL,NULL,NULL,NULL);

-- Patricia Johnson: $250 annual fund donation
INSERT INTO "Opportunity" VALUES('Opp-8','Johnson Annual Fund 2026','250','Closed Won','2026-02-05','Donation','To Be Acknowledged','true',NULL,'Renewal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-3','Campaign-1','Contact-5',NULL,NULL,NULL,NULL);

-- === Recurring Donation Installments ===

-- Sarah Chen: Monthly $100 (from RD-1)
INSERT INTO "Opportunity" VALUES('Opp-2','Chen Monthly Gift - January 2026','100','Closed Won','2026-01-15','Donation','Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-2','Campaign-1','Contact-3','RD-1',NULL,NULL,NULL);
INSERT INTO "Opportunity" VALUES('Opp-3','Chen Monthly Gift - February 2026','100','Closed Won','2026-02-15','Donation','To Be Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-2','Campaign-1','Contact-3','RD-1',NULL,NULL,NULL);

-- James Johnson: Monthly $50 (from RD-2)
INSERT INTO "Opportunity" VALUES('Opp-4','Johnson Monthly Gift - January 2026','50','Closed Won','2026-01-01','Donation','Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-3',NULL,'Contact-4','RD-2',NULL,NULL,NULL);
INSERT INTO "Opportunity" VALUES('Opp-5','Johnson Monthly Gift - February 2026','50','Closed Won','2026-02-01','Donation','To Be Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-3',NULL,'Contact-4','RD-2',NULL,NULL,NULL);

-- Maria Martinez: Monthly $250 (from RD-3)
INSERT INTO "Opportunity" VALUES('Opp-16','Martinez Monthly Gift - January 2026','250','Closed Won','2026-01-01','Donation','Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-1','Campaign-1','Contact-1','RD-3',NULL,NULL,NULL);
INSERT INTO "Opportunity" VALUES('Opp-17','Martinez Monthly Gift - February 2026','250','Closed Won','2026-02-01','Donation','To Be Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-1','Campaign-1','Contact-1','RD-3',NULL,NULL,NULL);

-- === Foundation Grant ===

-- Patel Family Foundation: $50,000 youth literacy grant
INSERT INTO "Opportunity" VALUES('Opp-9','Patel Foundation - Youth Literacy Grant','50000','Closed Won','2026-01-15','Grant','Acknowledged','true',NULL,NULL,'2026-01-01','2026-12-31','Youth Literacy and Reading Intervention',NULL,NULL,NULL,'false',NULL,NULL,NULL,NULL,NULL,NULL,'Account-7',NULL,'Contact-7',NULL,NULL,NULL,NULL);

-- === Membership ===

-- James Johnson: Gold membership renewal
INSERT INTO "Opportunity" VALUES('Opp-10','Johnson Gold Membership 2026','200','Closed Won','2026-01-10','Membership','Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Gold','2026-01-01','2026-12-31','Renewal',NULL,'Account-3',NULL,'Contact-4',NULL,NULL,NULL,NULL);

-- === Major Gift ===

-- Maria Martinez: $25,000 capital campaign gift
INSERT INTO "Opportunity" VALUES('Opp-11','Martinez Capital Campaign Gift','25000','Closed Won','2026-02-01','MajorGift','Acknowledged','true',NULL,'Upgrade',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-1','Campaign-5','Contact-1',NULL,NULL,NULL,NULL);

-- === Matching Gift ===

-- Acme Corporation: $1,000 matching Robert Williams'' year-end donation
INSERT INTO "Opportunity" VALUES('Opp-12','Acme Corporation Matching Gift','1000','Closed Won','2026-01-10','MatchingGift','Acknowledged','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-6','Campaign-3',NULL,NULL,NULL,'Opp-6',NULL);

-- === In-Kind Gift ===

-- Acme Corporation: Children''s books for program lending library
INSERT INTO "Opportunity" VALUES('Opp-13','Acme Corporation - Book Collection Donation','5000','Closed Won','2026-02-10','InKindGift','Acknowledged','true','5000',NULL,NULL,NULL,NULL,NULL,'500 new and gently-used children''s books for program lending library','Goods',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-6','Campaign-1',NULL,NULL,NULL,NULL,NULL);

-- === Memorial/Tribute Gift ===

-- Sarah Chen: $500 in memory of Dr. Helen Wei
INSERT INTO "Opportunity" VALUES('Opp-14','Chen - In Memory of Dr. Helen Wei','500','Closed Won','2026-02-14','Donation','To Be Acknowledged','true',NULL,NULL,NULL,NULL,NULL,'Dr. Helen Wei',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Memorial','Account-2',NULL,'Contact-3',NULL,NULL,NULL,NULL);

-- === Pledge (not yet received) ===

-- Patricia Johnson: $1,000 capital campaign pledge, payments scheduled
INSERT INTO "Opportunity" VALUES('Opp-15','Johnson - Capital Campaign Pledge','1000','Pledged','2026-06-30','Donation','Do Not Acknowledge','true',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-3','Campaign-5','Contact-5',NULL,NULL,NULL,NULL);


-- ============================================================
-- Payments
-- ============================================================
CREATE TABLE "OppPayment__c" (
    id VARCHAR(255) NOT NULL,
    "Payment_Amount__c" VARCHAR(255),
    "Payment_Date__c" VARCHAR(255),
    "Payment_Method__c" VARCHAR(255),
    "Paid__c" VARCHAR(255),
    "Scheduled_Date__c" VARCHAR(255),
    "Opportunity__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Paid payments for closed donations
INSERT INTO "OppPayment__c" VALUES('Pay-1','100','2026-01-15','Credit Card','true','2026-01-15','Opp-2');
INSERT INTO "OppPayment__c" VALUES('Pay-2','100','2026-02-15','Credit Card','true','2026-02-15','Opp-3');
INSERT INTO "OppPayment__c" VALUES('Pay-3','50','2026-01-01','ACH','true','2026-01-01','Opp-4');
INSERT INTO "OppPayment__c" VALUES('Pay-4','50','2026-02-01','ACH','true','2026-02-01','Opp-5');
INSERT INTO "OppPayment__c" VALUES('Pay-5','1000','2025-12-15','Credit Card','true','2025-12-15','Opp-6');
INSERT INTO "OppPayment__c" VALUES('Pay-6','500','2026-01-20','Check','true','2026-01-20','Opp-7');
INSERT INTO "OppPayment__c" VALUES('Pay-7','250','2026-02-05','Credit Card','true','2026-02-05','Opp-8');
INSERT INTO "OppPayment__c" VALUES('Pay-8','50000','2026-01-15','Check','true','2026-01-15','Opp-9');
INSERT INTO "OppPayment__c" VALUES('Pay-9','200','2026-01-10','Credit Card','true','2026-01-10','Opp-10');
INSERT INTO "OppPayment__c" VALUES('Pay-10','25000','2026-02-01','Check','true','2026-02-01','Opp-11');
INSERT INTO "OppPayment__c" VALUES('Pay-11','1000','2026-01-10','Check','true','2026-01-10','Opp-12');
INSERT INTO "OppPayment__c" VALUES('Pay-12','500','2026-02-14','Credit Card','true','2026-02-14','Opp-14');
INSERT INTO "OppPayment__c" VALUES('Pay-13','250','2026-01-01','Credit Card','true','2026-01-01','Opp-16');
INSERT INTO "OppPayment__c" VALUES('Pay-14','250','2026-02-01','Credit Card','true','2026-02-01','Opp-17');

-- Scheduled payments for Spring Gala pledge (not yet paid)
INSERT INTO "OppPayment__c" VALUES('Pay-15','5000',NULL,'Check','false','2026-04-15','Opp-1');

-- Scheduled payments for Capital Campaign pledge (two installments)
INSERT INTO "OppPayment__c" VALUES('Pay-16','500',NULL,'Check','false','2026-04-30','Opp-15');
INSERT INTO "OppPayment__c" VALUES('Pay-17','500',NULL,'Check','false','2026-06-30','Opp-15');


-- ============================================================
-- Allocations (GAU Fund Accounting)
-- ============================================================
CREATE TABLE "Allocation__c" (
    id VARCHAR(255) NOT NULL,
    "Amount__c" VARCHAR(255),
    "Percent__c" VARCHAR(255),
    "General_Accounting_Unit__c" VARCHAR(255),
    "Opportunity__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Split allocation: Carlos Martinez annual fund gift -> General Fund 60% / Literacy Programs 40%
INSERT INTO "Allocation__c" VALUES('Alloc-1','300','60','GAU-1','Opp-7');
INSERT INTO "Allocation__c" VALUES('Alloc-2','200','40','GAU-2','Opp-7');

-- Grant fully allocated: Literacy Programs 60% / Scholarship & Book Fund 40%
INSERT INTO "Allocation__c" VALUES('Alloc-3','30000','60','GAU-2','Opp-9');
INSERT INTO "Allocation__c" VALUES('Alloc-4','20000','40','GAU-4','Opp-9');

-- Major gift fully allocated to Capital Campaign Fund
INSERT INTO "Allocation__c" VALUES('Alloc-5','25000','100','GAU-3','Opp-11');

-- Monthly gifts to General Fund
INSERT INTO "Allocation__c" VALUES('Alloc-6','100','100','GAU-1','Opp-2');
INSERT INTO "Allocation__c" VALUES('Alloc-7','100','100','GAU-1','Opp-3');


-- ============================================================
-- Account Soft Credits
-- ============================================================
CREATE TABLE "Account_Soft_Credit__c" (
    id VARCHAR(255) NOT NULL,
    "Amount__c" VARCHAR(255),
    "Role__c" VARCHAR(255),
    "Account__c" VARCHAR(255),
    "Opportunity__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Acme Corporation gets org soft credit for matching Robert Williams' donation
INSERT INTO "Account_Soft_Credit__c" VALUES('ASC-1','1000','Match','Account-6','Opp-6');


-- ============================================================
-- Partial Soft Credits
-- ============================================================
CREATE TABLE "Partial_Soft_Credit__c" (
    id VARCHAR(255) NOT NULL,
    "Amount__c" VARCHAR(255),
    "Role_Name__c" VARCHAR(255),
    "Contact__c" VARCHAR(255),
    "Opportunity__c" VARCHAR(255),
    PRIMARY KEY (id)
);

-- Carlos Martinez gets soft credit for Maria's Spring Gala pledge
INSERT INTO "Partial_Soft_Credit__c" VALUES('PSC-1','5000','Household Member','Contact-2','Opp-1');


-- ============================================================
-- Grant Deadlines
-- ============================================================
CREATE TABLE "Grant_Deadline__c" (
    id VARCHAR(255) NOT NULL,
    "Name" VARCHAR(255),
    "Type__c" VARCHAR(255),
    "Grant_Deadline_Due_Date__c" VARCHAR(255),
    "Grant_Deliverable_Requirements__c" VARCHAR(255),
    "Opportunity__c" VARCHAR(255),
    PRIMARY KEY (id)
);

INSERT INTO "Grant_Deadline__c" VALUES('GD-1','Mid-Year Progress Report','Interim Report','2026-06-30','Submit progress report on literacy program outcomes including enrollment numbers and reading level assessments','Opp-9');
INSERT INTO "Grant_Deadline__c" VALUES('GD-2','Final Report and Financial Summary','Final Report','2026-12-31','Submit final report with program outcomes, financial summary, and student reading progress stories for foundation annual report','Opp-9');
INSERT INTO "Grant_Deadline__c" VALUES('GD-3','Grant Renewal Application','Application','2026-09-15','Submit renewal application for next fiscal year literacy program funding','Opp-9');
