global class LeaveRequestScheduler implements Schedulable {
    // Scheduler is called basically when leave start date is either less than 35 or is 35 and recordtype is any of the (Paid_Leave,Child_Care_Leave,Extended_Child_Care_Leave,Other_Leave,NSMen_Leave) 
   global void execute(SchedulableContext sc) {
       Id paidRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
       Id childkRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Child_Care_Leave').getRecordTypeId();
       Id extendedRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Extended_Child_Care_Leave').getRecordTypeId();    
       Id otherRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
       Id nationalServiceRecord = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('NSMen_Leave').getRecordTypeId();
       List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
       for(Leave_Request__c leaveObj : [SELECT Id,Leave_End_Date__c,Sick_leave_start_Time__c,Employee__c,Calendar_Update_Process__c,Status__c,Leave_Start_Date__c,RecordTypeId FROM Leave_Request__c where Status__c ='Approved' and Calendar_Update_Process__c =false and Leave_Start_Date__c>=today order by Leave_Start_Date__c Asc]){ 
         
           if(System.today().daysBetween(leaveObj.Leave_Start_Date__c) <=  Integer.valueOf(Label.Leave_Minimum_Due_No)  && (leaveObj.RecordTypeId==nationalServiceRecord || leaveObj.RecordTypeId==paidRecordTypeId || 
                                                                                  leaveObj.RecordTypeId==childkRecordTypeId || leaveObj.RecordTypeId==extendedRecordTypeId ||
                                                 								  leaveObj.RecordTypeId==otherRecordTypeId)){
               leaveReqList.add(leaveObj);
			   break;
           } 
       }
       if(leaveReqList.size()>0){
          LeaveRequestHelper.sickLeave(leaveReqList); 
       }
   }
}