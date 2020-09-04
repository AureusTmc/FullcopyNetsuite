/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/bookingReschedule/*')
global class AureusBookingRescheduleWebService{
    
   @HttpPost
   global Static void insertBookingReschedule(){
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response;
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
                                                  RestContext.request.requestBody.toString()
                                                );
               if(parameters.containsKey('bookingId') && parameters.containsKey('teacherId') && parameters.containsKey('oldteacherId') &&
                 parameters.containsKey('time') && parameters.containsKey('date') && parameters.containsKey('oldtime') && parameters.containsKey('olddate')
                 && parameters.containsKey('duration')){
                    String[] strTimeSplit = String.valueOf(parameters.get('time')).split(':');
                    Time newTime= Time.newInstance( Integer.valueOf(strTimeSplit[0]),Integer.valueOf(strTimeSplit[1]),0,0);
                    strTimeSplit = String.valueOf(parameters.get('oldtime')).split(':');
                    Time oldtime= Time.newInstance( Integer.valueOf(strTimeSplit[0]),Integer.valueOf(strTimeSplit[1]),0,0);
                    String[] strdateSplit = String.valueOf(parameters.get('date')).split('-');
                    Date newDate= Date.newInstance(Integer.valueOf(strdateSplit[0]),Integer.valueOf(strdateSplit [1]),Integer.valueOf(strdateSplit [2]));
                    strdateSplit = String.valueOf(parameters.get('olddate')).split('-');
                    Date oldDate= Date.newInstance(Integer.valueOf(strdateSplit[0]),Integer.valueOf(strdateSplit [1]),Integer.valueOf(strdateSplit [2]));
                      
                  response = WebServiceDataFactoryHelper.insertBookingReschedule(
                                    String.valueOf(parameters.get('bookingId')),
                                    String.valueOf(parameters.get('teacherId')),
                                    String.valueOf(parameters.get('oldteacherId')),
                                    newTime,
                                    newDate,
                                    oldtime,
                                    oldDate,
                                    Integer.valueOf(parameters.get('duration'))
                                    
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
}