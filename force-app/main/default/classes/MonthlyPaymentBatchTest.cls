/*
Name        :        MonthlyPaymentBatchTest
Date        :        5 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of MonthlyPaymentBatch.
*/
@isTest
public class MonthlyPaymentBatchTest{
    public static TestMethod void invokeMonthlyPaymentBatch(){
        
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
        
        String CRON_EXP = '0 0 0 15 3 ? *';
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        insert objCustmr;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        //List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'30',true);
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c='Friday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.Package_Process_Type__c='Upgrade';
        objEnrol.Package_Process_Status__c='Pending';
        objEnrol.Effective_Date__c=Date.newInstance(System.today().year(),System.today().month(), 05);
        objenrol.New_Package_Id__c=objNewPack.id;
        insert objEnrol;
        system.debug('objEnrol'+objEnrol.Id);
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=60;
        objInv.Center__c  = objCentr.Id;
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        insert objINVline;
        
        MonthlyPaymentBatch objMonthpay=new MonthlyPaymentBatch();
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        String jobId = System.schedule('MonthlyPaymentSchedular',  CRON_EXP, new MonthlyPaymentSchedular());
        //DataBase.executeBatch(objMonthpay);
        Test.stopTest();
    }
    public static TestMethod void invokeMonthlyPaymentBatch3(){
        
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
        
        String CRON_EXP = '0 0 0 15 3 ? *';
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        insert objCustmr;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        //List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'30',true);
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c='Friday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.Package_Process_Type__c='Upgrade';
        objEnrol.Package_Process_Status__c='Pending';
        objEnrol.Effective_Date__c=Date.newInstance(System.today().year(),System.today().month(), 05);
        objenrol.New_Package_Id__c=objNewPack.id;
        insert objEnrol;
        system.debug('objEnrol'+objEnrol.Id);
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=60;
        objINV.Paid_Amount__c =73.91;
        objInv.Center__c  = objCentr.Id;
        insert objINV;
        
        Invoice__C objINV1=TestUtil.createInvoice(objCustmr.Id,False);
        objINV1.Due_Date__c=Date.today();
        objINV1.Status__c=ConstantsClass.paidStatus;
        objINV1.Paid_Amount__c =74.2;
        objINv1.Admin_Fees__c=60;
        objInv1.Center__c  = objCentr.Id;
        insert objINV1;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        insert objINVline;
         Invoice_Line_Item__c objINVline1=TestUtil.createInvLineItem(objInv1.Id,false);
        objINVline1.Amount__c=30;
        objINVline1.Discount_Amount__c=20;
        objINVline1.Is_Deposit__c=false;
        objINVline1.Enrolment__c=objEnrol.id;
        insert objINVline1;
        
        MonthlyPaymentBatch objMonthpay=new MonthlyPaymentBatch();
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        String jobId = System.schedule('MonthlyPaymentSchedular',  CRON_EXP, new MonthlyPaymentSchedular());
        //DataBase.executeBatch(objMonthpay);
        Test.stopTest();
    }
    
     public static TestMethod void invokeMonthlyPaymentBatch2(){
        
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
        
        String CRON_EXP = '0 0 0 15 3 ? *';
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd';
        insert objCustmr;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        //List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'30',true);
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c='Friday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.Package_Process_Type__c='Upgrade';
        objEnrol.Package_Process_Status__c='Pending';
        objEnrol.Effective_Date__c=Date.newInstance(System.today().year(),System.today().month(), 05);
        objenrol.New_Package_Id__c=objNewPack.id;
        insert objEnrol;
        system.debug('objEnrol'+objEnrol.Id);
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=60;
        objInv.Center__c  = objCentr.Id;
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        insert objINVline;
        
        MonthlyPaymentBatch objMonthpay=new MonthlyPaymentBatch();
        test.startTest();
        
         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400,'{ "error": { "code": "resource_missing", "doc_url": "https://stripe.com/docs/error-codes/resource-missing", "message": "No such customer: cus_GFq2Er0xbTPe", "param": "customer", "stripeType": "invalid_request_error" } }'));
        String jobId = System.schedule('MonthlyPaymentSchedular',  CRON_EXP, new MonthlyPaymentSchedular());
        //DataBase.executeBatch(objMonthpay);
        Test.stopTest();
    }
}


/*@isTest
public static void unitTest(){
Contact con = new Contact(LastName = 'lname', email = 'ab@try.com');
insert con;
//String RecTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
//[select Id from RecordType where (Name='Person Account') and (SobjectType='Account')].Id;
Account acc = testUtility.createAccount('Test','Customer',false);
//acc.RecordTypeID = RecTypeId;
acc.Stripe_Customer_Id__c = '1234';
acc.PersonMailingStreet='test@yahoo.com';
acc.PersonMailingPostalCode='12345';
acc.PersonMailingCity='SFO';
acc.PersonEmail='test@yahoo.com';
acc.PersonHomePhone='1234567';
acc.PersonMobilePhone='12345678'; 
insert acc;
Invoice__c invoice = testUtility.createInvoice(acc.id, false);
invoice.Due_Date__c = system.today() - 10;
invoice.Status__c = ConstantsClass.dueStatus;
insert invoice;

Test.startTest();
Test.setMock(HttpCalloutMock.class, new mockupUtility());
MonthlyPaymentBatch obj = new MonthlyPaymentBatch();
DataBase.executeBatch(obj);
Test.stopTest();
}*/