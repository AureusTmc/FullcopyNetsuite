trigger PublicHoliday on Public_Holiday__c (after insert,after update,after undelete) {
    //Added By ....Ravi this trigger create a placholder for all teacher in various location as per teacher working hours 
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUndelete){
            PublicHolidayHelper.createdPlaceholderPublic(trigger.new);
        }
        
        if(trigger.isUpdate){
            List<Public_Holiday__c> phList = new List<Public_Holiday__c>();
            for(Public_Holiday__c phObj:trigger.New){
                if(trigger.oldmap.get(phObj.Id).Status__c != phObj.Status__c){
                    phList.add(phObj);   
                }
            }
            if(phList.size()>0){
              PublicHolidayHelper.createdPlaceholderPublic(phList);  
            }
        }
    }

}