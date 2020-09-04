@RestResource(urlMapping='/convertcentreapi/*')

global class ConvertToCentreApi {  
    @HttpGet
    global static Booking__c getBookingCentreDetail() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('id');
        Booking__c bObj= [SELECT Id, Lesson_Type__c, Is_Lesson_Type_Change__c FROM Booking__c where Id=:bookingId ];
        bObj.Lesson_Type__c='In Centre';
        bObj.Is_Lesson_Type_Change__c=true;
        Update bObj;
        return bObj;
    }   
}