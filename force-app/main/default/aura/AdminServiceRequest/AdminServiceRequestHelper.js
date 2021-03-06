({
	callCases : function(component, event,searchKeys) {
		var action = component.get("c.findAllNullCases");
        action.setParams({
            'searchKeys':searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                component.set("v.totalCount",response.getReturnValue().length);
                var total=response.getReturnValue().length;
                for(var i=0;i<total;i++){
                    if( response.getReturnValue()[i].OwnerId.substring(0, 3)=='00G'){
                        response.getReturnValue()[i].checkBoxValue='00G';
                    }else{
                        response.getReturnValue()[i].checkBoxValue='00S';
                    }
                    
                }
                
                component.set("v.Cases", response.getReturnValue());
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
	}
})