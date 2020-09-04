({
	initialize: function (component, event, helper) {
        helper.getEnrolment(component,event);
    },
    
    addRow:function (component, event, helper) {
        var criteriaList1 = component.get("v.criteriaList");
         criteriaList1.push({
                    'Student':component.get("v.Student"),
                    'Parent':component.get("v.Parent"),
                    'Enrolment':component.get("v.Enrolment"),
             		'Packages':component.get("v.Package"),
                    'Invoice_Date':'',
                    'DepositAmt':component.get("v.Deposit"),
             		'Stripe':'',
                    'CoInv':'',
                    'PaymentMethod':'Card'
                });      
        component.set("v.criteriaList", criteriaList1);  
        
    },
    deleteRow:function (component, event, helper) {
        var criteriaList1 = component.get("v.criteriaList");
        var index = event.getSource("v.class");
        criteriaList1.splice(index, 1);
        component.set("v.criteriaList", criteriaList1);
    },
    
     SaveInvoices:function(component,event,helper){
        var totalLength=component.get("v.criteriaList").length;
        var valuse=component.get("v.criteriaList");
        var InvoiceArray=[];
        for(var i=0;i<totalLength;i++){ 
             var objAccount={};
            if(valuse[i].Student != ''){
                var allValid = component.find('fldname').reduce(function (validFields,
                                                                               inputCmp) {
                    inputCmp.showHelpMessageIfInvalid();
                    return validFields && inputCmp.get('v.validity').valid;
                }, true);
               objAccount.Student=component.get("v.StudentId"); 
               objAccount.Parent=component.get("v.ParentId");
               objAccount.Center=component.get("v.CenterId");
                objAccount.Packages=component.get("v.PackageId");
               objAccount.Invoice_Date=valuse[i].Invoice_Date;
                objAccount.DepositAmt=valuse[i].DepositAmt; 
               objAccount.Stripe=valuse[i].Stripe; 
               objAccount.CoInv=valuse[i].CoInv;
                objAccount.PaymentMethod=valuse[i].PaymentMethod;
            }
            InvoiceArray.push(objAccount);
        }
        if(allValid){
            var action=component.get("c.SaveInvoice");
            action.setParams({
                'EnrolList':JSON.stringify(InvoiceArray),
                'Subscriptions':component.get("v.Subscription"),
                'EnrolmentId':component.get("v.EnrolmentId"),
                "PackageId":component.get("v.PackageId"),
                "TeacherId":component.get("v.TeacherId"),
                "SubscriptionLine":component.get("v.SubscriptionLineItem")
            });
            action.setCallback(this,function(response){
                console.log(response.getState());
                if(response.getState()=='SUCCESS'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'SUCCESS',
                        message: 'Invoices Successfully Created',            
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'SUCCESS',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId":component.get("v.enrolId"),
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
                
            });
            $A.enqueueAction(action);
        }
         
        
    }
})