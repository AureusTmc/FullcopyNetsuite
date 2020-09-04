({
    doInit : function(component, event, helper) {
        helper.getContry(component, event);
        helper.getCentre(component, event);
        helper.getInstrumentList(component, event);
    },
    
    handleCentreChange: function (component, event) {
        var selectedOptionsList = event.getParam("value");
        console.log(component.get("v.SelectedCentre"));
        component.set("v.SelectedCentre", selectedOptionsList);
       // alert(event.getParam("value"));
    }
})