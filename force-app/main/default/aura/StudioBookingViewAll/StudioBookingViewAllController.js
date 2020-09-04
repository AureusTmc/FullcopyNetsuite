({
	doInit: function(component, event,helper) {
    	var searchKeys = component.get("v.centerId");
        helper.getBooking(component,event,searchKeys);
        
    }
})