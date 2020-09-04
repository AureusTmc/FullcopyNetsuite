({
    
    doInit:function(component, event,helper){
      window.setInterval(function(){ 
          if(component.isValid()){
              var searchKeys=component.get("v.centerId"); 
              helper.callCases(component, event,searchKeys); 
          }
      }, 300000);
    },
	searchKeyChange: function(component, event,helper) {
        var searchKeys = event.getParam("searchKey");
         component.set("v.centerId",searchKeys);
        window.setInterval(function(){ 
            if(component.isValid()){
                helper.callCases(component, event,searchKeys);  
            }
        }, 300000);
        helper.callCases(component, event,searchKeys);
    	
    },
    OpenMegaPage:function(component,event,helper){
         var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:AdminServiceRequestViewAll",
             componentAttributes: {
                centerId : component.get("v.centerId")
            }
        });
        evt.fire();
    },
     changeOwner:function(component,event,helper){
         var searchKeys=component.get("v.centerId"); 
         var caseId=event.getSource().get("v.class");
        var action=component.get('c.updateAllNullOwner');
        action.setParams({
            "caseSalesId":caseId 
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                helper.callCases(component,event,searchKeys);
            }
        });
        $A.enqueueAction(action);
    }
})