/**
* Name: TerminateRentalSummaryControllerTest
* Author: Jatin
* Date : 16-March-2020
* Description: this class Used to test TerminateRentalSummaryController controller class
*/
@isTest
public class TerminateRentalSummaryControllerTest {
    
    @testSetup
    private static  void createData(){
        PianoRentalTestHelper.createPianoRentalData();
    }
    //if isButton = true;
    private static testMethod void testSubmitTerminateRentalSummaryRequest1(){
        list<Enrolment__c> lstEnrolments = [SELECT Id, Termination_request_date__c,Piano_Pickup_date__c,
                                            Termination_Reason__c,Termination_Reason_others__c
                                            FROM Enrolment__c
                                           ];
        
        for(Enrolment__c objEnrollment :lstEnrolments) {
            objEnrollment.Termination_request_date__c = System.today().addDays(30);
            objEnrollment.Termination_Reason__c = 'Others'; 
        }
        update lstEnrolments;
        Test.StartTest(); 
        PageReference pageRef = Page.TerminationSummaryPage; 
        pageRef.getParameters().put('enrolmentId', String.valueOf(lstEnrolments[0].Id));
        Test.setCurrentPage(pageRef);
        Test.StopTest();
        TerminateRentalSummaryController objController = new TerminateRentalSummaryController();
        TerminateRentalSummaryController.submitTerminateRentalSummaryRequest(string.valueOf(lstEnrolments[0].Id), string.valueOf(lstEnrolments[0].Termination_request_date__c),
                                                                             string.valueOf(lstEnrolments[0].Piano_Pickup_date__c), string.valueOf(lstEnrolments[0].Termination_Reason__c),
                                                                             string.valueOf(lstEnrolments[0].Termination_Reason_others__c),true);
    }
    //if isButton = false;
    private static testMethod void testSubmitTerminateRentalSummaryRequest2(){
        list<Enrolment__c> lstEnrolments = [SELECT Id, Termination_request_date__c,Piano_Pickup_date__c,
                                            Termination_Reason__c,Termination_Reason_others__c
                                            FROM Enrolment__c
                                           ];
        
        for(Enrolment__c objEnrollment :lstEnrolments) {
            objEnrollment.Termination_request_date__c = System.today().addDays(30);
            objEnrollment.Termination_Reason__c = 'Others'; 
            objEnrollment.Stage__c = 'Piano Termination In-Progress';
        }
        update lstEnrolments;
        Test.StartTest(); 
        PageReference pageRef = Page.TerminationSummaryPage; 
        pageRef.getParameters().put('enrolmentId', String.valueOf(lstEnrolments[0].Id));
        Test.setCurrentPage(pageRef);
        Test.StopTest();
        
        TerminateRentalSummaryController objController = new TerminateRentalSummaryController();
        
        TerminateRentalSummaryController.submitTerminateRentalSummaryRequest(string.valueOf(lstEnrolments[0].Id), string.valueOf(lstEnrolments[0].Termination_request_date__c),
                                                                             string.valueOf(lstEnrolments[0].Piano_Pickup_date__c), string.valueOf(lstEnrolments[0].Termination_Reason__c),
                                                                             string.valueOf(lstEnrolments[0].Termination_Reason_others__c),false);
    }
    private static testMethod void testTerminateRentalSummary() {
        list<Enrolment__c> lstEnrolments = [SELECT Id, Termination_request_date__c,Piano_Pickup_date__c,
                                            Termination_Reason__c,Termination_Reason_others__c
                                            FROM Enrolment__c
                                           ];
        
        for(Enrolment__c objEnrollment :lstEnrolments) {
            objEnrollment.Termination_request_date__c = System.today();
            objEnrollment.Piano_Pickup_date__c = System.today();
            
        }
        TerminateRentalSummaryController.getTerminateRentalSummary(string.valueOf(lstEnrolments[0].Id),string.valueOf(lstEnrolments[0].Termination_request_date__c),
                                                                   string.valueOf(lstEnrolments[0].Piano_Pickup_date__c),string.valueOf(lstEnrolments[0].Termination_Reason__c),
                                                                   string.valueOf(lstEnrolments[0].Termination_Reason_others__c));
    }
    
}