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
                                            And Credit_Expiry_date__c != null 
                                            And Credit_Apply_date__c != null
                                        ]);
                                
    }
    
    global void execute(Database.BatchableContext BC, List<Complementary_Credit__c> listOfComplementaryCredit){
        Set<String> setOfParentIds = new Set<String>();
        for(Complementary_Credit__c objComplementaryCredit : listOfComplementaryCredit){
                setOfParentIds.add(objComplementaryCredit.Parent__c);
        }
        Map<String, Boolean> mapOfActiveParent = new Map<String, Boolean>();
        mapOfActiveParent = checkParentHasMultipleEnrolments(setOfParentIds, complimentaryEffectiveDate);
        Map<String, Date> mapOfParentCancelEnrolment  = getParentCancelEnrolmentsDate(setOfParentIds);
        system.debug('listOfComplementaryCredit'+listOfComplementaryCredit);
        system.debug('mapOfActiveParent'+mapOfActiveParent);
        system.debug('mapOfParentCancelEnrolment'+mapOfParentCancelEnrolment);
        for(Complementary_Credit__c objComplementaryCredit : listOfComplementaryCredit){
            system.debug('mapOfParentCancelEnrolment'+mapOfParentCancelEnrolment.containsKey(objComplementaryCredit.Parent__c));
            system.debug('mapOfParentCancelEnrolment'+mapOfParentCancelEnrolment.get(objComplementaryCredit.Parent__c));
            if(!mapOfActiveParent.containsKey(objComplementaryCredit.Parent__c) && mapOfParentCancelEnrolment.containsKey(objComplementaryCredit.Parent__c)){
                objComplementaryCredit.Credit_Expiry_date__c = mapOfParentCancelEnrolment.get(objComplementaryCredit.Parent__c);
            }
            if(objComplementaryCredit.Is_Active__c && objComplementaryCredit.Credit_Expiry_date__c != null && objComplementaryCredit.Credit_Expiry_date__c <=  complimentaryEffectiveDate){
                objComplementaryCredit.Is_Active__c = false;
            }else if(!objComplementaryCredit.Is_Active__c && objComplementaryCredit.Credit_Apply_date__c != null && objComplementaryCredit.Credit_Apply_date__c <=  complimentaryEffectiveDate){
                objComplementaryCredit.Is_Active__c = true;
            }
        }
        update listOfComplementaryCredit;

    }

    //check that the Parent Has other Enrolments or Not
    public static Map<String, Boolean> checkParentHasMultipleEnrolments(Set<String> parentIds, Date lastDate){
        Map<String, Boolean> mapOfParentActiveEnrolment = new Map<String, Boolean>();
        Boolean flag = false;
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        for(Enrolment__c enrolObj : [SELECT Id, Parent__c FROM Enrolment__c
                                        WHERE Parent__c IN :parentIds 
                                        AND ((Stage__c = :ConstantsClass.enroledStatus 
                                                AND Type__c In: enrolTypes
                                                AND (Package_Process_Type__c != :ConstantsClass.enrollmentProcessCancelType 
                                                    OR Effective_Date__c > :lastDate)
                                                )
                                            )]){
            mapOfParentActiveEnrolment.put(enrolObj.Parent__c, TRUE);
        }
        return mapOfParentActiveEnrolment;
    }

    //check that the Parent Has other Enrolments or Not
    public static Map<String, Date> getParentCancelEnrolmentsDate(Set<String> parentIds){
        Map<String, Date> mapOfParentCancelEnrolment = new Map<String, Date>();
        Boolean flag = false;
        Set<String>  enrolstage = New Set<String>{ConstantsClass.enroledStatus,'Cancelled'};
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        for(Enrolment__c enrolObj : [SELECT Id, Parent__c,Effective_Date__c FROM Enrolment__c
                                        WHERE Parent__c IN :parentIds 
                                        AND Type__c In:enrolTypes
                                        AND  Stage__c In: enrolstage
                                        AND Package_Process_Type__c = :ConstantsClass.enrollmentProcessCancelType 
                                        and Effective_Date__c != null
                                        order by Effective_Date__c desc
                                    ]){
                                        if(!mapOfParentCancelEnrolment.containsKey(enrolObj.Parent__c)){
                                            mapOfParentCancelEnrolment.put(enrolObj.Parent__c, enrolObj.Effective_Date__c);
                                        }
        }
        return mapOfParentCancelEnrolment;
    }

    global void finish(Database.BatchableContext BC){
   
    }
}