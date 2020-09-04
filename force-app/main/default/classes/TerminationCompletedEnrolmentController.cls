/*
    Name: TerminationCompletedEnrolmentController
    Date: 25-Jan-2020
    Author: JATIN
    Description :  this controller for termination piano rental completed 
*/
public with sharing class TerminationCompletedEnrolmentController {
    Public Enrolment__c objEnrolment{get;set;}
    Public string  errorString {get;set;}
    
    public TerminationCompletedEnrolmentController(ApexPages.StandardController st) {
        objEnrolment = (Enrolment__c)st.getRecord();
        if(string.isNotBlank(objEnrolment.Id)){
            List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {objEnrolment.Id});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                objEnrolment = listOfenrolment[0];
            }
        }
    }

    // after this complete termination then we update enrolment stage and  upate subscription end date
    public void updateEnrolment(){
        errorString = 'Some error Is found';
        if(objEnrolment.Stage__c.equalsIgnoreCase(ConstantsClass.enrollmentPianoTerminationInProgressStage) && objEnrolment.Termination_Inspection_Completed__c
        && objEnrolment.Piano_Pickup_date__c <= System.today() ){
            Enrolment__c objEnrolment1 = new Enrolment__c(id= objEnrolment.id, Stage__c =ConstantsClass.enrollmentPianoRentalTerminatedStage);
            update objEnrolment1;
             map<string,Subscription__c> mapOfSubs = new Map<string,Subscription__c>();
            List<Subscription_Line_Item__c>  listOfSubLineItem = objEnrolment.Subscription_Line_Items__r;
            // After completed this enrolment then we 'In Active' Subscription_Line_Item__c
            if(listOfSubLineItem != null && listOfSubLineItem.size() > 0){
                // 5-Feb-2020: add 'Subscription end date' for subscriptions, subscription line items
                for(Subscription_Line_Item__c objSubLineItem : listOfSubLineItem){
                    //objSubLineItem.Status__c = 'In Active';
                    objSubLineItem.Subscription_Expiry_Date__c = objEnrolment.Termination_request_date__c;
                    mapOfSubs.put(objSubLineItem.Subscription__r.id,new Subscription__c(id=objSubLineItem.Subscription__c,
                                                                             Subscription_End_Date__c =objEnrolment.Termination_request_date__c));
                }
                update listOfSubLineItem;
                if(mapOfSubs != null && mapOfSubs.size() >0){
                    update mapOfSubs.values();
                }
            }
            errorString=  'Success';
        }else if(!objEnrolment.Termination_Inspection_Completed__c){
            errorString = 'Please Submit Inspection Report'; 
        }else if(!objEnrolment.Stage__c.equalsIgnoreCase(ConstantsClass.enrollmentPianoTerminationInProgressStage)){
            errorString =  'Enrolement Stage is not \'Piano Termination In-Progress\'';
        }else if(objEnrolment.Piano_Pickup_date__c > System.today()){
            errorString = System.today().daysBetween(objEnrolment.Piano_Pickup_date__c) +' Days are remaining for Piano Termination'; 
        }
    }
}