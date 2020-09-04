/**
* Name: PianoRentalHelperControllerTest
* Author: Jatin
* Date : 16-March-2020
* Description: this class Used to test PianoRentalHelperControllerTest controller class
*/
@isTest
public class PianoRentalHelperControllerTest {
    @testSetup
    private static void createData() {
        PianoRentalTestHelper.createPianoRentalData();
    }
    private static testMethod  void test_getRentalEnrolmentList(){
        List<Enrolment__c> enrolmentList = [Select Id from Enrolment__c];
        List<Invoice_Line_Item__c> listOfInvoice_Line_Item= [Select Id,Invoice__c,Enrolment__C from Invoice_Line_Item__c where Invoice__r.Status__C = :ConstantsClass.dueStatus];
        List<Invoice__C> listofInvoice = [SELECT Id,Name,Total_Amount__c,
                                          Center__r.Location__c,Parent_Account__r.personContactId,
                                          status__c FROM Invoice__c
                                          where id=:listOfInvoice_Line_Item[0].Invoice__c];
        enrolmentList = PianoRentalHelperController.getRentalEnrolmentList(New Set<String>{enrolmentList[0].id,enrolmentList[1].id}); 
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
            List<User> listOfUser = PianoRentalHelperController.getPackerAndRemoverUser();
            system.assert(listOfUser.size() > 0);
        }
        
