public class ServiceRequestCancellationClass {
    
    
    /*
    Name        :        ServiceRequestCancellationClass
    Author      :        Ravi Gupta
    Description :        It is the  class of .ServiceRequestCancellation
    */
    private static string serviceEnquiryRecordType=ConstantsClass.caseServiceEnqRecTypeName;
    
	@AuraEnabled
    public static list<Case> findCase(string searchKey){
         Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(serviceEnquiryRecordType).getRecordTypeId();
        list<Case> caseList =[SELECT Id,X24_Hrs_Cancellation_Request__c,Booking__c,Booking__r.Teacher_Account__r.Name,Booking__r.Teacher_Account__c,Booking__r.Start_Time__c,RecordTypeId,Booking__r.Name,Booking__r.Booking_Date__c,Booking__r.Parent__r.Name,Booking__r.Student__r.Name,Booking__r.Package__r.Name,Booking__r.Center__r.Name,Booking__r.Instrument__c,Booking__r.Status__c,Booking__r.Cancellation_Reason__c   FROM Case where Id=:searchKey AND RecordTypeId=:recorId AND (Subject='Lesson Cancellation within 24 hrs' OR Subject='Lesson Cancel within 24 hrs') AND Type='Lesson Cancel' AND Booking__c != null ];
        return caseList;
     
    }
    
    @AuraEnabled
    public static void updateCaseRequest(string actVal,string casId){
          list<Case> caseList = new list<Case>();
        
        if(actVal =='Confirm'){
            for(Case casobj:[SELECT Id,X24_Hrs_Cancellation_Request__c FROM Case WHERE Id=:casId ]){
                casobj.X24_Hrs_Cancellation_Request__c='Approved';
                casobj.X24_hrs_cancellation_approved_Reject_by__c=UserInfo.getUserId();
                caseList.add(casobj);                              
            }
            
        }else{
            for(Case casobj:[SELECT Id,X24_Hrs_Cancellation_Request__c FROM Case WHERE Id=:casId ]){
                casobj.X24_Hrs_Cancellation_Request__c='Rejected';
                casobj.X24_hrs_cancellation_approved_Reject_by__c=UserInfo.getUserId();
                caseList.add(casobj);                              
            }
        }
        if(caseList.size()>0){
            update caseList;   
        }
        
    }
}