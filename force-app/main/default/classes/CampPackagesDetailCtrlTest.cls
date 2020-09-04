/**
* Name: CampPackagesDetailCtrlTest
* Author: Jatin
* Date : 10-March-2020
* Description: this class Used to test CampPackagesDetailCtrlTest controller class
*/
@isTest
public class CampPackagesDetailCtrlTest {
    
    @testSetup
    private static void createData(){
        CampEnrolmentTestHelper.createCampData();
        
    }
    private static testMethod  void testCampPackage(){
        CampPackagesDetailCtrl objController = new CampPackagesDetailCtrl();
        list<Camp__c> lstCamps = [SELECT Id, Maximum_Age__c, Minimum_Age__c, Name FROM Camp__c limit 2];
        objController.campId = lstCamps[0].id;
        objController.stuPreExperience = '';
        objController.birthDate = '';
        objController.getCampDetails();
        objController.getAccoungGenderPicklist();
    } 
}