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
        helper.callSalesCase(component, event,searchKeys);
    },
    
    OpenMegaPage:function(component,event){
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:SalesViewAll",
            componentAttributes: {
                centerId : component.get("v.centerId")
            }
        });
        evt.fire();
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
                component.set("v.removeCheckBox",false);
            }
        });
        $A.enqueueAction(action);
    }
})