// Initialize TDTM trigger handler records and schedule default jobs.
// Only used in unmanaged (dev_org) context — for managed orgs,
// STG_InstallScript handles this during package install.
TDTM_DefaultConfig.insertDefaults(null);
UTIL_MasterSchedulableHelper.abortOldScheduledJobs();
UTIL_MasterSchedulableHelper.setScheduledJobs();
