({
    getCentreData : function(component,event){
        var action = component.get("c.getCenters");
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var initWrapper = response.getReturnValue();
                var cntrList = initWrapper.cntrList; 
                var cntrMap = [];
                for(var key in cntrList){
                    cntrMap.push({key: key, value: cntrList[key]});
                }
                component.set("v.cntrAccMap", cntrMap);
                component.set("v.slcdCentr", initWrapper.slcdCenter);
                component.set("v.gstPrcnt", initWrapper.gstPercent);
            } 
        });
        $A.enqueueAction(action);
    }, 
    getSageItems : function(component,event){
        var action = component.get("c.getSageProductItems");
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
               console.log(response.getReturnValue());
                component.set('v.SageProductItems', response.getReturnValue());
               /* var initWrapper = response.getReturnValue();
                var cntrList = initWrapper.cntrList; 
                var cntrMap = [];
                for(var key in cntrList){
                    cntrMap.push({key: key, value: cntrList[key]});
                }
                component.set("v.cntrAccMap", cntrMap);
                component.set("v.slcdCentr", initWrapper.slcdCenter);*/
            } 
        });
        $A.enqueueAction(action);
    }, 
    
	getAccountData : function(component){
        //Load the Account data from apex
        var action = component.get("c.getAccounts");
        var toastReference = $A.get("e.force:showToast");
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var accountWrapper = response.getReturnValue();
                if(accountWrapper.success){
                    //Setting data to be displayed in table
                    component.set("v.accountData",accountWrapper.accountsList);
                    toastReference.setParams({
                        "type" : "Success",
                        "title" : "Success",
                        "message" : accountWrapper.message,
                        "mode" : "dismissible"
                    });
                } // handel server side erroes, display error msg from response 
                else{
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "Error",
                        "message" : accountWrapper.message,
                        "mode" : "sticky"
                    }); 
                }
            } // handel callback error 
            else{
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "Error",
                    "message" : 'An error occurred during initialization '+state,
                    "mode" : "sticky"
                });
            }
            toastReference.fire();
        });
        $A.enqueueAction(action);
    },
    
    sortData : function(component,fieldName,sortDirection){
        var data = component.get("v.accountData");
        //function to return the value stored in the field
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        // to handel number/currency type fields 
        if(fieldName == 'NumberOfEmployees'){ 
            data.sort(function(a,b){
                var a = key(a) ? key(a) : '';
                var b = key(b) ? key(b) : '';
                return reverse * ((a>b) - (b>a));
            }); 
        }
        else{// to handel text type fields 
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });    
        }
        //set sorted data to accountData attribute
        component.set("v.accountData",data);
    },
    showToast : function(component, event, type, msg) {
      
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: msg,
            type : type
        });
        toastEvent.fire();
    }
})