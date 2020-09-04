/*
Name        :        PianoRentalPurchaseControllerTest
Date        :        17 March 2020
Author      :        Jatin
Description :        It is the test class of PianoRentalPurchaseController.
*/
@isTest
public class PianoRentalPurchaseControllerTest {
    
    @testSetup
    private static  void createData(){
        PianoRentalTestHelper.createPianoRentalData();
    }
    private static testMethod void testPianoMethods(){
        List<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1];
        
        
        lstEnrolments[0].Delivery_Charges__c = 100;
        lstEnrolments[0].Stair_Charges__c =50;
        update lstEnrolments[0];
        ApexPages.StandardController objStandardController = new ApexPages.StandardController(lstEnrolments[0]);
        PianoRentalPurchaseController objController = new PianoRentalPurchaseController(objStandardController);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.uploaded", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        objController.signAgreement();
        objController.isSignAgreement();
        objController.waitAgreement();
        objController.sendAgreement();
        objController.createSession();
        test.stopTest();
        
        objController.getPaymentTypePicklist();
        objController.sendEmailMessage();
        objController.createInvoiceViaChargeId();
        objController.createAttachmentForEmail();
        objController.createInvoiceViaCard();
        objController.getPaymentForInvoices();
        
        
        
    }
}