public with sharing class UploadProfilePictureController {
    
    @AuraEnabled
    public static Attachment getProfilePicture(Id parentId) {
        List<Attachment> attachList = new list<Attachment>([SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
            WHERE parentid=:ParentId AND Name Like '%Profile Image%' AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
            ORDER BY LastModifiedDate DESC LIMIT 1]);
        if(attachList.size()>0){
            return attachList.get(0);
        }
        return null;
        
    }
    
    @AuraEnabled
    public static Id saveAttachment(Id parentId, String fileName, String base64Data, String contentType) { 
        fileName = 'Profile Image';
        
        Attachment attachment = new Attachment();
        attachment.parentId = parentId;
        attachment.body = EncodingUtil.base64Decode(base64Data);
        attachment.name = fileName;
		attachment.contentType = contentType;
        insert attachment;
        return attachment.id;
    }

}