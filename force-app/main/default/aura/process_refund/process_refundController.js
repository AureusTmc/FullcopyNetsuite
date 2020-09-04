({
	processRefund : function(component, event, helper) {
        var element = document.getElementById("confirmModal");
  		element.classList.add("slds-hide");
		let recId = component.get('v.recordId');
        component.set('v.isProcessing',true);
        let action = component.get('c.initRefund');
        action.setParams({"recId":recId});
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS"){
                let result = response.getReturnValue();
                component.set('v.isProcessing',false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"Success",
                    "title": "Success!",
                    "message": "Refund has been done successfully."
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }else{
                component.set('v.isProcessing',false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"Error",
                    "title": "Error!",
                    "message": "Refund failed."
                });
                toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
		
        
	},
    
    showConfirmModal : function(component, event, helper) {
        var element = document.getElementById("confirmModal");
  		element.classList.remove("slds-hide");
    },
    
    hideConfirmModal : function(component, event, helper) {
        var element = document.getElementById("confirmModal");
  		element.classList.add("slds-hide");
    }
})