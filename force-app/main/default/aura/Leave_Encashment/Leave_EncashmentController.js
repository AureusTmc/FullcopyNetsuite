({       
    CalculateLeaveEncashment : function(component, event, helper){
        var Days = component.get("v.NoofDays");        
        if(typeof(Days) != 'undefined' && Days!=0){
            var action = component.get("c.CreateLeaveEncashment");       
            action.setParams({
                "PayoutId" : component.get("v.recordId"),
                "days" : Days
            });
            action.setCallback(this, function(response) {
                var state = response.getState();                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();                    
                    helper.ShowToast(component, event, helper, 'Success', 'success', 'Leave Encashment has been created.');                    
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    $A.get('e.force:refreshView').fire();                    
                }else if (state === "ERROR") {
                    var errors = response.getError(); 
                    var ErrMessage;
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        ErrMessage = errors[0].message;
                    }
                    helper.ShowToast(component, event, helper, 'Error', 'error', ErrMessage);  
                }else{
                    helper.ShowToast(component, event, helper, 'Error', 'error', 'Something went wrong.');  
                }
            });
            $A.enqueueAction(action);
        }else{
            helper.ShowToast(component, event, helper, 'Error', 'error', 'Invalid No of Days.');                        
        }
    },       
    
    showSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        $A.util.removeClass(spinner, "slds-hide");    
    },
    
    hideSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        $A.util.addClass(spinner, "slds-hide");    
    }
})