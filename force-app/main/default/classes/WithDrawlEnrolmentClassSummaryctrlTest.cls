/*
Name        :        WithDrawlEnrolmentClassSummaryctrlTest
Date        :        24 June 2019
Author      :        Karan Singh Soni
Description :        It is the test class for WithDrawlEnrolmentClassSummaryController.
*/
@isTest
public class WithDrawlEnrolmentClassSummaryctrlTest {
    @testSetup 
    Private static void createData(){
        ClassEditControllerTestHelper.createGroupClassData();
    }  
    public static testMethod void invokeWithdrawControllerTest(){
        
       Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c  limit 1];
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus ;
        objENrol.effective_Date__c = System.today().addDays(-3);
        update objENrol;
        ApexPages.currentPage().getParameters().put('id',objEnrol.Id);
        WithDrawlEnrolmentClassSummaryController objWithdrwCntrl = new WithDrawlEnrolmentClassSummaryController();
        objWithdrwCntrl.saveEnrollment();

    }
}