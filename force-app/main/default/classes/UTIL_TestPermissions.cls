/*
    Copyright (c) 2024, Salesforce.org
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
* @date 2024
* @group Utilities
* @description Utility class for assigning permission sets in tests.
* In 2GP packages, FLS access is granted automatically via the apexTestAccess
* configuration in sfdx-project.json. These methods are intentional no-ops
* retained for backward compatibility with existing test classes.
*/
@IsTest
public class UTIL_TestPermissions {

    private static final String ADMIN_PERMISSION_SET = 'NPPatch_Admin';

    /**
    * @description No-op. In 2GP packages, the NPPatch_Admin permission set is
    * automatically granted to the test runner via apexTestAccess in sfdx-project.json.
    * Manual PermissionSetAssignment DML fails in parallel test execution.
    */
    public static void assignAdminPermissionSet() {
        // No-op: apexTestAccess in sfdx-project.json handles this automatically.
        // Manual PermissionSetAssignment DML is not allowed in parallel Apex tests
        // and causes MIXED_DML_OPERATION errors when combined with non-setup object DML.
    }

    /**
    * @description No-op. See assignAdminPermissionSet().
    * @param permissionSetName The API name of the permission set (ignored)
    */
    public static void assignPermissionSet(String permissionSetName) {
        // No-op: see assignAdminPermissionSet()
    }

    /**
    * @description Creates a test user without permission set assignment.
    * In 2GP, FLS access comes from apexTestAccess, not PermissionSetAssignment DML.
    * @return User A test user
    */
    public static User createUserWithAdminPermissions() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String uniqueUserName = 'testuser' + DateTime.now().getTime() + '@nppatch.test';
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@nppatch.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert u;

        return u;
    }
}
