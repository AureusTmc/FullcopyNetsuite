/*
Name        :        TeacherLeaveReminderTest
Date        :        2 April 2019
Author      :        Ravi
Description :        It is the test class of TeacherLeaveReminderScheduler.
*/

@isTest
public class TeacherLeaveReminderTest {
    
    public static TestMethod Void invokeTaskScheduler(){
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Leave_Request__c leavObj = new Leave_Request__c();
        leavObj.Leave_Start_Date__c=system.today().addDays(7);
        leavObj.Leave_End_Date__c=system.today().addDays(8);
        leavObj.Employee__c=objtechr.Id;
        
        insert leavObj;
            
        
            teacherLeaveReminderScheduler objTaskSchd= new teacherLeaveReminderScheduler();
            objTaskSchd.execute(Null);
        
    }

}