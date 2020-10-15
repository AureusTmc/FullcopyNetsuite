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
                console.log("From server: " , response.getReturnValue());
                var invoiceWrapper = response.getReturnValue();
                if(invoiceWrapper.errorCode == 200){
                    //component.set("v.creditAmount", response.getReturnValue());
                    component.set("v.creditAmount", invoiceWrapper.currentCreditAmount);
                    component.set("v.isOssia", invoiceWrapper.isOssia);
                    component.set("v.invoiceAmount", invoiceWrapper.totalinvoiceAmount);
                    if(invoiceWrapper.totalinvoiceAmount > 0 ){
                        component.set("v.paidAmount", invoiceWrapper.totalinvoiceAmount);
                    }
                    component.set('v.isDueInvoice', true);
                }else{
                    component.set('v.isDueInvoice', false);
                    component.set("v.errormessage", invoiceWrapper.errormessage);
                }
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
    
    /*// commented by nishi: 15-oct-2020: for now we get all the invoice details  on getCurrentCredit function
    getIsOssia:function (component, event) {
        let recordId = component.get("v.recordId");
        var getIsOssia = component.get("c.getIsOssia");
        getIsOssia.setParams({recordId : recordId});
        getIsOssia.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("From server: " + response.getReturnValue());
                component.set("v.isOssia", response.getReturnValue());
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
        $A.enqueueAction(getIsOssia);
    },*/
    
})