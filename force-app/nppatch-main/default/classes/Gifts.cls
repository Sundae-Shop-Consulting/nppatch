/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Gifts entity class in NPSP.
*/

public with sharing class Gifts {

    @TestVisible private Map<Id, DataImport__c> dataImportsById = new Map<Id, DataImport__c>();
    @TestVisible private Map<Id, DataImport__c> giftsToUpdate = new Map<Id, DataImport__c>();
    @TestVisible private GiftSelector giftSelector;
    @TestVisible private DonationSelector donationSelector;
    @TestVisible private Donations donations;

    public Gifts() {}


    public Gifts(List<DataImport__c> dataImports) {
        this.giftSelector = new GiftSelector();
        this.donationSelector = new DonationSelector();
        init(dataImports);
    }

    public Gifts(GiftBatchId giftBatchId, GiftSelector giftSelector) {
        this(giftBatchId, giftSelector, new DonationSelector());
    }

    public Gifts(GiftBatchId giftBatchId, GiftSelector giftSelector, DonationSelector donationSelector) {
        this.giftSelector = giftSelector;
        this.donationSelector = donationSelector;
        init(this.giftSelector.getGiftsFor(giftBatchId));
    }

    private void init(List<DataImport__c> dataImports) {
        populateDataImportsById(dataImports);
        populateDonationsFrom(dataImports);
    }

    private void populateDonationsFrom(List<DataImport__c> dataImports) {
        List<Id> donationIds = new List<Id>();
        for (DataImport__c dataImport : dataImports) {
            if (dataImport.DonationImported__c != null) {
                donationIds.add(dataImport.DonationImported__c);
            }
        }

        if (donationIds.size() > 0) {
            donations = new Donations(donationIds, donationSelector);
        }
    }

    public void add(Gift gift) {
        this.dataImportsById.put(gift.id(), gift.asDataImport());
    }

    public Gift findBy(GiftId giftId) {
        DataImport__c matchingDataImport = this.dataImportsById.get(giftId.value());
        if (matchingDataImport != null) {
            return new Gift(matchingDataImport);
        }
        return null;
    }

    public List<Gift> all() {
        List<Gift> gifts = new List<Gift>();
        for (DataImport__c dataImport : dataImportsById.values()) {
            Gift currentGift = toGift(dataImport);
            gifts.add(currentGift);
        }
        return gifts;
    }

    public List<DataImport__c> asDataImports() {
        return dataImportsById.values();
    }

    public Integer size() {
        return this.dataImportsById.values().size();
    }

    public void prepareForProcessing() {
        giftsToUpdate.clear();

        giftsToProcessingStatus();
    }

    public void moveProcessableToProcessingStatus() {
        prepareForProcessing();
    }

    public Boolean hasRecurringGifts() {
        for (DataImport__c dataImport : dataImportsById.values()) {
            Gift gift = new Gift(dataImport);
            if (gift.hasPopulatedRecurringFields()) {
                return true;
            }
        }
        return false;
    }

    public void preprocessRecurringGifts(Boolean shouldPayFirstInstallment) {
        for (DataImport__c dataImport : dataImportsById.values()) {
            Gift gift = new Gift(dataImport);
            if (gift.hasPopulatedRecurringFields()) {
                gift.preprocessForRecurringGift(shouldPayFirstInstallment);
            }
        }
    }

    public void updateRecords() {
        update giftsToUpdate.values();
        giftsToUpdate.clear();
    }

    public void failWith(String failReason) {
        for (Gift gift : standardGiftsInProcessing()) {
            gift.asDataImport().Status__c = BDI_DataImport_API.bdiFailed;
            gift.asDataImport().FailureInformation__c = failReason;
            giftsToUpdate.put(gift.id(), gift.asDataImport());
        }
    }

    public Boolean inProcessing() {
        return standardGiftsInProcessing().size() > 0;
    }

    @TestVisible
    private List<Gift> standardGiftsInProcessing() {
        List<Gift> processingGifts = new List<Gift>();
        for (DataImport__c gift : dataImportsById.values()) {
            Gift currentGift = new Gift(gift);
            if (currentGift.isProcessing()) {
                processingGifts.add(currentGift);
            }
        }
        return processingGifts;
    }

    @TestVisible
    private void giftsToProcessingStatus() {
        for (DataImport__c dataImport : dataImportsById.values()) {
            if (dataImport.Status__c != BDI_DataImport_API.bdiImported) {
                dataImport.Status__c = BDI_DataImport_API.bdiProcessing;
                giftsToUpdate.put(dataImport.Id, dataImport);
            }
        }
    }

    private void populateDataImportsById(List<DataImport__c> dataImports) {
        for (DataImport__c dataImport : dataImports) {
            this.dataImportsById.put(dataImport.Id, dataImport);
        }
    }

    private Gift toGift(DataImport__c dataImport) {
        if (dataImport.DonationImported__c != null && donations != null) {
            return new Gift(dataImport, donations.getDonationFor(dataImport));
        } else {
            return new Gift(dataImport);
        }
    }
}
