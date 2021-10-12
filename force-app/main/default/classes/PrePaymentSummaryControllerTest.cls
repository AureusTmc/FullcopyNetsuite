/*
Name        :        PrePaymentSummaryControllerTest
Date        :        27 June 2019
Description :        It is the test class of PrePaymentSummaryController.
*/
@isTest
public class PrePaymentSummaryControllerTest {
    
    @testsetup
    public static void DataSetup(){
        
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Available_Make_up_Units__c=30;
        insert objCustmr;
        
        DateTime dt = System.today();
        
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
        
        
        //updated by @nishi 24 sep 2020
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        objCentr.Location__c = 'Aureus AMK Hub';
        //updated by @nishi 24 sep 2020
        objCentr.Center_Email__c =  'Test@gmail.com';
        objCentr.Organisation__c = organisationRecord.id;
        //objCentr.Location__c = 'Ossia Music';
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        
        INSERT objCentr;
        
        
        
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
        objenrol.Student__c = objCustmr.Id;
        objenrol.Parent__c = objCustmr.Id;
        insert objEnrol;
        
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
        
        
        
    }
    @isTest
    public static void invokePrePaymentSummaryController(){
        Enrolment__c objEnrol = [SELECT Id FROM Enrolment__c LIMIT 1];
        Package__c objPack = [SELECT Id FROM Package__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('enrolId',objEnrol.id);
        ApexPages.currentPage().getParameters().put('packageId',objPack.id);
        PrePaymentSummaryController controllerPrePaid = new PrePaymentSummaryController();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        controllerPrePaid.completePrepayment();
        controllerPrePaid.newAttachInsert();
        test.stopTest();
    }
}