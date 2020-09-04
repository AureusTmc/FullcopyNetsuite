({
	searchKeyChange: function(component, event,helper) {
    	var searchKeys = event.getParam("searchKey");
        //var dateFilter='Today';
       // helper.findDate(component,event);
        helper.getBooking(component,event,searchKeys);
        
    },
    
   /* onChangeDate: function(component,event,helper)
    {
        var dateVal=component.find('select-date').get('v.value');
        var searchKeys = component.get("v.accKey");
        var action =component.get("c.findBooking");
        action.setParams({
            'dateFilter':dateVal,
            'searchKey':searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                component.set("v.Bookings", response.getReturnValue());
                component.set("v.accKey",searchKeys);
                component.set("v.dateVal",dateVal);
            }
            else{
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    onChangeAction: function(component,event,helper){
        var accId=component.get('v.accKey');
        var dateFilter=component.get('v.dateVal');
        component.set("v.openModal", false);
        var currentTarget = event.currentTarget;
        var bookingID = component.get("v.bookingID");
        var bookingAction =component.get("v.action");
            var action= component.get("c.updateStage");
            action.setParams({
                "actVal":bookingAction,
                "bkgId":bookingID,
                "searchKey":accId
            });
            action.setCallback(this,function(response){
                if(response.getState() == 'SUCCESS'){
                    helper.getBooking(component,event,accId,dateFilter);
                }
            });
            $A.enqueueAction(action);
        
    },
    openModel: function(component, event, helper) {
       component.set("v.action", event.currentTarget.dataset.id);
        component.set("v.bookingID", event.currentTarget.dataset.val);
        component.set("v.openModal", true);
    },
    
    closeModel: function(component, event, helper) { 
        component.set("v.openModal", false);
    },*/
    
    OpenMegaPage: function(Component,event,helper){
         var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:StudioBookingViewAll",
            componentAttributes: {
                centerId : Component.get("v.accKey")
            }
        });
        evt.fire();
    }
})