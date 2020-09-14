@RestResource(urlMapping='/RAFMobileDiscountAmount/*')

global class RAFMobileDiscountAmountApi {
 @HttpGet
    global static List<Referral_Discount__c> getDiscountAmount(){
        RestRequest req = RestContext.request;
        String countryCode = '%'+req.params.get('country')+'%';
        List<Referral_Discount__c> objList = [SELECT Name,Discount_Amount_Referrer_wGST__c , Default__c, Start_Date__c, End_Date__c FROM Referral_Discount__c WHERE Active__c= 'Yes' AND Name LIKE :countryCode];
        return objList;
    }
}