
/*
Copyright (c) 2018, Salesforce.org
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of Salesforce.org nor the names of
its contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

/**
* @author Salesforce.org
* @date 2018
* @group Customizable Rollups Operations Services
* @description Unit Test for the Opportunity to Recurring Donation Rollups
*/
@isTest
private class CRLP_RollupRecurringDonation_TEST {

    private Enum TestType {
        TestTrigger, TestQueueuable, TestBatch, testSkewBatch
    }

    /**
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {
        UTIL_TestPermissions.assignAdminPermissionSet();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;
    }

    /**
     * @description Create Rollup__mdt records to test rolling up from the Opp object to Recurring Donations
     */
    private static void mockRollupCMTValues() {
        CMT_UnitTestData_TEST.mockRecurringDonationRollupCMTValues();
    }

    static testMethod void test_Rollups_Queueable() {
        testRollupsServices(TestType.TestQueueuable);
    }
    static testMethod void test_Rollups_Batch() {
        testRollupsServices(TestType.TestBatch);
    }
    static testMethod void test_Rollups_SkewBatch() {
        testRollupsServices(TestType.testSkewBatch);
    }
    static testMethod void test_Rollups_Trigger() {
        testRollupsServices(TestType.TestTrigger);
    }

    /**
     * @description Test some simple rollups from the Opportunity object to Recurring Donations using
     * four different methods:
     * 1. Trigger based rollup
     * 2. Call a Queueuable method directly (simulates clicking a button to recalculate)
     * 3. Nightly Batch Job
     * 4. Nightly LDV Batch Job
     */
    private static void testRollupsServices(TestType tt) {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                Rollups_Limit_on_Attached_Opps_for_Skew__c = (tt == TestType.testSkewBatch ? 50 : 200),
                Rollups_Account_SkewMode_Batch_Size__c = 200,
                Rollups_Contact_SkewMode_Batch_Size__c = 200,
                Rollups_Account_Soft_Credit_Batch_Size__c = 200,
                Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                Rollups_AcctContactSoftCredit_Batch_Size__c = 200,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_Contact_Batch_Size__c = 20
        ));

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new Contacts_And_Orgs_Settings__c(
                Opportunity_Contact_Role_Default_role__c = CAO_Constants.OCR_DONOR_ROLE,
                Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR
        ));

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new Recurring_Donations_Settings__c(
                        Maximum_Donations__c = 50,
                        Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                        Recurring_Donation_Batch_Size__c = 50
                ));

        // Create the test data
        mockRollupCMTValues();

        // Disable all legacy rollup triggers
        UTIL_UnitTestData_TEST.disableRollupTriggers();

        if (tt != TestType.TestTrigger) {
            // disable customizable rollup triggers to test the Batch & Queueuable logic
            UTIL_UnitTestData_TEST.disableCustomizableRollupTriggers();
        }

        // Retrieve the dummy Contact and then insert 100 Opportunity records
        Contact con = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        Id acctId = con.AccountId;

        String closedStage = UTIL_UnitTestData_TEST.getClosedWonStage();

        Decimal instAmt = 100;

        Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withDefaultValues()
                .withRecurringTypeOpen()
                .withContact(con.Id)
                .withAmount(instAmt)
                .withInstallmentPeriodMonthly()
                .withDateEstablished(Date.today())
                .build();
        insert rd;

        rd = [SELECT Total_Paid_Installments__c
                , Next_Payment_Date__c
                , Last_Payment_Date__c
                , Paid_Amount__c FROM Recurring_Donation__c WHERE Id = :rd.Id];

        // In trigger context, the initial pledged opportunities should've rolled up as follows:
        if (tt == TestType.TestTrigger) {
            System.assertEquals(0, rd.Total_Paid_Installments__c);
            System.assertNotEquals(null, rd.Next_Payment_Date__c, 'Next Payment Date should be set by evaluation service');
            System.assertEquals(null, rd.Last_Payment_Date__c);
            System.assertEquals(0, rd.Paid_Amount__c);
        }

        // In all other contexts, CRLP triggers aren't running, so rollup fields should be null.
        // Note: Next_Payment_Date__c is populated by the RD2 evaluation service on insert
        // (independent of CRLP triggers), so it is not expected to be null.
        if (tt != TestType.TestTrigger) {
            System.assertEquals(null, rd.Paid_Amount__c);
            System.assertEquals(null, rd.Total_Paid_Installments__c);
            System.assertEquals(null, rd.Last_Payment_Date__c);
            System.assertNotEquals(null, rd.Next_Payment_Date__c,
                    'Next Payment Date should be set by RD2 evaluation service on insert');
        }

        List<Opportunity> originalOpps = [SELECT Id, CloseDate
        FROM Opportunity
        WHERE Recurring_Donation__c = :rd.id
        ORDER BY CloseDate ASC];

        // Enhanced RDs create the first installment on insert
        System.assert(!originalOpps.isEmpty(), 'At least one Opportunity should be created on RD insert');

        // Close the first opportunity as Won
        originalOpps[0].StageName = closedStage;
        update originalOpps;

        // Capture the close date of the won opp for later assertion
        Date expectedLastPaymentDate = originalOpps[0].CloseDate;

        Test.startTest();

        Integer closedWonCount = [SELECT Count() FROM Opportunity WHERE IsWon = true AND Recurring_Donation__c = :rd.Id];
        system.assert(closedWonCount >= 1,
                'There should be at least 1 ClosedWon Opp on the RD, found ' + closedWonCount);
        Integer openCount = [SELECT Count() FROM Opportunity WHERE IsClosed = false AND Recurring_Donation__c = :rd.Id];
        system.assert(openCount >= 1,
                'There should be at least 1 Open Opp on the RD, found ' + openCount);
        system.assertEquals(instAmt, ([SELECT Sum(Amount) Amt FROM Opportunity
        WHERE IsWon = true])[0].get('Amt'),
                'The total Amount of all Closed Oppties should be $' + instAmt);

        Id rdId = rd.Id;
        String rdQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Recurring_Donation__c.SObjectType) + ' WHERE Id = :rdId LIMIT 1';
        rd = database.query(rdQuery);

        // Now test the rollups to the Recurring Donation from the Opportunity
        if (tt == TestType.TestTrigger) {
            // No need to execute anything special here. If the triggers worked as expected, then
            // the data will be rolled up automatically upon the stopTest().
        } else if (tt == TestType.TestBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                    CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);
        } else if (tt == TestType.testSkewBatch) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode, new List<Id>{rdId}, null);
        } else if (tt == TestType.TestQueueuable) {
            System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{rdId}));
        }
        Test.stopTest();

        // Query the RD with all the target fields specified in the rollups
        rd = database.query(rdQuery);

        // Basic rollup asserts using existing NPSP rollup fields.
        System.assertEquals(1, rd.Total_Paid_Installments__c,
                'Total Paid Installments should be 1');
        System.assertNotEquals(null, rd.Next_Payment_Date__c,
                'Next Payment Date should not be null after rollup');
        System.assertEquals(expectedLastPaymentDate, rd.Last_Payment_Date__c,
                'Last Payment Date should match the close date of the won Opportunity');
        System.assertEquals(instAmt, rd.Paid_Amount__c,
                'Paid Amount should equal the installment amount');

    }
}