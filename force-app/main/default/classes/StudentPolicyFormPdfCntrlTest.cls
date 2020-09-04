/*
Name        :        StudentPolicyFormPdfCntrlTest
Date        :        22 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of StudentPolicyFormPdfCntrl.
*/
@isTest
public class StudentPolicyFormPdfCntrlTest {
    public Static TestMethod Void invokeStudentPolicyFormPdfCntrl(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,True);
         Invoice__c objinvoice = testUtility.createInvoice(objCustmr.id, true);
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,false);
        objInvLneItm.Enrolment__c=objENrol.id;
        objInvLneItm.Remarks__c='Program Fees';
        objInvLneItm.Discount_Amount__c=30;
        insert objInvLneItm;
        Attachment objAttach=TestUtil.createAttachment(objEnrol.id, False);
        objAttach.Name=ConstantsClass.defAttSignName;
        insert objAttach;
        ApexPages.currentPage().getParameters().put('id',objinvoice.id);
        
        StudentPolicyFormPdfCntrl objStudentPolicy= new StudentPolicyFormPdfCntrl();
    }
}