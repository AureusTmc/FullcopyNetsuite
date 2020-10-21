/*
*      Name        :    PaymentComponentController
*      Date        :    22 Aug 2020
*      Description :    This Controlleris used to manage Payment credit and use with paymentComponent.
*/
public class PaymentComponentController {
    
    
    //@Juneid 22 Aug 2020, Method for get the Ccredit amount of Parent
    /* Commented by nishi: 15-oct-2020: for get more values in one time
    @AuraEnabled
    public static Decimal getCurrentCredit(String recordId){
        if(String.isNotBlank(recordId)){
            List<Invoice__c> invoiceList = [SELECT Id, Total_Amount__c,Parent_Account__c,Parent_Account__r.Total_Payment_Credit_Available__c,
                                            Total_Invoice_Amount__c,Center__r.Organisation__r.Name FROM Invoice__c WHERE Id =:recordId];
            if(!invoiceList.isEmpty()){
               return invoiceList[0].Parent_Account__r.Total_Payment_Credit_Available__c;
            }
            return 0;
        }
        return 0;
    } */ 
    // added by nishi:  15-Oct-2020: we get credit memo amount and invoice total amount and invoice organisation
    @AuraEnabled
    public static invoiceWrapper getCurrentCredit(String recordId){
        if(String.isNotBlank(recordId)){
            List<Invoice__c> invoiceList = [SELECT Id,Status__c, Balance_Amount__c,Parent_Account__c,Parent_Account__r.Total_Payment_Credit_Available__c,Parent_Account__r.Total_Credit_Memo_Available__c ,
                                            Total_Invoice_Amount__c,Center__r.Organisation__r.Name FROM Invoice__c WHERE Id =:recordId];
            if(!invoiceList.isEmpty()){
                Invoice__c invoice =invoiceList[0];
                boolean isOssia = false;
                if(string.isNotBlank(invoiceList[0].Center__c) && string.isNotBlank(invoiceList[0].Center__r.Organisation__c)&&
                    string.isNotBlank(invoiceList[0].Center__r.Organisation__r.Name) 
                    && invoiceList[0].Center__r.Organisation__r.Name ==System.Label.Ossia_Organisation_Name ){
                    isOssia=true;
                }
                return new invoiceWrapper(invoiceList[0].Parent_Account__r.Total_Credit_Memo_Available__c,invoiceList[0].Balance_Amount__c,isOssia);
            }
            return new invoiceWrapper();
        }
        return new invoiceWrapper();
    }
    
    public class invoiceWrapper{
        @AuraEnabled  public decimal currentCreditAmount; 
        @AuraEnabled public decimal totalinvoiceAmount;
        @AuraEnabled public boolean isOssia;
        @AuraEnabled public Integer errorCode;
        @AuraEnabled public string errormessage;
        public invoiceWrapper(decimal currentCreditAmount,decimal totalinvoiceAmount, boolean isOssia){
            this.currentCreditAmount =currentCreditAmount != null ?currentCreditAmount :0;
            this.totalinvoiceAmount =totalinvoiceAmount != null ?totalinvoiceAmount :0 ;
            this.isOssia = isOssia;
            this.errorCode = 200;
        }
        public invoiceWrapper(){
            this.currentCreditAmount =0;
            this.totalinvoiceAmount =0 ;
            this.isOssia = false;
            this.errorCode = 400;
        }
        public invoiceWrapper(Integer errorCode,string errormessage){
            this.errormessage =errormessage;
            this.errorCode =errorCode ;
        }
    }
      // added by nishi:  15-Oct-2020:end: we get credit memo amount and invoice total amount and invoice organisation
    
