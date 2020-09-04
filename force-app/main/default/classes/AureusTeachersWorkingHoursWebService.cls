/*
Name        :        AureusTeachersWorkingHoursWebService
Date        :        20/06/2019
Description :        This is a REST webservice Class for Getting the Working Hours of teachers in 15 mins slots 
*/
@RestResource(urlMapping='/teachersWorkingHour/*')
global class AureusTeachersWorkingHoursWebService{
    @HttpGet
    global static void fetchWorkingHours(){
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestRequest request = RestContext.request;
        Map <String, String> parameters = request.params;
        String Response = '';
        WebServiceModelHelper.WorkingHours workingHours = new WebServiceModelHelper.WorkingHours();
        Set<String> setOfTeacherId = new Set<String>();
        String centreId, weekDay;
        
        try{
            if(parameters.containsKey('teachers') && String.isNotBlank(parameters.get('teachers'))){
                for(String teacherId : parameters.get('teachers').split(',')){
                    setOfTeacherId.add(teacherId.trim());
                }
            }
            
            if(parameters.containsKey('centre') && parameters.containsKey('weekday')){
                if(setOfTeacherId.size() > 0 && String.isNotBlank(parameters.get('centre')) && 
                   String.isNotBlank(parameters.get('weekday'))){
                   workingHours = WebServiceDataFactoryHelper.getTeachersWorkingHourTimeSlotList(setOfTeacherId, parameters.get('centre'), parameters.get('weekday'));
                   RestContext.response.statusCode = 200;
                   response = JSON.serialize(workingHours);
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