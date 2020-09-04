({
	doInit : function(component, event, helper) {   
        var searchKeys = component.get("v.centerId");
        //var dateFilter='Last 7 Days';
        helper.getUserProfile(component,event);
        //helper.findDate(component,event);
        helper.getBooking(component,event,searchKeys);
	}
   /* onChangeDate: function(component,event,helper)
    {
        var dateFilter=component.find('select-date').get('v.value');
        var searchKeys = component.get("v.centerId");
        helper.getBooking(component,event,searchKeys,dateFilter);
    }*/
})