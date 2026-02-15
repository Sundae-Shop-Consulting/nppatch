/**
 * Created by voduyemi on 8/17/22.
 */

/**
* @description Handles sending commitment create and edit requests.
* Elevate integration has been removed; public methods are stubbed as no-ops.
*/
public without sharing class RD2_CommitmentService {

    /**
    * @description Sends commitment create/update requests, and constructs a response
    */
    private UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    /**
    * Used to adjust and validate Recurring Donation data
    */
    private RD2_DataRegulationService dataService {
        get {
            if (dataService == null) {
                dataService = new RD2_DataRegulationService();
            }
            return dataService;
        }
        set;
    }

    /**
    * @description Stubbed no-op. Elevate integration has been removed.
    * @param rd Recurring Donation
    * @param oldRd oldRecurring Donation
    * @param paymentMethodToken Payment Method Token
    * @return null
    */
    public UTIL_Http.Response handleCommitment(Recurring_Donation__c rd, Recurring_Donation__c oldRd, String paymentMethodToken) {
        return null;
    }

    /**
    * @description Stubbed no-op. Elevate integration has been removed.
    */
    public UTIL_Http.Response handleCommitmentPause(RD2_ScheduleService.ElevatePauseSchedule schedule, RD2_RecurringDonation rd) {
        return null;
    }

    /**
    * @description Stubbed no-op. Elevate integration has been removed.
    */
    public UTIL_Http.Response handleRemoveCommitmentPause(RD2_RecurringDonation rd) {
        return null;
    }

    /**
    * @description Constructs Recurring Donation record from received fields specified in the JSON string,
    * updates defaults that are otherwise updated in the trigger context, and
    * validates user entered values for a new or existing RD record.
    * @param rd Modified Recurring Donation record that is not created/updated in DB yet
    * @param oldRd oldRecurring Donation
    */
    public void adjustAndValidateRD(Recurring_Donation__c rd, Recurring_Donation__c oldRd) {
        // Populate defaults otherwise applied by the DML operation and available in the trigger context
        if (String.isBlank(rd.Status__c)) {
            rd.Status__c = UTIL_Describe.getDefaultSelectOption(
                'Recurring_Donation__c', String.valueOf(Recurring_Donation__c.Status__c)
            );
        }

        List<Recurring_Donation__c> newRds = new List<Recurring_Donation__c>{rd};
        List<Recurring_Donation__c> oldRds = new List<Recurring_Donation__c>();
        if (rd.Id != null) {
            oldRds.add(oldRd);
        }

        RD2_DataRegulationService regulationService = new RD2_DataRegulationService();
        regulationService.adjust(newRds, oldRds);
        regulationService.markRDsAsElevate(newRds);

        List<ErrorRecord> errorRds = new RD2_ValidationService(newRds, oldRds)
            .validate();

        regulationService.removeElevateMarker(newRds);

        if (!errorRds.isEmpty()) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(
                errorRds[0].getFirstError()
            );
        }
    }

    /**
    * @description Determines if the commitment has been created or updated successfully
    * @param response Payments API response
    * @return Boolean
    */
    public Boolean isCommitmentSuccess(UTIL_Http.Response response) {
        return response.statusCode == UTIL_Http.STATUS_CODE_CREATED
            || response.statusCode == UTIL_Http.STATUS_CODE_OK
            || response.statusCode == UTIL_Http.STATUS_CODE_NO_CONTENT;
    }

    /**
    * @description Creates an error record for the specified record Id and error message.
    * Stubbed -- Elevate integration has been removed.
    * @param recordId A Recurring Donation or a donor (Contact/Account) Id
    * @param errorMessage Error message
    */
    public void logError(Id recordId, String errorMessage) {
        // No-op: Elevate integration removed
    }
}
