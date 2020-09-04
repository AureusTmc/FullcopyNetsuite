global class SageApplyARPaymentBatch implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    Set<string> invoiceIds;
    public SageApplyARPaymentBatch(){}
    
    public SageApplyARPaymentBatch(Set<string> invIds){
        invoiceIds = invIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        if(invoiceIds!=null && invoiceIds.size()>0){
            return database.getQueryLocator([Select id,Name,Invoice_Date__c,SageInvoiceKey__c,Sage_AR_Payment_Applied__c,Sage_Error_Message__c,Discount_Amount__c,center__r.Organisation__r.Sage_Company__c,(Select id,MovedToSage__c from Payments__r) from Invoice__c where Id=:invoiceIds and MovedToSage__c=true and SageInvoiceKey__c!=null and Sage_AR_Payment_Applied__c=false and Status__c='Paid' and Discount_Amount__c>0]);
        }else{
            return database.getQueryLocator([Select id,Name,Invoice_Date__c,SageInvoiceKey__c,Sage_AR_Payment_Applied__c,Sage_Error_Message__c,Discount_Amount__c,center__r.Organisation__r.Sage_Company__c,(Select id,MovedToSage__c from Payments__r) from Invoice__c where MovedToSage__c=true and SageInvoiceKey__c!=null and Sage_AR_Payment_Applied__c=false and Status__c='Paid' and Discount_Amount__c>0]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> InvList){
        if(invList.size()>0){
            for(Invoice__c inv:invList){
                if(inv.payments__r.size()>0){
                    Boolean paymentMovedToSage = true;
                    for(Payment__c pay:inv.payments__r){
                        if(!pay.MovedToSage__c){
                            paymentMovedToSage = false;
                            break;
                        }
                    }
                    If(paymentMovedToSage){
                        SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(inv.center__r.Organisation__r.Sage_Company__c);
                        
                        SageIntacctIntegrationUtility.resultWrapper rw = SageIntacctIntegrationUtility.applyARPayment(sw,inv);
                        if(rw.isSuccess){
                            inv.Sage_AR_Payment_Applied__c = true;
                        }else{
                            inv.Sage_Error_Message__c = rw.errorMsg;
                        }
                    }
                }
            }
            update invList;
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SageApplyARPaymentBatch(),Integer.valueOf(label.SageBatchSize));
    }
}