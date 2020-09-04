/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/case/*')
global class AureusCaseWebService{
    @HttpGet
    global static void getCaseData() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            Map <String, String> parameters = request.params;
            system.debug('=====parameters.containsKey : '+parameters.containsKey('type'));
            //string parentId  = '0010k00000pFe0C';
            if(parameters.containsKey('parent_sf_Id') && parameters.containsKey('type')
            && parameters.containsKey('limit') && parameters.containsKey('offset')){
                string parentId  = parameters.get('parent_sf_Id');//'0010k00000pFe0C';
                response = WebServiceDataFactoryHelper.getCaseData(parentId, parameters.get('type'), integer.valueOf(parameters.get('limit')), integer.valueOf(parameters.get('offset')));
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
    
    
   @HttpPost
   global Static void createCaseData(){
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
          try {
            RestRequest request = RestContext.request;
            
             Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
             if(parameters.containsKey('requestType') && parameters.containsKey('subject') && parameters.containsKey('details') &&
             (parameters.containsKey('parentId') || parameters.containsKey('studentId')|| parameters.containsKey('invoiceId') || parameters.containsKey('bookingId'))){
                     String parentId = parameters.containsKey('parentId') ? String.valueOf(parameters.get('parentId')) :'';
                     String studentId= parameters.containsKey('studentId') ? String.valueOf(parameters.get('studentId')) :'';
                     String invoiceId= parameters.containsKey('invoiceId') ? String.valueOf(parameters.get('invoiceId')) :'';
                     String bookingId= parameters.containsKey('bookingId') ? String.valueOf(parameters.get('bookingId')) :'';
                 String enrollmentId= parameters.containsKey('enrollmentId') ? String.valueOf(parameters.get('enrollmentId')) :'';
                     response =  WebServiceDataFactoryHelper.createCase(
                                     parentId, studentId,
                                     String.valueOf(parameters.get('requestType')),
                                     String.valueOf(parameters.get('subject')),
                                     String.valueOf(parameters.get('details')),
                                     invoiceId, bookingId,enrollmentId
                                 );
                }else{
                  RestContext.response.statusCode = 400;
                  response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
              }
         }catch(Exception e) {
             RestContext.response.statusCode = 500;
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }   
       system.debug('response'+response);
       RestContext.response.responseBody = Blob.valueOf( response );
   }
}