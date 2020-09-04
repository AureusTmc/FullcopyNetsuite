/**
* Name: AllCampEnrolmentMultiStudentsCtrlTest
* Author: Jatin
* Date : 10-March-2020
* Description: this class Used to test AllCampEnrolmentMultiStudentsCtrl controller class
*/
@isTest
Public class AllCampEnrolmentMultiStudentsCtrlTest {
    @testSetup
    private static void createData() {
        CampEnrolmentTestHelper.createCampData();
    } 
    
    Private testMethod static  void testActiveCamp(){
        List<camp__c> listOfCamp = [select id,Centre__c from camp__c];
        test.startTest(); 
        AllCampEnrolmentMultiStudentsCtrl  objCampEnrolment = new AllCampEnrolmentMultiStudentsCtrl();
        objCampEnrolment.centerId = listOfCamp[0].Centre__c;
        objCampEnrolment.enrolCampId = listOfCamp[0].id;
        objCampEnrolment.getCampId();
        test.stopTest();
        
    }
    Private testMethod static  void testActiveCampAureusCenter(){
        List<camp__c> listOfCamp = [select id,Centre__c from camp__c];
        listOfCamp[0].Centre__c = Label.Aureus_at_Home_Id;
        update listOfCamp[0];
        test.startTest(); 
        AllCampEnrolmentMultiStudentsCtrl  objCampEnrolment = new AllCampEnrolmentMultiStudentsCtrl();
        objCampEnrolment.centerId = Label.Aureus_at_Home_Id;
        objCampEnrolment.enrolCampId = listOfCamp[0].id;
        objCampEnrolment.getCampId();
        test.stopTest();
        
    }
}