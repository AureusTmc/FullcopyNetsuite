@isTest
public class GenerateCPFSubmissionFileControllerTest{
    @isTest
    public static void unitTest(){
        GenerateCPFSubmissionFileController obj = new GenerateCPFSubmissionFileController();
        obj.getMonthList();
        obj.getYearList();
        obj.getOrganisationList();
        obj.generate();
    }
    @isTest
    public static void unitTestCPFSubmissionFile(){
        Organisation__c org = new Organisation__c(
            Name = 'Test Org',
            CPF_Advice_Code__c = '123456789',
            CPF_Payment_Type__c = 'Test Bank Name',
            UEN__c = '001'
        );
        insert org;
        
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
        Test.setCurrentPageReference(new PageReference('Page.CPFSubmissionFile')); 
        System.currentPageReference().getParameters().put('org', org.Id);
        CPFSubmissionFileController obj = new CPFSubmissionFileController();
        Test.StopTest();
    }
}