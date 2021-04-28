({
    callSalesCase:function(component,event,searchKeys){
    	var action = component.get("c.findSalesEnquiryCases");
        // 28-Apr-2021: nishi: as per discussion with rajesh we shoq  piano rental or salesenquirey  list view according to isSalesEnquiery 
        var isSalesEnquiery=component.get('v.isSalesEnquiery');
        action.setParams({
          "searchKey": searchKeys,
          "isSalesEnquiery":isSalesEnquiery,
        });
        action.setCallback(this, function(response) {
            var result = response.getState();
            if(result == 'SUCCESS'){
                var total=response.getReturnValue().length;
                component.set("v.totalCount",response.getReturnValue().length);
                for(var i=0;i<total;i++){
                    if( response.getReturnValue()[i].OwnerId.substring(0, 3)=='00G'){
                        response.getReturnValue()[i].checkBoxValue='00G';
                    }else{
                        response.getReturnValue()[i].checkBoxValue='00S';
                    }
                }
                component.set("v.Cases", response.getReturnValue());
                component.set("v.centerId",searchKeys);
            }
            else{
                console.log(response.getError());
            }
        });
    	$A.enqueueAction(action);
    }
})