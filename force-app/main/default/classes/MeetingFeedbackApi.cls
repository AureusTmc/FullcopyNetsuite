@RestResource(urlMapping='/meetingfeedback/*')

global class MeetingFeedbackApi {  
    @HttpGet
    global static String createMeetingFeedback() {
        RestRequest req = RestContext.request;
        String personId = req.params.get('person_id');
        String personName = req.params.get('person_name');
        String bookingId = req.params.get('booking_id');
        String rating = req.params.get('rating');
        Meeting_Feedback__c meetingObj = new Meeting_Feedback__c();
        meetingObj.Submitted_by__c=personName;
        meetingObj.Account_Id__c=personId;
        meetingObj.Booking__c=bookingId;
        meetingObj.Online_Lesson_Quality_Rating__c=rating;
        Insert meetingObj;
        return meetingObj.Id;
    }   
}