<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <layoutAssignments>
        <layout>Account-%%%NAMESPACE%%%Household Layout</layout>
        <recordType>Account.HH_Account</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Account-%%%NAMESPACE%%%Organization Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Account-%%%NAMESPACE%%%Organization Layout</layout>
        <recordType>Account.Organization</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Campaign-%%%NAMESPACE%%%NPPatch Campaign Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Contact-%%%NAMESPACE%%%Fundraising Contact Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Donation Layout</layout>
        <recordType>Opportunity.NPPatch_Default</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Donation Layout</layout>
        <recordType>Opportunity.Donation</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Grant Layout</layout>
        <recordType>Opportunity.Grant</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%In-Kind Gift Layout</layout>
        <recordType>Opportunity.InKindGift</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Major Gift Layout</layout>
        <recordType>Opportunity.MajorGift</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Matching Gift Layout</layout>
        <recordType>Opportunity.MatchingGift</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Membership Layout</layout>
        <recordType>Opportunity.Membership</recordType>
    </layoutAssignments>
    <recordTypeVisibilities>
        <default>true</default>
        <recordType>Opportunity.Donation</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.Grant</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.InKindGift</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.MajorGift</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.MatchingGift</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.Membership</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.NPPatch_Default</recordType>
        <visible>false</visible>
    </recordTypeVisibilities>
</Profile>
