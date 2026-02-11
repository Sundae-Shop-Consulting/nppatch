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
* In 2GP packages, the admin profile doesn't automatically have FLS access to package fields.
* Tests that use WITH SECURITY_ENFORCED queries need to assign the NPPatch_Admin permission set.
*/
@IsTest
public class UTIL_TestPermissions {

    private static final String ADMIN_PERMISSION_SET = 'NPPatch_Admin';

    /**
    * @description Assigns the NPPatch_Admin permission set to the current user.
    * Call this in @TestSetup or at the beginning of test methods that need FLS access.
    */
    public static void assignAdminPermissionSet() {
        assignPermissionSet(ADMIN_PERMISSION_SET);
    }

    /**
    * @description Assigns a permission set by name to the current user.
    * @param permissionSetName The API name of the permission set to assign
    */
    public static void assignPermissionSet(String permissionSetName) {
        // Get the permission set - use namespace prefix if running in namespaced context
        String nsPrefix = UTIL_Namespace.getNamespace();
        String fullName = String.isNotBlank(nsPrefix) ? nsPrefix + '__' + permissionSetName : permissionSetName;

        List<PermissionSet> permSets = [
            SELECT Id FROM PermissionSet
            WHERE Name = :permissionSetName OR Name = :fullName
            LIMIT 1
        ];

        if (permSets.isEmpty()) {
            // Permission set not found - this might be okay in some test contexts
            System.debug(LoggingLevel.WARN, 'Permission set not found: ' + permissionSetName);
            return;
        }

        // Check if already assigned
        List<PermissionSetAssignment> existingAssignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :permSets[0].Id
            LIMIT 1
        ];

        if (existingAssignments.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = permSets[0].Id
            );
        }
    }

    /**
    * @description Creates a test user with the NPPatch_Admin permission set assigned.
    * Use with System.runAs() to execute code that requires FLS access.
    * @return User A test user with admin permissions
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

        // Assign permission set
        String nsPrefix = UTIL_Namespace.getNamespace();
        String fullName = String.isNotBlank(nsPrefix) ? nsPrefix + '__' + ADMIN_PERMISSION_SET : ADMIN_PERMISSION_SET;

        List<PermissionSet> permSets = [
            SELECT Id FROM PermissionSet
            WHERE Name = :ADMIN_PERMISSION_SET OR Name = :fullName
            LIMIT 1
        ];

        if (!permSets.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = u.Id,
                PermissionSetId = permSets[0].Id
            );
        }

        return u;
    }
}
