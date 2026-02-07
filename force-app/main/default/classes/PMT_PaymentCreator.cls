/*
    Copyright (c) 2009, Salesforce.org
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
* @author Nick Bailey 
* @date 2011 (2.1)
* @group Payments
* @description Controls the creation of payment objects from Opportunity trigger
*/
public class PMT_PaymentCreator {

    /* @description Retrieve info about specific fields that may or may not exist on the objects */
    public static final SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
    public static final SObjectField PaymentCurrencyField = Schema.sObjectType.OppPayment__c.fields.getMap().get('CurrencyIsoCode');
    private static final SObjectField OppRecordTypeId = Schema.sObjectType.Opportunity.fields.getMap().get('RecordTypeId');


    /**
    * @description map of Opportunity to Payment field mappings, validated to only contain mappings that
    * are of compatible types.
    */ 
    public static map<string, Payment_Field_Mapping_Settings__c> paymentMappings {
        get {
            if (paymentMappings == null) {
                //load custom field mapping settings - if they exist        
                map<string, Payment_Field_Mapping_Settings__c> paymentMappingsAll = UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings().clone();
                paymentMappings = UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings().clone();
            
                for (string s : paymentMappingsAll.keySet()){
                    Payment_Field_Mapping_Settings__c pfms = paymentMappingsAll.get(s); 
                
                    SobjectField opportunityField;
                    SobjectField paymentField;
                    boolean isValid = true; 
                                
                    //check Opp fields
                    opportunityField = Schema.sObjectType.Opportunity.fields.getMap().get(pfms.Opportunity_Field__c);
                              
                    //check Payment fields            
                    paymentField = Schema.sObjectType.OppPayment__c.fields.getMap().get(pfms.Payment_Field__c);
                        
                    if (paymentField != null && opportunityField != null) {
                        Schema.DisplayType payF = paymentField.getDescribe().getType();
                        Schema.DisplayType oppF = opportunityField.getDescribe().getType();
                        isValid = UTIL_Describe.canDisplaytypesCopy(oppF, payF);
                    } else {
                        isValid = false;
                    }
    
                    if (isValid == false) paymentMappings.keyset().remove(s);                         
                }
                
            }
            return paymentMappings;
        }
        set;
    }
    
    /**
    * @description set of Opportunity Recordtype Id's to not create Payments for.
    */ 
    public static set<id> setOppRecordTypeIdNoPayment {
        get {
            if (setOppRecordTypeIdNoPayment == null) {
                string strProp = UTIL_CustomSettingsFacade.getContactsSettings().Opp_RecTypes_Excluded_for_Payments__c;
                if (strProp != null) {
                    setOppRecordTypeIdNoPayment = new Set<Id>((List<Id>)strProp.split(';'));
                } else {
                    setOppRecordTypeIdNoPayment = new set<Id>();
                }
            }
            return setOppRecordTypeIdNoPayment;
        }
        set;
    }

    /**
    * @description set of Opportunity Type values to not create Payments for.
    */ 
    public static set<string> setOppTypeNoPayment {
        get {
            if (setOppTypeNoPayment == null) {
                string strProp = UTIL_CustomSettingsFacade.getContactsSettings().Opp_Types_Excluded_for_Payments__c;
                if (strProp != null) {
                    setOppTypeNoPayment = new set<string>(strProp.split(';'));    
                } else {
                    setOppTypeNoPayment = new set<string>();
                }
            }
            return setOppTypeNoPayment;
        }
        set;
    }
    
    /**
    * @description Check if Advanced Currency Management is enabled
    */
    private static Boolean isACMEnabled {
        get {
            if (isACMEnabled == null) {
                isACMEnabled = UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled();
            }
            return isACMEnabled;
        }
        set;
    }

    /**
    * @description Contact Settings custom setting 
    */
    private static Contacts_And_Orgs_Settings__c contactSettings{
        get {
            if (contactSettings == null) {
                contactSettings = UTIL_CustomSettingsFacade.getContactsSettings();
            }
            return contactSettings;
        }
        set;
    } 

