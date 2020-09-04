//Description: Controller for File Utility Lightning Component for uploading files 
public without sharing class FileUtilityController {
    public static list<Employee_Document__c> availabledoclist;
    
    public static void fillDocList(string recordId){
        availabledoclist = new list<Employee_Document__c>([SELECT Id,Name,Required__c 
                                                   FROM Employee_Document__c where Employee__c=:recordId and Uploaded__c=false ORDER BY Name ASC]);
    }
    
    //Method to create a map of Objects and it's all related documents
    @AuraEnabled
    public static map<String,List<Employee_Document__c>> getDocumentMap(string recordId){
        fillDocList(recordId);
        
        map<String,List<Employee_Document__c>> documentObjMap = new map<String,List<Employee_Document__c>>();
        if(availabledoclist.size()>0){
            documentObjMap.put('Account',availabledoclist);
        }
        
        return documentObjMap;
    }
    
    
    //Method to create file utility wrapper
    @AuraEnabled
    public static list<FileUtilityController.fileMasterWrapper> getFileList(String recordId){
        
        //Master set to store all record Ids for fetching all the uploaded documents
        set<Id> masterSet = new set<Id>();
        for(Employee_Document__c ed: [Select id from Employee_Document__c where Employee__c=:recordId]){
            masterSet.add(ed.Id);
        }
        
   
        //Wrapper List variable
        list<FileUtilityController.fileMasterWrapper> fileWrapList = new list<FileUtilityController.fileMasterWrapper>();
        //Wrapper variable
        FileUtilityController.fileMasterWrapper fwrap = new FileUtilityController.fileMasterWrapper();
        
        //Getting the content document Ids
        set<Id> contentDocIds = new set<Id>();
        Map<Id,ContentDocumentLink> cdMap=new Map<Id,ContentDocumentLink>();
        if(!masterSet.isEmpty()){
            for(ContentDocumentLink cdlink : [SELECT ContentDocumentId, LinkedEntityId  FROM 
                                              ContentDocumentLink where LinkedEntityId in:masterSet]){
                 contentDocIds.add(cdlink.ContentDocumentId);
            }
        }
        
        //Already Uploaded Files List
        if(contentDocIds!=null && contentDocIds.size()>0){
            for(ContentVersion cv : [SELECT ID,Title,Employee_Document__c,Employee_Document__r.Name,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId in: contentDocIds]){
                FileUtilityController.uploadedFileWrapper uploaded = new FileUtilityController.uploadedFileWrapper();
                uploaded.conv = cv;
                fwrap.uploadedList.add(uploaded);
            }
        }
        
        fillDocList(recordId);
     
        list<Employee_Document__c> docList = new list<Employee_Document__c>(availabledoclist);
        
        //Loop to show 3 files to upload on page load
        for(Integer i=0;i<3;i++){
            FileUtilityController.fileWrapper fileWrap = new FileUtilityController.fileWrapper();
            for(Employee_Document__c doc : docList){
                fileWrap.docList.add(doc);
            }
            fwrap.toUploadList.add(fileWrap);
        }
        
        fileWrapList.add(fwrap);
        return fileWrapList;
    } 
    
    //Method to add a new row 
    @AuraEnabled
    public static list<FileUtilityController.fileMasterWrapper> addNewRow(string recordId,String jsonStr){
        //Fill all the documents in list variable
        fillDocList(recordId);
        
        //Get the exisiting JSON 
        List<FileUtilityController.fileMasterWrapper> listwrap = (List< FileUtilityController.fileMasterWrapper >)System.JSON.deserialize(jsonStr,List< FileUtilityController.fileMasterWrapper>.class);
        FileUtilityController.fileWrapper fileWrap = new FileUtilityController.fileWrapper();
        list<Employee_Document__c> docList = new list<Employee_Document__c>(availabledoclist);
        
        //loop through all the exisiting file wrap and add a new wrap variable
        for( FileUtilityController.fileMasterWrapper fwrap : listwrap){
            for(Employee_Document__c doc : docList){
                fileWrap.docList.add(doc);
            }
            system.debug('fileWrap-->'+fileWrap);
            fwrap.toUploadList.add(fileWrap);
        }
        return listwrap;
    }
    //Method to delete files from system
    @AuraEnabled
    public static void removeFile(String recordId, String objectId, String docId){
        System.debug('Inside removeFile');
        if(String.isNotBlank(recordId)){
            system.debug('recordId-->'+recordId);
            system.debug('objectId-->'+objectId);
            system.debug('docId-->'+docId);
            list<ContentVersion> conVer = new list<ContentVersion>([SELECT Id,ContentDocumentId,Employee_Document__c FROM ContentVersion WHERE Id=:recordId]);
            if(conVer!=null && conVer.size()>0){
                delete [SELECT Id FROM ContentDocument WHERE Id=:conVer[0].ContentDocumentId];
                                
                List<Employee_Document__c> edList = [select id,Uploaded__c from Employee_Document__c where Id=:conVer[0].Employee_Document__c limit 1];
                if(edList.size()>0){
                    edList[0].Uploaded__c=false;
                    update edList[0];
                }                
            }
        }
    }
    
    //Save Method
    @AuraEnabled
    public static String saveFiles(String recId, String jsonStr ){
        system.debug('jsonStr save string===>'+jsonStr);
        system.debug('recId save string===>'+recId);
        //System.debug('Test===='+blbFile);
        String message='Success';    
       
        try{
            List<FileUtilityController.fileMasterWrapper> listwrap = (List< FileUtilityController.fileMasterWrapper >)System.JSON.deserialize(jsonStr,List< FileUtilityController.fileMasterWrapper>.class);
            list<ContentVersion> cvToInsertList = new list<ContentVersion>();
            list<ContentVersion> cvToUpdateList = new list<ContentVersion>();
            
            //Loop through Outlet Wrap List variable
            for(FileUtilityController.fileMasterWrapper fwrap : listwrap){
                for(FileUtilityController.fileWrapper temp : fwrap.toUploadList){
                    System.debug('Inside saveFiles of FileUtility');
                    System.debug(temp);
                    //System.debug(temp.file);
                    if(String.isNotBlank(temp.original_filename) && String.isNotBlank(temp.file_base64)){ 
                        ContentVersion conVer = new ContentVersion();
                        conver.Employee_Document__c = temp.selectedDoc;
                        conVer.isMajorVersion  = false;
                        conVer.PathOnClient = temp.original_filename; // The files name, extension is very important here which will help the file in preview.
                        conVer.Title = temp.original_filename; // Display name of the files
                        conVer.VersionData = EncodingUtil.base64Decode(temp.file_base64); // converting your binary string to Blog
                        cvToInsertList.add(conVer);
                    }
                }
                //Loop through all exisiting files to update if any change has been made
                for(FileUtilityController.uploadedFileWrapper tempUpdate : fwrap.uploadedList){
                    if(String.isNotBlank(tempUpdate.original_filename) && String.isNotBlank(tempUpdate.file_base64)){
                        ContentVersion conVer = new ContentVersion();
                        conVer.PathOnClient = tempUpdate.original_filename; // The files name, extension is very important here which will help the file in preview.
                        conVer.Title = tempUpdate.original_filename; // Display name of the files
                        conVer.VersionData = EncodingUtil.base64Decode(tempUpdate.file_base64); // converting your binary string to Blog
                        conVer.Id = tempUpdate.conv.Id;
                        cvToUpdateList.add(conVer);
                    }
                }
            }
            
            system.debug('cvToInsertList-->'+cvToInsertList);
            
            //Insert all the newly added files
            if(cvToInsertList!=null && cvToInsertList.size()>0){
                insert cvToInsertList;
                
            }
            //Update all the existng files if any change has been made
            if(cvToUpdateList!=null && cvToUpdateList.size()>0)
                update cvToUpdateList;
            
            //Link the files to their respective Objects as selected by the user
            if(cvToInsertList!=null && cvToInsertList.size()>0){
                List<ContentDocumentLink> cdlink = new List<ContentDocumentLink>();
                List<ContentDistribution> cdistributionList = new List<ContentDistribution>();
                
                map<String,List<String>> acctDocIdListMap = new map<String,List<String>>();
                
                list<String> tempList = new list<String>();
                
                Map<Id,Id> empToContentVersionMap = new Map<Id,Id>(); 
                for(ContentVersion te : [SELECT Id,Title,ContentDocumentId,Employee_Document__c FROM ContentVersion WHERE Id in:cvToInsertList]){
                    ContentDocumentLink cDe = new ContentDocumentLink();
                    cDe.ContentDocumentId = te.ContentDocumentId;
                    cDe.LinkedEntityId = te.Employee_Document__c; // you can use objectId,GroupId etc
                    cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
                    cdlink.add(cDe);
                    
                    //Generate the public links of the added files.
                    ContentDistribution cd = new ContentDistribution();
                    cd.name = te.Title;
                    cd.ContentVersionId = te.Id;
                    cd.PreferencesAllowOriginalDownload = true;
                    cd.PreferencesAllowPDFDownload = true;
                    cd.PreferencesAllowViewInBrowser = true;
                    cdistributionList.add(cd);
                    
                    empToContentVersionMap.put(te.Employee_Document__c,te.Id);
                }
                
                //Insert all the content document links
                if(cdlink!=null && cdlink.size()>0)
                    insert cdlink;
                //Insert all the content distribution
                if(cdistributionList!=null && cdistributionList.size()>0)
                    insert cdistributionList;
                
                system.debug('cdistributionList-->'+cdistributionList);
                
                if(empToContentVersionMap!=null && empToContentVersionMap.size()>0){
                    
                    List<Employee_Document__c> edList = [Select id,Uploaded__c from Employee_Document__c where Id in:empToContentVersionMap.keyset()];
                    if(edList.size()>0){
                        for(Employee_Document__c ed: edList){
                            ed.Uploaded__c = true;
                            ed.ContentVersionId__c = empToContentVersionMap.get(ed.Id);
                        }
                        update edList;
                    }
                }
                
            }
        }catch(Exception e){
            message = 'Error '+e.getMessage();
            system.debug('Line No.-->'+e.getLineNumber());
            system.debug('Error Exception-->'+e.getMessage());
        }
        return message;
    }
        
     //Save Method
    @AuraEnabled
    public static String updateFiles(String recId, String jsonStr){
        
        System.debug('Inside updateFiles');
        system.debug('jsonStr save string updateFiles===>'+jsonStr);
        system.debug('recId save string===>'+recId);
        String message='Success';    
       
        try{
            List<FileUtilityController.fileMasterWrapperUpdate> listwrap = (List< FileUtilityController.fileMasterWrapperUpdate >)System.JSON.deserialize(jsonStr,List< FileUtilityController.fileMasterWrapperUpdate>.class);
            System.debug(listwrap);
            List<String> contentVersionId=new List<String>();
            List<ContentDocumentLink> contentDocumentLinkList=new List<ContentDocumentLink>();
            //List<ContentDocumentLink> insertLinks=new List<ContentDocumentLink>();
            List<ContentDocumentLink> deleteLinks=new List<ContentDocumentLink>();
            Map<String,String> contentdoc=new Map<String,String>();
            Map<String,FileUtilityController.uploadedFileWrapperUpdate> ffwMap=new Map<String,FileUtilityController.uploadedFileWrapperUpdate>();
            for(FileUtilityController.fileMasterWrapperUpdate ffwu : listwrap){
                for(FileUtilityController.uploadedFileWrapperUpdate ffw : ffwu.uploadedList){   
                    ffwMap.put(ffw.conv.Id,ffw);
                    contentVersionId.add(ffw.conv.Id);                    
                }
            }
            List<ContentVersion> conList=[select Id,Employee_Document__c,ContentDocumentId from ContentVersion where Id in:contentVersionId];
            for(ContentVersion conver:conList)
            {
                String obje = recId;                
                conver.Related_Record_ID__c=obje;
                conver.Employee_Document__c=ffwMap.get(conver.Id).selectedDoc;
                contentdoc.put(conver.ContentDocumentId,obje );
                ContentDocumentLink cd=new ContentDocumentLink();
                cd.LinkedEntityId=conver.Employee_Document__c;
                cd.ContentDocumentId=conver.ContentDocumentId;
                cd.ShareType='I';
                contentDocumentLinkList.add(cd);
            }
            insert contentDocumentLinkList;
            Set<String> contentdocid=contentdoc.keySet();
            for(ContentDocumentLink cdlink : [SELECT ContentDocumentId, LinkedEntityId  FROM 
                                          ContentDocumentLink where ContentDocumentId in:contentdocid])
            {
                System.debug(cdlink);
                String lid=cdlink.LinkedEntityId;
                if(cdlink.LinkedEntityId!=contentdoc.get(cdlink.ContentDocumentId) && lid.subString(0,3)!='005'){
                    deleteLinks.add(cdlink);
                    System.debug(deleteLinks);
                }
            }
            
           Delete deleteLinks;
            
            update conList;
        }catch(Exception e){
            system.debug(e.getStackTraceString());
            message = 'Error '+e.getMessage();
            system.debug('Line No.-->'+e.getLineNumber());
            system.debug('Error Exception-->'+e.getMessage());
        }
        return message;
    }   
        
        
    //Master Wrapper 
    public class fileMasterWrapper{
        @AuraEnabled
        public list<FileUtilityController.fileWrapper> toUploadList; 
        @AuraEnabled
        public list<FileUtilityController.uploadedFileWrapper> uploadedList;
        public fileMasterWrapper(){
            toUploadList = new list<FileUtilityController.fileWrapper>();
            uploadedList = new list<FileUtilityController.uploadedFileWrapper>();
        }
    }
        
    //Master Wrapper 
    public class fileMasterWrapperUpdate{
        @AuraEnabled
        public list<FileUtilityController.fileWrapper> toUploadList; 
        @AuraEnabled
        public list<FileUtilityController.uploadedFileWrapperUpdate> uploadedList;
        public fileMasterWrapperUpdate(){
            toUploadList = new list<FileUtilityController.fileWrapper>();
            uploadedList = new list<FileUtilityController.uploadedFileWrapperUpdate>();
        }
    }    
    //New File Uploads
    public class fileWrapper{
        @AuraEnabled
        public String original_filename;
        @AuraEnabled
        public String file_base64;
        @AuraEnabled
        public String selectedDoc;
        @AuraEnabled
        public list<Employee_Document__c> docList;
        
       // @AuraEnabled
        //public blob file;
        public fileWrapper(){
            original_filename='';
            file_base64='';
            docList = new list<Employee_Document__c>();
        }
    }
    //Update File Uploads
    public class uploadedFileWrapper{
        @AuraEnabled
        public String original_filename;
        @AuraEnabled
        public String file_base64;
        @AuraEnabled
        public ContentVersion conv;
        public uploadedFileWrapper(){
            original_filename='';
            file_base64='';
            conv = new ContentVersion();
        }
    } 
    //Update File Uploads
    public class uploadedFileWrapperUpdate{
        @AuraEnabled
        public String original_filename;
        @AuraEnabled
        public String file_base64;
        @AuraEnabled
        public ContentVersion conv;
        @AuraEnabled
        public FileUtilityController.fileWrapper reLink;
        @AuraEnabled
        public String selectedDoc; 
        public uploadedFileWrapperUpdate(){
            original_filename='';
            file_base64='';
            conv = new ContentVersion();
            reLink=new FileUtilityController.fileWrapper();
        }
    }
}