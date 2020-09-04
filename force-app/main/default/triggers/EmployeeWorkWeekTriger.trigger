trigger EmployeeWorkWeekTriger on Employee_Work_Week__c (after insert, after update, after delete, after unDelete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            new EmployeeWorkWeekTrigerHandler().EmployeeWorkWeekAfterInsert();
        }
        if(Trigger.isUpdate){
            new EmployeeWorkWeekTrigerHandler().EmployeeWorkWeekAfterUpdate();
        }
        if(Trigger.isDelete){
            new EmployeeWorkWeekTrigerHandler().EmployeeWorkWeekAfterDelete();
        }
        if(Trigger.isunDelete){
            new EmployeeWorkWeekTrigerHandler().EmployeeWorkWeekAfterUnDelete();
        }
    }
}