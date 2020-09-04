@isTest
private class Leave_Encashment_Controller_Test {
    
    @testSetup static void setup() {
        Schema.DescribeSObjectResult accountRecordType = Account.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = accountRecordType.getRecordTypeInfosByName();
        
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        
        insert country;
        
        Account Acc =  new Account(LastName = 'Bhuttan', Employee_Status__c = 'Draft', Onboarding_Stage__c = 'In Process', Employee_Nationality__c = 'American', 
                                   Work_Location__c = 'Singapore', Engagement_Type__c = 'Full-Time', PersonDepartment = 'C-Level', Person_Email__c = 'Bhuttan123@gmail.com',
                                   Job_Title__c = 'Cleaner', ID_Type__c = 'Foreigner', Identification_Number__c = '1234', ID_Location__c = 'Singapore', RecordTypeId = rtMapByName.get('Employee').RecordTypeId,
                                   Country__c = country.Id);
        insert Acc;
        Employee_Work_Week__c EWW = new Employee_Work_Week__c(Monday__c='Full Day',Tuesday__c='Full Day',Wednesday__c='Full Day',Thursday__c='Full Day',Friday__c='Full Day',Saturday__c='Full Day',Sunday__c='Full Day' ,Employee__c=Acc.Id,Effective_Date__c=system.today());
        insert EWW;
        Salary_Detail__c salary = new Salary_Detail__c(Employee_Name__c=Acc.Id,Basic_Salary__c=1000,Effective_Date__c=system.today(), Status__c='Active');
        Insert salary;
        Payout__c pay =   new Payout__c (Employee_Name__c = Acc.Id, Month__c = 'February', Year__c = '2020');
        insert pay;
        Payitem_Master__c pMaster = new Payitem_Master__c(Name='Leave Encashment');
        insert pMaster;
    }
    
    static testMethod void CreateLeaveEncashmenttest(){
        List<Payout__c> LstPayOut = [SELECT Id,Employee_Name__c,Year__c,Month__c  FROM Payout__c];
        List<Employee_Work_Week__c> WorkWeekLst = [SELECT Id,Working_Days_in_a_Week__c  FROM Employee_Work_Week__c];
        List<Salary_Detail__c> SalaryLst = [SELECT Id,Basic_Salary__c FROM Salary_Detail__c];
        List<Payitem_Master__c> itemMasterLst = [SELECT Id FROM Payitem_Master__c WHERE Name='Leave Encashment'];
        Test.startTest();
        Leave_Encashment_Controller.CreateLeaveEncashment(LstPayOut[0].Id, '2');
        Test.stopTest();
    }
    
    
    
}