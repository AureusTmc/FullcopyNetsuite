public class UpdateCustomerCardCntrl{
    public String cstmrAccId {get;set;}
    public String apiKey {get;set;}
    
    public String  cardNumber{get;set;}
    public String  cardImage{get;set;}
    public String selMonth{get;set;}
    public String selYear{get;set;}
    
    public Boolean isError{get;set;}
    public String errorMessage{get;set;}
    
    public Boolean isErrorInUpdateCard{get;set;}
    public Boolean isossiaOrg{get;set;} // added by nishi: for check current organisation is ossia or aureus
    String stCstmrId;
    
    //added by Rajesh: 17th July 2019. For add new customer on stripe if customer id is blank
    public Boolean isNotaStripeCstmr{get;set;}
    String stripeBaseUrl;
    String stripeApiSecKey;  
    public UpdateCustomerCardCntrl(){
        isossiaOrg = false;
        String tempCstmr = apexpages.currentpage().getparameters().get('id');
        isNotaStripeCstmr = false;
        
        List<Account> cstmrAccList = [SELECT Id, Name, Card_Number__c, Card_Type__c, 
                                              Card_Image__c, Stripe_Customer_Id__c ,
                                              Centre_Name__r.Organisation__r.Name,Organisation_Sharing__c // added by nishi: 5-Oct-2020 : for  get stripe infromation bases of the organisation
                                      FROM Account WHERE Id =: tempCstmr];
        if(cstmrAccList.size()>0){
            cstmrAccId = cstmrAccList.get(0).Id;
            
            if(String.isBlank(cstmrAccList.get(0).stripe_Customer_Id__c)){
                isNotaStripeCstmr = true;
            }else{
                cardNumber = cstmrAccList.get(0).Card_Number__c; 
                cardImage  = cstmrAccList.get(0).Card_Image__c;
                stCstmrId  = cstmrAccList.get(0).Stripe_Customer_Id__c;
            }
            if(string.isNotBlank(cstmrAccList.get(0).Organisation_Sharing__c) && 
            cstmrAccList.get(0).Organisation_Sharing__c.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isossiaOrg = true;
            }

             //added  by nishi 5th Oct 2020,start: for get stripe information bases of the Organisation
             Map<String,Organisation__c> organisationMap =  new Map<String,Organisation__c>();
             for(Organisation__c org : BillingUtility.getOrganisationMap(null).values())
                     organisationMap.put(org.Name.toUpperCase(), org);
             
             String tempCntryCodeUpper = cstmrAccList.get(0).Organisation_Sharing__c.toUpperCase();
             if(organisationMap.get(tempCntryCodeUpper) != null){
                 Organisation__c org    = organisationMap.get(tempCntryCodeUpper);
                 apiKey 				= org.Stripe_Publishable_Key__c;
                 stripeBaseUrl		= org.Stripe_Base_Url__c;
                 stripeApiSecKey		= org.Stripe_Secret_Key__c;
             }
             //added  by nishi 5th Oct 2020,end: for get stripe information bases of the Organisation
        }else{
            isError = true;
            errorMessage = 'Customer not found, Please contact to center admin.';
        }
        
       // getInvoiceLineItemRecords(invoiceId);
       /* commented by nishi: 5-oct-2020: for now change requirement we get stripe details according to organisation 
       List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c,Stripe_Publishable_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
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
    public static String sendInvoiceMail(String invoiceId){
       // List<Invoice__c> invoiceList = getInvoice(invoiceId);
        //BillingUtility.emailInvoiceToParent(invoiceList);
        return 'Mail Sent';
    }
    @RemoteAction
    public static String addCard(string token,String cstmrId, Boolean isNotaStripeCstmr){
        List<Account> cstmrAccList = [SELECT Id,Name,PersonEmail,Stripe_Customer_Id__c,Organisation_Sharing__c FROM Account WHERE Id =: cstmrId];
        
        if(cstmrAccList.size()>0){
            Account csmtr = cstmrAccList[0];
            String customerId = csmtr.Stripe_Customer_Id__c;
            String stripeBaseUrl;
            String stripeApiSecKey;
                        
            
              //added  by nishi 5th Oct 2020,start: for get stripe infromation bases of the Organisation
              Map<String,Organisation__c> organisationMap =  new Map<String,Organisation__c>();
              for(Organisation__c org : BillingUtility.getOrganisationMap(null).values())
                       organisationMap.put(org.Name.toUpperCase(), org);
              
              String tempCntryCodeUpper = cstmrAccList.get(0).Organisation_Sharing__c.toUpperCase();
              if(organisationMap.get(tempCntryCodeUpper) != null){
                  Organisation__c org    = organisationMap.get(tempCntryCodeUpper);
                  stripeBaseUrl		= org.Stripe_Base_Url__c;
                  stripeApiSecKey		= org.Stripe_Secret_Key__c;
              }
              
              //added  by nishi 5th Oct 2020,End: for get stripe infromation bases of the Organisation
  
            if(isNotaStripeCstmr){
                 //Added by nishi 5 Oct 2020, for get stripe information bases of the organisation
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
            	   //Added by nishi 5 Oct 2020, for get stripe information bases of the organisation
                //BillingUtility.StripeCard addCard = BillingUtility.AddCardWithCustomer(customerId,token);
                BillingUtility.StripeCard addCard = BillingUtility.AddCardWithCustomer(customerId,token,stripeBaseUrl,stripeApiSecKey);
                if(addCard.error != null){
                    return ''+addCard.error.message;
                }else if(addCard.statusCode == 200 && addCard.id != null && !String.isBlank(addCard.id)){
                    BillingUtility.StripeCharge setDefault = new BillingUtility.StripeCharge();
                      //Added by nishi 5 Oct 2020, for get stripe information bases of the organisation
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
          //Added by nishi 5 Oct 2020, for get stripe information bases of the organisation
            //BillingUtility.StripeCustomer sc = BillingUtility.getCustomerWithCard(stCstmrId);
            BillingUtility.StripeCustomer sc = BillingUtility.getCustomerWithCard(stCstmrId, stripeBaseUrl, stripeApiSecKey);
            System.debug('@@@@   '+sc.default_source);
            
            if(sc.error != null){
                errorMessage = sc.error.message;
            }else if(sc.statusCode == 200 && String.isNotBlank(sc.default_source)){
                 //Added by nishi 5 Oct 2020, for get stripe information bases of the organisation
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
            return new pageReference('/apex/trialthankyou?isOssia='+isossiaOrg);// 5-Oct-2020: nishi: added parameter to thankyou page 
        
        return null;
    }
}