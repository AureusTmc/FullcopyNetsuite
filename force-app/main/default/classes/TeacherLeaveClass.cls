public class TeacherLeaveClass {
	
    private static string Teacher = ConstantsClass.teacherRecTypeName; 
    private static string lesson = ConstantsClass.recordTypeLesson;
    @AuraEnabled
    public static list<Account> getTeacherAccount(string AccountId){
        Id TeacherRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Teacher).getRecordTypeId();
        Id EmployeeRecordType=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        
        list<Account> accList =[select Id,Name,RecordType.Name From Account Where Id=:AccountId and ( RecordTypeId =:TeacherRecordTypeId or RecordTypeId =:EmployeeRecordType ) ];
        if(accList.size()>0){
            return accList;
        } 
        return accList;
    }
    
    @AuraEnabled
    public static list<Report> getReport(){
        return [select Id,Name from Report where Name ='Teacher Bookings'];
        
    }
    
     @AuraEnabled
    public static string UpdateBooking(string recordObj, string recordId){
        string msg='Success';
        Try{
            // retrieved Sick leave record type from leave request 
            Id leaveTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByName().get('Sick Leave').getRecordTypeId();
            LeaveRequestClass reqObj = new LeaveRequestClass();
            reqObj = (LeaveRequestClass)JSON.deserialize(recordObj, LeaveRequestClass.class);
            system.debug('reqObj.SickLeaveTime'+ reqObj.SickLeaveTime);
            Time myTime= null;
            if(reqObj.SickLeaveTime !=''){
                myTime = Time.newInstance(integer.valueOf(reqObj.SickLeaveTime.split(':')[0]), integer.valueOf(reqObj.SickLeaveTime.split(':')[1]),integer.valueOf(reqObj.SickLeaveTime.split(':')[2]),00) ; 
            }   
            
           
            // Creating Leave request
            list<Leave_Request__c> leaveReqList = new list<Leave_Request__c>();
            Leave_Request__c leaveReqObj = new Leave_Request__c(Employee__c=reqObj.EmployeeId,Leave_Start_Date__c=reqObj.Leave_Start_Date,
                                                                Sick_leave_start_Time__c=myTime,Leave_End_Date__c=reqObj.Leave_End_Date,RecordTypeId=leaveTypeId,Remarks__c=reqObj.Remarks,Leave_Type__c='Teacher MC');
            leaveReqList.add(leaveReqObj);
            if(leaveReqList.size()>0){
                insert leaveReqList;
            }  
        }catch(Exception ex){
            msg =string.valueOf(ex.getMessage());
            system.debug('--->'+ex.getMessage() + '====>'+ ex.getLineNumber() +'msg'+ msg);
        }
        return msg;
    }
    public class LeaveRequestClass {
        
        @AuraEnabled
        public String Employee;
        @AuraEnabled
        public Date Leave_Start_Date;
        @AuraEnabled
        public Date Leave_End_Date;
        @AuraEnabled
        public string RecordTypeName;
        @AuraEnabled
        public String Remarks;
        @AuraEnabled
        public String SickLeaveTime;
        @AuraEnabled
        public string EmployeeId;
        
        public LeaveRequestClass(){
            
        }
    }
}