   /* Commented by nishi: 15-oct-2020: for get more values in one time
   @AuraEnabled
    public static boolean getIsOssia(String recordId){
        boolean isOssia = false;
        if(String.isNotBlank(recordId)){
            List<Invoice__c> invoiceList = [SELECT Id, Center__r.Organisation__r.Name FROM Invoice__c WHERE Id =:recordId];
            if(!invoiceList.isEmpty())
                if(string.isNotBlank(invoiceList[0].Center__c) && string.isNotBlank(invoiceList[0].Center__r.Organisation__c)&&
                   string.isNotBlank(invoiceList[0].Center__r.Organisation__r.Name) 
                   && invoiceList[0].Center__r.Organisation__r.Name ==System.Label.Ossia_Organisation_Name )
                isOssia=true;
            
            return isOssia;
        }
        return isOssia;
        
    }    */
    //@Juneid 21 Aug 2020, This method is used to manage Payment as credit calculation on invoice
    @AuraEnabled
    public static invoiceWrapper  createPayment( String selectedMethod, String recordId, String transacId, Boolean isCreditAmnt, Decimal currentCreditAmounts){
        system.debug('method call-->'+selectedMethod+ recordId+transacId);
        if( String.isNotBlank(selectedMethod) && String.isNotBlank(recordId) && String.isNotBlank(transacId)){
            try{  
                List<Payment__c> paymentsToUpsert  = new List<Payment__c>();//To update and create paymet of crdit
                //Getting recordtype Id
                String payCredRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
                String paySuccesRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
                
                //Fetching current invoice Values
                List<Invoice__c> invoiceList = new List<Invoice__c>();
                Map<String, Date> mapOfParentEnrolmentLastDate = new Map<String, Date>();
                for(Invoice__c invoiceObj : [SELECT Id, Name,Parent_Account__c,Total_Amount__c, Remarks__c,Invoice_Date__c,Parent_Account__r.Centre_Name__c,
                                                Center__r.Country__r.Tax_Rate__c,Credit_Memo_Amount__c,Balance_Amount__c,
                                                Parent_Account__r.Total_Payment_Credit_Available__c,
                                                Total_Invoice_Amount__c,Status__c,Parent_Account__r.Total_Credit_Memo_Available__c,
                                                (SELECT Id, Enrolment__r.id,Enrolment__r.Package_Process_Type__c ,
                                                    Enrolment__r.Effective_Date__c ,Package__c
                                                    FROM Invoice_Line_Items__r) 
                                                FROM Invoice__c 
                                            WHERE Id =: recordId]){
                                                invoiceList.add(invoiceObj);
                    for(Invoice_Line_Item__c  lineItemObj : invoiceObj.Invoice_Line_Items__r){
                        if(mapOfParentEnrolmentLastDate.containsKey(invoiceObj.Parent_Account__c) && 
                            mapOfParentEnrolmentLastDate.get(invoiceObj.Parent_Account__c) < lineItemObj.Enrolment__r.Effective_Date__c){
                            mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                        }else if(String.isNotBlank(lineItemObj.Enrolment__c) && lineItemObj.Enrolment__r.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType 
                                && lineItemObj.Enrolment__r.Effective_Date__c != NULL){
                            mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                        }
                    }
                }                                            
                system.debug('invoiceList--->'+invoiceList);
                if(invoiceList.size() > 0 ){
                    payment__c objpayment = new payment__c();
                    Invoice__c invoice = invoiceList[0];
                    List<Credit_Memo__c> creditMemosToUpsert  = new List<Credit_Memo__c>();//To update and create paymet of crdit
                    Map<String, Credit_Memo__c> mapOfCreditMemos = new Map<String, Credit_Memo__c>();
                    Decimal accumulatedCreditMemoAmount = invoice.Parent_Account__r.Total_Credit_Memo_Available__c != null ?invoice.Parent_Account__r.Total_Credit_Memo_Available__c : 0;
                            
                    if(accumulatedCreditMemoAmount != null && accumulatedCreditMemoAmount > 0){
                        Decimal invoiceTotalAmount = invoice.Balance_Amount__c; 
                        Decimal diffrenceAmount = 0;
                        if(isCreditAmnt){
                            List<Credit_Memo__c> listOfCreditMemos  =generateCreditMemoQuery( new Set<String>{invoice.Parent_Account__c});
                            if(listOfCreditMemos != null && listOfCreditMemos.size()>0){
                                Date lastDate = listOfCreditMemos[0].Credit_Memo_Date__c;
                                Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo = BillingUtility.getParentCreditMemo(new Set<String>{invoice.Parent_Account__c},lastDate);
                                BillingUtility.adjustPendingCreditMemoDeposit(invoiceList, new Set<String>{invoice.id}, new Set<String>{invoice.Parent_Account__c},mapOfParentEnrolmentLastDate,false,mapOfParentCreditMemo);
                                if(accumulatedCreditMemoAmount<invoiceTotalAmount){
                                    diffrenceAmount =  invoiceList[0].Balance_Amount__c - accumulatedCreditMemoAmount;
                                }
                                if(diffrenceAmount >0){
                                    //Create new payment credit for remaning amount
                                    objpayment = createpaymentrecord(diffrenceAmount,selectedMethod,invoiceList[0].Id,transacId,paySuccesRecId,invoiceList[0].Parent_Account__c);
                                    paymentsToUpsert.add(objpayment); 
                                    invoiceList[0].Status__c ='Paid';  
                                }
                            }else{
                                return new invoiceWrapper(400,'Pending Credit Memo Record Not Found');
                            }
                        }else{//If customer dont want to pay with credit amount 
                            objpayment = createpaymentrecord(invoiceList[0].Balance_Amount__c,selectedMethod,invoiceList[0].Id,transacId,paySuccesRecId,invoiceList[0].Parent_Account__c);
                            paymentsToUpsert.add(objpayment);
                            invoiceList[0].Status__c ='Paid';
                        }
                    }
                    // for if payment is credit record not found then we insert new payment record with full amount
                    else{
                        objpayment = createpaymentrecord(invoiceList[0].Balance_Amount__c,selectedMethod,invoiceList[0].Id,transacId,paySuccesRecId,invoiceList[0].Parent_Account__c);
                        paymentsToUpsert.add(objpayment);
                        invoiceList[0].Status__c ='Paid';
                    }
                    if(creditMemosToUpsert.size()> 0 ){
                        upsert creditMemosToUpsert;
                    }
                    if(paymentsToUpsert.size() > 0)
                        UPSERT paymentsToUpsert;
                    if(invoiceList.size() > 0)
                        update  invoiceList[0];
                    system.debug('paymentsToUpsert-->'+paymentsToUpsert);
                    
                system.debug('paymentsToUpsert-->'+paymentsToUpsert);
                }
            }catch(Exception e){
                system.debug('error'+e.getStackTraceString()+'-'+e.getMessage());
                return new invoiceWrapper(400,e.getMessage());
            }
            return new invoiceWrapper(200,'Paid Invoice Amount Sucessfully');
        }
        return new invoiceWrapper(400,'Some Internal Issue Found.');
    }
    

