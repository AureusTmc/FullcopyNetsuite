@isTest
public class TeacherLeaveTest {

    public static TestMethod void invokeTestMethod(){
       
        Account accObj=TestUtil.createAccount('Teacher', true, true);
        Account accCustObj=TestUtil.createAccount('Customer', true, true);
        
        
       
        TeacherLeaveClass.getTeacherAccount(accObj.Id);
        
        TeacherLeaveClass.LeaveRequestClass leaveReqObj = new TeacherLeaveClass.LeaveRequestClass();
        leaveReqObj.Employee=accObj.Id;
        leaveReqObj.EmployeeId=accObj.Id;
       	leaveReqObj.Leave_Start_Date =system.today();
        leaveReqObj.SickLeaveTime='1:2:3:4';
        leaveReqObj.Leave_End_Date=system.today().addDays(45);
        leaveReqObj.RecordTypeName='Teacher Mc';
        leaveReqObj.Remarks='Test';
        
        
        string leaveReq=JSON.Serialize(leaveReqObj);
        
        TeacherLeaveClass.UpdateBooking(leaveReq,accObj.Id);
        
        
    }
}