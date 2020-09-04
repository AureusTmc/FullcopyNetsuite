/*
        Name        :   PayoutWebService
        Author      :   Jatin
        Create Date :   10/02/2019
        Description :   This is a webservice class to get called by the stripe webhook. whenever the Stripe payout is created.
*/
@RestResource(urlMapping='/PayoutWebService/*')
global class PayoutWebService {
    @HttpPost
    global static Boolean createPayoutLog(){
        Boolean isSuccess = FALSE;
        RestRequest request = RestContext.request;
        String organisationId = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);
        String jsonBody = request.requestBody.toString();
        
        if(String.isNotBlank(jsonBody)){
            system.debug('@@@organisationId'+organisationId);
            if(String.isNotBlank(organisationId) && isExistOrganisation(organisationId)){
                PayoutWebhookWrapper obj = new PayoutWebhookWrapper();
                obj = PayoutWebhookWrapper.parse(jsonBody);
                Stripe_Payout_Log__c payObj = PayoutWebhookWrapper.parseToStripePayoutLog(obj, TRUE,organisationId);
                if(String.isNotBlank(payObj.Id)){
                    isSuccess = TRUE;
                }
            }
        }
        // @@jatin:1-Nov-2019: for check records save sucessfully then send statusCode 200 otherwise 400 
        if(isSuccess){
            RestContext.response.statusCode = 200;
        }else{
            RestContext.response.statusCode = 400;
        }
        return isSuccess;
    }

    //@Jatin : 1-Nov-2019 : for check Organization id is exist or not
    private  static Boolean isExistOrganisation(string organizationId){
        list<organisation__c> listOfOrganisation = [Select Id 
                                                    FROM Organisation__c 
                                                    where id=:organizationId];
        if(listOfOrganisation != null && listOfOrganisation.size() > 0){
            return TRUE;
        }                                            
        return FALSE;
    }
}