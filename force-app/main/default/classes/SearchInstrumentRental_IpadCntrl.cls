//CH01 Karan Singh 8 Sep 2020 Bypass pandaDoc Validation in case PandaDoc goes offline for maintenance purposes
//CH02 Karan Singh 16 Sep 2020 Replacing Sage Integration with Net Suite Integration for fetching inventory Details and changing the getProducts()method for this
//			and checking the enrolment is active type or not.
//CH03 Karan Singh 17/18 Sep 2020 : Deposit should be inclusive of GST in the rental summary and Pandadoc as well and also showing (T) in vf in the rental summary for indicating amount is inclusive of GST.
//									Updating the Instrument_Type__c for the selected enrolment ideally piano
//CH04 Karan Singh 22 Sep 2020 : Adding NetSuite API logger.
//CH05 Karan Singh 24 Sep 2020 : showing the type of the instrument in the page and storing the type of the instrument in the enrolment which can be piano,keyboard etc
//CH06 Karan Singh 25 Sep 2020 : Now will calculate the GST amount from selected piano location , as these location will be stored in our center(Account) record, center -> country(parent) -> taxrate will be applicable.
//CH07 Karan Singh 9 Oct 2020 : Now migrating the Netsuite Integration Code to seprate Class 
//CH08 Karan Singh 14 Oct 2020 : Now incase if the existing aureus student is selected for the piano rental, then we will use studentPrice instead of monthlyRental price from the api.
//								adding the Delivery changes for Aureus Students
public class SearchInstrumentRental_IpadCntrl {
    public String slcdCenter{get;set;}
    public String slcdEnrId{get;set;}
    Public Date GetToday{get;set;}
    public list<Centre_Users__c> centerName {get;set;}
    
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    public String countryCode{get;set;}
    
    //2nd page variables
    public Enrolment__c slcdEnrolment{get;set;}
    public Account parentAcc{get;set;}
    public String PersonMobilePhoneCustom{get;set;}  
    //CH02 public List<SageProductItems> sageProducts{get;set;} using Net Suite integration wrapper
    //CH02 public SageProductItems slcdPiano{get;set;}			using Net Suite integration 
    
    //3rd page variables
    public String residenttype{get;set;}
    public Integer nostairs{get;set;}
    // public Decimal charge{get;set;}
    // public Decimal chargerate{get;set;}
    public Date calStartDate{get;set;}
    public Date calEndDate{get;set;}
    public map<Date,list<string>> dateslotmap{get;set;}
    public String slcdSlot{get;set;}
    public String slcdSlotDate{get;set;}
    public String htmtxt{get;set;}
    public list<DateTimeSlot> dtimeslot{get;set;}
    
    public Integer slctdPianoOpt{get;set;}
    public String isRentalOrSellType{get;set;}
    
    //Fee Model for summary page
    public FeeModel fm{get;set;}
    
    public String apiKey {get;set;}
    public string stripeToken{get;set;}
    public String sessionId{get;set;}
    
    public Boolean isAlreadyStripCstmr{get;set;}
    public String  cardNumber{get;set;}
    public String  cardType{get;set;}
    public String  cardImage{get;set;}
    public string customerRefId{get;set;} // added by jatin: 20:feb:2020: is user click offline card payment option then we manage refId
    public string paymentType{get;set;} // added by jatin: 20:feb:2020: is user click offline card payment option then we manage payment type 'Card' or 'Nfsc'
    
    public Boolean agreementCheckbox{get;set;}
    String sageCmp;
    String stripeCstmrId;
    String templateId;
    String stripeBaseUrl;
    String stripeApiSecKey;
    String countryCurrencyCode;
    String folderId;
    String cenOrgId;
    
    PandaDocUtility.CreateDocument documentDetails;
    PandaDocUtility.SessionDocument sessionDetails;
    Integer pianoDelWind;
    
    //CH01 Karan Singh 
    public Boolean isPandaDocUnderMaintance{get;set;} //for showing the bypass checkbox    
    public Boolean isCustmrOptedOfflineSign{get;set;}  
    //CH01 END 
    
    //CH02 
    public List<NetSuiteIntegrationUtility.NetSuiteProducts> netSuiteProducts{get;set;}
    public NetSuiteIntegrationUtility.NetSuiteProducts slcdPiano{get;set;}
    public Boolean isExistingLessonEnrolment{get;set;} //17 sep 2020 as if slcd enrolment is an active lesson type enrolment then we will charge only one time rental amount not twice.
    //CH02 END
    //CH03
    Decimal gstAmount {get;set;}
    String instrumentType {get;set;} //currently we are using for piano, but later it will used to show ohter instrument like drum,violin etc
    //CH03
    
