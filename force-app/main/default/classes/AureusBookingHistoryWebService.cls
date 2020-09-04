/**
    Name        :      AureusBookingHistoryWebService  
    Date        :       24-Aug-2019
    Author      :        
    Description :     for this api is response all history of related booking id   
**/
 
@RestResource(urlMapping='/bookingHistory/*')
global class AureusBookingHistoryWebService{
  
    @HttpGet
    global static void getBookingHistory() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, String> parameters = request.params;
            if(parameters.containsKey('bookingId')){
                 response  = WebServiceDataFactoryHelper.getBookingHistory(parameters.get('bookingId'));
            }else{
                 RestContext.response.statusCode = 400;
                 response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
             }
          
        } catch(Exception e) {
            RestContext.response.statusCode = 500; 
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }
        RestContext.response.responseBody = Blob.valueOf( response );
    }
}