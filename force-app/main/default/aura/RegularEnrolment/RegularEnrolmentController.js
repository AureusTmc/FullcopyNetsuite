({
	searchKeyChange : function(component, event, helper) {
        var searchKeys = event.getParam("searchKey");
        var dateFilter='Last 7 Days';
        helper.findDate(component,event);
        helper.getBooking(component,event,searchKeys,dateFilter);
	},
    onChangeDate: function(component,event,helper)
    {
        var dateFilter=component.find('select-date').get('v.value');
        var searchKeys = component.get("v.accKey");
        helper.getBooking(component,event,searchKeys,dateFilter);
    },
     OpenMegaPage:function(component,event){
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:RegularViewAll",
            componentAttributes: {
                centerId : component.get("v.accKey"),
                selvalue:'Last 7 Days'
            }
        });
        evt.fire(); 
    }
})