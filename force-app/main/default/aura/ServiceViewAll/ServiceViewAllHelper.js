({
	callSalesCase : function(component, event,searchKeys) {
		var action = component.get("c.findCases");
        action.setParams({
          "searchKey": searchKeys
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                var total=response.getReturnValue().length;
                for(var i=0;i<total;i++){
                    if( response.getReturnValue()[i].OwnerId.substring(0, 3)=='00G'){
                        response.getReturnValue()[i].checkBoxValue='00G';
                    }else{
                        response.getReturnValue()[i].checkBoxValue='00S';
                    }
                    console.log(response.getReturnValue()[i]);
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