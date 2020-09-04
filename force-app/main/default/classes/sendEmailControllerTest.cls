/*
Name        :        sendEmailControllerTest
Date        :        2 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of sendEmailController.
*/
@isTest
public class sendEmailControllerTest {
    public static testmethod void invokeSendEmailController(){
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        Booking__C objBook=TestUtil.createBooking(objTchr.Id,'Lesson','Regular',True);
        list<EmailTemplate> objEmailTemp=[SELECT Id, Name, Subject, body, FolderName FROM EmailTemplate WHERE IsActive = true AND Folder.Name= 'Aureus Email Calender'];
        sendEmailController objSEC= new sendEmailController();
        objSEC.getEmailTemplates();
        sendEmailController.bookingId=objBook.id;
        if(objEmailTemp.size()>0)
            sendEmailController.templatePreview(objEmailTemp[0].id,sendEmailController.bookingId);
    }
}