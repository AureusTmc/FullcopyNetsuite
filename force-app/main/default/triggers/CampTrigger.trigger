/*
*Name: CampTrigger 
*date: 29-Feb-2020
*author: jatin
*description : this trigger for  if camp status is active then Placeholder should be created for 
*all camp teachers for the duration. This should be done once the camp is activated.
*
*/
Trigger CampTrigger on Camp__c (after update,before delete,after undelete) {
    Map<string,Camp__c> mapOfActiveCamp = new Map<string,Camp__c>(); 
    Map<string,Camp__c> mapOfCancelledCamp = new Map<string,Camp__c>(); 
    if(trigger.isAfter && ( Trigger.isUndelete || Trigger.isUpdate)){
        Map<Id,Camp__c> oldMap = trigger.oldMap;
        for(Camp__c objCamp : Trigger.new){ 
            if( (Trigger.isUpdate)){
                Camp__c oldCamp = oldMap.get(objCamp.Id);
                if(string.isnotBlank(objCamp.status__c) &&  oldCamp.status__c != objCamp.status__c && objCamp.status__c.equalsIgnoreCase(ConstantsClass.campActiveStatus)){
                    mapOfActiveCamp.put(objCamp.id,objCamp);
                }
                if(string.isnotBlank(objCamp.status__c) &&  oldCamp.status__c != objCamp.status__c && objCamp.status__c.equalsIgnoreCase(ConstantsClass.campCancelledStatus)){
                    mapOfCancelledCamp.put(objCamp.id,objCamp);
                }
            }else{
                if(string.isnotBlank(objCamp.status__c) && objCamp.status__c.equalsIgnoreCase(ConstantsClass.campActiveStatus)){
                    mapOfActiveCamp.put(objCamp.id,objCamp);
                }
            }
        }
    }
    
    if(Trigger.isDelete ){
        for(Camp__c objCamp :Trigger.old){ 
            if(string.isnotBlank(objCamp.status__c) && objCamp.status__c.equalsIgnoreCase(ConstantsClass.campActiveStatus)){
                mapOfCancelledCamp.put(objCamp.id,objCamp);
            }
        }
    }
    
    if(mapOfActiveCamp != null && mapOfActiveCamp.size() > 0){
        campTriggerHelper.createCampTeachersPlaceholder(mapOfActiveCamp);
    }
    system.debug('Cancelled'+mapOfCancelledCamp);
    // if camp class deleted or status is cancelled then  we delete camp teacher bookings
    if(mapOfCancelledCamp != null && mapOfCancelledCamp.size() > 0){
        campTriggerHelper.deleteCampTeachersPlaceholder(mapOfCancelledCamp);
    }
}