public class EnrolmentController {

    @AuraEnabled
    public static List<Enrolment__c> findEnrolment(string email){
        list<Enrolment__c> enrList = new list<Enrolment__c>();
        if(email<>''){
            String searchKey = '%' + email + '%';
            enrList = new list<Enrolment__c>([select id,Name,Parent__r.Name,Parent__r.PersonEmail from Enrolment__c Where Type__c='Trial' AND Stage__c='Requested' AND Parent__r.PersonEmail Like :searchKey]);      
        }
        return enrList;
          
    }
}