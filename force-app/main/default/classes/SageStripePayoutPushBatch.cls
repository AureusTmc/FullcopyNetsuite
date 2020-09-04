global class SageStripePayoutPushBatch implements Schedulable,Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    Set<Id> stripePayoutIds = new Set<Id>();
    public SageStripePayoutPushBatch(){}
    
    public SageStripePayoutPushBatch(Set<Id> stripePayoutIds){
        this.stripePayoutIds = stripePayoutIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        if(stripePayoutIds.size()>0){
            return Database.getQueryLocator([Select Id,Name,Stripe_Payout_Id__c,Stripe_Payout_Date__c,Stripe_Payment_Amount__c,Stripe_Fee_charged__c,Organisation__c,Organisation__r.Sage_Company__c,Organisation__r.Country__r.Currency_Code_PI__c,Status__c,SageJournalEntryKey__c,Sage_Error_Message__c from Stripe_Payout_Log__c where Status__c='Processed in SF' and Organisation__c!=null and Id in:stripePayoutIds]);
        }else{
            return Database.getQueryLocator([Select Id,Name,Stripe_Payout_Id__c,Stripe_Payout_Date__c,Stripe_Payment_Amount__c,Stripe_Fee_charged__c,Organisation__c,Organisation__r.Sage_Company__c,Organisation__r.Country__r.Currency_Code_PI__c,Status__c,SageJournalEntryKey__c,Sage_Error_Message__c from Stripe_Payout_Log__c where Status__c='Processed in SF' and Organisation__c!=null]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Stripe_Payout_Log__c> stripePayLogList){
        Set<Id> splIds = new Set<Id>();
        for(Stripe_Payout_Log__c spl:stripePayLogList){
            splIds.add(spl.Id);
        }
        
		List<Payment__c> paymentList = [Select id,Stripe_fees__c,recordType.Name,Payment_Amount__c,Invoice__r.Name,Refund_Id__c from Payment__c where Stripe_Payout_Id__c in:splIds];
        
        for(Stripe_Payout_Log__c spl:stripePayLogList){
            spl = SageIntacctIntegrationUtility.createStripeJournalEntries(spl,paymentList);
        }
        update stripePayLogList;
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global void execute(SchedulableContext sc) {
		Database.executeBatch(new SageStripePayoutPushBatch(),1);
    }
}