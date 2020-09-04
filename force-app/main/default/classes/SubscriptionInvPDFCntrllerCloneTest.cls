/*
Name        :        SubscriptionInvPDFCntrllerCloneTest
Date        :        5 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of SubscriptionInvoicePDFControllerClone.
*/
@isTest
public class SubscriptionInvPDFCntrllerCloneTest {
    public static testmethod void invokeSubscriptionInvoicePDFControllerClone(){
        Account objCustmr=TestUtil.createAccount('Customer', True, True);
        Account objCentr=TestUtil.createAccount('Centre',false,true);
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'30',true);
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,True);
        Invoice__C objInv=TestUtil.createInvoice(objCustmr.id,FALSE);
        objInv.Center__c = objCentr.id;
        INSERT objInv;
        Payment__c payobj = TestUtil.createPayment(objCustmr.Id, false);
        payobj.Invoice__c = objInv.Id;
        INSERT payobj;
        Stripe_Payment_log__c objStripePay= new Stripe_Payment_log__c();
        objStripePay.Invoice__c=objInv.id;
        objStripePay.Status__c='Success';
        insert objStripePay;
        
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objInv.id,False);
        objInvLneItm.Enrolment__c=objEnrol.Id;
        insert objInvLneItm;
        
        Apexpages.currentPage().getParameters().put('Id',objInv.id);
        SubscriptionInvoicePDFControllerClone objSubsInvPdf= new SubscriptionInvoicePDFControllerClone();
    }
}