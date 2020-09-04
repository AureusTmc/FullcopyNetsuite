/*
Name        :        ConfirmRentalPurchaseControllerTest
Date        :        17 March 2020
Author      :        Jatin
Description :        It is the test class of ConfirmRentalPurchaseController.
*/
@isTest
public class ConfirmRentalPurchaseControllerTest {
    @testSetup
    private static  void createData(){
        PianoRentalTestHelper.createPianoRentalData();
    }
    private static testMethod void testRentalSummary(){
        List<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1];
        lstEnrolments[0].Delivery_Charges__c = 50;
        lstEnrolments[0].Stair_Charges__c = 5;
        lstEnrolments[0].Selling_price__c = 100;
        
        update lstEnrolments[0];
        
        test.startTest();
        PageReference pageRef = Page.ConfirmRentalPurchasePage; // Add your VF page Name here
        pageRef.getParameters().put('Id',lstEnrolments[0].id);
        Test.setCurrentPage(pageRef);
        ConfirmRentalPurchaseController objController = new ConfirmRentalPurchaseController();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.uploaded", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        objController.signAgreement();
        objController.isSignAgreement();
        objController.waitAgreement();
        objController.sendAgreement();
        objController.createSession();
        test.stopTest();
        objController.signAgreementRentalPurchase(lstEnrolments[0].id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        objController.getPaymentForInvoices();
        objController.createAttachmentForEmail();
    }
    //for insert Current month rental invoice testMethod
    private static testMethod void testRentalSummary2(){
        List<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1];
        List<Invoice_Line_Item__c>lstInvoiceLineItems = [SELECT Is_Deposit__c,Invoice__r.Status__c,Enrolment__c,Invoice__r.Invoice_Type__c,Invoice__r.Due_Date__c
                                                         from Invoice_Line_Item__c
                                                         Where Enrolment__c =: lstEnrolments[0].id
                                                        ];
        List<Invoice__c>lstInvoice = new List<Invoice__c>();
        lstInvoiceLineItems[0].Is_Deposit__c = true;
        lstInvoiceLineItems[0].Amount__c =100;
        lstInvoiceLineItems[0].Invoice__r.Status__c = 'Paid';
        lstInvoiceLineItems[0].Invoice__r.Invoice_Type__c =ConstantsClass.recurringInvoiceType;
        
        lstInvoice.add(lstInvoiceLineItems[0].Invoice__r);
        update lstInvoice;
        
        lstEnrolments[0].Delivery_Charges__c = 50;
        lstEnrolments[0].Stair_Charges__c = 5;
        lstEnrolments[0].Selling_price__c = 100;
        
        update lstEnrolments[0];
        PageReference pageRef = Page.ConfirmRentalPurchasePage; 
        pageRef.getParameters().put('Id',lstEnrolments[0].id);
        Test.setCurrentPage(pageRef);
        ConfirmRentalPurchaseController objController = new ConfirmRentalPurchaseController();
        objController.createInvoiceViaCard();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        objController.getPaymentForInvoices();
        test.stopTest();
        objController.createAttachmentForEmail();
        
    }
    private static testMethod void testRentalSummary3(){
        List<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1];
        List<Invoice_Line_Item__c>lstInvoiceLineItems = [SELECT Is_Deposit__c,Invoice__r.Status__c,Enrolment__c,Invoice__r.Invoice_Type__c,Invoice__r.Due_Date__c
                                                         from Invoice_Line_Item__c
                                                         Where Enrolment__c =: lstEnrolments[0].id
                                                        ];
        List<Invoice__c>lstInvoice = new List<Invoice__c>();
        lstInvoiceLineItems[0].Is_Deposit__c = true;
        lstInvoiceLineItems[0].Amount__c =100;
        lstInvoiceLineItems[0].Invoice__r.Due_Date__c = System.today().addMonths(-2);
        lstInvoiceLineItems[0].Invoice__r.Status__c = 'Paid';
        lstInvoiceLineItems[0].Invoice__r.Invoice_Type__c =ConstantsClass.recurringInvoiceType;
        
        lstInvoice.add(lstInvoiceLineItems[0].Invoice__r);
        update lstInvoice;
        
        lstEnrolments[0].Delivery_Charges__c = 50;
        lstEnrolments[0].Stair_Charges__c = 5;
        lstEnrolments[0].Selling_price__c = 100;
        
        update lstEnrolments[0];
        PageReference pageRef = Page.ConfirmRentalPurchasePage; 
        pageRef.getParameters().put('Id',lstEnrolments[0].id);
        Test.setCurrentPage(pageRef);
        ConfirmRentalPurchaseController objController = new ConfirmRentalPurchaseController();
        objController.createInvoiceViaCard();
        
        lstInvoice.clear();
        lstInvoiceLineItems[0].Is_Deposit__c = true;
        lstInvoiceLineItems[0].Amount__c =100;
        lstInvoiceLineItems[0].Invoice__r.Due_Date__c = System.today();
        lstInvoiceLineItems[0].Invoice__r.Status__c = 'Paid';
        lstInvoiceLineItems[0].Invoice__r.Invoice_Type__c =ConstantsClass.recurringInvoiceType;
        
        lstInvoice.add(lstInvoiceLineItems[0].Invoice__r);
        update lstInvoiceLineItems[0];
        update lstInvoice;
        objController = new ConfirmRentalPurchaseController();
        objController.createInvoiceViaCard();
        
    }
}