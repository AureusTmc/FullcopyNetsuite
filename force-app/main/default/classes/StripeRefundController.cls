/*
    Name            :   StripeRefundController
    Date            :   30th May 2019
    Author          :   
    Description     :   
*/
public class StripeRefundController {
    @AuraEnabled
    public static String initiateRefund(String amount,String recId,String remark){
        String msg = 'success';
        Boolean isSuccess = FALSE;
        Decimal amountToRefund =  BillingUtility.roundOffAmount(Decimal.valueOf(amount));
        Payment__c objPay = [SELECT Id,Payment_Amount__c,Transaction_Id__c,remarks__c,Invoice__c,Parent_Account__c, Invoice__r.Center__r.Country__r.Id,  
                             Invoice__r.Center__r.Country__r.Stripe_Base_Url__c, Invoice__r.Center__r.Country__r.Stripe_Secret_Key__c 
                             FROM Payment__c WHERE Id=:recId LIMIT 1];
        
        if(String.isNotBlank(objPay.Invoice__r.Center__r.Country__r.Id) && String.isNotBlank(objPay.Invoice__r.Center__r.Country__r.Stripe_Base_Url__c) && 
           String.isNotBlank(objPay.Invoice__r.Center__r.Country__r.Stripe_Secret_Key__c)){
            isSuccess = TRUE;
        }
          
        if(amountToRefund > 0 && objPay.Payment_Amount__c >= amountToRefund && String.isNotBlank(objPay.Transaction_Id__c) && isSuccess){
            BillingUtility.StripeRefund  refundObj = BillingUtility.createRefundForCharge(objPay.Transaction_Id__c,amountToRefund, objPay.Invoice__r.Center__r.Country__r.Stripe_Base_Url__c, objPay.Invoice__r.Center__r.Country__r.Stripe_Secret_Key__c);
            if(refundObj.statusCode == 200 && refundObj.status == 'succeeded'){
                Payment__c newPayment = BillingUtility.fillPayment(objPay.Parent_Account__c, objPay.Invoice__c, -1*amountToRefund, 'Success');
                newPayment.refund_Id__c = refundObj.id;
                newPayment.remarks__c = remark;
                newPayment.Parent_Payment__c = objPay.Id;
                //paymentList.add(newPayment);
                Insert newPayment;
                SageIntacctIntegrationUtility.refundPayment(newPayment.id);	 
             
                if(String.isNotBlank(objPay.invoice__c)){
                    Invoice__c objInv = [SELECT Id,Balance_Amount__c,Status__c FROM Invoice__c WHERE Id=: objPay.invoice__c];
                    //System.debug('objInv '+objInv);
                    if(objInv.Balance_Amount__c > 0){
                        objInv.Status__c = ConstantsClass.dueStatus;
                        UPDATE objInv;
                    }
                }
            }else{
                if(refundObj.error != null){
                    msg = refundObj.error.message;
                }
            }
        }else{
            msg = 'Amount can not be more then payment amount.';
        }
        return msg;
    }
}