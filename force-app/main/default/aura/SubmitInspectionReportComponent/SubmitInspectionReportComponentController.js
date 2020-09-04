({
    initialize : function(component, event, helper) {
        var enrolId= component.get("v.recordId");
         
         var action = component.get("c.getType");
         action.setParams({
             'enrolId':enrolId 
         });
         action.setCallback(this,function(response){
             if(response.getState()=='SUCCESS'){
                //response.getReturnValue()[0].Stage__c=='Piano Termination In-Progress' &&
                if( response.getReturnValue()[0].Type__c=='Instrument' &&
                    (response.getReturnValue()[0].Stage__c=='Piano Rental Active' ||
                    response.getReturnValue()[0].Stage__c=='Piano Termination In-Progress')){
                    component.set("v.isPopup",true);
                    component.set("v.enrolStage",response.getReturnValue()[0].Stage__c);
                    
                    console.log('response.getReturnValue()[0].parent__c'+response.getReturnValue()[0].Parent__c);
                    component.set("v.accountId",response.getReturnValue()[0].Parent__c);
                    var today = new Date();
                    var dateToday = String(today.getDate()).padStart(2, '0') + '/' + String(today.getMonth() + 1).padStart(2, '0') + '/' + today.getFullYear();
                    if(response.getReturnValue()[0].Stage__c=='Piano Rental Active'){
                        var attachmentFileName = 'Inspection_'+response.getReturnValue()[0].Model__c+'_'+response.getReturnValue()[0].Serial_Number__c+'_'+dateToday;
                        component.set("v.attachmentFileName",attachmentFileName);
                        console.log("v.attachmentFileName",attachmentFileName); 
                    }else{
                        var attachmentFileName = 'Terminated_Inspection_'+response.getReturnValue()[0].Model__c+'_'+response.getReturnValue()[0].Serial_Number__c+'_'+dateToday;
                        component.set("v.attachmentFileName",attachmentFileName);
                        console.log("v.attachmentFileName",attachmentFileName);
                    }
                }else{
                    component.set("v.isPopup",false);
                }  
             } 
         });
         $A.enqueueAction(action);
     },
     handleUploadFinished: function (component, event) {
        // Get the list of uploaded files
        var enrolId= component.get("v.recordId");
        var uploadedFiles = event.getParam("files");
        console.log('uploadedFiles',uploadedFiles[0].documentId);
        console.log('component.get("v.accountId")',component.get("v.accountId"));
        console.log('component.get("v.attachmentFileName")',component.get("v.attachmentFileName"));
        var action = component.get("c.updateParentAccount");
         action.setParams({
             'enrolId':enrolId,
             'fileName':component.get("v.attachmentFileName"),
             'fileId':uploadedFiles[0].documentId,
             'enrolStage': component.get("v.enrolStage")
         });
         action.setCallback(this,function(response){
            console.log('response.getState()',response.getState());
            console.log('response.getReturnValue()',response.getReturnValue());
             if(response.getState()=='SUCCESS'){
                if(response.getReturnValue() =='SUCCESS'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "Success",
                        "message": "The Inspection Report has been Submitted successfully."
                    });
                    toastEvent.fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "Error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                }
                
            }

            window.open("/"+enrolId,"_self");
           
                
              
         });
         $A.enqueueAction(action);
    }
})