({
	doInit : function(component, event, helper) {
		
        var searchKeys = component.get("v.recordId");
        //alert(searchKeys);
        helper.getCaseBooking(component,event,searchKeys);
	},
     onChangeAction: function(component,event,helper){
        component.set("v.openModal", false);
         var searchKeys = component.get("v.recordId");
        var caseId = component.get("v.caseId");
        var bookingAction =component.get("v.action");
            var action= component.get("c.updateCaseRequest");
            action.setParams({
                "actVal":bookingAction,
                "casId":caseId
            });
            action.setCallback(this,function(response){
                if(response.getState() == 'SUCCESS'){
                    helper.getCaseBooking(component,event,searchKeys);
                    location.reload();
                }
            });
            $A.enqueueAction(action);
        
    },
    
     openModel: function(component, event, helper) {	
    	component.set("v.action", event.currentTarget.dataset.id);
        component.set("v.caseId", event.currentTarget.dataset.val);
        component.set("v.openModal", true); 
    },
    
    closeModel: function(component, event, helper) { 
        component.set("v.openModal", false);
    }
})