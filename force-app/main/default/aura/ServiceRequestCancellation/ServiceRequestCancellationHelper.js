({
	getCaseBooking :function(component,event,searchKeys){
        var action = component.get("c.findCase");
        action.setParams({
          "searchKey": searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            //alert(result);
            if(result == 'SUCCESS' && response.getReturnValue()[0] != null){
                component.set("v.Bookings", response.getReturnValue());
                component.set("v.recordId",searchKeys);
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})