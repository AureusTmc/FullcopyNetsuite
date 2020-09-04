/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/updateProfile/*')
global class AureusAttachmentWebService{
    
   @HttpPost
   global Static void createAttachmentData(){
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
          try {
            RestRequest request = RestContext.request;
            
             Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
             if(parameters.containsKey('parentId') && parameters.containsKey('body')){
             System.debug(String.valueOf(parameters.get('body')));
                     response =  WebServiceDataFactoryHelper.createAttachment(
                                     String.valueOf(parameters.get('parentId')),
                                     String.valueOf(parameters.get('body'))
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