/*
 *
 *  * Copyright (c) 2020, salesforce.com, inc.
 *  * All rights reserved.
 *  * SPDX-License-Identifier: BSD-3-Clause
 *  * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
 */

@IsTest
public with sharing class ServiceSessionService_TEST {
    private static final String COMPLETE_BUCKET = 'ServiceSessionStatusComplete';
    private static final String PENDING_BUCKET = 'ServiceSessionStatusPending';

    private static TestStub bucketSelectorStub;

    private static BasicStub sessionSelectorStub = new BasicStub(
        ServiceSessionSelector.class
    );

    private static BasicStub sessionDomainStub = new BasicStub(
        ServiceSessionDomain.class
    );

    private static ServiceSessionService service = new ServiceSessionService();

    @IsTest
    private static void testGetServiceSessionsByStartDate() {
        TestDataFactory.generateAttendanceData('Daily');

        final String dateLiteral = 'THIS_WEEK';
        final String methodName = 'getServiceSessionsByStartDate';
        final Set<String> allowedServiceSessionStatuses = new Set<String>{
            'Pending',
            'Complete'
        };

        Map<String, List<ServiceSession__c>> expected = new Map<String, List<ServiceSession__c>>();

        List<ServiceSession__c> expectedSessions = [
            SELECT Id, Name, PrimaryServiceProvider__c, Status__c, SessionStart__c
            FROM ServiceSession__c
            WHERE
                SessionStart__c = THIS_WEEK
                AND Status__c IN :allowedServiceSessionStatuses
            ORDER BY SessionStart__c
        ];

        System.assert(
            expectedSessions.size() >= 1,
            'Test data should include at least one service session for this week'
        );

        for (ServiceSession__c session : expectedSessions) {
            String dateKey = session.SessionStart__c.format('EEEE, dd MMMM');
            if (!expected.containsKey(dateKey)) {
                expected.put(dateKey, new List<ServiceSession__c>());
            }
            expected.get(dateKey).add(session);
        }

        sessionSelectorStub.withReturnValue(methodName, String.class, expectedSessions);

        Test.startTest();
        service.serviceSessionSelector = (ServiceSessionSelector) sessionSelectorStub.createMock();

        Map<String, List<ServiceSession__c>> actual = service.getServiceSessionsByStartDate(
            dateLiteral
        );

        Test.stopTest();

        System.assertEquals(
            expected.keySet(),
            actual.keySet(),
            'Expected date keys do not match actual date keys'
        );

        for (String dateKey : expected.keySet()) {
            System.assertEquals(
                expected.get(dateKey).size(),
                actual.get(dateKey).size(),
                'Expected list size does not match actual for key: ' + dateKey
            );
        }

        sessionSelectorStub.assertCalledWith(methodName, String.class, dateLiteral);
    }

    @IsTest
    private static void testGetServiceSessionStatusBuckets() {
        String methodName = 'getBuckets';
        List<String> bucketNames = new List<String>{ COMPLETE_BUCKET, PENDING_BUCKET };

        Schema.SObjectType serviceSessionSObjType = ServiceSession__c.SObjectType;
        Schema.SObjectField statusField = ServiceSession__c.Status__c;

        List<Bucket__mdt> statusBuckets = createStatusBuckets();

        bucketSelectorStub = new StubBuilder(FieldBucketSelector.class)
            .when(
                methodName,
                List<String>.class,
                Schema.SObjectType.class,
                Schema.SObjectField.class
            )
            .calledWith(bucketNames, serviceSessionSObjType, statusField)
            .thenReturn(statusBuckets)
            .build();

        service.bucketSelector = (FieldBucketSelector) bucketSelectorStub.create();

        Map<String, List<String>> expectedStatuses = new Map<String, List<String>>();
        expectedStatuses.put('Complete', new List<String>{ 'Complete' });
        expectedStatuses.put('Pending', new List<String>{ 'Pending' });

        Test.startTest();
        Map<String, List<String>> returnedStatuses = service.getServiceSessionStatusBuckets();
        Test.stopTest();

        System.assertEquals(
            expectedStatuses,
            returnedStatuses,
            'Expected values is not the same as actual values'
        );

        bucketSelectorStub.assertCalledAsExpected();
    }

    @IsTest
    private static void shouldSendSessionToDomainForUpdate() {
        String updateServiceSession = 'updateServiceSession';
        ServiceSession__c session = new ServiceSession__c();

        service.serviceSessionDomain = (ServiceSessionDomain) sessionDomainStub.createMock();

        Test.startTest();
        service.updateServiceSession(session);
        Test.stopTest();

        sessionDomainStub.assertCalledWith(
            updateServiceSession,
            ServiceSession__c.class,
            session
        );
    }

    private static List<Bucket__mdt> createStatusBuckets() {
        BucketedField__mdt bucketedField = (BucketedField__mdt) new TestUtil.BucketedFieldBuilder()
            .withDeveloperName('ServiceSessionStatuses')
            .withQualifiedApiName(UTIL_Namespace.prefixNamespace('ServiceSessionStatuses'))
            .withField('Status__c')
            .withObject('ServiceSession__c')
            .withMockId()
            .build();

        List<BucketedValue__mdt> completeValues = new List<BucketedValue__mdt>();
        completeValues.add(
            (BucketedValue__mdt) new TestUtil.BucketedValueBuilder()
                .withDeveloperName('Complete')
                .withQualifiedApiName(UTIL_Namespace.prefixNamespace('Complete'))
                .withBucket('Complete')
                .withValue('Complete')
                .withMockId()
                .build()
        );

        List<BucketedValue__mdt> pendingValues = new List<BucketedValue__mdt>();
        pendingValues.add(
            (BucketedValue__mdt) new TestUtil.BucketedValueBuilder()
                .withDeveloperName('Pending')
                .withQualifiedApiName(UTIL_Namespace.prefixNamespace('Pending'))
                .withBucket('Pending')
                .withValue('Pending')
                .withMockId()
                .build()
        );

        Bucket__mdt completeBucket = (Bucket__mdt) new TestUtil.BucketBuilder()
            .withBucketedField(bucketedField)
            .withBucketedValues(completeValues)
            .withDeveloperName('Complete')
            .withQualifiedApiName(UTIL_Namespace.prefixNamespace('Complete'))
            .withMockId()
            .build();

        Bucket__mdt pendingBucket = (Bucket__mdt) new TestUtil.BucketBuilder()
            .withBucketedField(bucketedField)
            .withBucketedValues(pendingValues)
            .withDeveloperName('Pending')
            .withQualifiedApiName(UTIL_Namespace.prefixNamespace('Pending'))
            .withMockId()
            .build();

        return new List<Bucket__mdt>{ completeBucket, pendingBucket };
    }
}
