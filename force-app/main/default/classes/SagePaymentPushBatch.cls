global class SagePaymentPushBatch implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    Set<String> recordIds;    
    string objectType;
    
    public SagePaymentPushBatch(string obType,Set<string> recIds){
        recordIds = recIds;
        objectType = obType;
    }
    
    public SagePaymentPushBatch(){}
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date cutOverDate = Date.newInstance(Integer.valueOf(label.SageCutoverYear),Integer.valueOf(label.SageCutoverMonth),1);
        If(recordIds!=null && recordIds.size()>0){
            if(objectType=='Payment'){
                return Database.getQueryLocator([Select Id,Payment_Date__c,Name,Parent_Account__c,Parent_Account__r.Name,Parent_Account__r.AccountID_Customer__c,Payment_Amount__c,Invoice__c,Invoice__r.Name,Invoice__r.Total_Amount__c,Invoice__r.SageInvoiceKey__c,MovedToSage__c,Sage_Error_Message__c,SagePaymentKey__c,Method_of_Payment__c,Invoice__r.Center__r.Organisation__r.Sage_Company__c,recordType.Name,Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Payment__r.SagePaymentKey__c,Parent_Payment__c,Parent_Payment__r.Payment_Amount__c,Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Account__r.Centre_Name__r.Organisation__r.Sage_Company__c,Parent_Account__r.Centre_Name__r.Name,Remarks__c from Payment__c where Payment_Date__c>=:cutOverDate and MovedToSage__c=False and Id in:recordIds and Payment_Status__c='Success' and Payment_Amount__c!=null order by Payment_Amount__c ASC] );
            }else if(objectType=='Invoice'){
                return Database.getQueryLocator([Select Id,Payment_Date__c,Name,Parent_Account__c,Parent_Account__r.Name,Parent_Account__r.AccountID_Customer__c,Payment_Amount__c,Invoice__c,Invoice__r.Name,Invoice__r.Total_Amount__c,Invoice__r.SageInvoiceKey__c,MovedToSage__c,Sage_Error_Message__c,SagePaymentKey__c,Method_of_Payment__c,Invoice__r.Center__r.Organisation__r.Sage_Company__c,recordType.Name,Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Payment__r.SagePaymentKey__c,Parent_Payment__c,Parent_Payment__r.Payment_Amount__c,Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Account__r.Centre_Name__r.Organisation__r.Sage_Company__c,Parent_Account__r.Centre_Name__r.Name,Remarks__c from Payment__c where Payment_Date__c>=:cutOverDate and MovedToSage__c=False and Invoice__c in:recordIds and Payment_Status__c='Success' and Payment_Amount__c!=null order by Payment_Amount__c ASC]);
            }else{
                return Database.getQueryLocator([Select Id,Payment_Date__c,Name,Parent_Account__c,Parent_Account__r.Name,Parent_Account__r.AccountID_Customer__c,Payment_Amount__c,Invoice__c,Invoice__r.Name,Invoice__r.Total_Amount__c,Invoice__r.SageInvoiceKey__c,MovedToSage__c,Sage_Error_Message__c,SagePaymentKey__c,Method_of_Payment__c,Invoice__r.Center__r.Organisation__r.Sage_Company__c,recordType.Name,Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Payment__r.SagePaymentKey__c,Parent_Payment__c,Parent_Payment__r.Payment_Amount__c,Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Account__r.Centre_Name__r.Organisation__r.Sage_Company__c,Parent_Account__r.Centre_Name__r.Name,Remarks__c from Payment__c where Payment_Date__c>=:cutOverDate and MovedToSage__c=False and Payment_Status__c='Success' and Payment_Amount__c!=null order by Payment_Amount__c ASC]);
            }
        }else{
            return Database.getQueryLocator([Select Id,Payment_Date__c,Name,Parent_Account__c,Parent_Account__r.Name,Parent_Account__r.AccountID_Customer__c,Payment_Amount__c,Invoice__c,Invoice__r.Name,Invoice__r.Total_Amount__c,Invoice__r.SageInvoiceKey__c,MovedToSage__c,Sage_Error_Message__c,SagePaymentKey__c,Method_of_Payment__c,Invoice__r.Center__r.Organisation__r.Sage_Company__c,recordType.Name,Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Payment__r.SagePaymentKey__c,Parent_Payment__c,Parent_Payment__r.Payment_Amount__c,Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Account__r.Centre_Name__r.Organisation__r.Sage_Company__c,Parent_Account__r.Centre_Name__r.Name,Remarks__c from Payment__c where Payment_Date__c>=:cutOverDate and MovedToSage__c=False and Payment_Status__c='Success' and Payment_Amount__c!=null order by Payment_Amount__c ASC]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Payment__c> payments){
        if(payments!=null && payments.size()>0){
            //SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID();
            SageIntacctIntegrationUtility.sessionWrapper sw = null;
            
            List<Payment__c> updPayList = new List<Payment__c>();
            for(Payment__c pay:payments){
                If(pay.Payment_Amount__c>0){
                	pay = SageIntacctIntegrationUtility.createPayment(sw,pay,'');
                }else{
                    if(pay.Parent_Payment__c!=null && (pay.Parent_Payment__r.Payment_Amount__c+pay.Payment_Amount__c)==0){
                        if(pay.Parent_Payment__r.SagePaymentKey__c!=null){
							pay = SageIntacctIntegrationUtility.reversePayment(sw,pay);
						}else{
							pay.Sage_Error_Message__c = 'Payment key not found.';
						}
                    }else{
                        pay = SageIntacctIntegrationUtility.createAdjustmentJournalEntries(sw,pay);
                    }
                }
                Payment__c paymentToUpdate  = new Payment__c();
                paymentToUpdate.Id = pay.Id;
                paymentToUpdate.MovedToSage__c = pay.MovedToSage__c;
                paymentToUpdate.SagePaymentKey__c = pay.SagePaymentKey__c;
                paymentToUpdate.Sage_Error_Message__c = pay.Sage_Error_Message__c;
                updPayList.add(paymentToUpdate);
            }
            update updPayList;
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global void execute(SchedulableContext sc) {
		Database.executeBatch(new SagePaymentPushBatch(),Integer.valueOf(label.SageBatchSize));
    }
}