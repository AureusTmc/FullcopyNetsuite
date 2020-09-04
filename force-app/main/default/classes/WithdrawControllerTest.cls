/*
Name        :        WithdrawControllerTest
Date        :        24 June 2019
Author      :        Karan Singh Soni
Description :        It is the test class for WithdrawController.
*/
@isTest
public class WithdrawControllerTest {
    public static testMethod void invokeWithdrawControllerTest(){
        
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
        Insert objCentr;
        
        Map<String,String> createdDummyData = TestUtil.createData();
        Enrolment__c objEnrol = new Enrolment__c();
        
        objEnrol.Id = createdDummyData.get('objEnrol');
        objEnrol.Center__c = objCentr.Id;
        objEnrol.Package_Process_Request_Date__c = Date.today();
        objEnrol.Effective_Date__c = Date.today().addDays(4);
        update objEnrol;
        
        Booking__C objBook = new Booking__C();
        objBook.Id = createdDummyData.get('objBook');
        objBook.Status__c = 'Pending';
        objBook.Type__c = 'Regular';
        objBook.Booking_Date__c = Date.today().addDays(1);
        objBook.Enrolment__c = objEnrol.Id;
        update objBook;
        
        Booking__c objBookTemp = new Booking__c();
        objBookTemp.Teacher_Account__c=createdDummyData.get('objTchr');
        objBookTemp.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        objBookTemp.Booking_Date__c=date.today().addDays(1);
        objBookTemp.Start_Time__c=Time.newInstance(11,0,0,0);
        objBookTemp.Type__c='Regular';
        objBookTemp.Status__c='Canceled';
        objBookTemp.Booking_Date__c = Date.today().addDays(1);
        objBookTemp.Enrolment__c = objEnrol.Id;
        objBookTemp.Available_Make_up_Units__c = 30;
        objBookTemp.Make_up_Expiry_Date__c = date.today();
        objBookTemp.Canceled_Date__c = date.today();
        insert objBookTemp;
        
        Subscription__C objSubs = testUtil.createSubscription( createdDummyData.get('objCustmr'), true );
        Subscription_Line_Item__c objSubline = testUtil.createSubscriptionLineItem( objSubs.Id, false );
        objSubline.Enrolment__c = createdDummyData.get('objEnrol');
        objSubline.Next_Bill_Date__c = Date.today().addDays(3);
        insert objSubline;
        
        ApexPages.currentPage().getParameters().put('id',objEnrol.Id);
        WithdrawController objWithdrwCntrl = new WithdrawController();
        
    }
}