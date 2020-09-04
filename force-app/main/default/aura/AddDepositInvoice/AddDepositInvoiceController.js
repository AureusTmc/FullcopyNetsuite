({
	initialize : function(component, event, helper) {
       var enrolId= component.get("v.recordId");
        
        var action = component.get("c.getType");
        action.setParams({
            'enrolId':enrolId 
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                if(response.getReturnValue()[0].Type__c=='Trial'){
                   component.set("v.isPopup",true);
                }else{
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                        componentDef : "c:AddDepositInvoices",
                        componentAttributes: {
                            enrolId : enrolId
                        }
                    });
                    evt.fire(); 
                }  
            } 
        });
        $A.enqueueAction(action);
	},
    
    hideModal:function(component,event,helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId":component.get("v.enrolId"),
            "slideDevName": "related"
        });
        navEvt.fire();
    }
})