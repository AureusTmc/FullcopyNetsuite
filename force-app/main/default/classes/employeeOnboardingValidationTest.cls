@isTest
public class employeeOnboardingValidationTest{
    @isTest
    public static void unitTest(){
        String empRecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Account employee = new Account(
            RecordTypeId = empRecordTypeId,
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
            Onboarding_Stage__c = 'In Process'
        );
        
        insert employee;
        
        List<Checklist_Master__c> ckmList = new List<Checklist_Master__c>();
        Checklist_Master__c ob = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Onboarding Process', X_days_before_Joining_Exit_Date__c = 2);
        Checklist_Master__c ex = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Exit Process', X_days_before_Joining_Exit_Date__c = 2);
        ckmList.add(ob);
        ckmList.add(ex);
        insert ckmList;
        
        List<Checklist_Item__c > ckItemList = new List<Checklist_Item__c >();
        Checklist_Item__c ckItem1 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ob.Id, Completed__c = False, Due_Date__c = Date.Today().addDays(-1), Employee__c = employee.Id , Type__c = 'Onboarding Process' );
        Checklist_Item__c ckItem2 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ex.Id, Completed__c = False, Due_Date__c = Date.Today().addDays(-1), Employee__c = employee.Id , Type__c = 'Exit Process' );
        ckItemList.add(ckItem1);
        ckItemList.add(ckItem2);
        insert ckItemList;
        
        Documents__c doc = new Documents__c(Name = 'Employee Policy');
        insert doc;
        
        Employee_Document__c eDoc = new Employee_Document__c(Document__c = doc.Id, Name = 'Employee Policy', Employee__c = employee.Id, Required__c = true, Uploaded__c = false, Stage__c = 'In Process');
        insert eDoc;
        
        Test.StartTest();
        
        
        
        
        ckItem1.Completed__c = true;
        update ckItem1;
        
        database.update( employee,false);
        
        employee.Onboarding_Stage__c = 'LO Signed';
        database.update( employee,false);
        
        employee.Onboarding_Stage__c = 'In Process';
        database.update( employee,false);
        
        employee.Onboarding_Stage__c = 'Contract Signed';
        database.update( employee,false);
        
        employee.Onboarding_Stage__c = 'Joining';
        database.update( employee,false);
        
        employee.Onboarding_Stage__c = 'Completed';
        database.update( employee,false);
        
        eDoc.Required__c = false;
        update eDoc;
        
        ckItem1.Completed__c = false;
        update ckItem1;
        
        employee.Onboarding_Stage__c = 'Joining';
        database.update( employee,false);
        Test.StopTest();
    }
}