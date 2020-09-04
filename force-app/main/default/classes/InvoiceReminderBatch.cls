/*
        Name        :    InvoiceReminderBatch
        Date        :    04/03/2019
        Author      :  
        Description :    This batch class is used to send reminder after some time of due date.
        
*/
global class InvoiceReminderBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    private Integer noOfDays;
    global DateTime startTime;
    global integer noOfRecords;
    
    public InvoiceReminderBatch(Integer days){
        noOfDays = days * -1;
        noOfRecords  = 0;
        startTime = system.now();
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date preDate = system.today().addDays(noOfDays);
        return Database.getQueryLocator([SELECT Id,Due_Date__c,Parent_Account__c,Parent_Account__r.PersonEmail,Parent_Account__r.Phone,
                                         Parent_Account__r.personContactId
                                         FROM Invoice__c
                                         WHERE Due_Date__c < today and Due_Date__c =:preDate and Status__c = 'Due']);
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> invoiceList){
        noOfRecords += invoiceList.size();
        BillingUtility.sendDeclinedMail(invoiceList,''+noOfDays);
    }

    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Invoice Reminder Batch',startTime,system.now(),noOfRecords);
    }
    
}