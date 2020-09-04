/**
 * Name         :       PaymentTrigger
 * Date         :       21 June 2019
 * Author       :       
 * Description  :       To Updaet Invoice Paid Amount from Payment whose record type os PaymentAsCredit or PaymentAs Deposit
*/
trigger PaymentTrigger on Payment__c (after insert,after update,after delete,after undelete, before insert) {
    
    Set<String> setOfPayouts = new Set<String>();

    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete){
             PaymentTriggerHandler.transferToInvoice( Trigger.New );  
             if( Trigger.isUpdate ){
                 //If invoice id changes
                 PaymentTriggerHandler.transferToInvoice( Trigger.old );   
             }    
        }else if(Trigger.isDelete){
            PaymentTriggerHandler.transferToInvoice( Trigger.Old );
        }
        //@Jatin 10/22/2019, Add the work due to stripe payout log
        if(Trigger.isUpdate){
            for(Payment__c paymentObj : Trigger.New){
                if(String.isNotBlank(paymentObj.Stripe_Payout_Id__c) && paymentObj.Stripe_fees__c != NULL && paymentObj.Stripe_fees__c != Trigger.oldMap.get(paymentObj.Id).Stripe_fees__c){
                    setOfPayouts.add(paymentObj.Stripe_Payout_Id__c);
                }
            }
            system.debug('setOfPayouts'+setOfPayouts);
            if(setOfPayouts.size() > 0){
                PaymentTriggerHandler.rollUpStripePayoutFees(setOfPayouts);
            }
        }
        
    }
    if(Trigger.isBefore && Trigger.isInsert){
        for(Payment__c pay : Trigger.New){
            pay.Name = 'New Payment Name';
        }
    }

}