@isTest
public class BookingFileDeleteBatchTest {
    @testSetup 
    static void setup() {
        List<Booking__c> bookingList = new List<Booking__c>();
        for (Integer i=0;i<5;i++) {
            date mydate = Date.parse('2'+i+'/06/2020');
            bookingList.add(new Booking__c(Booking_Date__c= mydate, Lesson_Type__c='Online'));
        }
        insert bookingList;
    }
    
    static testmethod void test() {        
        Test.startTest();
        BookingFileDeleteBatch batchCls = new BookingFileDeleteBatch();
        Database.executeBatch(batchCls);
        Test.stopTest();
    }
}