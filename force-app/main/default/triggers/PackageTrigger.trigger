/*
    Name    : PackageTrigger
*/
trigger PackageTrigger on Package__c (after update) {
    if(Trigger.isAfter && trigger.isUpdate){
        Map<Id,Package__c> mapOfOldPackage = trigger.oldMap;
        //Map<Id,Package__c> packageAfterAmountChange = new Map<Id,Package__c>();
        Set<String> setOfPackIds = new Set<String>();
        for(Package__c objPack : trigger.new){
            if(objPack.Package_Fee__c != mapOfOldPackage.get(objPack.Id).Package_Fee__c){
                //packageAfterAmountChange.put(objPack.Id, objpack);    
                setOfPackIds.add(objPack.Id);
            }
        }
        if(setOfPackIds.size() > 0){
            // call batch here
            Database.executeBatch(new PackageFeeBatch(setOfPackIds),100);
        }
    }
    
}