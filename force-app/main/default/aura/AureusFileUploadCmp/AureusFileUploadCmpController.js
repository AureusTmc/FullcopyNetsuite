({
    doInit: function(component, event, helper) {
        var action=  component.get('c.recordList');  
        action.setParams({"recordId":component.get('v.accId')});
        action.setCallback(this,function(response)  {
            var state=response.getState();            
            if(state ==='SUCCESS') {
                var custs = [];
                var conts = response.getReturnValue();
                for ( var key in conts ) {
                    custs.push({key:key,value:conts[key]});
                }
                component.set('v.recordMap',custs);  
                console.log(component.get('v.recordMap'));
            }
        });
        $A.enqueueAction(action);
    },
    deleteRecord :function(component, event, helper) {
        var ctarget = event.currentTarget;
        var index = ctarget.dataset.value;
        var action=  component.get('c.deleteRecordID');  
        action.setParams({ "recId":  index,"recordId":component.get('v.accId')});
        action.setCallback(this,function(response) {
            var state=response.getState();            
            if(state ==='SUCCESS')    {
                var custs = [];
                var conts = response.getReturnValue();
                
                for ( var key in conts ) {
                    custs.push({key:key,value:conts[key]});
                }
                component.set('v.recordMap',custs);  
                console.log(component.get('v.recordMap'));
            }
        });
        $A.enqueueAction(action);
    },
    handleFilesUploadChange: function(component, event, helper) {    
        component.set('v.Spinner',true);
        var filesA = component.get('v.uploadedFiles');
        var filesD = event.getSource().get("v.files");
        var filesAsArray = [].slice.call(filesD);
        var filesQ = filesA.concat(filesAsArray);
        component.set('v.uploadedFiles', filesQ);
        var fileName1 = "No file selected.";
        var fileCount1=component.get('v.uploadedFiles').length;
        var files='';
        var fileName;
        if (fileCount1 == 1) {
            fileName = component.find('fileInput').get('v.files')[0]['name'];
        }else{
            fileName=fileCount1+' files selected';
        }
        component.set("v.fileName1", fileName);
        helper.upload(component,event);
    },
})