public class HomeCarouselUploadController{   
    public HomeCarouselUploadController() {}
    @AuraEnabled
    public static Boolean createProfileImage(String parentId , String parentName , String documentId){
        /*This method is to check whether the parent have
        any file manager record have any file name records as child with type as 'Profile' if it is there it will update the version data else
        will create new version and update the version on file name record*/
        Boolean isCreated = createProfileData(parentId,parentName,documentId);        
        return isCreated; 
    }
    
    public static Boolean createProfileData(String parentId , String parentName, String documentId){
        Boolean isCreated = false;
        System.debug(documentId);
        System.debug(parentId+parentName);
        Set<Id> setOfContentIds = new Set<Id>();        
        ContentVersion verDetails = [Select Id,VersionData From ContentVersion Where ContentDocumentId =:documentId LIMIT 1];//Here we are getting version detail for newly inserted doc        
        System.debug('verDetails--->'+verDetails);
        List<ContentDocumentLink> linkToDeleteAccount = [Select Id, ContentDocumentId From ContentDocumentLink Where LinkedEntityId = :parentId];
        for(ContentDocumentLink contDocLink : linkToDeleteAccount){
            setOfContentIds.add(contDocLink.ContentDocumentId);
        }
        
        //Deleting existing Distribution URL From ContentDistribution
        List<ContentDistribution> conDisList = [select ContentDocumentId, ContentVersionId, DistributionPublicUrl from ContentDistribution USING SCOPE Team where ContentDocumentId in :setOfContentIds];
        if(!conDisList.isEmpty()){
            delete conDisList;   
        }
        //Creating new ContentDocument by creating new ContentVerison and not specifying ContentDocumentID in ContentVersion          
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = verDetails.VersionData;
        cv.Title = 'Img.jpg';  
        cv.PathOnClient= 'img.jpg';          
        insert cv; 
        
        System.debug(cv);
        //Attaching contentVersion with ContentDocumentLink to get attached from its Linked Object
        System.debug([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId);
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = parentId;        
        docLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        docLink.ShareType = 'I';//Inferred permission. The user’s permission is determined by the related record. For shares with a library, this is defined by the permissions the user has in that library.
        docLink.Visibility = 'AllUsers';
        insert docLink;
        System.debug('New Link---->'+docLink);            
        
        //Attaching doc with DistributionLink to make doc publically by URL
        ContentDistribution cd = new ContentDistribution();
        cd.Name = parentName;
        cd.ContentVersionId = cv.Id; 
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= false;
        cd.PreferencesAllowPDFDownload = false;
        cd.RelatedRecordId = parentId;
        insert cd;
        //Deleting existing ContentDocument
        System.debug(setOfContentIds); 
        if(linkToDeleteAccount != null) {
            System.debug('Old ContentDouments---->'+[Select Id, Title, FileExtension, Owner.Name, CreatedDate From ContentDocument USING SCOPE Team WHERE id in: setOfContentIds]);
            delete [Select Id, Title, FileExtension, CreatedDate From ContentDocument USING SCOPE Team WHERE id in: setOfContentIds];                                    
        }
        
        ContentDistribution contentDis = [SELECT DistributionPublicUrl,ContentVersionId,ContentDocumentId FROM ContentDistribution WHERE ID =: cd.Id];
        
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String orgId = '';
        List<Organization> orgList = Database.Query('select isSandbox, Id from organization');
        if(!orgList.isEmpty()){
            orgId = orgList[0].Id;
        } 
        ContentDocumentlink ContentDocumentlinkRec = [select id,LinkedEntityId,ContentDocumentId,ContentDocument.FileExtension from ContentDocumentlink 
                                                          where id = :docLink.id];
        String publicUrl = '';
        string versionId = contentDis.ContentVersionId;
        String urlToParse = contentDis.DistributionPublicUrl;                                                     
        String preUrl = baseUrl+'/sfc/dist/version/renditionDownload?rendition=';
        if(ContentDocumentlinkRec.ContentDocument.FileExtension == 'jpg' || ContentDocumentlinkRec.ContentDocument.FileExtension == 'jpeg'){
           preUrl  += 'ORIGINAL_Jpg';
        }else if(ContentDocumentlinkRec.ContentDocument.FileExtension == 'png'){
           preUrl  += 'ORIGINAL_Png';
        }  
        preUrl  += '&contentId='+contentDis.ContentDocumentId+'&operationContext=DELIVERY&page=0&oid='+orgId+'&dpt=null&viewId=';
        list<String> imageIdList = urlToParse.split('/a/');
        publicUrl = preUrl+'&versionId='+versionId+'&d=/a/'+imageIdList[1];
        
        Home_Carousel__c homeCarousel = new Home_Carousel__c(Id = parentId, Content_Version__c = cv.Id, Image_URL__c=publicUrl );
        try{
            upsert homeCarousel;
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
                                                    
        isCreated = true;                 
        return isCreated;
    }
}