({
	searchKeyChange: function(component, event,helper) {
    	var accId = event.getParam("searchKey");
        helper.getUserView(component,event);
        helper.findTaskHelp(component,event,accId);
    },
    
    OpenMegaPage: function(component,event,helper){
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:TaskViewAll",
            componentAttributes: {
                "centerId" : component.get("v.centerId"),
                "selvalue" :"My Tasks"
            }
        });
        evt.fire();
    },
    openapproveModel: function(component, event, helper) {
        var action=component.get("c.getTaskDesc");
        action.setParams({
            'tskId':event.getSource().get("v.class")
        });
        action.setCallback(this,function(response){
            if(response.getState()=='SUCCESS' && response.getReturnValue()[0].Id != null){
                component.set("v.description",response.getReturnValue()[0].Description);  
                component.set("v.tskId", event.getSource().get("v.class"));
                component.set("v.openModal", true);
            }
        	   
        });
        $A.enqueueAction(action);
    },
    
    closeModel: function(component, event, helper) { 
        component.set("v.openModal", false);
    },
    
    approveTask:function(component,event,helper){
        var accId=component.get('v.centerId');
        component.set("v.openModal", false);
        var tskId = component.get("v.tskId");
        var taskDesc=component.get("v.description");
            var action= component.get("c.updateTaskStage");
            action.setParams({
                "tskId":tskId,
                "descriptionTask":taskDesc
            });
            action.setCallback(this,function(response){
                if(response.getState() == 'SUCCESS'){
                   helper.findTaskHelp(component,event,accId);
                }
            });
            $A.enqueueAction(action);
    },
    onChangeUserView:function(comp,event,helper){
        helper.getTaskUser(comp,event);
    }
	
})