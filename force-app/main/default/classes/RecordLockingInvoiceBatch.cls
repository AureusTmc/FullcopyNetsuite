/*
        Name        :    RecordLockingInvoiceBatch
        Date        :    24-Sep-2020
        Author      :  nishi jain
        Description :    This batch class is used to all paid and Void invoices  records as locked that belongs to the previous calendar month  and its line items
        
*/
global class RecordLockingInvoiceBatch  implements Database.Batchable<sObject>,database.stateful{
    global Date startDate;
    global Date endDate;
    global integer noOfRecords;
    
    public RecordLockingInvoiceBatch(Date startDate,date endDate){
        noOfRecords  = 0;
        this.endDate = endDate;
        this.startDate = startDate;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        Set<string> invoiceStatus = new Set<String>{/*ConstantsClass.dueStatus,*/ConstantsClass.paidStatus, ConstantsClass.voidInvoiceStatus};
            
            return Database.getQueryLocator([SELECT Id, Name,Parent_Account__c,Total_Amount__c, Remarks__c,Invoice_Date__c,Parent_Account__r.Centre_Name__c,
                                             Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c,Locked__c,
                                             (SELECT Id, Enrolment__r.id,Enrolment__r.Package_Process_Type__c ,
                                              Enrolment__r.Effective_Date__c ,Package__c,Locked__c
                                              FROM Invoice_Line_Items__r
                                              Where Locked__c = false
                                              //  Month__c >=: startDate 
                                              //AND Month__c <=: endDate
                                             ) 
                                             FROM Invoice__c 
                                             WHERE invoice_date__C >=: startDate 
                                             AND invoice_date__C <=: endDate 
                                             AND Locked__c = false
                                             AND Status__c In: invoiceStatus]);
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> invoiceList){
        noOfRecords += invoiceList.size();
        List<Invoice_Line_Item__c> listOfUpdatedLineItem = new  List<Invoice_Line_Item__c>();
        if(invoiceList != null && invoiceList.size()  > 0){
            for(Invoice__c objInvoice : invoiceList){
                objInvoice.Locked__c = true;
                if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() >0){
                    for(Invoice_Line_Item__c objInvoice_Line_Item :  objInvoice.Invoice_Line_Items__r){
                        objInvoice_Line_Item.Locked__c = true;
                        listOfUpdatedLineItem.add(objInvoice_Line_Item);
                    }
                } 
            }
            update invoiceList;
            if(listOfUpdatedLineItem != null && listOfUpdatedLineItem.size() > 0){
                update listOfUpdatedLineItem;
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Invoice Record Locking Batch',system.now(),system.now(),noOfRecords);
    }
    
}