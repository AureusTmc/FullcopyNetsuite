({
     doInit:function(component, event,helper){
      window.setInterval(function(){ 
          if(component.isValid()){
              var searchKeys=component.get("v.centerId"); 
              helper.callSalesCase(component, event,searchKeys); 
          }
      }, 300000);
    },
	searchKeyChange: function(component, event,helper) {
    	var searchKeys = event.getParam("searchKey");
        component.set("v.centerId",searchKeys);
        helper.callSalesCase(component, event,searchKeys);
    	
    },
    OpenMegaPage:function(component,event,helper){
         var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:ServiceViewAll",
            componentAttributes: {
                centerId : component.get("v.centerId")
            }
        });
        evt.fire();
    },
     changeOwner:function(component,event,helper){
         var caseId=event.getSource().get("v.class");
        var searchKeys=component.get('v.centerId');
         component.set("v.centerId",searchKeys);
        var action=component.get('c.updateServiceOwner');
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