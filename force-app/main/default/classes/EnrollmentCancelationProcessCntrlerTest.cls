/*
Name        :        EnrollmentCancelationProcessCntrlerTest
Date        :        4 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of EnrollmentCancelationProcessController.
*/
@isTest
public class EnrollmentCancelationProcessCntrlerTest {
    public static testMethod void invokeEnrollmentCancelationProcessController(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
      	Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);        
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,True);
        ApexPages.currentPage().getParameters().put('id',objEnrol.id);
        EnrollmentCancelationProcessController objEnmtCnclProcssCntr = new EnrollmentCancelationProcessController();
        objEnmtCnclProcssCntr.saveEnrollment();
        
    }
}