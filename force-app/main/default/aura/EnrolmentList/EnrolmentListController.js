({
    doInit: function(component,event,helper){
           var url='https://' +window.location.hostname;
        	component.set('v.url',url);
        
    },
	getEnrolment : function(component, event, helper) {
        var emailId = event.target.value;
         var action= component.get("c.findEnrolment");
        action.setParams({
            'email':emailId
        });
        action.setCallback(this,function(response){
            if(response.getState() =='SUCCESS'){
                component.set('v.enrolment',response.getReturnValue());
            } 
        });
        $A.enqueueAction(action);
		
	}
})