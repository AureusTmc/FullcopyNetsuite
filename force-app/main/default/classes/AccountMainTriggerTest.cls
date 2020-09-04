@isTest
public class AccountMainTriggerTest{
    @istest
    public static void unitTest(){
        String empRecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Account employee1 = new Account(
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
            PersonBirthdate = date.today().addYears(-30)
        );
        
        List<Account > listOfEmployee = new List<Account >();
        listOfEmployee.add(new Account(
            RecordTypeId = empRecordTypeId,
            LastName='testEmployee1',
            Teacher_Bio__c='testbio',
            CentreName_Cust__c='testCenter',
            Status__c='Working',
            Employee_Status__c = 'Confirm',
            Joining_Date__c = Date.Today().addDays(-10),
            Last_Working_Date__c = Date.today().addDays(10),
            Issue_Date__c = Date.Today().addDays(-30),
            ID_Type__c = 'Permanent Resident',
            PersonBirthdate = date.today().addYears(-30)
        ));
        listOfEmployee.add(new Account(
            RecordTypeId = empRecordTypeId,
            LastName='testEmployee2',
            Teacher_Bio__c='testbio',
            CentreName_Cust__c='testCenter',
            Status__c='Working',
            Employee_Status__c = 'Confirm',
            Joining_Date__c = Date.Today().addDays(-10),
            Last_Working_Date__c = Date.today().addDays(10),
            Issue_Date__c = Date.Today().addDays(-30),
            ID_Type__c = 'Permanent Resident',
            PersonBirthdate = date.today().addYears(-30)
        ));
        Test.StartTest();
        insert employee1; 
        insert listOfEmployee; 
        employee1.Employee_Code__c = 'abc';
        update employee1;
        Test.StopTest();
    }
}