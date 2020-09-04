/*
Name        :        PreInvoiceBatchTest
Date        :        27 June 2019
Description :        It is the test class of PreInvoiceBatch.
*/
@isTest
public class PreInvoiceBatchTest {
    @isTest
    public static void invokePreInvoiceBatch(){
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Available_Make_up_Units__c=30;
        insert objCustmr;
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        DateTime dt = System.today();
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
        
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Country__c=country.id;
        insert objCentr;
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',false);
        objPack.Offer_Start_Date__c = System.today();
        objPack.Offer_End_Date__c = System.today().addDays(5);
        objPack.Type_of_package__c = 'Prepayment';
        objPack.Promotion_period_In_months__c = '6';
        objPack.Promotion_Discount__c = 100.00;
        objPack.Package_Fee__c = 300.00;
        insert objPack; 
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c= /*dt.format('EEEE')*/'Saturday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.type__c='Regular';
        objenrol.Lessons_Start_Date__c = Date.newInstance(2019,08,20);
        objenrol.Student__c = objCustmr.Id;
        objenrol.Parent__c = objCustmr.Id;
        insert objEnrol;
        Test.startTest();
        String jobId = System.schedule('PreInvoiceBatchSchedular',  CRON_EXP, new PreInvoiceBatchSchedular());
        Test.stopTest();
        
    }	//Created by Jatin 17March 2020
    private testMethod static void testGroupClass(){
        ClassEditControllerTestHelper.createGroupClassData(); 
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        Test.startTest();
        String jobId = System.schedule('PreInvoiceBatchSchedular',  CRON_EXP, new PreInvoiceBatchSchedular());
        Test.stopTest();
    }
    private testMethod static void testRentalClass(){
        PianoRentalTestHelper.createPianoRentalData();
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        Test.startTest();
        String jobId = System.schedule('PreInvoiceBatchSchedular',  CRON_EXP, new PreInvoiceBatchSchedular());
        Test.stopTest();
    }
}