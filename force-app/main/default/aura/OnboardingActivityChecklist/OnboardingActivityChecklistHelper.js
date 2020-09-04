({
    getMaster : function(component,event,dateofjoining,isJoin) {
        var action = component.get("c.getMasterCheckList");
        action.setParams({
            'EmployeeId': component.get("v.recordId"),
            'DateOfJoining': dateofjoining,
            'isJoining': isJoin 
        }); 
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS" && response.getReturnValue()!= null){
                component.set("v.DocumentList",response.getReturnValue().masterDocumentListData);
                component.set("v.masterCheckLists",response.getReturnValue().masterListData);
                component.set("v.masterCheckExitLists",response.getReturnValue().masterListExitData);
                component.set("v.static_masterCheckLists",response.getReturnValue().masterListData);
                component.set("v.static_masterCheckExitLists",response.getReturnValue().masterListExitData);
                component.set("v.joiningDate",response.getReturnValue().EmployeeJoiningDate);
                component.set("v.EmployeeName",response.getReturnValue().Employee.Name);
                component.set("v.employee",response.getReturnValue().Employee);
                component.set("v.EmployeeStatus",response.getReturnValue().Employee.Status__c );
                component.set("v.ContractEndDate",response.getReturnValue().Employee.Last_Working_Date__c);
                component.set("v.checkListItemTemplateOnBoarding",response.getReturnValue().CheckListItemTemplateOnBoarding);
                component.set("v.checkListItemTemplateExit",response.getReturnValue().CheckListItemTemplateExit);
                component.set("v.stages",response.getReturnValue().EmployeeStageValues );
                component.set("v.exitTypeList",response.getReturnValue().exitTypeList );
                if(response.getReturnValue().Employee.Employee_Status__c != 'Draft'){
                    component.set("v.isDraft",true );
                }
                //sorting the document result by selected or not selected.
                var listDocument = component.get("v.DocumentList");
                var newListDocumentChecked = [];
                var newListDocumentNotChecked = [];
                if(listDocument){
                    for(var i=0; i < listDocument.length; i++){
                        if(listDocument[i].isChecked){
                            newListDocumentChecked.push(listDocument[i]);
                        }else{
                            newListDocumentNotChecked.push(listDocument[i]);
                        }
                    }
                    for(var k=0; k < newListDocumentNotChecked.length; k++){
                        newListDocumentChecked.push(newListDocumentNotChecked[k]);
                    }
                }
                component.set("v.DocumentList",newListDocumentChecked);
                //sorting the checklist item result by selected or not selected.
                var list ;
                if(component.get("v.activity") == 'ExitProcess'){
                    list = component.get("v.masterCheckExitLists");
                }else if(component.get("v.activity") == 'OnboardingProcess'){
                    list = component.get("v.masterCheckLists");
                }
                var newListChecked = [];
                var newListNotChecked = [];
                if(list){
                    for(var i=0; i < list.length; i++){
                        if(list[i].isChecked){
                            newListChecked.push(list[i]);
                        }else{
                            newListNotChecked.push(list[i]);
                        }
                    }
                    for(var k=0; k < newListNotChecked.length; k++){
                        newListChecked.push(newListNotChecked[k]);
                    }
                }
                if(component.get("v.activity") == 'ExitProcess'){
                    component.set("v.masterCheckExitLists",newListChecked);
                }else if(component.get("v.activity") == 'OnboardingProcess'){
                    component.set("v.masterCheckLists",newListChecked);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    getMasterCheckListByTemplateId : function(component,event,tId) {
        var action = component.get("c.getMasterCheckListItemByTemplate");
        action.setParams({
            'templateId': tId,
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS" && response.getReturnValue()!= null){
                var rtIdList = response.getReturnValue();
                var list ;
                if(component.get("v.activity") == 'ExitProcess'){
                    list = component.get("v.static_masterCheckExitLists");
                }else if(component.get("v.activity") == 'OnboardingProcess'){
                    list = component.get("v.static_masterCheckLists");
                }
                var newListChecked = [];
                var newListNotChecked = [];
                if(list){
                    for(var i=0; i < list.length; i++){
                        list[i].isChecked = false;
                        console.log(list[i]);
                        for(var j=0; j < rtIdList.length; j++){
                            if(rtIdList[j] == list[i].master_check.Id){
                                list[i].isChecked = true;
                            }
                        }
                        if(list[i].isChecked){
                            newListChecked.push(list[i]);
                        }else{
                            newListNotChecked.push(list[i]);
                        }
                    }
                    for(var k=0; k < newListNotChecked.length; k++){
                        newListChecked.push(newListNotChecked[k]);
                    }
                }
                if(component.get("v.activity") == 'ExitProcess'){
                    component.set("v.masterCheckExitLists",newListChecked);
                }else if(component.get("v.activity") == 'OnboardingProcess'){
                    component.set("v.masterCheckLists",newListChecked);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    saveCheckListItem : function(component,event) {
        var type = component.get("v.activity");
        var isSV = component.get("v.isSaveAsTemplate");
        var svName = component.get("v.saveAsTemplateName");
        if(type === 'OnboardingProcess'){
            type = 'Onboarding Process';
        }
        else if(type === 'ExitProcess'){
            type = 'Exit Process';
            isSV = component.get("v.isSaveAsExitTemplate");
            svName = component.get("v.saveAsTemplateExitName");
        }
        var action = component.get("c.generateCheckListItems");
        
        action.setParams({
            'masterLists': JSON.stringify(component.get("v.masterCheckLists")),
            'masterExitLists':JSON.stringify(component.get("v.masterCheckExitLists")),
            'EmployeeId': component.get("v.recordId"),
            'Employee': component.get("v.employee"),
            'masterDocumentLists': JSON.stringify(component.get("v.DocumentList")),
            'isSaveAs': isSV,
            'saveAsName': svName,
            'mType': type
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS" && response.getReturnValue()!= null){
                if(response.getReturnValue() != ''){
                    var toastEvent = $A.get("e.force:showToast");
                    if(toastEvent){
                        toastEvent.setParams({
                            "title": "Error!",
                            key: 'info_alt',
                            type: 'error',
                            "message": response.getReturnValue()
                        });
                        toastEvent.fire();
                    }else{alert(response.getReturnValue())}
                }else{
                    $A.get('e.force:refreshView').fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction").fire(); 
                    if(dismissActionPanel) dismissActionPanel.fire();
                }
            }
        });
        
        $A.enqueueAction(action);
    },
})