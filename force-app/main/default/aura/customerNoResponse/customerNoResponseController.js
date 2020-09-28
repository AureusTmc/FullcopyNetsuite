({
  saveRecordCntrlr: function (component, event, helper) {
    component.find("recordHandler").saveRecord(
      $A.getCallback(function (saveResult) {
        
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
          console.log("recordSaved");
          helper.showToastMessage(component, event,'success','Customer No Response done successfully.');
        } else if (saveResult.state === "INCOMPLETE") {
          
            helper.showToastMessage(component, event,'error','User is offline, device doesn\'t support drafts.');
          
        } else if (saveResult.state === "ERROR") {
            helper.showToastMessage(component, event,'error','Error occured while saving the record.');
            console.log(
            "Problem saving record, error: " + JSON.stringify(saveResult.error)
          );
        } else {
            helper.showToastMessage(component, event,'error','Error occured while saving the record.');
          console.log(
            "Unknown problem, state: " +
              saveResult.state +
              ", error: " +
              JSON.stringify(saveResult.error)
          );
        }
      })
    );
  },
  handleRecordUpdated: function (component, event, helper) {
    var eventParams = event.getParams();
    if (eventParams.changeType === "LOADED") {

      if( component.get("v.simpleRecord.Status__c") == "Customer No Response" ){
          
        helper.showToastMessage(component, event,'error','Customer No Response is already done.');
      }else{

     console.log("Before setting --> " + component.get("v.simpleRecord.Comments__c"));
      console.log("Before setting --> " + component.get("v.simpleRecord.Status__c"));
      component.set("v.simpleRecord.Comments__c", "");
      component.set("v.simpleRecord.Status__c", "Customer No Response");
      console.log("After setting --> " + component.get("v.simpleRecord.Comments__c"));
      console.log("After setting --> " + component.get("v.simpleRecord.Status__c"));

      }  
      
    }
  },
  showMODAL: function( component,event,helper){
    component.set("v.simpleRecord.Comments__c", "");
    component.set("v.showMODAL",true);
  },
  cancelModal: function( component,event,helper){
    component.set("v.simpleRecord.Comments__c", "");
    component.set("v.showMODAL",false);
  }

  /*doInit: function( component,event,helper){

    var action = component.get("c.checkUserEligibility");
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {

            if( response.getReturnValue() != 'Success' ){
                helper.showToastMessage(component, event,'error',response.getReturnValue());
            }
           
        }
        else {
            helper.showToastMessage(component, event,'error',state);
            console.log("Failed with state: " + state);
        }
    });
    $A.enqueueAction(action);
  }*/

});
