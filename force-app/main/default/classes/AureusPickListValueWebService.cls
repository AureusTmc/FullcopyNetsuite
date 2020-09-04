@RestResource(urlMapping='/picklist/*')
global class AureusPickListValueWebService{
    @HttpGet
    global static void fetchPickListValues(){
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        
        RestRequest request = RestContext.request;
        Map <String, String> parameters = request.params;
        System.debug('parameters '+parameters );
        try {
            if(parameters.containsKey('objName') && parameters.containsKey('fieldApiName')){
                response = WebServiceDataFactoryHelper.getPickListValues(
                    parameters.get('objName'), 
                    parameters.get('fieldApiName')
                );
             }else{
                  RestContext.response.statusCode = 400;
                  response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
              }
         }catch(Exception e) {
             RestContext.response.statusCode = 500;
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }   
        System.debug('@@@response '+response );   
        RestContext.response.responseBody = Blob.valueOf( response );
    }
}