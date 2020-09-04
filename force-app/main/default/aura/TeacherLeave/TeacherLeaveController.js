({
	initialize : function(component, event, helper) {
         var today = new Date();        
        var dd = today.getDate();
        var mm = today.getMonth() + 1; //January is 0!
        var yyyy = today.getFullYear();
          if(dd < 10){
            dd = '0' + dd;
        } 
    // if month is less then 10, then append 0 before date    
        if(mm < 10){
            mm = '0' + mm;
        }
        var todayFormattedDate = yyyy+'-'+mm+'-'+dd;
        component.set("v.todayDate",todayFormattedDate);
		helper.getTeacher(component,event);
       // helper.getPicklist(component,event);
	},
    openModal:function(component,event,helper){
        component.set("v.Exception",false);
        helper.getConfirmTeacher(component,event);
    },
    hideModal:function(component,event){
        // component.set("v.isShowRemark",false);
        component.set("v.showForm",false);
       // component.set("v.showConfirmBox",false);
        component.set("v.Exception",false);
    },
    populatedDate:function(component,event,helper){
        var startDate= event.getSource().get("v.value");
        var recordobj=component.get("v.savevalue");
        recordobj.Leave_End_Date = startDate;
        component.set("v.savevalue",recordobj);
    },
    
    confirmYes:function(component,event,helper){
        var totalCoun=component.get("v.countClick");
        totalCoun+=1;
        if(totalCoun==1){
           component.set("v.isDisabled",true); 
        }
        //component.set("v.countClick",1);
        var recordObj=component.get("v.savevalue");
        recordObj.EmployeeId=component.get("v.lookupId");
        console.log('recordObj ', recordObj.SickLeaveTime);
        if(component.get("v.isDisabled")==true){
            var action=component.get("c.UpdateBooking");
            action.setParams({
                'recordObj': JSON.stringify(recordObj),
                'recordId':component.get("v.recordId")
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS' && response.getReturnValue()=='Success'){
                    component.set("v.showForm",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'SUCCESS',
                        message: 'Leave Request Successfully Saved',            
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'SUCCESS',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                }else{
                    var message=response.getReturnValue();
                    component.set('v.exceptionMessage',message);
                    component.set("v.Exception",true);
                    component.set("v.isDisabled",false); 
                    component.set("v.showForm",True);
                    
                }
            });
            $A.enqueueAction(action); 
        }
       
    },
    
     gotoReport : function (component, event, helper) {
        component.set("v.isShowRemark",false);
        var allValid = component.find('mcform').reduce(function (validFields,
                                                                 inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        if(allValid){
            var recordObj=component.get("v.savevalue");
            //recordObj.Employee=component.get("v.lookupId");
            
            var action = component.get("c.getReport");
            action.setCallback(this,function(response){
                if(response.getState()==='SUCCESS' && response.getReturnValue()[0].Id != null){
                    window.open("/lightning/r/Report/"+ response.getReturnValue()[0].Id +"/view?queryScope=userFolders&fv0="+ recordObj.Leave_Start_Date +"&fv1="+recordObj.Leave_End_Date+"&fv2="+ recordObj.Employee, "_blank");
                    
                } 
             });
            $A.enqueueAction(action);
        }
    }
})