/**
    Name        :      AureusMobileNotificationWebService  
    Date        :       7-Aug-2019
    Author      :        
    Description :      This api help for Notification
**/
 
@RestResource(urlMapping='/notifications/*')
global class AureusMobileNotificationWebService{
    
   @HttpPost
   global Static void updateMobileNotifications(){
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
               if(parameters.containsKey('notificationId')){
                  response = WebServiceDataFactoryHelper.updateNotfication(
                                    String.isNotBlank(String.valueOf(parameters.get('notificationId'))) ?String.valueOf(parameters.get('notificationId')) : '',
                                    ''
                                    
                               );
              }else if( parameters.containsKey('parentId')){
                  response = WebServiceDataFactoryHelper.updateNotfication(
                                    '',
                                    String.isNotBlank(String.valueOf(parameters.get('parentId'))) ?String.valueOf(parameters.get('parentId')) : ''
                                    
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
    global static void getMobileNotfication() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, String> parameters = request.params;
            if(parameters.containsKey('parentId')){
                 response  = WebServiceDataFactoryHelper.getMobileNotfication(parameters.get('parentId'));
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