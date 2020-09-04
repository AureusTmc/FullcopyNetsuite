/*
Name        :        subscriptionLineItemTriggerHelperTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of subscriptionLineItemTriggerHelper.
*/

@isTest
public class SubscriptionLineItemTriggerTest {
    public static testMethod void invokeSubscriptionLineItemTrigger(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='In Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        objSubsLine.Status__c='In Active';
        update objSubsLine;
    }
    
    @isTest
    private static void unitTest(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='In Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        Subscription_Line_Item__c objSubsLineNew=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLineNew.Status__c='Active';
        objSubsLineNew.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLineNew;
        
        objSubsLine.Status__c='In Active';
        update objSubsLine;
    }

}