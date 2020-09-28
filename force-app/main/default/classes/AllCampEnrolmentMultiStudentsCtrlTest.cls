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
        List<camp__c> listOfCamp = [select id,Centre__c,Centre__r.Organisation__c from camp__c where Centre__r.name !='Ossia Junction 10'];
        test.startTest(); 
        AllCampEnrolmentMultiStudentsCtrl  objCampEnrolment = new AllCampEnrolmentMultiStudentsCtrl();
        objCampEnrolment.centerId = listOfCamp[0].Centre__c;
        objCampEnrolment.enrolCampId = listOfCamp[0].id;
        objCampEnrolment.getActiveCamps(listOfCamp[0].Centre__r.Organisation__c);
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
    // added by nishi: 28-Sep-2020: for cover ossia related changes
    Private testMethod static  void testActiveOssiaCamp(){
        List<camp__c> listOfCamp = [select id,Centre__c,Centre__r.Organisation__c from camp__c where Centre__r.name ='Ossia Junction 10'];
        test.startTest(); 
        Test.setCurrentPageReference(new PageReference('Page.AllCampEnrolment_MultiStudents')); 
        System.currentPageReference().getParameters().put('org', 'ossia');
        AllCampEnrolmentMultiStudentsCtrl  objCampEnrolment = new AllCampEnrolmentMultiStudentsCtrl();
        objCampEnrolment.getActiveCamps(listOfCamp[0].Centre__r.Organisation__c);
        objCampEnrolment.centerId = listOfCamp[0].Centre__c;
        objCampEnrolment.enrolCampId = listOfCamp[0].id;
        objCampEnrolment.getCampId();
        test.stopTest();
        
    }
}