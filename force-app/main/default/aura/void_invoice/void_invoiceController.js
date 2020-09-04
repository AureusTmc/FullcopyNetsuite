({
    confirm : function(component, event, helper) {
        component.set("v.showConfirmBox",true);
        var buttonName = event.getSource().get("v.name");
        component.set("v.processType",buttonName);
    },
    hideModal : function(component){
        component.set("v.showConfirmBox",false);
    },
    confirmYes : function(component,event,helper){
        if(component.get("v.processType") == 'void' && component.get("v.remark") == undefined){
            component.find("Remark").setCustomValidity("Fill the Remark field");
            component.find("Remark").reportValidity();
        }else{
            let recordId = component.get("v.recordId");
            let processType = component.get("v.processType");
            let remarkVal = component.get("v.remark");
            var action = component.get("c.processInvoice");
            action.setParams({invId:recordId,processType:processType,remark :remarkVal});
            action.setCallback(this,function(response){
                console.log('response.getStatus() ==>',response.getState());
                if(response.getState() === 'SUCCESS'){
                    component.set("v.showConfirmBox",false);
                    console.log('processType',processType);
                    if(processType === 'delete'){
                        let parentId = response.getReturnValue();
                        console.log(parentId);
                        window.location.href = '/'+parentId;
                    }else{
                        window.location.reload();  
                    }
                    
                }else{
                    console.log('response.getStatus() ==>',response.getState());
                }
            });
            $A.enqueueAction(action);
        }
    }
})