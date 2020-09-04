@isTest
public class InvoiceReminderBatchTest{
    @isTest
    public static void unitTest(){
        Account acc = testUtility.createAccount('Test','Customer',true);
        
        Subscription__c subscription = testUtility.createSubscription(acc.id, true);
        subscription.Next_Bill_Date__c = System.today().addDays(-50);
        subscription.Status__c = 'Active';
        subscription.Subscription_Start_Date__c = System.today().addDays(-50);
        update subscription;
        
        Subscription_Line_Item__c subscriptionLineItem =  testUtility.createSubscription_Line_Item(subscription.id, true);
        
        List<Subscription__c> subscriptionList = new List<Subscription__c>();
        subscriptionList.add(subscription);
        
        Invoice__c invoice = testUtility.createInvoice(acc.id, true);
        
        
        InvoiceReminderBatch obj = new InvoiceReminderBatch(5);
        ID invoiceId = Database.executeBatch(obj,200);
    }
}