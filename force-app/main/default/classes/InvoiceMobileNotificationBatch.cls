/*
        Name        :    InvoiceMobileNotificationBatch
        Date        :    02/Aug/2019
        Author      :    Nishi
        Description :    This batch class is used in InvoiceMobileNotificationSchedular to  check Invoice Status is
                         'Due' and Invoice_Due_Date is less than today and Invoice_month is this_month 
                         then send  reminder notification after  3, 5 and 7 days.
        
*/
global class InvoiceMobileNotificationBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    private Integer noOfDays;
    public InvoiceMobileNotificationBatch (Integer days){
        noOfDays = days;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date preDate = system.today().addDays(noOfDays);
        system.debug('preDate'+preDate);
        return Database.getQueryLocator([SELECT Id,name,Due_Date__c,Parent_Account__c,Parent_Account__r.FCM_Token__c
                                         FROM Invoice__c
                                         WHERE Due_Date__c <:preDate 
                                         and Status__c =: ConstantsClass.dueStatus 
                                         and Invoice_Date__c = THIS_MONTH
                                         AND Parent_Account__r.FCM_Token__c !=null]);
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> invoiceList){
       List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
        for(Invoice__c invoiceObj: invoiceList){
                String  title =  invoiceObj.Name+ ' is now Overdue';
                 String  bodymsg = 'Please note that '+invoiceObj.Name+' is now overdue. Click here to view the invoice and make payment.';
                 String to = invoiceObj.Parent_Account__r.FCM_Token__c;
                 // Check if we get Mobile_Notification__c record then add in list. If we get null then skip this record. 
                  Mobile_Notification__c log = FirebaseNotificationHelper.sendNotificationBatch(invoiceObj.Parent_Account__c, to, title, bodymsg);
                  if(log != null)
                        listOfMobileNotification.add(log); 
               }
        if(listOfMobileNotification.size() > 0 && listOfMobileNotification!= Null){
            insert listOfMobileNotification;
        }
    }

    global void finish(Database.BatchableContext BC){
    }
    
}