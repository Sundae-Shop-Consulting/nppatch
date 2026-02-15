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
* @group Payment and Refund
* @description Payment Validation Service
*
*/
public inherited sharing class PMT_ValidationService {
    @TestVisible
    private Boolean isEnforceAccountingDataConsistency {
        get {
            if (isEnforceAccountingDataConsistency == null) {
                isEnforceAccountingDataConsistency = UTIL_CustomSettingsFacade.getContactsSettings().Enforce_Accounting_Data_Consistency__c;
            }
            return isEnforceAccountingDataConsistency;
        }
        set;
    }

    @TestVisible
    private PMT_RefundService refundService {
        get {
            if (refundService == null) {
                refundService = new PMT_RefundService();
            }
            return refundService;
        }
        set;
    }

    private Map<Id, ErrorRecord> paymentIdToErrorRecord = new Map<Id, ErrorRecord>();
    @TestVisible
    private List<OppPayment__c> payments = new List<OppPayment__c>();
    private List<OppPayment__c> oldPayments = new List<OppPayment__c>();
    private TDTM_Runnable.Action currentAction;


    public PMT_ValidationService(){}
    /**
    * @description Constructor for the PMT_ValidationService class for Update context
    * @param payments New payments that will be validated
    * @param oldPayments old payments which are available in the database, the size and Id should match payments
    * @param triggerAction current trigger action
    */
    public PMT_ValidationService(List<OppPayment__c> payments, List<OppPayment__c> oldPayments, TDTM_Runnable.Action triggerAction) {
        this.payments = payments;
        this.oldPayments = oldPayments;
        this.currentAction = triggerAction;
    }

    public PMT_ValidationService validate() {
        List<ErrorRecord> errorRecords = new List<ErrorRecord>();
        Boolean isNew = oldPayments == null || oldPayments.isEmpty();

        refundService.withOriginalPaymentIds(UTIL_SObject.extractId(payments, OppPayment__c.OriginalPayment__c));
        for (Integer i = 0; i < this.payments.size(); i++) {
            OppPayment__c payment = payments[i];
            OppPayment__c oldPayment = isNew ? null : oldPayments[i];

            if (this.currentAction == TDTM_Runnable.Action.AfterInsert || this.currentAction == TDTM_Runnable.Action.AfterUpdate) {
                validateAccountDataConsistency(payment);
            }

            if (this.currentAction == TDTM_Runnable.Action.BeforeInsert || this.currentAction == TDTM_Runnable.Action.BeforeUpdate) {
                validateRefund(payment);
            }

        }

        return this;
    }

    public List<ErrorRecord> getErrors() {
        return paymentIdToErrorRecord.values();
    }

    private void validateAccountDataConsistency(OppPayment__c payment) {    
        if (this.isEnforceAccountingDataConsistency) {
            enforceAccountingDataConsistency(payment);
        }

        if (payment.Paid__c && payment.Written_Off__c) {
            addError(payment, System.Label.pmtWriteOffPaidPayment);
        }
    }

    /*******************************************************************************************************
    * @description If the custom setting to enforce account rules is enabled, it will validate that paid payments
    * have a payment date and unpaid payments have a scheduled date.
    * @param payment the Payment from trigger new.
    ********************************************************************************************************/
    private void enforceAccountingDataConsistency(OppPayment__c payment) {
        if ((payment.Paid__c || payment.Written_Off__c) && payment.Payment_Date__c == null) {

            if (payment.Paid__c) {
                addError(payment, System.Label.pmtPaidPaymentDateRequired);

            } else {
                addError(payment, System.Label.pmtWrittenOffPaymentDateRequired);
            }
        } else if (!payment.Paid__c && !payment.Written_Off__c && payment.Scheduled_Date__c == null) {
            addError(payment, System.Label.pmtUnpaidPaymentScheduledDateRequired);
        }
    }

    private void validateRefund(OppPayment__c payment) {
        if (payment.DebitType__c == PMT_RefundService.FULL_REFUND
            || payment.DebitType__c == PMT_RefundService.PARTIAL_REFUND) {
            PMT_RefundService.RefundInfo refundInfo = refundService.getRefundInfoFor(payment.OriginalPayment__c);
            validateRefund(payment, refundInfo);
        }
    }

    public PMT_ValidationService validateRefund(OppPayment__c refund, PMT_RefundService.RefundInfo refundInfo) {
        if (refund.OriginalPayment__c == null || refundInfo == null || refundInfo.originalPayment == null) {
            addError(refund, System.Label.pmtOriginalPaymentNotFound);
            return this;
        }

        if (!refundInfo.originalPayment.Paid__c) {
            addError(refund, System.Label.pmtOriginalPaymentNotPaid);
        }

        if (refundInfo.originalPayment.DebitType__c == PMT_RefundService.FULL_REFUND
            || refundInfo.originalPayment.DebitType__c == PMT_RefundService.PARTIAL_REFUND
            || refundInfo.remainingBalance <= 0) {
            addError(refund, System.Label.pmtPaymentNotRefundable);
            return this;
        }

        Decimal remainingBalance = refundInfo.getNewRemiaingBalanceWith(refund);
        if (remainingBalance < 0) {
            addError(refund, System.Label.pmtRefundAmountInvalid);
            return this;
        }

        refundInfo.updateRemainingBalance(refund);
        return this;
    }

    private void addError(OppPayment__c payment, String errorMessage) {
        ErrorRecord errorRecord = paymentIdToErrorRecord.get(payment.Id);
        if (errorRecord == null) {
            errorRecord = new ErrorRecord(payment);
            paymentIdToErrorRecord.put(payment.Id, errorRecord);
        }

        errorRecord.addError(errorMessage);
    }
}
