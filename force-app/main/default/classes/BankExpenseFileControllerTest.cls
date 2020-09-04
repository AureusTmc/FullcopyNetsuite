@isTest
private class BankExpenseFileControllerTest {

@isTest
    static void ValidateBankExpenseFileTestData(){
        //Create Country Records
        Country__c objCountry = new Country__c(Country_Name__c = 'Singapore',Name = 'SGD',Currency_Code__c = 'test code',Tax_Rate__c = 22.10);
        insert objCountry;
        //create organisation record
        Organisation__c orgObj = new Organisation__c();
        orgObj.Name  = 'Test Company';
        orgObj.Country__c = objCountry.id;
        orgObj.Bank_Account_Number__c = '10298773434';
        orgObj.Bank_Name__c = 'test Bank';
        orgObj.Branch_Code__c = 'Test101';
        insert orgObj;
        //create bank matser records
        Bank_Master__c bankObj = new Bank_Master__C(name='DBS');
        insert bankObj;
        
        //create account records
        
        Account accObj = new Account(name = 'Test Account',AccountNumber = '12345678',Bank_Detail__c= bankObj.Id);
        
        insert accObj;
        
        //insert Expense Claim records
        Expense_Claim__c expenseObj = new Expense_Claim__c ();
        expenseObj.Status__c = 'Approved';
        expenseObj.Employee__c = accObj.Id;
        expenseObj.Organisation__c = orgObj.Id;
        expenseObj.Exp_Bank_File_Generated__c = false;
        expenseObj.Converted_Amount__c = 100;
        
         insert expenseObj;
         
        Apexpages.currentPage().getParameters().put('org',orgObj.id);
       // pageRef.getParameters().put('id',orgObj.id);
        BankExpenseFileController bookingObj = new BankExpenseFileController();
        bookingObj.generateFile();
        bookingObj.TestgenerateFile();
        
        
    }
}