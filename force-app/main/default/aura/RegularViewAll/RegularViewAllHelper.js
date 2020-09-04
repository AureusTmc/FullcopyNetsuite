({
    findDate : function(comp,event) {                
        var action = comp.get("c.findDateList");
        action.setCallback(this,function(response){
            var result = response.getState();
            if(result == 'SUCCESS')
            {                
                comp.set('v.dateList',response.getReturnValue());
            }else
            {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
        
    },
    getBooking :function(component,event,searchKeys,dateFilter){
        var action = component.get("c.findRegularBooking");
        action.setParams({
          "searchKey": searchKeys,
           "dateFilter":dateFilter
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                console.log('====Regular Booking>'+response.getReturnValue().length);
                console.log(response.getReturnValue());
                component.set("v.totalCount", response.getReturnValue().length);
                component.set("v.Bookings", response.getReturnValue());
                component.set("v.centerId",searchKeys);
                component.set("v.dateVal",dateFilter);
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})