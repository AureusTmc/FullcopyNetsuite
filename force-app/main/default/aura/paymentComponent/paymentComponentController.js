({
    doInit: function(component, event, helper){
        let recordId = component.get("v.recordId");
        component.set("v.recordId", recordId);
        helper.getCurrentCredit(component, event);
        //helper.getIsOssia(component, event); // commented by nishi: 15-oct-2020: for now we get all the invoice details  on getCurrentCredit function
    }, 
    //@Juneid Filling Payment options
    handlePayNow: function(component, event, helper) {
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
    // added by nishi: 15-oct-2020: we added this function for show paid amount details
    handleCheckboxChange: function(component, event, helper) {
        let isCreditAmount =component.get("v.chkValue");
        let creditAmount = component.get("v.creditAmount");
        let invoiceAmount =  component.get("v.invoiceAmount");
        // we showing paid amount
        if(isCreditAmount){
            if(creditAmount < invoiceAmount){
                let paidAmount = invoiceAmount - creditAmount; 
                component.set("v.paidAmount",paidAmount);
            }else{
                component.set("v.paidAmount",0);
            }
        }else{
            component.set("v.paidAmount", invoiceAmount);
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
        component.set("v.isUseCreditMemoOnly", false);
        console.log('chkValue-->'+component.get("v.chkValue"));
        let recordId = component.get("v.recordId");
        let paymentType = component.find("mygroup").get("v.value");
        if(paymentType== 'Cash' || paymentType== 'Offline card' ||paymentType=='NETS'){
            component.set("v.selectedOption", paymentType);
            $A.enqueueAction(component.get('c.closeModel'));
            component.set("v.openPopUp", true);
        }
        
    },
    // added condition nishi:13-nov-2020: for  if user use only credit memo amount not use other options
    handelCreditMemoSave : function (component, event) {
        component.set("v.isUseCreditMemoOnly", true);
        $A.enqueueAction(component.get('c.closeModel'));
        component.set("v.openPopUp", true);
    },
    //@Juneid method for genrate payment
    saveGeneratePaymet:function (component, event) {
        try {
            let isCreditCheck = component.get("v.chkValue");
            let recordId = component.get("v.recordId");
            let trnsactionId = component.get("v.inputValue");
            let currentCreditAmount = component.get("v.creditAmount");
            let isUseCreditMemoOnly = component.get("v.isUseCreditMemoOnly");// added condition nishi:13-nov-2020: for  if user use only credit memo amount not use other options
            console.log(isCreditCheck, recordId, trnsactionId, currentCreditAmount);
            let param = {
                selectedMethod : component.get('v.selectedOption'),
                recordId : recordId, 
                transacId : trnsactionId,
                isCreditAmnt : isCreditCheck, 
                currentCreditAmounts : currentCreditAmount,
                isUseCreditMemoOnly:isUseCreditMemoOnly // added condition nishi:13-nov-2020: for  if user use only credit memo amount not use other options
            };
            console.log('param',param);
            var createPayment = component.get("c.createPayment"); 
            createPayment.setParams(param);
            createPayment.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state-->',state);
                if (state === "SUCCESS") {
                    console.log('in success');
                    component.set("v.openPopUp", false);
                    var invoiceWrapper = response.getReturnValue();
                    if(invoiceWrapper.errorCode == 200){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'SUCCESS',
                            message: 'Invoice Paid Amount Successfully',            
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'SUCCESS',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'error',
                            message: invoiceWrapper.errormessage,            
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'error',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    }
                   
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId":component.get("v.recordId"),
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                    
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