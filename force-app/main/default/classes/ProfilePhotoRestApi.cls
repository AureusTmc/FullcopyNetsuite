@RestResource(UrlMapping='/profilephoto/*')

global class ProfilePhotoRestApi {
    @HttpGet
    global static void getBlob() {
        RestRequest req = RestContext.request;
        String personId = req.params.get('id');
        Attachment att = [Select body from attachment where ParentId=:personId LIMIT 1];
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type','image/jpg');
        res.responseBody = att.body;
    }
}