        Map<String,Decimal> mapOfTotalcurrentMonthDueInvoiceAmount = PianoRentalHelperController.getCurrentMonthInvoiceAmount(New Set<String>{enrolmentList[0].id,enrolmentList[1].id},ConstantsClass.dueStatus);
        system.assert(mapOfTotalcurrentMonthDueInvoiceAmount.size() > 0);
        PianoRentalHelperController.createInvoicePianoRent('piano', 2, 2, 30,60);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        PianoRentalHelperController.getPaymentForInvoices(New Map<String,String> {listOfInvoice_Line_Item[0].Invoice__c => listOfInvoice_Line_Item[0].Enrolment__C},'Instrument_Delivery_Confirmation'); 
        test.stopTest();
        PianoRentalHelperController.createInvoicelineItem(enrolmentList[0], mapOfTotalcurrentMonthDueInvoiceAmount.get(enrolmentList[0].id), enrolmentList[0].Subscription_Line_Items__r[0],  enrolmentList[0].center__r.country__r);
        map<string,Attachment> mapOfInvoiceAttachment = PianoRentalHelperController.createInvoiceAttachment(listofInvoice);
        map<String ,Blob> mapOfAttachment = new map<String ,Blob>{listofInvoice[0].id=>mapOfInvoiceAttachment.get(listofInvoice[0].id).Body};
            PianoRentalHelperController.sendEmailWithInvoiceAttachment(new Map<string,map<String ,Blob>>{listofInvoice[0].id =>mapOfAttachment},New LIst<Invoice__C> {listofInvoice[0]},'Rental Purchase Invoice');
    }
    private static testMethod  void test_PandaDocPurchaseAggrement(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__c,Parent__r.PersonEmail, center__c,teacher__c,package__C,(SELECT Id FROM Subscription_Line_Items__r )
                                            from Enrolment__c];
        enrolmentList[0].Selling_price__c = 1200;
        enrolmentList[0].Delivery_Charges__c = 100;
        enrolmentList[0].Model__c ='TestModel';
        enrolmentList[0].Serial_Number__c ='1235'; 
        update enrolmentList[0];
        List<invoice__c> listOfinvoice = new List<invoice__c>();
        listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(enrolmentList[0].Parent__c,enrolmentList[0].center__c,false));
        listOfinvoice[0].Invoice_Type__c = ConstantsClass.recurringInvoiceType;
        listOfinvoice[0].status__C = ConstantsClass.paidStatus;
        listOfinvoice[0].Due_Date__c =  Date.newInstance(system.today().AddMonths(-2).year(), system.today().AddMonths(-2).month(), system.today().AddMonths(-2).day());
        
        insert listOfinvoice;
        
        List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,enrolmentList[0].teacher__c,date.today().addDays(2),enrolmentList[0].id, enrolmentList[0].Subscription_Line_Items__r[0].id,enrolmentList[0].package__C,10.00,false));
        insert listOfInvoice_Line_Item;    
        
        List<Payment__c> listOfPayment = new List<Payment__c>();
        listOfPayment.add(AureusCalendarControllerTestHelper.createPayment(enrolmentList[0].Parent__c,listOfinvoice[0].id,false));
         PianoRentalHelperController.get4MonthPaidInvoiceAmountWithDate(New Set<String>{enrolmentList[0].id,enrolmentList[1].id});
        insert listOfPayment;
        enrolmentList = PianoRentalHelperController.getRentalEnrolmentList(New Set<String>{enrolmentList[0].id,enrolmentList[1].id}); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.uploaded", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        test.startTest();
        map<String,PandaDocUtility.CreateDocument> MapOfDocumentDetails = PianoRentalHelperController.signAgreement(New Set<String>{enrolmentList[0].id},'Purchase Aggrement');
        system.assert(MapOfDocumentDetails.size() > 0);
        system.assert(string.isNotBlank(MapOfDocumentDetails.get(enrolmentList[0].id).id ));
        map<String,PandaDocUtility.Document> document = PianoRentalHelperController.waitAgreement(new map<string,string>{enrolmentList[0].id => MapOfDocumentDetails.get(enrolmentList[0].id).id});
        PianoRentalHelperController.sendAgreement(new map<string,string>{enrolmentList[0].id => MapOfDocumentDetails.get(enrolmentList[0].id).id});
        PianoRentalHelperController.createSession(MapOfDocumentDetails.get(enrolmentList[0].id).id,enrolmentList[0].Parent__r.PersonEmail);
        DocumentWrapperForPianoPurchase.Fields objfield = new DocumentWrapperForPianoPurchase.Fields(enrolmentList[0].Parent__c, 'Parent Name');       
        test.stopTest();
    }
    private static testMethod  void test_PandaDocPianoRentalAggrement(){
        List<Enrolment__c> enrolmentList = [Select Id,Parent__c,Parent__r.PersonEmail, center__c,teacher__c,package__C,(SELECT Id FROM Subscription_Line_Items__r )
                                            from Enrolment__c];
        enrolmentList[0].Selling_price__c = 1200;
        enrolmentList[0].Delivery_Charges__c = 100;
        enrolmentList[0].Model__c ='TestModel';
        enrolmentList[0].Serial_Number__c ='1235'; 
        enrolmentList[0].Final_Delivery_date__c = system.today();
        enrolmentList[0]. Final_Delivery_Timeslot__c = system.now().time();
        update enrolmentList[0];
        List<invoice__c> listOfinvoice = new List<invoice__c>();
        listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(enrolmentList[0].Parent__c,enrolmentList[0].center__c,false));
        listOfinvoice[0].Invoice_Type__c = ConstantsClass.recurringInvoiceType;
        listOfinvoice[0].status__C = ConstantsClass.paidStatus;
        listOfinvoice[0].Due_Date__c =  Date.newInstance(system.today().AddMonths(-2).year(), system.today().AddMonths(-2).month(), system.today().AddMonths(-2).day());
        insert listOfinvoice;
        
        List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,enrolmentList[0].teacher__c,date.today().addDays(2),enrolmentList[0].id, enrolmentList[0].Subscription_Line_Items__r[0].id,enrolmentList[0].package__C,10.00,false));
        insert listOfInvoice_Line_Item;    
        
        List<Payment__c> listOfPayment = new List<Payment__c>();
        listOfPayment.add(AureusCalendarControllerTestHelper.createPayment(enrolmentList[0].Parent__c,listOfinvoice[0].id,false));
        insert listOfPayment;
        enrolmentList = PianoRentalHelperController.getRentalEnrolmentList(New Set<String>{enrolmentList[0].id,enrolmentList[1].id}); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.uploaded", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
       
        test.startTest();
        map<String,PandaDocUtility.CreateDocument> MapOfDocumentDetails = PianoRentalHelperController.signAgreement(New Set<String>{enrolmentList[0].id},'Rental Aggrement');
        
        system.assert(MapOfDocumentDetails.size() > 0);
        system.assert(string.isNotBlank(MapOfDocumentDetails.get(enrolmentList[0].id).id ));
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "R33xS4Ybe3qtBbRyke2p6a", "name": "[DEV] Enr-13456-RentalPolicy", "date_created": "2020-01-22T08:20:58.179132Z", "date_modified": "2020-01-22T08:20:58.652923Z", "template": { "id": "5jfk4yvnNWaqsjmg4tdnbm", "name": "Delivery Order Template" }, "tokens": [{ "name": "Delivery_Person.FirstName" }], "fields": [{ "uuid": "NmobNHTwG6fdu5bVcnAUbZ", "name": "Stairs", "title": "Stairs", "assigned_to": { "id": "QpQRqhYV4k9K95kAqrgaof", "first_name": "Ashish", "last_name": "Bansal", "email": "ashish@outlook.com", "recipient_type": "signer", "has_completed": false, "role": "Delivery_Person", "type": "recipient" }, "value": "0" }] }'));
        PianoRentalHelperController.getDocumentStairs(MapOfDocumentDetails.get(enrolmentList[0].id).id);
        map<String,PandaDocUtility.Document> document = PianoRentalHelperController.waitAgreement(new map<string,string>{enrolmentList[0].id => MapOfDocumentDetails.get(enrolmentList[0].id).id});
        PianoRentalHelperController.sendAgreement(new map<string,string>{enrolmentList[0].id => MapOfDocumentDetails.get(enrolmentList[0].id).id});
        PianoRentalHelperController.createSession(MapOfDocumentDetails.get(enrolmentList[0].id).id,enrolmentList[0].Parent__r.PersonEmail);
        test.stopTest();
    }
}