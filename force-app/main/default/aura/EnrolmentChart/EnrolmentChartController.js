({	
	doInit: function(cmp, event, helper) {
        var temp = [];
        var temp2 = [];
         var searchKeys = cmp.get("v.searchKey");
        if(searchKeys){
            var action = cmp.get("c.getChartMap");
            action.setParams({
                "searchKey": searchKeys
            });
            action.setCallback(this, function(response){
                if(response.getState() === 'SUCCESS' && response.getReturnValue()){
                    temp = response.getReturnValue();
                    helper.createGraph(cmp, temp);
                }
            });  
            $A.enqueueAction(action);
        }
	}
})