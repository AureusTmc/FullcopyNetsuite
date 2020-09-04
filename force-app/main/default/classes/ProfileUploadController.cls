public class ProfileUploadController {
	 @AuraEnabled
    public static void saveFile(Id parentId, String fileName, String base64Data, String contentType) {
        system.debug('parentId:'+parentId);
        Enrolment__c enrObj = [Select Id, Student__c from Enrolment__c where Id =:parentId];
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment attFile = new Attachment();
        system.debug('enrObj.Student__c:'+enrObj.Student__c);
        attFile.ParentId = enrObj.Student__c; 
        attFile.body = EncodingUtil.base64Decode(base64Data);
        attFile.name = filename;
        Insert attFile;
         system.debug('attFile:'+attFile.Id);
      //  return attFile.Id;
    }
}