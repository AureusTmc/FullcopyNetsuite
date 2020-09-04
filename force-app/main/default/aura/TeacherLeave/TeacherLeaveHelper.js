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
                //component.set("v.TeacherName",response.getReturnValue()[0].Name);
                LeaveRequestObj.Leave_Start_Date='';
                LeaveRequestObj.EmployeeId=response.getReturnValue()[0].Id;
                LeaveRequestObj.Leave_End_Date='';
                LeaveRequestObj.RecordTypeName='';
                LeaveRequestObj.SickLeaveTime='';
                LeaveRequestObj.Remarks='';
                component.set('v.savevalue',LeaveRequestObj);
                component.set('v.showForm',true);
                component.set('v.isDisabled',false);
            }
        });
        
        $A.enqueueAction(action);
    }
})