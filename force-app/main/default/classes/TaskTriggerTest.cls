@isTest
public class TaskTriggerTest {
    public static testMethod void invokeTaskTrigger(){
        Case caseObj = TestUtil.createCase(true);
        Task tskObj = new Task(Priority	='Normal',Status='Open',Subject='Call',WhatId=caseObj.Id);
        list<Task> taskList =new list<Task>();
        taskList.add(tskObj);
        insert taskList;
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        if(s!=null){
            objAcc.RecordTypeId =s; 
            objAcc.LastName='testEmployee';
            objAcc.Teacher_Bio__c='testbio';
            objAcc.CentreName_Cust__c='testCenter';
            objAcc.Status__c='Working';   
            objAcc.Employee_Status__c = 'draft';
        }
        insert objAcc;   
        
        //Checklist Master
        Checklist_Master__c ob = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Onboarding Process', X_days_before_Joining_Exit_Date__c = 2);
        insert ob;
        
        Checklist_Item__c ckItem1 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ob.Id, Completed__c = false, Due_Date__c = Date.Today(), Employee__c = objAcc.Id , Type__c = 'Onboarding Process' );
        insert ckItem1;
        
        Task t = new Task(Priority	='Normal',Status='Open',Subject='Call',WhatId=ckItem1.Id);
        insert t;
        
        t.Status = 'Completed';
        update t;
        
        
    }
}