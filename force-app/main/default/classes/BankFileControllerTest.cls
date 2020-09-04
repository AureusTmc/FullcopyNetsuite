@isTest
public class BankFileControllerTest{
    
     @isTest
    public static void unitTest(){
        
        string empRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Organisation__c org = new Organisation__c(
            Name = 'Test Org',
            Bank_Account_Number__c = '123456789',
            Bank_Name__c = 'Test Bank Name',
            Branch_Code__c = '001'
        );
        insert org;
        
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
            Organisation__c = org.Id,
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
        Test.setCurrentPageReference(new PageReference('Page.BankFile')); 
        System.currentPageReference().getParameters().put('org', org.Id);
        BankFileController obj = new BankFileController();
        obj.redirectTo();
        Test.StopTest();
    }
}