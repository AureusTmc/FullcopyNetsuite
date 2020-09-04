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
    
    String stCstmrId;
    
    //added by Rajesh: 17th July 2019. For add new customer on stripe if customer id is blank
    public Boolean isNotaStripeCstmr{get;set;}
    
    public UpdateCustomerCardCntrl(){
        String tempCstmr = apexpages.currentpage().getparameters().get('id');
        isNotaStripeCstmr = false;
        
        List<Account> cstmrAccList = [SELECT Id, Name, Card_Number__c, Card_Type__c, 
                                      		Card_Image__c, Stripe_Customer_Id__c 
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
        }else{
            isError = true;
            errorMessage = 'Customer not found, Please contact to center admin.';
        }
        
       // getInvoiceLineItemRecords(invoiceId);
        List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c,Stripe_Publishable_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
        if(stripeSettings.size()>0){
           apiKey = stripeSettings[0].Stripe_Publishable_Key__c;
        }
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
        List<Account> cstmrAccList = [SELECT Id,Name,PersonEmail,Stripe_Customer_Id__c FROM Account WHERE Id =: cstmrId];
        
        if(cstmrAccList.size()>0){
            Account csmtr = cstmrAccList[0];
            String customerId = csmtr.Stripe_Customer_Id__c;
           
            if(isNotaStripeCstmr){
                BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(token, csmtr.Name, csmtr.PersonEmail, 'Add customer from update card page');    
                if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){ 
                    
                    BillingUtility.cls_sources srcs = sCstmr.sources;
                    if(srcs.stripeData.size() > 0){
                        BillingUtility.cls_data clData  = srcs.stripeData.get(0);
                        String last4 = clData.last4;
                        String brand = clData.brand;
                        
                        Account objAcc = new Account(Id = cstmrId, Stripe_Customer_Id__c = sCstmr.id, Card_Number__c=last4, Card_Type__c=brand);
                        update objAcc;
                         
                        return 'Customer created Successfully'; 
                    }else{
                        return 'Stripe data not found..';
                    }
                }else{
                    return ''+sCstmr.error.message;
                }
            }else{
            	BillingUtility.StripeCard addCard = BillingUtility.AddCardWithCustomer(customerId,token);
                if(addCard.error != null){
                    return ''+addCard.error.message;
                }else if(addCard.statusCode == 200 && addCard.id != null && !String.isBlank(addCard.id)){
                    BillingUtility.StripeCharge setDefault = new BillingUtility.StripeCharge();
                    setDefault = BillingUtility.setDefaultCard(customerId,addCard.id);
                    String last4 = addCard.last4;
                    String brand = addCard.brand;
                    //system.debug('setDefault >>'+setDefault );
                    if(setDefault.error != null){
                        return ''+setDefault .error.message;
                    }else if(setDefault.statusCode == 200 && setDefault.Id != null && !String.isBlank(setDefault.id)){
                        Account objAcc = new Account(Id = cstmrId,Card_Number__c=last4,Card_Type__c=brand);
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
        
            BillingUtility.StripeCustomer sc = BillingUtility.getCustomerWithCard(stCstmrId);
            System.debug('@@@@   '+sc.default_source);
            
            if(sc.error != null){
                errorMessage = sc.error.message;
            }else if(sc.statusCode == 200 && String.isNotBlank(sc.default_source)){
            	BillingUtility.StripeCard scard = BillingUtility.updateCard(stCstmrId, sc.default_source, selMonth, selYear);
                
                if(scard.error != null)
                    errorMessage = scard.error.message;
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