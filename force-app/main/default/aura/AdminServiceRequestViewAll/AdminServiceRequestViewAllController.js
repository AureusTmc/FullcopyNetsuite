({
	doInit : function(component, event, helper) {
        var SearchKeys=component.get("v.centerId");
    	helper.callCase(component, event,SearchKeys);
	},
    changeOwner:function(component,event,helper){
        var SearchKeys=component.get("v.centerId");
         var caseId=event.getSource().get("v.class");
        var action=component.get('c.updateAllNullOwner');
        action.setParams({
            "caseSalesId":caseId 
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                helper.callCase(component,event,SearchKeys);
            }
        });
        $A.enqueueAction(action);
    }
})