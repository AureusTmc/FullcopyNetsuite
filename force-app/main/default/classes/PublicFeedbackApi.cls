@RestResource(urlMapping='/publicmeetingfeedback/*')

global class PublicFeedbackApi {  
    @HttpGet
    global static String createMeetingFeedback() {
        RestRequest req = RestContext.request;
        String personName = req.params.get('person_name');
        String roomName = req.params.get('room_name');
        String rating = req.params.get('rating');
        Meeting_Feedback__c meetingObj = new Meeting_Feedback__c();
        meetingObj.Submitted_by__c=personName;
        meetingObj.Room_Name__c=roomName;
        meetingObj.Online_Lesson_Quality_Rating__c=rating;
        Insert meetingObj;
        return meetingObj.Id;
    }   
}