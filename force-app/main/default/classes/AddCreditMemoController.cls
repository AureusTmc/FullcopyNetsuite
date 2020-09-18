public with sharing class AddCreditMemoController {
    @AuraEnabled
    public static creditMemoWrap getCreditMemoDetails(Id invId) {
        system.debug('invId --> ' + invId);
        creditMemoWrap objCreditMemoWrap = new creditMemoWrap();
        
        // prettier-ignore
        if ( String.isBlank(invId) || invId.getSobjectType() != Schema.Invoice__c.SObjectType) {
            objCreditMemoWrap.isError = 'Invalid Invoice Id';
            return objCreditMemoWrap;
            
        } else {
            //we will include inv line item having negative amount as well
            for (Invoice__c objInv : [ SELECT Id, Status__c,Currency_Code__c,Name,                                    
                                      (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c	 FROM Invoice_Line_Items__r)
                                      FROM Invoice__c 
                                      WHERE ID = :invId ]) {
                                          
                                          objCreditMemoWrap.invoiceStatus = objInv.Status__c;
                                          objCreditMemoWrap.invoiceCurrcyCode = objInv.Currency_Code__c;
                                          objCreditMemoWrap.objInvoiceName = objInv.Name;
                                          objCreditMemoWrap.invoiceId = invId;
                                          
                                          if( objInv.Invoice_Line_Items__r.size() > 0 ){
                                              
                                              for( Invoice_Line_Item__c objInvLine : objInv.Invoice_Line_Items__r ){
                                                  
                                                  system.debug('objInvLine.Amount__c --> ' + objInvLine.Amount__c);
                                                  if( objInvLine.Amount__c != Null )
                                                      objCreditMemoWrap.invoiceAmount += objInvLine.Amount__c;
                                                  
                                                  if( objInvLine.GST_Amount__c != Null )
                                                      objCreditMemoWrap.invoiceAmount += objInvLine.GST_Amount__c;
                                                  
                                              }
                                              
                                          }
                                      }
            //to scale it till two decimal points
            if(  objCreditMemoWrap.invoiceAmount > 0 ){
                objCreditMemoWrap.invoiceAmount = BillingUtility.roundOffAmount( objCreditMemoWrap.invoiceAmount );
                system.debug(' --> ' + objCreditMemoWrap.invoiceAmount);
            }
            
            for( Credit_Memo__c objCreditMem : [ SELECT ID,Name FROM Credit_Memo__c WHERE From_Invoice__c =: objCreditMemoWrap.invoiceId ] ){
                objCreditMemoWrap.existCreditMemo = objCreditMem.Name;
            }
        }
        return objCreditMemoWrap;
    }
    
    //make sure to add tax amount as gst in credit line item
    @AuraEnabled
    public static String createCreditMemo(
        String creditWrapJson,
        String creditMode,
        String remarks
    ) {
        System.debug(creditWrapJson);
        system.debug(remarks);
        
        String message = 'success';
        Savepoint objSavePoint;
        Credit_Memo__c objCreditMemo = new Credit_Memo__c();
        list<Credit_memo_line_item__c> listCreditLineItem;
        
        try {
            creditMemoWrap creditWrap = (creditMemoWrap) JSON.deserialize(
                creditWrapJson,
                creditMemoWrap.class
            );
            //need to do this in wrapper from lwc to apex, it cannot desrialize nested query results (FATAL_ERROR System.JSONException: QueryResult must start with '{')
            // prettier-ignore
            Invoice__c objInvoice = [ SELECT Id, Status__c,Currency_Code__c,Name,Parent_Account__c,Center__c,                                   
                                     (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c FROM Invoice_Line_Items__r),
                                     (SELECT Id, Payment_Amount__c, Transaction_Id__c, remarks__c, Invoice__c, Parent_Account__c, 
                                      Invoice__r.Center__r.Organisation__r.name,Payment_Date__c,method_of_payment__c,
                                      Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c
                                      FROM Payments__r LIMIT 1 ) 
                                     FROM Invoice__c 
                                     WHERE ID = :creditWrap.invoiceId];
            if (creditMode == 'Refund Memo') {
                // prettier-ignore
                Decimal amountToRefund =  BillingUtility.roundOffAmount( creditWrap.invoiceAmount );
                System.debug(creditWrap.invoiceAmount);
                system.debug(amountToRefund);
                // prettier-ignore
                if( String.isNotBlank(objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Id) && String.isNotBlank(objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c) && 
                   String.isNotBlank(objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c) &&
                   amountToRefund > 0 &&  objInvoice.Payments__r[0].Payment_Amount__c >= amountToRefund && String.isNotBlank(objInvoice.Payments__r[0].Transaction_Id__c) ){
                       
                       BillingUtility.StripeRefund  refundObj = BillingUtility.createRefundForCharge(objInvoice.Payments__r[0].Transaction_Id__c,amountToRefund, objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c);
                       
                       system.debug(refundObj);
                       if(refundObj.statusCode == 200 && refundObj.status == 'succeeded'){
                           objCreditMemo = createCreditMemoRec( objInvoice.Parent_Account__c,objInvoice.Center__c,objInvoice.Id,'Success',remarks,false);
                           objCreditMemo.Refund_ID__c = refundObj.id;
                       }else{
                           if(refundObj.error != null){
                               message = refundObj.error.message;
                           }
                       }
                       
                   }else{
                       message = 'Something went wrong.';
                   }
            }
            objSavePoint = Database.setSavepoint();
            if (creditMode == 'Refund Memo' && objCreditMemo.Status__c == 'Success') {
                insert objCreditMemo;
            }
            
            if (creditMode == 'Credit Memo (Future Adj)') {
                objCreditMemo = createCreditMemoRec(
                    objInvoice.Parent_Account__c,
                    objInvoice.Center__c,
                    objInvoice.Id,
                    'Pending',
                    remarks,
                    true
                );
            } else if (creditMode == 'Credit Memo (Invoice Cancellation)') {
                objCreditMemo = createCreditMemoRec(
                    objInvoice.Parent_Account__c,
                    objInvoice.Center__c,
                    objInvoice.Id,
                    'Success',
                    remarks,
                    true
                );
            }
            
            if (String.isNotBlank(objCreditMemo.Id)) {
                system.debug(objCreditMemo.Id);
                listCreditLineItem = new List<Credit_memo_line_item__c>();
                for (
                    Invoice_Line_Item__c objInvLine : objInvoice.Invoice_Line_Items__r
                ) {
                    listCreditLineItem.add(
                        createCreditMemoLineRec(
                            objCreditMemo.Id,
                            objInvLine.Amount__c,
                            objInvLine.GST_Amount__c,
                            objInvLine.Package__c,
                            objInvLine.Enrolment__c,
                            objInvLine.Id,
                            remarks,
                            objInvLine.Is_Deposit__c,
                            objInvLine.Is_Discount__c,
                            false
                        )
                    );
                }
                
                if (listCreditLineItem.size() > 0)
                    insert listCreditLineItem;
            }
        } catch (Exception objExcp) {
            Database.rollback(objSavePoint);
            message = objExcp.getMessage();
        }
        
        return message;
    }
    
    public static Credit_Memo__c createCreditMemoRec(
        Id parentAccntId,
        Id centerId,
        String invId,
        String Status,
        String reason,
        Boolean isDMl
    ) {
        Credit_Memo__c objCreditMemo = new Credit_Memo__c();
        objCreditMemo.Parent_Account__c = parentAccntId;
        objCreditMemo.Center__c = centerId;
        objCreditMemo.From_Invoice__c = invId;
        objCreditMemo.Credit_Memo_Date__c = date.today();
        objCreditMemo.Status__c = Status;
        objCreditMemo.Comments__c = reason;
        
        if (isDml)
            insert objCreditMemo;
        
        System.debug(objCreditMemo);
        return objCreditMemo;
    }
    
    public static Credit_memo_line_item__c createCreditMemoLineRec(
        Id creditMemoId,
        Decimal amount,
        Decimal taxAmount,
        Id packageId,
        Id enrolmentId,
        Id invoiceLineItemId,
        String reasons,
        Boolean isDeposit,
        Boolean isDiscount,
        Boolean isDMl
    ) {
        Credit_memo_line_item__c objCreditLineItem = new Credit_memo_line_item__c();
        objCreditLineItem.Credit_Memo_Number__c = creditMemoId;
        objCreditLineItem.Amount__c = amount;
        objCreditLineItem.Tax_Amount__c = taxAmount;
        objCreditLineItem.Package__c = packageId;
        objCreditLineItem.Enrolment__c = enrolmentId;
        objCreditLineItem.Invoice_Line_Item__c = invoiceLineItemId;
        objCreditLineItem.Is_Deposit__c = isDeposit;
        objCreditLineItem.Is_Discount__c = isDiscount;
        //objCreditLineItem.Remarks__c = reasons;
        if (isDml)
            insert objCreditLineItem;
        return objCreditLineItem;
    }
    
    public class creditMemoWrap {
        @AuraEnabled
        public Decimal invoiceAmount;
        @AuraEnabled
        public String existCreditMemo;
        @AuraEnabled
        public String invoiceCurrcyCode;
        @AuraEnabled
        public String invoiceStatus;
        @AuraEnabled
        public String isError;
        @AuraEnabled
        public String objInvoiceName;
        @AuraEnabled
        public String invoiceId;
        
        public creditMemoWrap() {
            invoiceAmount = 0;
            existCreditMemo = '';
            isError = '';
            invoiceStatus = '';
            invoiceCurrcyCode = '';
            objInvoiceName = '';
        }
    }
}