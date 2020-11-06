/*
 *      Name        :    EnrolmentProcessForClassCtrl
 *      Date        :    2019/08/24
 *      Description :    This Controller will Show the details of Enrolment and update it.
*/
//CH01 Karan Singh 25 Aug 2020 Bypass pandaDoc Validation in case PandaDoc goes offline for maintenance purposes

public class EnrolmentProcessForClassCtrl {
    
    Public EnrolDetails enrolDetails{get;set;}
    public List<SelectOption> genderList {get;set;}
    public List<SelectOption> nationalityList{get;set;}
    public List<SelectOption> schoolList{get;set;}
    public List<SelectOption> countries{get;set;}
    
    public Boolean isAmcClubMember{get;set;}
    public Boolean isAlreadyStripCstmr{get;set;}
    public String  cardNumber{get;set;}
    public String  cardType{get;set;}
    public String  cardImage{get;set;}
    
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    public String apiKey {get;set;}
    public string stripeToken{get;set;}
    public String sessionId{get;set;}
    
    public Boolean isSiteGuestUser{get;set;}
    public String cntryName{get;set;} 
    public Boolean agreementCheckbox{get;set;}
    Set<String> setOfEnrolments; 
    String stripeCstmrId;
    String templateId;
    String stripeBaseUrl;
    String stripeApiSecKey;
    String countryCurrencyCode;
    String folderId;
    String cenOrgId;           
  Integer enrolCount;//@Juneid 06 July 2020, This variable is use to store count of enrollment
    Public boolean isOssia{get;set;}//@Juneid 20 Aug 2020, For checking Organization
    
    //Added by Rajesh, 16th Sep 2019. To store enrolment source on Enrolment/Case object and country for filtercentre
    String enrolmentSource;
   Decimal refreldiscountGst; //@Juneid 06 Aug 2020, For Calculating GST or Refferel Discount
       List<Referral_Discount__c>countryWiseRfrelDiscount;//@Juneid 10 Aug 2020, To store reffrel discount country wise
    PandaDocUtility.CreateDocument documentDetails;
    PandaDocUtility.SessionDocument sessionDetails;

     //CH01 Karan Singh 
     public Boolean isPandaDocUnderMaintance{get;set;} //for showing the bypass checkbox    
     public Boolean isCustmrOptedOfflineSign{get;set;}  
     //CH01 END 
     
    //Counstructor
    Public EnrolmentProcessForClassCtrl(){
            
        //CH01 Karan Singh  
        isPandaDocUnderMaintance = false;   
        isCustmrOptedOfflineSign = false;   
        if( String.isNotBlank(Label.Allow_Offline_Signing)){    
            isPandaDocUnderMaintance = Label.Allow_Offline_Signing.equalsIgnoreCase('true');    
        }   
        //CH01 END

        isAmcClubMember     = false;
        isAlreadyStripCstmr = false;
        setOfEnrolments= new Set<String>();
        setOfEnrolments.addAll(Apexpages.currentpage().getparameters().values());
        genderList = new List<SelectOption>();
        genderList.add(new SelectOption('', '--Select Gender--'));
        genderList.addAll(fillPicklistValues('Account', 'Gender__c'));
        nationalityList = new List<SelectOption>();
        nationalityList = fillPicklistValues('Account', 'Nationality__c');
        schoolList = new List<SelectOption>();
        schoolList.add(new SelectOption('', '--Select School--'));
        //schoolList.addAll(fillSchools());
        countries = new List<SelectOption>();
        countries.add(new SelectOption('', '--Select Country--'));
        countries.addAll(fillPicklistValues('Account', 'BillingCountryCode'));
        enrolDetails = new EnrolDetails();
        isOssia =  false;
        enrolmentSource = ApexPages.currentPage().getParameters().get('es');
        //@Juneid 05, Aug 2020
        enrolCount =  0;
        countryWiseRfrelDiscount =  new List<Referral_Discount__c>();
        
        isSiteGuestUser = (UserInfo.getName()).contains('Site');
        
        countryCurrencyCode = ConstantsClass.currencyCode;
        templateId = Label.Student_Policies_Template;
        if(setOfEnrolments.size() > 0){
            enrolDetails = fetchEnrolmentDetails(setOfEnrolments);
            //system.debug('enrolDetails--->'+enrolDetails);
            if(enrolDetails.enrolments.size() > 0){
                cntryName = enrolDetails.enrolments.values().get(0).Center__r.Country__r.Name;
                cenOrgId  = enrolDetails.enrolments.values().get(0).Center__r.Organisation__c;
                if(String.isBlank(cntryName))
                    cntryName = 'SG';
                schoolList.addAll(fillSchools(cntryName));
            }
        }
        
       /* List<Stripe_Settings__mdt> stripeSettings = [SELECT Id, Stripe_Base_Url__c, Stripe_Secret_Key__c, Stripe_Publishable_Key__c 
                                                     FROM   Stripe_Settings__mdt 
                                                     WHERE  DeveloperName =: ConstantsClass.cstmMetaDataStripe LIMIT 1];
        if(stripeSettings.size()>0)
            apiKey = stripeSettings[0].Stripe_Publishable_Key__c;
        */
        
        if(enrolDetails.enrolments.size() == 0){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No Pending Enrolment found..'));    
        }
        //templateId = Label.Student_Policies_Template;
        documentDetails = new PandaDocUtility.CreateDocument();
        sessionDetails = new PandaDocUtility.SessionDocument();
    }
        
    Private EnrolDetails fetchEnrolmentDetails(Set<String> enrolIds){
        EnrolDetails enrolDetailsToReturn = new EnrolDetails();
        Map<String, Enrolment__c> enrolmentMap = new Map<String, Enrolment__c>();
        Map<String, String> enrolmentTimeSlotMap = new Map<String, String>();
        Map<String, FeeModel> feeMap = new Map<String, FeeModel>();
        Map<String, List<AccountDetails>> mapOfParentStudent = new Map<String, List<AccountDetails>>();
        Set<String> studentSet = new Set<String>();
        String parentId;
        
       List<Enrolment__c> enrList = [SELECT Id, Name, Center__c, Center__r.Name, Teacher__c,Teacher__r.Engagement_Type__c, Teacher__r.Name, Package__r.Name, Lesson_Day__c,  Parent__r.Name,
                                      Lesson_Start_time__c, Lessons_Start_Date__c, Student__r.Name, Student__r.FirstName, Student__r.LastName, Parent__c, Parent__r.FirstName, Parent__r.LastName, 
                                      Package__c, Package__r.Package_Fee__c, Package__r.Deposit_Fee__c, Package__r.Registration_Fee__c, Package__r.Unit_Fee__c,Referral_code_used__c,//Package__r.Facility_Fee__c,
                                      Package__r.Is_Promotion_Discount__c, Package__r.Promotion_Discount__c, Package__r.Promotion_period_In_months__c,Referred_by__c,Referred_by__r.name,Referee_discount_amount__c,Referrer_discount_amount__c,Center__r.Location__c, 
                                     Package__r.Type_of_package__c,Enrolment__c.Referred_by__r.personContactId, Package__r.Registration_Discount_Active__c, Package__r.Registration_Discount_Value__c, CreatedDate,Instrument__c, 
                                      Package__r.of_Units__c, Package__r.Package_after_Promotion__c, Package__r.Duration__c, Center__r.Country__c, Package__r.Type__c, Type__c, Class__c,
                                      Center__r.Country__r.Name, Center__r.Country__r.Country_Name__c, Center__r.Country__r.Tax_Rate__c, Center__r.Organisation__c,Center__r.Organisation__r.name,
                                      (SELECT Id, Subscription__c, Enrolment__c FROM Subscription_Line_Items__r) 
                                      FROM Enrolment__c WHERE Id IN: enrolIds AND Stage__c = 'Pending Enrolment'];
        if(enrList.size() > 0){
            Integer gstTaxPer;
            //@Juneid For Checking Organization
            isOssia = enrList.get(0).Center__r.Organisation__r.name == Label.Ossia_Organisation_Name ? true : false;
            String countryId          = enrList.get(0).Center__r.Country__c;
            
            //@Juneid 19 Aug 2020,Organisation wise charge as per new logic
            String organisationId =  enrList.get(0).Center__r.Organisation__c;
           Map<String,Organisation__c>organisationMap = BillingUtility.getOrganisationMap(organisationId);
            if(organisationMap.containsKey(organisationId)){
                stripeBaseUrl       = organisationMap.get(organisationId).Stripe_Base_Url__c;
                apiKey              = organisationMap.get(organisationId).Stripe_Publishable_Key__c;
                stripeApiSecKey     = organisationMap.get(organisationId).Stripe_Secret_Key__c;
                countryCurrencyCode = organisationMap.get(organisationId).country__r.Currency_Code__c;
                gstTaxPer           =  Integer.valueOf(organisationMap.get(organisationId).Tax_Rate__c);
                templateId          = organisationMap.get(organisationId).Student_Policies_Template_Id__c;
                folderId            = organisationMap.get(organisationId).Folder__c;
                
            }
            //Juneid commented becauis elogic is change now country wise to orgnization wise
             /*  Map<String,Country__c> countryMap = BillingUtility.getCountryMap(countryId);
            if(countryMap.containsKey(countryId)){
                stripeBaseUrl       = countryMap.get(countryId).Stripe_Base_Url__c;
                apiKey              = countryMap.get(countryId).Stripe_Publishable_Key__c;
                stripeApiSecKey     = countryMap.get(countryId).Stripe_Secret_Key__c;
                countryCurrencyCode = countryMap.get(countryId).Currency_Code__c;
                gstTaxPer           =  Integer.valueOf(countryMap.get(countryId).Tax_Rate__c);
                templateId          = countryMap.get(countryId).Student_Policies_Template_Id__c;
                folderId            = countryMap.get(countryId).Folder__c;
            }*/
           
            
            if(String.isBlank(countryCurrencyCode)) 
                countryCurrencyCode = ConstantsClass.currencyCode;
            
            //Gst
           /* Integer gstTaxPer  = enrList.get(0).Center__r.Country__r.Tax_Rate__c != null ? Integer.valueOf(enrList.get(0).Center__r.Country__r.Tax_Rate__c):null;
            apiKey             = enrList.get(0).Center__r.Country__r.Stripe_Publishable_Key__c;
            countryId          = enrList.get(0).Center__r.Country__c;
            countryCurrencyCode=enrList.get(0).Center__r.Country__r.Currency_Code__c;*/
           
           /* try{
                if(gstTaxPer == null){
                    gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                }
            }catch(Exception e){}*/
            //10 Aug 2020
            String centerCountry ;
            if(enrList.size() > 0){
                centerCountry = enrList[0].Center__r.Country__r.Country_Name__c;
                countryWiseRfrelDiscount = referreldiscounts(centerCountry);
            }
            for(Enrolment__c enrolObj : enrList){
                enrolCount ++;
                //Added by rajesh 31st Aug, To solve time slot issue on page AM,PM
                String slotTime = '';
                if(enrolObj.Lesson_Start_time__c != null){
                    Datetime myDateTime = Datetime.newInstance(Date.today(), enrolObj.Lesson_Start_time__c);
                    slotTime = myDateTime.format('h:mm a');   
                }
                enrolmentTimeSlotMap.put(enrolObj.Id, slotTime);
                
                enrolmentMap.put(enrolObj.Id, enrolObj); 
                studentSet.add(enrolObj.Student__c);
                parentId = enrolObj.Parent__c;
                                 
                //Fee calcuations for the selected package in enrolment
                feeMap.put(enrolObj.Id, calculateFeeForEnrolment(enrolObj, gstTaxPer)); 
                
            }
            
            if(studentSet.size() > 0){
                mapOfParentStudent = fetchStudentAndParent(studentSet, parentId, enrList.get(0));   
            }
            
            if(enrolmentMap.size() > 0){
                enrolDetailsToReturn.enrolments = enrolmentMap;
                enrolDetailsToReturn.enrolmentTimeSlotMap = enrolmentTimeSlotMap;
                enrolDetailsToReturn.feeModelObj= feeMap;
                //enrolDetailsToReturn.billingDetails = fetchBillDetails(enrolmentMap.values());
                enrolDetailsToReturn.billingDetails = fetchBillDetails(feeMap.values(), gstTaxPer);
            }
            if(mapOfParentStudent.size() > 0){
                
                if(mapOfParentStudent.containsKey('parent') && mapOfParentStudent.get('parent').size() > 0){
                    enrolDetailsToReturn.parent = mapOfParentStudent.get('parent')[0]; 
                }
                if(mapOfParentStudent.containsKey('student') && mapOfParentStudent.get('student').size() > 0){
                    for(AccountDetails accDetails : mapOfParentStudent.get('student')){
                        enrolDetailsToReturn.students.put(accDetails.id, accDetails);
                    }
                }
            }
        }
        return enrolDetailsToReturn;
    }
    
    private Map<String, List<AccountDetails>> fetchStudentAndParent(Set<String> studentSet, String parentId, Enrolment__c enr){
        Map<String, List<AccountDetails>> accMap = new Map<String, List<AccountDetails>>();
        AccountDetails accDetails = new AccountDetails();
        for(Account accObj : [SELECT Id, FirstName, LastName, PersonBirthdate, Gender__c, Nationality__c, School__c, School__r.Name, 
                              PersonEmail, Phone, BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingCountryCode, Country__c, Country__r.Country_Name__c, 
                              Is_Club_Member__c, Membership_Type__c, Stripe_Customer_Id__c, Card_Number__c, Card_Type__c, Card_Image__c, Instrument_At_Home__c     
                              FROM Account WHERE (Id IN: studentSet OR Id =: parentId)]){      
             
            if(parentId == accObj.Id){
                accDetails = fillAccountdetails(accObj, 'parent', enr);
                accMap.put('parent', new List<AccountDetails>{accDetails});
                
                //Added by Rajesh, 11th July 2019, for check that parent is American club member of not
                if(accObj.Is_Club_Member__c && accObj.Membership_Type__c == ConstantsClass.amcClubMember)
                    isAmcClubMember = true;
                
                if(accObj.Stripe_Customer_Id__c != null && accObj.Card_Number__c != null && accObj.Card_Type__c != null){
                    stripeCstmrId = accObj.Stripe_Customer_Id__c;
                    cardNumber    = accObj.Card_Number__c;
                    cardType      = accObj.Card_Type__c;            
                    cardImage     = accObj.Card_Image__c;
                    isAlreadyStripCstmr = true;
                }
            }
            if(studentSet.contains(accObj.Id)){
                accDetails = fillAccountdetails(accObj, 'student', enr);
                List<AccountDetails> studentList = new List<AccountDetails>();
                if(accMap.containsKey('student')){
                    studentList = accMap.get('student');  
                    studentList.add(accDetails);
                    accMap.put('student', studentList);
                }else{
                    accMap.put('student', new List<AccountDetails> {accDetails});
                }
            }       
        }
        return accMap;
    }
    
    private AccountDetails fillAccountdetails(Account acc, String type, Enrolment__c enr){
        AccountDetails accDetails = new AccountDetails();
        accDetails.enrolDate = new Enrolment__c();
        if(String.isNotBlank(acc.Id)){
            accDetails.id = acc.Id;
            accDetails.gender = acc.gender__c;
            accDetails.firstName = acc.FirstName;
            accDetails.lastName = acc.LastName;
            accDetails.nationality = acc.Nationality__c;
            accDetails.enrolDate.Lessons_Start_Date__c = acc.PersonBirthdate;
            if(type == 'student'){
                accDetails.dob = acc.PersonBirthdate;
                accDetails.school = acc.School__c;
            }else if(type == 'parent'){
                accDetails.email = acc.PersonEmail;
                accDetails.phone = acc.Phone;
                accDetails.address = acc.BillingStreet;
                accDetails.city = '';//acc.Country__r.Country_Name__c;
                accDetails.postalCode = acc.BillingPostalCode;
                accDetails.Country = acc.BillingCountryCode;
                accDetails.isInstrumentAtHome = acc.Instrument_at_Home__c;
                if(String.isBlank(accDetails.Country) && enr.Center__r.Country__r.Name != null)
                    accDetails.Country = enr.Center__r.Country__r.Name;
                accDetails.stripeId = acc.Stripe_Customer_Id__c;
            }
            
        }
        return accDetails;
    }
    
