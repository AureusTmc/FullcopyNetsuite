trigger ExitProcessValidation on Account (before update) {
    string employeeRecordTypeId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    string teacherRecordTypeId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
    Set<Id> accIds = new Set<Id>();
    for(Account acc:Trigger.new){
        if(acc.recordTypeId==employeeRecordTypeId || acc.recordTypeId==teacherRecordTypeId){
            If(acc.Exit_Stages__c!=null && acc.Exit_Stages__c!=Trigger.oldMap.get(acc.Id).Exit_Stages__c){
                accIds.add(acc.Id);
            }        
        }
    }
    
     If(accIds.size()>0){
        Map<Id,List<Checklist_Item__c>> accToChecklistMap = new Map<Id,List<Checklist_Item__c>>();
        
        for(Checklist_Item__c ci : [Select id,Employee__c from Checklist_Item__c where Employee__c in:accIds and Due_Date__c<:system.today() and Completed__c=False and Type__c='Exit Process']){
            List<Checklist_Item__c> tempList = new List<Checklist_Item__c>();
            if(accToChecklistMap.containsKey(ci.Employee__c)){
                tempList.addAll(accToChecklistMap.get(ci.Employee__c));
            }
            tempList.add(ci);
            accToChecklistMap.put(ci.Employee__c,tempList);
        }
        
        for(Account acc:Trigger.new){
            if(accToChecklistMap.containsKey(acc.Id)){
                acc.addError('Please complete the exit overdue checklist item.');
            }
        }
    }
}