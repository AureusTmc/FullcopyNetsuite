({
      
    updateDataset : function(component, event, helper) {
        var searchKeys = event.getParam("searchKey");
        $A.createComponent(
            "c:EnrolmentChart",
            {
                "searchKey": searchKeys
            },
            function(newChartComp, status, errorMessage){
                if(status == "SUCCESS"){
                    var body = component.get("v.body");
                    if(body)
                    {
                        body.pop(); // Remove the old body
                        body.push(newChartComp);  // Add the new version of the component to the body
                        component.set("v.body",body);
                    }
                    
                } 
            }
        );
    }
})