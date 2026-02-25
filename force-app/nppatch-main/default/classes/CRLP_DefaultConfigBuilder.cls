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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Static variables used to create the custom metadata type record for Customizable Rollups from
* the legacy rollup settings in the NPSP Custom Settings objects.
*/
public class CRLP_DefaultConfigBuilder {

    /** @description Prefix all CMT DeveloperName values with this */
    public static final String RecordNamePrefix = 'nppatch_';

    /** @description Legacy Account/Contact rollup settings are stored in this custom settings object */
    public static final Households_Settings__c legacySettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

    /** @description Set to True if the legacy Rollup Settings are different for Contacts versus Accounts */
    public static final Boolean isDifferentContactFilterGroupNeeded =
            (legacySettings.Excluded_Account_Opp_Rectypes__c != legacySettings.Excluded_Contact_Opp_Rectypes__c
            || legacySettings.Excluded_Account_Opp_Types__c != legacySettings.Excluded_Contact_Opp_Types__c);

    /** @description Legacy Allocation rollup settings are stored in this custom settings object */
    public static final Allocations_Settings__c legacyAllocSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    /** @description Number of days to use for all the N_Days rollups */
    public static final String LastNDaysString = (legacySettings.Rollup_N_Day_Value__c != null ?
        String.valueOf(legacySettings.Rollup_N_Day_Value__c.intValue()) : '365');

    /** @description Number of days to use for all the N_Days rollups on Allocations */
    public static final String LastNDaysAllocString = (legacyAllocSettings.Rollup_N_Day_Value__c != null ?
        String.valueOf(legacyAllocSettings.Rollup_N_Day_Value__c.intValue()) : '365');

    /** @description The RecordName for the default filter group of Closed Won Donations (Unique to Account rollups) */
    public static String FilterGroup_Opps_Accounts_HC = RecordNamePrefix + 'ClosedWon_Opps_HC' +
            (isDifferentContactFilterGroupNeeded  ? '_Accounts' : '');

    /** @description The RecordName for the default filter group of Closed Won Donations (Unique to Account rollups) */
    public static String FilterGroup_Opps_Accounts_SC = RecordNamePrefix + 'ClosedWon_Opps_SC' +
            (isDifferentContactFilterGroupNeeded  ? '_Accounts' : '');

    /** @description The RecordName for the default filter group of Closed Won Donations (Unique to Contact rollups) */
    public static String FilterGroup_Opps_Contacts_HC = RecordNamePrefix + 'ClosedWon_Opps_HC' +
            (isDifferentContactFilterGroupNeeded ? '_Contacts' : '');

    /** @description The RecordName for the default filter group of Closed Won Donations (Unique to Contact rollups) */
    public static String FilterGroup_Opps_Contacts_SC = RecordNamePrefix + 'ClosedWon_Opps_SC' +
            (isDifferentContactFilterGroupNeeded ? '_Contacts' : '');

    /** @description The RecordName for the default filter group of Closed Won Membership */
    public static final String FilterGroup_Membership = RecordNamePrefix + 'ClosedWon_Memberships';

    /** @description The RecordName for the default filter group to use for Allocations Rollups */
    public static final String FilterGroup_Allocations = RecordNamePrefix + 'Allocations_Filter';

    /** @description The RecordName for the default filter group of Pledged Donations (Unique to Recurring Donations Rollups) */
    public static final String FilterGroup_OpenOpps = RecordNamePrefix + 'Open_Opportunties';

    /** @description The RecordName for the default filter group of Closed Won Donations without RT Exclusions(Unique to Recurring Donations Rollups) */
    public static final String FilterGroup_ClosedWonOpps_NoRTExclusions = RecordNamePrefix + 'ClosedWon_Opps_No_RT_Exclusions';

    /** @description The RecordName for the default filter group of Paid Payments. Not used in default config, but provided as a courtesy.  */
    public static final String FilterGroup_PaymentsPaid = RecordNamePrefix + 'Paid_Payments';

    /** @description The RecordName for the default filter group of Paid Payments for Contacts. Not used in default config, but provided as a courtesy.  */
    public static final String FilterGroup_PaymentsPaid_Contacts = RecordNamePrefix + 'Paid_Payments_Contacts';

