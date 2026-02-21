/*
    Copyright (c) 2022, Salesforce.org
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
* @group Payment
* @description Payment Refund Service
*/
public inherited sharing class PMT_RefundService {
    public static final String FULL_REFUND = 'Refund';
    public static final String PARTIAL_REFUND = 'Partial Refund';

    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    @TestVisible
    private PaymentSelector paymentSelector {
        get {
            if (paymentSelector == null) {
                paymentSelector = new PaymentSelector();
            }
            return paymentSelector;
        }
        set;
    }

    @TestVisible
    private AllocationSelector allocationSelector {
        get {
            if (allocationSelector == null) {
                allocationSelector = new AllocationSelector();
            }
            return allocationSelector;
        }
        set;
    }

    @TestVisible
    private OpportunitySelector opportunitySelector {
        get {
            if (opportunitySelector == null) {
                opportunitySelector = new OpportunitySelector();
            }
            return opportunitySelector;
        }
        set;
    }

    @TestVisible
    private List<OppPayment__c> originalPayments {
        get {
            if (originalPayments == null && originalPaymentIds != null) {
                originalPayments = paymentSelector.getPaymentsWithRefunds(originalPaymentIds);
            }
            return originalPayments;
        }
        set;
    }

    private Set<Id> originalPaymentIds {
        get {
            if (originalPaymentIds == null) {
                if (originalPayments != null) {
                    originalPaymentIds = UTIL_SObject.extractIds(originalPayments);
                } else if (refundRecords != null) {
                    UTIL_SObject.extractId(refundRecords, OppPayment__c.originalPayment__c);
                }
            }
            return originalPaymentIds;
        }
        set;
    }

    @TestVisible
    private Map<Id, RefundInfo> originalPaymentWithRefunds {
        get {
            if (originalPaymentWithRefunds == null) {
                originalPaymentWithRefunds = getOriginalPaymentWithRefundInfo(this.originalPayments);
            }
            return originalPaymentWithRefunds;
        }
        set;
    }

    public static Allocations_Settings__c allocationSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();


    private List<OppPayment__c> refundRecords = new List<OppPayment__c>();
    private List<OppPayment__c> oldRefundRecords = new List<OppPayment__c>();
    @TestVisible
    private Map<Id, Opportunity> opportunityMap;
    @TestVisible
    private List<Allocation__c> allocationsToUpdate = new List<Allocation__c>();
    private Map<Id, ErrorRecord> paymentIdToErrorRecord = new Map<Id, ErrorRecord>();

    public static Boolean isElevateEnabled() {
        return false;
    }

    public PMT_RefundService withOriginalPayments(List<OppPayment__c> originalPayments) {
        this.originalPayments = originalPayments;
        return this;
    }

    public PMT_RefundService withOriginalPaymentIds(Set<Id> originalPaymentIds) {
        this.originalPaymentIds = originalPaymentIds;
        return this;
    }

    public PMT_RefundService withRefundRecords(List<OppPayment__c> refundRecords) {
        this.refundRecords = refundRecords;
        return this;
    }

        public PMT_RefundService withOldRefundRecords(List<OppPayment__c> oldRefundRecords) {
        this.oldRefundRecords = oldRefundRecords;
        return this;
    }

    public List<OppPayment__c> getRefundRecords() {
        return this.refundRecords;
    }

    public List<ErrorRecord> getErrors() {
        return this.paymentIdToErrorRecord.values();
    }

    public RefundInfo getRefundInfoFor(Id originalPaymentId) {
        if (originalPaymentId == null) {
            return null;
        }

        RefundInfo refundInfo = this.originalPaymentWithRefunds.get(originalPaymentId);

        if (refundInfo == null) {
            OppPayment__c payment = paymentSelector.getPaymentRecordForRefund(originalPaymentId);
            this.originalPayments.add(payment);
            refundInfo = new RefundInfo(payment);
            this.originalPaymentWithRefunds.put(payment.Id, refundInfo);
        }

        return refundInfo;
    }

    public UTIL_Http.Response getElevatePaymentRefundInfo(String transactionId) {
        return null;
    }

    public UTIL_Http.Response processElevateRefund(String transactionId, Decimal refundAmount) {
        return null;
    }

    public OppPayment__c buildRefundRecord(OppPayment__c originalPayment, Decimal refundAmount) {
        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -1 * refundAmount,
            Opportunity__c = originalPayment.Opportunity__c,
            OriginalPayment__c = originalPayment.Id,
            Paid__c = true,
            Payment_Date__c = Date.today(),
            DebitType__c = (originalPayment.Payment_Amount__c == refundAmount)
                ? PMT_RefundService.FULL_REFUND
                : PMT_RefundService.PARTIAL_REFUND
        );
        
        if (isMultiCurrencyEnabled) {
            refund.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD));
        }

        this.refundRecords.add(refund);
        return refund;
    }

    public PMT_RefundService adjustAllocationsAndOpportunities() {
        processAllocations();
        processOpportunities();
        return this;
    }

    public void insertRefunds() {
        List<Database.SaveResult> saveResults = Database.insert(this.refundRecords, false);
        for (Integer i = 0; i < this.refundRecords.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                processError(
                    new List<OppPayment__c>{this.refundRecords[i]},
                    saveResults[i].getErrors()[0].getMessage()
                );
            }
        }
    }

    public void updateAllocationsAndOpportunities() {
        List<Database.SaveResult> allocationResults;
        List<Database.SaveResult> opportunityResults;

        if (!this.allocationsToUpdate.isEmpty()) {
            ALLO_AllocationsUtil.disableAllocationTriggers();
            allocationResults = Database.update(this.allocationsToUpdate, false);
            ALLO_AllocationsUtil.enableAllocationTriggers();
        }
        if (!this.opportunityMap.isEmpty()) {
            opportunityResults = Database.update(this.opportunityMap.values(), false);
        }

        Map<Id, List<OppPayment__c>> refundsGroupByOpps = groupRefundsByOpp();

        for (Integer i = 0; i < this.allocationsToUpdate.size(); i++) {
            if (!allocationResults[i].isSuccess()) {
                processError(
                    refundsGroupByOpps.get(this.allocationsToUpdate[i].Opportunity__c),
                    allocationResults[i].getErrors()[0].getMessage()
                );
            }
        }

        for (Integer i = 0; i < this.opportunityMap.values().size(); i++) {
            if (!opportunityResults[i].isSuccess()) {
                processError(
                    refundsGroupByOpps.get(this.opportunityMap.values()[i].Id),
                    opportunityResults[i].getErrors()[0].getMessage()
                );
            }
        }
    }

    private void processError(List<oppPayment__c> refunds, String errorMessage) {
        for (OppPayment__c refund : refunds ){
            ErrorRecord error = this.paymentIdToErrorRecord.get(refund.Id);
            if (error == null) {
                error = new ErrorRecord(refund);
                this.paymentIdToErrorRecord.put(refund.Id, error);
            }
            error.addError(errorMessage);
        }
    }

    private Map<Id, List<OppPayment__c>> groupRefundsByOpp() {
        Map<Id, List<OppPayment__c>> refundsGroupByOpp = new Map<Id, List<OppPayment__c>>();
        for (OppPayment__c refund : this.refundRecords) {
            List<OppPayment__c> oppRefunds = refundsGroupByOpp.get(refund.Opportunity__c);

            if (oppRefunds == null) {
                oppRefunds = new List<OppPayment__c>();
                refundsGroupByOpp.put(refund.Opportunity__c, oppRefunds);
            }
            oppRefunds.add(refund);
        }

        return refundsGroupByOpp;
    }

    private Map<Id, RefundInfo> getOriginalPaymentWithRefundInfo(List<OppPayment__c> originalPayments) {
        Map<Id, RefundInfo> paymentIdToRefundabInfo = new Map<Id, RefundInfo>();

        for (OppPayment__c originalPayment : originalPayments) {
            RefundInfo refundInfo = new refundInfo(originalPayment);

            paymentIdToRefundabInfo.put(originalPayment.Id, refundInfo);
        }

        return paymentIdToRefundabInfo;
    }

    private void processAllocations() {
        Set<Id> partialRefundOppIds = new Set<Id>();
        for (OppPayment__c refund : this.refundRecords) {
            if (refund.DebitType__c == PARTIAL_REFUND) {
                partialRefundOppIds.add(refund.Opportunity__c);
            }
        }
        List<Allocation__c> allocations = allocationSelector.getOpportunityAllocations(partialRefundOppIds);
        Map<Id, List<Allocation__c>> allocationsGroupByOpp = new Map<Id, List<Allocation__c>>();

        for (Allocation__c allocation : allocations) {
            if (allocationSettings.Default_Allocations_Enabled__c && allocation.General_Accounting_Unit__c == allocationSettings.default__c) {
                continue;
            }
          
            List<Allocation__c> groupedAllocations = allocationsGroupByOpp.get(allocation.Opportunity__c);
            
            if(groupedAllocations == null) {
                groupedAllocations = new List<Allocation__c>();
                allocationsGroupByOpp.put(allocation.Opportunity__c, groupedAllocations);
            }

            groupedAllocations.add(allocation);
        }

        for (List<Allocation__c> groupedAllocations : allocationsGroupByOpp.values()) {
            convertFixedAmountAllocationsToPercentage(groupedAllocations);
        }
    }

    private void processOpportunities() {
        this.opportunityMap = new Map<Id, Opportunity>(
            opportunitySelector.getRefundOpportunities(
                UTIL_SObject.extractId(this.refundRecords, OppPayment__c.Opportunity__c))
        );

        for (Integer i = 0; i < this.refundRecords.size(); i++) {
            Opportunity parentOpp = this.opportunityMap.get(this.refundRecords[i].Opportunity__c);
            parentOpp.Amount = (parentOpp.Amount == null) ? 0 : parentOpp.Amount;
            parentOpp.Amount += getAdjustedRefundAmount(i);
        }

    }

    private Decimal getAdjustedRefundAmount(Integer index) {
       Decimal oldRefundAmount = (isUpdatingRefund()) ? this.oldRefundRecords[index].Payment_Amount__c : 0;
       return this.refundRecords[index].Payment_Amount__c - oldRefundAmount;
    }

    private Boolean isUpdatingRefund() {
        return !this.oldRefundRecords.isEmpty();
    }

    private void convertFixedAmountAllocationsToPercentage(List<Allocation__c> allocations) {
        if (allocations == null || allocations.isEmpty()) {
            return;
        }

        List<Allocation__c> toUpdate = new List<Allocation__c>();

        Decimal oppAmount = allocations[0].Opportunity__r.Amount;
        Double percentage = 0.0;
        for (Allocation__c allocation : allocations) {
            if (allocation.Percent__c == null) {
                allocation.Percent__c = allocation.Amount__c / oppAmount * 100;
                allocation.Amount__c = (oppAmount * allocation.Percent__c / 100).setScale(2);
                toUpdate.add(allocation);
            }

            percentage += allocation.Percent__c;
        }

        //There is a edge case where the total percentage will go over 100%. In this rare case,
        //the first adjusted allocation percentage will be deduct to match 100%
        if (percentage > 100) {
            toUpdate[0].Percent__c = toUpdate[0].Percent__c - (percentage - 100);
        }

        this.allocationsToUpdate.addAll(toUpdate);
    }

    public inherited sharing class RefundInfo {
        public OppPayment__c originalPayment;
        public Decimal remainingBalance;

        public RefundInfo(OppPayment__c originalPayment) {
            this.originalPayment = originalPayment;
            this.remainingBalance = this.originalPayment.Payment_Amount__c;

            if (this.originalPayment.Refunds__r != null) {
                for (OppPayment__c refund : originalPayment.Refunds__r) {
                    remainingBalance += refund.Payment_Amount__c;
                }
            }
        }

        public void updateRemainingBalance(OppPayment__c currentRefund) {
            this.remainingBalance = getNewRemiaingBalanceWith(currentRefund);
        }

        public Decimal getNewRemiaingBalanceWith(OppPayment__c currentRefund) {
            Decimal tempBalance = this.remainingBalance;
            if (currentRefund.Id == null || this.originalPayment.Refunds__r == null) {
                tempBalance += currentRefund.Payment_Amount__c;
               
            } else {
                for (OppPayment__c previousRefund : originalPayment.Refunds__r) {
                    if (previousRefund.Id == currentRefund.Id) {
                        tempBalance -= previousRefund.Payment_Amount__c;
                        break;
                    }
                }
                tempBalance += currentRefund.Payment_Amount__c;
            }

            return tempBalance;
        }
    }
}
