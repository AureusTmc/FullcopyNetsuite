/**
* Name: CampClassUtilityControllerTest
* Author: Jatin
* Date : 14-March-2020
* Description: this class Used to test CampClassUtilityController controller class
*/
@isTest
public class CampClassUtilityControllerTest {
    
    @testSetup
    private static void createData() {
        CampEnrolmentTestHelper.createCampData();
    }
    private static testMethod  void test_CampClassUtilityControllerTest(){
         list<Camp__c> lstCamp= [SELECT Id,Centre__c,Centre__r.Country__r.Currency_Code__c, Name
                                FROM Camp__c
                                Where Status__c =:ConstantsClass.campActiveStatus];
        list<Camp_Available_Package__c> lstPackages = [SELECT Id, Name,No_of_days__c FROM Camp_Available_Package__c 
                                                       where Camp_Name__c =:lstCamp[0].id 
                                                       and Active__c= true  
                                                       Order by No_of_days__c DESC];
        
        list<Camp_Days__c> lstCampDays = [ SELECT id,Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamp[0].id 
                                          and Status__c ='Active'
                                          Order by Dates_Of_The_Camp__c];
        List<Camp_Day_Teachers__c> listOfCamp_Day_Teachers = [Select id,Camp_Teacher__c,Camp_Day__c
                                                              from Camp_Day_Teachers__c
                                                              where Camp_Day__c=: lstCampDays[0].id];
        List<camp__c> ListOfCamp =CampClassUtilityController.getCampList(lstCamp[0].Centre__c,lstCamp[0].id,
                                                                         new set<string>{lstPackages[0].id},new set<string>{lstCampDays[0].id});
        
        ListOfCamp = CampClassUtilityController.getCampList(lstCamp[0].Centre__c,lstCamp[0].id,
                                                            lstPackages[0].id,new set<string>{string.valueOf(lstCampDays[0].id)});
        
        CampClassUtilityController.getPicklistValues('Camp__c','Status__c');
        CampClassUtilityController.getTeacherWorkingHoursList(new set<string>{listOfCamp_Day_Teachers[0].Camp_Teacher__c},new set<string>{listOfCamp_Day_Teachers[0].Camp_Day__c},lstCamp[0].Centre__c);
    	CampClassUtilityController.getCampDaysTeachers(new set<Id>{lstCampDays[0].id});
        List<Booking__C> listOfbooking = [select id,Student__c,Enrolment__c,Teacher_Account__c,Camp_Id__c,Camp_Days__c,Package__c,Center__c,Start_Time__c,
                                             End_Time__c,Booking_Date__c
                                             from Booking__C];
        
        CampClassUtilityController.createCampBooking(listOfbooking[0].Student__c,listOfbooking[0].Enrolment__c,listOfbooking[0].Booking_Date__c,
                                                     listOfbooking[0].End_Time__c,listOfbooking[0].Start_Time__c,listOfbooking[0].Center__c,
                                                     listOfbooking[0].Package__c,listOfbooking[0].Camp_Id__c,listOfbooking[0].Camp_Days__c,'');
    }

}