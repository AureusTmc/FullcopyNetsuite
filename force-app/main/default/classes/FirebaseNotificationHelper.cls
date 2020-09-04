public class FirebaseNotificationHelper {
    
    // Returns NULL on Exception
    public static Mobile_Notification__c sendNotificationBatch(String customerId, String to, String title, String bodymsg){
        
        Firebase_Settings__c settings = Firebase_Settings__c.getValues('setting');
        
        //if(settings == null || Test.isRunningTest()) return null;
         if(settings == null || !settings.Enable_Notifications__c) return null;
        String body = '{"to" : \"'+ to + '","notification": '+
            +'{"body" : \"' + bodymsg +'","title": \"' +title + '"},' +
            +'"data":{"click_action": "FLUTTER_NOTIFICATION_CLICK"}}';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(settings.Endpoint__c);
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setHeader('Authorization',settings.API_Key__c);
        request.setBody(body);
        HttpResponse response = null;
        
        if(!Test.isRunningTest()) response = http.send(request);
        
        //Parse JSON response if Logging is enabled
        if(settings.Enable_Logs__c) {
            try{
                // Deserialize the JSON string into collections of primitive data types.
                Map<String, Object> results = Test.isRunningTest() ? new Map<String, Object>() : (Map<String, Object>) JSON.deserializeUntyped(response.getBody()); 
                String status = String.valueOf(results.get('results'));
                Mobile_Notification__c log = new Mobile_Notification__c(Customer_Name__c = customerId, Title__c = title, Body__c = bodymsg, Status__c = status);
                return log;
            }catch(Exception e) {
                return null;
            }
        }
        return null;
        
    } 
    
    @Future(callout=true)
    public static void sendNotification(String customerId, String to, String title, String bodymsg){
        Mobile_Notification__c log = sendNotificationBatch(customerId,to, title, bodymsg);
        if(log !=null) {
            try {
                insert log;
            } catch(Exception e) {
                System.debug(e);
            }
        }
    }
    
}