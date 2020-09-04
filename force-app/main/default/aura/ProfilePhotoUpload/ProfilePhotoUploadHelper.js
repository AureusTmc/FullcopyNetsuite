({
    //MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    uploadHelper: function(component, event) {
        var fileInput = component.find("fileId").get("v.files");
        //alert(fileInput[0]);
        var file = fileInput[0];
        var self = this;
        var objFileReader = new FileReader(); 
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            
            fileContents = fileContents.substring(dataStart);
            self.uploadProcess(component, file, fileContents);
        });
        
        objFileReader.readAsDataURL(file);
    },
    
    uploadProcess: function(component, file, fileContents) {
        var startPosition = 0;
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '');
    },
    
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId) {
        var getchunk = fileContents.substring(startPosition, endPosition);
       // alert(component.get("v.accId"));
        var action = component.get("c.saveFile");
        action.setParams({
            parentId: component.get("v.accId"), 
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.attId",response.getReturnValue());
                component.set("v.isImgText",false);
                component.set("v.isModalOpen", false);
                component.set("v.btnShow", true); 
                
            } else if (state === "ERROR") {
                console.log("Error message: " + errors[0].message);
                console.log('error');
                var errors = response.getError();
                console.log(response.getError());
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})