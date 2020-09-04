/*
        Name           :    PackageFeeBatch
        Date           :    04/25/2019
        Description    :    This batch class update amount on all Subscription Line Item when amount is changed on the package
*/
global class PackageFeeBatch implements Database.Batchable<sObject>,database.stateful{
    global DateTime startTime;
    global integer noOfRecords;
    global Set<String> setOfPackIds;
    
    global PackageFeeBatch (Set<String> setOfPackIds){
        noOfRecords  = 0;
        startTime = system.now();
        this.setOfPackIds = setOfPackIds;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id,Amount__c,Plan_Package__c,Plan_Package__r.Package_Fee__c FROM Subscription_Line_Item__c WHERE Plan_Package__c IN: setOfPackIds]);                                
    }
    
    global void execute(Database.BatchableContext BC, List<Subscription_Line_Item__c> listOfLineItems){
        noOfRecords += listOfLineItems.size();
        for(Subscription_Line_Item__c objLineItem : listOfLineItems){
            objLineItem.Amount__c =  objLineItem.Plan_Package__r.Package_Fee__c; 
            
        }
        
        UPDATE listOfLineItems;
    }
    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('PackageFeeBatch',startTime,system.now(),noOfRecords);
    }
}