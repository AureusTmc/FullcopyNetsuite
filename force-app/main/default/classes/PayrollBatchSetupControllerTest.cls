@isTest
public class PayrollBatchSetupControllerTest{
    @isTest
    public static void newRecordUnitTestPayrollBatch(){
        Organisation__c org = new Organisation__c(Name = 'Test org');
        insert org;
        
        Payroll_Batch__c payBatchLastMonth = new Payroll_Batch__c(
            Month__c = DateTime.Now().addMonths(-1).format('MMMMM'),
            Organisation__c = org.id,
            Year__c = DateTime.Now().addMonths(-1).format('YYYY')
        );
        insert payBatchLastMonth ;
        
        Payroll_Batch__c payBatch = new Payroll_Batch__c(
            Month__c = DateTime.Now().format('MMMMM'),
            Organisation__c = org.id,
            Year__c = DateTime.Now().format('YYYY')
        );
        insert payBatch ;
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(new Payroll_Batch__c());
        PayrollBatchSetupController obj = new PayrollBatchSetupController(sc);
        
        PayrollBatchSetupController.getRunBatch(payBatchLastMonth.Id, org.Id, DateTime.Now().format('MMMMM'), DateTime.Now().format('YYYY'), '', payBatchLastMonth.Id);
        obj.reDirectTo();
        Test.stopTest();
    }
    
    @isTest
    public static void editRecordUnitTestPayrollBatch(){
        Organisation__c org = new Organisation__c(Name = 'Test org');
        insert org;
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        objAcc.RecordTypeId =s; 
        objAcc.LastName='testEmployee';
        objAcc.Teacher_Bio__c='testbio';
        objAcc.CentreName_Cust__c='testCenter';
        objAcc.Status__c='Working';   
        objAcc.Employee_Status__c = 'Confirm';
        objAcc.Joining_Date__c = Date.Today().addDays(-10);
        objAcc.Last_Working_Date__c = Date.today().addDays(10);
        objAcc.Issue_Date__c = Date.Today().addDays(-30);
        objAcc.ID_Type__c = 'Permanent Resident';
        objAcc.PersonBirthdate = date.today().addYears(-30);
        objAcc.Organisation__c = org.Id;
        objAcc.Employee_Duty_Type__c = 'Duty';
        insert objAcc; 
        
        Payroll_Batch__c payBatchLastMonth = new Payroll_Batch__c(
            Month__c = DateTime.Now().addMonths(-1).format('MMMMM'),
            Organisation__c = org.id,
            Year__c = DateTime.Now().addMonths(-1).format('YYYY')
        );
        insert payBatchLastMonth ;
        
        Payroll_Batch__c payBatch = new Payroll_Batch__c(
            Month__c = DateTime.Now().format('MMMMM'),
            Organisation__c = org.id,
            Year__c = DateTime.Now().format('YYYY')
        );
        insert payBatch ;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(payBatch);
        PayrollBatchSetupController obj = new PayrollBatchSetupController(sc);
        
        
        // calling meethods
        obj.reDirectTo();
        List<SelectOption> option = obj.getMonths;
        option = obj.getYearPickListValuesIntoList;
        String values = obj.getPaymentModePickListValuesIntoList;
        option = obj.getOrganisations;
        PayrollBatchSetupController.getFilterRemoteResult(org.Id, DateTime.Now().format('MMMMM'), DateTime.Now().format('YYYY'), payBatchLastMonth.Id);
        PayrollBatchSetupController.getRunBatch('', org.Id, DateTime.Now().format('MMMMM'), DateTime.Now().format('YYYY'), '', payBatchLastMonth.Id);
        PayrollBatchSetupController.getRunBatch('', org.Id, DateTime.Now().addMonths(1).format('MMMMM'), DateTime.Now().addMonths(1).format('YYYY'), '', payBatchLastMonth.Id);
        Test.stopTest();
    }
}