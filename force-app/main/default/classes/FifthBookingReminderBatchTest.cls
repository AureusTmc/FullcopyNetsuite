/*
Name        :        FifthBookingReminderBatchTest
Date        :        3 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of FifthBookingReminderBatch.
*/
@istest	
public class FifthBookingReminderBatchTest {
    public static testMethod void invokeFifthBookingReminderBatch(){
        Account objtchr=TestUtil.createAccount('Teacher',false,true);
        Account objCustmr=TestUtil.createAccount('Customer', True, true);
        Booking__c objBook=TestUtil.createBooking(objtchr.id,'Lesson','Regular', False);
        objBook.Is_fifth_booking__c=True;
        objBook.Student__c=objCustmr.id;
        insert objBook;
        test.startTest();
        FifthBookingReminderBatch objFBRB= new FifthBookingReminderBatch(1);
        DataBase.executeBatch(objFBRB);
        test.stopTest();
    }
}