// Deploy default CRLP rollup definitions (Rollup__mdt, Filter_Group__mdt, Filter_Rule__mdt)
// Run this in a scratch org after deployment to generate the default CMDT records.
// Then retrieve them with: sf project retrieve start -m "CustomMetadata:Rollup__mdt.*" "CustomMetadata:Filter_Group__mdt.*" "CustomMetadata:Filter_Rule__mdt.*"
new CRLP_EnablementService().reset();
System.debug('CRLP default rollup deployment started. Check Customizable_Rollup_Settings__c.CMT_API_Status__c for completion.');
