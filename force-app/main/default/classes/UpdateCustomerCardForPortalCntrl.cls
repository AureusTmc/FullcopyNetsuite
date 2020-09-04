global class UpdateCustomerCardForPortalCntrl{
    public String cstmrAccId {get;set;}
    public String apiKey {get;set;}
    
    public String  cstmrName{get;set;}
    public String  cardNumber{get;set;}
    public String  cardImage{get;set;}
    public String selMonth{get;set;}
    public String selYear{get;set;}
    
    public Boolean isError{get;set;}
    public String errorMessage{get;set;}
    
    public Boolean isErrorInUpdateCard{get;set;}
    
    String stCstmrId;
    
    //added by Rajesh: 17th July 2019. For add new customer on stripe if customer id is blank
    public Boolean isNotaStripeCstmr{get;set;}
    
    //Added by Rajesh 10th Sept 2019, for get stripe infromation bases of the country
    public String countryCode{get;set;}
    String stripeBaseUrl;
    String stripeApiSecKey;    
    public UpdateCustomerCardForPortalCntrl(){
        String tempCstmr = apexpages.currentpage().getparameters().get('id');
        isNotaStripeCstmr = false;
        
        List<Account> cstmrAccList = [SELECT Id, Name, Card_Number__c, Card_Type__c, Centre_Name__r.Country__r.Name,
                                            Card_Image__c, Stripe_Customer_Id__c, Expiry_Month__c, Expiry_Year__c  
                                      FROM Account WHERE Id =: tempCstmr];
        if(cstmrAccList.size()>0){
            cstmrAccId = cstmrAccList.get(0).Id;
			cstmrName  = cstmrAccList.get(0).Name;
            if(String.isBlank(cstmrAccList.get(0).stripe_Customer_Id__c)){
                isNotaStripeCstmr = true;
            }else{
                cardNumber = cstmrAccList.get(0).Card_Number__c; 
                cardImage  = cstmrAccList.get(0).Card_Image__c;
                stCstmrId  = cstmrAccList.get(0).Stripe_Customer_Id__c;
                
                 //added by Rajesh: 10th Sept 2019. For store/display expirty month or year in customer 
                selMonth   = ''+cstmrAccList.get(0).Expiry_Month__c;
                selYear	   = ''+cstmrAccList.get(0).Expiry_Year__c;
            }
            
            
            //Added by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
            countryCode	 = cstmrAccList.get(0).Centre_Name__r.Country__r.Name; 
            if(countryCode == null|| String.isBlank(countryCode))
                countryCode = 'SG';
            
            Map<String,Country__c> countryMap = new Map<String,Country__c>();
            for(Country__c cntry : BillingUtility.getCountryMap(null).values())
                countryMap.put(cntry.Name.toUpperCase(), cntry);
            
            String tempCntryCodeUpper = countryCode.toUpperCase();
            if(countryMap.get(tempCntryCodeUpper) != null){
                Country__c cntry    = countryMap.get(tempCntryCodeUpper);
                stripeBaseUrl		= cntry.Stripe_Base_Url__c;
                apiKey 				= cntry.Stripe_Publishable_Key__c;
                stripeApiSecKey		= cntry.Stripe_Secret_Key__c;
            }
        }else{
            isError = true;
            errorMessage = 'Customer not found, Please contact to center admin.';
        }
        
        //Commented by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
       // getInvoiceLineItemRecords(invoiceId);
      /*  List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c,Stripe_Publishable_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
        if(stripeSettings.size()>0){
           apiKey = stripeSettings[0].Stripe_Publishable_Key__c;
        }*/
    }
    
    public List<SelectOption> getYears(){
        List<SelectOption> yearOptions = new List<SelectOption>();
        
        Integer endingYear = System.today().year()+10;
        for(Integer startYear = System.today().year(); startYear<=endingYear; startYear++){
            String strYear = ''+startYear;
            yearOptions.add(new SelectOption(strYear, strYear));  
        }
        return yearOptions;
    }    
    
    @RemoteAction
    global static String sendInvoiceMail(String invoiceId){
       // List<Invoice__c> invoiceList = getInvoice(invoiceId);
        //BillingUtility.emailInvoiceToParent(invoiceList);
        return 'Mail Sent';
    }
    @RemoteAction
    global static String addCard(string token,String cstmrId, Boolean isNotaStripeCstmr, String countryCode){
        List<Account> cstmrAccList = [SELECT Id,Name,PersonEmail,Stripe_Customer_Id__c FROM Account WHERE Id =: cstmrId];
        
        if(cstmrAccList.size()>0){
            Account csmtr = cstmrAccList[0];
            String customerId = csmtr.Stripe_Customer_Id__c;
            
            //Added by Rajesh 10th Sept 2019, for get stripe infromation bases of the country
            String stripeBaseUrl;
            String stripeApiSecKey;
                        
            if(String.isBlank(countryCode))
            	countryCode = 'SG';
            
            Map<String,Country__c> countryMap = new Map<String,Country__c>();
            for(Country__c cntry : BillingUtility.getCountryMap(null).values())
                countryMap.put(cntry.Name.toUpperCase(), cntry);
            
            String tempCntryCodeUpper = countryCode.toUpperCase();
            if(countryMap.get(tempCntryCodeUpper) != null){
                Country__c cntry    = countryMap.get(tempCntryCodeUpper);
                stripeBaseUrl		= cntry.Stripe_Base_Url__c;
                stripeApiSecKey		= cntry.Stripe_Secret_Key__c;
            }
            
            if(isNotaStripeCstmr){
                //Added by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
                //BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(token, csmtr.Name, csmtr.PersonEmail, 'Add customer from update card page');    
                BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(token, csmtr.Name, csmtr.PersonEmail, 'Add customer from update card page',stripeBaseUrl,stripeApiSecKey);    
                if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){ 
                    
                    BillingUtility.cls_sources srcs = sCstmr.sources;
                    if(srcs.stripeData.size() > 0){
                        BillingUtility.cls_data clData  = srcs.stripeData.get(0);
                        String last4 = clData.last4;
                        String brand = clData.brand;
                        
                        Account objAcc = new Account(Id = cstmrId, Stripe_Customer_Id__c = sCstmr.id, Card_Number__c=last4, Card_Type__c=brand, Expiry_Month__c=clData.exp_month, Expiry_Year__c=clData.exp_year);
                        update objAcc;
                         
                        return 'Customer created Successfully'; 
                    }else{
                        return 'Stripe data not found..';
                    }
                }else{
                    return ''+sCstmr.error.message;
                }
            }else{
                //Added by Rajesh 10th Sept 2019, for get stripe infromation bases of the country
                //BillingUtility.StripeCard addCard = BillingUtility.AddCardWithCustomer(customerId,token);
                BillingUtility.StripeCard addCard = BillingUtility.AddCardWithCustomer(customerId,token,stripeBaseUrl,stripeApiSecKey);
                if(addCard.error != null){
                    return ''+addCard.error.message;
                }else if(addCard.statusCode == 200 && addCard.id != null && !String.isBlank(addCard.id)){
                    BillingUtility.StripeCharge setDefault = new BillingUtility.StripeCharge();
                    //Added by Rajesh 10th Sept 2019, for get stripe infromation bases of the country
                    //setDefault = BillingUtility.setDefaultCard(customerId,addCard.id);
                    setDefault = BillingUtility.setDefaultCard(customerId,addCard.id,stripeBaseUrl,stripeApiSecKey);
                    String last4 = addCard.last4;
                    String brand = addCard.brand;
                    //system.debug('setDefault >>'+setDefault );
                    if(setDefault.error != null){
                        return ''+setDefault .error.message;
                    }else if(setDefault.statusCode == 200 && setDefault.Id != null && !String.isBlank(setDefault.id)){
                        Account objAcc = new Account(Id = cstmrId,Card_Number__c=last4,Card_Type__c=brand, Expiry_Month__c=addCard.exp_month, Expiry_Year__c=addCard.exp_year);
                        UPDATE objAcc;
                         
                        return 'Card update Successfully'; 
                    }
                }
            }
            /*if(addCard.error != null){
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
                    Account objAcc = new Account(Id = cstmrId,Card_Number__c=last4,Card_Type__c=brand);
                    UPDATE objAcc;
                     
                    return 'Card update Successfully'; 
                }
            }*/
        }
        return null;
    }
    
    public pageReference updateCard(){
        isErrorInUpdateCard = false;
        errorMessage = '';
        if(String.isNotBlank(selMonth) && String.isNotBlank(selYear)){
            
        	//Added by Rajesh 10th Sept 2019, for get stripe infromation bases of the country
            //BillingUtility.StripeCustomer sc = BillingUtility.getCustomerWithCard(stCstmrId);
            BillingUtility.StripeCustomer sc = BillingUtility.getCustomerWithCard(stCstmrId, stripeBaseUrl, stripeApiSecKey);
            System.debug('@@@@   '+sc.default_source);
            
            if(sc.error != null){
                errorMessage = sc.error.message;
            }else if(sc.statusCode == 200 && String.isNotBlank(sc.default_source)){
                //Added by Rajesh 10th Sept 2019, for get stripe infromation bases of the country
                //BillingUtility.StripeCard scard = BillingUtility.updateCard(stCstmrId, sc.default_source, selMonth, selYear);
                BillingUtility.StripeCard scard = BillingUtility.updateCard(stCstmrId, sc.default_source, selMonth, selYear, stripeBaseUrl, stripeApiSecKey);
                
                if(scard.error != null){
                    errorMessage = scard.error.message;
                }else if(scard.statusCode == 200 && scard.exp_month != null && scard.exp_year != null){
                    Account objAcc = new Account(Id = cstmrAccId, Expiry_Month__c=scard.exp_month, Expiry_Year__c=scard.exp_year);
                    UPDATE objAcc;
                }
            }
        }else{
            errorMessage = 'Month and Year is required for the the card update';
        }
        
        if(String.isNotBlank(errorMessage))
            isErrorInUpdateCard = true;
        else
            return new pageReference('/apex/trialthankyou');
        
        return null;
    }
}