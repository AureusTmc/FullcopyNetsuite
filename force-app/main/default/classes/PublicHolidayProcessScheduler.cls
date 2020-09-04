global class PublicHolidayProcessScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      PublicHolidayProcess b = new PublicHolidayProcess(); 
       
       for(Public_Holiday__c holidayObj : [SELECT Id,Organisation__c,Name,Public_Holiday_Date__c,Organisation_Status__c,Execution_Date__c,Status__c FROM Public_Holiday__c where Organisation_Status__c != null and Execution_Date__c = today and Status__c='Pending for execution' and Public_Holiday_Date__c <> null ]){ 
                       b.holidayDate.add(holidayObj.Public_Holiday_Date__c);
                       b.organisationId.add(holidayObj.Organisation__c);
                             
           }
       database.executebatch(b,100);
      
   }
}