({
	doInit: function(component, event, helper) {
      helper.getAccount(component, event,helper);
        helper.getCenterId(component, event,helper);
      
   },
    searchKeyChange:function(component,event,helper)
    {
        var val=component.find("select-id").get("v.value");
        if(val)
        {
            var myEvent = $A.get("e.c:AccountKeyChange");
            myEvent.setParams({"searchKey": val});
            myEvent.fire();
        }else
        {
            $A.get('e.force:refreshView').fire();
        }

    },
    defaultLocation:function(component,event,helper){
        var location=component.find("select-id").get("v.value");
        helper.callHelperLocation(component,event,location);
        
    }
})