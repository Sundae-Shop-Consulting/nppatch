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
* @description Apex Controller for paymnet refund
*/
public with sharing class PMT_RefundController {
    @TestVisible
    private static PMT_RefundService refundService {
        get {
            if (refundService == null) {
                refundService = new PMT_RefundService();
            }
            return refundService;
        }
        set;
    }

    @AuraEnabled
    public static RefundView getInitialView(Id paymentId) {
        RefundView refundView = new RefundView();
        setPermissionData(refundView);

        if (!refundView.hasRequiredPermissions) {
            return refundView;
        }

        refundService.withOriginalPaymentIds(new Set<Id>{paymentId});
        PMT_RefundService.RefundInfo refundInfo = refundService.getRefundInfoFor(paymentId);

        refundView.remainingBalance = refundInfo.remainingBalance;

        if (UserInfo.isMultiCurrencyOrganization()) {
            refundView.currencyCode = (String) refundInfo.originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);

        } else {
            refundView.currencyCode = null;
        }
        return refundView;
    }

    @AuraEnabled 
    public static RefundView processRefund(Id paymentId, Decimal refundAmount) {
        RefundView refundView = new RefundView();
        setPermissionData(refundView);

        if (!refundView.hasRequiredPermissions) {
            return refundView;
        }

        refundService.withOriginalPaymentIds(new Set<Id>{paymentId});
        PMT_RefundService.RefundInfo refundInfo = refundService.getRefundInfoFor(paymentId);

        if (!isPaymentRefundable(refundInfo.originalPayment)) {
            handleError(refundView, System.Label.pmtPaymentNotRefundable);
            return refundView;
        }

        if (refundView.isSuccess != null && !refundView.isSuccess) {
            return refundView;
        }

        processNonElevateRefund(refundInfo.originalPayment, refundView, refundAmount);

        return refundView;
    }

    private static Boolean isPaymentRefundable(OppPayment__c originalPayment) {
        return String.isBlank(originalPayment.DebitType__c) && originalPayment.Payment_Amount__c > 0;
    }


    private static void setPermissionData(RefundView refundView) {
        refundView.hasRequiredPermissions = hasRequiredPermission();
    }

    private static void processNonElevateRefund(OppPayment__c originalPayment, RefundView refundView, Decimal refundAmount) {
        refundService.withOriginalPayments(new List<OppPayment__c>{originalPayment});
        OppPayment__c refundRecord = refundService.buildRefundRecord(originalPayment, refundAmount);
        List<ErrorRecord> errorRecords = new PMT_ValidationService()
            .validateRefund(refundRecord, refundService.getRefundInfoFor(refundRecord.OriginalPayment__c))
            .getErrors();
        if (errorRecords != null && !errorRecords.isEmpty()) {
            handleError(refundView, errorRecords[0].getFirstError());
            return;
        }

        refundService.insertRefunds();

        List<ErrorRecord> errors = refundService.getErrors();
        if (errors == null || errors.isEmpty()) {
            refundView.redirectToPaymentId = refundService.getRefundRecords()[0].Id;
            refundView.isSuccess = true;
        } else {
            handleError(refundView, errors[0].getFirstError());
        }
    }

    private static void handleError(RefundView refundView, String errorMessage) {
        refundView.isSuccess = false;
        refundView.errorMessage = errorMessage;
    }

    private static Boolean hasRequiredPermission() {
        return UTIL_Permissions.canCreate('oppPayment__c', false) &&
            UTIL_Permissions.canUpdate('oppPayment__c', false) &&
            UTIL_Permissions.canUpdate('Opportunity', false) &&
            UTIL_Permissions.canCreate('oppPayment__c', 'Payment_Amount__c', false) && 
            UTIL_Permissions.canCreate('oppPayment__c', String.valueOf(oppPayment__c.DebitType__c), false) && 
            UTIL_Permissions.canCreate('oppPayment__c', String.valueOf(oppPayment__c.OriginalPayment__c), false) &&
            UTIL_Permissions.canCreate('oppPayment__c', 'Paid__c', false) &&
            UTIL_Permissions.canCreate('oppPayment__c', 'Payment_Date__c', false);
    }

    public inherited sharing class RefundView {
        @AuraEnabled public Boolean hasRequiredPermissions;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Id redirectToPaymentId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Decimal remainingBalance;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Date paymentDate;
    }
}