    private List<SelectOption> fillPicklistValues(String ObjectApi_name,String Field_name){
        List<SelectOption> selectOptionList = new List<SelectOption>();
        /*for(String value : AureusCalendarController.getPickListValues(objectName, fieldName)){
            selectOptionList.add(new SelectOption(value, value));            
        }*/
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
    
    private List<SelectOption> fillSchools(String cntryName){
        List<SelectOption> schools = new List<SelectOption>(); 
        for(School__c school : [SELECT Id, Name FROM School__c WHERE Country__r.Name=:cntryName ORDER By Name]){
            schools.add(new SelectOption(school.Id, school.Name));
        }
        return schools;
    }
    
/*    private List<SelectOption> fillCountries(){
        List<SelectOption> countries = new List<SelectOption>(); 
        for(Country__c country : [SELECT Id, Country_Name__c FROM Country__c]){
            countries.add(new SelectOption(country.Id, country.Country_Name__c));
        }
        return countries;
    }*/
    
    public List<SelectOption> getFillInstrumentAtHome(){
        List<SelectOption> isInstrumentAtHome = new List<SelectOption>(); 
        isInstrumentAtHome.add(new SelectOption('', '--Please Select--'));
        isInstrumentAtHome.addAll(fillPicklistValues('Account', 'Instrument_at_Home__c'));
        return isInstrumentAtHome;
    }
    
    private Account fillAccountFromDetails(AccountDetails accDetails, String type){
        Account acc = new Account();
        if(String.isNotBlank(accDetails.id)){
            acc.Id = accDetails.id;
            acc.gender__c = accDetails.gender;
            acc.FirstName = accDetails.firstName;
            acc.LastName = accDetails.lastName;
            acc.Nationality__c = accDetails.nationality;
            /*if(type == 'student'){*/
                acc.PersonBirthdate = accDetails.enrolDate.Lessons_Start_Date__c;
                acc.School__c = accDetails.school;
            /*}else if(type == 'parent'){*/
                acc.PersonEmail = accDetails.email;
                acc.Phone = accDetails.phone;
                acc.BillingStreet = accDetails.address;
                acc.BillingCity = accDetails.city;
                acc.BillingPostalCode = accDetails.postalCode;
                acc.BillingCountryCode = accDetails.country;
                acc.Instrument_at_Home__c = accDetails.isInstrumentAtHome;
            /*}*/
        }
        return acc;
    }
    
    public void fetchFullAddress(){
        string postalCode = Apexpages.currentPage().getParameters().get('postalCode');
        //enrolDetails.parent.address = '';
        //enrolDetails.parent.country = '';
        //enrolDetails.parent.city = '';
        if(String.isNotBlank(enrolDetails.parent.country) && String.isNotBlank(postalCode)){
            String tempPostalCode = postalCode;
            try{
                tempPostalCode = ''+Integer.valueOf(postalCode);
            }catch(Exception e){}
            
            for(Postal_code__c code : [SELECT Id, Name, BuildingNo__c, Country__r.Name, Country__r.Country_Name__c, Street_Name__c, Building_Name__c 
                                       FROM Postal_code__c 
                                       WHERE Country__r.Name =: enrolDetails.parent.country AND Name =: tempPostalCode LIMIT 1]){
                if(String.isNotBlank(enrolDetails.parent.id)){
                    enrolDetails.parent.address = (String.isNotBlank(code.BuildingNo__c)) ? code.BuildingNo__c + ' ': '';
                    enrolDetails.parent.address += (String.isNotBlank(code.Building_Name__c)) ? code.Building_Name__c + ', ': '';
                    enrolDetails.parent.address += (String.isNotBlank(code.Street_Name__c)) ? code.Street_Name__c: '';
                   // enrolDetails.parent.country = code.Country__c;
                    enrolDetails.parent.city = code.Building_Name__c;
                    enrolDetails.parent.postalCode = code.Name;
                }
            }
        }    
    }

    Public static Decimal calculateCurrentMonthPckFees(Date lessDate, Decimal unitFees,Boolean isTeacherPartime) {
        Date tempDt = lessDate;        
        Integer noOfLessInCurrMonth = 0;
        
        while(lessDate.month() == tempDt.month()){
            if(tempDt.day() > 28 && isTeacherPartime)
                break;
            noOfLessInCurrMonth = noOfLessInCurrMonth+1;
            tempDt = tempDt.addDays(7);
        }
        Decimal packFee = unitFees * noOfLessInCurrMonth;
        system.debug('packFee'+packFee);
        return packFee;
    }
    
    private FeeModel calculateFeeForEnrolment(Enrolment__c enr, Integer gstTaxPer){
        FeeModel fm = new FeeModel();
        fm.selPckMonthFees = enr.package__r.Package_Fee__c;
        fm.depFees  = enr.package__r.Deposit_Fee__c != null ? enr.package__r.Deposit_Fee__c : 0 ;
        fm.regiFees = enr.package__r.Registration_Fee__c != null ? enr.package__r.Registration_Fee__c : 0 ;
        //@Juneid 18 Aug 2020, Facility Fee calucation
       // fm.facilityFee = enr.package__r.Facility_Fee__c > 0 ? enr.package__r.Facility_Fee__c : 0;
      //  system.debug('fm.facilityFee--->'+fm.facilityFee);
        Decimal tempUnitFee = enr.package__r.Unit_Fee__c;
        //Decimal facilityFee = enr.Package__r.Facility_Fee__c;
        //system.debug('facilityFee--->'+facilityFee);
        
        //Promotional fees discount calcuation
        fm.pkgFeesPromtnalDis  = 0;
        fm.prmtnalPkgInMonth   = 0;
        fm.isPromitionalPackage = false; // added by nishi:5-Nov-2020for check selected package is promotional or not
        if(enr.package__r.Is_Promotion_Discount__c && String.isNotBlank(enr.package__r.Promotion_period_In_months__c)){ 
            fm.pkgFeesPromtnalDis  = enr.package__r.Promotion_Discount__c;
            fm.prmtnalPkgInMonth   = 0;                        
            try{
                fm.prmtnalPkgInMonth   = Integer.valueOf(enr.package__r.Promotion_period_In_months__c);

            }catch(Exception e){}
        }                    
        
        //Registration fees calcuation
        fm.regiFeesDis = (enr.package__r.Registration_Discount_Active__c && enr.package__r.Registration_Discount_Value__c > 0) ? enr.package__r.Registration_Discount_Value__c : 0;
       
        //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the invoice line items
        Decimal tempTotAmt = fm.regiFees - fm.regiFeesDis; 
        fm.gstAmount = BillingUtility.roundOffAmount((tempTotAmt > 0 && gstTaxPer > 0) ? ((tempTotAmt * gstTaxPer) / 100):0);
        //Regular package fee calcuation on the bases of selected date
        if(enr.Lessons_Start_Date__c != null && tempUnitFee > 0){
            Date lessDate = enr.Lessons_Start_Date__c;           
          
           //start : 3-Sep-2020: added by nishi: if teacher Engagement_Type__c type is part-time then not calclulate 5th lesson booking
           // fm.prgFees = BillingUtility.calculateCurrentMonthPckFees(lessDate, tempUnitFee);
           if(string.isNotBlank(enr.Teacher__c) && string.isNotBlank(enr.Teacher__r.Engagement_Type__c) && 
           ConstantsClass.teacherPartTimeEngagementStatus.contains(enr.Teacher__r.Engagement_Type__c) && isOssia){
                fm.prgFees = calculateCurrentMonthPckFees(lessDate, tempUnitFee,true);
            }else{
                fm.prgFees = calculateCurrentMonthPckFees(lessDate, tempUnitFee,false);
            }
            //end:3-Sep-2020: added by nishi: if teacher Engagement_Type__c type is part-time then not calclulate 5th lesson booking
            
            //@Juneid 08 Aug 2020, Facility Fees Calculation as per total lesson in month
          //  fm.facilityFee =( BillingUtility.calculateCurrentMonthPckFees(lessDate, facilityFee) / 4);
            //system.debug(' fm.facilityFee after calculation -->'+ fm.facilityFee);
            if(enr.Class__c != null && String.isNotBlank(enr.Package__r.Type__c) && enr.Package__r.Type__c.equalsIgnoreCase('Group')){
                Date tempDt = lessDate;  
                Integer noOfLessInCurrMonth = 0;
            
                while(lessDate.month() == tempDt.month()){
                    if(tempDt.day() > 28)
                        break;
                    noOfLessInCurrMonth = noOfLessInCurrMonth+1;
                    tempDt = tempDt.addDays(7);
                }
                
                fm.prgFees = tempUnitFee * noOfLessInCurrMonth;
            }
        }
        
        //Promotional fees discount calcuation
        if(enr.package__r.Is_Promotion_Discount__c && fm.prmtnalPkgInMonth > 0){
           
            //updated by Rajesh | Date-24th April 2019, New promotinal related changes
            fm.prgFees = enr.package__r.Package_Fee__c;
            
            fm.proNoOfLess = Integer.valueOf(enr.package__r.of_Units__c);
            fm.pkgAftPro = enr.package__r.Package_after_Promotion__c;  
            
            //Added by Rajesh, 13th Nov 2019. To solve 1cent issue on invoice
            fm.actPkgFee = fm.prgFees;
            fm.actDiscount = fm.pkgFeesPromtnalDis;
        }
        
        //Updated by Rajesh, 19th Sept 2019. To solve 2 decimal point for the 
        if(fm.pkgFeesPromtnalDis > 0 && fm.prmtnalPkgInMonth > 0 && fm.proNoOfLess >0){
            //Process for identify last date of subscription
            Date stDt = enr.Lessons_Start_Date__c;            
            Date currLesDt = null;
            Integer countDtforMonth = 0;
            Integer countNoOfLess = 0;
            
            Date subTempDt = enr.Lessons_Start_Date__c.addMonths(1);
            Date tempEndBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);   
            tempEndBillingDate = tempEndBillingDate.addMonths(fm.prmtnalPkgInMonth);
            Date promPerEndDate;
            while(stDt<=tempEndBillingDate){
                if(currLesDt == null)
                    currLesDt = stDt;
                
                if(currLesDt.month() == stDt.month()){
                    if(countDtforMonth < 4){
                        countDtforMonth = countDtforMonth+1;
                        countNoOfLess = countNoOfLess+1;
                    }
                }else{
                    currLesDt = stDt;
                    countDtforMonth = 1;
                    countNoOfLess = countNoOfLess+1;
                }
                
                if(countNoOfLess >= fm.proNoOfLess)
                    break;
                
                stDt = stDt.addDays(7);
            }    
            promPerEndDate = stDt;
            if(countDtforMonth == 4)
                stDt = stDt.addMonths(1);
            tempEndBillingDate = Date.newInstance(stDt.year(), stDt.month(), ConstantsClass.subNextBillingDay);
            
            //Start calcuation
            stDt = enr.Lessons_Start_Date__c;     
            Decimal prgFeeForSingleLess = fm.prgFees/fm.proNoOfLess;
            Decimal prgDisFeeForSingleLess = 0;
            if(fm.pkgFeesPromtnalDis > 0)
                prgDisFeeForSingleLess = fm.pkgFeesPromtnalDis/fm.proNoOfLess;
            
            currLesDt = null;
            countDtforMonth = 0;
            
            Decimal totPrgFee = 0;
            Decimal totDiscount= 0;
            while(stDt<=promPerEndDate){
                if(currLesDt == null)
                    currLesDt = stDt;
                
                if(currLesDt.month() == stDt.month()){
                    if(countDtforMonth < 4){
                        countDtforMonth = countDtforMonth+1;
                    }
                }else{
                    Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                    Decimal tempPrgFeegstTax=0;
                    Decimal discountgstTax=0;
                    decimal discount =prgDisFeeForSingleLess*countDtforMonth;
                    totPrgFee += (tempPrgFee);
                    totDiscount += (prgDisFeeForSingleLess*countDtforMonth); 
                    
                    //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                    //Update by Rajesh on 25th nov 2019. add rounding due to solve 2decimal problem with this 'tempPrgFee'
                    tempTotAmt = (tempPrgFee-((prgDisFeeForSingleLess*countDtforMonth))); 
                    tempPrgFeegstTax = BillingUtility.roundOffAmount((tempPrgFee > 0 && gstTaxPer> 0) ? ((tempPrgFee * gstTaxPer) / 100):0);
                    if(discount != 0){
                        discountgstTax= BillingUtility.roundOffAmount((discount != 0 && gstTaxPer != null && gstTaxPer> 0) ? ((discount * gstTaxPer) / 100):0);
                    }
                    fm.gstAmount += tempPrgFeegstTax-discountgstTax;
                    //fm.gstAmount += BillingUtility.roundOffAmount((tempTotAmt > 0 && gstTaxPer> 0) ? ((tempTotAmt * gstTaxPer) / 100):0);
                    
                    currLesDt = stDt;
                    countDtforMonth = 1;
                }                                            
                stDt = stDt.addDays(7);
            }
            system.debug('countDtforMonth'+countDtforMonth);
            if(countDtforMonth > 0){
                Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                Decimal tempPrgFeegstTax=0;
                tempPrgFeegstTax = BillingUtility.roundOffAmount((tempPrgFee > 0 && gstTaxPer > 0) ? ((tempPrgFee * gstTaxPer) / 100):0);
                totPrgFee += (tempPrgFee);
                totDiscount += ((prgDisFeeForSingleLess*countDtforMonth)); 
                
                //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                //Update by Rajesh on 25th nov 2019. add rounding due to solve 2decimal problem with this 'tempPrgFee'
                tempTotAmt = (tempPrgFee-(prgDisFeeForSingleLess*countDtforMonth));
                // added by nishi:start: 21-Sep-2020 : manage discount gst amount
                decimal discount = prgDisFeeForSingleLess*countDtforMonth;
                decimal discountgstTax = 0;
                if(discount != null && discount != 0 ){
                        discountgstTax = BillingUtility.roundOffAmount((discount != 0 && gstTaxPer != null && gstTaxPer > 0) ? ((discount * gstTaxPer) / 100):0);
                }
                fm.gstAmount += tempPrgFeegstTax-discountgstTax;
                // added by nishi: 21-Sep-2020 : end:manage discount gst amount
                //fm.gstAmount += BillingUtility.roundOffAmount((tempTotAmt > 0 && gstTaxPer > 0) ? ((tempTotAmt * gstTaxPer) / 100):0);
            }
            
            fm.prgFees = totPrgFee;
            fm.pkgFeesPromtnalDis = BillingUtility.roundOffAmount(totDiscount);
            fm.isPromitionalPackage = true;// added by nishi:5-Nov-2020 for check selected package is promotional or not
            fm.listOfpromotinalPackages = getlistOfpromotinalPackages(fm,enr,promPerEndDate);
            system.debug('fm.listOfpromotinalPackages'+fm.listOfpromotinalPackages);
        }else{//Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
            fm.gstAmount += BillingUtility.roundOffAmount((fm.prgFees > 0 && gstTaxPer > 0) ? ((fm.prgFees * gstTaxPer) / 100):0);
             // Decimal amount = fm.facilityFee > 0 ? BillingUtility.roundOffAmount(fm.facilityFee) : 0;
          //  system.debug('amount--->'+amount);
         //   system.debug('enr.Center__r.Country__r.Tax_Rate__c--->'+enr.Center__r.Country__r.Tax_Rate__c);
         //   system.debug('BillingUtility.roundOffAmount-->'+BillingUtility.roundOffAmount(Double.valueOf(amount) * (enr.Center__r.Country__r.Tax_Rate__c / 100)));
          //  fm.facilityGst += BillingUtility.roundOffAmount(Double.valueOf(amount) * (enr.Center__r.Country__r.Tax_Rate__c / 100));
         //   system.debug(' fm.facilityGst-->'+ fm.facilityGst);
        }
       
        /*Integer gstTaxPer = ConstantsClass.defGST;
        try{
            if(gstTaxPer == null){
                gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
            }
        }catch(Exception e){}*/
        
        fm.depFees = BillingUtility.roundOffAmount(fm.depFees);
        fm.prgFees = BillingUtility.roundOffAmount(fm.prgFees);
        fm.regiFees = BillingUtility.roundOffAmount(fm.regiFees);
        //@Juneid 08 Aug  2020, Adding Facililty Fee in Total
        Decimal totTemp = fm.regiFees + fm.prgFees /*+(fm.facilityFee > 0 ?  fm.facilityFee : 0)*/;
        Decimal TempDisTot  =  (fm.regiFeesDis + fm.pkgFeesPromtnalDis);
        Decimal tempTot = totTemp - TempDisTot;
        
        //Commented and added by Rajesh on 21st oct 2019. For calcuate individual gst amount for the line items
        //Decimal gstAmt = BillingUtility.roundOffAmount((tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0));        
        //Decimal gstAmt = (tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0);        
        //fm.totAmt = totTemp + gstAmt;
        fm.totAmt = totTemp + fm.gstAmount;
        /*
        fm.depFees = BillingUtility.roundOffAmount(fm.depFees);
        fm.prgFees = BillingUtility.roundOffAmount(fm.prgFees);
        fm.regiFees = BillingUtility.roundOffAmount(fm.regiFees);*/
        //@Juneid 06 Aug 2020, Applying Refferel Discount 
        if((String.isNotBlank(enr.Referral_code_used__c) && checkOsiaForRefrel(enr.Center__r.Organisation__r.name) ==true )){ ///&& enr.Package__r.Type_of_package__c =='Normal'
            //@Juneid 05 Aug 2020 ,Give Reffrel Discount
            if(enrolCount == 1){
                //@Juneid, 05 Aug 2020 Refrel Discount Calculation country wise
                if(countryWiseRfrelDiscount.size() > 0){
                    if(enr.Package__r.Type_of_package__c =='Normal'){
                    fm.refrelDiscount = countryWiseRfrelDiscount[0].Discount_Amount_Referee__c;
                    fm.refrelDiscountName = countryWiseRfrelDiscount[0].Name;
                    enr.Referee_discount_amount__c = countryWiseRfrelDiscount[0].Discount_Amount_Referee__c;
                    enr.Referrer_discount_amount__c = countryWiseRfrelDiscount[0].Discount_Amount_Referrer__c;
                        // added by nishi: 25-Sep-2020 : manage discount gst amount for referee
                    fm.gstAmount += -BillingUtility.roundOffAmount((countryWiseRfrelDiscount[0].Discount_Amount_Referee__c > 0 && gstTaxPer > 0) ? ((countryWiseRfrelDiscount[0].Discount_Amount_Referee__c * gstTaxPer) / 100):0);
                    }
                    /*start: nishi: 23-Sep-2020: we create credit memo  if student selected package is promo then we are not give discout to student but we give discount to refreer customer */
                    else{
                        fm.refreeDiscount = countryWiseRfrelDiscount[0].Discount_Amount_Referee__c;
                        enr.Referrer_discount_amount__c = countryWiseRfrelDiscount[0].Discount_Amount_Referrer__c;
                    }
                     /*end:nishi: 23-Sep-2020: we create credit memo  if student selected package is promo then we are not give discout to student but we give discount to refreer customer */
                }
            }
        }
                                
       
        
                                
        
        return fm;
    }

    // added by nishi:5-Nov-2020 for check selected package is promotional or not
    private List<promotinalPackagesDetails>  getlistOfpromotinalPackages(FeeModel fm,enrolment__c enr,date promPerEndDate){
        List<promotinalPackagesDetails> listOfpromotinalPackages = new List<promotinalPackagesDetails>();
        promotinalPackagesDetails objpromotinalPackagesDetails = new promotinalPackagesDetails();
        if(fm.pkgFeesPromtnalDis > 0 && fm.prmtnalPkgInMonth > 0 && fm.proNoOfLess >0){
            // Decimal prgFeeForSingleLess = fm.prgFees/fm.proNoOfLess;
            Decimal prgFeeForSingleLess = fm.actPkgFee/fm.proNoOfLess;
            Decimal prgDisFeeForSingleLess = 0;
            if(fm.pkgFeesPromtnalDis > 0){
                //prgDisFeeForSingleLess = fm.pkgFeesPromtnalDis/fm.proNoOfLess;
                prgDisFeeForSingleLess = fm.actDiscount/fm.proNoOfLess;
            }
            Date stDt = enr.Lessons_Start_Date__c;
            decimal tempTotAmt =0;
            date currLesDt = null;
            Integer countDtforMonth = 0;
            while(stDt<=promPerEndDate){
                if(currLesDt == null)
                    currLesDt = stDt;
                
                if(currLesDt.month() == stDt.month()){
                    if(countDtforMonth < 4){
                        countDtforMonth = countDtforMonth+1;
                    }
                }else{
                    Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                    listOfpromotinalPackages.add(new promotinalPackagesDetails(currLesDt,BillingUtility.roundOffAmount(tempPrgFee),enr.Package__r.Name,false));
                    if(prgDisFeeForSingleLess >0){
                        tempTotAmt = (prgDisFeeForSingleLess*countDtforMonth) ; 
                        listOfpromotinalPackages.add(new promotinalPackagesDetails(currLesDt,BillingUtility.roundOffAmount(tempTotAmt),enr.Package__r.Name+' (Discount)',true));
                    }
                    currLesDt = stDt;
                    countDtforMonth = 1;
                }                                            
                stDt = stDt.addDays(7);
            }
            
            if(countDtforMonth > 0){
                Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                listOfpromotinalPackages.add(new promotinalPackagesDetails(currLesDt,BillingUtility.roundOffAmount(tempPrgFee),enr.Package__r.Name,false));
                if(prgDisFeeForSingleLess > 0){
                    tempTotAmt = (prgDisFeeForSingleLess*countDtforMonth); 
                    listOfpromotinalPackages.add(new promotinalPackagesDetails(currLesDt,BillingUtility.roundOffAmount(tempTotAmt),enr.Package__r.Name+' (Discount)',true));
                }
            }
        }
        return listOfpromotinalPackages;
    }
    
    private BillingDetails fetchBillDetails(List<FeeModel> feeModelList, Integer gstTaxPer){
        BillingDetails billDetails = new BillingDetails();
       Decimal refrelDiscounttax = 0;
        for(FeeModel fm: feeModelList){    
//@Juneid 05,Aug 2020,Calculation for For Deduct the Refrel discount amount
            //@Juneid 18 Aug 2020, Facility fees add
           Decimal totTemp = ((fm.regiFees + fm.prgFees) /*+  (fm.facilityFee > 0 ? fm.facilityFee : 0)*/ );//commented bu nishi : 25-Sep-2020: for now we created different line for discount- (fm.refrelDiscount !=null ? fm.refrelDiscount : 0));
            billDetails.feesTot += (totTemp);
            billDetails.disTot  +=  (fm.regiFeesDis + fm.pkgFeesPromtnalDis +(fm.refrelDiscount !=null ? fm.refrelDiscount : 0));
            billDetails.depositTot +=(fm.depFees != null ? fm.depFees : 0);
            //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
            billDetails.gstTot += (fm.gstAmount);
            //@Juneid 26 Aug 2020, facility Fees GSt
            
            //billDetails.gstTot +=fm.facilityGst;
        }
        system.debug('refrelDiscounttax'+refrelDiscounttax);
        system.debug('billDetails.gstTot'+billDetails.gstTot);
        system.debug('billDetails.gstTot'+(billDetails.gstTot+refrelDiscounttax));
        //Gst
      /*  Integer gstTaxPer = ConstantsClass.defGST;
        try{
            gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
        }catch(Exception e){}*/
        
        Decimal tempTot = billDetails.feesTot - billDetails.disTot;
        //Commented by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
       // billDetails.gstTot = tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0;        
        
        billDetails.disTot   = BillingUtility.roundOffAmount(billDetails.disTot);
        billDetails.feesTot  =BillingUtility.roundOffAmount(billDetails.feesTot);
        //Commented by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
       // billDetails.gstTot   = BillingUtility.roundOffAmount(billDetails.gstTot);
        billDetails.depositTot =BillingUtility.roundOffAmount( billDetails.depositTot);
        billDetails.subsTot  = BillingUtility.roundOffAmount(billDetails.feesTot + billDetails.depositTot - (billDetails.disTot));
        billDetails.grandTot = BillingUtility.roundOffAmount((billDetails.subsTot +billDetails.gstTot));
        billDetails.totalAmt = BillingUtility.roundOffAmount(( billDetails.feesTot +  billDetails.depositTot));
        /*billDetails.total = 0;
        Double packageTotal = 0;
        for(Enrolment__c enrolObj : enrolList){
            billDetails.total += enrolObj.Package__r.Package_Fee__c;
            billDetails.total += enrolObj.Package__r.Deposit_Fee__c;
            billDetails.total += enrolObj.Package__r.Registration_Fee__c;
            packageTotal += enrolObj.Package__r.Package_Fee__c;
        }
        billDetails.total = BillingUtility.roundOffAmount(billDetails.total);
        if(packageTotal > 0){
            billDetails.gst = BillingUtility.roundOffAmount(packageTotal * Decimal.valueOf(Label.GST_Tax_Rate) / 100);
            billDetails.grandTotal = BillingUtility.roundOffAmount(billDetails.total + billDetails.gst);
        }
        */
        return billDetails;
    }
    
