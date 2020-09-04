({
	getEnrolment : function(component,event) {
	 	var action = component.get("c.getEnrolment");
        var criteriaList1 = component.get("v.criteriaList");
        action.setParams({
            'enrolId':component.get("v.enrolId")
        });
        action.setCallback(this, function(response) {
            if(response.getState()=='SUCCESS'){
            if(response.getReturnValue().length > 0){
                component.set("v.TeacherId",response.getReturnValue()[0].Teacher__c);
                component.set("v.Student",response.getReturnValue()[0].Student__r.Name);
                component.set("v.Parent",response.getReturnValue()[0].Parent__r.Name);
                component.set("v.Center",response.getReturnValue()[0].Center__r.Name);
                component.set("v.StudentId",response.getReturnValue()[0].Student__c);
                component.set("v.ParentId",response.getReturnValue()[0].Parent__c);
                component.set("v.CenterId",response.getReturnValue()[0].Center__c);
                component.set("v.Enrolment",response.getReturnValue()[0].Name);
                component.set("v.EnrolmentId",response.getReturnValue()[0].Id);
                component.set("v.Package",response.getReturnValue()[0].Package__r.Name);
                component.set("v.PackageId",response.getReturnValue()[0].Package__c);
                component.set("v.Deposit",response.getReturnValue()[0].Package__r.Deposit_Fee__c);
                component.set("v.Subscription",response.getReturnValue()[0].Subscription_Line_Items__r[0].Subscription__c);
                component.set("v.SubscriptionLineItem",response.getReturnValue()[0].Subscription_Line_Items__r[0].Id);
                criteriaList1.push({
                    'Student':response.getReturnValue()[0].Student__r.Name,
                    'Parent':response.getReturnValue()[0].Parent__r.Name,
                    'Enrolment':response.getReturnValue()[0].Name,
                    'Packages':response.getReturnValue()[0].Package__r.Name,
                    'Invoice_Date':'',
                    'DepositAmt':response.getReturnValue()[0].Package__r.Deposit_Fee__c,
                    'Stripe':'',
                    'CoInv':'',
                    'PaymentMethod':'Card'
                });
            }
            }    
            component.set("v.criteriaList", criteriaList1);
            
        }),
            $A.enqueueAction(action);
	},
})