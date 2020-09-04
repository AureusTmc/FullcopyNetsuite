/*
Name        :    LeaveEntitlementTrigger
Date        :    02 September 2019
Author      :
*/

trigger LeaveEntitlementTrigger on Leave_Entitlement__c (Before Insert, Before Update){
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AureusHRManagementUtil.validateDateConflict(trigger.new, null);
        }
        else if(Trigger.isUpdate){
            AureusHRManagementUtil.validateDateConflict(trigger.new, trigger.newmap);
        }
    }
}