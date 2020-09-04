/*
        Name        :    PostInvoiceBatch
        Date        :    06/28/2019
        Author      :  
        Description :    This batch class is used for the following:
                         1. Perform Advance Actions like:
                             A. Upgrade Enrolment
                             B. Downgrade Enrolment
                             C. Withdrawal of Enrolment
                             D. Change of Enrolment
                         2. creating 13th Month Bookings
        
*/
global class PostInvoiceBatch implements Database.Batchable<sObject>, database.stateful{
     global DateTime startTime;
     global integer noOfRecords;
     global String enroledStatus;
     global Set<String> enrolTypes;
     global String enrolRegularType;
     global Set<String> enrolmentIds;
     global PostInvoiceBatch(){
        enroledStatus = ConstantsClass.enroledStatus;
        enrolRegularType = ConstantsClass.enrolRegularStatus;
        noOfRecords  = 0;
        startTime = system.now();
         enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        
     }
    public PostInvoiceBatch(Set<string> enrolIds){
        enrolmentIds = enrolIds;
        enroledStatus = ConstantsClass.enroledStatus;
        enrolRegularType = ConstantsClass.enrolRegularStatus;
        noOfRecords  = 0;
        startTime = system.now();
         enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        
    }
     global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Student__c, Center__c, Center__r.Name, Teacher__c, Package__c,
                                          Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,
                                          Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name,
                                          Package_Process_Type__c, Package_Process_Request_Date__c, 
                                          New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,
                                          New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,
                                          //Commented by jatin: 9-jan-2020 : For manage  group class in enrolments
                                          Type__c, Class__c,New_Class__c 
                                          FROM Enrolment__c 
                                          WHERE Type__c In: enrolTypes AND
                                          //Commented by jatin: 9-jan-2020 : For manage regular and group type enrolments
                                          //Type__c = :enrolRegularType
                                          Stage__c =: enroledStatus AND 
                                          Lessons_Start_Date__c <= THIS_MONTH AND
                                          Id IN: enrolmentIds]);
     }
     
     global void execute(Database.BatchableContext BC, List<Enrolment__c> enrolmentList){
        noOfRecords  += enrolmentList.size();
        system.debug('enrolmentList'+enrolmentList);
        AureusUtility.postInvoiceJobOnEnrolment(enrolmentList);
     }
     
     global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Post-Invoice Batch',startTime,system.now(),noOfRecords);
     }
}