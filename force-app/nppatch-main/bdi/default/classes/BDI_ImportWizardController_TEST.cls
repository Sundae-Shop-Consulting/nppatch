@isTest
private class BDI_ImportWizardController_TEST {

    @isTest
    static void shouldGetDefaultBatchSettings() {
        Test.startTest();
        Map<String, Object> settings =
            BDI_ImportWizardController.getDefaultBatchSettings();
        Test.stopTest();

        System.assert(settings.containsKey('contactMatchingRule'),
            'Should contain contactMatchingRule');
        System.assert(settings.containsKey('donationMatchingBehavior'),
            'Should contain donationMatchingBehavior');
        System.assert(settings.containsKey('batchProcessSize'),
            'Should contain batchProcessSize');
    }

    @isTest
    static void shouldReturnFieldCategories() {
        Test.startTest();
        Map<String, List<Map<String, String>>> categories =
            BDI_ImportWizardController.getFieldCategories();
        Test.stopTest();

        System.assert(!categories.isEmpty(), 'Should return field categories');
        System.assert(categories.containsKey('Primary Contact'),
            'Should contain Primary Contact category');
        System.assert(categories.containsKey('Donation'),
            'Should contain Donation category');

        // Verify fields have required keys
        List<Map<String, String>> contactFields = categories.get('Primary Contact');
        System.assert(!contactFields.isEmpty(), 'Primary Contact should have fields');
        Map<String, String> firstField = contactFields[0];
        System.assert(firstField.containsKey('value'), 'Field should have value key');
        System.assert(firstField.containsKey('label'), 'Field should have label key');
        System.assert(firstField.containsKey('type'), 'Field should have type key');
    }

    @isTest
    static void shouldExcludeStatusFields() {
        Test.startTest();
        Map<String, List<Map<String, String>>> categories =
            BDI_ImportWizardController.getFieldCategories();
        Test.stopTest();

        // Flatten all field values
        Set<String> allFieldNames = new Set<String>();
        for (List<Map<String, String>> fields : categories.values()) {
            for (Map<String, String> f : fields) {
                allFieldNames.add(f.get('value'));
            }
        }

        System.assert(!allFieldNames.contains('Contact1ImportStatus__c'),
            'Should exclude import status fields');
        System.assert(!allFieldNames.contains('Status__c'),
            'Should exclude system Status field');
        System.assert(!allFieldNames.contains('ApexJobId__c'),
            'Should exclude system ApexJobId field');
    }

    @isTest
    static void shouldCreateBatchWithRecords() {
        List<Map<String, String>> rows = new List<Map<String, String>>();
        rows.add(new Map<String, String>{
            'First Name' => 'Test',
            'Last Name' => 'Contact',
            'Amount' => '100'
        });
        rows.add(new Map<String, String>{
            'First Name' => 'Another',
            'Last Name' => 'Person',
            'Amount' => '200'
        });

        Map<String, String> fieldMap = new Map<String, String>{
            'First Name' => 'Contact1_Firstname__c',
            'Last Name' => 'Contact1_Lastname__c',
            'Amount' => 'Donation_Amount__c'
        };

        Map<String, Object> batchConfig = new Map<String, Object>{
            'contactMatchingRule' => '',
            'donationMatchingBehavior' => 'Best Match or Create',
            'donationMatchingRule' => '',
            'donationDateRange' => 0,
            'batchProcessSize' => 200,
            'runRollups' => false,
            'contactCustomUniqueId' => '',
            'accountCustomUniqueId' => '',
            'donationMatchingClass' => '',
            'postProcessClass' => '',
            'processUsingScheduledJob' => false
        };

        Test.startTest();
        Map<String, Object> result = BDI_ImportWizardController.createBatchWithRecords(
            'Test Batch',
            'Test description',
            JSON.serialize(rows),
            JSON.serialize(fieldMap),
            JSON.serialize(batchConfig)
        );
        Test.stopTest();

        System.assertNotEquals(null, result.get('batchId'), 'Should return batch ID');
        System.assertEquals(2, result.get('totalInserted'), 'Should insert 2 records');
        System.assertEquals(0, result.get('totalFailed'), 'Should have no failures');

        // Verify batch record
        DataImportBatch__c batch = [
            SELECT Name, Batch_Description__c
            FROM DataImportBatch__c
            WHERE Id = :(Id) result.get('batchId')
        ];
        System.assertEquals('Test Batch', batch.Name);
        System.assertEquals('Test description', batch.Batch_Description__c);

        // Verify DI records
        List<DataImport__c> dis = [
            SELECT Contact1_Firstname__c, Contact1_Lastname__c, Donation_Amount__c
            FROM DataImport__c
            WHERE NPPatch_Data_Import_Batch__c = :(Id) result.get('batchId')
            ORDER BY Contact1_Firstname__c
        ];
        System.assertEquals(2, dis.size());
        System.assertEquals('Another', dis[0].Contact1_Firstname__c);
        System.assertEquals('Test', dis[1].Contact1_Firstname__c);
    }

