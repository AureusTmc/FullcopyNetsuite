({
	confirmYes:function(component,event,helper){
        helper.performAction(component,event,component.get("v.recordId"));
    },
    hideModal:function(component,event,helper){
       // alert(component.get("v.showForm"));
        var cmpEvent = component.getEvent("cmpEvent");
        cmpEvent.setParams({
            "showForm" :false
        });
        cmpEvent.fire();
        
       component.set("v.showForm",false);
        component.set("v.showFormRefund",false);
        component.set("v.showModal",false);
        component.set("v.isError",false);
        /*if(event.getSource().get("v.name")=='RefundInterface'){
            component.set("v.showModal",false);
            //component.set("v.showFormRefund",true);
            var action = component.get("c.getInvoiceRefundData");
            action.setParams({
                "invoiceID":component.get("v.recordId")
            });
            action.setCallback(this,function(response){
                console.log(response.getState());
                if(response.getState()=='SUCCESS' && response.getReturnValue()[0] != null){
                    if(response.getReturnValue()[0].StripeCustomerId==''){
                        component.set("v.isDisabled",true);  
                    }
                    component.set("v.invoiceRefundRecord",response.getReturnValue()[0])
                    component.set("v.showFormRefund",true);
                }
            });
            $A.enqueueAction(action);
        }*/
    }
})