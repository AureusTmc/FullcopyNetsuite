({
    handleUploadFinishedImage: function (cmp, event) {
        // This will contain the List of File uploaded data and status
        var uploadedFiles = event.getParam("files");
        
        cmp.set('v.imageFileId',uploadedFiles[0]['documentId']);
        cmp.set('v.imageUploadStatus',uploadedFiles[0]['name']+' is uploading');
        
        var saveImageAction = cmp.get('c.createProfileImage');
        saveImageAction.setParams({parentId : cmp.get('v.recordId'),parentName :cmp.get('v.ParentRecord.Name'), documentId:cmp.get('v.imageFileId')});
        saveImageAction.setCallback(this,function(response){
            var res = response.getState();            
            console.log(res);
            if(res == 'SUCCESS'){
                cmp.set('v.imageUploadStatus',uploadedFiles[0]['name']+' uploaded successfully');        
            }
        });
        $A.enqueueAction(saveImageAction);
    },
    
    handleClose : function(component, event){
        $A.get("e.force:closeQuickAction").fire();
    },
    
    handleDone : function(component, event){
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire();
    },
})