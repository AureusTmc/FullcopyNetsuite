/*
Name        :        FifthBookingReminderSchedularTest
Date        :        5 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of FifthBookingReminderSchedular.
*/
@istest
public class FifthBookingReminderSchedularTest {
    public static testMethod void invokeFifthBookingReminderSchedular(){
        Account objtchr=TestUtil.createAccount('Teacher',false,true);
        Account objCustmr=TestUtil.createAccount('Customer', True, true);
        Booking__c objBook=TestUtil.createBooking(objtchr.id,'Lesson','Regular', False);
        objBook.Is_fifth_booking__c=True;
        objBook.Student__c=objCustmr.id;
        objBook.Booking_Date__c=Date.today().addDays(10);
        insert objBook;
        FifthBookingReminderSchedular objFifthBookRem= new FifthBookingReminderSchedular();
        objFifthBookRem.execute(null);
     
    }
}