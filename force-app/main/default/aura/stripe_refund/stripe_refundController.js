({
    openRefund: function(component,event,helper){
        component.set('v.isOpen',true);
    },
    cancel: function(component,event,helper){
        component.set('v.isOpen',false);
    },
	callRefund : function(component, event, helper) {
        let amount = component.get('v.amount');
        let recId = component.get("v.recordId");
        let remark = component.get('v.remark');
        console.log('remark');
        let isValid = true;
        if(!remark){
            component.find("remarkField").showHelpMessageIfInvalid();
        	isValid = false;
        }
        if(!amount){
        	component.find("amountField").showHelpMessageIfInvalid();
            isValid = false
        }
        console.log('isValid');
        if(isValid && recId){
            component.set('v.isProcessing',true);
        	let action = component.get('c.initiateRefund');
            console.log('action',action);
            action.setParams({"amount":amount,"recId":recId,"remark":remark});
            console.log('action1');
            action.setCallback(this,function(response){
                console.log('response.getState()'+response.getState());
                if(response.getState() === "SUCCESS"){
                	let result = response.getReturnValue();
                    if(result === 'success'){
                    	component.set('v.isProcessing',false);
        	    		component.set('v.isOpen',false);
    					var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type":"Success",
                            "title": "Success!",
                            "message": "Refund has been done successfully."
                        });
                        toastEvent.fire();
                    }else{
                        component.find("amountField").setCustomValidity(result);
                        component.find("amountField").reportValidity();
                        component.set('v.isProcessing',false);
        	    	}
                    console.log('result '+result);
                }else{
                    console.log('eee');
                }
            });
            $A.enqueueAction(action);
        }else{
        		component.find("amountField").showHelpMessageIfInvalid();
        }
        //initiateRefund
	}
})