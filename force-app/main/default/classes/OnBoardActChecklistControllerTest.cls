@isTest
public class OnBoardActChecklistControllerTest{
    @testSetup static void methodName() {
        // Create Employee
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        if(s!=null){
            objAcc.RecordTypeId =s; 
            objAcc.LastName='testEmployee';
            objAcc.Teacher_Bio__c='testbio';
            objAcc.CentreName_Cust__c='testCenter';
            objAcc.Status__c='Working';   
            objAcc.Employee_Status__c = 'Confirm';
            objAcc.Joining_Date__c = system.today();
            objAcc.Employee_Duty_Type__c = 'Duty';
        }
        insert objAcc;   
        
        //Checklist Master
        List<Checklist_Master__c> ckmList = new List<Checklist_Master__c>();
        Checklist_Master__c ob = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Onboarding Process', X_days_before_Joining_Exit_Date__c = 2);
        Checklist_Master__c ex = new Checklist_Master__c(Activity_Name__c = 'Master' , Type__c = 'Exit Process', X_days_before_Joining_Exit_Date__c = 2);
        ckmList.add(ob);
        ckmList.add(ex);
        insert ckmList;
        
        List<Checklist_Item__c > ckItemList = new List<Checklist_Item__c >();
        Checklist_Item__c ckItem1 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ob.Id, Completed__c = true, Due_Date__c = Date.Today(), Employee__c = objAcc.Id , Type__c = 'Onboarding Process' );
        Checklist_Item__c ckItem2 = new Checklist_Item__c (Activity_Name__c = 'Act', Checklist_Master__c = ex.Id, Completed__c = true, Due_Date__c = Date.Today(), Employee__c = objAcc.Id , Type__c = 'Exit Process' );
        ckItemList.add(ckItem1);
        ckItemList.add(ckItem2);
        
        insert ckItemList;
        
        Checklist_Template__c ckLTemplate = new Checklist_Template__c(Type__c = 'Onboarding Process');
        insert ckLTemplate ;
        Checklist_Template_Activity__c  temp = new Checklist_Template_Activity__c (Checklist_Template__c = ckLTemplate.Id, Checklist_Master__c = ob.Id);
        insert temp;
        
        Documents__c doc = new Documents__c(Name = 'Employee Policy');
        insert doc;
        
        Employee_Document__c eDoc = new Employee_Document__c(Document__c = doc.Id, Name = 'Employee Policy', Employee__c = objAcc.Id, Required__c = false, Stage__c = 'In Process');
        insert eDoc;
    }
    
    @isTest
    public static void unitTest(){
        String employeeId = [SELECT Id FROM Account LIMIT 1].Id;
        
        OnboardingActivityChecklistController.getExistingOBCheckListItem(employeeId);
        OnboardingActivityChecklistController.getExistingExitCheckListItem(employeeId);
        
        OnboardingActivityChecklistController.getMasterCheckList(employeeId, DateTime.Now().format('YYYY-MM-dd'), false);
        
        String templateId = [SELECT Id FROM Checklist_Master__c LIMIT 1].Id;
        OnboardingActivityChecklistController.getMasterCheckListItemByTemplate(templateId);
        
        String ChkMasterId = [SELECT Id FROM Checklist_Master__c WHERE Type__c = 'Onboarding Process' LIMIT 1].Id;
        String ChkItemId = [SELECT Id FROM Checklist_Item__c WHERE Type__c = 'Onboarding Process' LIMIT 1].Id;
        String masterLists = '';
        masterLists += '[{';
            masterLists += '"checklist_Item": {';
                masterLists += '"Checklist_Master__c": "'+ChkMasterId+'",';
                masterLists += '"Activity_Name__c": "Apply for Visa",';
                masterLists += '"Due_Date__c": "'+DateTime.Now().format('YYYY-MM-dd')+'",';
                masterLists += '"Type__c": "Onboarding Process",';
                masterLists += '"Employee__c": "'+employeeId+'",';
                masterLists += '"Id": "'+ChkItemId+'"';
            masterLists += '},';
            masterLists += '"isChecked": true,';
            masterLists += '"master_check": {';
                masterLists += '"Id": "'+ChkMasterId+'",';
                masterLists += '"Activity_Name__c": "Apply for Visa",';
                masterLists += '"Name": "CM - 0002",';
                masterLists += '"Type__c": "Onboarding Process",';
                masterLists += '"X_days_before_Joining_Exit_Date__c": 10';
            masterLists += '},';
            masterLists += '"oldDate": "'+DateTime.Now().addDays(-1).format('YYYY-MM-dd')+'"';
        masterLists += '}]';
        
        String ChkMasterId2 = ChkMasterId;
        ChkMasterId = [SELECT Id FROM Checklist_Master__c WHERE Id != : ChkMasterId2 AND  Type__c = 'Exit Process' LIMIT 1].Id;
        
        String masterExitLists = '';
        masterExitLists += '[{';
            masterExitLists += '"checklist_Item": {';
                masterExitLists += '"Checklist_Master__c": "'+ChkMasterId+'",';
                masterExitLists += '"Activity_Name__c": "Apply for Visa",';
                masterExitLists += '"Due_Date__c": "'+DateTime.Now().format('YYYY-MM-dd')+'",';
                masterExitLists += '"Type__c": "Onboarding Process",';
                masterExitLists += '"Employee__c": "'+employeeId+'",';
                masterExitLists += '"Id": "'+ChkItemId+'"';
            masterExitLists += '},';
            masterExitLists += '"isChecked": false,';
            masterExitLists += '"master_check": {';
                masterExitLists += '"Id": "'+ChkMasterId+'",';
                masterExitLists += '"Activity_Name__c": "Apply for Visa",';
                masterExitLists += '"Name": "CM - 0002",';
                masterExitLists += '"Type__c": "Onboarding Process",';
                masterExitLists += '"X_days_before_Joining_Exit_Date__c": 10';
            masterExitLists += '},';
            masterExitLists += '"oldDate": "'+DateTime.Now().addDays(-1).format('YYYY-MM-dd')+'"';
        masterExitLists += '}]';
        Account Employee = [SELECT Id, Name,Status__c,Joining_Date__c,Last_Working_Date__c,Employee_Status__c, Contract_End_Date__c,Exit_Type__c,Notice_Period__c FROM Account WHERE Id =: employeeId LIMIT 1];
        
        String docId = [SELECT Id FROM Documents__c LIMIT 1].Id;
        String eDOcId = [SELECT Id FROM Employee_Document__c  LIMIT 1].Id;
        String masterDocumentLists = '';
        masterDocumentLists += '[{';
            masterDocumentLists += '"documentId": "'+docId+'",';
            masterDocumentLists += '"documentName": "Employee Policy",';
            masterDocumentLists += '"eDocumentId": "'+eDOcId+'",';
            masterDocumentLists += '"isChecked": true,';
            masterDocumentLists += '"isRequired": true,';
            masterDocumentLists += '"onBoardingStatge": "In Process"';
        masterDocumentLists += '}]';

        
        OnboardingActivityChecklistController.generateCheckListItems(masterLists, masterExitLists, employeeId, Employee , masterDocumentLists, true, 'Test Template', 'Onboarding Process');
    }
}