    Public  PageReference saveAccountForEnrolmentAndGenerateInvoice(){
        Savepoint sp;
        isError = false;
        errorMsg = '';
        // Decimal facilityFeesGst = 0;//@Juneid 08 Aug 2020, String Facility Fee gst
        //BillingUtility.initConnection(countryId);
                    
        //Added by Prabhat (18-06-2019)
        EnrollmentProcessErrorLogs.errorLogObj errorObj = new EnrollmentProcessErrorLogs.errorLogObj();
        if(isAmcClubMember || isAlreadyStripCstmr || (stripeToken!=null && stripeToken.trim().length()>0)){
            try{                
                Account parentAcc =  fillAccountFromDetails(enrolDetails.parent, 'parent');
                
                String last4CardNumber;
                String cardType;
                Integer exp_month;
                Integer exp_year;
                //Updated by Rajesh, 30th June 2019, for American club member
                if(!isAmcClubMember && (!isAlreadyStripCstmr || String.isBlank(stripeCstmrId))){                    
                    String cusName = String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName : ' ';
                    cusName += parentAcc.LastName;
                    //BillingUtility.initConnection(countryId);
                    
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
                
                 //Updated by Rajesh, 30th June 2019, for American club member
                if(isAmcClubMember || String.isNotBlank(stripeCstmrId)){ 
                    
                    Decimal amountInSmallUnit      = enrolDetails.billingDetails.grandTot;
                    BillingUtility.stripeCharge sc = new BillingUtility.stripeCharge(); 
                    //Updated by Rajesh, 30th June 2019, Skip stripe customer creation for the American club member
                    if(!isAmcClubMember){
                        //BillingUtility.initConnection(countryId);
                        sc = BillingUtility.createChargeForCustomer(stripeCstmrId,amountInSmallUnit, countryCurrencyCode, stripeBaseUrl, stripeApiSecKey);
                    }
                    
                    //Updated by Rajesh, 30th June 2019, for the American club member
                    //Added by Rajesh, 30th Sept 2019. Paid condition for check the payment is success/unsucess(In case of declined)
                    if(isAmcClubMember || (sc.statusCode == 200 && sc.paid)){
                        sp = Database.setSavepoint();
                        List<Account> accListToUpdate = new List<Account>();                        
                        
                        //Added By Prabhat(01-07-2019) to create error logs if exception occurs
                        //Below mapping will also be used to refund the amount back to the customer.
                        errorObj.customerStripeId = stripeCstmrId;
                        errorObj.stripeTransactionId = sc.id;
                        errorObj.stripeChargeAmount = sc.amount;
                        errorObj.customerSalesforceId = parentAcc.Id;
                        errorObj.baseUrl = stripeBaseUrl;
                        errorObj.apiKey  = stripeApiSecKey;
                        
                        //Updated by Rajesh, 30th June 2019, No need to set card details on parent for the American club member
                        if(!isAmcClubMember){
                            parentAcc.Stripe_Customer_Id__c = stripeCstmrId;
                            if(String.isNotBlank(last4CardNumber))
                                parentAcc.Card_Number__c = last4CardNumber;
                            if(String.isNotBlank(cardType))
                                parentAcc.Card_Type__c = cardType;
                            
                            parentAcc.Expiry_Month__c = exp_month;
                            parentAcc.Expiry_Year__c = exp_year;
                        }
                        
                        //Added by Rajesh: 19th July, Populate Customer fields When first Active Enrolment is created in the system (Discussed with Prashant)
                        //Commented by Rajesh: 11th Oct 2019, No need to populate centre for first enrolment, we can do everytime latest centre for the customer
                       /*Boolean isFirstEnrolment = true;
                        
                        //Check that customer is already exist or not on the bases of email
                        List<Account> accList = [SELECT Id,Name,Location__c,Centre_Name__c,Enroled__c FROM Account WHERE Id =: parentAcc.Id]; 
                        if(accList.size() > 0){                            
                            //Added by Rajesh: 19th July, Populate Customer fields When first Active Enrolment is created in the system (Discussed with Prashant)
                            if(accList.get(0).Enroled__c)
                                isFirstEnrolment = false;
                        }*/
                        //Added by Rajesh: 19th July, Populate Customer fields When first Active Enrolment is created in the system (Discussed with Prashant)
                       // if(isFirstEnrolment  && studentWrapList.size() > 0 && studentWrapList.get(0).lessonList.size() > 0){
                       List<Account> centrList = new  List<Account>();
                       //Commented by Rajesh: 11th Oct 2019, No need to populate centre for first enrolment, we can do everytime latest centre for the customer
                       //if(isFirstEnrolment  && enrolDetails.enrolments.size() > 0){
                       if(enrolDetails.enrolments.size() > 0){    
                            Enrolment__c enr         = enrolDetails.enrolments.values().get(0);
                            parentAcc.Centre_Name__c = enr.Center__c;
                            parentAcc.Enroled__c     = true;
                            parentAcc.Instrument__c  = enr.Instrument__c;
                            parentAcc.Enroled_Date__c= System.today();
                            centrList = [SELECT Id, Name, Location__c, Country__r.Country_Name__c FROM Account WHERE Id =: enr.Center__c];
                            if(centrList.size() > 0){
                                parentAcc.Location__c = centrList.get(0).Location__c;
                                //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                                if(centrList.get(0).Country__r.Country_Name__c != null)
                                    parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                            }
                        }                        
                        accListToUpdate.add(parentAcc);
                        
                        if(enrolDetails.students.size() > 0){
                            for(String students : enrolDetails.students.keySet()){
                                if(students != parentAcc.Id){
                                    Account stuTempAcc = fillAccountFromDetails(enrolDetails.students.get(students), 'student');
                                    //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                                    stuTempAcc.Centre_Name__c =  enrolDetails.enrolments.values().get(0).Center__c;
                                    if(centrList.size() > 0){
                                        stuTempAcc.Location__c = centrList.get(0).Location__c;
                                        //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                                        if(centrList.get(0).Country__r.Country_Name__c != null)
                                            stuTempAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                                    }
                                    accListToUpdate.add(stuTempAcc);
                                }                                    
                            }
                        }
                        if(accListToUpdate.size() > 0)
                            update accListToUpdate;  
                        
                        Map<String, Subscription__c> activeSubMap = new Map<String, Subscription__c>();
                        Set<String> grpClsBookSet = new Set<String>();
                        for(Enrolment__c enr: enrolDetails.enrolments.values()){
                            if(enr.center__c != null)
                                activeSubMap.put(enr.center__c, null);
                            
                            if(enr.Class__c != null && String.isNotBlank(enr.Package__r.Type__c) && enr.Package__r.Type__c.equalsIgnoreCase('Group'))
                                grpClsBookSet.add(enr.Class__c);
                        }
                        Map<String, Booking__c> grpClsBookMap = new Map<String, Booking__c>();
                        if(grpClsBookSet.size() > 0){
                            String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();   
                            for(Class__c cls: [SELECT Id, Name, Package__c, Package__r.Name, Teacher__c, Class_Day__c, Start_Time__c,End_Time__c,
                                          (SELECT Id, Class__c, Booking_Date__c FROM Bookings__r WHERE RecordTypeId =: bookGrpClsRecId AND Booking_Date__c != null)
                                   FROM Class__c WHERE Id IN:grpClsBookSet AND Active__c = True AND Available_Capacity__c > 0
                                   // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                   And Is_Makeup_Class__c = false]){                                                               
                              
                                for(Booking__c book: cls.Bookings__r)
                                    grpClsBookMap.put(cls.Id+'#'+book.Booking_Date__c, book);                 
                            }    
                        }
                        
                        
                        for(Subscription__c sub: [SELECT Id, Parent__c, Center__c FROM Subscription__c  
                                                  WHERE Parent__c =: parentAcc.Id AND Center__c IN:activeSubMap.keySet()  
                                                        AND Status__c =: ConstantsClass.activeStatus])
                            activeSubMap.put(sub.Center__c, sub);
                        
                     /*   Map<String, Booking__c> bookingMap = new Map<String, Booking__c>();
                        for(Booking__c book: [SELECT Id, Name, Booking_Date__c, Enrolment__c, Type__c, Status__c, Category__c, Enrolment__r.Lessons_Start_Date__c FROM Booking__c 
                                              WHERE Enrolment__c IN: enrolDetails.enrolments.keySet() 
                                                    AND Status__c = 'Blocked' AND Booking_Date__c != null Order By Booking_Date__c]){
                                   
                            String key = book.Enrolment__c +'#'+book.Booking_Date__c;
                            bookingMap.put(key, book);
                        }*/
                        List<Booking__c> bookLstForDel = [SELECT Id,Name FROM Booking__c WHERE Status__c = 'Blocked' AND Enrolment__c IN: enrolDetails.enrolments.keySet()];
                        if(bookLstForDel.size() > 0)
                            delete bookLstForDel;
                        
                        Map<Id, Subscription__c> centSubMap = new Map<Id, Subscription__c>();
                        Map<Id, Invoice__c> cntrInvMap      = new Map<Id, Invoice__c>();
                        Map<Id, Credit_Memo__c> cntrCreditMap      = new Map<Id, Credit_Memo__c>();
                        List<Credit_memo_line_item__c> listOfCreditmemolineitem     = new List<Credit_memo_line_item__c>();
                        Map<Id, Payment__c> cntrPayMap      = new Map<Id, Payment__c>();
                        List<Account> studentList           = new List<Account>(); 
                        List<Enrolment__c> enrolmentList    = new List<Enrolment__c>();
                        List<Booking__c> bookList           = new List<Booking__c>();
                        List<Subscription_Line_Item__c> subLinItmList = new List<Subscription_Line_Item__c>();
                        List<Invoice_Line_Item__c> invLineItmList     = new List<Invoice_Line_Item__c>();
                        List<Payment__c> customerPaymentList = new List<Payment__c>();
                        
                        //Added by rajesh,17th sept 2019: for fifth lesson record
                        List<Fifth_Lesson__c> fifthLsnList  = new List<Fifth_Lesson__c>();                        
                        //Added by rajesh,17th sept 2019: cancelled booking process if teacher on leave
                        Date tempLessonDt;
                        
                        //------------------- Start for aureus at home ------------------------------ 
                        Set<String> centSet = new Set<String>();
                        Set<String> tchrSet = new Set<String>();
                        Set<String> daySet = new Set<String>();
                        Map<String,Teacher_Working_Hour__c> tcrWrkHourMap = new Map<String,Teacher_Working_Hour__c>();
                        Set<String> enrolmentCenterIds = new Set<String>();
                        Set<String> enrolmentTeacherIds = new Set<String>();
                        for(Enrolment__c enr : enrolDetails.enrolments.values()){
                            if(enr.Center__c == Label.Aureus_at_Home_Id){
                                centSet.add(enr.Center__c);
                                tchrSet.add(enr.Teacher__c);
                                
                                if(enr.Lessons_Start_Date__c != null){
                                    Date tempDt    = enr.Lessons_Start_Date__c;
                                    String currDay = DateTime.newInstance(tempDt, Time.newInstance(0, 0, 0, 0)).format('E');
                                    daySet.add(currDay);
                                }
                            }
                            enrolmentCenterIds.add(enr.Center__c);
                            enrolmentTeacherIds.add(enr.Teacher__c);
                            //Added by rajesh,17th sept 2019: cancelled booking process if teacher on leave
                            if(tempLessonDt == null || tempLessonDt < enr.Lessons_Start_Date__c) 
                                tempLessonDt = enr.Lessons_Start_Date__c;
                        }
                        if(centSet.size() > 0 && tchrSet.size() > 0 && daySet.size() > 0){
                            for(Teacher_Working_Hour__c tchr : [SELECT Id,Name,Teacher_Name__c, Center_Name__c, Working_Day__c, Start_Time__c
                                                                FROM Teacher_Working_Hour__c 
                                                                WHERE Teacher_Name__c IN: tchrSet AND Working_Day__c IN:daySet  AND Center_Name__c IN: centSet AND Active__c = true AND Break_Time__c = False 
                                                                AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null ]){
                                                                    String key = tchr.Teacher_Name__c+'#'+tchr.Center_Name__c+'#'+tchr.Working_Day__c;
                                                                    tcrWrkHourMap.put(key,tchr);                                                                     
                                                                }
                        }
                        //------------------- end for aureus at home ------------------------------
                        
                        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();  
                        for(Enrolment__c enr: enrolDetails.enrolments.values()){
                            Boolean isLinkGrpBookClsId = false;
                            String bookType = ConstantsClass.bookTypeRegular;
                            if(enr.Class__c != null && String.isNotBlank(enr.Package__r.Type__c) && enr.Package__r.Type__c.equalsIgnoreCase('Group')){
                                isLinkGrpBookClsId = true;
                                bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Lesson').getRecordTypeId();
                                bookType = 'Group Lesson';
                            }
                           /* String grpBookClsId;
                            if(isLinkGrpBookClsId){
                                if(grpClsBookMap.get(enr.Class__c+'#'+enr.Lessons_Start_Date__c) != null){
                                    grpBookClsId = grpClsBookMap.get(enr.Class__c).Id; 
                                }else{
                                    //Show error its booked
                                }
                            }*/
                            
                            //Added by Rajesh, date 24th June 2019, for populating subscription start date and next billing date for the 
                            Date subTempDt = enr.Lessons_Start_Date__c.addMonths(1);
                            Date subsDt    = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                            Date subsNextBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);
                            Date promPerEndDate;
                            
                            //Added by Rajesh: 25th June 2019, Populating last date, according to promotional package
                            FeeModel fm = enrolDetails.feeModelObj.get(enr.Id);
                            //-------subsciption next date calcualtion for promotional package ---Start
                            if(fm.pkgFeesPromtnalDis > 0 && fm.prmtnalPkgInMonth > 0 && fm.proNoOfLess >0){
                                subsNextBillingDate = subsNextBillingDate.addMonths(fm.prmtnalPkgInMonth);
                                Date stDt = enr.Lessons_Start_Date__c;
                                
                                Date currLesDt;
                                Integer countDtforMonth = 0;
                                Integer countNoOfLess = 0;
                                
                                while(stDt<=subsNextBillingDate){
                                    if(currLesDt == null)
                                        currLesDt = stDt;
                                    
                                    if(currLesDt.month() == stDt.month()){
                                        if(countDtforMonth < 4){
                                            countDtforMonth = countDtforMonth+1;
                                            countNoOfLess = countNoOfLess+1;
                                        }
                                    }else{
                                        currLesDt = stDt;
                                        countDtforMonth = 1;
                                        countNoOfLess = countNoOfLess+1;
                                    }
                                    
                                    if(countNoOfLess >= fm.proNoOfLess)
                                        break;
                                    
                                    stDt = stDt.addDays(7);
                                }
                                promPerEndDate = stDt;
                                if(countDtforMonth == 4)
                                    stDt = stDt.addMonths(1);
                                subsNextBillingDate = Date.newInstance(stDt.year(), stDt.month(), ConstantsClass.subNextBillingDay);
                            }//-------------End
                            
                            //Filling subscription
                            Subscription__c subs = new Subscription__c();
                            if(activeSubMap.get(enr.Center__c) != null){
                                subs = activeSubMap.get(enr.Center__c);
                            }else if(centSubMap.get(enr.Center__c) != null){
                                subs = centSubMap.get(enr.Center__c);
                            }else{
                                //Filling subscription
                                subs = BillingUtility.fillSubscription(parentAcc.Id, ConstantsClass.activeStatus, subsDt);
                                subs.Center__c = enr.Center__c;
                                
                                //Commented by Rajesh on 24th June 2019, for populating next billing date according to promotinaly package
                                subs.Next_Bill_Date__c   = subsNextBillingDate;
                            }
                            centSubMap.put(enr.Center__c, subs);
                            
                            //Filling Invoice
                            Invoice__c inv        = new Invoice__c();
                            if(cntrInvMap.containsKey(enr.Center__c)){
                                inv = cntrInvMap.get(enr.Center__c);
                            }else{
                                inv = BillingUtility.fillInvoice(null, parentAcc.Id, ConstantsClass.paidStatus);
                                inv.Center__c = enr.Center__c; 
                                inv.Subscription__r = subs;
                                //Added by Rajesh, 30th July 2019, Set invoice type for the Enrolment process
                                inv.invoice_type__c = 'New Enrolment';
                            }
                            //Updated by Rajesh, 30th June 2019, Set invoice status as a due for the American club member
                            if(isAmcClubMember){
                                inv.Status__c   = ConstantsClass.dueStatus; 
                            }
                            cntrInvMap.put(enr.Center__c, inv);
                            //Filling Payment
                            String payTrnRecId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
                            Payment__c pay     = new Payment__c(RecordtypeId      = payTrnRecId);
                            if(cntrPayMap.containsKey(enr.Center__c)){
                                Decimal totAmtTemp = fm.totAmt + fm.depFees;
                                totAmtTemp = (totAmtTemp - (fm.regiFeesDis + fm.pkgFeesPromtnalDis));
                                pay = cntrPayMap.get(enr.Center__c);
                                pay.Payment_Amount__c += totAmtTemp;
                            }else{ 
                                Decimal totAmtTemp = fm.totAmt + fm.depFees;
                                totAmtTemp = (totAmtTemp - (fm.regiFeesDis + fm.pkgFeesPromtnalDis));
                                pay        = BillingUtility.fillPayment(parentAcc.Id, null, totAmtTemp, ConstantsClass.successStatus);
                                //@Juneid 06 Aug 2020, Calucation of Refrel Discount - Payment
                                if( fm.refrelDiscount > 0) {
                                   pay.Payment_Amount__c -=   fm.refrelDiscount;
                                }
                                //@juneid 18 Aug 2020, Gst on Payment
                               /* if(fm.facilityGst > 0){
                                    system.debug('pay.Payment_Amount__c-in gst-->'+pay.Payment_Amount__c);
                                    system.debug('facilityFeesGst--->'+fm.facilityGst);
                                    
                                    pay.Payment_Amount__c += fm.facilityGst;
                                    system.debug('pay.Payment_Amount__c after gst -->'+pay.Payment_Amount__c);
                                }*/
                                
                                //@Juneid 18 Aug,2020, Add Facility Fees in payment
                                /*if(fm.facilityFee > 0){
                                    system.debug('fm.facilityFee in payment -->'+ fm.facilityFee);
                                     pay.Payment_Amount__c +=   fm.facilityFee ;
                                    system.debug('pay.Payment_Amount__c--->'+pay.Payment_Amount__c);
                                }*/
                                pay.RecordtypeId      = payTrnRecId;
                                pay.Method_of_Payment__c = 'Card';
                                pay.Transaction_ID__c = sc.id; 
                                pay.Invoice__r        = inv;
                            }
                            //Updated by Rajesh, 30th June 2019, No need to create payment for the American club member
                            if(!isAmcClubMember)
                                cntrPayMap.put(enr.Center__c, pay);
                            
                             enr.Type__c        = 'Regular';
                              //CH01  Karan Singh25 March   
                            enr.Offline_Signing_Selected__c = isCustmrOptedOfflineSign; 
                            //CH01 END
                             enr.Stage__c = ConstantsClass.enroledStatus;
                             enr.Cancellation_Policy_Agreed__c = true;
                             enr.Promotional_Period_End_Date__c= promPerEndDate;
                             enr.Package_To_Be_Change__c       = fm.pkgAftPro;
                             enr.Cancellation_Policy_Agreed__c = true;
                             if(enr.Lessons_Start_Date__c != null){
                                 Datetime dt = DateTime.newInstance(enr.Lessons_Start_Date__c, Time.newInstance(0, 0, 0, 0));
                                 String dayOfWeek = dt.format('EEEE');                                                                                   
                                 enr.Lesson_Day__c = dayOfWeek;
                             } 
                            
                             //updated by Rajesh, 16th Nov 2019. to store enrolmentsource on enrolment/case object
                             if(String.isNotBlank(enrolmentSource))
                                enr.Enrolment_Source__c = enrolmentSource;
                             if(isLinkGrpBookClsId)
                                enr.Type__c        = 'Group';
                            
                             enrolmentList.add(enr);
                            
                             Subscription_Line_Item__c subLItm = BillingUtility.fillSubscriptionLineItem(enr.Student__c, null, enr.Package__c, enr.Id, 
                                                                                                            fm.selPckMonthFees, ConstantsClass.activeStatus);
                             subLItm.Subscription__r = subs;
                             subLItm.Subscription_Start_Date__c = enr.Lessons_Start_Date__c;
                             //Filling subscription line item billing date for the enrolment
                             subLItm.Next_Bill_Date__c   = subsNextBillingDate;
                             subLinItmList.add(subLItm);
                            
                             if(enr.Lessons_Start_Date__c != null){
                                
                               /*  Date lessDate = enr.Lessons_Start_Date__c;
                                 
                                 Date stDate  = lessDate;
                                 Date endDate = stDate.addMonths(12); 
                                 
                                 Integer numberOfDays = Date.daysInMonth(endDate.year(), endDate.month());
                                 Date lastDayOfEndDateMonth = Date.newInstance(endDate.year(), endDate.month(), numberOfDays);
                                 
                                 Date dt=lessDate;   
                                 Integer countBookingForMonth = 0;
                                 Date currLesDt;
                                 
                                 Date tempDt  = lessDate;
                                 tempDt = tempDt.addDays(-7); 
                                 while(System.today() <= tempDt){
                                     String key = enr.Id+'#'+tempDt;
                                     if(bookingMap.containsKey(key)){
                                         Booking__c bTemp = bookingMap.get(key);
                                         if(String.isNotBlank(bTemp.Category__c) && bTemp.Category__c.equalsIgnoreCase('Placeholder')){                 
                                             bTemp.Status__c     = ConstantsClass.scheduledStatus;
                                             bookList.add(bTemp); 
                                         }   
                                     }
                                     tempDt = tempDt.addDays(-7); 
                                 }
                                 
                                 while(dt<=lastDayOfEndDateMonth){
                                     String key = enr.Id+'#'+dt;
                                     if(bookingMap.containsKey(key)){
                                         Booking__c bTemp = bookingMap.get(key);
                                         
                                         Boolean isScheduled = false;
                                        
                                         if(String.isNotBlank(bTemp.Type__c) && bTemp.Type__c.equalsIgnoreCase('Busy')){
                                             isScheduled   = true;
                                         }else{
                                             bTemp.Type__c = 'Regular';
                                             if(promPerEndDate != null && promPerEndDate >= dt){
                                                isScheduled   = true; 
                                             }else if(lessDate.month() == dt.month() && lessDate.year() == dt.year()){
                                                 isScheduled   = true;                                  
                                             }
                                         }
                                         bTemp.Status__c = isScheduled ? ConstantsClass.scheduledStatus : ConstantsClass.pendingStatus;
                                         bookList.add(bTemp); 
                                          
                                     }
                                     dt = dt.addDays(7);
                                 }
                                 */
                                
                                 
                                 //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                 String remStr    =  enr.Parent__r.Name;
                                 remStr   =  remStr +':'+enr.Student__r.Name;
                                 Date lessDate = enr.Lessons_Start_Date__c;
                                 
                                 if(!isLinkGrpBookClsId){
                                     //Start --- Added by Rajesh: 25th July 2019, for Adding placeholder bookings before enrolment lesson start
                                     Date tempDt  = lessDate;
                                     tempDt = tempDt.addDays(-7); 
                                     while(System.today() < tempDt){
                                         Booking__c bTemp = fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, tempDt, null);
                                         bTemp.Type__c    = ConstantsClass.busyBookingType;
                                         bTemp.Category__c= 'Placeholder';                                            
                                         bTemp.Remarks__c = 'A future regular enrolemnt starting from '+lessDate+' for '+remStr;
                                         bookList.add(bTemp);    
                                         
                                         //Adding trial time during Aureus at home center
                                         if(enr.Center__c == Label.Aureus_at_Home_Id){
                                             
                                             String currDay =  DateTime.newInstance(tempDt, Time.newInstance(0, 0, 0, 0)).format('E');
                                             String key = enr.Teacher__c+'#'+enr.Center__c+'#'+currDay;
                                             
                                             if(tcrWrkHourMap.containsKey(key)){
                                                 Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                 
                                                 if(tchrworkH.Start_Time__c != enr.Lesson_Start_time__c){
                                                     //Traveling booking Before
                                                     Booking__c befBook = fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, tempDt, null);
                                                     befBook.Type__c       = ConstantsClass.busyBookingType;
                                                     befBook.Category__c   = 'Travel';
                                                     befBook.Remarks__c    = 'Booking for before trial.'+remStr;
                                                     befBook.End_Time__c   = bTemp.Start_Time__c;
                                                     befBook.Start_Time__c = bTemp.Start_Time__c.addMinutes(-30);
                                                     
                                                     bookList.add(befBook);
                                                 }
                                             }
                                         }
                                         tempDt = tempDt.addDays(-7); 
                                    } 
                                    //End--------Added by Rajesh: 25th July 2019, for Adding placeholder bookings before enrolment lesson start
                                }
                                 
                                Date stDate  = lessDate;
                                Date endDate = stDate.addMonths(12); 
                                
                                Integer numberOfDays = Date.daysInMonth(endDate.year(), endDate.month());
                                Date lastDayOfEndDateMonth = Date.newInstance(endDate.year(), endDate.month(), numberOfDays);
                                
                                Date dt=lessDate;  
                                Integer countBookingForMonth = 0;
                                Date currLesDt; 
                                
                                //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                remStr    =     'Placeholder booking for 5th lesson of '+remStr;    
                                while(dt<=lastDayOfEndDateMonth){
                                    if(promPerEndDate != null && promPerEndDate >= dt){
                                                                        
                                        Boolean isCreate5thPlaceBooking = false;
                                        if(currLesDt == null)
                                            currLesDt = dt;
                                        
                                        if(currLesDt.month() == dt.month()){
                                            if(countBookingForMonth < 4){
                                                countBookingForMonth = countBookingForMonth+1;
                                            }else{
                                                isCreate5thPlaceBooking = true;
                                            }
                                        }else{
                                            currLesDt = dt;
                                            countBookingForMonth = 1;
                                        }
                                        
                                        String grpBookClsId;
                                        if(isLinkGrpBookClsId){
                                            if(grpClsBookMap.get(enr.Class__c+'#'+dt) != null){
                                                grpBookClsId = grpClsBookMap.get(enr.Class__c+'#'+dt).Id; 
                                            }else{
                                                //Show error its booked
                                            }
                                        }
                                        // Booking__c bTemp = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, dt);
                                        Booking__c bTemp = fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, dt, grpBookClsId);
                                        
                                        if(isCreate5thPlaceBooking){   
                                           /* bTemp.Type__c    = ConstantsClass.busyBookingType;
                                            bTemp.Category__c= 'Placeholder';
                                            
                                            //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                            bTemp.Remarks__c = remStr;*/
                                            if(!isLinkGrpBookClsId){
                                                //Added by Rajesh,  17th Sept, 5th lesson booking
                                                Fifth_Lesson__c fifLes = fillFifthLesson(enr, dt);
                                                fifLes.Remarks__c = remStr;
                                                fifthLsnList.add(fifLes);
                                            }
                                        }else{
                                            bookList.add(bTemp);     
                                        }
                                    
                                         //Adding trial time during Aureus at home center
                                        if(enr.Center__c == Label.Aureus_at_Home_Id){
                                            
                                            String currDay =  DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('E');
                                            String key = enr.Teacher__c+'#'+enr.Center__c+'#'+currDay;
                                            
                                            if(tcrWrkHourMap.containsKey(key)){
                                                Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                
                                               /* Time tempT;
                                                if(String.isNotBlank(lw.lessonSlctSlot)){
                                                    List<String> timeList = lw.lessonSlctSlot.split(':');
                                                    tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                }*/
                                                
                                                if(tchrworkH.Start_Time__c != enr.Lesson_Start_time__c){
                                                    //Traveling booking Before
                                                   // Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                                    Booking__c befBook    = fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, dt, null);
                                                    befBook.Type__c       = ConstantsClass.busyBookingType;
                                                    befBook.Category__c   = 'Travel';
                                                    befBook.Remarks__c    = 'Booking for before trial';
                                                    //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                    befBook.End_Time__c   = befBook.Start_Time__c;
                                                    befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-30);
                                                    
                                                    if(isCreate5thPlaceBooking){   
                                                       /* befBook.Type__c    = ConstantsClass.busyBookingType;
                                                        befBook.Category__c= 'Placeholder';
                                                        
                                                        //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                                        befBook.Remarks__c = 'Booking for before trial'+remStr; 
                                                        */
                                                        //Added by Rajesh,  17th Sept, 5th lesson booking
                                                        if(!isLinkGrpBookClsId){
                                                            Fifth_Lesson__c fifLes = fillFifthLesson(enr, dt);
                                                            fifLes.Remarks__c = 'Booking for before trial'+remStr; 
                                                            fifthLsnList.add(fifLes);
                                                        }
                                                    }else{   
                                                        bookList.add(befBook);
                                                    }
                                                }
                                            }
                                        }
                                    }else if(!enr.Package__r.Is_Promotion_Discount__c && lessDate.month() == dt.month() && lessDate.year() == dt.year()){
                                        Boolean isCreate5thCurrentMonthPartTimeTeacherBooking = false;
                                        //bookList.add(EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, dt));
                                        System.debug('@@@@--->'+enr.Class__c+'#'+dt);
                                        String grpBookClsId;
                                        if(isLinkGrpBookClsId){
                                            if(grpClsBookMap.get(enr.Class__c+'#'+dt) != null){
                                                grpBookClsId = grpClsBookMap.get(enr.Class__c+'#'+dt).Id; 
                                            }else{
                                                //Show error its booked
                                            }
                                        }
                                       //3-Sep:2020:Start: added by nishi: if teacher Engagement_Type__c type is part-time then not creating fifth lesson booking 
                                        if(string.isNotBlank(enr.Teacher__c) && string.isNotBlank(enr.Teacher__r.Engagement_Type__c) && 
                                        ConstantsClass.teacherPartTimeEngagementStatus.contains(enr.Teacher__r.Engagement_Type__c) && dt.day() > 28 && isOssia){
                                            isCreate5thCurrentMonthPartTimeTeacherBooking = true;
                                        }
                                        //3-Sep:2020:End  added by nishi: if teacher Engagement_Type__c type is part-time then not creating fifth  booking  we creating fifth_lesson booking
                                        if(!isCreate5thCurrentMonthPartTimeTeacherBooking){
                                            bookList.add(fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, dt, grpBookClsId));
                                        
                                            //Adding trial time during Aureus at home center
                                            if(enr.Center__c == Label.Aureus_at_Home_Id){
                                                String currDay =  DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('E');
                                                String key = enr.Teacher__c+'#'+enr.Center__c+'#'+currDay;
                                                
                                                if(tcrWrkHourMap.containsKey(key)){
                                                    Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                    
                                                    Time tempT = enr.Lesson_Start_time__c;
                                                /* if(String.isNotBlank(lw.lessonSlctSlot)){
                                                        List<String> timeList = lw.lessonSlctSlot.split(':');
                                                        tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                    }*/
                                                    
                                                    if(tchrworkH.Start_Time__c != tempT){
                                                    //Traveling booking Before
                                                    /*  Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                                        befBook.RecordTypeId  = bookLessRecId;
                                                        befBook.Type__c       = ConstantsClass.busyBookingType;
                                                        befBook.Status__c    = ConstantsClass.scheduledStatus;
                                                        befBook.Category__c   = 'Travel';
                                                        befBook.Remarks__c    = 'Travel time slot for home regular booking'; 
                                                        //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                        befBook.End_Time__c   = befBook.Start_Time__c;
                                                        befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                        bookList.add(befBook);
                                                        */
                                                        Booking__c befBook = fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, dt, null);
                                                        befBook.Type__c       = ConstantsClass.busyBookingType;
                                                        befBook.Category__c   = 'Travel';
                                                        befBook.Remarks__c    = 'Travel time slot for home regular booking';
                                                        befBook.End_Time__c   = befBook.Start_Time__c;
                                                        befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-30);
                                                        
                                                        bookList.add(befBook);
                                                    }
                                                }
                                            }    
                                        } else{
                                            if(!isLinkGrpBookClsId){
                                                //Added by nishi,  4th Sept, 5th lesson booking
                                                Fifth_Lesson__c fifLes = fillFifthLesson(enr, dt);
                                                fifLes.Remarks__c = remStr; 
                                                fifthLsnList.add(fifLes);
                                            }
                                        }                                           
                                    }else{
                                        Boolean isCreate5thPlaceBooking = false;
                                        if(currLesDt == null)
                                            currLesDt = dt;
                                        
                                        if(currLesDt.month() == dt.month()){
                                            if(countBookingForMonth < 4){
                                                countBookingForMonth = countBookingForMonth+1;
                                            }else{
                                                isCreate5thPlaceBooking = true;
                                            }
                                        }else{
                                            currLesDt = dt;
                                            countBookingForMonth = 1;
                                        }
                                        
                                        String grpBookClsId;
                                        if(isLinkGrpBookClsId){
                                            if(grpClsBookMap.get(enr.Class__c+'#'+dt) != null){
                                                grpBookClsId = grpClsBookMap.get(enr.Class__c+'#'+dt).Id; 
                                            }else{
                                                //Show error its booked
                                            }
                                        }
                                        //Booking__c bTemp = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.pendingStatus, dt);
                                        Booking__c bTemp =  fillBook(bookLessRecId, enr, ConstantsClass.pendingStatus, bookType, dt, grpBookClsId);
                                        if(isCreate5thPlaceBooking){   
                                           /* bTemp.Type__c    = ConstantsClass.busyBookingType;
                                            bTemp.Status__c  = ConstantsClass.scheduledStatus;
                                            bTemp.Category__c= 'Placeholder';
                                            
                                            //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                            bTemp.Remarks__c = remStr; */
                                            if(!isLinkGrpBookClsId){
                                                //Added by Rajesh,  17th Sept, 5th lesson booking
                                                Fifth_Lesson__c fifLes = fillFifthLesson(enr, dt);
                                                fifLes.Remarks__c = remStr; 
                                                fifthLsnList.add(fifLes);
                                            }
                                        }else{
                                            bookList.add(bTemp);
                                        }
                                    
                                         //Adding trial time during Aureus at home center
                                        if(enr.Center__c == Label.Aureus_at_Home_Id){
                                            String currDay =  DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('E');
                                            String key = enr.Teacher__c+'#'+enr.Center__c+'#'+currDay;
                                            
                                            if(tcrWrkHourMap.containsKey(key)){
                                                Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                
                                                Time tempT = enr.Lesson_Start_time__c;
                                                /*if(String.isNotBlank(lw.lessonSlctSlot)){
                                                    List<String> timeList = lw.lessonSlctSlot.split(':');
                                                    tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                }*/
                                                
                                                if(tchrworkH.Start_Time__c != tempT){
                                                   //Traveling booking Before
                                                  /*  Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                                    befBook.Status__c     = ConstantsClass.scheduledStatus;
                                                    befBook.Type__c       = ConstantsClass.busyBookingType;
                                                    befBook.Remarks__c    = 'Booking for before trial';
                                                    befBook.Category__c   = 'Travel';
                                                    //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                    befBook.End_Time__c   = befBook.Start_Time__c;
                                                    befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                    //befBook.End_Time__c   = befBook.Start_Time__c;*/
                                                    //
                                                    Booking__c befBook = fillBook(bookLessRecId, enr, ConstantsClass.scheduledStatus, bookType, dt, null);
                                                    befBook.Type__c       = ConstantsClass.busyBookingType;
                                                    befBook.Remarks__c    = 'Booking for before trial';
                                                    befBook.Category__c   = 'Travel';
                                                    //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                    befBook.End_Time__c   = befBook.Start_Time__c;
                                                    befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-30);
 
                                                    if(isCreate5thPlaceBooking){   
                                                       /* befBook.Category__c= 'Placeholder';
                                                        
                                                        //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                                        befBook.Remarks__c = 'Booking for before trial,'+remStr; */
                                                        //Added by Rajesh,  17th Sept, 5th lesson booking
                                                        if(!isLinkGrpBookClsId){
                                                            Fifth_Lesson__c fifLes = fillFifthLesson(enr, dt);
                                                            fifLes.Remarks__c = remStr; 
                                                            fifthLsnList.add(fifLes);
                                                        }
                                                    }else{                                                               
                                                        bookList.add(befBook);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    dt = dt.addDays(7);
                                }    
                                
                                 
                                //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                                Decimal tempGstPrcntg = enr.Center__r.Country__r.Tax_Rate__c != null ? enr.Center__r.Country__r.Tax_Rate__c : 0;
                                 
                                 //Start Filling Invoice Line items
                                if(fm.prgFees> 0){
                                    String remarksStr = ConstantsClass.pkgPrgFeesDes;
                                    
                                    //Added by Rajesh: 25th June 2019, Calcuating prg fee and discount on invoice line item on the bases of Lessons
                                    if(fm.pkgFeesPromtnalDis > 0 && fm.prmtnalPkgInMonth > 0 && fm.proNoOfLess >0){
                                        // Decimal prgFeeForSingleLess = fm.prgFees/fm.proNoOfLess;
                                        Decimal prgFeeForSingleLess = fm.actPkgFee/fm.proNoOfLess;
                                        Decimal prgDisFeeForSingleLess = 0;
                                        if(fm.pkgFeesPromtnalDis > 0){
                                            //prgDisFeeForSingleLess = fm.pkgFeesPromtnalDis/fm.proNoOfLess;
                                            prgDisFeeForSingleLess = fm.actDiscount/fm.proNoOfLess;
                                        }
                                        Date stDt = enr.Lessons_Start_Date__c;
                                        
                                        currLesDt = null;
                                        Integer countDtforMonth = 0;
                                        
                                        while(stDt<=promPerEndDate){
                                            if(currLesDt == null)
                                                currLesDt = stDt;
                                            
                                            if(currLesDt.month() == stDt.month()){
                                                if(countDtforMonth < 4){
                                                    countDtforMonth = countDtforMonth+1;
                                                }
                                            }else{
                                                Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                                                Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (tempPrgFee), remarksStr, enr.Teacher__c);
                                                invLnItm.Package__c   = enr.Package__c;
                                                invLnItm.Invoice__r   = inv;
                                                invLnItm.Enrolment__c = enr.Id;
                                                invLnItm.Subscription_Line_Item__r = subLItm;
                                                invLnItm.Month__c = currLesDt;
                                                // commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                               // if(prgDisFeeForSingleLess > 0)
                                                    //invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount((prgDisFeeForSingleLess*countDtforMonth)); 
                                                
                                                //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                                                Decimal tempTotAmt = invLnItm.Amount__c; 
                                                //tempTotAmt = invLnItm.Discount_Amount__c > 0 ? (tempTotAmt-invLnItm.Discount_Amount__c): tempTotAmt; 
                                                invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                                
                                                invLineItmList.add(invLnItm);
                                                
                                                  //start: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                                if(prgDisFeeForSingleLess >0){
                                                    tempTotAmt = (prgDisFeeForSingleLess*countDtforMonth) * -1; 
                                                    invLnItm = BillingUtility.fillInvLnItm(null, null, null, tempTotAmt, remarksStr +' (Discount)', enr.Teacher__c);
                                                    invLnItm.Is_Discount__c = true;
                                                    invLnItm.Package__c   = enr.Package__c;
                                                    invLnItm.Invoice__r   = inv;
                                                    invLnItm.Enrolment__c = enr.Id;
                                                    invLnItm.Subscription_Line_Item__r = subLItm;
                                                    invLnItm.Month__c = currLesDt;
                                                    invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                                    invLineItmList.add(invLnItm);
                                                }
                                                  //end: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                                currLesDt = stDt;
                                                countDtforMonth = 1;
                                            }                                            
                                            stDt = stDt.addDays(7);
                                        }
                                        
                                        if(countDtforMonth > 0){
                                            Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (tempPrgFee), remarksStr, enr.Teacher__c);
                                            invLnItm.Package__c   = enr.Package__c;
                                            invLnItm.Invoice__r   = inv;
                                            invLnItm.Enrolment__c = enr.Id;
                                            invLnItm.Subscription_Line_Item__r = subLItm;
                                            invLnItm.Month__c = currLesDt;
                                              // commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                            //if(prgDisFeeForSingleLess > 0)
                                                //invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(BillingUtility.roundOffAmount((prgDisFeeForSingleLess*countDtforMonth))); 
                                            
                                            //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                                            Decimal tempTotAmt = invLnItm.Amount__c; 
                                            //tempTotAmt = invLnItm.Discount_Amount__c > 0 ? (tempTotAmt-invLnItm.Discount_Amount__c): tempTotAmt; 
                                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                            
                                            invLineItmList.add(invLnItm);
                                              //start: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                            if(prgDisFeeForSingleLess > 0){
                                                tempTotAmt = (prgDisFeeForSingleLess*countDtforMonth) * -1; 
                                                invLnItm = BillingUtility.fillInvLnItm(null, null, null, (tempTotAmt), remarksStr+' (Discount)', enr.Teacher__c);
                                                invLnItm.Package__c   = enr.Package__c;
                                                invLnItm.Is_Discount__c = true;
                                                invLnItm.Invoice__r   = inv;
                                                invLnItm.Enrolment__c = enr.Id;
                                                invLnItm.Subscription_Line_Item__r = subLItm;
                                                invLnItm.Month__c = currLesDt;
                                                invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                                
                                                invLineItmList.add(invLnItm);
                                            }
                                              // end:commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                        }
                                    }else{
                                        Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.prgFees), remarksStr, enr.Teacher__c);
                                        invLnItm.Package__c   = enr.Package__c;
                                        invLnItm.Invoice__r   = inv;
                                        invLnItm.Enrolment__c = enr.Id;
                                        invLnItm.Subscription_Line_Item__r = subLItm;
                                        invLnItm.Month__c     =  enr.Lessons_Start_Date__c;
                                          // commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                        //if(fm.pkgFeesPromtnalDis > 0)
                                            //invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(fm.pkgFeesPromtnalDis); 
                                        
                                        //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                                        Decimal tempTotAmt = invLnItm.Amount__c; 
                                        //tempTotAmt = invLnItm.Discount_Amount__c > 0 ? (tempTotAmt-invLnItm.Discount_Amount__c): tempTotAmt; 
                                        invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                        
                                        invLineItmList.add(invLnItm);
                                        //start: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                        if(fm.pkgFeesPromtnalDis > 0){
                                            tempTotAmt =fm.pkgFeesPromtnalDis * -1;
                                            invLnItm = BillingUtility.fillInvLnItm(null, null, null,(tempTotAmt), remarksStr+' (Discount)', enr.Teacher__c);
                                            invLnItm.Package__c   = enr.Package__c;
                                            invLnItm.Invoice__r   = inv;
                                            invLnItm.Enrolment__c = enr.Id;
                                            invLnItm.Subscription_Line_Item__r = subLItm;
                                            invLnItm.Month__c     =  enr.Lessons_Start_Date__c;
                                            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount(( tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                            invLnItm.Is_Discount__c = true;
                                            invLineItmList.add(invLnItm);
                                        }
                                          //end: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                    }
                                }
                                if(fm.regiFees> 0){
                                    String remarksStr = ConstantsClass.pkgRegFeesDes;
                                    
                                    Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.regiFees), remarksStr, enr.Teacher__c);
                                    invLnItm.Package__c   = enr.Package__c;
                                    invLnItm.Invoice__r   = inv;
                                    invLnItm.Enrolment__c = enr.Id;
                                    invLnItm.Subscription_Line_Item__r = subLItm;
                                    //Added by Rajesh: 25th June 2019, for poulating month on invoice
                                    //commented by Rajesh: 23rd Oct 2019. instead of lesson date we need to put invoice created date for the registration fees  
                                    //invLnItm.Month__c     =  enr.Lessons_Start_Date__c;
                                    invLnItm.Month__c     =  System.today();
                                      // commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                   // if(fm.regiFeesDis > 0)
                                        //invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(fm.regiFeesDis); 
                                    
                                    //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
                                    Decimal tempTotAmt = invLnItm.Amount__c; 
                                    tempTotAmt = invLnItm.Discount_Amount__c > 0 ? (tempTotAmt-invLnItm.Discount_Amount__c): tempTotAmt; 
                                    invLnItm.GST_Amount__c = BillingUtility.roundOffAmount((tempTotAmt > 0 && tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                    
                                    invLineItmList.add(invLnItm);
                                      //start: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                    if(fm.regiFeesDis > 0){
                                        tempTotAmt = fm.regiFeesDis * -1; 
                                        invLnItm = BillingUtility.fillInvLnItm(null, null, null, (tempTotAmt), remarksStr+' (Discount)', enr.Teacher__c);
                                        invLnItm.Package__c   = enr.Package__c;
                                        invLnItm.Invoice__r   = inv;
                                        invLnItm.Enrolment__c = enr.Id;
                                        invLnItm.Subscription_Line_Item__r = subLItm;
                                        invLnItm.Is_Discount__c = true;
                                        invLnItm.Month__c     =  System.today();
                                        invLnItm.GST_Amount__c = BillingUtility.roundOffAmount(( tempGstPrcntg > 0) ? ((tempTotAmt * tempGstPrcntg) / 100):0);
                                        invLineItmList.add(invLnItm);
                                    }
                                      //end: commented by nishi: 15-Sep-2020: for new reqirement In netsuit we added new invoice line itme for discount amount
                                }
                                if(fm.depFees > 0){
                                    String remarksStr = ConstantsClass.pkgDepFeesDes;
                                    Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, (fm.depFees), remarksStr, enr.Teacher__c);
                                    invLnItm.Package__c   = enr.Package__c;
                                    invLnItm.Invoice__r   = inv;
                                    invLnItm.Enrolment__c = enr.Id;
                                    invLnItm.Subscription_Line_Item__r = subLItm;
                                    invLnItm.Is_Deposit__c = true;
                                    //Added by Rajesh: 25th June 2019, for poulating month on invoice
                                    invLnItm.Month__c     =  enr.Lessons_Start_Date__c;
                                    invLineItmList.add(invLnItm);
                                }
                                       
