@isTest
public class TestFifthBookingNotificationSchedular {
    
    @isTest
    public static void invokeTestFifthBookingNotificationSchedular(){
        Account objtchr=TestUtil.createAccount('Teacher',false,true);
        Account objCustmr=TestUtil.createAccount('Customer', True, true);
        objCustmr.FCM_Token__c = 'test';
        update objCustmr; 
        Booking__c objBook=TestUtil.createBooking(objtchr.id,'Lesson','Regular', False);
        Fifth_Lesson__c lesson = new Fifth_Lesson__c();
        lesson.Parent__c = objCustmr.id;
        lesson.Student__c = objCustmr.id;
        lesson.Booking_Date__c = System.today().addDays(10);
        lesson.start_time__c = System.now().time();
        insert lesson;
        FifthBookingNotificationSchedular objFifthBookRem= new FifthBookingNotificationSchedular();
        objFifthBookRem.execute(null);
    }
}