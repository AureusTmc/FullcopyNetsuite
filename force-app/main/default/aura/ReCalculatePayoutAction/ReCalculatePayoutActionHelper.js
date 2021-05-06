({
	getCalculate : function(component,event) {
        var action = component.get("c.getCalculatePayout");
        action.setParams({
            'payoutId': component.get("v.recordId"),
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS" && response.getReturnValue()!= null){
                if(response.getReturnValue() == true){
                    console.log('response.getReturnValue()',response.getReturnValue());
                    //commeted by nishi: 6may:2021:this.showToast(component, event, 'Success!', 'The record has been calculated successfully.', 'success');
                   //added by nishi : 6-may-2021: for Calculate teacher tiered working hrs
                    this.calculatePayoutTeacherTieredHrs(component, event);
                    //added by nishi : 6-may-2021: for Calculate teacher tiered working hrs
                }else{
                    this.showToast(component, event, 'Error!', 'Something went wrong, please try again.', 'error');
                    $A.get('e.force:refreshView').fire();
                    this.dismissAction(component,event);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    dismissAction:function(component,event){
        $A.get("e.force:closeQuickAction").fire(); 
    },
    showToast : function(component, event, title, msg, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": msg,
            "type": type
        });
        toastEvent.fire();
    },
    //added by nishi : 6-may-2021: for Calculate teacher tiered working hrs
    calculatePayoutTeacherTieredHrs : function(component,event) {
        var action = component.get("c.getCalculatePayoutTeacherTieredHrs");
        console.log('response.getReturnValue()-->');
        action.setParams({
            'payoutId': component.get("v.recordId"),
        });
        action.setCallback(this,function(response){
            console.log('response.getState()-->',response.getState());
            console.log('response.getReturnValue()-->',response.getReturnValue());
            if(response.getState()=="SUCCESS" && response.getReturnValue()!= null){
                if(response.getReturnValue() == true){
                    console.log('response.getReturnValue()-->',response.getReturnValue());
                   this.showToast(component, event, 'Success!', 'The record has been calculated successfully.', 'success');
                }else{
                    this.showToast(component, event, 'Error!', 'Something went wrong, please try again.', 'error');
                }
                $A.get('e.force:refreshView').fire();
                this.dismissAction(component,event);
            }
        });
        
        $A.enqueueAction(action);
    }
})