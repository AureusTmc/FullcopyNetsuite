@isTest
public class EmployeeNRICValidationTest{
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
            Identification_Number__c = '121212',
            Tax_Number__c = '21342'
        );
        Test.StartTest();
        database.insert(employee,false);  
        Test.StopTest();
    }
}