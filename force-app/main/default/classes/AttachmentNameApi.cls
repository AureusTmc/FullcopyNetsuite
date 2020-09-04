@RestResource(urlMapping='/attachmentnameservice/*')

global class AttachmentNameApi {  
    @HttpGet
    global static String getBookingAttachmentsBlob() {
        RestRequest req = RestContext.request;
        String attId = req.params.get('id');
        Map<String, String> attachmentData = new Map<String, String>();
        for (Attachment att : [Select Name,ContentType, Body from Attachment where Id=:attId ]) {
            attachmentData.put(att.Id, EncodingUtil.base64Encode(att.Body));
        }
        //RestResponse res = RestContext.response;
       // res.responseBody =  Blob.valueOf(JSON.serialize(attachmentData));
        return String.valueOf(JSON.serialize(attachmentData));
    }   
}