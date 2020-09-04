@RestResource(urlMapping='/singleWorkingHours/*')
global class AureusSingleWorkingHoursWebService{
    @HttpGet
    global static void fetchSingleWorkingHours(){
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        List<String> timeSlots = new List<String>();
        
        RestRequest request = RestContext.request;
        Map <String, String> parameters = request.params;
        System.debug('parameters '+parameters );
        try { 
            if(parameters.containsKey('centre') && parameters.containsKey('teacher') 
                && parameters.containsKey('duration') && parameters.containsKey('date')){
                if(String.isNotBlank(parameters.get('centre')) && String.isNotBlank(parameters.get('teacher')) 
                && String.isNotBlank(parameters.get('duration'))){
                    timeSlots = WebServiceDataFactoryHelper.getTimeSlotsAccordingly(parameters.get('centre'),
                                 parameters.get('teacher'), parameters.get('duration'),parameters.get('date'));
                        RestContext.response.statusCode = 200;
                        response = JSON.serialize(timeSlots);
                }else{
                    RestContext.response.statusCode = 400;
                    response = '{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }';
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