    /**
    * @description Execute different functions based on trigger context
    * @param triggerAction Current trigger action context
    * @param newOpps Opportunity trigger new list
    * @param oldMap Opportunity trigger old map
    * @param dmlWrapper TDTM dml wrapper to update records
    */
    public void run(TDTM_Runnable.Action triggerAction, List<Opportunity> newOpps, Map<Id, Opportunity> oldMap, TDTM_Runnable.DMLWrapper dmlWrapper) {
        switch on triggerAction {

            when BeforeUpdate {
                closeOppsWhenFullPaymentsReceived(newOpps, oldMap);
            }
            when AfterInsert {
                autoCreateOppPayments(newOpps, dmlWrapper);
            }
            when AfterUpdate {
                evaluateOpportunityPayments(newOpps, oldMap, dmlWrapper);
            }

            when else {
            }
        }
    }

    /**
    * @description Evaluate if the opportunity stage needs to be updated when payments are fully received.
    *   If ACM is enabled in an organization, changes to the Payment object will not roll-up to (and cause triggers
    *   to execute) on the Opportunity. The trigger on the Payment Object is used to detect a new/updated payment
    *   and to handle auto-closing the Opportunity if necessary. However, if the Opportunity.Amount is updated to
    *   match the total of the payments, the Opportunity must still be closed. However, when ACM is enabled
    *   the Payments_Made__c rollup field on the Opportunity does not work. In this case, we have to force
    *   a requery of the Opportunities (with a sub-query on Payments) to allow the actual Payment Amount to be
    *   queried.
    * @param newOpps Opportunity trigger new list
    * @param oldMap Opportunity trigger old map
    */
    private void closeOppsWhenFullPaymentsReceived(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (String.isBlank(contactSettings.Payments_Auto_Close_Stage_Name__c)) {
            return;
        }

        Map<Id, Opportunity> newOppsMapRequeried = new Map<Id, Opportunity>();

        if (isACMEnabled) {
            newOppsMapRequeried = new Map<Id, Opportunity>(getPaymentOpportunities(newOpps));
        }

        for (Opportunity opp : newOpps) {
            Decimal totalPaymentAmount = (isACMEnabled)
                ? PMT_PaymentCreator.getPaymentsMade(newOppsMapRequeried.get(opp.Id))
                : opp.Payments_Made__c;

            closeOpportunityIfAllPaymentsReceived(
                oldMap.get(opp.Id),
                opp,
                contactSettings.Payments_Auto_Close_Stage_Name__c,
                totalPaymentAmount
            );
        }
    }

    /**
    * @description automatically create opportunity payments when Payments_Enabled__c is enabled
    * @param newOpps Opportunity Trigger new list
    * @param dmlWrapper TDTM DML wrapper
    */
    private void autoCreateOppPayments(List<Opportunity> newOpps, TDTM_Runnable.DMLWrapper dmlWrapper) {
        if (contactSettings == null || contactSettings.Payments_Enabled__c == false) {
            return;
        }

        List<OppPayment__c> paymentsToInsert = new List<OppPayment__c>();

        for (Opportunity thisOpp : newOpps) {
            if (isNoPaymentForOpp(thisOpp)) {
                continue;
            }

            // if opp is closed won with no payments scheduled or made, add an automatic payment
            if ( /*(thisOpp.IsClosed && thisOpp.IsWon) && */
                thisOpp.amount > 0 && thisOpp.payments_made__c == 0 && thisOpp.Number_of_Payments__c == 0) {

                oppPayment__c op = new oppPayment__c(
                    opportunity__c = thisOpp.Id
                );

                //in multicurrency SFDC set the payment currency field to equal to the opp currency
                if(paymentCurrencyField != null && oppCurrencyField != null) {
                    op.put(paymentCurrencyField, thisOpp.get(oppCurrencyField));
                }

                op.payment_amount__c = thisOpp.amount;

                if(paymentMappings.size() > 0) {
                    for (string s : paymentMappings.keyset()) {
                        Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
                        string oppField = pfms.Opportunity_Field__c;
                        if (thisOpp.get(oppField) != null) {
                            op.put(pfms.Payment_Field__c, thisOpp.get(oppField));
                        }
                    }
                }

                if (thisOpp.IsClosed && thisOpp.IsWon){
                    op.Paid__c = true;
                    op.payment_date__c = thisOpp.closeDate;
                }

                if (!thisOpp.IsClosed) {
                    op.Paid__c = false;
                    op.scheduled_date__c = thisOpp.closeDate;
                }

                paymentsToInsert.add(op);
            }
        }
        
        if (!paymentsToInsert.isEmpty()) {
            dmlWrapper.objectsToInsert.addAll((list<SObject>) paymentsToInsert);
        }
    }

