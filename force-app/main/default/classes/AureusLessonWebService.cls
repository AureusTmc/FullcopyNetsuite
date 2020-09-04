/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/lesson/*')
global class AureusLessonWebService{
    @HttpGet
    global static void getLessonData() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, String> parameters = request.params;
            system.debug('=====parameters.containsKey : '+parameters.containsKey('type'));
            //string parentId  ='0010k00000pFe0C';
            if(parameters.containsKey('parentId')){
                string parentId  = parameters.get('parentId');//'0010k00000pFe0C';
                response  = WebServiceDataFactoryHelper.getLesson(parentId);
            }else if(parameters.containsKey('enrollmentId') && parameters.containsKey('Limit') && parameters.containsKey('offset') && parameters.containsKey('type')){
                     response  = WebServiceDataFactoryHelper.getEnrollment(parameters.get('enrollmentId'),Integer.valueOf(parameters.get('Limit')),Integer.valueOf(parameters.get('offset')),parameters.get('type'));
             }else{
                  RestContext.response.statusCode = 400;
                  response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
              }
         }catch(Exception e) {
             system.debug('e.getMessage()'+e.getMessage());
             RestContext.response.statusCode = 500;
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }   
        RestContext.response.responseBody = Blob.valueOf( response );
    }
    
   

}