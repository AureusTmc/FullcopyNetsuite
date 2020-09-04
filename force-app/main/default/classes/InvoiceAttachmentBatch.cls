/*
        Class Name    :    InvoiceAttachmentBatch 
        Date          :    05/13/2019
        Description   :    This Batch helps to create attachment for Invoices.

*/

global class InvoiceAttachmentBatch implements Database.Batchable<sObject>, database.stateful{
    Set<String> invoiceIds = new Set<String>();
    global DateTime startTime;
    global integer noOfRecords;
    global Date invoiceDate;
    global InvoiceAttachmentBatch(Set<String> invoiceIds){
        //this.invoiceDate = invoiceDate;
        this.invoiceIds = invoiceIds;
        noOfRecords  = 0;
        startTime = system.now();
    }
    
     global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Name, Parent_Account__c, Parent_Account__r.personContactId FROM Invoice__c WHERE Id IN: invoiceIds]);
    }
    global void execute(Database.BatchableContext BC, List<Invoice__c> invList){
        if(invList.size()>0){
            noOfRecords  += invList.size();
            BillingUtility.createInvoiceAttachment(invList);
        }
    
    }
    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Invoice Attachment batch',startTime,system.now(),noOfRecords);
    }
}