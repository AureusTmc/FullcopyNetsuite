/**
* Name: TerminationCompletedEnrolmentTest
* Author: Jatin
* Date : 16-March-2020
* Description: this class Used to test TerminationCompletedEnrolmentController  controller class
*/
@isTest
public class TerminationCompletedEnrolmentTest {
    @testSetup
    private static void createData(){
        PianoRentalTestHelper.createPianoRentalData();
    }
    
    //if  Termination_Inspection_Completed__c = true
    private static testMethod void testUpdateEnrollment(){
        list<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c 
                                            where Stage__c =: ConstantsClass.enrollmentPianoTerminationInProgressStage
                                           ];
        
        for(Enrolment__c objEnrolment : lstEnrolments){
            objEnrolment.Piano_Pickup_date__c = System.today().addDays(-10);
            objEnrolment.Termination_Inspection_Completed__c = true;
        }
        update lstEnrolments;
        
        ApexPages.StandardController objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        TerminationCompletedEnrolmentController objController = new TerminationCompletedEnrolmentController(objStandarCon);
        objController.updateEnrolment();
        
        System.assertEquals(true,objController.errorString == 'Success');
    }
    
    //if  Termination_Inspection_Completed__c = false
    private static testMethod void testUpdateEnrollment2() {
        list<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1 ];
        
        for(Enrolment__c objEnrolment : lstEnrolments){
            objEnrolment.Termination_Inspection_Completed__c = false;
        }
        update lstEnrolments;
        ApexPages.StandardController objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        TerminationCompletedEnrolmentController objController = new TerminationCompletedEnrolmentController(objStandarCon);
        objController.updateEnrolment();
        
        System.assertEquals(true,objController.errorString == 'Please Submit Inspection Report');
    }
    	
    //if( ! objEnrolment.Stage__c.equalsIgnoreCase(ConstantsClass.enrollmentPianoTerminationInProgressStage)) 
    private static testMethod void testUpdateEnrollment3(){
        list<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1 ];
        
        for(Enrolment__c objEnrolment : lstEnrolments){
            objEnrolment.Stage__c = ConstantsClass.enrollmentPianoRentalActiveStage;
            objEnrolment.Termination_Inspection_Completed__c = true;
            
        }
        update lstEnrolments;
        ApexPages.StandardController objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        TerminationCompletedEnrolmentController objController = new TerminationCompletedEnrolmentController(objStandarCon);
        objController.updateEnrolment();
        System.assertEquals(true,objController.errorString == 'Enrolement Stage is not \'Piano Termination In-Progress\'');
    }
    
}