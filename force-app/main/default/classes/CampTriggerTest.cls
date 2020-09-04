/**
* Name: CampTriggerTest
* Author: Jatin
* Date : 13-March-2020
* Description: this class Used to test CampTriggerTest Trigger
*/
@isTest
public class CampTriggerTest {
    @testSetup
    private static void createData() {
        CampEnrolmentTestHelper.createCampData();
    }
    
    private static testMethod void testCampUpdateInActiveStatus() {
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c !=: ConstantsClass.campActiveStatus];
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
        for(Camp__c objCamp : lstCamps){
            objCamp.Status__c = ConstantsClass.campActiveStatus;
        }
        update lstCamps;
        List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:lstCampDays[0].id 
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        test.stopTest();
    }
    
    private static testMethod void testCampUpdateInCancelledStatus() {
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus];
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
        for(Camp__c objCamp : lstCamps){
            objCamp.Status__c = ConstantsClass.campCancelledStatus;
        }
        update lstCamps;
        List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:lstCampDays[0].id 
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        test.stopTest();
    }
    private static testMethod void testActiveCampDelete() {
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus];
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
        Delete lstCamps;
        List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:lstCampDays[0].id 
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() == 0); 
        test.stopTest();
    }
    
    private static testMethod void testActiveCampUnDelete() {
        list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c =: ConstantsClass.campActiveStatus];
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
        Delete lstCamps;
        UnDelete lstCamps;
        List<Booking__C> listofBooking = [Select id from Booking__c 
                                          where Camp_Days__c =:lstCampDays[0].id 
                                          AND status__c =: ConstantsClass.scheduledStatus
                                          AND Category__c =: ConstantsClass.bookingCategoryCamp
                                          AND Teacher_Account__c =:listOfCamp_Day_Teachers[0].Camp_Teacher__c];
        system.assert(listofBooking.size() > 0); 
        test.stopTest();
    }
    
    /*  private static testMethod void testDelete(){
list<Camp__c> lstCamps = [SELECT Id, Status__c FROM Camp__c WHERE status__c != Null];
//delete lstCamps;

for(Camp__c objCamp : lstCamps){
objCamp.Status__c = 'Active';
}
System.assertEquals(false,lstCamps[0].Status__c != 'Active');

if(lstCamps.size()>0){
update lstCamps;
delete lstCamps;
undelete lstCamps;
}
System.assertEquals(false, lstCamps.size() < 1);
}*/
    
}