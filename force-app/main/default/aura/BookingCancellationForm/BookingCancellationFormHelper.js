({
	getEnrolment : function(component,event) {
	 	var action = component.get("c.getEnrolment");
        var criteriaList1 = component.get("v.criteriaList");
        action.setParams({
            'enrolId':component.get("v.enrolId")
        });
        action.setCallback(this, function(response) {
            if(response.getState()=='SUCCESS'){
            if(response.getReturnValue().length > 0){
                component.set("v.Student",response.getReturnValue()[0].Student__r.Name);
                component.set("v.Parent",response.getReturnValue()[0].Parent__r.Name);
                component.set("v.Center",response.getReturnValue()[0].Center__r.Name);
                component.set("v.StudentId",response.getReturnValue()[0].Student__c);
                component.set("v.ParentId",response.getReturnValue()[0].Parent__c);
                component.set("v.CenterId",response.getReturnValue()[0].Center__c);
                criteriaList1.push({
                    'Student':response.getReturnValue()[0].Student__r.Name,
                    'Parent':response.getReturnValue()[0].Parent__r.Name,
                    'Center':response.getReturnValue()[0].Center__r.Name,
                    'Booking_Date':'',
                    'Start_Time':'',
                    'duration':'15',
                    'End_Time':'',
                    'Available_Make_up_Units':'15'
                });
            }
            }    
            component.set("v.criteriaList", criteriaList1);
            
        }),
            $A.enqueueAction(action);
	},
    
    getTime:function(component,event){
        
        
        try {
            //Variable to get the selected index
            let selIdx = event.getSource().get('v.accesskey');
            //variable to get the value of selected time from the specified row
            let objTime = event.getSource().get('v.value');
            //vriable to split the time for hour, min and secs
            if(objTime != ''){
                let timeList = objTime.split(':');
                //variables to assign those values to four different variables
                let [one, two, three, four] = timeList;
                //Variables to keep the integer forms of hour and minute values
                let intOfHour = parseInt(one);
                let intOfMin = parseInt(two);
                
                //Variable to add minutes
                let objList = component.get('v.criteriaList');
                let addMinutes = parseInt(objList[selIdx].duration);
                
                // assigning vale to make up credit
                 objList[selIdx].Available_Make_up_Units=addMinutes;  
                
                
                intOfMin+=addMinutes;
                if(intOfMin > 59){ 
                    intOfHour+=1;
                    intOfMin =   intOfMin - 60;
                }
                if(intOfHour==24)
                    intOfHour=0;
                
                //Assign min value
                let textHour = String(intOfHour);
                if(textHour.length==1)
                    textHour = '0'+textHour;
                let textMin = String(intOfMin);
                if(textMin.length==1)
                    textMin = '0'+textMin;
                
                objList[selIdx].End_Time = textHour+':'+textMin+':00.000';
                
                component.set('v.criteriaList',objList);
            }else{
                let objList = component.get('v.criteriaList');
                let addMinutes = parseInt(objList[selIdx].duration);
                objList[selIdx].End_Time = '';
                objList[selIdx].Available_Make_up_Units=addMinutes; 
            }
        }
        catch(err) {
            console.log(err.message);
        }
      
        
        
		
    },
     getDuration:function(component,event,duration){
        //Variable to get the selected index
        let selIdx = event.getSource().get('v.accesskey');
        //variable to get the value of selected time from the specified row
        let objList = component.get('v.criteriaList');
        let objTime = objList[selIdx].Start_Time;
        if(objTime != ''){
           //let objTime = event.getSource().get('v.value');
        //vriable to split the time for hour, min and secs
        let timeList = objTime.split(':');
        //variables to assign those values to four different variables
        let [one, two, three, four] = timeList;
       	//Variables to keep the integer forms of hour and minute values
        let intOfHour = parseInt(one);
        let intOfMin = parseInt(two);
        
        //Variable to add minutes
        //let objList = component.get('v.criteriaList');
        let addMinutes =parseInt(duration);
          // let addMinutes = parseInt(objList[selIdx].duration);
		
		 
        intOfMin+=addMinutes;
        if(intOfMin > 59){ 
            intOfHour+=1;
            intOfMin =   intOfMin - 60;
        }
        if(intOfHour==24)
            intOfHour=0;
        
        //Assign min value
        let textHour = String(intOfHour);
        if(textHour.length==1)
            textHour = '0'+textHour;
        let textMin = String(intOfMin);
        if(textMin.length==1)
            textMin = '0'+textMin;
        
        objList[selIdx].End_Time = textHour+':'+textMin+':00.000';
        objList[selIdx].Available_Make_up_Units=parseInt(duration); 
        }else{
            objList[selIdx].End_Time = '';
            objList[selIdx].Available_Make_up_Units=parseInt(duration); 
        }
          
        
        component.set('v.criteriaList',objList);
		
    }
})