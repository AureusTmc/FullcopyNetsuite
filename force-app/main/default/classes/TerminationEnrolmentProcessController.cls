/*
Name: TerminationEnrolmentProcessController
Date: 23-jan-2020
Author: JATIN
Description :  this controller for Terminating Piano Rental  for get Terminating date and pickup date 
*/

//CH01 15 Oct 2020 Karan Singh : CHanging the minimum period and Terminate Notice Period for aureus Student.
//Test Class -> TerminationEnrolmentProcessTest

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
            
            //CH01 : Fetching other details of the enrolment to check if the student is existing or not. Similar exisitng aureus student logic as used in PIano Rental process where we check if the customer is existing or no
            //			CLass- > SearchInstrumentRental_IpadCntrl , exisitng logic used, search this loginc in the class : isAlreadyStripCstmr
            Map<String, Enrolment__c> mapOfParentActiveEnrolment= checkParentHasMultipleEnrolments(new Set<string>{objEnrolment.Parent__c});
            // commented by nishi: 12-Nov-2020: Checks to receive active enrollment student
            //List< Enrolment__c > listofEnrolForAureusStruent = [ SELECT Id,Instrument_Type__c, Parent__r.Stripe_Customer_Id__c, Parent__r.Card_Number__c, Parent__r.Card_Type__c FROM Enrolment__c WHERE Id =: objEnrolment.id ];
            Boolean isMinimumPeriodApplicable = false;
            
            set< String > setInstrumentType = new set< String >();
            if( String.isNotBlank( Label.Instrument_Type_for_the_Existing_Aureus_Students ) ){
                
                if( Label.Instrument_Type_for_the_Existing_Aureus_Students.contains(',') ){
                    setInstrumentType.addAll( Label.Instrument_Type_for_the_Existing_Aureus_Students.split(',') );
                }else{
                    setInstrumentType.add( Label.Instrument_Type_for_the_Existing_Aureus_Students);
                }
            }
            // commented by nishi: 12-Nov-2020:we check is any enrolment have same instrument then we allow to Minimum Period termination
            for(string instrumentType: setInstrumentType){
                if(mapOfParentActiveEnrolment.containsKey(instrumentType)){
                    isMinimumPeriodApplicable = true;
                }
            }
            /*if( setInstrumentType.contains( listofEnrolForAureusStruent[0].Instrument_Type__c ) 
               //Existing Aureus Student checking loginc - (isAlreadyStripCstmr) 
               && String.isNotBlank( listofEnrolForAureusStruent[0].Parent__r.Stripe_Customer_Id__c  ) 
               && String.isNotBlank( listofEnrolForAureusStruent[0].Parent__r.Card_Number__c  ) && String.isNotBlank( listofEnrolForAureusStruent[0].Parent__r.Card_Type__c  ) ){
                   isMinimumPeriodApplicable = true;
               }*/
             // commented by nishi: 12-Nov-2020:end: we check is any enrolment have same instrument then we allow to Minimum Period termination

            //CH01 END
            //Commented by nishi: 12-Nov-2020: for now we remove static months we get month according to Min Notice - Inst Rental Termination field
            //Date terminateDate = system.today().addMonths(2);
            Integer MinNoticeMonths =  Integer.valueOf(objEnrolment.Min_Notice_Inst_Rental_Termination__c != null  ? objEnrolment.Min_Notice_Inst_Rental_Termination__c : 2);
            Date terminateDate = system.today().addMonths(MinNoticeMonths);
            //CH01 Start
            if(isMinimumPeriodApplicable && String.isNotBlank( Label.Min_Notice_Period_for_Instrument_Rental_Termination_For_Aureus_Students )) {
                terminateDate = system.today().addMonths( Integer.valueOf( Label.Min_Notice_Period_for_Instrument_Rental_Termination_For_Aureus_Students ) );
            }
            //CH01 END
            Date minCommitmentRentalDate;
            isSendToButton = true;
            //consider Terminating Piano Rental:
            //a.	Minimum commitment period – 6 months
            //b.	Minimum notice period – 2 months
            
            //CH01 : ALso consider this points for Terminating Piano Rental
            //c.	Minimum Commitment period for the Aureus Student will be 3 months for KeyBoard and drum only
            //d.	Minimum notice period for the Aureus Student will be 1 months for KeyBoard and drum only
            
            if(objEnrolment.Subscription_Line_Items__r != null && objEnrolment.Subscription_Line_Items__r.size() > 0){
                if(objEnrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c != null){
                    /* if(objEnrolment.Minimum_Rental_Commitment_Period__c != null){
minCommitmentRentalDate = objEnrolment.Minimum_Rental_Commitment_Period__c;
}else{*/    
                    //Commented by nishi: 12-Nov-2020: for now we remove static months we get month according to Min Commit Dur - Inst Rental field
                    Integer minCommitmentRentalMonths =  Integer.valueOf(objEnrolment.Min_Commit_Dur_Inst_Rental__c != null  ? objEnrolment.Min_Commit_Dur_Inst_Rental__c : 6);
                    minCommitmentRentalDate = objEnrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c.AddMonths(minCommitmentRentalMonths);
                    //}
                    
                    //CH01 Start
                    if(isMinimumPeriodApplicable && String.isNotBlank( Label.Min_Commitment_Duration_for_Instrument_Rental_For_Aureus_Students )) {
                        minCommitmentRentalDate = objEnrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c.AddMonths( Integer.valueOf( Label.Min_Commitment_Duration_for_Instrument_Rental_For_Aureus_Students ) );  
                    }
                    //CH01 END
                    
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
    
     //added by nishi:for check that the Parent Has other Enrolments or Not
     public Map<String, Enrolment__c> checkParentHasMultipleEnrolments(Set<String> parentIds){
        Map<String, Enrolment__c> mapOfParentActiveEnrolment = new Map<String, Enrolment__c>();
        Boolean flag = false;
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        for(Enrolment__c enrolObj : [SELECT id,Instrument_Type__c, Parent__r.Stripe_Customer_Id__c, Parent__r.Card_Number__c, Parent__r.Card_Type__c FROM Enrolment__c
                                        WHERE Parent__c IN :parentIds 
                                        AND (Stage__c = :ConstantsClass.enroledStatus 
                                                AND Type__c In: enrolTypes
                                                AND (Package_Process_Type__c != :ConstantsClass.enrollmentProcessCancelType )
                                            )]){
            if(String.isNotBlank( enrolObj.Parent__r.Stripe_Customer_Id__c  ) 
                    && String.isNotBlank( enrolObj.Parent__r.Card_Number__c  ) && String.isNotBlank(enrolObj.Parent__r.Card_Type__c  ) ){
                mapOfParentActiveEnrolment.put(enrolObj.Instrument_Type__c, enrolObj);
            }
        }
        return mapOfParentActiveEnrolment;
    }
    
}