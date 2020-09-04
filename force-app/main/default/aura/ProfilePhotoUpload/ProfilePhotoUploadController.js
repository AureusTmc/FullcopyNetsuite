({
    doInit: function(component, event, helper) {
        var action = component.get("c.getProfileImage");
        action.setParams({
            parentId: component.get("v.accId"), 
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(response.getReturnValue());
            //alert(state);
            if (state === "SUCCESS") {
                if(response.getReturnValue().length>1){
                    //alert(response.getReturnValue());
                    component.set("v.attId",response.getReturnValue());
                    component.set("v.isImgText",false);
                }else{
                    //alert(response.getReturnValue());
                    component.set("v.isImgText",true);
                    component.set("v.imgText",response.getReturnValue());
                }
                component.set("v.isModalOpen", false);
                
            } else if (state === "ERROR") {
                console.log('error');
                var errors = response.getError();
                console.log(response.getError());
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    openModel: function(component, event, helper) {
        component.set("v.isModalOpen", true);
        component.set("v.btnShow", false); 
    },
    handleFilesChange: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
    },
})