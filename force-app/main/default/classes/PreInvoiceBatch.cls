/*
        Name        :    PreInvoiceBatch
        Date        :    06/26/2019
        Author      :  
        Description :    1. change status of current Month Bookings
                         2. 5th weekday booking of month, if weekday occur 
        
*/
global class PreInvoiceBatch implements Database.Batchable<sObject>, database.stateful{
     //variable(s)
     global String enroledStatus;
     global String enrolRegularType;
     global Set<String> enrolTypes;
     
     global DateTime startTime;
     global integer noOfRecords;
    //Constructor
     global PreInvoiceBatch(){
         enroledStatus = ConstantsClass.enroledStatus;
         //Commented by jatin: 9-jan-2020 : For manage regular and group type enrolments
         //enrolRegularType = ConstantsClass.enrolRegularStatus;
         
         enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
         noOfRecords  = 0;
         startTime = system.now();
     }
     
     global Database.QueryLocator start(Database.BatchableContext BC){
                                           
      return Database.getQueryLocator([SELECT Id, Student__c, Center__c, Center__r.Location__c, Center__r.Name, Teacher__c, Package__c,
                                         Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,
                                         Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, Parent__r.personContactId, 
                                         Package_Process_Type__c, Package_Process_Request_Date__c, 
                                         New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,
                                         New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,
                                         Type__c ,Teacher__r.Engagement_Type__c,
                                         Center__r.Organisation__r.Name,Available_Make_up_mins__c // added by nishi : 13-Aug-2020:for ossia organisation requirement
                                         FROM Enrolment__c 
                                         WHERE Type__c In: enrolTypes AND
                                         //Commented by jatin: 9-jan-2020 : For manage regular and group type enrolments
                                         //Type__c = :enrolRegularType 
                                         Stage__c =: enroledStatus 
                                         AND Lessons_Start_Date__c < THIS_MONTH
                                        ]);
     }
     
     global void execute(Database.BatchableContext BC, List<Enrolment__c> enrolmentList){
        noOfRecords  += enrolmentList.size();
        system.debug('enrolmentList'+enrolmentList);
        AureusUtility.preInvoiceJobOnEnrolment(enrolmentList);   
        
     }
     
     global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Pre-Invoice Batch',startTime,system.now(),noOfRecords);
     }
}