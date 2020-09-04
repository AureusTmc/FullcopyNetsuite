/*
Name        :        TeacherMc
Date        :        
Author      :        Ravi Gupta
Description :        It is the test class For Teacher Mc.
*/
@isTest
public class TeacherMcClassTest {

    public static TestMethod void getTeacherAccountTest(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        
        Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
        insert org;
        Account accObj=TestUtil.createAccount('Teacher', true, true);
        Account accCustObj=TestUtil.createAccount('Customer', true, true);
        Account accCentObj=TestUtil.createAccount('Centre', true, false);
        accCentObj.Country__c =cntry.Id;
        accCentObj.Organisation__c=org.Id;
        insert accCentObj;
        
       
        TeacherMcClass.getTeacherAccount(accObj.Id);
        
        TeacherMcClass.LeaveRequestClass leaveReqObj = new TeacherMcClass.LeaveRequestClass();
        leaveReqObj.Employee=accObj.Id;
       	leaveReqObj.Leave_Start_Date =system.today();
        leaveReqObj.Leave_End_Date=system.today().addDays(45);
        leaveReqObj.RecordTypeName='Teacher Mc';
        leaveReqObj.Remarks='Test';
        
        
        string leaveReq=JSON.Serialize(leaveReqObj);
        List<Booking__c> booklist = new List<Booking__c>();
        for(integer i=1;i<=2;i++){
            Booking__c objBook = new Booking__c();
            objBook.Teacher_Account__c=accObj.Id;
            objBook.Parent__c=accCustObj.Id;
            objBook.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
            objBook.Booking_Date__c=date.today().addDays(i);
            objBook.Type__c='Regular';
            objBook.Status__c='Pending';
            objBook.Start_Time__c=Time.newInstance(11,0,0,0);
            objBook.End_Time__c=Time.newInstance(12,0,0,0);
            booklist.add(objBook);  
        }
        	
        insert booklist;
        TeacherMcClass.SaveLeaveRequest(leaveReq,accObj.Id);
        
        Case casObj = new Case(Status='Closed',Type=booklist[0].Type__c,Origin='Email',Priority='Medium',Booking__c=booklist[0].Id,Leave_Start_Date__c=booklist[0].Booking_Date__c,Leave_End_Date__c=booklist[0].Booking_Date__c.addDays(1));
        insert casObj;
        Teacher_Working_Hour__c teachObj= new Teacher_Working_Hour__c();
        teachObj.Teacher_Name__c=accObj.Id;
        teachObj.Center_Name__c=accCentObj.Id;
        
        insert teachObj;
        TeacherMcClass.UpdateBooking(leaveReq,accObj.Id,'Teacher Holiday');
        TeacherMcClass.getrequestedBooking(leaveReq,accObj.Id);
        
    }

    public static TestMethod void getTeacherAccount2Test(){
        
        Account accObj=TestUtil.createAccount('Teacher', true, true);
        Account accCustObj=TestUtil.createAccount('Customer', true, true);
       
        TeacherMcClass.getTeacherAccount(accObj.Id);
        
        TeacherMcClass.LeaveRequestClass leaveReqObj = new TeacherMcClass.LeaveRequestClass();
        leaveReqObj.Employee=accObj.Id;
       	leaveReqObj.Leave_Start_Date =system.today();
        leaveReqObj.Leave_End_Date=system.today().addDays(45);
        leaveReqObj.RecordTypeName='Teacher Mc';
        leaveReqObj.Remarks='Test';
        
        
        string leaveReq=JSON.Serialize(leaveReqObj);
        List<Booking__c> booklist = new List<Booking__c>();
        for(integer i=1;i<=2;i++){
            Booking__c objBook = new Booking__c();
            objBook.Teacher_Account__c=accObj.Id;
            objBook.Parent__c=accCustObj.Id;
            objBook.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
            objBook.Booking_Date__c=date.today().addDays(i);
            objBook.Type__c='Make-up';
            objBook.Status__c='Canceled';
            objBook.Start_Time__c=Time.newInstance(11,0,0,0);
            objBook.End_Time__c=Time.newInstance(12,0,0,0);
            booklist.add(objBook);  
        }
        	
        insert booklist;
        TeacherMcClass.SaveLeaveRequest(leaveReq,accObj.Id);
        
        Case casObj = new Case(Status='Closed',Type=booklist[0].Type__c,Origin='Email',Priority='Medium',Booking__c=booklist[0].Id,Leave_Start_Date__c=booklist[0].Booking_Date__c,Leave_End_Date__c=booklist[0].Booking_Date__c.addDays(1));
        insert casObj;
        TeacherMcClass.UpdateBooking(leaveReq,accObj.Id,'Teacher Holiday');
        TeacherMcClass.getrequestedBooking(leaveReq,accObj.Id);
        TeacherMcClass.getReport();
        
    }
}