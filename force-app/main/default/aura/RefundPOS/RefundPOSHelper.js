({
	 performbankTrnsfrAction:function(component,event,invId,Name,val){
        if(Name=='Bank Transfer' && invId != null){
            component.set("v.isBankTrnsfr",val);
            component.set("v.isOfflineCard",false);
            component.set("v.isCardOnFile",false);  
        }else if (Name=='Offline Card' && invId != null){
             component.set("v.isOfflineCard",val);
            component.set("v.isCardOnFile",false); 
            component.set("v.isBankTrnsfr",false);
        }else if(Name=='Card On file' && invId != null){
            component.set("v.isCardOnFile",val);  
            component.set("v.isBankTrnsfr",false);
            component.set("v.isOfflineCard",false);
        }
        
    },
    
    saveAction:function(component,event,invId,Name){
        if((Name=='Bank Transfer' || Name=='Offline Card') && invId != null){
            var action = component.get("c.performBankTrnsfrAct");
            action.setParams({
                "invoiceID":invId
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS' && response.getReturnValue()=='SUCCESS'){
                    component.set("v.showFormRefund",false);
                    component.set("v.isBankTrnsfr",false);
                    component.set("v.isError",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Invoice voided and payment Successfully refunded.',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    var cmpEvent = component.getEvent("cmpEvent");
                    cmpEvent.setParams({
                        "showFormRefund" :false
                    });
                    cmpEvent.fire();
                }else{
                    component.set("v.Exception",true);
                    component.set("v.exceptionMessage",response.getReturnValue());
                }
            });
            $A.enqueueAction(action);
        }else if(Name=='Card On file' && invId != null){
            var action = component.get("c.perfrmCardAction");
            action.setParams({
                "invoiceID":invId
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS' && response.getReturnValue()=='SUCCESS'){
                    component.set("v.showFormRefund",false);
                    component.set("v.isCardOnFile",false);
                    component.set("v.isError",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Invoice voided and payment Successfully refunded.',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    var cmpEvent = component.getEvent("cmpEvent");
                    cmpEvent.setParams({
                        "showFormRefund" :false
                    });
                    cmpEvent.fire();
                }else{
                    component.set("v.Exception",true);
                    component.set("v.exceptionMessage",response.getReturnValue());
                }
            });
            $A.enqueueAction(action);
        } 
        
    }
})