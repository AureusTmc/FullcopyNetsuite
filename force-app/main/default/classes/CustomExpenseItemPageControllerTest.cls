/*
    Name : CustomExpenseItemPageControllerTest
    Date : 07 October 2019
    Author :
    Description: 
*/

@isTest
public class CustomExpenseItemPageControllerTest{
    @isTest
    public static void validateCustomExpenseItemPageController(){
        Account acc = new Account(LastName = 'test');
        insert acc;
        
        Expense_Type__c expType = new Expense_Type__c(Name = 'Test');
        insert expType;
        
        Expense_Claim__c expClaim = new Expense_Claim__c(Employee__c = acc.id, Status__c = 'Pending');
        insert expClaim;
        
        Expense_Item__c expItem = new Expense_Item__c(Expense_Claim__c = expClaim.Id, Expense_Type__c = expType.Id, Status__c = 'Pending', Amount__c = 100);
        insert expItem;
        
        Expense_Item__c expItem2 = new Expense_Item__c(Expense_Claim__c = expClaim.Id, Expense_Type__c = expType.Id, Status__c = 'Pending', Amount__c = 200);
        insert expItem2;
        
        PageReference pageRef = Page.CustomExpenseItemPage;
        pageRef.getparameters().put('id', expClaim.id);  
        Test.setCurrentPage(pageRef);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(expClaim);
        CustomExpenseItemPageController ext = new  CustomExpenseItemPageController(sc);      
        ext.fetchExpItems();
        ext.getIsCurrentUserApprover();
        
        Integer i = 0;
        for(CustomExpenseItemPageController.ExpItem expItmWrapperObj: ext.expItemList){
            if(i==0)
                expItmWrapperObj.approvalAction = true;
            else
                expItmWrapperObj.approvalAction = false;
            i++;
        }
        
        ext.saveChanges();
        
        Expense_Item__c expItem3 = new Expense_Item__c(Expense_Claim__c = expClaim.Id, Expense_Type__c = expType.Id, Status__c = 'Pending');
        insert expItem3;
        
        expClaim.Status__c = 'Approved';
        update expClaim;
        
        expClaim.Status__c = 'Rejected';
        update expClaim;
        ext.getExpenseTypePL();
        ext.getSupplierPL();
        ext.saveChanges();
    }
    
}