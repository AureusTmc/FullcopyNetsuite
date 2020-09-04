({
    handleSelect : function (component, event,helper) {
    	var stepName = event.getParam("detail").value;
    	var action = component.get('c.updateEmployee');   
    	action.setParams({ employeeId : component.get("v.recordId") , status : stepName });
        action.setCallback(this, function(response) {
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
    }
})