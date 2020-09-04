/*
Name        :        PackageProcessHandlerTest
Date        :        8 April 2019
Remodified  :		 24 June 2019
Author      :        Karan Singh Soni
Description :        It is the test class of PackageProcessHandler.
*/

@isTest
public class PackageProcessHandlerTest {
    
    public static testmethod void invokePackageProcessHandler(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Package_Process_Status__c='Pending';
        objENrol.Package_Process_Type__c='Downgrade';
        objENrol.Effective_Date__c=date.today();
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
        
        List<Subscription_Line_Item__c> listOfSubLineItems=[SELECT Id,ENrolment__c,Enrolment__r.Package_Process_type__c,
                                                            Enrolment__r.Package_Process_Status__c,
                                                            Enrolment__r.effective_date__c
                                                            FROM Subscription_Line_Item__c];
            
            //new List<Subscription_Line_Item__c>();
       // listOfSubLineItems.add(objSubsLine);
        
        Invoice__C objInv=Testutil.createInvoice(objCustmr.Id,true);
        
        PackageProcessHandler objPackProcess=new PackageProcessHandler(objInv,listOfSubLineItems,date.today(),date.today());
        
        objENrol.Package_Process_Type__c='Upgrade';
        update objENrol;
        
        listOfSubLineItems=[SELECT Id,ENrolment__c,Enrolment__r.Package_Process_type__c,
                                                            Enrolment__r.Package_Process_Status__c,
                                                            Enrolment__r.effective_date__c
                                                            FROM Subscription_Line_Item__c];
        PackageProcessHandler objPackProcess2=new PackageProcessHandler(objInv,listOfSubLineItems,date.today(),date.today());
        objENrol.Package_Process_Type__c='Cancellation';
        update objENrol;
        listOfSubLineItems=[SELECT Id,ENrolment__c,Enrolment__r.Package_Process_type__c,
                                                            Enrolment__r.Package_Process_Status__c,
                                                            Enrolment__r.effective_date__c
                                                            FROM Subscription_Line_Item__c];
        PackageProcessHandler objPackProcess3=new PackageProcessHandler(objInv,listOfSubLineItems,date.today(),date.today());
        
    }
}