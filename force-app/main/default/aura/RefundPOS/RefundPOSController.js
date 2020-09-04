({
    
    changeVal:function(component,event,helper){
        helper.performbankTrnsfrAction(component,event,component.get("v.recordId"),event.getSource().get("v.label"),event.getSource().get("v.checked"));    
        
    },
    
    Save:function(component,event,helper){
       /* if(component.get("v.isBankTrnsfr")== true){
            helper.saveAction(component,event,component.get("v.recordId"),'Bank Transfer');
        }else if(component.get("v.isCardOnFile")== true){
            helper.saveAction(component,event,component.get("v.recordId"),'Card On file');
        }else if(component.get("v.isOfflineCard")== true){
            component.set("v.showModal",true);
            component.set("v.isChildForm",false);   
        }else{
            component.set("v.isError",true);
        }*/
        
        if(component.get("v.isCardOnFile")== true){
            helper.saveAction(component,event,component.get("v.recordId"),'Card On file');
        }else if(component.get("v.isOfflineCard")== true || component.get("v.isBankTrnsfr")== true){
            component.set("v.showModal",true);
            component.set("v.isChildForm",false);   
        }else{
            component.set("v.isError",true);
        }
        
    },
    SaveConfirm:function(component,event,helper){
        var slcdType = component.get("v.isOfflineCard") ? 'Offline Card' : 'Bank Transfer';
        helper.saveAction(component,event,component.get("v.recordId"),slcdType);
    },
    hideModal:function(component,event,helper){
        component.set("v.Exception",false);
        component.set("v.isError",false);
        component.set("v.isChildForm",true); 
        if(event.getSource().get("v.name")=='RefundInterface'){
            component.set("v.showModal",false);
            //component.set("v.showFormRefund",true);
            var action = component.get("c.getInvoiceRefundData");
            action.setParams({
                "invoiceID":component.get("v.recordId")
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS' && response.getReturnValue()[0] != null){
                    //if(response.getReturnValue()[0].StripeCustomerId==''){
                       // component.set("v.isDisabled",true);  
                   // }
                    component.set("v.invoiceRefundRecord",response.getReturnValue()[0])
                   
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    hideModalRefund:function(component,event,helper){
        component.set("v.Exception",false);
         var cmpEvent = component.getEvent("cmpEvent");
        cmpEvent.setParams({
            "showFormRefund" :false
        });
        cmpEvent.fire();
        component.set("v.isError",false);
    }
})