({
	searchKeyChange: function(component, event,helper) {
        var searchKeys = event.getParam("searchKey");
        console.log(searchKeys);
        helper.getInvoice(component,event,searchKeys);
        component.set("v.centerId",searchKeys);
    	
    },
    OpenMegaPage:function(component,event,helper){
         var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:OverdueInvoicesViewAll",
            componentAttributes: {
                centerId : component.get("v.centerId")
            }
        });
        evt.fire();
    }
})