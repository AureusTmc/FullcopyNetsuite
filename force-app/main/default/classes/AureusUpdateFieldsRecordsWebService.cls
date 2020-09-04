/**
    Name        :        
    Date        :       
    Author      :        
    Description :     id, field api or new value du   
**/
 
@RestResource(urlMapping='/updateFieldsRecords/*')
global class AureusUpdateFieldsRecordsWebService{
    
   @HttpPost
   global Static void updateRecords(){
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
               if(parameters.containsKey('recordId') && parameters.containsKey('fieldApi') && parameters.containsKey('newValue')){
                  if(String.IsNotBlank(String.valueOf(parameters.get('recordId')))){
                          response = WebServiceDataFactoryHelper.updateRecords(
                                            Id.valueOf(String.valueOf(parameters.get('recordId'))),
                                            String.valueOf(parameters.get('fieldApi')),
                                            String.valueOf(parameters.get('newValue'))
                                     );
                     }else{
                         RestContext.response.statusCode = 400;
                         response = '{ "errorCode": "DATA_NOT_FOUND","message": "Record Id Not Found" }';
                     }
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