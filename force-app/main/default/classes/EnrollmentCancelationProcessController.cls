public class EnrollmentCancelationProcessController{
    public Enrolment__c enrollmentObj{get;set;}
    public List<Enrolment__c> enrollmentList{get;set;}
    public EnrollmentCancelationProcessController(){
        String id = ApexPages.currentPage().getParameters().get('id');
        //system.debug('ID = '+id);
        
        if(String.isNotBlank(id)){
            enrollmentObj = new Enrolment__c();
            enrollmentList = [SELECT id, Reason_of_Withdraw__c,Package__r.Name,Parent__r.Name,Student__r.Name, Feedback_Comments__c, 
                                Lesson_Day__c,Refund_Method__c,Lesson_Start_Time__c, 
                          Notice_Period_Start_Date__c, Notice_Period_End_Date__c 
                          FROM Enrolment__c WHERE id =: id];
            
            if(enrollmentList.size() > 0){
                enrollmentObj = enrollmentList[0];
            } 
        System.debug('enrollmentList = '+enrollmentList);
        }
    }
    public pageReference saveEnrollment(){
        if(enrollmentList.size() > 0){
            update enrollmentObj;
        }
        PageReference pageRef = new pageReference('/apex/thankyouPage');
        return pageRef;
    }
}