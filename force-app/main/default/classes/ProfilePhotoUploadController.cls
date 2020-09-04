public class ProfilePhotoUploadController {
	
    @AuraEnabled
    public static string getProfileImage(Id parentId) {
        Enrolment__c enrObj = new Enrolment__c();
        enrObj = [Select Id, Student__c,Student__r.Name from Enrolment__c where Id =:parentId];     
        List<Attachment> attList= new List<Attachment>();
        attList=[Select Id from Attachment where ParentId =:enrObj.Student__c];
        if(attList.size()>0){
           return attList[0].Id;
        }else{
            return enrObj.Student__r.Name.substring(0,1);
        }
    }
    @AuraEnabled
    public static string saveFile(Id parentId, String fileName, String base64Data, String contentType) {
        
        Enrolment__c enrObj = [Select Id, Student__c from Enrolment__c where Id =:parentId];    
        List<Attachment> attList = new List<Attachment>();
        
       attList=[Select Id,Name from Attachment where ParentId =:enrObj.Student__c AND Name='Profile Image'];
        if(attList.size()>0){
        	Delete attList;
        }
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment attFile = new Attachment();
        attFile.ParentId = enrObj.Student__c; 
        attFile.body = EncodingUtil.base64Decode(base64Data);
        attFile.name = 'Profile Image';
        attFile.ContentType = contentType;
        Insert attFile;
        system.debug('attFile.Id'+attFile.Id);
        return attFile.Id;
    }
}