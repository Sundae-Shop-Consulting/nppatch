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
* @description Payment Validation Service Test
*
*/
@IsTest
public with sharing class PMT_ValidationService_TEST {
    @IsTest
    private static void verifyNoErrorWillBeAddedOnCorrectFullRefund() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 10,
            Paid__c = true
        );

        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'Expected no error to be returned.');
    }

    @IsTest
    private static void verifyNoErrorWillBeAddedOnCorrectPartialRefund() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 100,
            Paid__c = true
        );

        List<OppPayment__c> refunds = new List<OppPayment__c> {
            new OppPayment__c(
                Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
                Payment_Amount__c = -40,
                DebitType__c = PMT_RefundService.PARTIAL_REFUND,
                OriginalPayment__c = originalPayment.Id
            )
        };

        originalPayment = addRefundRelatedList(originalPayment, refunds);

        OppPayment__c newRefund = new OppPayment__c(
            Payment_Amount__c = -50,
            DebitType__c = PMT_RefundService.PARTIAL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );
        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{newRefund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'Expected no error to be returned.');
    }

    @IsTest
    private static void verifyRefundsNeedToHaveAnOriginalPayment() {
        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = null
            );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );
        validationService.isEnforceAccountingDataConsistency = false;    
    
        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'There should be one error create when the refund does not have an original payment');
        System.assertEquals(System.Label.pmtOriginalPaymentNotFound, errorRecords[0].getFirstError(),
            'Original Payment not found error should be returned');
    }

    @IsTest
    private static void verifyRefundOriginalPaymentHasToBePaid() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 10,
            Paid__c = false
        );

        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );
        validationService.isEnforceAccountingDataConsistency = false;

        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtOriginalPaymentNotPaid, errorRecords[0].getFirstError(),
            'Original Payment should be paid error should be returned');
    }

    @IsTest
    private static void verifyRefundPaymentCannotBeRefunded() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            Paid__c = true
        );

        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );
        validationService.isEnforceAccountingDataConsistency = false;

        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, errorRecords[0].getFirstError(),
            'Original Payment cannot be a refund payment');
    }

    @IsTest
    private static void verifyCanNotRefundMoreThanRemainingBalance() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 10,
            Paid__c = true
        );

        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -11,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtRefundAmountInvalid, errorRecords[0].getFirstError(),
            'Refund cannot be greater than the original payment amount');
    }

    @IsTest
    private static void verifyRefundCannotBeMadeOnFullyRefundPayment() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 10,
            Paid__c = true
        );

        OppPayment__c refund = new OppPayment__c(
            Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );
       
        originalPayment = addRefundRelatedList(originalPayment, new List<SObject>{refund});

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, errorRecords[0].getFirstError(),
            'Refund cannot be processed when the payment is fully refunded');
    }

    @IsTest
    private static void verifyPartialRefundCannotExceedRemainingBalance() {
        OppPayment__c originalPayment = new OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
            Payment_Amount__c = 100,
            Paid__c = true
        );

        List<OppPayment__c> refunds = new List<OppPayment__c> {
            new OppPayment__c(
                Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
                Payment_Amount__c = -40,
                DebitType__c = PMT_RefundService.PARTIAL_REFUND,
                OriginalPayment__c = originalPayment.Id
            ),
            new OppPayment__c(
                Id = UTIL_UnitTestData_TEST.mockId(OppPayment__c.SObjectType),
                Payment_Amount__c = -40,
                DebitType__c = PMT_RefundService.PARTIAL_REFUND,
                OriginalPayment__c = originalPayment.Id
            )
        };

        originalPayment = addRefundRelatedList(originalPayment, refunds);

        OppPayment__c newRefund = new OppPayment__c(
            Payment_Amount__c = -21,
            DebitType__c = PMT_RefundService.PARTIAL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );
        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<OppPayment__c>{newRefund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtRefundAmountInvalid, errorRecords[0].getFirstError(),
            'Refund cannot be processed when the payment is fully refunded');
    }

    private static OppPayment__c addRefundRelatedList(OppPayment__c payment, List<SObject> records) {
        String paymentRecord = JSON.serialize(payment);
        paymentRecord = paymentRecord.left(paymentRecord.length()-1);

        String objJson = JSON.serialize(records);
        paymentRecord += ',"' + UTIL_Namespace.StrTokenNSPrefix('Refunds__r') + '":{"totalSize":' + records.size() + ',"done":true,"records":' + objJson + '}';

        paymentRecord += '}';

        return (OppPayment__c)JSON.deserialize(paymentRecord, OppPayment__c.class);
    }
}