    //public static 
    public SearchInstrumentRental_IpadCntrl(){
        
        //CH03
        gstAmount = 0;
        instrumentType = 'Piano';
        //CH03
        //CH02
        netSuiteProducts = new List<NetSuiteIntegrationUtility.NetSuiteProducts>();
        slcdPiano = new NetSuiteIntegrationUtility.NetSuiteProducts();
        isExistingLessonEnrolment = false;
        //CH02
        //CH01 Karan Singh  
        isPandaDocUnderMaintance = false;   
        isCustmrOptedOfflineSign = false;   
        if( String.isNotBlank(Label.Allow_Offline_Signing)){    
            isPandaDocUnderMaintance = Label.Allow_Offline_Signing.equalsIgnoreCase('true');    
        }   
        system.debug('isPandaDocUnderMaintance --> ' + isPandaDocUnderMaintance );
        //CH01 END
        
        //system.debug('slcdCenter'+slcdCenter);
        centerName= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c from Centre_Users__c where User_Name__c=:UserInfo.getUserId()]);
        slcdCenter=centerName[0].Centre_Name__c;
        sageCmp =centerName[0].Centre_Name__r.Organisation__r.Sage_Company__c;
        GetToday=system.today();
        PersonMobilePhoneCustom = '';
        countryCode  = ApexPages.currentPage().getParameters().get('country');
        if(String.isBlank(countryCode))
            countryCode = 'SG';
        
        parentAcc    = new Account();
        slcdEnrolment= new Enrolment__c();
        //CH02 sageProducts = new List<SageProductItems>();
        //CH02 slcdPiano = new SageProductItems();
        agreementCheckbox = false;
        
        //by uzair
        nostairs = 0;
        // charge = 0;
        //chargerate  = ConstantsClass.chargerate;
        pianoDelWind = Integer.valueOf(Label.Piano_Delivery_Window);
        this.calStartDate   = System.today().addDays(pianoDelWind);
        fetchDates();
        dtimeslot = new list<DateTimeSlot>();
        fm = new FeeModel();
        
        documentDetails = new PandaDocUtility.CreateDocument();
        sessionDetails = new PandaDocUtility.SessionDocument();
    }   
    
    public list<SelectOption> getCenters(){
        list<SelectOption> options = new list<SelectOption>();
        
        String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        options.add(new SelectOption('','Please select')); 
        
        for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                          WHERE RecordtypeId =: cenRecId AND CentreName_Cust__c != null AND Country__r.Name =:countryCode ORDER BY CentreName_Cust__c]){
                              system.debug('----'+acc);
                              options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
                          }
        
        return options;
    }
    //20-Feb-2020:jatin:start: get Payment Type picklist for show Payment mode for Offline cards
    public List<SelectOption> getPaymentTypePicklist(){     
        set<string> paymentTypes = new Set<string>{'Card','NETS'};
            List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        Map<String, Schema.SObjectField> field_map = Schema.getGlobalDescribe().get('Payment__c').newSObject().getSObjectType().getDescribe().fields.getMap(); //From the Object Api name retrieving the SObject and grab the sobject that was passed
        List<Schema.PicklistEntry> pick_list_values   = field_map.get('Method_of_Payment__c').getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        
        for(Schema.PicklistEntry a : pick_list_values){ //for all values in the picklist list
            if(paymentTypes.contains(a.getValue()))
                lstPickvals.add(new SelectOption(a.getValue(), a.getLabel()));
        }
        
        return lstPickvals;
    }
    //20-Feb-2020:jatin:end: get Payment Type picklist for show Payment mode for Offline cards
    
    public List<Account> getSampleController(){
        return [SELECT Name, AccountNumber, Phone FROM Account LIMIT 999];
    }
    public list<SelectOption> getType(){        
        list<SelectOption> options = new list<SelectOption>();
        /*options.add(new SelectOption('','Please select')); 
for(string str : Label.Type.split(','))
options.add(new SelectOption(str,str));*/
        options.add(new SelectOption('', '--Please select--'));
        options.addAll(fillPicklistValues('Enrolment__c', 'House_type__c'));
        return options;
    }
    
    public list <EnrolmentModel> getEnrolments() {
        List<EnrolmentModel> enrList = new List<EnrolmentModel>(); 
        // String type = ConstantsClass.typeTrial;
        //Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment};
        Set<String> stgList = new Set<String>{'Piano Viewing Booked','Piano Viewing Completed'};
            if(String.isNotBlank(slcdCenter)){
                for(Enrolment__c enr: [SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Student__r.Name,
                                       Teacher__c, Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c,
                                       Center__c, Center__r.Name 
                                       FROM Enrolment__c 
                                       WHERE Parent__r.Personemail != null AND Type__c ='Instrument'  AND Stage__c IN:stgList AND Type__c = 'Instrument' 
                                       AND Center__c=:slcdCenter and Trial_Date__c=:GetToday]){
                                           system.debug('----'+enr);  
                                           String tempTSlot = DateTime.newInstance(enr.Trial_Date__c, enr.Trial_Start_Time__c).format('hh:mm a');                          
                                           enrList.add(new EnrolmentModel(enr, tempTSlot));
                                       }
            }
        
        return enrList;
    }
    
    @RemoteAction
    public static list <EnrolmentModel> fetchEnrolments(String srchKey, String cntryCode){
        
        List<EnrolmentModel> enrList = new List<EnrolmentModel>(); 
        String type = ConstantsClass.typeTrial;
        // Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment};
        Set<String> stgList = new Set<String>{'Piano Viewing Booked','Piano Viewing Completed'};
            system.debug('======------>'+srchKey);
        if(String.isNotBlank(srchKey)){
            String tempSerch = srchKey + '%';
            system.debug('=====>'+tempSerch);
            String str = 'SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Student__r.Name,Teacher__c, '+
                'Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c,Center__c, Center__r.Name  '+
                'FROM Enrolment__c WHERE Center__r.Country__r.Name =:cntryCode AND Parent__r.Personemail != null AND Parent__c != null AND '+
                'Parent__r.Name != null AND Stage__c IN:stgList AND Type__c = \'Instrument\' AND (Name like: tempSerch OR Parent__r.Name like: tempSerch OR '+
                'Parent__r.PersonEmail like: tempSerch OR Parent__r.Phone like: tempSerch ) LIMIT 5'; 
            System.debug('@str@@@'+str);
            List<Enrolment__c> enrListing= database.query(str);
            
            //System.debug('@str@@@'+enrListing.size());
            for(Enrolment__c enr:enrListing){
                String tempTSlot;
                system.debug('---->'+enr);
                if(enr.Trial_Date__c != null){
                    tempTSlot = DateTime.newInstance(enr.Trial_Date__c, enr.Trial_Start_Time__c).format('hh:mm a');   
                } 
                enr.Parent_Email__c = enr.Parent__r.Personemail;
                enrList.add(new EnrolmentModel(enr, tempTSlot));  
            }
        }
        system.debug('enrList---'+enrList.size());
        return enrList;
    }
    
    public void procssSlcdEnrolment(){
        slcdEnrolment = new Enrolment__c();
        stripeCstmrId = '';
        cardNumber    = '';
        cardType      = '';            
        cardImage     = '';
        fm.gstTaxPer  = 7;
        isAlreadyStripCstmr = false;
        cenOrgId  = '';
        if(String.isNotBlank(slcdEnrId)){
            String defStnAss = '';
            integer count = 0;
            for(SelectOption so : fillPicklistValues('Enrolment__c', 'Standard_Accessories__c')){
                defStnAss += (count != 0 ? ';'+so.getValue() : so.getValue());
                count = count+1;
            }
            
            List<Enrolment__c> enrList = [SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Parent__r.FirstName, Parent__r.LastName,
                                          Parent__r.Phone, Parent__r.BillingStreet, Parent__r.BillingCity,  Parent__r.BillingPostalCode,  Parent__r.BillingCountryCode, House_type__c, Block__c,Additional_Delivery_comments__c,
                                          Teacher__c, Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c, Center__c, Center__r.Name, Standard_Accessories__c,
                                          Parent__r.Stripe_Customer_Id__c, Parent__r.Card_Number__c, Parent__r.Card_Type__c, Parent__r.Card_Image__c,Center__r.Country__r.name, Center__r.Country__c, Center__r.Organisation__c
                                          
                                          //CH02 17 sep 2020 will work later on this
                                          //   ,recordtype.name,Parent__r.Enroled__c
                                          //CH02 END
                                          //CH03 Karan for Calc GST Price as well
                                          ,Center__r.Country__r.Tax_Rate__c
                                          //CH03
                                          FROM Enrolment__c 
                                          WHERE Id =: slcdEnrId];
            if(enrList.size() > 0){
                
                //CH03 Karan 18 Sep 2020
                //CH06  if( enrList.get(0).Center__r.Country__r.Tax_Rate__c != null )
                    //CH06  gstAmount = BillingUtility.roundOffAmount(enrList.get(0).Center__r.Country__r.Tax_Rate__c);
                //CH03 
                
                // 17 sep 2020 will work later on thisCH02 17 Sep 2020 checking if it is existing  active/enrolled Lesson Enrolment
                //if(  enrList.get(0).recordtype.name != Null && enrList.get(0).recordtype.name == 'Lesson' && enrList.get(0).Parent__r.Enroled__c != Null && enrList.get(0).Parent__r.Enroled__c ){
                //     isExistingLessonEnrolment = true;
                // }
                //CH02
                parentAcc.id          = enrList.get(0).Parent__c;
                parentAcc.firstName   = enrList.get(0).Parent__r.FirstName;
                parentAcc.LastName    = enrList.get(0).Parent__r.LastName;
                parentAcc.Personemail = enrList.get(0).Parent__r.Personemail;
                parentAcc.Phone       = enrList.get(0).Parent__r.Phone;
                parentAcc.BillingStreet      = enrList.get(0).Parent__r.BillingStreet;
                parentAcc.BillingCity        = enrList.get(0).Parent__r.BillingCity;
                parentAcc.BillingPostalCode  = enrList.get(0).Parent__r.BillingPostalCode;
                parentAcc.BillingCountryCode = enrList.get(0).Parent__r.BillingCountryCode;
                cenOrgId = enrList.get(0).Center__r.Organisation__c;
                
                slcdEnrolment = enrList.get(0);
                
                slcdEnrolment.Standard_Accessories__c = defStnAss;
                
                if(String.isBlank(parentAcc.BillingCountryCode))
                    parentAcc.BillingCountryCode = enrList.get(0).Center__r.Country__r.name;
                
                if(enrList.get(0).Parent__r.Stripe_Customer_Id__c != null && enrList.get(0).Parent__r.Card_Number__c != null && enrList.get(0).Parent__r.Card_Type__c != null){
                    stripeCstmrId = enrList.get(0).Parent__r.Stripe_Customer_Id__c;
                    cardNumber    = enrList.get(0).Parent__r.Card_Number__c;
                    cardType      = enrList.get(0).Parent__r.Card_Type__c;            
                    cardImage     = enrList.get(0).Parent__r.Card_Image__c;
                    isAlreadyStripCstmr = true;
                }
                //added by nishi: 23-Sep-2020: According to new requirement we get stripe details according to organisation not country fields
                String organisationId          = enrList.get(0).Center__r.Organisation__c;
                Map<String,Organisation__c> organisationMap = BillingUtility.getOrganisationMap(organisationId);
                if(organisationMap.containsKey(organisationId)){
                    stripeBaseUrl       = organisationMap.get(organisationId).Stripe_Base_Url__c;
                    apiKey              = organisationMap.get(organisationId).Stripe_Publishable_Key__c;
                    stripeApiSecKey     = organisationMap.get(organisationId).Stripe_Secret_Key__c;
                    countryCurrencyCode = organisationMap.get(organisationId).country__r.Currency_Code__c;
                    fm.gstTaxPer        =  Integer.valueOf(organisationMap.get(organisationId).Tax_Rate__c);
                    templateId          = organisationMap.get(organisationId).Student_Policies_Template_Id__c;
                    folderId            = organisationMap.get(organisationId).Folder__c;
                }
               
                /*commented by nishi: 23-Sep-2020: According to new requirement we get stripe details according to organisation not country fields
                String countryId          = enrList.get(0).Center__r.Country__c;
                Map<String,Country__c> countryMap = BillingUtility.getCountryMap(countryId);
                if(countryMap.containsKey(countryId)){
                    stripeBaseUrl       = countryMap.get(countryId).Stripe_Base_Url__c;
                    apiKey              = countryMap.get(countryId).Stripe_Publishable_Key__c;
                    stripeApiSecKey     = countryMap.get(countryId).Stripe_Secret_Key__c;
                    countryCurrencyCode = countryMap.get(countryId).Currency_Code__c;
                    fm.gstTaxPer        =  Integer.valueOf(countryMap.get(countryId).Tax_Rate__c);
                    templateId          = countryMap.get(countryId).Student_Policies_Template_Id__c;
                    folderId            = countryMap.get(countryId).Folder__c;
                }
                end:commented by nishi: 23-Sep-2020: According to new requirement we get stripe details according to organisation not country fields
                */
                if(String.isBlank(countryCurrencyCode)) 
                countryCurrencyCode = ConstantsClass.currencyCode;
            
            }
        }
    }
    
    public PageReference nextBtnCmp1(){        
        return page.SearchInstrumentRental_Ipad2;
    }
    public PageReference backBtnCmp2(){        
        return page.SearchInstrumentRental_Ipad1;
    }
    public PageReference backBtnCmp3(){        
        return page.SearchInstrumentRental_Ipad2;
    }
    public PageReference backBtnCmp4(){        
        return page.SearchInstrumentRentalDeliveryPage_Ipad3;
    }
    public PageReference nextBtnCmp3(){ 
        fm.deliCharges = (Decimal.valueOf(Label.Delivery_Charges));
        fm.tuningFee = (Decimal.valueOf(Label.Tuning_Fee));
        fm.heatingRodInsFee = (Decimal.valueOf(Label.Heating_Rod_Installation_Fee));
        
        //CH08 : for Aureus Students Delivery fees
        if(isAlreadyStripCstmr != null && isAlreadyStripCstmr && String.isNotBlank( Label.Delivery_Charges_for_Aureus_Students )){
             fm.deliCharges = (Decimal.valueOf(Label.Delivery_Charges_for_Aureus_Students));
        }
        //CH08 END
        //Start: nishi: 27-Jul-2020: Existing Student – one month (with any active enrolment) ; others – two months
        if(isAlreadyStripCstmr != null && isAlreadyStripCstmr){ 
            //if(isExistingLessonEnrolment != null && isExistingLessonEnrolment){// 17 sep 2020 will work later on this CH02 Karan :as 17 sep 2020 , now checking if the selected enrolment is existing active/enrolled enrolment of type lesson.
            //CH02 
            //fm.depFee = BillingUtility.roundOffAmount(Decimal.valueOf(Label.Piano_Rental_Deposit_Fee)); CH02 Karan 17 Sep 2020 :use piano Deposit fee only instead Label as now we are getting rental amount of piano from netSuite
            system.debug('gstAmount-->  ' + gstAmount);
            if(string.isNotBlank(slcdPiano.monthlyRental) &&  slcdPiano.monthlyRental != Null ){
                
                fm.depFee = (Decimal.valueOf(slcdPiano.monthlyRental));
                //CH03 Will add Gst amount as well
                fm.depFee += BillingUtility.roundOffAmount((Decimal.valueOf(slcdPiano.monthlyRental)) * gstAmount) /100;
                fm.depFee = (fm.depFee);
                //CH03 END
            }
            
            //CH02 END
        }else{
            //CH02
            //fm.depFee = BillingUtility.roundOffAmount(Decimal.valueOf(Label.Piano_Rental_Deposit_Fee) *2 ); CH02 Karan 17 Sep 2020: use piano Deposit fee only instead Label as now we are getting rental amount of piano from netSuite
            if(string.isNotBlank(slcdPiano.monthlyRental) &&  slcdPiano.monthlyRental != Null ){
                
                fm.depFee =(Decimal.valueOf(slcdPiano.monthlyRental) *2 );
                //CH03 Will add Gst amount as well
                fm.depFee += BillingUtility.roundOffAmount((Decimal.valueOf(slcdPiano.monthlyRental) *2 ) * gstAmount) /100;
                fm.depFee = (fm.depFee);
                //CH03 END
            }
            
            //CH02 END 
        }
        //End:nishi: 27-Jul-2020:Existing Student – one month (with any active enrolment) ; others – two months
        //fm.depFee = BillingUtility.roundOffAmount(Decimal.valueOf(Label.Piano_Rental_Deposit_Fee) *2 ); commented by CH02 17 sep 2020 Karan as now will use above if else only 
        fm.perStairCharges  = (Decimal.valueOf(Label.Per_Stair_Charges));
        
        Integer isTwiceCharge = isRentalOrSellType.equalsIgnoreCase('Rent') ? 2 : 1;
        //Stair charge with twice for the Rental
        if(nostairs > 0)
            fm.stairDelCharges = ((fm.perStairCharges * nostairs)*isTwiceCharge);
        
        //Delivery charges twice for the Rental
        fm.deliCharges = (fm.deliCharges*isTwiceCharge);
        
        //Instrument charge will be zero During rent. it will be taken on the time of Delivery
        fm.instrumentChrg = 0;//BillingUtility.roundOffAmount(slcdPiano.rentalPrice);
        if(isRentalOrSellType.equalsIgnoreCase('Rent')){
            fm.totFee = fm.deliCharges + fm.tuningFee + fm.heatingRodInsFee + fm.stairDelCharges;
            // added by nishi: 2:Oct-2020: for we calculate gst per invoice line item
            fm.gstAmt += BillingUtility.roundOffAmount(fm.deliCharges > 0 && fm.gstTaxPer > 0 ?  (fm.deliCharges*fm.gstTaxPer/100) : 0);
            fm.gstAmt += BillingUtility.roundOffAmount(fm.tuningFee > 0 && fm.gstTaxPer > 0 ?  (fm.tuningFee*fm.gstTaxPer/100) : 0);
            fm.gstAmt += BillingUtility.roundOffAmount(fm.heatingRodInsFee > 0 && fm.gstTaxPer > 0 ?  (fm.heatingRodInsFee*fm.gstTaxPer/100) : 0);
            fm.gstAmt += BillingUtility.roundOffAmount(fm.stairDelCharges > 0 && fm.gstTaxPer > 0 ?  (fm.stairDelCharges*fm.gstTaxPer/100) : 0);
        }else{
            fm.depFee = fm.deliCharges = fm.tuningFee = fm.heatingRodInsFee = fm.stairDelCharges = fm.perStairCharges = 0;
            //CH02 
            //fm.instrumentChrg = BillingUtility.roundOffAmount(slcdPiano.salesPrice);
            system.debug(' --> ' + BillingUtility.roundOffAmount(Decimal.valueOf(slcdPiano.listPrice )));
            fm.instrumentChrg = (Decimal.valueOf(slcdPiano.listPrice) );
            //CH02 END
            fm.totFee = fm.instrumentChrg;
              fm.gstAmt += BillingUtility.roundOffAmount(fm.instrumentChrg > 0 && fm.gstTaxPer > 0 ?  (fm.instrumentChrg*fm.gstTaxPer/100) : 0);
        }
        
        
        //fm.gstAmt = BillingUtility.roundOffAmount(fm.totFee > 0 && fm.gstTaxPer > 0 ?  (fm.totFee*fm.gstTaxPer/100) : 0);
        
        fm.totFee += fm.depFee;
        fm.grandTot = BillingUtility.roundOffAmount(fm.totFee + fm.gstAmt);
        fm.totFee = BillingUtility.roundOffAmount(fm.totFee);
        return page.SearchInstrumentFinalConfirmPage_Ipad4;
    }
    public void setSlots(){
        
        Time t = getTime(slcdSlot);
        DateTime dtime = DateTime.newInstance(Date.parse(slcdSlotDate), t);
        DateTimeSlot dtslt = new DateTimeSlot();
        dtslt.dt = dtime;
        
        System.debug('slcdSlotDate---->>>'+slcdSlotDate);
        System.debug('DateTimeSlot---->>>'+dtime);
        System.debug('DateTimeSlot---->>>'+dtime.Date());
        
        list<string> htmlsplit = htmtxt.split('@@');
        dtslt.dttime = htmlsplit[0]+' ('+slcdSlot+')';
        dtslt.appid =  htmlsplit[1]+slcdSlot;
        
        Integer i = getIndex(dtslt.appid);
        if(dtimeslot!=null && i>=0 && i<dtimeslot.size())
            dtimeslot.remove(i);
        
        dtimeslot.add(dtslt);
        
        
        /*   System.debug('dtimeslot---->>>'+dtimeslot.size());
Map<DateTime, DateTimeSlot> dateMap = new Map<DateTime, DateTimeSlot>();
List<DateTime> dateSet = new List<DateTime>();
for(DateTimeSlot dtSlot:dtimeslot ){
dateMap.put(dtSlot.dt, dtSlot);
dateSet.add(dtSlot.dt);
}

dtimeslot = new List<DateTimeSlot>();
dateSet.sort();
for(DateTime slcdDt: dateSet){
dtimeslot.add(dateMap.get(slcdDt));
}*/
        //dtimeslot = new List<DateTimeSlot>();
    }
    public void detSlots(){
        
        Integer index = getIndex(slcdSlotDate);
        if(dtimeslot!=null && index>=0 && index<dtimeslot.size())
            dtimeslot.remove(index);
        System.debug('dtimeslot-->>>>'+dtimeslot.size());
    }
    public Integer getIndex(String slcdSlotDate){
        integer i = 0;
        Boolean isIn = false;
        for(DateTimeSlot dts : dtimeslot){
            if((dts.appid).contains(slcdSlotDate)){
                isIn = true;
                break;
            }
            i++;
        }
        
        if(isIn==false)
            return -1;
        else
            return i;
    }
    public Time getTime(string slcdSlot){
        
        list<string> strlst = slcdSlot.split('-');
        integer srthour;
        integer endhour;
        if(strlst[0].length()==4)
            srthour= Integer.valueof(strlst[0].substring(0,1));
        else
            srthour= Integer.valueof(strlst[0].substring(0,2)); 
        if(strlst[0].contains('pm') && srthour != 12)
            srthour = srthour + 12;
        
        if(strlst[1].length()==4)
            endhour= Integer.valueof(strlst[1].substring(1,2));
        else
            endhour= Integer.valueof(strlst[1].substring(1,3)); 
        if(strlst[1].contains('pm') && endhour != 12)
            endhour = endhour + 12;
        return (Time.newInstance(srthour, 0, 0, 0));
    }
    public void addDate(){
        GetToday= GetToday.addDays(1);
        getEnrolments();
        // return GetToday;
    }
    public void subDate(){
        GetToday= GetToday.addDays(-1);
        getEnrolments();
        // return GetToday;
    }
    
    public void fetchFullAddress(){
        string postalCode = Apexpages.currentPage().getParameters().get('postalCode');
        system.debug('postalCode'+postalCode);
        system.debug('parentAcc.BillingCountryCode'+parentAcc.BillingCountryCode);
        if(String.isNotBlank(parentAcc.BillingCountryCode) && String.isNotBlank(postalCode)){
            String tempPostalCode = postalCode;
            try{
                tempPostalCode = ''+Integer.valueOf(postalCode);
            }catch(Exception e){}
            System.debug('@@@@'+[SELECT Id, Name, BuildingNo__c, Country__r.Name, Country__r.Country_Name__c, Street_Name__c, Building_Name__c 
                                       FROM Postal_code__c 
                                       WHERE Country__r.Name =: parentAcc.BillingCountryCode AND Name =: tempPostalCode LIMIT 1]);
            for(Postal_code__c code : [SELECT Id, Name, BuildingNo__c, Country__r.Name, Country__r.Country_Name__c, Street_Name__c, Building_Name__c 
                                       FROM Postal_code__c 
                                       WHERE Country__r.Name =: parentAcc.BillingCountryCode AND Name =: tempPostalCode LIMIT 1]){
                                            System.debug('code'+code);
                                           parentAcc.BillingStreet = (String.isNotBlank(code.BuildingNo__c)) ? code.BuildingNo__c + ' ': '';
                                           parentAcc.BillingStreet += (String.isNotBlank(code.Building_Name__c)) ? code.Building_Name__c + ', ': '';
                                           parentAcc.BillingStreet += (String.isNotBlank(code.Street_Name__c)) ? code.Street_Name__c: '';
                                           // enrolDetails.parent.country = code.Country__c;
                                           parentAcc.BillingCity = code.Building_Name__c;
                                           parentAcc.BillingPostalCode = code.Name;
                                           
                                           
                                           
                                       }
        }    
    }
    
    //Page to functionality
    //CH02 Deprecated this method, will use the getProducts1 method for this
    public void getProducts(){
        
        //CH02
        /*
sageProducts = new List<SageProductItems>(); 

SageIntacctIntegrationUtility.resultWrapper rw = new SageIntacctIntegrationUtility.resultWrapper();

SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);        
if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
System.debug('@@@'+sw.sessionId);
HttpRequest req = new HttpRequest();
req.setMethod('POST');
req.setEndpoint(sw.endPointUrl);
req.setHeader('Content-Type','application/xml');

string timestamp = String.valueof(DateTime.now().getTime());

//Fetch Wharehouse details
String wareHouseName = 'AGP-WH';//'ACP-WH';

String wareHouseLocationId= '';
//fetching warehouse details
String body = '<?xml version="1.0" encoding="UTF-8"?>'+
'<request>'+
'<control>'+
'<senderid>'+sw.senderId+'</senderid>'+
'<password>'+sw.senderPassword+'</password>'+
'<controlid>'+timestamp+'</controlid>'+
'<uniqueid>false</uniqueid>'+
'<dtdversion>3.0</dtdversion>'+
'<includewhitespace>false</includewhitespace>'+
'</control>'+
'<operation>'+
'<authentication>'+
'<sessionid>'+sw.sessionId+'</sessionid>'+
'</authentication>'+
'<content>'+
'<function controlid="'+timestamp+'">'+
'<readByQuery>'+
'<object>ITEMWAREHOUSEINFO</object>'+
'<fields>*</fields>'+
'<query>WAREHOUSEID=\''+wareHouseName+'\'</query>'+
'<pagesize>100</pagesize>'+
'</readByQuery>'+
'</function>'+
'</content>'+
'</operation>'+
'</request>';   
req.setBody(body);
req.setTimeout(120000);

String response;
If(!Test.isRunningTest()){
Http http = new Http();
HTTPResponse res = http.send(req);                    
response = res.getBody();
}else{
//   response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
response ='<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout><data><itemwarehouseinfo><RECORDNO>1</RECORDNO><ITEMID>1</ITEMID><WAREHOUSEID>001</WAREHOUSEID><WONHAND>0</WONHAND><STANDARD_COST>10</STANDARD_COST></itemwarehouseinfo></data></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';

}

system.debug('body==='+body);
System.debug('response==='+response);

Set<String> whereHouseItems = new Set<String>();

DOM.Document doc = new DOM.Document();
doc.load(response);
DOM.XMLNode root = doc.getRootElement();
for(DOM.XMLNode child : root.getChildElements()){
if(child.getName()=='operation'){
for(DOM.XMLNode child1 : child.getChildElements()){                        
Boolean isSuccess = false;
for(DOM.XMLNode child2 : child1.getChildElements()){
if(child2.getName()=='status'){
if(child2.getText()=='success'){
isSuccess = true;
}
}else if(child2.getName()=='locationid'){
wareHouseLocationId = child2.getText();
}

if(isSuccess && child2.getName()=='data'){
for(DOM.XMLNode child3 : child2.getChildElements()){
if(child3.getName()=='itemwarehouseinfo'){

for(DOM.XMLNode child4 : child3.getChildElements()){
if(child4.getName()=='RECORDNO'){
//System.debug('@@@@-->'+child4.getText());
//sgPr.recNo = child4.getText();
}
else if(child4.getName()=='ITEMID'){
whereHouseItems.add(child4.getText());
}else if(child4.getName()=='WONHOLD'){
// sgPr.category = child4.getText();
}
}
}                                       
}
}

if(child2.getName()=='errormessage'){
for(DOM.XMLNode child3 : child2.getChildElements()){
if(child3.getName()=='error'){
for(DOM.XMLNode child4 : child3.getChildElements()){
if(child4.getName()=='description2'){
rw.errorMsg = child4.getText();
break;
}
}
if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){
break;
}
}
}
}
}
}
}
if(child.getName()=='errormessage'){
for(DOM.XMLNode child1 : child.getChildElements()){
if(child1.getName()=='error'){
for(DOM.XMLNode child2 : child1.getChildElements()){
if(child2.getName()=='description2'){
rw.isSuccess = false;
rw.errorMsg = child2.getText();
break;
}
}
}
}
}
}   

System.debug('whereHouseItems==='+whereHouseItems);     


//Fetch item details
body = '<?xml version="1.0" encoding="UTF-8"?>'+
'<request>'+
'<control>'+
'<senderid>'+sw.senderId+'</senderid>'+
'<password>'+sw.senderPassword+'</password>'+
'<controlid>'+timestamp+'</controlid>'+
'<uniqueid>false</uniqueid>'+
'<dtdversion>3.0</dtdversion>'+
'<includewhitespace>false</includewhitespace>'+
'</control>'+
'<operation>'+
'<authentication>'+
'<sessionid>'+sw.sessionId+'</sessionid>'+
'</authentication>'+
'<content>'+
'<function controlid="'+timestamp+'">'+
'<readByQuery>'+
'<object>ITEM</object>'+
'<fields>*</fields>'+
'<query>ITEMTYPE=\'I\' and STATUS=\'T\' and PRODUCTLINEID=\'Piano\'</query>'+
'<pagesize>100</pagesize>'+
'</readByQuery>'+
'</function>'+
'</content>'+
'</operation>'+
'</request>';

req.setBody(body);
req.setTimeout(120000);

response = '';
If(!Test.isRunningTest()){
Http http = new Http();
HTTPResponse res = http.send(req);                    
response = res.getBody();
}else{
//  response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
response ='<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout><data><item><NAME>test</NAME><ITEM_MAKE>test</ITEM_MAKE><ITEM_MODEL_NUMBER>001</ITEM_MODEL_NUMBER><ITEM_SERIAL_NUMBER>001</ITEM_SERIAL_NUMBER><RENTAL_RATE>10</RENTAL_RATE><SALE_PRICE>10</SALE_PRICE><ITEM_STATUS>True</ITEM_STATUS></item></data></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
}

system.debug('body==='+body);
System.debug('response==='+response);

doc = new DOM.Document();
doc.load(response);
root = doc.getRootElement();

for(DOM.XMLNode child : root.getChildElements()){
if(child.getName()=='operation'){
for(DOM.XMLNode child1 : child.getChildElements()){                        
Boolean isSuccess = false;
for(DOM.XMLNode child2 : child1.getChildElements()){
if(child2.getName()=='status'){
if(child2.getText()=='success'){
isSuccess = true;
}
}

if(isSuccess && child2.getName()=='data'){
Integer count = 1;
for(DOM.XMLNode child3 : child2.getChildElements()){
if(child3.getName()=='item'){
SageProductItems sgPr = new SageProductItems();

Boolean isWareHouseProduct = false;
for(DOM.XMLNode child4 : child3.getChildElements()){
if(child4.getName()=='NAME'){
if(whereHouseItems.contains(child4.getText()))
isWareHouseProduct = true;
}else if(child4.getName()=='ITEM_MAKE'){
sgPr.brand = child4.getText();
}else if(child4.getName()=='ITEM_MODEL_NUMBER'){
sgPr.modelNo = child4.getText();
}else if(child4.getName()=='ITEM_SERIAL_NUMBER'){
sgPr.serNo = child4.getText();
}else if(child4.getName()=='RENTAL_RATE' && String.isNotBlank(child4.getText())){
sgPr.rentalPrice = Decimal.valueOf(child4.getText());
}else if(child4.getName()=='SALE_PRICE' && String.isNotBlank(child4.getText())){
sgPr.salesPrice =  Decimal.valueOf(child4.getText());
}else if(child4.getName()=='ITEM_STATUS'){
sgPr.condi = child4.getText();
}
}
sgPr.location = wareHouseLocationId;
if(isWareHouseProduct){
sgPr.srNo = count;
count = count+1;
sageProducts.add(sgPr);
}
}                                       
}
}

if(child2.getName()=='errormessage'){
for(DOM.XMLNode child3 : child2.getChildElements()){
if(child3.getName()=='error'){
for(DOM.XMLNode child4 : child3.getChildElements()){
if(child4.getName()=='description2'){
rw.errorMsg = child4.getText();
break;
}
}
if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){
break;
}
}
}
}
}
}
}
if(child.getName()=='errormessage'){
for(DOM.XMLNode child1 : child.getChildElements()){
if(child1.getName()=='error'){
for(DOM.XMLNode child2 : child1.getChildElements()){
if(child2.getName()=='description2'){
rw.isSuccess = false;
rw.errorMsg = child2.getText();
break;
}
}
}
}
}
}

}else If(sw.errorMsg!=null && sw.errorMsg.trim().length()>0){
rw.isSuccess = false;
rw.errorMsg = sw.errorMsg;
}else{
rw.isSuccess = false;
rw.errorMsg = 'Unknown error occured. Please contact your admin.';
}
*/
    }
    
    public pageReference prcToRental(){
        isRentalOrSellType = 'Rent';
        getStripeDetails();
        return page.SearchInstrumentRentalDeliveryPage_Ipad3;
    }
    
    public pageReference prcToSell(){
        isRentalOrSellType = 'Sell';       
        getStripeDetails();
        return page.SearchInstrumentRentalDeliveryPage_Ipad3;
    }
    
    public void setSlcdPiano(){
        System.debug('@@@@@-->'+slctdPianoOpt);
        //CH02
        //slcdPiano = sageProducts.get(slctdPianoOpt-1); old
        slcdPiano = netSuiteProducts.get(slctdPianoOpt-1);
        system.debug('slcdPiano -> '+ slcdPiano);

        //CH06 will fetch the tax rate from the selected piano center
        if( String.isNotBlank( slcdPiano.location ) ){
            List< Account > listCenterAccnt = [ SELECT ID, Country__r.Tax_Rate__c  FROM Account 
                                                WHERE Country__r.Tax_Rate__c  <> NULL 
                                                AND Recordtype.Name=:ConstantsClass.centerRecTypeName
                                                AND NAME =: slcdPiano.location
                                                LIMIT 1 ];

            if( listCenterAccnt.size() > 0 ){
                gstAmount = BillingUtility.roundOffAmount(listCenterAccnt[0].Country__r.Tax_Rate__c); 
            }else{ //incase no center is found
                gstAmount = 0;
            }
            
        }else{ //incase piano center is blank make it 0
            gstAmount = 0;
        }
        System.debug( 'gstAmount --> ' + gstAmount );
        //CH06 END
        //CH02
    }
    // added by nishi: 23-Sep-2020: for stripe id and other country details the enrollment's center was inserted according to the home page selected center. So we get stripe details according to this center   
    public void getStripeDetails(){
        system.debug('slcdPiano -> '+ slcdPiano.location);
        system.debug('slcdEnrolment -> '+ slcdEnrolment);
        if( string.isBlank(slcdEnrolment.id)){
           isAlreadyStripCstmr = false;
            parentAcc.Centre_Name__c = slcdCenter;
            parentAcc.Phone =  PersonMobilePhoneCustom;
            system.debug('PersonMobilePhoneCustom -> '+ PersonMobilePhoneCustom);
            if(parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name,Stripe_Customer_Id__c,Card_Number__c,Card_Type__c,Card_Image__c,
                                            BillingStreet,BillingCity,BillingPostalCode,BillingCountryCode
                                        FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
                if(accList.size() > 0){
                    parentAcc.Id = accList.get(0).Id;
                    parentAcc.BillingStreet      = accList.get(0).BillingStreet;
                    parentAcc.BillingCity        =accList.get(0).BillingCity;
                    parentAcc.BillingPostalCode  = accList.get(0).BillingPostalCode;
                    if(accList.get(0).Stripe_Customer_Id__c != null && accList.get(0).Card_Number__c != null && accList.get(0).Card_Type__c != null){
                        stripeCstmrId = accList.get(0).Stripe_Customer_Id__c;
                        cardNumber    = accList.get(0).Card_Number__c;
                        cardType      = accList.get(0).Card_Type__c;            
                        cardImage     = accList.get(0).Card_Image__c;
                        isAlreadyStripCstmr = true;
                    }
                }
                
            }
            upsert parentAcc;
            List<Account> centerlist =  [Select id,Name,Organisation__c,country__r.name from account where id=:slcdCenter and recordtype.Name=:ConstantsClass.centerRecTypeName];
            
            system.debug('centerlist -> '+ centerlist);
            if(centerlist != null && centerlist.size() > 0){
                parentAcc.BillingCountryCode  = centerlist.get(0).country__r.name;
                String organisationId          = centerlist[0].Organisation__c;
                system.debug('organisationId -> '+ organisationId);
                if(string.isBlank(stripeBaseUrl) && string.isBlank(apiKey) && string.isBlank(stripeApiSecKey) && 
                string.isBlank(templateId) && string.isBlank(folderId)){
                    Map<String,Organisation__c> organisationMap = BillingUtility.getOrganisationMap(organisationId);
                    if(organisationMap.containsKey(organisationId)){
                        stripeBaseUrl       = organisationMap.get(organisationId).Stripe_Base_Url__c;
                        apiKey              = organisationMap.get(organisationId).Stripe_Publishable_Key__c;
                        stripeApiSecKey     = organisationMap.get(organisationId).Stripe_Secret_Key__c;
                        countryCurrencyCode = organisationMap.get(organisationId).country__r.Currency_Code__c;
                        fm.gstTaxPer        =  Integer.valueOf(organisationMap.get(organisationId).Tax_Rate__c);
                        templateId          = organisationMap.get(organisationId).Student_Policies_Template_Id__c;
                        folderId            = organisationMap.get(organisationId).Folder__c;
                    
                    }

                    system.debug('apiKey -> '+ apiKey);
                    system.debug('folderId -> '+ folderId);
                    if(String.isBlank(countryCurrencyCode)) 
                        countryCurrencyCode = ConstantsClass.currencyCode;
                }
            }
            List<Enrolment__c> enrList = [SELECT Id, Name, Parent__c, Parent__r.FirstName, Parent__r.LastName, Parent__r.PersonEmail, Model__c, Serial_Number__c,
                                          Rental_price_per_month__c 
                                          FROM Enrolment__c WHERE Parent__c =: parentAcc.Id and stage__c = null and RecordType.Name ='Instrument Rental'];  
            if(enrList!= null && enrList.size() >0){
                slcdEnrolment.id = enrList[0].id;
            }
            /*start: added by nishi:23-Sep-2020 for insert parent and student id */  
            String enrInsRenRecId =  Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();  
            slcdEnrolment.Parent__c     = parentAcc.Id;
            slcdEnrolment.Student__c    = parentAcc.Id;
            slcdEnrolment.RecordTypeId  = enrInsRenRecId;
            slcdEnrolment.Type__c       = 'Instrument';
            slcdEnrolment.Center__c = slcdCenter;
            upsert slcdEnrolment;
            /*end: added by nishi:23-Sep-2020 for insert parent and student id */   
        }
    }
    
    Public void nextWeek(){
        //this.calStartDate   = this.calStartDate.addDays(7);
        this.calStartDate   = this.calEndDate.addDays(1);
        fetchDates();
        dtimeslot.clear();
    }
    Public void prevWeek(){
        if(calStartDate.addDays(-7) > System.today()){
            this.calStartDate   = this.calStartDate.addDays(-7);
            fetchDates();
        }
    }
    public void fetchDates(){
        
        DateTime strtdate = (DateTime)calStartDate;
        if(strtdate.format('E')=='Sun')
            calStartDate = calStartDate.addDays(1);
        
        if(strtdate.format('E')=='Mon')
            this.calEndDate = calStartDate.addDays(5);
        else
            this.calEndDate = calStartDate.addDays(6);
        
        Date startDt = this.calStartDate;
        Date endDt   = this.calEndDate;
        dateslotmap = new map<date,list<string>>();
        Datetime dt;
        list<string> timeslotlst = new list<string>{'9am - 12pm','12pm - 3pm','3pm - 6pm'};
            
            Set<Date> publicHolidayDate = new Set<Date>();
        for(Public_Holiday__c pubHoliday: [SELECT Id, Name, Public_Holiday_Date__c,Organisation_Status__c FROM Public_Holiday__c 
                                           WHERE Organisation__c =: cenOrgId AND Public_Holiday_Date__c >=:calStartDate AND Public_Holiday_Date__c <=: calEndDate AND Status__c IN('Draft') ]){
                                               publicHolidayDate.add(pubHoliday.Public_Holiday_Date__c);                               
                                           }
        
        while(startDt<=endDt){
            if(!publicHolidayDate.contains(startDt)){
                dt = (DateTime)startDt;
                
                dateslotmap.put(startDt,timeslotlst);
                if(dt.format('E')!='Sat'){
                    dateslotmap.put(startDt,timeslotlst);
                    startDt = startDt.addDays(1);
                }else{
                    dateslotmap.put(startDt,new list<string>{'9am - 12pm'});
                    startDt = startDt.addDays(2);
                }
            }else{
                // dateslotmap.put(startDt,new list<string>());
                startDt = startDt.addDays(1);
                endDt = endDt.addDays(1);
            }
        }
        
        this.calEndDate = endDt;
    }
    
    //Added by Rajesh: 19th Sept 2019. To populate updated information in panda doc
    public void  updateCstmrDetail(){        
        //update parentAcc;//;// commented by nishi:23-Sep-2020: according to  new requirement we update or insert customer details
        upsert parentAcc;
    }
    Public void signAgreement(){
        documentDetails = new PandaDocUtility.CreateDocument();
        if(String.isNotBlank(ParentAcc.id)){
            String body = fillCreateDocumentWrapper(slcdEnrolment);  
            documentDetails = PandaDocUtility.createDocument(body);   
        }  
        
    }
    
    Public Void waitAgreement(){
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        if(String.isNotBlank(documentDetails.id)){
            document = PandaDocUtility.viewDocument(documentDetails.id);
        } 
    }
    
    Public void sendAgreement(){
        DocumentWrapper.SendDocument sendDocument;
        String body = '';
        
        if(String.isNotBlank(documentDetails.id)){
            sendDocument = new DocumentWrapper.SendDocument('Hello! This document was sent from the PandaDoc API.', true);      
            body = JSON.serialize(sendDocument);
            documentDetails = PandaDocUtility.sendDocument(body, documentDetails.id);
            System.debug('@@@documentDetails'+documentDetails);
        }
    }
    
    
    Public void createSession(){
        if(String.isNotBlank(parentAcc.id) && String.isNotBlank(documentDetails.id)){
            String body = '{ "recipient": "'+parentAcc.personemail+'", "lifetime": 3600}';   
            sessionDetails = PandaDocUtility.createSession(documentDetails.id, body);
            System.debug('@@@sessionDetails'+sessionDetails);
            if(String.isNotBlank(sessionDetails.id)){
                sessionId = sessionDetails.id;     
            }
        }
    }
    
    Public void createSessForAureusGrp(){
        if(String.isNotBlank(parentAcc.id) && String.isNotBlank(documentDetails.id)){
            String userEmail = [SELECT Id,Email FROM User WHERE Id=:Userinfo.getUserId() LIMIT 1].Email;
            String body = '{ "recipient": "'+userEmail+'", "lifetime": 3600}';   
            sessionDetails = PandaDocUtility.createSession(documentDetails.id, body);
            System.debug('@@@sessionDetails'+sessionDetails);
            if(String.isNotBlank(sessionDetails.id)){
                sessionId = sessionDetails.id;     
            }
        }
    }
    
    
    private String fillCreateDocumentWrapper(Enrolment__c enrolDetail){        
        String jsonBody = '';   
        
        List<Enrolment__c> enrList = [SELECT Id, Name, Parent__c, Parent__r.FirstName, Parent__r.LastName, Parent__r.PersonEmail, Model__c, Serial_Number__c, Rental_price_per_month__c 
                                      FROM Enrolment__c WHERE Id =: enrolDetail.Id];
        List<User> userList = [SELECT Id,FirstName,LastName,Email FROM User WHERE Id=: Userinfo.getUserId()];
        
        if(enrList.size() > 0 && userList.size() > 0){
            String pandaFolderId   =  'Hk2younc4gRoh696TvY6yn';
            String pandaTemplateId =  '9LbUZRRrAofSkQ3ECrYfEB';
            if(isRentalOrSellType.equalsIgnoreCase('Sell')){
                pandaFolderId   = 'LQ66xcYvjjSZebir2cCUW8';
                pandaTemplateId = 'q6ScM9GBwi7UAzutYCfS8m';
            }
            
            Enrolment__c enrolmentObj = enrList.get(0);
            User curntUsr = userList.get(0);
            
            //DocumentWrapperForPianoAgreement.recipients recipientTransporter = new DocumentWrapperForPianoAgreement.recipients();     
            DocumentWrapperForPianoAgreement.recipients recipientClient = new DocumentWrapperForPianoAgreement.recipients();     
            DocumentWrapperForPianoAgreement.CreateDocument createDocWrapper = new DocumentWrapperForPianoAgreement.CreateDocument();  
            createDocWrapper.recipients = new List<DocumentWrapperForPianoAgreement.Recipients>();     
            List<DocumentWrapperForPianoAgreement.Tokens> tokens = new List<DocumentWrapperForPianoAgreement.Tokens>();
            
            createDocWrapper.name = '';    
            //Set template and folder Id
            createDocWrapper.template_uuid =  pandaTemplateId;   
            createDocWrapper.folder_uuid = pandaFolderId;
            /*
recipientTransporter.first_name = curntUsr.FirstName;        
recipientTransporter.last_name = curntUsr.LastName;     
recipientTransporter.email = curntUsr.Email;
recipientTransporter.role = 'AureusGrp';      
recipientTransporter.recipient_type = 'signer';  
recipientTransporter.has_completed = true;  
createDocWrapper.recipients.add(recipientTransporter);  */
            
            // pass a list of tokens/values to pre-fill tokens used in a template
            ///added by nishi: 2-Oct-2020: for if enrolment not exist then we get deatils to parent account;
                if(string.isBlank(enrolmentObj.id)){ 
                    tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Parent_First_Name__c',parentAcc.FirstName));
                    tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Parent_Last_Name__c', parentAcc.LastName));
                }else{
                    tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Parent_First_Name__c', enrolmentObj.Parent__r.FirstName));
                    tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Parent_Last_Name__c', enrolmentObj.Parent__r.LastName));
                }
            ///added by nishi:end: 2-Oct-2020: for if enrolment not exist then we get deatils to parent account;
            //CH02 Changes after NetSuite Integration
            
            /*tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Model__c', slcdPiano.modelNo));
tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Serial_Number__c', slcdPiano.serNo)); 
tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Rental_price_per_month__c', ''+(slcdPiano.rentalPrice !=null ? slcdPiano.rentalPrice : 0)));
tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Deposit__c', ''+(fm.depFee!=null ? fm.depFee : 0)));
tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Delivery__c', ''+(fm.deliCharges!=null ? fm.deliCharges : 0)));
tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Selling__c', ''+(slcdPiano.salesPrice!=null ? slcdPiano.salesPrice : 0)));*/
            
            tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Model__c', slcdPiano.model ));
            tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Serial_Number__c', slcdPiano.serialNumber )); 
            //CH03 Start
            //tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Rental_price_per_month__c', ''+(slcdPiano.monthlyRental  !=null ? Decimal.valueOf(slcdPiano.monthlyRental)  : 0)));
            tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Rental_price_per_month__c', ''+(slcdPiano.monthlyRental  !=null ? BillingUtility.roundOffAmount(Decimal.valueOf(slcdPiano.monthlyRental)
                                                                                                                                                                    + (Decimal.valueOf(slcdPiano.monthlyRental)) * gstAmount /100) : 0)));
            //CH03 END
            tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Deposit__c', ''+(fm.depFee!=null ? fm.depFee : 0)));
            tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Delivery__c', ''+(fm.deliCharges!=null ? fm.deliCharges : 0)));
            tokens.add(new DocumentWrapperForPianoAgreement.Tokens('Selling__c', ''+(slcdPiano.listPrice !=null ? Decimal.valueOf(slcdPiano.listPrice)  : 0)));
            
            //CH02 END
            ///added by nishi: 2-Oct-2020: for if enrolment not exist then we get deatils to parent account;
            if(string.isBlank(enrolmentObj.id)){ 
                createDocWrapper.metadata.salesforceAccount_id = parentAcc.id;     
                recipientClient.first_name = parentAcc.FirstName;        
                recipientClient.last_name = parentAcc.LastName;      
                recipientClient.email = parentAcc.PersonEmail; 
                  createDocWrapper.name += parentAcc.FirstName+'-'+parentAcc.LastName + '-';  
            }else{
                if(enrolmentObj.Parent__c != null){       
                    createDocWrapper.metadata.salesforceAccount_id = enrolmentObj.Parent__c;     
                    recipientClient.first_name = enrolmentObj.Parent__r.FirstName;        
                    recipientClient.last_name = enrolmentObj.Parent__r.LastName;      
                    recipientClient.email = enrolmentObj.Parent__r.PersonEmail; 
                      createDocWrapper.name += enrolmentObj.name + '-';  
                }      
            }
            recipientClient.recipient_type = 'signer';  
            recipientClient.has_completed = true;  
            recipientClient.role = 'Client';      
            createDocWrapper.recipients.add(recipientClient); 
            
            createDocWrapper.tokens = tokens;
            createDocWrapper.name += 'RentalAgreement';       
            if(String.isNotBlank(createDocWrapper.name)){       
                jsonBody = JSON.Serialize(createDocWrapper).replaceAll('pandadoc_Default_Section_XYZ','default');   
                jsonBody = jsonBody.replaceAll('pandadoc_Currency_Code_XYZ','currency');     
                System.debug('createDocWrapper '+createDocWrapper);     
                System.debug('createDocWrapper '+createDocWrapper.metadata);        
                jsonBody = jsonBody.replaceAll('salesforceAccount_id','salesforce.account_id');     
                jsonBody = jsonBody;  
                system.debug('jsonBody'+jsonBody);      
            }
        }
        /*DocumentWrapper.Fields field;       
DocumentWrapper.recipients recipient = new DocumentWrapper.recipients();        
List<DocumentWrapper.Rows> rows = new List<DocumentWrapper.Rows>();     
List<DocumentWrapper.Sections> sections = new List<DocumentWrapper.Sections>();     
List<DocumentWrapper.PricingTable> pricingTables = new List<DocumentWrapper.PricingTable>();        
DocumentWrapper.CreateDocument createDocWrapper = new DocumentWrapper.CreateDocument();     

createDocWrapper.template_uuid = templateId;   
createDocWrapper.folder_uuid = folderId;
if(String.isNotBlank(ParentAcc.Id)){       
createDocWrapper.metadata.salesforceAccount_id = ParentAcc.Id;     
recipient.first_name = ParentAcc.firstName;        
recipient.last_name = ParentAcc.lastName;      
recipient.email = ParentAcc.personemail;     
field = new DocumentWrapper.Fields(ParentAcc.firstName +' '+ParentAcc.lastName, 'Parent Name');       
createDocWrapper.fields = new DocumentWrapper.CustomField(field);       
recipient.role = 'Client';      
createDocWrapper.recipients = new List<DocumentWrapper.Recipients>();       
createDocWrapper.recipients.add(recipient);     
}       
if(enrolDetail.Id != null){      
DateTime enrolmentDateTime;     
createDocWrapper.name = '';     
DocumentWrapper.Rows row;  

for(Enrolment__c enrolmentObj:[SELECT Id, Name, Lessons_Start_Date__c, Lesson_Start_time__c, Student__r.FirstName, Student__r.LastName, Package__r.Name 
FROM Enrolment__c WHERE Id =: enrolDetail.Id]){
//  enrolmentDateTime = DateTime.newInstance(enrolmentObj.Lessons_Start_Date__c, enrolmentObj.Lesson_Start_time__c);  
//createDocWrapper.name += enrolmentObj.name + '-';       
row = new DocumentWrapper.Rows(new DocumentWrapper.Data(enrolmentObj.Student__r.FirstName + ' ' + enrolmentObj.Student__r.LastName), new DocumentWrapper.CustomFields('', '',''));      
rows.add(row);   
}   

sections.add(new DocumentWrapper.Sections('Sample Title', rows));       
pricingTables.add(new DocumentWrapper.PricingTable('PricingTable1', sections));     
createDocWrapper.pricing_tables = new List<DocumentWrapper.PricingTable>();     
createDocWrapper.pricing_tables = pricingTables;        
createDocWrapper.name += 'StudentPolicy';       

}       

if(String.isNotBlank(createDocWrapper.name)){       
jsonBody = JSON.Serialize(createDocWrapper).replaceAll('pandadoc_Default_Section_XYZ','default');   
jsonBody = jsonBody.replaceAll('pandadoc_Currency_Code_XYZ','currency');     
System.debug('createDocWrapper '+createDocWrapper);     
System.debug('createDocWrapper '+createDocWrapper.metadata);        
jsonBody = jsonBody.replaceAll('salesforceAccount_id','salesforce.account_id');     
JSONBody = jsonBody;        
}       

System.debug('@@@jsonBody'+jsonBody);       
*/     
        
        
        return jsonBody;        
    }
    
    public List<SelectOption> getCountries(){
        List<SelectOption> countries = new List<SelectOption>();    
        countries.add(new SelectOption('', '--Select Country--'));
        countries.addAll(fillPicklistValues('Account', 'BillingCountryCode'));
        
        return countries;
    }
    
    private List<SelectOption> fillPicklistValues(String ObjectApi_name,String Field_name){
        List<SelectOption> selectOptionList = new List<SelectOption>();
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map    = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values   = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        
        for(Schema.PicklistEntry a : pick_list_values){ //for all values in the picklist list
            selectOptionList.add(new SelectOption(a.getValue(), a.getLabel()));
        }
        
        return selectOptionList;
    }
    
    
    Public PageReference saveAndCompleteProcess(){
        Savepoint sp;
        isError = false;
        errorMsg = '';
        system.debug('in this process');
        //CH02 Karan Singh 17 sep 2020 : Before doing any process, checking that if the selected piano is still avaiable
        NetSuite_Integration_Creds__c objNetSuiteCred = NetSuite_Integration_Creds__c.getValues('Aureus Inventory Search');
        
        if( objNetSuiteCred == null ){
            
            errorMsg = 'NetSuite credentails(Aureus Inventory Search) not available. Please contact System Admin for this.';
            isError = true;
            return null;
        }
        HTTPResponse resp = NetSuiteIntegrationUtility.sendNetSuiteRequest( objNetSuiteCred,'{"serialNumber": "'+slcdPiano.serialNumber  + '","productId": "'+slcdPiano.productId+'"}' ,'saveAndCompleteProcess() :Inventory Search');
        //when the selected piano is not avaiable in the inventory
        if(resp.getBody().contains('[]')){
            
            errorMsg = 'Requested piano not available.';
            isError = true;
            return null;
            
        }
        //Incase when the authentication failed due to encrypted request
        else if( resp.getStatusCode() != 200 ){
            
            errorMsg = 'An error occurred while processing the request. Please try again. StatusCode : ' +resp.getStatusCode();
            isError = true;
            return null;
        }
        //CH02 END
        
        EnrollmentProcessErrorLogs.errorLogObj errorObj = new EnrollmentProcessErrorLogs.errorLogObj();
        system.debug('in this process'+stripeToken);
        system.debug('in this process'+isAlreadyStripCstmr);
        if(isAlreadyStripCstmr || (stripeToken!=null && stripeToken.trim().length()>0)){
            try{     
                String last4CardNumber;
                String cardType;
                Integer exp_month;
                Integer exp_year;
                
                //Updated by Rajesh, 30th June 2019, for American club member
                ////commented by jatin: 20-feb:2020: for manage offline card reference id is also balnk then we create stripe orther wise not
                //if(!isAlreadyStripCstmr || (String.isBlank(stripeCstmrId) && (string.isBlank(customerRefId) && string.isBlank(paymentType))){  
                
                if(!isAlreadyStripCstmr || (String.isBlank(stripeCstmrId) && (string.isBlank(customerRefId) && string.isBlank(paymentType)))){  
                    
                    String cusName = String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName : ' ';
                    cusName += parentAcc.LastName;
                    
                    BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(stripeToken, cusName, parentAcc.PersonEmail, 'Parent customer', stripeBaseUrl, stripeApiSecKey); 
                    
                    if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){ 
                        stripeCstmrId = sCstmr.id;
                        
                        BillingUtility.cls_sources srcs = sCstmr.sources;
                        if(srcs.stripeData.size() > 0){
                            BillingUtility.cls_data clData  = srcs.stripeData.get(0);
                            last4CardNumber = clData.last4;
                            cardType = clData.brand;
                            exp_month = clData.exp_month;
                            exp_year  = clData.exp_year;
                        }
                    }else{
                        errorMsg = sCstmr.error.message;
                        isError = true;
                        return null;
                    } 
                }
                
                if(String.isNotBlank(stripeCstmrId)){ 
                    Decimal amountInSmallUnit      = fm.grandTot;
                    BillingUtility.stripeCharge sc = BillingUtility.createChargeForCustomer(stripeCstmrId,amountInSmallUnit, countryCurrencyCode, stripeBaseUrl, stripeApiSecKey);
                    
                    if(sc.statusCode == 200 && sc.paid){
                        sp = Database.setSavepoint();
                        String csmrRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(); 
                        parentAcc.RecordTypeId   = csmrRecId;
                        parentAcc.Stripe_Customer_Id__c = stripeCstmrId;
                        if(String.isNotBlank(last4CardNumber))
                            parentAcc.Card_Number__c = last4CardNumber;
                        if(String.isNotBlank(cardType))
                            parentAcc.Card_Type__c = cardType;
                        
                        parentAcc.Expiry_Month__c = exp_month;
                        parentAcc.Expiry_Year__c = exp_year;
                        
                        parentAcc.Centre_Name__c = slcdCenter;
                        // parentAcc.Enroled__c     = true;
                        // parentAcc.Enroled_Date__c= System.today();
                        List<Account> centrList = [SELECT Id, Name, Location__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
                        if(centrList.size() > 0){
                            parentAcc.Location__c = centrList.get(0).Location__c;
                            //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                            if(centrList.get(0).Country__r.Country_Name__c != null)
                                parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                        }
                        //update parentAcc;// commented by nishi:23-Sep-2020: according to  new requirement we update or insert customer details 
                        upsert parentAcc;  
                        //Filling enrolment
                        if(isRentalOrSellType.equalsIgnoreCase('Rent'))
                            slcdEnrolment.Stage__c = 'Piano Rental Active';
                        else
                            slcdEnrolment.Stage__c = 'Piano Sold';
                        slcdEnrolment.Cancellation_Policy_Agreed__c = true;
                        slcdEnrolment.No_of_Stairs__c = nostairs;
                        slcdEnrolment.Center__c = slcdCenter;
                        
                        //CH02 Changes after Net Suite Integration
                        
                        /*slcdEnrolment.Model__c = slcdPiano.modelNo;
slcdEnrolment.Serial_Number__c = slcdPiano.serNo;
slcdEnrolment.Brand__c = slcdPiano.brand;
slcdEnrolment.Rental_price_per_month__c = slcdPiano.rentalPrice;
slcdEnrolment.Selling_price__c = slcdPiano.salesPrice;*/
                        
                        slcdEnrolment.Model__c = slcdPiano.model ;
                        slcdEnrolment.Serial_Number__c = slcdPiano.serialNumber ;
                        slcdEnrolment.Brand__c = slcdPiano.brand ;
                        slcdEnrolment.Rental_price_per_month__c = Decimal.valueOf(slcdPiano.monthlyRental );
                        slcdEnrolment.Selling_price__c = Decimal.valueOf(slcdPiano.listPrice );
                        slcdEnrolment.Product_Id__c =  'R-' + slcdPiano.productId; //newly added
                        //CH02 END
                        slcdEnrolment.Delivery_Charges__c= fm.deliCharges > 0 ? fm.deliCharges : 0;
                        slcdEnrolment.Stair_Charges__c = fm.stairDelCharges > 0 ? fm.stairDelCharges : 0;
                        Integer count = 1;
                        system.debug('!!dtimeslot'+dtimeslot);
                        for(DateTimeSlot dSlot: dtimeslot){  
                            system.debug('!!dSlot'+dSlot);
                            List<string> tList = dSlot.dtTime.split(' \\(');
                            system.debug('!!tList'+tList);
                            
                            tList = tList.get(1).split('-');
                            String stTime = tList.get(0);
                            String endTime = tList.get(1);
                            Integer lsStartTime;
                            system.debug('!!stTime'+stTime);
                            if(stTime.contains('am')){
                                lsStartTime = Integer.valueOf(stTime.split('am').get(0));
                            }else if(stTime.contains('pm')){
                                lsStartTime = Integer.valueOf(stTime.split('pm').get(0));
                                if(lsStartTime != 12)
                                    lsStartTime = lsStartTime + 12;
                            }
                            system.debug('!!lsStartTime'+lsStartTime);
                            Time deliverTime = Time.newInstance(lsStartTime, 0, 0, 0);
                            
                            slcdEnrolment.put('Delivery_Option_Date_'+count+'__c', dSlot.dt.date());
                            slcdEnrolment.put('Delivery_Option_Timeslot_'+count+'__c', deliverTime);
                            
                            count = count+1;
                        }
                        
                        //CH01  Karan Singh25 March   
                        slcdEnrolment.Offline_Signing_Selected__c = isCustmrOptedOfflineSign; 
                        //CH01 END     
                        //CH03 updating the Instrument type -piano only
                        //CH05 any instrunemnt which can be piano,violin etc
                        slcdEnrolment.Instrument_Type__c = slcdPiano.inventoryType;
                        //CH05 END
                        //CH03
                        //update slcdEnrolment;// commented by nishi:23-Sep-2020: according to  new requirement we update or insert customer details
                        upsert slcdEnrolment;
                        //Mark as complete booking which created trail earlier
                        List<Booking__c> bookList = [SELECT Id, Status__c FROM Booking__c where Enrolment__c=: slcdEnrolment.Id AND Type__c IN ('Trial','Piano Viewing') AND Status__c != 'Completed'];
                        if(bookList.size() > 0){
                            for(Booking__c b: bookList)
                                b.Status__c = 'Completed';
                            update bookList;
                        }
                        
                        
                        Subscription__c subs = new Subscription__c();
                        Subscription_Line_Item__c subLItm = new Subscription_Line_Item__c();
                        if(isRentalOrSellType.equalsIgnoreCase('Rent')){ 
                            //Filling subscription
                            List<Subscription__c> subsList = [SELECT Id, Parent__c, Center__c FROM Subscription__c  
                                                              WHERE Parent__c =: parentAcc.Id AND Center__c =: slcdEnrolment.Center__c 
                                                              AND Status__c =: ConstantsClass.activeStatus LIMIT 1];                       
                            
                            if(subsList.size() > 0){
                                subs = subsList.get(0);
                            }else{
                                subs = BillingUtility.fillSubscription(parentAcc.Id, ConstantsClass.activeStatus, null);
                                subs.Center__c = slcdEnrolment.Center__c;
                            }                        
                            upsert subs;
                            
                            subLItm = BillingUtility.fillSubscriptionLineItem(null, null, null, slcdEnrolment.Id, null, ConstantsClass.activeStatus);
                            subLItm.Subscription__c = subs.Id;
                            
                            //CH02 Changes after NetSuite Integration
                            //subLItm.Amount__c = slcdPiano.rentalPrice;
                            subLItm.Amount__c = Decimal.valueOf(slcdPiano.monthlyRental) ;
                            //CH02 END
                            //subLItm.Subscription_Start_Date__c = enr.Lessons_Start_Date__c;
                            //subLItm.Next_Bill_Date__c   = subsNextBillingDate;
                            insert subLItm;
                        }
                        
                        //Filling Invoice
                        Invoice__c inv        = new Invoice__c();                       
                        inv = BillingUtility.fillInvoice(null, parentAcc.Id, ConstantsClass.paidStatus);
                        inv.Center__c = slcdEnrolment.Center__c; 
                        inv.Subscription__c = subs.Id;
                        inv.invoice_type__c = 'New Enrolment';
                        insert inv;
                        
                        String payTrnRecId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
                        Payment__c pay        = BillingUtility.fillPayment(parentAcc.Id, inv.Id, fm.grandTot, ConstantsClass.successStatus);
                        pay.RecordtypeId      = payTrnRecId;
                        pay.Method_of_Payment__c = 'Card';
                        pay.Transaction_ID__c = sc.id; 
                        pay.Invoice__c        = inv.Id;
                        insert pay;
                        
                        List<Invoice_Line_Item__c> invLineItmList     = new List<Invoice_Line_Item__c>();
                        String remarksStr = '';
                        if(fm.instrumentChrg> 0){
                            
                            //CH02 
                            //remarksStr = slcdPiano.brand;
                            remarksStr = slcdPiano.brand;
                            //CH02 END
                            //
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, fm.instrumentChrg, remarksStr, slcdEnrolment.Teacher__c);
                            invLnItm.Teacher_Id__c = null;
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = slcdEnrolment.Id; 
                            invLnItm.Month__c     =  System.today();
                            
                            //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                            Decimal tempTotAmt = invLnItm.Amount__c; 
                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);
                            
                            invLineItmList.add(invLnItm);
                        }
                        if(fm.depFee > 0){
                            remarksStr = ConstantsClass.pkgDepFeesDes;
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null,fm.depFee, remarksStr, slcdEnrolment.Teacher__c);
                            invLnItm.Teacher_Id__c = null;
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = slcdEnrolment.Id;
                            invLnItm.Subscription_Line_Item__c = subLItm.Id;
                            invLnItm.Is_Deposit__c = true;
                            invLnItm.Month__c     =  System.today();
                            invLineItmList.add(invLnItm);
                        }
                        if(fm.deliCharges> 0){
                            remarksStr = 'Delivery Charges ';
                            if(isRentalOrSellType.equalsIgnoreCase('Rent'))
                                remarksStr += '(2-way)';
                            else    
                                remarksStr += '(1-way)';
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, fm.deliCharges, remarksStr, slcdEnrolment.Teacher__c);
                            invLnItm.Teacher_Id__c = null;
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = slcdEnrolment.Id; 
                            invLnItm.Month__c     =  System.today();
                            Decimal tempTotAmt = invLnItm.Amount__c; 
                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
                            invLineItmList.add(invLnItm);
                        }                        
                        if(fm.tuningFee> 0){
                            remarksStr = 'Tuning Fee';
                            
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null,fm.tuningFee, remarksStr, slcdEnrolment.Teacher__c);
                            invLnItm.Teacher_Id__c = null;
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = slcdEnrolment.Id; 
                            invLnItm.Month__c     =  System.today();
                            Decimal tempTotAmt = invLnItm.Amount__c; 
                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
                            invLineItmList.add(invLnItm);
                        }
                        if(fm.stairDelCharges> 0){
                            remarksStr = 'Staircase moving charges for '+ nostairs +' steps ';
                            if(isRentalOrSellType.equalsIgnoreCase('Rent'))
                                remarksStr += '(2-way)';
                            else    
                                remarksStr += '(1-way)';        
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, fm.stairDelCharges, remarksStr, slcdEnrolment.Teacher__c);
                            invLnItm.Teacher_Id__c = null;
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = slcdEnrolment.Id; 
                            invLnItm.Month__c     =  System.today();
                            Decimal tempTotAmt = invLnItm.Amount__c; 
                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
                            invLineItmList.add(invLnItm);
                        }
                        if(fm.heatingRodInsFee> 0){
                            remarksStr = 'Heating Rod Installation';
                            
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null,fm.heatingRodInsFee, remarksStr, slcdEnrolment.Teacher__c);
                            invLnItm.Teacher_Id__c = null;
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = slcdEnrolment.Id; 
                            invLnItm.Month__c     =  System.today();
                            Decimal tempTotAmt = invLnItm.Amount__c; 
                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
                            invLineItmList.add(invLnItm);
                        }
                        
                        if(invLineItmList.size() > 0)
                            insert invLineItmList;
                        
                        
                        
                        PageReference pageRef = new PageReference('/apex/thankyoupage_ipad');
                        
                        String invStr = 'inv1';
                        pageRef.getParameters().put(invStr, inv.Id);    
                        
                        //Added by Sanjay/Rajesh, 26th June 2019.  For push invoice on sageIntaccount describe by Sanjay
                        if(!test.isRunningTest()){
                            SageIntacctIntegrationUtility.newEnrolment(String.valueOf(parentAcc.Id), new Set<String>{inv.Id});
                        }
                        pageRef.getParameters().put('scId', sc.id);
                        
                        //CH02 Karan 17 sep 2020 updating the NetSuite Inventory
                        SearchInstrumentRental_IpadCntrl.pushDataToNetsuite( slcdEnrolment.Name,slcdPiano.serialNumber, slcdPiano.productId);
                        //CH02 END
                        return pageRef.setRedirect(true);
                    }else{
                        errorMsg = sc.error.message;
                        isError  = true;
                        
                        //Added by Rajesh, 30th Sept 2019. showing custom error messagge if card decliend
                        if(String.isNotBlank(sc.error.decline_code))
                            errorMsg= 'Payment Failed. Please try with a different card.';
                    }
                }
                
                
                
            }catch(Exception e){
                if(sp != null)
                    Database.rollback(sp);
                
                System.debug('Error:  '+e.getMessage()+e.getLineNumber());
                errorMsg = e.getMessage();
                isError  = true;
            }
        }
        return null;
    } 
    
    // 20-Feb-2020: Jatin: if user pay amount with offline card then we create paid status invoice then 
    //we create payment with reference charge id 
    public PageReference SaveAndCompleteProcessViaReferenceId(){
        Decimal amountInSmallUnit      = fm.grandTot;
        parentAcc.Centre_Name__c = slcdCenter;
        List<Account> centrList = [SELECT Id, Name, Location__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
        if(centrList.size() > 0){
            parentAcc.Location__c = centrList.get(0).Location__c;
            //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
            if(centrList.get(0).Country__r.Country_Name__c != null)
                parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
        }
        //update parentAcc;// commented by nishi:23-Sep-2020: according to  new requirement we update or insert customer details
        upsert parentAcc;
        //Filling enrolment
        if(isRentalOrSellType.equalsIgnoreCase('Rent'))
            slcdEnrolment.Stage__c = 'Piano Rental Active';
        else
            slcdEnrolment.Stage__c = 'Piano Sold';
         /*start: added by nishi:23-Sep-2020 for insert parent and student id */    
         if(string.isBlank(slcdEnrolment.id)){  
            String enrInsRenRecId =  Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();  
            slcdEnrolment.Parent__c     = parentAcc.Id;
            slcdEnrolment.Student__c    = parentAcc.Id;
            slcdEnrolment.RecordTypeId  = enrInsRenRecId;
            slcdEnrolment.Type__c       = 'Instrument';
         }
         /*end: added by nishi:23-Sep-2020 for insert parent and student id */  
        slcdEnrolment.Cancellation_Policy_Agreed__c = true;
        slcdEnrolment.No_of_Stairs__c = nostairs;
        slcdEnrolment.Center__c = slcdCenter;
        
        //CH02 
        /*slcdEnrolment.Model__c = slcdPiano.modelNo;
slcdEnrolment.Serial_Number__c = slcdPiano.serNo;
slcdEnrolment.Brand__c = slcdPiano.brand;
slcdEnrolment.Rental_price_per_month__c = slcdPiano.rentalPrice;
slcdEnrolment.Selling_price__c = slcdPiano.salesPrice;*/
        
        slcdEnrolment.Model__c = slcdPiano.model;
        slcdEnrolment.Serial_Number__c = slcdPiano.serialNumber;
        slcdEnrolment.Brand__c = slcdPiano.brand;
        slcdEnrolment.Rental_price_per_month__c = Decimal.valueOf(slcdPiano.monthlyRental);
        slcdEnrolment.Selling_price__c = Decimal.valueOf(slcdPiano.listPrice );
        
        //CH02 END
        slcdEnrolment.Delivery_Charges__c= fm.deliCharges > 0 ? fm.deliCharges : 0;
        slcdEnrolment.Stair_Charges__c = fm.stairDelCharges > 0 ? fm.stairDelCharges : 0;
        Integer count = 1;
        for(DateTimeSlot dSlot: dtimeslot){  
            List<string> tList = dSlot.dtTime.split(' \\(');
            
            tList = tList.get(1).split('-');
            String stTime = tList.get(0);
            String endTime = tList.get(1);
            Integer lsStartTime;
            if(stTime.contains('am')){
                lsStartTime = Integer.valueOf(stTime.split('am').get(0));
            }else if(stTime.contains('pm')){
                lsStartTime = Integer.valueOf(stTime.split('pm').get(0));
                if(lsStartTime != 12)
                    lsStartTime = lsStartTime + 12;
            }
            
            Time deliverTime = Time.newInstance(lsStartTime, 0, 0, 0);
            
            slcdEnrolment.put('Delivery_Option_Date_'+count+'__c', dSlot.dt.date());
            slcdEnrolment.put('Delivery_Option_Timeslot_'+count+'__c', deliverTime);
            
            count = count+1;
        }                        
       // update slcdEnrolment;// commented by nishi:23-Sep-2020: according to  new requirement we update or insert customer details
        upsert slcdEnrolment;
        //Mark as complete booking which created trail earlier
        List<Booking__c> bookList = [SELECT Id, Status__c FROM Booking__c where Enrolment__c=: slcdEnrolment.Id AND Type__c IN ('Trial','Piano Viewing') AND Status__c != 'Completed'];
        if(bookList.size() > 0){
            for(Booking__c b: bookList)
                b.Status__c = 'Completed';
            update bookList;
        }
        
        
        Subscription__c subs = new Subscription__c();
        Subscription_Line_Item__c subLItm = new Subscription_Line_Item__c();
        if(isRentalOrSellType.equalsIgnoreCase('Rent')){ 
            //Filling subscription
            List<Subscription__c> subsList = [SELECT Id, Parent__c, Center__c FROM Subscription__c  
                                              WHERE Parent__c =: parentAcc.Id AND Center__c =: slcdEnrolment.Center__c 
                                              AND Status__c =: ConstantsClass.activeStatus LIMIT 1];                       
            
            if(subsList.size() > 0){
                subs = subsList.get(0);
            }else{
                subs = BillingUtility.fillSubscription(parentAcc.Id, ConstantsClass.activeStatus, null);
                subs.Center__c = slcdEnrolment.Center__c;
            }                        
            upsert subs;
            
            subLItm = BillingUtility.fillSubscriptionLineItem(null, null, null, slcdEnrolment.Id, null, ConstantsClass.activeStatus);
            subLItm.Subscription__c = subs.Id;
            
            //CH02 
            //subLItm.Amount__c = slcdPiano.rentalPrice;
            subLItm.Amount__c = Decimal.valueOf(slcdPiano.monthlyRental) ;
            //CH02 END
            //subLItm.Subscription_Start_Date__c = enr.Lessons_Start_Date__c;
            //subLItm.Next_Bill_Date__c   = subsNextBillingDate;
            insert subLItm;
        }
        
        //Filling Invoice
        Invoice__c inv        = new Invoice__c();                       
        inv = BillingUtility.fillInvoice(null, parentAcc.Id, ConstantsClass.paidStatus);
        inv.Center__c = slcdEnrolment.Center__c; 
        inv.Subscription__c = subs.Id;
        inv.invoice_type__c = 'New Enrolment';
        insert inv;
        
        String payTrnRecId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        Payment__c pay        = BillingUtility.fillPayment(parentAcc.Id, inv.Id, fm.grandTot, ConstantsClass.successStatus);
        pay.RecordtypeId      = payTrnRecId;
        pay.Reference_Charge_Id__c = customerRefId;// jatin: 20-feb-2020 :add Payment mode for Offline cards
        pay.Method_of_Payment__c = paymentType; // jatin: 20-feb-2020 :add Payment mode for Offline cards
        pay.Remarks__c = 'Payment with Offline Card';
        pay.Invoice__c        = inv.Id;
        insert pay;
        
        List<Invoice_Line_Item__c> invLineItmList     = new List<Invoice_Line_Item__c>();
        String remarksStr = '';
        if(fm.instrumentChrg> 0){
            //CH02
            //remarksStr = slcdPiano.brand;
            remarksStr = slcdPiano.brand;
            //CH02 END
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.instrumentChrg), remarksStr, slcdEnrolment.Teacher__c);
            invLnItm.Teacher_Id__c = null;
            invLnItm.Invoice__c   = inv.Id;
            invLnItm.Enrolment__c = slcdEnrolment.Id; 
            invLnItm.Month__c     =  System.today();
            
            //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
            Decimal tempTotAmt = invLnItm.Amount__c; 
            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);
            
            invLineItmList.add(invLnItm);
        }
        if(fm.depFee > 0){
            remarksStr = ConstantsClass.pkgDepFeesDes;
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.depFee), remarksStr, slcdEnrolment.Teacher__c);
            invLnItm.Teacher_Id__c = null;
            invLnItm.Invoice__c   = inv.Id;
            invLnItm.Enrolment__c = slcdEnrolment.Id;
            invLnItm.Subscription_Line_Item__c = subLItm.Id;
            invLnItm.Is_Deposit__c = true;
            invLnItm.Month__c     =  System.today();
            invLineItmList.add(invLnItm);
        }
        if(fm.deliCharges> 0){
            remarksStr = 'Delivery Charges ';
            if(isRentalOrSellType.equalsIgnoreCase('Rent'))
                remarksStr += '(2-way)';
            else    
                remarksStr += '(1-way)';
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.deliCharges), remarksStr, slcdEnrolment.Teacher__c);
            invLnItm.Teacher_Id__c = null;
            invLnItm.Invoice__c   = inv.Id;
            invLnItm.Enrolment__c = slcdEnrolment.Id; 
            invLnItm.Month__c     =  System.today();
            Decimal tempTotAmt = invLnItm.Amount__c; 
            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
            invLineItmList.add(invLnItm);
        }                        
        if(fm.tuningFee> 0){
            remarksStr = 'Tuning Fee';
            
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.tuningFee), remarksStr, slcdEnrolment.Teacher__c);
            invLnItm.Teacher_Id__c = null;
            invLnItm.Invoice__c   = inv.Id;
            invLnItm.Enrolment__c = slcdEnrolment.Id; 
            invLnItm.Month__c     =  System.today();
            Decimal tempTotAmt = invLnItm.Amount__c; 
            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
            invLineItmList.add(invLnItm);
        }
        if(fm.stairDelCharges> 0){
            remarksStr = 'Staircase moving charges for '+ nostairs +' steps ';
            if(isRentalOrSellType.equalsIgnoreCase('Rent'))
                remarksStr += '(2-way)';
            else    
                remarksStr += '(1-way)';        
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.stairDelCharges), remarksStr, slcdEnrolment.Teacher__c);
            invLnItm.Teacher_Id__c = null;
            invLnItm.Invoice__c   = inv.Id;
            invLnItm.Enrolment__c = slcdEnrolment.Id; 
            invLnItm.Month__c     =  System.today();
            Decimal tempTotAmt = invLnItm.Amount__c; 
            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
            invLineItmList.add(invLnItm);
        }
        if(fm.heatingRodInsFee> 0){
            remarksStr = 'Heating Rod Installation';
            
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.heatingRodInsFee), remarksStr, slcdEnrolment.Teacher__c);
            invLnItm.Teacher_Id__c = null;
            invLnItm.Invoice__c   = inv.Id;
            invLnItm.Enrolment__c = slcdEnrolment.Id; 
            invLnItm.Month__c     =  System.today();
            Decimal tempTotAmt = invLnItm.Amount__c; 
            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && fm.gstTaxPer > 0) ? ((tempTotAmt * fm.gstTaxPer) / 100):0);                            
            invLineItmList.add(invLnItm);
        }
        
        if(invLineItmList.size() > 0)
            insert invLineItmList;
        
        
        
        PageReference pageRef = new PageReference('/apex/thankyoupage_ipad');
        
        String invStr = 'inv1';
        pageRef.getParameters().put(invStr, inv.Id);    
        
        //Added by Sanjay/Rajesh, 26th June 2019.  For push invoice on sageIntaccount describe by Sanjay
        SageIntacctIntegrationUtility.newEnrolment(String.valueOf(parentAcc.Id), new Set<String>{inv.Id});
        
        pageRef.getParameters().put('scId', '');
        return pageRef.setRedirect(true);
    }
    
    //CH02
    //For reference -> https://gist.github.com/smaeda-ks/dc5cdd50956e63bdae11314612389a07,https://stackoverflow.com/questions/15271508/netsuite-oauth-implemenation,https://github.com/metadaddy/sfdc-oauth-playground/blob/master/OAuth/src/classes/OAuth.cls
    //CH04 22 Sep 2020 : Adding method name in the paramater
    //CH07 this method is shifted to NetSuiteIntegrationUtility.apxc
    //public static HTTPResponse sendNetSuiteRequest( NetSuite_Integration_Creds__c objNetSuiteCred, String jsonRequestBody, String methodName ){
        
    //this will call the netsuite inventorty products
    public void getProducts1(){
        
        system.debug(' isAlreadyStripCstmr ->> ' + isAlreadyStripCstmr );
        NetSuite_Integration_Creds__c objNetSuiteCred = NetSuite_Integration_Creds__c.getValues('Aureus Inventory Search');
        
        if( objNetSuiteCred == null ){
            return;
        }

		//CH08 Start        
         //'{"type": "'+ instrumentType +'"}' for production
        //{ "location": "test location"}  for sandbox
        String requestBody = '{"type": "'+ instrumentType +'"}';
        if( String.isNotBlank( objNetSuiteCred.Sample_Request__c ) ){
            requestBody = objNetSuiteCred.Sample_Request__c;
        }
        HTTPResponse resp = NetSuiteIntegrationUtility.sendNetSuiteRequest( objNetSuiteCred,requestBody, 'getProducts1() : Inventory Search' );
       
        //Before CH08 HTTPResponse resp = NetSuiteIntegrationUtility.sendNetSuiteRequest( objNetSuiteCred,'{"type": "'+ instrumentType +'"}', 'getProducts1() : Inventory Search' );
        //CH08 End
        
        //checking some params so that it is ensure it doesnot contains any error json
        if( resp.getBody().contains( 'serialNumber' ) && resp.getBody().contains( 'item' ) && resp.getBody().contains( 'location' ) && resp.getBody().contains( 'inventoryType' )){
            
            netSuiteProducts = ( List<NetSuiteIntegrationUtility.NetSuiteProducts>  )JSON.deserialize(resp.getBody(), List<NetSuiteIntegrationUtility.NetSuiteProducts>.class);
            
            for( Integer index = 0; index < netSuiteProducts.size(); index++ ){
                
                netSuiteProducts[ index ].srNo = index + 1;
                system.debug(' -->  ' + netSuiteProducts[ index ] );
                
                if( String.isBlank(netSuiteProducts[ index ].listPrice) ){
                    netSuiteProducts[ index ].listPrice = '0';
                }
                if( String.isBlank(netSuiteProducts[ index ].monthlyRental) ){
                    netSuiteProducts[ index ].monthlyRental = '0';
                }
                
                //CH08 if already aureus existing customer then change the rental price
                
                if( String.isBlank(netSuiteProducts[ index ].studentPrice) ){
                    netSuiteProducts[ index ].studentPrice = '0';
                }
                
                //isAlreadyStripCstmr : this will decide if the customer is existing or not
                if( isAlreadyStripCstmr != Null && isAlreadyStripCstmr ){
                    netSuiteProducts[ index ].monthlyRental = netSuiteProducts[ index ].studentPrice;
                }
                //CH08 END

            }//end of for Loop
        }//end of response check
    }//end of getProducts1
    
    @future(callout=true)
    public static void pushDataToNetsuite( String enrolName, string serialNo, string productId ){
        
        NetSuite_Integration_Creds__c objNetSuiteCred = NetSuite_Integration_Creds__c.getValues('Convert Item to Fixed Asset');
        HTTPResponse resp = NetSuiteIntegrationUtility.sendNetSuiteRequest( objNetSuiteCred,'{"serialNumber": "'+serialNo+'","productId" : "'+productId+'"}' ,'pushDataToNetsuite() :  Convert Item to Fixed Asset');
        //String s1 = '{"error": {"code": "USER_ERROR","message": "serialNumber is required.","request_datetime": "11/09/2020 11:43:48 am"}}';
        
        //send email in case of error only
        if( resp.getBody().contains('"error"') ){
            
            NetSuiteIntegrationUtility.NetSuiteError error = ( NetSuiteIntegrationUtility.NetSuiteError )JSON.deserialize( resp.getBody() ,NetSuiteIntegrationUtility.NetSuiteError.class);
            
            Messaging.SingleEmailMessage objOutGoingEmail =  new Messaging.SingleEmailMessage();
            objOutGoingEmail.setToAddresses(new list< String >{ 'aureus@techmatrixconsulting.com'});
            objOutGoingEmail.setSubject('Piano rental Process.');
            string emailHtmlBody = 'Dear User <br/>' ;
            emailHtmlBody += ' Cannot update NetSuite Inventory with Piano Serial Number : '+serialNo+' and Product Id : '+serialNo+' of the Enrolment : '+enrolName+'<br/>';
            emailHtmlBody += ' Error Reason :'+ error.error.message +' <br/>';
            objOutGoingEmail.setHtmlBody(emailHtmlBody); 
            
            objOutGoingEmail.setTargetObjectId( UserInfo.getUserId());
            objOutGoingEmail.saveAsActivity = false;
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult[]  sendEmailResults =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] {objOutGoingEmail});
            }
        }
    }
    //CH02 END
    
    public class SageProductItems{
        public Integer srNo{get;set;}
        public String  brand{get;set;}
        public String  modelNo{get;set;}
        public String  serNo{get;set;}
        public String  location{get;set;}
        public Decimal  rentalPrice{get;set;}
        public Decimal  salesPrice{get;set;}
        public String  condi{get;set;}
        
        public SageProductItems(){
            this.rentalPrice = 0;
            this.salesPrice = 0;
        }
    }
    public class EnrolmentModel{
        public Enrolment__c enr{get;set;}
        public String enrTrialSlot{get;set;}
        
        public EnrolmentModel(Enrolment__c enr, String enrTrialSlot){
            this.enr = enr;
            this.enrTrialSlot = enrTrialSlot;
        }
    }
    public class DateTimeSlot{
        public Datetime dt{get;set;}
        public String dttime{get;set;}
        public String appid{get;set;}
        public DateTimeSlot(){
            dttime = '';
            appid = '';
        }
    }
    
    public class FeeModel{
        public Decimal instrumentChrg{get;set;}
        public Decimal depFee{get;set;}
        public Decimal deliCharges{get;set;}
        public Decimal tuningFee{get;set;}
        public Decimal perStairCharges{get;set;}
        public Decimal stairDelCharges{get;set;}
        public Decimal heatingRodInsFee{get;set;}
        public Decimal totFee{get;set;}
        public Decimal gstTaxPer{get;set;}
        public Decimal gstAmt{get;set;}
        public Decimal grandTot{get;set;}
        
        public FeeModel(){
            depFee           = Decimal.valueOf(Label.Piano_Rental_Deposit_Fee);
            deliCharges      = Decimal.valueOf(Label.Delivery_Charges);
            tuningFee        = Decimal.valueOf(Label.Tuning_Fee);
            heatingRodInsFee = Decimal.valueOf(Label.Heating_Rod_Installation_Fee);
            perStairCharges  = Decimal.valueOf(Label.Per_Stair_Charges);
            gstTaxPer		 = 7;
            instrumentChrg   = 0;
            stairDelCharges  = 0;
            totFee           = 0;
            gstAmt           = 0;
            grandTot         = 0;
        }
    }
    
    //CH02
    //CH07 move the code to the NetSuiteIntegrationUtility.apxc
    //CH02 END
}