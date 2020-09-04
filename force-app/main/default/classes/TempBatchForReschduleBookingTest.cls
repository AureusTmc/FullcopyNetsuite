/*
Name        :    TempBatchForReschduleBookingTest
Date        :    07/15/2019
Author      :    Karan 
Description :    This is temprary batch Test class, which is used to test  correct reschedule bookings
We will deactivate after correct reschedule bookings.
*/
@isTest
public class TempBatchForReschduleBookingTest {
    public static testMethod void invokeTempBatch(){
        
        Map<String,String> createdDataMap = TestUtil.createData();
        
        Enrolment__c objEnrol = new Enrolment__c ();
        objEnrol.Id = createdDataMap.get('objEnrol');
        objEnrol.Last_Reschedule_Date__c = Null;
        objEnrol.Stage__c = 'Enrolled';
        update objEnrol;
        
        Booking__c objBook = new Booking__c();
        objBook.Id = createdDataMap.get('objBook');
        objBook.Type__c = 'Regular';
        objBook.Enrolment__c = objEnrol.id;
        objBook.Booking_Date__c = Date.newInstance(2019, 7, 29);
        update objBook;
        
        Booking__c objBook2 = Testutil.createBooking(createdDataMap.get('objTchr'),'Lesson','Regular',false);
        objBook2.Enrolment__c = objEnrol.id;
        objBook2.Booking_Date__c = objBook.Booking_Date__c.addDays(20);
        
        insert objBook2;
        
        TempBatchForReschduleBooking objTempBatch = new TempBatchForReschduleBooking();
        Database.executeBatch(objTempBatch);
    }
    
}