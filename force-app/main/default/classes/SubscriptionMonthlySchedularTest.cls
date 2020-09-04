/*
Name        :        SubscriptionMonthlySchedularTest
Date        :        8 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of SubscriptionMonthlySchedular.
*/

@isTest
public class SubscriptionMonthlySchedularTest {
    public static testmethod void invokeSubscriptionMonthlySchedular(){
        
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        
        Account objCentr=TestUtil.createAccount('Centre',False,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,True); 
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine; 
        
        SubscriptionMonthlySchedular objSubMonSch= new SubscriptionMonthlySchedular();
        objSubMonSch.execute(Null);
    }
}