global class SageFetchARInvoiceKey implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
	Set<String> invoiceIds;
	
    public SageFetchARInvoiceKey(Set<string> invIds){
        invoiceIds = invIds;
    }
    
    public SageFetchARInvoiceKey(){}
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        If(invoiceIds!=null && invoiceIds.size()>0){
            return Database.getQueryLocator([Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id in:invoiceIds and MovedToSage__c=true and SageOrderEntryKey__c!=null and  SageInvoiceKey__c=null]);
        }else{
            return Database.getQueryLocator([Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where MovedToSage__c=true and SageOrderEntryKey__c!=null and  SageInvoiceKey__c=null]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> Invoices){
        if(Invoices!=null && Invoices.size()>0){
            List<Invoice__c> updInvList = new List<Invoice__c>();
            for(Invoice__c inv:Invoices){
				SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(inv.center__r.Organisation__r.Sage_Company__c);
				string status;
				if(inv.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
					status = SageIntacctIntegrationUtility.fetchVATprocessStatus(sw,inv.Name);
				}else{
					status = 'Complete';
				}
				Invoice__c invToUpdate = new Invoice__c();
				invToUpdate.Id = inv.Id;
				If(status=='Complete'){	
					
					SageIntacctIntegrationUtility.resultWrapper rrw = SageIntacctIntegrationUtility.fetchARInvoiceKey(sw,inv.SageOrderEntryKey__c);
					if(rrw.isSuccess){
						invToUpdate.SageInvoiceKey__c = rrw.sageRecordKey;
					}else{
						invToUpdate.Sage_Error_Message__c = rrw.errorMsg;
					}
				}else{
					invToUpdate.Sage_Error_Message__c = status;
				}
				updInvList.add(invToUpdate);
            }
            update updInvList;
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global void execute(SchedulableContext sc) {
		Database.executeBatch(new SageFetchARInvoiceKey(),Integer.valueOf(label.SageBatchSize));
    }
    
}