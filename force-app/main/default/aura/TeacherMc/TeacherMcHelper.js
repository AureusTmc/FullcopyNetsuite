({
	getTeacher : function(component,event) {
		var action = component.get("c.getTeacherAccount");
        action.setParams({
            'AccountId': component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS" && response.getReturnValue()[0]!= null){
                component.set("v.isTeacher",response.getReturnValue()[0].RecordType.Name);
            }
        });
        
        $A.enqueueAction(action);
	},
    
    getConfirmTeacher:function(component,event){
        if(event.getSource().get('v.name')=='Planned'){
           
         	   component.set('v.plannedBoolean','Planned');
        }else{
                component.set('v.plannedBoolean','Mc');
        }
		var action = component.get("c.getTeacherAccount");
        action.setParams({
            'AccountId': component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS" && response.getReturnValue()[0].RecordType.Name != null){
                var LeaveRequestObj={};
                component.set("v.lookupId",response.getReturnValue()[0].Id);
                component.set("v.isTeacher",response.getReturnValue()[0].RecordType.Name);
                LeaveRequestObj.Employee=response.getReturnValue()[0].Name;
                component.set("v.TeacherName",response.getReturnValue()[0].Name);
                LeaveRequestObj.Leave_Start_Date='';
                LeaveRequestObj.Leave_End_Date='';
                LeaveRequestObj.RecordTypeName='';
                LeaveRequestObj.Remarks='';
                component.set('v.savevalue',LeaveRequestObj);
                component.set('v.showForm',true);
            }
        });
        
        $A.enqueueAction(action);
    }
   /* getPicklist:function(component,event){
       var action= component.get("c.getPickListValue");
        var inputLeave = component.find("LeaveTypeRequest");
        var opts=[];
        action.setCallback(this,function(response){
            for(var i=0;i< response.getReturnValue().length;i++){
                opts.push({value: response.getReturnValue()[i]});
            }
            component.set("v.options", opts);
        });
        $A.enqueueAction(action);
    }*/
})