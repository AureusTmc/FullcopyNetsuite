@isTest
public class PianoRentalEditCalendarControllerTest {
    @testSetup
    public static void createData(){
        //Create Country Records
        Country__c objCountry = AureusCalendarControllerTestHelper.createCountryRecord ('Singapore','SGD',true);
        
        //updated by @nishi 17 sep 2020
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = objCountry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;  
        
        // Create 2 Centre  
        List<Account> ListCentre = new List<Account>();
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus Northpoint', objCountry.Id,FALSE));
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus AMK Hub', objCountry.Id,FALSE));
        //updated by @nishi 17 sep 2020
        ListCentre[0].Organisation__c = organisationRecord.id;
        ListCentre[0].Organisation_Sharing__c ='Aureus Academy Singapore';
        ListCentre[1].Organisation__c = organisationRecord.id;
        ListCentre[1].Organisation_Sharing__c ='Aureus Academy Singapore';
        Insert ListCentre; 
        
        //create  Centre_Users__c
        Centre_Users__c objCentre_Users = AureusCalendarControllerTestHelper.createCentreUsers(ListCentre[0].id,true);
        
        // Create Center Working Hours 
        list<Center_Working_Hours__c> listOfCenterWorkingHours= new list<Center_Working_Hours__c>();
        listOfCenterWorkingHours.AddAll(TestUtil.createCenter_Working_Hours(ListCentre[0].id, FALSE,7));
        listOfCenterWorkingHours.AddAll(TestUtil.createCenter_Working_Hours(ListCentre[1].id, FALSE,7));
        insert listOfCenterWorkingHours;
        
        // Create 3 employee 
        List<Account> ListOfTeacherAccount = new List<Account>();
        ListOfTeacherAccount.add(createAccount('Employee',false,False));
        ListOfTeacherAccount.add(createAccount('Employee',false,False));
        ListOfTeacherAccount.add(createAccount('Employee',false,False));
        Insert ListOfTeacherAccount;   
        
        // Create Teacher Working Hours 
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[0].id,ListCentre[0].Id,True,False,7));
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[1].id,ListCentre[1].Id,True,False,7));
        
        // Create Program 
        Program__c objProg=TestUtil.createProgram('Active','Piano',true);
        
        // Create Package 
        List<Package__c> listOfPackage =new List<Package__c>();
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30','Trial',False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'15','Trial',False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'45','Trial',False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'60','Trial',False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'15',ConstantsClass.pakageTypeMakeup,False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30',ConstantsClass.pakageTypeMakeup,False));
        listOfPackage[0].Package_Fee__c = 100;
        listOfPackage[0].Deposit_Fee__c = 100;
        listOfPackage[1].Package_Fee__c = 200;
        listOfPackage[2].Package_Fee__c = 300;
        listOfPackage[3].Package_Fee__c = 400;
        listOfPackage[1].Deposit_Fee__c = 200;
        listOfPackage[2].Deposit_Fee__c = 300;
        listOfPackage[3].Deposit_Fee__c = 400;
        insert listOfPackage;
        
        // Create Customer
        List<Account> listOfCustomerAccount = new List<Account> ();
        listOfCustomerAccount.add(TestUtil.createAccount('Customer',True,false));
        listOfCustomerAccount.add(TestUtil.createAccount('Customer',false,false));
        
        listOfCustomerAccount[0].Centre_Name__c = ListCentre[0].Id;
        listOfCustomerAccount[0].personEmail = 'test1@tmc.com';
        listOfCustomerAccount[0].Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        
        listOfCustomerAccount[1].Centre_Name__c = ListCentre[1].Id;
        listOfCustomerAccount[1].personEmail = 'test2@tmc.com';
        listOfCustomerAccount[1].Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT listOfCustomerAccount;
        
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[0].Id,listOfPackage[0].id,dt.format('EEEE'),'Piano Viewing Completed','Instrument',false));
        listOfEnrolment[0].RecordTypeId =Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get(ConstantsClass.enrollmentInstrumentRecTypeName).getRecordTypeId();
        insert listOfEnrolment;
        
        
    }
    public static Account createAccount(String recTypeName,Boolean alsoStudnt,Boolean isDML){
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        
        if(s!=null){
            objAcc.RecordTypeId =s; 
            objAcc.LastName='testTeacher';
            objAcc.Teacher_Bio__c='testbio';
            objAcc.CentreName_Cust__c='Aureus Eastpoint';
            objAcc.Status__c='Working';   
            objAcc.Job_Title__c = 'Sales Executive';
            // updated
            objAcc.Center_Email__c = 'rajesh@techmatrixconsulting.com';
            objAcc.Major_Instruments_Disciplines__c='Piano';
            objAcc.Minor_Instruments_Disciplines__c='Piano';
            // set values here
            if(isDml){
                insert objAcc;
            }
            
        }
        return objAcc;
    }
    
    public static testMethod void test1(){
        List<case> listOfcase = [select id  from case];
        List<Account> listOfCentre = [select id  from Account Where recordType.name='Centre'];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Employee'];
        test.startTest();
        PianoRentalEditCalendarController.getListOfEmployee(listOfCentre[0].id,new Set<String>{listOfTeacher[0].id});
        PianoRentalEditCalendarController.getCalendarAllEmployeeData(listOfCentre[0].id,listOfTeacher[0].id,new List<String>{string.valueOf(system.today()),
            string.valueOf(system.today().adddays(1))});
        PianoRentalEditCalendarController.getCalendarAllEmployeeData(listOfCentre[0].id,listOfTeacher[0].id,new List<String>{string.valueOf(system.today())});
        PianoRentalEditCalendarController.getCalendarAllEmployeeData(listOfCentre[0].id,'AllStaff',new List<String>{string.valueOf(system.today())});
        PianoRentalEditCalendarController.getCalendarAllEmployeeData(listOfCentre[0].id,'AllRosteredStaff',new List<String>{string.valueOf(system.today())});
        test.stopTest();
    }
}