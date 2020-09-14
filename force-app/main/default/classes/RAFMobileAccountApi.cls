@RestResource(urlMapping='/RAFMobileAccount/*')

global class RAFMobileAccountApi {
 @HttpGet
    global static Account getAccountDetails(){
        RestRequest req = RestContext.request;
        String accountSFId = req.params.get('accId');
        Account acc = [SELECT BillingCountryCode, Unique_Referral_Code__c FROM Account WHERE Id =: accountSFId][0];
        return acc;
    }
}