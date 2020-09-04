/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/signup/*')
global class AureusSignupWebService{
    @HttpPost
    global static void getAccountData() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
             Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
            if(parameters.containsKey('emailId') && parameters.containsKey('password') 
                 &&  parameters.containsKey('OTP')){
                    response =  WebServiceDataFactoryHelper.signUpAccount(
                                    String.valueOf(parameters.get('emailId')),
                                    String.valueOf(parameters.get('password')),
                                    String.valueOf(parameters.get('OTP'))
                               );
                 
              }else if(parameters.containsKey('emailId') && parameters.containsKey('appversion') && parameters.containsKey('reset') &&
              (!parameters.containsKey('password')  &&  !parameters.containsKey('OTP') )){
                  if(Integer.valueOf(Label.Aureus_Academy_App_Version) > Integer.valueOf(parameters.get('appversion'))){
                      RestContext.response.statusCode = 400;
                      response = '{ "errorCode": "VERSION_ERROR ","message": "Update your version." }';
                  }else{
                      response =  WebServiceDataFactoryHelper.generateCode(
                                    String.valueOf(parameters.get('emailId')), Boolean.ValueOf(parameters.get('reset'))
                               );
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