public class EmployeeWorkWeekTrigerHandler{

    /*  Employee Work Week - Functionality Description - Create Rostering record when a Employee Work Week record create/Update.*/
    Id employeeRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    List<Employee_Work_Week__c> newList = new List<Employee_Work_Week__c >();
    Map<Id,Employee_Work_Week__c> oldMap = new Map<Id,Employee_Work_Week__c>();
    Integer rosteringForNumberofMonth = 3;
    
    public void EmployeeWorkWeekAfterInsert(){
        newList = (List<Employee_Work_Week__c>) trigger.new;
        oldMap = (Map<Id,Employee_Work_Week__c>)trigger.oldMap;
        EmployeeWorkWeekRosteringSetup();
    }
    public void EmployeeWorkWeekAfterUpdate(){
        newList = (List<Employee_Work_Week__c>) trigger.new;
        oldMap = (Map<Id,Employee_Work_Week__c>)trigger.oldMap;
        EmployeeWorkWeekRosteringSetup();
    }
    public void EmployeeWorkWeekAfterDelete(){
        newList = (List<Employee_Work_Week__c>) trigger.old;
        oldMap = null;
        EmployeeWorkWeekRosteringSetup();
    }
    public void EmployeeWorkWeekAfterUnDelete(){
        newList = (List<Employee_Work_Week__c>) trigger.new;
        oldMap = null;
        EmployeeWorkWeekRosteringSetup();
    }
    
    
    public void EmployeeWorkWeekRosteringSetup(){
        Set<Id> accountIdSet = new Set<Id>();
        // Pre process of data
        for(Employee_Work_Week__c eww : newList){
            if((oldMap == null || oldMap != null && (oldMap.get(eww.Id).Effective_Date__c != eww.Effective_Date__c || oldMap.get(eww.Id).Working_Days_in_a_Week__c != eww.Working_Days_in_a_Week__c))){
                accountIdSet.add(eww.Employee__c);
            }
        }
        if(!accountIdSet.isEmpty()){
            Id jobId = Database.executeBatch(new EmployeeRosteringBatch(accountIdSet, rosteringForNumberofMonth), 200);
        }
    }
}