/*
Name        :    CarryForwardLeaveBatch
Date        :    02 September 2019
Author      :
Description :    Calculate carry forward leaves and populate it in next entitlement.
*/

global class CarryForwardLeaveBatch implements Database.Batchable<Leave_Entitlement__c>{
    global final Date leaveEntitlementEndingDate;
    
    global CarryForwardLeaveBatch(Date d){
        leaveEntitlementEndingDate = d;
    }
    global List<Leave_Entitlement__c> start(Database.BatchableContext context){
        //get Entitlement records ending today or on the received date
        String query = 'SELECT Id, Paid_Leave__c, Used_Paid_Leaves__c, Carry_forward_Paid_Leave__c, Remaining_Paid_Leaves__c,Additional_Paid_Leaves__c, Employee__c, End_Date__c, Start_Date__c FROM Leave_Entitlement__c WHERE End_Date__c = TODAY';
        if(leaveEntitlementEndingDate != NULL){
            query = 'SELECT Id, Paid_Leave__c, Used_Paid_Leaves__c, Carry_forward_Paid_Leave__c, Remaining_Paid_Leaves__c,Additional_Paid_Leaves__c, Employee__c, End_Date__c, Start_Date__c FROM Leave_Entitlement__c WHERE End_Date__c =: leaveEntitlementEndingDate';
        }
        return Database.query(query);
    }
    global void execute(Database.BatchableContext context, List<Leave_Entitlement__c> listOfLeaveEntitlements){
        AureusHRManagementUtil.populateCarryForwardLeavesForNextEntitlement(listOfLeaveEntitlements, leaveEntitlementEndingDate);
    }
    
    global void finish(Database.BatchableContext context){
    
    }
}