                                if(fm.refrelDiscount > 0){
                                     //@Juneid 06 Aug 2020, Filling invoice line Item for Reffrel Discount
                                     //String refDisc = ConstantsClass.refrelDiscount;
                                     String refDiscRemark = fm.refrelDiscountName;  
                                     Decimal amount = fm.refrelDiscount !=0 ? (fm.refrelDiscount) : 0;
                                     amount =  (amount * -1);
                                     Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, amount, refDiscRemark, enr.Teacher__c);
                                     invLnItm.Package__c   = enr.Package__c;
                                     invLnItm.Invoice__r   = inv;
                                     invLnItm.Is_Discount__c = true;
                                     invLnItm.Discount_Amount__c = 0;
                                     invLnItm.Enrolment__c = enr.Id;
                                     invLnItm.Subscription_Line_Item__r = subLItm;
                                     invLnItm.Is_Deposit__c = false;
                                     invLnItm.Month__c     =  enr.Lessons_Start_Date__c;
                                      refreldiscountGst = BillingUtility.roundOffAmount(Double.valueOf(amount) * (enr.Center__r.Country__r.Tax_Rate__c / 100));
                                      invLnItm.GST_Amount__c = refreldiscountGst;
                                     invLineItmList.add(invLnItm);
                                     //commented by nishi: 21-Sep-2020: for new netsuite requirement we not create pending payment records now we create credit memo and realted line item
                                     //Juneid 07 Aug 2020, Creating Payment Record for Refferal
                                    /* 
                                    Id paymentAsCreditRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId();
                                     Payment__c cutomerPayment = new Payment__c();
                                     cutomerPayment.RecordTypeId =paymentAsCreditRecId;  // Record Type
                                     cutomerPayment.Payment_Date__c = system.today();  // Payment Date
                                     cutomerPayment.Parent_Account__c = enr.Referred_by__c;  // Parent Account
                                     cutomerPayment.Payment_Status__c = 'Pending';// Payment Status
                                     cutomerPayment.Remarks__c = 'Referral Discount (Customer: '+ enr.parent__r.name +'-'+ enr.Name +')';//Filling Remark
                                     cutomerPayment.Payment_Amount__c = fm.refrelDiscount;// Payment Amount
                                     customerPaymentList.add(cutomerPayment);*/

