/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/bookingCancellation/*')
global class AureusCancelBookingWebService{
    
   @HttpPost
   global Static void updateCancelBooking(){
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
               if(parameters.containsKey('bookingIds') && parameters.containsKey('cancellationReason') && parameters.containsKey('makeUpReason') &&
                 parameters.containsKey('makeupRemark')){
                  response = WebServiceDataFactoryHelper.updateBooking(
                                    String.valueOf(parameters.get('bookingIds')),
                                    String.valueOf(parameters.get('cancellationReason')),
                                    String.valueOf(parameters.get('makeUpReason')),
                                    String.valueOf(parameters.get('makeupRemark'))
                                    
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
   
    @HttpGet
    global static void getCancelBooking() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, String> parameters = request.params;
            if(parameters.containsKey('parentId')){
                 response  = WebServiceDataFactoryHelper.getCancelBookingSelection(parameters.get('parentId'));
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