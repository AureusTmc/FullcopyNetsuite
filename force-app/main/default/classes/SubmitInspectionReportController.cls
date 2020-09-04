/*
    Name: SubmitInspectionReportController
    Date: 23-jan-2020
    Author: JATIN
    Description :  this controller for submit inspaction report as a attachment 
*/
public with sharing class SubmitInspectionReportController {
    

    // get enrolment details
    @AuraEnabled
    public static list<Enrolment__c> getType(string enrolId){
        list<Enrolment__c> enrList= [select Id,Type__c,Parent__c,Model__c,Serial_Number__c,Stage__c From Enrolment__c where Id=:enrolId];
        return enrList;
    }

    // update enrolment if stage is 'Piano Termination In-Progress' then update termination check box 
    // other wise update initial inspection check box value
    @AuraEnabled
    public static string  updateParentAccount(Id enrolId, String fileName, String fileId,String enrolStage) {
        try{
            if(string.isNotBlank(enrolId)&& String.isNotBlank(enrolStage)){
                Enrolment__c objenr = new Enrolment__c();
                if(enrolStage == ConstantsClass.enrollmentPianoTerminationInProgressStage){
                    objenr = new Enrolment__c(id = enrolId,Termination_Inspection_Completed__c = true);
                }else{
                    objenr = new Enrolment__c(id = enrolId,Initial_Inspection_Completed__c = true);
                }
                update objenr;
            }
            if(string.isNotBlank(fileId)&& String.isNotBlank(fileName)){
                ContentDocument objContentDocument = new ContentDocument(id=fileId,Title=fileName);
                update objContentDocument;
            }
        }catch(Exception e){
            return e.getMessage();
        }
        return 'SUCCESS';
    }
}