    /**
    * @description Evaluate if opportunity payments need to be updated when opportunity is updated
    * @param newOpps Opportunity trigger new list
    * @param oldOppsMap Opportunity trigger old map
    * @param dmlWrapper TDTM DML wrapper
    */
    private void evaluateOpportunityPayments(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap, TDTM_Runnable.DMLWrapper dmlWrapper) {
        if (contactSettings == null || contactSettings.Payments_Enabled__c == false) {
            return;
        }

        list<OppPayment__c> paymentsToInsert = new list<OppPayment__c>();
        list<OppPayment__c> paymentsToUpdate = new list<OppPayment__c>();

        for (Opportunity thisOpp : getPaymentOpportunities(newOpps)){
            Opportunity oldOpp = oldOppsMap.get(thisOpp.id);
            
            boolean mappingsUpdated = false;
            
            //check to see if any of the custom mapped fields have been updated
            for (string s : paymentMappings.keyset()){
                if(thisOpp.get(paymentMappings.get(s).Opportunity_Field__c) != oldOpp.get(paymentMappings.get(s).Opportunity_Field__c)){
                    mappingsUpdated = true;
                }
            }

            // Use a method to determine the value for total payments that takes Advanced Currency Management
            // into consideration.
            Decimal totalPaymentsMade = getPaymentsMade(thisOpp);

            if (thisOpp.OppPayment__r.size() > 0){
                    // if opp is updated, update the automatic payment
                if ( ((thisOpp.Amount != oldOpp.Amount) || (thisOpp.CloseDate != oldOpp.CloseDate) || mappingsUpdated == true) &&
                        (thisOpp.OppPayment__r[0].Scheduled_Date__c == oldOpp.CloseDate || thisOpp.OppPayment__r[0].Scheduled_Date__c == thisOpp.CloseDate) &&
                        (thisOpp.OppPayment__r[0].Payment_Amount__c == oldOpp.Amount || thisOpp.OppPayment__r[0].Payment_Amount__c == thisOpp.Amount) &&
                        thisOpp.OppPayment__r.size() == 1 &&
                        thisOpp.OppPayment__r[0].paid__c == False &&
                        //open opportunities only
                        !thisOpp.isClosed && thisOpp.amount > 0 &&
                        totalPaymentsMade == 0) {
                    thisOpp.OppPayment__r[0].scheduled_date__c = thisOpp.closeDate;
                    thisOpp.OppPayment__r[0].payment_amount__c = thisOpp.amount;
                    
                    
                    if (paymentMappings.size() > 0){
                        for (string s : paymentMappings.keyset()){
                                Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
                                string x = pfms.Opportunity_Field__c;
                                if (thisOpp.get(x) != null)
                                    thisOpp.OppPayment__r[0].put(pfms.Payment_Field__c, thisOpp.get(x));
                        }
                    }
                    
                    paymentsToUpdate.add(thisOpp.OppPayment__r[0]);
                }
                else if ( ((thisOpp.Amount != oldOpp.Amount) || (thisOpp.CloseDate != oldOpp.CloseDate) || (thisOpp.isWon != oldOpp.IsWon)) &&
                        (thisOpp.OppPayment__r[0].scheduled_Date__c == oldOpp.CloseDate || thisOpp.OppPayment__r[0].scheduled_Date__c == thisOpp.CloseDate || thisOpp.OppPayment__r[0].Payment_Date__c == oldOpp.CloseDate || thisOpp.OppPayment__r[0].Payment_Date__c == thisOpp.CloseDate) &&
                        (thisOpp.OppPayment__r[0].Payment_Amount__c == oldOpp.Amount || thisOpp.OppPayment__r[0].Payment_Amount__c == thisOpp.Amount) &&
                        thisOpp.OppPayment__r.size() == 1 &&
                        thisOpp.OppPayment__r[0].paid__c == False &&
                        //closed/won opportunities only
                        thisOpp.isClosed && thisOpp.isWon && thisOpp.amount > 0 &&
                        totalPaymentsMade == 0) {
                    thisOpp.OppPayment__r[0].payment_date__c = thisOpp.closeDate;
                    thisOpp.OppPayment__r[0].payment_amount__c = thisOpp.amount;
                    thisOpp.OppPayment__r[0].paid__c = true;
                    paymentsToUpdate.add(thisOpp.OppPayment__r[0]);
                
                }
                //closed/lost opportunities only
                else if ( thisOpp.isClosed && !thisOpp.isWon) {
                    
                    for(OppPayment__c thisPayment : thisOpp.OppPayment__r){
                        if(thisPayment.Paid__c == False && thisPayment.Written_Off__c == False){
                            thisPayment.Written_Off__c = true;
                            paymentsToUpdate.add(thisPayment);
                        }
                    }
                }
            }
            
            // we may need to add payments if the open opp amount has been changed from $0
            else if (
                    thisOpp.Amount != null && thisOpp.Amount != 0 && 
                    (thisOpp.IsClosed == false || thisOpp.IsWon == true) &&
                    (oldOpp.Amount == null || oldOpp.Amount == 0) && 
                    isNoPaymentForOpp(thisOpp) == false
                ) {
                
                paymentsToInsert.add(constructOppPayment(thisOpp, paymentCurrencyField, oppCurrencyField));                                              
            }
        }
        // update or delete payments     
        if (!paymentsToUpdate.isEmpty())
            dmlWrapper.objectsToUpdate.addAll((list<SObject>)paymentsToUpdate);
        if (!paymentsToInsert.isEmpty())
            dmlWrapper.objectsToInsert.addAll((list<SObject>)paymentsToInsert);
    }

