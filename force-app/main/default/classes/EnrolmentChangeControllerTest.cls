/*
Name        :        EnrolmentChangeControllerTest
Date        :        3 April 2019(modified at 8 april 2019)
Description :        It is the test class of EnrolmentChangeController.
*/
@isTest
public class EnrolmentChangeControllerTest {
    public static testmethod void invokeEnrolmentChangeController(){
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
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Phone = '123456789';
        objCentr.Country__c = country.Id;
        objCentr.Center_Email__c = 'test@test.com';
        objCentr.Website = 'www.aureusacademy.com';
        //updated by @nishi 24 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        
        Insert objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Package__c objNewPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Package_Process_Status__c='Pending';
        objENrol.Package_Process_Type__c='Enrolment Change';
        objENrol.Effective_Date__c=date.today();
        objEnrol.Lesson_Day__c='Friday';
        objEnrol.New_Package_Id__c=objNewPack.Id;
        insert objENrol;
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
        
        Invoice__C objInv=Testutil.createInvoice(objCustmr.Id,true);
        
        Map<String,List<Date>> datemap=BillingUtility.getDateMap(Date.newInstance(2019,4,1),Date.newInstance(2019,4,30));        
        EnrolmentChangeHandler objPUC=new EnrolmentChangeHandler([Select Enrolment__r.New_Package_Id__r.Deposit_Fee__c,Enrolment__r.Center__c, 
                                                                  Enrolment__r.New_Package_Id__r.Unit_Fee__c,Enrolment__r.Lesson_Day__c,Enrolment__r.Effective_Date__c,
                                                                  Enrolment__r.Package__r.Deposit_Fee__c ,Enrolment__r.Package__r.Unit_Fee__c ,Enrolment__r.Teacher__c ,
                                                                  Enrolment__r.Center__r.Country__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c
                                                                  from Subscription_Line_Item__c WHERE Enrolment__c =: objEnrol.Id][0]);
        
        SubscriptionMonthlyInvoiceBatch obj = new SubscriptionMonthlyInvoiceBatch();
        DataBase.executeBatch(obj);
        
        objPUC.createInvoiceLineItem(objINV, datemap);
    }
}