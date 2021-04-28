({
	doInit : function(component, event, helper) {
		var searchKeys = component.get("v.centerId");
       helper.callSalesCase(component, event,searchKeys);
	},
    changeOwner:function(component,event,helper){
         var caseId=event.getSource().get("v.class");
        var searchKeys=component.get('v.centerId');
        var action=component.get('c.updateOwner');
        action.setParams({
            "caseSalesId":caseId 
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                helper.callSalesCase(component,event,searchKeys);
            }
        });
        $A.enqueueAction(action);
    }
})