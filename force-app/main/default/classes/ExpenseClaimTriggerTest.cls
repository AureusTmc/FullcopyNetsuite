/*
    Name        : ExpenseClaimTriggerTest
    Date        : 02-dec-2019
    Author      :   
    Description : Test class of ExpenseClaimTrigger
*/
@isTest
private class ExpenseClaimTriggerTest{
    @testSetup
    static void testDataSetup(){
        List<Expense_Claim__c> listOfExpenseClaim = new  List<Expense_Claim__c>();
        //Create Country Records
        Country__c objCountry = new Country__c(Country_Name__c = 'Singapore',Name = 'SGD',Currency_Code__c = 'test code',Tax_Rate__c = 22.10);
        insert objCountry;
        
        //Create Organisation Object
        Organisation__c orgObj = new Organisation__c(Name = 'Test Organisation',Country__c = objCountry.Id);
        insert orgObj; 
      
        //Create Account records 
        Account accObj = new Account(name = 'Test Account');
        insert accObj;
      
        //Create Expense_claim object
       
        listOfExpenseClaim.add(new Expense_Claim__c(Status__c = 'Rejected',Employee__c = accObj.Id,Organisation__c = orgObj.Id));
        
        listOfExpenseClaim.add(new Expense_Claim__c(Status__c = 'Pending',Employee__c = accObj.Id,Organisation__c = orgObj.Id));
        
        //Insert Expense_claim object 
        if(listOfExpenseClaim.size() > 0){
            insert listOfExpenseClaim;
        }
        //Create Expense_Type records
        Expense_Type__c expensesTypeObj = new Expense_Type__c(Name ='Test type');
        insert expensesTypeObj;
        
        //Create Expenses Item
        Expense_Item__c expenseItemObj = new Expense_Item__c(Expense_Claim__c = listOfExpenseClaim[0].id, Expense_Type__c = expensesTypeObj.id,Amount__c = 1000);
        insert expenseItemObj;
    }
    @isTest
    static void invokeExpenseClaimTest(){
        Test.startTest();
        List<Expense_Claim__c> listToUpdate = new List<Expense_Claim__c>();
        List<Expense_Claim__c> expenseClaim  = [SELECT Id,Name,Status__c,Submit_Date__c,Organisation__c,Employee__c FROM Expense_Claim__c]; 
        
        //Update Expense_Claim Records
        listToUpdate.add(new Expense_Claim__c(Id = expenseClaim[0].Id,Status__c = 'Approved'));
        listToUpdate.add(new Expense_Claim__c(Id = expenseClaim[1].Id,Status__c = 'Rejected'));
       
        if(listToUpdate.size() > 0){
            update listToUpdate;
        }
        
        test.stopTest();
        
    }
}