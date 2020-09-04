/**
    Name        :        
    Date        :       
    Author      :        
    Description :        
**/
 
@RestResource(urlMapping='/allLesson/*')
global class AureusGetAllLessonWebService{
   
    @HttpGet
    global static void getallLesson() {
       RestContext.response.addHeader('Content-Type', 'application/json');
        String response = '';
        try {
            RestRequest request = RestContext.request;
            //response  = WebServiceDataFactoryHelper.getAllLesson();
            WebServiceModelHelper.LessonResult LessonResultobj = new WebServiceModelHelper.LessonResult();
            List<WebServiceModelHelper.lesson> listOfLesson= new List<WebServiceModelHelper.lesson>();
            listOfLesson = WebServiceDataFactoryHelper.getAllLesson();
            LessonResultobj.lessons =listOfLesson; 
            response = JSON.Serialize(LessonResultobj);
            
        } catch(Exception e) {
             RestContext.response.statusCode = 500;
            response = '{ "errorCode": "INTERNAL_ERROR","message": "'+e.getMessage()+'" }';
        }
        RestContext.response.responseBody = Blob.valueOf( response );
    }
}