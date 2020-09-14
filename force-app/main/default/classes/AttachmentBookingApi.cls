@RestResource(urlMapping='/attachmentbookingservice/*')

global class AttachmentBookingApi {  
    @HttpGet
    global static String getBookingAttachmentsBlob() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('id');
        Map<String, String> attachmentData = new Map<String, String>();
         bookingId = '%'+bookingId+'%';
        Booking__c  bookingObj = [SELECT Id FROM Booking__c Where Online_Lesson_URL__c like:bookingId limit 1];
        for (Attachment att : [Select Name,ContentType, Body from Attachment where ParentId=:bookingObj.Id]) {
            attachmentData.put(att.Name,att.Id);
        }
        //RestResponse res = RestContext.response;
       // res.responseBody =  Blob.valueOf(JSON.serialize(attachmentData));
        return String.valueOf(JSON.serialize(attachmentData));
    }   
}