@isTest
public class EmployeeRosteringSetupControllerTest{
    @testSetup static void testSetup() {
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
        /*Account centre = new Account(
name='testCenter',
CentreName_Cust__c='testCenter',
Travel_Time__c=60.00,
Location__c='Aureus Forum',
Center_Email__c='test@test.com',
Centre_Status__c='Active'
);
insert centre;*/
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
     
        Rostering__c rost = new Rostering__c(
            Employee__c = employee.id,
            Additional_Work_Day__c = true, 
            Centre__c = centre.id,
            Effective_Date__c = Date.Today().addDays(-1),
            Work_Day__c = 'Half Day',
            Shift__c = 'Regular Hours'
        );
        insert rost;  
        DateTime dt = system.now();
        Payout__c pay = new Payout__c (
            Employee_Name__c = employee.Id,
            Year__c  = dt.format('YYYY'),
            Month__c = dt.format('MMMMM')
        );
        insert pay;
        
    }
    @isTest
    public static void unitTest(){
        String centreId = [SELECT Id FROM Account Where RecordType.Name = 'Centre' LIMIT 1].Id;
        String employeeId = [SELECT Id FROM Account Where RecordType.Name = 'Employee' LIMIT 1].Id;
        Test.StartTest();
        EmployeeRosteringSetupController obj = new EmployeeRosteringSetupController();
        //obj.removeAssignEmployee();
        obj.rosteringSetupObject.rosteringSetupObject.Effective_Date__c = Date.Today();
        obj.rosteringSetupObject.rosteringSetupObject.Centre__c = centreId;
        obj.rosteringSetupObject.dateString = DateTime.Now().format('YYYY-MM-dd');
        obj.setupRosteringData();
        
        obj.rosteringSetupObject.rosteringSetupObject.Employee__c = employeeId;
        obj.rosteringSetupObject.rosteringSetupObject.Shift__c = 'Opening Hours';
        obj.rosteringSetupObject.rosteringSetupObject.Work_Day__c = 'Half Day';
        
        obj.addRosteringSetup();
        obj.editIndex = 0;
        obj.editAssignEmployee();
        
        obj.rosteringSetupObject.dateString = DateTime.Now().format('YYYY-MM-dd');
        obj.rosteringSetupObject.rosteringSetupObject.Work_Day__c = 'Full Day';
        obj.addRosteringSetup();
        
        obj.rosteringSetupObject.rosteringSetupObject.Centre__c = centreId;
        obj.saveRosteringSetup();
        
        EmployeeRosteringSetupController.getAssignedEmployee(DateTime.Now().format('YYYY-MM-dd'));
        EmployeeRosteringSetupController.getRemoteSearchResult('test');
        
        obj.updateDate = DateTime.Now().addDays(5).format('YYYY-MM-dd');
        obj.uptoDate = DateTime.Now().addDays(30).format('YYYY-MM-dd');
        obj.updateId = [SELECT Id FROM Rostering__c WHERE Additional_Work_Day__c = true LIMIT 1].Id;
        obj.isDefaultCentre = true;
        obj.afterUpdateEvent();
        obj.updateResourceId = centreId;
        obj.updateCalendarEvent();
        
        obj.removeIndex = 0;
        obj.removeAssignEmployee();
        obj.saveRosteringSetup();
        Test.StopTest();
    }
    @isTest
    public static void unitTest2(){
        Organisation__c orgObj = [select id FROM Organisation__c LIMIT 1];
        Country__c countryObj = [select id FROM Country__c LIMIT 1];
        String centreId = [SELECT Id FROM Account Where RecordType.Name = 'Centre' LIMIT 1].Id;
        String employeeId = [SELECT Id FROM Account Where RecordType.Name = 'Employee' LIMIT 1].Id;
        Leave_Request__c leaveObj = new Leave_Request__c();
        leaveObj.Employee__c = employeeId;
        leaveObj.Leave_Start_Date__c = Date.Today().addDays(1);
        leaveObj.Leave_End_Date__c = Date.Today().addDays(2);
        leaveObj.Status__c = 'Approved';
        insert leaveObj;
        Public_Holiday__c publicholidayObj= new Public_Holiday__c(Name='Test',Organisation_Status__c='Closed',Public_Holiday_Date__c=system.today().addDays(1),
                                                                  Execution_Date__c=system.today(),Status__c='Pending for execution',Country__c=countryObj.id,Organisation__c=orgObj.Id);
        insert publicholidayObj;
        List<Rostering__c> listOfRostering = new List<Rostering__c>();
        Rostering__c rost = new Rostering__c(
            Employee__c = employeeId,
            Additional_Work_Day__c = true, 
            Centre__c = centreId,
            Effective_Date__c = Date.Today(),
            Work_Day__c = 'Half Day',
            Shift__c = 'Regular Hours'
        );
        listOfRostering.add(rost);
        Rostering__c rost2 = new Rostering__c(
            Employee__c = employeeId,
            Additional_Work_Day__c = true, 
            Centre__c =centreId,
            Effective_Date__c = Date.Today().addDays(1),
            Work_Day__c = 'Full Day',
            Shift__c = 'Opening Hours'
        );
      listOfRostering.add(rost2);
        
        Rostering__c rost3 = new Rostering__c(
            Employee__c = employeeId,
            Additional_Work_Day__c = true, 
            Centre__c = centreId,
            Effective_Date__c = Date.Today().addDays(2),
            Work_Day__c = 'Full Day',
            Shift__c = 'Closing Hours'
        );
        listOfRostering.add(rost3);
        insert listOfRostering;
        
        Test.StartTest();
        EmployeeRosteringSetupController obj = new EmployeeRosteringSetupController();
        //obj.removeAssignEmployee();
        obj.rosteringSetupObject.rosteringSetupObject.Effective_Date__c = Date.Today();
        obj.rosteringSetupObject.rosteringSetupObject.Centre__c = centreId;
        obj.rosteringSetupObject.dateString = DateTime.Now().format('YYYY-MM-dd');
        obj.setupRosteringData();
        
        obj.rosteringSetupObject.rosteringSetupObject.Employee__c = employeeId;
        obj.rosteringSetupObject.rosteringSetupObject.Shift__c = 'Opening Hours';
        obj.rosteringSetupObject.rosteringSetupObject.Work_Day__c = 'Half Day';
        
        obj.addRosteringSetup();
        obj.editIndex = 0;
        obj.editAssignEmployee();
        
        obj.rosteringSetupObject.dateString = DateTime.Now().format('YYYY-MM-dd');
        obj.rosteringSetupObject.rosteringSetupObject.Work_Day__c = 'Full Day';
        obj.addRosteringSetup();
        
        obj.rosteringSetupObject.rosteringSetupObject.Centre__c = centreId;
        obj.saveRosteringSetup();
        
        EmployeeRosteringSetupController.getAssignedEmployee(DateTime.Now().format('YYYY-MM-dd'));
        EmployeeRosteringSetupController.getRemoteSearchResult('test');
        
        obj.updateDate = DateTime.Now().addDays(5).format('YYYY-MM-dd');
        obj.uptoDate = DateTime.Now().addDays(30).format('YYYY-MM-dd');
        obj.updateId = [SELECT Id FROM Rostering__c WHERE Additional_Work_Day__c = true LIMIT 1].Id;
        obj.updateResourceId = centreId;
        obj.isDefaultCentre = true;
        obj.updateCalendarEvent();
        obj.afterUpdateEvent();
        obj.workDayOldValue = 'Full Day';
        obj.editIndex =0;
        obj.validateOnWorkDayChange();
        obj.removeIndex = obj.existingRosteringList.size()-1;
        obj.removeAssignEmployee();
        obj.saveRosteringSetup();
        Test.StopTest();
    }
}