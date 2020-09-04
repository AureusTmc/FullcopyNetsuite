({
	getBooking :function(component,event,searchKeys){
        var action = component.get("c.findPendingEnrolmentCase");
        action.setParams({
          "searchKey": searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
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