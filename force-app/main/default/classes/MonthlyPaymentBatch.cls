/*
        Name        :    MonthlyPaymentBatch
        Date        :    02/27/2019
        Author      :  
        Description :    This batch class is used for making payment with stripe for the particular invoice.
        
*/
global class MonthlyPaymentBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    global DateTime startTime;
    global integer noOfRecords;
    global Set<String> invIds;
    global MonthlyPaymentBatch(){
        noOfRecords  = 0;
        startTime = system.now();
        invIds = new Set<String>();
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId,Parent_Account__r.Stripe_Customer_Id__c, 
                                         Total_Amount__c,subscription__c,Balance_Amount__c,Paid_Amount__c,
                                         Parent_Account__r.personEmail,Parent_Account__r.Centre_Name__r.Location__c,
                                         Center__r.Country__c, Center__r.Country__r.Id, Center__r.Country__r.Tax_Rate__c, 
                                         Center__r.Country__r.Currency_Code__c, Center__r.Country__r.Stripe_Base_Url__c, 
                                         Center__r.Country__r.Stripe_Secret_Key__c,
                                         Center__r.Organisation__c, Center__r.Organisation__r.Id, Center__r.Organisation__r.Tax_Rate__c, 
                                         Center__r.Organisation__r.Country__r.Currency_Code__c, Center__r.Organisation__r.Stripe_Base_Url__c, 
                                         Center__r.Organisation__r.Stripe_Secret_Key__c
                                         FROM Invoice__c WHERE 
                                         Parent_Account__r.Stripe_Customer_Id__c != NULL AND Due_Date__c <= :system.today() 
                                         AND Status__c=:ConstantsClass.dueStatus AND Center__c != NULL AND Parent_Account__r.Is_Club_Member__c != TRUE 
                                         AND Parent_Account__r.Membership_Type__c != :ConstantsClass.amcClubMember]);
    }
    
    global void execute(Database.BatchableContext BC, List<Invoice__c> invList){
        noOfRecords  += invList.size();
        invIds.addAll(MonthlyPaymentBatchHelper.getPaymentForInvoices(invList));   
    }

    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Monthly Payment Batch',startTime,system.now(),noOfRecords);
        if(invIds.size()>0){
            // Arpit :  to send invoice receipt
            Database.executeBatch(new SendInvoiceInMailBatch(invIds),50);
            Database.executeBatch(new InvoiceAttachmentBatch(invIds),50);
            //Sanjay Mankani : Sage Code
             //Temprary stop sage pushing, Immediate step due to COVID-19 by Rajesh on 3rd april 2020
            //database.executeBatch(new SagePaymentPushBatch('Invoice',invIds),Integer.valueOf(label.SageBatchSize));
        }
    }
    
}