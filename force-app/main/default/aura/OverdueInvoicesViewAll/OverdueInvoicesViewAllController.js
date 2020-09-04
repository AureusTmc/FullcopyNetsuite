({
	doInit : function(component, event, helper) {
		var searchKeys = component.get("v.centerId");
    	helper.getInvoice(component, event,searchKeys);
	}
})