({
	getContry : function(component, event) {
        var action = component.get("c.getCountry");
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS" && response.getReturnValue() != null && response.getReturnValue() !='') {
                component.set("v.countryList",response.getReturnValue());
            }
        });    
        $A.enqueueAction(action);
	},
    getCentre : function(component, event,val) {
        var action = component.get("c.getCenter");
        action.setParams({
            country:val 
        });
        action.setCallback(this,function(response){
            
			var centerOpt=[];            
            if(response.getState() === "SUCCESS" && response.getReturnValue() != null && response.getReturnValue() !='') {
                var apexCourseList=response.getReturnValue();
                apexCourseList.forEach(function(res){
                    centerOpt.push({ 
                            "value":res.Id,
                            "label": res.Name 
                        }); 
                });
                component.set("v.CentreOptions",centerOpt);
            }
        });    
        $A.enqueueAction(action);
	},
    getInstrumentList: function(component, event) {
        var action = component.get("c.getInstrument");
        action.setCallback(this,function(response){
            
			var instrumentOpt=[];            
            if(response.getState() === "SUCCESS" && response.getReturnValue() != null && response.getReturnValue() !='') {
                response.getReturnValue().forEach(function(res){
                    instrumentOpt.push(
                        { 
                            'label': res.Name,
                            'value':res.Name
                        }
                    ); 
                });
                component.set("v.instrumentList",instrumentOpt);
            }
        });    
        $A.enqueueAction(action);
	}
})