/*
Name        :        PackageCancellationControllerTest
Date        :        8 April 2019
Author      :        Karan Singh Soni
Remodified  :		 24 June 2019
Description :        It is the test class of PackageCancellationController.
*/
@isTest
public class PackageCancellationControllerTest {
    public static testMethod void invokePackageCancellationController(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);
		Package__c objNewPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Package_Process_Status__c='Pending';
        objENrol.Package_Process_Type__c='Cancellation';
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
        PackageCancellationController objPCC=new PackageCancellationController([Select Enrolment__r.Lesson_Day__c,Enrolment__r.Effective_Date__c,Enrolment__r.Package__r.Deposit_Fee__c ,Enrolment__r.Package__r.Unit_Fee__c ,Enrolment__r.Teacher__c from Subscription_Line_Item__c WHERE Enrolment__c =: objEnrol.Id][0]);
        SubscriptionMonthlyInvoiceBatch obj = new SubscriptionMonthlyInvoiceBatch();
        DataBase.executeBatch(obj);
        objPCC.createInvoiceLineItem(objINV,datemap);
    }
}