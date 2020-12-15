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
     global String  errorDesciption;
     global PostInvoiceBatch(){
        enroledStatus = ConstantsClass.enroledStatus;
        enrolRegularType = ConstantsClass.enrolRegularStatus;
        noOfRecords  = 0;
        startTime = system.now();
        errorDesciption = '';
         enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
         enrolmentIds = new Set<String>();
     }
    public PostInvoiceBatch(Set<string> enrolIds){
        enrolmentIds = enrolIds;
        enroledStatus = ConstantsClass.enroledStatus;
        enrolRegularType = ConstantsClass.enrolRegularStatus;
        noOfRecords  = 0;
        startTime = system.now();
        errorDesciption = '';
         enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        
    }
    // added by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
    public PostInvoiceBatch(Set<string> enrolIds,DateTime startingDate){
      enrolmentIds = enrolIds;
      enroledStatus = ConstantsClass.enroledStatus;
      enrolRegularType = ConstantsClass.enrolRegularStatus;
      noOfRecords  = 0;
      startTime = startingDate;
      errorDesciption = '';
       enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
  }
     global Database.QueryLocator start(Database.BatchableContext BC){
        string queryString = 'SELECT Id, Student__c, Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
         queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
         queryString+= ' Type__c, Class__c,New_Class__c  FROM Enrolment__c ';
         queryString+= ' WHERE Type__c In: enrolTypes ';
         queryString+= ' AND Stage__c =: enroledStatus ';
         queryString+= ' AND Lessons_Start_Date__c <= THIS_MONTH ';
         if(enrolmentIds != null && enrolmentIds.size() > 0){
            queryString+= ' And Id IN: enrolmentIds';
         }
        return Database.getQueryLocator(queryString);
        /* commented by nishi:6-Oct-2020
        return Database.getQueryLocator([SELECT Id, Student__c, Center__c, Center__r.Name, Teacher__c, Package__c,
                                          Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,
                                          Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name,
                                          Package_Process_Type__c, Package_Process_Request_Date__c, 
                                          New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,
                                          New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,
                                          New_Centre__c,//added by nishi: 4-sep-2020: for manage change center process 
                                          //Commented by jatin: 9-jan-2020 : For manage  group class in enrolments
                                          Type__c, Class__c,New_Class__c 
                                          FROM Enrolment__c 
                                          WHERE Type__c In: enrolTypes AND
                                          //Commented by jatin: 9-jan-2020 : For manage regular and group type enrolments
                                          //Type__c = :enrolRegularType
                                          Stage__c =: enroledStatus AND 
                                          Lessons_Start_Date__c <= THIS_MONTH AND
                                          Id IN: enrolmentIds]);*/

     }
     
     global void execute(Database.BatchableContext BC, List<Enrolment__c> enrolmentList){
        noOfRecords  += enrolmentList.size();
        system.debug('enrolmentList'+enrolmentList);
         // commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
         //AureusUtility.postInvoiceJobOnEnrolment(enrolmentList);
         Savepoint monthInvoiceSavePoint;
         string enrolIds = getenrolmentListIds(enrolmentList);
         try{
            monthInvoiceSavePoint = Database.setSavepoint();
            AureusUtility.postInvoiceJobOnEnrolment(enrolmentList,startTime.date());
         }catch (Exception e){
            //On 16th December 2020 to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(monthInvoiceSavePoint);
            errorDesciption  += 'enrolIds:'+enrolIds+' : '+e.getStackTraceString()+'-'+e.getMessage() +';';
         }
     }
     
     global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Post-Invoice Batch',startTime,system.now(),noOfRecords,errorDesciption);
     }
     // get enroment ids in string format
     private  string getenrolmentListIds(List<Enrolment__c> enrolmentList){
      set<string> objenrolIds = new set<string>(); 
      for(Enrolment__c objenrol  : enrolmentList){
         objenrolIds.add(objenrol.id);
      }
      return string.join(new List<string>(objenrolIds),', ');
  }
}