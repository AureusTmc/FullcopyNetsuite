@RestResource(urlMapping='/centrenameapi/*')

global class CentreNameApi {  
    @HttpGet
    global static String getCentreName() {
        RestRequest req = RestContext.request;
        String bookingId = req.params.get('id');
        Booking__c bObj= [SELECT Center__r.Name FROM Booking__c where Id=:bookingId ];
        return bObj.Center__r.Name;
    }   
}