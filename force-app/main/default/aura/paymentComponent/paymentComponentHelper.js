({
	helperMethod : function() {
		
	},
    getCurrentCredit:function (component, event) {
        let recordId = component.get("v.recordId");
    	var getCurrentCredit = component.get("c.getCurrentCredit");
        getCurrentCredit.setParams({recordId : recordId});
        getCurrentCredit.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("From server: " + response.getReturnValue());
                component.set("v.creditAmount", response.getReturnValue());
             
            } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(getCurrentCredit);
	},
    
})