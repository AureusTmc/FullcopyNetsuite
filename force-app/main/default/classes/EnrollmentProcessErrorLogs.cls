//Description: Apex Class to geneate error logs when expcetion occurs during enrollment processing in Salesforce after successfull payments.
//Created By: Techmatrix Consulting.

public without sharing class EnrollmentProcessErrorLogs {
    
    
    @future(callout=true)
    public static void generateErrorLogsAndRefundAmount(String errorLog){
    	 
    	EnrollmentProcessErrorLogs.errorLogObj newObj = (EnrollmentProcessErrorLogs.errorLogObj)Json.deserialize(errorLog,EnrollmentProcessErrorLogs.errorLogObj.class);
    	 
    	if(String.isNotBlank(newObj.stripeTransactionId) && newObj.stripeChargeAmount!=null){
    		//Call Stripe Refund API
    		Decimal stripAmt = newObj.stripeChargeAmount/100; 
    		
    		BillingUtility.StripeRefund  refundObj = BillingUtility.createRefundForCharge(newObj.stripeTransactionId,stripAmt,newObj.baseUrl, newObj.apiKey);
    		//If refund is successfull
    		if(refundObj.statusCode == 200 && refundObj.status == 'succeeded'){
    			Enrollment_Exception_Logs__c errLog = new Enrollment_Exception_Logs__c();
    			if(String.isNotBlank(newObj.customerSalesforceId))
    				errLog.Customer__c = newObj.customerSalesforceId;
				if(String.isNotBlank(newObj.exceptionMessage))
    				errLog.Error_Message__c = newObj.exceptionMessage;
				if(String.isNotBlank(newObj.customerStripeId))
    				errLog.Stripe_Customer_ID__c = newObj.customerStripeId;
				if(String.isNotBlank(newObj.stripeTransactionId))
    				errLog.Stripe_Transaction_ID__c = newObj.stripeTransactionId;
				if(newObj.stripeChargeAmount!=null)
    				errLog.Stripe_Charge_Amount__c = stripAmt;
    			
    			//Insert error log
    			insert errLog;
    		}
    	}
    }
    
    
    
    //Class to fetch the details from Enrollment Process Controller
    public class errorLogObj{
    	public String customerSalesforceId;
    	public String customerStripeId;
    	public String stripeTransactionId;
    	public Decimal stripeChargeAmount;
    	public String exceptionMessage;
    	
        //Added by Rajesh: 4th Sept, 2019, To solve apikey or baseurl related issue according to country
        public String baseUrl;
        public String apiKey;
        
    	public errorLogObj(){
    		stripeChargeAmount = 0;
    	}
    }
    
}