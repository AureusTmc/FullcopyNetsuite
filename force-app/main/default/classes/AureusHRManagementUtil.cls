public class AureusHRManagementUtil{  
    private static Map<Integer, String> numberToMonthMap = new Map<Integer, String>{
        1=>'January',
        2=>'February',
        3=>'March',
        4=>'April',
        5=>'May',
        6=>'June',
        7=>'July',
        8=>'August',
        9=>'September',
        10=>'October',
        11=>'November',
        12=>'December'
    };
    
    private static Map<String,Integer> monthMap = new Map<String,Integer>{
        'January'=>1,
        'February'=>2,
        'March'=>3,
        'April'=>4,
        'May'=>5,
        'June'=>6,
        'July'=>7,
        'August'=>8,
        'September'=>9,
        'October'=>10,
        'November'=>11,
        'December'=>12
    };
    
    //Auto approve leaves which don't have approval process
    public static void autoApproveLeave(List<Leave_Request__c> leaveReqList){
        Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Id paidLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
        Id nsMenRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('NSMen_Leave').getRecordTypeId();
        
        for(Leave_Request__c leaveReq: leaveReqList){
            if(leaveReq.RecordTypeId != sickLeaveRcTypeId && leaveReq.RecordTypeId != paidLeaveRcTypeId && leaveReq.RecordTypeId != nsMenRcTypeId)
                leaveReq.Status__c = 'Approved';
        }
    }
    
    //Populates Reporting Manager field on Leave Request - either Employee's Reporting Manager or HR Manager
    public static void populateReportingManager(List<Leave_Request__c> leaveReqList){
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, Id> mapAccToRM = new Map<Id, Id>();
        Map<Id, Id> mapAccToRM2 = new Map<Id, Id>();
        Id HRUserId;
        
        List<User> userList = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'HR Manager' LIMIT 1];
        if(userList != null && userList.size()==1){
            HRUserId = userList[0].Id;
        }
        
        for(Leave_Request__c leaveReq: leaveReqList){
            accIdSet.add(leaveReq.Employee__c);
        }
        
        for(Account acc: [SELECT Id, Reporting_Manager__c, Reporting_Manager_2__c FROM Account WHERE Id IN: accIdSet]){
            if(acc.Reporting_Manager__c != NULL)
                mapAccToRM.put(acc.Id, acc.Reporting_Manager__c);
            if(acc.Reporting_Manager_2__c != NULL)
                mapAccToRM2.put(acc.Id, acc.Reporting_Manager_2__c);
        }
        
        for(Leave_Request__c leaveReq: leaveReqList){
            leaveReq.Reporting_Manager__c = mapAccToRM.containsKey(leaveReq.Employee__c)? mapAccToRM.get(leaveReq.Employee__c): HRUserId != null? HRUserId: null;
            leaveReq.Reporting_Manager_2__c = mapAccToRM2.containsKey(leaveReq.Employee__c)? mapAccToRM2.get(leaveReq.Employee__c): null;
        }
    }
    
    //Calculate carry forward leaves and populate it in next entitlement. Called from CarryForwardLeaveBatch.
    public static void populateCarryForwardLeavesForNextEntitlement(List<Leave_Entitlement__c> listOfLeaveEntitlements, Date leaveEntitlementEndingDate){
        Map<Id, Leave_Entitlement__c> mapEmployeeToLeaveEntitlement = new Map<Id, Leave_Entitlement__c>();
        Map<Id, Leave_Entitlement__c> mapEmployeeToImmediateNextLeaveEntitlement = new Map<Id, Leave_Entitlement__c>();
        List<Leave_Entitlement__c> leaveEntitlementListToUpdate = new List<Leave_Entitlement__c>();
        
        for(Leave_Entitlement__c leaveEntitlementObj: listOfLeaveEntitlements){
            if(leaveEntitlementObj.Employee__c != NULL)
                mapEmployeeToLeaveEntitlement.put(leaveEntitlementObj.Employee__c, leaveEntitlementObj);
        }
        
        Date endDate = Date.today();
        if(leaveEntitlementEndingDate != NULL){
            endDate = leaveEntitlementEndingDate;
        }
        system.debug('endDate '+endDate );
        system.debug('mapEmployeeToLeaveEntitlement '+mapEmployeeToLeaveEntitlement );
        for(Account acc: [SELECT Id, 
                                (SELECT Id, Employee__c, End_Date__c, Start_Date__c, Carry_forward_Paid_Leave__c
                                FROM Leave_Entitlement__r 
                                WHERE Start_Date__c >: endDate 
                                ORDER BY Start_Date__c ASC 
                                LIMIT 1) 
                            FROM Account 
                            WHERE Id IN: mapEmployeeToLeaveEntitlement.KeySet()]){
            Leave_Entitlement__c leaveEntitlementObjEndingToday = mapEmployeeToLeaveEntitlement.get(acc.Id);
            Decimal actualUsedLeaves = 0;
            Decimal carryForwardLeaves = leaveEntitlementObjEndingToday.Paid_Leave__c + leaveEntitlementObjEndingToday.Additional_Paid_Leaves__c;
            
            if(leaveEntitlementObjEndingToday.Used_Paid_Leaves__c != NULL && leaveEntitlementObjEndingToday.Used_Paid_Leaves__c > 0){
                if(leaveEntitlementObjEndingToday.Carry_forward_Paid_Leave__c != NULL && leaveEntitlementObjEndingToday.Carry_forward_Paid_Leave__c > 0){
                    actualUsedLeaves = leaveEntitlementObjEndingToday.Used_Paid_Leaves__c - leaveEntitlementObjEndingToday.Carry_forward_Paid_Leave__c;
                   //9-Feb-2021: Nishi: start: we have added additional paid leave for carry forward leaves Calculation and populate it in next entitlement
                    //carryForwardLeaves = leaveEntitlementObjEndingToday.Paid_Leave__c - actualUsedLeaves;
                    carryForwardLeaves = (leaveEntitlementObjEndingToday.Paid_Leave__c + leaveEntitlementObjEndingToday.Additional_Paid_Leaves__c)- actualUsedLeaves;
                    //9-Feb-2021: Nishi: end: we have added additional paid leave for carry forward leaves Calculation and populate it in next entitlement
                }
                else{
                    //9-Feb-2021: Nishi: start: we have added additional paid leave for carry forward leaves Calculation and populate it in next entitlement
                    //carryForwardLeaves = leaveEntitlementObjEndingToday.Paid_Leave__c  - leaveEntitlementObjEndingToday.Used_Paid_Leaves__c;
                    carryForwardLeaves = (leaveEntitlementObjEndingToday.Paid_Leave__c + leaveEntitlementObjEndingToday.Additional_Paid_Leaves__c) - leaveEntitlementObjEndingToday.Used_Paid_Leaves__c;
                    //9-Feb-2021: Nishi: end: we have added additional paid leave for carry forward leaves Calculation and populate it in next entitlement
                }
            }
            system.debug('carryForwardLeaves '+carryForwardLeaves );
            system.debug('acc.Leave_Entitlement__r '+acc.Leave_Entitlement__r );
            if(acc.Leave_Entitlement__r != NULL && acc.Leave_Entitlement__r.size() > 0){
                acc.Leave_Entitlement__r[0].Carry_forward_Paid_Leave__c = carryForwardLeaves;
                leaveEntitlementListToUpdate.add(acc.Leave_Entitlement__r[0]);
            }
        }
        system.debug('leaveEntitlementListToUpdate'+leaveEntitlementListToUpdate);
        if(!leaveEntitlementListToUpdate.isEmpty()){
            update leaveEntitlementListToUpdate;
        }
    }
    
    //method to validate Leave Request date conflict for an Employee. Called from LeaveRequestTrigger. Works for all recordtypes.
    public static void validateLeaveDateConflict(List<Leave_Request__c> newList, Map<Id,Leave_Request__c> newMap){
        Map<Id, List<Leave_Request__c>> mapEmployeeToNewLeaveReqList = new Map<Id, List<Leave_Request__c>>();
        Map<Id, List<Leave_Request__c>> mapEmployeeToExistingLeaveReqList = new Map<Id, List<Leave_Request__c>>();
        List<Leave_Request__c> existingLeaveReqList = new List<Leave_Request__c>();
        Set<String> statusSet = new Set<String>{'Draft', 'Pending', 'Approved'};
        
        //storing new Leave Request records for the Employees
        for(Leave_Request__c newLeaveReqObj: newList){
            if(newLeaveReqObj.Employee__c != NULL){
                List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
                
                if(mapEmployeeToNewLeaveReqList.containsKey(newLeaveReqObj.Employee__c)){
                    leaveReqList = mapEmployeeToNewLeaveReqList.get(newLeaveReqObj.Employee__c);
                }
                leaveReqList.add(newLeaveReqObj);
                mapEmployeeToNewLeaveReqList.put(newLeaveReqObj.Employee__c, leaveReqList);
            }
        }
        
        //fetching and storing existing Leave Request records for the Employees
        if(newMap != NULL){
            existingLeaveReqList = [SELECT Id, Employee__c, Leave_Start_Date__c, Leave_End_Date__c FROM Leave_Request__c WHERE Employee__c IN: mapEmployeeToNewLeaveReqList.KeySet() AND Id NOT IN: newMap.KeySet() AND (Status__c IN: statusSet OR Status__c = NULL)];
        }
        else{
            existingLeaveReqList = [SELECT Id, Employee__c, Leave_Start_Date__c, Leave_End_Date__c FROM Leave_Request__c WHERE Employee__c IN: mapEmployeeToNewLeaveReqList.KeySet() AND (Status__c IN: statusSet OR Status__c = NULL)];
        }
        
        for(Leave_Request__c existingLeaveReqObj: existingLeaveReqList){
            List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
            
            if(mapEmployeeToExistingLeaveReqList.containsKey(existingLeaveReqObj.Employee__c)){
                leaveReqList = mapEmployeeToExistingLeaveReqList.get(existingLeaveReqObj.Employee__c);
            }
            leaveReqList.add(existingLeaveReqObj);
            mapEmployeeToExistingLeaveReqList.put(existingLeaveReqObj.Employee__c, leaveReqList);
        }
        
        //if Leave Request records exists for the Employee record, then validate the dates
        if(!mapEmployeeToExistingLeaveReqList.isEmpty()){
            Boolean conflictingDateFound = false;
            
            for(Leave_Request__c newLeaveReqObj: newList){
                List<Leave_Request__c> leaveReqList;
                if(mapEmployeeToExistingLeaveReqList.containsKey(newLeaveReqObj.Employee__c)){
                    leaveReqList = mapEmployeeToExistingLeaveReqList.get(newLeaveReqObj.Employee__c);
                }
                
                if(leaveReqList != NULL){
                    for(Leave_Request__c existingLeaveReqObj: leaveReqList){
                        if(newLeaveReqObj.Leave_Start_Date__c< existingLeaveReqObj.Leave_Start_Date__c&& !(newLeaveReqObj.Leave_End_Date__c < existingLeaveReqObj.Leave_Start_Date__c)){
                            conflictingDateFound = true;
                        }
                        
                        if(!conflictingDateFound && (newLeaveReqObj.Leave_Start_Date__c>= existingLeaveReqObj.Leave_Start_Date__c&& newLeaveReqObj.Leave_Start_Date__c<= existingLeaveReqObj.Leave_End_Date__c) || 
                        (newLeaveReqObj.Leave_End_Date__c >= existingLeaveReqObj.Leave_Start_Date__c&& newLeaveReqObj.Leave_End_Date__c <= existingLeaveReqObj.Leave_End_Date__c)){
                            conflictingDateFound = true;
                        }
                        
                        if(conflictingDateFound){
                            newLeaveReqObj.addError(label.DateConflictLeaveRequestError);
                        }
                    }
                }
            }
        } 
    }
    
    //method to validate Leave entitlement date conflict for an Employee. Called from LeaveEntitlementTrigger.
    public static void validateDateConflict(List<Leave_Entitlement__c> newList, Map<Id,Leave_Entitlement__c> newMap){
        System.debug(newList);
        System.debug(newList.size());
        System.debug(newMap);
        Map<Id, List<Leave_Entitlement__c>> mapEmployeeToNewEntitlementList = new Map<Id, List<Leave_Entitlement__c>>();
        Map<Id, List<Leave_Entitlement__c>> mapEmployeeToExistingEntitlementList = new Map<Id, List<Leave_Entitlement__c>>();
        List<Leave_Entitlement__c> existingLeaveEntitlementList = new List<Leave_Entitlement__c>();
        
        //storing new Leave Entitlement records for the Employees
        for(Leave_Entitlement__c newLeaveEntitlementObj: newList){
            if(newLeaveEntitlementObj.Employee__c != NULL){
                List<Leave_Entitlement__c> leaveEmploymentList = new List<Leave_Entitlement__c>();
                
                if(mapEmployeeToNewEntitlementList.containsKey(newLeaveEntitlementObj.Employee__c)){
                    leaveEmploymentList = mapEmployeeToNewEntitlementList.get(newLeaveEntitlementObj.Employee__c);
                }
                leaveEmploymentList.add(newLeaveEntitlementObj);
                mapEmployeeToNewEntitlementList.put(newLeaveEntitlementObj.Employee__c, leaveEmploymentList);
            }
        }
        
        System.debug(mapEmployeeToNewEntitlementList);
        
        //fetching and storing existing Leave Entitlement records for the Employees
        if(newMap != NULL){
            existingLeaveEntitlementList = [SELECT Id, Employee__c, Start_Date__c, End_Date__c FROM Leave_Entitlement__c WHERE Employee__c IN: mapEmployeeToNewEntitlementList.KeySet() AND Id NOT IN: newMap.KeySet()];
        }
        else{
            existingLeaveEntitlementList = [SELECT Id, Employee__c, Start_Date__c, End_Date__c FROM Leave_Entitlement__c WHERE Employee__c IN: mapEmployeeToNewEntitlementList.KeySet()];
        }
        
        System.debug(existingLeaveEntitlementList);
        
        for(Leave_Entitlement__c existingLeaveEntitlementObj: existingLeaveEntitlementList){
            List<Leave_Entitlement__c> leaveEmploymentList = new List<Leave_Entitlement__c>();
            
            if(mapEmployeeToExistingEntitlementList.containsKey(existingLeaveEntitlementObj.Employee__c)){
                leaveEmploymentList = mapEmployeeToExistingEntitlementList.get(existingLeaveEntitlementObj.Employee__c);
            }
            leaveEmploymentList.add(existingLeaveEntitlementObj);
            mapEmployeeToExistingEntitlementList.put(existingLeaveEntitlementObj.Employee__c, leaveEmploymentList);
        }
        System.debug(mapEmployeeToExistingEntitlementList);
        
        //if Leave Entitlement records exists for the Employee record, then validate the dates
        
        if(!mapEmployeeToExistingEntitlementList.isEmpty()){
            Boolean conflictingDateFound = false;
            
            for(Leave_Entitlement__c newLeaveEntitlementObj: newList){
                System.debug(newLeaveEntitlementObj);
                List<Leave_Entitlement__c> leaveEmploymentList;
                if(mapEmployeeToExistingEntitlementList.containsKey(newLeaveEntitlementObj.Employee__c)){
                    leaveEmploymentList = mapEmployeeToExistingEntitlementList.get(newLeaveEntitlementObj.Employee__c);
                }
                
                if(leaveEmploymentList != NULL){
                    for(Leave_Entitlement__c existingEntitlementObj: leaveEmploymentList){
                        System.debug(existingEntitlementObj);
                        if(newLeaveEntitlementObj.Start_Date__c < existingEntitlementObj.Start_Date__c && !(newLeaveEntitlementObj.End_Date__c < existingEntitlementObj.Start_Date__c)){
                            conflictingDateFound = true;
                        }
                        
                        if(!conflictingDateFound && (newLeaveEntitlementObj.Start_Date__c >= existingEntitlementObj.Start_Date__c && newLeaveEntitlementObj.Start_Date__c <= existingEntitlementObj.End_Date__c) || 
                        (newLeaveEntitlementObj.End_Date__c >= existingEntitlementObj.Start_Date__c && newLeaveEntitlementObj.End_Date__c <= existingEntitlementObj.End_Date__c)){
                            conflictingDateFound = true;
                        }
                        
                        if(conflictingDateFound){
                            newLeaveEntitlementObj.addError(label.DateConflictLeaveEntitlementError);
                        }
                    }
                }
            }
        }
    }
    
    //Sick Leave: creates PayItem Leave Request records for storing unpaid leaves mapped to month and year
    public static void createPayItemLeaveRequest(List<Leave_Request__c> unpaidSickLeaveList, Map<Id, Leave_Request__c> newMap){
        Set<Id> empIdSet = new Set<Id>();
        Map<Id, List<Leave_Entitlement__c>> accToLeaveEntMap = new Map<Id, List<Leave_Entitlement__c>>();
        Map<Id, List<Employee_Work_Week__c>> empToworkWeekList = new Map<Id, List<Employee_Work_Week__c>>();
        List<Payitem_Leave_Request__c> plrList = new List<Payitem_Leave_Request__c>();
        Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
        Set<Id> orgIdSet = new Set<Id>();
        
        for(Leave_Request__c leaveRequestObj: unpaidSickLeaveList){
            if(leaveRequestObj.Employee__c != NULL)
                empIdSet.add(leaveRequestObj.Employee__c);
        }
        
        if(!empIdSet.isEmpty()){
            for(Employee_Work_Week__c workWeek: [SELECT Id, Friday__c, Effective_Date__c, Monday__c, Saturday__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Working_Days_in_a_Week__c, Employee__c FROM Employee_Work_Week__c WHERE Employee__c IN: empIdSet ORDER BY Effective_Date__c ASC]){
                List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
                
                if(empToworkWeekList.containsKey(workWeek.Employee__c)){
                    workWeekList = empToworkWeekList.get(workWeek.Employee__c);
                }
                workWeekList.add(workWeek);
                empToworkWeekList.put(workWeek.Employee__c, workWeekList);
            }
    
            for(Leave_Entitlement__c leaveEntObj: [SELECT Id, Employee__c, End_Date__c, Start_Date__c, Remaining_Sick_Leaves__c, Employee__r.Joining_Date__c, Employee__r.Organisation__c, Employee__r.Employee_Duty_Type__c FROM Leave_Entitlement__c WHERE Employee__c IN: empIdSet ORDER BY Start_Date__c ASC]){
                List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
                
                if(accToLeaveEntMap.containsKey(leaveEntObj.Employee__c)){
                    leaveEntList = accToLeaveEntMap.get(leaveEntObj.Employee__c);
                }
                leaveEntList.add(leaveEntObj);
                orgIdSet.add(leaveEntObj.Employee__r.Organisation__c);
                accToLeaveEntMap.put(leaveEntObj.Employee__c, leaveEntList);
            }
            if(!orgIdSet.isEmpty())
                mapOrgToHolidays = getPublicHolidaysWithOrg(orgIdSet);
                
            Map<Id, Decimal> mapEntToRemainingLeaves = new Map<Id, Decimal>();
            Map<String, Decimal> mapMonthYearToUnpaidLeave = new Map<String, Decimal>();
            
            for(Leave_Request__c leaveReqObj: unpaidSickLeaveList){
                Date startDate = leaveReqObj.Leave_Start_Date__c;
                Date endDate;
                
                if(accToLeaveEntMap.containsKey(leaveReqObj.Employee__c)){
                    for(Leave_Entitlement__c leaveEntObj: accToLeaveEntMap.get(leaveReqObj.Employee__c)){
                        Decimal unpaidLeave = 0;
                        Decimal remainingLeave = leaveEntObj.Remaining_Sick_Leaves__c;
                        
                        if(mapEntToRemainingLeaves.containsKey(leaveEntObj.Id)){
                            remainingLeave = mapEntToRemainingLeaves.get(leaveEntObj.Id);
                        }
                        endDate = leaveReqObj.Leave_End_Date__c; 
                        
                        //if employee applies for leave within first three months of joining
                        if(leaveEntObj.Employee__r.Joining_Date__c != NULL && leaveReqObj.Leave_Start_Date__c <= leaveEntObj.Employee__r.Joining_Date__c.addMonths(3)){
                            System.debug('called from joining date'+ mapMonthYearToUnpaidLeave);
                            mapMonthYearToUnpaidLeave = getUnpaidLeaveMapWithoutWorkweek(leaveReqObj.Leave_Start_Date__c, leaveReqObj.Leave_End_Date__c, mapMonthYearToUnpaidLeave, leaveReqObj.Employee__c);
                            break;
                        }
                        //if workweek exists for the employee
                        else if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                            if(leaveEntObj.End_Date__c >= startDate && leaveEntObj.Start_Date__c <= endDate){ //valid entitlements for the leave period.
                                if(endDate > leaveEntObj.End_Date__c){
                                    endDate = leaveEntObj.End_Date__c;
                                }
                                else{
                                    endDate = leaveReqObj.Leave_End_Date__c;
                                }
                                
                                Decimal totalLeaveThisMonth = 0;
                                
                                Set<Public_Holiday__c> publicHolidaySet;
                                if(mapOrgToHolidays.containsKey(leaveEntObj.Employee__r.Organisation__c) && mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c) != NULL){
                                    publicHolidaySet = mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c);
                                }
                                        
                                if(startDate.month() != endDate.month()){ 
                                    while(startDate <= endDate){
                                        unpaidLeave = 0;
                                        Date monthStartDate, monthEndDate;
                                        Date endDateForCalc, startDateForCalc;
                                        monthStartDate = startDate.toStartOfMonth(); 
                                        monthEndDate = monthStartDate.addDays(date.daysInMonth(monthStartDate.year(), monthStartDate.month())-1);
                                        
                                        startDateForCalc = monthStartDate;
                                        endDateForCalc = monthEndDate;
                                        
                                        if(startDate >= monthStartDate){
                                            startDateForCalc = startDate; 
                                        }
                                        if(monthEndDate >= endDate){ 
                                            endDateForCalc = endDate; 
                                        }
                                        
                                        totalLeaveThisMonth = calculateWorkingDays(startDateForCalc, endDateForCalc, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c, false);
                                        System.debug(totalLeaveThisMonth);
                                        
                                        if(mapMonthYearToUnpaidLeave.containsKey(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year())){
                                            unpaidLeave = mapMonthYearToUnpaidLeave.get(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year());
                                        }
                                        
                                        if(leaveReqObj.Status__c == 'Rejected'){
                                            unpaidLeave += totalLeaveThisMonth;
                                        }
                                        else{
                                            if(totalLeaveThisMonth <= remainingLeave){
                                                Decimal roundUpVal = totalLeaveThisMonth.round(System.RoundingMode.HALF_UP);
                                                remainingLeave = (remainingLeave - roundUpVal);
                                            }
                                            else{
                                                unpaidLeave += (totalLeaveThisMonth - remainingLeave);
                                                remainingLeave = 0;
                                            }
                                        }
                                        System.debug(unpaidLeave);
                                        mapMonthYearToUnpaidLeave.put(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year(), unpaidLeave);
                                        System.debug(mapMonthYearToUnpaidLeave);
                                        startDate = monthEndDate.addDays(1);
                                    }
                                }
                                else{                                    
                                    totalLeaveThisMonth = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c, false);
                                    
                                    Date monthStartDate, monthEndDate;
                                    monthStartDate = startDate.toStartOfMonth(); 
                                    monthEndDate = monthStartDate.addDays(date.daysInMonth(monthStartDate.year(), monthStartDate.month())-1);
                                        
                                    if(mapMonthYearToUnpaidLeave.containsKey(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year())){
                                        unpaidLeave = mapMonthYearToUnpaidLeave.get(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year());
                                    }
                                    if(leaveReqObj.Status__c == 'Rejected'){
                                        unpaidLeave += totalLeaveThisMonth;
                                    }
                                    else{
                                        if(totalLeaveThisMonth <= remainingLeave){
                                            Decimal roundUpVal = totalLeaveThisMonth.round(System.RoundingMode.HALF_UP);
                                            remainingLeave = remainingLeave - roundUpVal;
                                        }
                                        else{
                                            unpaidLeave += (totalLeaveThisMonth - remainingLeave);
                                            remainingLeave = 0;
                                        }
                                    }
                                    mapMonthYearToUnpaidLeave.put(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year(), unpaidLeave);
                                    System.debug(mapMonthYearToUnpaidLeave);
                                }
                                startDate = leaveEntObj.End_Date__c.addDays(1);
                            }
                        }
                        else{
                            break;
                        }
                        mapEntToRemainingLeaves.put(leaveEntObj.Id, remainingLeave);
                    }
                    
                    //if no work week is created for the employee
                    if(!empToworkWeekList.containsKey(leaveReqObj.Employee__c) || empToworkWeekList.get(leaveReqObj.Employee__c) == NULL){
                        System.debug('called from no work week');
                        mapMonthYearToUnpaidLeave = getUnpaidLeaveMapWithoutWorkweek(leaveReqObj.Leave_Start_Date__c, leaveReqObj.Leave_End_Date__c, mapMonthYearToUnpaidLeave, leaveReqObj.Employee__c);
                    }
                    
                    for(String empMonthYear: mapMonthYearToUnpaidLeave.KeySet()){
                        Id empId = empMonthYear.split('-')[0];
                        Integer month = Integer.valueOf(empMonthYear.split('-')[1]);
                        String year = empMonthYear.split('-')[2];
                        
                        if(mapMonthYearToUnpaidLeave.get(empMonthYear) != 0){
                            Payitem_Leave_Request__c plrObj = new Payitem_Leave_Request__c(Leave_Request__c = leaveReqObj.Id, Month__c = numberToMonthMap.get(month), Year__c = year, Unpaid_Leaves__c = mapMonthYearToUnpaidLeave.get(empMonthYear));
                            plrList.add(plrObj);
                        }
                    }
                }
            }
            
            System.debug(plrList);
            
            if(!plrList.isEmpty()){
                insert plrList;
                createPayItemForUnpaidLeave(unpaidSickLeaveList, newMap);
            }
        }
    }
    
    //Payitem Creation: method that returns unpaid leaves mapped to (employeeid + month + year) key.
    private static Map<String, Decimal> getUnpaidLeaveMapWithoutWorkweek(Date leaveStartDate, Date leaveEndDate, Map<String, Decimal> mapReceived, Id empId){
        Map<String, Decimal> mapMonthYearToUnpaidLeave = new Map<String, Decimal>(mapReceived);
        Decimal totalLeaveThisMonth = 0;
        Decimal unpaidLeave = 0;
        Date monthStartDate; 
        Date monthEndDate;
        Date startDtForCal, endDtForCal;
        
        while(leaveStartDate <= leaveEndDate){
            unpaidLeave = 0;
            monthStartDate = leaveStartDate.toStartOfMonth(); 
            monthEndDate = monthStartDate.addDays(date.daysInMonth(monthStartDate.year(), monthStartDate.month())-1);
            
            startDtForCal = monthStartDate;
            endDtForCal = monthEndDate;
            
            if(leaveStartDate >= monthStartDate){
                startDtForCal = leaveStartDate; 
            }
            if(monthEndDate >= leaveEndDate){ 
                endDtForCal = leaveEndDate; 
            }
            totalLeaveThisMonth = startDtForCal.daysBetween(endDtForCal)+ 1;
            System.debug(totalLeaveThisMonth);
            if(mapMonthYearToUnpaidLeave.containsKey(empid+ '-'+ monthStartDate.month() +'-'+ monthStartDate.year())){
                unpaidLeave = mapMonthYearToUnpaidLeave.get(empid + '-'+ monthStartDate.month() +'-'+ monthStartDate.year());
                System.debug(unpaidLeave);
            }
            
            System.debug(unpaidLeave);
            unpaidLeave += totalLeaveThisMonth;
            
            mapMonthYearToUnpaidLeave.put(empid + '-'+ monthStartDate.month() +'-'+ monthStartDate.year(), unpaidLeave);
            leaveStartDate = monthEndDate.addDays(1);
        }
        
        System.debug(mapMonthYearToUnpaidLeave);
        return mapMonthYearToUnpaidLeave;
    }
    
    //Paid Leave: validates leave balance. Called from LeaveRequestTrigger.
    public static void validateLeaveBalance(List<Leave_Request__c> newList, Map<Id, Leave_Request__c> newmap){        
        Id paidLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, List<Leave_Entitlement__c>> accToLeaveEntMap = new Map<Id, List<Leave_Entitlement__c>>();
        Map<Id, List<Employee_Work_Week__c>> empToworkWeekList = new Map<Id, List<Employee_Work_Week__c>>();
        Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
        Set<Id> orgIdSet = new Set<Id>();
        Map<Id, Decimal> mapLeaveEntToAppliedLeave = new Map<Id, Decimal>();
        
        for(Leave_Request__c leaveRequestObj: newList){
            if(paidLeaveRcTypeId == leaveRequestObj.RecordTypeId && leaveRequestObj.Employee__c != NULL){
                accountIdSet.add(leaveRequestObj.Employee__c);
            }
        }
        
        if(!accountIdSet.isEmpty()){
            for(Employee_Work_Week__c workWeek: [SELECT Id, Friday__c, Effective_Date__c, Monday__c, Saturday__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Working_Days_in_a_Week__c, Employee__c FROM Employee_Work_Week__c WHERE Employee__c IN: accountIdSet ORDER BY Effective_Date__c ASC]){
                List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
                
                if(empToworkWeekList.containsKey(workWeek.Employee__c)){
                    workWeekList = empToworkWeekList.get(workWeek.Employee__c);
                }
                workWeekList.add(workWeek);
                empToworkWeekList.put(workWeek.Employee__c, workWeekList);
            }
    
            for(Leave_Entitlement__c leaveEntObj: [SELECT Id, Remaining_Paid_Leaves__c, Employee__c, End_Date__c, Start_Date__c, Employee__r.Joining_Date__c, Employee__r.Organisation__c, Employee__r.Employee_Duty_Type__c FROM Leave_Entitlement__c WHERE Employee__c IN: accountIdSet ORDER BY Start_Date__c ASC]){
                List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
                
                if(accToLeaveEntMap.containsKey(leaveEntObj.Employee__c)){
                    leaveEntList = accToLeaveEntMap.get(leaveEntObj.Employee__c);
                }
                leaveEntList.add(leaveEntObj);
                orgIdSet.add(leaveEntObj.Employee__r.Organisation__c);
                accToLeaveEntMap.put(leaveEntObj.Employee__c, leaveEntList);
            }
            
            mapOrgToHolidays = getPublicHolidaysWithOrg(orgIdSet);
            mapLeaveEntToAppliedLeave = getLeaveEntMappedToAppliedLeave(empToworkWeekList, accToLeaveEntMap, accountIdSet, mapOrgToHolidays, paidLeaveRcTypeId, newmap);
            
            for(Leave_Request__c leaveReqObj: newList){
                Decimal paidLeaves = 0;
                if(paidLeaveRcTypeId == leaveReqObj.RecordTypeId){
                    Date startDate = leaveReqObj.Leave_Start_Date__c;
                    Date endDate = leaveReqObj.Leave_End_Date__c;
                    
                    Boolean flagForValidLeaveStartDate = false;
                    Boolean flagForValidLeaveEndDate = false;
                    
                    if(accToLeaveEntMap.containsKey(leaveReqObj.Employee__c)){
                        for(Leave_Entitlement__c leaveEntObj: accToLeaveEntMap.get(leaveReqObj.Employee__c)){
                            if(leaveReqObj.Leave_Start_Date__c >= leaveEntObj.Start_Date__c && leaveReqObj.Leave_Start_Date__c <= leaveEntObj.End_Date__c){
                                flagForValidLeaveStartDate = true;
                            }
                            if(leaveReqObj.Leave_End_Date__c >= leaveEntObj.Start_Date__c && leaveReqObj.Leave_End_Date__c <= leaveEntObj.End_Date__c){
                                flagForValidLeaveEndDate = true;
                            }
                            
                            endDate = leaveReqObj.Leave_End_Date__c;
                        
                            if(endDate > leaveEntObj.End_Date__c){
                                endDate = leaveEntObj.End_Date__c;
                            }
                            else{
                                endDate = leaveReqObj.Leave_End_Date__c;
                            }
                            
                            Decimal actualLeaves = 0;
                            Decimal appliedLeaves = 0;
                            if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                                Set<Public_Holiday__c> publicHolidaySet;
                                if(mapOrgToHolidays.containsKey(leaveEntObj.Employee__r.Organisation__c) && mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c) != NULL){
                                    publicHolidaySet = mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c);
                                }
                                actualLeaves = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c, true);
                                system.debug('Test===='+actualLeaves);
                                paidLeaves += actualLeaves;
                                appliedLeaves += actualLeaves;
                                System.debug(actualLeaves);
                            }else{
                                leaveReqObj.addError('Please define the work week for this employee.');
                            }
                            
                            Decimal remainingLeave = !mapLeaveEntToAppliedLeave.isEmpty() && mapLeaveEntToAppliedLeave.containsKey(leaveEntObj.Id)? leaveEntObj.Remaining_Paid_Leaves__c - mapLeaveEntToAppliedLeave.get(leaveEntObj.Id): leaveEntObj.Remaining_Paid_Leaves__c;
                            System.debug(remainingLeave);
                            if(startDate >= leaveEntObj.Start_Date__c && leaveReqObj.Leave_End_Date__c <= leaveEntObj.End_Date__c){
                                if(actualLeaves > remainingLeave){
                                    leaveReqObj.addError(label.InsufficientLeaveBalanceError);
                                }
                                break;
                            }
                            else if(startDate >= leaveEntObj.Start_Date__c && leaveEntObj.End_Date__c >= startdate){
                                if(actualLeaves > remainingLeave){
                                    System.debug('leaveEntObj.Remaining_Paid_Leaves__c: '+ leaveEntObj.Remaining_Paid_Leaves__c);
                                    leaveReqObj.addError(label.InsufficientLeaveBalanceError);
                                }
                                startDate = leaveEntObj.End_Date__c.addDays(1);
                            }
                            
                            if(mapLeaveEntToAppliedLeave.containsKey(leaveEntObj.Id)){
                                appliedLeaves += mapLeaveEntToAppliedLeave.get(leaveEntObj.Id);
                            }
                            Decimal roundUpVal = appliedLeaves.round(System.RoundingMode.HALF_UP);
                            mapLeaveEntToAppliedLeave.put(leaveEntObj.Id, roundUpVal);
                        }
                        
                        if(!flagForValidLeaveEndDate || !flagForValidLeaveStartDate){
                            leaveReqObj.addError(label.NotEntitledForApplyingLeaveError);
                        }
                    }else{//added by Sanjay
                        leaveReqObj.addError(label.NotEntitledForApplyingLeaveError);
                    }
                    leaveReqObj.Paid_Leaves__c = paidLeaves;
                }
            }
        }
    }
    
    //Sick Leave: updates Paid Leaves and Unpaid Leaves on Leave Request record when leave rejected
    public static void updateUnpaidLeaveForSL(List<Leave_Request__c> rejectedLeaveList){
        for(Leave_Request__c leaveReq: rejectedLeaveList){
            Decimal pl = leaveReq.Paid_Leaves__c != NULL? leaveReq.Paid_Leaves__c: 0;
            Decimal ul = leaveReq.Unpaid_Leaves__c != NULL? leaveReq.Unpaid_Leaves__c: 0;
            Decimal totalLeaves = pl + ul;
            leaveReq.Unpaid_Leaves__c = totalLeaves;
            leaveReq.Paid_Leaves__c = 0;
        }        
    }
    
    //calculate applied leaves for leave entitlements
    private static Map<Id, Decimal> getLeaveEntMappedToAppliedLeave(Map<Id, List<Employee_Work_Week__c>> empToworkWeekList, Map<Id, List<Leave_Entitlement__c>> accToLeaveEntMap, Set<Id> accountIdSet, Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays, Id rcTypeId, Map<Id, Leave_Request__c> newMap){
        Id paidLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
        
        Map<Id, Decimal> mapLeaveEntToAppliedLeave = new Map<Id, Decimal>();
        Set<String> statusSet = new Set<String>{'Draft', 'Pending'};
        List<Leave_Request__c> existingPendingLeaveReqList = new List<Leave_Request__c>();
        
        if(newMap != null){
            existingPendingLeaveReqList = [SELECT Id, Employee__c, Leave_Start_Date__c, Leave_End_Date__c FROM Leave_Request__c WHERE RecordTypeId =: rcTypeId AND Status__c IN: statusSet AND Employee__c IN: accountIdSet AND Id NOT IN: newMap.KeySet()];
        }
        else{
            existingPendingLeaveReqList = [SELECT Id, Employee__c, Leave_Start_Date__c, Leave_End_Date__c FROM Leave_Request__c WHERE RecordTypeId =: rcTypeId AND Status__c IN: statusSet AND Employee__c IN: accountIdSet];
        }
        
        
        for(Leave_Request__c leaveReqObj: existingPendingLeaveReqList){
            Date startDate = leaveReqObj.Leave_Start_Date__c;
            Date endDate = leaveReqObj.Leave_End_Date__c;
            
            if(accToLeaveEntMap.containsKey(leaveReqObj.Employee__c)){
                for(Leave_Entitlement__c leaveEntObj: accToLeaveEntMap.get(leaveReqObj.Employee__c)){   
                    if(endDate >= leaveEntObj.Start_Date__c && startDate <= leaveEntObj.End_Date__c){
                        Decimal appliedLeaves = 0;
                        
                        if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                            Set<Public_Holiday__c> publicHolidaySet;
                            if(mapOrgToHolidays.containsKey(leaveEntObj.Employee__r.Organisation__c) && mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c) != NULL){
                                publicHolidaySet = mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c);
                            }
                            appliedLeaves = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c, true);
                            
                            System.debug(appliedLeaves);
                        }
                        if(mapLeaveEntToAppliedLeave.containsKey(leaveEntObj.Id)){
                            appliedLeaves += mapLeaveEntToAppliedLeave.get(leaveEntObj.Id);
                        }
                        Decimal roundUpVal = appliedLeaves.round(System.RoundingMode.HALF_UP);
                        mapLeaveEntToAppliedLeave.put(leaveEntObj.Id, roundUpVal);
                        break;
                    }
                }
            }
        }
        System.debug(mapLeaveEntToAppliedLeave);
        return mapLeaveEntToAppliedLeave;
    }
    
    //Paid Leave: updates used leave in entitlement for approved and cancelled leaves. Called from LeaveRequestTrigger.
    public static void updateUsedPaidLeave(List<Leave_Request__c> newList){
        Id paidLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
        
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, List<Leave_Entitlement__c>> accToLeaveEntMap = new Map<Id, List<Leave_Entitlement__c>>();
        //Map<Id, List<Employee_Work_Week__c>> empToworkWeekList = new Map<Id, List<Employee_Work_Week__c>>();
        List<Leave_Entitlement__c> leaveEntToUpdate = new List<Leave_Entitlement__c>();
        //Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
        //Set<Id> orgIdSet = new Set<Id>();
        
        for(Leave_Request__c leaveRequestObj: newList){
            if(paidLeaveRcTypeId == leaveRequestObj.RecordTypeId && leaveRequestObj.Employee__c != NULL){
                accountIdSet.add(leaveRequestObj.Employee__c);
            }
        }
        
        if(!accountIdSet.isEmpty()){
            /*for(Employee_Work_Week__c workWeek: [SELECT Id, Friday__c, Effective_Date__c, Monday__c, Saturday__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Working_Days_in_a_Week__c, Employee__c FROM Employee_Work_Week__c WHERE Employee__c IN: accountIdSet ORDER BY Effective_Date__c ASC]){
                List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
                
                if(empToworkWeekList.containsKey(workWeek.Employee__c)){
                    workWeekList = empToworkWeekList.get(workWeek.Employee__c);
                }
                workWeekList.add(workWeek);
                empToworkWeekList.put(workWeek.Employee__c, workWeekList);
            }*/
    
            for(Leave_Entitlement__c leaveEntObj: [SELECT Id, Employee__c, End_Date__c, Start_Date__c, Used_Paid_Leaves__c, Employee__r.Organisation__c, Employee__r.Employee_Duty_Type__c FROM Leave_Entitlement__c WHERE Employee__c IN: accountIdSet ORDER BY Start_Date__c ASC]){
                List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
                
                if(accToLeaveEntMap.containsKey(leaveEntObj.Employee__c)){
                    leaveEntList = accToLeaveEntMap.get(leaveEntObj.Employee__c);
                }
                leaveEntList.add(leaveEntObj);
                //orgIdSet.add(leaveEntObj.Employee__r.Organisation__c);
                accToLeaveEntMap.put(leaveEntObj.Employee__c, leaveEntList);
            }
            
            /*if(!orgIdSet.isEmpty())
                mapOrgToHolidays = getPublicHolidaysWithOrg(orgIdSet);
            System.debug(mapOrgToHolidays);*/
            for(Leave_Request__c leaveReqObj: newList){
                if(paidLeaveRcTypeId == leaveReqObj.RecordTypeId){
                    Date startDate = leaveReqObj.Leave_Start_Date__c;
                    Date endDate = leaveReqObj.Leave_End_Date__c;
                    
                    if(accToLeaveEntMap.containsKey(leaveReqObj.Employee__c)){
                        for(Leave_Entitlement__c leaveEntObj: accToLeaveEntMap.get(leaveReqObj.Employee__c)){
                            leaveEntObj.Used_Paid_Leaves__c = leaveEntObj.Used_Paid_Leaves__c != NULL? leaveEntObj.Used_Paid_Leaves__c : 0;
                            
                            endDate = leaveReqObj.Leave_End_Date__c;
                        
                            if(endDate > leaveEntObj.End_Date__c){
                                endDate = leaveEntObj.End_Date__c;
                            }
                            else{
                                endDate = leaveReqObj.Leave_End_Date__c;
                            }
                            
                            Decimal actualLeaves = leaveReqObj.Paid_Leaves__c != NULL? leaveReqObj.Paid_Leaves__c: 0;
                            /*
                            if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                                Set<Public_Holiday__c> publicHolidaySet;
                                if(mapOrgToHolidays.containsKey(leaveEntObj.Employee__r.Organisation__c) && mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c) != NULL){
                                    publicHolidaySet = mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c);
                                }
                                System.debug(publicHolidaySet);
                                actualLeaves = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c);
                            }*/
                            actualLeaves = actualLeaves.round(System.RoundingMode.HALF_UP);
                            
                            if(startDate >= leaveEntObj.Start_Date__c && leaveReqObj.Leave_End_Date__c <= leaveEntObj.End_Date__c){
                                if(leaveReqObj.Status__c == 'Approved'){
                                    leaveEntObj.Used_Paid_Leaves__c = leaveEntObj.Used_Paid_Leaves__c + actualLeaves;
                                }
                                else{
                                    leaveEntObj.Used_Paid_Leaves__c = leaveEntObj.Used_Paid_Leaves__c - actualLeaves;
                                }
                                
                                leaveEntToUpdate.add(leaveEntObj);
                                break;
                            }
                            else if(startDate >= leaveEntObj.Start_Date__c && leaveEntObj.End_Date__c >= startdate){
                                if(leaveReqObj.Status__c == 'Approved'){
                                    leaveEntObj.Used_Paid_Leaves__c = leaveEntObj.Used_Paid_Leaves__c + actualLeaves;
                                }
                                else{
                                    leaveEntObj.Used_Paid_Leaves__c = leaveEntObj.Used_Paid_Leaves__c - actualLeaves;
                                }
                                startDate = leaveEntObj.End_Date__c.addDays(1);
                                leaveEntToUpdate.add(leaveEntObj);
                            }
                        }
                    }
                }
            }
            if(!leaveEntToUpdate.isEmpty()){
                update leaveEntToUpdate;
            }
        }
    }
    
    //Sick Leave: updates used sick leave on Leave Entitlement object. Called from LeaveRequestTrigger.
    public static void updateUsedSickLeave(List<Leave_Request__c> newList){
        Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, List<Leave_Entitlement__c>> accToLeaveEntMap = new Map<Id, List<Leave_Entitlement__c>>();
        //Map<Id, List<Employee_Work_Week__c>> empToworkWeekList = new Map<Id, List<Employee_Work_Week__c>>();
        List<Leave_Entitlement__c> leaveEntToUpdate = new List<Leave_Entitlement__c>();
        //Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
        //Set<Id> orgIdSet = new Set<Id>();
        
        for(Leave_Request__c leaveRequestObj: newList){
            if(sickLeaveRcTypeId == leaveRequestObj.RecordTypeId && leaveRequestObj.Employee__c != NULL && leaveRequestObj.Paid_Leaves__c != null){
                accountIdSet.add(leaveRequestObj.Employee__c);
            }
        }
        
        if(!accountIdSet.isEmpty()){
            /*for(Employee_Work_Week__c workWeek: [SELECT Id, Friday__c, Effective_Date__c, Monday__c, Saturday__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Working_Days_in_a_Week__c, Employee__c FROM Employee_Work_Week__c WHERE Employee__c IN: accountIdSet ORDER BY Effective_Date__c ASC]){
                List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
                
                if(empToworkWeekList.containsKey(workWeek.Employee__c)){
                    workWeekList = empToworkWeekList.get(workWeek.Employee__c);
                }
                workWeekList.add(workWeek);
                empToworkWeekList.put(workWeek.Employee__c, workWeekList);
            }*/
    
            for(Leave_Entitlement__c leaveEntObj: [SELECT Id, Employee__c, End_Date__c, Start_Date__c, Used_Sick_Leaves__c, Remaining_Sick_Leaves__c, Employee__r.Joining_Date__c, Employee__r.Organisation__c, Employee__r.Employee_Duty_Type__c FROM Leave_Entitlement__c WHERE Employee__c IN: accountIdSet ORDER BY Start_Date__c ASC]){
                List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
                
                if(accToLeaveEntMap.containsKey(leaveEntObj.Employee__c)){
                    leaveEntList = accToLeaveEntMap.get(leaveEntObj.Employee__c);
                }
                leaveEntList.add(leaveEntObj);
                //orgIdSet.add(leaveEntObj.Employee__r.Organisation__c);
                accToLeaveEntMap.put(leaveEntObj.Employee__c, leaveEntList);
            }
            
            /*if(!orgIdSet.isEmpty())
                mapOrgToHolidays = getPublicHolidaysWithOrg(orgIdSet);*/
            for(Leave_Request__c leaveReqObj: newList){
                if(sickLeaveRcTypeId == leaveReqObj.RecordTypeId && leaveReqObj.Type__c != 'Unpaid'){ //if all leaves are unpaid - does nothing
                    Date startDate = leaveReqObj.Leave_Start_Date__c;
                    Date endDate = leaveReqObj.Leave_End_Date__c;
                    
                    if(accToLeaveEntMap.containsKey(leaveReqObj.Employee__c)){
                        for(Leave_Entitlement__c leaveEntObj: accToLeaveEntMap.get(leaveReqObj.Employee__c)){
                            leaveEntObj.Used_Sick_Leaves__c = leaveEntObj.Used_Sick_Leaves__c != NULL? leaveEntObj.Used_Sick_Leaves__c : 0;
                            
                            endDate = leaveReqObj.Leave_End_Date__c;
                        
                            if(endDate > leaveEntObj.End_Date__c){
                                endDate = leaveEntObj.End_Date__c;
                            }
                            else{
                                endDate = leaveReqObj.Leave_End_Date__c;
                            }
                            
                            Decimal actualLeaves = leaveReqObj.Paid_Leaves__c != NULL? leaveReqObj.Paid_Leaves__c : 0;
                            /*if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                                Set<Public_Holiday__c> publicHolidaySet;
                                if(mapOrgToHolidays.containsKey(leaveEntObj.Employee__r.Organisation__c) && mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c) != NULL){
                                    publicHolidaySet = mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c);
                                }
                                actualLeaves = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c);
                            }*/
                            
                            actualLeaves = actualLeaves.round(System.RoundingMode.HALF_UP);
                            
                            if(startDate >= leaveEntObj.Start_Date__c && leaveReqObj.Leave_End_Date__c <= leaveEntObj.End_Date__c){
                                if(actualLeaves < leaveEntObj.Remaining_Sick_Leaves__c){
                                    leaveEntObj.Used_Sick_Leaves__c += actualLeaves;
                                }
                                else{
                                    leaveEntObj.Used_Sick_Leaves__c += leaveEntObj.Remaining_Sick_Leaves__c;
                                }
                                leaveEntToUpdate.add(leaveEntObj);
                                break;
                            }
                            else if(startDate >= leaveEntObj.Start_Date__c && leaveEntObj.End_Date__c >= startdate){
                                if(actualLeaves < leaveEntObj.Remaining_Sick_Leaves__c){
                                    leaveEntObj.Used_Sick_Leaves__c += actualLeaves;
                                }
                                else{
                                    leaveEntObj.Used_Sick_Leaves__c += leaveEntObj.Remaining_Sick_Leaves__c;
                                }
                                startDate = leaveEntObj.End_Date__c.addDays(1);
                                leaveEntToUpdate.add(leaveEntObj);
                            }
                        }    
                    }
                }
            }
            if(!leaveEntToUpdate.isEmpty()){
                update leaveEntToUpdate;
            }
        }
    }
    
    //Sick Leave: calculates sick leave and populate paid and unpaid sick leave for the leave request object. Called from LeaveRequestTrigger.
    public static void calculatePaidUnpaidSickLeaves(List<Leave_Request__c> newList, Map<Id, Leave_Request__c> newMap){
        Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Set<Id> accountIdSet = new Set<id>();
        Map<Id, List<Leave_Entitlement__c>> accToLeaveEntMap = new Map<Id, List<Leave_Entitlement__c>>();
        Map<Id, List<Employee_Work_Week__c>> empToworkWeekList = new Map<Id, List<Employee_Work_Week__c>>();
        Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
        Set<Id> orgIdSet = new Set<Id>();
        Map<Id, Decimal> mapLeaveEntToAppliedLeave = new Map<Id, Decimal>();
        
        for(Leave_Request__c leaveRequestObj: newList){
            if(sickLeaveRcTypeId == leaveRequestObj.RecordTypeId && leaveRequestObj.Employee__c != NULL){
                accountIdSet.add(leaveRequestObj.Employee__c);
            }
        }
        
        if(!accountIdSet.isEmpty()){
            for(Employee_Work_Week__c workWeek: [SELECT Id, Friday__c, Effective_Date__c, Monday__c, Saturday__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Working_Days_in_a_Week__c, Employee__c FROM Employee_Work_Week__c WHERE Employee__c IN: accountIdSet ORDER BY Effective_Date__c ASC]){
                List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
                
                if(empToworkWeekList.containsKey(workWeek.Employee__c)){
                    workWeekList = empToworkWeekList.get(workWeek.Employee__c);
                }
                workWeekList.add(workWeek);
                empToworkWeekList.put(workWeek.Employee__c, workWeekList);
            }
    
            for(Leave_Entitlement__c leaveEntObj: [SELECT Id, Employee__c, End_Date__c, Start_Date__c, Remaining_Sick_Leaves__c, Employee__r.Joining_Date__c, Employee__r.Organisation__c, Employee__r.Employee_Duty_Type__c FROM Leave_Entitlement__c WHERE Employee__c IN: accountIdSet ORDER BY Start_Date__c ASC]){
                List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
                
                if(accToLeaveEntMap.containsKey(leaveEntObj.Employee__c)){
                    leaveEntList = accToLeaveEntMap.get(leaveEntObj.Employee__c);
                }
                leaveEntList.add(leaveEntObj);
                orgIdSet.add(leaveEntObj.Employee__r.Organisation__c);
                accToLeaveEntMap.put(leaveEntObj.Employee__c, leaveEntList);
            }
            if(!orgIdSet.isEmpty())
                mapOrgToHolidays = getPublicHolidaysWithOrg(orgIdSet);
            
            mapLeaveEntToAppliedLeave = getLeaveEntMappedToAppliedLeave(empToworkWeekList, accToLeaveEntMap, accountIdSet, mapOrgToHolidays, sickLeaveRcTypeId, newMap);
                
            for(Leave_Request__c leaveReqObj: newList){
                if(sickLeaveRcTypeId == leaveReqObj.RecordTypeId){
                    leaveReqObj.Paid_Leaves__c = 0;
                    leaveReqObj.Unpaid_Leaves__c = 0;
                    
                    Date startDate = leaveReqObj.Leave_Start_Date__c;
                    Date endDate = leaveReqObj.Leave_End_Date__c;
                    
                    Boolean entitlementfound = false;
                    if(accToLeaveEntMap.containsKey(leaveReqObj.Employee__c)){
                        for(Leave_Entitlement__c leaveEntObj: accToLeaveEntMap.get(leaveReqObj.Employee__c)){
                            endDate = leaveReqObj.Leave_End_Date__c;
                        
                            if(endDate > leaveEntObj.End_Date__c){
                                endDate = leaveEntObj.End_Date__c;
                            }
                            else{
                                endDate = leaveReqObj.Leave_End_Date__c;
                            }
                            
                            Decimal actualLeaves = 0;
                            Integer actualLeavesWithNoWorkweek = 0;
                            
                            //if at least one workweek exists for the employee
                            if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                                Set<Public_Holiday__c> publicHolidaySet;
                                if(mapOrgToHolidays.containsKey(leaveEntObj.Employee__r.Organisation__c) && mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c) != NULL){
                                    publicHolidaySet = mapOrgToHolidays.get(leaveEntObj.Employee__r.Organisation__c);
                                }
                                actualLeaves = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, leaveEntObj.Employee__r.Employee_Duty_Type__c, true);
                                
                                if(actualLeaves == null){ //no related workweek exists for the leave period
                                    actualLeavesWithNoWorkweek = leaveReqObj.Leave_Start_Date__c.daysBetween(leaveReqObj.Leave_End_Date__c) + 1;
                                    leaveReqObj.Unpaid_Leaves__c += actualLeavesWithNoWorkweek;
                                    break;
                                }
                                else{
                                    Decimal remainingLeave = !mapLeaveEntToAppliedLeave.isEmpty() && mapLeaveEntToAppliedLeave.containsKey(leaveEntObj.Id)? leaveEntObj.Remaining_Sick_Leaves__c - mapLeaveEntToAppliedLeave.get(leaveEntObj.Id): leaveEntObj.Remaining_Sick_Leaves__c;
                                    Decimal appliedLeaves = 0;
                                    
                                    if(startDate >= leaveEntObj.Start_Date__c && leaveReqObj.Leave_End_Date__c <= leaveEntObj.End_Date__c){
                                        entitlementfound = true;
                                        //if sick leave is requested within first three months of joining - all will be unpaid
                                        if(leaveEntObj.Employee__r.Joining_Date__c != NULL && leaveReqObj.Leave_Start_Date__c <= leaveEntObj.Employee__r.Joining_Date__c.addMonths(3)){
                                            leaveReqObj.Unpaid_Leaves__c += actualLeaves;
                                        }
                                        else if(actualLeaves < remainingLeave){
                                            leaveReqObj.Paid_Leaves__c += actualLeaves;
                                            appliedLeaves += actualLeaves;
                                        }
                                        else{
                                            leaveReqObj.Paid_Leaves__c += remainingLeave;
                                            appliedLeaves += remainingLeave;
                                            leaveReqObj.Unpaid_Leaves__c += actualLeaves - remainingLeave;
                                        }
                                        
                                        if(mapLeaveEntToAppliedLeave.containsKey(leaveEntObj.Id)){
                                            appliedLeaves += mapLeaveEntToAppliedLeave.get(leaveEntObj.Id);
                                        }
                                        Decimal roundUpVal = appliedLeaves.round(System.RoundingMode.HALF_UP);
                                        mapLeaveEntToAppliedLeave.put(leaveEntObj.Id, roundUpVal);
                                        break;
                                    }
                                    else if(startDate >= leaveEntObj.Start_Date__c &&  leaveEntObj.End_Date__c >= startdate){
                                        entitlementfound = true;
                                        //if sick leave is requested within first three months of joining - all will be unpaid
                                        if(leaveEntObj.Employee__r.Joining_Date__c != NULL && leaveReqObj.Leave_Start_Date__c <= leaveEntObj.Employee__r.Joining_Date__c.addMonths(3)){
                                            leaveReqObj.Unpaid_Leaves__c += actualLeaves;
                                        }
                                        else if(actualLeaves < remainingLeave){
                                            leaveReqObj.Paid_Leaves__c += actualLeaves;
                                            appliedLeaves += actualLeaves;
                                        }
                                        else{
                                            leaveReqObj.Paid_Leaves__c += remainingLeave;
                                            appliedLeaves += remainingLeave;
                                            leaveReqObj.Unpaid_Leaves__c += actualLeaves - remainingLeave;
                                        }
                                        
                                        
                                        if(mapLeaveEntToAppliedLeave.containsKey(leaveEntObj.Id)){
                                            appliedLeaves += mapLeaveEntToAppliedLeave.get(leaveEntObj.Id);
                                        }
                                        Decimal roundUpVal = appliedLeaves.round(System.RoundingMode.HALF_UP);
                                        mapLeaveEntToAppliedLeave.put(leaveEntObj.Id, roundUpVal);
                                        
                                        startDate = leaveEntObj.End_Date__c.addDays(1);
                                    }
                                }
                            }
                            else{ //if no work week is created for the employee
                                actualLeavesWithNoWorkweek = leaveReqObj.Leave_Start_Date__c.daysBetween(leaveReqObj.Leave_End_Date__c) + 1;
                                leaveReqObj.Unpaid_Leaves__c += actualLeavesWithNoWorkweek;
                                break;
                            }
                        }
                    }
                    if(!entitlementfound){ //if no entitlement is created then all will be unpaid for this sick leave record
                        leaveReqObj.Unpaid_Leaves__c = leaveReqObj.Leave_Start_Date__c.daysBetween(leaveReqObj.Leave_End_Date__c) + 1;
                    }
                    leaveReqObj.Type__c = NULL;

                    //if all leaves are paid then type will be paid, if all leaves are unpaid then type will be unpaid, else type will be blank
                    if(leaveReqObj.Paid_Leaves__c != 0 && leaveReqObj.Unpaid_Leaves__c == 0){
                        leaveReqObj.Type__c = 'Paid';
                    }
                    else if(leaveReqObj.Paid_Leaves__c == 0 && leaveReqObj.Unpaid_Leaves__c != 0){
                        leaveReqObj.Type__c = 'Unpaid';
                    }
                }
            }
        }
    }
    
    //Sick Leave: calls calcLossAndCreatePayItemForUnpaidLeave to create PayItem records if the current month Leave Requests are approved.
    // Called from LeaveRequestTrigger.
    private static void createPayItemForUnpaidLeave(List<Leave_Request__c> unpaidSickLeaveRequestList, Map<Id, Leave_Request__c> newMap){
        /*Date todayDate = system.today();
        Date currMonthStartDate = todayDate.toStartOfMonth();
        Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);*/
        
        Set<Id> empIdSet = new Set<Id>();
        Set<Id> payoutIdSet = new Set<Id>();
        
        for(Leave_Request__c leaveReq: unpaidSickLeaveRequestList){
            //if(leaveReq.Leave_End_Date__c >= currMonthStartDate && leaveReq.Leave_Start_Date__c <= currMonthEndDate){
                if(leaveReq.Employee__c != NULL){
                    empIdSet.add(leaveReq.Employee__c);
                }
            //}
        }
        
        if(!empIdSet.isEmpty()){
            for(Payout__c payoutObj: [SELECT Id FROM Payout__c WHERE Employee_Name__c IN: empIdSet]){ // AND Month__c =: numberToMonthMap.get(currMonthStartDate.month())
                payoutIdSet.add(payoutObj.Id);
            }
        }
        
        if(!payoutIdSet.isEmpty()){
            System.debug('payoutIdSet'+payoutIdSet);
            System.debug(newMap);
            calcLossAndCreatePayItemForUnpaidLeave(payoutIdSet, newMap, null, empIdSet);
        }
    }
    
    //NSMen Leave: calls createPayItemWithoutPLR to create PayItem records if the current month NS Men Leave Requests are approved.
    // Called from LeaveRequestTrigger.
    public static void createPayItemForNSMen(List<Leave_Request__c> nsMenLeaveRequestList, Map<Id, Leave_Request__c> newMap){
        /*Date todayDate = system.today();
        Date currMonthStartDate = todayDate.toStartOfMonth();
        Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);*/
                
        Set<Id> empIdSet = new Set<Id>();
        Set<Id> payoutIdSet = new Set<Id>();
        
        for(Leave_Request__c leaveReqObj: nsMenLeaveRequestList){
            //if(leaveReqObj.Leave_End_Date__c >= currMonthStartDate && leaveReqObj.Leave_Start_Date__c <= currMonthEndDate){
                if(leaveReqObj.Employee__c != NULL){
                    empIdSet.add(leaveReqObj.Employee__c);
                }
            //}
        }
        
        if(!empIdSet.isEmpty()){
            //String year = currMonthStartDate.year() +'';
            for(Payout__c payoutObj: [SELECT Id FROM Payout__c WHERE Employee_Name__c IN: empIdSet]){ // AND Month__c =: numberToMonthMap.get(currMonthStartDate.month()) AND Year__c =: year
                payoutIdSet.add(payoutObj.Id);
            }
        }
        
        if(!payoutIdSet.isEmpty()){
            System.debug('called calcLossAndCreatePayItemForNSMen');
            List<Payitem_Master__c> NSMenPayitemMasterObj = [SELECT Id FROM Payitem_Master__c WHERE Name = 'NS Make-up Pay' AND Active__c = TRUE];
            
            if(NSMenPayitemMasterObj != NULL && NSMenPayitemMasterObj.size()>0){
                System.debug(payoutIdSet);
                createPayItemWithoutPLR(payoutIdSet, newMap, null, empIdSet);
            }
        }
    }
    
    //Leave dates can only be updated for Draft/In Approval status. Works for all record types. Called from LeaveRequestTrigger
    public static void leaveDateUpdateValidation(List<Leave_Request__c> newList, Map<Id,Leave_Request__c> oldMap){
        for(Leave_Request__c leavReq: newList){
            if(leavReq.Status__c != 'Draft' && leavReq.Status__c != 'Pending' && (leavReq.Leave_Start_Date__c != oldMap.get(leavReq.Id).Leave_Start_Date__c || leavReq.Leave_End_Date__c != oldMap.get(leavReq.Id).Leave_End_Date__c)){
                leavReq.addError(label.OnlyUpdateLeaveDateIfDraft);
            }
        }
    }
    
    //calculates working days to get actual leaves applied. Called from this Util class.
    private static Decimal calculateWorkingDays(Date startDate, Date endDate, List<Employee_Work_Week__c> workWeekList, Set<Public_Holiday__c> publicHolidaySet, String empType, Boolean isHalfDayFullDay){
        Map<String, Decimal> mapDayTypeToNumericVal = new Map<String, Decimal>{'Half Day' => 0.5, 'Full Day' => 1, 'Rest Day' => 0};
        Decimal actualLeavesApplied = 0;
        Date sundayDate = Date.newInstance(1900, 1, 7);
        Map<Employee_Work_Week__c, Map<String, Date>> mapWorkWeekToStartEndDate = new Map<Employee_Work_Week__c, Map<String, Date>>();
        Map<Integer, Decimal> mapWorkWeekToDays;
        Boolean workweekFound = false;
         
        for(Integer i = 0; i < workWeekList.size(); i++){
            Employee_Work_Week__c empWorkWeek = workWeekList[i];
            Integer j = i+1;
            Map<String, Date> tempMap = new Map<String, Date>();
            tempMap.put('start', workWeekList[i].Effective_Date__c);
            
            if(j < workWeekList.size()){
                tempMap.put('end', workWeekList[j].Effective_Date__c.addDays(-1));
                mapWorkWeekToStartEndDate.put(empWorkWeek, tempMap);
            }
            else{
                tempMap.put('end', endDate);
                mapWorkWeekToStartEndDate.put(empWorkWeek, tempMap);
            }
        }
        
        for(Employee_Work_Week__c empWorkWeek: workWeekList){
            Decimal workingDaysInWeek = empWorkWeek.Working_Days_in_a_Week__c;
            mapWorkWeekToDays = new Map<Integer, Decimal>{0 => mapDayTypeToNumericVal.get(empWorkWeek.Sunday__c), 1 => mapDayTypeToNumericVal.get(empWorkWeek.Monday__c), 2 => mapDayTypeToNumericVal.get(empWorkWeek.Tuesday__c), 3 => mapDayTypeToNumericVal.get(empWorkWeek.Wednesday__c), 4 => mapDayTypeToNumericVal.get(empWorkWeek.Thursday__c), 5 => mapDayTypeToNumericVal.get(empWorkWeek.Friday__c), 6 => mapDayTypeToNumericVal.get(empWorkWeek.Saturday__c)};
            
            if(isHalfDayFullDay){
                Decimal tempWorkingDaysInWeek = 0;
                for(Integer i: mapWorkWeekToDays.KeySet()){
                    if(mapWorkWeekToDays.get(i) != 0){ //if not rest day
                        tempWorkingDaysInWeek += 1;
                        mapWorkWeekToDays.put(i, 1); //treat half day as full day
                    }
                }
                workingDaysInWeek = tempWorkingDaysInWeek;
            }
            Date empWorkWeekEndDate;
            if(mapWorkWeekToStartEndDate.containsKey(empWorkWeek)){
                empWorkWeekEndDate = mapWorkWeekToStartEndDate.get(empWorkWeek).get('end');
            }
            
            if(empWorkWeekEndDate != NULL){
                if(empWorkWeekEndDate > endDate){
                    empWorkWeekEndDate = endDate;
                }
                if(startDate >= empWorkWeek.Effective_Date__c && endDate <= empWorkWeekEndDate){                    
                    workweekFound = true;
                    Integer numberOfLeavesApplied = startDate.daysBetween(empWorkWeekEndDate)+1;
                    Integer currentDayOfWeek = Math.mod(sundayDate.daysBetween(startDate), 7); //returns 0 for Sunday and 6 for Saturday
                    
                    if((numberOfLeavesApplied/7) >= 1){
                        actualLeavesApplied += (numberOfLeavesApplied/7) * workingDaysInWeek;
                    }
                    
                    if(Math.mod(numberOfLeavesApplied, 7) > 0){
                        Integer remainingDays = Math.mod(numberOfLeavesApplied, 7);
                        Integer counterForRemainingDays = remainingDays;
                        
                        for(Integer i=currentDayOfWeek; i<7; i++){
                            if(counterForRemainingDays == 0){
                                break;
                            }
                            if(mapWorkWeekToDays.containsKey(i)){
                                actualLeavesApplied += mapWorkWeekToDays.get(i);
                            }
                            counterForRemainingDays--;
                            if(i==6){
                                i=-1;
                                continue;
                            }
                        }
                    }
                    break;
                }
                else if(startDate >= empWorkWeek.Effective_Date__c && empWorkWeekEndDate >= startdate){
                    workweekFound = true;
                    Integer numberOfLeavesApplied = startDate.daysBetween(empWorkWeekEndDate)+1;
                    Integer currentDayOfWeek = Math.mod(sundayDate.daysBetween(startDate), 7); //returns 0 for Sunday and 6 for Saturday
                    
                    if((numberOfLeavesApplied/7) >= 1){
                        actualLeavesApplied += (numberOfLeavesApplied/7) * empWorkWeek.Working_Days_in_a_Week__c;
                    }
                    
                    if(Math.mod(numberOfLeavesApplied, 7) > 0){
                        Integer remainingDays = Math.mod(numberOfLeavesApplied, 7);
                        Integer counterForRemainingDays = remainingDays;
                        
                        for(Integer i=currentDayOfWeek; i<7; i++){
                            if(counterForRemainingDays == 0){
                                break;
                            }
                            if(mapWorkWeekToDays.containsKey(i)){
                                actualLeavesApplied += mapWorkWeekToDays.get(i);
                            }
                            counterForRemainingDays--;
                            if(i==6){
                                i=-1;
                                continue;
                            }
                        }
                    }
                    startDate = empWorkWeekEndDate.addDays(1);
                }
            }
        }
        
        if(!workweekFound){ //if no related workweek is found then actualLeavesApplied will be null
            return 0;
        }
        Decimal publicHolidaysToAddBack = 0;
        System.debug(empType);
        
        if(publicHolidaySet != NULL && !publicHolidaySet.isEmpty()){
            for(Public_Holiday__c phObj: publicHolidaySet){
                System.debug(phObj);
                if(phObj.Public_Holiday_Date__c >= startDate && phObj.Public_Holiday_Date__c <= endDate && (phObj.Organisation_Status__c == 'Closed' || (phObj.Organisation_Status__c == 'Open' && empType == 'Duty'))){
                    Integer phDayOfWeek = Math.mod(sundayDate.daysBetween(phObj.Public_Holiday_Date__c), 7); //returns 0 for Sunday and 6 for Saturday
                    System.debug(phDayOfWeek);
                    publicHolidaysToAddBack += mapWorkWeekToDays.get(phDayOfWeek);
                }
            }
        }
        
        System.debug(actualLeavesApplied);
        System.debug(publicHolidaysToAddBack);
        actualLeavesApplied = actualLeavesApplied - publicHolidaysToAddBack;
        
        return actualLeavesApplied;
    }
    
    //Sick Leave: calculates Loss of Income in case of Unpaid Leave Request. Called from LeaveRequestTrigger and a batch class that creates Payout records.
    public static void calcLossAndCreatePayItemForUnpaidLeave(Set<Id> payoutIdSet, Map<Id, Leave_Request__c> unpaidLeaveRequestMap, Date processDate, Set<Id> empIdSet){  
        List<Payitem_Master__c> unpaidPayitemMasterObj = [SELECT Id FROM Payitem_Master__c WHERE Name = 'Unpaid Sick Leave' 
                                                          AND Active__c = TRUE];
        Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Set<Id> setPayoutId = new Set<Id>();
        Set<Id> employeeIdSet = new Set<Id>();
        
        if(unpaidPayitemMasterObj != NULL && unpaidPayitemMasterObj.size()>0){            
            List<Payout__c> payoutList;
            system.debug('empIdSet'+empIdSet);
            if(empIdSet != NULL && empIdSet.size()>0)
                payoutList = [SELECT Id, Year__c, Month__c, Salary__c, Total_OW_Amount__c, Monthly_Working_Days__c, Employee_Name__c,
                              Daily_Rate__c FROM Payout__c WHERE Employee_Name__c IN: empIdSet];
            else
                payoutList = [SELECT Id, Year__c, Month__c, Salary__c, Total_OW_Amount__c, Monthly_Working_Days__c, Employee_Name__c, 
                              Daily_Rate__c FROM Payout__c WHERE Id IN: payoutIdSet];
             system.debug('payoutList'+payoutList);
            if(payoutList != NULL && payoutList.size() > 0){
                Date todayDate = system.today();
                if(processDate != NULL)
                    todayDate = processDate;
                Date currMonthStartDate = todayDate.toStartOfMonth();
                Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);
                
                String currentMonth = numberToMonthMap.get(currMonthStartDate.month());
                String currentYear = currMonthStartDate.year()+'';
                Map<Id, List<Payout__c>> mapEmpToPayoutObj = new Map<Id, List<Payout__c>>();
                Map<String, PayItem__c> mapPayoutToPayItem = new Map<String, PayItem__c>();
                Map<String, PayItem__c> mapPayoutToPayItemToInsert = new Map<String, PayItem__c>();
                Map<Id, Id> mapLeaveReqToPayout = new Map<Id, Id>();
                
                for(Payout__c payoutObj: payoutList){
                    List<Payout__c> payoutListTemp = new List<Payout__c>();
                    if(mapEmpToPayoutObj.containsKey(payoutObj.Employee_Name__c)){
                        payoutListTemp = mapEmpToPayoutObj.get(payoutObj.Employee_Name__c);
                    }
                    payoutListTemp.add(payoutObj);
                    mapEmpToPayoutObj.put(payoutObj.Employee_Name__c, payoutListTemp);
                    employeeIdSet.add(payoutObj.Employee_Name__c);
                    setPayoutId.add(payoutObj.Id);
                }
                 system.debug('setPayoutId'+setPayoutId);
                   system.debug('unpaidPayitemMasterObj'+unpaidPayitemMasterObj[0].Id);
                //get existing PayItem records
                for(PayItem__c payitemObj: [SELECT Id, Payout__c, Notes__c, No_of_Days__c, Payitem__c, System_Generated__c, 
                                            Type__c, Value__c FROM PayItem__c WHERE Payout__c IN: setPayoutId AND Payitem__c =: 
                                            unpaidPayitemMasterObj[0].Id]){
                    mapPayoutToPayItem.put(payitemObj.Payout__c, payitemObj);
                }
                 system.debug('mapPayoutToPayItem'+mapPayoutToPayItem);
                List<Payitem_Leave_Request__c> plrList = [SELECT Id, Leave_Request__c, Month__c, Year__c, Unpaid_Leaves__c, Leave_Request__r.Employee__c, PayItem__c FROM Payitem_Leave_Request__c WHERE Leave_Request__r.Employee__c IN: employeeIdSet AND PayItem__c = NULL];
                Set<Id> leaveReqIdSet = new Set<Id>();
                Map<String, Payitem_Leave_Request__c> mapYearMonthToPLR = new Map<String, Payitem_Leave_Request__c>();
                 system.debug('plrList'+plrList);
                for(Payitem_Leave_Request__c plrObj: plrList){
                    leaveReqIdSet.add(plrObj.Leave_Request__c);
                    mapYearMonthToPLR.put(plrObj.Month__c+'-'+plrObj.Year__c+'-'+plrObj.Leave_Request__c, plrObj);
                }
                
                System.debug(mapYearMonthToPLR);
                
                List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
                
                if(unpaidLeaveRequestMap != NULL){
                    System.debug(unpaidLeaveRequestMap);
                    leaveReqList = [SELECT Id, Name, Employee__c, Leave_Start_Date__c, Leave_End_Date__c FROM Leave_Request__c WHERE
                                    Id IN: unpaidLeaveRequestMap.KeySet()];
                }
                else{
                    leaveReqList = [SELECT Id, Name, Employee__c, Leave_Start_Date__c, Leave_End_Date__c FROM Leave_Request__c 
                                    WHERE (Leave_End_Date__c >=: currMonthStartDate AND Leave_Start_Date__c <=: currMonthEndDate)
                                    AND RecordTypeId =: sickLeaveRcTypeId AND 
                                    Employee__c IN: mapEmpToPayoutObj.KeySet() AND (Status__c = 'Approved' OR Status__c = 'Rejected')];
                }
                System.debug('leaveReqList'+leaveReqList);
                Set<String> validMonthYearLeaveReq = new Set<String>();
                if(!leaveReqList.isEmpty()){
                    System.debug(leaveReqList);
                    for(Leave_Request__c leaveReqObj: leaveReqList){
                        if(mapEmpToPayoutObj.containsKey(leaveReqObj.Employee__c)){
                            if(mapEmpToPayoutObj.containsKey(leaveReqObj.Employee__c)){
                                List<Payout__c> payoutObjList = mapEmpToPayoutObj.get(leaveReqObj.Employee__c);
                                for(Payout__c payoutObj: payoutObjList){
                                    Integer yearInt = Integer.valueOf(payoutObj.Year__c);
                                    Integer monthInt = monthMap.get(payoutObj.Month__c);
                                    Date payoutStartDate = Date.newInstance(yearInt, monthInt, 1);
                                    Date payoutEndDate = payoutStartDate.addDays(date.daysInMonth(payoutStartDate.year(), payoutStartDate.month())-1);
                                    
                                    //if leave request is for this payout
                                    if(leaveReqObj.Leave_End_Date__c >= payoutStartDate && leaveReqObj.Leave_Start_Date__c <= payoutEndDate){
                                        validMonthYearLeaveReq.add(leaveReqObj.Id + '-' + payoutObj.Month__c + '-'+payoutObj.Year__c);
                                        PayItem__c payItemObj;
                                        System.debug(payoutObj.Month__c+'-'+ payoutObj.Year__c+'-'+leaveReqObj.Id);
                                        if(mapYearMonthToPLR.containsKey(payoutObj.Month__c+'-'+ payoutObj.Year__c+'-'+leaveReqObj.Id)){
                                            Decimal noOfDays = mapYearMonthToPLR.get(payoutObj.Month__c+'-'+ payoutObj.Year__c+'-'+leaveReqObj.Id).Unpaid_Leaves__c;
                                            noOfDays = noOfDays != NULL? noOfDays : 0;
                                            
                                            System.debug(payoutObj.Daily_Rate__c);
                                            System.debug(noOfDays);
                                            if(mapPayoutToPayItem.containsKey(payoutObj.Id)){ //if PayItem is already created for the month year
                                                payItemObj = mapPayoutToPayItem.get(payoutObj.Id);
                                                payItemObj.Value__c += noOfDays;
                                                payItemObj.Notes__c = payItemObj.Notes__c.removeEnd('.') + ', ' + leaveReqObj.Name + '.';
                                            }
                                            else{
                                                payItemObj = new PayItem__c(Payitem__c = unpaidPayitemMasterObj[0].Id, Payout__c = payoutObj.Id);
                                                payItemObj.Value__c = noOfDays;
                                                payItemObj.Notes__c = 'Calculated on the basis of '+ leaveReqObj.Name + '.';
                                            }
                                            if(payItemObj != NULL){
                                                payItemObj.Type__c = 'Days';
                                                payItemObj.System_Generated__c = TRUE;
                                                mapPayoutToPayItem.put(payoutObj.Id, payItemObj);
                                                mapPayoutToPayItemToInsert.put(payoutObj.Id, payItemObj);
                                                mapLeaveReqToPayout.put(leaveReqObj.Id, payoutObj.Id);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                System.debug('mapPayoutToPayItem'+mapPayoutToPayItem);
                
                if(!mapPayoutToPayItem.isEmpty()){
                    upsert mapPayoutToPayItem.values();
                    
                    for(Payitem_Leave_Request__c plrObj: plrList){
                        if(mapLeaveReqToPayout.containsKey(plrObj.Leave_Request__c)){
                            if(mapPayoutToPayItem.containsKey(mapLeaveReqToPayout.get(plrObj.Leave_Request__c))){
                                if(validMonthYearLeaveReq.contains(plrObj.Leave_Request__c + '-' + plrObj.Month__c + '-' + plrObj.Year__c))
                                    plrObj.PayItem__c = mapPayoutToPayItem.get(mapLeaveReqToPayout.get(plrObj.Leave_Request__c)).Id;
                            }
                        }
                    }
                     System.debug('plrList'+plrList);
                    if(!plrList.isEmpty()){
                        update plrList;
                    }
                }
            }
        }
    }
    
    //Maternity Leave Calculation: populates end leave date for maternity leave. Called from LeaveRequestTrigger (Before insert, update)
    public static void maternityEndLeaveCalc(List<Leave_Request__c> leaveReqList){
        Id maternityRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
        Integer noOfDays = 0, noOfWeeks = 0, noOfPaidWeek = 0, noOfUnpaidWeek = 0;
        
        for(Leave_Request__c leaveReq: leaveReqList){
            if(leaveReq.RecordtypeId == maternityRcTypeId){
                leaveReq.Leave_End_Date__c = NULL;
                if(leaveReq.No_of_Weeks__c != NULL && leaveReq.Leave_Start_Date__c != NULL){
                    noOfDays = Integer.valueOf(leaveReq.No_of_Weeks__c) * 7;
                    leaveReq.Leave_End_Date__c = leaveReq.Leave_Start_Date__c.addDays(noOfDays);
                }
            }
        }
    }
    
    //Maternity Leave Validation: allows only female employees to apply for maternity leave. Called from LeaveRequestTrigger (Before insert, update)
    public static void maternityLeaveFemaleValidation(List<Leave_Request__c> newList){
        Id maternityLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> validEmployee = new Set<Id>();
        
        for(Leave_Request__c leaveReq: newList){
            if(leaveReq.RecordTypeId == maternityLeaveRcTypeId){
                accIdSet.add(leaveReq.Employee__c);
            }
        }
        
        for(Account accObj: [SELECT Id, Gender__c FROM Account WHERE Id IN: accIdSet AND Gender__c = 'Female']){
            validEmployee.add(accObj.Id);
        }
        
        for(Leave_Request__c leaveReq: newList){
            if(leaveReq.RecordTypeId == maternityLeaveRcTypeId && !validEmployee.contains(leaveReq.Employee__c)){
                leaveReq.addError(label.OnlyFemaleToApplyForMaternityLeave);
            }
        }
    }
    
    //Maternity Leave Validation: checks no of weeks is equal to sum of paid and unpaid week. Called from LeaveRequestTrigger(Before Insert, Update).
    public static void maternityLeaveWeekValidation(List<Leave_Request__c> leaveReqList){
        Id maternityRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
        Integer noOfWeeks = 0, noOfPaidWeek = 0, noOfUnpaidWeek = 0;
        
        for(Leave_Request__c leaveReq: leaveReqList){
            if(leaveReq.RecordTypeId == maternityRcTypeId){
                //Sum of Paid Week and Unpaid Week must be equal to No. of Weeks
                noOfWeeks = leaveReq.No_of_Weeks__c != NULL? Integer.valueOf(leaveReq.No_of_Weeks__c): 0;
                noOfPaidWeek = leaveReq.Paid_Week__c != NULL? Integer.valueOf(leaveReq.Paid_Week__c): 0;
                noOfUnpaidWeek = leaveReq.Unpaid_Week__c != NULL? Integer.valueOf(leaveReq.Unpaid_Week__c): 0;
                
                if((noOfPaidWeek + noOfUnpaidWeek) != noOfWeeks){
                    leaveReq.addError(label.MaternityLeavePaidUnpaidWeekError);
                }
            }
        }
    }
    
    //Maternity Leave: Create PayItem record for unpaid leave in this month
    public static void createPayItemForMaternity(List<Leave_Request__c> maternityLeaveRequestList, Map<Id, Leave_Request__c> newMap){
        Set<Id> empIdSet = new Set<Id>();
        Set<Id> payoutIdSet = new Set<Id>();
        
        /*Date todayDate = system.today();
        Date currMonthStartDate = todayDate.toStartOfMonth();
        Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);*/
        
        for(Leave_Request__c leaveReqObj: maternityLeaveRequestList){
            //if(leaveReqObj.Leave_End_Date__c >= currMonthStartDate && leaveReqObj.Leave_Start_Date__c <= currMonthEndDate){
                if(leaveReqObj.Employee__c != NULL){
                    empIdSet.add(leaveReqObj.Employee__c);
                }
            //}
        }
        
        if(!empIdSet.isEmpty()){
            //String year = currMonthStartDate.year() +'';
            for(Payout__c payoutObj: [SELECT Id FROM Payout__c WHERE Employee_Name__c IN: empIdSet]){ // AND Month__c =: numberToMonthMap.get(currMonthStartDate.month()) AND Year__c =: year
                payoutIdSet.add(payoutObj.Id);
            }
        }
        
        //if payout for current month exists for the employee
        if(!payoutIdSet.isEmpty()){
            System.debug('called calcLossAndCreatePayItemForMaternity');
            List<Payitem_Master__c> UnpaidPayitemMasterObj = [SELECT Id FROM Payitem_Master__c WHERE Name = 'Unpaid Leave' AND Active__c = TRUE];
            
            if(UnpaidPayitemMasterObj != NULL && UnpaidPayitemMasterObj.size()>0){
                createPayItemWithoutPLR(payoutIdSet, newMap, null, empIdSet);
            }
        }
    }
    
	//Nishi : 9-Apr-2021:get teacher active hrs. according to booking 
    public static List<Booking__c> getBookingsOnSelectedDates(Set<id> teacherIds,date currentDate){
        date monthStartdate = Date.newInstance(currentDate.year(),currentDate.month(),1);
        date monthEndDate = Date.newInstance(monthStartdate.year(), monthStartdate.month(), date.daysInMonth(monthStartdate.year(),monthStartdate.month()));
        Set<Date> dates = new Set<Date>();
        for(Integer i = 0; i < date.daysInMonth(monthStartdate.year(),monthStartdate.month()); i++){
            dates.add(monthStartdate.addDays(i)); 
        }
        Set<string> recordTypeSet = new Set<String>{ConstantsClass.recordTypeLesson};//,ConstantsClass.groupLessonBookingRecordType
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending,  ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted,'Canceled'};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.typeTrial,  ConstantsClass.typeMakeup,ConstantsClass.typeAdhoc};
        set<string> bookingValidType =  new Set<String>{ConstantsClass.typeRegular};//, ConstantsClass.groupLessonTypeBooking
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory}; 
        string cancelledEnrolment ='Cancelled';   
        string fixedpayout ='Fixed';    
        Date dt, endDt;
        String busyType = ConstantsClass.typeBusy;
        string packageProcessType = ConstantsClass.enrollmentProcessCancelType;
        String weekDay;
        String queryStr = 'SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c,Teacher_Account__r.Tiered_Salary__c , RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c,Duration__c FROM Booking__c';
        queryStr += ' WHERE RecordType.Name in: recordTypeSet AND Start_Time__c != NULL AND End_Time__c != NULL';
        if(teacherIds != null && teacherIds.size() > 0){
            queryStr += ' AND Teacher_Account__c In: teacherIds';
            queryStr += ' AND Teacher_Account__r.Payout_Type__c =: fixedpayout';
        	//queryStr += ' AND Teacher_Account__r.Tiered_Salary__c = true';
        }
        queryStr += ' AND Booking_Date__c >=: monthStartdate AND Booking_Date__c <= :monthEndDate';
        queryStr += ' AND status__c IN: bookingStatus AND (Type__c IN: bookingValidType And (Enrolment__r.Stage__c !=: cancelledEnrolment Or (Enrolment__r.Package_Process_Status__c !=: packageProcessType and Booking_Date__c > :monthEndDate)))';
        return Database.query(queryStr);
    }

    //Nishi : 9-Apr-2021:Add Pay Item For Salary Payroll accding to employee  working hrs.
   
    public static void createPayItemForSalaryPayroll(Set<id> employeeIds,date currentdate,Set<Id> payoutIdSet){
        list<booking__c> listOfBookings = getBookingsOnSelectedDates(employeeIds,currentdate);
        Set<Id> empIdSet = new Set<Id>();
        Map<string,decimal> employeeWorkingHrs = new Map<string,decimal>();
        set<string> employeetiredIds = new Set<string>();
        if( listOfBookings != null && listOfBookings.size()> 0){
            for(booking__c bookingObj: listOfBookings){
                empIdSet.add(bookingObj.Teacher_Account__c);
                decimal totalworkingHrs  = 0;
                if(bookingObj.Teacher_Account__r.Tiered_Salary__c){
                    employeetiredIds.add(bookingObj.Teacher_Account__c);
                }
                if(employeeWorkingHrs.containsKey(bookingObj.Teacher_Account__c)){
                    totalworkingHrs = employeeWorkingHrs.get(bookingObj.Teacher_Account__c);
                }
                totalworkingHrs += (bookingObj.Duration__c);
                employeeWorkingHrs.put(bookingObj.Teacher_Account__c,totalworkingHrs);
            }
            System.debug(empIdSet);
        }
        
        List<Payitem_Master__c> unpaidPayitemMasterObj = [SELECT Id,CPF__c  FROM Payitem_Master__c WHERE Name =: label.Salary_Tier_Master_Payitem_Name 
                                                          AND Active__c = TRUE];
        Set<Id> setPayoutId = new Set<Id>();
        Set<Id> employeeIdSet = new Set<Id>();
        
        if(unpaidPayitemMasterObj != NULL && unpaidPayitemMasterObj.size()>0){            
            List<Payout__c> payoutList;
            system.debug('empIdSet'+empIdSet);
            if(payoutIdSet != NULL && payoutIdSet.size()>0)
                payoutList = [SELECT Id, Year__c, Month__c, Salary__c, Total_OW_Amount__c, Monthly_Working_Days__c, Employee_Name__c, 
                              Daily_Rate__c FROM Payout__c WHERE Id IN: payoutIdSet];
            else
            payoutList = [SELECT Id, Year__c, Month__c, Salary__c, Total_OW_Amount__c, Monthly_Working_Days__c, Employee_Name__c,
                            Daily_Rate__c FROM Payout__c WHERE Employee_Name__c IN: empIdSet]; 
            system.debug('payoutList'+payoutList);
            if(payoutList != NULL && payoutList.size() > 0 && employeeWorkingHrs != null && employeeWorkingHrs.size()> 0){
                Date todayDate = system.today();
                if(currentdate != NULL)
                    todayDate = currentdate;
                Date currMonthStartDate = todayDate.toStartOfMonth();
                Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);
                
                String currentMonth = numberToMonthMap.get(currMonthStartDate.month());
                String currentYear = currMonthStartDate.year()+'';
                Map<Id, List<Payout__c>> mapEmpToPayoutObj = new Map<Id, List<Payout__c>>();
                Map<String, PayItem__c> mapPayoutToPayItem = new Map<String, PayItem__c>();
                Map<String, PayItem__c> mapPayoutToPayItemToInsert = new Map<String, PayItem__c>();
                Map<Id, Id> mapLeaveReqToPayout = new Map<Id, Id>();
                
                
                system.debug('payoutIdSet'+payoutIdSet);
                system.debug('unpaidPayitemMasterObj'+unpaidPayitemMasterObj[0].Id);
                //get existing PayItem records
                for(PayItem__c payitemObj: [SELECT Id, Payout__c, Notes__c, No_of_Days__c, Payitem__c, System_Generated__c, 
                                            Type__c, Value__c FROM PayItem__c WHERE Payout__c IN: payoutIdSet 
                                            AND Payitem__c =: unpaidPayitemMasterObj[0].Id]){
                                                mapPayoutToPayItem.put(payitemObj.Payout__c, payitemObj);
                                            }
                system.debug('mapPayoutToPayItem'+mapPayoutToPayItem);
                Set<String> validMonthYearLeaveReq = new Set<String>();
                if(!payoutList.isEmpty()){
                    System.debug(payoutList);
                    for(Payout__c payoutObj: payoutList){
                        Integer yearInt = Integer.valueOf(payoutObj.Year__c);
                        Integer monthInt = monthMap.get(payoutObj.Month__c);
                        Date payoutStartDate = Date.newInstance(yearInt, monthInt, 1);
                        Date payoutEndDate = payoutStartDate.addDays(date.daysInMonth(payoutStartDate.year(), payoutStartDate.month())-1);
                        
                        //if leave request is for this payout
                        PayItem__c payItemObj;
                        if(employeeWorkingHrs.containsKey(payoutObj.Employee_Name__c)){
                            Decimal noOfHours = employeeWorkingHrs.get(payoutObj.Employee_Name__c);
                            noOfHours = noOfHours != NULL? (noOfHours/60) : 0;
                            if(mapPayoutToPayItem.containsKey(payoutObj.Id)){ //if PayItem is already created for the month year
                                payItemObj = mapPayoutToPayItem.get(payoutObj.Id);
                                if(employeetiredIds.contains(payoutObj.Employee_Name__c)){
                                    payItemObj.Value__c = noOfHours;
                                }
                            }
                            else{
                                if(employeetiredIds.contains(payoutObj.Employee_Name__c)){
                                    payItemObj = new PayItem__c(Payitem__c = unpaidPayitemMasterObj[0].Id, Payout__c = payoutObj.Id);
                                    payItemObj.Value__c = noOfHours;
                                    payItemObj.Notes__c = 'Calculated on the basis of all Regular bookings.';
                                }
                            }
                            if(payItemObj != NULL){
                                payItemObj.Type__c = 'Hours';
                                payItemObj.CPF__c =unpaidPayitemMasterObj[0].CPF__c;
                                payItemObj.System_Generated__c = TRUE;
                                mapPayoutToPayItem.put(payoutObj.Id, payItemObj);
                            }
                            
                        }
                    }
                }
                
                System.debug('mapPayoutToPayItem'+mapPayoutToPayItem);
                
                if(!mapPayoutToPayItem.isEmpty()){
                    upsert mapPayoutToPayItem.values();
                    
                }
            }
        }
    }

    //Other Leave: Create PayItem record for unpaid leave in this month
    public static void createPayItemForOtherLeave(List<Leave_Request__c> otherLeaveRequestList, Map<Id, Leave_Request__c> newMap){
        System.debug('createPayItemForOtherLeave');
        Set<Id> empIdSet = new Set<Id>();
        Set<Id> payoutIdSet = new Set<Id>();
        
        /*Date todayDate = system.today();
        Date currMonthStartDate = todayDate.toStartOfMonth();
        Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);*/
        
        for(Leave_Request__c leaveReqObj: otherLeaveRequestList){
            //if(leaveReqObj.Leave_End_Date__c >= currMonthStartDate && leaveReqObj.Leave_Start_Date__c <= currMonthEndDate){
                if(leaveReqObj.Employee__c != NULL){
                    empIdSet.add(leaveReqObj.Employee__c);
                }
            //}
        }
        System.debug(empIdSet);
        
        if(!empIdSet.isEmpty()){
            //String year = currMonthStartDate.year() +'';
            for(Payout__c payoutObj: [SELECT Id FROM Payout__c WHERE Employee_Name__c IN: empIdSet]){ // AND Month__c =: numberToMonthMap.get(currMonthStartDate.month()) AND Year__c =: year
                payoutIdSet.add(payoutObj.Id);
            }
        }
        
        System.debug(payoutIdSet);
        //if payout for current month exists for the employee
        if(!payoutIdSet.isEmpty()){
            System.debug('called calcLossAndCreatePayItemForMaternity');
            List<Payitem_Master__c> UnpaidPayitemMasterObj = [SELECT Id FROM Payitem_Master__c WHERE Name = 'Unpaid Leave' AND Active__c = TRUE];
            
            if(UnpaidPayitemMasterObj != NULL && UnpaidPayitemMasterObj.size()>0){
                createPayItemWithoutPLR(payoutIdSet, newMap, null, empIdSet);
            }
        }
    }
    
    //calculates loss for the month considering only work week and public holidays. Works for Maternity, NSMen and Other record type.
    public static void createPayItemWithoutPLR(Set<Id> payoutIdSet, Map<Id, Leave_Request__c> newMap, Date payoutProcessDate, Set<Id> empIdSet){
        Id nsMenRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('NSMen_Leave').getRecordTypeId();
        Id otherRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
        Id maternityRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
        
        Payitem_Master__c nsMenMasterObj, unpaidMasterObj;
        
        Set<Id> payitemMasterSet = new Set<Id>();
        Set<Id> setPayoutId = new Set<Id>();
        Set<Id> employeeIdSet = new Set<Id>();
        
        for(Payitem_Master__c payitemMaster: [SELECT Id, Name FROM Payitem_Master__c WHERE (Name = 'Unpaid Leave' OR Name = 'NS Make-up Pay') AND Active__c = TRUE]){
            if(payitemMaster.Name == 'NS Make-up Pay')
                nsMenMasterObj = payitemMaster;
            else
                unpaidMasterObj = payitemMaster;
            payitemMasterSet.add(payitemMaster.Id);
        }       
        system.debug('##payitemMasterSet'+payitemMasterSet);
        List<Payout__c> payoutList;
        
        if(empIdSet != NULL && empIdSet.size()>0)
            payoutList = [SELECT Id, Year__c, Month__c, Salary__c, Total_OW_Amount__c, Monthly_Working_Days__c, Employee_Name__c, Daily_Rate__c FROM Payout__c WHERE Employee_Name__c IN: empIdSet];
        else
            payoutList = [SELECT Id, Year__c, Month__c, Salary__c, Total_OW_Amount__c, Monthly_Working_Days__c, Employee_Name__c, Daily_Rate__c FROM Payout__c WHERE Id IN: payoutIdSet];
        
        system.debug('##payoutList'+payoutList);
        if(payoutList != NULL && payoutList.size() > 0){
            System.debug('IN');
            Map<Id, List<Payout__c>> mapEmpToPayoutObj = new Map<Id, List<Payout__c>>();
            Map<String, PayItem__c> mapPayoutToPayItem = new Map<String, PayItem__c>();
            Map<String, PayItem__c> mapPayoutToPayItemToInsert = new Map<String, PayItem__c>();
            Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
            Set<Id> orgIdSet = new Set<Id>();
            
            Date todayDate = system.today();
            if(payoutProcessDate != NULL)
                todayDate = payoutProcessDate;
            System.debug(todayDate);
            Date currMonthStartDate = todayDate.toStartOfMonth();
            Date currMonthEndDate = currMonthStartDate.addDays(date.daysInMonth(currMonthStartDate.year(), currMonthStartDate.month())-1);
            String currentMonth = numberToMonthMap.get(currMonthStartDate.month());
            String currentYear = currMonthStartDate.year()+'';
            
            for(Payout__c payoutObj: payoutList){ 
                List<Payout__c> payoutListTemp = new List<Payout__c>();
                if(mapEmpToPayoutObj.containsKey(payoutObj.Employee_Name__c)){
                    payoutListTemp = mapEmpToPayoutObj.get(payoutObj.Employee_Name__c);
                }
                payoutListTemp.add(payoutObj);
                mapEmpToPayoutObj.put(payoutObj.Employee_Name__c, payoutListTemp);
                employeeIdSet.add(payoutObj.Employee_Name__c);
                setPayoutId.add(payoutObj.Id);
            }
            system.debug('##setPayoutId'+setPayoutId);
            system.debug('##payitemMasterSet'+payitemMasterSet);
            //get existing PayItem records
            for(PayItem__c payitemObj: [SELECT Id, Payout__c, Amount__c, Notes__c, No_of_Days__c, Payitem__c, System_Generated__c, Type__c, Value__c
                                        FROM PayItem__c WHERE Payout__c IN: setPayoutId AND Payitem__c IN: payitemMasterSet]){
                mapPayoutToPayItem.put(payitemObj.Payout__c+'-'+payitemObj.Payitem__c, payitemObj);
            }
            
            Map<Leave_Request__c, PayItem__c> leaveRequestToPayItem = new Map<Leave_Request__c, PayItem__c>();
            List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
            
            if(newMap != NULL){
                leaveReqList = [SELECT Id, Name, Employee__c, Leave_Start_Date__c, Leave_End_Date__c, RecordTypeId, Paid_Week__c, Unpaid_Week__c, Employee__r.Employee_Duty_Type__c, Employee__r.Organisation__c FROM Leave_Request__c WHERE Id IN: newMap.KeySet()];
            }
            else{
                leaveReqList = [SELECT Id, Name, Employee__c, Leave_Start_Date__c, Leave_End_Date__c, RecordTypeId, Paid_Week__c, 
                                Unpaid_Week__c, Employee__r.Employee_Duty_Type__c, Employee__r.Organisation__c FROM Leave_Request__c
                                WHERE (Leave_End_Date__c >=: currMonthStartDate AND Leave_Start_Date__c <=: currMonthEndDate) 
                                AND (RecordTypeId =: nsMenRcTypeId OR RecordTypeId =: maternityRcTypeId OR RecordTypeId =: otherRcTypeId) 
                                AND Employee__c IN: employeeIdSet AND Status__c = 'Approved'];
            }
            system.debug('##leaveReqList'+leaveReqList);
            Map<Id, String> mapLeaveReqToPayoutPayItemMaster = new Map<Id, String>();
            Map<String, Payitem_Leave_Request__c> mapYearMonthToPLR = new Map<String, Payitem_Leave_Request__c>();
            Map<Id, List<Payitem_Leave_Request__c>> mapLeaveReqToPLR = new Map<Id, List<Payitem_Leave_Request__c>>();
            
            List<Payitem_Leave_Request__c> plrList = [SELECT Id, Leave_Request__c, Month__c, Year__c, Unpaid_Leaves__c,
                                                      Leave_Request__r.Employee__c, PayItem__c FROM Payitem_Leave_Request__c
                                                      WHERE Leave_Request__r.Employee__c IN: employeeIdSet AND PayItem__c = NULL];

            for(Payitem_Leave_Request__c plrObj: plrList){
                List<Payitem_Leave_Request__c> tempList = new List<Payitem_Leave_Request__c>();
                mapYearMonthToPLR.put(plrObj.Month__c+'-'+plrObj.Year__c+'-'+plrObj.Leave_Request__c, plrObj);
                if(mapLeaveReqToPLR.containsKey(plrObj.Leave_Request__c)){
                    tempList = mapLeaveReqToPLR.get(plrObj.Leave_Request__c);
                }
                tempList.add(plrObj);
                mapLeaveReqToPLR.put(plrObj.Leave_Request__c, tempList);
            }
            system.debug('##mapLeaveReqToPLR'+mapLeaveReqToPLR);
            system.debug('##leaveReqList'+leaveReqList);
            Set<String> validMonthYearLeaveReq = new Set<String>();
            if(!leaveReqList.isEmpty()){
                for(Leave_Request__c leaveReqObj: leaveReqList){
                    if(mapEmpToPayoutObj.containsKey(leaveReqObj.Employee__c)){
                        List<Payout__c> payoutObjList = mapEmpToPayoutObj.get(leaveReqObj.Employee__c);
                        
                        for(Payout__c payoutObj: payoutObjList){
                            Integer yearInt = Integer.valueOf(payoutObj.Year__c);
                            Integer monthInt = monthMap.get(payoutObj.Month__c);
                            Date payoutStartDate = Date.newInstance(yearInt, monthInt, 1);
                            Date payoutEndDate = payoutStartDate.addDays(date.daysInMonth(payoutStartDate.year(), payoutStartDate.month())-1);
                            
                            //if leave request is for this payout
                            if(leaveReqObj.Leave_End_Date__c >= payoutStartDate && leaveReqObj.Leave_Start_Date__c <= payoutEndDate){                                
                                validMonthYearLeaveReq.add(leaveReqObj.Id + '-' + payoutObj.Month__c + '-'+payoutObj.Year__c);
                                PayItem__c payItemObj;
                                if(mapYearMonthToPLR.containsKey(payoutObj.Month__c+'-'+ payoutObj.Year__c+'-'+leaveReqObj.Id)){
                                    Decimal noOfDays = mapYearMonthToPLR.get(payoutObj.Month__c+'-'+ payoutObj.Year__c+'-'+leaveReqObj.Id).Unpaid_Leaves__c;
                                    noOfDays = noOfDays != NULL? noOfDays : 0;
                                    
                                    Boolean flagForExistingPayItem = false;
                                    if(nsMenMasterObj != NULL && leaveReqObj.RecordTypeId == nsMenRcTypeId && mapPayoutToPayItem.containsKey(payoutObj.Id + '-'+ nsMenMasterObj.Id)){ //if there is already a PayItem for NS Men Make-Up Pay
                                        payItemObj = mapPayoutToPayItem.get(payoutObj.Id + '-'+ nsMenMasterObj.Id);
                                        flagForExistingPayItem = true;
                                    }
                                    else if(unpaidMasterObj != NULL && leaveReqObj.RecordTypeId != nsMenRcTypeId && mapPayoutToPayItem.containsKey(payoutObj.Id + '-'+ unpaidMasterObj.Id)){ //if there is already a PayItem for unpaid leave
                                        payItemObj = mapPayoutToPayItem.get(payoutObj.Id + '-'+ unpaidMasterObj.Id);
                                        flagForExistingPayItem = true;
                                    }
                                    if(flagForExistingPayItem){ //if PayItem record exists already
                                        payItemObj.Value__c+= noOfDays;
                                        payItemObj.Notes__c = payItemObj.Notes__c.removeEnd('.') + ', ' + leaveReqObj.Name + '.';
                                    }
                                    else{
                                        if(leaveReqObj.RecordTypeId == nsMenRcTypeId && nsMenMasterObj != NULL){
                                            payItemObj = new PayItem__c(Payitem__c = nsMenMasterObj.Id, Payout__c = payoutObj.Id);
                                        }
                                        else if(leaveReqObj.RecordTypeId != nsMenRcTypeId && unpaidMasterObj != NULL){
                                            payItemObj = new PayItem__c(Payitem__c = unpaidMasterObj.Id, Payout__c = payoutObj.Id);
                                        }
                                        payItemObj.Value__c = noOfDays;
                                        payItemObj.Notes__c = 'Calculated on the basis of '+ leaveReqObj.Name + '.';
                                    }
                                    if(payItemObj != NULL){
                                        payItemObj.Type__c = 'Days';
                                        payItemObj.System_Generated__c = TRUE;
                                        mapPayoutToPayItem.put(payoutObj.Id + '-'+ payItemObj.Payitem__c, payItemObj);
                                        mapPayoutToPayItemToInsert.put(payoutObj.Id + '-'+ payItemObj.Payitem__c, payItemObj);
                                        mapLeaveReqToPayoutPayItemMaster.put(leaveReqObj.Id, payoutObj.Id+'-'+payItemObj.Payitem__c);
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
             system.debug('##validMonthYearLeaveReq'+validMonthYearLeaveReq);
             system.debug('##mapPayoutToPayItemToInsert'+mapPayoutToPayItemToInsert);
            system.debug('##plrList'+plrList);
            if(!mapPayoutToPayItemToInsert.isEmpty()){
                upsert mapPayoutToPayItemToInsert.values();
                
                for(Payitem_Leave_Request__c plrObj: plrList){
                    if(mapLeaveReqToPayoutPayItemMaster.containsKey(plrObj.Leave_Request__c)){
                        if(mapPayoutToPayItemToInsert.containsKey(mapLeaveReqToPayoutPayItemMaster.get(plrObj.Leave_Request__c))){
                            if(validMonthYearLeaveReq.contains(plrObj.Leave_Request__c + '-' + plrObj.Month__c + '-' + plrObj.Year__c))
                                plrObj.PayItem__c = mapPayoutToPayItemToInsert.get(mapLeaveReqToPayoutPayItemMaster.get(plrObj.Leave_Request__c)).Id;
                        }
                    }
                }
                system.debug('##plrList'+plrList);
                if(!plrList.isEmpty()){
                    update plrList;
                }
            }
        }
    }
    
    //returns public holidays mapped to organisation name
    private static Map<Id, Set<Public_Holiday__c>> getPublicHolidaysWithOrg(Set<Id> orgIdSet){
        Map<Id, Set<Public_Holiday__c>> mapOrgToPublicHolidays = new Map<Id, Set<Public_Holiday__c>>();
        
        for(Public_Holiday__c publicHoliday: [SELECT Id, Public_Holiday_Date__c, Organisation__c, Organisation_Status__c FROM Public_Holiday__c WHERE Organisation__c IN: orgIdSet ORDER BY Public_Holiday_Date__c ASC]){
            Set<Public_Holiday__c> publicHolidaySet = new Set<Public_Holiday__c>();
            
            if(mapOrgToPublicHolidays.containsKey(publicHoliday.Organisation__c)){
                publicHolidaySet = mapOrgToPublicHolidays.get(publicHoliday.Organisation__c);
            }
            publicHolidaySet.add(publicHoliday);
            mapOrgToPublicHolidays.put(publicHoliday.Organisation__c, publicHolidaySet);
        }
        
        return mapOrgToPublicHolidays;
    }
    
    //creates Leave Entitlements for Account(insert/update) when Employee Status is 'Probation' or 'Confirm'. Called from AccountTrigger.
    public static void createEntitlementsForAccount(List<Account> accList, String action){
        System.debug(action);
        List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
        List<Leave_Entitlement__c> leaveEntToInsertList = new List<Leave_Entitlement__c>();
        
        for(Account acc: accList){
            Date startDate = acc.Joining_Date__c;
            
            for(Integer i=0; i<3; i++){
                Leave_Entitlement__c leaveEntObj = new Leave_Entitlement__c();
                leaveEntObj.Start_Date__c = startDate;
                leaveEntObj.End_Date__c = startDate.addYears(1).addDays(-1);
                
                if(i == 0 && acc.Job_Title__c == 'Teacher'){
                    leaveEntObj.Paid_Leave__c = 7;
                }
                else{
                    leaveEntObj.Paid_Leave__c = 14;
                }
                leaveEntObj.Employee__c = acc.id;
                leaveEntObj.Sick_Leave__c = 14;
                
                System.debug(startDate.daysBetween(leaveEntObj.End_Date__c));
                
                startDate = leaveEntObj.End_Date__c.addDays(1);
                leaveEntList.add(leaveEntObj);
            }
        }
        
        if(!leaveEntList.isEmpty()){
            System.debug('**');
            if(action == 'update'){
                System.debug('update');
                List<Leave_Entitlement__c> existingLeaveEntitlementList = [SELECT Id, Employee__c, Start_Date__c, End_Date__c FROM Leave_Entitlement__c WHERE Employee__c IN: accList];
                Map<Id, List<Leave_Entitlement__c>> mapEmployeeToExistingEntitlementList = new Map<Id, List<Leave_Entitlement__c>>();
                
                if(existingLeaveEntitlementList != NULL){
                    for(Leave_Entitlement__c existingLeaveEntitlementObj: existingLeaveEntitlementList){
                        List<Leave_Entitlement__c> leaveEmploymentList = new List<Leave_Entitlement__c>();
                        
                        if(mapEmployeeToExistingEntitlementList.containsKey(existingLeaveEntitlementObj.Employee__c)){
                            leaveEmploymentList = mapEmployeeToExistingEntitlementList.get(existingLeaveEntitlementObj.Employee__c);
                        }
                        leaveEmploymentList.add(existingLeaveEntitlementObj);
                        mapEmployeeToExistingEntitlementList.put(existingLeaveEntitlementObj.Employee__c, leaveEmploymentList);
                    }
                }
                
                //if Leave Entitlement records exists for the Employee record, then validate the dates
                if(!mapEmployeeToExistingEntitlementList.isEmpty()){
                    Boolean conflictingDateFound = false;
                    for(Leave_Entitlement__c newLeaveEntitlementObj: leaveEntList){
                        List<Leave_Entitlement__c> leaveEmploymentList;
                        if(mapEmployeeToExistingEntitlementList.containsKey(newLeaveEntitlementObj.Employee__c)){
                            leaveEmploymentList = mapEmployeeToExistingEntitlementList.get(newLeaveEntitlementObj.Employee__c);
                        }
                        
                        conflictingDateFound = false;
                        if(leaveEmploymentList != NULL){
                            for(Leave_Entitlement__c existingEntitlementObj: leaveEmploymentList){
                                if(newLeaveEntitlementObj.Start_Date__c < existingEntitlementObj.Start_Date__c && !(newLeaveEntitlementObj.End_Date__c < existingEntitlementObj.Start_Date__c)){
                                    conflictingDateFound = true;
                                }
                                
                                if(!conflictingDateFound && (newLeaveEntitlementObj.Start_Date__c >= existingEntitlementObj.Start_Date__c && newLeaveEntitlementObj.Start_Date__c <= existingEntitlementObj.End_Date__c) || 
                                (newLeaveEntitlementObj.End_Date__c >= existingEntitlementObj.Start_Date__c && newLeaveEntitlementObj.End_Date__c <= existingEntitlementObj.End_Date__c)){
                                    conflictingDateFound = true;
                                }
                            }
                            
                            if(!conflictingDateFound)
                                leaveEntToInsertList.add(newLeaveEntitlementObj);
                        }
                    }
                }
                else{
                    leaveEntToInsertList.addAll(leaveEntList);
                }
                System.debug(leaveEntToInsertList);
                if(!leaveEntToInsertList.isEmpty())
                    insert leaveEntToInsertList;
            }
            else if(action == 'insert'){
                System.debug('insert'+ leaveEntList);
                if(!leaveEntList.isEmpty())
                    insert leaveEntList;
            }
        }
    }
    
    //updates Reporting Managers on Leave Request record if any of them is updated in Account. Called from AccountTrigger.
    public static void updateReportingManager(Map<Id, Id> mapAccToRMId, Map<Id, Id> mapAccToRMId2){
        List<Leave_Request__c> leaveReqList = [SELECT Id, Reporting_Manager__c, Employee__c FROM Leave_Request__c WHERE (Employee__c IN: mapAccToRMId.KeySet() OR Employee__c IN: mapAccToRMId2.KeySet())];
        Id HRUserId;
        
        List<User> userList = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'HR Manager' LIMIT 1];
        if(userList != null && userList.size()==1){
            HRUserId = userList[0].Id;
        }
        
        if(leaveReqList != NULL && leaveReqList.size()>0){
            for(Leave_Request__c leaveReq: leaveReqList){
                if(!mapAccToRMId.isEmpty() && mapAccToRMId.containsKey(leaveReq.Employee__c)){
                    if(mapAccToRMId.get(leaveReq.Employee__c) != NULL)
                        leaveReq.Reporting_Manager__c = mapAccToRMId.get(leaveReq.Employee__c);
                    else
                        leaveReq.Reporting_Manager__c = HRUserId != NULL? HRUserId: NULL;
                }
                else if(!mapAccToRMId2.isEmpty() && mapAccToRMId2.containsKey(leaveReq.Employee__c)){
                    if(mapAccToRMId2.get(leaveReq.Employee__c) != NULL)
                        leaveReq.Reporting_Manager_2__c = mapAccToRMId2.get(leaveReq.Employee__c);
                    else
                        leaveReq.Reporting_Manager_2__c = null;
                }
            }
            
            update leaveReqList;
        }
    }
    
    //creates PLR records for Maternity, Other and NSMen leave request
    public static void createPayItemLeaveRequestRecord(List<Leave_Request__c> leaveRequestList, Map<Id, Leave_Request__c> newMap){
        System.debug(leaveRequestList);
        Id maternityRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
        Set<Id> empIdSet = new Set<Id>();
        Map<Id, List<Employee_Work_Week__c>> empToworkWeekList = new Map<Id, List<Employee_Work_Week__c>>();
        List<Payitem_Leave_Request__c> plrList = new List<Payitem_Leave_Request__c>();
        Map<Id,Set<Public_Holiday__c>> mapOrgToHolidays = new Map<Id,Set<Public_Holiday__c>>();
        Set<Id> orgIdSet = new Set<Id>();
        
        for(Leave_Request__c leaveRequestObj: leaveRequestList){
            if(leaveRequestObj.Employee__c != NULL)
                empIdSet.add(leaveRequestObj.Employee__c);
        }
        
        if(!empIdSet.isEmpty()){
            for(Employee_Work_Week__c workWeek: [SELECT Id, Friday__c, Effective_Date__c, Monday__c, Saturday__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Working_Days_in_a_Week__c, Employee__c, Employee__r.Organisation__c, Employee__r.Employee_Duty_Type__c, Employee__r.Joining_Date__c FROM Employee_Work_Week__c WHERE Employee__c IN: empIdSet ORDER BY Effective_Date__c ASC]){
                List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
                
                if(empToworkWeekList.containsKey(workWeek.Employee__c)){
                    workWeekList = empToworkWeekList.get(workWeek.Employee__c);
                }
                workWeekList.add(workWeek);
                empToworkWeekList.put(workWeek.Employee__c, workWeekList);
            }
            
            if(!orgIdSet.isEmpty())
                mapOrgToHolidays = getPublicHolidaysWithOrg(orgIdSet);
                
            Map<String, Decimal> mapMonthYearToUnpaidLeave = new Map<String, Decimal>();
            
            for(Leave_Request__c leaveReqObj: leaveRequestList){
                Date startDate = leaveReqObj.Leave_Start_Date__c;
                Date endDate = leaveReqObj.Leave_End_Date__c; 
                Decimal unpaidLeave = 0;
                
                if(leaveReqObj.RecordTypeId == maternityRcTypeId){
                    if(leaveReqObj.Unpaid_Week__c != NULL)
                        startDate = leaveReqObj.Paid_Week__c != NULL? startDate.addDays(Integer.valueOf(leaveReqObj.Paid_Week__c) * 7)+1: startDate;
                    else
                        continue;
                }
                       
                //if workweek exists for the employee - valid employee
                if(empToworkWeekList.containsKey(leaveReqObj.Employee__c) && empToworkWeekList.get(leaveReqObj.Employee__c) != NULL){
                    Employee_Work_Week__c tempWW = empToworkWeekList.get(leaveReqObj.Employee__c)[0];
                    
                    //if employee applies for leave within first three months of joining
                    if(tempWW.Employee__r.Joining_Date__c != NULL && leaveReqObj.Leave_Start_Date__c <= tempWW.Employee__r.Joining_Date__c.addMonths(3)){
                        System.debug('called from joining date'+ mapMonthYearToUnpaidLeave);
                        mapMonthYearToUnpaidLeave = getUnpaidLeaveMapWithoutWorkweek(leaveReqObj.Leave_Start_Date__c, leaveReqObj.Leave_End_Date__c, mapMonthYearToUnpaidLeave, leaveReqObj.Employee__c);
                        continue;
                    }
                
                    Decimal totalLeaveThisMonth = 0;
                    Set<Public_Holiday__c> publicHolidaySet;
                    if(mapOrgToHolidays.containsKey(tempWW.Employee__r.Organisation__c) && mapOrgToHolidays.get(tempWW.Employee__r.Organisation__c) != NULL){
                        publicHolidaySet = mapOrgToHolidays.get(tempWW.Employee__r.Organisation__c);
                    }
                    
                    if(startDate.month() != endDate.month()){ 
                        while(startDate <= endDate){
                            unpaidLeave = 0;
                            Date monthStartDate, monthEndDate;
                            Date endDateForCalc, startDateForCalc;
                            monthStartDate = startDate.toStartOfMonth(); 
                            monthEndDate = monthStartDate.addDays(date.daysInMonth(monthStartDate.year(), monthStartDate.month())-1);
                            
                            startDateForCalc = monthStartDate;
                            endDateForCalc = monthEndDate;
                            
                            if(startDate >= monthStartDate){
                                startDateForCalc = startDate; 
                            }
                            if(monthEndDate >= endDate){ 
                                endDateForCalc = endDate; 
                            }
                            
                            totalLeaveThisMonth = calculateWorkingDays(startDateForCalc, endDateForCalc, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, tempWW.Employee__r.Employee_Duty_Type__c, false);
                            System.debug(totalLeaveThisMonth);
                            
                            if(mapMonthYearToUnpaidLeave.containsKey(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year())){
                                unpaidLeave = mapMonthYearToUnpaidLeave.get(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year());
                            }
                            else{
                                unpaidLeave = totalLeaveThisMonth;
                            }
                            System.debug(unpaidLeave);
                            mapMonthYearToUnpaidLeave.put(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year(), unpaidLeave);
                            System.debug(mapMonthYearToUnpaidLeave);
                            startDate = monthEndDate.addDays(1);
                        }
                    }
                    else{ //if in same month
                        Date monthStartDate, monthEndDate;
                        monthStartDate = startDate.toStartOfMonth(); 
                        monthEndDate = monthStartDate.addDays(date.daysInMonth(monthStartDate.year(), monthStartDate.month())-1);
                        System.debug(startDate+ ' ' +endDate);
                        totalLeaveThisMonth = calculateWorkingDays(startDate, endDate, empToworkWeekList.get(leaveReqObj.Employee__c), publicHolidaySet, tempWW.Employee__r.Employee_Duty_Type__c, false);
                        System.debug(totalLeaveThisMonth);
                        mapMonthYearToUnpaidLeave.put(leaveReqObj.Employee__c + '-'+ monthStartDate.month() +'-'+ monthStartDate.year(), totalLeaveThisMonth);
                    }
                }
                else{
                    //if no work week is created for the employee
                    System.debug('called from no work week');
                    mapMonthYearToUnpaidLeave = getUnpaidLeaveMapWithoutWorkweek(leaveReqObj.Leave_Start_Date__c, leaveReqObj.Leave_End_Date__c, mapMonthYearToUnpaidLeave, leaveReqObj.Employee__c);
                }
            }
            
            for(Leave_Request__c leaveReqObj: leaveRequestList){
                for(String empMonthYear: mapMonthYearToUnpaidLeave.KeySet()){
                    Id empId = empMonthYear.split('-')[0];
                    Integer month = Integer.valueOf(empMonthYear.split('-')[1]);
                    String year = empMonthYear.split('-')[2];
                    
                    if(mapMonthYearToUnpaidLeave.get(empMonthYear) != 0){
                        Payitem_Leave_Request__c plrObj = new Payitem_Leave_Request__c(Leave_Request__c = leaveReqObj.Id, Month__c = numberToMonthMap.get(month), Year__c = year, Unpaid_Leaves__c = mapMonthYearToUnpaidLeave.get(empMonthYear));
                        plrList.add(plrObj);
                    }
                }
            }
            
            System.debug(plrList);
            
            if(!plrList.isEmpty()){
                insert plrList;
            }
        }
    }
    
    //creates task when user keys in/update probation end date
    public static void createTaskToTakeActionForProbation(List<Account> accList){
        List<Task> taskList = new List<Task>();   
        List<User> userList = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'HR Manager' LIMIT 1];
        
        if(userList != NULL && userList.size()>0){
            for(Account acc: accList){
                Task tsk = new Task();
                tsk.Subject = 'Probation ends for ' + acc.Name + ' on ' + acc.Probation_End_Date__c.format();
                tsk.Status = 'Open';
                tsk.Priority = 'Normal';
                tsk.WhatId = acc.Id;
                tsk.OwnerId = userList[0].Id;
                //tsk.OwnerId = '0050k000002PZGz';
                tsk.ActivityDate = acc.Probation_End_Date__c;
                taskList.add(tsk);
            }
            
            if(!taskList.isEmpty()){
                insert taskList;
            }
        }
    }
}