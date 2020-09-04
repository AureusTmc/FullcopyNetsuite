/*
Name        :        TestSpecialReferralDiscountBatchSheduler
Date        :       12 Aug 2020
Author      :       
Description :       It is a Test Class for specialReferralDiscountBatchSheduler and specialReferralDiscountBatch
*/
@isTest
public class TestSpecialReferralDiscountBatchSheduler {
    @testSetup
    private static void setupMethod(){
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Referral_Discount__c referral_discount = new Referral_Discount__c();
        referral_discount.Name = 'Special. Referral (SG)';
        referral_discount.Discount_Amount_Referrer__c = 93.46;
        referral_discount.Discount_Amount_Referee__c = 93.46;
        referral_discount.Start_Date__c = system.today();
        referral_discount.End_Date__c = Date.newInstance(2020,09,15);
        referral_discount.Country__c = country.Id;
        referral_discount.Default__c = 'No';
        referral_discount.Active__c = 'Yes';
        insert referral_discount;
        
        
        
    }
    @isTest
    private static void unitTest1(){
        Referral_Discount__c referral_discount = [SELECT id,name,Discount_Amount_Referrer__c,Discount_Amount_Referee__c,Start_Date__c,End_Date__c
                                                  ,Country__c,Default__c,Active__c from Referral_Discount__c LIMIT 1];
        Test.startTest();
        specialReferralDiscountBatch obj = new specialReferralDiscountBatch();
        Database.executeBatch(obj);
        referral_discount.Start_Date__c = system.today() - 2;
        referral_discount.End_Date__c = system.today() - 1;
    }
    @isTest
    private static void unitTest2(){
        Referral_Discount__c referral_discount = [SELECT id,name,Discount_Amount_Referrer__c,Discount_Amount_Referee__c,Start_Date__c,End_Date__c
                                                  ,Country__c,Default__c,Active__c from Referral_Discount__c LIMIT 1];
        Test.startTest();
        
        referral_discount.Start_Date__c = system.today() - 2;
        referral_discount.End_Date__c = system.today() - 1;
        update referral_discount;
        specialReferralDiscountBatch obj = new specialReferralDiscountBatch();
        Database.executeBatch(obj);
        specialReferralDiscountBatchSheduler sheduler = new specialReferralDiscountBatchSheduler();
        sheduler.execute(null);
        
    }
}