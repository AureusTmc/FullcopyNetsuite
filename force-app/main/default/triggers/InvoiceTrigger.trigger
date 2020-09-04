/*
        Name        :    InvoiceTrigger
        Date        :    4/02/2019
        Description :      
*/

trigger InvoiceTrigger on Invoice__c (After Update, Before Insert , After Insert ) {
    
    Set<String> setOfInvoice = new Set<String>();
    Set<String> setOfRefundInvoice = new Set<String>();
    Map<String,String> mapOfStatusInvoice = new Map<String,String> ();
    Firebase_Settings__c settings = Firebase_Settings__c.getValues('setting');
    
    //Invoices to change their names Before Insert
    List<Invoice__c> invoicesForUpdatedNames = new List<Invoice__c>();
    List<Invoice__c> Inv = new List<Invoice__c>();
    
    if(Trigger.isAfter){
        if(trigger.isUpdate){
            for(Invoice__c invoice : Trigger.new){
                if(invoice.Gross_Total__c != NULL && invoice.Gross_Total__c != Trigger.oldMap.get(invoice.Id).Gross_Total__c){
                    setOfInvoice.add(invoice.Id);
                }
                /*
                    Fill the Set of Invoice Id's where the total amount of amount is less than zero. Means It is a case of refund.
                */
                if(invoice.Total_Amount__c != Trigger.oldMap.get(invoice.Id).Total_Amount__c && invoice.Total_Amount__c < 0){
                    setOfRefundInvoice.add(invoice.Id); 
                }
                //@@NISHI:(Date: 26-JUL-2019) : for check is Invoice Status = Paid then send notifiction
                if(invoice.Status__c!= Trigger.oldMap.get(invoice.Id).Status__c && invoice.Status__c =='Paid' && settings.Enable_Notifications__c){
                    mapOfStatusInvoice.put(invoice.Id,invoice.Parent_Account__c); 
                }
                
            }
            if(setOfInvoice.size() > 0){
                InvoiceTriggerHelper.getAdminFees(setOfInvoice);
            }
            if(setOfRefundInvoice.size() > 0){
                InvoiceTriggerHelper.createRefundTask(setOfRefundInvoice);
            }
            if(mapOfStatusInvoice.size() > 0 && mapOfStatusInvoice != null){
                InvoiceTriggerHelper.procesStatusInvoice(mapOfStatusInvoice);
            }
            
        }
    }
    //Fill the list of Invoices Before Insert 
    if(trigger.isBefore && trigger.isInsert){
         for(Invoice__c invoice : Trigger.new){
             invoicesForUpdatedNames.add(invoice);
         }
    }
    
    //Pass the list of Invoice to the InvoiceTriggerHelper
    if(invoicesForUpdatedNames.size() > 0){
        InvoiceTriggerHelper.fillInvoiceName(invoicesForUpdatedNames);
    }
    
    // update the Fields Internal Reference no. in invoice obj and Ref no field in Country obj .
     // added by zakir dated 22-10-2019
    if(trigger.isAfter && trigger.isinsert){
           InvoiceTriggerHelper.updateReferenceNo(Trigger.new);
    }
     
    
}