({
    doInit : function(component, event, helper) {
        helper.getContry(component, event);
        helper.getCentre(component, event,null);
        helper.getInstrumentList(component, event);
    },
    
    handleCentreChange: function (component, event) {
        var selectedOptionsList = event.getParam("value");
        component.set("v.SelectedCentre", selectedOptionsList.toString());
       // alert(event.getParam("value"));
    },
    handleInstrumentChange: function (component, event) {
        var selectedInstrumentList = event.getParam("value");
        console.log(selectedInstrumentList.toString());
        component.set("v.SelectedInstrument", selectedInstrumentList.toString());
       // alert(event.getParam("value"));
    },
    getEnrolmentSize:function (component,event,handler){
        var action = component.get("c.getEnrolment");
        action.setParams({
            'teacherId':component.get("v.SelectedTeacher"),
            'CentreList':component.get("v.SelectedCentre"),
            'InstrumentList':component.get("v.SelectedInstrument")
        });
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS" && response.getReturnValue() != null && response.getReturnValue() !='') {
             // alert(response.getReturnValue());
                  component.set("v.parentCount",response.getReturnValue().length);
            }else if(response.getState() === "SUCCESS" && response.getReturnValue().length==0){
                component.set("v.parentCount",response.getReturnValue().length);
            }
        });    
        $A.enqueueAction(action);
    },
    getCenterVal: function(component, event, helper) {
        helper.getCentre(component, event,event.getSource().get("v.value"));
    }
})