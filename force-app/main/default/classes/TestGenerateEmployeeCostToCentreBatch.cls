/*
 * 		Name 			: TestGenerateEmployeeCostToCentreBatch;
 * 		Date 			: Dec, 24 2019
 * 		Author 			:
 * 		Descriptions	: this is GenerateEmployeeCostCentreBatchTest class of GenerateEmployeeCostToCentreBatch this Test class used to coverd GenerateEmployeeCostToCentreBatch class..
 * 		
*/


@isTest
private class TestGenerateEmployeeCostToCentreBatch {
    
    
    @TestSetup
    private static void dataSetup(){
        
        
        List<Account>	accountsList = new List<Account>();
        
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
        
        accountsList.add(new Account(LastName = 'Bhuttan', Employee_Status__c = 'Draft', Onboarding_Stage__c = 'In Process', Employee_Nationality__c = 'American', 
                                    Work_Location__c = 'Singapore', Engagement_Type__c = 'Full-Time', PersonDepartment = 'C-Level', Person_Email__c = 'Bhuttan123@gmail.com',
                                    Job_Title__c = 'Cleaner', ID_Type__c = 'Foreigner', Identification_Number__c = '1234', ID_Location__c = 'Singapore', RecordTypeId = rtMapByName.get('Employee').RecordTypeId,
                        			Country__c = country.Id));
        accountsList.add(new Account(Name = 'Aureus 112 katong', Location__c = 'Aureus 112 katong', Center_Email__c = 'bhutt23@gmail.com', RecordTypeId = rtMapByName.get('Centre').RecordTypeId,
                         Country__c = country.Id));
        accountsList.add(new Account(LastName = 'Bhuttan', Employee_Status__c = 'Draft', Onboarding_Stage__c = 'In Process', Employee_Nationality__c = 'American', 
                                    Work_Location__c = 'Singapore', Engagement_Type__c = 'Full-Time', PersonDepartment = 'C-Level', Person_Email__c = 'btun23@gmail.com',
                                    Job_Title__c = 'Cleaner', ID_Type__c = 'Foreigner', Identification_Number__c = '3013', ID_Location__c = 'Singapore', RecordTypeId = rtMapByName.get('Teacher').RecordTypeId,
                        Country__c = country.Id));
        
        
        if(!accountsList.isEmpty()){
            INSERT accountsList;
        }
        
        List<Payout__c>	payoutsList = new List<Payout__c>();
        
        payoutsList.add(new Payout__c (Employee_Name__c = accountsList[0].Id, Month__c = 'December', Year__c = '2019'));
        payoutsList.add(new Payout__c (Employee_Name__c = accountsList[2].Id, Month__c = 'December', Year__c = '2019'));
        
        if(!payoutsList.isEmpty()){
            INSERT payoutsList;
        }
        
        List<Rostering__c> rosteringsList = new List<Rostering__c>();
        
        rosteringsList.add(new Rostering__c(Employee__c = accountsList[0].Id, Work_Day__c = 'Full Day', Centre__c = accountsList[1].Id , Effective_Date__c = Date.newInstance(2019, 12, 9),
                                           Shift__c = 'Opening Hours'));
       
        
        if(!rosteringsList.isEmpty()){
            INSERT rosteringsList;
        }
        
        List<Teacher_Working_Hour__c>	teacherWrokingsList = new List<Teacher_Working_Hour__c>();
        teacherWrokingsList.add(new Teacher_Working_Hour__c(Active__c = true, Break_Time__c = false,  Center_Name__c = accountsList[1].Id, Teacher_Name__c = accountsList[2].Id,
                                                            Start_Time__c = Time.newInstance(2,23,45,55), End_Time__c = Time.newInstance(7,40,50,51) , Working_Day__c = 'mon'));
        
        if(!teacherWrokingsList.isEmpty()){
            INSERT teacherWrokingsList;
        }
        
    }
    Private static testMethod void processGenerateEmployeeCostToCentre(){
        
        Set<Id>	accountIdsSet = new Set<Id>();
        
        for(Account accountRecord : [SELECT Id, LastName, Employee_Status__c FROM Account]){
            if(accountRecord.Id != null){
                accountIdsSet.add(accountRecord.Id);
            }
        }
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2022';
		String jobId = System.schedule('GenerateEmployeeCostToCentreScheduler',CRON_EXP,new GenerateEmployeeCostToCentreScheduler());
        
        Test.stopTest();
        System.debug('hello accountIds --> '+accountIdsSet);
		GenerateEmployeeCostToCentreBatch  employeeObj1 = new GenerateEmployeeCostToCentreBatch();        
        GenerateEmployeeCostToCentreBatch  employeeObj2 = new GenerateEmployeeCostToCentreBatch(accountIdsSet);
        
        GenerateEmployeeCostToCentreBatch  employeeObj3 = new GenerateEmployeeCostToCentreBatch(accountIdsSet, Date.newInstance(2019, 12, 2));
        GenerateEmployeeCostToCentreBatch  employeeObj4 = new GenerateEmployeeCostToCentreBatch(Date.newInstance(2019, 12, 5));
        
        Database.executeBatch(new GenerateEmployeeCostToCentreBatch(accountIdsSet));
        Database.executeBatch(new GenerateEmployeeCostToCentreBatch(accountIdsSet));
        
    }
    
    

}