public with sharing class RefundCreditMemoController {
    
    //____________________________________________  INITIALIZATION  _____________________________________________________________
    @AuraEnabled
    public static creditMemoWrap getCreditMemoDetails(Id creditMemoId) {
        system.debug('creditMemoId --> ' + creditMemoId);
        creditMemoWrap objCreditMemoWrap = new creditMemoWrap();
        
        // prettier-ignore
        if ( String.isBlank(creditMemoId) || creditMemoId.getSobjectType() != Schema.Credit_Memo__c.SObjectType) {
            objCreditMemoWrap.isError = 'Invalid Credit Memo Id';
            return objCreditMemoWrap;
            
        } else {
            
            for( Credit_Memo__c objCredit : [ SELECT Total_Amount__c,Currency_Code__c,From_Invoice__c 
                                             FROM Credit_Memo__c 
                                             WHERE ID =: creditMemoId 
                                             AND Status__c = 'Pending' ] ){
                                                 objCreditMemoWrap.creditMemoAmnt = objCredit.Total_Amount__c;
                                                 objCreditMemoWrap.creditCurrcyCode = objCredit.Currency_Code__c;
                                                 objCreditMemoWrap.parentInvoiceId = objCredit.From_Invoice__c;
                                                 objCreditMemoWrap.creditMemoId = objCredit.Id;
                                             }
        }
        system.debug(objCreditMemoWrap.parentInvoiceId);
        
        if( String.isBlank( objCreditMemoWrap.parentInvoiceId )){
            objCreditMemoWrap.isError = 'No Invoice linked to this Credit Memo.';
        }
        //to scale it till two decimal points
        if(  objCreditMemoWrap.creditMemoAmnt > 0 ){
            
            objCreditMemoWrap.creditMemoAmnt = BillingUtility.roundOffAmount( objCreditMemoWrap.creditMemoAmnt );
            objCreditMemoWrap.userEnterAMount = objCreditMemoWrap.creditMemoAmnt;
        }
        system.debug(' --> ' + objCreditMemoWrap.creditMemoAmnt);
        
        if( objCreditMemoWrap.creditMemoAmnt <= 0 ){
            objCreditMemoWrap.isError = 'No Amount to refund';
        }
        return objCreditMemoWrap;
    }
    
    //____________________________________________  Refund Credit MEmo  _____________________________________________________________
    @AuraEnabled
    public static string refundCreditMemo(  String objCreditMemoJSON ){
        
        String message = 'Success';
        Boolean isPaymentSuccess = false;
        String refundId = '';
        Savepoint objSavePoint;
        Credit_Memo__c cloneCreditMemo = new Credit_Memo__c();
        list< Credit_memo_line_item__c > listCreditMemoLineItem = new list< Credit_memo_line_item__c >();
        list< Credit_memo_line_item__c > listDeleteCreditMemoLineItem = new list< Credit_memo_line_item__c >();
        
        system.debug(objCreditMemoJSON);
        if( String.isBlank( objCreditMemoJSON )){
            return 'Did not recieved the correct Information. Please contact System Admin.';
        }else{
            try{
                
                creditMemoWrap objCreditMemoWrap = (creditMemoWrap) JSON.deserialize( objCreditMemoJSON,creditMemoWrap.class);
                System.debug( objCreditMemoWrap );
                
                Invoice__c objInvoice = [ SELECT Id,Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c,
                                         //Status__c,Currency_Code__c,Name,Parent_Account__c,Center__c,                                   
                                         //(SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c FROM Invoice_Line_Items__r),
                                         (SELECT Id, Payment_Amount__c, Transaction_Id__c, remarks__c, Invoice__c, Parent_Account__c, 
                                          Invoice__r.Center__r.Organisation__r.name,Payment_Date__c,method_of_payment__c,
                                          Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c
                                          FROM Payments__r LIMIT 1 ) 
                                         FROM Invoice__c 
                                         WHERE ID = : objCreditMemoWrap.parentInvoiceId];
                
                Credit_Memo__c objCreditMemo = [ SELECT Id, Status__c,Parent_Account__c,Center__c,From_Invoice__c,Bank_Name__c,Cheque_Date__c,
                                                Cheque_No__c,Comments__c,Field_1__c,NETS_Code__c,Payment_Method__c,Stripe_Fee__c,
                                                ( SELECT Id,Transaction_ID__c, Credit_Memo_Number__c, Enrolment__c, Amount__c, Netsuite_GST_Code__c, Tax_Amount__c, 
                                                 Month__c, Remarks__c, Package__c, Is_Deposit__c, Is_Discount__c,Invoice_Line_Item__c, Package_Name__c,
                                                 Netsuite_Product_Name__c
                                                 FROM Credit_memo_line_items__r order by Amount__c Desc
                                                ) 
                                                FROM Credit_Memo__c
                                                WHERE ID =: objCreditMemoWrap.creditMemoId ];
                
                system.debug(objInvoice);
                system.debug(objCreditMemo);
                
                Decimal amountToRefund =  BillingUtility.roundOffAmount( objCreditMemoWrap.userEnterAMount );
                system.debug(amountToRefund);
                if(  objInvoice.Payments__r.size() == 0 ){
                    return 'Cannot find the payment record associated with the linked invoice amount';
                }
                if( String.isNotBlank(objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Id) && String.isNotBlank(objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c) && 
                   String.isNotBlank(objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c) &&
                   amountToRefund > 0 &&  objInvoice.Payments__r[0].Payment_Amount__c >= amountToRefund && String.isNotBlank(objInvoice.Payments__r[0].Transaction_Id__c) ){
                       
                    BillingUtility.StripeRefund  refundObj;
                    if(Test.isRunningTest()){
                        refundObj = BillingUtility.createRefundForCharge(objInvoice.Payments__r[0].Transaction_Id__c,amountToRefund, objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, objInvoice.Payments__r[0].Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c);
                    }
                    
                       else{
                        refundObj =  new BillingUtility.StripeRefund();
                        refundObj.statusCode = 200;
                        refundObj.status = 'succeeded';
                        refundObj.id = 'test';
                       }

                       system.debug(refundObj);
                       if(refundObj.statusCode == 200 && refundObj.status == 'succeeded'){
                           isPaymentSuccess = true;
                           refundId = refundObj.id;
                       }else{
                           if(refundObj.error != null){
                               message = refundObj.error.message;
                           }
                       }
                       
                   }else{
                       message = 'Something went wrong.';
                   }
                
                //incase of payment successful then only update the credit memo
                if( isPaymentSuccess ){
                    
                    objSavePoint = Database.setSavepoint();
                    system.debug(objCreditMemoWrap.creditMemoAmnt == objCreditMemoWrap.userEnterAMount);
                    //incase of full amount refund
                    if( objCreditMemoWrap.creditMemoAmnt == objCreditMemoWrap.userEnterAMount ){
                        
                        objCreditMemo.Refund_ID__c = refundId;
                        objCreditMemo.Payment_Method__c =  objInvoice.Payments__r[0].Method_of_Payment__c;
                        objCreditMemo.Status__c = 'Success';
                        objCreditMemo.Credit_Memo_Date__c = Date.today();
                        objCreditMemo.Comments__c = objCreditMemoWrap.userRemarks;
                        update objCreditMemo;
                    }
                    //incase of partial refund
                    else{
                        
                        Decimal adjustmentAmnt = objCreditMemoWrap.userEnterAMount;
                        Boolean isAdjustmentDOne = false;
                        
                        cloneCreditMemo.Status__c = 'Pending';
                        objCreditMemo.Status__c = 'Success';
                        cloneCreditMemo.Parent_Account__c = objCreditMemo.Parent_Account__c;
                        cloneCreditMemo.Center__c = objCreditMemo.Parent_Account__c;
                        cloneCreditMemo.Bank_Name__c = objCreditMemo.Bank_Name__c;
                        cloneCreditMemo.Cheque_Date__c = objCreditMemo.Cheque_Date__c;
                        cloneCreditMemo.Cheque_No__c = objCreditMemo.Cheque_No__c;
                        cloneCreditMemo.Field_1__c = objCreditMemo.Field_1__c;
                        cloneCreditMemo.NETS_Code__c = objCreditMemo.NETS_Code__c;
                        cloneCreditMemo.Payment_Method__c = objCreditMemo.Parent_Account__c;
                        cloneCreditMemo.Comments__c = objCreditMemoWrap.userRemarks;
                        
                        upsert new list<Credit_Memo__c>{ cloneCreditMemo,objCreditMemo};
                            
                            for( Credit_memo_line_item__c objExistingCreditMemoLine : objCreditMemo.Credit_memo_line_items__r ){
                                
                                if( isAdjustmentDOne ){
                                    
                                    Credit_memo_line_item__c newCreditMemoLineItem = new Credit_memo_line_item__c();
                                    newCreditMemoLineItem.Amount__c = objExistingCreditMemoLine.Amount__c;
                                    newCreditMemoLineItem.Tax_Amount__c = objExistingCreditMemoLine.Tax_Amount__c;
                                    newCreditMemoLineItem.Credit_Memo_Number__c = cloneCreditMemo.Id;
                                    newCreditMemoLineItem.Enrolment__c = objExistingCreditMemoLine.Enrolment__c;
                                    newCreditMemoLineItem.Month__c = objExistingCreditMemoLine.Month__c;
                                    newCreditMemoLineItem.Package__c = objExistingCreditMemoLine.Package__c;
                                    newCreditMemoLineItem.Is_Deposit__c = objExistingCreditMemoLine.Is_Deposit__c;
                                    newCreditMemoLineItem.Is_Discount__c = objExistingCreditMemoLine.Is_Discount__c; 
                                    newCreditMemoLineItem.Invoice_Line_Item__c = objExistingCreditMemoLine.Invoice_Line_Item__c;
                                    listCreditMemoLineItem.add( newCreditMemoLineItem );
                                    listDeleteCreditMemoLineItem.add(objExistingCreditMemoLine);
                                    
                                }else{
                                    
                                    if( adjustmentAmnt >= ( objExistingCreditMemoLine.Amount__c + objExistingCreditMemoLine.Tax_Amount__c )){
                                        
                                        adjustmentAmnt = adjustmentAmnt - (objExistingCreditMemoLine.Amount__c + objExistingCreditMemoLine.Tax_Amount__c);
                                    }
                                    else{
                                        
                                        if( adjustmentAmnt == 0 ){
                                            isAdjustmentDOne = true;
                                        }else{
                                            
                                            Decimal newCreditLineItemAmount = (objExistingCreditMemoLine.Amount__c + objExistingCreditMemoLine.Tax_Amount__c);
                                            
                                            newCreditLineItemAmount = newCreditLineItemAmount - adjustmentAmnt;
                                            
                                            if( objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != Null && objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != 0 ){
                                                
                                                objExistingCreditMemoLine.Tax_Amount__c = (objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c/100)*newCreditLineItemAmount;
                                            }else{
                                                objExistingCreditMemoLine.Tax_Amount__c = 0;
                                            }
                                            objExistingCreditMemoLine.Amount__c = newCreditLineItemAmount - objExistingCreditMemoLine.Tax_Amount__c;
                                            
                                            listCreditMemoLineItem.add( objExistingCreditMemoLine );
                                            
                                            Credit_memo_line_item__c newCreditMemoLineItem = new Credit_memo_line_item__c();
                                            
                                            if( objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != Null && objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != 0 ){
                                                
                                                newCreditMemoLineItem.Tax_Amount__c = (objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c/100)*adjustmentAmnt;
                                            }else{
                                                newCreditMemoLineItem.Tax_Amount__c = 0;
                                            }
                                            newCreditMemoLineItem.Amount__c = adjustmentAmnt - newCreditMemoLineItem.Tax_Amount__c;
                                            newCreditMemoLineItem.Credit_Memo_Number__c = cloneCreditMemo.Id;
                                            newCreditMemoLineItem.Enrolment__c = objExistingCreditMemoLine.Enrolment__c;
                                            newCreditMemoLineItem.Month__c = objExistingCreditMemoLine.Month__c;
                                            newCreditMemoLineItem.Package__c = objExistingCreditMemoLine.Package__c;
                                            newCreditMemoLineItem.Is_Deposit__c = objExistingCreditMemoLine.Is_Deposit__c;
                                            newCreditMemoLineItem.Is_Discount__c = objExistingCreditMemoLine.Is_Discount__c; 
                                            newCreditMemoLineItem.Invoice_Line_Item__c = objExistingCreditMemoLine.Invoice_Line_Item__c;
                                            listCreditMemoLineItem.add( newCreditMemoLineItem );
                                        }
                                    }
                                }
                                
                            }//end of credit memo line item loop
                    }//end of partial refund case
                    
                }//end of successfule payment check


                if(listCreditMemoLineItem.size() > 0 )
                upsert listCreditMemoLineItem;
                if(listDeleteCreditMemoLineItem.size() > 0 )
                delete listDeleteCreditMemoLineItem;
            }Catch( Exception objExcp ){
                Database.rollback(objSavePoint);
                message = objExcp.getMessage();
            }
        }//end of objCreditMemoJSON Null check
        
        return message;
    }
    //_______________________________________________ WRAPPER CLASS _____________________________________________________________
    public class creditMemoWrap {
        @AuraEnabled
        public Decimal creditMemoAmnt;
        @AuraEnabled
        public String creditCurrcyCode;
        @AuraEnabled
        public String isError;
        @AuraEnabled
        public String creditMemoId;
        @AuraEnabled
        public String parentInvoiceId;
        @AuraEnabled
        public Decimal userEnterAMount;
        @AuraEnabled
        public String userRemarks;
        
        //_____________________________________________Constructor ______________________________________________________
        public creditMemoWrap() {
            creditMemoAmnt = 0;
            userEnterAMount = 0;
            isError = '';
            creditCurrcyCode = '';
            creditMemoId = '';
            userRemarks = '';
            parentInvoiceId = '';
        }
    }
}