global class SageCustomerPushBatch implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    Set<String> parentIds;
    
    string parentRecordTypeId = schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
    
    public SageCustomerPushBatch(Set<string> accIds){
        parentIds = accIds;
    }
    
    public SageCustomerPushBatch(){}
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        If(parentIds!=null && parentIds.size()>0){
            return Database.getQueryLocator([Select id,Name,AccountID_Customer__c,PersonEmail,MovedToSage__c,SageCustomerKey__c,Sage_Error_Message__c,Centre_Name__r.Organisation__r.Sage_Company__c from Account where recordTypeId=:parentRecordTypeId and MovedToSage__c=False and Id in:parentIds and Total_Invoice_Amount__c>0]);
        }else{
            return Database.getQueryLocator([Select id,Name,AccountID_Customer__c,PersonEmail,MovedToSage__c,SageCustomerKey__c,Sage_Error_Message__c,Centre_Name__r.Organisation__r.Sage_Company__c from Account where recordTypeId=:parentRecordTypeId and MovedToSage__c=False and Total_Invoice_Amount__c>0]);
        }
    }
    
    
    global void execute(Database.BatchableContext BC, List<Account> accounts){
        system.debug('accounts==='+accounts);
        if(accounts!=null && accounts.size()>0){
            //SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID();
            SageIntacctIntegrationUtility.sessionWrapper sw = null;
            List<Account> updAccList = new List<Account>();
            for(Account acc:accounts){
                acc = SageIntacctIntegrationUtility.createCustomer(sw,acc);
                system.debug('acc===='+acc);
                Account custToUpdate = new Account();
                custToUpdate.Id = acc.Id;
                custToUpdate.MovedToSage__c = acc.MovedToSage__c;
                custToUpdate.SageCustomerKey__c = acc.SageCustomerKey__c;
                custToUpdate.Sage_Error_Message__c = acc.Sage_Error_Message__c;
                updAccList.add(custToUpdate);
            }
            
            
            update updAccList;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
    global void execute(SchedulableContext sc) {
		Database.executeBatch(new SageCustomerPushBatch(),Integer.valueOf(label.SageBatchSize));
    }
}