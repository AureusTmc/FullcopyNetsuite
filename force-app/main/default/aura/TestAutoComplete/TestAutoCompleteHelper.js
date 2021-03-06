({
    searchRecords : function(component, searchString) {
        console.log('component.get("v.objectApiName")',component.get("v.objectApiName"));
        var action = component.get("c.getRecords");
        action.setParams({
            "searchString" : searchString,
            "objectApiName" : component.get("v.objectApiName"),
            "idFieldApiName" : component.get("v.idFieldApiName"),
            "valueFieldApiName" : component.get("v.valueFieldApiName"),
            "extendedWhereClause" : component.get("v.extendedWhereClause"),
            "maxRecords" : component.get("v.maxRecords")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                const serverResult = response.getReturnValue();
                const results = [];
                serverResult.forEach(element => {
                    const result = {id : element[component.get("v.idFieldApiName")], value : element[component.get("v.valueFieldApiName")]};
                    results.push(result);
                });
                component.set("v.results", results);
                if(serverResult.length>0){
                    component.set("v.openDropDown", true);
                }
            } else{
                var toastEvent = $A.get("e.force:showToast");
                if(toastEvent){
                    toastEvent.setParams({
                        "title": "ERROR",
                        "type": "error",
                        "message": "Something went wrong!! Check server logs!!"
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },  
    sageProducts : function(component, searchString, serverResult){
      //  alert(searchString);
        const results = [];
        serverResult.forEach(element => {
           
            if(element.item.toLowerCase().includes(searchString.toLowerCase())){
				// const result = {id : element.recNo, value : element.item};
				var itemValue = element.recNo+'##'+element.item+'##'+element.category+'##'+element.quantity+'##'+element.price;
            	const result = {id : itemValue, value : element.item};
                results.push(result);
    		}
        });
		component.set("v.results", results);
		if(serverResult.length>0){
    		component.set("v.openDropDown", true);
		}
	},
});