                                     //Filling credit memo
                                    Credit_Memo__c objCreditMemo        = new Credit_Memo__c();
                                    if(cntrCreditMap.containsKey(enr.Center__c)){
                                        objCreditMemo = cntrCreditMap.get(enr.Center__c);
                                    }else{
                                        objCreditMemo.Parent_Account__c = enr.Referred_by__c;
                                        objCreditMemo.Center__c = enr.Center__c;
                                        //objCreditMemo.From_Invoice__r = inv;
                                        objCreditMemo.Credit_Memo_Date__c = System.today();
                                        objCreditMemo.Status__c = ConstantsClass.creditMemoPendingStatus;
                                        objCreditMemo.Comments__c = 'Referral Discount (Customer: '+ enr.parent__r.name +'-'+ enr.Name +')';
                                        objCreditMemo.Payment_Method__c = 'Card';
                                    }
                                    
                                    cntrCreditMap.put(enr.Center__c, objCreditMemo);
                                    Credit_memo_line_item__c objCreditLineItem = new Credit_memo_line_item__c();
                                    objCreditLineItem.Amount__c = fm.refrelDiscount;
                                    decimal taxAmount = BillingUtility.roundOffAmount(Double.valueOf(fm.refrelDiscount) * (enr.Center__r.Country__r.Tax_Rate__c / 100));
                                    if(taxAmount > 0){
                                        objCreditLineItem.Tax_Amount__c = taxAmount;
                                    }
                                    objCreditLineItem.Package__c =  enr.Package__c;
                                    objCreditLineItem.Enrolment__c =  enr.Id;
                                   // objCreditLineItem.Invoice_Line_Item__r = invLnItm;
                                    objCreditLineItem.Is_Discount__c = true;
                                    objCreditLineItem.Month__c =  enr.Lessons_Start_Date__c;
                                    objCreditLineItem.Remarks__c = 'Referral Discount (Customer: '+ enr.parent__r.name +'-'+ enr.Name +')';
                                    listOfCreditmemolineitem.add(objCreditLineItem);
                                    // end:commented by nishi: 21-Sep-2020: for new netsuite requirement we not create pending payment records now we create credit memo and realted line item
                                 }
                                 /*nishi: 23-Sep-2020: we create credit memo  if student selected package is promo then we are not give discout to student but we give discount to reffei customer */
                                 else if(fm.refreeDiscount > 0){
                                    
                                    //Filling credit memo
                                   Credit_Memo__c objCreditMemo        = new Credit_Memo__c();
                                   if(cntrCreditMap.containsKey(enr.Center__c)){
                                       objCreditMemo = cntrCreditMap.get(enr.Center__c);
                                   }else{
                                       objCreditMemo.Parent_Account__c = enr.Referred_by__c;
                                       objCreditMemo.Center__c = enr.Center__c;
                                      // objCreditMemo.From_Invoice__r = inv;
                                       objCreditMemo.Credit_Memo_Date__c = System.today();
                                       objCreditMemo.Status__c = ConstantsClass.creditMemoPendingStatus;
                                       objCreditMemo.Comments__c = 'Referral Discount (Customer: '+ enr.parent__r.name +' - '+ enr.Name +')';
                                       objCreditMemo.Payment_Method__c = 'Card';
                                   }
                                   
                                   cntrCreditMap.put(enr.Center__c, objCreditMemo);
                                   Credit_memo_line_item__c objCreditLineItem = new Credit_memo_line_item__c();
                                   objCreditLineItem.Amount__c = fm.refreeDiscount;
                                   decimal taxAmount = BillingUtility.roundOffAmount(Double.valueOf(fm.refreeDiscount) * (enr.Center__r.Country__r.Tax_Rate__c / 100));
                                   if(taxAmount > 0){
                                       objCreditLineItem.Tax_Amount__c = taxAmount;
                                   }
                                   objCreditLineItem.Package__c =  enr.Package__c;
                                   objCreditLineItem.Enrolment__c =  enr.Id;
                                   //objCreditLineItem.Invoice_Line_Item__r = invLnItm;
                                   objCreditLineItem.Is_Discount__c = true;
                                   objCreditLineItem.Month__c =  enr.Lessons_Start_Date__c;
                                   objCreditLineItem.Remarks__c = 'Referral Discount';
                                   listOfCreditmemolineitem.add(objCreditLineItem);
                                   // end:commented by nishi: 21-Sep-2020: for new netsuite requirement we not create pending payment records now we create credit memo and realted line item
                                }
                                 //@Juneid 18 Aug,2020,Invoice line Item for Facililty Fee
                                 /*if(fm.facilityFee > 0){
                                     String facilityFeeRemark = ConstantsClass.facilityFee;
                                       // Decimal amount = fm.facilityFee > 0 ? BillingUtility.roundOffAmount(fm.facilityFee) : 0;
                                     Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(fm.facilityFee), facilityFeeRemark, enr.Teacher__c);
                                     invLnItm.Package__c   = enr.Package__c;
                                     invLnItm.Invoice__r   = inv;
                                     invLnItm.Enrolment__c = enr.Id;
                                     invLnItm.Subscription_Line_Item__r = subLItm;
                                     invLnItm.Is_Deposit__c = false;
                                     invLnItm.Month__c     =  enr.Lessons_Start_Date__c;
                                     facilityFeesGst +=fm.facilityGst;
                                     system.debug('facilityFeesGst-->'+facilityFeesGst);
                                     fm.facilityGst = fm.facilityGst;
                                       //facilityFeesGst = BillingUtility.roundOffAmount(Double.valueOf(amount) * (enr.Center__r.Country__r.Tax_Rate__c / 100));
                                      invLnItm.GST_Amount__c = fm.facilityGst;
                                     invLineItmList.add(invLnItm);
                                 }*/
                                //-- End Invoice line item filling
                            }
                        }
                        if(enrolmentList.size() > 0){
                            update enrolmentList;
                            //@Juneid 07 Aug,2020, Notify the reafree about Enrolment
                            sendMailToReffrel(enrolmentList[0]);
                           
                           
                            
                            //Insert Subscription
                            if(centSubMap.size() > 0)
                                upsert centSubMap.values();
                            
                            //Insert Invoice
                            if(cntrInvMap.size() > 0){
                                for(Invoice__c inv: cntrInvMap.values())
                                    inv.Subscription__c = inv.Subscription__r.id;   
                                
                                Insert cntrInvMap.values();
                            }
                            
                             //Insert Payment
                            if(cntrPayMap.size() > 0){
                                for(Payment__c pay: cntrPayMap.values()){
                                    pay.Invoice__c = pay.Invoice__r.id;
                                    //@juneid 18 Aug 2020, Gst on Payment
                                 /*  if(facilityFeesGst > 0){
                                        system.debug('pay.Payment_Amount__c-in gst-->'+pay.Payment_Amount__c);
                                        system.debug('facilityFeesGst--->'+facilityFeesGst);
                                        
                                        pay.Payment_Amount__c += facilityFeesGst;
                                        system.debug('pay.Payment_Amount__c after gst -->'+pay.Payment_Amount__c);
                                    }*/
                                    
                                    pay.Payment_Amount__c = BillingUtility.roundOffAmount(pay.Payment_Amount__c);
                                }
                                insert cntrPayMap.values(); 
                            }
                        
                            if(subLinItmList.size() > 0){
                                for(Subscription_Line_Item__c subsItm: subLinItmList){
                                    subsItm.Subscription__c = subsItm.Subscription__r.Id;
                                    //subsItm.Student__c      = subsItm.Student__r.Id;
                                    //subsItm.Enrolment__c    = subsItm.Enrolment__r.Id;
                                }
                                insert subLinItmList;
                            }
                            
                            if(bookList.size() > 0){
                                //Added by Rajesh on 18th oct 2019. adding country sharing in booking for stop extra process builder on bookings
                                for(Booking__c b: bookList)
                                    b.Country_Sharing__c  = parentAcc.Country_PI__pc;
                                insert bookList;
                            }
                            
                            if(fifthLsnList.size() > 0)
                                insert fifthLsnList;
                            
                            if(invLineItmList.size() > 0){
                                for(Invoice_Line_Item__c invLnItm: invLineItmList){
                                    invLnItm.Invoice__c = invLnItm.Invoice__r.Id;
                                    //vLnItm.Enrolment__c = invLnItm.Enrolment__r.Id;
                                    invLnItm.Subscription_Line_Item__c = invLnItm.Subscription_Line_Item__r.Id;
                                }
                                
                                insert invLineItmList;
                                if(customerPaymentList.size() > 0){
                                 
                                    insert customerPaymentList;
                                }
                            }
                            // start:commented by nishi: 21-Sep-2020: for new netsuite requirement we not create pending payment records now we create credit memo and realted line item

                            if(listOfCreditmemolineitem.size() > 0){
                                // for(Credit_Memo__c objCreditMemo : cntrCreditMap.values()){
                                //     objCreditMemo.From_Invoice__c = objCreditMemo.From_Invoice__r.Id;
                                // }
                                insert cntrCreditMap.values();
                                for(Credit_Memo__c objCreditMemo : cntrCreditMap.values()){
                                    for(Credit_memo_line_item__c creditLnItm: listOfCreditmemolineitem){
                                        creditLnItm.Credit_Memo_Number__c = objCreditMemo.Id;
                                       // creditLnItm.Invoice_Line_Item__c = creditLnItm.Invoice_Line_Item__r.Id;
                                    }
                                }
                                
                                insert listOfCreditmemolineitem;
                            }
                            //end:commented by nishi: 21-Sep-2020: for new netsuite requirement we not create pending payment records now we create credit memo and realted line item
                            
                            //Added by rajesh,17th sept 2019: cancelled booking process if teacher on leave
                            Map<String,List<Booking__c>> bookingMap = new Map<String,List<Booking__c>>();
                            Map<String,List<Fifth_Lesson__c>> fifthLessMap = new Map<String,List<Fifth_Lesson__c>>();
                            List<Booking__c> bCancellationList = new List<Booking__c>();
                            List<Fifth_Lesson__c> fifthLsnCanList = new List<Fifth_Lesson__c>();
                            
                            Set<String> tchrTempSet = new Set<String>();
                            Date endDate = tempLessonDt.addMonths(12);                             
                            Integer numberOfDays = Date.daysInMonth(endDate.year(), endDate.month());
                            Date lastDayOfEndDateMonth = Date.newInstance(endDate.year(), endDate.month(), numberOfDays);
                            
                            List<Booking__c> bookingList = [SELECT Id, Name, Status__c, Type__c, Center__c, Package__c,
                                                                   Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, Teacher_Account__r.Employee_Duty_Type__c,
                                                                   Start_Time__c, Duration__c, Student__c, Student__r.Name, Student__r.Parent__c,Student__r.PersonContactId,
                                                                   Student__r.Parent__r.PersonContactId, End_Time__c, Enrolment__c, Enrolment__r.Lessons_Start_Date__c, Center__r.Location__c, 
                                                                   RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c 
                                                            FROM Booking__c 
                                                            WHERE Id IN: bookList];
                            List<Fifth_Lesson__c> fifthLsnTempList = [SELECT Id, Name, Center__c, Booking_Date__c, Teacher_Account__c, Package__c, 
                                                                           Start_Time__c, Student__c, Student__r.Name, Student__r.Parent__c,Student__r.PersonContactId,
                                                                           Student__r.Parent__r.PersonContactId, End_Time__c, Enrolment__c, Center__r.Location__c
                                                                      FROM Fifth_Lesson__c 
                                                                      WHERE Id IN: fifthLsnList];
                           
                            List<Ossia_Organisation_Settings__mdt>   listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
                                                                      Language, NamespacePrefix,Makeup_Expiry_Days_For_Public_Holiday__c, Label, QualifiedApiName, Makeup_Expiry_Days__c,
                                                                      Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
                                                                      WHERE Label =:System.Label.Ossia_Organisation_Name];
                            for(Booking__c b: bookingList){
                                if(b.Booking_Date__c >= b.Enrolment__r.Lessons_Start_Date__c){
                                    List<Booking__c> bList = new List<Booking__c>();
                                    
                                    //Adding date map key for public holiday
                                    String key = b.Booking_Date__c + '';
                                    if(bookingMap.containsKey(key))
                                        bList = bookingMap.get(key);
                                    bList.add(b);
                                    bookingMap.put(key, bList);
                                    
                                    //Adding date with teacher key for teacher leave request
                                    key = key+'#'+b.Teacher_Account__c;     
                                    bList = new List<Booking__c>();
                                    if(bookingMap.containsKey(key))
                                        bList = bookingMap.get(key);
                                    bList.add(b);
                                    bookingMap.put(key, bList);
                                    
                                    tchrTempSet.add(b.Teacher_Account__c);
                                }
                            }
                            for(Fifth_Lesson__c f: fifthLsnTempList){
                                List<Fifth_Lesson__c> fifthLesnList = new List<Fifth_Lesson__c>();
                                
                                //Adding date map key for public holiday
                                String key = f.Booking_Date__c + '';
                                if(fifthLessMap.containsKey(key))
                                    fifthLesnList = fifthLessMap.get(key);
                                fifthLesnList.add(f);
                                fifthLessMap.put(key, fifthLesnList);
                                
                                //Adding date with teacher key for teacher leave request
                                key = key+'#'+f.Teacher_Account__c;     
                                fifthLesnList = new List<Fifth_Lesson__c>();
                                if(fifthLessMap.containsKey(key))
                                    fifthLesnList = fifthLessMap.get(key);
                                fifthLesnList.add(f);
                                fifthLessMap.put(key, fifthLesnList);
                                
                                tchrTempSet.add(f.Teacher_Account__c);
                            }
                            Set<Id> canBookIds = new Set<Id>();
                            for(Leave_Request__c lveReq: [SELECT Id, Name, Leave_Type__c, Employee__c, Leave_Start_Date__c, Leave_End_Date__c 
                                                          FROM Leave_Request__c 
                                                          WHERE Employee__c IN:tchrTempSet AND Status__c = 'Approved' AND
                                                          Leave_Start_Date__c >=Today AND Leave_Start_Date__c <=: lastDayOfEndDateMonth]){
                                
                                Date d = lveReq.Leave_Start_Date__c;
                                while(d <= lveReq.Leave_End_Date__c){ 
                                    String key = d+'#'+lveReq.Employee__c;
                                    
                                    if(bookingMap.containsKey(key)){
                                        for(Booking__c b: bookingMap.get(key)){
                                            if(!canBookIds.contains(b.Id)){
                                                b.Status__c = ConstantsClass.statusCanceled;
                                                b.Available_Make_up_Units__c = b.Duration__c; 
                                                // added by nishi: 22-Sep-2020: for manage ossia organization student we added differnent days in expiry dates
        
                                                if(isOssia){
                                                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                                        b.Make_up_Expiry_Date__c   = b.Booking_Date__c.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c));
                                                    }
                                                }else{
                                                    b.Make_up_Expiry_Date__c  = b.Booking_Date__c.addDays(120);
                                                }
                                                // added by nishi: 22-sep-2020: for manage ossia organization student we added differnent days in expiry dates
        
                                                b.Makeup_Reason__c = 'Teacher Mc';
                                                b.Cancellation_Reason__c = 'Teacher Mc';
                                                bCancellationList.add(b);
                                                canBookIds.add(b.Id);
                                            }
                                        }
                                    }
                                    
                                    if(fifthLessMap.containsKey(key)){
                                        for(Fifth_Lesson__c f: fifthLessMap.get(key)){
                                            if(!canBookIds.contains(f.Id)){
                                                f.IsActive__c = False;
                                                fifthLsnCanList.add(f);  
                                                canBookIds.add(f.Id);
                                            }
                                        }
                                    }
                                    d= d.addDays(1);
                                }
                            }
                            
                            for(Public_Holiday__c pubHoliday: [SELECT Id, Name, Public_Holiday_Date__c,Organisation_Status__c 
                                                               FROM Public_Holiday__c 
                                                               WHERE Organisation__c =: cenOrgId AND Public_Holiday_Date__c >=Today AND Public_Holiday_Date__c <=: lastDayOfEndDateMonth 
                                                               AND Status__c IN('Execution completed') AND Organisation_Status__c != null]){
                                String key = pubHoliday.Public_Holiday_Date__c+'';
                                
                                if(bookingMap.containsKey(key)){
                                    for(Booking__c b: bookingMap.get(key)){
                                        Boolean isCancelBook = false;
                                        if(pubHoliday.Organisation_Status__c == 'Closed' || (pubHoliday.Organisation_Status__c == 'Open' && b.Teacher_Account__r.Employee_Duty_Type__c=='Duty'))
                                            isCancelBook = true;
                                        
                                        if(isCancelBook && !canBookIds.contains(b.Id)){
                                            b.Status__c = ConstantsClass.statusCanceled;
                                            b.Available_Make_up_Units__c = b.Duration__c; 
                                            // added by nishi: 22-Aug-2020: for manage ossia organization student we added 180 days in expiry dates
                                            if(isOssia){
                                                if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                                    b.Make_up_Expiry_Date__c   = b.Booking_Date__c.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_For_Public_Holiday__c));
                                                }
                                            }else{
                                                b.Make_up_Expiry_Date__c   = b.Booking_Date__c.addDays(120);
                                            }
                                            // added by nishi: 22-Aug-2020: for manage ossia organization student we added 180 days in expiry dates
        
                                            b.Cancellation_Reason__c   = 'Holidays';
                                            b.Public_Holiday_Status__c = pubHoliday.Organisation_Status__c;
                                            bCancellationList.add(b);
                                            canBookIds.add(b.Id);
                                        }
                                    }                                                 
                                }
                                if(fifthLessMap.containsKey(key)){
                                    for(Fifth_Lesson__c f: fifthLessMap.get(key)){
                                        if(!canBookIds.contains(f.Id))
                                            fifthLsnCanList.add(f);   
                                    }
                                }
                            }
                            if(bCancellationList.size() > 0){
                                update bCancellationList;
                                bookingsCancellationProcess(bCancellationList);
                            }
                            if(fifthLsnCanList.size() > 0){
                               // update fifthLsnCanList;
                                createPlaceholderForFifthLsn(fifthLsnCanList);
                                //bookingsCancellationProcess(bCancellationList);
                            }

                            //Jatin: 6-Mar-2020: Start: For  not to Filter out the Camp Placeholder in enrolment Process 
                            campBookingCancelProcess(enrolmentTeacherIds,enrolmentCenterIds,bookingMap,fifthLessMap,canBookIds,isOssia);
                            //Jatin: 6-Mar-2020: End: For  not to Filter out the Camp Placeholder in enrolment Process 
                            //@Juneid 22 Aug 20202 , Passing organization to next page as per page filter
                            PageReference pageRef = new PageReference('/apex/thankyoupage_ipad?&isOssia='+isOssia);
                            
                            Set<String> invIds = new Set<String>();
                            Integer invCounter = 1;
                            for(Invoice__c inv: cntrInvMap.values()){
                                String invStr = 'inv'+invCounter ;
                                pageRef.getParameters().put(invStr, inv.Id);    
                                
                                invCounter = invCounter+1;
                                invIds.add(inv.Id);
                            }
                            //Added by Sanjay/Rajesh, 26th June 2019.  For push invoice on sageIntaccount describe by Sanjay
                            SageIntacctIntegrationUtility.newEnrolment(String.valueOf(parentAcc.Id), invIds);
                            
                            pageRef.getParameters().put('scId', sc.id);
                            return pageRef.setRedirect(true);
                        }
                    }else{
                        errorMsg = sc.error.message;
                        isError  = true;
                        
                        //Added by Rajesh, 30th Sept 2019. showing custom error messagge if card decliend
                        if(String.isNotBlank(sc.error.decline_code))
                            errorMsg= 'Payment Failed. Please try with a different card.';
                    }
                }
            }catch(Exception e){
                Database.rollback(sp);
                
                System.debug('Error:  '+e.getMessage());
                errorMsg = e.getMessage();
                isError  = true;
                
                //Create error log and refund amount
                errorObj.exceptionMessage = errorMsg;
                String jsonObj = JSON.serialize(errorObj);
                
                system.debug('jsonObj-->'+jsonObj);
                
                EnrollmentProcessErrorLogs.generateErrorLogsAndRefundAmount(jsonObj);                
                return null;
            }
        }
        /*List<Account> accListToUpdate = new List<Account>();
        System.debug('@@enrolDetails'+enrolDetails.parent);
        String parentId = '';
        if(String.isNotBlank(enrolDetails.parent.id)){
            parentId = enrolDetails.parent.id;
            accListToUpdate.add(fillAccountFromDetails(enrolDetails.parent, 'parent'));
            System.debug('@@Got update');
        }
        
        if(enrolDetails.students.size() > 0){
            for(String students : enrolDetails.students.keySet()){
                if(students != parentId){
                    accListToUpdate.add(fillAccountFromDetails(enrolDetails.students.get(students), 'student'));
                }
            }
        }
        if(accListToUpdate.size() > 0){
            update accListToUpdate;    
        }
       
        if(enrolDetails.billingDetails.grandtotal > 0 && enrolDetails.enrolments.values().size() > 0 && String.isNotBlank(enrolDetails.parent.stripeId)){
            List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
            Invoice_Line_Item__c invoiceLineItem;
            Enrolment__c enrolObj = new Enrolment__c();
            //BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(enrolDetails.parent.stripeId, enrolDetails.billingDetails.grandtotal, ConstantsClass.currencyCode); 
            if(TRUE){
                Invoice__c objInvoice = BillingUtility.fillInvoice(enrolDetails.enrolments.values()[0].Subscription_Line_Items__r[0].Subscription__c, enrolDetails.parent.id, constantsClass.paidStatus);
                objInvoice.Center__c = enrolDetails.enrolments.values()[0].center__c;
                insert objInvoice;
                if(String.isNotBlank(objInvoice.Id)){
                    for(String enrolId : enrolDetails.enrolments.keySet()){
                        enrolObj = enrolDetails.enrolments.get(enrolId);
                        if(enrolObj.Package__r.Package_Fee__c > 0){
                            invoiceLineItem = new Invoice_Line_Item__c();
                            invoiceLineItem = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolObj.Subscription_Line_Items__r[0], enrolObj.Package__r.Package_Fee__c, enrolObj.Package__r.Id, false, '');
                            invoiceLineItem.Month__c = System.today();
                            invoiceLineItems.add(invoiceLineItem);
                        }
                        
                        if(enrolObj.Package__r.Deposit_Fee__c > 0){
                            invoiceLineItem = new Invoice_Line_Item__c();
                            invoiceLineItem = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolObj.Subscription_Line_Items__r[0], enrolObj.Package__r.Deposit_Fee__c, enrolObj.Package__r.Id, true, '');
                            invoiceLineItem.Month__c = System.today();
                            invoiceLineItem.Is_Deposit__c = True;
                            invoiceLineItems.add(invoiceLineItem);
                        }
                        
                        if(enrolObj.Package__r.Registration_Fee__c > 0){
                            invoiceLineItem = new Invoice_Line_Item__c();
                            invoiceLineItem = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolObj.Subscription_Line_Items__r[0], enrolObj.Package__r.Registration_Fee__c, enrolObj.Package__r.Id, false, '');
                            invoiceLineItem.Month__c = System.today();
                            invoiceLineItem.Remarks__c = 'Registration Fee';
                            invoiceLineItems.add(invoiceLineItem);
                        }
                    }
                }
                
                if(invoiceLineItems.size() > 0){
                    insert invoiceLineItems;
                }
                
                if(String.isNotBlank(objInvoice.Id)){
                    objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:objInvoice.Id LIMIT 1];   
                }
                
                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c, objInvoice.Id, objInvoice.Total_Amount__c, ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = '';
                objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                INSERT objPayment; 
                
                if(objInvoice != NULL){
                    BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                }
            }
        }*/
        
        //return new PageReference('/apex/thankyoupage_ipad');
        return null;
    }   
    
    // jatin: 6-Mar-2020: for find camp booking then we canceled for teacher is busy in camp 
    public static void campBookingCancelProcess(set<string> tchrSet,Set<string> centSet,Map<String,List<Booking__c>> bookingMap,Map<String,List<Fifth_Lesson__c>> fifthLessMap,
                                                set<id> canBookIds,boolean isOssia){
        List<Booking__c> campCancellationList = new List<Booking__c>();
        List<Ossia_Organisation_Settings__mdt>   listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
        Language, NamespacePrefix,Makeup_Expiry_Days_For_Public_Holiday__c, Label, QualifiedApiName, Makeup_Expiry_Days__c,
        Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
        WHERE Label =:System.Label.Ossia_Organisation_Name];
        List<Fifth_Lesson__c> campFifthLsnCanList = new List<Fifth_Lesson__c>();
        
                                            for(Camp_Day_Teachers__c campTeacher : [SELECT Id, Camp_Teacher__c, Start_time__c, End_Time__c, Status__c, Camp_Day__c,
                                                Camp_Day__r.Dates_Of_The_Camp__c ,Camp_Day__r.Camp_Name__r.Centre__c,Camp_Day__r.Camp_Name__r.Name
                                                FROM Camp_Day_Teachers__c
                                                WHERE Camp_Teacher__c IN: tchrSet  
                                                AND Camp_Day__r.Camp_Name__r.Centre__c IN: centSet
                                                AND Status__c =: ConstantsClass.campTeacherActiveStatus
                                                AND Start_Time__c != null 
                                                AND End_Time__c != null]){
                                                    
                                                    Date d = campTeacher.Camp_Day__r.Dates_Of_The_Camp__c;
                                                    String key = campTeacher.Camp_Day__r.Dates_Of_The_Camp__c+'';
                                                    
                                                    if(bookingMap.containsKey(key)){
                                                        for(Booking__c b: bookingMap.get(key)){
                                                            if(!canBookIds.contains(b.Id)){
                                                                b.Status__c = ConstantsClass.statusCanceled;
                                                                b.Available_Make_up_Units__c = b.Duration__c; 
                                                                 // added by nishi: 22-Aug-2020: for manage ossia organization student we added 180 days in expiry dates
                                                                if(isOssia){
                                                                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                                                        b.Make_up_Expiry_Date__c   = b.Booking_Date__c.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_For_Public_Holiday__c));
                                                                    }
                                                                }else{
                                                                    b.Make_up_Expiry_Date__c   = b.Booking_Date__c.addDays(120);
                                                                }
                                                                // added by nishi: 22-Aug-2020: for manage ossia organization student we added 180 days in expiry dates
                                                                b.Cancellation_Reason__c   = 'Holidays';
                                                                campCancellationList.add(b);
                                                                canBookIds.add(b.Id);
                                                            }
                                                        }                                                 
                                                    }
                                                    if(fifthLessMap.containsKey(key)){
                                                        for(Fifth_Lesson__c f: fifthLessMap.get(key)){
                                                            if(!canBookIds.contains(f.Id))
                                                                campFifthLsnCanList.add(f);   
                                                        }
                                                    }
                                                }
                                                    
        if(campCancellationList.size() > 0){
            update campCancellationList;
            campBookingsCancellationProcess(campCancellationList);
        }
                                                    
        if(campFifthLsnCanList.size() > 0){
            createPlaceholderForCampFifthLsn(campFifthLsnCanList);
        }
    }
    @testVisible
    private static void bookingsCancellationProcess(List<Booking__c> bookingList){
       /* List<Booking__c> bookingList = [SELECT Id, Name, Status__c, Type__c, Center__c,
                                               Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, 
                                               Start_Time__c, Duration__c, Student__c, Student__r.Name, Student__r.Parent__c,Student__r.PersonContactId,
                                               Student__r.Parent__r.PersonContactId, End_Time__c, Enrolment__c, Center__r.Location__c, 
                                               RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c 
                                        FROM Booking__c 
                                       WHERE Id IN: bookList];
        for(Booking__c b: bookingList){
            b.Status__c = ConstantsClass.statusCanceled;
            b.Available_Make_up_Units__c = b.Duration__c; 
            b.Make_up_Expiry_Date__c  = b.Booking_Date__c.addDays(120);
            b.Makeup_Reason__c = 'Teacher Mc';
            b.Cancellation_Reason__c = 'Teacher Mc';
        }
        update bookingList;*/
        
        List<Booking__c> placeholderList = createPlaceholder(bookingList);
        insert placeholderList;
        
        List<Case> caseList = AureusUtility.createCase(bookingList);
        insert caseList;
        
        Set<Id> csIds = new Set<Id>();
        for(Case c : caseList)
            csIds.add(c.Id);
        //@Juneid 26 Aug 2020, Org wise Email
        if(csIds != null && csIds.size()> 0){
            if(caseList[0].Centre_Name__r.Organisation__r.name  == Label.Ossia_Organisation_Name) {
                AureusUtility.sendOssiaCaseEmail(csIds);
            }else{
                AureusUtility.sendCaseEmail(csIds);    
            }
        }
     
    }
    // added by jatin: 6Mar-2020: for cancel booking and create placeholder for camp process
    public static void campBookingsCancellationProcess(List<Booking__c> bookingList){
         List<Booking__c> placeholderList = createCampPlaceholder(bookingList);
         insert placeholderList;
         
         List<Case> caseList = AureusUtility.createCase(bookingList);
         insert caseList;
         
         Set<Id> csIds = new Set<Id>();
         for(Case c : caseList)
             csIds.add(c.Id);
          //@Juneid 26 Aug 2020, Org wise Email
        if(caseList[0].Centre_Name__r.Organisation__r.name  == Label.Ossia_Organisation_Name) {
            AureusUtility.sendOssiaCaseEmail(csIds);
        }else{
               AureusUtility.sendCaseEmail(csIds);    
        }
         //AureusUtility.sendCaseEmail(csIds);    
     }
