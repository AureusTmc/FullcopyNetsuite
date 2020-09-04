/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/adhocbooking/*')
global class AureusAdHocBookingWebService{
    
   @HttpPost
   global Static void updateAdHocBooking(){
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
               if(parameters.containsKey('fifthBookingId')){
                  response = WebServiceDataFactoryHelper.updateAdHocBooking(
                                    String.valueOf(parameters.get('fifthBookingId'))
                                   );
              }else{
                  RestContext.response.statusCode = 400;
                 response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
             }
         }catch(Exception e) {
            RestContext.response.statusCode = 500; 
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }   
        RestContext.response.responseBody = Blob.valueOf( response );
   }
   
}