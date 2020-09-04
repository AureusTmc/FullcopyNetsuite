({
	doInit : function(component, event, helper) {
		
        var searchKeys = component.get("v.recordId");
        helper.getBooking(component,event,searchKeys);
	},
     onChangeAction: function(component,event,helper){
        component.set("v.openModal", false);
         var searchKeys = component.get("v.recordId");
        var bookingID = component.get("v.bookingID");
        var bookingAction =component.get("v.action");
            var action= component.get("c.updatePendingEnrolmentStage");
            action.setParams({
                "actVal":bookingAction,
                "bkgId":bookingID
            });
            action.setCallback(this,function(response){
                if(response.getState() == 'SUCCESS'){
                    helper.getBooking(component,event,searchKeys);
                    location.reload();
                }
            });
            $A.enqueueAction(action);
        
    },
    
     openModel: function(component, event, helper) {	
    	component.set("v.action", event.currentTarget.dataset.id);
        component.set("v.bookingID", event.currentTarget.dataset.val);
        component.set("v.openModal", true); 
    },
    
    closeModel: function(component, event, helper) { 
        component.set("v.openModal", false);
    }
})