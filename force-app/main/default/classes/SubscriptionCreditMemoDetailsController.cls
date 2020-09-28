Public without sharing class SubscriptionCreditMemoDetailsController{
    public Credit_Memo__c creditMemo{get;set;}
    public centerInfo center {get;set;}
    public Invoice__c invoice {get;set;}
    public String invoiceNo{get;set;}
    public Invoice__c frominvoice {get;set;}
    public String frominvoiceNo{get;set;}
    //By Ravi
    public String InvoiceStatus{get;set;}
    Public string customLabelValue{get;set;}
    Public String InvoiceId{get;set;}
    public boolean displayUpdate{get;set;}
    public boolean isOssia{get;set;}
    public string ParentAccId{get;set;}
    public Decimal subTotal{get;set;}
    public Decimal discountAmount{get;set;}
    public Decimal totalAmount{get;set;}
    //By Ravi
    public SubscriptionCreditMemoDetailsController(){
        String paymentAsDeposit = ConstantsClass.paymentAsDepositRecordType;
        creditMemo = new Credit_Memo__c();
        center = new centerInfo();
        invoiceNo = '';
        isOssia = false;
        subTotal=0;
        totalAmount =0;
        string invId = Apexpages.currentPage().getParameters().get('Id');
        // string invId ='a1k1m000001dpW1AAI';// for temp used
        system.debug('@@invId'+invId);
        
        List<Credit_Memo__c> creditMemoList = [SELECT From_Invoice__c, Field_1__c, Parent_Account__c, Organisations_Name__c, Comments__c, Currency_Code__c, Total_Amount__c, Payment_Method__c,Invoice_Number__c, Credit_Memo_Date__c, Status__c, Refund_ID__c, Stripe_Payout_Id__c, Stripe_Fee__c, Cheque_Date__c, Cheque_No__c, Bank_Name__c, NETS_Code__c, Amount_Exl_tax_Rollup__c, Tax_Amount_Rollup__c, Center__c, Netsuite_Payment_Method__c, Id, Name,
                                               (SELECT Transaction_ID__c, Credit_Memo_Number__c, Enrolment__c, Amount__c, Netsuite_GST_Code__c, Tax_Amount__c,Enrolment__r.Teacher__r.Name,
                                                Enrolment__r.Student__r.Name,Package__r.Type__c,
                                                Month__c, Remarks__c, Package__c, Is_Deposit__c, Is_Discount__c, Field_1__c, Invoice_Line_Item__c, Package_Name__c, Netsuite_Product_Name__c, Name, Id 
                                                FROM Credit_memo_line_items__r ORDER BY Month__c Asc), Center__r.Organisation__r.Name,
                                               Parent_Account__r.Card_Number__c,Parent_Account__r.Name, Parent_Account__r.Admin_Fees__c, 
                                               Parent_Account__r.Billingstreet,Parent_Account__r.BillingCity,Parent_Account__r.BillingState,Parent_Account__r.personEmail,
                                               Parent_Account__r.personMobilePhone,Parent_Account__r.BillingPostalcode,Parent_Account__r.BillingCountry,
                                               Center__r.Name,Center__r.PersonEmail,Center__r.PersonMobilePhone,Center__r.Billingstreet,Center__r.BillingCity,
                                               Center__r.BillingState,Center__r.BillingPostalcode,Center__r.GST_Number__c, Center__r.Phone, Center__r.Center_Email__c, Center__r.Website,
                                               Center__r.country__r.Id,Center__r.Organisation__r.Tax_Rate__c, Center__r.country__r.Tax_Rate__c,
                                               Invoice_Number__r.Status__c,Invoice_Number__r.Name,Invoice_Number__r.createdDate,createdDate,
                                               From_Invoice__r.Status__c,From_Invoice__r.Name,From_Invoice__r.createdDate
                                               FROM Credit_Memo__c  
                                               WHERE id=:invId Limit 1 ];
        system.debug('creditMemoList--->'+creditMemoList);
        if(creditMemoList.size()>0){
            
            creditMemo = creditMemoList[0];
            // added by nishi: 18-Aug-2020: for show Ossia Logo
            if(String.isNotBlank(creditMemoList[0].Center__c) && 
               String.isNotBlank(creditMemoList[0].Center__r.Organisation__c) && 
               String.isNotBlank(creditMemoList[0].Center__r.Organisation__r.Name) && 
               creditMemoList[0].Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                   isOssia= true;  
               }
            discountAmount =0;
            subTotal =0;
            if(creditMemo.Credit_memo_line_items__r != null && creditMemo.Credit_memo_line_items__r.size() > 0){
                for(Credit_memo_line_item__c objlineitem : creditMemo.Credit_memo_line_items__r){
                    if(objlineitem.Is_Discount__c){
                        discountAmount+=objlineitem.Amount__c;   
                    }else{
                        subTotal+=objlineitem.Amount__c;
                    }
                    
                }
            }
            if(discountAmount != 0){
                discountAmount = BillingUtility.roundOffAmount(discountAmount);
            }
            if(subTotal != 0){
                subTotal = BillingUtility.roundOffAmount(subTotal);
            }
            
            // By Ravi
            ParentAccId= creditMemo.Parent_Account__c;
            if(String.isNotBlank(creditMemo.Status__c))
                InvoiceStatus = creditMemo.Status__c;
            InvoiceId=creditMemo.Id;
            customLabelValue = System.Label.Aureus_Site;
            if(String.isNotBlank(creditMemo.Parent_Account__r.Card_Number__c))
                displayUpdate = true;
            else
                displayUpdate = false;
            // By Ravi
            if(String.isNotBlank(creditMemo.Center__r.Name))
                center.name = creditMemo.Center__r.Name;
            if(creditMemo.Center__r.Phone != null){
                center.phone = creditMemo.Center__r.Phone;
            }   
            if(creditMemo.Center__r.Center_Email__c != null){
                center.email = creditMemo.Center__r.Center_Email__c;
            }  
            if(creditMemo.Center__r.Website != null){
                center.website  = creditMemo.Center__r.Website;
            }
            center.address = creditMemo.Center__r.Billingstreet != null? creditMemo.Center__r.Billingstreet:'';
            center.address += creditMemo.Center__r.BillingCity != null ? ' '+creditMemo.Center__r.BillingCity : '';
            center.address += creditMemo.Center__r.BillingState != null ? ' '+creditMemo.Center__r.BillingState : '';
            center.address += creditMemo.Center__r.BillingPostalcode != null ? ' '+creditMemo.Center__r.BillingPostalcode : '';
            invoice = creditMemo.Invoice_Number__r;
            if(String.isNotBlank(creditMemo.Invoice_Number__c)){
                invoiceNo = creditMemo.Invoice_Number__r.Name;
            }
            frominvoice = creditMemo.From_Invoice__r;
            if(String.isNotBlank(creditMemo.From_Invoice__c)){
                frominvoiceNo = creditMemo.From_Invoice__r.Name;
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