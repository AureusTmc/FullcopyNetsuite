/**
 *  Name		 : GenExpenseBankFileControllerTest
 * 	Date 		 : Dec, 2 2019
 *  Author 		 : 
 * Descriptions  : this is Test class of GenExpenseBankFileController and this test class used for coverage code of 
*/

@isTest
private class GenExpenseBankFileControllerTest {
    
    @TestSetup
    static void dataSetup(){
        
        List<Country__c> countiesList = new List<Country__c>();
        countiesList.add(new Country__c(Currency_Code_PI__c = 'SGD', Country_Name__c = 'singapore', Currency_Code__c = 'SGD', Tax_Rate__C = 7.0));
        
        if(!countiesList.isEmpty()){
            INSERT countiesList;
        } 
        
        List<Organisation__c> organisationsList = new List<Organisation__c>();
        organisationsList.add(new Organisation__c(Name = 'Aureus', Bank_Name__c = 'SBI', Bank_Account_Number__c = '101020291829', Branch_Code__c = 'SBI0123'));
        
        if(!organisationsList.isEmpty()){
            Insert organisationsList;
        }
        
        List<Bank_Master__c>  bankMastersList = new List<Bank_Master__c>();
        bankMastersList.add(new Bank_Master__c(Name='DBS'));
        
        if(!bankMastersList.isEmpty()){
           INSERT bankMastersList;
        }
        
        List<Account>	accountsList = new List<Account>();
        Id employeRecordId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        accountsList.add(new Account(LastName = 'rahul', Tax_Number__c = 'S2688233H', Employee_Status__c = 'Draft', Onboarding_Stage__c = 'In Process',
                                    Employee_Nationality__c = 'Indian', Personal_Email__c = 'rahul123@gmail.com', PersonMobilePhone = '9834456576',
                                    Engagement_Type__c = 'Contract', Work_Location__c = 'Hong Kong', Job_Title__c = 'Cleaner', PersonDepartment = 'C-Level',
                                    Identification_Number__c = '23', ID_Type__c = 'foreigner', ID_Location__c = 'Hong Kong',RecordTypeId =employeRecordId,
                                    AccountNumber = '12345',Organisation__c = organisationsList[0].Id,Bank_Detail__c = bankMastersList[0].Id));
        
        if(!accountsList.isEmpty()){
            INSERT accountsList;
        }
        
        
        List<Expense_Claim__c> expenseClaimsList = new List<Expense_Claim__c>();
        
        expenseClaimsList.add(new Expense_Claim__c(Exp_Bank_File_Generated__c = FALSE,Status__c = 'Approved',Converted_Amount__c = 120,
                                                   Employee__c=accountsList[0].Id,Organisation__c = organisationsList[0].Id ));
        
        if(!expenseClaimsList.isEmpty()){
            INSERT expenseClaimsList;
        }
        
    }
    static testMethod void processCalculateExpenseDetail(){
        List<Organisation__c> organisationsList = [SELECT Id FROM Organisation__c LIMIT 1];
        
        GenExpenseBankFileController obj = new GenExpenseBankFileController();
        obj.OrganisationName = organisationsList[0].Id;
        obj.organisation = organisationsList[0].Id;
        obj.calculateExpenseDetail();
        obj.getOrganisationList();
        obj.generate();
    }

}