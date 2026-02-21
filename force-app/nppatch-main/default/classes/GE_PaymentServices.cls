/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group HGE
* @group-content
* @description Class holds payment services purchase request related methods.
*/
public with sharing class GE_PaymentServices {
    @TestVisible class PaymentServicesException extends Exception {}

    private static GE_PaymentServices paymentServicesInstance;

    // Elevate payment services configuration removed

    /**
    * @description Returns static instance of this class. Primarily used to facilitate
    * dependency injection in tests.
    * @return Instance of GE_PaymentServices class.
    */
    public static GE_PaymentServices getInstance(){
        if (paymentServicesInstance == null) {
            paymentServicesInstance = new GE_PaymentServices();
        }
        return paymentServicesInstance;
    }

    /**
    * @description Sets instance member variable holding instance of this class.  Primarily
    * used to facilitate dependency injection in tests.
    * @param paymentServicesInstance An instance of the GE_PaymentServices class.
    */
    @TestVisible
    private static void setInstance(GE_PaymentServices instance){
        paymentServicesInstance = instance;
    }

    /**
     * @description Elevate has been removed. Always returns false.
     * @return Boolean
     */
    public Boolean isElevateCustomer() {
        return false;
    }

    /**
     * @description Elevate SDK URL - removed with Elevate.
     * @return String
     */
    public String getElevateSDKURL() {
        return null;
    }

    /**
     * @description Elevate client ID - removed with Elevate.
     * @return String
     */
    public String getClientId() {
        return null;
    }

    /**
     * @description Elevate gateway IDs - removed with Elevate.
     * @return String
     */
    public String getGatewayIds() {
        return null;
    }

    public String getMerchantIds() {
        return null;
    }

    /**
     * @description Elevate JWT - removed with Elevate.
     * @return String
     */
    public String getJwtForToken() {
        return null;
    }

    /**
     * @description Returns Payments Services transaction status values.
     * Elevate has been removed; returns empty map.
     * @return String JSON of the transaction status values by name
     */
    @AuraEnabled(cacheable=true)
    public static String getPaymentTransactionStatusValues() {
        Map<String, String> paymentStatusNameByEnum = new Map<String, String>();
        return JSON.serialize(paymentStatusNameByEnum);
    }

    /**
     * @description Returns salesforce lightning URL
     * @return String JSON of lightning URL
     */
    public String getLightningURL() {
        return DomainCreator.getLightningHostname();
    }

    /**
     * @description Returns salesforce visualforce URL
     * @param namespace: string for namespace in org instance
     * @return String JSON of visualforce URL
     */
    @AuraEnabled(cacheable=true)
    public static OriginUrls getOriginUrls(String namespace) {
        return new OriginUrls(
            DomainCreator.getVisualforceHostname(namespace),
                DomainCreator.getLightningHostname()
        );
    }

    public class OriginUrls {
        @AuraEnabled public String visualForceOriginUrl;
        @AuraEnabled public String lightningOriginUrl;

        public OriginUrls(String visualForceOriginUrl, String lightningOriginUrl) {
            this.visualForceOriginUrl = 'https://'+visualForceOriginUrl;
            this.lightningOriginUrl = 'https://'+lightningOriginUrl;
        }
    }

    /**
     * @description Returns purchase request body
     * @param jsonRequestBody: JSON containing parameters for the purchase call request body
     * @return PurchaseCallBody
     */
    private PurchaseCallBody getPurchaseCallBody(String jsonRequestBody) {
        Map<String, Object> requestBodyParameters =
            (Map<String, Object>) JSON.deserializeUntyped(jsonRequestBody);

        PurchaseCallBody requestBody = new PurchaseCallBody(
            UserInfo.getDefaultCurrency(),
            null,
            null
        ).applyAll(requestBodyParameters);

        return requestBody;
    }

    /**
     * @description Returns purchase request body
     * @param jsonRequestBody JSON containing some purchase call request body parameters set by the LWC
     * @return UTIL_Http.Response
     */
    public UTIL_Http.Response createTransaction(String jsonRequestBody) {
        PurchaseCallBody requestBody = getPurchaseCallBody(jsonRequestBody);

        return createTransaction(requestBody);
    }

    /**
     * @description Method sends a purchase requet to Elevate.
     * Check out the Payments swagger in the SFDO Payments repo for additional information.
     * @param requestBody Purchase call request body
     * @return UTIL_Http.Response
    */
    public UTIL_Http.Response createTransaction(PurchaseCallBody requestBody) {
        UTIL_Http.RequestService requestService = new UTIL_Http.RequestService();

        HttpRequest request = buildPurchaseRequest(requestBody.getAsJson());

        UTIL_Http.Response response = requestService.sendRequest(request);

        return response;
    }

    /***
    * @description Creates an HttpRequest for a new one-time payment (purchase) creation.
    * Elevate has been removed; this method returns null.
    * @param jsonRequestBody JSON containing parameters for the purchase call request body
    * @return HttpRequest
    */
    private HttpRequest buildPurchaseRequest(String jsonRequestBody) {
        return null;
    }

    /***
    * @description Inner class of PurchaseCallBody to assist in constructing the metadata property.
    * This could/should probably just be a map.
    */
    public with sharing class Metadata {
        public String campaignCode;
    }

    /**
     * @description Inner class for constructing ACH specific data for the purchase request body
     */
    public with sharing class AchData {
        public String achCode;
        public String consent;
        public String type;
        public String bankType;
        public ConsentDetails consentDetails = new ConsentDetails();
    }

    public with sharing class ConsentDetails {
        public String consentType;
    }

    /***
    * @description Inner class to assist in constructing the Purchase http request body.
    */
    public with sharing class PurchaseCallBody {
        /*********************************
        * Required properties
        */
        public Integer amount;
        // Currency code for the amount property. Currently an ENUM = [USD] from Elevate
        public String currencyCode;
        public String paymentMethodToken;
        public String merchantId;
        public String gatewayId;
        public String email;
        public String firstName;
        public String lastName;
        public String phone;
        public String city;
        public String state;
        public String postalCode;
        // The ISO 3166-1 alpha-2 country code. E.g. US
        public String country;
        public AchData achData;
        public String paymentMethodType;
        public String accountName;
        public String productMetadataSchemaUri;
        /***
         * Optional properties
         */
        public Map<String, Object> productMetadata;



        public PurchaseCallBody(String currencyCode, String merchantIds, String gatewayIds) {
            this.currencyCode = currencyCode;
            this.merchantId = merchantIds;
            this.gatewayId = gatewayIds;
        }

        public String getAsJson() {
            return JSON.serialize(this);
        }

        public PurchaseCallBody applyAll(Map<String, Object> requestBodyParameters) {
            Map<String, Object> selfAsUntyped = (Map<String, Object>) JSON.deserializeUntyped(getAsJson());
            for (String key : requestBodyParameters.keySet()) {
                selfAsUntyped.put(key, requestBodyParameters.get(key));
            }

            return (PurchaseCallBody) JSON.deserialize(JSON.serialize(selfAsUntyped), PurchaseCallBody.class);
        }
    }

}