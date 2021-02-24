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
    public boolean isAlreadyStripCstmr {get; set;}  // added by nishi: 13-Nov-2020: for if user is not a Stripe customer then you use one time payment using stripe
    public string apiKey{get;set;}
    public string stripeToken{get;set;}
    public boolean isContractInvoice{get;set;} // nishi: 24-Feb-2021: aureus -Q1-2021: we check which invoice type is contract then we show student different details
   
    public  payNowDetailController() {
        isOssia= false;
        isAlreadyStripCstmr = false;
        apiKey ='';
        isContractInvoice = false;  // nishi: 24-Feb-2021: aureus -Q1-2021: we check which invoice type is contract then we show student different details
         
        paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        InvId=ApexPages.currentPage().getParameters().get('id');
        InvObj= [Select Id,Status__c,Parent_Account__r.Card_Type__c,Parent_Account__r.Card_Image__c,Customer_Name__c,Parent_Account__r.Name,Parent_Account__c,Name,Balance_Amount__c,Parent_Account__r.Stripe_Customer_Id__c,Parent_Account__r.Card_Number__c, 
                Center__r.Organisation__r.Stripe_Publishable_Key__c, Center__r.Organisation__r.Name,Invoice_Type__c //added by nishi :5-Oct:2020  for show Ossia Logo image
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
        // nishi: 24-Feb-2021: aureus -Q1-2021: we check which invoice type is contract then we show student different details
        if(InvObj.Invoice_Type__c == 'Contract'){
            isContractInvoice = true;
        }
        // nishi: 24-Feb-2021: aureus -Q1-2021: we check which invoice type is contract then we show student different details
        // added by nishi: 13-Nov-2020:start: for if user is not a Stripe customer then you use one time payment using stripe
        if(InvObj.Parent_Account__r.Stripe_Customer_Id__c != null && InvObj.Parent_Account__r.Card_Number__c != null && InvObj.Parent_Account__r.Card_Type__c != null){
            isAlreadyStripCstmr = true;
        }
        if(string.isNotBlank(InvObj.Center__c) && string.isNotBlank(InvObj.Center__r.Organisation__c) && string.isNotBlank(InvObj.Center__r.Organisation__r.Stripe_Publishable_Key__c)){        
            apiKey = InvObj.Center__r.Organisation__r.Stripe_Publishable_Key__c;
        }
        // added by nishi: 13-Nov-2020:end for if user is not a Stripe customer then you use one time payment using stripe
    }

     public void paywithonetimeStripe(){
        system.debug('stripeToken'+stripeToken);
        if(stripeToken!=null && string.isNotBlank(stripeToken.trim())){
            List<Invoice__c> InvList  = new List<Invoice__c>();
            String payCreditRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId(); 
            List<Stripe_Payment_Log__c> invoiceLogList = new List<Stripe_Payment_Log__c>();
            Map<string,Payment__c> mapOfPayment = new Map<string,Payment__c>();
            List<Payment__c> paymentListToCreate = new List<Payment__c>();
            map<string,Country__c> maptoCoutry=BillingUtility.getCountryMap('');
            map<string,Organisation__c> organisationMap=BillingUtility.getOrganisationMap('');
            Map<String,Invoice__c> successinvoiceIdmap = new  Map<String,Invoice__c>();
            // Added By Ravi on ... 21st july 2020 to send mail in case of failure
            Set<String> paymentFailedEmails=new Set<string>{'Ossia_Payment_Collection_Failed','Payment_Collection_Failed'};
            Map<String,EmailTemplate> mapOfEmailTemplate = new Map<String,EmailTemplate>();
            for(EmailTemplate objEmailTemplate: [SELECT Id, Name ,DeveloperName
                                            FROM EmailTemplate 
                                            WHERE DeveloperName In:paymentFailedEmails]){
                                                mapOfEmailTemplate.put(objEmailTemplate.DeveloperName,objEmailTemplate);
                                            }
            List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
             // End..Added By Ravi on ... 21st july 2020 to send mail in case of failure
            Invoice__c invObject = [Select Id,Customer_Name__c,Parent_Account__c,Center__r.Country__c,Parent_Account__r.name,
                                      Center__r.Organisation__r.Name , //added  by nishi 5th Oct 2020,start: for get stripe information bases of the Organisation
                                      Name,Balance_Amount__c,Parent_Account__r.Stripe_Customer_Id__c,
                                      Parent_Account__r.Card_Number__c,Parent_Account__r.PersonContactId,Parent_Account__r.Centre_Name__r.Location__c
                                      from Invoice__c where Id=:InvId];
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
                    BillingUtility.stripeCharge objStripeCharge = BillingUtility.createOneTimeCharge(stripeToken,InvObj.Balance_Amount__c,InvObj.Name,countryObj.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
                    
                    system.debug('====>'+objStripeCharge);
                    if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                        //invObject.Status__c=ConstantsClass.paidStatus;
                        InvList.add(new invoice__c(id = invObject.id,status__c = ConstantsClass.paidStatus));
                        successinvoiceIdmap.put(invObject.id,invObject);
                        Payment__c objPayment = BillingUtility.fillPayment(invObject.Parent_Account__c,invObject.Id, invObject.Balance_Amount__c,
                                                                        ConstantsClass.successStatus); 
                        objPayment.Transaction_ID__c = objStripeCharge.Id;
                        objPayment.recordTypeId = paymentRecType;
                        objPayment.Method_of_Payment__c='Card';// Updated on card method on 10 Jan 2020
                        //paymentListToCreate.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                        mapOfPayment.put(invObject.Id,objPayment);
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
                        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
                            string centerId,personContactId;
                            if(invObject.Parent_Account__r != null && invObject.Parent_Account__r.Centre_Name__r != null &&
                            string.isNotBlank(invObject.Parent_Account__r.Centre_Name__r.Location__c) ){
                                centerId = invObject.Parent_Account__r.Centre_Name__r.Location__c;
                            }
                            if(invObject.Parent_Account__r != null && string.isNotBlank(invObject.Parent_Account__r.PersonContactId)){
                                personContactId = invObject.Parent_Account__r.PersonContactId;
                            }
                            if(organisationObj.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                if(mapOfEmailTemplate.containsKey('Ossia_Payment_Collection_Failed')){
                                    sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Ossia_Payment_Collection_Failed').Id,personContactId,invObject.id,centerId));
                                }
                            }else{
                                if(mapOfEmailTemplate.containsKey('Payment_Collection_Failed')){
                                    sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Payment_Collection_Failed').Id,personContactId,invObject.id,centerId));
                                }   
                            }
                        }
                            
                            
                        // End.. Added By Ravi ..on 21st july 2020 to send email in case of payment failure
                    }    
                    
                }else if(invObject.Balance_Amount__c <= 0.30 && invObject.Balance_Amount__c >= 0){
                     //invObject.status__c = ConstantsClass.paidStatus;
                     InvList.add(new invoice__c(id = invObject.id,status__c = ConstantsClass.paidStatus));
                     successinvoiceIdmap.put(invObject.id,invObject);
                     Payment__c objPayment = BillingUtility.fillPayment(invObject.Parent_Account__c,invObject.Id, invObject.Balance_Amount__c,
                                                                     ConstantsClass.successStatus); 
                     objPayment.recordTypeId = payCreditRecType;
                     objPayment.Method_of_Payment__c='Card';// Updated on card method on 10 Jan 2020
                     objPayment.remarks__c = 'Rounding Down';
                     //paymentListToCreate.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                     mapOfPayment.put(invObject.Id,objPayment);
                     displayPopup=true;
                }
            }catch(Exception ex){
                iLog.Status__c = 'Failure';
                iLog.Invoice__c = InvId;
                iLog.Message__c =   ex.getMessage(); //objStripeCharge.error.message;
                iLog.Type__c =     'internal_error';  //objStripeCharge.error.stripeType;
                invoiceLogList.add(iLog);  
                displayPopupforDeclined=true;
                displayPopup=false;
            }
            
            /*commented by nishi 15-Dec-2020: for as per new logic if in this process we have found any type of error in invoice and payment then we send a email. 
            if(InvList.size()>0){
                system.debug('---->'+InvList);
                Database.update(InvList,false);
            } 
            if(paymentListToCreate.size() > 0){
                system.debug('@@@@@@'+paymentListToCreate);
                Database.insert(paymentListToCreate,false);
            }
            */
            
            system.debug('---->InvList'+InvList);
            system.debug('---->mapOfPayment'+mapOfPayment);
            if(InvList.size()>0){
                BillingUtility.MonthlyBatchClassChunkError objMonthlyBatchClassChunkError =  MonthlyPaymentBatchHelper.createpaymentsForDueInvoice(InvList,mapOfPayment, successinvoiceIdmap,1,false);
                system.debug('---->objMonthlyBatchClassChunkError'+objMonthlyBatchClassChunkError);
                if(objMonthlyBatchClassChunkError.mapOfPaymentErrorWrapper != null && objMonthlyBatchClassChunkError.mapOfPaymentErrorWrapper.size() > 0){
                    for(MonthlyPaymentBatchHelper.paymentErrorWrapper objpaymentErrorWrapper :  objMonthlyBatchClassChunkError.mapOfPaymentErrorWrapper.values()){
                        iLog = new Stripe_Payment_Log__c();
                        iLog.Status__c = 'Failure';
                        iLog.Invoice__c = InvId;
                        iLog.Message__c =   objpaymentErrorWrapper.erroDescription; 
                        iLog.Type__c =  'internal_error';
                        iLog.ChargeId__c = objpaymentErrorWrapper.stripeId;
                        invoiceLogList.add(iLog);  
                    }
                    displayPopupforDeclined=true;
                    displayPopup=false;
                }
            }
            if(invoiceLogList.size()>0){
                Database.insert(invoiceLogList,false);
            }
        
            if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
            }
            
        }else{
            displayPopupforDeclined=true;
        }

    }
    //167dec-2020:nishi: if we find sucessfully invoice ids then we show  confirmation alert popup other wise we show error messages 
    public  void callPaymentGate(){
        List<Stripe_Payment_Log__c> invoiceLogList = new List<Stripe_Payment_Log__c>();
        List<Invoice__c> listOfInvoice = [Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId,Parent_Account__r.Stripe_Customer_Id__c, 
                                            Total_Amount__c,subscription__c,Balance_Amount__c,Paid_Amount__c,Parent_Account__r.Name,
                                            Parent_Account__r.personEmail,Parent_Account__r.Centre_Name__r.Location__c,
                                            Center__r.Country__c, Center__r.Country__r.Id, Center__r.Country__r.Tax_Rate__c, 
                                            Center__r.Country__r.Currency_Code__c, Center__r.Country__r.Stripe_Base_Url__c, 
                                            Center__r.Country__r.Stripe_Secret_Key__c,
                                            Center__r.Organisation__c, Center__r.Organisation__r.Id, /*Center__r.Organisation__r.Tax_Rate__c, */
                                            Center__r.Organisation__r.Country__r.Currency_Code__c, Center__r.Organisation__r.Stripe_Base_Url__c, 
                                            Center__r.Organisation__r.Stripe_Secret_Key__c,Center__r.Organisation__r.Name
                                            FROM Invoice__c 
                                            WHERE Id=:InvId];
        Set<String>  invoiceIds  = MonthlyPaymentBatchHelper.getPaymentForInvoices(listOfInvoice);
        if(invoiceIds != null && invoiceIds.size() > 0 ){
            displayPopup=true;
            displayPopupforDeclined=false;
        }else{
            displayPopupforDeclined=true;
            displayPopup=false;
        }
       
    }

    /*Commented by nishi: 17-Dec-2020: for we centeralize payment insertion code
    public  void callPaymentGate(){
        List<Invoice__c> InvList  = new List<Invoice__c>();
        String payCreditRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId(); 
        List<Stripe_Payment_Log__c> invoiceLogList = new List<Stripe_Payment_Log__c>();
        Map<String,Invoice__c> successinvoiceIdmap = new  Map<String,Invoice__c>();
        List<Payment__c> paymentListToCreate = new List<Payment__c>();
        Map<string,Payment__c> mapOfPayment = new Map<string,Payment__c>();
        map<string,Country__c> maptoCoutry=BillingUtility.getCountryMap('');
        map<string,Organisation__c> organisationMap=BillingUtility.getOrganisationMap('');
        // Added By Ravi on ... 21st july 2020 to send mail in case of failure
        Set<String> paymentFailedEmails=new Set<string>{'Ossia_Payment_Collection_Failed','Payment_Collection_Failed'};
        /*list<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name 
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName ='Payment_Collection_Failed'];*-/
        Map<String,EmailTemplate> mapOfEmailTemplate = new Map<String,EmailTemplate>();
        for(EmailTemplate objEmailTemplate: [SELECT Id, Name ,DeveloperName
                                        FROM EmailTemplate 
                                        WHERE DeveloperName In:paymentFailedEmails]){
                                            mapOfEmailTemplate.put(objEmailTemplate.DeveloperName,objEmailTemplate);
                                        }
        List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
         // End..Added By Ravi on ... 21st july 2020 to send mail in case of failure
        Invoice__c invObject = [Select Id,Customer_Name__c,Parent_Account__c,Center__r.Country__c,Parent_Account__r.name,
                                Center__r.Organisation__r.Name , //added  by nishi 5th Oct 2020,start: for get stripe information bases of the Organisation
                                Name,Balance_Amount__c,Parent_Account__r.Stripe_Customer_Id__c,
                                Parent_Account__r.Card_Number__c,Parent_Account__r.PersonContactId,Parent_Account__r.Centre_Name__r.Location__c
                                from Invoice__c where Id=:InvId];
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
            if(string.isnotBlank(InvObj.Parent_Account__r.Stripe_Customer_Id__c)){
                system.debug('invObject.Balance_Amount__c'+invObject.Balance_Amount__c);
                if(invObject.Balance_Amount__c >=0.30){
                    system.debug('InvObj.Parent_Account__r.Stripe_Customer_Id__c'+InvObj.Parent_Account__r.Stripe_Customer_Id__c +'InvObj.Balance_Amount__c'+InvObj.Balance_Amount__c +'ConstantsClass.currencyCode,'+ConstantsClass.currencyCode +'InvObj.Name'+InvObj.Name);
                    BillingUtility.StripeCharge objStripeCharge;
                    // updated currency code dynamically on 3rd Nov by Ravi....
                    //objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(InvObj.Parent_Account__r.Stripe_Customer_Id__c,InvObj.Balance_Amount__c,ConstantsClass.currencyCode,InvObj.Name,countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c); 
                    // commented by nishi: 5-oct-2020:  for get stripe information bases of the Organisation
                    //	objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(InvObj.Parent_Account__r.Stripe_Customer_Id__c,InvObj.Balance_Amount__c,countryObj.Currency_Code__c,InvObj.Name,countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c); 
                    objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(InvObj.Parent_Account__r.Stripe_Customer_Id__c,InvObj.Balance_Amount__c,countryObj.Currency_Code__c,InvObj.Name,organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c); 
                    
                    
                    system.debug('====>'+objStripeCharge);
                    if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                        //invObject.Status__c=ConstantsClass.paidStatus;
                        InvList.add(new invoice__c(id = invObject.id,status__c = ConstantsClass.paidStatus));
                        successinvoiceIdmap.put(invObject.id,invObject);
                        Payment__c objPayment = BillingUtility.fillPayment(invObject.Parent_Account__c,invObject.Id, invObject.Balance_Amount__c,
                                                                        ConstantsClass.successStatus); 
                        objPayment.Transaction_ID__c = objStripeCharge.Id;
                        objPayment.recordTypeId = paymentRecType;
                        objPayment.Method_of_Payment__c='Card';// Updated on card method on 10 Jan 2020
                        //paymentListToCreate.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                        mapOfPayment.put(invObject.Id,objPayment);
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
                        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
                            string centerId,personContactId;
                            if(invObject.Parent_Account__r != null && invObject.Parent_Account__r.Centre_Name__r != null &&
                            string.isNotBlank(invObject.Parent_Account__r.Centre_Name__r.Location__c) ){
                                centerId = invObject.Parent_Account__r.Centre_Name__r.Location__c;
                            }
                            if(invObject.Parent_Account__r != null && string.isNotBlank(invObject.Parent_Account__r.PersonContactId)){
                                personContactId = invObject.Parent_Account__r.PersonContactId;
                            }
                            if(organisationObj.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                if(mapOfEmailTemplate.containsKey('Ossia_Payment_Collection_Failed')){
                                    sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Ossia_Payment_Collection_Failed').Id,personContactId,invObject.id,centerId));
                                }
                            }else{
                                if(mapOfEmailTemplate.containsKey('Payment_Collection_Failed')){
                                    sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Payment_Collection_Failed').Id,personContactId,invObject.id,centerId));
                                }   
                            }
                        }
                            
                            
                        // End.. Added By Ravi ..on 21st july 2020 to send email in case of payment failure
                    }    
                    
                }else if(invObject.Balance_Amount__c <= 0.30 && invObject.Balance_Amount__c >= 0){
                    //invObject.status__c = ConstantsClass.paidStatus;
                    InvList.add(new invoice__c(id = invObject.id,status__c = ConstantsClass.paidStatus));
                    successinvoiceIdmap.put(invObject.id,invObject);
                    Payment__c objPayment = BillingUtility.fillPayment(invObject.Parent_Account__c,invObject.Id, invObject.Balance_Amount__c,
                                                                    ConstantsClass.successStatus); 
                    objPayment.recordTypeId = payCreditRecType;
                    objPayment.Method_of_Payment__c='Card';// Updated on card method on 10 Jan 2020
                    objPayment.remarks__c = 'Rounding Down';
                    //paymentListToCreate.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                    mapOfPayment.put(invObject.Id,objPayment);
                    displayPopup=true;
                }
            }else{
                displayPopupforDeclined=true;
            }
        }catch(Exception ex){
            iLog.Status__c = 'Failure';
            iLog.Invoice__c = InvId;
            iLog.Message__c =   ex.getMessage(); //objStripeCharge.error.message;
            iLog.Type__c =     'internal_error';  //objStripeCharge.error.stripeType;
            invoiceLogList.add(iLog);  
            displayPopupforDeclined=true;
            displayPopup=false;
        }
        system.debug('invoiceLogList'+invoiceLogList);
        
        /* 15-Dec-2020: Nishi: start: as per new logic if in this process we have found any type of error in invoice and payment then we send a email. 
        if(InvList.size()>0){
            system.debug('---->'+InvList);
            Database.update(InvList,false);
        } 
        if(paymentListToCreate.size() > 0){
            system.debug('@@@@@@'+paymentListToCreate);
            Database.insert(paymentListToCreate,false);
        }
        *-/
        system.debug('---->InvList'+InvList);
        system.debug('---->mapOfPayment'+mapOfPayment);
        if(InvList.size()>0){
            BillingUtility.MonthlyBatchClassChunkError objMonthlyBatchClassChunkError =  MonthlyPaymentBatchHelper.createpaymentsForDueInvoice(InvList,mapOfPayment, successinvoiceIdmap,1,false);
            system.debug('---->objMonthlyBatchClassChunkError'+objMonthlyBatchClassChunkError);
            if(objMonthlyBatchClassChunkError.mapOfPaymentErrorWrapper != null && objMonthlyBatchClassChunkError.mapOfPaymentErrorWrapper.size() > 0){
                for(MonthlyPaymentBatchHelper.paymentErrorWrapper objpaymentErrorWrapper :  objMonthlyBatchClassChunkError.mapOfPaymentErrorWrapper.values()){
                    iLog = new Stripe_Payment_Log__c();
                    iLog.Status__c = 'Failure';
                    iLog.Invoice__c = InvId;
                    iLog.Message__c =   objpaymentErrorWrapper.erroDescription; 
                    iLog.Type__c =  'internal_error';
                    iLog.ChargeId__c = objpaymentErrorWrapper.stripeId;
                    invoiceLogList.add(iLog);  
                }
                displayPopupforDeclined=true;
                displayPopup=false;
            }
        }
        if(invoiceLogList.size()>0){
            Database.insert(invoiceLogList,false);
        }
       
        if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
            Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
        }
        // 15-Dec-2020: Nishi: end: as per new logic if in this process we have found any type of error in invoice and payment then we send a email. 
    }*/

    public  void closeErrorPopup(){
        displayPopupforDeclined=false;
    }
}