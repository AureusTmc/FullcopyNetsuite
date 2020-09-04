/*
    Name : AureusHRManagementUtilTest
    Date : 23 September 2019
    Author :
    Description: 
*/

@isTest
public class AureusHRManagementUtilTest{
    //validates Leave Entitlement Date Conflict
    public static testMethod void validateLeaveEntDateConflict(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        List<Leave_Entitlement__c> leaveEntList = AureusHRManagementDataUtil.getLeaveEntitlement(2, acc.Id);
        
        leaveEntList[0].Start_Date__c = System.today().addMonths(1);
        leaveEntList[0].End_Date__c = System.today().addMonths(3);
        insert leaveEntList;
        
        try{
            List<Leave_Entitlement__c> overlappingLeaveEntList = AureusHRManagementDataUtil.getLeaveEntitlement(2, acc.Id);
            
            for(Leave_Entitlement__c leaveEnt: overlappingLeaveEntList){
                leaveEnt.Start_Date__c = System.today().addDays(1);
                leaveEnt.End_Date__c = System.today().addMonths(3);
            }
            
            leaveEntList[1].Start_Date__c = System.today().addMonths(2);
            leaveEntList[1].End_Date__c = System.today().addMonths(4);
            overlappingLeaveEntList.add(leaveEntList[1]);
            
            Database.Upsert(overlappingLeaveEntList);
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.DateConflictLeaveEntitlementError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
    
    //validates Carry Forward Leave populated in future Leave Entitlement
    public static testMethod void validateCarryForwardLeaveBatch(){
        List<Account> accList = AureusHRManagementDataUtil.createAccounts(2);
        List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
        
        for(Integer i=0; i<accList.size(); i++){
            List<Leave_Entitlement__c> leaveEntTempList = AureusHRManagementDataUtil.getLeaveEntitlement(2, accList[i].Id);
            
            for(Integer j = 0; j<leaveEntTempList.size(); j++){                
                if(j == 0){
                    leaveEntTempList[j].Start_Date__c = System.today().addMonths(-3);
                    leaveEntTempList[j].End_Date__c = System.today();
                    leaveEntTempList[j].Paid_Leave__c = 14;
                    leaveEntTempList[j].Used_Paid_Leaves__c = 7;
                    if(i==1){
                        leaveEntTempList[j].Carry_forward_Paid_Leave__c = 2;
                    }
                }
                else{
                    leaveEntTempList[j].Start_Date__c = System.today().addDays(1);
                    leaveEntTempList[j].End_Date__c = System.today().addMonths(3);
                }
            }
            leaveEntList.addAll(leaveEntTempList);
        }
        
        insert leaveEntList;
        
        Test.startTest();
        CarryForwardLeaveBatch batchObj = new CarryForwardLeaveBatch(null);
        Id batchId = Database.executeBatch(batchObj);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM Leave_Entitlement__c WHERE Carry_forward_Paid_Leave__c = 7].size());
        System.assertEquals(1, [SELECT Id FROM Leave_Entitlement__c WHERE Carry_forward_Paid_Leave__c = 9].size());
    }
    
    //tests scheduler for carry forward batch
    public static testMethod void testschedule(){
        Test.StartTest();
        CarryForwardLeaveBatchScheduler cfLeaveSch = new CarryForwardLeaveBatchScheduler();
        String sch = '0 0 23 * * ?';
        System.schedule('Test CarryForwardLeaveBatchScheduler', sch, cfLeaveSch);
        Test.stopTest();
    }
    
