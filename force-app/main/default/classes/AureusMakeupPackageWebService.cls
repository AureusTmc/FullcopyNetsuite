/**
Name        :        AureusMakeupPackageWebService
Date        :      28-jul-2019 
Author      :        
Description :   insert multiple makeup Bookings according to given api body.
**/

@RestResource(urlMapping='/package/*')
global class AureusMakeupPackageWebService{
    @HttpGet
    global static void getPackageData() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            Map <String, String> parameters = request.params;
            system.debug('=====parameters.containsKey : '+parameters.containsKey('type'));
            //string centerId= '0010k00000khhzg';
            if(parameters.containsKey('centerId')){
                response  = WebServiceDataFactoryHelper.getMakeupPackageSelection(String.valueOf(parameters.get('centerId')));
            }else if(parameters.containsKey('location') && !parameters.containsKey('program')){
                response  = WebServiceDataFactoryHelper.getPackages(String.valueOf(parameters.get('location')));
            }else if(parameters.containsKey('program') && parameters.containsKey('location')){
                response  = WebServiceDataFactoryHelper.getPackages(String.valueOf(parameters.get('program')),String.valueOf(parameters.get('location')));
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
    //28-JUL-2019: add this function for  insert multiple makeup Bookings according to given api body.
    @HttpPost
    global Static void insertMakeUpBooking(){
        RestContext.response.addHeader('Content-Type', 'application/json');
        String response='';
        try{
            RestRequest request = RestContext.request;
            String screen = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
            /* Map <String, Object> parameters = (Map<String, Object>)JSON.deserializeUntyped(
RestContext.request.requestBody.toString()
);
*/
            // get restapi request body and add multiple make_up in model class
            List<WebServiceModelHelper.MakeAppointmentForPortalModalClass> newModelList = ( List<WebServiceModelHelper.MakeAppointmentForPortalModalClass> ) JSON.deserialize(RestContext.request.requestBody.toString(),  List<WebServiceModelHelper.MakeAppointmentForPortalModalClass>.class);                                 
            system.debug('@@@newModelList '+newModelList );
            if(newModelList.Size() > 0 && newModelList != null){
                response = WebServiceDataFactoryHelper.inserMakeupBooking(newModelList);
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