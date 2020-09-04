@RestResource(urlMapping='/bookingservice/*')

global class BookingRestApi {  
    @HttpGet
    global static String getAttachmentsBlob() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('id');
        Map<String, String> attachmentData = new Map<String, String>();
        for (Attachment att : [Select Name,ContentType, Body from Attachment where ParentId=:bookingId ]) {
            attachmentData.put(att.Name +'(ContentType-'+att.ContentType+')', EncodingUtil.base64Encode(att.Body));
        }
        //RestResponse res = RestContext.response;
       // res.responseBody =  Blob.valueOf(JSON.serialize(attachmentData));
        return String.valueOf(JSON.serialize(attachmentData));
    }   
}