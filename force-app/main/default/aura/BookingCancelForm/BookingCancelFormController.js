({
	initialize : function(component, event, helper) {
       var enrolId= component.get("v.recordId");
		 var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:BookingCancellationForm",
            componentAttributes: {
                enrolId : enrolId
            }
        });
        evt.fire();
	}
})