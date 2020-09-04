/**
* Name: SubmitInspectionReportControllerTest
* Author: Jatin
* Date : 11-March-2020
* Description: this class Used to test SubmitInspectionReportController controller class
*/
@isTest
public class SubmitInspectionReportControllerTest {
    
    @testSetup
    private static void createData(){
        PianoRentalTestHelper.createPianoRentalData();
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        
    }
    
    Private testMethod static void testupdateParentAccount(){
        list<Enrolment__c> lstEnrolments = [SELECT Id,Stage__c FROM Enrolment__c where Stage__c =: ConstantsClass.enrollmentPianoTerminationInProgressStage ];
        
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        system.assert(string.isNotBlank(cvList[0].ContentDocumentId));
        
        SubmitInspectionReportController.getType(lstEnrolments[0].id);
        SubmitInspectionReportController.updateParentAccount(lstEnrolments[0].id,'test enrolment',cvList[0].ContentDocumentId,lstEnrolments[0].Stage__c);
        
        
    } 
    private testMethod static void testupdateParentAccount2(){
        list<Enrolment__c> lstEnrolments = [SELECT Id,Stage__c FROM Enrolment__c];
        
        for(Enrolment__c objEnrollment : lstEnrolments){
            lstEnrolments[0].stage__c = ConstantsClass.enrollmentPianoRentalActiveStage;
        }
        update lstEnrolments;
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        system.assert(string.isNotBlank(cvList[0].ContentDocumentId));
        
        SubmitInspectionReportController.getType(lstEnrolments[0].id);
        SubmitInspectionReportController.updateParentAccount(lstEnrolments[0].id,'test enrolment',cvList[0].ContentDocumentId,lstEnrolments[0].Stage__c);
        
        
    }
}