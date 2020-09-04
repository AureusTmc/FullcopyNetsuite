public class MakePaymentController{
    public String invoiceId {get;set;}
    public Decimal totalDue {get;set;}
    public Decimal totalTax {get;set;}
    public Decimal totalDeposite {get;set;}
    public Decimal totalAmount {get;set;}
    public Decimal subTotal {get;set;}
    public String apiKey {get;set;}
    public String customerId;
    public Static Invoice__c invoice;
    public List<Invoice_Line_Item__c> invLineItm{get;set;}
    public MakePaymentController(){
        totalDue = totalTax = totalDeposite = totalAmount = subTotal  = 0;
        
        invoice = new Invoice__c();
        invoiceId = apexpages.currentpage().getparameters().get('id');
        getInvoiceLineItemRecords(invoiceId);
        List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c,Stripe_Publishable_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
        if(stripeSettings.size()>0){
           apiKey = stripeSettings[0].Stripe_Publishable_Key__c;
        }
    }
    public void getInvoiceLineItemRecords(String invoiceId){
       invLineItm = new List<Invoice_Line_Item__c>([SELECT Id,Invoice__r.GST_Tax_Amount__c,Invoice__r.Total_Amount__c,Package__r.Name,
                        Invoice__r.Deposit__c, Package_Name__c, Amount__c,Invoice__r.Sub_Total__c
                        FROM Invoice_Line_Item__c 
                        WHERE Invoice__c =:invoiceId and Invoice__r.Status__c='Due']);
       if(invLineItm.size()>0){
           for(Invoice_Line_Item__c inItem : invLineItm){
               subTotal += inItem.Amount__c;
           }
           totalAmount = invLineItm[0].Invoice__r.Total_Amount__c;
           totalDeposite = invLineItm[0].Invoice__r.Deposit__c;
           totalDue = (invLineItm[0].Invoice__r.Total_Amount__c) + (invLineItm[0].Invoice__r.Deposit__c);
           totalTax = invLineItm[0].Invoice__r.GST_Tax_Amount__c;
           //subTotal = invLineItm[0].Invoice__r.Sub_Total__c;
       }
    }
    public static List<Invoice__c>  getInvoice(String invoiceId){
        return [Select Id,Name,Status__c,Due_Date__c,Deposit__c,Subscription__c,Total_Amount__c,Parent_Account__c,Parent_Account__r.Stripe_Customer_Id__c,
                Parent_Account__r.PersonContactId 
                FROM Invoice__c WHERE Id=:invoiceId];
    }
    @RemoteAction
    public static String sendInvoiceMail(String invoiceId){
        List<Invoice__c> invoiceList = getInvoice(invoiceId);
        //BillingUtility.emailInvoiceToParent(invoiceList);
        return 'Mail Sent';
    }
    @RemoteAction
    public static String createCharge(string token,String invoiceIdd){
        List<Invoice__c> invoiceList =  getInvoice(invoiceIdd);
        String last4;
        String brand;
        if(invoiceList.size()>0){
            Invoice__c objInvoice = invoiceList[0];
            String customerId = objInvoice.Parent_Account__r.Stripe_Customer_Id__c;
            Decimal amount =   objInvoice.total_Amount__c;  //Integer.valueOf((objInvoice.Total_Amount__c + invoiceList[0].Deposit__c).round(System.RoundingMode.CEILING));
            BillingUtility.StripeCard addCard = new BillingUtility.StripeCard();
            addCard = BillingUtility.AddCardWithCustomer(customerId,token);
            system.debug('addCard  >>'+addCard);
            if(addCard.error != null){
                return ''+addCard.error.message;
            }else if(addCard.statusCode == 200 && addCard.id != null && !String.isBlank(addCard.id)){
                BillingUtility.StripeCharge setDefault = new BillingUtility.StripeCharge();
                setDefault = BillingUtility.setDefaultCard(customerId,addCard.id);
                last4 = addCard.last4;
                brand = addCard.brand;
                //system.debug('setDefault >>'+setDefault );
                if(setDefault.error != null){
                    return ''+setDefault .error.message;
                }else if(setDefault.statusCode == 200 && setDefault.Id != null && !String.isBlank(setDefault.id)){
                    BillingUtility.StripeCharge createCharge = new BillingUtility.StripeCharge();
                    createCharge = BillingUtility.createChargeForCustomer(customerId,amount,ConstantsClass.currencyCode);
                    system.debug('createCharge >>'+createCharge );
                    if(createCharge.error != null){
                        return ''+createCharge.error.message;
                    }else if(createCharge.statusCode == 200 && createCharge.Id != null && !String.isBlank(createCharge.Id)){
                        Invoice__c objInv = invoiceList[0]; 
                        objInv.Status__c = ConstantsClass.paidStatus;
                        update objInv;
                        Payment__c objPayment = BillingUtility.fillPayment(objInv.Parent_Account__c,objInv.Id,objInv.Total_Amount__c,ConstantsClass.successStatus); 
                        objPayment.Transaction_ID__c = createCharge.Id;
                        insert objPayment;
                        
                        Account objAcc = new Account(Id = objInv.Parent_Account__c,Card_Number__c=last4,Card_Type__c=brand);
                        UPDATE objAcc;
                        
                        BillingUtility.updateCharge(createCharge.Id,invoiceList[0].Name);
                        
                        //INSERT BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,objInvoice.Total_Amount__c,ConstantsClass.successStatus);
                        
                        if(invoiceList.size()>0){
                            if(invoiceList[0].Subscription__c == null){
                                Set<Id> invoiceIdSet = new Set<Id>();
                                invoiceIdSet.add(invoiceList[0].Id);
                                MonthlyPaymentBatchHelper.updateFifthBookingStatus(invoiceIdSet);
                            }else{
                                //List<Enrolment__c> listOfEnrolment = MonthlyPaymentBatchHelper.getListOfEnrollments(invoiceList);
                                
                                //UPDATE MonthlyPaymentBatchHelper.getEnrolmentsToProccess(listOfEnrolment);
                                
                                //listOfEnrolment = MonthlyPaymentBatchHelper.getUpdatedEnrolment(listOfEnrolment);
                                
                                //MonthlyPaymentBatchHelper.changeThisMonthBookingStatus(listOfEnrolment);
                                //MonthlyPaymentBatchHelper.createNextAppointments(listOfEnrolment);
                            }
                        }
                        return 'Payment Success';
                    }
                }
            }
        }
        return null;
    }
}