    //validates Leave Request Date Conflict
    public static testMethod void validateLeaveReqDateConflict(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        List<Leave_Request__c> leaveReqList = AureusHRManagementDataUtil.getSickLeaveRequests(2, acc.Id);
        
        for(Integer i=0; i<leaveReqList.size(); i++){
            if(i==1){
                leaveReqList[i].Leave_Start_Date__c = System.today().addMonths(1);
                leaveReqList[i].Leave_End_Date__c = System.today().addMonths(3);
            }
            else{
                leaveReqList[i].Leave_Start_Date__c = System.today();
                leaveReqList[i].Leave_End_Date__c = System.today();
            }
        }
        
        insert leaveReqList;
        
        try{
            List<Leave_Request__c> overlappingLeaveReqList = AureusHRManagementDataUtil.getSickLeaveRequests(2, acc.Id);
            
            for(Leave_Request__c leaveReq: overlappingLeaveReqList){
                leaveReq.Leave_Start_Date__c = System.today().addDays(1);
                leaveReq.Leave_End_Date__c = System.today().addMonths(3);
            }
            
            leaveReqList[1].Leave_Start_Date__c = System.today().addMonths(2);
            leaveReqList[1].Leave_End_Date__c = System.today().addMonths(4);
            overlappingLeaveReqList.add(leaveReqList[1]);
            
            Database.Upsert(overlappingLeaveReqList);
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.DateConflictLeaveRequestError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
    
    //validates Paid Leave Request balance
    public static testMethod void validatePaidLeaveBalance(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Employee_Work_Week__c empWW = AureusHRManagementDataUtil.getEmployeeWorkWeek(1, acc.Id)[0];
        empWW.Effective_Date__c = System.Today().addDays(-15);
        insert empWW;
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-1);
        leaveEnt.End_Date__c = System.today().addMonths(3);
        leaveEnt.Paid_Leave__c = 3;
        insert leaveEnt;      
        
        List<Leave_Request__c> paidLeaveReqList = AureusHRManagementDataUtil.getPaidLeaveRequests(2, acc.Id);
        for(Integer i=0; i<paidLeaveReqList.size(); i++){
            if(i==1){
                paidLeaveReqList[i].Leave_Start_Date__c = System.today().addMonths(2);
                paidLeaveReqList[i].Leave_End_Date__c = System.today().addMonths(2).addDays(4);
            }
            else{
                paidLeaveReqList[i].Leave_Start_Date__c = System.today().addMonths(2).addDays(5);
                paidLeaveReqList[i].Leave_End_Date__c = System.today().addMonths(2).addDays(6);
            }
        }
        
        try{
            Database.insert(paidLeaveReqList);
        }
        catch(Exception e){
            System.debug(e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.InsufficientLeaveBalanceError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
    
    //validates Used Paid Leave update
    public static testMethod void validateUsedPaidLeaveUpdate(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-1);
        leaveEnt.End_Date__c = System.today().addMonths(4);
        leaveEnt.Paid_Leave__c = 3;
        insert leaveEnt;  
        
        Employee_Work_Week__c empWW = AureusHRManagementDataUtil.getEmployeeWorkWeek(1, acc.Id)[0];
        empWW.Effective_Date__c = System.Today().addDays(-15);
        insert empWW;
        
        Leave_Request__c paidLeaveReq = AureusHRManagementDataUtil.getPaidLeaveRequests(1, acc.Id)[0];
        paidLeaveReq.Leave_Start_Date__c = System.today().addDays(34);
        paidLeaveReq.Leave_End_Date__c = System.today().addDays(35);
        insert paidLeaveReq;
        
        paidLeaveReq.Status__c = 'Approved';
        update paidLeaveReq;
        
        System.assertEquals(1, [SELECT Id FROM Leave_Entitlement__c WHERE Used_Paid_Leaves__c != 0].size());
    }
    
    //validates Used Sick Leave update
    public static testMethod void validateUsedSickLeaveUpdate(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-3);
        leaveEnt.End_Date__c = System.today().addMonths(3);
        leaveEnt.Sick_Leave__c = 3;
        insert leaveEnt;
        
        Employee_Work_Week__c empWW = AureusHRManagementDataUtil.getEmployeeWorkWeek(1, acc.Id)[0];
        empWW.Effective_Date__c = System.Today().addDays(-15);
        insert empWW;
        
        Leave_Request__c leaveReq = AureusHRManagementDataUtil.getSickLeaveRequests(1, acc.Id)[0];
        leaveReq.Leave_Start_Date__c = System.today().addDays(34);
        leaveReq.Leave_End_Date__c = System.today().addDays(35);
        insert leaveReq;
        
        leaveReq.Status__c = 'Approved';
        update leaveReq;
        
        System.assertEquals(1, [SELECT Id FROM Leave_Entitlement__c WHERE Used_Sick_Leaves__c != 0].size());
    }
    
    //validates leave entitlement creation for account
    public static testMethod void validateEntitlementCreation(){
        Id empRcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();        
        try{
            Account acc1 = new Account(LastName = 'Test1', Employee_Status__c = 'Probation', RecordTypeId = empRcTypeId);
            insert acc1;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.EmpStatusJoiningDateMandatory) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        try{
            Account acc2 = new Account(LastName = 'Test2', Employee_Status__c = 'Probation', RecordTypeId = empRcTypeId, Joining_Date__c = System.today(), Job_Title__c = 'Teacher');
            insert acc2;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.EmpStatusDutyTypeMandatory) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Account acc2 = new Account(LastName = 'Test2', Employee_Status__c = 'Probation', Employee_Duty_Type__c = 'Duty', RecordTypeId = empRcTypeId, Joining_Date__c = System.today(), Job_Title__c = 'Teacher');
        insert acc2;
        
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addDays(-15);
        leaveEnt.End_Date__c = System.today().addDays(-15).addYears(1);
        insert leaveEnt;
        
        acc.PersonBirthdate = System.today();
        try{
            acc.Employee_Status__c = 'Probation';
            update acc;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.EmpStatusJoiningDateMandatory) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        try{
            acc.Employee_Status__c = 'Probation';
            acc.Joining_Date__c = System.today().addDays(-15);
            update acc;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.EmpStatusDutyTypeMandatory) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }

        acc.Employee_Status__c = 'Probation';
        acc.Job_Title__c = 'Teacher';
        acc.Employee_Duty_Type__c = 'Duty';
        update acc;
        
        //System.assertEquals(6, [SELECT Id FROM Leave_Entitlement__c].size());
    }
    
    //validates Onboarding Stage errors
    public static testMethod void validateOnboardingStageError(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        acc.PersonBirthdate = System.today();
        try{
            acc.Onboarding_Stage__c = 'Completed';
            update acc;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.JoiningDateOnboardingProcessError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        try{
            acc.Joining_Date__c = System.today().addDays(-15);
            acc.Onboarding_Stage__c = 'Completed';
            update acc;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.EmployeeDutyTypeOnboardingProcessError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        try{
            acc.Joining_Date__c = System.today().addDays(-15);
            acc.Onboarding_Stage__c = 'Completed';
            acc.Employee_Duty_Type__c = 'Duty';
            update acc;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(label.ReportingManagerOnboardingProcessError) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
    
    //validates that all leaves be unpaid in case Sick Leave is rejected
    public static testMethod void validateRejectedSickLeave(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-1);
        leaveEnt.End_Date__c = System.today().addMonths(4);
        leaveEnt.Sick_Leave__c = 3;
        leaveEnt.Paid_Leave__c = 3;
        insert leaveEnt;
        
        List<Leave_Request__c> sickLeaveReqList = AureusHRManagementDataUtil.getSickLeaveRequests(1, acc.Id);
        
        sickLeaveReqList[0].Leave_Start_Date__c = System.today();
        sickLeaveReqList[0].Leave_End_Date__c = System.today();
        
        insert sickLeaveReqList;
        
        for(Leave_Request__c lr: sickLeaveReqList){
            lr.Status__c = 'Rejected';
        }
        update sickLeaveReqList;
        
        System.assertEquals(1, [SELECT Id FROM Leave_Request__c WHERE Unpaid_Leaves__c = 1].size());
    }
    
    //validates PayItem creation for Sick Leave
    public static testMethod void validatePayItemCreationSickLeave(){
        AureusHRManagementDataUtil.createPayItemMasterUnpaidLeave();
        
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];        
        AureusHRManagementDataUtil.insertPayoutForThisMonth(acc.Id);
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-1);
        leaveEnt.End_Date__c = System.today().addMonths(4);
        leaveEnt.Sick_Leave__c = 3;
        leaveEnt.Paid_Leave__c = 3;
        insert leaveEnt;
        
        List<Leave_Request__c> sickLeaveReqList = AureusHRManagementDataUtil.getSickLeaveRequests(2, acc.Id);
        
        for(Integer i=0; i< sickLeaveReqList.size(); i++){
            if(i==0){
                sickLeaveReqList[i].Leave_Start_Date__c = System.today();
                sickLeaveReqList[i].Leave_End_Date__c = System.today();
            }
            else{
                sickLeaveReqList[i].Leave_Start_Date__c = System.today();
                sickLeaveReqList[i].Leave_End_Date__c = System.today().addMonths(1);
            }
        }
        
        insert sickLeaveReqList;
        
        for(Leave_Request__c lr: sickLeaveReqList){
            lr.Status__c = 'Approved';
        }
        update sickLeaveReqList;
        
        String payoutId = [SELECT Id FROM Payout__c LIMIT 1].Id;
        //System.assertEquals(3, [SELECT Id FROM Payitem_Leave_Request__c].size());
        //System.assertEquals(1, [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId].size());
    }
    
    //validates PayItem creation for NsMen Leave
    public static testMethod void validatePayItemCreationNsMenLeave(){
        AureusHRManagementDataUtil.createPayItemMasterNSMen();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];        
        AureusHRManagementDataUtil.insertPayoutForThisMonth(acc.Id);
        
        Leave_Request__c nsMenLeaveReq = AureusHRManagementDataUtil.getNsMenLeaveRequests(1, acc.Id)[0];
        nsMenLeaveReq.Leave_Start_Date__c = System.today();
        nsMenLeaveReq.Leave_End_Date__c = System.today();
        leaveReqList.add(nsMenLeaveReq);
        insert leaveReqList;
        
        for(Leave_Request__c lr: leaveReqList){
            lr.Status__c = 'Approved';
        }
        update leaveReqList;
        String payoutId = [SELECT Id FROM Payout__c LIMIT 1].Id;
        
        System.assertEquals(1, [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId].size());
    }
    
    //validates PayItem creation for Maternity Leave
    public static testMethod void validatePayItemCreationMaternityLeave(){
        AureusHRManagementDataUtil.createPayItemMasterUnpaidLeave();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];        
        AureusHRManagementDataUtil.insertPayoutForThisMonth(acc.Id);
        String payoutId = [SELECT Id FROM Payout__c LIMIT 1].Id;
        
        Leave_Request__c maternityLeaveReq = AureusHRManagementDataUtil.getMaternityLeaveRequests(1, acc.Id)[0];
        maternityLeaveReq.No_of_Weeks__c = '4';
        maternityLeaveReq.Unpaid_Week__c = '4';
        maternityLeaveReq.Leave_Start_Date__c = System.today();
        leaveReqList.add(maternityLeaveReq);
        insert leaveReqList;
        
        System.assertEquals(1, [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId].size());
        
        List<PayItem__c> delPayItemList = [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId];
        
        if(delPayItemList != NULL && delPayItemList.size()>0){
            delete delPayItemList;
        }
        
        for(Leave_Request__c lr: leaveReqList){
            lr.Status__c = null;
        }
        update leaveReqList;
        
        for(Leave_Request__c lr: leaveReqList){
            lr.Status__c = 'Approved';
        }
        update leaveReqList;
        System.assertEquals(1, [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId].size());
    }
    