    /** @description The RecordName for the default filter group of Written Off Payments. Not used in default config, but provided as a courtesy.  */
    public static final String FilterGroup_PaymentsWrittenOff = RecordNamePrefix + 'WrittenOff_Payments';

    /** @description The RecordName for the default filter group of Written Off Payments. Not used in default config, but provided as a courtesy.  */
    public static final String FilterGroup_PaymentsWrittenOff_Contacts = RecordNamePrefix + 'WrittenOff_Payments_Contacts';


    // Commonly used Fields in the rollup definitions to help with duplicate content and readability.
    private static final String allocAmountFld = 'Allocation__c.Amount__c';
    private static final String oppAmountFld = 'Opportunity.Amount';
    private static final String oppCloseDateFld = 'Opportunity.CloseDate';
    private static final String opportunityObject = 'Opportunity';
    public static final String pscAmountFld = 'Partial_Soft_Credit__c.Amount__c';

    /** @description Map of Rollup Details, where the MapKey is the SummaryObject.Field and List<String> is the
     * following set of rollup properties
     * Key=SummaryObject.SummaryField
     * Value=List<String>{ DetailObject.Field, FilterGroupRecordName, AmountObject.Field, DateObject.Field, OperationString, TimeBoundOperationString, IntValue }
     */
    public static Map<String, List<String>> rollupDetailsBySummaryField = new Map<String, List<String>>{

            /* ======== Account Hard Credit ======== */
            'Account.AverageAmount__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Average', 'All_Time', '' },
            'Account.Best_Gift_Year__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Best_Year', 'All_Time', '' },
            'Account.Best_Gift_Year_Total__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Best_Year_Total', 'All_Time', '' },
            'Account.FirstCloseDate__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'First', 'All_Time', '' },
            'Account.LargestAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Largest', 'All_Time', '' },
            'Account.LastCloseDate__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Account.LastOppAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Account.NumberOfClosedOpps__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Count', '', '' },
            'Account.OppAmount2YearsAgo__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '2' },
            'Account.OppAmountLastNDays__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Days_Back', LastNDaysString },
            'Account.OppAmountLastYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '1' },
            'Account.OppAmountThisYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '0' },
            'Account.OppsClosed2YearsAgo__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '2' },
            'Account.OppsClosedLastNDays__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Days_Back', LastNDaysString },
            'Account.OppsClosedLastYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '1' },
            'Account.OppsClosedThisYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '0' },
            'Account.SmallestAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Smallest', 'All_Time', '' },
            'Account.TotalOppAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Accounts_HC, oppAmountFld, oppCloseDateFld, 'Sum', '', '' },

            /* ======== Account Membership ======== */
            'Account.TotalMembershipOppAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Membership, oppAmountFld, oppCloseDateFld, 'Sum', '', '' },
            'Account.LastMembershipAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Membership, oppAmountFld, oppCloseDateFld, 'Last', '', '' },
            'Account.LastMembershipDate__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Membership, opportunityObject, oppCloseDateFld, 'Last', '', '' },
            'Account.LastMembershipLevel__c' =>
                    new List<String>{ 'Opportunity.Member_Level__c', FilterGroup_Membership, opportunityObject, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Account.LastMembershipOrigin__c' =>
                    new List<String>{ 'Opportunity.Membership_Origin__c', FilterGroup_Membership, opportunityObject, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Account.MembershipEndDate__c' =>
                    new List<String>{ 'Opportunity.Membership_End_Date__c', FilterGroup_Membership, opportunityObject, 'Opportunity.Membership_End_Date__c', 'Last', 'All_Time', '' },
            'Account.MembershipJoinDate__c' =>
                    new List<String>{ 'Opportunity.Membership_Start_Date__c', FilterGroup_Membership, opportunityObject, 'Opportunity.Membership_Start_Date__c', 'First', 'All_Time', '' },
            'Account.NumberOfMembershipOpps__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Membership, oppAmountFld, oppCloseDateFld, 'Count', 'All_Time', '' },

            /* ======== Contact Hard Credit ======== */
            'Contact.AverageAmount__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Average', 'All_Time', '' },
            'Contact.Best_Gift_Year__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Best_Year', 'All_Time', '' },
            'Contact.Best_Gift_Year_Total__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Best_Year_Total', 'All_Time', '' },
            'Contact.FirstCloseDate__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'First', 'All_Time', '' },
            'Contact.LargestAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Largest', 'All_Time', '' },
            'Contact.LastCloseDate__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.LastOppAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.NumberOfClosedOpps__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Count', '', '' },
            'Contact.OppAmount2YearsAgo__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '2' },
            'Contact.OppAmountLastNDays__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Days_Back', LastNDaysString },
            'Contact.OppAmountLastYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '1' },
            'Contact.OppAmountThisYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '0' },
            'Contact.OppsClosed2YearsAgo__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '2' },
            'Contact.OppsClosedLastNDays__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Days_Back', LastNDaysString },
            'Contact.OppsClosedLastYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '1' },
            'Contact.OppsClosedThisYear__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '0' },
            'Contact.SmallestAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Smallest', 'All_Time', '' },
            'Contact.TotalOppAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Opps_Contacts_HC, oppAmountFld, oppCloseDateFld, 'Sum', '', '' },

            /* ======== Contact Soft Credit ======== */
            'Contact.First_Soft_Credit_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'First', 'All_Time', '' },
            'Contact.Last_Soft_Credit_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.First_Soft_Credit_Amount__c' =>
                    new List<String>{ pscAmountFld, FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'First', 'All_Time', '' },
            'Contact.Largest_Soft_Credit_Amount__c' =>
                    new List<String>{ pscAmountFld, FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Largest', 'All_Time', '' },
            'Contact.Largest_Soft_Credit_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Largest', 'All_Time', '' },
            'Contact.Last_Soft_Credit_Amount__c' =>
                    new List<String>{ pscAmountFld, FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.Soft_Credit_Last_Year__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '1' },
            'Contact.Soft_Credit_This_Year__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '0' },
            'Contact.Soft_Credit_Total__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Sum', 'All_Time', '' },
            'Contact.Soft_Credit_Two_Years_Ago__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '2' },
            'Contact.Number_of_Soft_Credits__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Count', 'All_Time', '' },
            'Contact.Number_of_Soft_Credits_Last_N_Days__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Count', 'Days_Back', LastNDaysString },
            'Contact.Number_of_Soft_Credits_Last_Year__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '1' },
            'Contact.Number_of_Soft_Credits_This_Year__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '0' },
            'Contact.Number_of_Soft_Credits_Two_Years_Ago__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '2' },
            'Contact.Soft_Credit_Last_N_Days__c' =>
                    new List<String>{ 'Partial_Soft_Credit__c', FilterGroup_Opps_Contacts_SC, pscAmountFld, oppCloseDateFld, 'Sum', 'Days_Back', LastNDaysString },

            /* ======== Contact Membership ======== */
            'Contact.TotalMembershipOppAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Membership, oppAmountFld, oppCloseDateFld, 'Sum', '', '' },
            'Contact.NumberOfMembershipOpps__c' =>
                    new List<String>{ opportunityObject, FilterGroup_Membership, opportunityObject, opportunityObject, 'Count', '', '' },
            'Contact.MembershipEndDate__c' =>
                    new List<String>{ 'Opportunity.Membership_End_Date__c', FilterGroup_Membership, opportunityObject, 'Opportunity.Membership_End_Date__c', 'Last', 'All_Time', '' },
            'Contact.MembershipJoinDate__c' =>
                    new List<String>{ 'Opportunity.Membership_Start_Date__c', FilterGroup_Membership, opportunityObject, 'Opportunity.Membership_Start_Date__c', 'First', 'All_Time', '' },
            'Contact.LastMembershipAmount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_Membership, oppAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.LastMembershipDate__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Membership, opportunityObject, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.LastMembershipLevel__c' =>
                    new List<String>{ 'Opportunity.Member_Level__c', FilterGroup_Membership, opportunityObject, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Contact.LastMembershipOrigin__c' =>
                    new List<String>{ 'Opportunity.Membership_Origin__c', FilterGroup_Membership, opportunityObject, oppCloseDateFld, 'Last', 'All_Time', '' },

            /* ======== Allocation to GAU ======== */
            'General_Accounting_Unit__c.First_Allocation_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Allocations, opportunityObject, oppCloseDateFld, 'First', 'All_Time', '' },
            'General_Accounting_Unit__c.Last_Allocation_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_Allocations, opportunityObject, oppCloseDateFld, 'Last', 'All_Time', '' },
            'General_Accounting_Unit__c.Largest_Allocation__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Largest', 'All_Time', '' },
            'General_Accounting_Unit__c.Smallest_Allocation__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Smallest', 'All_Time', '' },
            'General_Accounting_Unit__c.Number_of_Allocations_Last_N_Days__c' =>
                    new List<String>{ 'Allocation__c', FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Count', 'Days_Back', LastNDaysAllocString },
            'General_Accounting_Unit__c.Number_of_Allocations_Last_Year__c' =>
                    new List<String>{ 'Allocation__c', FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '1' },
            'General_Accounting_Unit__c.Number_of_Allocations_This_Year__c' =>
                    new List<String>{ 'Allocation__c', FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '0' },
            'General_Accounting_Unit__c.Number_of_Allocations_Two_Years_Ago__c' =>
                    new List<String>{ 'Allocation__c', FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Count', 'Years_Ago', '2' },
            'General_Accounting_Unit__c.Average_Allocation__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Average', 'All_Time', '' },
            'General_Accounting_Unit__c.Total_Allocations__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Sum', 'All_Time', '' },
            'General_Accounting_Unit__c.Total_Allocations_Last_N_Days__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Sum', 'Days_Back', LastNDaysAllocString },
            'General_Accounting_Unit__c.Total_Allocations_Last_Year__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '1' },
            'General_Accounting_Unit__c.Total_Allocations_This_Year__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '0' },
            'General_Accounting_Unit__c.Total_Allocations_Two_Years_Ago__c' =>
                    new List<String>{ allocAmountFld, FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Sum', 'Years_Ago', '2' },
            'General_Accounting_Unit__c.Total_Number_of_Allocations__c' =>
                    new List<String>{ 'Allocation__c', FilterGroup_Allocations, allocAmountFld, oppCloseDateFld, 'Count', 'All_Time', '' },

            /* ======== Opportunity to Recurring Donation ======== */
            'Recurring_Donation__c.Next_Payment_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_OpenOpps, oppAmountFld, oppCloseDateFld, 'First', 'All_Time', '' },
            'Recurring_Donation__c.Last_Payment_Date__c' =>
                    new List<String>{ oppCloseDateFld, FilterGroup_ClosedWonOpps_NoRTExclusions, oppAmountFld, oppCloseDateFld, 'Last', 'All_Time', '' },
            'Recurring_Donation__c.Paid_Amount__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_ClosedWonOpps_NoRTExclusions, oppAmountFld, oppCloseDateFld, 'Sum', 'All_Time', '' },
            'Recurring_Donation__c.Total_Paid_Installments__c' =>
                    new List<String>{ oppAmountFld, FilterGroup_ClosedWonOpps_NoRTExclusions, oppAmountFld, oppCloseDateFld, 'Count', 'All_Time', '' }

    };

    /** @description Map of Rollup Name & Descriptions; Keeping these separate from the Rollup details map just
     * to make the maps easier to read.
     * Key=SummaryObject.SummaryField
     * Value=List<String>{ Rollup Label, Rollup Description }
     */
    public static final Map<String, List<String>> rollupNameAndDescriptionsBySummaryField = new Map<String, List<String>>{

            /* ======== Account Hard Credit ======== */
            'Account.TotalOppAmount__c' =>
                    new List<String>{ 'Account: Total Gifts', 'Total of all gifts from the Account' },
            'Account.AverageAmount__c' =>
                    new List<String>{ 'Account: Average Gift', 'Average of all gifts from the Account' },
            'Account.Best_Gift_Year__c' =>
                    new List<String>{ 'Account: Best Gift Year', 'Year of the highest total gifts from the Account' },
            'Account.Best_Gift_Year_Total__c' =>
                    new List<String>{ 'Account: Best Gift Year Total', 'Total gifts in the year of the highest total gifts from the Account' },
            'Account.FirstCloseDate__c' =>
                    new List<String>{ 'Account: First Gift Date', 'Date of the first gift from the Account' },
            'Account.LargestAmount__c' =>
                    new List<String>{ 'Account: Largest Gift', 'Largest gift amount from the Account' },
            'Account.LastCloseDate__c' =>
                    new List<String>{ 'Account: Last Gift Date', 'Date of the last gift from the Account' },
            'Account.LastOppAmount__c' =>
                    new List<String>{ 'Account: Last Gift Amount', 'Amount of the last gift from the Account' },
            'Account.NumberOfClosedOpps__c' =>
                    new List<String>{ 'Account: Total Number of Gifts', 'Total number of all gifts from the Account' },
            'Account.OppAmount2YearsAgo__c' =>
                    new List<String>{ 'Account: Total Gifts Two Years Ago', 'Total of all gifts two calendar years ago from the Account' },
            'Account.OppAmountLastNDays__c' =>
                    new List<String>{ 'Account: Total Gifts Last N Days', 'Total of all gifts for the last N days from the Account' },
            'Account.OppAmountLastYear__c' =>
                    new List<String>{ 'Account: Total Gifts Last Year', 'Total of all gifts in the previous calendar year from the Account' },
            'Account.OppAmountThisYear__c' =>
                    new List<String>{ 'Account: Total Gifts This Year', 'Total of all gifts in the current calendar year from the Account' },
            'Account.OppsClosed2YearsAgo__c' =>
                    new List<String>{ 'Account: Number of Gifts Two Years Ago', 'Count of all gifts two calendar years ago from the Account' },
            'Account.OppsClosedLastNDays__c' =>
                    new List<String>{ 'Account: Number of Gifts Last N Days', 'Count of all gifts for the last N days from the Account' },
            'Account.OppsClosedLastYear__c' =>
                    new List<String>{ 'Account: Number of Gifts Last Year', 'Count of all gifts in the previous calendar year from the Account' },
            'Account.OppsClosedThisYear__c' =>
                    new List<String>{ 'Account: Number of Gifts This Year', 'Count of all gifts in the current calendar year from the Account' },
            'Account.SmallestAmount__c' =>
                    new List<String>{ 'Account: Smallest Gift', 'Smallest gift amount from the Account' },

            /* ======== Account Membership ======== */
            'Account.TotalMembershipOppAmount__c' =>
                    new List<String>{ 'Account: Total Membership Amount', 'Total of all Memberships for the Account' },
            'Account.LastMembershipAmount__c' =>
                    new List<String>{ 'Account: Last Membership Amount', 'Amount of the most recent Membership Opportunity for the Account' },
            'Account.LastMembershipDate__c' =>
                    new List<String>{ 'Account: Last Membership Date', 'Close Date of the most recent Membership Opportunity for the Account' },
            'Account.LastMembershipLevel__c' =>
                    new List<String>{ 'Account: Last Membership Level', 'Membership Level from the most recent Membership Opportunity for the Account' },
            'Account.LastMembershipOrigin__c' =>
                    new List<String>{ 'Account: Last Membership Origin', 'Membership Origin from the most recent Membership Opportunity for the Account' },
            'Account.MembershipEndDate__c' =>
                    new List<String>{ 'Account: Membership End Date', 'Last Membership End Date for the Account' },
            'Account.MembershipJoinDate__c' =>
                    new List<String>{ 'Account: Membership Join Date', 'First Membership Join Date for the Account' },
            'Account.NumberOfMembershipOpps__c' =>
                    new List<String>{ 'Account: Number of Memberships', 'Count of all Membership Opportunities for the Account' },

            /* ======== Contact Hard Credit ======== */
            'Contact.TotalOppAmount__c' =>
                    new List<String>{ 'Contact: Total Gifts', 'Total of all gifts where the Contact is the Opportunity Primary Contact' },
            'Contact.AverageAmount__c' =>
                    new List<String>{ 'Contact: Average Gift', 'Average of all Gifts where the Contact is the Opportunity Primary Contact' },
            'Contact.Best_Gift_Year__c' =>
                    new List<String>{ 'Contact: Best Gift Year', 'Year with highest total gifts where the Contact is the Opportunity Primary Contact' },
            'Contact.Best_Gift_Year_Total__c' =>
                    new List<String>{ 'Contact: Best Gift Year Total', 'Total of all gifts in the best gift year where the Contact is the Opportunity Primary Contact' },
            'Contact.FirstCloseDate__c' =>
                    new List<String>{ 'Contact: First Gift Date', 'The date of the first gift where the Contact is the Opportunity Primary Contact' },
            'Contact.LargestAmount__c' =>
                    new List<String>{ 'Contact: Largest Gift', 'The largest gift where the Contact is the Opportunity Primary Contact' },
            'Contact.LastCloseDate__c' =>
                    new List<String>{ 'Contact: Last Gift Date', 'The close date of the most recent gift where the Contact is the Opportunity Primary Contact' },
            'Contact.LastOppAmount__c' =>
                    new List<String>{ 'Contact: Last Gift Amount', 'The amount of the most recent gift where the Contact is the Opportunity Primary Contact' },
            'Contact.NumberOfClosedOpps__c' =>
                    new List<String>{ 'Contact: Total Number of Gifts', 'The count of all gifts where the Contact is the Opportunity Primary Contact' },
            'Contact.OppAmount2YearsAgo__c' =>
                    new List<String>{ 'Contact: Total Gifts Two Years Ago', 'The total of all gifts two calendar years ago where the Contact is the Opportunity Primary Contact' },
            'Contact.OppAmountLastNDays__c' =>
                    new List<String>{ 'Contact: Total Gifts Last N Days', 'The total of all gifts in the last N days where the Contact is the Opportunity Primary Contact' },
            'Contact.OppAmountLastYear__c' =>
                    new List<String>{ 'Contact: Total Gifts Last Year', 'The total of all gifts in the last calendar year where the Contact is the Opportunity Primary Contact' },
            'Contact.OppAmountThisYear__c' =>
                    new List<String>{ 'Contact: Total Gifts This Year', 'The total of all gifts in the current calendar year where the Contact is the Opportunity Primary Contact' },
            'Contact.OppsClosed2YearsAgo__c' =>
                    new List<String>{ 'Contact: Number of Gifts Two Years Ago', 'The count of all gifts two calendar years ago where the Contact is the Opportunity Primary Contact' },
            'Contact.OppsClosedLastNDays__c' =>
                    new List<String>{ 'Contact: Number of Gifts Last N Days', 'The count of all gifts in the last N days where the Contact is the Opportunity Primary Contact' },
            'Contact.OppsClosedLastYear__c' =>
                    new List<String>{ 'Contact: Number of Gifts Last Year', 'The count of all gifts in the last calendar year where the Contact is the Opportunity Primary Contact' },
            'Contact.OppsClosedThisYear__c' =>
                    new List<String>{ 'Contact: Number of Gifts This Year', 'The count of all gifts in the current calendar year where the Contact is the Opportunity Primary Contact' },
            'Contact.SmallestAmount__c' =>
                    new List<String>{ 'Contact: Smallest Gift', 'The smallest gift where the Contact is the Opportunity Primary Contact' },

            /* ======== Contact Soft Credit ======== */
            'Contact.First_Soft_Credit_Date__c' =>
                    new List<String>{ 'Contact: First Soft Credit Date', 'Date of the first gift where the Contact received a Soft Credit' },
            'Contact.Last_Soft_Credit_Date__c' =>
                    new List<String>{ 'Contact: Last Soft Credit Date', 'Date of the last gift where the Contact received a Soft Credit' },
            'Contact.First_Soft_Credit_Amount__c' =>
                    new List<String>{ 'Contact: First Soft Credit Amount', 'Amount of the first gift where the Contact received a Soft Credit' },
            'Contact.Largest_Soft_Credit_Amount__c' =>
                    new List<String>{ 'Contact: Largest Soft Credit Amount', 'Largest gift where the Contact received a Soft Credit' },
            'Contact.Largest_Soft_Credit_Date__c' =>
                    new List<String>{ 'Contact: Largest Soft Credit Date', 'Date of the largest gift where the Contact received a Soft Credit' },
            'Contact.Last_Soft_Credit_Amount__c' =>
                    new List<String>{ 'Contact: Last Soft Credit Amount', 'Amount of the most recent gift where the Contact received a Soft Credit' },
            'Contact.Soft_Credit_Total__c' =>
                    new List<String>{ 'Contact: Soft Credit Total', 'Total of all gifts where the Contact received Soft Credit' },
            'Contact.Soft_Credit_This_Year__c' =>
                    new List<String>{ 'Contact: Soft Credit This Year', 'Total of all gifts in the current calendar year where the Contact received Soft Credit' },
            'Contact.Soft_Credit_Last_Year__c' =>
                    new List<String>{ 'Contact: Soft Credit Last Year', 'Total of all gifts in the previous calendar year where the Contact received Soft Credit' },
            'Contact.Soft_Credit_Two_Years_Ago__c' =>
                    new List<String>{ 'Contact: Soft Credit Two Years Ago', 'Total of all gifts two calendar years ago where the Contact received Soft Credit' },
            'Contact.Soft_Credit_Last_N_Days__c' =>
                    new List<String>{ 'Contact: Soft Credit Last N Days', 'Total of all first gifts in the last N days where the Contact received Soft Credit' },
            'Contact.Number_of_Soft_Credits__c' =>
                    new List<String>{ 'Contact: Number of Soft Credits', 'Count of all gifts where the Contact received Soft Credit' },
            'Contact.Number_of_Soft_Credits_This_Year__c' =>
                    new List<String>{ 'Contact: Number of Soft Credits This Year', 'Count of all gifts in the current calendar year where the Contact received Soft Credit' },
            'Contact.Number_of_Soft_Credits_Last_Year__c' =>
                    new List<String>{ 'Contact: Number of Soft Credits Last Year', 'Count of all gifts in the previous calendar year where the Contact received Soft Credit' },
            'Contact.Number_of_Soft_Credits_Two_Years_Ago__c' =>
                    new List<String>{ 'Contact: Number of Soft Credits Two Years Ago', 'Count of all gifts two calendar years ago where the Contact received Soft Credit' },
            'Contact.Number_of_Soft_Credits_Last_N_Days__c' =>
                    new List<String>{ 'Contact: Number of Soft Credits Last N Days', 'Count of all first gifts in the last N days where the Contact received Soft Credit' },

            /* ======== Contact Membership ======== */
            'Contact.TotalMembershipOppAmount__c' =>
                    new List<String>{ 'Contact: Total Membership Amount', 'Total of all Membership Donations where the Contact is the Opportunity Primary Contact' },
            'Contact.NumberOfMembershipOpps__c' =>
                    new List<String>{ 'Contact: Number of Memberships', 'Count of all Membership Donations where the Contact is the Opportunity Primary Contact' },
            'Contact.MembershipEndDate__c' =>
                    new List<String>{ 'Contact: Membership End Date', 'Latest Membership End Date where the Contact is the Opportunity Primary Contact' },
            'Contact.MembershipJoinDate__c' =>
                    new List<String>{ 'Contact: Membership Join Date', 'First Membership Join Date where the Contact is the Opportunity Primary Contact' },
            'Contact.LastMembershipAmount__c' =>
                    new List<String>{ 'Contact: Last Membership Amount', 'Amount of the most recent Membership Opportunity where the Contact is the Opportunity Primary Contact' },
            'Contact.LastMembershipDate__c' =>
                    new List<String>{ 'Contact: Last Membership Date', 'Latest Membership Close Date where the Contact is the Opportunity Primary Contact' },
            'Contact.LastMembershipLevel__c' =>
                    new List<String>{ 'Contact: Last Membership Level', 'Latest Membership Level where the Contact is the Opportunity Primary Contact' },
            'Contact.LastMembershipOrigin__c' =>
                    new List<String>{ 'Contact: Last Membership Origin', 'Latest Membership Origin where the Contact is the Opportunity Primary Contact' },

            /* ======== Allocation to GAU ======== */
            'General_Accounting_Unit__c.First_Allocation_Date__c' =>
                    new List<String>{ 'GAU: First Allocation Date', 'Date of the first Opportunity with an Allocation to this GAU' },
            'General_Accounting_Unit__c.Last_Allocation_Date__c' =>
                    new List<String>{ 'GAU: Last Allocation Date', 'Date of the last Opportunity with an Allocation to this GAU' },
            'General_Accounting_Unit__c.Largest_Allocation__c' =>
                    new List<String>{ 'GAU: Largest Allocation', 'Largest gift amount to this GAU' },
            'General_Accounting_Unit__c.Smallest_Allocation__c' =>
                    new List<String>{ 'GAU: Smallest Allocation', 'Smallest amount allocated to this GAU' },
            'General_Accounting_Unit__c.Total_Number_of_Allocations__c' =>
                    new List<String>{ 'GAU: Total Number of Allocations', 'Count of all gifts allocated to this GAU' },
            'General_Accounting_Unit__c.Number_of_Allocations_Last_N_Days__c' =>
                    new List<String>{ 'GAU: Number of Allocations Last N Days', 'Count of all gifts allocated in the last N days to this GAU' },
            'General_Accounting_Unit__c.Number_of_Allocations_Last_Year__c' =>
                    new List<String>{ 'GAU: Number of Allocations Last Year','Count of all gifts allocated in the last calendar year to this GAU' },
            'General_Accounting_Unit__c.Number_of_Allocations_This_Year__c' =>
                    new List<String>{ 'GAU: Number of Allocations This Year', 'Count of all gifts allocated in the current calendar year to this GAU' },
            'General_Accounting_Unit__c.Number_of_Allocations_Two_Years_Ago__c' =>
                    new List<String>{ 'GAU: Number of Allocations Two Years Ago', 'Count of all Allocation Amounts two calendar years ago to this GAU' },
            'General_Accounting_Unit__c.Average_Allocation__c' =>
                    new List<String>{ 'GAU: Average Allocation', 'Average gift amount to this GAU' },
            'General_Accounting_Unit__c.Total_Allocations__c' =>
                    new List<String>{ 'GAU: Total Allocations', 'Total of all gift amounts to this GAU' },
            'General_Accounting_Unit__c.Total_Allocations_Last_N_Days__c' =>
                    new List<String>{ 'GAU: Total Allocations Last N Days', 'Total amount of gifts allocated in the last N days to this GAU' },
            'General_Accounting_Unit__c.Total_Allocations_Last_Year__c' =>
                    new List<String>{ 'GAU: Total Allocations Last Year', 'Total of all Allocation Amounts in the last calendar year to this GAU' },
            'General_Accounting_Unit__c.Total_Allocations_This_Year__c' =>
                    new List<String>{ 'GAU: Total Allocations This Year', 'Total of all Allocation Amounts in the current calendar year to this GAU' },
            'General_Accounting_Unit__c.Total_Allocations_Two_Years_Ago__c' =>
                    new List<String>{ 'GAU: Total Allocations Two Years Ago', 'Total of all Allocation Amounts two calendar years ago to this GAU' },

            /* ======== Opportunity to Recurring Donation ======== */
            'Recurring_Donation__c.Next_Payment_Date__c' =>
                    new List<String>{ 'RD: Next Payment Date', 'Date of the next Opportunity set to close' },
            'Recurring_Donation__c.Last_Payment_Date__c' =>
                    new List<String>{ 'RD: Last Payment Date', 'Date of the last Closed Won Opportunity' },
            'Recurring_Donation__c.Paid_Amount__c' =>
                    new List<String>{ 'RD: Paid Amount', 'Sum of Opportunity Amounts of all Closed Won Opportunities' },
            'Recurring_Donation__c.Total_Paid_Installments__c' =>
                    new List<String>{ 'RD: Total Paid Installments', 'Count of all Closed Won Opportunities' }

    };

}
