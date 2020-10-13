Public without sharing class SubscriptionInvoicePDFControllerClone{
    public Invoice__c invoice{get;set;}
    public centerInfo center {get;set;}
    public Payment__c payment {get;set;}
    public String paymentNo{get;set;}
    //By Ravi
    public String InvoiceStatus{get;set;}
    Public string customLabelValue{get;set;}
    Public String InvoiceId{get;set;}
    public boolean displayUpdate{get;set;}
    public boolean isOssia{get;set;}
    public string ParentAccId{get;set;}
    public Decimal subTotal{get;set;}
    public Decimal totalAmount{get;set;}
    public Decimal payableAmount{get;set;}
    public boolean isPartial{get;set;}
    public boolean isShowCreditMemo{get;set;}
    //By Ravi
    public SubscriptionInvoicePDFControllerClone(){
        String paymentAsDeposit = ConstantsClass.paymentAsDepositRecordType;
        invoice = new Invoice__c();
        center = new centerInfo();
        paymentNo = '';
        isOssia = false;
        isShowCreditMemo= false;
        isPartial = true;
        subTotal=0;
        totalAmount =0;
        payableAmount=0;
        string invId = Apexpages.currentPage().getParameters().get('Id');
        system.debug('@@invId'+invId);
        List<Invoice__c> invList = [Select Id,Name,Due_Date__c,Parent_Account__r.Card_Number__c,GST_Tax__c,GST_Tax_Amount__c,Invoice_Date__c,Parent_Account__c, Admin_Fees__c, 
                                    New_GST_Amount_Admin_Fee__c,
                                    Center__r.Organisation__r.Name ,//added by nishi :18_aug:2020  for show Ossia Logo4
                                    Discount_LineItem_Amount__c,Gross_Total__c,Deposit__c,Total_Discount__c,Credit_Memo_Amount__c,Total_Payable__c, // added by nishi: 15-Sep-2020: for change Invoice Ui show subtotal,discount
                                    Card_Number__c,Card_Image__c,Parent_Account__r.Name, Parent_Account__r.Admin_Fees__c, 
                                    Parent_Account__r.Billingstreet,Parent_Account__r.BillingCity,Parent_Account__r.BillingState,Parent_Account__r.personEmail,
                                    Parent_Account__r.personMobilePhone,createdDate,Remarks__c ,CM_Created__c,
                                    Parent_Account__r.BillingPostalcode,Parent_Account__r.BillingCountry,Status__c,Sub_Total__c,Subscription__c,
                                    Total_Amount__c,Discount_Amount__c ,Stripe_Charge_Id__c,Paid_Amount__c,Balance_Amount__c,
                                    Center__r.Name,Center__r.PersonEmail,Center__r.PersonMobilePhone,Center__r.Billingstreet,Center__r.BillingCity,
                                    Center__r.BillingState,Center__r.BillingPostalcode,Center__r.GST_Number__c, Center__r.Phone, Center__r.Center_Email__c, Center__r.Website,
                                    Center__r.country__r.Id,Center__r.Organisation__r.Tax_Rate__c, Center__r.country__r.Tax_Rate__c, New_GST_Amount__c, Internal_Ref_No__c,
                                        (Select Id,Amount__c, is_Deposit__c,Subscription_Line_Item__c,Package_Name__c,Remarks__c,Opportunity__c,Student__c,
                                        Subscription_Line_Item__r.Student__r.Name,Subscription_Line_Item__r.Plan_Package__r.Location__r.Name,
                                        Subscription_Line_Item__r.Enrolment__r.Teacher__r.Name,Month__c, Package__r.Type__c ,Is_Discount__c 
                                         from Invoice_Line_Items__r 
                                         ORDER BY Month__c Asc), 
                                        (Select Id,Name,Payment_Status__c,createdDate,Payment_Amount__c, RecordType.Name From Payments__r)
                                    FROM Invoice__c 
                                    WHERE Id=:invId LIMIT 1];  
                                     system.debug('@@@pdf invList'+invList);  
        if(invList.size()>0){

            invoice = invList[0];
            // added by nishi: 18-Aug-2020: for show Ossia Logo
            if(String.isNotBlank(invList[0].Center__c) && 
            String.isNotBlank(invList[0].Center__r.Organisation__c) && 
            String.isNotBlank(invList[0].Center__r.Organisation__r.Name) && 
            invList[0].Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssia= true;  
            }
            // added by nishi: 18-Aug-2020: for show Ossia Logo
            if(invoice.CM_Created__c != null && invoice.CM_Created__c >= 0){
                isShowCreditMemo= true;
            }
            if(invoice.CM_Created__c == invoice.Total_Payable__c){
                isPartial = false;
            }
            //nishi: 15-Sep-2020: for new requirement in netsuite we adjust discount as a line item 
            if(invoice.Gross_Total__c != null && invoice.Gross_Total__c !=0){
                subTotal+=invoice.Gross_Total__c;
                totalAmount+=invoice.Gross_Total__c;
            }
            if(invoice.Deposit__c != null && invoice.Deposit__c != 0){
                subTotal+=invoice.Deposit__c;
                totalAmount+=invoice.Deposit__c;
            }
            if(invoice.Total_Discount__c != null && invoice.Total_Discount__c != 0){
                subTotal+=invoice.Total_Discount__c;
            }
            if(subTotal == totalAmount){
                subTotal =0;
            }
            if(subTotal != 0){
                subTotal = BillingUtility.roundOffAmount(subTotal);
            }
            if(totalAmount != 0){
                totalAmount = BillingUtility.roundOffAmount(totalAmount);
            }
            //end:nishi: 15-Sep-2020: for new requirement in netsuite we adjust discount as a line item 

            //15-Sep-2020:start: Credit Memo  handling we show Credit_Memo_Amount__c amount after showing  payableAmount (grand total duction amount)
            if(invoice.Credit_Memo_Amount__c != null &&invoice.Credit_Memo_Amount__c != 0 ){
               /* if(invoice.Total_Amount__c != null && invoice.Total_Amount__c  != 0){
                    payableAmount=invoice.Total_Amount__c;
                }
                payableAmount-=invoice.Credit_Memo_Amount__c;
                */
                payableAmount=invoice.Total_Payable__c;
                
                if(payableAmount != 0){
                    payableAmount = BillingUtility.roundOffAmount(payableAmount);
                }
            }else{
                payableAmount =0;
            }
            //15-Sep-2020:end: Credit Memo  handling we show Credit_Memo_Amount__c amount after showing  payableAmount (grand total duction amount)
          

            system.debug('@@@pdf invoice'+invoice);
             system.debug('@@@pdf invoice amount'+invoice.Invoice_Line_Items__r);
            system.debug('@@@pdf invoice amount'+invoice.Total_Amount__c);
            // By Ravi
            ParentAccId= invoice.Parent_Account__c;
            if(String.isNotBlank(invoice.Status__c))
                InvoiceStatus = invoice.Status__c;
            	InvoiceId=invoice.Id;
            	customLabelValue = System.Label.Aureus_Site;
            if(String.isNotBlank(invoice.Parent_Account__r.Card_Number__c))
            	displayUpdate = true;
            else
                displayUpdate = false;
            // By Ravi
            System.debug('invoice'+invoice.center__r.country__r);
            //system.debug('invoices'+invoice.Invoice_Line_Items__r);
            if(String.isNotBlank(invoice.Center__r.Name))
                center.name = invoice.Center__r.Name;
            if(invoice.Center__r.Phone != null){
                center.phone = invoice.Center__r.Phone;
            }   
            if(invoice.Center__r.Center_Email__c != null){
                center.email = invoice.Center__r.Center_Email__c;
            }  
            if(invoice.Center__r.Website != null){
                center.website  = invoice.Center__r.Website;
            }
            center.address = invoice.Center__r.Billingstreet != null? invoice.Center__r.Billingstreet:'';
            center.address += invoice.Center__r.BillingCity != null ? ' '+invoice.Center__r.BillingCity : '';
            center.address += invoice.Center__r.BillingState != null ? ' '+invoice.Center__r.BillingState : '';
            center.address += invoice.Center__r.BillingPostalcode != null ? ' '+invoice.Center__r.BillingPostalcode : '';
            
            system.debug('@@invoice.payments__r'+invoice.payments__r);
            if(invoice.payments__r.size()>0){
                for(Payment__c paymentObj : invoice.payments__r){
                     if(paymentObj.Payment_Status__c == 'Success'){
                         payment = paymentObj;
                         break;
                     }
                     
                }
                for(Payment__c paymentObj : invoice.payments__r){
                      //if(paymentObj.RecordType.Name== paymentAsDeposit){
                          paymentNo = paymentNo + ', '+paymentObj.Name;
                      //}
                }
                if(String.isNotBlank(paymentNo)){
                    paymentNo = paymentNo.removeStart(',');

                }
            }
        }
    }
    public class centerInfo{
        public string phone {get;set;}
        public string email {get;set;}
        public string name {get;set;}
        public string address {get;set;}
        public string website {get;set;}
    }
    
}