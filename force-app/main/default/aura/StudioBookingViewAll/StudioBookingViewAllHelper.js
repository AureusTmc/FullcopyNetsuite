({
    getBooking :function(component,event,searchKeys){
        var action = component.get("c.findStudioBooking");
        action.setParams({
          "searchKey": searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                console.log("----");
                console.log(response.getReturnValue());
                component.set("v.Bookings", response.getReturnValue());
                component.set("v.accKey",searchKeys);
                //component.set("v.selvalue",'');
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})