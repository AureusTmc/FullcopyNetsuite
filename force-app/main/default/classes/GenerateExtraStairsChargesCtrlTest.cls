/**
* Name: GenerateExtraStairsChargesCtrlTest
* Author: Jatin
* Date : 16-March-2020
* Description: this class Used to test GenerateExtraStairsChargesCtr controller class
*/
@isTest
public class GenerateExtraStairsChargesCtrlTest {
    @testSetup
    private static void createData(){
        PianoRentalTestHelper.createPianoRentalData();
        
        
    }
    private static testMethod void testUpdateEnrollment(){
        List<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c LIMIT 1];
        List<Invoice__c> lstInvoice = [SELECT Id,status__c FROM Invoice__c where status__c =: ConstantsClass.paidStatus  limit 1 ];
        lstEnrolments[0].Stage__c = 'Piano Rental Active';
        lstEnrolments[0].Actual_Delivery_Date_Time__c = System.now();
        lstEnrolments[0].Extra_Stairs__c = 20;
        lstEnrolments[0].No_of_Stairs__c = 20;
        lstEnrolments[0].Stair_Charges__c =40;
        UPDATE lstEnrolments;
        
        
        ApexPages.StandardController objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        GenerateExtraStairsChargesCtrl objController = new GenerateExtraStairsChargesCtrl(objStandarCon);
        objController.invoiceId = lstInvoice[0].Id;
        objController.getPaymentForInvoices();
        objController.createAttachmentForEmail();
        objController.generateExtraStairsCharges();
        System.debug('!!lstInvoice'+lstInvoice.size());
        GenerateExtraStairsChargesCtrl.insertPdfAndSendEmail(lstInvoice[0].id);
        
        System.assertEquals(true,objController.errorString == 'getPaymentForInvoices');
        
        
    }
}