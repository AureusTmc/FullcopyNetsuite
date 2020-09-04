({
	getInvoice : function(component,event,searchKeys) {
    	var action = component.get("c.findInvoices");
        action.setParams({
          "searchKey": searchKeys,
           "FrontPage":false
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                component.set("v.Invoices", response.getReturnValue());
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
		
	}
})