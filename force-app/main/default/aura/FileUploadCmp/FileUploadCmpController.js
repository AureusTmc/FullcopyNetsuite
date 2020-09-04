({
    doInit : function(component, event, helper) {
        //No action needed
    },
    /**Used for**/
    selectFile : function(component, event, helper)
    {
        console.log(event.getSource().get('v.accesskey'));
        console.log(event.getSource().get('v.value'));
        var convarId=event.getSource().get('v.value');
        var filewrapList=component.get('v.fileWrapList').uploadedList;
        var updateConVerList=component.get('v.updateConVer');
        var updateConVerArr=[];
        const updateConVerListRes = updateConVerList.find( fruit => fruit.conv.Id === convarId );
        if(updateConVerListRes==null)
        {
            const result = filewrapList.find( fruit => fruit.conv.Id === convarId );
            updateConVerArr.push(result);
            component.set('v.updateConVer',updateConVerArr);
            console.log(result);
        }
        
        
        
    },
    //LDS handle record update 
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            var record = component.get('v.simpleRecord'); 
            
            if(component.get('v.sObjectName')=='Account'){
                component.set('v.accountRecordId',record.Id);
            }
            //Get Document List Map
            helper.populatedoclistMap(component, event);
            helper.populateFileDetails(component, event);	
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    
    //Add new rows
    addMoreRows : function(component, event, helper){
        helper.addRows(component, event);
    },
    
    //Remove a row from top section
    removeRowTop : function(component, event, helper){
        helper.removeNewRow(component,event,'first');    
    },
    
    //Remove a row from second section
    removeRowBottom : function(component, event, helper){
        helper.removeNewRow(component,event,'second');    
    },
    
    //File change on first section
    handleTopFilesChange : function(component, event, helper){
        helper.handleFileUpload(component, event,'first');
    },
    
    //File change in second section
    handleBottomFilesChange : function(component, event, helper){
        helper.handleFileUpload(component, event,'second');
    },
    
    //Map all the contact and outlet with their documents and make them appear
    populateDependent : function(component, event, helper){
        var idx = event.getSource().get('v.accesskey');
        var val = event.getSource().get('v.value');
        //alert(val);
        var fileWrap = component.get('v.fileWrapList');
        
        if(!$A.util.isEmpty(val)){
            fileWrap[0].toUploadList[idx].docList = component.get('v.docListMap')[val];
        }
        component.set('v.fileWrapList',fileWrap);
        
    },
     
    //Call the save method
    saveMethod : function(component, event, helper){
        console.log(component.get("v.fileWrapList"));
        var toUploadListDetail=component.get("v.fileWrapList")[0].toUploadList;
        var newfiletoUploadObjectCount=0;
        var newfiletoUploadCount=0;
        var newfiletoUploadFileCount=0;
        var uniqueDocs = '';
        for(var tuld in toUploadListDetail )
            {
                console.log(tuld);
                if(toUploadListDetail[tuld].selectedDoc!='-- Select --')
                {
                    console.log('Hi');
                    newfiletoUploadObjectCount++;
                                        
                    newfiletoUploadCount++;
                    
                    console.log('toUploadListDetail[tuld].file_base64'+toUploadListDetail[tuld].file_base64);
                    if(toUploadListDetail[tuld].file_base64!='')
                    {
                        newfiletoUploadFileCount++;
                        console.log('Inside saveMethod');
                        if(uniqueDocs.includes(toUploadListDetail[tuld].selectedDoc)){
                            alert('ERROR! Uploaded file type should be unique');
                            return;
                        }else{
                            uniqueDocs = toUploadListDetail[tuld].selectedDoc + ';';
                        }
                        
                    }
                    
                }
               
			                  
            }
        console.log('newfiletoUploadCount'+newfiletoUploadCount);
        console.log('newfiletoUploadFileCount'+newfiletoUploadFileCount);
        console.log('newfiletoUploadObjectCount'+newfiletoUploadObjectCount);
        console.log(newfiletoUploadCount!=newfiletoUploadFileCount!=newfiletoUploadObjectCount);
         if(newfiletoUploadCount==0 && newfiletoUploadFileCount==0 && newfiletoUploadObjectCount==0)
                {
                    alert('ERROR! Please retry after uploading the file(s)');
                }
                else if(newfiletoUploadCount!=newfiletoUploadFileCount || newfiletoUploadFileCount!=newfiletoUploadObjectCount || newfiletoUploadCount!=newfiletoUploadObjectCount)
                {
                    alert('ERROR! Please retry after uploading the file(s)');
                }
                else
                    {
                        helper.saveAll(component, event)
                    }
        
    },
    
    //Close Window
    closeModal : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    },
    
    //Method to delete files from system
    deletFile : function(component, event, helper){
        helper.deleteContentVersion(component,event);
    },
    //Method to delete existing files of contract from system
    deletExistFile : function(component, event, helper){
        helper.deleteContentVersionExisting(component,event);
    },
    openModel: function(component, event, helper) {
      // for Display Model,set the "isOpen" attribute to "true"
      component.set("v.isOpen", true);
   },
 
   closeModel1: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   },
 
   likenClose: function(component, event, helper) {
      // Display alert message on the click on the "Like and Close" button from Model Footer 
      // and set set the "isOpen" attribute to "False for close the model Box.
      //alert('thanks for like Us :)');
      component.set("v.isOpen", false);
       helper.reLink(component, event);
      
   },
})