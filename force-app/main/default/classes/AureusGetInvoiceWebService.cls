/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/Invoice/*')
global class AureusGetInvoiceWebService{
    @HttpGet
    global static void getinvoiceData() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            String accountId= request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
           // Map <String, String> parameters = request.params;
            //system.debug('=====parameters.containsKey : '+parameters.containsKey('parent_sf_Id'));
            //string parentId  ='0010k00000pFe0C';
            if(String.isNotBlank(accountId)){
                response  = WebServiceDataFactoryHelper.fetchInvoice(accountId);
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