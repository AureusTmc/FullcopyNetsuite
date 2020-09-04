({
	doInit : function(component, event, helper) {
		var accId = component.get("v.recordId");
        
        if(accId != null && accId != ''){
            var action = component.get('c.getCurrentLeaveEntitlement');
            action.setParams({ recId : accId });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS"){
                    component.set('v.leaveEntObj', response.getReturnValue());
                }
                else if(state === "ERROR"){
                    var errors = response.getError();
                    if(errors){
                        if(errors[0] && errors[0].message){
                            console.log("Error message: " + errors[0].message);
                        }
                    }else{
                        console.log("Unknown error");
                    }
                }
        	});
        	$A.enqueueAction(action);
        }
	}
})