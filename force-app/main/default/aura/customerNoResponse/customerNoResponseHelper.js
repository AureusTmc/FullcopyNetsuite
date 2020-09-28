({
    showToastMessage : function(component,event,toastType,message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: message,
            duration:' 5000',
            type: toastType,
            
        });
        toastEvent.fire();
        $A.get('e.force:refreshView').fire();
        component.set("v.showMODAL",false);
    }
})
