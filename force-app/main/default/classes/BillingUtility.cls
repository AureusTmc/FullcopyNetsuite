public class BillingUtility{
    /*public static string apikey;
    public static string baseUrl;
    public static Decimal taxRate;
    public static Map<String,Country__c> countryMap;
    */
    /*static{
        List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
        if(stripeSettings.size()>0){
            baseUrl = stripeSettings[0].Stripe_Base_Url__c;
            apiKey = stripeSettings[0].Stripe_Secret_Key__c;
        }
    }*/
    
    // @ 03/09/2019, change regarding country code.
    /*static{
        if(countryMap  == NULL){
        
            countryMap = new Map<String,Country__c>([SELECT Id, Tax_Rate__c, Stripe_Secret_Key__c, Stripe_Publishable_Key__c, Stripe_Base_Url__c, 
                                            Currency_Code__c, Country_Name__c, Name FROM Country__c WHERE Stripe_Secret_Key__c!= NULL AND 
                                            Stripe_Base_Url__c != NULL]);
        }
    }
    */
    
/* public static Boolean initConnection(String countryId){
        if(countryMap.containsKey(countryId)){
            Country__c country = countryMap.get(countryId);
            apikey = country.Stripe_Secret_Key__c;
            baseUrl = country.Stripe_Base_Url__c;
            taxRate = country.Tax_Rate__c;
        }
        
        return String.isNotBlank(apikey) && String.isNotBlank(baseUrl); 
    }
    */
// Jatin : get enrolment ids according to related invoiceIds
public static set<string> getInvoiceLineItemEnrollmentIds(Set<string> invoiceIds){
    Set<String> enrolmentIds = new Set<string>();
    if(invoiceIds != NULL && invoiceIds.size() > 0 ){
        For(invoice_Line_Item__c invoicelineItemObj : [SELECT Id,Enrolment__c 
                                                        FROM Invoice_Line_Item__c
                                                        WHERE Invoice__c IN: invoiceIds]){
                                                            enrolmentIds.add(invoicelineItemObj.Enrolment__c);
                                                        }
    }
    return enrolmentIds;
}    
    public static Map<String,Country__c> getCountryMap(String cntryId){
        if(String.isNotBlank(cntryId)){
            return new Map<String,Country__c>([SELECT Id, Name, Tax_Rate__c, Stripe_Secret_Key__c, Stripe_Publishable_Key__c, Stripe_Base_Url__c, 
                                                    Currency_Code__c, Country_Name__c, Student_Policies_Template_Id__c, Folder__c 
                                            FROM Country__c 
                                            WHERE Id=:cntryId AND Stripe_Secret_Key__c!= NULL AND Stripe_Base_Url__c != NULL AND Tax_Rate__c != null]);
        }else{
            return new Map<String,Country__c>([SELECT Id, Name, Tax_Rate__c, Stripe_Secret_Key__c, Stripe_Publishable_Key__c, Stripe_Base_Url__c, 
                                                    Currency_Code__c, Country_Name__c, Student_Policies_Template_Id__c, Folder__c 
                                            FROM Country__c 
                                            WHERE Stripe_Secret_Key__c!= NULL AND Stripe_Base_Url__c != NULL AND Tax_Rate__c != null]);
        }                                       
    }
    
    //method is used in creating invoice for subscription
    public static Set<string> createInvoiceFromSubscription(List<Subscription__c> subscriptions, String invId,Date invDate){
        List<Invoice__c> invList = new List<Invoice__c>();
       //system.debug('@@@subscriptions'+subscriptions.size());
       //system.debug('@@invId'+invId);
       //system.debug('@@invDate'+invDate);
        Set<string> invIds = new Set<string>();
        Set<String> parentIds = new Set<String>();
        List<Invoice_Line_Item__c> invLineItmList = new List<Invoice_Line_Item__c>();
        Map<Subscription__c , Invoice__c> mapOfSubInvoice = new Map<Subscription__c, Invoice__c>();
        List<PackageProcessHandler> listOfPackageToProcess = new List<PackageProcessHandler>();
        
        Date currentDate = invDate;
        Date firstDate = Date.newInstance(currentDate.year(), currentDate.month(), 01);
        Integer daysInMonth = Date.daysInMonth(currentDate.year(), currentDate.month());
        Date lastDate = Date.newInstance(currentDate.year(), currentDate.month(), daysInMonth);
        Map<String,List<Date>> mapOfDates = getDateMap(firstDate,lastDate);
            
       //system.debug('@@mapOfSubInvoice'+subscriptions);
       //system.debug('@@mapOfDates'+mapOfDates);
        for(Subscription__c sub:subscriptions){
           //system.debug('@@sub'+sub.Subscription_Line_Items__r.size());
            if(sub.Subscription_Line_Items__r.size() > 0){
                Invoice__c inv = fillInvoice(sub.Id,sub.Parent__c,constantsClass.dueStatus);   //new Invoice__c();
                inv.Center__c = sub.Center__c;
                inv.Invoice_Date__c = invDate;
               //system.debug('@@sub'+sub);
                inv.Due_Date__c = invDate.addDays(Integer.valueOf(Label.Invoice_Due_Day));
                inv.invoice_type__c = 'Recurring';
                mapOfSubInvoice.put(sub, inv);   
                // fill parentIds set, used in subsequent process i.e. adjustDeposit
                if(String.isNotBlank(sub.Parent__c)){
                    parentIds.add(sub.Parent__c);    
                }
                
            }
        }
       //system.debug('@@mapOfSubInvoice'+mapOfSubInvoice);
        if(mapOfSubInvoice.size() > 0){
            INSERT mapOfSubInvoice.values();
           //system.debug('@@mapOfSubInvoice'+mapOfSubInvoice);
            for(Subscription__c objSub : mapOfSubInvoice.keySet()){
                invIds.add(mapOfSubInvoice.get(objSub).Id);
                listOfPackageToProcess.add(new PackageProcessHandler(mapOfSubInvoice.get(objSub),objSub.Subscription_Line_Items__r,firstDate,lastDate));        
            }
            
            for(PackageProcessHandler objProcessHandler : listOfPackageToProcess ){
                for(PackageProcessInterface objProcess : objProcessHandler.listOfPackageProcess){
                    invLineItmList.addAll(objProcess.createInvoiceLineItem(objProcessHandler.objInvoice,mapOfDates ));
                }
            }
            
            if(invLineItmList.size()>0){
                for(Invoice_Line_Item__c incItm: invLineItmList){
                    if(String.isNotBlank(invId)){
                        incItm.Invoice__c = invId;
                    }
                    incItm.Month__c = invDate;
                }
                INSERT invLineItmList;
            }
           //system.debug('@@@invLineItmList'+invLineItmList);
            List<Invoice__c> invoices = new List<Invoice__c>();
            Map<String, Date> mapOfParentEnrolmentLastDate = new Map<String, Date>();
            //@Jatin on 21st Nov 2019 commented due to refund record not created
            //Map<String, Set<String>> mapOfParentEnrolments = new Map<String, Set<String>>();
            for(Invoice__c invoiceObj : [SELECT Id, Name,Parent_Account__c,Total_Amount__c, Remarks__c,Invoice_Date__c,Parent_Account__r.Centre_Name__c,
                                            Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c,
                                             (SELECT Id, Enrolment__r.id,Enrolment__r.Package_Process_Type__c ,
                                                Enrolment__r.Effective_Date__c ,Package__c
                                                FROM Invoice_Line_Items__r) 
                                            FROM Invoice__c 
                                        WHERE Id IN : invIds]){
                invoices.add(invoiceObj);
                for(Invoice_Line_Item__c  lineItemObj : invoiceObj.Invoice_Line_Items__r){
                    if(mapOfParentEnrolmentLastDate.containsKey(invoiceObj.Parent_Account__c) && 
                        mapOfParentEnrolmentLastDate.get(invoiceObj.Parent_Account__c) < lineItemObj.Enrolment__r.Effective_Date__c){
                        mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                    }else if(String.isNotBlank(lineItemObj.Enrolment__c) && lineItemObj.Enrolment__r.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType && lineItemObj.Enrolment__r.Effective_Date__c != NULL){
                        mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                    }
                }
            }
           //system.debug('@@@mapOfParentEnrolmentLastDate'+mapOfParentEnrolmentLastDate);
           //system.debug('@@@mapOfParentEnrolmentLastDate'+mapOfSubInvoice.keySet());
           //system.debug('@@@mapOfParentEnrolmentLastDate'+mapOfSubInvoice.values());
           //system.debug('@@@mapOfParentEnrolmentLastDate'+invIds);
           //system.debug('@@@mapOfParentEnrolmentLastDate'+invDate);
           //system.debug('@@@mapOfParentEnrolmentLastDate'+mapOfParentEnrolmentLastDate);
            

            updateSubscriptionNextDate(mapOfSubInvoice.keySet());
            adjustDiscounts(mapOfSubInvoice.values(),invIds,invDate);
            //adjustDeposit(invoices, invIds, parentIds, firstDate, lastDate, mapOfParentEnrolmentLastDate); //commented by nishi: 16-Sep-2020 : for new requirement we adjust pending credit memo not payment
            adjustCreditMemoDeposit(invoices, invIds, parentIds, firstDate, lastDate, mapOfParentEnrolmentLastDate);
        }
        return invIds;
    }
    
    //@ 22-05-2019 this method is used for adjusting credit notes on the parent.
    private static void adjustDiscounts(List<Invoice__c> listOfInv,Set<String> setOfInvIds,Date invDate){
        Map<String,Invoice__c> mapOfParentInv = new Map<String,Invoice__c>();
        Map<String,Customer_Adhoc_Discount__c> customerDiscountsMap = new Map<String,Customer_Adhoc_Discount__c>();
        List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
        List<Customer_Adhoc_Discount__c> listOfDiscounts = new List<Customer_Adhoc_Discount__c>();
        //@Jatin on 20th Nov 2019 to apply tax on discount...
        Map<String, Account> mapOfParent = new Map<String, Account>();
        for(Invoice__c objInv : [SELECT Id,Parent_Account__c, Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c, 
                                Total_Amount__c,Parent_Account__r.Centre_Name__r.Organisation__r.Tax_Rate__c
                                FROM Invoice__c WHERE Id IN : setOfInvIds]){
            mapOfParentInv.put(objInv.parent_Account__c, objInv);
            mapOfParent.put(objInv.parent_Account__c, objInv.parent_Account__r);
        }
        // filling map of 1 pending discont for each parent if it has any.
        for(Customer_Adhoc_Discount__c discount : [SELECT Id,Discount_Amount__c,Parent__c,Status__c,Reason__c,Remark__c 
                                                FROM Customer_Adhoc_Discount__c 
                                                WHERE Parent__c IN :mapOfParentInv.keySet() AND
                                                Status__c =: constantsClass.paymentPendingStatus 
                                                AND Discount_Amount__c != NULL 
                                                AND Discount_Date__c <=: invDate
                                                order by Discount_Amount__c Desc]){
        
            if(!customerDiscountsMap.containsKey(discount.Parent__c)){
                customerDiscountsMap.put(discount.Parent__c,discount);
            }
        }
        // Adjusting discount
        for(String parentId : customerDiscountsMap.keySet()){
            Customer_Adhoc_Discount__c discount = customerDiscountsMap.get(parentId);
            if(mapOfParentInv.containsKey(parentId) && mapOfParentInv.get(parentId).Total_Amount__c >= discount.Discount_Amount__c){
                String invId = mapOfParentInv.get(parentId).Id;
                String remarks='';
                if(String.isNotBlank(discount.Reason__c)){
                    if(discount.Reason__c == 'Admin Error'){
                        remarks = 'Referral';    
                    }else if(discount.Reason__c == 'Others'){
                        remarks = discount.Remark__c;  
                    }else{
                        remarks = discount.Reason__c;
                    }
                }

                //@Jatin on 20th Nov 2019 to apply tax on discount invoice line item...
                Decimal taxAmount  = 0;
                if(mapOfParent.containsKey(parentId) && String.isNotBlank(mapOfParent.get(parentId).Centre_Name__r.Country__c) && 
                    mapOfParent.get(parentId).Centre_Name__r.Country__r.Tax_Rate__c != NULL && 
                    mapOfParent.get(parentId).Centre_Name__r.Country__r.Tax_Rate__c > 0){
                        taxAmount = (roundOffAmount((-1*discount.Discount_Amount__c)) * mapOfParent.get(parentId).Centre_Name__r.Country__r.Tax_Rate__c) / 100;
                }
               
                Invoice_Line_Item__c discountItem = fillInvLnItm(invId,null,null, roundOffAmount(-1*discount.Discount_Amount__c), remarks,'');
                discountItem.Month__c = invDate;
                
                //@Jatin on 20th Nov 2019 to apply tax on discount invoice line item...
                discountItem.GST_Amount__c = roundOffAmount(taxAmount);

                listOfLineItems.add(discountItem);
                discount.Status__c = ConstantsClass.paymentSuccessStatus;
                discount.invoice__c = invId;
                listOfDiscounts.add(discount); 
            }
        }
        
        if(listOfLineItems.size() > 0){
            INSERT listOfLineItems;
        }
        if(listOfDiscounts.size() > 0){
            UPDATE listOfDiscounts;
        }
        /* Map<String,Invoice__c> mapOfParentInv = new Map<String,Invoice__c>();
        Map<String,Payment__c> mapOfPayment = new Map<String,Payment__c>();
        List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
        List<Payment__c> listOfPayments = new List<Payment__c>();
        for(Invoice__c objInv : [SELECT Id,Parent_Account__c,Total_Amount__c FROM Invoice__c WHERE Id IN : setOfInvIds]){
            mapOfParentInv.put(objInv.parent_Account__c, objInv);
        }
        
        //System.debug('mapOfParentInv ==>'+mapOfParentInv);
        for(Payment__c objPay : [SELECT Id,Payment_Amount__c,Parent_Account__c FROM Payment__c WHERE Parent_Account__c IN :mapOfParentInv.keySet() AND
                                RecordType.Name =: ConstantsClass.creditNoteRecType AND Payment_Status__c =: constantsClass.paymentPendingStatus 
                                order by Payment_Amount__c Desc]){
        
            if(!mapOfPayment.containsKey(objPay.Parent_Account__c)){
                mapOfPayment.put(objPay.Parent_Account__c,objPay);
            }
        }
        
        //System.debug('mapOfPayment==>'+mapOfPayment);
        for(String parentId : mapOfPayment.keySet()){
            Payment__c objPay = mapOfPayment.get(parentId);
            if(mapOfParentInv.containsKey(parentId) && mapOfParentInv.get(parentId).Total_Amount__c >= objPay.payment_Amount__c){
                String invId = mapOfParentInv.get(parentId).Id;
                listOfLineItems.add(fillInvLnItm(invId,null,null, -1*objPay.payment_Amount__c, 'Credit Note',''));
                objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                objPay.invoice__c = invId;
                listOfPayments.add(objPay); 
            }
        }
        
        if(listOfLineItems.size() > 0){
            INSERT listOfLineItems;
        }
        if(listOfPayments.size() > 0){
            UPDATE listOfPayments;
        }*/
        
    }
     //@Nishi on 16-Sep:2020 Due to refund record not created for Deposit Adjust.
    // adjust deposit in invoice
  /*pplying a credit memo to the next invoice [Invoice generation process & Next month invoice]
        a.	Comment the previous handling of payments with the status =’Pending’ 
        b.	Check if there is any pending credit memo available with the customer account.
        c.	If yes, then if the credit memo amount <= invoice amount then
                i.	Credit Memo: Update the Invoice number field of the pending credit memo
                ii.	Credit Memo: Status = success
                iii.	Credit Memo: Invoice number = to invoice number
                iv.	Invoice: Update the Prev Adjustment field with the amount
        d.	if the credit memo amount >  invoice amount then
        .	break the original credit memo to two credit memos - One equivalent to the invoice amount and other the balance with the status pending
                i.	Credit Memo: Update the Invoice number field of the pending credit memo (equivalent to the invoice amount)
                ii.	Credit Memo: Status = success
                iii.	Credit Memo: Invoice number = to invoice number
                iv.	Invoice: Update the Prev Adjustment field with the amount
                v.	Balance credit memo will be utilized in the subsequent invoice  
    */

    private static void adjustCreditMemoDeposit(List<Invoice__c> listOfInv, Set<String> setOfInvIds,Set<String> setOfParentIds,
                                        Date firstDate,Date lastDate, Map<String, Date> mapOfParentEnrolmentLastDate){
    
        List<Invoice__c> invListToUpdate = new List<Invoice__c>();
        Map<String, Credit_Memo__c> mapOfCreditMemos = new Map<String, Credit_Memo__c>();
        
        Map<String, Boolean> mapOfActiveParent = new Map<String, Boolean>();
        mapOfActiveParent = checkParentHasMultipleEnrolments(setOfParentIds, lastDate);

        List<Credit_Memo__c> newPendingCreditMemos = new List<Credit_Memo__c>();

        Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo = getParentCreditMemo(setOfParentIds,lastDate);
        Map<String,Decimal> parentCreditMemoTotal = getParentCreditMemoMap(mapOfParentCreditMemo);
        
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        String depositRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        Credit_Memo__c newCreditMemo = new Credit_Memo__c();
        Map<String,List<Credit_memo_line_item__c>> creditNoteAmountAdjustment = new Map<String,List<Credit_memo_line_item__c>>(); 
        map<string,String> mapofAdjustmentCreditNoteAmount = new  map<string,String>();
        List<Credit_memo_line_item__c> listOfDeletedCreditmemolineitem  = new  List<Credit_memo_line_item__c>();
        List<Credit_memo_line_item__c> listOfUpdatedCreditmemolineitem  = new  List<Credit_memo_line_item__c>();
       //system.debug('listOfInv'+listOfInv);                                 
        for(Invoice__c invoice : listOfInv){

            newCreditMemo = new Credit_Memo__c();
            Decimal totalCreditMemoLineItemAmount =0;
            Boolean finding = TRUE;
            Decimal invoiceTotalAmount = invoice.Total_Amount__c;
            Decimal accumulatedCreditMemoAmount = (parentCreditMemoTotal.containsKey(invoice.parent_account__c)) ? parentCreditMemoTotal.get(invoice.parent_account__c) : 0;
            Decimal adjustedAmount = 0;
            Decimal adjustedPaymentAmount = 0;
            // SELECT From_Invoice__c, Field_1__c, Parent_Account__c, Organisations_Name__c, Comments__c, Currency_Code__c, Total_Amount__c, Payment_Method__c, Invoice_Number__c, 
            // Credit_Memo_Date__c, Status__c, Refund_ID__c, Stripe_Payout_Id__c, 
            // Stripe_Fee__c, Cheque_Date__c, Cheque_No__c, Bank_Name__c, NETS_Code__c, Amount_Exl_tax_Rollup__c, Tax_Amount_Rollup__c, Center__c, Netsuite_Payment_Method__c, Id,
            //  Name FROM Credit_Memo__c
           // String chargeId = (mapOfParentCreditMemo.containskey(invoice.parent_account__c)) ? mapOfParentCreditMemo.get(invoice.parent_account__c)[0].Transaction_ID__c : '';
            if(String.isNotBlank(invoice.Parent_Account__c) && mapOfParentCreditMemo.containsKey(invoice.parent_account__c)){
               
                for(Credit_Memo__c objCreditMemo : mapOfParentCreditMemo.get(invoice.parent_account__c)){
                
                    if(!mapOfCreditMemos.containsKey(objCreditMemo.Id)){
                           //system.debug('invoiceTotalAmount'+invoiceTotalAmount);
                           //system.debug('accumulatedCreditMemoAmount'+accumulatedCreditMemoAmount);
                            if(accumulatedCreditMemoAmount <= invoiceTotalAmount){ // accumulatedCreditMemoAmount(500) <= invoiceTotalAmount(1000)
                               //run if the credit memo amount <= invoice amount then
                                objCreditMemo.Status__c = ConstantsClass.creditMemoSuccessStatus;
                                objCreditMemo.From_Invoice__c = invoice.Id;
                                objCreditMemo.Comments__c = 'Adjusted against '+invoice.Name;
                                objCreditMemo.Credit_Memo_Date__c = invoice.Invoice_Date__c; 
                                mapOfCreditMemos.put(objCreditMemo.Id, objCreditMemo);
                                invoice.Credit_Memo_Amount__c = invoiceTotalAmount;
                                if(accumulatedCreditMemoAmount == invoiceTotalAmount){
                                    invoice.status__c = 'Paid';
                                }
                            }else if(accumulatedCreditMemoAmount > invoiceTotalAmount){
                              //	if the credit memo amount >  invoice amount then break the original credit memo to two credit memos -
                              // One equivalent to the invoice amount and other the balance with the status pending
                                
                                if(finding){
                                    // @@jatin 11-jan-2020 : for manage invoice and payment per amount  
                                    if(objCreditMemo.Total_Amount__c  > invoiceTotalAmount ){
                                        adjustedPaymentAmount =  adjustedPaymentAmount + objCreditMemo.Total_Amount__c; 
                                    }else if(objCreditMemo.Total_Amount__c == invoiceTotalAmount){
                                        adjustedPaymentAmount = adjustedPaymentAmount + invoiceTotalAmount; 
                                    }else if(objCreditMemo.Total_Amount__c < invoiceTotalAmount  ){
                                        adjustedPaymentAmount = adjustedPaymentAmount + objCreditMemo.Total_Amount__c; //2000 = 1000+1000
                                    }
                                    // if invoice Total Amount is greater then  Adjust payment then we remove extra amount and 
                                    // create new payment recoard  
                                    if(invoiceTotalAmount < adjustedPaymentAmount){
                                        Decimal remainingAmount = adjustedPaymentAmount - invoiceTotalAmount; 
                                        adjustedPaymentAmount = adjustedPaymentAmount - remainingAmount;
                                       // objCreditMemo.Total_Amount__c = objCreditMemo.Total_Amount__c - remainingAmount; 
                                       Double adjustmentCreditMemoLineItemAmount = objCreditMemo.Total_Amount__c - remainingAmount; 
                                        if(objCreditMemo.Credit_memo_line_items__r != null && objCreditMemo.Credit_memo_line_items__r.size() > 0){
                                            //One equivalent to the invoice amount and other the balance with the status pending
                                           
                                            for(Credit_memo_line_item__c objCreditmemolineitem : objCreditMemo.Credit_memo_line_items__r){
                                               //system.debug('objCreditmemolineitem'+objCreditmemolineitem);
                                                decimal totalCreditMemoLineItemAmountWithoutTax=objCreditmemolineitem.Amount__c;
                                                decimal totalCreditMemoLineItemTax=objCreditmemolineitem.Tax_Amount__c; 
                                               //system.debug('totalCreditMemoLineItemAmountWithoutTax'+totalCreditMemoLineItemAmountWithoutTax);
                                               //system.debug('totalCreditMemoLineItemTax'+totalCreditMemoLineItemTax);
                                                totalCreditMemoLineItemAmount =  objCreditmemolineitem.Amount__c+objCreditmemolineitem.Tax_Amount__c; 
                                               //system.debug('adjustmentCreditMemoLineItemAmount'+adjustmentCreditMemoLineItemAmount);
                                                if(adjustmentCreditMemoLineItemAmount <= 0.00){
                                                    List<Credit_memo_line_item__c> listOfCreditmemolineitem  = new  List<Credit_memo_line_item__c>();
                                                   //system.debug('creditNoteAmountAdjustment'+creditNoteAmountAdjustment);
                                                    if(creditNoteAmountAdjustment.containsKey(invoice.id)){
                                                        listOfCreditmemolineitem =    creditNoteAmountAdjustment.get(invoice.id);
                                                    } 
                                                    string remarks = 'Total Deposit '+String.valueOf(accumulatedCreditMemoAmount)+' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount) + ' and balance '+adjustedAmount+' become pending deposit.';
                            
                                                   listOfCreditmemolineitem.add(
                                                         createCreditMemoLineRec(objCreditmemolineitem.Amount__c,objCreditmemolineitem.Tax_Amount__c,invoice.Invoice_Line_Items__r[0].Package__c,
                                                        invoice.Invoice_Line_Items__r[0].Enrolment__r.id,invoice.Invoice_Line_Items__r[0].Id,remarks));
                                                   //system.debug('objCreditmemolineitem'+objCreditmemolineitem);
                                                    creditNoteAmountAdjustment.put(invoice.id,listOfCreditmemolineitem);
                                                    listOfDeletedCreditmemolineitem.add(objCreditmemolineitem);
                                                   //system.debug('creditNoteAmountAdjustment'+creditNoteAmountAdjustment);
                                                }else{
                                                    if(totalCreditMemoLineItemAmount > adjustmentCreditMemoLineItemAmount){
                                                        Decimal taxAmount = 0;
                                                        if(invoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != null && invoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c != 0){
                                                            taxAmount =(invoice.Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c/100)*adjustmentCreditMemoLineItemAmount; 
                                                        }
                                                       //system.debug('taxAmount'+taxAmount);
                                                        objCreditmemolineitem.Amount__c =adjustmentCreditMemoLineItemAmount - BillingUtility.roundOffAmount( taxAmount); 
                                                        objCreditmemolineitem.Tax_Amount__c = BillingUtility.roundOffAmount( taxAmount);
                                                        listOfUpdatedCreditmemolineitem.add(objCreditmemolineitem);
                                                        adjustmentCreditMemoLineItemAmount = adjustmentCreditMemoLineItemAmount - totalCreditMemoLineItemAmount ;
                                                       //system.debug('totalCreditMemoLineItemAmount'+totalCreditMemoLineItemAmount);
                                                       //system.debug('adjustmentCreditMemoLineItemAmount'+adjustmentCreditMemoLineItemAmount);
                                                        Decimal creditMemoTotalAmount = 0;
                                                        Decimal creditMemoTotaltaxAmount = 0;
                                                       //system.debug('mapofAdjustmentCreditNoteAmount'+mapofAdjustmentCreditNoteAmount);
                                                        if(mapofAdjustmentCreditNoteAmount.containsKey(invoice.id)){
                                                            creditMemoTotalAmount = Decimal.valueOf(mapofAdjustmentCreditNoteAmount.get(invoice.id).split('@')[0]);
                                                            creditMemoTotaltaxAmount =Decimal.valueOf(mapofAdjustmentCreditNoteAmount.get(invoice.id).split('@')[1]);
                                                        }
                                                       //system.debug('objCreditmemolineitem.Amount__c'+objCreditmemolineitem.Amount__c);
                                                       //system.debug('objCreditmemolineitem.Tax_Amount__c'+objCreditmemolineitem.Tax_Amount__c);
                                                        creditMemoTotalAmount += (totalCreditMemoLineItemAmountWithoutTax - objCreditmemolineitem.Amount__c);
                                                        creditMemoTotaltaxAmount += (totalCreditMemoLineItemTax - objCreditmemolineitem.Tax_Amount__c);
                                                       //system.debug('creditMemoTotaltaxAmount'+creditMemoTotaltaxAmount);
                                                       //system.debug('creditMemoTotaltaxAmount'+creditMemoTotaltaxAmount);
                                                        mapofAdjustmentCreditNoteAmount.put(invoice.id,creditMemoTotalAmount+'@'+creditMemoTotaltaxAmount);
                                                    }else if(totalCreditMemoLineItemAmount <= adjustmentCreditMemoLineItemAmount){
                                                       //system.debug('totalCreditMemoLineItemAmount'+totalCreditMemoLineItemAmount);
                                                       //system.debug('adjustmentCreditMemoLineItemAmount'+adjustmentCreditMemoLineItemAmount);
                                                        adjustmentCreditMemoLineItemAmount = adjustmentCreditMemoLineItemAmount - totalCreditMemoLineItemAmount ; 
                                                       //system.debug('adjustmentCreditMemoLineItemAmount'+adjustmentCreditMemoLineItemAmount);
                                                    }
                                                }
                                            }
                                        }
                                    } 
                                    
                                    objCreditMemo.Status__c = ConstantsClass.creditMemoSuccessStatus;
                                    objCreditMemo.From_Invoice__c = invoice.Id;
                                    objCreditMemo.Credit_Memo_Date__c = invoice.Invoice_Date__c; 
                                    objCreditMemo.Comments__c = 'Total Deposit '+ String.valueOf(accumulatedCreditMemoAmount) +' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount)+' and balance '+String.valueOf(accumulatedCreditMemoAmount - invoiceTotalAmount)+' refunded';
                                    mapOfCreditMemos.put(objCreditMemo.Id, objCreditMemo);
                                    invoice.Credit_Memo_Amount__c = invoiceTotalAmount;
                                    invoice.status__c = 'Paid';
                                     // Run if the Adjust payment is equals to total invoice Amount
                                    if(adjustedPaymentAmount ==  invoiceTotalAmount){ // 100 ==100
                                        adjustedAmount = accumulatedCreditMemoAmount - invoiceTotalAmount; // 400 = 500 - 100
                                        finding = FALSE;
                                    }
                                }else{
                                   //system.debug('adjustedAmount else'+adjustedAmount);
                                   //system.debug('objCreditMemo.Total_Amount__c else'+objCreditMemo.Total_Amount__c);
                                    // parent is not active then we worked this part
                                    // if Creditmemo record is exist and adjusted Payment Amount is equal to payment amount 
                                    // then we not creating new record
                                    if(mapOfActiveParent.containsKey(invoice.parent_account__c)
                                    && mapOfActiveParent.get(invoice.parent_account__c)){
                                        // if(adjustedAmount >= objCreditMemo.Total_Amount__c ){ //400 >= 400 
                                        //     adjustedAmount = adjustedAmount - objCreditMemo.Total_Amount__c; //400  = 400-400
                                        // }
                                    }else{
                                        objCreditMemo.Comments__c = 'Adjusted against '+invoice.Name+', Change Amount from '+objCreditMemo.Total_Amount__c+' to 0.';
                                        objCreditMemo.Credit_Memo_Date__c = invoice.Invoice_Date__c; 
                                        objCreditMemo.Status__c = ConstantsClass.creditMemoPendingStatus;
                                        mapOfCreditMemos.put(objCreditMemo.Id, objCreditMemo);
                                    }
                                }

                            }
                            
                    }

                }
               //system.debug('adjustedAmount'+adjustedAmount);
                if(adjustedAmount > 0){
                    string remarks='';
                    if(mapOfActiveParent.containsKey(invoice.parent_account__c)
                         && mapOfActiveParent.get(invoice.parent_account__c)){
                             //creditNoteAmountAdjustment.put(invoice.id,mapOfCreditMemosAmount);
                             //mapofAdjustmentCreditNoteAmount.put(objCreditMemo.id,creditMemoTotalAmount+'-'+creditMemoTotaltaxAmount);
                        // if credit Memo total is greater then invoice total then we check this adjusted payment record type  and 
                        // create new payment according to previous adjusted credit Memo object 
                            remarks = 'Total Deposit '+String.valueOf(accumulatedCreditMemoAmount)+' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount) + ' and balance '+adjustedAmount+' become pending deposit.';
                            if(creditNoteAmountAdjustment.containsKey(invoice.id)){
                                newCreditMemo = createCreditMemoRec(invoice,System.today(),remarks);
                            }else {
                                if(mapofAdjustmentCreditNoteAmount.containsKey(invoice.id)){
                                    newCreditMemo = createCreditMemoRec(invoice,System.today(),remarks);
                                }
                            }
                           
                            if(mapofAdjustmentCreditNoteAmount.containsKey(invoice.id)){
                               //system.debug('mapofAdjustmentCreditNoteAmount.get(invoice.id)'+mapofAdjustmentCreditNoteAmount.get(invoice.id));
                                Decimal creditMemoTotalAmount = Double.valueOf(mapofAdjustmentCreditNoteAmount.get(invoice.id).split('@')[0]);
                                Decimal creditMemoTotaltaxAmount =Double.valueOf(mapofAdjustmentCreditNoteAmount.get(invoice.id).split('@')[1]);
                               //system.debug('creditMemoTotalAmount'+creditMemoTotalAmount);
                               //system.debug('creditMemoTotalAmount'+creditMemoTotalAmount);
                                List<Credit_memo_line_item__c> listOfCreditmemolineitem  = new  List<Credit_memo_line_item__c>();
                                                    if(creditNoteAmountAdjustment.containsKey(invoice.id)){
                                                        listOfCreditmemolineitem =    creditNoteAmountAdjustment.get(invoice.id);
                                                    } 
                                listOfCreditmemolineitem.add( createCreditMemoLineRec(creditMemoTotalAmount,creditMemoTotaltaxAmount,invoice.Invoice_Line_Items__r[0].Package__c,
                                                        invoice.Invoice_Line_Items__r[0].Enrolment__r.id,invoice.Invoice_Line_Items__r[0].Id,remarks));
                                creditNoteAmountAdjustment.put(invoice.id,listOfCreditmemolineitem);
                            }
                    }else{
                        remarks = 'Total Deposit '+String.valueOf(accumulatedCreditMemoAmount)+' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount) + ' and balance '+adjustedAmount+' refunded.';
                        if(creditNoteAmountAdjustment.containsKey(invoice.id)){
                            newCreditMemo = createCreditMemoRec(invoice, mapOfParentEnrolmentLastDate.get(invoice.parent_account__c),remarks);
                        }else {
                            if(mapofAdjustmentCreditNoteAmount.containsKey(invoice.id)){
                                newCreditMemo = createCreditMemoRec(invoice, mapOfParentEnrolmentLastDate.get(invoice.parent_account__c),remarks);
                            }
                        }
                       
                        if(mapofAdjustmentCreditNoteAmount.containsKey(invoice.id)){
                            Decimal creditMemoTotalAmount = Decimal.valueOf(mapofAdjustmentCreditNoteAmount.get(invoice.id).split('-')[0]);
                            Decimal creditMemoTotaltaxAmount =Decimal.valueOf(mapofAdjustmentCreditNoteAmount.get(invoice.id).split('-')[1]);
                           //system.debug('creditMemoTotalAmount'+creditMemoTotalAmount);
                           //system.debug('creditMemoTotalAmount'+creditMemoTotalAmount);
                            List<Credit_memo_line_item__c> listOfCreditmemolineitem  = new  List<Credit_memo_line_item__c>();
                                                if(creditNoteAmountAdjustment.containsKey(invoice.id)){
                                                    listOfCreditmemolineitem =    creditNoteAmountAdjustment.get(invoice.id);
                                                } 
                            listOfCreditmemolineitem.add( createCreditMemoLineRec(creditMemoTotalAmount,creditMemoTotaltaxAmount,invoice.Invoice_Line_Items__r[0].Package__c,
                                                    invoice.Invoice_Line_Items__r[0].Enrolment__r.id,invoice.Invoice_Line_Items__r[0].Id,remarks));
                            creditNoteAmountAdjustment.put(invoice.id,listOfCreditmemolineitem);
                        }
                    }
                   //system.debug('newCreditMemo'+newCreditMemo);
                    newPendingCreditMemos.add(newCreditMemo);
                }
                invListToUpdate.add(invoice);
            }
        }

        
        
        if(newPendingCreditMemos.size() > 0){
            Insert newPendingCreditMemos;  
           //system.debug('newPendingCreditMemos'+newPendingCreditMemos);
           //system.debug('creditNoteAmountAdjustment'+creditNoteAmountAdjustment);
            List<Credit_memo_line_item__c> listOfNewCreditmemolineitem = new List<Credit_memo_line_item__c>();  
            
            for(Credit_Memo__c objCreditMemo : newPendingCreditMemos){
               //system.debug('creditNoteAmountAdjustment'+creditNoteAmountAdjustment);
               //system.debug('objCreditMemo.Invoice_Number__c'+objCreditMemo.Invoice_Number__c);
                if(creditNoteAmountAdjustment != null && creditNoteAmountAdjustment.size() > 0){
                    
                    if(creditNoteAmountAdjustment.containsKey(objCreditMemo.Invoice_Number__c)){
                        List<Credit_memo_line_item__c> listOfCreditmemolineitem  = creditNoteAmountAdjustment.get(objCreditMemo.Invoice_Number__c);
                        for(Credit_memo_line_item__c objCreditLineItem: listOfCreditmemolineitem){
                            objCreditLineItem.Credit_Memo_Number__c = objCreditMemo.id;
                            listOfNewCreditmemolineitem.add(objCreditLineItem);
                        }
                    }
                }
            } 
            if(listOfNewCreditmemolineitem != null && listOfNewCreditmemolineitem.size() > 0){
                upsert listOfNewCreditmemolineitem;
            }
            //system.debug('listOfNewCreditmemolineitem'+listOfNewCreditmemolineitem);                                   
        }
       //system.debug('mapOfCreditMemos'+mapOfCreditMemos);
        if(listOfDeletedCreditmemolineitem != null && listOfDeletedCreditmemolineitem.size() > 0){
            Delete listOfDeletedCreditmemolineitem;
        }
       //system.debug('listOfUpdatedCreditmemolineitem'+listOfUpdatedCreditmemolineitem);
        if(listOfUpdatedCreditmemolineitem != null && listOfUpdatedCreditmemolineitem.size() > 0){
            update listOfUpdatedCreditmemolineitem;
        }
        if(mapOfCreditMemos.size() > 0){
            update mapOfCreditMemos.values();
        }
       //system.debug('invListToUpdate'+invListToUpdate);
        if(invListToUpdate.size() > 0){
            UPDATE invListToUpdate;     
            //system.debug('invListToUpdate'+invListToUpdate);                                   
        }
                                  
    }

    // create credit memo  records
    public static Credit_Memo__c createCreditMemoRec(Invoice__c objInvoice,date creditMemoDate,string remarks) {
        Credit_Memo__c objCreditMemo = new Credit_Memo__c();
        objCreditMemo.Parent_Account__c = objInvoice.parent_account__c;
        objCreditMemo.Center__c = objInvoice.Parent_Account__r.Centre_Name__c;
        objCreditMemo.Invoice_Number__c = objInvoice.id;
        objCreditMemo.Credit_Memo_Date__c = creditMemoDate;
        objCreditMemo.Status__c = ConstantsClass.creditMemoPendingStatus;
        objCreditMemo.Comments__c = remarks;
       //system.debug('objCreditMemo'+objCreditMemo);
        return objCreditMemo;
      }
    
     // create credit memo line item records
      public static Credit_memo_line_item__c createCreditMemoLineRec(Decimal amount,Decimal taxAmount,Id packageId,Id enrolmentId, Id invoiceLineItemId,String reasons) {
        Credit_memo_line_item__c objCreditLineItem = new Credit_memo_line_item__c();
        objCreditLineItem.Amount__c = amount;
        objCreditLineItem.Tax_Amount__c = taxAmount;
        objCreditLineItem.Package__c = packageId;
        objCreditLineItem.Enrolment__c = enrolmentId;
        objCreditLineItem.Invoice_Line_Item__c = invoiceLineItemId;
        objCreditLineItem.Remarks__c = reasons;
       //system.debug('objCreditLineItem'+objCreditLineItem);
        return objCreditLineItem;
      }

    


    //@Jatin on 21st November 2019 Due to refund record not created for Deposit Adjust.
    // adjust deposit in invoice
    /*private static void adjustDeposit(List<Invoice__c> listOfInv, Set<String> setOfInvIds,Set<String> setOfParentIds,
                                        Date firstDate,Date lastDate, Map<String, Date> mapOfParentEnrolmentLastDate){
    
        List<Invoice__c> invListToUpdate = new List<Invoice__c>();
        Map<String, Payment__c> mapOfPayments = new Map<String, Payment__c>();
        
        Map<String, Boolean> mapOfActiveParent = new Map<String, Boolean>();
        mapOfActiveParent = checkParentHasMultipleEnrolments(setOfParentIds, lastDate);

        List<Payment__c> newRefundPayments = new List<Payment__c>();

        Map<String,List<Payment__c>> mapOfParentDeposit = getParentPayments(setOfParentIds,'deposit',firstDate,lastDate);
        Map<String,Decimal> parentPaymentsTotal = getParentPaymentMap(mapOfParentDeposit);
        
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        String depositRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();

        Payment__c newPayment = new Payment__c();
        Map<String,String> paymentAmountRecType = new Map<String,String>(); 
       //system.debug('listOfInv'+listOfInv);                                 
        for(Invoice__c invoice : listOfInv){

            newPayment = new Payment__c();

            Boolean finding = TRUE;
            Decimal invoiceTotalAmount = invoice.Total_Amount__c;
            Decimal accumulatedDepositAmount = (parentPaymentsTotal.containsKey(invoice.parent_account__c)) ? parentPaymentsTotal.get(invoice.parent_account__c) : 0;
            Decimal adjustedAmount = 0;
            Decimal adjustedPaymentAmount = 0;
            String chargeId = (mapOfParentDeposit.containskey(invoice.parent_account__c)) ? mapOfParentDeposit.get(invoice.parent_account__c)[0].Transaction_ID__c : '';
            Date lastLessonDate = (mapOfParentDeposit.containskey(invoice.parent_account__c)) ? mapOfParentDeposit.get(invoice.parent_account__c)[0].last_lesson_Date__c : NULL;
            String paymentId = (mapOfParentDeposit.containskey(invoice.parent_account__c)) ? mapOfParentDeposit.get(invoice.parent_account__c)[0].Id : NULL;
            if(String.isNotBlank(invoice.Parent_Account__c) && mapOfParentDeposit.containsKey(invoice.parent_account__c)){
               
                for(Payment__c objPay : mapOfParentDeposit.get(invoice.parent_account__c)){
                
                    if(!mapOfPayments.containsKey(objPay.Id)){
                           //system.debug('invoiceTotalAmount'+invoiceTotalAmount);
                           //system.debug('accumulatedDepositAmount'+accumulatedDepositAmount);
                            if(invoiceTotalAmount == accumulatedDepositAmount){
                                //Run if the total Invoice Amount is equal to the Total of Payment deposits
                                if(finding){

                                    objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                                    objPay.invoice__c = invoice.Id;
                                    objPay.Payment_Amount__c = invoiceTotalAmount;  
                                    objPay.Remarks__c = 'Total Deposit '+ String.valueOf(invoiceTotalAmount) +' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount)+' and balance 0 refunded';
                                    objPay.Payment_Date__c = invoice.Invoice_Date__c; 
                                    mapOfPayments.put(objPay.Id, objPay);
                                    invoice.status__c = 'Paid';
                                    finding = FALSE;

                                }else{

                                    objPay.Payment_Status__c = ConstantsClass.paymentVoid;
                                    objPay.Remarks__c = 'Adjusted against '+invoice.Name+', Change Amount from '+objPay.Payment_Amount__c+' to 0.';
                                    objPay.Payment_Amount__c = 0; 
                                    objPay.Payment_Date__c = invoice.Invoice_Date__c; 
                                    mapOfPayments.put(objPay.Id, objPay);

                                }
                            }else if(invoiceTotalAmount > accumulatedDepositAmount){
                                //Run if the total Invoice Amount is greater than Total of Payment deposits
                                    
                                    objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                                    objPay.invoice__c = invoice.Id;
                                    objPay.Remarks__c = 'Adjusted against '+invoice.Name;
                                    objPay.Payment_Date__c = invoice.Invoice_Date__c; 
                                    mapOfPayments.put(objPay.Id, objPay);

                            }else if(invoiceTotalAmount < accumulatedDepositAmount){
                                //Run if the total Invoice Amount is Smaller than Total of Payment deposits
                                
                                if(finding){
                                    // @@jatin 11-jan-2020 : for manage invoice and payment per amount  
                                    if(objPay.Payment_Amount__c  > invoiceTotalAmount ){
                                        adjustedPaymentAmount =  adjustedPaymentAmount + objPay.Payment_Amount__c; 
                                    }else if(objPay.Payment_Amount__c == invoiceTotalAmount){
                                        adjustedPaymentAmount = adjustedPaymentAmount + invoiceTotalAmount; 
                                        objPay.Payment_Amount__c = invoiceTotalAmount;
                                    }else if(objPay.Payment_Amount__c < invoiceTotalAmount  ){
                                        adjustedPaymentAmount = adjustedPaymentAmount + objPay.Payment_Amount__c; 
                                    }
                                    // if invoice Total Amount is greater then  Adjust payment then we remove extra amount and 
                                    // create new payment recoard  
                                    if(invoiceTotalAmount < adjustedPaymentAmount){  
                                        Decimal remainingAmount = adjustedPaymentAmount - invoiceTotalAmount; 
                                        adjustedPaymentAmount = adjustedPaymentAmount - remainingAmount; 
                                        objPay.Payment_Amount__c = objPay.Payment_Amount__c - remainingAmount;
                                        paymentAmountRecType.put(invoice.Id,objPay.RecordTypeId);
                                    } 
                                    
                                    objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                                    objPay.invoice__c = invoice.Id;
                                    objPay.Payment_Date__c = invoice.Invoice_Date__c; 
                                    objPay.Remarks__c = 'Total Deposit '+ String.valueOf(accumulatedDepositAmount) +' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount)+' and balance '+String.valueOf(accumulatedDepositAmount - invoiceTotalAmount)+' refunded';
                                    mapOfPayments.put(objPay.Id, objPay);
                                    invoice.status__c = 'Paid';
                                     // Run if the Adjust payment is equals to total invoice Amount
                                    if(adjustedPaymentAmount ==  invoiceTotalAmount){ 
                                        adjustedAmount = accumulatedDepositAmount - invoiceTotalAmount;
                                        finding = FALSE;
                                    }
                                }else{
                                    // 13-JAN-2020: JATIN: if Payment record is exist and adjusted Payment Amount is equal to payment amount 
                                    // then we not creating new record
                                    if(mapOfActiveParent.containsKey(invoice.parent_account__c)
                                    && mapOfActiveParent.get(invoice.parent_account__c)){
                                        if(adjustedAmount >= objPay.Payment_Amount__c ){
                                            adjustedAmount = adjustedAmount - objPay.Payment_Amount__c;
                                        }
                                    }else{
                                        objPay.Remarks__c = 'Adjusted against '+invoice.Name+', Change Amount from '+objPay.Payment_Amount__c+' to 0.';
                                        objPay.Payment_Amount__c = 0;
                                        objPay.Payment_Date__c = invoice.Invoice_Date__c; 
                                        objPay.Payment_Status__c = ConstantsClass.paymentVoid;
                                        mapOfPayments.put(objPay.Id, objPay);
                                    }
                                }

                            }
                            
                    }

                }
                if(adjustedAmount > 0){
                    newPayment.Parent_Account__c = invoice.parent_account__c;
                    
                    newPayment.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                    if(mapOfActiveParent.containsKey(invoice.parent_account__c)
                         && mapOfActiveParent.get(invoice.parent_account__c)){
                        // 13-JAN-2020: JATIN:if payment total is greate then invoice total then we check this adjusted payment record type  and 
                        // create new payment according to previous adjusted payment object record type 
                        if(paymentAmountRecType.containsKey(invoice.Id)){
                            newPayment.Payment_Amount__c = adjustedAmount;
                            newPayment.recordTypeId = paymentAmountRecType.get(invoice.Id);
                            newPayment.Payment_Date__c = System.today();
                            newPayment.Remarks__c = 'Total Deposit '+String.valueOf(accumulatedDepositAmount)+' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount) + ' and balance '+adjustedAmount+' become pending deposit.';
                        }else{
                            newPayment.Payment_Amount__c = adjustedAmount;
                            newPayment.recordTypeId = depositRecType;
                            newPayment.Payment_Date__c = System.today();
                            newPayment.Remarks__c = 'Total Deposit '+String.valueOf(accumulatedDepositAmount)+' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount) + ' and balance '+adjustedAmount+' become pending deposit.';
                          
                        }
                    }else{
                        // 14-JAN-2020: JATIN: For add enrolment id if payment is refund
                        if((invoice.Invoice_Line_Items__r != null && invoice.Invoice_Line_Items__r.size() > 0) &&
                            (string.isNotBlank(invoice.Invoice_Line_Items__r[0].Enrolment__r.id))){
                               newPayment.Enrolment__c =  invoice.Invoice_Line_Items__r[0].Enrolment__r.id;
                        }
                        newPayment.recordTypeId = refundRecType;
                        newPayment.Transaction_Id__c = chargeId;
                        newPayment.Payment_Amount__c = -adjustedAmount;
                        if(mapOfParentEnrolmentLastDate.containsKey(invoice.parent_account__c)){
                            newPayment.Payment_Date__c = mapOfParentEnrolmentLastDate.get(invoice.parent_account__c);
                        }
                        newPayment.Remarks__c = 'Total Deposit '+String.valueOf(accumulatedDepositAmount)+' adjusted with the final invoice to the extent of '+String.valueOf(invoiceTotalAmount) + ' and balance '+adjustedAmount+' refunded.';
                    
                    }
                   //system.debug('newPayment'+newPayment);
                    newRefundPayments.add(newPayment);
                }
                invListToUpdate.add(invoice);
            }
        }
        
        if(invListToUpdate.size() > 0){
            UPDATE invListToUpdate;     
            //system.debug('invListToUpdate'+invListToUpdate);                                   
        }
        
        if(mapOfPayments.size() > 0){
            newRefundPayments.addAll(mapOfPayments.values());
            UPSERT newRefundPayments; 
           //system.debug('@@@@newRefundPayments'+newRefundPayments); 

        }
        //calculateRefundAmount(listOfInv, mapOfParentDeposit);                                   
    }*/

    //check that the Parent Has other Enrolments or Not
    private static Map<String, Boolean> checkParentHasMultipleEnrolments(Set<String> parentIds, Date lastDate){
        Map<String, Boolean> mapOfParentActiveEnrolment = new Map<String, Boolean>();
        Boolean flag = false;
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        for(Enrolment__c enrolObj : [SELECT Id, Parent__c FROM Enrolment__c
                                        WHERE Parent__c IN :parentIds 
                                        AND ((Stage__c = :ConstantsClass.enroledStatus 
                                                AND Type__c In: enrolTypes
                                                //Commented by jatin: 9-jan-2020 : For manage regular and group type enrolments
                                                //Type__c = :ConstantsClass.enrolRegularStatus 
                                                AND (Package_Process_Type__c != :ConstantsClass.enrollmentProcessCancelType 
                                                    OR Effective_Date__c > :lastDate)
                                                )
                                            OR  (Stage__c = : ConstantsClass.enrollmentPianoViewingBookedStage //ConstantsClass.enrollmentPianoRentalActiveStage
                                                AND Type__c =: ConstantsClass.enrollmentTypeInstrument) 
                                            )]){
            mapOfParentActiveEnrolment.put(enrolObj.Parent__c, TRUE);
        }
        return mapOfParentActiveEnrolment;
    }

    // make refund if any
    /*private static void calculateRefundAmount(List<invoice__c> listOfInvoice,Map<String,List<Payment__c>> mapOfPayments){
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        Map<String,Decimal> parentTotalPayment = new Map<String,Decimal>();
        List<Payment__c> refundPayments = new List<Payment__c>();
        parentTotalPayment = getParentPaymentMap(mapOfPayments);
    for(Invoice__c objInv : listOfInvoice){
            if(String.isNotBlank(objInv.parent_Account__c) && parentTotalPayment.containsKey(objInv.parent_Account__c)
                && parentTotalPayment.get(objInv.parent_Account__c) > objInv.total_amount__c){
                
                    Payment__c oldPay = mapOfPayments.get(objInv.Parent_account__c)[0];            
                    Payment__c refundPay = new Payment__c();
                    refundPay.recordTypeId = refundRecType;
                    refundPay.payment_amount__c = objInv.total_amount__c - parentTotalPayment.get(objInv.parent_Account__c);
                    refundPay.parent_account__c = objInv.parent_account__c;
                    refundPay.invoice__c = objInv.id;
                    refundPay.transaction_id__c = oldPay.transaction_id__c;
                    refundPay.payment_date__c = oldPay.last_lesson_Date__c;
                    refundPay.payment_status__c = constantsClass.paymentPendingStatus;
                    refundPay.parent_payment__c = oldPay.id;
                    refundPayments.add(refundPay); 
                }
                
        }
        if(refundPayments.size() > 0){
            INSERT refundPayments;
        }
        
    }*/
    
    
    
    /*private static void insertTasks(List<Payment__c> listOfPayment){
    
List<Task> listOftask = new List<Task>();
        for(Payment__c objPay : listOfPayment){
            listOfTask.add(createTask(objPay.Id,objPay.Payment_Date__c,System.Label.Financial_User,'Refund Amount '+ (-1* objPay.Payment_amount__c)));    
        }
        if(listOfTask.size() > 0){
            //INSERT listOfTask;
        }
    }*/
    

    //@02-26-2018 this method update next date on Subscription object after invoice generate by Sanjay Bhati
    public static void updateSubscriptionNextDate(Set<Subscription__c> subscriptionSet){
        if(subscriptionSet.size()>0){
            List<Subscription__c> listOfSubscriptions = new List<Subscription__c>();
            List<Subscription_Line_Item__c> listOfSubsLineItem = new List<Subscription_Line_Item__c>();
            for(Subscription__c subscription : subscriptionSet){
                subscription.Next_Bill_Date__c = subscription.Next_Bill_Date__c.addMonths(1);
                for(Subscription_Line_Item__c objLineItem : subscription.Subscription_Line_Items__r){
                    if(objLineItem.Next_Bill_Date__c != NULL){
                        objLineItem.Next_Bill_Date__c = objLineItem.Next_Bill_Date__c.addMonths(1); 
                        listOfSubsLineItem.add(objLineItem);
                    }
                }
                listOfSubscriptions.add(subscription);
            }
            if(listOfSubscriptions.size() > 0){
                UPDATE listOfSubscriptions;
            }
            if(listOfSubsLineItem.size() > 0){
                UPDATE listOfSubsLineItem;
            }
        }
    } 
    
    //@ 1 April 2019 
    
    // this method return map of dates on the base of day .
    public static Map<String,List<Date>> getDateMap(Date firstDate,Date lastDate ){
        Map<String,List<Date>> datesMap = new Map<String,List<Date>>();
        while(firstDate <= lastDate){
            DateTime myDateTime = (DateTime) firstDate;
            String day = myDateTime.format('EEEE');
            List<Date> dateList = new List<Date>();
            if(datesMap.containskey(day)){
                dateList = datesMap.get(day);
            }
            dateList.add(firstDate);
            firstDate = firstDate.addDays(1);
            datesMap.put(day,dateList);
        }
        //system.debug(datesMap);
        return datesMap;
    }
    
    public static void emailInvoiceToParent(List<Invoice__c> invList){
        if(invList!=null && invList.size()>0){
           //system.debug('invList'+invList);
            deleteAttachment(invList);
            List<EmailTemplate> templateList = [Select Id from EmailTemplate where Name='Subscription Invoice' limit 1];
            if(templateList.size()>0){                
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                List<Attachment> attList = new List<Attachment>();
                for(Invoice__c inv:invList){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(inv.Parent_Account__r.personContactId);
                    mail.setWhatId(inv.Id);
                    mail.setTemplateId(templateList[0].Id);
                    mail.saveAsActivity = false;
                    List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName(inv.Name+'.pdf');
                    
                    PageReference pdf =   new pageReference('/apex/SubscriptionInvoicePdfClone?Id='+inv.Id); //new pageReference('/apex/testpdf?Id='+inv.Id);     //new pageReference('/apex/SubscriptionInvoicePDF?Id='+inv.Id);
                    blob bdy = null;
                    if(!test.isRunningTest()){
                        bdy  = pdf.getContent();
                    }else{
                        BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
                        objStripeCharge.statusCode = 200;
                        objStripeCharge.paid = true;
                        bdy = blob.valueOf(JSON.serialize(objStripeCharge));
                    }
                    efa.setBody(bdy);
                    fileAttachments.add(efa);
                    
                    mail.setFileAttachments(fileAttachments);
                    emailList.add(mail);
                    
                    Attachment att = new Attachment();
                    att.Name = inv.Name+'.pdf';
                    att.parentId = inv.Id;
                    att.body = bdy;
                    attList.add(att);                    
                }
                //commented by arpit to disable invoice email (5 April 2019)
                // Messaging.sendEmail(emailList);
                insert attList;
            }
        }
    }
    
    @future(callout=true)
    public static void invoiceAttWithFuture(Set<string> invIds){
        BillingUtility.addInvocieAttachment(invIds);
    }
    
    public static void addInvocieAttachment(Set<string> invIds){
        if(invIds.size()>0){
            List<Invoice__c> invList = new List<Invoice__c>();
            if(invIds.size()>0){
                invList = [Select Id,Name,Parent_Account__c,Parent_Account__r.personContactId from Invoice__c where id in:invIds]; 
            }
            if(invList.size()>0){
                deleteAttachment(invList );
                List<Attachment> attList = new List<Attachment>();
                for(Invoice__c inv : invList){
                    PageReference pdf = new pageReference('/apex/SubscriptionInvoicePdfClone?Id='+inv.Id);
                    if(!Test.isRunningTest()){
                        blob bdy = pdf.getContent();
                        
                        Attachment att = new Attachment();
                        att.Name = inv.Name+'.pdf';
                        att.parentId = inv.Id;
                        att.body = bdy;
                        attList.add(att);   
                    }
                }
                if(attList.size()>0){
                    insert attList;
                }
            }
        }
    }
    
    
    //@07-05-2019 Delete Existing Attachment From Invoice By Sanjay Bhati
    public static Void deleteAttachment(List<Invoice__c> invList){
        Set<Id> invIds = new Set<Id>();
        for(Invoice__c inv : invList){
            invIds.add(inv.Id);
        }
        if(invIds.size()>0){
            List<Attachment> attachList = [Select Id,Parentid,Name From Attachment Where Parentid IN:invIds];
            delete attachList;
        }
    }
    //@05-03-2018 This method send the mail to customer when payment is declined or reminder for rePayment. By Sanjay Bhati
    public static void sendDeclinedMail(List<Invoice__c> invoiceList,String mailfor){
        if(String.isNotBlank(mailfor)){
            Email_Settings__mdt[] declinedEmail = [SELECT DeveloperName, Id, Template_Id__c FROM Email_Settings__mdt WHERE DeveloperName =: mailfor];
            List<EmailTemplate> templateList = new List<EmailTemplate>();
            String emailTemplateId = '';
            if(mailfor == 'Declined'){
                if(declinedEmail.size() > 0){
                    emailTemplateId = declinedEmail[0].Template_Id__c;
                }
            }else if(mailfor== '3'){
                templateList = [Select Id from EmailTemplate where Name='PaymentReminderFor3Days' limit 1];
                emailTemplateId = templateList[0].Id;
            }else if(mailfor== '5'){
                templateList = [Select Id from EmailTemplate where Name='PaymentReminderFor5Days' limit 1];
                emailTemplateId = templateList[0].Id;
            }else if(mailfor== '7'){
                templateList = [Select Id from EmailTemplate where Name='PaymentReminderFor7Days' limit 1];
                emailTemplateId = templateList[0].Id;
            }
            
            
            if(String.isNotBlank(emailTemplateId)){                
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                for(Invoice__c inv : invoiceList){
                    
                    /*Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, inv.Parent_Account__r.personContactId, inv.Id);
                    mail.setTargetObjectId(inv.Parent_Account__r.personContactId);
                    mail.saveAsActivity = true;
                    mail.setWhatId(inv.Parent_Account__c);
                    mail.setTemplateId(emailTemplateId);  
                    */
                    Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(emailTemplateId,
                                                        inv.Parent_Account__r.personContactId, inv.Id,inv.Center__r.Location__c);
                    emailList.add(mail);     
                }
                Messaging.sendEmail(emailList);
            }
        }
    }
    
    //@@ 3July19 By arpit
    public static Decimal roundOffAmount(Decimal amount){
        Decimal value = 0;
        if(amount != NULL){
            value = amount.setScale(2,System.RoundingMode.HALF_UP);
        }
        return value;        
    }    
    
    // return task , whatId (task related to record)
    /*public static Task createTask(String whatId,Date taskDate,String ownerId,String subject){
        Task taskObj = new Task(WhatId = whatId, Priority = 'Normal',Status = 'Open',ActivityDate = taskDate,OwnerId = ownerId,
                                Subject = subject);
        return taskObj;
    }
    */
    public static void createPaymentusingInvoice(List<Invoice__c> invList){
        if(invList!=null && invList.size()>0){
            for(Invoice__c inv:invList){
                //Boolean isPaymentSuccessful;
                
                Payment__c pay = new Payment__c();
                
                pay.Invoice__c = inv.Id;
                pay.Method_of_Payment__c = ConstantsClass.modeOfPayments[0];
                pay.Parent_Account__c = inv.Parent_Account__c;
                pay.Payment_Amount__c = inv.Total_Amount__c;
                pay.Payment_Date__c = system.today();
                //pay.Payment_Status__c   
                // pay.Remarks__c
                //pay.Transaction_ID__c
            }
        }
    }
    
    public static StripeCustomer createStripeCustomer(string token,string name,string email, string description,String baseUrl,String apiKey){
        StripeCustomer sc = new StripeCustomer();
        string customerUrl = baseurl + '/v1/customers';
        
        HttpRequest http = new HttpRequest();
        http.setEndpoint(customerUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apiKey + ':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('source', 'UTF-8') + '=' + EncodingUtil.urlEncode(token, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('metadata[Name]', 'UTF-8') + '=' + EncodingUtil.urlEncode(name, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('email', 'UTF-8') + '=' + EncodingUtil.urlEncode(email, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('description', 'UTF-8') + '=' + EncodingUtil.urlEncode(description, 'UTF-8') + '&';
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
       //system.debug('Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        sc = (StripeCustomer) System.JSON.deserialize(response, StripeCustomer.class);
        sc.statusCode = statusCode;
        return sc;
    }
    
    
    
    
    // call this method to take payment from customer when you dont have any invoice no.
    public static stripeCharge createChargeForCustomer(string customerId,Decimal amount,string currencyCode,String baseUrl,String apiKey){
        //system.debug('countryMap >>'+countryMap);
        //System.debug('billingUtility.baseurl '+billingUtility.baseurl);
        string chargeUrl = baseurl + '/v1/charges';
        amount = ((amount)*100);
        //system.debug('amount after 100 >>'+amount);
        Integer stripeAmt = Integer.valueOf(amount);
        //system.debug('stripeAmt  >>'+stripeAmt );
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apiKey + ':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('customer', 'UTF-8') + '=' + EncodingUtil.urlEncode(customerId, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('amount', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(stripeAmt), 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('currency', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(currencyCode), 'UTF-8') + '&';
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
        //system.debug('Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        StripeCharge sc = (StripeCharge) System.JSON.deserialize(response, StripeCharge.class);
        
        sc.statusCode = statusCode;
        return sc;
    }
    //@Juneid 19 Aug 2020, This method is use for Create charge on the basis of Organisation
    public static stripeCharge createChargeForCustomer(string customerId,Decimal amount,string organisationId){
         BillingUtility.stripeCharge stripeChrg = new BillingUtility.stripeCharge(); 
        List<Organisation__c> orgnizationList = [SELECT Id,name,Country__r.Currency_Code__c,Stripe_Publishable_Key__c,Stripe_Secret_Key__c,Stripe_Base_Url__c FROM Organisation__c WHERE Id =:organisationId];
        if(!orgnizationList.isEmpty())
            stripeChrg = createChargeForCustomer(customerId, amount, orgnizationList[0].Country__r.Currency_Code__c, orgnizationList[0].Stripe_Base_Url__c, orgnizationList[0].Stripe_Publishable_Key__c);
        return stripeChrg;
    }
    
    // call this method to take payment from customer when you have invoice number.
    public static stripeCharge createChargeForCustomerWithInvoice(string customerId,Decimal amount,string currencyCode,String invoiceName,String baseUrl,String apiKey){
        
        string chargeUrl = baseurl + '/v1/charges';
        amount = ((amount)*100);
        Integer stripeAmt = Integer.valueOf(amount);
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        http.setTimeout(120000);
        Blob headerValue = Blob.valueOf(apiKey + ':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('customer', 'UTF-8') + '=' + EncodingUtil.urlEncode(customerId, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('amount', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(stripeAmt), 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('currency', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(currencyCode), 'UTF-8') + '&';
        if(String.isNotBlank(invoiceName)){
            url += EncodingUtil.urlEncode('description', 'UTF-8') + '=' + EncodingUtil.urlEncode(invoiceName, 'UTF-8') + '&';
        }
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
        String response = hs.getBody();
        response = BillingUtility.cleanJson(response);
       //system.debug('@response'+response);
        StripeCharge sc = (StripeCharge) System.JSON.deserialize(response, StripeCharge.class);
        
        sc.statusCode = statusCode;
        return sc;
    }
    
    
    public static stripeCharge createOneTimeCharge(string token,Decimal amount,string currencyCode,String baseUrl,String apiKey){
        string chargeUrl = baseurl + '/v1/charges';
        amount = ((amount)*100);
        Integer stripeAmt = Integer.valueOf(amount);
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apiKey + ':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('source', 'UTF-8') + '=' + EncodingUtil.urlEncode(token, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('amount', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(stripeAmt), 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('currency', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(currencyCode), 'UTF-8') + '&';
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
       //system.debug('Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        StripeCharge sc = (StripeCharge) System.JSON.deserialize(response, StripeCharge.class);
        
        sc.statusCode = statusCode;
        return sc;
    }
    
    //@05-03-2018 This method is used to add card with a customer
    public static StripeCard AddCardWithCustomer(String customerId,String token,String baseUrl,String apiKey){
        string chargeUrl = baseurl+'/v1/customers/'+customerId+'/sources';
        
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apikey+':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('source', 'UTF-8') + '=' + 
            EncodingUtil.urlEncode(token, 'UTF-8') + '&';
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
        //system.debug('Carrd Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        StripeCard sc = (StripeCard) System.JSON.deserialize(response, StripeCard.class);
        
        sc.statusCode = statusCode;
       //system.debug('Stripe Card '+sc);
        return sc;
    }
    
    //@17-05-2019 This method is used to fetch customer detail with card 
    public static StripeCustomer getCustomerWithCard(String customerId,String baseUrl,String apiKey){
        string chargeUrl = baseurl+'/v1/customers/'+customerId;
        
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('GET');
        Blob headerValue = Blob.valueOf(apikey+':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
       //system.debug('Carrd Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        StripeCustomer sc = (StripeCustomer) System.JSON.deserialize(response, StripeCustomer.class);
        
        sc.statusCode = statusCode;
       //system.debug('Stripe Card '+sc);
        return sc;
    }
    
    //@17-05-2019 This method is used to update card details
    public static StripeCard updateCard(String customerId, String cardId, String expMonth, String expYear,String baseUrl,String apiKey){
        string chargeUrl = baseurl+'/v1/customers/'+customerId+'/sources/'+cardId;
        
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apikey+':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('exp_month', 'UTF-8') + '=' + EncodingUtil.urlEncode(expMonth, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('exp_year', 'UTF-8') + '=' + EncodingUtil.urlEncode(expYear, 'UTF-8') ;
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
        //system.debug('Carrd Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        StripeCard sc = (StripeCard) System.JSON.deserialize(response, StripeCard.class);
        
        sc.statusCode = statusCode;
       //system.debug('Stripe Card '+sc);
        return sc;
    }
    
    public static StripeCharge setDefaultCard(String customerId,String cardId,String baseUrl,String apiKey){
        string chargeUrl = baseurl+'/v1/customers/'+customerId;
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apikey+':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        string url = '&' + EncodingUtil.urlEncode('default_source', 'UTF-8') + '=' + EncodingUtil.urlEncode(cardId, 'UTF-8') + '&';
        http.setBody(url);
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        hs = con.send(http);
        statusCode = hs.getStatusCode();
       //system.debug('Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        StripeCharge sc = (StripeCharge) System.JSON.deserialize(response, StripeCharge.class);
        sc.statusCode = statusCode;
        return sc;
    }
    @future(callout=true)
    //public static 
    public static /*StripeCharge*/ void updateCharge(String chargeId, String invoiceName,String baseUrl,String apiKey){
        String endPoint = baseUrl+'/v1/charges/'+chargeId;
        HttpRequest http = new HttpRequest();
        
        http.setEndpoint(endPoint);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apikey+':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('description', 'UTF-8') + '=' + EncodingUtil.urlEncode(invoiceName, 'UTF-8') + '&';
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        hs = con.send(http);
        statusCode = hs.getStatusCode();
        
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        StripeCharge sc = (StripeCharge) System.JSON.deserialize(response, StripeCharge.class);
        sc.statusCode = statusCode;//system.debug('@@@Update Charge'+sc);
        //return sc;
        
    }
    
    public static void createBatchLog(String jobName,DateTime startTime,DateTime endTime,Integer noOfRecords){
        Batch_Job_Log__c blog = new Batch_Job_Log__c();
        blog.Name = jobName;
        blog.Start_Time__c = startTime;
        blog.End_Time__c = endTime;
        blog.No_of_records_proceeds__c = noOfRecords;
        insert blog;
    }
    public static void createBatchLog(String jobName,DateTime startTime,DateTime endTime,Integer noOfRecords,string Description){
        Batch_Job_Log__c blog = new Batch_Job_Log__c();
        blog.Name = jobName;
        blog.Start_Time__c = startTime;
        blog.End_Time__c = endTime;
        blog.No_of_records_proceeds__c = noOfRecords;
        blog.Description__c = Description;
        insert blog;
    }
    
    Public static Decimal calculateCurrentMonthPckFees(Date lessDate, Decimal unitFees) {
        Date tempDt = lessDate;        
        Integer noOfLessInCurrMonth = 0;
        
        while(lessDate.month() == tempDt.month()){
            noOfLessInCurrMonth = noOfLessInCurrMonth+1;
            tempDt = tempDt.addDays(7);
        }
        Decimal packFee = unitFees * noOfLessInCurrMonth;
       //system.debug('packFee'+packFee);
        return packFee;
    }
    
    Public static Subscription__c fillSubscription(String parId, String status, Date subsDate) {
        Subscription__c subs = new Subscription__c();
        subs.Parent__c = parId;
        subs.Status__c = status;
        subs.Subscription_Start_Date__c = subsDate;
        
        Integer gstTaxPer = ConstantsClass.defGST;
        try{
            gstTaxPer     = Integer.valueOf(Label.GST_Tax_Rate);
        }catch(Exception e){}
        subs.GST_Tax__c   = gstTaxPer;
        
        return subs;
    }
    
    Public static Subscription_Line_Item__c fillSubscriptionLineItem(String stuId, String subId, String packId, String enrId, Decimal Amt, String status) {
        Subscription_Line_Item__c subLItm = new Subscription_Line_Item__c();
        subLItm.Subscription__c = subId;
        subLItm.Plan_Package__c = packId;
        subLItm.Student__c      = stuId;
        subLItm.Enrolment__c    = enrId;
        subLItm.Amount__c       = Amt;
        subLItm.Status__c       = status;
        
        return subLItm;
    }
    
    Public static Invoice__c fillInvoice(String subsId, String parId, String status) {
        Invoice__c inv        = new Invoice__c();
        if(String.isNotBlank(subsId)){
            inv.Subscription__c   = subsId; 
        }
        inv.Parent_Account__c = parId;
        inv.Status__c         = status;
        inv.Invoice_Date__c   = System.today();
        inv.Due_Date__c       = inv.Invoice_Date__c.addDays(ConstantsClass.addInvoiceDueDays);
        return inv;
    }
    Public static Payment__c fillPayment(String parId, String invId, Decimal payAmt, String status) {
        Payment__c pay = new Payment__c();
        pay.Invoice__c        = string.isNotBlank(invId) ? invId : null;
        pay.Payment_Date__c   = System.today(); 
        pay.Parent_Account__c = parId;
        pay.Payment_Amount__c = payAmt;
        pay.Payment_Status__c = status;
        return pay;
    }
    
    Public static Enrolment__c fillEnrolment(String parId, String stuId, String centerId, String tchrId, String pckgId, Date lessStDate, Time lessStTime, String stage) {
        Enrolment__c enrl   = new Enrolment__c();
        //enrl.Name           = name;
        enrl.Parent__c      = parId;
        enrl.Student__c     = stuId;
        enrl.Type__c        = 'Regular';
        enrl.Stage__c       = stage;
        enrl.Center__c      = centerId;
        enrl.Teacher__c     = tchrId;
        enrl.Package__c     = pckgId;
        enrl.Lessons_Start_Date__c =  lessStDate;
        enrl.Lesson_Start_time__c  = lessStTime;
        if(lessStDate != null){
            Datetime dt = DateTime.newInstance(lessStDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('EEEE');                                                                                   
            enrl.Lesson_Day__c = dayOfWeek;
        }
        return enrl;
    }   
    
    public Static Invoice_Line_Item__c fillInvLnItm(String invId, String enrlId, String subLItmId, Decimal Amount, String remStr){
        return fillInvLnItm(invId,enrlId,subLItmId,Amount,remStr,'');
    }
    
    public Static Invoice_Line_Item__c fillInvLnItm(String invId, String enrlId, String subLItmId, Decimal Amount, String remStr,String teacherId){
        Invoice_Line_Item__c invLneItm = new Invoice_Line_Item__c();
        invLneItm.Invoice__c = invId;
        invLneItm.Enrolment__c = enrlId;
        // invLneItm.Package__c = slcdPlan;
        invLneItm.Subscription_Line_Item__c = subLItmId;
        invLneItm.Amount__c = Amount;
        invLneItm.Remarks__c = remStr;
        if(String.isNotBlank(teacherId)){
            invLneItm.Teacher_Id__c = teacherId;    
        }
        return invLneItm;
    }
    
    
    Public static String cleanJson(String json) {
        json = json.replaceAll('"object":', '"stripeObject":');
        json = json.replaceAll('"date":', '"stripeDate":');
        json = json.replaceAll('"end":', '"endDate":');
        json = json.replaceAll('"data":', '"stripeData":');
        json = json.replaceAll('"currency":', '"stripeCurrency":');
        json = json.replaceAll('"type":', '"stripeType":');
        
        json = json.replaceAll('"customer":\\s?"cus_', '"customer_id": "cus_');
        json = json.replaceAll('"invoice":\\s?"in_', '"invoice_id": "in_');
        
        return json;
    }
    
    
    //@ 12 March by Arpit
    
    public static void rollUpMakeupCredits(Set<String> setOfStudentIds){
        String lessonTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        // 20-dec-2019 : added by jatin for Add makeup hours for  group lesson record type 
        // this group lesson bookings work same as regular booking 
        String grouplessonTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
       // commented by :18-dec:2019 jatin for manage regular and group lesson bookings available mins 
       //Map<String, Decimal> mapOfParentAggregate = new Map<String, Decimal>();
        Map<String, String> mapOfParentAggregate = new Map<String, String>();
        Map<String, String> mapOfEnrolmentAggregate = new Map<String, String>();
        Map<String, String> mapOfStudentAndParent = new Map<String,String>();
        Map<String,String> mapOfSelfParent = new Map<String,String>();
        List<Account> listOfAccountsToUpdate = new List<Account>();
        List<Enrolment__C > listOfEnrolmentToUpdate = new List<Enrolment__C>();
        Set<String> setOfAccIds = new Set<String>();
        for(Account objAcc : [SELECT Id,Parent__c, Also_A_Student__c FROM Account WHERE Id In : setOfStudentIds OR 
                                Parent__c IN : setOfStudentIds ]){
            if(String.isBlank(objAcc.Parent__c)){
                mapOfSelfParent.put(objAcc.Id,objAcc.Id);
            }else{
                mapOfStudentAndParent.put(objAcc.Id,objAcc.Parent__c);
            }
        }
        for(Account objAcc : [SELECT Id,Parent__c, Also_A_Student__c FROM Account WHERE Id In : mapOfSelfParent.keySet() OR 
                                Parent__c IN : mapOfStudentAndParent.values()]){
            if(String.isBlank(objAcc.Parent__c)){
                mapOfSelfParent.put(objAcc.Id,objAcc.Id);
            }else{
                mapOfStudentAndParent.put(objAcc.Id,objAcc.Parent__c);
            }
            setOfAccIds.add(objAcc.Id);
            if(String.isNotBlank(objAcc.Parent__c)){
                setOfAccIds.add(objAcc.Parent__c);
            }
        }
       //system.debug('@@@setOfAccIds'+setOfAccIds);
        for( AggregateResult agrResult : [SELECT SUM(Available_Make_up_Units__c) creditSum, Student__c,Enrolment__c enrollId,Center__r.Organisation__r.Name orgName FROM Booking__c 
                                        WHERE Student__c IN :setOfAccIds  
                                        AND RecordTypeId =:lessonTypeId   
                                        AND Makeup_Given__c = 'true' 
                                        AND Type__c IN ('Regular','Ad-hoc') 
                                        AND Make_up_Expiry_Date__c >= TODAY /*AND Available_Make_up_Units__c >=0*/
                                        GROUP By Student__c,Enrolment__c,Center__r.Organisation__r.Name]){
            Decimal creditSum = (Decimal)agrResult.get('creditSum');
            String studentId = (String) agrResult.get('Student__c');
           // added by Nishi: 20-Jul-2020:Start: for Ossia student requirement :
            // Makeup minutes will needs to be managed at enrolment level instead of parent level
            String orgName = (String) agrResult.get('orgName');
           //system.debug('orgName'+orgName);
            String enrollId = (String) agrResult.get('enrollId');
            if(String.isNotBlank(enrollId) &&String.isNotBlank(orgName) &&  orgName.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                string availableMakeupMins =mapOfEnrolmentAggregate.containsKey(enrollId)
                                        ? mapOfEnrolmentAggregate.get(enrollId) : '0-0';
                    Decimal sumToAddAvailableMakeupMins = decimal.valueOf(availableMakeupMins.split('-')[0]);
                    if(creditSum!= NULL){
                        sumToAddAvailableMakeupMins += creditSum;
                    }
                    availableMakeupMins = sumToAddAvailableMakeupMins+'-'+ availableMakeupMins.split('-')[1];
                    mapOfEnrolmentAggregate.put(enrollId, availableMakeupMins);
                   //system.debug('mapOfEnrolmentAggregate'+mapOfEnrolmentAggregate);
            }
            // added by Nishi: 20-Jul-2020:End: for Ossia student requirement 
            else{
                String parentId = mapOfStudentAndParent.get(studentId);
                if(String.isBlank(parentId)){
                    parentId  = mapOfSelfParent.get(studentId);
                }
                if(String.isNotBlank(parentId)){
                    string availableMakeupMins =mapOfParentAggregate.containsKey(parentId)
                                        ? mapOfParentAggregate.get(parentId) : '0-0';
                    Decimal sumToAddAvailableMakeupMins = decimal.valueOf(availableMakeupMins.split('-')[0]);
                    if(creditSum!= NULL){
                        sumToAddAvailableMakeupMins += creditSum;
                    }
                    availableMakeupMins = sumToAddAvailableMakeupMins+'-'+ availableMakeupMins.split('-')[1];
                    mapOfParentAggregate.put(parentId, availableMakeupMins);
                }   
            }
        }
       //system.debug('@@@mapOfParentAggregate'+mapOfParentAggregate);
        // 20-dec-2019 : added by jatin for Add bookingTypes group lesson for calculate Available_Make_up_Units_for group lesson
        Set<String> bookingGroupTypes = new Set<String>{ConstantsClass.groupLessonTypeBooking};
        for( AggregateResult agrResult : [SELECT SUM(Available_Make_up_Units__c) creditSum, Student__c, Enrolment__c enrollId,
                                        Center__r.Organisation__r.Name orgName FROM Booking__c 
                                        WHERE Student__c IN :setOfAccIds  
                                        AND RecordTypeId =:grouplessonTypeId AND 
                                        Makeup_Given__c = 'true' 
                                        AND Type__c IN : bookingGroupTypes
                                        AND Make_up_Expiry_Date__c >= TODAY /*AND Available_Make_up_Units__c >=0*/
                                        GROUP By Student__c,Enrolment__c,Center__r.Organisation__r.Name]){
            Decimal creditSum = (Decimal)agrResult.get('creditSum');
            String studentId = (String) agrResult.get('Student__c');
            // added by Nishi: 21-Aug-2020:Start: for Ossia student requirement :
            // Makeup minutes will needs to be managed at enrolment level instead of parent level
            String orgName = (String) agrResult.get('orgName');
           //system.debug('orgName'+orgName);
            String enrollId = (String) agrResult.get('enrollId');
            if(String.isNotBlank(enrollId) &&String.isNotBlank(orgName) &&  orgName.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                string availableMakeupMins =mapOfEnrolmentAggregate.containsKey(enrollId)
                                        ? mapOfEnrolmentAggregate.get(enrollId) : '0-0';
                    Decimal sumToAddAvailableMakeupMins = decimal.valueOf(availableMakeupMins.split('-')[0]);
                    if(creditSum!= NULL){
                        sumToAddAvailableMakeupMins += creditSum;
                    }
                    availableMakeupMins = sumToAddAvailableMakeupMins+'-'+ availableMakeupMins.split('-')[1];
                    mapOfEnrolmentAggregate.put(enrollId, availableMakeupMins);
                   //system.debug('mapOfEnrolmentAggregate'+mapOfEnrolmentAggregate);
            }else{
                // added by Nishi: 21-Aug-2020:End: for Ossia student requirement
                String parentId = mapOfStudentAndParent.get(studentId);
                if(String.isBlank(parentId)){
                    parentId  = mapOfSelfParent.get(studentId);
                }
                if(String.isNotBlank(parentId)){
                    string availableMakeupMins =mapOfParentAggregate.containsKey(parentId)
                                        ? mapOfParentAggregate.get(parentId) : '0-0';
                    Decimal sumToAddGroupLessonAvailableMakeupMins = decimal.valueOf(availableMakeupMins.split('-')[1]);
                    if(creditSum!= NULL){
                        sumToAddGroupLessonAvailableMakeupMins += creditSum;
                    }
                    availableMakeupMins = availableMakeupMins.split('-')[0]+'-'+sumToAddGroupLessonAvailableMakeupMins;
                    mapOfParentAggregate.put(parentId, availableMakeupMins);
                }
            }
        }
        // added by Nishi: 20-Jul-2020:Start: for Ossia student requirement :
        // Makeup minutes will needs to be managed at enrolment level instead of parent level
       //system.debug('@@@mapOfParentAggregate'+listOfEnrolmentToUpdate);
        for(String enrolmentId : mapOfEnrolmentAggregate.keySet()){
            string availableMakeupMins = mapOfEnrolmentAggregate.get(enrolmentId);
            Enrolment__C objenrolment = new Enrolment__C(Id =enrolmentId, Available_Make_up_mins__c = decimal.valueOf(availableMakeupMins.split('-')[0]));
            listOfEnrolmentToUpdate.add(objenrolment);
        }
       //system.debug('@@@listOfEnrolmentToUpdate'+listOfEnrolmentToUpdate);
        if(listOfEnrolmentToUpdate.size() > 0){
            update listOfEnrolmentToUpdate;
        }
        // added by Nishi: 20-Jul-2020:END: for Ossia student

        for(String parentId : mapOfParentAggregate.keySet()){
            string availableMakeupMins = mapOfParentAggregate.get(parentId);
            Account objAcc = new Account(Id =parentId, Available_Make_up_Units__c = decimal.valueOf(availableMakeupMins.split('-')[0]),
            // added by jatin:18-dec-2019: for add makeupmins for group type booking 
            Available_Make_up_mins_For_Group__c =  decimal.valueOf(availableMakeupMins.split('-')[1]));
            listOfAccountsToUpdate.add(objAcc);
        }
       //system.debug('@@@listOfAccountsToUpdate'+listOfAccountsToUpdate);
        if(listOfAccountsToUpdate.size() > 0){
            update listOfAccountsToUpdate;
        }
       //system.debug('@@@listOfAccountsToUpdate'+listOfAccountsToUpdate);
    }
    
    // @ 26 March 2019 By Arpit
    public static StripeRefund createRefundForCharge(string chargeId,Decimal amount,String baseUrl,String apiKey){
        string chargeUrl = baseurl + '/v1/refunds';
        amount = ((amount)*100);
        Integer finalAmount = Integer.valueOf(amount);
        HttpRequest http = new HttpRequest();
        http.setEndpoint(chargeUrl);
        http.setMethod('POST');
        Blob headerValue = Blob.valueOf(apiKey + ':');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        http.setHeader('Authorization', authorizationHeader);
        
        string url = '&' + EncodingUtil.urlEncode('charge', 'UTF-8') + '=' + EncodingUtil.urlEncode(chargeId, 'UTF-8') + '&';
        url += EncodingUtil.urlEncode('amount', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(finalAmount), 'UTF-8') + '&';
        //url += EncodingUtil.urlEncode('currency', 'UTF-8') + '=' + EncodingUtil.urlEncode(string.valueOf(currencyCode), 'UTF-8') + '&';
        
        http.setBody(url);
        
        Integer statusCode;
        Http con = new Http();
        HttpResponse hs = new HttpResponse();
        
        hs = con.send(http);
        
        statusCode = hs.getStatusCode();
        
       //system.debug('Response===='+hs.getBody());
        string response = hs.getBody();
        response = BillingUtility.cleanJson(response);
        
        StripeRefund sc = (StripeRefund) System.JSON.deserialize(response, StripeRefund.class);
        sc.statusCode = statusCode;
       //system.debug('sc '+sc );
        return sc;
    }
    
    // @ 13 May 2019 By Arpit
    public static void createInvoiceAttachment(List<Invoice__c> invList){
       //system.debug('@@@invList'+invList);
        if(invList.size()>0){
            List<Attachment> attList = new List<Attachment>();
            for(Invoice__c inv:invList){
               //system.debug('@@@inv.Id call --'+inv.Id);    
                PageReference pdf =   new pageReference('/apex/SubscriptionInvoicePdfClone?Id='+inv.Id); //new pageReference('/apex/testpdf?Id='+inv.Id);     //new pageReference('/apex/SubscriptionInvoicePDF?Id='+inv.Id);
                blob bdy = null;
                if(!test.isRunningTest()){
                    bdy  = pdf.getContent();
                }else{
                    bdy = blob.valueOf('Sample Body');
                }
               //system.debug('@@bdy'+bdy);
                Attachment att = new Attachment();
                att.Name = inv.Name+'.pdf';
                att.parentId = inv.Id;
                att.body = bdy;
                attList.add(att);                    
            }
            if(attList.size() > 0){
                insert attList;
            }
        }
    }
    
    public class invoiceWrapper{
        public Invoice__c invoice{get;set;}
        public List<Invoice_Line_Item__c> invLineItmList{get;set;}
        public InvoiceWrapper(){
            invoice = new Invoice__c();
            invLineItmList = new List<Invoice_Line_Item__c>();
        }
    }
    
    @Future(callout=true)
    public static void createAttachment(Set<String> invoices){
        if(invoices.size() > 0){
            List<Invoice__c> invoiceList = [SELECT Id,Name,Total_Amount__c,Parent_Account__c,Parent_Account__r.personContactId, status__c FROM Invoice__c WHERE Id IN:invoices];
            createInvoiceAttachment(invoiceList);        
        }
        //System.debug('Invoices is Created....');
    }

    //Get parent Map and its list of Invoices
    /*Private static Map<String, List<Invoice__c>> getMapOfInvoices(List<Invoice__c> listOfInv){
        Map<String, List<Invoice__c>> mapOfInvoices = new Map<String, List<Invoice__c>>();
        for(Invoice__c invObj : listOfInv){
            if(mapOfInvoices.containsKey(invObj.Parent_Account__c)){
                mapOfInvoices.get(invObj.Parent_Account__c).add(invObj);
            }else{
                mapOfInvoices.put(invObj.Parent_Account__c, new List<Invoice__c> {invObj});
            }
        }
        return mapOfInvoices;
    }*/

    private static Map<String,List<Payment__c>> getParentPayments(Set<String> setOfParentIds, string type,Date firstDate,Date lastDate){
        Map<String,List<Payment__c>>  parentPayments = new Map<String,List<Payment__c>>();
        String query = generatePaymentQuery(setOfParentIds,type,firstDate,lastDate);
        for(Payment__c objPay : Database.query(query)){
            List<Payment__c> paymentList = parentPayments.containsKey(objPay.Parent_Account__c) ? 
                                            parentPayments.get(objPay.Parent_Account__c) : new List<Payment__c>();
            paymentList.add(objPay);
            parentPayments.put(objPay.Parent_Account__c,paymentList);
        }
        return parentPayments;
    }

    // get if there is any pending credit memo available with the customer account
    private static Map<String,List<Credit_Memo__c>> getParentCreditMemo(Set<String> setOfParentIds, Date lastDate){
        Map<String,List<Credit_Memo__c>>  parentCreditMemos = new Map<String,List<Credit_Memo__c>>();
        String query = generateCreditMemoQuery(setOfParentIds,lastDate);
        for(Credit_Memo__c objPay : Database.query(query)){
            List<Credit_Memo__c> listOfCreditMemos = parentCreditMemos.containsKey(objPay.Parent_Account__c) ? 
                                                    parentCreditMemos.get(objPay.Parent_Account__c) : new List<Credit_Memo__c>();
            listOfCreditMemos.add(objPay);
            parentCreditMemos.put(objPay.Parent_Account__c,listOfCreditMemos);
        }
        return parentCreditMemos;
    }

// get  pending credit memo available with the customer account
     private static string generateCreditMemoQuery(Set<String> setOfParentIds, Date lastDate){
        String pendingStatus = ConstantsClass.creditMemoPendingStatus;
        String query = 'SELECT From_Invoice__c, Parent_Account__c, Organisations_Name__c, Comments__c, Currency_Code__c, Total_Amount__c, Payment_Method__c, Invoice_Number__c, ';
        query+= ' Credit_Memo_Date__c, Status__c, Refund_ID__c, Stripe_Payout_Id__c, Stripe_Fee__c, Cheque_Date__c, Cheque_No__c, Bank_Name__c, NETS_Code__c, Amount_Exl_tax_Rollup__c, ';
        query+= ' (SELECT Transaction_ID__c, Credit_Memo_Number__c, Enrolment__c, Amount__c, Netsuite_GST_Code__c, Tax_Amount__c, Month__c, Remarks__c, Package__c, Is_Deposit__c, Is_Discount__c, ';
        query+= '  Invoice_Line_Item__c, Package_Name__c, Netsuite_Product_Name__c, Name, Id FROM Credit_memo_line_items__r order by Amount__c Desc),';
        query+= ' Tax_Amount_Rollup__c, Center__c, Netsuite_Payment_Method__c, Id, Name FROM Credit_Memo__c ';
        query+= ' WHERE Status__c =\''+pendingStatus +'\'';
        query+= ' AND Credit_Memo_Date__c <=:lastDate';
        query+= ' AND Parent_Account__c IN :setOfParentIds order by Total_Amount__c Desc';
       //system.debug('Query '+query);
        return query;
    }

     // this method is used for filling sum of Credit memo of parent
     private static Map<String,Decimal> getParentCreditMemoMap(Map<String,List<Credit_Memo__c>> mapOfCreditMemos){
        Map<String,Decimal> parentWithCreditMemos = new Map<String,Decimal>();
        for(String parentId : mapOfCreditMemos.keySet()){
            for(Credit_Memo__c objCreditMemos : mapOfCreditMemos.get(parentId)){
                Decimal total = parentWithCreditMemos.containsKey(parentId) ? parentWithCreditMemos.get(parentId) : 0;
                total+= objCreditMemos.Total_Amount__c;
                parentWithCreditMemos.put(parentId,total);
            }     
        }
        return parentWithCreditMemos;
    }

    // this method is used for filling sum of payment of parent
    private static Map<String,Decimal> getParentPaymentMap(Map<String,List<Payment__c>> mapOfPayments){
        Map<String,Decimal> parentWithPayment = new Map<String,Decimal>();
        for(String parentId : mapOfPayments.keySet()){
            for(Payment__c payment : mapOfPayments.get(parentId)){
                Decimal total = parentWithPayment.containsKey(parentId) ? parentWithPayment.get(parentId) : 0;
                total+= payment.Payment_Amount__c;
                parentWithPayment.put(parentId,total);
            }     
        }
        return parentWithPayment;
    }

    //get Total of Parent Invoices...
    /*private static Map<String, Decimal> getParentInvoiceTotalMap(Map<String, List<Invoice__c>> mapOfParentInvoice){
        Map<String, Decimal> mapOfParentTotal = new  Map<String, Decimal>();
        for(String parentId : mapOfParentInvoice.keySet()){
            for(Invoice__c invoice : mapOfParentInvoice.get(parentId)){
                Decimal total = mapOfParentTotal.containsKey(parentId) ? mapOfParentTotal.get(parentId) : 0;
                total+= invoice.Total_Amount__c;
                mapOfParentTotal.put(parentId,total);
            }     
        }
        return mapOfParentTotal;
    }*/

    private static string generatePaymentQuery(Set<String> setOfParentIds, string type,Date firstDate,Date lastDate){
        String pendingStatus = ConstantsClass.paymentPendingStatus;
        String query = 'SELECT Id,Payment_Amount__c,Parent_Account__c,Transaction_Id__c,Payment_Date__c,last_lesson_Date__c,RecordTypeId FROM Payment__c';
        query+= ' WHERE Payment_Status__c =\''+pendingStatus +'\'';
        if(type == 'creditNote'){
            query+= ' AND RecordType.Name =\''+ConstantsClass.creditNoteRecType+'\'';
        }else if(type == 'deposit'){
            query+= ' AND ( RecordType.Name =\''+ConstantsClass.paymentAsDepositRecordType+'\'';
            query+= ' or RecordType.Name =\''+ConstantsClass.paymentAsCredit+'\' )';
            query+= ' AND Payment_Date__c <=:lastDate';
        }
        query+= ' AND Parent_Account__c IN :setOfParentIds order by Payment_Amount__c Desc';
       //system.debug('Query '+query);
        return query;
    }
    
    //@Juneid 19 Aug 2020, Organization wise stripe Caluclation
    public static Map<String,Organisation__c> getOrganisationMap(String orgId){
        if(String.isNotBlank(orgId)){
            return new Map<String,Organisation__c>([SELECT Id, Name, Stripe_Secret_Key__c, Stripe_Publishable_Key__c, Stripe_Base_Url__c,country__r.Currency_Code__c,
                                                    Tax_Rate__c,Student_Policies_Template_Id__c, Folder__c 
                                               FROM Organisation__c 
                                               WHERE Id=:orgId AND Stripe_Secret_Key__c!= NULL AND Stripe_Base_Url__c != NULL]);
        }else{
            return new Map<String,Organisation__c>([SELECT Id, Name, Stripe_Secret_Key__c, Stripe_Publishable_Key__c, Stripe_Base_Url__c,country__r.Currency_Code__c,
                                                    Tax_Rate__c,Student_Policies_Template_Id__c, Folder__c 
                                               FROM Organisation__c 
                                               WHERE Stripe_Secret_Key__c!= NULL AND Stripe_Base_Url__c != NULL ]);
        }                                     
    }
    public class RollupCreditMins{
        public string parentId;
        public string available_Make_up_mins_For_Group;
        public string vailable_Make_up_mins;
        
    }
    public class StripeCustomer{
        Public Integer created;
        Public Integer account_balance;
        Public String description;
        Public StripeError error;
        Public Boolean livemode;
        public String default_source;
        Public String token;
        Public String id;
        Public Map<String, String> metadata;
        
        Public CardList cards;
        Public String default_card;
        public integer statusCode;
        public cls_sources sources;
    }
    public class cls_sources {
        public cls_data[] stripeData;
        public boolean has_more;
        public Integer total_count; //1
        public String url;  ///v1/customers/cus_EuGxgjwNxGcLDd/sources
    }
    public class cls_data {
        public String id;   //card_1EQSP8Jja9IPifcSD7uJtvTz
        public String brand;    //Visa
        public String country;  //US
        public String customer; //cus_EuGxgjwNxGcLDd
        public String cvc_check;    //pass
        public Integer exp_month;   //4
        public Integer exp_year;    //2024
        public String fingerprint;  //DodUMgRQg0xbj77T
        public String funding;  //credit
        public String last4;    //4242
    }
    
    Public class CardList {
        Public Integer count;
        Public String url;
        Public List<StripeCard> stripeData;
    }
    
    public class StripeCard{
        Public String stripeType;
        Public String country;
        Public Integer exp_month;
        Public String fingerprint;
        Public Integer exp_year;
        Public String last4;
        Public String stripeObject;
        Public String id;
        Public String name;
        public String brand;
        Public StripeError error;
        Public String customer_id;
        public Integer statusCode;
    }
    
    Public class StripeError {
        public String charge; //@28-02-2019 store chargeId when we make charges By Sanjay bhati
        Public String stripeType;
        Public String param;
        Public String message;
        Public String code;
        public String decline_code;
    }
    
    public class StripeCharge{
        Public Integer amount;
        Public Integer created;
        Public String stripeCurrency;
        Public String customer_id;
        Public StripeCustomer customer;
        Public String description;
        Public Boolean disputed;
        Public Integer fee;
        Public String id;
        Public Boolean livemode;
        Public String stripeObject;
        Public Boolean paid;
        Public Boolean refunded;
        Public Integer amount_refunded;
        Public StripeCard card;
        Public StripeError error;
        Public String invoice_id;
        Public String failure_message;
        Public Map<String, String> metadata;
        public integer statusCode;
    }
    
    public class StripeRefund{
        Public String id;
        Public Integer amount;
        public String balance_transaction;
        public String charge;
        Public Integer created;
        Public String stripeCurrency;
        Public Map<String, String> metadata;
        public String status;
        Public StripeError error;
        public integer statusCode;
    }
}