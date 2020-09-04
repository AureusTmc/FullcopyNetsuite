/**
 * Name         :       PaymentTriggerHandler
 * Date         :       21 June 2019
 * Author       :       
 * Description  :       To Updaet Invoice Paid Amount from Payment whose record type os PaymentAsCredit or PaymentAs Deposit
*/
public Class PaymentTriggerHandler{
    public static void transferToInvoice( List<Payment__c> payments ){
        List<Invoice__c> paymentInvoice = new List<Invoice__c>();
        Set<Id> listInvoiceIds = new Set<Id>();
        Id paymentDepositId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        Id paymentCreditId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId();
        Id paymentTransactionId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        for( Payment__c payment : payments ){
            if( ( payment.RecordTypeId == paymentDepositId || payment.RecordTypeId == paymentCreditId || 
                  payment.RecordTypeId == paymentTransactionId ) && 
                payment.Invoice__c != NULL){
                listInvoiceIds.add(payment.Invoice__c); 
            }
        }
        system.debug('listInvoiceIds'+listInvoiceIds);
        if( listInvoiceIds != NULL && listInvoiceIds.size() > 0 ){
            for( AggregateResult aggRes : [ SELECT Invoice__c, SUM(Payment_Amount__c) total FROM Payment__c WHERE Invoice__c IN: listInvoiceIds GROUP BY invoice__c ] ){
                Invoice__c invoice = new Invoice__c( Id = (Id)aggRes.get('Invoice__c') );
                invoice.Paid_Amount__c = aggRes.get('total') != NULL ? (Decimal)aggRes.get('total') : 0;
                paymentInvoice.add( invoice );
                listInvoiceIds.remove( (Id)aggRes.get('Invoice__c') );
            }  
            //if invoice has left with no payment record then set paid amount to 0
            for( Id invoiceId : listInvoiceIds){
                paymentInvoice.add( new Invoice__c( Id = invoiceId, Paid_Amount__c = 0 ) );
            }
            system.debug('paymentInvoice'+paymentInvoice);
            if( paymentInvoice != NULL && paymentInvoice.size() > 0 ){
                
                UPDATE paymentInvoice;
            }
        }
    }

    //@Jatin 10/22/2019, Add the work due to stripe payout log
    public static void rollUpStripePayoutFees(Set<String> stripePayoutIds){
        List<Stripe_Payout_Log__c> payoutLogList = new List<Stripe_Payout_Log__c>();
        if(stripePayoutIds.size() > 0){

            List<AggregateResult> paymentAggregateList = [SELECT SUM(Stripe_fees__c) fees, Stripe_Payout_Id__c FROM Payment__c WHERE Stripe_Payout_Id__c IN :stripePayoutIds GROUP BY Stripe_Payout_Id__c];
			system.debug('paymentAggregateList'+paymentAggregateList);
            for(AggregateResult paymentAggregate : paymentAggregateList){
                payoutLogList.add(new Stripe_Payout_Log__c(Id = String.valueOf(paymentAggregate.get('Stripe_Payout_Id__c')), Stripe_Fee_charged__c = Double.valueOf(paymentAggregate.get('fees'))));
            }
        }
        system.debug('payoutLogList'+payoutLogList);
        if(payoutLogList.size() > 0){
            UPDATE payoutLogList;
        }
    }
}