@isTest
public class EmployeeRosteringBatchTest {
    @testSetup
    public static void createData(){
        string centerRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
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
        Account centre=TestUtil.createAccount('Centre',False,false);
        centre.Country__c =cntry.Id;
        centre.Organisation__c=org.Id;
        insert centre;
        
        
        string empRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Account employee = new Account(
            Main_Centre__c = centre.Id,
            RecordTypeId = empRecordType,
            LastName='testEmployee',
            Teacher_Bio__c='testbio',
            CentreName_Cust__c='testCenter',
            Status__c='Working',
            Employee_Status__c = 'Confirm',
            Joining_Date__c = Date.Today().addDays(-10),
            Last_Working_Date__c = Date.today().addDays(10),
            Issue_Date__c = Date.Today().addDays(-30),
            ID_Type__c = 'Permanent Resident',
            PersonBirthdate = date.today().addYears(-30),
            Tax_Number__c = 'G3107590X',
            Employee_Duty_Type__c = 'Duty',
            Organisation__c=org.Id
        );
        insert employee;  
        
        Leave_Entitlement__c le = new Leave_Entitlement__c(
            Employee__c = employee.Id,
            Start_Date__c = Date.Today().addMonths(-1),
            End_Date__c = Date.Today().addMonths(1)
        );
        insert le;
        
        Employee_Work_Week__c eww = new Employee_Work_Week__c(
            Effective_Date__c = Date.Today().addDays(3),
            Employee__c = employee.Id,
            Friday__c = 'Full Day',
            Monday__c = 'Full Day',
            Saturday__c = 'Half Day',
            Sunday__c = 'Rest Day',
            Thursday__c = 'Half Day',
            Tuesday__c = 'Full Day',
            Wednesday__c = 'Full Day'
        );
        eww.Friday_Centre__c = centre.id;
        eww.Monday_Centre__c = centre.id;
        eww.Saturday_Centre__c = centre.id;
        eww.Sunday_Centre__c = centre.id;
        eww.Thursday_Centre__c = centre.id;
        eww.Tuesday_Centre__c = centre.id;
        eww.Wednesday_Centre__c= centre.id;
        
        eww.Friday_Note__c = '9:00 to 10:00';
        eww.Monday_Note__c = '9:00 to 10:00';
        eww.Saturday_Note__c = '9:00 to 10:00';
        eww.Sunday_Note__c = '9:00 to 10:00';
        eww.Thursday_Note__c = '9:00 to 10:00';
        eww.Tuesday_Note__c = '9:00 to 10:00';
        eww.Wednesday_Note__c = '9:00 to 10:00';
        
        eww.Friday_Shift__c = 'Regular Hours';
        eww.Monday_Shift__c = 'Regular Hours';
        eww.Saturday_Shift__c = 'Closing Hours';
        eww.Sunday_Shift__c = 'Regular Hours';
        eww.Thursday_Shift__c = 'Regular Hours';
        eww.Tuesday_Shift__c = 'Opening Hours';
        eww.Wednesday_Shift__c = 'Regular Hours';
        insert eww;
    }
    @isTest
    public static void unitTest1(){
        Test.startTest();
        Id jobId = Database.executeBatch(new EmployeeRosteringBatch(), 200);
        Test.StopTest();
    }
    @isTest
    public static void unitTest2(){
        Test.startTest();
        Id jobId = Database.executeBatch(new EmployeeRosteringBatch(1), 200);
        Test.StopTest();
    }
    @isTest
    public static void unitTest3(){
        Account acc =[select id  from Account limit 1];
        Test.startTest();
        Id jobId = Database.executeBatch(new EmployeeRosteringBatch(new set<Id>{acc.id},Date.today(),1), 200);
        Test.StopTest();
    }
    @isTest
    public static void unitTest4(){
        Account acc =[select id  from Account limit 1];
        Test.startTest();
        Id jobId = Database.executeBatch(new EmployeeRosteringBatch(new set<Id>{acc.id}), 200);
        Test.StopTest();
    }
    @isTest
    public static void unitTest5(){
        Account acc =[select id  from Account limit 1];
        Test.startTest();
        Id jobId = Database.executeBatch(new EmployeeRosteringBatch(new set<Id>{acc.id},Date.today()), 200);
        Test.StopTest();
    }
    @isTest
    public static void unitTest6(){
        Account acc =[select id  from Account limit 1];
        Test.startTest();
        Id jobId = Database.executeBatch(new EmployeeRosteringBatch(new set<Id>{acc.id},1), 200);
        Test.StopTest();
    }
    @isTest
    public static void unitTest7(){
        // This test runs a scheduled job at midnight 1pm
        String CRON_EXP = '0 0 1 * * ? * ';
        // Schedule the test job
        String jobId = System.schedule('EmployeeRosteringSchedular', CRON_EXP, new EmployeeRosteringSchedular());
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run 
        Datetime nextSchduletime = datetime.newInstance(DATE.today().year(), DATE.today().month(), DATE.today().addDays(1).day(),01,00,00);
        System.assertEquals(string.valueOf(nextSchduletime), String.valueOf(ct.NextFireTime));   
        
        EmployeeRosteringSchedular objTaskSchd= new EmployeeRosteringSchedular();
        objTaskSchd.execute(Null);
        
    }
}