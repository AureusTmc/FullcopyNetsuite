global class EmployeeRosteringBatch implements Database.Batchable<sObject> {
global Set<Id> accountIdSet = new Set<Id>();
global Integer setupRosteringForMonths = 3;
global Date startDate = Date.today();

    // constructor defination
    global EmployeeRosteringBatch(){ }
    global EmployeeRosteringBatch(Integer setupRosteringForMonths){ this.setupRosteringForMonths = setupRosteringForMonths; }
    global EmployeeRosteringBatch(Set<Id> accountIdSet){ this.accountIdSet = accountIdSet;}
    global EmployeeRosteringBatch(Set<Id> accountIdSet, Date startDate){ this.accountIdSet = accountIdSet; this.startDate = startDate;}
    global EmployeeRosteringBatch(Set<Id> accountIdSet, Integer setupRosteringForMonths){ this.accountIdSet = accountIdSet; this.setupRosteringForMonths = setupRosteringForMonths;}
    global EmployeeRosteringBatch(Set<Id> accountIdSet, Date startDate, Integer setupRosteringForMonths){ this.accountIdSet = accountIdSet; this.startDate = startDate; this.setupRosteringForMonths = setupRosteringForMonths;}
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'Select Id, Name, Main_Centre__c FROM Account WHERE Employee_Status__c in (\'Probation\',\'Confirm\') and (recordType.Name=\'Employee\') ';
        // commmented by arpit  13-dec-2019    
        //query += 'or recordType.Name=\'Teacher\') ';    
        if(!accountIdSet.isEmpty()){
            query += ' AND Id IN: accountIdSet';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<SObject> records){
        EmployeeRosteringBatchHandler.generateRostering(records, setupRosteringForMonths, startDate );
    }    
    
    global void finish(Database.BatchableContext bc){}  
}