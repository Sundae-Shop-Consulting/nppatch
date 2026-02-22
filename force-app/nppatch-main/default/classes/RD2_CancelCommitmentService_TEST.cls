/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit Tests for the Cancel Commitment Service.
* Tests that required full Elevate integration (deleted classes) have been removed.
*/
@IsTest
public with sharing class RD2_CancelCommitmentService_TEST {
    public static final String COMMITMENT_ID = '11a1c101-bcde-001-111f-g1dh00i0jk111';
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        UTIL_TestPermissions.assignAdminPermissionSet();

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /***
    * @description Should prepare record for retry when Elevate Cancel not verified.
    */
    @isTest
    private static void shouldUpdateRecordForRetryWhenElevateCancelNotVerified() {
        String originalReason = 'Original Reason';
        String firstError = 'Conflict';

        RD2_CancelCommitmentService.RecordWrapper wrapper = prepRDRecordAndWrapper(originalReason, firstError);
        wrapper.isConfirmationRequired = true;

        UTIL_Http.Response response = buildCommitmentResponse('ACTIVE');

        RD2_CancelCommitmentService service = new RD2_CancelCommitmentService();
        ERR_LogService.Logger logger = buildLogger();
        service.handleResponse(wrapper, response, logger);

        System.assertEquals(false, wrapper.isDone,
            'Record should be marked as ready for retry when Elevate Cancel not verified.');
        System.assertEquals(false, wrapper.isConfirmationRequired,
            'Record should be marked as confirmation not required if Elevate status not INACTIVE.');
    }

    /***
    * @description Should recognize Elevate status is verified when Elevate status is inactive
    */
    @isTest
    private static void shouldUpdateRecordCompleteWhenElevateCancelVerified() {
        String originalReason = 'Original Reason';
        String firstError = 'Conflict';

        RD2_CancelCommitmentService.RecordWrapper wrapper = prepRDRecordAndWrapper(originalReason, firstError);

        UTIL_Http.Response response = buildCommitmentResponse('INACTIVE');

        RD2_CancelCommitmentService service = new RD2_CancelCommitmentService();
        ERR_LogService.Logger logger = buildLogger();
        service.handleResponse(wrapper, response, logger);

        System.assertEquals(true, wrapper.isDone,
            'Record should be marked complete when Elevate Cancel is verified.');
    }

    /**
    * @description Verifies that callout will be retried when Response to cancel times out
    */
    @isTest
    private static void shouldRetryWhenResponseIsTimeout() {
        String originalReason = 'Original Reason';
        String firstError = null;

        RD2_CancelCommitmentService.RecordWrapper wrapper = prepRDRecordAndWrapper(originalReason, firstError);

        UTIL_Http.Response response = buildTimeoutResponse();

        RD2_CancelCommitmentService service = new RD2_CancelCommitmentService();
        ERR_LogService.Logger logger = buildLogger();
        service.handleResponse(wrapper, response, logger);

        System.assertEquals(false, wrapper.isDone,
            'Record should be marked as ready for retry when Response is timeout.');
        System.assertEquals(true, wrapper.isConfirmationRequired,
            'Record should be marked as requiring confirmation when Response is timeout.');
    }

    /**
    * @description Verifies that record marked complete when Response is not found.
    */
    @isTest
    private static void shouldNotRetryWhenResponseIsNotFound() {
        String originalReason = 'Original Reason';
        String firstError = null;

        RD2_CancelCommitmentService.RecordWrapper wrapper = prepRDRecordAndWrapper(originalReason, firstError);

        UTIL_Http.Response response = buildNotFoundResponse();

        RD2_CancelCommitmentService service = new RD2_CancelCommitmentService();
        ERR_LogService.Logger logger = buildLogger();
        service.handleResponse(wrapper, response, logger);

        System.assertEquals(true, wrapper.isDone,
            'Record should be marked complete when Response is not found.');
        System.assertEquals(UTIL_Http_TEST.MESSAGE_NOT_FOUND, wrapper.firstErrorMessage,
            'First error message should equal ' + UTIL_Http_TEST.MESSAGE_NOT_FOUND);
    }

    /**
    * @description Verifies that callout will be retried when the Response is conflict.
    */
    @isTest
    private static void shouldRetryWhenResponseIsConflict() {
        String originalReason = 'Original Reason';
        String firstError = null;

        RD2_CancelCommitmentService.RecordWrapper wrapper = prepRDRecordAndWrapper(originalReason, firstError);

        UTIL_Http.Response response = buildConflictResponse();

        RD2_CancelCommitmentService service = new RD2_CancelCommitmentService();
        ERR_LogService.Logger logger = buildLogger();
        service.handleResponse(wrapper, response, logger);

        System.assertEquals(false, wrapper.isDone,
            'Record should be marked as ready for retry when Response is conflict.');
        System.assertEquals(true, wrapper.isConfirmationRequired,
            'Record should be marked as requiring confirmation when Response is conflict.');
        System.assertEquals(UTIL_Http_TEST.MESSAGE_DATA_CONFLICT, wrapper.firstErrorMessage,
            'First error message should equal ' + UTIL_Http_TEST.MESSAGE_DATA_CONFLICT);
    }


    // Helpers
    ///////////////////

    /****
    * @description Prepares environment and returns RecordWrapper
    * @return RD2_CancelCommitmentService.RecordWrapper
    */
    private static RD2_CancelCommitmentService.RecordWrapper prepRDRecordAndWrapper(
        String originalReason,
        String firstError
    ) {

        Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
            .withAmount(100)
            .withInstallmentFrequency(1)
            .build();

        rd.ClosedReason__c = originalReason;
        rd.Status__c = RD2_Constants.STATUS_CLOSED;

        RD2_CancelCommitmentService.RecordWrapper wrapper = buildRecordWrapper(rd);
        wrapper.firstErrorMessage = firstError;

        return wrapper;
    }

    /****
    * @description Builds a RecordWrapper from a Recurring Donation record.
    * @return RD2_CancelCommitmentService.RecordWrapper
    */
    public static RD2_CancelCommitmentService.RecordWrapper buildRecordWrapper(Recurring_Donation__c rd) {
        return new RD2_CancelCommitmentService.RecordWrapper(rd);
    }

    /****
    * @description Builds a cancel response for a time out.
    * @return UTIL_Http.Response
    */
    public static UTIL_Http.Response buildTimeoutResponse() {
        UTIL_Http.Response response = new UTIL_Http.Response();
        String timeout = 'Timed out';

        response.statusCode = UTIL_Http.STATUS_CODE_REQUEST_TIMEOUT;
        response.status = UTIL_Http.STATUS_TIMED_OUT;
        response.body = '{"errors":[{'
            + '"message":"' + timeout
            + '","localizedPaymentsMessage":"' + timeout
            + '","detailedMessage":"' + timeout
            + '"}]}';

        return response;
    }

    /****
    * @description Builds a cancel response for Elevate commitment not found.
    * @return UTIL_Http.Response
    */
    public static UTIL_Http.Response buildNotFoundResponse() {
        UTIL_Http.Response response = new UTIL_Http.Response();

        response.statusCode = UTIL_Http.STATUS_CODE_NOT_FOUND;
        response.status = UTIL_Http.STATUS_NOT_FOUND;
        response.body = '{"errors":[{'
            + '"message":"' + UTIL_Http_TEST.MESSAGE_NOT_FOUND
            + '","localizedPaymentsMessage":"' + UTIL_Http_TEST.MESSAGE_NOT_FOUND
            + '","detailedMessage":"' + UTIL_Http_TEST.MESSAGE_NOT_FOUND
            + '"}]}';

        return response;
    }

    /****
    * @description Builds a cancel response for Elevate commitment conflict.
    * @return UTIL_Http.Response
    */
    public static UTIL_Http.Response buildConflictResponse() {
        UTIL_Http.Response response = new UTIL_Http.Response();

        response.statusCode = UTIL_Http.STATUS_CODE_CONFLICT;
        response.status = UTIL_Http.STATUS_CONFLICT;
        response.body = '{"errors":[{'
            + '"message":"' + UTIL_Http_TEST.MESSAGE_DATA_CONFLICT
            + '","localizedPaymentsMessage":"' + UTIL_Http_TEST.MESSAGE_DATA_CONFLICT
            + '","detailedMessage":"' + UTIL_Http_TEST.MESSAGE_DATA_CONFLICT
            + '"}]}';

        return response;
    }

    /****
    * @description Builds a cancel commitment response for a COMMIT GET.
    * @return UTIL_Http.Response
    */
    public static UTIL_Http.Response buildCommitmentResponse(String status) {
        UTIL_Http.Response response = new UTIL_Http.Response();

        response.statusCode = 200;
        response.body = '{"commitment":{"status":"' + status + '"}}';

        return response;
    }

    /****
    * @description Builds a cancel commitment response body
    * returned when the commitment is successfully cancelled
    * @return String
    */
    public static String buildCommitmentCanceledResponseBody() {
        return '{"id":"' + COMMITMENT_ID
            + '","status":"INACTIVE","statusReason":"DONOR_CANCELED"'
            + '"}}';
    }

    /****
    * @description Builds a logger with expected context and SObject type
    * @return ERR_LogService.Logger
    */
    private static ERR_LogService.Logger buildLogger() {
        return new ERR_LogService.Logger(
            ERR_Handler_API.Context.Elevate,
            Recurring_Donation__c.SObjectType
        );
    }

}
