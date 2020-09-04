({
    //Fetch all documents
    populatedoclistMap : function(component, event) {
		var action = component.get('c.getDocumentMap');
        action.setParams({
            recordId : component.get('v.accountRecordId')
        });
        action.setCallback(this, function(response){
            if(response.getState()==='SUCCESS'){
                if(!$A.util.isEmpty(response.getReturnValue())){
                    component.set('v.docListMap',response.getReturnValue());
                }
            }
            if(response.getState()==='ERROR'){
                var errors = action.getError();
                alert(errors[0].message);
            }
        });
        $A.enqueueAction(action);
	},
    
	//Populate file details    
    populateFileDetails : function(component, event, rectypeName) {
        
		var action = component.get('c.getFileList');       
        action.setParams({
            recordId : component.get('v.accountRecordId')
        });
        action.setCallback(this, function(response){
            if(response.getState()==='SUCCESS'){
                if(!$A.util.isEmpty(response.getReturnValue())){
                    component.set('v.fileWrapList',response.getReturnValue());
                    var result=response.getReturnValue();
                    var fileWrapLArr=[];
                    console.log('Hi');
                    console.log(fileWrapLArr);
                    fileWrapLArr.push(JSON.parse(JSON.stringify({'toUploadList':result[0].toUploadList})));
                    fileWrapLArr[0].uploadedList=JSON.parse(JSON.stringify([]));
                    //var reLink=[];
                    console.log(fileWrapLArr);
                    for(var fileWrapL in result[0].uploadedList)
                        {
                            console.log(fileWrapL);
                            console.log(result[0].uploadedList);
                            fileWrapLArr[0].toUploadList.push(result[0].toUploadList[0]);
                            if(result[0].uploadedList[fileWrapL].objType!='Contract'){}
                            else{
                                console.log('SK');
                                console.log(result[0].uploadedList[fileWrapL]);
                                if(result[0].uploadedList[fileWrapL].objType!='Contract'){}
                                else{
                                    fileWrapLArr[0].uploadedList.push(result[0].uploadedList[fileWrapL]);
                                    console.log(fileWrapLArr[0].uploadedList);
                                    console.log(fileWrapLArr[0].uploadedList.length);
                                    fileWrapLArr[0].uploadedList[fileWrapLArr[0].uploadedList.length-1].reLink=JSON.parse(JSON.stringify(result[0].toUploadList[0]));
                                }
                            }
                        }
                    component.set('v.fileWrapListContract',fileWrapLArr);
                    
                    console.log(component.get('v.fileWrapList'));
                    console.log(component.get('v.fileWrapListContract'));
                }
            }
            if(response.getState()==='ERROR'){
                var errors = action.getError();
                alert(errors[0].message);
            }
        });
        $A.enqueueAction(action);
	},
    
    //Add new wrap variable to the list
    addRows : function(component, event){
        $A.util.removeClass(component.find('mySpinner'),'slds-hide');
        var action = component.get('c.addNewRow');
        
        var jsonString = JSON.stringify(component.get('v.fileWrapList'));
        var record = component.get('v.simpleRecord');
        
        action.setParams({
            recordId : component.get('v.accountRecordId'),
            jsonStr : jsonString
        });
        action.setCallback(this, function(response){
            if(response.getState()==='SUCCESS'){
                if(!$A.util.isEmpty(response.getReturnValue())){
                    component.set('v.fileWrapList',response.getReturnValue());
                }
            }
            if(response.getState()==='ERROR'){
                var errors = action.getError();
                alert(errors[0].message);
            }
            $A.util.addClass(component.find('mySpinner'),'slds-hide');
        });
        $A.enqueueAction(action);
    },
    
    //Remove a row from the list
    removeNewRow : function(component, event, listType){
        var idx = event.getSource().get('v.accesskey');
        var wrapList = component.get('v.fileWrapList');
        if(idx>-1){
            if(listType=='first'){
                wrapList[0].toUploadList.splice(idx,1); 
            }
            if(listType=='second'){
                wrapList[0].uploadedList.splice(idx,1); 
            }
        }
        component.set('v.fileWrapList',wrapList);
    },    
    
    //Map file base 64 and original file name
    handleFileUpload : function(component, event,listType){
        var idx = event.getSource().get('v.accesskey');
        var files = event.getSource().get("v.files");
        var wrapList = component.get("v.fileWrapList"); 
        console.log(files);
        if(files[0].size>2000000){
			alert("File size cannot be greater than 2 MB");            
        }else{
            if(!$A.util.isEmpty(files)){
                var originalFileName = event.getSource().get("v.files")[0]['name'];
                if(listType=='first'){
                    wrapList[0].toUploadList[idx].original_filename=originalFileName; 
                }
                if(listType=='second'){
                    wrapList[0].uploadedList[idx].original_filename=originalFileName; 
                }
                
                var reader = new FileReader();
                reader.onloadend = function() {
                    var dataURL = reader.result;
                    var content = dataURL.match(/,(.*)$/)[1];
                    if(listType=='first'){
                        wrapList[0].toUploadList[idx].file_base64=content;
                       // wrapList[0].toUploadList[idx].file=files[0]; //Using for file upload without base64
                    }
                    if(listType=='second'){
                        wrapList[0].uploadedList[idx].file_base64=content; 
                    }
                }
                reader.readAsDataURL(event.getSource().get("v.files")[0]);
                component.set("v.fileWrapList",wrapList);
            }
        }
        
    },
    
    //Save Method
    saveAll : function(component, event){
        $A.util.removeClass(component.find('mySpinner'),'slds-hide');
        var action = component.get('c.saveFiles');
        console.log(component.get('v.fileWrapList'));
        action.setParams({
            recId : component.get('v.accountRecordId'),
            jsonStr : JSON.stringify(component.get('v.fileWrapList'))
            //blbFile:component.get('v.fileWrapList')
        });
        action.setCallback(this, function(response){
            
            if(response.getState()==='SUCCESS'){
                if(response.getReturnValue()!=undefined){
                    var resp = response.getReturnValue();
                    if(resp.includes('Success')){
                        $A.get("e.force:closeQuickAction").fire();
                        var showToast = $A.get("e.force:showToast"); 
                        showToast.setParams({ 
                            'title' : 'Success',
                            'message' : 'Documents added successfully!',
                            'type': 'success'
                        }); 
                        showToast.fire();
                        $A.get('e.force:refreshView').fire();
                    }
                }
            }
            if(response.getState()==='ERROR'){
                var errors = action.getError();
                alert(errors[0].message);
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    reLink : function(component, event){
        $A.util.removeClass(component.find('mySpinner'),'slds-hide');
        var action = component.get('c.updateFiles');
        action.setParams({
            recId : component.get('v.accountRecordId')
        });
        action.setCallback(this, function(response){
            if(response.getState()==='SUCCESS'){
                if(response.getReturnValue()!=undefined){
                    var resp = response.getReturnValue();
                    if(resp.includes('Success')){
                        $A.get("e.force:closeQuickAction").fire();
                        var showToast = $A.get("e.force:showToast"); 
                        showToast.setParams({ 
                            'title' : 'Success',
                            'message' : 'Documents added successfully!',
                            'type': 'success'
                        }); 
                        showToast.fire();
                        $A.get('e.force:refreshView').fire();
                    }
                }
            }
            if(response.getState()==='ERROR'){
                var errors = action.getError();
                alert(errors[0].message);
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    
    deleteContentVersion : function(component, event){
        if(confirm('Are you sure?')){
            $A.util.removeClass(component.find('mySpinner'),'slds-hide');
            var selid = event.currentTarget.dataset.selid;
            var objid = event.currentTarget.dataset.objid;
            var docid = event.currentTarget.dataset.docid;
            var idx = event.currentTarget.dataset.idx;
            
            var action = component.get("c.removeFile");
            action.setParams({
                'recordId' : selid,
                'objectId' : objid,
                'docId' : docid
            });
            action.setCallback(this, function(response){
                if(response.getState()==='SUCCESS'){
                    var wrapList = component.get('v.fileWrapList');
                    if(idx>-1){ 
                        wrapList[0].uploadedList.splice(idx,1); 
                    }
                    component.set('v.fileWrapList',wrapList);
                }
                if(response.getState()==='ERROR'){
                    var errors = action.getError();
                    alert(errors[0].message);
                }
                $A.util.addClass(component.find('mySpinner'),'slds-hide');
            });
            $A.enqueueAction(action);
        }
    },
    deleteContentVersionExisting : function(component, event){
        if(confirm('Are you sure?')){
            $A.util.removeClass(component.find('mySpinner'),'slds-hide');
            var acckey=document.getElementById("delete-exist").accessKey;
    		var wrapList = component.get('v.fileWrapListContract')[0].uploadedList;
            console.log(wrapList);
            console.log(wrapList[acckey]);
            console.log(wrapList[acckey].conv);
            console.log(wrapList[acckey].conv.Id);
            
            var action = component.get("c.removeFile");
            action.setParams({
                'recordId' : wrapList[acckey].conv.Id,
                'objectId' : '',
                'docId' : ''
            });
            action.setCallback(this, function(response){
                if(response.getState()==='SUCCESS'){
                    //var wrapList = component.get('v.fileWrapList');
                    if(acckey>-1){ 
                        wrapList.splice(acckey,1); 
                    }
                    component.set('v.fileWrapListContract',wrapList);
                }
                if(response.getState()==='ERROR'){
                    var errors = action.getError();
                    //alert(errors[0].message);
                }
                $A.util.addClass(component.find('mySpinner'),'slds-hide');
            });
            $A.enqueueAction(action);
        }
    }
})