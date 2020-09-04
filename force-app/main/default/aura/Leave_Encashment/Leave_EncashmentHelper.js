({
	 ShowToast : function(component, event, helper, title, type, msg){        
        var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : title,
                message: msg,
                messageTemplate: '',
                duration:'7000',
                key: 'info_alt',
                type: type,
                mode: 'dismissible'
            });
            toastEvent.fire();
    }
})