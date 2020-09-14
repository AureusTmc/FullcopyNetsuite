@RestResource(urlMapping='/RAFMobileEnrolment/*')

global class RAFMobileEnrolmentApi {
 @HttpGet
    global static List<Enrolment__c> getEnrolmentDetails(){
        RestRequest req = RestContext.request;
        String accountSFId = req.params.get('accId');
        List<Enrolment__c> enrolList = [Select referrer_discount_amount__c,parent_first_name__c, parent_last_name__c, type__c, stage__c, enrolment_created_date__c, parent__c from enrolment__c where referred_by__c=: accountSFId AND type__c='Regular' AND stage__c='Enrolled'];
        return enrolList;
    }
}