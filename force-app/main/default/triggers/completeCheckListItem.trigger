trigger completeCheckListItem on Task (after update) {
    Set<Id> whatIds = new Set<Id>();
    for(Task tsk:Trigger.New){
        if(tsk.status=='Completed' && tsk.status!=Trigger.oldMap.get(tsk.Id).status){
            whatIds.add(tsk.whatId);
        }
    }
    
    Map<Id,Checklist_Item__c> checklistMap = new Map<Id,Checklist_Item__c>([Select id,Completed__c,Notes__c from Checklist_Item__c where Id in:whatIds]);
    
    List<Checklist_Item__c> checkItemList = new List<Checklist_Item__c>();
    for(Task tsk:Trigger.New){
        if(tsk.status=='Completed' && tsk.status!=Trigger.oldMap.get(tsk.Id).status){
            if(checklistMap.containsKey(tsk.whatId)){
                Checklist_Item__c ci = new Checklist_Item__c();
                ci = checklistMap.get(tsk.whatId);
                ci.Completed__c = true;
                ci.Notes__c = tsk.Description;
                checkItemList.add(ci);
            }
        }
    }
    update checkItemList;
}