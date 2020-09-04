({
	doInit: function(component, event,helper) {
    	var searchKeys = component.get("v.centerId");
        helper.getAppFeeds(component,event,searchKeys);
        
    }
})