// Added By Ravi (25th Oct 2019)....
@isTest
public class LeaveRequestTest {
    
    static TestMethod void invokeMethodOne(){
        Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
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
        /*
Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
insert org;*/
        
        // update 21 09 2020 @nishi jain 
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = cntry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        Account accObj=TestUtil.createAccount('Teacher', true, true);
        Account accCustObj=TestUtil.createAccount('Customer', true, true);
        Account accCentObj=TestUtil.createAccount('Centre', true, false);
        accCentObj.Country__c =cntry.Id;
        accCentObj.Organisation__c=organisationRecord.Id;
        insert accCentObj;
        
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
        Case casObj = new Case(Status='Closed',Type=booklist[0].Type__c,Origin='Automation',Priority='Medium',Booking__c=booklist[0].Id,Leave_Start_Date__c=booklist[0].Booking_Date__c,Leave_End_Date__c=booklist[0].Booking_Date__c.addDays(1));
        insert casObj;
        Teacher_Working_Hour__c teachObj= new Teacher_Working_Hour__c();
        teachObj.Teacher_Name__c=accObj.Id;
        teachObj.Center_Name__c=accCentObj.Id;
        
        insert teachObj;
        Leave_Request__c levObjReq= new Leave_request__c();
        levObjReq.Employee__c=accObj.Id;
        levObjReq.Calendar_Update_Process__c=false;
        levObjReq.Sick_leave_start_Time__c=Time.newInstance(00,00,00,00);
        levObjReq.Leave_Start_Date__c=system.today();
        levObjReq.Leave_End_Date__c=system.today().addDays(2);
        levObjReq.RecordTypeId=sickRecordTypeId;
        levObjReq.Status__c='Pending';
        
        insert levObjReq;
        
        //LeaveRequestScheduler objLeaveScheduler= new LeaveRequestScheduler();
        //objLeaveScheduler.execute(Null);
    }
    static TestMethod void invokeMethodTwo(){
        Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Id otherRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
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
        /*
Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
insert org;*/
        // update 21 09 2020 @nishi jain 
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = cntry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        Account accObj=TestUtil.createAccount('Teacher', true, true);
        
        Fifth_Lesson__c fifthLessonObj = new Fifth_Lesson__c();
        fifthLessonObj.Booking_Date__c=system.today().addDays(1);
        fifthLessonObj.IsActive__c=true;
        fifthLessonObj.Teacher_Account__c=accObj.Id;
        
        insert fifthLessonObj;
        
        
        Leave_Request__c levObjReq= new Leave_request__c();
        levObjReq.Employee__c=accObj.Id;
        levObjReq.Calendar_Update_Process__c=false;
        levObjReq.Sick_leave_start_Time__c=Time.newInstance(00,00,00,00);
        levObjReq.Leave_Start_Date__c=system.today().addDays(1);
        levObjReq.Leave_End_Date__c=system.today().addDays(2);
        levObjReq.RecordTypeId=otherRecordTypeId;
        levObjReq.Status__c='Approved';
        
        insert levObjReq;
        
        //LeaveRequestScheduler objLeaveScheduler= new LeaveRequestScheduler();
        // objLeaveScheduler.execute(Null);
    }
    
    static TestMethod void invokeMethodThree(){
        Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Id otherRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
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
        
        Fifth_Lesson__c fifthLessonObj = new Fifth_Lesson__c();
        fifthLessonObj.Booking_Date__c=system.today().addDays(1);
        fifthLessonObj.IsActive__c=true;
        fifthLessonObj.Teacher_Account__c=accObj.Id;
        
        insert fifthLessonObj;
        
        
        Leave_Request__c levObjReq= new Leave_request__c();
        levObjReq.Employee__c=accObj.Id;
        levObjReq.Calendar_Update_Process__c=false;
        levObjReq.Leave_Start_Date__c=system.today().addDays(1);
        levObjReq.Leave_End_Date__c=system.today().addDays(2);
        levObjReq.RecordTypeId=otherRecordTypeId;
        levObjReq.Status__c='Approved';
        
        insert levObjReq;
        
        //LeaveRequestScheduler objLeaveScheduler= new LeaveRequestScheduler();
        // objLeaveScheduler.execute(Null);
    }
    
