/*
Name        :        BusyBookingSchedularTest
Date        :        5 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of BusyBookingSchedular.
*/
@isTest
public class BusyBookingSchedularTest {
     @isTest
    public static void invokeBusyBookingSchedular(){
        Country__c country = new Country__c(); 
        country.Name = 'IN'; 
        country.Country_Name__c = 'India'; 
        country.Tax_Rate__c = 7.0; 
        country.Currency_Code__c = 'INR'; 
        country.Student_Policies_Template_Id__c = 'test'; 
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;

        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        insert objCentr;
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,true,7);
        
        Test.startTest();
        	BusyBookingSchedular objBusyBookSchd=new BusyBookingSchedular();
      		objBusyBookSchd.execute(NULL);
        Test.stopTest();
        
        
    }
    
    /*@isTest
    static void testMethod1(){
        String CRON_EXP = '0 0 0 15 3 ? *';
        String jobId = System.schedule('BusyBookingSchedular',  CRON_EXP, new BusyBookingSchedular());
    }*/
}