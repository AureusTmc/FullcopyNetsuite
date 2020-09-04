global class SageInvoicePushBatch implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    Set<String> invoiceIds;
    
    public SageInvoicePushBatch(Set<string> invIds){
        invoiceIds = invIds;
    }
    
    public SageInvoicePushBatch(){}
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date cutOverDate = Date.newInstance(Integer.valueOf(label.SageCutoverYear),Integer.valueOf(label.SageCutoverMonth),1);
        If(invoiceIds!=null && invoiceIds.size()>0){
            return Database.getQueryLocator([Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Invoice_Date__c>=:cutOverDate and MovedToSage__c=False and Id in:invoiceIds/* and Status__c not in ('void','Cancelled')*/]);
        }else{
            return Database.getQueryLocator([Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Invoice_Date__c>=:cutOverDate and MovedToSage__c=False/* and Status__c not in ('void','Cancelled')*/]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> Invoices){
        if(Invoices!=null && Invoices.size()>0){
            //SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID();
            SageIntacctIntegrationUtility.sessionWrapper sw = null;
            
            List<Invoice__c> updInvList = new List<Invoice__c>();
            for(Invoice__c inv:Invoices){
                inv = SageIntacctIntegrationUtility.createInvoice(sw,inv);
                Invoice__c invToUpdate = new Invoice__c();
                invToUpdate.Id = inv.Id;
                invToUpdate.MovedToSage__c = inv.MovedToSage__c;
                invToUpdate.SageInvoiceKey__c = inv.SageInvoiceKey__c;
                invToUpdate.SageOrderEntryKey__c = inv.SageOrderEntryKey__c;
                invToUpdate.Sage_Error_Message__c = inv.Sage_Error_Message__c;
                updInvList.add(invToUpdate);
                
            }
            update updInvList;
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global void execute(SchedulableContext sc) {
		Database.executeBatch(new SageInvoicePushBatch(),Integer.valueOf(label.SageBatchSize));
    }
}