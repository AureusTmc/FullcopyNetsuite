/*
Name        :        AddCreditMemoController
Date        :        13 Sep 2020
Author      :        Karan Singh Soni
Test Class  :        AddCreditMemoControllerTest
Component   :		 AddCreditMemo(LWC)
*/

//CH01 21 Sep 2020 : Karan SIngh add credit memo line item amount in the linked invoice line item Credit_Memo_Amount__c
//						Also add remarks in the Invoice in case of voiding it and also link the from and to Invoice of credit memo to same invoice itself.
//						Also  only populate Credit Memo : Credit_Memo_Date__c in case of success status only.
//						Also Addng new field mapping for the Credit memo/line item as per fields req in  credit memo reports 
//CH02 24 Sep 2020 : Karan Singh Adding the Gst AMount + Amount in the invoice line item credit amount so that it can balance out the invoice line item total amount
//CH03 25 Sep 2020 : Karan Singh Need -> Ashish bansal : to set the intial value of Credit Memo Date in creation of Credit memo not of Success Status (CH01)

public with sharing class AddCreditMemoController {
    
    //This method will may refund and create the credit memo or create credit memo only
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
        
        //CH01 Start
        list< Invoice_Line_Item__c > listInvoiceLineItem = new list< Invoice_Line_Item__c >();
        //CH01 end
        try {
            creditMemoWrap creditWrap = (creditMemoWrap) JSON.deserialize(
                creditWrapJson,
                creditMemoWrap.class
            );
            //need to do this in wrapper from lwc to apex, it cannot desrialize nested query results (FATAL_ERROR System.JSONException: QueryResult must start with '{')
            // prettier-ignore
            Invoice__c objInvoice = [ SELECT Id, Status__c,Currency_Code__c,Name,Parent_Account__c,Center__c,                                   
                                     (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c FROM Invoice_Line_Items__r),
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
                       
                       BillingUtility.StripeRefund  refundObj;
                       
                       if( !Test.isRunningTest() ){
                           refundObj = BillingUtility.createRefundForCharge(objInvoice.Payments__r[0].Transaction_Id__c,amountToRefund, objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c);
                       }else{
                           refundObj = new BillingUtility.StripeRefund();
                           refundObj.statusCode = 200;
                           refundObj.status = 'succeeded';
                           refundObj.id = 'TestId';
                       }
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
                
                //CH01 21 Sep 2020 : Karan incase of refund, also add the payment method
                objCreditMemo.Payment_Method__c =  objInvoice.Payments__r[0].Method_of_Payment__c;
                //CH01 end
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
                    false
                );
                
                //CH01 21 Sep 2020: Linking it with same invoice
                objCreditMemo.Invoice_Number__c = objInvoice.Id;
                insert objCreditMemo;
                //CH01 ENd
                //Karan 18 Sep 2020 : Change the status of the invoice to Void after creating the credit memo. This is applicable only for Due invoices
                objInvoice.Status__c = 'Void';
                
                //CH01 21 Sep 2020: Adding voiding reason as well
                objInvoice.Remarks__c = remarks;
                //CH01 END
                update objInvoice;
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
                            remarks,
                             false,
                            objInvLine                       
                        )
                    );
                    
                    //CH01 Start
                    objInvLine.Credit_Memo_Amount__c = objInvLine.Amount__c;
                    //CH02
                    if( objInvLine.GST_Amount__c != Null ){
                    objInvLine.Credit_Memo_Amount__c = objInvLine.Credit_Memo_Amount__c  + objInvLine.GST_Amount__c;
                    }
                    //CH02 END
                    listInvoiceLineItem.add(objInvLine);
                    //CH01 END
                }
                
                if (listCreditLineItem.size() > 0)
                    insert listCreditLineItem;
                
                //CH01 Start
                if( listInvoiceLineItem.size() > 0 )
                    update listInvoiceLineItem;
                //CH01 END
            }
        } catch (Exception objExcp) {
            if(objSavePoint != Null){
            Database.rollback(objSavePoint);    
            }
            
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
        
        //CH01 : only populate date in case of success status only.
        //CH03 commneting and canclling CH01 point if( Status == 'Success' ){
            objCreditMemo.Credit_Memo_Date__c = date.today(); 
        //CH03 }
        //CH01
        objCreditMemo.Status__c = Status;
        objCreditMemo.Comments__c = reason;
        
        if (isDml)
            insert objCreditMemo;
        
        System.debug(objCreditMemo);
        return objCreditMemo;
    }
    
    public static Credit_memo_line_item__c createCreditMemoLineRec(
        Id creditMemoId,
        String reasons,
         Boolean isDMl,
        Invoice_Line_Item__c objInvLine
        
    ) {
        Credit_memo_line_item__c objCreditLineItem = new Credit_memo_line_item__c();
        objCreditLineItem.Credit_Memo_Number__c = creditMemoId;
        objCreditLineItem.Amount__c = objInvLine.Amount__c;
        objCreditLineItem.Tax_Amount__c = objInvLine.GST_Amount__c;
        objCreditLineItem.Package__c = objInvLine.Package__c;
        objCreditLineItem.Enrolment__c = objInvLine.Enrolment__c;
        objCreditLineItem.Invoice_Line_Item__c = objInvLine.Id;
        objCreditLineItem.Is_Deposit__c = objInvLine.Is_Deposit__c;
        objCreditLineItem.Is_Discount__c = objInvLine.Is_Discount__c;
        
        //CH01 Start
        objCreditLineItem.Month__c = objInvLine.Month__c;
        //CH01 ENd
        
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