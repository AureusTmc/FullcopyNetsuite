({
    doInit: function (cmp, event){
        //Get Picklist Values and get Parent Account name or Id
        var action = cmp.get("c.getReasonListValues");
        action.setParams({parentAccId : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(!JSON.parse(response.getReturnValue()).userAccess){
                    cmp.set("v.isPaymentCreated", "true");
                    cmp.set("v.alertMessage", 'Insufficient privilege. Please contact finance team.');
                    $A.util.addClass(cmp.find("savePayment"), 'slds-hide');
                    $A.util.addClass(cmp.find("Reason"), 'slds-hide');
                    $A.util.addClass(cmp.find("Amount"), 'slds-hide');
                    $A.util.addClass(cmp.find("ParentAccount"), 'slds-hide');
                    $A.util.addClass(cmp.find("paymentCard"), 'slds-hide');
                     $A.util.addClass(cmp.find("alertMessage"), 'addMargin');
                }
                cmp.set("v.parentAccountId", JSON.parse(response.getReturnValue()).accountId);
                cmp.set("v.parentAccountName",JSON.parse(response.getReturnValue()).accountName);
                cmp.set("v.reasonOptions", JSON.parse(response.getReturnValue()).listOfReasonPicklistValues);
                
            }
        });
        $A.enqueueAction(action);
    },
    // check picklist value if Picklist value is 'Other' then show other reason text 
    handleReasonChange: function (cmp, event) {
        var selectedOptionValue = event.getParam("value");
        if(selectedOptionValue =='Others'){
            cmp.set("v.isReasonOtherSelected", "true");
        }else{
            cmp.set("v.isReasonOtherSelected", "false");
        }
    },
    handleSavePayment: function(cmp, event, helper) {
        // check payment condition then create payment record
        helper.helperPaymentValidation(cmp);
    },
    handleCancel: function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})