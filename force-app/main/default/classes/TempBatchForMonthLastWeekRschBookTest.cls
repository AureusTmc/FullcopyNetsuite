/*
Name        :    TempBatchForMonthLastWeekRschBookTest
Date        :    07/16/2019
Author      :    Karan 

*/

@isTest
public class TempBatchForMonthLastWeekRschBookTest {

    public static testMethod void invokeTempBatchForMonthLastWeekRschBook(){
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
        objBook2.Booking_Date__c = objBook.Booking_Date__c.addDays(40);
        
        insert objBook2;
        
        TempBatchForMonthLastWeekRschBook objTempBatch = new TempBatchForMonthLastWeekRschBook();
        Database.executeBatch(objTempBatch);
    }
}