    //validates PayItem creation for Other Leave
    public static testMethod void validatePayItemCreationOtherLeave(){
        AureusHRManagementDataUtil.createPayItemMasterUnpaidLeave();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];        
        AureusHRManagementDataUtil.insertPayoutForThisMonth(acc.Id);
        String payoutId = [SELECT Id FROM Payout__c LIMIT 1].Id;
        
        Leave_Request__c otherLeaveReq = AureusHRManagementDataUtil.getOtherLeaveRequests(1, acc.Id)[0];
        otherLeaveReq.Type__c = 'Unpaid';
        otherLeaveReq.Leave_Start_Date__c = System.today();
        otherLeaveReq.Leave_End_Date__c = System.today();
        leaveReqList.add(otherLeaveReq);
        insert leaveReqList;
        
        System.assertEquals(1, [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId].size());
        
        List<PayItem__c> delPayItemList = [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId];
        
        if(delPayItemList != NULL && delPayItemList.size()>0){
            delete delPayItemList;
        }
        
        for(Leave_Request__c lr: leaveReqList){
            lr.Status__c = null;
        }
        update leaveReqList;
        
        for(Leave_Request__c lr: leaveReqList){
            lr.Status__c = 'Approved';
        }
        update leaveReqList;
        
        System.assertEquals(1, [SELECT Id FROM PayItem__c WHERE Payout__c =: payoutId].size());
    }
    
    //tests LeaveSummaryController
    public static testMethod void testLeaveSummaryController(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-1);
        leaveEnt.End_Date__c = System.today().addMonths(4);
        leaveEnt.Sick_Leave__c = 3;
        leaveEnt.Paid_Leave__c = 3;
        insert leaveEnt;
        
        LeaveSummaryController.getCurrentLeaveEntitlement(acc.Id);
        
        delete leaveEnt;
        LeaveSummaryController.getCurrentLeaveEntitlement(acc.Id);
    }
    
    //validates Maternity Leave - End Leave Calculation
    public static testMethod void validateMaternityLeave(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Request__c maternityLeaveReq = AureusHRManagementDataUtil.getMaternityLeaveRequests(1, acc.Id)[0];
        maternityLeaveReq.No_of_Weeks__c = '4';
        maternityLeaveReq.Unpaid_Week__c = '4';
        maternityLeaveReq.Leave_Start_Date__c = System.today();
        insert maternityLeaveReq;
        
        /*maternityLeaveReq.Status__c = 'Approved';
        maternityLeaveReq.Leave_Start_Date__c = System.today().addDays(1);
        maternityLeaveReq.Paid_Week__c = '4';
        maternityLeaveReq.Unpaid_Week__c = '4';
        maternityLeaveReq.No_of_Weeks__c = '8';
        update maternityLeaveReq;*/
    }
    
    //validates Paid Leave - End Leave Calculation
    public static testMethod void validatePaidLeave(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Entitlement__c leaveEnt = AureusHRManagementDataUtil.getLeaveEntitlement(1, acc.Id)[0];
        leaveEnt.Start_Date__c = System.today().addMonths(-1);
        leaveEnt.End_Date__c = System.today().addMonths(4);
        leaveEnt.Sick_Leave__c = 3;
        leaveEnt.Paid_Leave__c = 3;
        insert leaveEnt;
        
        Employee_Work_Week__c empWW = AureusHRManagementDataUtil.getEmployeeWorkWeek(1, acc.Id)[0];
        empWW.Effective_Date__c = System.Today().addDays(-15);
        insert empWW;
        
        Leave_Request__c paidLeaveReq = AureusHRManagementDataUtil.getPaidLeaveRequests(1, acc.Id)[0];
        paidLeaveReq.Leave_End_Date__c = System.today().addDays(35);
        paidLeaveReq.Leave_Start_Date__c = System.today().addDays(34);
        insert paidLeaveReq;
        /*
        paidLeaveReq.Leave_Start_Date__c = System.today().addDays(35);
        update paidLeaveReq;*/
    }
    //Sick Leave: calculates Loss of Income in case of Unpaid Leave Request.
    public static testmethod void calculateAndCreatePayItemForUnpaidLeave(){
        //create account records
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        //Insert acc;
        set<Id> empIdset = new set<Id>{acc.id};
        Payitem_Master__c itemMasterObj = new Payitem_Master__c(name ='Unpaid Sick Leave', Active__c = true);
        insert itemMasterObj;
        Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Leave_Request__c sickLeave =new Leave_Request__c(RecordTypeId = sickLeaveRcTypeId, Employee__c = acc.id,Leave_Start_Date__c = System.today(),Leave_End_Date__c = System.today());
        INSERT sickLeave ;
        Map<Id,Leave_Request__c> leaveRequestMap = new Map<Id,Leave_Request__c>();
        leaveRequestMap.put(sickLeave.id,sickLeave); 
        Payout__c payoutObj = new Payout__c(Employee_Name__c = acc.Id,Month__c='June',Year__c='2019');
        insert payoutObj;
        Date processDate = system.today();
        Set<Id> payoutId = new Set<Id>{payoutObj.id};
        AureusHRManagementUtil.calcLossAndCreatePayItemForUnpaidLeave(payoutId,leaveRequestMap,processDate,empIdset);
    }
    
     
    //validates Reporting Manager gets updated on Leave Requests if updated on related Account
    public static testMethod void validateReportingManager(){
        Account acc = AureusHRManagementDataUtil.createAccounts(1)[0];
        
        Leave_Request__c maternityLeaveReq = AureusHRManagementDataUtil.getMaternityLeaveRequests(1, acc.Id)[0];
        maternityLeaveReq.No_of_Weeks__c = '4';
        maternityLeaveReq.Unpaid_Week__c = '4';
        maternityLeaveReq.Leave_Start_Date__c = System.today();
        insert maternityLeaveReq;
        
        Id HRUserId;
        List<User> userList = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'HR Manager' LIMIT 1];
        if(userList != null && userList.size()==1){
            HRUserId = userList[0].Id;
        }
        
        if(HRUserId != null){
            acc.Reporting_Manager__c = HRUserId;
            update acc;
            System.assertEquals(1, [SELECT Id FROM Leave_Request__c WHERE Reporting_Manager__c =: HRUserId].size());
        }
        
        acc.Reporting_Manager__c = null;
        update acc;
        
        if(HRUserId != NULL){
            System.assertEquals(1, [SELECT Id FROM Leave_Request__c WHERE Reporting_Manager__c =: HRUserId].size());
        }
        else{
            System.assertEquals(1, [SELECT Id FROM Leave_Request__c WHERE Reporting_Manager__c = null].size());
        }
    }
}