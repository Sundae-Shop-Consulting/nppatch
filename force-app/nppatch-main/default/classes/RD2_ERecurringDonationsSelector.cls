/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @description Recurring Donations Selector class.
*/
public inherited sharing class RD2_ERecurringDonationsSelector {

    private final String ELEVATE_RD = 'Elevate Recurring Donations';
    private final String NONELEVATE_RD = 'Non-Elevate Recurring Donations';

    @TestVisible
    private Id currentContactId {
        get {
            if(currentContactId == null) {
                currentContactId = USER_UserService.getContactIdByUserId();
            }
            return currentContactId;
        }
        set;
    }

    /**
     * @description Returns the Recurring Donation records related to the Experience Site user.
     * @return List<Recurring_Donation__c>
     */
    public List<Recurring_Donation__c> getRecurringDonations(String elevateFilter) {

        Id currentContactId = this.currentContactId;
        List<Recurring_Donation__c> recurringDonations = new List<Recurring_Donation__c>();
        if(currentContactId != NULL) {
            String ns = UTIL_Namespace.getNamespace();
            String nsPrefix = String.isBlank(ns) ? '' : ns + '__';
            String queryString = 'SELECT ' + nsPrefix + 'Amount__c, FORMAT(' + nsPrefix + 'Amount__c) Amt, '
                                + nsPrefix + 'Installment_Period__c, '
                                + nsPrefix + 'InstallmentFrequency__c, '
                                + nsPrefix + 'Day_of_Month__c, '
                                + nsPrefix + 'Status__c, '
                                + nsPrefix + 'PaymentMethod__c, '
                                + nsPrefix + 'CardLast4__c, '
                                + nsPrefix + 'CardExpirationYear__c, '
                                + nsPrefix + 'CardExpirationMonth__c, '
                                + nsPrefix + 'ACH_Last_4__c, '
                                + nsPrefix + 'Last_Payment_Date__c, '
                                + nsPrefix + 'Installments__c, '
                                + nsPrefix + 'RecurringType__c, '
                                + nsPrefix + 'Date_Established__c, '
                                + nsPrefix + 'Next_Payment_Date__c, '
                                + nsPrefix + 'Total_Paid_Installments__c, '
                                + 'Lastmodifieddate '
                                + 'FROM ' + nsPrefix + 'Recurring_Donation__c '
                                + 'WHERE ' + nsPrefix + 'Contact__c = \'' + currentContactId + '\' ';

            queryString += 'WITH SECURITY_ENFORCED ';
            queryString += 'ORDER BY ' + nsPrefix + 'Next_Payment_Date__c DESC NULLS LAST';

            recurringDonations = Database.query(queryString);
        }
        return recurringDonations;
    }
}