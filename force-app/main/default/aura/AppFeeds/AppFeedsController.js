({
	searchKeyChange: function(component, event,helper) {
        var searchKeys = event.getParam("searchKey");
        helper.getAppFeeds( component, event, searchKeys );
        component.set( "v.centerId", searchKeys );
    	
    },
    OpenMegaPage:function(component,event,helper){
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:AppFeedsViewAll",
            componentAttributes: {
                centerId : component.get("v.centerId")
            }
        });
        evt.fire();
    }
})