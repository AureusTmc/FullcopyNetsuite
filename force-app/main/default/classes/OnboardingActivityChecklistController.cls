public class OnboardingActivityChecklistController{
    
    public static string validate(List<masterCheckList_wrp> masterList){
        String retVal = '';
        String selectOneError = 'Please select at least one activity to save.';
        String selectDateError = '';
        system.debug('@masterList --'+masterList);
        for(masterCheckList_wrp acw : masterList){
            system.debug('@@@@acw.isChecked -----'+acw.isChecked);
            system.debug('@@@@acw'+acw);
            if(acw.isChecked){
                selectOneError  = '';
                system.debug('@@@@masterList'+masterList);
                system.debug('acw.Checklist_Item.Due_Date__c==='+acw.Checklist_Item.Due_Date__c);
                system.debug('acw.oldDate==='+acw.oldDate);
                if(acw.Checklist_Item.Due_Date__c < Date.Today() && (acw.oldDate==null || acw.oldDate != acw.Checklist_Item.Due_Date__c)){
                    selectDateError = 'Checklist Activity - Due date must be greater then today, for selected Activities.';
                }
            }
        }
        if(String.isNotBlank(selectOneError)) return selectOneError;
        if(String.isNotBlank(selectDateError )) return selectDateError ;
        return retVal ;
    }
    @AuraEnabled
    public static String generateCheckListItems( String masterLists, String masterExitLists, String EmployeeId, Account Employee, String masterDocumentLists, Boolean isSaveAs, String saveAsName, String mType){
        List<masterCheckList_wrp> masterList = (List<masterCheckList_wrp>)JSON.deserialize(masterLists, List<masterCheckList_wrp>.class);
        List<masterCheckList_wrp> masterExitList = (List<masterCheckList_wrp>)JSON.deserialize(masterExitLists, List<masterCheckList_wrp>.class);
        List<masterDocument_wrp> masterDocumentList = (List<masterDocument_wrp>)JSON.deserialize(masterDocumentLists, List<masterDocument_wrp>.class);
        Map<Id,Checklist_Item__c> existingCheckListMap = getExistingOBCheckListItem(EmployeeId);
        Map<Id,Checklist_Item__c> existingExitCheckListMap = getExistingExitCheckListItem(EmployeeId);
        Map<Id,Task> existingTaskMap = getExistingTask(existingCheckListMap );
        system.debug('@@@masterLists'+masterLists);
        string errorMsg = '';
        if(mType.equalsignorecase('Onboarding Process')){
        	errorMsg = validate(masterList);
        }else{
        	errorMsg = validate(masterExitList);    
        }
        
        if(String.isBlank(errorMsg)){
            List<Checklist_Item__c > upsertChecklistItemList = new List<Checklist_Item__c > ();
            List<Checklist_Item__c > deleteChecklistItemList = new List<Checklist_Item__c > ();
            List<Checklist_Item__c > ctaList = new List<Checklist_Item__c >();
            for(masterCheckList_wrp acw : masterList){
                if(acw.isChecked){
                    upsertChecklistItemList.add(acw.checklist_Item);
                    if(mType.equalsignorecase('Onboarding Process')) ctaList.add(acw.checklist_Item);
                }else if((!acw.isChecked) && existingCheckListMap.containsKey(acw.master_check.Id)){
                    if(mType.equalsignorecase('Onboarding Process')) deleteChecklistItemList.add(acw.checklist_Item);
                }
            }
            for(masterCheckList_wrp acw : masterExitList){
                if(acw.isChecked){
                    upsertChecklistItemList.add(acw.checklist_Item);
                    if(mType.equalsignorecase('Exit Process')) ctaList.add(acw.checklist_Item);
                }else if((!acw.isChecked) && existingExitCheckListMap.containsKey(acw.master_check.Id)){
                    if(mType.equalsignorecase('Exit Process')) deleteChecklistItemList.add(acw.checklist_Item);
                }
            }
            
            // create template for this mapping
            if(isSaveAs){
                if(String.isBlank(saveAsName)){
                    return 'Required field missing. - [Template Name]';
                }
                Checklist_Template__c template = new Checklist_Template__c(
                    Name = saveAsName,
                    Type__c = mType
                );
                Insert template;
                List<Checklist_Template_Activity__c> tiList = new List<Checklist_Template_Activity__c>();
                for(Checklist_Item__c ci : ctaList){
                    tiList.add(new Checklist_Template_Activity__c(Checklist_Template__c = template.Id , Checklist_Master__c = ci.Checklist_Master__c));
                }
                if(!tiList.isEmpty()){
                    insert tiList;
                }
            }
            
            if(!upsertChecklistItemList.isEmpty()){
                upsert upsertChecklistItemList;
                                          
                List<Task> upsertTaskList = new List<Task> ();
                for(Checklist_Item__c ci : upsertChecklistItemList){
                    Task tk = new Task(
                        Subject = ci.Activity_Name__c,
                        ActivityDate = ci.Due_Date__c,
                        OwnerId = UserInfo.getUserId(),
                        WhatId = ci.Id,
                        Description = ci.Activity_Name__c,
                        Priority = 'Normal',
                        Status = 'Open',
                        IsReminderSet = true,
                        Type='Other'
                    );
                    if(existingTaskMap.containsKey(ci.Id)) tk.Id = existingTaskMap.get(ci.Id).Id;
                    upsertTaskList.add(tk);
                    
                    if(!upsertTaskList.isEmpty()){
                        upsert upsertTaskList;
                    }
                }
            }
            
            if(!deleteChecklistItemList.isEmpty()){
                delete deleteChecklistItemList;
            }
            List<Employee_Document__c> upsertDocumentItemList = new List<Employee_Document__c> ();
            List<Employee_Document__c> deleteDocumentItemList = new List<Employee_Document__c> ();
            for(masterDocument_wrp adw : masterDocumentList){
                if(adw.isChecked){
                    Employee_Document__c ed = new Employee_Document__c(
                        Name = adw.documentName,
                        Document__c = adw.documentId,
                        Employee__c = EmployeeId,
                        Required__c = adw.isRequired,
                        Stage__c = adw.onBoardingStatge
                    );
                    if(String.isNotBlank(adw.eDocumentId)) ed.Id= adw.eDocumentId;
                    upsertDocumentItemList.add(ed);
                }else if((!adw.isChecked) && String.isNotBlank(adw.eDocumentId)){
                    deleteDocumentItemList.add(new Employee_Document__c(
                        Id = adw.eDocumentId
                    ));
                }
            }
            if(!upsertDocumentItemList.isEmpty()){
                upsert upsertDocumentItemList;
            }
            if(!deleteDocumentItemList.isEmpty()){
                delete deleteDocumentItemList;
            }
            if(Employee != null){
                Account employeeUpdate = new Account(Id=Employee.Id);
                if(mType.equalsignorecase('Onboarding Process')){
                    employeeUpdate.Joining_Date__c = Employee.Joining_Date__c;
                }
                if(mType.equalsignorecase('Exit Process')){
                    employeeUpdate.Last_Working_Date__c = Employee.Last_Working_Date__c;
                    employeeUpdate.Exit_Type__c = employee.Exit_Type__c;
                    employeeUpdate.Exit_Stages__c = 'Initiated';
                }
                update employeeUpdate;
            }
        }
        return errorMsg;
    }
    
    public Static Map<Id,Checklist_Item__c> getExistingOBCheckListItem(String employeeId){
        Map<Id,Checklist_Item__c> returnMap = new Map<Id,Checklist_Item__c>();
        for(Checklist_Item__c ci: [SELECT Id,Name,Checklist_Master__c,Due_Date__c,Activity_Name__c,Type__c FROM Checklist_Item__c WHERE Employee__c = : employeeId AND Type__c = 'Onboarding Process']){
            returnMap.put(ci.Checklist_Master__c,ci);
        }
        return returnMap;
    }
    
    public Static Map<Id,Checklist_Item__c> getExistingExitCheckListItem(String employeeId){
        Map<Id,Checklist_Item__c> returnMap = new Map<Id,Checklist_Item__c>();
        for(Checklist_Item__c ci: [SELECT Id,Name,Checklist_Master__c,Due_Date__c,Activity_Name__c,Type__c FROM Checklist_Item__c WHERE Employee__c = : employeeId AND Type__c = 'Exit Process']){
            returnMap.put(ci.Checklist_Master__c,ci);
        }
        return returnMap;
    }
    
    public Static Map<Id,Task> getExistingTask(Map<Id,Checklist_Item__c> existingCheckListMap){
        Map<Id,Task> returnMap = new Map<Id,Task>();
        for(Task tsk: [SELECT Id,ActivityDate,Priority,Status ,Subject, Type, WhatId FROM Task WHERE WhatId IN : existingCheckListMap.values()]){
            returnMap.put(tsk.WhatId ,tsk);
        }
        return returnMap;
    }
    
    public static Date convertToDate(String dt){
        try{
            return Date.ValueOf(dt);
        }catch(exception e){}
        return Date.Today();
    }
    @AuraEnabled
    public Static List<Id> getMasterCheckListItemByTemplate(String templateId){
        List<Id> retList = new List<Id>();
        for(Checklist_Template_Activity__c  cta: [SELECT Id, Checklist_Master__c FROM Checklist_Template_Activity__c WHERE Checklist_Template__c = : templateId]){
            retList.add(cta.Checklist_Master__c);
        }
        return retList ;
    }
    
    
    @AuraEnabled
    public static Data_wrp getMasterCheckList(String EmployeeId , String DateOfJoining, Boolean isJoining){
        Map<Id,Checklist_Item__c> existingCheckListMap = getExistingOBCheckListItem(EmployeeId);
        Map<Id,Checklist_Item__c> existingExitCheckListMap = getExistingExitCheckListItem(EmployeeId);
        
        Map<Id,Task> existingTaskMap = getExistingTask(existingCheckListMap );
        system.debug('DateOfJoining !!!! '+DateOfJoining);
        Date convertedDate = convertToDate(DateOfJoining);
        List<masterCheckList_wrp> returnList = new List<masterCheckList_wrp>();
        List<masterCheckList_wrp> returnExitList = new List<masterCheckList_wrp>();
        for(Checklist_Master__c cm: [SELECT Id, Activity_Name__c, Name, Type__c, X_days_before_Joining_Exit_Date__c FROM  Checklist_Master__c WHERE Type__c = 'Onboarding Process' ORDER BY Activity_Name__c ASC]){
            // for Onboarding
            Boolean isChecked = false;
            Checklist_Item__c checkItem = new Checklist_Item__c(
                Checklist_Master__c = cm.Id,
                Activity_Name__c = cm.Activity_Name__c,
                Due_Date__c = convertedDate,
                Type__c = cm.Type__c,
                Employee__c = EmployeeId
            );
            if(existingCheckListMap.containsKey(cm.Id)){
                isChecked = true;
                checkItem.Id = existingCheckListMap.get(cm.Id).Id;
                checkItem.Due_Date__c = existingCheckListMap.get(cm.Id).Due_Date__c;
            }
            Integer xDays = (Integer) cm.X_days_before_Joining_Exit_Date__c;
            if(xDays != null && String.isBlank(checkItem.Id)){
                if(xDays > 0 ) xDays = (xDays * -1);
                checkItem.Due_Date__c = checkItem.Due_Date__c.addDays(xDays);
            }
            returnList.add(new masterCheckList_wrp(cm, isChecked, checkItem));
        }
        for(Checklist_Master__c cm: [SELECT Id, Activity_Name__c, Name, Type__c, X_days_before_Joining_Exit_Date__c FROM  Checklist_Master__c WHERE Type__c = 'Exit Process' ORDER BY Activity_Name__c ASC]){
            // for Exit
            Boolean isChecked = false;
            Checklist_Item__c checkItem = new Checklist_Item__c(
                Checklist_Master__c = cm.Id,
                Activity_Name__c = cm.Activity_Name__c,
                Due_Date__c = convertedDate,
                Type__c = cm.Type__c,
                Employee__c = EmployeeId
            );
            if(existingExitCheckListMap.containsKey(cm.Id)){
                isChecked = true;
                checkItem.Id = existingExitCheckListMap.get(cm.Id).Id;
                checkItem.Due_Date__c = existingExitCheckListMap.get(cm.Id).Due_Date__c;
            }
            Integer xDays = (Integer) cm.X_days_before_Joining_Exit_Date__c;
            if(xDays != null && String.isBlank(checkItem.Id)){
                if(xDays > 0 ) xDays = (xDays * -1);
                checkItem.Due_Date__c = checkItem.Due_Date__c.addDays(xDays);
            }
            returnExitList.add(new masterCheckList_wrp(cm, isChecked, checkItem));
        }
        
        List<Account> accountList = [SELECT Id, Name,Status__c,Joining_Date__c,Last_Working_Date__c,Employee_Status__c, Contract_End_Date__c,Exit_Type__c,Notice_Period__c FROM Account WHERE Id = : EmployeeId];
        Account employee = new Account();
        if(!accountList.isEmpty()){
            employee = accountList.get(0);
        }
        Map<Id,Documents__c> documentMap = new Map<Id,Documents__c> ([select id,Name from Documents__c ORDER By Name]);  
        map<id,masterDocument_wrp> masterDocumentmap = new map<id,masterDocument_wrp>();
        for(Id key : documentMap.keyset()){
            masterDocument_wrp mdw = new masterDocument_wrp(documentMap.get(key).name, false, false, '', documentMap.get(key).Id,'');
            masterDocumentmap.put(key,mdw);
        }
        
        for(Employee_Document__c ed : [select id , Required__c,Employee__r.name, Employee__r.Onboarding_Stage__c,Stage__c, 
                                       Document__c, Employee__c from Employee_Document__c where Employee__c =: EmployeeId ]){
           if(masterDocumentmap.containsKey(ed.Document__c)){
               string doc_name = documentMap.get(ed.Document__c).name;
               masterDocument_wrp mdw = new masterDocument_wrp(doc_name, true, ed.Required__c, ed.Stage__c, documentMap.get(ed.Document__c).Id, ed.Id);
               masterDocumentmap.put(ed.Document__c,mdw);
           }
        }
        if(employee.Joining_Date__c != null && String.isBlank(DateOfJoining) && isJoining) convertedDate = employee.Joining_Date__c;
        else if(String.isNotBlank(DateOfJoining) && isJoining) employee.Joining_Date__c = convertedDate;
        
        if(String.isNotBlank(DateOfJoining) && !isJoining) employee.Last_Working_Date__c = convertedDate;
        if(employee.Notice_Period__c != null && employee.Last_Working_Date__c == null){
            employee.Last_Working_Date__c = date.today().addMonths(Integer.valueOf(employee.Notice_Period__c));
        }else if(employee.Last_Working_Date__c == null){
            employee.Last_Working_Date__c = date.today();
        }
        return new Data_wrp(returnList, employee.Joining_Date__c ,employee,  masterDocumentmap.values(), returnExitList) ;
    }
    
    public class Data_wrp{
        @AuraEnabled
        public List<masterCheckList_wrp> masterListData;
        @AuraEnabled
        public List<masterCheckList_wrp> masterListExitData;
        @AuraEnabled
        public List<masterDocument_wrp> masterDocumentListData;
        @AuraEnabled
        public Date EmployeeJoiningDate ;
        @AuraEnabled
        public Account Employee;
        @AuraEnabled
        public List<String> EmployeeStageValues;
        @AuraEnabled
        public List<String> exitTypeList;
        @AuraEnabled
        public List<SelectOptionCustum> CheckListItemTemplateOnBoarding;
        @AuraEnabled
        public List<SelectOptionCustum> CheckListItemTemplateExit;
        
        public Data_wrp(List<masterCheckList_wrp> masterListData , Date EmployeeJoiningDate, Account Employee, list<masterDocument_wrp> masterDocumentListData, List<masterCheckList_wrp> masterListExitData){
            this.masterListData = masterListData;
            this.EmployeeJoiningDate = EmployeeJoiningDate;
            this.Employee = Employee;
            this.masterDocumentListData = masterDocumentListData ;
            this.masterListExitData = masterListExitData;
            this.EmployeeStageValues = getPickListValuesIntoList();
            this.CheckListItemTemplateExit = getCheckListItemTemplateExit();
            this.CheckListItemTemplateOnBoarding = getCheckListItemTemplateOnBoarding();
            this.exitTypeList = getExitTypeIntoList();
        }
        public List<SelectOptionCustum> getCheckListItemTemplateOnBoarding(){
            List<SelectOptionCustum> retList = new List<SelectOptionCustum>();
            for(Checklist_Template__c ct: [SELECT Id, Name FROM Checklist_Template__c WHERE Type__c = 'Onboarding Process']){
                retList.add(new SelectOptionCustum(ct.Id,ct.Name));
            }
            return retList ;
        }
        public List<SelectOptionCustum> getCheckListItemTemplateExit(){
            List<SelectOptionCustum> retList = new List<SelectOptionCustum>();
            for(Checklist_Template__c ct: [SELECT Id, Name FROM Checklist_Template__c WHERE Type__c = 'Exit Process']){
                retList.add(new SelectOptionCustum(ct.Id,ct.Name));
            }
            return retList ;
        }
        
        public List<String> getPickListValuesIntoList(){
            List<String> pickListValuesList= new List<String>();
            Schema.DescribeFieldResult fieldResult = Employee_Document__c.Stage__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }     
            return pickListValuesList;
        }
        public List<String> getExitTypeIntoList(){
            List<String> pickListValuesList= new List<String>();
            Schema.DescribeFieldResult fieldResult = Account.Exit_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }     
            return pickListValuesList;
        }
    }
    public class SelectOptionCustum{
        @AuraEnabled
        public string value;
        @AuraEnabled
        public string label;
        public SelectOptionCustum(string value, string label){
            this.value = value;
            this.label = label;
        }
    }
    
    public class masterDocument_wrp{
        @AuraEnabled
        public string documentName ;
        @AuraEnabled
        public Boolean isChecked;
        @AuraEnabled
        public Boolean isRequired;
        @AuraEnabled
        public String onBoardingStatge;
        @AuraEnabled
        public String documentId;
        @AuraEnabled
        public String eDocumentId;
        
        public masterDocument_wrp(string documentName, Boolean isChecked, Boolean isRequired, String onBoardingStatge, String documentId, String eDocumentId){
            this.documentName = documentName;
            this.isChecked = isChecked;
            this.isRequired = isRequired;
            this.onBoardingStatge = onBoardingStatge;
            this.documentId = documentId;
            this.eDocumentId = eDocumentId;
        }
    }
    
    public class masterCheckList_wrp{
        @AuraEnabled
        public Checklist_Master__c master_check ;
        @AuraEnabled
        public Boolean isChecked;
        @AuraEnabled
        public Date oldDate;
        @AuraEnabled
        public Checklist_Item__c checklist_Item {get;set;}
        
        public masterCheckList_wrp(Checklist_Master__c master_check, Boolean isChecked, Checklist_Item__c checklist_Item){
            this.master_check = master_check;
            this.oldDate = checklist_Item.Due_Date__c ;
            this.isChecked = isChecked;
            this.checklist_Item = checklist_Item;
        }
    }
}