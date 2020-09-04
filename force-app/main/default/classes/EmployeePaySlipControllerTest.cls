@isTest
public class EmployeePaySlipControllerTest{
    @isTest
    public static void unitTest(){
        
        string empRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Account employee = new Account(
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
			Employee_Duty_Type__c = 'Duty'
        );
        insert employee;  
        Payout__c payout = new Payout__c(
            Salary__c = 200,
            Employee_Name__c = employee.Id,
            year__c = DateTime.Now().format('YYYY'),
            Month__c = DateTime.Now().format('MMMM'),
            Employee_CPF_Amount__c = 21,
            Employer_CPF_Amount__c = 31,
            CDAC_Contribution__c = true,
            EUCF_Contribution__c = true,
            MBMF_Contribution__c = true,
            SINDA_Contribution__c = true
        );
        insert payout ;
        
        Test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(payout );
        EmployeePaySlipController ctrl = new EmployeePaySlipController(sc);
        Test.StopTest();
    }
}