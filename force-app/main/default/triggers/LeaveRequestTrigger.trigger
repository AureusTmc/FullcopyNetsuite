trigger LeaveRequestTrigger on Leave_Request__c (before insert,before update, after update, after insert) {    
    Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
    Id paidLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
    Id nsMenRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('NSMen_Leave').getRecordTypeId();
    Id maternityRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
    Id otherRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AureusHRManagementUtil.populateReportingManager(trigger.new);
            AureusHRManagementUtil.autoApproveLeave(trigger.new);
            AureusHRManagementUtil.validateLeaveBalance(trigger.new, null);
            AureusHRManagementUtil.calculatePaidUnpaidSickLeaves(trigger.new, null);
            AureusHRManagementUtil.validateLeaveDateConflict(trigger.new, null);
            AureusHRManagementUtil.maternityLeaveFemaleValidation(trigger.new);
            AureusHRManagementUtil.maternityLeaveWeekValidation(trigger.new);
            AureusHRManagementUtil.maternityEndLeaveCalc(trigger.new);
        }
        else if(Trigger.isUpdate){
            AureusHRManagementUtil.leaveDateUpdateValidation(trigger.new, trigger.oldMap);
            AureusHRManagementUtil.validateLeaveDateConflict(trigger.new, trigger.newmap);
            AureusHRManagementUtil.maternityLeaveFemaleValidation(trigger.new);
            
            List<Leave_Request__c> leaveRequestList = new List<Leave_Request__c>();
            List<Leave_Request__c> sickLeaveRequestList = new List<Leave_Request__c>();
            List<Leave_Request__c> nsMenLeaveRequestList = new List<Leave_Request__c>();
            List<Leave_Request__c> unpaidSickLeaveList = new List<Leave_Request__c>();
            List<Leave_Request__c> maternityLeaveEndDateCalcList = new List<Leave_Request__c>();
            List<Leave_Request__c> maternityLeaveWeekValidationList = new List<Leave_Request__c>();
            List<Leave_Request__c> approvedMaternityLeave = new List<Leave_Request__c>();
            List<Leave_Request__c> approvedOtherLeave = new List<Leave_Request__c>();
            List<Leave_Request__c> rejectedSLReqList = new List<Leave_Request__c>();
            List<Leave_Request__c> approvedLeaveList = new List<Leave_Request__c>();
            
            for(Leave_Request__c leaveReqObj: trigger.new){
                Leave_Request__c oldLeaveReq = trigger.oldmap.get(leaveReqObj.Id);
                
                //Create PLR for NSMen, Maternity, other leave
                if((leaveReqObj.RecordTypeId == nsMenRcTypeId || leaveReqObj.RecordTypeId == maternityRcTypeId || leaveReqObj.RecordTypeId == otherRcTypeId) && leaveReqObj.Status__c == 'Approved' && oldLeaveReq.Status__c != leaveReqObj.Status__c){
                    approvedLeaveList.add(leaveReqObj);
                }
                
                //calculate paid unpaid sick leaves if leave start date and end date are not null and either one is updated
                if(leaveReqObj.RecordTypeId == sickLeaveRcTypeId  && (leaveReqObj.Leave_Start_Date__c != NULL && leaveReqObj.Leave_End_Date__c != NULL) && (oldLeaveReq.Leave_Start_Date__c != leaveReqObj.Leave_Start_Date__c || oldLeaveReq.Leave_End_Date__c != leaveReqObj.Leave_End_Date__c)){
                    sickLeaveRequestList.add(leaveReqObj);
                }
                
                //validate leave start date and end date if both are not null and either one is updated
                if(leaveReqObj.RecordTypeId == paidLeaveRcTypeId && (leaveReqObj.Leave_Start_Date__c != NULL && leaveReqObj.Leave_End_Date__c != NULL) && (oldLeaveReq.Leave_Start_Date__c != leaveReqObj.Leave_Start_Date__c || oldLeaveReq.Leave_End_Date__c != leaveReqObj.Leave_End_Date__c)){
                    leaveRequestList.add(leaveReqObj);
                }
                
                //if NS MEN Leave Request(s) is approved for the current month
                if(leaveReqObj.RecordTypeId == nsMenRcTypeId && leaveReqObj.Status__c == 'Approved' && oldLeaveReq.Status__c != leaveReqObj.Status__c){
                    nsMenLeaveRequestList.add(leaveReqObj);
                }
                
                //calculate loss of income for unpaid leave - create payItem
                if(leaveReqObj.RecordTypeId == sickLeaveRcTypeId  && leaveReqObj.Unpaid_Leaves__c != NULL && (leaveReqObj.Status__c == 'Approved' || leaveReqObj.Status__c == 'Rejected') && oldLeaveReq.Status__c != leaveReqObj.Status__c){
                    unpaidSickLeaveList.add(leaveReqObj);
                }
                
                //if Other Leave Request is approved for the current month of type Unpaid - Create PayItem under Payout
                if(leaveReqObj.RecordTypeId == otherRcTypeId && leaveReqObj.Type__c == 'Unpaid' && leaveReqObj.Status__c == 'Approved' && oldLeaveReq.Status__c != leaveReqObj.Status__c){
                    approvedOtherLeave.add(leaveReqObj);
                }
                
                //if sick leave request status is updated to Rejected with paid leave- update # Unpaid Leaves
                if(leaveReqObj.RecordTypeId == sickLeaveRcTypeId && leaveReqObj.Paid_Leaves__c != NULL && trigger.newmap.get(leaveReqObj.Id).Status__c == 'Rejected' && trigger.oldmap.get(leaveReqObj.Id).Status__c != trigger.newmap.get(leaveReqObj.Id).Status__c){
                    rejectedSLReqList.add(leaveReqObj);
                }
                
                //Maternity Leave
                if(leaveReqObj.RecordTypeId == maternityRcTypeId){
                    //leave end date calculation if start date or no of weeks is updated
                    if(leaveReqObj.Leave_Start_Date__c != oldLeaveReq.Leave_Start_Date__c || leaveReqObj.No_of_Weeks__c != oldLeaveReq.No_of_Weeks__c){
                        maternityLeaveEndDateCalcList.add(leaveReqObj);
                    }
                    
                    //sum of paid week and unpaid week re-checked if either one of them or no of weeks is updated
                    if(leaveReqObj.No_of_Weeks__c != oldLeaveReq.No_of_Weeks__c || leaveReqObj.Paid_Week__c != oldLeaveReq.Paid_Week__c || leaveReqObj.Unpaid_Week__c != oldLeaveReq.Unpaid_Week__c){
                        maternityLeaveWeekValidationList.add(leaveReqObj);
                    }
                    
                    //create PayItem under Payout
                    if(leaveReqObj.Status__c == 'Approved' && oldLeaveReq.Status__c != leaveReqObj.Status__c){
                        approvedMaternityLeave.add(leaveReqObj);
                    }
                }
            }
            
            if(!approvedLeaveList.isEmpty()){
                AureusHRManagementUtil.createPayItemLeaveRequestRecord(approvedLeaveList, trigger.newMap);
            }
            
            if(!leaveRequestList.isEmpty()){
                AureusHRManagementUtil.validateLeaveBalance(leaveRequestList, trigger.newMap);
            }
            
            if(!sickLeaveRequestList.isEmpty()){
                AureusHRManagementUtil.calculatePaidUnpaidSickLeaves(sickLeaveRequestList, trigger.newMap);
            }
            
            if(!unpaidSickLeaveList.isEmpty()){
                AureusHRManagementUtil.createPayItemLeaveRequest(unpaidSickLeaveList, trigger.newMap);
            }
            
            if(!nsMenLeaveRequestList.isEmpty()){
                AureusHRManagementUtil.createPayItemForNSMen(nsMenLeaveRequestList, trigger.newMap);
            }
            
            if(!maternityLeaveEndDateCalcList.isEmpty()){
                AureusHRManagementUtil.maternityEndLeaveCalc(maternityLeaveEndDateCalcList);
            }
            
            if(!maternityLeaveWeekValidationList.isEmpty()){
                AureusHRManagementUtil.maternityLeaveWeekValidation(maternityLeaveWeekValidationList);
            }
            
            if(!approvedMaternityLeave.isEmpty()){
                AureusHRManagementUtil.createPayItemForMaternity(approvedMaternityLeave, trigger.newMap);
            }
            
            if(!approvedOtherLeave.isEmpty()){
                AureusHRManagementUtil.createPayItemForOtherLeave(approvedOtherLeave, trigger.newMap);
            }
            
            if(!rejectedSLReqList.isEmpty()){
                AureusHRManagementUtil.updateUnpaidLeaveForSL(rejectedSLReqList);
            }
        }
    }
    else if(Trigger.isAfter){
        if(Trigger.isUpdate){
            List<Leave_Request__c> leaveRequestList = new List<Leave_Request__c>();
            List<Leave_Request__c> sickLeaveRequestList = new List<Leave_Request__c>();
            
            for(Leave_Request__c leaveReqObj: trigger.new){
                //if sick leave request status is updated to Approved with paid leave- update leave balance on leave entitlement
                if(leaveReqObj.RecordTypeId == sickLeaveRcTypeId && (trigger.newmap.get(leaveReqObj.Id).Status__c == 'Approved' && 
                    trigger.oldmap.get(leaveReqObj.Id).Status__c != trigger.newmap.get(leaveReqObj.Id).Status__c) || 
                    (trigger.newmap.get(leaveReqObj.Id).Status__c == 'Cancelled' 
                    && trigger.oldmap.get(leaveReqObj.Id).Status__c == 'Approved')){
                    sickLeaveRequestList.add(leaveReqObj);
                }
                
                //if paid leave request status is updated to Cancelled (from Approved Status) or Approved - update leave balance on leave entitlement
                if(leaveReqObj.RecordTypeId == paidLeaveRcTypeId && (trigger.newmap.get(leaveReqObj.Id).Status__c == 'Approved' && 
                    trigger.oldmap.get(leaveReqObj.Id).Status__c != trigger.newmap.get(leaveReqObj.Id).Status__c) || 
                    (trigger.newmap.get(leaveReqObj.Id).Status__c == 'Cancelled' 
                    && trigger.oldmap.get(leaveReqObj.Id).Status__c == 'Approved')){
                    leaveRequestList.add(leaveReqObj);
                }
            }
            
            if(!leaveRequestList.isEmpty()){
                AureusHRManagementUtil.updateUsedPaidLeave(leaveRequestList);
            }
            
            if(!sickLeaveRequestList.isEmpty()){
                AureusHRManagementUtil.updateUsedSickLeave(sickLeaveRequestList);
            }
        }
        else if(Trigger.isInsert){
            List<Leave_Request__c> approvedMaternityLeave = new List<Leave_Request__c>();
            List<Leave_Request__c> approvedLeaveList = new List<Leave_Request__c>();
            List<Leave_Request__c> approvedOtherLeave = new List<Leave_Request__c>();
            
            for(Leave_Request__c leaveReqObj: trigger.new){
                //Create PLR for Maternity, other leave (Without approval process they are already approved)
                if((leaveReqObj.RecordTypeId == maternityRcTypeId || leaveReqObj.RecordTypeId == otherRcTypeId) && leaveReqObj.Status__c == 'Approved'){
                    approvedLeaveList.add(leaveReqObj);
                }
                
                //Create PayItem under payout - maternity
                if(leaveReqObj.RecordTypeId == maternityRcTypeId && leaveReqObj.Status__c == 'Approved'){
                    approvedMaternityLeave.add(leaveReqObj);
                }
                
                //Create PayItem under payout - other
                if(leaveReqObj.RecordTypeId == otherRcTypeId && leaveReqObj.Type__c == 'Unpaid' && leaveReqObj.Status__c == 'Approved'){
                    approvedOtherLeave.add(leaveReqObj);
                }
            }
            
            if(!approvedLeaveList.isEmpty()){
                AureusHRManagementUtil.createPayItemLeaveRequestRecord(approvedLeaveList, trigger.newMap);
            }
            
            if(!approvedMaternityLeave.isEmpty()){
                AureusHRManagementUtil.createPayItemForMaternity(approvedMaternityLeave, trigger.newMap);
            }
            if(!approvedOtherLeave.isEmpty()){
                AureusHRManagementUtil.createPayItemForOtherLeave(approvedOtherLeave, trigger.newMap);
            }
        }
    }
    // Added By Ravi....
    if(trigger.isAfter && trigger.isInsert){
        List<Leave_Request__c> sickReqList = new List<Leave_Request__c>();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        // defined to fetch the Recordtpe 
        Id paidRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
        Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Id childkRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Child_Care_Leave').getRecordTypeId();
        Id extendedRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Extended_Child_Care_Leave').getRecordTypeId();    
        Id otherRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
        for(Leave_Request__c leavObj:trigger.new){
            if((leavObj.Status__c=='Draft' || leavObj.Status__c=='Pending') && leavObj.RecordTypeId==sickRecordTypeId && leavObj.Calendar_Update_Process__c==false){
                                                    sickReqList.add(leavObj);
                                                }
            if(leavObj.Status__c=='Approved' && leavObj.Calendar_Update_Process__c ==false && System.today().daysBetween(leavObj.Leave_Start_Date__c) <= Integer.valueOf(Label.Leave_Minimum_Due_No) && ( leavObj.RecordTypeId==childkRecordTypeId || leavObj.RecordTypeId==extendedRecordTypeId ||
                                                 leavObj.RecordTypeId==otherRecordTypeId  )){
                                                    leaveReqList.add(leavObj);
                                                }
            
        }
        //calling helper when Status is Pending or recordtype is Either sick,Child care,Extended Child Care Leave, other leave
        if(sickReqList.size()>0){
            LeaveRequestHelper.sickLeave(sickReqList);  
        } 
        if(leaveReqList.size()>0){
            LeaveRequestHelper.sickLeave(leaveReqList);  
        } 
    }
}