    /**
     * @description Creates a Payment for the input Opportunity
     * @param newOpportunity the new value of the updated Opportunity
     * @param paymentCurrencyField The Payment Object Currency Field
     * @param oppCurrencyField The Opportunity Object Currency Field
     * @return OppPayment__c The Opportunity Payment created
     */
    public static OppPayment__c constructOppPayment(Opportunity newOpportunity, SObjectField paymentCurrencyField, SObjectField oppCurrencyField) {
        OppPayment__c opportunityPayment = new OppPayment__c(
            Opportunity__c = newOpportunity.Id,
            Paid__c = newOpportunity.IsClosed,
            Payment_Amount__c = newOpportunity.Amount
        );

        if (opportunityPayment.Paid__c) {
            opportunityPayment.Payment_Date__c = newOpportunity.CloseDate;
        } else {
            opportunityPayment.Scheduled_Date__c = newOpportunity.CloseDate;
        }
                
        //in multicurrency SFDC set the payment currency field to equal to the opp currency
        if (paymentCurrencyField != null && oppCurrencyField != null) {
            opportunityPayment.put(paymentCurrencyField, newOpportunity.get(oppCurrencyField));
        }
        
        for (Payment_Field_Mapping_Settings__c paymentMapping : paymentMappings.values()) {
            if (newOpportunity.get(paymentMapping.Opportunity_Field__c) != null) {
                opportunityPayment.put(
                    paymentMapping.Payment_Field__c, 
                    newOpportunity.get(paymentMapping.Opportunity_Field__c)
                );
            }
        }

        return opportunityPayment;
    }