    public static Payment__c createpaymentrecord(decimal paymentamount,string selectedMethod,string invoiceId,string transacId,string paymentRecId,string parentAccountId){
        payment__c objpayment = new payment__c();
        objpayment.Payment_Amount__c = paymentamount;
        objpayment.Payment_Status__c = 'Success';
        objpayment.Method_of_Payment__c = selectedMethod;
        objpayment.Payment_Date__c = system.today();
        objpayment.Invoice__c = invoiceId;
        objpayment.Transaction_ID__c = transacId;
        objpayment.RecordTypeId =  paymentRecId;
        objpayment.Parent_Account__c = parentAccountId;
        return objpayment;
    }

    public static List<Credit_Memo__c> generateCreditMemoQuery(Set<String> setOfParentIds){
        String pendingStatus = ConstantsClass.creditMemoPendingStatus;
        String query = 'SELECT From_Invoice__c, Parent_Account__c, Organisations_Name__c, Comments__c, Currency_Code__c, Total_Amount__c, Payment_Method__c, Invoice_Number__c, ';
        query+= ' Credit_Memo_Date__c, Status__c, Refund_ID__c, Stripe_Payout_Id__c, Stripe_Fee__c, Cheque_Date__c, Cheque_No__c, Bank_Name__c, NETS_Code__c, Amount_Exl_tax_Rollup__c, ';
        query+= ' (SELECT Transaction_ID__c, Credit_Memo_Number__c, Enrolment__c, Amount__c, Netsuite_GST_Code__c, Tax_Amount__c, Month__c, Remarks__c, Package__c, Is_Deposit__c, Is_Discount__c, ';
        query+= '  Invoice_Line_Item__c, Package_Name__c, Netsuite_Product_Name__c, Name, Id FROM Credit_memo_line_items__r order by Amount__c Desc),';
        query+= ' Tax_Amount_Rollup__c, Center__c, Netsuite_Payment_Method__c, Id, Name FROM Credit_Memo__c ';
        query+= ' WHERE Status__c =\''+pendingStatus +'\'';
        query+= ' AND Parent_Account__c IN :setOfParentIds And Credit_Memo_Date__c != null order by Credit_Memo_Date__c Desc';
       
        return Database.query(query);
    }
}
    
    /*//commented by nishi: 15-Oct-2020 : for new requirement we adjust pending credit memo not a pending payment amount
     //@Juneid 21 Aug 2020, This method is used to manage Payment as credit calculation on invoice
    @AuraEnabled
    public static void createPayment( String selectedMethod, String recordId, String transacId, Boolean isCreditAmnt, Decimal currentCreditAmounts){
        system.debug('method call-->'+selectedMethod+ recordId+transacId);
        if( String.isNotBlank(selectedMethod) && String.isNotBlank(recordId) && String.isNotBlank(transacId)){  
            List<Payment__c> paymentsToUpsert  = new List<Payment__c>();//To update and create paymet of crdit
            //Getting recordtype Id
            String payCredRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
            String paySuccesRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
            
            
            //Fetching current invoice Values
            List<Invoice__c> invoiceList = [SELECT Id, Total_Amount__c,Parent_Account__c,Parent_Account__r.Total_Payment_Credit_Available__c, Total_Invoice_Amount__c FROM Invoice__c WHERE Id =:recordId];
            system.debug('invoiceList--->'+invoiceList);
            if(invoiceList.size() > 0 ){
                for(Payment__c pay: [SELECT Id, Name, Parent_Account__c,Invoice__c, Payment_Amount__c, Payment_Status__c FROM Payment__c where  Parent_Account__c =:invoiceList[0].Parent_Account__c AND RecordType.Name = 'Payment As Credit' AND Payment_Status__c = 'Pending' AND Payment_Amount__c > 0 ORDER BY Payment_Amount__c]){
                    system.debug('pay---->'+pay);
                    if(isCreditAmnt){
                        system.debug('in credit amnt -->'+pay);
                        //Checking if Cutomer have full or more than amout of invoice 
                        if(invoiceList[0].Total_Amount__c <=invoiceList[0].Parent_Account__r.Total_Payment_Credit_Available__c){
                            system.debug('in if');
                            pay.Payment_Amount__c = invoiceList[0].Total_Amount__c;
                            pay.Payment_Status__c = 'Success';
                            pay.Method_of_Payment__c = selectedMethod;
                            pay.Payment_Date__c = system.today();
                            pay.Invoice__c = invoiceList[0].Id;
                            pay.Transaction_ID__c = transacId;
                            pay.RecordTypeId =  paySuccesRecId;
                            paymentsToUpsert.add(pay);
                            
                        }else{//If payment is less than invoice than manage payment
                            system.debug('in else');
                            Decimal diffrenceAmount =  invoiceList[0].Total_Amount__c - currentCreditAmounts;
                            //Decimal actualPayCredit = pay.Payment_Amount__c;
                            pay.Payment_Status__c = 'Success';
                            pay.Payment_Amount__c = currentCreditAmounts;
                            pay.Transaction_ID__c = transacId;
                            pay.RecordTypeId =  paySuccesRecId;
                             pay.Invoice__c = invoiceList[0].Id;
                            paymentsToUpsert.add(pay);   
                            
                            //Create new payment credit for remaning amount
                            Payment__c payCrd = new Payment__c();
                             pay.Invoice__c = invoiceList[0].Id;
                            payCrd.RecordTypeId = payCredRecId;
                            payCrd.Payment_Amount__c = diffrenceAmount;
                            payCrd.Payment_Status__c = 'Pending';
                            payCrd.Parent_Account__c = invoiceList[0].Parent_Account__c;
                            paymentsToUpsert.add(payCrd);  
                        }
                    }else{//If customer dont want to pay with credit amount 
                        pay.Payment_Amount__c = invoiceList[0].Total_Amount__c;
                        pay.Payment_Status__c = 'Success';
                        pay.Method_of_Payment__c = selectedMethod;
                        pay.Payment_Date__c = system.today();
                        pay.Invoice__c = invoiceList[0].Id;
                        pay.Transaction_ID__c = transacId;
                        pay.RecordTypeId =  paySuccesRecId;
                        paymentsToUpsert.add(pay);
                    }
                    if(paymentsToUpsert.size() > 0)
                        UPSERT paymentsToUpsert;
                    
                    system.debug('paymentsToUpsert-->'+paymentsToUpsert);
                }
            }
        }
    }
    */
