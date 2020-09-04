/**
    Name        :        
    Date        :       
    Author      :        
    Description :   this class is used for get and post teacher records with related instruments     
**/
 
@RestResource(urlMapping='/TeachersInstrument/*')
global class AureusTeacherWebService{
    @HttpGet
    global static void getTeachersData() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            Map <String, String> parameters = request.params;
            // accoring to booking ids send all teachers with instrument
            if(parameters.containsKey('bookingId')){
                string bookingId= parameters.get('bookingId');//'0010k00000pFe0C';
                response = WebServiceDataFactoryHelper.getAllRelatedTeacher(bookingId);
            }// send all teachers records according to center id and instrument 
            else If(parameters.containsKey('centerId') && parameters.containsKey('instrument')){
                response = WebServiceDataFactoryHelper.getAllTeacher(parameters.get('centerId'),parameters.get('instrument'));
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