    /**
     * @description Close an opportunity if all payments have been received.
     * This will update the StageName of newOpp, in place, if "all payments
     * received" conditions are satisfied.
     * This method will not execute if Advanced Currency Mgt is enabled. In that
     * case, a trigger on the Payment object is used to auto-close the Opportunity.
     * @param oldOpp The opportunity before being updated
     * @param newOpp The opportunity after being updated
     * @param closedStageName The name of an opportunity stage that corresponds to Closed/Won to transition to if all payments are determined to be received
     * @param totalPaymentAmount The total amount of all Paid Payment records for the Opportunity
     * @return void
     */
    private void closeOpportunityIfAllPaymentsReceived(Opportunity oldOpp, Opportunity newOpp, String closedStageName,
            Decimal totalPaymentAmount) {
        Boolean amountUpdated = (oldOpp.Amount != newOpp.Amount);
        Boolean paymentAmountReceivedUpdated = (oldOpp.Payments_Made__c != totalPaymentAmount);
        Boolean amountPositive = (newOpp.Amount > 0);
        Boolean isNotAndWasNotClosed = (!oldOpp.IsClosed && !newOpp.IsClosed);
        Boolean isAmountEqualOrGreaterPaymentReceived;

        // If the org has multicurrency set up we need to round the currency value
        if (UTIL_Currency.getInstance().isMultiCurrencyOrganization()) {
            String oppCurrency = (UserInfo.isMultiCurrencyOrganization())
                ? (String) newOpp.get('CurrencyIsoCode')
                : UserInfo.getDefaultCurrency();
            Integer decimalPlaces = UTIL_CurrencyCache.getInstance().getCurrDecimalPlaces(oppCurrency);
            isAmountEqualOrGreaterPaymentReceived = isEqualOrGreaterWhenRounded(totalPaymentAmount, newOpp.Amount, decimalPlaces);

        } else {
            isAmountEqualOrGreaterPaymentReceived = (totalPaymentAmount >= newOpp.Amount);
        }

        Boolean stageNameSpecified = !String.isEmpty(closedStageName);
        if (
            (amountUpdated || paymentAmountReceivedUpdated)
            && amountPositive
            && isNotAndWasNotClosed
            && isAmountEqualOrGreaterPaymentReceived
            && stageNameSpecified
        ) {
            newOpp.StageName = closedStageName;
        }
    }


    /**
    * @description return true if amount 1 is equal or greater than amount 2 when rounded on the same decimal scale.
    * @param Decimal amount1 one of the decimal values to compare.
    * @param Decimal amount2 the other decimal value to compare.
    * @param Integer decimalPlaces for both values
    * @return Boolean stating id booth Decimal values are equal.
    */
    private static Boolean isEqualOrGreaterWhenRounded(Decimal amount1, Decimal amount2, Integer decimalPlaces) {
        Decimal amount1Rounded = amount1 != null ? amount1.setScale(decimalPlaces) : null;
        Decimal amount2Rounded = amount2 != null ? amount2.setScale(decimalPlaces) : null;
        return (amount1Rounded >= amount2Rounded);
    }

    /**
    * @description Specifies whether Payments should be excluded for the Opportunity
    *   The payment should not be created if:
    *   - Record Type or Type is excluded in the Contact Settings Custom Setting
    *   - Do_Not_Automatically_Create_Payment__c is true
    * @param opp the Opportunity to evaluate.
    * @return Boolean true if Payments excluded for the Opportunity
    */ 
    private static boolean isNoPaymentForOpp(Opportunity opp) {
        return (opp.Do_Not_Automatically_Create_Payment__c
            || setOppTypeNoPayment.contains(opp.Type)
            || setOppRecordTypeIdNoPayment.contains((Id) opp.get('RecordTypeId'))
        );
    }   

