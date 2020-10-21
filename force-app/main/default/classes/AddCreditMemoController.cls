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
//CH04 9 Oct 2020 :  Karan Singh -> Adding of remarks from Invoice Line Items to credit memo line items
//CH05 12 Oct 2020 : Karan Singh ->  removing the creteria as if already credit memo existed , then it should not create another Credit memo.
//                    Instead check the invoice's Line Item Amount >  Invoice CM_Created__c amount, then it will allow to create the Credit Memo
//CH06 15 OCt 2020 : Karan Singh ->  Refund a Credit Memo (other than stripe) : Incase the user had made payment without stripe as cash,cheque etc then in that case
//                   it will not hit the stripe api and there are changes in the api instead.
//                    Also changes in the refund toast message in Js.
//CH07 16 Oct 2020 : Add Card Number and Card tyoe in the UI In case of Refund method is Card on file and payment method will be change from cheque to bank 
public with sharing class AddCreditMemoController {
    
    //This method will may refund and create the credit memo or create credit memo only
    @AuraEnabled
    public static creditMemoWrap getCreditMemoDetails(Id invId) {
        system.debug('invId --> ' + invId);
        creditMemoWrap objCreditMemoWrap = new creditMemoWrap();
        
        Decimal invoiceTotalCreditMemoAmount = 0; //CH05
        // prettier-ignore
        if ( String.isBlank(invId) || invId.getSobjectType() != Schema.Invoice__c.SObjectType) {
            objCreditMemoWrap.isError = 'Invalid Invoice Id';
            return objCreditMemoWrap;
            
        } else {
            //we will include inv line item having negative amount as well
            for (Invoice__c objInv : [ SELECT Id, Status__c,Currency_Code__c,Name  
                                        /* CH05 */ ,CM_Created__c,    
                                        
                                        /*CH07 : adding card information details */ Parent_Account__r.Card_Number__c,  Parent_Account__r.Card_Type__c,
                                      (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c	 FROM Invoice_Line_Items__r)
                                      
                                      //CH06 : Start 
                                      ,(SELECT Id, Payment_Amount__c, Transaction_Id__c, remarks__c, Invoice__c, Parent_Account__c, 
                                      Invoice__r.Center__r.Organisation__r.name,Payment_Date__c,method_of_payment__c,
                                      Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c
                                      FROM Payments__r LIMIT 1 ) 
                                      //CH06 : ENd  
                                      FROM Invoice__c 
                                      WHERE ID = :invId ]) {
                                          
                                          objCreditMemoWrap.invoiceStatus = objInv.Status__c;
                                          objCreditMemoWrap.invoiceCurrcyCode = objInv.Currency_Code__c;
                                          objCreditMemoWrap.objInvoiceName = objInv.Name;
                                          objCreditMemoWrap.invoiceId = invId;
                                        
                                          //CH05 Start
                                            if( objInv.CM_Created__c != Null && objInv.CM_Created__c != 0){
                                                invoiceTotalCreditMemoAmount = BillingUtility.roundOffAmount( objInv.CM_Created__c );
                                            }
                                        //CH05 End
                                          if( objInv.Invoice_Line_Items__r.size() > 0 ){
                                              
                                              for( Invoice_Line_Item__c objInvLine : objInv.Invoice_Line_Items__r ){
                                                  
                                                  system.debug('objInvLine.Amount__c --> ' + objInvLine.Amount__c);
                                                  if( objInvLine.Amount__c != Null )
                                                      objCreditMemoWrap.invoiceAmount += objInvLine.Amount__c;
                                                  
                                                  if( objInvLine.GST_Amount__c != Null )
                                                      objCreditMemoWrap.invoiceAmount += objInvLine.GST_Amount__c;
                                                  
                                              }
                                              
                                          }//end of Invoice line Item size check

                                          //CH06 Start : Check if it is Stripe payment or not
                                          if( objInv.Payments__r.size() > 0 && String.isNotBlank(objInv.Payments__r[0].Invoice__r.Center__r.Organisation__r.Id) 
                                            && String.isNotBlank(objInv.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c) 
                                            && String.isNotBlank(objInv.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c) 
                                            && String.isNotBlank(objInv.Payments__r[0].Transaction_Id__c) ){

                                                objCreditMemoWrap.isStripePayment = true;

                                                //CH07 Adding Card Information
                                                if( String.isNotBlank( objInv.Parent_Account__r.Card_Number__c ) ){

                                                    objCreditMemoWrap.cardNumber = 'XXXX-' + objInv.Parent_Account__r.Card_Number__c;
                                                }
                                                if( String.isNotBlank( objInv.Parent_Account__r.Card_Type__c   ) ){
                                                    
                                                    objCreditMemoWrap.cardType = objInv.Parent_Account__r.Card_Type__c;
                                                }
                                                //CH07 END
                                          }
                                        //CH06 ENd

                                      }//end of loop

                                      system.debug(' --> ' + invoiceTotalCreditMemoAmount);
            //to scale it till two decimal points
            if(  objCreditMemoWrap.invoiceAmount > 0 ){
                //objCreditMemoWrap.invoiceAmount = BillingUtility.roundOffAmount( objCreditMemoWrap.invoiceAmount );
                //system.debug(' --> ' + objCreditMemoWrap.invoiceAmount);
                
                //CH05 Start removing any orevious created Credit memo amount
                objCreditMemoWrap.invoiceAmount = objCreditMemoWrap.invoiceAmount - invoiceTotalCreditMemoAmount;
                objCreditMemoWrap.invoiceAmount = BillingUtility.roundOffAmount( objCreditMemoWrap.invoiceAmount );
                system.debug(' --> ' + objCreditMemoWrap.invoiceAmount);
                //CH05 END
            }
            //Ch05 - CHecking the no amount is left for creation of credit memo, then show the user the created Credit memo Name
            if( objCreditMemoWrap.invoiceAmount == 0 ){

                for( Credit_Memo__c objCreditMem : [ SELECT ID,Name FROM Credit_Memo__c WHERE From_Invoice__c =: objCreditMemoWrap.invoiceId ] ){
                    objCreditMemoWrap.existCreditMemo = objCreditMemoWrap.existCreditMemo + objCreditMem.Name + '  ';
                }
            }
            //Ch05 End

            /*Commneted due to CH05
            for( Credit_Memo__c objCreditMem : [ SELECT ID,Name FROM Credit_Memo__c WHERE From_Invoice__c =: objCreditMemoWrap.invoiceId ] ){
                objCreditMemoWrap.existCreditMemo = objCreditMem.Name;
            }*/
            //CH05 Start
            
            //CH05 ENd
            
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
                                     (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c
                                     //CH04 added this field
                                     ,Remarks__c
                                     //CH04 ENd
                                     
                                     FROM Invoice_Line_Items__r),
                                     (SELECT Id, Payment_Amount__c, Transaction_Id__c, remarks__c, Invoice__c, Parent_Account__c, 
                                      Invoice__r.Center__r.Organisation__r.name,Payment_Date__c,method_of_payment__c,
                                      Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c
                                      FROM Payments__r LIMIT 1 ) 
                                     FROM Invoice__c 
                                     WHERE ID = :creditWrap.invoiceId];

            if (creditMode == 'Refund Memo' && creditWrap.isStripePayment ) { //CH06 : added isStripePayment creteria
                //if (creditMode == 'Refund Memo') { //CH06 : in case of Stripe Trnsaction is found , then only it will work
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
                           objCreditMemo.Refund_ID__c = Cheque_No__c.id;
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

            //CH06  : added creditWrap.isStripePayment creteria in this if
            if ( creditWrap.isStripePayment && creditMode == 'Refund Memo' && objCreditMemo.Status__c == 'Success') {
                
                //CH01 21 Sep 2020 : Karan incase of refund, also add the payment method
                objCreditMemo.Payment_Method__c =  objInvoice.Payments__r[0].Method_of_Payment__c;
                //CH01 end
                insert objCreditMemo;
            } 
            //CH06 : Creating Credit Memo for the offline refunds, Aureus will refund them as per their convince
            if( !creditWrap.isStripePayment && creditMode == 'Refund Memo' ){

                objCreditMemo = createCreditMemoRec( objInvoice.Parent_Account__c,objInvoice.Center__c,objInvoice.Id,'Success',remarks,false);
                objCreditMemo.Payment_Method__c = 'Bank';  //CH04 : change the payment method Cheque
                insert objCreditMemo;
            }
            //CH06 ENd
            
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
                        //commented by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                        //objInvLine.Credit_Memo_Amount__c = objInvLine.Credit_Memo_Amount__c  + objInvLine.GST_Amount__c;
                        objInvLine.Credit_Memo_Tax__c = objInvLine.GST_Amount__c;
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
        
        objCreditLineItem.Remarks__c = objInvLine.Remarks__c;
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

        //CH06 Start : checking if the payment is done with stripe or not
        @AuraEnabled
        public Boolean isStripePayment;
        //CH06 ENd

        //CH07 Start
        @AuraEnabled
        public String cardNumber;
        @AuraEnabled
        public String cardType;
        //CH07 END

        public creditMemoWrap() {
            invoiceAmount = 0;
            existCreditMemo = '';
            isError = '';
            invoiceStatus = '';
            invoiceCurrcyCode = '';
            objInvoiceName = '';
            isStripePayment = false; //Ch06

            //CH07 Start
            cardNumber = 'XXXX-XXXX';
            cardType = 'X-Card';
            //CH07 END
        }
    }
}