/*
Name        :        SubscriptionTriggerTest
Date        :        11 September 2019
Author      :        
Description :        It is the test class of SubscriptionTrigger.
*/
@isTest
public class SubscriptionTriggerTest {
    
    public static testMethod void invokeTestMethod(){
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
    }
}