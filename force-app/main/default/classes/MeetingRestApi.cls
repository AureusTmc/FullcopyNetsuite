@RestResource(urlMapping='/meetingservice/*')

global class MeetingRestApi {  
    @HttpGet
    global static Booking__c getBooking() {
       RestRequest req = RestContext.request;
        String bookingId = req.params.get('id');
        Booking__c bookingObj = new Booking__c();
        bookingId = '%'+bookingId+'%';
        bookingObj = [SELECT Online_Lesson_URL__c, Online_Lesson_Passcode__c, Id FROM Booking__c Where Online_Lesson_URL__c like:bookingId limit 1];
        return bookingObj;  
    }   
}