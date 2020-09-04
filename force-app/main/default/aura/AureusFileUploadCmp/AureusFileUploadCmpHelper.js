({
    MAX_FILE_SIZE: 10485760, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000, //Chunk Max size 750Kb 
    upload: function(component,event) {
        var fileCount1=component.get('v.uploadedFiles').length;
        if(fileCount1 > 0){
            for (var i = 0; i < fileCount1; i++) 
            {
                this.uploadHelper(component, event,component.get('v.uploadedFiles')[i]);
            }
        }
    },
    uploadHelper: function(component, event,f) {
        var file = f;
        var self = this;
        if (file.size > self.MAX_FILE_SIZE) {
            //component.set("v.fileName1", 'Alert : File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
            component.set("v.fileName1", 'Alert : File size cannot exceed 10 MB.');
            component.set("v.Spinner",false);
            component.find('fileInput').set('v.files', []);
                component.set('v.uploadedFiles',[]);
            return;
        }
        
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
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition);
    },
    
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition) {
        // call the apex method 'saveFile'
        var getchunk = fileContents.substring(startPosition, endPosition);
        console.log('idnew'+component.get("v.accId"));
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
                
                var custs = [];
                var conts = response.getReturnValue();
                
                for ( var key in conts ) {
                    custs.push({key:key,value:conts[key]});
                }
                
                component.set('v.recordMap',custs);  
                component.find('fileInput').set('v.files', []);
                component.set('v.uploadedFiles',[]);
                component.set("v.fileName1", 'Drag your files here');
                component.set("v.Spinner",false);
                
            } else if (state === "ERROR") {
                console.log('error');
                var errors = response.getError();
                console.log(response.getError());
                console.log("Error message: " + errors[0].message);
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
    },
})