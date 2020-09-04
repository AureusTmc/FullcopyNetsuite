@isTest
public class HomeCarouselUploadControllerTest {
	@isTest
    private static void test() {
        Home_Carousel__c newHomeCarouselObj = new Home_Carousel__c(Sr_No__c='1');
        insert newHomeCarouselObj;
        
        insertContentVersion('Title','test',Blob.valueOf('Unit Test Attachment Body'),TRUE);
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');
		ContentVersion objContent = insertContentVersion('content title','path',beforeblob,TRUE);
        insertContentDocumentLink(newHomeCarouselObj.id,objContent.ContentDocumentId,'V','AllUsers',TRUE);
        
        
        ContentVersion converObj = [SELECT id, ContentDocumentId FROM ContentVersion Limit 1];
        
        ContentDocumentlink ContentObj = new ContentDocumentlink(LinkedEntityId = newHomeCarouselObj.Id,ShareType = 'V',ContentDocumentId = converObj.ContentDocumentId);
        insert ContentObj;
        
        ContentDistribution ConDistObj = new ContentDistribution(Name = 'document',ContentVersionId = converObj.Id);
        insert ConDistObj;
                   	
        HomeCarouselUploadController.createProfileImage(newHomeCarouselObj.id,'Name',objContent.contentDocumentId);                             
    }
    
    public static ContentVersion insertContentVersion(String title , String clientPath, Blob versionData, Boolean isDML){
        ContentVersion cv = new ContentVersion(title = title,PathOnClient =clientPath,
                                               VersionData =versionData );
        if(isDML){
            try{
                insert cv;    
                cv = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
            }catch(Exception e){
                System.debug(e.getMessage());
            }
            
        }
        return cv;  
    }
    
     public static ContentDocumentLink insertContentDocumentLink(String parentId,String documentId, String shareType,String visibility,Boolean isDML){
        ContentDocumentLink objDocLink = new ContentDocumentLink(LinkedEntityId = parentId,ContentDocumentId=documentId,
                                                                 ShareType = shareType,Visibility = visibility);
        try{
            if(isDML){
                insert objDocLink;
            }   
        }catch(Exception e){
            System.debug('in catch');
            System.debug(e.getMessage());
        }
        return objDocLink;
    }
    
}