    @isTest
    static void shouldGetBatches() {
        DataImportBatch__c batch = new DataImportBatch__c(
            Name = 'Test Batch'
        );
        insert batch;

        Test.startTest();
        List<Map<String, Object>> batches =
            BDI_ImportWizardController.getBatches('All');
        Test.stopTest();

        System.assert(!batches.isEmpty(), 'Should return batches');
        Boolean found = false;
        for (Map<String, Object> b : batches) {
            if (b.get('Name') == 'Test Batch') {
                found = true;
                break;
            }
        }
        System.assert(found, 'Should find our test batch');
    }

    @isTest
    static void shouldFilterBatchesByStatus() {
        DataImportBatch__c batch = new DataImportBatch__c(
            Name = 'Open Batch'
        );
        insert batch;

        Test.startTest();
        List<Map<String, Object>> openBatches =
            BDI_ImportWizardController.getBatches('Open');
        List<Map<String, Object>> completedBatches =
            BDI_ImportWizardController.getBatches('Completed');
        Test.stopTest();

        // New batches default to Open status
        Boolean foundInOpen = false;
        for (Map<String, Object> b : openBatches) {
            if (b.get('Name') == 'Open Batch') foundInOpen = true;
        }
        System.assert(foundInOpen, 'Should find batch in Open filter');

        Boolean foundInCompleted = false;
        for (Map<String, Object> b : completedBatches) {
            if (b.get('Name') == 'Open Batch') foundInCompleted = true;
        }
        System.assert(!foundInCompleted, 'Should not find batch in Completed filter');
    }

    @isTest
    static void shouldExcludeGiftBatches() {
        DataImportBatch__c giftBatch = new DataImportBatch__c(
            Name = 'Gift Batch',
            GiftBatch__c = true
        );
        insert giftBatch;

        Test.startTest();
        List<Map<String, Object>> batches =
            BDI_ImportWizardController.getBatches('All');
        Test.stopTest();

        for (Map<String, Object> b : batches) {
            System.assertNotEquals('Gift Batch', b.get('Name'),
                'Should exclude Gift Entry batches');
        }
    }

    @isTest
    static void shouldGetProcessingStatus() {
        DataImportBatch__c batch = new DataImportBatch__c(Name = 'Test');
        insert batch;

        DataImport__c di = new DataImport__c(
            NPPatch_Data_Import_Batch__c = batch.Id,
            Contact1_Lastname__c = 'Test'
        );
        insert di;

        Test.startTest();
        Map<String, Object> status = BDI_ImportWizardController.getProcessingStatus(
            batch.Id, null
        );
        Test.stopTest();

        System.assertNotEquals(null, status, 'Should return status');
        System.assert(status.containsKey('batchStatus'), 'Should have batchStatus');
        System.assert(status.containsKey('statusCounts'), 'Should have statusCounts');

        Map<String, Integer> counts = (Map<String, Integer>) status.get('statusCounts');
        System.assert(counts != null, 'Status counts should not be null');
    }

    @isTest
    static void shouldProcessBatch() {
        DataImportBatch__c batch = new DataImportBatch__c(Name = 'Test');
        insert batch;

        DataImport__c di = new DataImport__c(
            NPPatch_Data_Import_Batch__c = batch.Id,
            Contact1_Firstname__c = 'Test',
            Contact1_Lastname__c = 'Contact',
            Donation_Amount__c = 100,
            Donation_Date__c = Date.today()
        );
        insert di;

        Test.startTest();
        Id jobId = BDI_ImportWizardController.processBatch(batch.Id, true);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Should return job ID');
    }
}
