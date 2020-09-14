@RestResource(urlMapping='/RAFMobileBaseURL/*')

global class RAFMobileBaseURLApi {
 @HttpGet
    global static String getBaseURL(){
        rafurl__c obj = [SELECT URLraf__c FROM rafurl__c WHERE Name= 'BaseURL'][0];
        return obj.URLraf__c;
    }
}