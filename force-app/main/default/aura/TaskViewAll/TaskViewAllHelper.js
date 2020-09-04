({
    findTaskHelp:function(component,event,accId){
        var filterData=component.get("v.selvalue");
        var action = component.get("c.findTask");
        action.setParams({
          "searchKey": accId,
           "filter":filterData    
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                var total=response.getReturnValue().length;
                for(var i=0;i<total;i++){
                    if(response.getReturnValue()[i].What){
                        if( response.getReturnValue()[i].What.substring(0, 3)=='500'){
                            response.getReturnValue()[i].hyperLinkValue='500';
                        } 
                    }else{
                        response.getReturnValue()[i].hyperLinkValue='null';
                    }
                }
                component.set("v.Tasks", response.getReturnValue());
                component.set("v.centerId",accId);
                component.set("v.selvalue",filterData);
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    },
     getUserView:function(component,event){
        var action=component.get('c.findUserList');
        action.setCallback(this, function(response){
            if(response.getState()=='SUCCESS'){
                component.set("v.userView",response.getReturnValue());
            }else{
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    getTaskUser:function(comp,event){
        var filterValue=comp.find('select-userview').get('v.value');
        var cenId=comp.get('v.centerId');
        var action= comp.get('c.findTask');
        action.setParams({
            "filter":filterValue,
            "searchKey":cenId
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS'){
                comp.set('v.Tasks',response.getReturnValue());
                comp.set('v.totalCount',response.getReturnValue().length);
                //comp.set('v.selvalue',filterValue);
            }else{
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    }
})