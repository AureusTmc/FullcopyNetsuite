/*
    Name: TerminationEnrolmentProcessController
    Date: 23-jan-2020
    Author: JATIN
    Description :  this controller for Terminating Piano Rental  for get Terminating date and pickup date 
*/
public with sharing class TerminationEnrolmentProcessController {
    Public Enrolment__c objEnrolment{get;set;}
    Public String TerminationReasonName{get;set;}
    Public String rentalDateString{get;set;}
    Public Boolean isSendToButton{get;set;}
    Public Boolean isRentalNotFound{get;set;}
    Public String errorMessage{get;set;}
    
    public TerminationEnrolmentProcessController(ApexPages.StandardController st) {
        objEnrolment = (Enrolment__c)st.getRecord();
        if(string.isNotBlank(objEnrolment.id)){
            List<Enrolment__c> listOfEnrolment = PianoRentalHelperController.getRentalEnrolmentList(new Set<string>{objEnrolment.id});
            if(listOfEnrolment != null && listOfEnrolment.size() > 0 ){
                objEnrolment = listOfEnrolment[0];
            }
            Date terminateDate = system.today().addMonths(2);
            Date minCommitmentRentalDate;
            isSendToButton = true;
            //consider Terminating Piano Rental:
            //a.	Minimum commitment period – 6 months
            //b.	Minimum notice period – 2 months
            if(objEnrolment.Subscription_Line_Items__r != null && objEnrolment.Subscription_Line_Items__r.size() > 0){
                if(objEnrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c != null){
                   /* if(objEnrolment.Minimum_Rental_Commitment_Period__c != null){
                        minCommitmentRentalDate = objEnrolment.Minimum_Rental_Commitment_Period__c;
                    }else{*/
                        minCommitmentRentalDate = objEnrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c.AddMonths(6);
                    //}
                    if(minCommitmentRentalDate > terminateDate){
                        terminateDate = terminateDate.addDays(terminateDate.daysBetween(minCommitmentRentalDate));
                    }
                    isRentalNotFound= true;
                }else{
                    isRentalNotFound= false;
                    errorMessage ='We cannot process your request at the moment Rental Date not found. Please centre admin for further assistance.';
                }
               // terminateDate = terminateDate.addDays(1);
                rentalDateString = terminateDate.month()+'/'+terminateDate.day()+'/'+terminateDate.year();
                if(objEnrolment.Stage__c =='Piano Termination In-Progress' || objEnrolment.Stage__c =='Piano Rental Terminated'){
                    isRentalNotFound = false;
                    errorMessage ='We cannot process your request at the moment Already instrument terminatation is proceed. Please centre admin for further assistance.';
                }
            }else{
                isRentalNotFound= false;
                errorMessage ='We cannot process your request at the moment. Please centre admin for further assistance.';
            }
        }
    }

    public  List<SelectOption> getTerminationReason(){
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{'Enrolment__c'});
        Schema.DescribeFieldResult dfrList = results[0].fields.getMap().get('Termination_Reason__c').getDescribe();
        String type = String.valueOf(dfrList.getType());
        options.add(new SelectOption('','Select Termination Reason'));
        if(type.equalsIgnoreCase('PICKLIST')){
            for(Schema.PicklistEntry currentEntry : dfrList.getPicklistValues()){
                options.add(new SelectOption(currentEntry.getValue() ,currentEntry.getValue()));
            }
        }
        return options;
    }
    
}