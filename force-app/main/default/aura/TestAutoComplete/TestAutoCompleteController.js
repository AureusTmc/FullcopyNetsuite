({
    doInit : function (component, event, helper) {
       // alert(component.get("v.inputValue") +'<---->'+component.get("v.selectedOption"));
      /*  if(component.get("v.inputValue")){
            component.set("v.inputValue", component.get("v.selectedOption"));
            component.set("v.openDropDown", false);
            component.set("v.selectedOption", component.get("v.inputValue"));
        }*/
    },    
    searchHandler : function (component, event, helper) {
        const searchString = event.target.value;
        console.log('component.get("v.SageProductItems")',component.get("v.SageProductItems"));
        if (searchString.length >= 3) {
            //Ensure that not many function execution happens if user keeps typing
            if (component.get("v.inputSearchFunction")) {
                clearTimeout(component.get("v.inputSearchFunction"));
            }

            var inputTimer = setTimeout($A.getCallback(function () {
                var objName = component.get("v.objectApiName");
              //  alert(objName);
				if(objName != 'SageProduct')                    
                	helper.searchRecords(component, searchString);
                else
                	helper.sageProducts(component, searchString, component.get("v.SageProductItems"));
            }), 1000);
            component.set("v.inputSearchFunction", inputTimer);
        } else{
            component.set("v.results", []);
            component.set("v.openDropDown", false);
        }
    },

    optionClickHandler : function (component, event, helper) {
        const selectedId = event.target.closest('li').dataset.id;
        const selectedValue = event.target.closest('li').dataset.value;
//        alert(event.target.closest('li').dataset.quantity);
        component.set("v.inputValue", selectedValue);
        component.set("v.openDropDown", false);
        component.set("v.selectedOption", selectedId);
        
      //  alert(selectedId +'++++'+selectedValue);
        var myEvent = $A.get("e.c:PosHomeCmpEvent");
        myEvent.setParams({"inputValue": selectedValue});
        myEvent.setParams({"selectedOption": selectedId});
        myEvent.fire();
    },

    clearOption : function (component, event, helper) {
        component.set("v.results", []);
        component.set("v.openDropDown", false);
        component.set("v.inputValue", "");
        component.set("v.selectedOption", "");
    },
})