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
        
        helper.getConfirmTeacher(component,event);
    },
    hideModal:function(component,event){
         component.set("v.isShowRemark",false);
        component.set("v.showForm",false);
        component.set("v.showConfirmBox",false);
        component.set("v.Exception",false);
    },
    populatedDate:function(component,event,helper){
        var startDate= event.getSource().get("v.value");
        var recordobj=component.get("v.savevalue");
        recordobj.Leave_End_Date = startDate;
        component.set("v.savevalue",recordobj);
    },
    
    createLeaveRequest:function(component,event,helper){
        component.set("v.isDisabled",false);
        component.set("v.LeaveTy",component.find('LeaveTypeRequest').get("v.value"));
        var isRemark= false;
        component.set("v.isShowRemark",true);
        var allValid = component.find('mcform').reduce(function (validFields,inputCmp) {
                    inputCmp.showHelpMessageIfInvalid();
                    return validFields && inputCmp.get('v.validity').valid;
                }, true);
        if(component.find('remarks').get("v.value") != ''){
            component.set("v.isShowRemark",false);
            isRemark = true;
        }
        if(allValid && isRemark){
            var recordObj=component.get("v.savevalue");
            recordObj.Employee=component.get("v.lookupId");
            var action=component.get("c.SaveLeaveRequest");
            action.setParams({
                'recordObj': JSON.stringify(recordObj),
                'recordId':component.get("v.recordId")
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS'){
                    component.set("v.showConfirmBox",true);
                    component.set("v.showForm",false)
                    component.set("v.totalBooking",response.getReturnValue()[0].TotalCount);
                    component.set("v.totalMakeUpCredit",response.getReturnValue()[0].TotalTime);              
                }
            });
            $A.enqueueAction(action); 
        }
    },
    
    confirmYes:function(component,event,helper){
        var totalCoun=component.get("v.countClick");
        totalCoun+=1;
        if(totalCoun==1){
           component.set("v.isDisabled",true); 
        }
        //component.set("v.countClick",1);
        var recordObj=component.get("v.savevalue");
        recordObj.Employee=component.get("v.lookupId");
        var LeaveType =component.get("v.LeaveTy");
        if(component.get("v.isDisabled")==true){
            var action=component.get("c.UpdateBooking");
            action.setParams({
                'recordObj': JSON.stringify(recordObj),
                'recordId':component.get("v.recordId"),
                'LeaveType':LeaveType
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS' && response.getReturnValue()=='Success'){
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
                    component.set("v.showConfirmBox",false);
                }else if(response.getReturnValue()=='Exception'){
                    component.set("v.Exception",true);
                }
            });
            $A.enqueueAction(action); 
        }
       
    },
    
    ShowRequestBooking:function(component,event,helper){
        component.set("v.isShowRemark",true);
        var allValid = component.find('mcform').reduce(function (validFields,
                                                                 inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        if(allValid){
            var recordObj=component.get("v.savevalue");
            recordObj.Employee=component.get("v.lookupId");
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:ShowRequestedBooking",
                componentAttributes: {
                    recordObj:recordObj,
                    accId : component.get("v.recordId")
                }
            });
            evt.fire();  
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