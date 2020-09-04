/*
Name        :    specialReferralDiscountBatch
Date        :    08 Aug 2020
Author      :  
Description :    This batch class is used to apply special refrral discount 

*/
global class specialReferralDiscountBatch implements  Database.Batchable<sObject>{
    //Start Method
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // collect the Refferral discount records to be passed to execute
        return Database.getQueryLocator([SELECT Id, Name, Start_Date__c, End_Date__c, Active__c, Default__c, Discount_Amount_Referee__c, Discount_Amount_Referrer__c FROM Referral_Discount__c where Start_Date__c !=Null AND End_Date__c !=Null order by createddate desc]);
        
    }
    //Execute Method
    global void execute(Database.BatchableContext bc, List<Referral_Discount__c> records){
        List<Referral_Discount__c>refrelDiscounts = new List<Referral_Discount__c>();//Store REcords to update
        Map<Id,Referral_Discount__c>mapToChnage = new Map<Id,Referral_Discount__c>();
        
        // process each batch of records
        Boolean isDiscountActive = false;//To check discountActive special Discount active or not
        for(Referral_Discount__c refDisc : records){
            //Like special Discount Default = No and Start Date 1 Sep and End Date 10 Sep
            if((refDisc.Default__c =='No' && (refDisc.Start_Date__c <= system.today() && refDisc.End_Date__c >= system.today()))){
                mapToChnage.put(refDisc.Id,refDisc);
            }
            for(Referral_Discount__c refDiscs : records){
                if(mapToChnage.containsKey(refDiscs.Id)){//Checking for special discount Record
                    refDiscs.Active__c = 'Yes';
                    refrelDiscounts.add(refDiscs);
                    break;
                    
                }else{
                    if(refDiscs.Default__c =='No' && refDiscs.Active__c =='Yes'){//Reverse the Logic after end date
                        refDiscs.Active__c = 'No';
                        refrelDiscounts.add(refDiscs);
                    }
                }
            }
            if(refrelDiscounts.size() > 0){
                Update refrelDiscounts;
            }
        }
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    } 
    
}