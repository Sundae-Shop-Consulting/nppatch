/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Account Model Converter
* @description Account model conversion utility main class. This class holds all conversion logic
*/
global class CONV_Account_Conversion_BATCH implements Database.Batchable<SObject>{

    /*******************************************************************************************************
    * @description Query string set in the constructor
    */
    public String query {get; set;}
    /*******************************************************************************************************
    * @description Not yet implemented mapping of fields between the old Household object and new Household Account
    */
    public Map<String, String> fieldmap {get;set;}
    /*******************************************************************************************************
    * @description Field used to store the old Household Id on the Account
    */
    public String HouseholdIdField {get;set;}
    /*******************************************************************************************************
    * @description Audit fields to write on created accounts if enabled by salesforce support
    */
    public set<string> auditFields = new set<string>{'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate'};

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    * @param q Query string
    * @param hhIdField Field for Household Id from the controller
    * @param Unimplemented map of fields to be copied
    */
    public CONV_Account_Conversion_BATCH(String q, String hhIdField, Map<String, String> fm) {
        fieldmap = fm;
        query = q;
        HouseholdIdField = hhIdField;
    }

    /*******************************************************************************************************
    * @description Turns off the TDTM triggers and returns the query locator
    * @param bc BatchableContext passed by the system call
    * @return database.Querylocator
    */
    global database.Querylocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    /*******************************************************************************************************
    * @description Executes the conversion process. This method contains all of the actual conversion logic
    * @param bc BatchableContext passed by the system call
    * @param result Results to be processed from the query
    */
    global void execute(Database.BatchableContext bc, Sobject[] result) {
    
        //turn off all existing TDTM-related trigger operations to avoid duplicative processing
        TDTM_TriggerHandler.disableTDTM = true;

        SavePoint sp = Database.setSavepoint();

        try{

            List<Contact> consForUpdate = new List<Contact>();
            List<OpportunityContactRole> ocrsForUpdate = new List<OpportunityContactRole>();
            List<Opportunity> oppsForUpdate = new List<Opportunity>();

            Map<Id, Account> hh2account = new Map<Id, Account>();
            Map<Id, Account> con2account = new Map<Id, Account>();
            Map<Id, Household__c> addressedHouseholds = new Map<Id, Household__c>();

            List<Household__c> hhscope = (List<Household__c>)result;

            consForUpdate = [SELECT AccountId, Name, OwnerId, Owner.IsActive, Account.RecordTypeId, Account.Type,
                                Account.SYSTEM_AccountType__c,Account.SYSTEMIsIndividual__c, Household__c, TotalOppAmount__c,
                                Primary_Address_Type__c, MailingStreet, MailingCity, MailingState, MailingCountry,
                                MailingPostalCode, Primary_Affiliation__c
                            FROM Contact WHERE Household__c IN :hhscope ORDER BY CreatedDate];

            /********************************************************************/
            /** Generating a new Household Account for each Household in scope **/
            /********************************************************************/

            //remove hh that have existing hh accounts
            hhscope = removeHouseholdAccountsFromList(hhscope, consForUpdate);
            //use the filtered list of accounts to remove the cons
            consForUpdate = removeContactsWithHouseholdAccount(hhscope, consForUpdate);

            for (Household__c hh : hhscope){
                Account a = new Account(
                    Name = hh.Name, OwnerId = (hh.Owner.IsActive == true ? hh.OwnerId : UserInfo.getUserId()),
                    TotalOppAmount__c = hh.TotalOppAmount__c,
                    TotalMembershipOppAmount__c = hh.TotalMembershipOppAmount__c,
                    SmallestAmount__c = hh.SmallestAmount__c, SYSTEM_CUSTOM_NAMING__c = hh.SYSTEM_CUSTOM_NAMING__c,
                    OppsClosedThisYear__c = hh.OppsClosedThisYear__c, OppsClosedLastYear__c = hh.OppsClosedLastYear__c,
                    OppsClosedLastNDays__c = hh.OppsClosedLastNDays__c, OppsClosed2YearsAgo__c = hh.OppsClosed2YearsAgo__c,
                    OppAmountThisYear__c = hh.OppAmountThisYear__c, OppAmountLastYear__c = hh.OppAmountLastYear__c,
                    OppAmountLastNDays__c = hh.OppAmountLastNDays__c, OppAmount2YearsAgo__c = hh.OppAmount2YearsAgo__c,
                    NumberOfMembershipOpps__c = hh.NumberOfMembershipOpps__c, NumberOfClosedOpps__c = hh.NumberOfClosedOpps__c,
                    MembershipJoinDate__c = hh.MembershipJoinDate__c, MembershipEndDate__c = hh.MembershipEndDate__c,
                    LastOppAmount__c = hh.LastOppAmount__c, LastMembershipOrigin__c = hh.LastMembershipOrigin__c,
                    LastMembershipLevel__c = hh.LastMembershipLevel__c, LastMembershipDate__c = hh.LastMembershipDate__c,
                    LastMembershipAmount__c = hh.LastMembershipAmount__c, LastCloseDate__c = hh.LastCloseDate__c,
                    LargestAmount__c = hh.LargestAmount__c, Informal_Greeting__c = hh.Informal_Greeting__c,
                    HouseholdPhone__c = hh.HouseholdPhone__c, Formal_Greeting__c = hh.Formal_Greeting__c,
                    FirstCloseDate__c = hh.FirstCloseDate__c, Best_Gift_Year__c = hh.Best_Gift_Year__c,
                    Best_Gift_Year_Total__c = hh.Best_Gift_Year_Total__c, Type = 'Household', SYSTEM_AccountType__c = 'Household Account',
                    SYSTEMIsIndividual__c = true
                );

                if (UTIL_CustomSettingsFacade.getContactsSettings().HH_Account_RecordTypeID__c != null)
                    a.RecordTypeId = UTIL_CustomSettingsFacade.getContactsSettings().HH_Account_RecordTypeID__c;

                if (HouseholdIdField != null && HouseholdIdField != ''){
                    a.put(HouseholdIdField, hh.Id);
                }

                if (hh.MailingStreet__c != null ||
                    hh.MailingPostalCode__c != null ||
                    hh.MailingCountry__c != null ||
                    hh.MailingState__c != null ||
                    hh.MailingCity__c != null){

                    a.BillingStreet = hh.MailingStreet__c;
                    a.BillingPostalCode = hh.MailingPostalCode__c;
                    a.BillingCountry = hh.MailingCountry__c;
                    a.BillingState = hh.MailingState__c;
                    a.BillingCity = hh.MailingCity__c;
                    addressedHouseholds.put(hh.Id, hh);
                }

                //if setting audit fields on insert has been enabled by salesforce support, copy over household audit fields to the account
                Map<String, Schema.SObjectField> mapAudit = Schema.SObjectType.Account.fields.getMap();
                for (string auditField : auditFields) {
                    if (mapAudit.get(auditField).getDescribe().isCreateable()) {
                        a.put(auditField, hh.get(auditField));
                    }
                }

                hh2Account.put(hh.id, a);
            }

            UTIL_DMLService.insertRecords(hh2Account.values());

            //save the contact giving amount to determine the primary contact
            Map<Id, Double> conGiving = new Map<Id, Double>();
            //Map of the Account back to the all of the new Household members
            Map<Id, List<Contact>> consWithNewHousehold = new Map<Id, List<Contact>>();

            Map<Id, Map<Id,ContactAddress>> addressMap = new Map<Id, Map<Id,ContactAddress>>();

            /***********************************************************************/
            /** Attaching current Household members to the new Household Account  **/
            /***********************************************************************/
            
            Map<Id, Affiliation__c> conAffMap = new Map<Id, Affiliation__c>();
            Map<Id, Integer> hhMemberCount = new Map<Id, Integer>();
            Map<string, Affiliation__c> mapKeyAff = new Map<string, Affiliation__c>();
            
            for (Affiliation__c aff : [select Id, Status__c, Primary__c, Organization__c, Contact__c
                    from Affiliation__c where Contact__c in :consForUpdate]) {
                string strKey = aff.Contact__c + ':' + aff.Organization__c;
                mapKeyAff.put(strKey, aff);
            }

            for (Contact c : consForUpdate){
                Account a = hh2Account.get(c.Household__c);

                if (hhMemberCount.containsKey(a.Id)){
                    Integer currCount = hhMemberCount.get(a.Id);
                    currCount++;
                    hhMemberCount.put(a.Id, currCount);
                }
                else{
                    hhMemberCount.put(a.Id, 1);
                }

                //generate affiliations for any non 1x1/Individual accounts associated to this Contact
                //or if an existing affiliation already exists, mark it primary.
                //also set the contact's Primary Affiliation field.
                if (!c.Account.SYSTEMIsIndividual__c){
                    string strKey = c.Id + ':' + c.AccountId;
                    Affiliation__c aff = mapKeyAff.get(strKey);
                    if (aff == null) {                    
                        aff = new Affiliation__c(Status__c = 'Current', Primary__c = true, Organization__c = c.AccountId, Contact__c = c.Id);
                        mapKeyAff.put(strKey, aff);
                    }
                    if (c.Primary_Affiliation__c == null) {
                        c.Primary_Affiliation__c = c.AccountId;
                        aff.Primary__c = true;
                        aff.Status__c = 'Current';
                    }
                    if (conAffMap.get(c.Id) == null)
                        conAffMap.put(c.Id, aff);
                }

                c.AccountId = a.Id;
                if (!conGiving.containsKey(a.Id) || (conGiving.containsKey(a.Id) && c.TotalOppAmount__c > conGiving.get(a.Id))){
                    a.One2OneContact__c = c.Id;
                    if (c.Owner.IsActive == true) {
                        // If the owner of the "Primary Contact" is active, set that as the owner of the Household Account
                        a.OwnerId = c.OwnerId;
                    }
                    conGiving.put(a.Id, c.TotalOppAmount__c);
                }
                con2account.put(c.Id, a);

                //build a map of cons with the new household to use later for address
                if (consWithNewHousehold.containsKey(a.Id)){
                    consWithNewHousehold.get(a.Id).add(c);
                }
                else{
                    consWithNewHousehold.put(a.Id, new List<Contact>{c});
                }
            }

            //for any contacts that have an affiliation, update the primary affiliation for the contact
            if (!conAffMap.isEmpty()){
                Database.upsert(conAffMap.values(), true);
            }

            for (Account a : hh2Account.values()){
                a.Number_of_Household_Members__c = hhMemberCount.get(a.Id);
            }

            UTIL_DMLService.updateRecords(consForUpdate);
            UTIL_DMLService.updateRecords(hh2Account.values());

            /***************************************************************/
            /** Porting all existing opportunities to the new hh accounts **/
            /***************************************************************/

            ocrsForUpdate = [select Opportunity.AccountId, Contact.Household__c, Opportunity.Id from OpportunityContactRole where isPrimary = true and ContactId IN :consForUpdate and Opportunity.Is_Opp_From_Individual__c = 'true'];

            for (OpportunityContactRole ocr : ocrsForUpdate) {
                Opportunity o = new Opportunity (id = ocr.OpportunityId);
                o.AccountId = con2Account.get(ocr.ContactId).Id;
                oppsForUpdate.add(o);
            }
            if (!oppsForUpdate.isEmpty())
                UTIL_DMLService.updateRecords(oppsForUpdate);

            /******************************************************************************/
            /** Moving any activities and tasks from the Household object to the Account **/
            /******************************************************************************/

            List<Task> tasksForUpdate = new List<Task>();
            tasksForUpdate = database.query('select WhatId from Task where WhatId IN :hhscope');

            for (Task t : tasksForUpdate)
                t.WhatId = hh2Account.get(t.WhatId).Id;

            UTIL_DMLService.updateRecords(tasksForUpdate);

            /**********************************************************************/
            /** Address Mapping from existing Contacts to new Household Accounts **/
            /**********************************************************************/

            consForUpdate.clear();
            Map<Id, Address__c> addressesForInsert = new Map<Id, Address__c>();
            List<Account> hhAccountsForUpdate = new List<Account>();

            Contacts_And_Orgs_Settings__c contactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
            if (!contactsSettings.Household_Account_Addresses_Disabled__c) {
                for (Id accountId : consWithNewHousehold.keySet()){
                    List<Contact> conList = consWithNewHousehold.get(accountId);

                    //if its the only Contact decide if we need to use the household account address or the contacts...
                    if (conList != null && conList.size() == 1){

                        ContactAddress cadd = new ContactAddress(conList[0]);
                        Account myHHAccount = con2Account.get(conList[0].Id);
                        
                        //first, create an Address object if the original household had an address.
                        if (addressedHouseholds.containsKey(conList[0].Household__c)) {
                            Address__c a = new Address__c(
                                MailingStreet__c = myHHAccount.BillingStreet,
                                MailingCity__c = myHHAccount.BillingCity,
                                MailingState__c = myHHAccount.BillingState,
                                MailingPostalCode__c = myHHAccount.BillingPostalCode,
                                MailingCountry__c = myHHAccount.BillingCountry,
                                Default_Address__c = true,
                                Address_Type__c = 'Home',
                                Household_Account__c = myHHAccount.Id
                                );
                            Addresses.handleMultilineStreet(a);
                            addressesForInsert.put(myHHAccount.Id, a);                                            
                        }

                        //we have a household address, but the contact does not have one assign the values to the contact
                        //the address lookup will be populated later via the addressesForInsert based on the accountId
                        if (addressedHouseholds.containsKey(conList[0].Household__c) && !cadd.hasAddress()){
                            conList[0].MailingCity = myHHAccount.BillingCity;
                            conList[0].MailingState = myHHAccount.BillingState;
                            conList[0].MailingPostalCode = myHHAccount.BillingPostalCode;
                            conList[0].MailingStreet = myHHAccount.BillingStreet;
                            conList[0].MailingCountry = myHHAccount.BillingCountry;
                            conList[0].Primary_Address_Type__c = 'Home';
                            consForUpdate.add(conList[0]);
                        }

                        //we have a household address and the contact has one
                        else if (addressedHouseholds.containsKey(conList[0].Household__c) && cadd.hasAddress()){
                            //if they're the same, do nothing, otherwise create a new contact address
                            if (myHHAccount.BillingCity != cadd.MailingCity ||
                                myHHAccount.BillingCountry != cadd.MailingCountry ||
                                myHHAccount.BillingPostalCode != cadd.MailingZip ||
                                myHHAccount.BillingState != cadd.MailingState ||
                                myHHAccount.BillingStreet != cadd.MailingStreet){

                                Address__c a = new Address__c(MailingStreet__c = cadd.MailingStreet,
                                    MailingState__c = cadd.MailingState,
                                    MailingPostalCode__c = cadd.MailingZip,
                                    MailingCountry__c = cadd.MailingCountry,
                                    MailingCity__c = cadd.MailingCity,
                                    Default_Address__c = true,
                                    Address_Type__c = cadd.AddressType,
                                    Household_Account__c = accountId);
                                Addresses.handleMultilineStreet(a);
                                addressesForInsert.put(conList[0].Id, a);
                            }
                        }

                        //we do not have a household address, but the contact has one
                        //use the contact's address as the default and do not set the override for the
                        //contact
                        else if (!addressedHouseholds.containsKey(conList[0].Household__c) && cadd.hasAddress()){
                            Address__c a = new Address__c(MailingStreet__c = cadd.MailingStreet,
                                MailingState__c = cadd.MailingState,
                                MailingPostalCode__c = cadd.MailingZip,
                                MailingCountry__c = cadd.MailingCountry,
                                MailingCity__c = cadd.MailingCity,
                                Default_Address__c = true,
                                Address_Type__c = cadd.AddressType,
                                Household_Account__c = accountId);
                            Addresses.handleMultilineStreet(a);
                            addressesForInsert.put(AccountId, a);

                            myHHAccount.BillingStreet = cadd.MailingStreet;
                            myHHAccount.BillingState = cadd.MailingState;
                            myHHAccount.BillingPostalCode = cadd.MailingZip;
                            myHHAccount.BillingCountry = cadd.MailingCountry;
                            myHHAccount.BillingCity = cadd.MailingCity;
                            hhAccountsForUpdate.add(myHHAccount);
                        }
                    }

                    //multiple contacts
                    else if (conList != null && conList.size() > 1){

                        Map<Contact, ContactAddress> HHaddresses = new Map<Contact, ContactAddress>();
                        Map<String, Integer> addressFrequency = new Map<String, Integer>();
                        Map<String, Double> addressHighestGiver = new Map<String, Double>();
                        Map<String, ContactAddress> uniqueContactAddress = new Map<String, ContactAddress>();

                        //build the list of new address__c objects that are present and grab some stats to
                        //determine the default address.  First frequency, then total giving amount
                        for (Contact c : conList){
                            ContactAddress cadd = new ContactAddress(c);

                            //if this contact has an address and the new household does not yet...
                            if (cadd.hasAddress() && !addressesForInsert.containsKey(c.AccountId)){
                                HHaddresses.put(c, cadd);
                                uniqueContactAddress.put(cadd.getMD5(), cadd);

                                if (!addressFrequency.containsKey(cadd.getMD5()))
                                    addressFrequency.put(cadd.getMD5(),1);
                                else{
                                    Integer addrCount = addressFrequency.get(cadd.getMd5());
                                    addrCount++;
                                    addressFrequency.put(cadd.getMD5(), addrCount);
                                }

                                if (!addressHighestGiver.containsKey(cadd.getMD5()))
                                    addressHighestGiver.put(cadd.getMD5(), c.TotalOppAmount__c);
                                else{
                                    Double OppTotal = addressHighestGiver.get(cadd.getMD5());
                                    if (c.TotalOppAmount__c > OppTotal)
                                        addressHighestGiver.put(cadd.getMD5(), c.TotalOppAmount__c);
                               }
                            }
                            //if this contact has an address and the household does as well...
                            else if (cadd.hasAddress() && addressesForInsert.containsKey(c.AccountId)){
                                //if they're not the same address
                                if (!cadd.isSameAddress(addressesForInsert.get(c.AccountId))){
                                    HHaddresses.put(c, cadd);
                                }
                            }
                            else
                                HHaddresses.put(c, null);
                        }//end conlist loop

                        //loop through the unique addresses create address objects and determine the master address
                        Boolean hasDefaultAddr = false;
                        Integer addresscount = uniqueContactAddress.keySet().size();
                        Integer counter = 0;
                        String masteraddresshash = null;

                        for (String MD5Hash : uniqueContactAddress.keySet()){
                            ContactAddress cadd = uniqueContactAddress.get(MD5Hash);
                            counter ++;

                            //is this the top address in this household?
                            if (!hasDefaultAddr){
                                //first try address frequency
                                Integer addCount = addressFrequency.get(MD5Hash);
                                for (Integer i : addressFrequency.values()){
                                    if(addCount > i)
                                        hasDefaultAddr = true;
                                    else
                                        hasDefaultAddr = false;
                                }
                                //if we can't determine based on the frequency, try the largest giver
                                if(!hasDefaultAddr){
                                    Double giverAmount = addressHighestGiver.get(MD5Hash);
                                    for (Double d : addressHighestGiver.values()){
                                        if (giverAmount > d)
                                            hasDefaultAddr = true;
                                        else
                                            hasDefaultAddr = false;
                                    }
                                }
                            }

                            //finally, if this is the last address adn we still don't have a default, use this one
                            if(!hasDefaultAddr && counter == addresscount)
                                hasDefaultAddr = true;

                            // save our master address
                            if (hasDefaultAddr && masteraddresshash == null)
                                masteraddresshash = MD5Hash;

                            Address__c a = new Address__c(
                                                MailingStreet__c = cadd.MailingStreet,
                                                MailingState__c = cadd.MailingState,
                                                MailingPostalCode__c = cadd.MailingZip,
                                                MailingCountry__c = cadd.MailingCountry,
                                                MailingCity__c = cadd.MailingCity,
                                                Default_Address__c = (masteraddresshash == MD5Hash ? true : false),
                                                Address_Type__c = cadd.AddressType,
                                                Household_Account__c = cadd.contact.AccountId
                                                );
                            Addresses.handleMultilineStreet(a);

                            if (masteraddresshash == MD5Hash){
                                addressesForInsert.put(cadd.AccountId, a);
                                UTIL_Debug.debug('****DJH default address: ' + a);
                            }
                            else {
                                addressesForInsert.put(cadd.ConId, a);
                                UTIL_Debug.debug('****DJH not default address: ' + a);
                            }
                        }

                        //set the household address fields to the default address values
                        ContactAddress masteraddress = uniqueContactAddress.get(masteraddresshash);

                        if (masteraddress != null && masteraddress.hasAddress()){
                            Account a = con2Account.get(masteraddress.ConId);
                            a.BillingStreet = masteraddress.MailingStreet;
                            a.BillingCity = masteraddress.MailingCity;
                            a.BillingPostalCode = masteraddress.MailingZip;
                            a.BillingCountry = masteraddress.MailingCountry;
                            a.BillingState = masteraddress.MailingState;
                            hhAccountsForUpdate.add(a);
                        }

                        //set any non-addressed contacts to the default address
                        for (Contact c : HHaddresses.keySet()){
                            ContactAddress ca = HHAddresses.get(c);
                            if ((ca != null && !ca.hasAddress()) && (masteraddress != null && masteraddress.hasAddress())){
                                c.MailingStreet = masteraddress.MailingStreet;
                                c.MailingState = masteraddress.MailingState;
                                c.MailingPostalCode = masteraddress.MailingZip;
                                c.MailingCountry = masteraddress.MailingCountry;
                                c.MailingCity = masteraddress.MailingCity;
                                c.Primary_Address_Type__c = masteraddress.AddressType;
                                consForUpdate.add(c);
                            }
                        }
                    }//close for multiple contacts
                }//close for household
            }//close for hh account addresses disabled
            

            if (consForUpdate.size() > 0) UTIL_DMLService.updateRecords(consForUpdate);
            if (addressesForInsert.values().size() > 0) UTIL_DMLService.insertRecords(addressesForInsert.values());
            if (hhAccountsForUpdate.size() > 0) UTIL_DMLService.updateRecords(hhAccountsForUpdate);

            consForUpdate.clear();
            hhAccountsForUpdate.clear();

            //set the lookup value and address override box on each contact for the address its current using
            //this has to happen after the other inserts as we need the address IDs for the lookups
            //also set primary contact for each household account
            for (Id accountId : consWithNewHousehold.keySet()){
                List<Contact> conList = consWithNewHousehold.get(accountId);

                Account myHHAccount = con2Account.get(conList[0].Id);

                //setting primary contact
                if (conList != null && conList.size() == 1){
                    myHHAccount.One2OneContact__c = conList[0].Id;
                    hhAccountsForUpdate.add(myHHAccount);
                }
                else if (conList != null && conList.size() > 1){
                    Double maxOppAmount = conList[0].TotalOppAmount__c;
                    myHHAccount.One2OneContact__c = conList[0].Id;
                    for (Contact con : conList){
                        if (con.TotalOppAmount__c > maxOppAmount){
                            myHHAccount.One2OneContact__c = con.Id;
                            maxOppAmount = con.TotalOppAmount__c;
                        }
                    }
                    hhAccountsForUpdate.add(myHHAccount);
                }

                //setting lookup address and overrides
                if (!contactsSettings.Household_Account_Addresses_Disabled__c) {
                    for (Contact c : conList){
                        //this contact address is not the master address, associate contact with other address and set override
                        if (addressesForInsert.containsKey(c.Id)){
                            c.Current_Address__c = addressesForInsert.get(c.Id).Id;
                            c.is_Address_Override__c = true;
                            consForUpdate.add(c);
                        }
                        //This Contact ID is not in the 'unique address' list, so set it to the hh address
                        else if (addressesForInsert.containsKey(accountId)){
                            c.Current_Address__c = addressesForInsert.get(accountId).Id;
                            consForUpdate.add(c);
                        }
                    }
                }
            }

            //update the contacts with the correct address lookup
            if (consForUpdate.size() > 0) UTIL_DMLService.updateRecords(consForUpdate);
            if (hhAccountsForUpdate.size() > 0) UTIL_DMLService.updateRecords(hhAccountsForUpdate);

        //rollback the entire transaction on any failure, DML or otherwise
        }catch (Exception e){
            Database.rollback(sp);

            //restore the trigger handlers
            TDTM_TriggerHandler.disableTDTM = false;
            
            ERR_Handler.processError(e, ERR_Handler_API.Context.CONV);
            //crash the transaction
            throw new AccountModelConversionException(e.getMessage());
        }

        //restore the trigger handlers
        TDTM_TriggerHandler.disableTDTM = false;
    }//close execute method

    /*******************************************************************************************************
    * @description Cleans up after the conversion process.  Resets settings, resets TDTM records
    * @param bc BatchableContext passed by the system call
    */
    global void finish(Database.BatchableContext bc) {

        //update the custom setting
        Contacts_and_Orgs_Settings__c ContactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
        ContactsSettings.Account_Processor__c = 'Household Account';

        Recordtypeinfo householdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(CAO_Constants.HH_ACCOUNT_RT_DEVELOPER_NAME);
        if(householdAccount != null)
            ContactsSettings.HH_Account_RecordTypeID__c = householdAccount.getRecordTypeId();
        if(!Test.isRunningTest())
            upsert ContactsSettings;

        Households_Settings__c HHSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        HHSettings.Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
        if(!Test.isRunningTest())
            upsert HHSettings;
    }

    /*******************************************************************************************************
    * @description Utility method to remove Households that already have Household Accounts from the batch scope
    * @param hhList List of Households to remove from the conversion scope
    * @param conList List of Contacts to possibly be removed
    * @return List<Household__c>
    */
    private List<Household__c> removeHouseholdAccountsFromList(List<Household__c> hhList, List<Contact> conList){
        Map<Id, Household__c> hhScopeMap = new Map<Id, Household__c>(hhList);
        for (Contact c : conList){
            if (c.Account.RecordTypeID == UTIL_CustomSettingsFacade.getContactsSettings().HH_Account_RecordTypeID__c &&
                c.Account.SYSTEM_AccountType__c == 'Household Account' &&
                c.Account.SYSTEMIsIndividual__c == true &&
                c.Account.Type == 'Household' &&
                hhScopeMap.containsKey(c.Household__c)){
                    hhScopeMap.remove(c.Household__c);
            }
        }
        return hhScopeMap.values();
    }

    /*******************************************************************************************************
    * @description Utility method to remove Contacts that already have Household Accounts from the batch scope
    * @param hhList List of Households to remove from the conversion scope
    * @param conList List of Contacts to possibly be removed
    * @return List<Contact>
    */
    private List<Contact> removeContactsWithHouseholdAccount(List<Household__c> hhList, List<Contact> cList){
        Map<Id, Contact> filteredMap = new Map<Id, Contact>(cList);
        Map<Id, Household__c> hhScopeMap = new Map<Id, Household__c>(hhList);

        for (Contact c : cList){
            if (!hhScopeMap.containsKey(c.Household__c)){
                filteredMap.remove(c.Id);
            }
        }
        return filteredMap.values();
    }

    /*******************************************************************************************************
    * @description Thrown after the rollback when a batch fails
    */
    public class AccountModelConversionException extends Exception {}
}