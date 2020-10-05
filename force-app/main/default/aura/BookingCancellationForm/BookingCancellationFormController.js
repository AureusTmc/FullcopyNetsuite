({
    testData : function(component, event,helper){ 
        helper.getTime(component,event);      
    },   
   
    initialize: function (component, event, helper) {
        helper.getEnrolment(component,event);
    },
    
    addRow:function (component, event, helper) {
        var criteriaList1 = component.get("v.criteriaList");
         criteriaList1.push({
                    'Student':component.get("v.Student"),
                    'Parent':component.get("v.Parent"),
                    'Center':component.get("v.Center"),
                    'Booking_Date':'',
                    'Start_Time':'',
             		'duration':'15',
                    'End_Time':'',
                    'Available_Make_up_Units':'15'
                });      
        component.set("v.criteriaList", criteriaList1);  
        
    },
    deleteRow:function (component, event, helper) {
        var criteriaList1 = component.get("v.criteriaList");
        var index = event.getSource("v.class");
        criteriaList1.splice(index, 1);
        component.set("v.criteriaList", criteriaList1);
    },
    
    SaveBookings:function(component,event,helper){
        var totalLength=component.get("v.criteriaList").length;
        var valuse=component.get("v.criteriaList");
        var objBookingArray=[];
        for(var i=0;i<totalLength;i++){ 
             var objAccount={};
            if(valuse[i].Student != ''){
                var allValid = component.find('fldname').reduce(function (validFields,
                                                                               inputCmp) {
                    inputCmp.showHelpMessageIfInvalid();
                    return validFields && inputCmp.get('v.validity').valid;
                }, true);
               objAccount.Student=component.get("v.StudentId");
               objAccount.Parent=component.get("v.ParentId");
               objAccount.Center=component.get("v.CenterId"); 
               objAccount.Booking_Date=valuse[i].Booking_Date;
                objAccount.Start_Time=valuse[i].Start_Time; 
               objAccount.End_Time=valuse[i].End_Time; 
               objAccount.Available_Make_up_Units=valuse[i].Available_Make_up_Units
            }
            objBookingArray.push(objAccount);
        }
        if(allValid){
            var action=component.get("c.SaveBooking");
            action.setParams({
                'BookingTypeList':JSON.stringify(objBookingArray),
                'enrolmentId': component.get("v.enrolId")  // added by nishi:5-oct-2020 : if enrolment belong to ossia then we add enrolment id on booking
            });
            action.setCallback(this,function(response){
                if(response.getState()=='SUCCESS'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'SUCCESS',
                        message: 'Booking Successfully Created',            
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'SUCCESS',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId":component.get("v.enrolId"),
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
                
            });
            $A.enqueueAction(action);
        }
         
        
    },
     addDuration:function(component,event,helper){
         var duration=event.getSource().get('v.value');
     	helper.getDuration(component,event,duration);       
     
     }
    
    
    
    
})