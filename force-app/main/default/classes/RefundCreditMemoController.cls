/*
Name        :        RefundCreditMemoControllerTest
Date        :        24 Sep 2020
Author      :        Karan Singh Soni
Apex Class :        RefundCreditMemoController
*/
//CH01 25 Sep 2020 : Karan Singh : Ashish Bansal -> on the status as success credit memo date will also populate.
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
                       if(!Test.isRunningTest()){
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
                    //incase of full amount refund simply update the existing credit memo
                    if( objCreditMemoWrap.creditMemoAmnt == objCreditMemoWrap.userEnterAMount ){
                        
                        objCreditMemo.Refund_ID__c = refundId;
                        objCreditMemo.Payment_Method__c =  objInvoice.Payments__r[0].Method_of_Payment__c;
                        objCreditMemo.Status__c = 'Success';
                        objCreditMemo.Credit_Memo_Date__c = Date.today();
                        objCreditMemo.Comments__c = objCreditMemoWrap.userRemarks;
                        update objCreditMemo;
                    }
                    //incase of partial refund- we will adjust the credit memo line item amount with the user enter amount, the remaining balnce will be used in new 
                    //credit memo and it's line item + also calculating taxes while adjusting the amount 
                    else{
                        
                        Decimal adjustmentAmnt = objCreditMemoWrap.userEnterAMount;
                        
                        //this is notify that the adjustment amount is fully done, then we will clone the existing the creditmemo line item to the new credit memo and delete the existing
                        Boolean isAdjustmentDOne = false;								
                        
                        //___________________________________________  Cloning the existing credit memo and updating it _______________________________________________
                        objCreditMemo.Refund_ID__c = refundId;
                        cloneCreditMemo.Status__c = 'Pending';
                        objCreditMemo.Status__c = 'Success';
                        
                        //CH02
                        objCreditMemo.Credit_Memo_Date__c = Date.today();
                        cloneCreditMemo.Credit_Memo_Date__c = Date.today();
                        //CH02
                        objCreditMemo.Payment_Method__c =  objInvoice.Payments__r[0].Method_of_Payment__c;
                        cloneCreditMemo.Parent_Account__c = objCreditMemo.Parent_Account__c;
                        cloneCreditMemo.Center__c = objCreditMemo.Center__c;
                        cloneCreditMemo.Bank_Name__c = objCreditMemo.Bank_Name__c;
                        cloneCreditMemo.Cheque_Date__c = objCreditMemo.Cheque_Date__c;
                        cloneCreditMemo.Cheque_No__c = objCreditMemo.Cheque_No__c;
                        cloneCreditMemo.Field_1__c = objCreditMemo.Field_1__c;
                        cloneCreditMemo.NETS_Code__c = objCreditMemo.NETS_Code__c;
                        cloneCreditMemo.Payment_Method__c = objCreditMemo.Payment_Method__c;
                        cloneCreditMemo.Comments__c = objCreditMemoWrap.userRemarks;
                        cloneCreditMemo.From_Invoice__c = objCreditMemo.From_Invoice__c;
                        upsert new list<Credit_Memo__c>{ cloneCreditMemo,objCreditMemo};
                            
                        system.debug('cloneCreditMemo --> ' + cloneCreditMemo );
                        system.debug('objCreditMemo --> ' + objCreditMemo );
                        
                        //_____________________________________________________ Adjusting the existing credit memo line items  _______________________________________________
                        for( Credit_memo_line_item__c objExistingCreditMemoLine : objCreditMemo.Credit_memo_line_items__r ){
                            
                            system.debug('isAdjustmentDOne --> ' + isAdjustmentDOne );
                            system.debug('adjustmentAmnt --> ' + adjustmentAmnt );
                            
                            Decimal existingTaxAmount = 0;
                            if( objExistingCreditMemoLine.Tax_Amount__c != Null ){ //as tax amount can be zero
                                existingTaxAmount = objExistingCreditMemoLine.Tax_Amount__c;
                            }
                            system.debug('existingTaxAmount --> ' + existingTaxAmount );
                            
                            //incase the amount is already adjusted ( adjustmentAmnt = 0 ), 
                            //then we will clone the exisitng line item to new credit memo. and later deleting the main line item
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
                                
                            }else{ //if not then we will try to adjust the amount from the line item. adjustmentAmnt > 0
                                
                                //if the adjustmentAmnt is greater, then we will reduce the credit line item amount from the adjustmentAmnt.
                                //				300 >= 100 + 7 
                                if( adjustmentAmnt >= ( objExistingCreditMemoLine.Amount__c + existingTaxAmount )){
                                    
                                    system.debug('adjustmentAmnt --> ' + adjustmentAmnt );
                                    system.debug('amount to be deduct --> ' + (objExistingCreditMemoLine.Amount__c + existingTaxAmount) );
                                    adjustmentAmnt = adjustmentAmnt - (objExistingCreditMemoLine.Amount__c + existingTaxAmount);
                                    system.debug('adjustmentAmnt --> ' + adjustmentAmnt );
                                    
                                }
                                //if the adjustmentAmnt is greater, then we will break that credit memo line item amount as per the remaining adjustmentAmnt and the balnce amount of
                                //credit line item will be used to create the new line item for the new cloned credit memo
                                //adjustmentAmnt = 200, credit memo line item amount = 300 
                                else{
                                    
                                    //incase the adjustmentAmnt = 0 then just clone the credit memo line item
                                    if( adjustmentAmnt == 0 ){
                                        isAdjustmentDOne = true;
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
                                        
                                        //#################################################  Existning Line Item amount Adjustment  #########################################################
                                        //incase the adjustmentAmnt != 0 we will break the amount , ex -> adjustmentAmnt = 200 and credit memo amount = 300 including tax
                                        //then we will update the existing the credit memo line item total amount as 200 and calculate the tax accordinly so that the total amount is 200.
                                        //And create the new line item of total amount 100 and then calculate the tax accoringly so that the total amount is 100. 
                                        
                                        Decimal newCreditLineItemAmount = (objExistingCreditMemoLine.Amount__c + existingTaxAmount); //calculating the new line item amount
                                        system.debug('newCreditLineItemAmount --> ' + newCreditLineItemAmount );
                                        newCreditLineItemAmount = newCreditLineItemAmount - adjustmentAmnt;							//removing the user enter amount ex- 200 - 100 = 100 ( new credit memo line item amount )
                                        
                                        system.debug('newCreditLineItemAmount --> ' + newCreditLineItemAmount );
                                        newCreditLineItemAmount = BillingUtility.roundOffAmount( newCreditLineItemAmount );			//rounding it to two decimal places
                                        system.debug('newCreditLineItemAmount --> ' + newCreditLineItemAmount );
                                        
                                        //now calculating the new tax amount for the exisitng line item aount ex user entered 100, tax = 7%, so the amount = 93 & tax amount = 7
                                        if( objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != Null && objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != 0 ){
                                            
                                            objExistingCreditMemoLine.Tax_Amount__c = (objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c/100)*adjustmentAmnt;
                                            objExistingCreditMemoLine.Tax_Amount__c = BillingUtility.roundOffAmount( objExistingCreditMemoLine.Tax_Amount__c );
                                        }else{
                                            objExistingCreditMemoLine.Tax_Amount__c = 0;
                                        }
                                        system.debug('objExistingCreditMemoLine.Tax_Amount__c --> ' + objExistingCreditMemoLine.Tax_Amount__c );
                                        
                                        objExistingCreditMemoLine.Amount__c = adjustmentAmnt - objExistingCreditMemoLine.Tax_Amount__c;
                                        objExistingCreditMemoLine.Amount__c = BillingUtility.roundOffAmount( objExistingCreditMemoLine.Amount__c );
                                        system.debug('objExistingCreditMemoLine.Amount__c --> ' + objExistingCreditMemoLine.Amount__c );
                                        
                                        listCreditMemoLineItem.add( objExistingCreditMemoLine );
                                        System.debug('listCreditMemoLineItem --> ' + listCreditMemoLineItem );
                                        adjustmentAmnt = 0;
                                        
                                        
                                        //#################################################  Existning Line Item amount Adjustment  #########################################################
                                        Credit_memo_line_item__c newCreditMemoLineItem = new Credit_memo_line_item__c();
                                        
                                        //now calculating the new tax amount for the exisitng line item remaining amount was 100, tax = 7%, so the amount = 93 & tax amount = 7
                                        if( objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != Null && objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != 0 ){
                                            
                                            newCreditMemoLineItem.Tax_Amount__c = (objInvoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c/100)*newCreditLineItemAmount;
                                            newCreditMemoLineItem.Tax_Amount__c = BillingUtility.roundOffAmount( newCreditMemoLineItem.Tax_Amount__c );
                                        }else{
                                            newCreditMemoLineItem.Tax_Amount__c = 0;
                                        }
                                        system.debug('newCreditMemoLineItem.Tax_Amount__c --> ' + newCreditMemoLineItem.Tax_Amount__c );
                                        
                                        newCreditMemoLineItem.Amount__c = newCreditLineItemAmount - newCreditMemoLineItem.Tax_Amount__c;
                                        newCreditMemoLineItem.Amount__c = BillingUtility.roundOffAmount( newCreditMemoLineItem.Amount__c );
                                        system.debug('newCreditMemoLineItem.Amount__c --> ' + newCreditMemoLineItem.Amount__c );    
                                        newCreditMemoLineItem.Credit_Memo_Number__c = cloneCreditMemo.Id;
                                        newCreditMemoLineItem.Enrolment__c = objExistingCreditMemoLine.Enrolment__c;
                                        newCreditMemoLineItem.Month__c = objExistingCreditMemoLine.Month__c;
                                        newCreditMemoLineItem.Package__c = objExistingCreditMemoLine.Package__c;
                                        newCreditMemoLineItem.Is_Deposit__c = objExistingCreditMemoLine.Is_Deposit__c;
                                        newCreditMemoLineItem.Is_Discount__c = objExistingCreditMemoLine.Is_Discount__c; 
                                        newCreditMemoLineItem.Invoice_Line_Item__c = objExistingCreditMemoLine.Invoice_Line_Item__c;
                                        system.debug('newCreditMemoLineItem --> ' + newCreditMemoLineItem );
                                        listCreditMemoLineItem.add( newCreditMemoLineItem );
                                        System.debug('listCreditMemoLineItem --> ' + listCreditMemoLineItem );
                                        System.debug('listCreditMemoLineItem.size() --> ' + listCreditMemoLineItem.size() );
                                        
                                }//end of adjustmentAmnt == 0 else part 
                            }//end of if adjustment amount <= credit memo line item amount
                            
                        }//end of credit memo line item loop
                    }//end of partial refund case
                    
                }//end of successfule payment check
                
                
                if(listCreditMemoLineItem.size() > 0 )
                    upsert listCreditMemoLineItem;
                if(listDeleteCreditMemoLineItem.size() > 0 )
                    delete listDeleteCreditMemoLineItem;
                
                system.debug('listDeleteCreditMemoLineItem --> ' + listDeleteCreditMemoLineItem );
                system.debug('listCreditMemoLineItem --> ' + listCreditMemoLineItem );
                
            }
        }
            Catch( Exception objExcp ){
                if( objSavePoint != Null ){
                    Database.rollback(objSavePoint);
                }
                
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