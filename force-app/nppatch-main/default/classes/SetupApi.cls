/**
 * @description Global API for org setup operations callable from anonymous apex
 * (e.g., CumulusCI tasks). Wraps internal setup logic that lives in public classes.
 */
global without sharing class SetupApi {

    /**
     * @description Resets TDTM trigger handler records to their defaults. Inserts
     * missing handlers, updates changed handlers (unless user-managed), and deletes
     * handlers for removed classes.
     */
    global static void resetTriggerHandlers() {
        TDTM_DefaultConfig.insertDefaults(null);
    }

    /**
     * @description Aborts deprecated scheduled jobs and reschedules all default
     * NPPatch scheduled jobs.
     */
    global static void rescheduleDefaultJobs() {
        UTIL_MasterSchedulableHelper.abortOldScheduledJobs();
        UTIL_MasterSchedulableHelper.setScheduledJobs();
    }
}
