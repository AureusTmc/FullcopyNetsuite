({
   /* findDate : function(comp,event) {                
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
        
    },*/
    getUserProfile:function(component,event){
        var action = component.get("c.findUserprofile");
        
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS' && response.getReturnValue()[0].Profile.Name == 'System Administrator'){
                component.set("v.Userprofile", true);
            }
            else{
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    getBooking :function(component,event,searchKeys){
        var action = component.get("c.findMakeUpBooking");
        action.setParams({
          "searchKey": searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                console.log('====Regular Booking>'+response.getReturnValue().length);
                console.log(response.getReturnValue());
                component.set("v.totalCount", response.getReturnValue().length);
                component.set("v.Bookings", response.getReturnValue());
                component.set("v.centerId",searchKeys);
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})