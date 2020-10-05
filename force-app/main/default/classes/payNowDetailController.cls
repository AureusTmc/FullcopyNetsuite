public class payNowDetailController {
    
    
    public Invoice__c InvObj{get;set;}
    public string InvId {get;set;}
    public string changePayment {get;set;}
    List<Stripe_Payment_Log__c> invoiceLogList {get;set;}
    Public List<Invoice__c> InvoicesListTOUpdate {get;set;}
    string paymentRecType {get;set;}
    public boolean displayPopup {get; set;} 
    public boolean displayPopupforDeclined {get; set;} 
    public boolean displayUpdateCard {get; set;} 
    public boolean isOssia {get; set;} 
    
    public  payNowDetailController() {
        isOssia= false;
        paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        InvId=ApexPages.currentPage().getParameters().get('id');
        InvObj= [Select Id,Status__c,Parent_Account__r.Card_Type__c,Parent_Account__r.Card_Image__c,Customer_Name__c,Parent_Account__r.Name,Parent_Account__c,Name,Balance_Amount__c,Parent_Account__r.Stripe_Customer_Id__c,Parent_Account__r.Card_Number__c, 
                 Center__r.Organisation__r.Name //added by nishi :5-Oct:2020  for show Ossia Logo image
                from Invoice__c where Id=:InvId];

         // added by nishi: 5-Oct:2020 for show Ossia Logo
         if(String.isNotBlank(InvObj.Center__c) && 
         String.isNotBlank(InvObj.Center__r.Organisation__c) && 
         String.isNotBlank(InvObj.Center__r.Organisation__r.Name) && 
         InvObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
             isOssia= true;  
         }
         // added by nishi: 5-Oct:2020 for show Ossia Logo

        changePayment = 'Charge credit card';
        displayPopup=false;
        displayPopupforDeclined=false;
        

    }
    
    public  void callPaymentGate(){
        List<Invoice__c> InvList  = new List<Invoice__c>();
        String payCreditRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId(); 
        List<Stripe_Payment_Log__c> invoiceLogList = new List<Stripe_Payment_Log__c>();
        set<Id> successinvoiceIdSet = new set<Id>();
        List<Payment__c> paymentListToCreate = new List<Payment__c>();
        map<string,Country__c> maptoCoutry=BillingUtility.getCountryMap('');
        map<string,Organisation__c> organisationMap=BillingUtility.getOrganisationMap('');
        // Added By Ravi on ... 21st july 2020 to send mail in case of failure
        list<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name 
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName ='Payment_Collection_Failed'];
        List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
         // End..Added By Ravi on ... 21st july 2020 to send mail in case of failure
        for(Invoice__c invObject:[Select Id,Customer_Name__c,Parent_Account__c,Center__r.Country__c,
                                  Center__r.Organisation__r.Name , //added  by nishi 5th Oct 2020,start: for get stripe information bases of the Organisation
                                  Name,Balance_Amount__c,Parent_Account__r.Stripe_Customer_Id__c,
                                  Parent_Account__r.Card_Number__c,Parent_Account__r.PersonContactId,Parent_Account__r.Centre_Name__r.Location__c
                                  from Invoice__c where Id=:InvId]){
            system.debug('== Inv Id from Class '+ invObject.id);
            
          Stripe_Payment_Log__c iLog = new Stripe_Payment_Log__c();
            try{
                Country__c countryObj = new Country__c();
                if(maptoCoutry.containsKey(invObject.Center__r.Country__c)){
                    countryObj = maptoCoutry.get(invObject.Center__r.Country__c);
                }
                 //added  by nishi 5th Oct 2020,start: for get stripe information bases of the Organisation
                 Organisation__c organisationObj = new Organisation__c();
                 if(organisationMap.containsKey(invObject.Center__r.Organisation__c)){
                    organisationObj = organisationMap.get(invObject.Center__r.Organisation__c);
                }
                //added  by nishi 5th Oct 2020,end: for get stripe information bases of the Organisation
                system.debug('invObject.Balance_Amount__c'+invObject.Balance_Amount__c);
                if(invObject.Balance_Amount__c >=0.30){
                    system.debug('InvObj.Parent_Account__r.Stripe_Customer_Id__c'+InvObj.Parent_Account__r.Stripe_Customer_Id__c +'InvObj.Balance_Amount__c'+InvObj.Balance_Amount__c +'ConstantsClass.currencyCode,'+ConstantsClass.currencyCode +'InvObj.Name'+InvObj.Name);
                    BillingUtility.StripeCharge objStripeCharge;
                    if(!test.isRunningTest()){
                         // updated currency code dynamically on 3rd Nov by Ravi....
                    	//objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(InvObj.Parent_Account__r.Stripe_Customer_Id__c,InvObj.Balance_Amount__c,ConstantsClass.currencyCode,InvObj.Name,countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c); 
                        // commented by nishi: 5-oct-2020:  for get stripe information bases of the Organisation
                        //	objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(InvObj.Parent_Account__r.Stripe_Customer_Id__c,InvObj.Balance_Amount__c,countryObj.Currency_Code__c,InvObj.Name,countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c); 
                        objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(InvObj.Parent_Account__r.Stripe_Customer_Id__c,InvObj.Balance_Amount__c,countryObj.Currency_Code__c,InvObj.Name,organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c); 
                    
                    }else{
                        BillingUtility.StripeCharge sc = new BillingUtility.StripeCharge();
                        sc.statusCode = 100;
                        sc.paid = true;
                        objStripeCharge = sc;
                    }
                    system.debug('====>'+objStripeCharge);
                    if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                        invObject.Status__c=ConstantsClass.paidStatus;
                        InvList.add(invObject);
                        
                        Payment__c objPayment = BillingUtility.fillPayment(invObject.Parent_Account__c,invObject.Id, invObject.Balance_Amount__c,
                                                                           ConstantsClass.successStatus); 
                        objPayment.Transaction_ID__c = objStripeCharge.Id;
                        objPayment.recordTypeId = paymentRecType;
                        objPayment.Method_of_Payment__c='Card';// Updated on card method on 10 Jan 2020
                        paymentListToCreate.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                        displayPopup=true;
                    }else{
                        if(objStripeCharge.error != null){
                            iLog.Status__c = 'Failure';
                            iLog.Invoice__c = invObject.Id;
                            iLog.Message__c = objStripeCharge.error.message;
                            iLog.Type__c = objStripeCharge.error.stripeType;
                            if(String.isNotBlank(objStripeCharge.error.charge))
                                iLog.ChargeId__c = objStripeCharge.error.charge;
                            if(String.isNotBlank(objStripeCharge.error.decline_code))
                                iLog.Code__c = objStripeCharge.error.decline_code;
                            displayPopupforDeclined=true;
                        }
                        invoiceLogList.add(iLog);
                        // Added By Ravi ..on 21st july 2020 to send email in case of payment failure
                        if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 ){
                            string centerId,personContactId;
                            if(invObject.Parent_Account__r != null && invObject.Parent_Account__r.Centre_Name__r != null &&
                               string.isNotBlank(invObject.Parent_Account__r.Centre_Name__r.Location__c) ){
                                   centerId = invObject.Parent_Account__r.Centre_Name__r.Location__c;
                               }
                            if(invObject.Parent_Account__r != null && string.isNotBlank(invObject.Parent_Account__r.PersonContactId)){
                                personContactId = invObject.Parent_Account__r.PersonContactId;
                            }
                            sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,invObject.id,centerId));
                        }
                            
							
                        // End.. Added By Ravi ..on 21st july 2020 to send email in case of payment failure
                    }    
                    
                }else if(invObject.Balance_Amount__c <= 0.30 && invObject.Balance_Amount__c >= 0){
                    invObject.status__c = ConstantsClass.paidStatus;
                    InvList.add(invObject);
                    
                    Payment__c objPayment = BillingUtility.fillPayment(invObject.Parent_Account__c,invObject.Id, invObject.Balance_Amount__c,
                                                                       ConstantsClass.successStatus); 
                    objPayment.recordTypeId = payCreditRecType;
                    objPayment.Method_of_Payment__c='Card';// Updated on card method on 10 Jan 2020
                    objPayment.remarks__c = 'Rounding Down';
                    paymentListToCreate.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                    displayPopup=true;
                }
            }
                catch(Exception ex){iLog.Status__c = 'Failure';iLog.Invoice__c = InvId;iLog.Message__c =   ex.getMessage(); //objStripeCharge.error.message;iLog.Type__c =     ex.getTypeName();  //objStripeCharge.error.stripeType;invoiceLogList.add(iLog);   }
        }   
        
    }
        if(InvList.size()>0){
            system.debug('---->'+InvList);
            Database.update(InvList,false);
        }    
        if(invoiceLogList.size()>0){
            Database.insert(invoiceLogList,false);
        }
        
        if(paymentListToCreate.size() > 0){
            system.debug('@@@@@@'+paymentListToCreate);
            Database.insert(paymentListToCreate,false);
        }
        if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
            Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
        }
    }
}