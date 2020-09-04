/**
* Name: CampDayTeacherTriggerTest
* Author: Jatin
* Date : 13-March-2020
* Description: this class Used to test CampDayTeacherTriggerTest Trigger
*/
@isTest
public class CampDayTeacherTriggerTest {
    @testSetup
    private static void createData() {
        CampEnrolmentTestHelper.createCampData();
    }
    
    // if camp is active and teacher is Active Status
    //  we update teacher records in 'InActive' then check 'PlaceHolder'bookings are Deleted or not
    private static testMethod void testCampTeacherUpdateInActiveStatus() {
        
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus and Name='Test Camp3'];
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamps[0].id 
                                          and Status__c =:ConstantsClass.campDaysActiveStatus
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__r.Camp_Name__c =: lstCamps[0].id
                                                              AND Camp_Day__c =:lstCampDays[1].id
                                                              And Status__c =:ConstantsClass.campTeacherActiveStatus];
        System.debug('!!before'+listOfCamp_Day_Teachers);
        system.assert(listOfCamp_Day_Teachers.size() == 1); 
        test.startTest();
        List<Booking__C> listofBooking = [Select id ,Camp_Days__c,Teacher_Account__c,Camp_Days__r.Camp_Name__c, Booking_date__C from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        System.debug('!!before'+listofBooking);
        for(Camp_Day_Teachers__c objCamp_Day_Teachers : listOfCamp_Day_Teachers){
            objCamp_Day_Teachers.Status__c = ConstantsClass.campTeacherInActiveStatus;
        }
        update listOfCamp_Day_Teachers;
        
        listofBooking = [Select id,Camp_Days__c,Teacher_Account__c,Camp_Days__r.Camp_Name__c, Booking_date__C from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        System.debug('!!after'+listofBooking);
        system.assert(listofBooking.size() == 0,''+listofBooking); 
        test.stopTest();
    }
    
     // if camp is Inactive and teacher is Active Status
    //  we update teacher records in 'InActive' then check 'PlaceHolder'bookings are Deleted or not
    private static testMethod void testCampTeacherUpdateInActiveStatus2() {
        
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c !=: ConstantsClass.campActiveStatus and Name='Test Camp1'];
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamps[0].id 
                                          and Status__c =:ConstantsClass.campDaysActiveStatus
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__r.Camp_Name__c =: lstCamps[0].id
                                                              And Status__c =:ConstantsClass.campTeacherActiveStatus];
        test.startTest();
         List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        for(Camp_Day_Teachers__c objCamp_Day_Teachers : listOfCamp_Day_Teachers){
            objCamp_Day_Teachers.Status__c = ConstantsClass.campTeacherInActiveStatus;
        }
        update listOfCamp_Day_Teachers;
        listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        test.stopTest();
    }
    
     // if camp is active and teacher is Inactive Status
    //  we update teacher records in 'Active' then check 'PlaceHolder'bookings are created or not
    private static testMethod void testCampTeacherUpdateActiveStatus() {
        
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus and Name='Test Camp3'];
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamps[0].id 
                                          and Status__c =:ConstantsClass.campDaysActiveStatus
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__r.Camp_Name__c =: lstCamps[0].id
                                                              And Status__c !=:ConstantsClass.campTeacherActiveStatus];
        test.startTest();
        for(Camp_Day_Teachers__c objCamp_Day_Teachers : listOfCamp_Day_Teachers){
            objCamp_Day_Teachers.Status__c = ConstantsClass.campTeacherActiveStatus;
        }
        update listOfCamp_Day_Teachers;
        
        List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        test.stopTest();
    }
    // if camp is Inactive and teacher is also Inactive Status
    // if we update teacher records in 'Active' then check 'PlaceHolder'bookings are created or not
    private static testMethod void testCampTeacherUpdateActiveStatus2() {
        
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c !=: ConstantsClass.campActiveStatus and Name='Test Camp1'];
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamps[0].id 
                                          and Status__c =:ConstantsClass.campDaysActiveStatus
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__r.Camp_Name__c =: lstCamps[0].id
                                                              And Status__c !=:ConstantsClass.campTeacherActiveStatus];
        test.startTest();
        for(Camp_Day_Teachers__c objCamp_Day_Teachers : listOfCamp_Day_Teachers){
            objCamp_Day_Teachers.Status__c = ConstantsClass.campTeacherActiveStatus;
        }
        update listOfCamp_Day_Teachers;
        List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        test.stopTest();
    }
   
     // if camp is active and teacher is Inactive Status
    //  we Delete or undelete teacher records in 'Active' then check 'PlaceHolder'bookings are created or not
    private static testMethod void testCampTeacherDeleteOrUndeleteActiveStatus() {
        
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus and Name='Test Camp3'];
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamps[0].id 
                                          and Status__c =:ConstantsClass.campDaysActiveStatus
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__r.Camp_Name__c =: lstCamps[0].id
                                                              And Status__c =:ConstantsClass.campTeacherActiveStatus];
        test.startTest();
       Delete listOfCamp_Day_Teachers;
         List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        undelete listOfCamp_Day_Teachers;
        listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        test.stopTest();
    }
    
     // if camp is active and teacher is Inactive Status
    //  we update teacher records in 'Active' then check 'PlaceHolder'bookings are created or not
    private static testMethod void testCampTeacherUpdateCampDayId() {
        
       list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus and Name='Test Camp3'];
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamps[0].id 
                                          and Status__c =:ConstantsClass.campDaysActiveStatus
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__r.Camp_Name__c =: lstCamps[0].id
                                                              AND Camp_Day__c =:lstCampDays[1].id
                                                              And Status__c =:ConstantsClass.campTeacherActiveStatus];
        test.startTest();
        List<Booking__C> listofBooking = [Select id,Camp_Days__c,Teacher_Account__c,Camp_Days__r.Camp_Name__c, Booking_date__C from Booking__c 
                                          where Camp_Days__c =:listOfCamp_Day_Teachers[0].Camp_Day__c
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        for(Camp_Day_Teachers__c objCamp_Day_Teachers : listOfCamp_Day_Teachers){
            objCamp_Day_Teachers.Camp_Day__c = lstCampDays[0].id;
        }
        update listOfCamp_Day_Teachers;
        
       listofBooking = [Select id,Camp_Days__c,Teacher_Account__c,Camp_Days__r.Camp_Name__c, Booking_date__C from Booking__c 
                                          where Camp_Days__c =:lstCampDays[1].id
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        listofBooking = [Select id,Camp_Days__c,Teacher_Account__c,Camp_Days__r.Camp_Name__c, Booking_date__C from Booking__c 
                                          where Camp_Days__c =:lstCampDays[0].id
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        test.stopTest();
    }
    
}