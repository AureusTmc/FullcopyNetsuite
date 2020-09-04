/*
Name        :        EnrolmentThankyouCntrlTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of EnrolmentThankyouCntrl.
*/

@Istest
public class EnrolmentThankyouCntrlTest {
    public Static testMethod Void invokeEnrolmentThankyouCntrl(){
        Account acc = testUtility.createAccount('Test','Customer',true);
        Invoice__c objinvoice = testUtility.createInvoice(acc.id, true);
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,True);
        Case objCase=new Case();
        //objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=acc.id;
        insert objCase;
        ApexPages.currentPage().getParameters().put('inv',objinvoice.id);
        EnrolmentThankyouCntrl objEnrolThank = new EnrolmentThankyouCntrl();
        
        pageReference pdfPage = Page.SubscriptionInvoicePdfClone;
        pdfPage.getParameters().put('inv',objinvoice.id);
       
        objEnrolThank.generateInvPdf();
        EnrolmentThankyouCntrl.fillAtt(Blob.valueOf('test pdf'), String.valueOf(objinvoice.id),'testpdf');
        
        //Insert booking
        Booking__C objBookForStudent=TestUtil.createBooking(null,'Facility','Studio',False);
        objBookForStudent.Student__c = acc.Id;
        objBookForStudent.Parent__c = acc.Id;
        objBookForStudent.Status__c='Completed';
        objBookForStudent.Studio_Booking_Invoice_Number__c = objinvoice.Id;
        insert objBookForStudent;
        
        ApexPages.currentPage().getParameters().put('bookId',objBookForStudent.id);
        ApexPages.currentPage().getParameters().put('type','Studio');
        objEnrolThank.generateInvPdf();
    }
}