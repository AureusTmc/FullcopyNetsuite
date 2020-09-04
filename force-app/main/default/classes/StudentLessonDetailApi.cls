@RestResource(urlMapping='/studentlessondetail/*')

global class StudentLessonDetailApi {  
    @HttpGet
    global static Booking__c getStudentLessonDetail() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('booking_id');
        Booking__c bObj= [SELECT Id, Online_Lesson_URL__c, Online_Lesson_Passcode__c FROM Booking__c WHERE Id=:bookingId];
        return bObj;
    }   
}