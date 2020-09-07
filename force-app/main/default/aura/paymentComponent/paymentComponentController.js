({
    doInit: function(component, event, helper){
        let recordId = component.get("v.recordId");
        component.set("v.recordId", recordId);
        helper.getCurrentCredit(component, event);
        
    }, 
    //@Juneid Filling Payment options
    handlePayNow: function(component, event, helper) {
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
        }
    },
    //Juneid, Method for Close 1st Model
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.showmodal", false);
    },
    
    //@Juneid method for close the popup model
    closePopup: function(component, event, helper) {
        // Set openPopUp attribute to false  
        component.set("v.openPopUp", false);
    },
    
    handleChange: function (cmp, event) {
        var changeValue = event.getParam("value");
    },
    //@Juneid Method for Save On confirmatio of payment
    handelSave: function (component, event) {
        console.log('chkValue-->'+component.get("v.chkValue"));
        let recordId = component.get("v.recordId");
        let paymentType = component.find("mygroup").get("v.value");
        if(paymentType== 'Cash' || paymentType== 'Offline card' ||paymentType=='NETS'){
            component.set("v.selectedOption", paymentType);
            $A.enqueueAction(component.get('c.closeModel'));
            component.set("v.openPopUp", true);
        }
        
    },
    //@Juneid method for genrate payment
    saveGeneratePaymet:function (component, event) {
        try {
            let isCreditCheck = component.get("v.chkValue");
            let recordId = component.get("v.recordId");
            let trnsactionId = component.get("v.inputValue");
            let currentCreditAmount = component.get("v.creditAmount");
            console.log(isCreditCheck, recordId, trnsactionId, currentCreditAmount);
            let param = {
                selectedMethod : component.get('v.selectedOption'),
                recordId : recordId, 
                transacId : trnsactionId,
                isCreditAmnt : isCreditCheck, 
                currentCreditAmounts : currentCreditAmount 
            };
            console.log('param',param);
            var createPayment = component.get("c.createPayment"); 
            createPayment.setParams(param);
            createPayment.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state-->',state);
                if (state === "SUCCESS") {
                    console.log('in success');
                    var a = component.get('c.closePopup'); 
                    $A.enqueueAction(a);
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
            $A.enqueueAction(createPayment);
        } catch(err) {
            console.log("err", err);
        }
    }
})