    static TestMethod void invokeMethodScheduler(){
        Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Id otherRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
        Id nationalServiceRecord = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('NSMen_Leave').getRecordTypeId(); 
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
        /*
Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
insert org; */
        
        // update 21 09 2020 @nishi jain 
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = cntry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        
        Account accObj=TestUtil.createAccount('Teacher', true, true);
        Account accCentObj=TestUtil.createAccount('Centre', true, false);
        accCentObj.Country__c =cntry.Id;
        // update 21 09 2020 @nishi jain 
        accCentObj.Organisation__c=organisationRecord.Id;
        insert accCentObj;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,false);
        objtechr.Employee_Duty_Type__c='Non-Duty';
        // update 21 09 2020 @nishi jain 
        objtechr.Organisation__c=organisationRecord.Id;
        insert objtechr;
        Datetime dt = DateTime.newInstance(system.today().addDays(1), Time.newInstance(0, 0, 0, 0));
        String dayOfWeek=dt.format('E');
        Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
        tw.Active__c = true;
        tw.Break_Time__c=false;
        tw.Active__c=True;
        tw.Teacher_Name__c=accObj.id;
        tw.Center_Name__c=accCentObj.Id;
        tw.Working_Day__c=dayOfWeek;
        tw.Start_Time__c=Time.newInstance(7,0,0,0);
        tw.End_Time__c=Time.newInstance(23,0,0,0);
        
        insert tw;
        
        Leave_Request__c levObjReq= new Leave_request__c();
        levObjReq.Employee__c=accObj.Id;
        levObjReq.Calendar_Update_Process__c=false;
        levObjReq.Sick_leave_start_Time__c=Time.newInstance(00,00,00,00);
        levObjReq.Leave_Start_Date__c=system.today().addDays(1);
        levObjReq.Leave_End_Date__c=system.today().addDays(2);
        levObjReq.RecordTypeId=nationalServiceRecord;
        levObjReq.Status__c='Approved';
        
        insert levObjReq;
        system.debug('--->'+ levObjReq);
        
        LeaveRequestScheduler objLeaveScheduler= new LeaveRequestScheduler();
        objLeaveScheduler.execute(Null);
    }
    
    // added by nishi:  26-Sep-2020: for cover ossia regarding changes
    static TestMethod void testOssiachanges(){
        OssiaCenterCalendarControllerTestHelper.createCalenderData();
         List<Booking__c> listOfBooking = [SELECT Id,Type__c,Student__c,center__c,Teacher_Account__c,Package__c,Enrolment__c,Booking_Date__c,
                                          Available_Make_up_Units__c,end_Time__c,parent__c
                                          FROM Booking__c
                                         Where RecordType.name =:ConstantsClass.recordTypeLesson]; 
        test.startTest();
         List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today(),'Scheduled','Lesson','Trial',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().adddays(1),'Scheduled','Lesson','Make-up',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today(),'Scheduled','Lesson','Ad-hoc',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().adddays(1),'Scheduled','Lesson','Busy',false));
        listOfcreateBooking[0].Start_Time__c =Time.newInstance(10,00,00,00);
        listOfcreateBooking[1].Start_Time__c =Time.newInstance(10,00,00,00);
        listOfcreateBooking[2].Start_Time__c =Time.newInstance(10,00,00,00);
        listOfcreateBooking[3].Start_Time__c =Time.newInstance(10,00,00,00);
        insert listOfcreateBooking;
        
        List<account> listOfteacher = [select id from account where recordType.name='Teacher'];
        Id sickRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
        Id otherRecordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Other_Leave').getRecordTypeId();
        List<Leave_Request__c> levObjReqlist= new List<Leave_Request__c>();
       /* Leave_Request__c levObjReq= new Leave_request__c();
        levObjReq.Employee__c=listOfBooking[0].Teacher_Account__c;
        levObjReq.Calendar_Update_Process__c=false;
        levObjReq.Leave_Start_Date__c=system.today().addDays(1);
        levObjReq.Leave_End_Date__c=system.today().addDays(2);
        levObjReq.RecordTypeId=otherRecordTypeId;
        levObjReq.Status__c='Approved';
         insert levObjReq;
        */
        Leave_Request__c levObjReq= new Leave_request__c();
        levObjReq.Employee__c=listOfBooking[0].Teacher_Account__c;
        levObjReq.Calendar_Update_Process__c=false;
        levObjReq.Sick_leave_start_Time__c=Time.newInstance(11,00,00,00);
        levObjReq.Leave_Start_Date__c=system.today();
        levObjReq.Leave_End_Date__c=system.today().addDays(2);
        levObjReq.RecordTypeId=sickRecordTypeId;
        levObjReq.Status__c='Pending';
        levObjReqlist.add(levObjReq);
        insert levObjReq;
        test.stopTest();
    }
    
    
}