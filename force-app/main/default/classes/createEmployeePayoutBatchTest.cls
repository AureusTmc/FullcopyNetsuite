@isTest
public class createEmployeePayoutBatchTest{
    @testSetup static void testSetup() {
        // Create Employee
        
        Account objAcc1 = new Account();
        string centerRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        objAcc1.name='testCenter';
        objAcc1.CentreName_Cust__c='testCenter'; 
        objAcc1.Travel_Time__c=60.00;
        objAcc1.Location__c='Aureus Forum';
        objAcc1.Center_Email__c='rajesh@techmatrixconsulting.com';
        objAcc1.Centre_Status__c='Active';
        insert objAcc1;
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        objAcc.RecordTypeId =s; 
        objAcc.LastName='testEmployee';
        objAcc.Teacher_Bio__c='testbio';
        objAcc.CentreName_Cust__c='testCenter';
        objAcc.Status__c='Working';   
        objAcc.Employee_Status__c = 'Confirm';
        objAcc.Employee_Duty_Type__c = 'Non-Duty';
        objAcc.Main_Centre__c = objAcc1.Id;
        objAcc.Joining_Date__c = Date.Today().addDays(-10);
        objAcc.Last_Working_Date__c = Date.today().addDays(10);
        objAcc.Issue_Date__c = Date.Today().addDays(-30);
        objAcc.ID_Type__c = 'Permanent Resident';
        objAcc.PersonBirthdate = date.today().addYears(-30);
        insert objAcc;   
        
        // Employee work week
        Employee_Work_Week__c workweek = new Employee_Work_Week__c(
            Effective_Date__c = Date.Today().addDays(-20),
            Employee__c = objAcc.Id,
            Friday__c = 'Full Day',
            Friday_Centre__c = objAcc1.Id,
            Monday__c = 'Full Day',
            Monday_Centre__c = objAcc1.Id,
            Saturday__c = 'Half Day',
            Saturday_Centre__c = objAcc1.Id,
            Sunday__c = 'Full Day',
            Sunday_Centre__c = objAcc1.Id,
            Thursday__c = 'Half Day',
            Thursday_Centre__c = objAcc1.Id,
            Tuesday__c = 'Full Day',
            Tuesday_Centre__c = objAcc1.Id,
            Wednesday__c = 'Full Day',
            Wednesday_Centre__c = objAcc1.Id
        );
        insert workweek;
        // Employee work week
        Employee_Work_Week__c workweek2 = new Employee_Work_Week__c(
            Effective_Date__c = Date.Today().addDays(-10),
            Employee__c = objAcc.Id,
            Friday__c = 'Full Day',
            Friday_Centre__c = objAcc1.Id,
            Monday__c = 'Full Day',
            Monday_Centre__c = objAcc1.Id,
            Saturday__c = 'Half Day',
            Saturday_Centre__c = objAcc1.Id,
            Sunday__c = 'Full Day',
            Sunday_Centre__c = objAcc1.Id,
            Thursday__c = 'Half Day',
            Thursday_Centre__c = objAcc1.Id,
            Tuesday__c = 'Full Day',
            Tuesday_Centre__c = objAcc1.Id,
            Wednesday__c = 'Full Day',
            Wednesday_Centre__c = objAcc1.Id
        );
        insert workweek2;
        
        Salary_Detail__c salaryDetails = new Salary_Detail__c(
            Active__c = true,
            Basic_Salary__c = 500,
            Effective_Date__c = Date.Today(),
            Employee_Name__c = objAcc.Id,
            Housing_Allowance__c = 32,
            Transport_Allowance__c = 32 ,
            Status__c='Active'
        );
        insert salaryDetails ;
        
        //Checklist Master
        List<Checklist_Master__c> ckmList = new List<Checklist_Master__c>();
        Checklist_Master__c ob = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Onboarding Process', X_days_before_Joining_Exit_Date__c = 2);
        Checklist_Master__c ex = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Exit Process', X_days_before_Joining_Exit_Date__c = 2);
        ckmList.add(ob);
        ckmList.add(ex);
        insert ckmList;
        
        List<Checklist_Item__c > ckItemList = new List<Checklist_Item__c >();
        Checklist_Item__c ckItem1 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ob.Id, Completed__c = true, Due_Date__c = Date.Today(), Employee__c = objAcc.Id , Type__c = 'Onboarding Process' );
        Checklist_Item__c ckItem2 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ex.Id, Completed__c = true, Due_Date__c = Date.Today(), Employee__c = objAcc.Id , Type__c = 'Exit Process' );
        ckItemList.add(ckItem1);
        ckItemList.add(ckItem2);
        
        insert ckItemList;
        
        Checklist_Template__c ckLTemplate = new Checklist_Template__c(Type__c = 'Onboarding Process');
        insert ckLTemplate ;
        Checklist_Template_Activity__c  temp = new Checklist_Template_Activity__c (Checklist_Template__c = ckLTemplate.Id, Checklist_Master__c = ob.Id);
        insert temp;
        
        Documents__c doc = new Documents__c(Name = 'Employee Policy');
        insert doc;
        
        Employee_Document__c eDoc = new Employee_Document__c(Document__c = doc.Id, Name = 'Employee Policy', Employee__c = objAcc.Id, Required__c = false, Stage__c = 'In Process');
        insert eDoc;
        
        Organisation__c org = new Organisation__c(Name = 'Test org');
        insert org;
        
        Payroll_Batch__c payBatch = new Payroll_Batch__c(
            Month__c = DateTime.Now().format('MMMMM'),
            Organisation__c = org.id,
            Year__c = DateTime.Now().format('YYYY')
        );
        insert payBatch ;
        
        CPF_Category__c cpfCat = new CPF_Category__c(
            Category__c = 'First Year',
            Min_Employee_Age__c = 0,
            Max_Employee_Age__c = 55,
            Min_Total_Wage__c = 0,
            Max_Total_Wages__c = 4000,
            Capped_OW_Ceiling_Amount__c = 3000
        );
        insert cpfCat;
        
        Test.StartTest();
        Id batchJobId = Database.executeBatch(new createEmployeePayoutBatch(), 200);
        Test.StopTest();
    }
    
    @isTest
    public static void unitSDTest(){
        Id employeeId = [SELECT Id FROM Account Where RecordType.Name = 'Employee' LIMIT 1].Id;
        Salary_Detail__c salaryDetails2 = new Salary_Detail__c(
            Active__c = true,
            Basic_Salary__c = 2000,
            Effective_Date__c = Date.Today().addDays(-5),
            Employee_Name__c = employeeId ,
            Housing_Allowance__c = 32,
            Transport_Allowance__c = 32 ,
            Status__c='Active'
        );
        insert salaryDetails2 ;
        Test.StartTest();
        Id batchJobId = Database.executeBatch(new createEmployeePayoutBatch(), 200);
        Test.StopTest();
    }
    
    @isTest
    public static void unitBatchParamTest(){
        Test.StartTest();
        Id employeeId = [SELECT Id FROM Account Where RecordType.Name = 'Employee' LIMIT 1].Id;
        Payroll_Batch__c pay = [SELECT Id, Name, Month__c, Year__c, Status__c, Organisation__c FROM Payroll_Batch__c Limit 1];
        Id batchJobId = Database.executeBatch(new createEmployeePayoutBatch(Date.Today(), new Set<Id>{employeeId}, pay ), 200);
        Test.StopTest();
    }
    
    @isTest
    public static void unitWithoutParamTest(){
        Test.StartTest();
        Id batchJobId = Database.executeBatch(new createEmployeePayoutBatch(), 200);
        
        Id employeeId = [SELECT Id FROM Account Where RecordType.Name = 'Employee' LIMIT 1].Id;
        // Aureus HR Utilty class method call
        date currentDate = system.today(); 
        Integer currYear = currentDate.Year();
        Integer currMonth = currentDate.month();
        Date startMonthDate = date.newInstance(currYear,currMonth,1); 
        Date lastMonthDate = date.newInstance(currYear,currMonth,Date.DaysInMonth(currYear,currMonth));
        
        AureusHRUtility.getEmployeeWorkWeek(new Set<Id>{employeeId}, lastMonthDate );
        AureusHRUtility.getEmployeeSalary(new Set<Id>{employeeId}, lastMonthDate );
            
        AureusHRUtility.nricValidation('087655432');
        Test.StopTest();
        
        String payoutIdStr = [SELECT Id FROM Payout__c ORDER BY CreatedDate DESC LIMIT 1].Id;
        AureusHRUtility.getEmployeePayout(new List<String>{payoutIdStr });
        
        Payitem_Master__c pMaster = new Payitem_Master__c(Active__c = TRUE, CPF__c = 'OW', Type__c = 'Addition');
        insert pMaster;
        
        PayItem__c payItem = new PayItem__c(Payout__c = payoutIdStr, Value__c=4, Payitem__c = pMaster.Id);
        insert payItem;
        
        ReCalculatePayoutActionController.getCalculatePayout(payoutIdStr);
        
        CalculatePayoutService.getAmountByPercent(10,100);
        CalculatePayoutService.ECMultipleofTWFixedAmount(10,100,10);
    }
    
    @isTest
    public static void testMethod1(){
        //Payroll_Batch__c pay = [SELECT Id, Name, Month__c, Year__c, Status__c, Organisation__c FROM Payroll_Batch__c Limit 1];
        /*Payout__c payout = new Payout__c();
        insert payout;*/
        
        Id payoutId = [SELECT Id FROM Payout__c ORDER BY CreatedDate ASC LIMIT 1].Id;
        
        Test.StartTest();
        AureusHRUtility.calculatePayout(new Set<id>{payoutId});
        Test.StopTest();
    }
}