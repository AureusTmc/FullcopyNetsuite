/*
        Name        :   PayoutWebhookWrapper
        Author      :   Jatin
        Create Date :   10/02/2019
        Description :   This is a Wrapper Class for storing the webhook response from the stripe.
*/
public class PayoutWebhookWrapper {

    
	public Payoutdata data;

	class Payoutdata {
		public PayoutObject object_c;
	}

	class PayoutObject {
		public String id;	
		public String object_c;	
		public Double amount;	
		public Integer arrival_date;	
		public boolean automatic;
		public String balance_transaction;	
		public Long created;	
		public String currency_c;	
		public String description;	
		public String destination;	
		public String method;	
		public String source_type;
		public String status;	
		public String type;	
	}

	public static PayoutWebhookWrapper parse(String json){
        if(String.isNotBlank(json)){
            json = json.replaceAll('object', 'object_c');
            json = json.replaceAll('currency', 'currency_c');
        }
		return (PayoutWebhookWrapper) System.JSON.deserialize(json, PayoutWebhookWrapper.class);
	}

    public static Stripe_Payout_Log__c parseToStripePayoutLog(PayoutWebhookWrapper payoutObject, Boolean isDML,String organisationId){
        Stripe_Payout_Log__c payoutLogObject = new Stripe_Payout_Log__c();
        if(String.isNotBlank(payoutObject.data.object_c.id)){
            payoutLogObject.Stripe_Payout_Id__c = payoutObject.data.object_c.id;
            if(payoutObject.data.object_c.created > 0 && payoutObject.data.object_c.created != NULL){
                payoutLogObject.Stripe_Payout_Date__c = DateTime.newInstance(payoutObject.data.object_c.created * 1000);
            }
            if(payoutObject.data.object_c.amount > 0 && payoutObject.data.object_c.amount != NULL){
               payoutLogObject.Stripe_Payment_Amount__c = payoutObject.data.object_c.amount / 100;
            }
            payoutLogObject.Status__c = ConstantsClass.payoutStatusUnprocessed;
            //@@ Jatin :1-nov-2019: for add Organization Id 
            payoutLogObject.Organisation__c =organisationId;
        }
        if(isDML){
            try{
                INSERT payoutLogObject;
            }catch(exception e){
                RestContext.response.statusCode = 500;
            }
        }
        return payoutLogObject;
    }

}