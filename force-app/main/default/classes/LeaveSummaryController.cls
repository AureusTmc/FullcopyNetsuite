/*
Name        :    LeaveSummaryController
Date        :    11 September 2019
Author      :    
*/

public class LeaveSummaryController{
    @AuraEnabled
    public static Leave_Entitlement__c getCurrentLeaveEntitlement(String recId){
        List<Leave_Entitlement__c> leaveEntList = [SELECT Id, Paid_Leave__c, Used_Paid_Leaves__c, Remaining_Paid_Leaves__c, Sick_Leave__c, Used_Sick_Leaves__c, Remaining_Sick_Leaves__c FROM Leave_Entitlement__c WHERE Start_Date__c <= TODAY AND End_Date__c >= TODAY AND Employee__c =: recId LIMIT 1];
        
        if(leaveEntList != NULL && leaveEntList.size()>0){
            return leaveEntList[0];
        }
        return null;
    }
}