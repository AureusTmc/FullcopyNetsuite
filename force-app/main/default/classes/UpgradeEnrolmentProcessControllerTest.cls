/*
Name        :        UpgradeEnrolmentProcessControllerTest
Date        :        
Author      :        
Description :        
*/
@istest
public class UpgradeEnrolmentProcessControllerTest {
    Public Static testMethod void invokeUpgradeEnrolmentProcessController(){
        
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
        
        Package__c objMakeup = testUtil.createPackage(objProg.id,objCntr.id,'60',False); 
        objMakeup.Type__c = 'Makeup';
        objMakeup.Active__c=true;
        insert objMakeup;

        Package__c objMakeup2 = testUtil.createPackage(objProg.id,objCntr.id,'30',False); 
        objMakeup2.Type__c = 'Makeup';
        objMakeup2.Active__c=true;
        insert objMakeup2;

        Enrolment__c objEnrl=TestUtil.createEnrolment(objCntr.id,objTechr.id,objCustmr.id,objOldPack.id,FALSE);
        objEnrl.effective_date__c = System.today();
        INSERT objEnrl;

         Booking__c objBook=TestUtil.createBooking(objTechr.Id,'Lesson','Regular',False);
        objBook.Enrolment__c=objEnrl.Id;
        objBook.Booking_Date__c=Date.today().adddays(10);
        objBook.Package__c = objOldPack.Id;
        insert objBook;

        Booking__c objBook2=TestUtil.createBooking(objTechr.Id,'Lesson','Make-up',False);
        objBook2.Enrolment__c=objEnrl.Id;
        objBook2.status__c = 'Scheduled';
        objBook2.Booking_Date__c=date.newInstance(2019, 10, 29);
        objBook2.Package__c = objMakeup2.Id;
        insert objBook2;

        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 10, 29), Center__c=objCntr.id, End_Time__c=time.newInstance(10, 0, 0, 0), Enrolment__c=objEnrl.id,
                                                 Package__c=objOldPack.id, Start_Time__c= time.newInstance(10, 30, 0, 0), Student__c=objCustmr.id, Teacher_Account__c=objTechr.id, Remarks__c='40',
                                                 IsActive__c=FALSE ,Parent__c=objCustmr.id, Booking__c = objBook2.Id);
        insert objFifthLesson;

        
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.id, FALSE);
        objSubs.Center__c= objCntr.Id;
        insert objSubs;
        Subscription_Line_Item__c objSLI=TestUtil.createSubscriptionLineItem(objSubs.id,false);
        objSLI.Enrolment__c=objEnrl.Id;
        insert objSLI;

        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', objOldPack.Id);
        mapOfCaseValues.put('newPackage', objNewPack.Id);
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        
       UpgradeEnrolmentProcessController controllerObj = new UpgradeEnrolmentProcessController(objBook.Id, '10/10/2019', objNewPack.Id, objOldPack.Id, '10:00 AM', '', 'true', mapOfCaseValues);
       test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        controllerObj.initProcess();
        test.stopTest();

    }
}