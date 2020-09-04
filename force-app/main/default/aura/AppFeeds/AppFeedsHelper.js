({
	getAppFeeds : function(component,event,searchKeys) {
		var action = component.get("c.getAppFeedsHomePage");
        action.setParams({
          "searchKey": searchKeys,
           "FrontPage":true
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if( result == 'SUCCESS' ){
                component.set("v.totalCount",response.getReturnValue().length);
                component.set("v.AppFeeds",response.getReturnValue());
            }else{
                Alert(response.getError());
            }
        });
    	$A.enqueueAction(action);
	}
})