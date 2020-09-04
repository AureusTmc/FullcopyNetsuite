({
    getAccount: function(component, event,helper) {
          // create a server side action. 
          var action = component.get("c.fetchAccount"); 
          // set a call back   
          action.setCallback(this, function(a) {
              var result = a.getReturnValue();
              component.set("v.Accounts", result);
 
      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
    getCenterId:function(component,event,helper){
     var action = component.get("c.getUser");
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS' && response.getReturnValue()[0]){
                component.set('v.setLoginId',response.getReturnValue()[0].Centre_Name__c);
                component.set('v.setDefaultLocation',response.getReturnValue()[0].Centre_Name__r.Name);
                var val=response.getReturnValue()[0].Centre_Name__c;
                if(val)
                {
                    var myEvent = $A.get("e.c:AccountKeyChange");
                    myEvent.setParams({"searchKey": val});
                    myEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
	},
    callHelperLocation:function(component,event,location){
        var action=component.get("c.setDefaultLocation");
        action.setParams({
            "locationVal":location
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                this.getCenterId(component,event);
            }
        });
        $A.enqueueAction(action);
    }
})