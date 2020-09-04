/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/home/*')
global class AureusHomeWebService{
    @HttpPost
    global static void getHomeData() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
             Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
             if(parameters.containsKey('emailId') && parameters.containsKey('password') && parameters.containsKey('appversion')){
                 system.debug('Integer.valueOf(Label.Aureus_Academy_App_Version)'+Integer.valueOf(Label.Aureus_Academy_App_Version));
                 system.debug(Integer.valueOf(parameters.get('appversion')));
                 system.debug( (Integer.valueOf(Label.Aureus_Academy_App_Version) > Integer.valueOf(parameters.get('appversion'))));
                              
                 if( Integer.valueOf(Label.Aureus_Academy_App_Version) > Integer.valueOf(parameters.get('appversion'))){
                      RestContext.response.statusCode = 400;
                      response = '{ "errorCode": "VERSION_ERROR ","message": "Update is required to login into the app." }';
                  }else{
                      if( parameters.containsKey('token')){
                             response =  WebServiceDataFactoryHelper.fetchloginAccount(
                                    String.valueOf(parameters.get('emailId')),
                                    String.valueOf(parameters.get('password')),
                                   String.valueOf(parameters.get('token'))
                               );
                      }
                    else{
                        response =  WebServiceDataFactoryHelper.fetchloginAccount(
                                    String.valueOf(parameters.get('emailId')),
                                    String.valueOf(parameters.get('password')),
                                   ''
                               );
                    }
                   }
              }else{
                  RestContext.response.statusCode = 400;
                  response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
              }
         }catch(Exception e) {
             RestContext.response.statusCode = 500;
             system.debug('e.getMessage()'+e.getMessage());
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }   
        RestContext.response.responseBody = Blob.valueOf( response );
    }
}