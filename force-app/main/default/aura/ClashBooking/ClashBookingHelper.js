({
    getDateHelp:function(comp,event){
       var action= comp.get("c.getDate");
        action.setCallback(this,function(response){
            if(response.getState()== 'SUCCESS'){
                comp.set("v.datetyp",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})