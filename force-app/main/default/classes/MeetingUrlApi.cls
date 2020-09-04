@RestResource(urlMapping='/meetingurlapi/*')

global class MeetingUrlApi {  
    @HttpGet
    global static String getMeetingURL() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('id');
        Booking__c bObj= [SELECT Online_Lesson_URL__c FROM Booking__c where Id=:bookingId ];
        return bObj.Online_Lesson_URL__c;
    }   
}