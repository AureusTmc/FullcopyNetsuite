/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/customerCard/*')
global class AureusCustomerCardWebService{
    
   @HttpPost
   global Static void updateCustomerCard(){
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
               if(parameters.containsKey('parentId') && parameters.containsKey('expMonth') && parameters.containsKey('expYear')){
                  response = WebServiceDataFactoryHelper.updateCustomerCard(
                                    String.valueOf(parameters.get('parentId')),
                                    String.valueOf(parameters.get('expMonth')),
                                    String.valueOf(parameters.get('expYear'))
                               );
              }else if(parameters.containsKey('parentId') && parameters.containsKey('token')){
                   response = WebServiceDataFactoryHelper.addCustomerCard(
                                    String.valueOf(parameters.get('parentId')),
                                    String.valueOf(parameters.get('token'))
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