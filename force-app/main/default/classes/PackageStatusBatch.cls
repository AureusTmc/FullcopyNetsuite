/*
Name		:	PackageStatusBatch
Date		:	23Jul19
Author		:	Arpit vijayvergiya
Description :	This class is being used for marking packages active and in active.
*/
global class PackageStatusBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id,Active__c,offer_start_date__c, offer_end_Date__c FROM Package__c WHERE offer_start_date__c != null and offer_end_Date__c != NULL');
    }
    
    global void execute(Database.BatchableContext BC, List<Package__c> packages){
        Date today = System.today();
        List<Package__c> packageList = new List<Package__c>();
        for(Package__c objPack : packages){
            objPack.Active__c = objPack.Offer_Start_Date__c <= today && objPack.Offer_End_Date__c >= today ? true : false; 
        	packageList.add(objPack);
        }
        if(packageList.size() > 0){
            update packageList;
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}