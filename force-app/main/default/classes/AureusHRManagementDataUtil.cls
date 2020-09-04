/*
    Name : AureusHRManagementDataUtil
    Date : 24 September 2019
    Description: Creates data for AureusHRManagementUtilTest test class.
    Author :
*/

public class AureusHRManagementDataUtil{
    public static Id createOrganisation(){
        Organisation__c org = new Organisation__c(Name = 'Test Org');
        insert org;
        return org.Id;
    }
    
    public static List<Account> createAccounts(Integer count){
        Account accMainCentre = new Account(LastName='Main Centre Test');
        insert accMainCentre;
        
        Id empRcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Teacher').getRecordTypeId();
        List<Account> accList = new List<Account>();
        
        for(Integer i = 0; i<count; i++){
            Account acc = new Account(LastName = 'Test', RecordTypeId = empRcTypeId, Main_Centre__c = accMainCentre.Id, Gender__c = 'Female');
            accList.add(acc);
        }
        
        insert accList;
        return accList;
    }
    
    public static List<Leave_Entitlement__c> getLeaveEntitlement(Integer count, Id accId){
        List<Leave_Entitlement__c> leaveEntList = new List<Leave_Entitlement__c>();
        
        for(Integer i = 0; i<count; i++){
            Leave_Entitlement__c leaveEnt = new Leave_Entitlement__c(Employee__c = accId);
            leaveEntList.add(leaveEnt);
        }
        
        return leaveEntList;
    }
    
    public static List<Leave_Request__c> getOtherLeaveRequests(Integer count, Id accId){
        Id otherRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        for(Integer i = 0; i<count; i++){
            Leave_Request__c leaveReq = new Leave_Request__c(RecordTypeId = otherRcTypeId, Employee__c = accId);
            leaveReqList.add(leaveReq);
        }
        
        return leaveReqList;
    }
    
    public static List<Leave_Request__c> getPaidLeaveRequests(Integer count, Id accId){
        Id paidLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Paid_Leave').getRecordTypeId();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        for(Integer i = 0; i<count; i++){
            Leave_Request__c leaveReq = new Leave_Request__c(RecordTypeId = paidLeaveRcTypeId, Employee__c = accId);
            leaveReqList.add(leaveReq);
        }
        
        return leaveReqList;
    }
    
    public static List<Leave_Request__c> getSickLeaveRequests(Integer count, Id accId){
        Id sickLeaveRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        for(Integer i = 0; i<count; i++){
            Leave_Request__c leaveReq = new Leave_Request__c(RecordTypeId = sickLeaveRcTypeId, Employee__c = accId);
            leaveReqList.add(leaveReq);
        }
        
        return leaveReqList;
    }
    
    public static List<Leave_Request__c> getNsMenLeaveRequests(Integer count, Id accId){
        Id nsMenRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('NSMen_Leave').getRecordTypeId();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        for(Integer i = 0; i<count; i++){
            Leave_Request__c leaveReq = new Leave_Request__c(RecordTypeId = nsMenRcTypeId, Employee__c = accId);
            leaveReqList.add(leaveReq);
        }
        
        return leaveReqList;
    }
    
    public static List<Leave_Request__c> getMaternityLeaveRequests(Integer count, Id accId){
        Id maternityRcTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Maternity_Leave').getRecordTypeId();
        List<Leave_Request__c> leaveReqList = new List<Leave_Request__c>();
        
        for(Integer i = 0; i<count; i++){
            Leave_Request__c leaveReq = new Leave_Request__c(RecordTypeId = maternityRcTypeId, Employee__c = accId);
            leaveReqList.add(leaveReq);
        }
        
        return leaveReqList;
    }
    
    public static Public_Holiday__c getPublicHoliday(Id orgId){
        Public_Holiday__c publicHoliday = new Public_Holiday__c(Name = 'PH', Organisation__c = orgId);
        
        return publicHoliday;
    }
    
    public static List<Employee_Work_Week__c> getEmployeeWorkWeek(Integer count, Id accId){
        List<Employee_Work_Week__c> empWorkWeekList = new List<Employee_Work_Week__c>();
        
        for(Integer i = 0; i<count; i++){
            Employee_Work_Week__c empWorkWeek = new Employee_Work_Week__c(Employee__c = accId);
            empWorkWeek.Monday__c = 'Full Day';
            empWorkWeek.Tuesday__c = 'Full Day';
            empWorkWeek.Wednesday__c = 'Full Day';
            empWorkWeek.Thursday__c = 'Full Day';
            empWorkWeek.Friday__c = 'Half Day';
            empWorkWeek.Saturday__c = 'Rest Day';
            empWorkWeek.Sunday__c = 'Rest Day';
            
            empWorkWeekList.add(empWorkWeek);
        }
        
        return empWorkWeekList;
    }
    
    public static Payroll_Batch__c getPayrollBatch(Id orgId){
        Payroll_Batch__c payBatch = new Payroll_Batch__c(
            Month__c = DateTime.Now().format('MMMMM'),
            Organisation__c = orgId,
            Year__c = DateTime.Now().format('yyyy')
        );
        insert payBatch;
        return payBatch;
    }
    
    public static void insertPayoutForThisMonth(Id accId){
        Date currentDate = System.today();
        Datetime dtm = (datetime) currentDate;
        String strCurrMonth = dtm.format('MMMM');
        Integer currYear = currentDate.Year();
        
        Payout__c payout = new Payout__c();
        payout.Month__c = strCurrMonth;
        payout.Year__c = ''+currYear+'';
        payout.Employee_Name__c = accId;
        insert payout;
    }
    
    public static void createPayItemMasterUnpaidLeave(){
        Payitem_Master__c pm = new Payitem_Master__c(Name = 'Unpaid Leave', Active__c = TRUE);
        insert pm;
    }
    
    public static void createPayItemMasterNSMen(){
        Payitem_Master__c pm = new Payitem_Master__c(Name = 'NS Make-up Pay', Active__c = TRUE);
        insert pm;
    }
}