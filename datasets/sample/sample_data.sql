-- ==========================================================================
-- NPPatch Sample Dataset
-- ==========================================================================
-- Demonstrates common nonprofit scenarios:
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

INSERT INTO "Campaign" VALUES('Campaign-1','Annual Fund 2026','true','In Progress','Direct Mail','2026-01-01','2026-12-31','Annual operating fund supporting all programs and services','150000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-2','Spring Gala 2026','true','Planned','Event','2026-04-15','2026-04-15','Annual fundraising gala dinner and auction','75000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-3','Year-End Appeal 2025','false','Completed','Email','2025-11-01','2025-12-31','Year-end giving campaign targeting lapsed and current donors','50000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-4','Capital Campaign 2025-2027','true','In Progress','Other','2025-01-01','2027-12-31','Multi-year capital campaign for facility improvements','500000',NULL);
INSERT INTO "Campaign" VALUES('Campaign-5','Building Renovation','true','In Progress','Other','2025-03-01','2026-06-30','Main building renovation project','300000','Campaign-4');


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
INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-2','Programs','true','Restricted fund for program delivery and services');
INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-3','Capital Campaign Fund','true','Restricted fund for capital improvements and construction');
INSERT INTO "General_Accounting_Unit__c" VALUES('GAU-4','Scholarship Fund','true','Restricted fund for student scholarships and educational support');


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
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-3','Send Impact Report','30','Low','Not Started','Email','true','Share quarterly impact report showing how gifts make a difference','EPT-1','EPTask-2');

-- Major Gift Cultivation tasks
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-4','Initial Discovery Meeting','1','High','Not Started','Meeting','false','Meet to understand donor interests, capacity, and connection to mission','EPT-2',NULL);
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-5','Follow-Up Call','14','Medium','Not Started','Call','false','Follow up on discovery meeting and answer questions','EPT-2','EPTask-4');
INSERT INTO "Engagement_Plan_Task__c" VALUES('EPTask-6','Present Gift Proposal','30','High','Not Started','Meeting','false','Present formal gift proposal aligned with donor interests','EPT-2','EPTask-5');


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

-- Household Accounts
INSERT INTO "Account" VALUES('Account-1','Martinez Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-2','Chen Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-3','Johnson Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-4','Williams Household','HH_Account','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-5','Patel Household','HH_Account','false','false',NULL,NULL);

-- Organization Accounts
INSERT INTO "Account" VALUES('Account-6','Acme Corporation','Organization','false','true','100',NULL);
INSERT INTO "Account" VALUES('Account-7','Patel Family Foundation','Organization','true','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-8','Community Food Bank','Organization','false','false',NULL,NULL);
INSERT INTO "Account" VALUES('Account-9','State University','Organization','false','false',NULL,NULL);


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

INSERT INTO "Address__c" VALUES('Addr-1','Home','true','742 Evergreen Terrace','Portland','Oregon','97201','United States','Account-1');
INSERT INTO "Address__c" VALUES('Addr-2','Home','true','1200 NW Marshall St','Portland','Oregon','97209','United States','Account-2');
INSERT INTO "Address__c" VALUES('Addr-3','Home','true','456 Oak Avenue','Seattle','Washington','98101','United States','Account-3');
INSERT INTO "Address__c" VALUES('Addr-4','Home','true','789 Birch Lane','Portland','Oregon','97214','United States','Account-4');
INSERT INTO "Address__c" VALUES('Addr-5','Home','true','321 Willow Drive','Eugene','Oregon','97401','United States','Account-5');


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

-- Martinez Household
INSERT INTO "Contact" VALUES('Contact-1','Maria','Martinez','maria.martinez@email.com','maria@martinezlaw.com','503-555-0101','Work','Personal','Home','Account-1','Addr-1',NULL,NULL);
INSERT INTO "Contact" VALUES('Contact-2','Carlos','Martinez','carlos.martinez@email.com',NULL,NULL,'Home','Personal','Home','Account-1','Addr-1',NULL,NULL);

-- Chen Household (Sarah is a board member at State University)
INSERT INTO "Contact" VALUES('Contact-3','Sarah','Chen','sarah.chen@email.com','schen@stateuniv.edu','503-555-0201','Work','Work','Home','Account-2','Addr-2','Account-9',NULL);

-- Johnson Household (Patricia works at Community Food Bank)
INSERT INTO "Contact" VALUES('Contact-4','James','Johnson','james.johnson@email.com',NULL,'206-555-0301','Home','Personal','Home','Account-3','Addr-3',NULL,NULL);
INSERT INTO "Contact" VALUES('Contact-5','Patricia','Johnson','patricia.johnson@email.com','pjohnson@communityfoodbank.org','206-555-0302','Work','Work','Home','Account-3','Addr-3','Account-8',NULL);

-- Williams Household (Robert works at Acme Corporation - matching gift employer)
INSERT INTO "Contact" VALUES('Contact-6','Robert','Williams','robert.williams@email.com','rwilliams@acmecorp.com','503-555-0401','Work','Work','Home','Account-4','Addr-4','Account-6',NULL);

-- Patel Household (Aisha is Program Director at Patel Family Foundation)
INSERT INTO "Contact" VALUES('Contact-7','Aisha','Patel','aisha.patel@email.com','apatel@patelfoundation.org','541-555-0501','Work','Work','Home','Account-5','Addr-5','Account-7',NULL);


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
INSERT INTO "Affiliation__c" VALUES('Aff-4','Volunteer','Current','false','2024-09-01','Weekend volunteer at food bank','Contact-5','Account-8');


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

-- Patel Family Foundation: $50,000 youth education grant
INSERT INTO "Opportunity" VALUES('Opp-9','Patel Foundation - Youth Education Grant','50000','Closed Won','2026-01-15','Grant','Acknowledged','true',NULL,NULL,'2026-01-01','2026-12-31','Youth Education and Workforce Development',NULL,NULL,NULL,'false',NULL,NULL,NULL,NULL,NULL,NULL,'Account-7',NULL,'Contact-7',NULL,NULL,NULL,NULL);

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

-- Acme Corporation: 20 refurbished laptops
INSERT INTO "Opportunity" VALUES('Opp-13','Acme Corporation - Office Equipment Donation','5000','Closed Won','2026-02-10','InKindGift','Acknowledged','true','5000',NULL,NULL,NULL,NULL,NULL,'20 refurbished laptops for program participants','Goods',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Account-6','Campaign-1',NULL,NULL,NULL,NULL,NULL);

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

-- Split allocation: Carlos Martinez annual fund gift → General Fund 60% / Programs 40%
INSERT INTO "Allocation__c" VALUES('Alloc-1','300','60','GAU-1','Opp-7');
INSERT INTO "Allocation__c" VALUES('Alloc-2','200','40','GAU-2','Opp-7');

-- Grant fully allocated: Programs 60% / Scholarship 40%
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

INSERT INTO "Grant_Deadline__c" VALUES('GD-1','Mid-Year Progress Report','Report','2026-06-30','Submit progress report on youth education outcomes including enrollment numbers and assessment results','Opp-9');
INSERT INTO "Grant_Deadline__c" VALUES('GD-2','Final Report and Financial Summary','Report','2026-12-31','Submit final report with program outcomes, financial summary, and photos for foundation annual report','Opp-9');
INSERT INTO "Grant_Deadline__c" VALUES('GD-3','Q3 Site Visit','Other','2026-09-15','Foundation staff will conduct on-site visit to observe program delivery','Opp-9');
