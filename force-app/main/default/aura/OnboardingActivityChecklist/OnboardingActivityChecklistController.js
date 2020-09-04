({
    initialize : function(component, event, helper) {
        //helper.getMaster(component,event,'',true);
    },
    resetTemplate : function(component, event, helper) {
        component.set("v.selectedCheckListItemTemplateExit",'');
        component.set("v.selectedCheckListItemTemplateOnBoarding",'');
        component.set("v.selectAll", false);
        helper.getMaster(component,event,'',true); 
    }, 
    calculateDataByDOJ:function(component,event,helper){
        var doj= event.getSource().get("v.value");
        helper.getMaster(component,event,doj,true);
    },
    calculateDataByLWD:function(component,event,helper){
        var lwd= event.getSource().get("v.value");
        helper.getMaster(component,event,lwd,false);
    },
    save:function(component,event,helper){
        helper.saveCheckListItem(component,event);
    },
    cancel:function(component,event,helper){
        var dismissActionPanel = $A.get("e.force:closeQuickAction").fire(); 
        if(dismissActionPanel) dismissActionPanel.fire();
    },
    showSpinner: function(component, event, helper) {
        component.set("v.Spinner", true); 
    },
    hideSpinner : function(component,event,helper){   
        component.set("v.Spinner", false);
    },
    selectAllAct: function(component, event, helper) {
        var activities;
        if(component.get("v.activity") == 'ExitProcess'){
            activities = component.get("v.masterCheckExitLists");
        }else if(component.get("v.activity") == 'OnboardingProcess'){
            activities = component.get("v.masterCheckLists");
        }
        for(var i=0 ; i < activities.length; i++){
            activities[i].isChecked = component.get("v.selectAll");
        }
        if(component.get("v.activity") == 'ExitProcess'){
            component.set("v.masterCheckExitLists",activities);
        }else if(component.get("v.activity") == 'OnboardingProcess'){
            component.set("v.masterCheckLists",activities);
        }
        
    },
    selectAllDoc: function(component, event, helper) {
        var documents = component.get("v.DocumentList");
        for(var i=0 ; i < documents.length; i++){
            documents[i].isChecked = component.get("v.selectAllDocument");
        }
        component.set("v.DocumentList",documents);
    },
    onExitSelectChange: function(component, event, helper) {
        component.set("v.selectAll", false);
        if(component.get("v.selectedCheckListItemTemplateExit") == ''){
            helper.getMaster(component,event,'',false);
        }else{
            helper.getMasterCheckListByTemplateId(component,event,component.get("v.selectedCheckListItemTemplateExit"));
        }
    },
    onOnBoardingSelectChange: function(component, event, helper) {
        component.set("v.selectAll", false);
        if(component.get("v.selectedCheckListItemTemplateOnBoarding") == ''){
            helper.getMaster(component,event,'',true);
        }else{
            helper.getMasterCheckListByTemplateId(component,event,component.get("v.selectedCheckListItemTemplateOnBoarding"));
        }
    }
})