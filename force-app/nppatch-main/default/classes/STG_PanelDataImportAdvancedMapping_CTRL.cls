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
* @group Settings
* @group-content ../../ApexDocContent/Settings.htm
* @description Controller extension for the Gift Entry and Advanced Mapping settings panel.
*/
public with sharing class STG_PanelDataImportAdvancedMapping_CTRL extends STG_Panel {
    /*********************************************************************************************************
    * @description Returns the string Id of the Data Import Advanced Mapping panel
    */
    public override String idPanel() { return 'idPanelDataImportAdvancedMapping'; }

    /*******************************************************************************************************
    * @description Action Method to navigate to separate VF page that contains custom Advanced Mapping UI in
    * Aura and Lightning. Uses the runtime namespace to build the component URL, falling back to 'c' in
    * non-namespaced orgs.
    *
    * @return PageReference
    */
    public PageReference navigate() {
        String namespace = UTIL_Namespace.getNamespace();
        String prefix = String.isBlank(namespace) ? 'c' : namespace;
        PageReference advancedMapping = new PageReference('/lightning/cmp/' + prefix + '__BDI_ManageAdvancedMapping');
        advancedMapping.setRedirect(true);
        return advancedMapping;
    }

    /*******************************************************************************************************
    * @description Adds a message to the Page
    *
    * @param severity: Severity level of message
    * @param message: Text to be displayed
    */
    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

}
