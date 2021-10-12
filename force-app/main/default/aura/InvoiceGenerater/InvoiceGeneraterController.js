({
    confirm : function(component, event, helper) {
        component.set("v.showNextInvoice",true);
        let recordId = component.get("v.recordId");
        var action = component.get("c.generateInvoiceSummary");
        action.setParams({subscriptionId:recordId});
        action.setCallback(this,function(response){
            console.log('response.getStatus() ==>',response.getState());
            if(response.getState() === 'SUCCESS'){
                let generateInvoiceWrapper = response.getReturnValue();
                console.log('generateInvoiceWrapper',generateInvoiceWrapper);
                if(generateInvoiceWrapper.errorCode =='200'){
                    component.set("v.showConfirmBox",true);
                    component.set("v.showButton",false);
                    var buttonName = event.getSource().get("v.name");
                    component.set("v.processType",buttonName);
                }else{
                    component.set("v.showList",false);
                    component.set("v.errorMessage",generateInvoiceWrapper.errorMessage);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": generateInvoiceWrapper.errorMessage,
                        "type":'error'
                    });
                    toastEvent.fire();
                }
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message":'Some Other Error Found.Please Refresh Subscription.',
                    "type":'error'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
       
    },
    hideModal : function(component){
        component.set("v.showConfirmBox",false);
        component.set("v.showInvoiceSummaryBox",false);
        component.set("v.showList",true);
        component.set("v.errorMessage",'');
        component.set("v.showButton",true);
        component.set("v.invoiceDate",'');
        component.set("v.grossAmount",0);
        component.set("v.discountAmount",0);
        component.set("v.totalAmount",0);
        component.set("v.gstAmount",0);
        component.set("v.parentTaxRate",0);
    },
    confirmYes : function(component,event,helper){
            let recordId = component.get("v.recordId");
            console.log('recordId',recordId);
            component.set("v.showList",true);
            component.set("v.invoiceDate",'');
            component.set("v.grossAmount",0);
            component.set("v.discountAmount",0);
            component.set("v.totalAmount",0);
            component.set("v.gstAmount",0);
            component.set("v.parentTaxRate",0);
            var action = component.get("c.generateInvoiceSummary");
            action.setParams({subscriptionId:recordId});
            action.setCallback(this,function(response){
                console.log('response.getStatus() ==>',response.getState());
                if(response.getState() === 'SUCCESS'){
                    component.set("v.showInvoiceSummaryBox",true);
                    component.set("v.showConfirmBox",false);
                    let generateInvoiceWrapper = response.getReturnValue();
                    console.log('generateInvoiceWrapper',generateInvoiceWrapper);
                    if(generateInvoiceWrapper.errorCode =='200'){
                        component.set("v.showList",true);
                        component.set("v.generatedInvoiceList",generateInvoiceWrapper.listOfBillSummary);
                        component.set("v.invoiceDate",generateInvoiceWrapper.invoiceDate);
                        component.set("v.grossAmount",generateInvoiceWrapper.grossAmount);
                        component.set("v.discountAmount",generateInvoiceWrapper.discountAmount);
                        component.set("v.totalAmount",generateInvoiceWrapper.totalAmount);
                        component.set("v.gstAmount",generateInvoiceWrapper.gstAmount);
                        component.set("v.parentTaxRate",generateInvoiceWrapper.parentTaxRate);
                        component.set("v.showNextInvoice",false);
                    }else{
                        component.set("v.showList",false);
                        component.set("v.errorMessage",generateInvoiceWrapper.errorMessage);
                    }
                }else{
                    console.log('response.getStatus() ==>',response.getState());
                    component.set("v.showList",false);
                }
            });
            $A.enqueueAction(action);
    },
    generateNewInvoice : function(component,event,helper){
        let recordId = component.get("v.recordId");
        component.set("v.showNextInvoice",true);
        console.log('recordId',recordId);
        var action = component.get("c.generateInvoice");
        action.setParams({subscriptionId:recordId});
        action.setCallback(this,function(response){
            console.log('response.getStatus() ==>',response.getState());
            component.set("v.showConfirmBox",false);
            component.set("v.showInvoiceSummaryBox",false);
            component.set("v.showList",true);
            component.set("v.errorMessage",'');
            component.set("v.showButton",true);
            component.set("v.invoiceDate",'');
            component.set("v.grossAmount",0);
            component.set("v.discountAmount",0);
            component.set("v.totalAmount",0);
            component.set("v.gstAmount",0);
            component.set("v.parentTaxRate",0);
            if(response.getState() === 'SUCCESS'){
                let generateInvoiceWrapper = response.getReturnValue();
                console.log(recordId);
                if(generateInvoiceWrapper.errorCode =='200'){
                    console.log('generateInvoiceWrapper',generateInvoiceWrapper);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The All Invoices Generated successfully.",
                        "type":'success'
                    });
                    toastEvent.fire();
                    var paymentAction = component.get("c.generateInvoicePayment");
                    paymentAction.setParams({invoiceId:generateInvoiceWrapper.returnId});
                    paymentAction.setCallback(this,function(paymentResponse){
                        console.log('paymentResponse.getStatus() ==>',paymentResponse.getState());
                        if(paymentResponse.getState() === 'SUCCESS'){
                            let generatepaymentInvoiceWrapper = paymentResponse.getReturnValue();
                            console.log('generatepaymentInvoiceWrapper',generatepaymentInvoiceWrapper);
                            var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Success!",
                                    "message": "Please wait... Payments Are Pending...",
                                    "type":'success'
                                });
                                toastEvent.fire();
                                 window.location.href = '/'+generateInvoiceWrapper.returnId;
                           /* if(generatepaymentInvoiceWrapper.errorCode =='200'){
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Success!",
                                    "message": "Please wait... All Invoices Payments Are Pending...",
                                    "type":'success'
                                });
                                toastEvent.fire();
                                    window.location.href = '/'+generatepaymentInvoiceWrapper.returnId;
                            }else{
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Error!",
                                    "message": generatepaymentInvoiceWrapper.errorMessage,
                                    "type":'error'
                                });
                                toastEvent.fire();
                                window.location.href = '/'+generateInvoiceWrapper.returnId;
                            }*/
                        }else{
                            console.log('response.getStatus() ==>',paymentResponse.getState());
                        }
                    });
                    $A.enqueueAction(paymentAction);
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": generateInvoiceWrapper.errorMessage,
                        "type":'error'
                    });
                    toastEvent.fire();
                }
            }else{
                console.log('response.getStatus() ==>',response.getState());
            }
        });
        $A.enqueueAction(action);
},
generateNewonlyInvoice : function(component,event,helper){
    let recordId = component.get("v.recordId");
    component.set("v.showNextInvoice",true);
    console.log('recordId',recordId);
    var action = component.get("c.generateInvoice");
    action.setParams({subscriptionId:recordId});
    action.setCallback(this,function(response){
        console.log('response.getStatus() ==>',response.getState());
        component.set("v.showConfirmBox",false);
        component.set("v.showInvoiceSummaryBox",false);
        component.set("v.showList",true);
        component.set("v.errorMessage",'');
        component.set("v.showButton",true);
        component.set("v.invoiceDate",'');
        component.set("v.grossAmount",0);
        component.set("v.discountAmount",0);
        component.set("v.totalAmount",0);
        component.set("v.gstAmount",0);
        component.set("v.parentTaxRate",0);
        if(response.getState() === 'SUCCESS'){
            let generateInvoiceWrapper = response.getReturnValue();
            console.log(recordId);
            if(generateInvoiceWrapper.errorCode =='200'){
                console.log('generateInvoiceWrapper',generateInvoiceWrapper);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The All Invoices Generated successfully.",
                    "type":'success'
                });
                toastEvent.fire();
                window.location.href = '/'+generateInvoiceWrapper.returnId;
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": generateInvoiceWrapper.errorMessage,
                    "type":'error'
                });
                toastEvent.fire();
            }
        }else{
            console.log('response.getStatus() ==>',response.getState());
        }
    });
    $A.enqueueAction(action);
}
})