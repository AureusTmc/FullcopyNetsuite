({
    initialize : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        window.open('/apex/EmployeePaySlipPDF?id='+recordId);
    },
	showSpinner: function(component, event, helper) {
        component.set("v.Spinner", true); 
    },
    hideSpinner : function(component,event,helper){   
        component.set("v.Spinner", false);
        $A.get("e.force:closeQuickAction").fire(); 
    }
})