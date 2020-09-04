({
	 getAppFeeds :function(component,event,searchKeys){
        var action = component.get("c.getAppFeeds");
        action.setParams({
          "searchKey": searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                console.log("----");
                console.log(response.getReturnValue());
                component.set("v.AppFeeds", response.getReturnValue());
                component.set("v.accKey",searchKeys);
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})