/*
Name        :        EnrolmentThankyouCntrlTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of EnrolmentThankyouCntrl.
*/

@Istest
public class EnrolmentThankyouCntrlTest {
     @testSetup
    private static void createData() {
        AureusCalendarControllerTestHelper.createCalenderData();
    }
    
    public Static testMethod Void invokeEnrolmentThankyouCntrl(){
      /*  Account acc = testUtility.createAccount('Test','Customer',true);
        Invoice__c objinvoice = testUtility.createInvoice(acc.id, true);
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,True);
        Case objCase=new Case();
        //objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=acc.id;
        insert objCase;*/
        test.startTest();
        list<Invoice__c> invoicelist = [select id from Invoice__c];
        list<Booking__C> bookinglist = [select id,teacher_account__c,enrolment__c,parent__c,center__c,package__C from Booking__C];
        ApexPages.currentPage().getParameters().put('inv',invoicelist[0].id);
        EnrolmentThankyouCntrl objEnrolThank = new EnrolmentThankyouCntrl();
        
        pageReference pdfPage = Page.SubscriptionInvoicePdfClone;
        pdfPage.getParameters().put('inv',invoicelist[0].id);
       
        objEnrolThank.generateInvPdf();
        EnrolmentThankyouCntrl.fillAtt(Blob.valueOf('test pdf'), String.valueOf(invoicelist[0].id),'testpdf');
        
        //Insert booking
        Booking__C objBookForStudent=AureusCalendarControllerTestHelper.createBooking(bookinglist[0].teacher_account__c,bookinglist[0].enrolment__c,
                                                                                      bookinglist[0].parent__c,bookinglist[0].center__c,
                                                   bookinglist[0].package__C,date.today(),'Completed','Facility','Studio',false);
        objBookForStudent.Studio_Booking_Invoice_Number__c = invoicelist[0].Id;
        insert objBookForStudent;
        
        ApexPages.currentPage().getParameters().put('bookId',objBookForStudent.id);
        ApexPages.currentPage().getParameters().put('type','Studio');
        objEnrolThank.generateInvPdf();
       
        ApexPages.currentPage().getParameters().put('scId','test');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        objEnrolThank.updateInvoiceNumOnStripe(new set<string> {invoicelist[0].id});
         test.stopTest();
    }
    
    public Static testMethod Void invokeEnrolmentThankyouCntrl2(){
      /*  Account acc = testUtility.createAccount('Test','Customer',true);
        Invoice__c objinvoice = testUtility.createInvoice(acc.id, true);
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,True);
        Case objCase=new Case();
        //objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=acc.id;
        insert objCase;*/
        test.startTest();
        list<Invoice__c> invoicelist = [select id,Parent_Account__C from Invoice__c];
        list<Booking__C> bookinglist = [select id,teacher_account__c,enrolment__c,parent__c,center__c,package__C from Booking__C];
        ApexPages.currentPage().getParameters().put('inv',invoicelist[0].id);
        ApexPages.currentPage().getParameters().put('isOssia','true');
        EnrolmentThankyouCntrl objEnrolThank = new EnrolmentThankyouCntrl();
        Account obj1=new Account();
        obj1.LastName='American club';
        obj1.Membership_Type__c=ConstantsClass.amcClubMember;
        obj1.PersonEmail ='test@test.com';
        insert obj1;
        
        Account objAcc=new Account();
        objAcc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        objAcc.Membership_Type__c=ConstantsClass.amcClubMember;
        objAcc.LastName='test cstmr';
        objAcc.Stripe_Customer_Id__c=NULL;
        objAcc.American_club__c=obj1.id;
        objAcc.Membership_Number__c= '90';
        objAcc.id= invoicelist[0].Parent_Account__c;
         objAcc.PersonEmail ='test@gmail.com';
        update objAcc;
        pageReference pdfPage = Page.SubscriptionInvoicePdfClone;
        pdfPage.getParameters().put('inv',invoicelist[0].id);
       
        objEnrolThank.isOssia = TRUE;
        objEnrolThank.generateInvPdf();
        EnrolmentThankyouCntrl.fillAtt(Blob.valueOf('test pdf'), String.valueOf(invoicelist[0].id),'testpdf');
        
        //Insert booking
        Booking__C objBookForStudent=AureusCalendarControllerTestHelper.createBooking(bookinglist[0].teacher_account__c,bookinglist[0].enrolment__c,
                                                                                      bookinglist[0].parent__c,bookinglist[0].center__c,
                                                   bookinglist[0].package__C,date.today(),'Completed','Facility','Studio',false);
        objBookForStudent.Studio_Booking_Invoice_Number__c = invoicelist[0].Id;
        insert objBookForStudent;
        
        ApexPages.currentPage().getParameters().put('bookId',objBookForStudent.id);
        ApexPages.currentPage().getParameters().put('type','Studio');
        objEnrolThank.generateInvPdf();
        ApexPages.currentPage().getParameters().put('scId','test');
     
         test.stopTest();
    }
   
}