({
    helperPaymentValidation : function(cmp) {
        if(cmp.get("v.selectedReasonOption") == 'Others' 
           && cmp.get("v.reasonOther") == undefined){
            cmp.find("reasonOther").setCustomValidity("Fill the Other reason field");
            cmp.find("reasonOther").reportValidity();
        }else if(cmp.get("v.amount") == undefined){
            cmp.find("Amount").setCustomValidity("Fill the Amount field");
            cmp.find("Amount").reportValidity();
        }else if(cmp.get("v.recordId") != undefined){
            // save payment with record type 'credit payment transaction'
            var action = cmp.get("c.createPayment");
            action.setParams({amount : cmp.get("v.amount"),
                              accountId : cmp.get("v.parentAccountId"),
                              reason : cmp.get("v.selectedReasonOption"), 
                              otherReason : cmp.get("v.reasonOther")});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    // show success message
                    if(response.getReturnValue() == "SUCCESS"){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "The record has been Inserted successfully.",
                            "type" : "success"
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }else{
                        cmp.set("v.isPaymentCreated", "true");
                        cmp.set("v.alertMessage", response.getReturnValue());
                    }
                }
            });
            $A.enqueueAction(action);
        }
    }
})