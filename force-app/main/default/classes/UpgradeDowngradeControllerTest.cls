/*
Name        :        UpgradeDowngradeControllerTest
Date        :        4 April 2019,17 july 2019
Author      :        Karan Singh Soni
Description :        It is the test class of UpgradeDowngradeController.
*/
@istest
public class UpgradeDowngradeControllerTest {
    Public Static testMethod void invokeUpgradeDowngradeController(){
        
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        Account objTechr=TestUtil.createAccount('Teacher',False,True);
        Account objCntr=TestUtil.createAccount('Centre',False,FALSE);
        objCntr.Country__c = country.Id;
        INSERT objCntr;
        Account objCustmr=TestUtil.createAccount('Customer',False,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        insert objCustmr;
        
        
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objOldPack=testUtil.createPackage(objProg.id,objCntr.id,'30',true);        
        Package__c objNewPack=testUtil.createPackage(objProg.id,objCntr.id,'60',False);    
        objNewPack.Package_Fee__c=15.00;
        objNewPack.Active__c=true;
        objNewPack.Unit_Fee__c=15.00;
        objNewPack.Registration_Fee__c=18.00;
        objNewPack.Deposit_Fee__c=18.00;
        insert objNewPack;
        
        Enrolment__c objEnrl=TestUtil.createEnrolment(objCntr.id,objTechr.id,objCustmr.id,objOldPack.id,True);
        Booking__c objBook=TestUtil.createBooking(objTechr.Id,'Lesson','Regular',False);
        objBook.Enrolment__c=objEnrl.Id;
        objBook.Booking_Date__c=Date.today().adddays(10);
        insert objBook;
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.id, FALSE);
        objSubs.Center__c= objCntr.Id;
        insert objSubs;
        Subscription_Line_Item__c objSLI=TestUtil.createSubscriptionLineItem(objSubs.id,false);
        objSLI.Enrolment__c=objEnrl.Id;
        insert objSLI;
        
        UpgradeDowngradeController.getEnrolmentId(objBook.id);
        UpgradeDowngradeController.getEnrolment(objSubs.id);
        Time tt = Time.newInstance(14, 00, 00, 00);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        	UpgradeDowngradeController.upgradePackage(objEnrl.Id, Date.today().adddays(5) ,objNewPack.id, objOldPack.id, tt, country.Currency_Code__c, country.Stripe_Base_Url__c, country.Stripe_Secret_Key__c, country.Tax_Rate__c);
        Test.stopTest();
        
    }
}