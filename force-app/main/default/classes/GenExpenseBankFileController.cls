Public class GenExpenseBankFileController{
    public string organisation{get;set;}
    public integer totalEmployees{get;set;}
    Public decimal totalExpenseAmount{get;set;}
    Public String currencyCode{get;set;}
    //Public String sfUrl{get;set;}
    Public String OrganisationName{get;set;}
    Public date uploadDate{get;set;}
    
    Public GenExpenseBankFileController(){
        totalEmployees = 0;
        totalExpenseAmount = 0;
        //sfUrl = URL.getSalesforceBaseUrl().getHost();
    }
    
    Public void calculateExpenseDetail(){
        totalExpenseAmount = 0;
        if(organisation!=null && organisation.trim().length()>0){            
            List<Expense_Claim__c> expClaimList = [SELECT Id, Department__c, Organisation__c,Organisation__r.country__r.currency_code__c,Organisation__r.name, Employee__c, Remarks__c, Status__c, 
                    Submit_Date__c, Submit_For_Approval_Expense_Claim__c, Applied_Amount__c, Approved_Amount__c, Exp_Bank_File_Generated__c, 
                    Currency_Code__c, Name, Employee__r.Bank_Detail__r.Bank_Code__c, Employee__r.Bank_Detail__r.Branch_Code__c,Employee__r.Bank_Detail__c, 
                    Employee__r.AccountNumber, Employee__r.Beneficiary_Name__c, Employee__r.Tax_Number__c,Converted_Amount__c FROM Expense_Claim__c 
                    WHERE Organisation__c =:organisation AND Exp_Bank_File_Generated__c = FALSE AND Status__c in ('Approved','Partial Approved') and Converted_Amount__c>0 and Employee__r.AccountNumber!=null 
                    and Employee__r.Bank_Detail__c!=null];
            //add a condition to check expense claim list size and fetch currency code by organisation
            //code update by sakib on 28/11/2019
            
            if(expClaimList.size() > 0){
                currencyCode = expClaimList[0].Organisation__r.country__r.currency_code__c;
                OrganisationName = expClaimList[0].Organisation__r.Name;
                set<Id> empSet = new Set<Id>();        
                for(Expense_Claim__c expClaim: expClaimList){
                    empSet.add(expClaim.Employee__c);
                    totalExpenseAmount += expClaim.Converted_Amount__c;
                }
                totalExpenseAmount = totalExpenseAmount.setScale(2);
                totalEmployees = empSet.size(); 
            } 
        }
    }
    
    public pageReference generate(){
        return new pageReference('/apex/BankExpFile?org='+organisation+'&uploadDate='+uploadDate);
    }
    public List<Selectoption> getOrganisationList(){
        List<Selectoption> orgList = new List<Selectoption>();
        orgList.add(new SelectOption('','-- Select --'));
        for(Organisation__c org : [SELECT Id, Name FROM Organisation__c]){
            orgList.add(new SelectOption(org.Id,org.Name));
        }
        return orgList;
    }
    
}