/*
    Name : ComplimentaryCreditExpiryBatch
    Desription :  a.	Identify all those Complimentary Credit  whose makeup credit is expiry soon 
                    b. In case of withdrawal, all complimentary credit will expire on the last lesson date
    Author : Nishi Jain
    Date : 25-Feb-2021
*/
global with sharing class ComplimentaryCreditExpiryBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    global Date complimentaryEffectiveDate;
    global ComplimentaryCreditExpiryBatch (date complimentaryEffectiveDate){
       this.complimentaryEffectiveDate = complimentaryEffectiveDate;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Credit_Apply_date__c, Credit_Expiry_date__c, Credit_Reason__c, Enrolment__c, Teacher_Name__c, Parent__c, Available_credit_Min__c,
                                            Package_Name__c, Is_Active__c, Name, Id,Enrolment__r.stage__c,Enrolment__r.Type__c,
                                            Enrolment__r.Package_Process_Status__c,Enrolment__r.Package_Process_Type__c,Enrolment__r.effective_Date__c
                                            FROM Complementary_Credit__c 
                                            WHERE  Parent__c != null
                                        ]);
                                
    }
    
    global void execute(Database.BatchableContext BC, List<Complementary_Credit__c> listOfComplementaryCredit){
        Set<String> setOfParentIds = new Set<String>();
        for(Complementary_Credit__c objComplementaryCredit : listOfComplementaryCredit){
            if(string.isNotBlank(objComplementaryCredit.Enrolment__c)){
                enrolment__c objEnrolment = objComplementaryCredit.Enrolment__r;
                if(objEnrolment.stage__c == 'Cancelled' && objEnrolment.Type__c == 'Regular'){
                    setOfParentIds.add(objComplementaryCredit.Parent__c);
                }else if(string.isnotBlank(objEnrolment.Package_Process_Type__c) && objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType){
                    if(string.isnotBlank(objEnrolment.Package_Process_Status__c)){
                        setOfParentIds.add(objComplementaryCredit.Parent__c);
                    }
                }
            }else{
                setOfParentIds.add(objComplementaryCredit.Parent__c);
            }
        }
        Map<String, Boolean> mapOfActiveParent = new Map<String, Boolean>();
        mapOfActiveParent = BillingUtility.checkParentHasMultipleEnrolments(setOfParentIds, complimentaryEffectiveDate);
        system.debug('listOfComplementaryCredit'+listOfComplementaryCredit);
        for(Complementary_Credit__c objComplementaryCredit : listOfComplementaryCredit){
            if(objComplementaryCredit.Is_Active__c && objComplementaryCredit.Credit_Expiry_date__c != null && objComplementaryCredit.Credit_Expiry_date__c <=  complimentaryEffectiveDate){
                objComplementaryCredit.Is_Active__c = false;
            }
            if(!objComplementaryCredit.Is_Active__c && objComplementaryCredit.Credit_Apply_date__c != null && objComplementaryCredit.Credit_Apply_date__c <=  complimentaryEffectiveDate){
                objComplementaryCredit.Is_Active__c = true;
            }
            if(string.isNotBlank(objComplementaryCredit.Enrolment__c)){
                enrolment__c objEnrolment = objComplementaryCredit.Enrolment__r;
                if(objEnrolment.stage__c == 'Cancelled' && objEnrolment.Type__c == 'Regular'){
                    if(!mapOfActiveParent.containsKey(objComplementaryCredit.Parent__c)){
                        objComplementaryCredit.Is_Active__c = false;
                        objComplementaryCredit.Credit_Expiry_date__c = objEnrolment.effective_Date__c;
                    }
                }else if(string.isnotBlank(objEnrolment.Package_Process_Type__c) && objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType){
                    if(string.isnotBlank(objEnrolment.Package_Process_Status__c) && (!mapOfActiveParent.containsKey(objComplementaryCredit.Parent__c))){
                        if(objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus){
                            objComplementaryCredit.Credit_Expiry_date__c = objEnrolment.effective_Date__c;
                        }else if(objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessCompletedStatus){
                            objComplementaryCredit.Is_Active__c = false;
                            objComplementaryCredit.Credit_Expiry_date__c = objEnrolment.effective_Date__c;
                        }
                    }
                }
            }
        }
        update listOfComplementaryCredit;

    }

    global void finish(Database.BatchableContext BC){
   
    }
}