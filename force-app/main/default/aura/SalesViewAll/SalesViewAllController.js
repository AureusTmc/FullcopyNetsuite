({
	doInit : function(component, event, helper) {
		var searchKeys = component.get("v.centerId");
         // 28-Apr-2021: nishi: as per discussion with rajesh we shoq  piano rental or salesenquirey  list view according to isSalesEnquiery 
        var isSalesEnquiery=component.get('v.isSalesEnquiery');
        if(isSalesEnquiery){
            component.set("v.cardtitle", 'Sales Enquiry');
        }else{
            component.set("v.cardtitle", ' Instrument Rental Enquiry');
        }
         // 28-Apr-2021: nishi: as per discussion with rajesh we shoq  piano rental or salesenquirey  list view according to isSalesEnquiery 
        helper.callSalesCase(component, event,searchKeys);
	},
    changeOwner:function(component,event,helper){
         var caseId=event.getSource().get("v.class");
        var searchKeys=component.get('v.centerId');
        var action=component.get('c.updateOwner');
        action.setParams({
            "caseSalesId":caseId 
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                helper.callSalesCase(component,event,searchKeys);
            }
        });
        $A.enqueueAction(action);
    }
})