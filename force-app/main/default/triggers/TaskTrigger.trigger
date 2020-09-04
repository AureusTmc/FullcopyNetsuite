trigger TaskTrigger on Task (before insert) {
	if(trigger.isBefore){
        
        if(trigger.isInsert){
           // This trigger is updating the Name of task with the personAccount name in Case 
			TaskTriggerHelper.UpdateName(Trigger.new);            
        }
    }
}