/*
Name        :        SubscriptionMonthlyInvoiceBatchTest
Date        :        8 April 2019(re-Modified 29 May 2019)
Author      :        Karan Singh Soni
Description :        It is the test class of SubscriptionMonthlyInvoiceBatch.
*/

@isTest
public class SubscriptionMonthlyInvoiceBatchTest{
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
        
        Test.startTest();
        SubscriptionMonthlyInvoiceBatch obj = new SubscriptionMonthlyInvoiceBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
    }
    private testMethod static void testGroupClass(){
        ClassEditControllerTestHelper.createGroupClassData(); 
        Test.startTest();
        SubscriptionMonthlyInvoiceBatch obj = new SubscriptionMonthlyInvoiceBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
    }
    private testMethod static void testRentalClass(){
        PianoRentalTestHelper.createPianoRentalData();
        Test.startTest();
        SubscriptionMonthlyInvoiceBatch obj = new SubscriptionMonthlyInvoiceBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
    }
}