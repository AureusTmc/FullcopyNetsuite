trigger UpdateInvoiceAmount on Invoice_Line_Item__c (After insert,After Update,After Delete) {
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate || trigger.isUndelete){
            // This trigger is updating the total Deposit Value on enrolment with the sum of amount on Invoice line item when isdeposit is true and status not =  (void,Cancelled)
            UpdateInvoiceAmountClass.sumInvoiceLineAmount(Trigger.New);   
        }
        if(trigger.isDelete){
            UpdateInvoiceAmountClass.deleteInvoiceLineAmount(Trigger.Old); 
        }        
    }
    
}