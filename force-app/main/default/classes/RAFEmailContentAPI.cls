@RestResource(urlMapping='/rafemailcontentservice/*')

global class RAFEmailContentAPI {  
    @HttpGet
    global static ReferAFriendEmail__mdt getRAFEmailContent() {
        RestRequest req = RestContext.request;
        ReferAFriendEmail__mdt rafEmail = [SELECT EmailBody__c, EmailSubject__c from ReferAFriendEmail__mdt WHERE MasterLabel =: 'Email'][0];
        //RestResponse res = RestContext.response;
       // res.responseBody =  Blob.valueOf(JSON.serialize(attachmentData));
        return rafEmail;
    }   
}