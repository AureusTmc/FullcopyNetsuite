public class TaskTriggerHelper {
	public static void UpdateName(List<Task> taskList){
        // This trigger is updating the Name of task with the personAccount name in Case
        set<id> caseIdsSet = new set<id>();
        for(Task tskObj:taskList){
            if(tskObj.WhatId != null && tskObj.WhoId == null)
               caseIdsSet.add(tskObj.WhatId);
        }
        Map<Id,Case> mapCase = new Map<Id,Case>([SELECT Id,Account.PersonContactId 
                                                     FROM Case 
                                                     WHERE Id IN : caseIdsSet AND Account.PersonContactId != null]);
        
        for(Task tskObj:taskList){
            if(mapCase.ContainsKey(tskObj.WhatId) && tskObj.WhoId == null)
               tskObj.WhoId = mapCase.get(tskObj.WhatId).Account.PersonContactId; 
        } 
    }
}