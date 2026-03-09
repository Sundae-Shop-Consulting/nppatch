public with sharing class BDI_ImportWizardController {

    private static final Integer INSERT_CHUNK_SIZE = 200;

    private static final Map<String, String> CATEGORY_LABELS = new Map<String, String>{
        'Contact1' => 'Primary Contact',
        'Contact2' => 'Secondary Contact',
        'Account1' => 'Primary Account',
        'Account2' => 'Secondary Account',
        'Donation' => 'Donation',
        'Payment' => 'Payment',
        'Home' => 'Home Address',
        'Recurring_Donation' => 'Recurring Donation',
        'GAU_Allocation_1' => 'GAU Allocation 1',
        'GAU_Allocation_2' => 'GAU Allocation 2',
        'Opportunity_Contact_Role_1' => 'Opportunity Contact Role 1',
        'Opportunity_Contact_Role_2' => 'Opportunity Contact Role 2',
        'Campaign' => 'Campaign',
        'Other' => 'Other'
    };

    private static final Set<String> SYSTEM_FIELDS = new Set<String>{
        'Status__c', 'ApexJobId__c', 'ImportedDate__c', 'FailureInformation__c',
        'NPPatch_Data_Import_Batch__c', 'Additional_Object_JSON__c',
        'DataImport_ID__c', 'Imported_Record_Status__c'
    };

    private static final Set<String> STATUS_FIELD_SUFFIXES = new Set<String>{
        'ImportStatus__c', 'Imported__c', 'Import_Status__c'
    };

    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getFieldCategories() {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        Map<String, List<Map<String, String>>> categories = new Map<String, List<Map<String, String>>>();
        for (String cat : CATEGORY_LABELS.values()) {
            categories.put(cat, new List<Map<String, String>>());
        }

        Schema.DescribeSObjectResult describe = DataImport__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fd = fieldMap.get(fieldName).getDescribe();
            String apiName = fd.getName();

            if (!apiName.endsWith('__c') || !fd.isCreateable()) {
                continue;
            }
            if (SYSTEM_FIELDS.contains(apiName)) {
                continue;
            }
            if (isStatusField(apiName)) {
                continue;
            }

            String category = categorizeField(apiName);
            String categoryLabel = CATEGORY_LABELS.containsKey(category)
                ? CATEGORY_LABELS.get(category) : CATEGORY_LABELS.get('Other');

            categories.get(categoryLabel).add(new Map<String, String>{
                'value' => apiName,
                'label' => fd.getLabel(),
                'type' => fd.getType().name()
            });
        }

        // Remove empty categories
        List<String> emptyKeys = new List<String>();
        for (String key : categories.keySet()) {
            if (categories.get(key).isEmpty()) {
                emptyKeys.add(key);
            }
        }
        for (String key : emptyKeys) {
            categories.remove(key);
        }

        return categories;
    }

    @AuraEnabled
    public static Map<String, Object> getDefaultBatchSettings() {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        return new Map<String, Object>{
            'contactMatchingRule' => diSettings.Contact_Matching_Rule__c,
            'donationMatchingBehavior' => diSettings.Donation_Matching_Behavior__c,
            'donationMatchingRule' => diSettings.Donation_Matching_Rule__c,
            'donationDateRange' => diSettings.Donation_Date_Range__c,
            'batchProcessSize' => diSettings.Batch_Size__c,
            'runRollups' => diSettings.Run_Opportunity_Rollups_while_Processing__c,
            'contactCustomUniqueId' => '',
            'accountCustomUniqueId' => '',
            'donationMatchingClass' => '',
            'postProcessClass' => '',
            'processUsingScheduledJob' => false
        };
    }

    @AuraEnabled
    public static Map<String, Object> createBatchWithRecords(
        String batchName,
        String batchDescription,
        String rowsJson,
        String fieldMapJson,
        String batchConfigJson
    ) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        Map<String, String> fieldMapping = (Map<String, String>) JSON.deserialize(
            fieldMapJson, Map<String, String>.class
        );
        List<Map<String, String>> rows = (List<Map<String, String>>) JSON.deserialize(
            rowsJson, List<Map<String, String>>.class
        );
        Map<String, Object> batchConfig = (Map<String, Object>) JSON.deserializeUntyped(
            batchConfigJson
        );

        // Create batch record with config
        DataImportBatch__c batch = new DataImportBatch__c(
            Name = batchName,
            Batch_Description__c = batchDescription
        );

        batch.Contact_Matching_Rule__c = (String) batchConfig.get('contactMatchingRule');
        batch.Donation_Matching_Behavior__c = (String) batchConfig.get('donationMatchingBehavior');
        batch.Donation_Matching_Rule__c = (String) batchConfig.get('donationMatchingRule');
        batch.Donation_Date_Range__c = batchConfig.get('donationDateRange') != null
            ? ((Decimal) batchConfig.get('donationDateRange')).intValue() : null;
        batch.Batch_Process_Size__c = batchConfig.get('batchProcessSize') != null
            ? ((Decimal) batchConfig.get('batchProcessSize')).intValue() : null;
        batch.Run_Opportunity_Rollups_while_Processing__c =
            batchConfig.get('runRollups') == true;
        batch.Contact_Custom_Unique_ID__c = (String) batchConfig.get('contactCustomUniqueId');
        batch.Account_Custom_Unique_ID__c = (String) batchConfig.get('accountCustomUniqueId');
        batch.Donation_Matching_Implementing_Class__c = (String) batchConfig.get('donationMatchingClass');
        batch.Post_Process_Implementing_Class__c = (String) batchConfig.get('postProcessClass');
        batch.Process_Using_Scheduled_Job__c =
            batchConfig.get('processUsingScheduledJob') == true;

        insert batch;

        // Build DataImport__c records in chunks
        Integer totalInserted = 0;
        Integer totalFailed = 0;
        List<String> errors = new List<String>();
        List<DataImport__c> chunk = new List<DataImport__c>();

        for (Integer i = 0; i < rows.size(); i++) {
            Map<String, String> row = rows.get(i);
            DataImport__c di = new DataImport__c(
                NPPatch_Data_Import_Batch__c = batch.Id
            );

            for (String csvHeader : fieldMapping.keySet()) {
                String targetField = fieldMapping.get(csvHeader);
                String cellValue = row.get(csvHeader);
                if (String.isNotBlank(cellValue) && String.isNotBlank(targetField)) {
                    try {
                        di.put(targetField, coerceValue(targetField, cellValue));
                    } catch (Exception ex) {
                        // Skip field on coercion error — will be caught by DML
                    }
                }
            }

            chunk.add(di);

            if (chunk.size() == INSERT_CHUNK_SIZE || i == rows.size() - 1) {
                List<Database.SaveResult> results = Database.insert(chunk, false);
                for (Integer j = 0; j < results.size(); j++) {
                    if (results[j].isSuccess()) {
                        totalInserted++;
                    } else {
                        totalFailed++;
                        if (errors.size() < 10) {
                            errors.add('Row ' + (i - chunk.size() + j + 2) + ': ' +
                                results[j].getErrors()[0].getMessage());
                        }
                    }
                }
                chunk.clear();
            }
        }

        return new Map<String, Object>{
            'batchId' => batch.Id,
            'totalInserted' => totalInserted,
            'totalFailed' => totalFailed,
            'errors' => errors
        };
    }

    @AuraEnabled
    public static Id processBatch(Id batchId, Boolean isDryRun) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        List<BDI_DataImport_API.ProcessDataImportBatchesResult> results =
            BDI_DataImport_API.processDataImportBatches(
                new List<Id>{ batchId }, isDryRun
            );
        Id jobId = results != null && !results.isEmpty() ? results[0].apexJobId : null;

        // Store the job ID on the batch so we can poll status
        if (jobId != null) {
            update new DataImportBatch__c(
                Id = batchId,
                Latest_Apex_Job_Id__c = jobId
            );
        }

        return jobId;
    }

    @AuraEnabled
    public static Map<String, Object> getProcessingStatus(Id batchId, Id jobId) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        DataImportBatch__c batch = [
            SELECT Id, Name, Batch_Status__c, Records_Successfully_Processed__c,
                Records_Failed__c, Latest_Apex_Job_Id__c, Last_Processed_On__c
            FROM DataImportBatch__c
            WHERE Id = :batchId
            LIMIT 1
        ];

        Map<String, Object> result = new Map<String, Object>{
            'batchStatus' => batch.Batch_Status__c,
            'recordsProcessed' => batch.Records_Successfully_Processed__c,
            'recordsFailed' => batch.Records_Failed__c,
            'lastProcessedOn' => batch.Last_Processed_On__c
        };

        // Get job progress if actively processing
        Id activeJobId = batch.Latest_Apex_Job_Id__c != null
            ? batch.Latest_Apex_Job_Id__c : jobId;
        if (activeJobId != null) {
            List<AsyncApexJob> jobs = [
                SELECT Id, Status, JobItemsProcessed, TotalJobItems,
                    NumberOfErrors, ExtendedStatus
                FROM AsyncApexJob
                WHERE Id = :activeJobId
                LIMIT 1
            ];
            if (!jobs.isEmpty()) {
                AsyncApexJob job = jobs[0];
                result.put('jobStatus', job.Status);
                result.put('jobItemsProcessed', job.JobItemsProcessed);
                result.put('totalJobItems', job.TotalJobItems);
                result.put('jobErrors', job.NumberOfErrors);
            }
        }

        // Count records by status
        List<AggregateResult> statusCounts = [
            SELECT Status__c, COUNT(Id) cnt
            FROM DataImport__c
            WHERE NPPatch_Data_Import_Batch__c = :batchId
            GROUP BY Status__c
        ];
        Map<String, Integer> counts = new Map<String, Integer>();
        for (AggregateResult ar : statusCounts) {
            counts.put((String) ar.get('Status__c'), (Integer) ar.get('cnt'));
        }
        result.put('statusCounts', counts);

        return result;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getBatches(String statusFilter) {
        STG_Panel.throwAuraExceptionIfRunningUserNotAdmin();

        String query = 'SELECT Id, Name, Batch_Description__c, Batch_Status__c, '
            + 'Records_Successfully_Processed__c, Records_Failed__c, '
            + 'Last_Processed_On__c, CreatedDate '
            + 'FROM DataImportBatch__c '
            + 'WHERE GiftBatch__c != true ';

        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            query += 'AND Batch_Status__c = :statusFilter ';
        }
        query += 'ORDER BY CreatedDate DESC LIMIT 50';

        List<DataImportBatch__c> batches = Database.query(query);

        // Get record counts per batch
        Set<Id> batchIds = new Set<Id>();
        for (DataImportBatch__c b : batches) {
            batchIds.add(b.Id);
        }

        Map<Id, Integer> totalCounts = new Map<Id, Integer>();
        Map<Id, Integer> pendingCounts = new Map<Id, Integer>();
        if (!batchIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT NPPatch_Data_Import_Batch__c batchId, COUNT(Id) cnt
                FROM DataImport__c
                WHERE NPPatch_Data_Import_Batch__c IN :batchIds
                GROUP BY NPPatch_Data_Import_Batch__c
            ]) {
                totalCounts.put((Id) ar.get('batchId'), (Integer) ar.get('cnt'));
            }
            for (AggregateResult ar : [
                SELECT NPPatch_Data_Import_Batch__c batchId, COUNT(Id) cnt
                FROM DataImport__c
                WHERE NPPatch_Data_Import_Batch__c IN :batchIds
                    AND Status__c NOT IN ('Imported', 'Failed')
                GROUP BY NPPatch_Data_Import_Batch__c
            ]) {
                pendingCounts.put((Id) ar.get('batchId'), (Integer) ar.get('cnt'));
            }
        }

        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (DataImportBatch__c b : batches) {
            results.add(new Map<String, Object>{
                'Id' => b.Id,
                'Name' => b.Name,
                'Description' => b.Batch_Description__c,
                'Status' => b.Batch_Status__c,
                'RecordsProcessed' => b.Records_Successfully_Processed__c,
                'RecordsFailed' => b.Records_Failed__c,
                'TotalRecords' => totalCounts.containsKey(b.Id) ? totalCounts.get(b.Id) : 0,
                'PendingRecords' => pendingCounts.containsKey(b.Id) ? pendingCounts.get(b.Id) : 0,
                'LastProcessedOn' => b.Last_Processed_On__c,
                'CreatedDate' => b.CreatedDate
            });
        }
        return results;
    }

    // ---- Private helpers ----

    private static Map<String, Schema.SObjectField> diFieldMap {
        get {
            if (diFieldMap == null) {
                diFieldMap = DataImport__c.SObjectType.getDescribe().fields.getMap();
            }
            return diFieldMap;
        }
        set;
    }

    private static Object coerceValue(String fieldApiName, String cellValue) {
        Schema.SObjectField field = diFieldMap.get(fieldApiName.toLowerCase());
        if (field == null) return cellValue;

        Schema.DisplayType fieldType = field.getDescribe().getType();

        switch on fieldType {
            when CURRENCY, DOUBLE, PERCENT {
                return Decimal.valueOf(cellValue.replaceAll('[^\\d.\\-]', ''));
            }
            when INTEGER {
                return Integer.valueOf(cellValue.replaceAll('[^\\d\\-]', ''));
            }
            when DATE {
                // Try ISO format first, then common US format
                try {
                    return Date.valueOf(cellValue);
                } catch (Exception e) {
                    // Try MM/DD/YYYY
                    List<String> parts = cellValue.split('/');
                    if (parts.size() == 3) {
                        return Date.newInstance(
                            Integer.valueOf(parts[2]),
                            Integer.valueOf(parts[0]),
                            Integer.valueOf(parts[1])
                        );
                    }
                    throw e;
                }
            }
            when DATETIME {
                return Datetime.valueOf(cellValue);
            }
            when BOOLEAN {
                return cellValue.equalsIgnoreCase('true')
                    || cellValue.equalsIgnoreCase('yes')
                    || cellValue == '1';
            }
            when else {
                return cellValue;
            }
        }
    }

    private static Boolean isStatusField(String apiName) {
        for (String suffix : STATUS_FIELD_SUFFIXES) {
            if (apiName.endsWith(suffix)) {
                return true;
            }
        }
        return false;
    }

    private static String categorizeField(String apiName) {
        // Check multi-word prefixes first (longest match)
        List<String> multiWordPrefixes = new List<String>{
            'Recurring_Donation', 'GAU_Allocation_1', 'GAU_Allocation_2',
            'Opportunity_Contact_Role_1', 'Opportunity_Contact_Role_2',
            'Campaign_Member'
        };
        for (String prefix : multiWordPrefixes) {
            if (apiName.startsWith(prefix + '_')) {
                if (prefix == 'Campaign_Member') return 'Campaign';
                return prefix;
            }
        }

        // Single-word prefixes
        String firstPart = apiName.substringBefore('_');
        if (CATEGORY_LABELS.containsKey(firstPart)) {
            return firstPart;
        }

        // Specific field overrides
        if (apiName.startsWith('Household_') || apiName.startsWith('Home_')) {
            return 'Home';
        }

        return 'Other';
    }
}