    /**
    * @description When Advanced Currency Management is enabled in an org, the packaged rollups and formula
    * from the Payment object will not work. This method will detect that scenario and return either the
    * value from the formula or calculate the Amount Outstanding from the payment records
    * track this.
    * @param currentOpp = Opportunity object with a subquery on all Payment records
    * @return Decimal amount outstanding
    */
    public static Decimal getAmountOutstanding(Opportunity currentOpp) {
        if (!UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled()) {
            return currentOpp.Amount_Outstanding__c;
        } else {
            // calculate the value since the roll-ups and formula are not functional with ACM
            Decimal totalPayments = 0;
            Decimal amtWrittenOff = 0;
            for (OppPayment__c pmt : currentOpp.OppPayment__r) {
                if (pmt.Paid__c == true) {
                    totalPayments += pmt.Payment_Amount__c;
                }
                if (pmt.Written_Off__c == true) {
                    amtWrittenOff += pmt.Payment_Amount__c;
                }
            }
            return (currentOpp.Amount - totalPayments - amtWrittenOff);
        }
    }

    /**
    * @description When Advanced Currency Management is enabled in an org, the packaged rollups and formula
    * from the Payment object will not work. This method will detect that scenario and return either the
    * value from the formula or calculate the Total Payments (Paid) from the payment records
    * track this.
    * @param currentOpp = Opportunity object with a subquery on all Payment records
    * @return Decimal total of payment records where Paid = True
    */
    public static Decimal getPaymentsMade(Opportunity currentOpp) {
        if (!UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled()) {
            return currentOpp.Payments_Made__c;
        } else {
            // calculate the value since the roll-ups and formula are not functional with ACM
            Decimal totalPayments = 0;
            for (OppPayment__c pmt : currentOpp.OppPayment__r) {
                if (pmt.Paid__c == true) {
                    totalPayments += pmt.Payment_Amount__c;
                }
            }
            return totalPayments;
        }
    }

    /**
    * @description Query opportunities with payments
    * @return List<Opportunity> 
    */
    private List<Opportunity> getPaymentOpportunities(List<Opportunity> newOpps) {
        return Database.query(buildOppsQuery() + 'WHERE Id IN :newOpps');
    }

    /**
     * @description Build a query string to retrieve a list of Opportunities with a subquery on the Payments object.
     * Does not include a Where clause.
     * @return SOQL string
     */
    private static String buildOppsQuery() {
        String soqlStatement = '';
        soqlStatement += 'SELECT Id, CloseDate, Amount, isClosed, isWon, Do_Not_Automatically_Create_Payment__c, Type, ';
        if (OppRecordTypeId != null) {
            soqlStatement += 'RecordTypeId, ';
        }
        for (string s : paymentMappings.keyset()) {
            Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
            if (!soqlStatement.contains(pfms.Opportunity_Field__c)) {
                soqlStatement += pfms.Opportunity_Field__c + ', ';
            }
        }
        if (OppCurrencyField!=null) {
            soqlStatement += 'CurrencyIsoCode, ';
        }
        soqlStatement += 'payments_made__c, ';
        string soqlSub = '(SELECT id, Paid__c, Payment_Amount__c, Payment_Date__c, Written_Off__c, ';
        for (string s : paymentMappings.keyset()) {
            Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
            if (!soqlSub.contains(pfms.Payment_Field__c)) {
                soqlSub += pfms.Payment_Field__c + ', ';
            }
        }
        soqlStatement += soqlSub;
        soqlStatement += 'scheduled_date__c ';
        soqlStatement += 'FROM Opportunity.OppPayment__r ' +
                'WHERE Written_Off__c = false) ' +
                'FROM Opportunity ';

        return soqlStatement;
    }
}