// added by jatin: 6Mar-2020: for add  placeholder booking for camp process
     private static List<Booking__c> createCampPlaceholder(List<Booking__c> bookingObjList){
        
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Booking__c bookingCurrentObj : bookingObjList){
            Booking__c placeholderObj = new Booking__c();
            placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = bookingCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = bookingCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = bookingCurrentObj.End_Time__c;
            placeholderObj.status__c = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = bookingCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c = bookingCurrentObj.Center__c;
            placeholderObj.remarks__c = 'Teacher is busy in Camp So placeholder booking for cancelling '+ bookingCurrentObj.Student__r.Name + ' booking';
            //placeholderObj.Category__c = bookingCurrentObj.Cancellation_Reason__c == 'Holidays' ? ConstantsClass.holidayCategory : ConstantsClass.leaveCategory;
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            placeholderObj.Enrolment__c= bookingCurrentObj.Enrolment__c;
            placeholderObj.Student__c  = bookingCurrentObj.Student__c;
            placeholderObj.Package__c  = bookingCurrentObj.Package__c;
            placeholderList.add(placeholderObj);
        }
        return placeholderList;
    }
    
    private static List<Booking__c> createPlaceholder(List<Booking__c> bookingObjList){
        
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Booking__c bookingCurrentObj : bookingObjList){
            Booking__c placeholderObj = new Booking__c();
            placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = bookingCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = bookingCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = bookingCurrentObj.End_Time__c;
            placeholderObj.status__c = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = bookingCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c = bookingCurrentObj.Center__c;
            placeholderObj.remarks__c = 'placeholder booking for cancelling '+ bookingCurrentObj.Student__r.Name + ' booking';
            //placeholderObj.Category__c = bookingCurrentObj.Cancellation_Reason__c == 'Holidays' ? ConstantsClass.holidayCategory : ConstantsClass.leaveCategory;
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            placeholderObj.Enrolment__c= bookingCurrentObj.Enrolment__c;
            placeholderObj.Student__c  = bookingCurrentObj.Student__c;
            placeholderObj.Package__c  = bookingCurrentObj.Package__c;
            placeholderList.add(placeholderObj);
        }
        return placeholderList;
    }
    @TestVisible
    private static void createPlaceholderForFifthLsn(List<Fifth_Lesson__c> fifthLsnObjList){
        
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Fifth_Lesson__c fifthLsnCurrentObj : fifthLsnObjList){
            Booking__c placeholderObj   = new Booking__c();
            placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = fifthLsnCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = fifthLsnCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = fifthLsnCurrentObj.End_Time__c;
            placeholderObj.status__c   = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = fifthLsnCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c   = fifthLsnCurrentObj.Center__c;
            placeholderObj.remarks__c  = 'Placeholder booking for Fifth Lesson '+ fifthLsnCurrentObj.Student__r.Name + ' booking.';
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            placeholderObj.Enrolment__c= fifthLsnCurrentObj.Enrolment__c;
            placeholderObj.Student__c  = fifthLsnCurrentObj.Student__c;
            placeholderObj.Package__c  = fifthLsnCurrentObj.Package__c;
            placeholderList.add(placeholderObj);            
            
            fifthLsnCurrentObj.Booking__r= placeholderObj;
        }
        insert placeholderList;
        
        for(Fifth_Lesson__c fl : fifthLsnObjList){
            fl.IsActive__c = False;
            fl.Booking__c = fl.Booking__r.Id;
        }
        
        update fifthLsnObjList;
    }

    // added by jatin: 6Mar-2020: for create placeholder booking for camp process
    public static void createPlaceholderForCampFifthLsn(List<Fifth_Lesson__c> fifthLsnObjList){
        
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Fifth_Lesson__c fifthLsnCurrentObj : fifthLsnObjList){
            Booking__c placeholderObj   = new Booking__c();
            placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = fifthLsnCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = fifthLsnCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = fifthLsnCurrentObj.End_Time__c;
            placeholderObj.status__c   = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = fifthLsnCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c   = fifthLsnCurrentObj.Center__c;
            placeholderObj.remarks__c  = 'Teacher is busy in Camp So Placeholder booking for Fifth Lesson '+ fifthLsnCurrentObj.Student__r.Name + ' booking.';
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            placeholderObj.Enrolment__c= fifthLsnCurrentObj.Enrolment__c;
            placeholderObj.Student__c  = fifthLsnCurrentObj.Student__c;
            placeholderObj.Package__c  = fifthLsnCurrentObj.Package__c;
            placeholderList.add(placeholderObj);            
            
            fifthLsnCurrentObj.Booking__r= placeholderObj;
        }
        insert placeholderList;
        
        for(Fifth_Lesson__c fl : fifthLsnObjList){
            fl.IsActive__c = False;
            fl.Booking__c = fl.Booking__r.Id;
        }
        
        update fifthLsnObjList;
    }
    /*
    public static List<Case> createCase(List<Booking__c> bookingObjList){
        List<Case> caseList = new List<Case>();
     
        for(Booking__c objBooking: bookingObjList){  
            Case currentCase = new Case();
            currentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.caseServiceEnqRecTypeName).getRecordTypeId();
            currentCase.Booking__c = objBooking.Id;
            currentCase.Enrolment__c = objBooking.Enrolment__c;            
            currentCase.Student_Name__c = objBooking.Student__c;
            currentCase.Centre_Name__c = objBooking.Center__c;
            currentCase.Location__c = objBooking.Center__r.Location__c;            
            currentCase.Status =  ConstantsClass.caseOpenStatus;  // ConstantsClass.casePendingStatus;
            currentCase.Type = ConstantsClass.cancelType;            
            currentCase.Leave_Start_Date__c = objBooking.Booking_Date__c;
            currentCase.Priority = 'Medium';    
            
            if(String.isNotBlank(objBooking.Student__r.Parent__c)){
                currentCase.ContactId = objBooking.Student__r.Parent__r.PersonContactId;
                currentCase.AccountId = objBooking.Student__r.Parent__c;
            }else if(String.isNotBlank(objBooking.Student__c) && String.isBlank(objBooking.Student__r.Parent__c)){
                currentCase.ContactId = objBooking.Student__r.PersonContactId;
                currentCase.AccountId = objBooking.Student__c;
            }
            caseList.add(currentCase);
        }
        return caseList;
    }
    
    @future
    private static void sendCaseEmail(Set<Id> caseIds){
        // template when teacher is on Holiday
        
        Map<String,Id> templateMap = new Map<String,Id>();
        for(EmailTemplate et: [Select Id,Name,DeveloperName from EmailTemplate where (DeveloperName  = 'Teacher_Leave_Enrolment' OR 
                                                                                      DeveloperName  = 'Holiday_Enrolment_Open' OR 
                                                                                      DeveloperName  = 'Holiday_Enrolment_Closed')]){
            templateMap.put(et.DeveloperName, et.Id);
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Case CasObject:[select Id,Booking__r.Type__c,Booking__r.Status__c,Booking__r.Cancellation_Reason__c, Booking__r.Public_Holiday_Status__c,
                                   Booking__r.Start_Time__c,Booking__r.Parent__r.PersonContactId,Booking__r.Parent__r.personEmail,Booking__r.Center__c,
                                   Booking__r.Center__r.Location__c,Booking__r.Teacher_Account__c 
                            FROM Case WHERE Id IN:caseIds]){
             
            String templateId;
            if(CasObject.Booking__r.Cancellation_Reason__c.equalsIgnoreCase('Teacher Mc') && templateMap.containsKey('Teacher_Leave_Enrolment')){
                templateId = templateMap.get('Teacher_Leave_Enrolment');
            }else if(CasObject.Booking__r.Cancellation_Reason__c.equalsIgnoreCase('Holidays') && String.isNotBlank(CasObject.Booking__r.Public_Holiday_Status__c)){
                if(CasObject.Booking__r.Public_Holiday_Status__c.equalsIgnoreCase('Open') && templateMap.containsKey('Holiday_Enrolment_Open'))
                    templateId = templateMap.get('Holiday_Enrolment_Open');
                else if(CasObject.Booking__r.Public_Holiday_Status__c.equalsIgnoreCase('Closed') && templateMap.containsKey('Holiday_Enrolment_Closed'))
                    templateId = templateMap.get('Holiday_Enrolment_Closed');
            }
            
            if(String.isNotBlank(templateId) && String.isNotBlank(CasObject.Booking__r.Parent__r.PersonEmail)){
                //personEmailList.add(CasObject.Booking__r.Parent__r.personEmail);
                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                //mail.setToAddresses(personEmailList);
                emailList.add(mail);
            }
        }
            system.debug('emailList'+emailList);
        if(!test.isRunningTest())
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }    
    }*/
    
    public void sendEmailToParent(){
       
        /*
        Set<String> setOfEnrolments= new Set<String>();
        setOfEnrolments.addAll(Apexpages.currentpage().getparameters().values());
        
        List<Enrolment__c> enrListT  = [SELECT Id, Parent__r.Name, Student__r.Name, Center__c, Teacher__c, Package__c, Package__r.Duration__C, Package__r.Program__r.Instrument__c,Field_1__c,
                                        Parent__r.Also_a_Student__c, Student__c,  Parent__c, Trial_Date__c,  Trial_Start_Time__c, Center__r.Travel_Time__c, Lessons_Start_Date__c, Lesson_Start_Time__c ,
                                        Parent__r.personContactId, Center__r.Location__c
                                        FROM Enrolment__c  
                                        WHERE  Id IN:setOfEnrolments];
        
        sendEmail(enrListT);
        errorMsg = 'success';*/
        
        Savepoint sp;
        isError = false;
        errorMsg = '';
            
        try{
            sp = Database.setSavepoint();
            List<Enrolment__c> enrList = new List<Enrolment__c>();
            List<Booking__c> bookList  = new List<Booking__c>();
                    
           // String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();  
            for(Enrolment__c enr: enrolDetails.enrolments.values()){
                //enrList.add(new Enrolment__c(Id = enr.Id, Enrolment_Email_Date__c = System.now()));
                 //updated by Rajesh, 16th Nov 2019. to store enrolmentsource on enrolment/case object
                Enrolment__c enrl = new Enrolment__c(Id = enr.Id, Enrolment_Email_Date__c = System.now());
                if(String.isNotBlank(enrolmentSource))
                    enrl.Enrolment_Source__c = enrolmentSource;
                
                enrList.add(enrl);
            }      
            update enrList;
            enrList  = [SELECT Id, Parent__r.Name, Student__r.Name, Center__c, Teacher__c, Package__c, Package__r.Duration__C, Package__r.Program__r.Instrument__c,Field_1__c,
                        Parent__r.Also_a_Student__c, Student__c,  Parent__c, Trial_Date__c,  Trial_Start_Time__c, Center__r.Travel_Time__c, Lessons_Start_Date__c, Lesson_Start_Time__c ,
                        Parent__r.personContactId, Center__r.Location__c, Type__c,class__C
                        FROM Enrolment__c  
                        WHERE  Id IN: enrList];
            //For aureus home centers 
            Set<String> centSet = new Set<String>();
            Set<String> tchrSet = new Set<String>();
            Set<String> daySet = new Set<String>();
            Map<String,Teacher_Working_Hour__c> tcrWrkHourMap = new Map<String,Teacher_Working_Hour__c>();
            Set<String> grpClsBookSet = new Set<String>();
            for(Enrolment__c enr : enrList){
                if(enr.Center__c == Label.Aureus_at_Home_Id){
                    centSet.add(enr.Center__c);
                    tchrSet.add(enr.Teacher__c);
                    
                    if(enr.Lessons_Start_Date__c != null){
                        Date tempDt    = enr.Lessons_Start_Date__c;
                        String currDay = DateTime.newInstance(tempDt, Time.newInstance(0, 0, 0, 0)).format('E');
                        daySet.add(currDay);
                    }
                }
                
                if(enr.Type__c != null && enr.Type__c.equalsIgnoreCase('Group') && enr.Class__c != null)
                    grpClsBookSet.add(enr.Class__c);
            }
            
            Map<String, Booking__c> grpClsBookMap = new Map<String, Booking__c>();
            if(grpClsBookSet.size() > 0){
                String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();   
                for(Class__c cls: [SELECT Id, Name, Package__c, Package__r.Name, Teacher__c, Class_Day__c, Start_Time__c,End_Time__c,
                                   (SELECT Id, Class__c, Booking_Date__c FROM Bookings__r WHERE RecordTypeId =: bookGrpClsRecId AND Booking_Date__c != null)
                                   FROM Class__c WHERE Id IN:grpClsBookSet AND Active__c = True AND Available_Capacity__c > 0
                                   // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                   And Is_Makeup_Class__c = false]){                                                               
                                       
                 for(Booking__c book: cls.Bookings__r)
                    grpClsBookMap.put(cls.Id+'#'+book.Booking_Date__c, book);                                   
                 }    
            }
            
            if(centSet.size() > 0 && tchrSet.size() > 0 && daySet.size() > 0){
                for(Teacher_Working_Hour__c tchr : [SELECT Id,Name,Teacher_Name__c, Center_Name__c, Working_Day__c, Start_Time__c
                                                    FROM Teacher_Working_Hour__c 
                                                    WHERE Teacher_Name__c IN: tchrSet AND Working_Day__c IN:daySet  AND Center_Name__c IN: centSet AND Active__c = true AND Break_Time__c = False 
                                                    AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null ]){
                    String key = tchr.Teacher_Name__c+'#'+tchr.Center_Name__c+'#'+tchr.Working_Day__c;
                    tcrWrkHourMap.put(key,tchr);                                                                     
                }
            }
            
            
            List<Booking__c> bookLstForDel = [SELECT Id,Name FROM Booking__c WHERE Status__c = 'Blocked' AND Enrolment__c IN: enrList];
            if(bookLstForDel.size() > 0)
                delete bookLstForDel;
           
            for(Enrolment__c enr : enrList){
                String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();  
                Boolean isGrpEnrolment = false;
                if(enr.Type__c.equalsIgnoreCase('Group')){
                    bookLessRecId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Lesson').getRecordTypeId();
                    isGrpEnrolment = true;
                }
                
                
                String remStr    =  enr.Parent__r.Name;
                remStr   =  remStr +':'+enr.Student__r.Name;
                
                if(!isGrpEnrolment){
                    //Added by Rajesh: 25th July 2019, for Adding placeholder bookings before enrolment lesson start
                    Date tempDt  = enr.Lessons_Start_Date__c;
                    tempDt = tempDt.addDays(-7); 
                    while(System.today() < tempDt){
                        Booking__c bTemp   = new Booking__c(Student__c = enr.Student__c, Teacher_Account__c = enr.Teacher__c, Enrolment__c = enr.Id);
                        bTemp.RecordTypeId = bookLessRecId;
                        bTemp.Package__c   = enr.Package__c;
                        bTemp.Center__c    = enr.Center__c;
                        bTemp.Type__c      = ConstantsClass.busyBookingType;
                        bTemp.Status__c    = 'Blocked';
                        bTemp.Category__c    = 'Placeholder';
                        bTemp.Booking_Date__c = tempDt;
                        bTemp.Start_Time__c = enr.Lesson_Start_Time__c;
                        bTemp.Remarks__c = 'A future regular enrolemnt starting from '+enr.Lessons_Start_Date__c+' for '+remStr;
                        if(String.isNotBlank(enr.Package__r.Duration__C)){
                            Integer pkgDur = 0;
                            try{
                                pkgDur = Integer.valueOf(enr.Package__r.Duration__C);
                            }catch(exception e){}
                            bTemp.End_Time__c = bTemp.Start_Time__c.addMinutes(pkgDur);
                        }
                        bookList.add(bTemp);    
                        
                        //Adding trial time during Aureus at home center
                        if(enr.Center__c == Label.Aureus_at_Home_Id){                        
                            String currDay =  DateTime.newInstance(tempDt, Time.newInstance(0, 0, 0, 0)).format('E');
                            String key = enr.Teacher__c+'#'+enr.Center__c+'#'+currDay;
                            
                            if(tcrWrkHourMap.containsKey(key)){
                                Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                            
                                if(tchrworkH.Start_Time__c != enr.Lesson_Start_Time__c){
                                    //Traveling booking Before
                                   
                                    Booking__c book   = new Booking__c(Student__c = enr.Student__c, Teacher_Account__c = enr.Teacher__c, Enrolment__c = enr.Id);
                                    book.RecordTypeId = bookLessRecId;
                                    book.Package__c   = enr.Package__c;
                                    book.Center__c    = enr.Center__c;
                                    book.Type__c      = ConstantsClass.busyBookingType;
                                    book.Status__c    = 'Blocked';
                                    book.Category__c   = 'Travel';
                                    book.Booking_Date__c = tempDt;
                                    book.Start_Time__c = enr.Lesson_Start_Time__c;
                                    book.Remarks__c    = 'A future regular enrolemnt starting from '+enr.Lessons_Start_Date__c+' for '+remStr +' Booking for before trial.'+remStr;
                                    book.End_Time__c   = bTemp.Start_Time__c;
                                    book.Start_Time__c = bTemp.Start_Time__c.addMinutes(-30);
                                    bookList.add(book); 
                                }
                            }
                        }
                        tempDt = tempDt.addDays(-7); 
                    }
                }
                
                remStr   =  'Placeholder booking for 5th lesson of '+remStr;
                Date lessDate = enr.Lessons_Start_Date__c;
                Date stDate  = lessDate;
                Date endDate = stDate.addMonths(12); 
            
                Integer numberOfDays = Date.daysInMonth(endDate.year(), endDate.month());
                Date lastDayOfEndDateMonth = Date.newInstance(endDate.year(), endDate.month(), numberOfDays);
            
                Date dt=lessDate;   
                Integer countBookingForMonth = 0;
                Date currLesDt; 
                while(dt<=lastDayOfEndDateMonth){       
                    Boolean isCreate5thPlaceBooking = false;
                    
                    if(currLesDt == null)
                        currLesDt = dt;
                    
                    if(currLesDt.month() == dt.month()){
                        if(countBookingForMonth < 4){
                            countBookingForMonth = countBookingForMonth+1;
                        }else{
                            isCreate5thPlaceBooking = true;
                        }
                    }else{
                        currLesDt = dt;
                        countBookingForMonth = 1;
                    }
                    
                    Booking__c book   = new Booking__c(Student__c = enr.Student__c, Teacher_Account__c = enr.Teacher__c, Enrolment__c = enr.Id);
                    book.RecordTypeId = bookLessRecId;
                    book.Package__c   = enr.Package__c;
                    book.Center__c    = enr.Center__c;
                    book.Type__c      = 'Trial';
                    book.Status__c    = 'Blocked';     
                    book.Booking_Date__c = dt;
                    book.Start_Time__c = enr.Lesson_Start_Time__c;
                    if(String.isNotBlank(enr.Package__r.Duration__C)){
                        Integer pkgDur = 0;
                        try{
                            pkgDur = Integer.valueOf(enr.Package__r.Duration__C);
                        }catch(exception e){}
                        book.End_Time__c = book.Start_Time__c.addMinutes(pkgDur);
                    }
                    
                    if(isGrpEnrolment){
                        if(grpClsBookMap.get(enr.Class__c+'#'+dt) != null)
                            book.Group_Class__c = grpClsBookMap.get(enr.Class__c+'#'+dt).Id;
                    }
                    
                    if(isCreate5thPlaceBooking){
                        book.Status__c  = 'Blocked';
                        book.Type__c    = ConstantsClass.busyBookingType;
                        book.Category__c= 'Placeholder';
                        
                        book.Remarks__c = remStr; 
                    }           
                    if(!isGrpEnrolment)
                        bookList.add(book); 
                    else if(!isCreate5thPlaceBooking)                       
                        bookList.add(book); 
                    
                    Boolean isAureusAtHome = (enr.Center__c == Label.Aureus_at_Home_Id ? true : false);
                    if(isAureusAtHome){
                        //Filling booking for the Before travel  
                        Booking__c befBook = new Booking__c(Student__c = enr.Student__c, Teacher_Account__c = enr.Teacher__c, Enrolment__c = enr.Id);
                        befBook.RecordTypeId  = bookLessRecId;
                        befBook.Type__c       = ConstantsClass.busyBookingType;
                        befBook.Status__c    = 'Blocked';  
                        befBook.Category__c= 'Travel';
                        befBook.Remarks__c = 'Travel time slot for home trial booking';
                        befBook.Package__c = enr.Package__c;
                        befBook.Center__c =  enr.Center__c;
                        befBook.Start_Time__c = book.Start_Time__c.addMinutes(-30);
                        befBook.End_Time__c   = book.Start_Time__c;
                        befBook.Booking_Date__c = dt;
                        
                        if(isGrpEnrolment){
                            if(grpClsBookMap.get(enr.Class__c+'#'+dt) != null)
                                befBook.Group_Class__c = grpClsBookMap.get(enr.Class__c+'#'+dt).Id;
                        }
                        
                        if(isCreate5thPlaceBooking){
                            befBook.Type__c    = ConstantsClass.busyBookingType;
                            befBook.Status__c  = 'Blocked';
                            befBook.Category__c= 'Placeholder';
                            
                            befBook.Remarks__c = 'Travel time slot for home trial booking and' +remStr; 
                        }
                        
                        if(!isGrpEnrolment)
                            bookList.add(befBook);  
                        else if(!isCreate5thPlaceBooking)                       
                            bookList.add(befBook);  
                    }       
                    dt = dt.addDays(7);
                        
                }
            }
            System.debug('@@@@@'+bookList.size());
            if(bookList.size() > 0)
                insert bookList;

            sendEmail(enrList);
            errorMsg = 'success';
          //  return;
               
        }catch(Exception e){
             Database.rollback(sp);
             
             System.debug('Error:  '+e.getMessage());
             errorMsg = e.getMessage();
             isError  = true;
         }
        //return;
    }
    
    private  void sendEmail(List<Enrolment__c> enrListTemp){
         List<EmailTemplate> templateList =  new List<EmailTemplate>();
                //@Juneid 26 Aaug 2020, Orgnization wise templates
                if(isOssia){
                    templateList = [Select Id,name,developerName from EmailTemplate where developerName =:'Ossia_Send_Pending_Enrolment_Link_Email']; 
                }else{
                    templateList =  [Select Id,name,developerName from EmailTemplate where developerName ='Send_Pending_Enrolment_Link_Email' limit 1];
                }
        //List<EmailTemplate> templateList =  [Select Id,name,developerName from EmailTemplate where developerName ='Send_Pending_Enrolment_Link_Email' limit 1];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        if(enrListTemp.size() > 0 && templateList.size() > 0){
            Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>();
            
            for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress])
               mapOfOrgWide.put(objAddress.DisplayName,objAddress);
           
            Enrolment__c enr = enrListTemp.get(0);
            
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateList[0].Id, enr.Parent__r.personContactId, enr.Parent__c);
            
            if( String.isNotBlank(enr.Center__r.Location__c) && mapOfOrgWide.containsKey(enr.Center__r.Location__c)){
                mail.setOrgWideEmailAddressId(mapOfOrgWide.get(enr.Center__r.Location__c).Id);
            }
            mail.setTargetObjectId(enr.Parent__r.personContactId);
            mail.saveAsActivity = true;
            mail.setWhatId(enr.Parent__c);
            mail.setTemplateId(templateList[0].Id);
            
            emailList.add(mail); 
             system.debug('EEEEEEEEEEE-->'+emailList);
            if(emailList.size() > 0){
                system.debug('EEEEEEEEEEE-->'+emailList);
                Messaging.sendEmail(emailList,false);
            }
        }
    }
    
    
    Public void signAgreement(){
        documentDetails = new PandaDocUtility.CreateDocument();
        if(String.isNotBlank(enrolDetails.parent.id)){
            String body = fillCreateDocumentWrapper(enrolDetails);  
            documentDetails = PandaDocUtility.createDocument(body);   
        }  
         
    }

    Public Void waitAgreement(){
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        if(String.isNotBlank(documentDetails.id)){
            document = PandaDocUtility.viewDocument(documentDetails.id);
        } 
    }

    //Added by Rajesh: 19th Sept 2019. To populate updated information in panda doc
    public void  updateCstmrDetail(){
        List<Account> cstmrAccList = new  List<Account>();
        Account parentAcc =  fillAccountFromDetails(enrolDetails.parent, 'parent');
        cstmrAccList.add(parentAcc);
        
        //cstmrAccList.add(stuAcc);
        if(enrolDetails.students.size() > 0){
            for(String students : enrolDetails.students.keySet()){
                if(students != parentAcc.Id)
                    cstmrAccList.add(fillAccountFromDetails(enrolDetails.students.get(students), 'student'));
            }
        }
        
        update cstmrAccList;
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
        if(String.isNotBlank(enrolDetails.parent.id) && String.isNotBlank(documentDetails.id)){
            String body = '{ "recipient": "'+enrolDetails.parent.email+'", "lifetime": 3600}';   
            sessionDetails = PandaDocUtility.createSession(documentDetails.id, body);
            System.debug('@@@sessionDetails'+sessionDetails);
            if(String.isNotBlank(sessionDetails.id)){
                sessionId = sessionDetails.id;     
            }
        }
    }
    
    private String fillCreateDocumentWrapper(EnrolDetails enrolDetail){        
        String jsonBody = '';       
        DocumentWrapper.Fields field;       
        DocumentWrapper.recipients recipient = new DocumentWrapper.recipients();        
        List<DocumentWrapper.Rows> rows = new List<DocumentWrapper.Rows>();     
        List<DocumentWrapper.Sections> sections = new List<DocumentWrapper.Sections>();     
        List<DocumentWrapper.PricingTable> pricingTables = new List<DocumentWrapper.PricingTable>();        
        DocumentWrapper.CreateDocument createDocWrapper = new DocumentWrapper.CreateDocument();     
                
        createDocWrapper.template_uuid = templateId;   
        createDocWrapper.folder_uuid = folderId;
        if(String.isNotBlank(enrolDetail.parent.Id)){       
            createDocWrapper.metadata.salesforceAccount_id = enrolDetail.parent.Id;     
            recipient.first_name = enrolDetail.parent.firstName;        
            recipient.last_name = enrolDetail.parent.lastName;      
            recipient.email = enrolDetail.parent.email;     
            field = new DocumentWrapper.Fields(enrolDetail.parent.firstName +' '+enrolDetail.parent.lastName, 'Parent Name');       
            createDocWrapper.fields = new DocumentWrapper.CustomField(field);       
            recipient.role = 'Client';      
            createDocWrapper.recipients = new List<DocumentWrapper.Recipients>();       
            createDocWrapper.recipients.add(recipient);     
        }       
        if(enrolDetail.enrolments.size() > 0){      
            DateTime enrolmentDateTime;     
            createDocWrapper.name = '';     
            DocumentWrapper.Rows row;  
             //Updated by Rajesh: 19th Sept 2019. To populate updated information in panda doc
            /*for(String enrolStr : enrolDetail.enrolments.keySet()){     
                Enrolment__c enrolmentObj = enrolDetail.enrolments.get(enrolStr);       
                enrolmentDateTime = DateTime.newInstance(enrolmentObj.Lessons_Start_Date__c, enrolmentObj.Lesson_Start_time__c);        
                createDocWrapper.name += enrolmentObj.name + '-';       
                row = new DocumentWrapper.Rows(new DocumentWrapper.Data(enrolmentObj.Student__r.FirstName + ' ' + enrolmentObj.Student__r.LastName), new DocumentWrapper.CustomFields(enrolmentObj.Package__r.Name, enrolmentDateTime.format('EEE @ hh:mm a'),*/ /*enrolmentObj.CreatedDate.format('dd-MM-yyyy')*//* enrolmentDateTime.format('dd-MM-yyyy')));      
                rows.add(row);      
            } */
            for(Enrolment__c enrolmentObj:[SELECT Id, Name, Lessons_Start_Date__c, Lesson_Start_time__c, Student__r.FirstName, Student__r.LastName, Package__r.Name 
                                           FROM Enrolment__c WHERE Id IN: enrolDetail.enrolments.keySet()]){
                enrolmentDateTime = DateTime.newInstance(enrolmentObj.Lessons_Start_Date__c, enrolmentObj.Lesson_Start_time__c);  
                createDocWrapper.name += enrolmentObj.name + '-';       
                row = new DocumentWrapper.Rows(new DocumentWrapper.Data(enrolmentObj.Student__r.FirstName + ' ' + enrolmentObj.Student__r.LastName), new DocumentWrapper.CustomFields(enrolmentObj.Package__r.Name, enrolmentDateTime.format('EEE @ hh:mm a'), /*enrolmentObj.CreatedDate.format('dd-MM-yyyy')*/ enrolmentDateTime.format('dd-MM-yyyy')));      
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
                
            
                
        return jsonBody;        
    }
    
     public PageReference redirectToenrollmentprocessPage(){
        String url = '/apex/enrolmentprocess_ipad?';
        integer counter = 1;
        Id param = null;
        for(String parameter : Apexpages.currentpage().getparameters().keyset()){
            if(parameter.contains('enr')){
                url += 'enr'+counter+'='+Apexpages.currentpage().getparameters().get(parameter)+'&';
                counter++;    
            }
        }
        url = url.removeEnd('&');
        System.debug('@@@url'+url);
        return new PageReference(url).setRedirect(true);
    }
    
    private Static Booking__c fillBook(String recTypeId, Enrolment__c enrl, String status, String type, Date bookDate, String grpClsBookId){
        Booking__c book   = new Booking__c();
        book.RecordTypeId = recTypeId;
        book.Enrolment__c = enrl.Id;
        book.Student__c   = enrl.Student__c;
        book.Teacher_Account__c = enrl.Teacher__c; 
        book.Package__c   = enrl.Package__c;
        book.Center__c    = enrl.Center__c;
        book.Type__c      = type;//ConstantsClass.bookTypeRegular;
        book.Status__c    = status;     
        book.Booking_Date__c = bookDate;
        book.Start_Time__c= enrl.Lesson_Start_time__c;
        book.End_Time__c  = enrl.Lesson_Start_time__c.addMinutes(Integer.valueOf(enrl.Package__r.Duration__c));
        
        book.Group_Class__c = grpClsBookId;
        return book;
    }
   
    private Static Fifth_Lesson__c fillFifthLesson(Enrolment__c enrl, Date bookDate){
        Fifth_Lesson__c fifthLesn   = new Fifth_Lesson__c();
        fifthLesn.Enrolment__c = enrl.Id;
        fifthLesn.Student__c   = enrl.Student__c;
        fifthLesn.Teacher_Account__c = enrl.Teacher__c; 
        fifthLesn.Package__c      = enrl.Package__c;
        fifthLesn.Center__c       = enrl.Center__c;
       // fifthLesn.Type__c       = ConstantsClass.bookTypeRegular;
        //fifthLesn.Status__c     = status;     
        fifthLesn.Parent__c       = enrl.Parent__C;
        fifthLesn.Booking_Date__c = bookDate;
        fifthLesn.Start_Time__c   = enrl.Lesson_Start_time__c;
        fifthLesn.End_Time__c     = enrl.Lesson_Start_time__c.addMinutes(Integer.valueOf(enrl.Package__r.Duration__c));
        
        return fifthLesn;
    }
     
    //Juneid 10 Aug method to ger Refrrel discount Country Wise
    private List<Referral_Discount__c>referreldiscounts(String countryName){
        
        List<Referral_Discount__c> refDesc = [SELECT Active__c, Default__c,Country__r.Country_Name__c, Country__c, End_Date__c, Start_Date__c, Discount_Amount_Referee__c, Discount_Amount_Referrer__c, Currency_Code__c, Id, Name FROM Referral_Discount__c WHERE Country__r.Country_Name__c =:countryName AND Active__c ='Yes' order by lastmodifieddate desc];
        return refDesc;
    }
    //@Juneid  05 Aug 2020, This methos is used to check that centaer is osia or not
    private Boolean checkOsiaForRefrel(string centerName){
        if(String.isNotBlank(System.Label.Ossia_Organisation_Name)){
            String osiaName = System.Label.Ossia_Organisation_Name;
            if(String.isNotBlank(centerName)){
                if(osiaName == centerName){
                    //@Juneid 05 Aug 2020, getting Custtom setting value for osia
                    Ossia_Referral_Discount__c osiaRefSetting = Ossia_Referral_Discount__c.getOrgDefaults();
                    if(osiaRefSetting.Ossia_Referral_Discount__c ==  true)
                        return true;
                    else 
                        return false;
                }
                 return true;
            }
        }
        return false;
    }
    //@Juneid 07 Aug 2020 , Send Mail to refrel
    private void sendMailToReffrel(Enrolment__c enrol){
        if(enrol.Id !=Null){
            if(enrol.Referred_by__c !=Null && String.isNotBlank(enrol.Referral_code_used__c)){
                sendMobileNotification(enrol);
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                List<EmailTemplate> emailTemplates =  new List<EmailTemplate>();
                //@Juneid 26 Aaug 2020, Orgnization wise templates
                if(isOssia){
                    emailTemplates = [Select Id,name,developerName from EmailTemplate where developerName =:'Ossia_Send_Referral_Enrollment_Details']; 
                }else{
                    emailTemplates =  [Select Id,name,developerName from EmailTemplate where developerName =:'Send_Referral_Enrollment_Details']; 
                }
                
                if(emailTemplates.size() > 0){
                    Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>();                    
                    for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress])
                        mapOfOrgWide.put(objAddress.DisplayName,objAddress);
                    //@Juneid 06 Aug Aug 2020, This email is sent to reffrel 
                    Messaging.SingleEmailMessage refrenceMail = Messaging.renderStoredEmailTemplate(emailTemplates[0].Id, enrol.Referred_by__r.personContactId, enrol.Id);
                    if( String.isNotBlank(enrol.Center__r.Location__c) && mapOfOrgWide.containsKey(enrol.Center__r.Location__c) ){
                        refrenceMail.setOrgWideEmailAddressId(mapOfOrgWide.get(enrol.Center__r.Location__c).Id);
                    }
                    refrenceMail.setTargetObjectId(enrol.Referred_by__r.personContactId);
                    refrenceMail.saveAsActivity = true;
                    refrenceMail.setWhatId(enrol.Id);
                    refrenceMail.setTemplateId(emailTemplates[0].Id);
                    emailList.add(refrenceMail); 
                }
                if(emailList.size() > 0){
                    Messaging.sendEmail(emailList,false);
                }
            }
        }
    }
    //@Juneid 10 Aug 2020, This method is used to send a notification on Mobile app 
    Private void sendMobileNotification(Enrolment__c enrolObj ){
        String tittle = enrolObj.Referred_by__r.name+' has enrolled using your referral link!';
        String bodyMsg = enrolObj.Referrer_discount_amount__c+' has been credited to your Aureus account';
        FirebaseNotificationHelper.sendNotification(enrolObj.Referred_by__c, enrolObj.Referred_by__r.Id, tittle, bodyMsg);
    }
    
    public Class EnrolDetails{       
        Public Map<String, Enrolment__c> enrolments{get;set;}
        Public Map<String, String> enrolmentTimeSlotMap{get;set;}
        Public Map<String, FeeModel> feeModelObj{get;set;}
        Public Map<String, AccountDetails> students{get;set;}
        Public AccountDetails parent{get;set;}
        Public BillingDetails billingDetails{get;set;}
        
        public EnrolDetails(){
            enrolments = new Map<String, Enrolment__c>();
            enrolmentTimeSlotMap = new  Map<String, String>();
            students = new Map<String, AccountDetails>();
            parent = new AccountDetails();
            billingDetails = new BillingDetails();
            feeModelObj = new Map<String, FeeModel>();
        }
        
        public EnrolDetails(Map<String, Enrolment__c> enrolments, Map<String, AccountDetails> students, AccountDetails parent, Map<String, FeeModel> feeModelObj){
            this.enrolments = enrolments;
            this.students = students;
            this.parent = parent;
            this.feeModelObj = feeModelObj;
        }
    }
       
    public Class AccountDetails{
        
        Public String id{get;set;}
        Public String firstName{get;set;}
        Public String lastName{get;set;}
        Public Date dob{get;set;}
        Public Enrolment__c enrolDate{get;set;}
        Public String gender{get;set;}
        Public String nationality{get;set;}
        Public String school{get;set;}
        Public String email{get;set;}
        Public String phone{get;set;}
        Public String address{get;set;}
        Public String city{get;set;}
        Public String postalCode{get;set;}
        Public String country{get;set;}
        Public String isInstrumentAtHome{get;set;}
        Public String stripeId;
        
    }
    
    public class FeeModel{
         //Fee calculation variables
        public Decimal depFees{get;set;}
        public Decimal prgFees{get;set;}
        public Decimal pkgFeesPromtnalDis{get;set;}
        public Decimal regiFees{get;set;}
        public Decimal regiFeesDis{get;set;}    
        Public List<promotinalPackagesDetails> listOfpromotinalPackages{get;set;}  
        public Boolean isPromitionalPackage{get;set;}
 //@Juneid 05 Aug 2020,Use For Refrel Discount
        public Decimal refrelDiscount{get;set;}
        public Decimal refreeDiscount{get;set;}
      //  public Decimal facilityFee{get;set;}//@Juneid 18 Aug 2020, Facility fee
        //public Decimal facilityGst{get;set;}//@Juneid 18 Aug, 2020, For facility GSt 
        
        Decimal  selPckMonthFees;
        Decimal  totAmt;
        String   pkgAftPro;
        Integer  proNoOfLess;
        Integer  prmtnalPkgInMonth;
         //Added by Rajesh on 21st oct 2019. calcuate individual gst amount for the line items
        Decimal  gstAmount;
        
        //Added by Rajesh 13th Nov 2019, to solve 1cent issue in invoice
        Decimal actPkgFee;
        Decimal actDiscount;
        //@Juneid 11 Aug 2020 , STore Refrel DIscount Name 
        string refrelDiscountName;
        public FeeModel(){
            selPckMonthFees = depFees = prgFees = regiFees = pkgFeesPromtnalDis = regiFeesDis = prmtnalPkgInMonth = proNoOfLess = 0;
            gstAmount = 0;
            //Added by Rajesh 13th Nov 2019, to solve 1cent issue in invoice
            actPkgFee = actDiscount= 0;
            //Juneid 05 Aug 2020
            refrelDiscount=0;
           // facilityGst = 0;
            refrelDiscountName ='';
            refreeDiscount =0;
            listOfpromotinalPackages = new List<promotinalPackagesDetails>();
            isPromitionalPackage = false;
        }
    }

    // added by nishi:5-Nov-2020: for show promotinal pacakges details seperatly
    public class promotinalPackagesDetails{
        Public Date invoiceDate{get;set;}
        public Decimal amount{get;set;}
        public String packageName{get;set;}
        public Boolean isDiscount{get;set;}
        public promotinalPackagesDetails(Date invDate,Decimal amount,String packageName,Boolean isDiscount){
            this.invoiceDate = invDate;
            this.amount = amount;
            this.packageName = packageName;
            this.isDiscount = isDiscount;
        }
        public promotinalPackagesDetails(){
            this.invoiceDate = null;
            this.amount = 0;
            this.packageName = '';
            this.isDiscount = false;
        }
    }

    
    public Class BillingDetails{
        public Decimal disTot{get;set;}
        public Decimal feesTot{get;set;}
        public Decimal gstTot{get;set;}
        public Decimal totalAmt{get;set;}
        public Decimal subsTot{get;set;}
        public Decimal depositTot{get;set;}
        public Decimal grandTot{get;set;}
        
        public BillingDetails(){
            disTot = feesTot = gstTot = totalAmt=subsTot =depositTot = grandTot = 0;
        }
    }
}