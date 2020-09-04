({
	 performAction: function(component,event,invoiceID){
        var action = component.get("c.peformActionInvoice");
        action.setParams({
            "invoiceID":invoiceID
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS' && response.getReturnValue() =='SUCCESS'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'SUCCESS',
                    message: 'Invoice voided and payment as credit given Successfully',            
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'SUCCESS',
                    mode: 'pester'
                });
                toastEvent.fire();
                var cmpEvent = component.getEvent("cmpEvent");
                cmpEvent.setParams({
                    "showForm" :false
                });
                cmpEvent.fire();
               // component.set("v.showForm",false);
            }else{
                component.set("v.Exception",true);
                component.set("v.exceptionMessage",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})