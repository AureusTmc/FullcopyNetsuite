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

    handlePayNow:function (component, event) {
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
                this.handleToCheckPayNow(component, event);
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
    //@Juneid Filling Payment options
    handleToCheckPayNow: function(component, event) {
        var isDueInvoice =  component.get("v.isDueInvoice");
        console.log('isDueInvoice'+isDueInvoice);
        if(isDueInvoice){
            component.set('v.showmodal', true);
            var finaloptions = [];
            //finaloptions.push({'label':'Cash','value':'Cash'});
            finaloptions.push({'label':'Offline card','value':'Offline card'});
            finaloptions.push({'label':'NETS','value':'NETS'});
            component.set("v.options", finaloptions);
            let isCheckBoxEnabled = component.get("v.isEnabled");
            console.log('isCheckBoxEnabled-->'+isCheckBoxEnabled);
            if(component.get("v.creditAmount") > 0){
                console.log('in if -->');
                component.set("v.isEnabled",false);
            }else{
                component.set("v.isEnabled",true);
            }
        }else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'error',
                message: component.get("v.errormessage"),            
                duration:' 5000',
                key: 'info_alt',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId":component.get("v.recordId"),
                "slideDevName": "related"
            });
            navEvt.fire();
        }
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