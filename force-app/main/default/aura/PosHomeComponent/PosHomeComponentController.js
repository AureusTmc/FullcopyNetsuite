({
    onInit : function(component,event,helper){
        // Setting column information.To make a column sortable,set sortable as true on component load
       /* component.set("v.accountColumns",[
            {
                label : 'Name',
                fieldName : 'Name',
                type : 'text',
                sortable : true
            },
            {
                label : 'Account Source',
                fieldName : 'AccountSource',
                type : 'text',
                sortable : true
            },
            {
                label : 'Rating',
                fieldName : 'Rating',
                type : 'text',
                sortable : true
            },
            {
                label : 'Employees',
                fieldName : 'NumberOfEmployees',
                type : 'number',
                sortable : true
            }
        ]);*/
        // call helper function to fetch account data from apex
       // helper.getAccountData(component);
       
       /* var action = component.get("c.getCenters");
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
               
                //Setting data to be displayed in table
                //component.set("v.accountData",accountWrapper.accountsList);
                var initWrapper = response.getReturnValue();
                var cntrList = initWrapper.cntrList; 
                var cntrMap = [];
                for(var key in cntrList){
                    cntrMap.push({key: key, value: cntrList[key]});
                }
                component.set("v.cntrAccMap", cntrMap);
                component.set("v.slcdCentr", initWrapper.slcdCenter);
            } 
        });
        $A.enqueueAction(action);*/
        
       
        helper.getCentreData(component,event);
        helper.getSageItems(component,event);  
       // helper.toggle(component,event);
    },
    
    //Method gets called by onsort action,
   /* handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortData(component,sortBy,sortDirection);
    },
    handleKeyUp : function (cmp, event, helper) {
        alert('handleKeyUp:' + event.which);
        if (event.which == 13){
            alert('handleKeyUp: enter button');
        }
    },
    handleInput : function (cmp, event, helper) {
        var entersearch = cmp.get("{!v.myEnterSearch}");
        var messageempty = (entersearch ===""?" empty":"") ;
        alert('handle Input: ' + entersearch + messageempty );
        
    },*/
    handleMyApplicationEvent : function(component, event, helper) {
       
        var valueId = event.getParam("selectedOption");  
        var value = event.getParam("inputValue");
       // alert("Received application event with param = "+ value+"     "+valueId);
        if(!valueId.startsWith("001")){
            var totAmt   = 0;
            var gstPrcntAmt = 0;
            var grandTot = 0;
            
            var slcdProducts = component.get("{!v.slcdProducts}"); 
			if(slcdProducts == null)
                slcdProducts = [];
            
            for(var i = 0; i < slcdProducts.length; i++){
                if(slcdProducts[i].price > 0)
                	totAmt = parseInt(totAmt) +  parseInt(slcdProducts[i].price);
            }
            
            var indxNo = slcdProducts.length + 1;
            
            //element.recNo+'##'+element.item+'##'+element.category+'##'+element.quantity+'##'+element.price;
            var dataList = valueId.split("##");
            slcdProducts.push({indexNo:indxNo, recNo: dataList[0], category: dataList[2], quantity: dataList[3], price: dataList[4], item: value, singleQunPrice: dataList[4]});
            //slcdProducts.push({recNo: valueId, item: value});
            component.set("v.slcdProducts", slcdProducts);
            
            console.log(parseInt(dataList[4]));
            if(dataList[4])
                totAmt = parseInt(totAmt) + parseInt(dataList[4]);
            
            
            if(component.get("v.gstPrcnt"))
                gstPrcntAmt = (totAmt * component.get("v.gstPrcnt")) / 100;
                
			grandTot =  totAmt + gstPrcntAmt;   
            
            component.set("v.totalAmt", totAmt);
            component.set("v.gstPercntAmt", gstPrcntAmt);
            component.set("v.grandTot", grandTot);
        }else{
            component.set("v.accCstmrId", valueId);
            
            var action = component.get("c.checkCstmrCard");
            action.setParams({"cstmrId":valueId});
            
            action.setCallback(this,function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                   // alert(response.getReturnValue());
                	//component.set("v.isCstmrHasCard", );
                    
                    var finaloptions = [];
                    finaloptions.push({'label':'Cash','value':'Cash'});
                    finaloptions.push({'label':'Offline card','value':'Offline card'});
                    finaloptions.push({'label':'NETS','value':'NETS'});
                    
                    if(response.getReturnValue().Stripe_Customer_Id__c){
                        finaloptions.push({'label':'Card on file','value':'Card'});
                    	finaloptions.push({'label':'Online email','value':'Online email'});
                    }
                    
                    component.set("v.avlPayCredits", response.getReturnValue().Total_Payment_Credit_Available__c);
                    component.set("v.slcdCstmrDetail", response.getReturnValue());
                    component.set("v.options", finaloptions);
                }       
            });
            $A.enqueueAction(action);
        }
    },
    
    removeItem:function(component, event, helper) {
        var className = event.getSource().get("v.class");
        var indexVal = className.split('_');
        var finalIndVal = parseInt(indexVal[1])-1;
        
        var slcdProducts = component.get("{!v.slcdProducts}"); 
        slcdProducts.splice(finalIndVal,1);
        
        
        var totAmt   = 0;
        var gstPrcntAmt = 0;
        var grandTot = 0;
        
        for(var i = 0; i < slcdProducts.length; i++){           
            if(slcdProducts[i].singleQunPrice > 0 && slcdProducts[i].quantity > 0){                
                totAmt = parseInt(totAmt) +  (parseInt(slcdProducts[i].singleQunPrice * slcdProducts[i].quantity));
            }
            slcdProducts[i].indexNo = i+1;
        }
        component.set("v.slcdProducts", slcdProducts);
       
        if(component.get("v.gstPrcnt"))
            gstPrcntAmt = (totAmt * component.get("v.gstPrcnt")) / 100;
        
        grandTot =  totAmt + gstPrcntAmt;   
        
        component.set("v.totalAmt", totAmt);
        component.set("v.gstPercntAmt", gstPrcntAmt);
        component.set("v.grandTot", grandTot);
        //  added by jatin: 26-Feb-2020:for is remove items and all products list size is 0 then we  adhocPOSServicesName veriable blank */
        if(slcdProducts.length == 0 && component.get("v.isAdhocPOSServices")){
            component.set("v.adhocPOSServicesName","");
        }
    },
    
    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
    
    submitDetails: function(component, event, helper) {
        // Set isModalOpen attribute to false
        //Add your code to call apex method or do some processing
        var accDetails= component.get("v.acc");
        
        var action = component.get("c.insrtCstmr");
        action.setParams({"acc" : accDetails});
        
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
               //alert(response.getReturnValue());
            	var instdAcc = response.getReturnValue();
                
                var name = instdAcc.FirstName+' '+instdAcc.LastName;
                
                var msg = 'New customer successfully added.'
                helper.showToast(component,event,'Success',msg);
                component.set("v.accCstmrId", instdAcc.Id);
                component.set("v.accName", name);
                component.set("v.isModalOpen", false);
                
                var finaloptions = [];
                finaloptions.push({'label':'Cash','value':'Cash'});
                finaloptions.push({'label':'Offline card','value':'Offline card'});
                finaloptions.push({'label':'NETS','value':'NETS'});
                
                component.set("v.options", finaloptions);
            }else{
                
            } 
        });
        $A.enqueueAction(action);
    },    
    processWalkIn: function(component, event, helper) {       
        var action = component.get("c.linkDummyCstmr");
        component.set("v.isAdhocPOSServices",false);
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
               //alert(response.getReturnValue());
            	var instdAcc = response.getReturnValue();
                var name = instdAcc.FirstName+' '+instdAcc.LastName;
                component.set("v.accCstmrId", instdAcc.Id);
                component.set("v.accName", name);
                
                var finaloptions = [];
                finaloptions.push({'label':'Cash','value':'Cash'});
                finaloptions.push({'label':'Offline card','value':'Offline card'});
                finaloptions.push({'label':'NETS','value':'NETS'});
               
                component.set("v.options", finaloptions);
            }else{
                
            } 
        });
        $A.enqueueAction(action);
    }, 

    // added by :jatin: 25-Feb-2020: for manage Adho booking invoice table
    processAdhocPOSServices: function(component, event, helper) {   
        component.set("v.isItemSearch", false);
        component.set("v.isItemSearchError", '' );
        var cmpTarget = component.find('processAdhocPOSServicesBtn');
        if(component.get("v.isAdhocPOSServices")){
            component.set("v.isAdhocPOSServices",false);
            var serviceList = [];
            component.set("v.slcdProducts", serviceList);
            $A.util.removeClass(cmpTarget, 'btn_AdhocPOSServicesEnable');
            $A.util.addClass(cmpTarget, 'btn_AdhocPOSServicesDisable'); 
            component.set("v.adhocPOSServicesName","");
            event.getSource().set('v.label','Adhoc POS Services');
        }else{
            component.set("v.isAdhocPOSServices",true);
            var adhocServiceList = [];
            component.set("v.slcdProducts", adhocServiceList);
            $A.util.removeClass(cmpTarget, 'btn_AdhocPOSServicesDisable');
            $A.util.addClass(cmpTarget, 'btn_AdhocPOSServicesEnable'); 
            component.set("v.adhocPOSServicesName","");
            event.getSource().set('v.label','Inventory Item');
        }
        
        if(component.get("v.isAdhocPOSServices")){
            var action = component.get("c.getPocAdhocServicesNames");
            var slcdCntr     = component.get("v.slcdCentr");
            console.log('slcdCntr',component.get("v.slcdCentr"));
            action.setParams({"centerId" : slcdCntr});
            action.setCallback(this,function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    var serviceList =  response.getReturnValue(); 
                    var serviceMap = [];
                    console.log(Object.keys(serviceList).length);
                    if(Object.keys(serviceList).length > 0){
                        for(var key in serviceList){
                            serviceMap.push({key: key, value: serviceList[key]});
                        }
                        component.set("v.adhocPOSServicesOptions", serviceMap);
                    }else{
                        component.set("v.isItemSearch", true);
                        component.set("v.isItemSearchError", 'Adhoc Pos Service Not Found' );
                    }
                    // added by jatin: 26-feb-2020: If isAdhocPOSServices button is click this we blank this list for manage sage list
                    
                }else{
                    
                } 
            });
            $A.enqueueAction(action);
        }
    }, 
    getPosInvoiceItems: function(component, event, helper) {     
        var adhocPOSServicesValue     = component.get("v.adhocPOSServicesName");
        var totAmt   = 0;
        var gstPrcntAmt = 0;
        var grandTot = 0;
        var serviceList =[];
        if(adhocPOSServicesValue && adhocPOSServicesValue != '' && adhocPOSServicesValue!= undefined){
            component.set("v.isItemSearch", false);
            component.set("v.isItemSearchError", '' );
             serviceList = component.get("{!v.slcdProducts}"); 
            if(serviceList == null)
            serviceList = [];
            
            for(var i = 0; i < serviceList.length; i++){
                if(serviceList[i].price > 0)
                    totAmt = parseInt(totAmt) +  parseInt(serviceList[i].price);
            }
            
            var indxNo = serviceList.length + 1;
            
            //element.recNo+'##'+element.item+'##'+element.category+'##'+element.quantity+'##'+element.price;
            var dataList = adhocPOSServicesValue.split("-");
            serviceList.push({indexNo:indxNo, recNo: dataList[0], category: dataList[2], quantity: 1, price: dataList[3], item: dataList[1], singleQunPrice: dataList[3]});
            //slcdProducts.push({recNo: valueId, item: value});
            component.set("v.slcdProducts", serviceList);
            
            console.log(parseInt(dataList[3]));
            if(dataList[3])
                totAmt = parseInt(totAmt) + parseInt(dataList[3]);
            
            
            if(component.get("v.gstPrcnt"))
                gstPrcntAmt = (totAmt * component.get("v.gstPrcnt")) / 100;
                
            grandTot =  totAmt + gstPrcntAmt;   
            
            component.set("v.totalAmt", totAmt);
            component.set("v.gstPercntAmt", gstPrcntAmt);
            component.set("v.grandTot", grandTot);
        }else{
            component.set("v.slcdProducts", serviceList);
            component.set("v.isItemSearch", true);
            component.set("v.isItemSearchError", 'Select Any Adhoc POS Services Name!....' );
        }
    }, 
    openPaymentDetModel: function(component, event, helper) {
        if( (component.get("v.accName") == '' || component.get("v.accName")==undefined) && component.get("v.slcdProducts") ==null  
           && (component.get("v.slcdCentr")=='' || component.get("v.slcdCentr") == undefined) ) {
                component.set("v.isItemSearch",true);
                component.set("v.isCustomer",true);
                component.set("v.isCenter",true);
            
        }else if((component.get("v.accName") == '' || component.get("v.accName")==undefined) && component.get("v.slcdProducts") ==null){
            component.set("v.isItemSearch",true);
            component.set("v.isCustomer",true);
             component.set("v.isCenter",false);
        }else if(component.get("v.slcdCentr")==''){
            component.set("v.isCenter",true); 
        }else if(component.get("v.accName") == '' || component.get("v.accName")==undefined) {
            component.set("v.isCustomer",true); 
             component.set("v.isCenter",false); 
        }else if(component.get("v.slcdProducts") == null){
            component.set("v.isCustomer",false);  
            component.set("v.isItemSearch",true);
            component.set("v.isCenter",false);
        }else{
            component.set("v.isItemSearch",false);
            component.set("v.isCustomer",false); 
            component.set("v.isCenter",false); 
            component.set("v.payDetailModel", true);
        }
        
        
    },    
    closePaymentDetModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.payDetailModel", false);
        component.set("v.openPopUp",false);
    },    
    generateInvoice: function(component, event, helper){
        component.set("v.slcdPayType", component.find("mygroup").get("v.value"));
        
        if(component.find("mygroup").get("v.value")== 'Cash' || component.find("mygroup").get("v.value")=='Offline card' || 
          	component.find("mygroup").get("v.value")=='NETS'){
            component.set("v.openPopUp",true); 
            component.set("v.payDetailModel", false);
        }else{
            component.set("v.openPopUp",false); 
            component.set("v.payDetailModel", false);
            // Set isModalOpen attribute to false  
            var slcdCntr     = component.get("{!v.slcdCentr}");
            var slcdCstmr    = component.get("{!v.accCstmrId}");
            var slcdProducts = component.get("{!v.slcdProducts}"); 
            var slcdPayType  = component.find("mygroup").get("v.value"); 
            console.log('slcdCntr',slcdCntr);
            console.log('slcdCstmr',slcdCstmr);
            console.log('slcdProducts',slcdProducts);
            console.log('slcdPayType',slcdPayType);
            // alert(slcdCstmr);
            var action = component.get("c.payAndRedirect");
            action.setParams({"selectedCenter" : slcdCntr, "cstmrId":slcdCstmr, "slcdPayType":slcdPayType, "sgPrdItms" : slcdProducts,"enrolmentId":slcdEnrolmentId});
            
            action.setCallback(this,function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    var retRes = response.getReturnValue();
                    console.log('retRes',retRes);
                   // alert(retRes+'      '+retRes.startsWith('Error'));
                    if(!retRes.startsWith('Error')){
                        // var navEvent = $A.get("e.force:navigateToSObject");  
                        // navEvent.setParams({"recordId": response.getReturnValue()});
                        // navEvent.fire(); 
                        // var toastEvent = $A.get("e.force:showToast");
                        // toastEvent.setParams({
                        //     "title": "Success!",
                        //     "message": "Please wait... Payments Are Pending...",
                        //     "type":'success'
                        // });
                        // toastEvent.fire();
                        window.open('/'+response.getReturnValue(),"_self");
                    }else{
                         helper.showToast(component,event,'Error',retRes);
                    }
                    //alert(response.getReturnValue());
                    /*var instdAcc = response.getReturnValue();
                
                var name = instdAcc.FirstName+' '+instdAcc.LastName;
                component.set("v.accCstmrId", instdAcc.Id);
                component.set("v.accName", name);
                component.set("v.isModalOpen", false);*/
                    //  alert('sdfuc');
                }else{
                    component.set("v.openPopUp",false); 
                    component.set("v.payDetailModel", false);
                } 
            });
            $A.enqueueAction(action);
        }
       
    },   
    // added by ravi
    saveGenerateInvoice:function (component,event,helper){
       // alert(component.get("{!v.slcdPayType}"));
        
        
        // Set isModalOpen attribute to false 
        component.set("v.openPopUp",false); 
        component.set("v.payDetailModel", false); 
        var slcdCntr     = component.get("{!v.slcdCentr}");
        var slcdCstmr    = component.get("{!v.accCstmrId}");
        var slcdProducts = component.get("{!v.slcdProducts}"); 
        var slcdPayType  = component.get("{!v.slcdPayType}");
        var slcdEnrolmentId  = component.get("{!v.slcdEnrolmentId}"); 
        console.log('slcdCntr',slcdCntr);
        console.log('slcdCstmr',slcdCstmr);
        console.log('slcdProducts',slcdProducts);
        console.log('slcdPayType',slcdPayType);
        
        var action = component.get("c.payAndRedirect");
        action.setParams({"selectedCenter" : slcdCntr, "cstmrId":slcdCstmr, "slcdPayType":slcdPayType, "sgPrdItms" : slcdProducts,"enrolmentId":slcdEnrolmentId});
        
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                // var navEvent = $A.get("e.force:navigateToSObject");  
                // console.log(response.getReturnValue());
                // navEvent.setParams({"recordId": response.getReturnValue()});
                // navEvent.fire(); 
               // alert(response.getReturnValue());
                /*var instdAcc = response.getReturnValue();
                
                var name = instdAcc.FirstName+' '+instdAcc.LastName;
                component.set("v.accCstmrId", instdAcc.Id);
                component.set("v.accName", name);
                component.set("v.isModalOpen", false);*/
                  //  alert('sdfuc');
                //   var toastEvent = $A.get("e.force:showToast");
                //   toastEvent.setParams({
                //       "title": "Success!",
                //       "message": "Please wait... Payments Are Pending...",
                //       "type":'success'
                //   });
                //   toastEvent.fire();
                window.open('/'+response.getReturnValue(),"_self");
                }else{
                    
                } 
            });
        $A.enqueueAction(action);
        
    },    

    // added by jatin: 26-Feb-2020:if  POSService price will change then manage Gst and grand total
    onChangeAdhocServicePrice:function (component,event,helper){
      
        var totAmt   = 0;
        var gstPrcntAmt = 0;
        var grandTot = 0;
        
        var slcdProducts = component.get("v.slcdProducts"); 
        
        for(var i = 0; i < slcdProducts.length; i++){           
            if(slcdProducts[i].price > 0 ){                
                totAmt = parseFloat(totAmt) +  (parseFloat(slcdProducts[i].price));
            }
        }
        component.set("v.slcdProducts", slcdProducts);
        
        //element.recNo+'##'+element.item+'##'+element.category+'##'+element.quantity+'##'+element.price;
       /* var dataList = valueId.split("##");
        slcdProducts.push({recNo: dataList[0], category: dataList[2], quantity: dataList[3], price: dataList[4], item: value});
        //slcdProducts.push({recNo: valueId, item: value});
        component.set("v.slcdProducts", slcdProducts);
        
        console.log(parseInt(dataList[4]));
        if(dataList[4])
            totAmt = parseInt(totAmt) + parseInt(dataList[4]);
        */
        
        if(component.get("v.gstPrcnt"))
            gstPrcntAmt = (totAmt * component.get("v.gstPrcnt")) / 100;
        
        grandTot =  totAmt + gstPrcntAmt;   
        
        component.set("v.totalAmt", totAmt.toFixed(2));
        component.set("v.gstPercntAmt", gstPrcntAmt.toFixed(2));
        component.set("v.grandTot", grandTot.toFixed(2));
    },
    
    onChangeQuantity:function (component,event,helper){
      
        var totAmt   = 0;
        var gstPrcntAmt = 0;
        var grandTot = 0;
        
        var slcdProducts = component.get("{!v.slcdProducts}"); 
        
        for(var i = 0; i < slcdProducts.length; i++){           
            if(slcdProducts[i].singleQunPrice > 0 && slcdProducts[i].quantity > 0){                
                totAmt = parseInt(totAmt) +  (parseInt(slcdProducts[i].singleQunPrice * slcdProducts[i].quantity));
                slcdProducts[i].price = (parseInt(slcdProducts[i].singleQunPrice * slcdProducts[i].quantity));
            }
        }
        component.set("v.slcdProducts", slcdProducts);
        
        //element.recNo+'##'+element.item+'##'+element.category+'##'+element.quantity+'##'+element.price;
       /* var dataList = valueId.split("##");
        slcdProducts.push({recNo: dataList[0], category: dataList[2], quantity: dataList[3], price: dataList[4], item: value});
        //slcdProducts.push({recNo: valueId, item: value});
        component.set("v.slcdProducts", slcdProducts);
        
        console.log(parseInt(dataList[4]));
        if(dataList[4])
            totAmt = parseInt(totAmt) + parseInt(dataList[4]);
        */
        
        if(component.get("v.gstPrcnt"))
            gstPrcntAmt = (totAmt * component.get("v.gstPrcnt")) / 100;
        
        grandTot =  totAmt + gstPrcntAmt;   
        
        component.set("v.totalAmt", totAmt);
        component.set("v.gstPercntAmt", gstPrcntAmt);
        component.set("v.grandTot", grandTot);
	},
    showSpinner : function(component,event,helper){
        component.set("v.toggleSpinner", true);  
    },
    hideSpinner : function(component,event,helper){
        component.set("v.toggleSpinner", false);
    },
    openItemDetailModel: function(component, event, helper) {
    	component.set("v.isOpenItemDetail", true);
    },
    closeItemDetailModel: function(component, event, helper) {
    	component.set("v.isOpenItemDetail", false);
    },
    slctdItmDetils: function(component, event, helper){
       
        var className = event.getSource().get("v.class");
        var indexVal = className.split('_');
        var finalIndVal = parseInt(indexVal[1])-1;  
        
        var slcdProducts = component.get("{!v.slcdProducts}"); 
        var singleProdct = slcdProducts[finalIndVal];
        
        
        
        var action = component.get("c.getSageProductItemWareHouseDetails");
        action.setParams({"slcdItm" : singleProdct});
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
               // alert(response.getReturnValue());
                component.set('v.wareHouseItemDetailList', response.getReturnValue());
                component.set("v.slcdSingleProduct", singleProdct);
               
                component.set("v.isOpenItemDetail", true);
            } 
        });
        $A.enqueueAction(action);
        
         //openItemDetailModel(component, event, helper);
    },
})