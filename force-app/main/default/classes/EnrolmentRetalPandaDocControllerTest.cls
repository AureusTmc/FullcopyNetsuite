/**
* Name: EnrolmentRetalPandaDocControllerTest
* Author: Jatin
* Date : 16-March-2020
* Description: this class Used to test EnrolmentRetalPandaDocController controller class
*/
@isTest
public class EnrolmentRetalPandaDocControllerTest {
    @testSetup
    private static void createData() {
        PianoRentalTestHelper.createPianoRentalData();
    }
    private static testMethod  void test_getRentalEnrolmentAggrementViewed(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__r.PersonEmail from Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        PageReference myVfPage = Page.EnrolmentDeliveryPandaDoc;
        Test.setCurrentPage(myVfPage);
        enrolmentList[0].Aggrement_id__c  = 'FCsg5zUszbvQWhAxXhxnmB';
        update enrolmentList[0];
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('id', enrolmentList[0].id);
        ApexPages.currentPage().getParameters().put('type', 'Client');
        EnrolmentRetalPandaDocController objEnrolmentRetalPandaDocController = new EnrolmentRetalPandaDocController();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.viewed", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        objEnrolmentRetalPandaDocController.sendDocument();
        test.stopTest();
    }
    private static testMethod  void test_getRentalEnrolmentAggrementSent(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__r.PersonEmail from Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        PageReference myVfPage = Page.EnrolmentDeliveryPandaDoc;
        Test.setCurrentPage(myVfPage);
        enrolmentList[0].Aggrement_id__c  = 'FCsg5zUszbvQWhAxXhxnmB';
        update enrolmentList[0];
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('id', enrolmentList[0].id);
        ApexPages.currentPage().getParameters().put('type', 'Client');
        EnrolmentRetalPandaDocController objEnrolmentRetalPandaDocController = new EnrolmentRetalPandaDocController();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.sent", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        objEnrolmentRetalPandaDocController.sendDocumentAgreement(enrolmentList[0].Aggrement_id__c ,enrolmentList[0].id);
        test.stopTest();
    }
    private static testMethod  void test_getRentalEnrolmentAggrementDraft(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__r.PersonEmail from Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        PageReference myVfPage = Page.EnrolmentDeliveryPandaDoc;
        Test.setCurrentPage(myVfPage);
        enrolmentList[0].Aggrement_id__c  = 'FCsg5zUszbvQWhAxXhxnmB';
        update enrolmentList[0];
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('id', enrolmentList[0].id);
        ApexPages.currentPage().getParameters().put('type', 'Client');
        EnrolmentRetalPandaDocController objEnrolmentRetalPandaDocController = new EnrolmentRetalPandaDocController();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.draft", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        
        objEnrolmentRetalPandaDocController.sendDocument();
        test.stopTest();
    }
    private static testMethod  void test_getRentalEnrolmentAggrementSession(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__r.PersonEmail from Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        PageReference myVfPage = Page.EnrolmentDeliveryPandaDoc;
        Test.setCurrentPage(myVfPage);
        enrolmentList[0].Aggrement_id__c  = 'FCsg5zUszbvQWhAxXhxnmB';
        update enrolmentList[0];
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('id', enrolmentList[0].id);
        ApexPages.currentPage().getParameters().put('type', 'Client');
        EnrolmentRetalPandaDocController objEnrolmentRetalPandaDocController = new EnrolmentRetalPandaDocController();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "R33xS4Ybe3qtBbRyke2p6a", "status": "document.completed", "name": "API Sample Document from PandaDoc Template", "date_created": "2020-01-22T08:20:58.179132Z", "date_modified": "2020-01-22T08:20:58.652923Z", "template": { "id": "5jfk4yvnNWaqsjmg4tdnbm", "name": "Delivery Order Template" }, "tokens": [{ "name": "Delivery_Person.FirstName" }], "fields": [{ "uuid": "NmobNHTwG6fdu5bVcnAUbZ", "name": "Stairs", "title": "Stairs", "assigned_to": { "id": "QpQRqhYV4k9K95kAqrgaof", "first_name": "Ashish", "last_name": "Bansal", "email": "ashish@outlook.com", "recipient_type": "signer", "has_completed": false, "role": "Delivery_Person", "type": "recipient" }, "value": "0" }] }'));
        objEnrolmentRetalPandaDocController.updateEnrolment();
        test.stopTest();
    }
    private static testMethod  void test_getRentalEnrolmentAggrementCompleted(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__r.PersonEmail from Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        PageReference myVfPage = Page.EnrolmentDeliveryPandaDoc;
        Test.setCurrentPage(myVfPage);
        enrolmentList[0].Aggrement_id__c  = 'FCsg5zUszbvQWhAxXhxnmB';
        update enrolmentList[0];
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('id', enrolmentList[0].id);
        ApexPages.currentPage().getParameters().put('type', 'Client');
        EnrolmentRetalPandaDocController objEnrolmentRetalPandaDocController = new EnrolmentRetalPandaDocController();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "QYCPtavst3DqqBK72ZRtbF", "expires_at": "2017-08-29T22:18:44.315Z" }'));
        objEnrolmentRetalPandaDocController.createSession();
        test.stopTest();
    }
    private static testMethod  void test_getRentalEnrolmentAggrementSignUser(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__r.PersonEmail from Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        PageReference myVfPage = Page.EnrolmentDeliveryPandaDoc;
        Test.setCurrentPage(myVfPage);
        // Put Id into the current page Parameters
        test.startTest();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'Packers and Movers',
            Email = 'PackersandMovers@tmc.com',
            Username = 'PackersandMovers@tmc.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('id', enrolmentList[0].id);
            ApexPages.currentPage().getParameters().put('type', 'Delivery_Person');
            EnrolmentRetalPandaDocController objEnrolmentRetalPandaDocController = new EnrolmentRetalPandaDocController();
        }
        test.stopTest();
    }
}