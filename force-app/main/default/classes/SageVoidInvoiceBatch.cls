global class SageVoidInvoiceBatch implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    Set<String> invoiceIds;
    
    public SageVoidInvoiceBatch(Set<string> invIds){
        invoiceIds = invIds;
    }
    
    public SageVoidInvoiceBatch(){}
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date cutOverDate = Date.newInstance(Integer.valueOf(label.SageCutoverYear),Integer.valueOf(label.SageCutoverMonth),1);
        If(invoiceIds!=null && invoiceIds.size()>0){
            return Database.getQueryLocator([Select id, Parent_Account__r.personContactId ,Center__r.Location__c,SageInvoiceKey__c,Voided_on_Sage__c,Sage_Error_Message__c,Invoice_Date__c,Remarks__c,Center__r.Organisation__r.Sage_Company__c from Invoice__c where SageInvoiceKey__c!=null and Invoice_Date__c>=:cutOverDate and Id in:invoiceIds and Status__c in ('Void','Cancelled') and Voided_on_Sage__c=false]);
        }else{
            return Database.getQueryLocator([Select id, Parent_Account__r.personContactId ,Center__r.Location__c,SageInvoiceKey__c,Voided_on_Sage__c,Sage_Error_Message__c,Invoice_Date__c,Remarks__c,Center__r.Organisation__r.Sage_Company__c from Invoice__c where SageInvoiceKey__c!=null and Invoice_Date__c>=:cutOverDate and Status__c in ('Void','Cancelled') and Voided_on_Sage__c=false]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> Invoices){
        if(Invoices!=null && Invoices.size()>0){
            //SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID();
            /*SageIntacctIntegrationUtility.sessionWrapper sw = null;
            
            List<Invoice__c> updInvList = new List<Invoice__c>();
            for(Invoice__c inv:Invoices){
                inv = SageIntacctIntegrationUtility.reverseInvoice(sw,inv);
                Invoice__c invToUpdate = new Invoice__c();
                invToUpdate.Id = inv.Id;
                invToUpdate.Voided_on_Sage__c = inv.Voided_on_Sage__c;
                invToUpdate.Sage_Error_Message__c = inv.Sage_Error_Message__c;
                updInvList.add(invToUpdate);
                
            }*/
            
            SageIntacctIntegrationUtility.sessionWrapper sw = null;
            List<Invoice__c> updInvList = new List<Invoice__c>();
            Set<Id> invoiceIds = new map<id,Invoice__c>(Invoices).KeySet();
            Map<string,Boolean> mapOfInvoiceIsPromoPrepayemnt = VoidInvoiceController.checkInvoiceIsPromoPrepayemnt(invoiceIds);
            system.debug('mapOfInvoiceIsPromoPrepayemnt'+mapOfInvoiceIsPromoPrepayemnt);
            if(mapOfInvoiceIsPromoPrepayemnt != null && mapOfInvoiceIsPromoPrepayemnt.size() > 0){
                for(Invoice__c inv:Invoices){
                    /* Jatin:6-mar-2020:Start: check that if the invoice type is prepayment and promo 
                                    then we will not send the info to sage 
                                    instead of that we will send the email to the customer
                                    other wise we call sage function and update invoice */
                    if(!mapOfInvoiceIsPromoPrepayemnt.containsKey(inv.id) || !mapOfInvoiceIsPromoPrepayemnt.get(inv.id)){
                        inv = SageIntacctIntegrationUtility.invoiceVoid(sw,inv.Id, false);
                        Invoice__c invToUpdate = new Invoice__c();
                        invToUpdate.Id = inv.Id;
                        invToUpdate.Voided_on_Sage__c = inv.Voided_on_Sage__c;
                        invToUpdate.Sage_Error_Message__c = inv.Sage_Error_Message__c;
                        invToUpdate.SageCreditMemoOrderEntryKey__c = inv.SageCreditMemoOrderEntryKey__c;
                        updInvList.add(invToUpdate);
                    }
                }
                
                if(updInvList != null && updInvList.size() > 0){
                    update updInvList;
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SageVoidInvoiceBatch(),Integer.valueOf(label.SageBatchSize));
    }
}