/*
Name        :    FetchBalanceTransactionsScheduler
Date        :    18 October 2019
Author      :
Description :    Schedule FetchBalanceTransactionsQueueable to run daily at 12 AM.
*/


global class FetchBalanceTransactionsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        for(Stripe_Payout_Log__c payoutObj: [SELECT Id FROM Stripe_Payout_Log__c WHERE Status__c = 'Unprocessed']){
            System.enqueueJob(new FetchBalanceTransactionsQueueable(payoutObj.Id, 200));
        }
    }   
}