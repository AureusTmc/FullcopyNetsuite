({
	 initialize :function(component,event,helper){
         var searchKeys = component.get("v.centerId");
         helper.getDateHelp(component,event);
        var action = component.get("c.getBooking");
         action.setParams({
             'center': searchKeys
         });
        action.setCallback(this, function(response) {
            var bookingResult=[];
            
            var result = response.getState();
            if(result == 'SUCCESS'){
                for(var i=0;i<response.getReturnValue().length;i++){
                       
                    for(var j=0;j<response.getReturnValue()[i].bookListing.length;j++){
                        var BkgObj ={};
                        	if(response.getReturnValue()[i].bookListing[j].Name){
                            	BkgObj.Name=response.getReturnValue()[i].bookListing[j].Name;
                        	}
                        	if(response.getReturnValue()[i].bookListing[j].Booking_Date__c){
                            	BkgObj.Booking_Date__c=response.getReturnValue()[i].bookListing[j].Booking_Date__c;
                        	}
                            if(response.getReturnValue()[i].bookListing[j].Start_Time__c){
                            	BkgObj.Start_Time__c=response.getReturnValue()[i].bookListing[j].Start_Time__c;
                        	}
                            
                            BkgObj.Id=response.getReturnValue()[i].bookListing[j].Id;
                        	if(response.getReturnValue()[i].bookListing[j].Parent__r){
                            	BkgObj.Parent=response.getReturnValue()[i].bookListing[j].Parent__r.Name;
                        	}
                            if(response.getReturnValue()[i].bookListing[j].Student__r){
                                BkgObj.Student=response.getReturnValue()[i].bookListing[j].Student__r.Name; 
                            }
                       		 if(response.getReturnValue()[i].bookListing[j].Package__r){
                            	BkgObj.Package=response.getReturnValue()[i].bookListing[j].Package__r.Name;
                        	}
                        	 if(response.getReturnValue()[i].bookListing[j].Type__c){
                            	BkgObj.Type__c=response.getReturnValue()[i].bookListing[j].Type__c;
                        	}
                            if(response.getReturnValue()[i].bookListing[j].Center__c){
                                BkgObj.Center__c=response.getReturnValue()[i].bookListing[j].Center__c;
                            }
                        if(response.getReturnValue()[i].bookListing[j].Center__r){
                            BkgObj.Center=response.getReturnValue()[i].bookListing[j].Center__r.Name;
                        }
                            if(response.getReturnValue()[i].bookListing[j].Status__c){
                                BkgObj.Status__c=response.getReturnValue()[i].bookListing[j].Status__c;
                            }
                            if(response.getReturnValue()[i].bookListing[j].Teacher_Account__r){
                                BkgObj.Teacher=response.getReturnValue()[i].bookListing[j].Teacher_Account__r.Name;
                            }
                        if(response.getReturnValue()[i].bookListing[j].Teacher_Account__c){
                            BkgObj.Teacher__c=response.getReturnValue()[i].bookListing[j].Teacher_Account__c;
                        }
                            BkgObj.NumberRecord=response.getReturnValue()[i].NumberRecord;
                        	bookingResult.push(BkgObj);
                            
                    } 
                    
                }
                component.set("v.Bookings", bookingResult);
                
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})