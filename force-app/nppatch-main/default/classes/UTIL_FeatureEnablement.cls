/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Utilities
* @description Services for feature enablement. FeatureParameters removed for 2GP compatibility.
*/
public without sharing class UTIL_FeatureEnablement {

    private static UTIL_FeatureEnablement featureEnablement;

    public static UTIL_FeatureEnablement getInstance() {
        if (featureEnablement == null) {
            featureEnablement = new UTIL_FeatureEnablement();
        }
        return featureEnablement;
    }

    /**
     * @description Check if PilotEnabled feature is active.
     * In scratch orgs, can be overridden via OverrideFeature_PilotEnabled__c setting.
     * @return Boolean Always false unless overridden in scratch org
     */
    public static Boolean isPilotEnabled() {
        return UTIL_FeatureEnablement.getInstance().isOverridePilotEnabled();
    }

    /**
     * @description If the code is currently executing in a Scratch Org, it's possible to override
     * the PilotEnabled feature using the Error_Settings__c custom settings object.
     * @return True if the PilotEnabled feature is overridden in a scratch org
     */
    private Boolean isOverridePilotEnabled() {
        Boolean isPilotOverride = false;

        if (UTIL_Namespace.isScratchOrg()) {
            Error_Settings__c errSettings = UTIL_CustomSettingsFacade.getOrgErrorSettings();
            isPilotOverride = (errSettings.OverrideFeature_PilotEnabled__c == true);
        }

        return isPilotOverride;
    }
}
