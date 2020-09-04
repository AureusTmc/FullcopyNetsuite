public without sharing class EnrolmentProcessController{
    public AccountWrapper parentAccWrap{get;set;}
    public StudentWrapper studentWrap{get;set;}
    public LessonWrapper  lessonWrap{get;set;}
    public List<StudentWrapper> studentWrapList{get;set;}
    public Boolean       isAddMoreButtonCheck{get;set;}
    public String        buttonType{get;set;}
    public Boolean       isParAlsoAStudent{get;set;}
    
    public Integer selectedStudentIndex{get;set;}
    public Integer selectedLessonIndex{get;set;}
    
    public String tSlotStr{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    public string base64SignImg{get;set;}
    public GrandTotalWrapper grndTotModel{get;set;}
    
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    public string stripeToken{get;set;}
    
    //Free trial Opportunity
    public Boolean isFreeTrialOpp{get;set;}
    public Boolean isMoreFreeTrial{get;set;}
    public Boolean isLastFreeTrial{get;set;}
    public Integer manageFreeTrialList{get;set;}
    public String  apiKey {get;set;}
    public string  PersonMobilePhoneCustom{get;set;} 
    public Boolean isAlreadyStripCstmr{get;set;}
    public String  cardNumber{get;set;}
    public String  cardType{get;set;}
    public String  cardImage{get;set;}
    Enrolment__c currFreeTrailEnr;
    List<Enrolment__c> enrList;
    
    String stripeCstmrId;
    //Added by Rajesh, 6th Aug 2019. To store enrolment source on Enrolment/Case object and country for filtercentre
    String enrolmentSource;
    public String countryCode{get;set;}
    
    //Added by Rajesh, 30th June 2019, for check that parent is American club member of not
    public Boolean isAmcClubMember{get;set;}
    
     //Added by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
    String stripeBaseUrl;
    String stripeApiSecKey;
    String countryCurrencyCode;
    Integer gstTaxPer;
    public EnrolmentProcessController(){
        PersonMobilePhoneCustom = '';
        parentAccWrap = new AccountWrapper();
        parentAccWrap.BillingCountryCode = 'SG';
        
        studentWrap = new StudentWrapper();
        lessonWrap  = new LessonWrapper();
        studentWrapList = new List<StudentWrapper>();
        isAddMoreButtonCheck = false;
        
        tSlotMap     = new TimeSlotModelCntrl();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        
        grndTotModel = new GrandTotalWrapper();
        isError      = false;
        errorMsg     = '';
        isMoreFreeTrial      = false;
        manageFreeTrialList  = 0;
        
        
        isFreeTrialOpp   = false;
        currFreeTrailEnr = new Enrolment__c();
        enrList          = new List<Enrolment__c>();
        isAlreadyStripCstmr= false;
        
         //Added by Rajesh, 30th June 2019, set defaut value as false
        isAmcClubMember  = false;
        Set<String> enrIds = new Set<String>();
        Map<String, String> params  =  ApexPages.currentPage().getParameters(); 
        if(params != null && params.size() > 0){
            for(String strKey : params.keySet()){
                //Added by Rajesh, 6th Aug 2019. To store enrolment source on Enrolment/Case object and country for filtercentre
                if(strKey == 'es')
                    enrolmentSource = params.get(strKey);
                else if(strKey == 'country')
                	countryCode	 = params.get(strKey);
                else    
                	enrIds.add(params.get(strKey));
            }
        }
        //Added by Rajesh, 7th Aug 2019. country for filtercentre
        if(String.isBlank(countryCode))
            countryCode = 'SG';
        
        if(enrIds.size() > 0){          
            enrList = [SELECT Id, Center__c, Teacher__c, Package__c, Package__r.Type__c,Package__r.Duration__c, Package__r.Program__r.Instrument__c, Parent__r.Also_a_Student__c,
                                                 Student__c, Parent__c, Trial_Date__c, Trial_Start_Time__c, Center__r.Travel_Time__c, Center__r.Name, Center__r.Country__r.Name
                                          FROM Enrolment__c
                                          WHERE Id IN: enrIds AND Student__c != null AND Parent__c != null AND Trial_Date__c != null AND Trial_Start_Time__c != null 
                                                AND Center__c != null AND Teacher__c != null AND Package__c != null ORDER BY Student__c];
            if(enrList.size() > 0){
                isFreeTrialOpp    = true;
                isParAlsoAStudent = enrList.get(0).Parent__c == enrList.get(0).Student__c;//enrList.get(0).Parent__r.Also_a_Student__c;
                
                //Added by Rajesh 17th Nov 2019, To solve hk centre related issue
				countryCode = String.isNotBlank(enrList.get(0).Center__r.Country__r.Name) ? enrList.get(0).Center__r.Country__r.Name : 'SG';				
                
                List<Account> accList = [SELECT Id, FirstName, LastName, PersonMobilePhone, PersonOtherPhone, 
                                                PersonEmail, BillingCountryCode, Gender__c, Nationality__c, Phone, Occupation__c, 
                                                BillingStreet, BillingCity, BillingPostalCode, BillingCountry, Is_Club_Member__c, Membership_Type__c
                                         FROM Account WHERE Id =: enrList.get(0).Parent__c];
                if(accList.size() > 0){
                    Account parentAcc = accList.get(0);
                    parentAccWrap = new AccountWrapper(parentAcc.FirstName, parentAcc.Lastname, parentAcc.Gender__c, 
                                                       parentAcc.PersonMobilePhone, parentAcc.Nationality__c, parentAcc.phone, 
                                                       parentAcc.Occupation__c, parentAcc.PersonEmail, parentAcc.BillingStreet, 
                                                       parentAcc.BillingCity, parentAcc.BillingPostalCode, parentAcc.BillingCountryCode,'');                                   
                    parentAccWrap.accId = parentAcc.Id;
                    PersonMobilePhoneCustom = parentAcc.PersonMobilePhone;
                    
                    //Added by Rajesh, 11th July 2019, for check that parent is American club member of not
                    if(parentAcc.Is_Club_Member__c && parentAcc.Membership_Type__c == ConstantsClass.amcClubMember)
                        isAmcClubMember = true;
                }
                
                manageFreeTrialList = enrList.size() - 1;
                currFreeTrailEnr    = enrList.get(0);
                fromFreeTrial();
            }else{
                //No trial enrolment found
            }
        }else{
            fillCenterAndPlan();
        }
        
        //Commented by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
        //Get Api key for the Stripe
        /*List<Stripe_Settings__mdt> stripeSettings = [SELECT Id,Stripe_Base_Url__c,Stripe_Secret_Key__c,Stripe_Publishable_Key__c 
                                                     FROM Stripe_Settings__mdt 
                                                     WHERE DeveloperName =: ConstantsClass.cstmMetaDataStripe LIMIT 1];
        if(stripeSettings.size()>0)
           apiKey = stripeSettings[0].Stripe_Publishable_Key__c;*/
        Map<String,Country__c> countryMap = new Map<String,Country__c>();
        for(Country__c cntry : BillingUtility.getCountryMap(null).values())
            countryMap.put(cntry.Name.toUpperCase(), cntry);
        
        String tempCntryCodeUpper = countryCode.toUpperCase();
        if(countryMap.get(tempCntryCodeUpper) != null){
            Country__c cntry    = countryMap.get(tempCntryCodeUpper);
            stripeBaseUrl		= cntry.Stripe_Base_Url__c;
            apiKey 				= cntry.Stripe_Publishable_Key__c;
            stripeApiSecKey		= cntry.Stripe_Secret_Key__c;
            countryCurrencyCode = cntry.Currency_Code__c;
            gstTaxPer			=  Integer.valueOf(cntry.Tax_Rate__c);
        }
        
        try{
            if(gstTaxPer == null){
                gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
            }
        }catch(Exception e){}
    }
    
    //Added by Rajesh, 14th July 2019, for check that parent is American club member of not
    public void nextSecondPage(){
        List<Account> accList = [SELECT Id, Name, Stripe_Customer_Id__c, Card_Number__c, Card_Type__c, Card_Image__c, Is_Club_Member__c, Membership_Type__c 
                                 FROM Account WHERE (Id =: parentAccWrap.accId OR PersonEmail =: parentAccWrap.Email) 
                                     AND (Is_Club_Member__c = true AND Membership_Type__c =: ConstantsClass.amcClubMember )];       
        isAmcClubMember  = false; 
        if(accList.size() > 0 && accList.get(0).Is_Club_Member__c && accList.get(0).Membership_Type__c == ConstantsClass.amcClubMember)
            isAmcClubMember = true;
    }
    
    public List<SelectOption> getAccoungGenderPicklist(){     
        return getPicklistValues('Account','Gender__c');
    }
    
    public List<SelectOption> getAccoungNationalityPicklist(){     
        return getPicklistValues('Account','Nationality__c');
    }
    
    public List<SelectOption> getAccoungBillCntryPicklist(){     
        return getPicklistValues('Account','BillingCountryCode');
    }
    
    private static List<SelectOption> getPicklistValues(String ObjectApi_name,String Field_name){ 
        List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map    = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values   = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        
        for(Schema.PicklistEntry a : pick_list_values){ //for all values in the picklist list
            lstPickvals.add(new SelectOption(a.getValue(), a.getLabel()));
        }
        
        return lstPickvals;
    }
    
    public List<SelectOption> getSchoolPicklist(){     
        List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        
        School__c otherSch;
        for(School__c sch : [SELECT Id, Name FROM School__c ORDER BY Name  LIMIT 999]){
            if(sch.Name != 'Other')
              lstPickvals.add(new SelectOption(sch.Id, sch.Name));
            else
                otherSch = sch;
        }
        if(otherSch != null)
            lstPickvals.add(new SelectOption(otherSch.Id, otherSch.Name));
        
        return lstPickvals;
    }
    
    private void fromFreeTrial(){
         if(currFreeTrailEnr.Id != null){
            fillCenterAndPlan();    
             
            //Fetching Student Account
            List<Account> accList = [SELECT Id, FirstName, LastName, PersonMobilePhone, PersonOtherPhone, PersonEmail, 
                                            BillingCountryCode, Gender__c, Nationality__c, Phone, Occupation__c, BillingStreet,
                                            BillingCity, BillingPostalCode, BillingCountry, PersonBirthdate, Learning_Style__c,
                                            Description, School__c
                                     FROM Account WHERE Id =: currFreeTrailEnr.Student__c];
            
            if(accList.size() > 0){
                Account stuAcc = accList.get(0);
                studentWrap.stuAccWrap  = new AccountWrapper(stuAcc.FirstName, stuAcc.Lastname, stuAcc.Gender__c, stuAcc.PersonMobilePhone, 
                                                             stuAcc.Nationality__c, stuAcc.phone, stuAcc.Occupation__c, stuAcc.PersonEmail, 
                                                             stuAcc.BillingStreet, stuAcc.BillingCity, stuAcc.BillingPostalCode, 
                                                             stuAcc.BillingCountryCode, stuAcc.School__c);
                studentWrap.stuAccWrap.accId = stuAcc.Id;
                studentWrap.enrBirthdateField.Trial_Date__c = stuAcc.PersonBirthdate;
            }
            lessonWrap.enrId          = currFreeTrailEnr.Id;        
            lessonWrap.selectedCenter = currFreeTrailEnr.Center__c;
             
            fetchTeachers();
            for(SelectOption selOpt : lessonWrap.teacherOptions){
                String optTchrValue = selOpt.getValue();
                
                if(optTchrValue == String.valueOf(currFreeTrailEnr.Teacher__c)){
                    lessonWrap.selectedTeacher =  currFreeTrailEnr.Teacher__c; 
                    break;
                }  
            }
            
            if(String.isNotBlank(lessonWrap.selectedTeacher)){
                fetchPlans();   
                
                String trailSlcdIns = currFreeTrailEnr.Package__r.Program__r.Instrument__c;
                String slcdDuration = currFreeTrailEnr.Package__r.Duration__c;
                String slcdPkgType  = currFreeTrailEnr.Package__r.Type__c;
                
                String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
                //Query Updated by Rajesh:28th June 2019, Enrolmentprocess should be consider (Normal and Promotional)
                List<Package__c> pkgList = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name, Location__r.Travel_Time__c 
                                            FROM Package__c 
                                            WHERE Location__c =: currFreeTrailEnr.Center__c AND Program__r.Status__c =: ConstantsClass.activeStatus  AND Program__r.Instrument__c =: trailSlcdIns
                                            AND Duration__c =: slcdDuration AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND
                                            Active__c = True AND (Type__c = 'Individual' OR Type__c = 'Home') AND (Type_of_package__c = 'Normal' OR Type_of_package__c = 'Promo')
                                            AND RecordtypeId =: pkgLessRecId AND Is_Promotion_Discount__c = False LIMIT 1]; 
                if(pkgList.size() > 0){
                    lessonWrap.selectedPlan = pkgList.get(0).Id;
                    
                    Date tempTrailDT = currFreeTrailEnr.Trial_Date__c.addDays(7);
                    lessonWrap.lessonSlcdDate = tempTrailDT.day()+'/'+tempTrailDT.month()+'/'+tempTrailDT.year() ;
                    
                    String minTmp = currFreeTrailEnr.Trial_Start_Time__c.minute() != 0 ?  (currFreeTrailEnr.Trial_Start_Time__c.minute() +'') : '00';
                    String tempTSlot = currFreeTrailEnr.Trial_Start_Time__c.hour() + ':' + minTmp;
                    lessonWrap.lessonSlctSlot = tempTSlot;
                    lessonWrap.lessonSlctSlotT = DateTime.newInstance(currFreeTrailEnr.Trial_Date__c, currFreeTrailEnr.Trial_Start_Time__c).format('hh:mm a');
                    lessonWrap.lessonSlcdDateD = tempTrailDT;
                    
                    fetchTimeSlot(); 
                }
                
                
                /*
                for(SelectOption selOpt : lessonWrap.planOptions){
                    String optPlanLbl = selOpt.getLabel();
                    
                    if(optPlanLbl.contains(trailSlcdIns) && !(optPlanLbl.contains('Advance Promotion'))){
                        lessonWrap.selectedPlan  = selOpt.getValue(); 
                        break;
                    }  
                }*/
                
                               
            } 
            /*fetchPlans();
             
            String trailSlcdIns = currFreeTrailEnr.Package__r.Program__r.Instrument__c;
            system.debug('lessonWrap.planOptions'+lessonWrap.planOptions);
            for(SelectOption selOpt : lessonWrap.planOptions){
                String optPlanLbl = selOpt.getLabel();
                
                if(optPlanLbl.contains(trailSlcdIns)){
                    lessonWrap.selectedPlan  = selOpt.getValue(); 
                    break;
                }  
            }
            if(String.isNotBlank(lessonWrap.selectedPlan)){
                fetchTeachers();
                if(currFreeTrailEnr.Trial_Date__c != null && currFreeTrailEnr.Trial_Start_Time__c != null){
                   for(SelectOption selOpt : lessonWrap.teacherOptions){
                        String optTchrValue = selOpt.getValue();
                       
                        if(optTchrValue == String.valueOf(currFreeTrailEnr.Teacher__c)){
                            lessonWrap.selectedTeacher =  currFreeTrailEnr.Teacher__c; 
                            break;
                        }  
                    }
                     
                    if(String.isNotBlank(lessonWrap.selectedTeacher)){
                        Date tempTrailDT = currFreeTrailEnr.Trial_Date__c.addDays(7);
                        lessonWrap.lessonSlcdDate = tempTrailDT.day()+'/'+tempTrailDT.month()+'/'+tempTrailDT.year() ;
                        
                        String minTmp = currFreeTrailEnr.Trial_Start_Time__c.minute() != 0 ?  (currFreeTrailEnr.Trial_Start_Time__c.minute() +'') : '00';
                        String tempTSlot = currFreeTrailEnr.Trial_Start_Time__c.hour() + ':' + minTmp;
                        lessonWrap.lessonSlctSlot = tempTSlot;
                        lessonWrap.lessonSlctSlotT = DateTime.newInstance(currFreeTrailEnr.Trial_Date__c, currFreeTrailEnr.Trial_Start_Time__c).format('hh:mm a');
                        lessonWrap.lessonSlcdDateD = tempTrailDT;
                        
                        fetchTimeSlot();
                    }
                }
            }*/
            
            enrList.remove(0);
            isMoreFreeTrial = enrList.size() > 0 ? true : false;
            isLastFreeTrial = enrList.size() == 0 ? true : false; 
             
            currFreeTrailEnr = new Enrolment__c(); 
        }
    } 
    
    public void checkTrialAvl(){
      
        if(isFreeTrialOpp == true)
            manageFreeTrialList = manageFreeTrialList - 1;
    }
    
    //  Method to add centers and plans.
    private void fillCenterAndPlan(){
        //  Fetching center recordtype to query the center accounts.
        String centerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        //  Creating selectoption for center.
        lessonWrap = new LessonWrapper();
        //updated by Rajesh, 7th Aug 2019. updated soql To filter centre on the bases of the country
        //Updated by Rajesh, 13th Aug 2019. Updated soql to remove hardcoded centre and filter centres on the bases of centre status
        for(Account acc : [SELECT Id, Name,CentreName_Cust__c FROM Account WHERE RecordType.Id =: centerRecId AND Centre_Status__c =:ConstantsClass.activeStatus AND CentreName_Cust__c != null AND Country__r.Name =:countryCode ORDER BY CentreName_Cust__c])
            lessonWrap.centerOptions.add(new SelectOption(acc.Id, acc.CentreName_Cust__c));
    }
    
    //  Method to get plans based on the centers.
    public void fetchPlans(){
        String selCenter          = lessonWrap.selectedCenter;
        lessonWrap.planOptions    = new List<SelectOption>();
        lessonWrap.planOptions.add(new SelectOption('', '--None--'));
        lessonWrap.selectedPlan = '';
        lessonWrap.selectedPlanName = '';
        tSlotMap = new TimeSlotModelCntrl();
        
        if(String.isNotBlank(selCenter) && String.isNotBlank(lessonWrap.selectedTeacher)){
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c FROM Account WHERE Id =:lessonWrap.selectedTeacher];
            
            Set<String> instrumentTempSet = new Set<String>();
            for(Account acc: tchrList){
                if(acc.Major_Instruments_Disciplines__c != null){
                    for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))
                        instrumentTempSet.add(strIns); 
                }
                
                if(acc.Minor_Instruments_Disciplines__c != null){
                    for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))
                        instrumentTempSet.add(strIns); 
                }
            }
            
            //Query Updated by Rajesh:28th June 2019, Enrolmentprocess should be consider (Normal and Promotional)             
            String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
            for(Package__c pkg : [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name, Location__r.Travel_Time__c, Type__c  
                                  FROM Package__c 
                                  WHERE Location__c =: selCenter AND Program__r.Status__c =: ConstantsClass.activeStatus  AND Program__r.Instrument__c IN:instrumentTempSet
                                        AND Duration__c !=: ConstantsClass.trialStatus AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND
                                        Active__c = True AND (Type__c = 'Individual' OR Type__c = 'American Club') AND RecordtypeId =: pkgLessRecId 
                                        AND (Type_of_package__c = 'Normal' OR Type_of_package__c = 'Promo')
                                        ORDER BY Program__r.Name,Duration__c]){
                Boolean isAddPkg = false;
                if(isAmcClubMember){
                    if(pkg.Type__c == 'American Club')                       
                        isAddPkg = true;
                }else if(pkg.Type__c == 'Individual'){
                    isAddPkg = true;
                }
                
                if(isAddPkg){
                    lessonWrap.planOptions.add(new SelectOption(pkg.Id, pkg.Name)); 
                    lessonWrap.selectedCenterName = pkg.Location__r.Name;
                    
                    lessonWrap.cntrTravHour = pkg.Location__r.Travel_Time__c != null ? Integer.valueOf(pkg.Location__r.Travel_Time__c) : 0 ;
                }
            }
        }
        
       /* String selCenter          = lessonWrap.selectedCenter;
        lessonWrap.planOptions    = new List<SelectOption>();
        lessonWrap.teacherOptions = new List<SelectOption>();
        
        lessonWrap.planOptions.add(new SelectOption('', '--None--'));
        lessonWrap.teacherOptions.add(new SelectOption('', '--None--'));
        tSlotMap = new TimeSlotModelCntrl();
        
        if(String.isNotBlank(selCenter)){
            String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
            for(Package__c pkg : [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name, Location__r.Travel_Time__c 
                                  FROM Package__c 
                                  WHERE Location__c =: selCenter AND Program__r.Status__c =: ConstantsClass.activeStatus  AND Program__r.Instrument__c != NULL 
                                        AND Duration__c !=: ConstantsClass.trialStatus AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND
                                        Active__c = True AND (Type__c = 'Individual' OR Type__c = 'Home') AND RecordtypeId =: pkgLessRecId]){
                lessonWrap.planOptions.add(new SelectOption(pkg.Id, pkg.Name)); 
                lessonWrap.selectedCenterName = pkg.Location__r.Name;
                
                lessonWrap.cntrTravHour = pkg.Location__r.Travel_Time__c != null ? Integer.valueOf(pkg.Location__r.Travel_Time__c) : 0 ;
            }
        }*/
    }
    
    //  Method to get teachers based on the centers.
    public void fetchTeachers(){
        String selCenter = lessonWrap.selectedCenter;        
        lessonWrap.planOptions    = new List<SelectOption>();
        lessonWrap.teacherOptions = new List<SelectOption>();
        lessonWrap.teacherOptions.add(new SelectOption('', '--None--'));    
        lessonWrap.planOptions.add(new SelectOption('', '--None--'));          
        tSlotMap = new TimeSlotModelCntrl();
        lessonWrap.selectedTeacher = '';
        lessonWrap.selectedTeacherName = '';
        lessonWrap.selectedPlan = '';
        lessonWrap.selectedPlanName = '';
        tSlotMap = new TimeSlotModelCntrl();
        
        String teacherRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();
            
        List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Center_Name__c =: selCenter AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                         (Teacher_Name__r.Major_Instruments_Disciplines__c != null OR Teacher_Name__r.Minor_Instruments_Disciplines__c != null) ORDER BY Teacher_Name__r.Name]; 
        
        Map<String,String> tchrMap = new Map<String,String>();
        for(Teacher_Working_Hour__c teachWorkHour : techWorkSchList)
            tchrMap.put(teachWorkHour.Teacher_Name__c, teachWorkHour.Teacher_Name__r.Name);
        
        for(String tchrId: tchrMap.keySet())
            lessonWrap.teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
        /*
        String selCenter = lessonWrap.selectedCenter; 
        String selPlan   = lessonWrap.selectedPlan;           
        
        lessonWrap.teacherOptions = new List<SelectOption>();
        lessonWrap.teacherOptions.add(new SelectOption('', '--None--'));            
        tSlotMap = new TimeSlotModelCntrl();
        lessonWrap.selectedTeacher = '';
        lessonWrap.selectedTeacherName = '';
        
        List<Package__c> pkgLst = [SELECT Id, Name, Program__r.Instrument__c, Program__c, Program__r.Name,Duration__c, Location__r.Name 
                                   FROM Package__c WHERE Id =: selPlan];
        
        if(pkgLst.size() > 0){
            lessonWrap.selectedPlanName = pkgLst.get(0).Name;
            
            try {
                lessonWrap.pkgDuration = Integer.valueOf(pkgLst.get(0).Duration__c);
            }Catch (exception e) {}
            
            String pkgPrgInstrument = pkgLst.get(0).Program__r.Instrument__c;
            
            String teacherRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();
            
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Center_Name__c =: selCenter AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                                   Teacher_Name__r.Major_Instruments_Disciplines__c includes(:pkgPrgInstrument)]; 
           
           Map<String,String> tchrMap = new Map<String,String>();
           for(Teacher_Working_Hour__c teachWorkHour : techWorkSchList)
                tchrMap.put(teachWorkHour.Teacher_Name__c, teachWorkHour.Teacher_Name__r.Name);
           
           for(String tchrId: tchrMap.keySet())
                lessonWrap.teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
        } */
    }
    
    public void fetchTimeSlot(){
        List<Package__c> pkgLst = [SELECT Id, Name, Program__r.Instrument__c, Program__c, Program__r.Name,Duration__c, Location__r.Name 
                                   FROM Package__c WHERE Id =: lessonWrap.selectedPlan];
        if(pkgLst.size() > 0){
            lessonWrap.selectedPlanName = pkgLst.get(0).Name;
            //Added by Rajesh: 3rd aug 2018, To populate instrumet in person account assign by prashant
            lessonWrap.instrument		= pkgLst.get(0).Program__r.Instrument__c;
            try {
                lessonWrap.pkgDuration = Integer.valueOf(pkgLst.get(0).Duration__c);
            }Catch (exception e) {}
        }
        
        String slcdCenter = lessonWrap.selectedCenter;
        String slcdTeacher = lessonWrap.selectedTeacher;
        
        Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();
        List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,
                                                         Start_Time__c,End_Time__c,Active__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Center_Name__c =: slcdCenter AND Active__c = true AND Working_Day__c != null AND 
                                                         Break_Time__c = False AND Teacher_Name__c =: slcdTeacher];
        
        lessonWrap.selectedTeacherName = techWorkSchList.size() > 0 ? techWorkSchList.get(0).Teacher_Name__r.Name : '';
        
        for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){                                                               
            List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
            if(tchList == null)
                tchList = new List<Teacher_Working_Hour__c>();
            
            tchList.add(tchWrkSch);                                                  
            teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);                                                  
        }
        
        Map<String,LessonWrapper> addTimeSlotMap = new Map<String,LessonWrapper>();
        if(!(buttonType != null && buttonType.equalsIgnoreCase('EditRowBtn'))){
            for(StudentWrapper sWrap : studentWrapList){
                for(LessonWrapper lWrap : sWrap.lessonList){
                    if(String.isNotBlank(lWrap.lessonSlctSlot) && lWrap.pkgDuration > 0){
                        List<String> timeList = lWrap.lessonSlctSlot.split(':');
                
                        Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                        Time endTime = startTime.addMinutes(lWrap.pkgDuration);
                        
                        startTime = startTime.addMinutes(-((lWrap.pkgDuration-15)));
                        
                        while(startTime < endTime){
                            String stTimeTmp = startTime.hour() + ':' + (startTime.minute() != 0 ?  (startTime.minute() +'') : '00');
                            
                            //String addTimeSlotTempKey =  lWrap.selectedCenter + ':' + lWrap.selectedPlan + ':' + lWrap.selectedTeacher + ':' +lWrap.lessonSlcdDate + ':' +stTimeTmp;
                            String addTimeSlotTempKey =  lWrap.selectedTeacher + ':' +lWrap.lessonSlcdDate + ':' +stTimeTmp;
                            addTimeSlotMap.put(addTimeSlotTempKey, lWrap);
                            
                            startTime = startTime.addMinutes(15);
                        }
                    }
                }
            }
        }
        
       // String addTimeSlotKey =  slcdCenter + ':' + lessonWrap.selectedPlan + ':' + slcdTeacher; 
        String addTimeSlotKey =  slcdTeacher; 
        
        Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
        Map<String,List<Date>> bookDayMap = new Map<String,List<Date>>();
        Date startDt   = System.today();
        //Updated by-: Rajesh| Date-: 21st Aug 2019, to compare enrolments only for 4 weeks from the selected date
        Date endDtTemp = startDt.addMonths(2);
        
        //Set<String> bookTypeSet    = new Set<String>{'Regular'};
        //Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled'};
        //update by-: Nishant |  Date-: 17-06-2019
        //Updated by-: Rajesh| Date-: 21st Aug 2019, To override busy booking with leave request, So here we have removed 'Busy' type from the set also updated soql
        //Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc','Busy'};
        Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed', 'Blocked'};
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();   
        
        for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c, Status__c
                               FROM Booking__c 
                               WHERE Teacher_Account__c =: slcdTeacher AND RecordTypeId =: bookLessRecId  AND Status__c IN: bookStatusSet
                               AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDtTemp) AND 
                               ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Leave'))]){                        
                
          if(book.End_Time__c > book.Start_Time__c){                    
                String key =  book.Booking_Date__c +':'+ book.Start_Time__c;
                bookMap.put(key, book);   
                /*                       
                String currDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                key = currDay +':'+ book.Start_Time__c;
                bookDayMap.put(key, book);*/
                //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                String currDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                  
              	Time temStartTime = book.Start_Time__c.addMinutes(-(lessonWrap.pkgDuration-15)); 
              	Time endTempT     = book.End_Time__c;
              	while(temStartTime < endTempT){
                    key = currDay +':'+ temStartTime;
                    
                    List<Date> bookDtList = new List<Date>();
                    if(bookDayMap.containsKey(key))
                        bookDtList = bookDayMap.get(key);
                    bookDtList.add(book.Booking_Date__c);
                    bookDayMap.put(key, bookDtList);  
                      
                    temStartTime = temStartTime.addMinutes(15);
                }  
            }
        }
        
        Date endDt = startDt.addMonths(1);
        for(Date st=startDt; st<=endDt; st=st.addDays(1)){
            TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
            
            Set<Time> morningTimesTemp      = new Set<Time>();
            Set<Time> afternoonTimesTemp    = new Set<Time>();
            
            String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
            
            if(teachWorkSchMap.containsKey(currDay)){
                List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                
                for(Teacher_Working_Hour__c teachWorkSch: tchWorSchLst){                                      
                    Time stTime = teachWorkSch.Start_Time__c;
                    
                    Integer endTimeDef = lessonWrap.pkgDuration  > 0 ? lessonWrap.pkgDuration : 30;
                    
                    //Adding trial time during Aureus at home center
                    if(currFreeTrailEnr.Id != null && currFreeTrailEnr.Center__c == Label.Aureus_at_Home_Id && currFreeTrailEnr.Center__r.Travel_Time__c != null){
                        endTimeDef = endTimeDef + Integer.valueOf(currFreeTrailEnr.Center__r.Travel_Time__c); 
                    }
                    
                    while(stTime <= teachWorkSch.End_Time__c.addMinutes(-endTimeDef)){
            if(st != date.Parse(lessonWrap.lessonSlcdDate) && (morningTimesTemp.size() > 0 && afternoonTimesTemp.size() > 0)){
                            break;
                        } 
            
                        String key = st + ':'+ stTime;
                        if(bookMap.containsKey(key)){
                            Booking__c bookTmp = bookMap.get(key);
                            stTime = bookTmp.End_Time__c;
                        }else{
                            string key2 = st + ':'+ stTime.addMinutes(ConstantsClass.defaultMinutesDiffinSlot);
                            
                            if(bookMap.containsKey(key2)){
                                Booking__c bookTmp = bookMap.get(key2);
                                stTime = bookTmp.End_Time__c;
                            }else{
                                if(stTime.hour() < 12){
                                    if(stTime.addMinutes(15) < teachWorkSch.End_Time__c){
                                        //Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                        //currTime = currTime.addHours(4);    
                                        DateTime tempTodayTime = System.now().addHours(4);
                                        DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                        
                                        //if(st > System.today() || (st == System.today() && stTime > currTime)){
                                        if(tempStDtTime > tempTodayTime){
                                            String dayKey  =  currDay + ':'+ stTime;
                                            
                                            //Checking that time slot is already added in student or not
                                            String cuDtStr = st.day() +'/'+ st.month()+'/'+ st.year();
                                            String minTmp = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                            String addTimeSlotKeyTemp = addTimeSlotKey + ':'+ cuDtStr +':'+ minTmp;
                                            
                                            //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                                            Boolean isTimeSlotNotAvl = false;
                                            if(bookDayMap.containsKey(dayKey)){
                                                for(Date dt: bookDayMap.get(dayKey)){
                                                    if(dt >= st && st.daysBetween(dt) <= 28){
                                                        isTimeSlotNotAvl = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            
                                            //if(!(bookDayMap.containsKey(dayKey) || addTimeSlotMap.containsKey(addTimeSlotKeyTemp)))   
                                            if(!(isTimeSlotNotAvl || addTimeSlotMap.containsKey(addTimeSlotKeyTemp)))                                                                                     
                                                morningTimesTemp.add(stTime);  
                                        }
                                    }
                                    stTime = stTime.addMinutes(ConstantsClass.defaultMinutesDiffinSlot);
                                }else{
                                   // Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                    //currTime = currTime.addHours(4);
                                    DateTime tempTodayTime = System.now().addHours(4);
                                    DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                    
                                    //if(st > System.today() || (st == System.today() && stTime > currTime)){
                                    if(tempStDtTime > tempTodayTime){
                                        String dayKey  =  currDay + ':'+ stTime;
                                        
                                        //Checking that time slot is already added in student or not
                                        String cuDtStr = st.day() +'/'+ st.month()+'/'+ st.year();
                                        String minTmp = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                        String addTimeSlotKeyTemp = addTimeSlotKey + ':'+ cuDtStr +':'+ minTmp;
                                        
                                        //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                                        Boolean isTimeSlotNotAvl = false;
                                        if(bookDayMap.containsKey(dayKey)){
                                            for(Date dt: bookDayMap.get(dayKey)){
                                                if(dt >= st && st.daysBetween(dt) <= 28){
                                                    isTimeSlotNotAvl = true;
                                                    break;
                                                }
                                            }
                                        }
                                        //if(!(bookDayMap.containsKey(dayKey) || addTimeSlotMap.containsKey(addTimeSlotKeyTemp)))
                                        if(!(isTimeSlotNotAvl || addTimeSlotMap.containsKey(addTimeSlotKeyTemp)))
                                            afternoonTimesTemp.add(stTime);
                                    }
                                    stTime = stTime.addMinutes(ConstantsClass.defaultMinutesDiffinSlot);
                                }
                            }                            
                        }
                    }
                }
            }
            
            List<String> mrgSlotList = new List<String>();
            List<Time> tmpLst = new List<Time>();
            tmpLst.addAll(morningTimesTemp);tmpLst.sort();
            for(Time t : tmpLst){
                String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                mrgSlotList.add(t.hour() + ':' + minTmp);
            }
            
            List<String> aftSlotList = new List<String>();
            tmpLst = new List<Time>();
            tmpLst.addAll(afternoonTimesTemp);tmpLst.sort();
            for(Time t : tmpLst){
                String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                aftSlotList.add(t.hour() + ':' + minTmp);
            }
            
            if(lessonWrap.lessonSlcdDate != null){
                if(st == date.Parse(lessonWrap.lessonSlcdDate)){
                    tSlotMapTemp.morningSlot = mrgSlotList;
                    tSlotMapTemp.afternoonSlot = aftSlotList;
                }
            }
            
            if(mrgSlotList.size() > 0)
                tSlotMapTemp.isAvlMrgSlot = true;
            if(aftSlotList.size() > 0)
                tSlotMapTemp.isAvlAfternoonSlot = true;
            
            tSlotDateMap.put(st.day()+'/'+st.month()+'/'+st.year() , tSlotMapTemp);
        }
        
        tSlotStr = JSON.serialize(tSlotDateMap);
        tSlotMap = tSlotDateMap.get(lessonWrap.lessonSlcdDate);
    }

    
    public void refreshSlots(){
        if(String.isNotBlank(lessonWrap.lessonSlcdDate)){
            lessonWrap.lessonSlcdDateD = date.Parse(lessonWrap.lessonSlcdDate);
            fetchTimeSlot();
        }
    }
    
    public void editLesson(){
        if(selectedStudentIndex != null && selectedLessonIndex != null){
            StudentWrapper studentWrapTemp = studentWrapList.get(selectedStudentIndex);
            studentWrap.stuAccWrap =   studentWrapTemp.stuAccWrap;
            studentWrap.enrBirthdateField.Trial_Date__c = studentWrapTemp.enrBirthdateField.Trial_Date__c;
            lessonWrap  = studentWrapTemp.lessonList.get(selectedLessonIndex);            
            fetchTimeSlot();
        }
    }
    
    public void deleteLesson(){
        if(selectedStudentIndex != null && selectedLessonIndex != null){
            if(selectedStudentIndex == selectedLessonIndex){
                studentWrapList.remove(selectedStudentIndex);
            }else{
                studentWrapList.get(selectedStudentIndex).lessonList.remove(selectedLessonIndex);
            }
        }
    }
    
    //  Method to add more students.
    public void addMoreStudentsAndLessons(){
        isAddMoreButtonCheck = true;
        studentWrap = new StudentWrapper();
        
       /*  //  Fetching center recordtype to query the center accounts.
        String centerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        //  Creating selectoption for center.
        lessonWrap = new LessonWrapper();
        for(Account acc : [SELECT Id, Name FROM Account WHERE RecordType.Id =: centerRecId])
            lessonWrap.centerOptions.add(new SelectOption(acc.Id, acc.Name)); 
        */
        fillCenterAndPlan();
        
        tSlotMap = new TimeSlotModelCntrl();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        tSlotStr = '';
    }
    
    //  Method to add more students.
    public void addMoreLessons(){
        if(String.isNotBlank(lessonWrap.lessonSlctSlot)){
            List<String> timeList = lessonWrap.lessonSlctSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            lessonWrap.lessonSlctSlotT = DateTime.newInstance(lessonWrap.lessonSlcdDateD, tempT).format('hh:mm a');
        }
            
        if(buttonType != null && buttonType.equalsIgnoreCase('EditRowBtn')  && selectedStudentIndex != null && selectedLessonIndex != null){
            //studentWrapList[selectedStudentIndex].student = studentWrap.student;
            studentWrapList[selectedStudentIndex].stuAccWrap = studentWrap.stuAccWrap;
            studentWrapList[selectedStudentIndex].lessonList[selectedLessonIndex] = lessonWrap;
        }else if(!(isAddMoreButtonCheck) && selectedStudentIndex != null){
            studentWrapList.get(selectedStudentIndex).lessonList.add(lessonWrap);
        }else{
            if(studentWrapList.size() == 0){
                studentWrapList.add(studentWrap);
                studentWrapList.get(0).lessonList.add(lessonWrap);
            }else{
                if(isAddMoreButtonCheck){
                    studentWrapList.add(studentWrap);
                    isAddMoreButtonCheck = false;
                }
                
                Integer lstSize = studentWrapList.size();
                studentWrapList.get(lstSize-1).lessonList.add(lessonWrap);  
            }
        }
         //  Fetching center recordtype to query the center accounts.
       /* String centerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        //  Creating selectoption for center.
        lessonWrap = new LessonWrapper();
        for(Account acc : [SELECT Id, Name FROM Account WHERE RecordType.Id =: centerRecId])
            lessonWrap.centerOptions.add(new SelectOption(acc.Id, acc.Name));   
        */
        fillCenterAndPlan();
        
        tSlotMap = new TimeSlotModelCntrl();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        tSlotStr = '';
        buttonType = '';
    }
    
    public void saveStuAndLessonOnGrid(){
        if(String.isNotBlank(lessonWrap.lessonSlctSlot)){
            List<String> timeList = lessonWrap.lessonSlctSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            lessonWrap.lessonSlctSlotT = DateTime.newInstance(lessonWrap.lessonSlcdDateD, tempT).format('hh:mm a');
        }
        
        if(buttonType != null && buttonType.equalsIgnoreCase('EditRowBtn')  && selectedStudentIndex != null && selectedLessonIndex != null){
            //studentWrapList.get(selectedStudentIndex).student    = studentWrap.student;
            studentWrapList.get(selectedStudentIndex).stuAccWrap = studentWrap.stuAccWrap;
            buttonType = '';
        }else if(!(isAddMoreButtonCheck) && selectedStudentIndex != null){
            studentWrapList.get(selectedStudentIndex).lessonList.add(lessonWrap);
        }else{
            if(studentWrapList.size() == 0){
                studentWrapList.add(studentWrap);
                studentWrapList.get(0).lessonList.add(lessonWrap);
            }else{
                if(isAddMoreButtonCheck){
                    studentWrapList.add(studentWrap);
                    isAddMoreButtonCheck = false;
                }else if(isMoreFreeTrial || isLastFreeTrial){
                    studentWrapList.add(studentWrap);
                }
                
                Integer lstSize = studentWrapList.size();
                studentWrapList.get(lstSize-1).lessonList.add(lessonWrap);  
            }
            
             //  Fetching center recordtype to query the center accounts.
            String centerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
            //  Creating selectoption for center.
            studentWrap = new StudentWrapper();
            lessonWrap = new LessonWrapper();
            for(Account acc : [SELECT Id, Name FROM Account WHERE RecordType.Id =: centerRecId])
                lessonWrap.centerOptions.add(new SelectOption(acc.Id, acc.Name));   
                    
            tSlotMap = new TimeSlotModelCntrl();
            tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
            tSlotStr = '';
            
            if(isMoreFreeTrial){
                currFreeTrailEnr = enrList.get(0);
                fromFreeTrial();
            }
        }
    }
    
    public void thirdScreenFeeCalculation(){
        Map<String,Package__c> packMap = new Map<String,Package__c>();
        grndTotModel = new GrandTotalWrapper();
        
        for(StudentWrapper sWrap : studentWrapList){
            for(LessonWrapper lWrap : sWrap.lessonList){
                if(String.isNotBlank(lWrap.selectedPlan))
                    packMap.put(lWrap.selectedPlan, null);
            }
        }
        
        packMap = new Map<String,Package__c>([SELECT Id, Name, Program__c, Deposit_Fee__c, Registration_Fee__c, Package_Fee__c, 
                                                     Unit_Fee__c, Duration__c, Program__r.Billing__c, Program__r.Scheduling__c, of_Units__c,
                                                     Promotion_period_In_months__c, Promotion_Discount__c, Package_after_Promotion__c, Package_after_Promotion__r.Unit_Fee__c,
                                                     Is_Promotion_Discount__c, Registration_Discount_Active__c, Registration_Discount_Value__c  
                                              FROM Package__c WHERE Id IN: packMap.keySet()]);
        
        for(StudentWrapper sWrap : studentWrapList){
            for(LessonWrapper lWrap : sWrap.lessonList){
                if(String.isNotBlank(lWrap.selectedPlan) && packMap.get(lWrap.selectedPlan) != null){
                    Package__c pack = packMap.get(lWrap.selectedPlan);
                    
                    lWrap.selPckMonthFees = pack.Package_Fee__c;
                    //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                    //lWrap.depFees  = pack.Deposit_Fee__c != null ? pack.Deposit_Fee__c.setScale(2) : 0 ;
                    lWrap.depFees  = pack.Deposit_Fee__c != null ? BillingUtility.roundOffAmount(pack.Deposit_Fee__c) : 0 ;
                    lWrap.regiFees = pack.Registration_Fee__c != null ? pack.Registration_Fee__c : 0 ;
                    
                    Decimal tempUnitFee = pack.Unit_Fee__c;
                    
                    //Promotional fees discount calcuation
                    lWrap.pkgFeesPromtnalDis  = 0;
                    lWrap.prmtnalPkgInMonth   = 0;
                    if(pack.Is_Promotion_Discount__c && String.isNotBlank(pack.Promotion_period_In_months__c)){ 
                        tempUnitFee         = pack.Package_after_Promotion__r.Unit_Fee__c;
                        lWrap.pkgFeesPromtnalDis  = pack.Promotion_Discount__c;
                        lWrap.prmtnalPkgInMonth   = 0;                        
                        try{
                            lWrap.prmtnalPkgInMonth   = Integer.valueOf(pack.Promotion_period_In_months__c);
                        }catch(Exception e){}
                    }                    
                    //Registration fees calcuation
                    lWrap.regiFeesDis = (pack.Registration_Discount_Active__c && pack.Registration_Discount_Value__c > 0) ? pack.Registration_Discount_Value__c : 0;
                    
                    //Regular package fee calcuation on the bases of selected date
                    if(String.isNotBlank(lWrap.lessonSlcdDate) && tempUnitFee > 0){
                        Date lessDate = date.Parse(lWrap.lessonSlcdDate);                      
                        lWrap.prgFees = BillingUtility.calculateCurrentMonthPckFees(lessDate, tempUnitFee);
                    }
                    
                    //Promotional fees discount calcuation
                    if(pack.Is_Promotion_Discount__c && lWrap.prmtnalPkgInMonth > 0){
                       // lWrap.prgFees = pack.Package_Fee__c + lWrap.prgFees;
                       
                        //updated by Rajesh | Date-24th April 2019, New promotinal related changes
                        lWrap.prgFees = pack.Package_Fee__c;
                        lWrap.proNoOfLess = Integer.valueOf(pack.of_Units__c);
                        lWrap.pkgAftPro = pack.Package_after_Promotion__c;
                    }
                    
                    Decimal totTemp = lWrap.regiFees + lWrap.prgFees;
                    
                    //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                    //lWrap.prgFees = lWrap.prgFees.setScale(2);
                    lWrap.prgFees = BillingUtility.roundOffAmount(lWrap.prgFees);
                    
                    grndTotModel.feesTot += totTemp;
                    grndTotModel.disTot  +=  (lWrap.regiFeesDis + lWrap.pkgFeesPromtnalDis);
                    grndTotModel.depositTot += lWrap.depFees != null ? lWrap.depFees : 0;
                    
                     //Start-- Total amount calcuation for the Individual Enrolment
                    Integer gstTaxPer = ConstantsClass.defGST;
                    try{
                        gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                    }catch(Exception e){} 
                    
                    Decimal TempDisTot  =  (lWrap.regiFeesDis + lWrap.pkgFeesPromtnalDis);
                    
                    Decimal tempTot = totTemp - TempDisTot;
                    //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                    //Decimal gstAmt = (tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0).setScale(2);
                    Decimal gstAmt = BillingUtility.roundOffAmount(tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0);
                    
                    lWrap.totAmt = totTemp + gstAmt;
                    //lWrap.totAmt = totTemp + lWrap.gstAmt;
                    //End-- Total amount calcuation for the Individual Enrolment
                    
                    lWrap.slcdPakgPrgBillingType = pack.Program__r.Billing__c;
                    lWrap.slcdPakgPrgScdlType    = pack.Program__r.Scheduling__c;                    
                    try {
                        lWrap.pkgDuration = Integer.valueOf(pack.Duration__c);
                    }Catch (exception e) {}
                    /*Package__c pack = packMap.get(lWrap.selectedPlan);
                    
                    lWrap.selPckMonthFees = pack.Package_Fee__c;
                    lWrap.depFees  = pack.Deposit_Fee__c != null ? pack.Deposit_Fee__c.setScale(2) : 0 ;
                    lWrap.regiFees = pack.Registration_Fee__c;
                    
                    Decimal tempUnitFee = pack.Unit_Fee__c;
                    
                    lWrap.pkgFeesPromtnalDis  = 0;
                    lWrap.prmtnalPkgInMonth   = 0;
                    //Promotional fees discount calcuation
                    if(pack.Is_Promotion_Discount__c && String.isNotBlank(pack.Promotion_period_In_months__c)){ 
                        tempUnitFee         = pack.Package_after_Promotion__r.Unit_Fee__c;
                        lWrap.pkgFeesPromtnalDis  = pack.Promotion_Discount__c;
                        lWrap.prmtnalPkgInMonth   = 0;
                        
                        try{
                            lWrap.prmtnalPkgInMonth   = Integer.valueOf(pack.Promotion_period_In_months__c);
                        }catch(Exception e){}
                    }
                    
                    //Registration fees calcuation
                    lWrap.regiFeesDis = (pack.Registration_Discount_Active__c && pack.Registration_Discount_Value__c > 0) ? pack.Registration_Discount_Value__c : 0;
                        
                    //Regular package fee calcuation on the bases of selected date
                    if(String.isNotBlank(lWrap.lessonSlcdDate) && tempUnitFee > 0){
                        Date lessDate = date.Parse(lWrap.lessonSlcdDate);
                      
                        lWrap.prgFees = BillingUtility.calculateCurrentMonthPckFees(lessDate, tempUnitFee);
                    }
                    
                    //Promotional fees discount calcuation
                    if(pack.Is_Promotion_Discount__c && lWrap.prmtnalPkgInMonth > 0){
                        lWrap.prgFees = pack.Package_Fee__c + lWrap.prgFees;
                    }
                    
                    
                    Decimal totTemp = lWrap.regiFees + lWrap.prgFees;
                    
                    //Deducting registration fees
                    if(lWrap.regiFeesDis > 0)
                        totTemp = (totTemp - lWrap.regiFeesDis);
                    
                    //Deducting promotional fees
                    if(lWrap.pkgFeesPromtnalDis > 0)
                        totTemp = (totTemp - lWrap.pkgFeesPromtnalDis);
                    
                    Integer gstTaxPer = ConstantsClass.defGST;
                    try{
                        gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                    }catch(Exception e){}
                    
                    lWrap.gstAmt = totTemp > 0 ? ((totTemp * gstTaxPer) / 100):0;
                    lWrap.totAmt = totTemp + lWrap.gstAmt;
                    
                    
                    lWrap.gstAmt = lWrap.gstAmt.setScale(2);
                    lWrap.totAmt = lWrap.totAmt.setScale(2);
                    
                    grndTotModel.disTot +=  (lWrap.regiFeesDis + lWrap.pkgFeesPromtnalDis);
                    grndTotModel.gstTot +=  lWrap.gstAmt;
                    
                    grndTotModel.feesTot += lWrap.totAmt;
                    grndTotModel.depositTot += lWrap.depFees != null ? lWrap.depFees : 0;
                    
                    lWrap.slcdPakgPrgBillingType = pack.Program__r.Billing__c;
                    lWrap.slcdPakgPrgScdlType    = pack.Program__r.Scheduling__c;
                    
                    try {
                        lWrap.pkgDuration = Integer.valueOf(pack.Duration__c);
                    }Catch (exception e) {}
               */
                }   
            }
        }
        
        //Gst calculation
        Integer gstTaxPer = ConstantsClass.defGST;
        try{
            gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
        }catch(Exception e){}
        
        Decimal tempTot = grndTotModel.feesTot - grndTotModel.disTot;
        grndTotModel.gstTot = tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0;        
        
        //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
        /*
        grndTotModel.disTot   = grndTotModel.disTot.setScale(2);
        grndTotModel.feesTot  = grndTotModel.feesTot.setScale(2);
        grndTotModel.gstTot   = grndTotModel.gstTot.setScale(2);
        grndTotModel.depositTot = grndTotModel.depositTot.setScale(2);
        grndTotModel.subsTot  = (grndTotModel.feesTot + grndTotModel.gstTot -(grndTotModel.disTot)).setScale(2);
        grndTotModel.grandTot = (grndTotModel.subsTot + grndTotModel.depositTot).setScale(2);*/
        grndTotModel.disTot   = BillingUtility.roundOffAmount(grndTotModel.disTot);
        grndTotModel.feesTot  = BillingUtility.roundOffAmount(grndTotModel.feesTot);
        grndTotModel.gstTot   = BillingUtility.roundOffAmount(grndTotModel.gstTot);
        grndTotModel.depositTot = BillingUtility.roundOffAmount(grndTotModel.depositTot);
        grndTotModel.subsTot  = BillingUtility.roundOffAmount(grndTotModel.feesTot + grndTotModel.gstTot -(grndTotModel.disTot));
        grndTotModel.grandTot = BillingUtility.roundOffAmount(grndTotModel.subsTot + grndTotModel.depositTot);
        
        List<Account> accList = [SELECT Id, Name, Stripe_Customer_Id__c, Card_Number__c, Card_Type__c, Card_Image__c 
                                 FROM Account WHERE (Id =: parentAccWrap.accId OR PersonEmail =: parentAccWrap.Email) 
                                     AND Stripe_Customer_Id__c != null AND Card_Number__c != null AND Card_Type__c != null];
        isAlreadyStripCstmr = false;
        if(accList.size() > 0){
            stripeCstmrId = accList.get(0).Stripe_Customer_Id__c;
            cardNumber    = accList.get(0).Card_Number__c;
            cardType      = accList.get(0).Card_Type__c;            
            cardImage     = accList.get(0).Card_Image__c;
            isAlreadyStripCstmr = true;
        }
        
        
        
       /* 
        grndTotModel.grandTot = grndTotModel.feesTot + grndTotModel.depositTot;
        
        grndTotModel.feesTot    = grndTotModel.feesTot.setScale(2);
        grndTotModel.depositTot = grndTotModel.depositTot.setScale(2);
        grndTotModel.grandTot   = grndTotModel.grandTot.setScale(2);*/
    }
    
    public PageReference completeEnrolment(){
        Savepoint sp;
        isError = false;
        errorMsg = '';
        
        //Added by Prabhat (18-06-2019)
        EnrollmentProcessErrorLogs.errorLogObj errorObj = new EnrollmentProcessErrorLogs.errorLogObj();
        
        //Updated by Rajesh, 30th June 2019, for American club member
        if(isAmcClubMember || isAlreadyStripCstmr || (stripeToken!=null && stripeToken.trim().length()>0)){
            try{
                String recId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
                Account parentAcc = new Account(Id = parentAccWrap.accId, RecordTypeId = recId, FirstName = parentAccWrap.FirstName, LastName = parentAccWrap.Lastname, 
                                                Gender__c = parentAccWrap.gender, PersonMobilePhone = PersonMobilePhoneCustom, Nationality__c = parentAccWrap.Nationality, 
                                                phone = PersonMobilePhoneCustom, Occupation__c = parentAccWrap.Occupation, PersonEmail = parentAccWrap.Email, 
                                                BillingStreet = parentAccWrap.Address, BillingCity = parentAccWrap.City, BillingPostalCode = parentAccWrap.BillingPostalCode, 
                                                BillingCountryCode = parentAccWrap.BillingCountryCode);
               
                String cusName = String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName : ' ';
                       cusName += parentAcc.LastName;
                
                String last4CardNumber;
                String cardType;
                //Added by Rajesh, 9th sept, for store expiry month or year on customer 
                Integer exp_month;
                Integer exp_year;
                
                //Updated by Rajesh, 30th June 2019, for American club member
                if(!isAmcClubMember && (!isAlreadyStripCstmr || String.isBlank(stripeCstmrId))){   
                    //Updated by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
                    //BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(stripeToken, cusName, parentAcc.PersonEmail, 'Parent customer');    
                    BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(stripeToken, cusName, parentAcc.PersonEmail, 'Parent customer', stripeBaseUrl, stripeApiSecKey);    
                    if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){ 
                      stripeCstmrId = sCstmr.id;
                        
                        BillingUtility.cls_sources srcs = sCstmr.sources;
                        if(srcs.stripeData.size() > 0){
                            BillingUtility.cls_data clData  = srcs.stripeData.get(0);
                            last4CardNumber = clData.last4;
                            cardType = clData.brand;
                            
                             //Added by Rajesh, 9th sept, for store expiry month or year on customer 
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
                    
                    Decimal amountInSmallUnit      = grndTotModel.grandTot;
                    BillingUtility.stripeCharge sc = new BillingUtility.stripeCharge(); 
                    //Updated by Rajesh, 30th June 2019, Skip stripe customer creation for the American club member
                    if(!isAmcClubMember){
                        //Updated by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
                        // sc = BillingUtility.createChargeForCustomer(stripeCstmrId,amountInSmallUnit,'sgd');
                        sc = BillingUtility.createChargeForCustomer(stripeCstmrId, amountInSmallUnit, countryCurrencyCode, stripeBaseUrl, stripeApiSecKey);
                    }
                    //Updated by Rajesh, 30th June 2019, for the American club member
                    if(isAmcClubMember || (sc.statusCode == 200 && sc.paid)){
                        sp = Database.setSavepoint();
                        
                        //Added By Prabhat(01-07-2019) to create error logs if exception occurs
                        //Below mapping will also be used to refund the amount back to the customer.
                        errorObj.customerStripeId = stripeCstmrId;
                        errorObj.stripeTransactionId = sc.id;
                        errorObj.stripeChargeAmount = sc.amount;
                        errorObj.baseUrl = stripeBaseUrl;
                        errorObj.apiKey  = stripeApiSecKey;
                        
                        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();    
                        
                        //Added by Rajesh: 19th July, Populate Customer fields When first Active Enrolment is created in the system (Discussed with Prashant)
                        Boolean isFirstEnrolment = true;
                        
                        //Check that customer is already exist or not on the bases of email
                        if(parentAcc.Id == null && parentAcc.PersonEmail != null){
                            List<Account> accList = [SELECT Id,Name,Location__c,Centre_Name__c,Enroled__c FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
                            if(accList.size() > 0){
                                parentAcc.Id = accList.get(0).Id;
                                
                                //Added by Rajesh: 19th July, Populate Customer fields When first Active Enrolment is created in the system (Discussed with Prashant)
                                if(accList.get(0).Enroled__c)
                                    isFirstEnrolment = false;
                            }
                        }
                        //Added by Rajesh: 19th July, Populate Customer fields When first Active Enrolment is created in the system (Discussed with Prashant)
                        if(isFirstEnrolment  && studentWrapList.size() > 0 && studentWrapList.get(0).lessonList.size() > 0){
                            LessonWrapper lw = studentWrapList.get(0).lessonList.get(0);
                            parentAcc.Centre_Name__c = lw.selectedCenter;
                            parentAcc.Enroled__c= true;
                            parentAcc.Instrument__c=lw.instrument;
                            List<Account> centrList = [SELECT Id, Name, Location__c FROM Account WHERE Id =: lw.selectedCenter];
                            if(centrList.size() > 0)
                                parentAcc.Location__c = centrList.get(0).Location__c;
                        }
                        
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
                        upsert parentAcc;
                        
                        //Added By Prabhat(18-06-2019) to create error logs if exception occurs
                        //Below mapping will also be used to refund the amount back to the customer.
                        errorObj.customerSalesforceId = parentAcc.Id;
                        /*errorObj.customerStripeId = stripeCstmrId;
                        errorObj.stripeTransactionId = sc.id;
                        errorObj.stripeChargeAmount = sc.amount;
                        */
                         
                        
                        Set<Id> tempCenIds = new Set<Id>();
                        for(StudentWrapper stu : studentWrapList){
                            for(LessonWrapper lw : stu.lessonList){
                                if(String.isNotBlank(lw.selectedCenter))
                                    tempCenIds.add(lw.selectedCenter);
                            }
                        }
                        Map<String, Subscription__c> activeSubMap = new Map<String, Subscription__c>();
                        for(Subscription__c sub: [SELECT Id, Parent__c, Center__c FROM Subscription__c  
                                                  WHERE Parent__c =: parentAcc.Id AND Center__c IN:tempCenIds  
                                                        AND Status__c =: ConstantsClass.activeStatus])
                            activeSubMap.put(sub.Center__c, sub);
                        
                        Set<String> centSet = new Set<String>();
                        Set<String> tchrSet = new Set<String>();
                        Set<String> daySet = new Set<String>();
                        Map<String,Teacher_Working_Hour__c> tcrWrkHourMap = new Map<String,Teacher_Working_Hour__c>();
                        for(StudentWrapper stu : studentWrapList){
                            for(LessonWrapper lw : stu.lessonList){
                                if(lw.selectedCenter == Label.Aureus_at_Home_Id && lw.cntrTravHour > 0){
                                    centSet.add(lw.selectedCenter);
                                    tchrSet.add(lw.selectedTeacher);
                                    
                                    if(String.isNotBlank(lw.lessonSlcdDate)){
                                        Date tempDt    = Date.parse(lw.lessonSlcdDate);
                                        String currDay = DateTime.newInstance(tempDt, Time.newInstance(0, 0, 0, 0)).format('E');
                                        daySet.add(currDay);
                                    }
                                }
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
                        
                        Map<Id, Subscription__c> centSubMap = new Map<Id, Subscription__c>();
                        Map<Id, Invoice__c> cntrInvMap      = new Map<Id, Invoice__c>();
                        Map<Id, Payment__c> cntrPayMap      = new Map<Id, Payment__c>();
                        List<Account> studentList           = new List<Account>(); 
                        List<Enrolment__c> enrolmentList    = new List<Enrolment__c>();
                        List<Booking__c> bookList           = new List<Booking__c>();
                        List<Subscription_Line_Item__c> subLinItmList = new List<Subscription_Line_Item__c>();
                        List<Invoice_Line_Item__c> invLineItmList     = new List<Invoice_Line_Item__c>();
                        
                        Integer counter = 0;
                        for(StudentWrapper stu : studentWrapList){
                            Account tempStuAcc = new Account(Id = stu.stuAccWrap.accId, RecordTypeId = recId, FirstName = stu.stuAccWrap.FirstName, LastName = stu.stuAccWrap.Lastname, 
                                                            Gender__c = stu.stuAccWrap.gender, PersonMobilePhone = stu.stuAccWrap.mobile, Nationality__c = stu.stuAccWrap.Nationality, 
                                                            phone = stu.stuAccWrap.Phone, Occupation__c = stu.stuAccWrap.Occupation, PersonEmail = stu.stuAccWrap.Email, 
                                                            BillingStreet = stu.stuAccWrap.Address, BillingCity = stu.stuAccWrap.City, BillingPostalCode = stu.stuAccWrap.BillingPostalCode, 
                                                            BillingCountryCode = stu.stuAccWrap.BillingCountryCode, School__c = stu.stuAccWrap.school);
                            tempStuAcc.PersonBirthdate = stu.enrBirthdateField.Trial_Date__c;
                            
                            Account stdnt = new Account();
                            if(isParAlsoAStudent && counter == 0){
                                stdnt                   = parentAcc;
                                stdnt.Also_a_Student__c = true;
                                stdnt.PersonBirthdate   = tempStuAcc.PersonBirthdate;
                                stdnt.Gender__c         = tempStuAcc.Gender__c;
                                stdnt.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                            }else{
                                stdnt           = tempStuAcc;
                                stdnt.Parent__c = parentAcc.Id;
                                stdnt.Current_Engagement_Status__c = ConstantsClass.activeStatus; 
                            }
                            counter = counter+1;
                            studentList.add(stdnt);                         
                            
                            for(LessonWrapper lw : stu.lessonList){
                                //Added by Rajesh, date 24th June 2019, for populating subscription start date and next billing date for the 
                                Date subTempDt = Date.parse(lw.lessonSlcdDate).addMonths(1);
                                Date subsDt = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                                Date subsNextBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);
                                Date promPerEndDate;
                                
                                //Added by Rajesh: 25th June 2019, Populating last date, according to promotional package
                                if(lw.pkgFeesPromtnalDis > 0 && lw.prmtnalPkgInMonth > 0 && lw.proNoOfLess >0){
                                    subsNextBillingDate = subsNextBillingDate.addMonths(lw.prmtnalPkgInMonth);
                                    Date stDt = Date.parse(lw.lessonSlcdDate);
                                    
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
                                        
                                        if(countNoOfLess >= lw.proNoOfLess)
                                            break;
                                        
                                        stDt = stDt.addDays(7);
                                    }
                                    promPerEndDate = stDt;
                                    if(countDtforMonth == 4)
                                        stDt = stDt.addMonths(1);
                                    subsNextBillingDate = Date.newInstance(stDt.year(), stDt.month(), ConstantsClass.subNextBillingDay);
                                }
                                
                                
                                //Filling subscription
                                Subscription__c subs = new Subscription__c();
                                if(activeSubMap.containsKey(lw.selectedCenter)){
                                    subs = activeSubMap.get(lw.selectedCenter);
                                }else if(centSubMap.containsKey(lw.selectedCenter)){
                                    subs = centSubMap.get(lw.selectedCenter);
                                }else{
                                    //Commented by Rajesh on 24th June 2019, for populating next billing date according to promotinaly package
                                   /* Date subTempDt       = Date.parse(lw.lessonSlcdDate).addMonths(1);
                                    Date subsDt = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                                    */
                                    
                                    //Filling subscription
                                    subs = BillingUtility.fillSubscription(parentAcc.Id, ConstantsClass.activeStatus, subsDt);
                                    subs.Center__c = lw.selectedCenter;
                                    
                                    //Commented by Rajesh on 24th June 2019, for populating next billing date according to promotinaly package
                                    //Date subsNextBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);
                                    subs.Next_Bill_Date__c   = subsNextBillingDate;
                                    
                                    //Commented by Rajesh on 24th June 2019, for populating next billing date according to promotinaly package
                                    /*if(lw.pkgFeesPromtnalDis > 0 && lw.prmtnalPkgInMonth > 0){
                                        subs.Next_Bill_Date__c = subs.Next_Bill_Date__c.addMonths(lw.prmtnalPkgInMonth); 
                                    }*/                                    
                                    
                                }
                                centSubMap.put(lw.selectedCenter, subs);
                                
                                //Filling Invoice
                                Invoice__c inv        = new Invoice__c();
                                if(cntrInvMap.containsKey(lw.selectedCenter)){
                                    inv = cntrInvMap.get(lw.selectedCenter);
                                }else{
                                    inv = BillingUtility.fillInvoice(null, parentAcc.Id, ConstantsClass.paidStatus);
                                    inv.Center__c = lw.selectedCenter; 
                                    inv.Subscription__r = subs;
                                    //Added by Rajesh, 30th July 2019, Set invoice type for the Enrolment process
                                    inv.invoice_type__c = 'New Enrolment';
                                }
                                //Updated by Rajesh, 30th June 2019, Set invoice status as a due for the American club member
                                if(isAmcClubMember){
                                   inv.Status__c   = ConstantsClass.dueStatus; 
                                }
                                cntrInvMap.put(lw.selectedCenter, inv);
                                
                                //Filling Payment
                                //Added By Rajesh: 1 July 2019, Set Payment Transaction recordtype on payment object
                                String payTrnRecId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
                                Payment__c pay     = new Payment__c(RecordtypeId      = payTrnRecId);
                                if(cntrPayMap.containsKey(lw.selectedCenter)){
                                    /*pay = cntrPayMap.get(lw.selectedCenter);
                                    
                                    Decimal totAmtTemp = lw.totAmt;
                                    totAmtTemp += lw.depFees;
                                    
                                    pay.Payment_Amount__c += lw.totAmt;*/
                                    
                                    Decimal totAmtTemp = lw.totAmt + lw.depFees;
                                    totAmtTemp = (totAmtTemp - (lw.regiFeesDis + lw.pkgFeesPromtnalDis));
                                    
                                    pay = cntrPayMap.get(lw.selectedCenter);
                                    pay.Payment_Amount__c += totAmtTemp;
                                }else{
                                   /* Decimal totAmtTemp = lw.totAmt;
                                    totAmtTemp += lw.depFees;*/                                    
                                    Decimal totAmtTemp = lw.totAmt + lw.depFees;
                                    totAmtTemp = (totAmtTemp - (lw.regiFeesDis + lw.pkgFeesPromtnalDis));
                                    
                                    pay        = BillingUtility.fillPayment(parentAcc.Id, null, totAmtTemp, ConstantsClass.successStatus);
                                    //Added By Rajesh: 1 July 2019, Set Payment Transaction recordtype on payment object
                                    //Added By Rajesh: 20th Aug 2019, Set Method of payment as a Card on payment object
                                    pay.RecordtypeId      = payTrnRecId;
                                    pay.Method_of_Payment__c = 'Card';
                                    pay.Transaction_ID__c = sc.id; 
                                    pay.Invoice__r        = inv;
                                }
                                //Updated by Rajesh, 30th June 2019, No need to create payment for the American club member
                                if(!isAmcClubMember)
                                    cntrPayMap.put(lw.selectedCenter, pay);
                            
                                //Filling Enrolment 
                                Date lessDt; 
                                if(String.isNotBlank(lw.lessonSlcdDate))
                                    lessDt =  date.Parse(lw.lessonSlcdDate);
                                
                                Time startTime;
                                if(String.isNotBlank(lw.lessonSlctSlot)){
                                    List<String> timeList = lw.lessonSlctSlot.split(':');
                                    
                                    startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                }
                                
                                Enrolment__c enrl   = BillingUtility.fillEnrolment(parentAcc.Id, null, lw.selectedCenter, lw.selectedTeacher, 
                                                                                   lw.selectedPlan, lessDt, startTime, ConstantsClass.enroledStatus);
                                enrl.Student__r     = stdnt;
                                enrl.Cancellation_Policy_Agreed__c = true;
                                enrl.Promotional_Period_End_Date__c= promPerEndDate;
                                enrl.Package_To_Be_Change__c       = lw.pkgAftPro;
                                //updated by Rajesh, 7th Aug 2019. to store enrolmentsource on enrolment/case object
                                if(String.isNotBlank(enrolmentSource))
                					enrl.Enrolment_Source__c = enrolmentSource;
                                
                                if(lw.enrId != null)
                                    enrl.Id         = lw.enrId;
                                enrolmentList.add(enrl);
                                
                                Subscription_Line_Item__c subLItm = BillingUtility.fillSubscriptionLineItem(null, null, lw.selectedPlan, null, 
                                                                                                            lw.selPckMonthFees, ConstantsClass.activeStatus);
                                subLItm.Subscription__r = subs;
                                subLItm.Student__r   = stdnt;
                                subLItm.Enrolment__r = enrl;
                                subLItm.Subscription_Start_Date__c = lessDt;
                                    
                                //Commented by Rajesh on 24th June 2019, for populating next billing date according to promotinaly package
                               /* Date subTempDt = lessDt.addMonths(1);
                                Date subsDt = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                                
                                Date subsNextBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);
                                */
                                
                                //Filling subscription line item billing date for the enrolment
                                subLItm.Next_Bill_Date__c   = subsNextBillingDate;
                                 //Commented by Rajesh on 24th June 2019, for populating next billing date according to promotinaly package
                                /*if(lw.pkgFeesPromtnalDis > 0 && lw.prmtnalPkgInMonth > 0){
                                    subLItm.Next_Bill_Date__c = subLItm.Next_Bill_Date__c.addMonths(lw.prmtnalPkgInMonth); 
                                }*/
                                subLinItmList.add(subLItm);
                                
                                //Populating Booking list
                                if(String.isNotBlank(lw.lessonSlcdDate) && String.isNotBlank(lw.slcdPakgPrgScdlType)){
                                    Date lessDate = date.Parse(lw.lessonSlcdDate);
                                    if(lw.slcdPakgPrgScdlType.equalsIgnoreCase(ConstantsClass.pkgOneTimeType)){
                                        bookList.add(EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, lessDate));
                                        
                                        //Adding trial time during Aureus at home center
                                        if(lw.selectedCenter == Label.Aureus_at_Home_Id && lw.cntrTravHour > 0){
                                            String currDay =  DateTime.newInstance(lessDate, Time.newInstance(0, 0, 0, 0)).format('E');
                                            String key = lw.selectedTeacher+'#'+lw.selectedCenter+'#'+currDay;
                                            
                                            if(tcrWrkHourMap.containsKey(key)){
                                                Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                
                                                Time tempT;
                                                if(String.isNotBlank(lw.lessonSlctSlot)){
                                                    List<String> timeList = lw.lessonSlctSlot.split(':');
                                                    tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                }
                                                
                                                if(tchrworkH.Start_Time__c != tempT){
                                                    //Traveling booking Before
                                                    Booking__c befBook    = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', lessDate);
                                                    befBook.Type__c       = ConstantsClass.busyBookingType;
                                                    befBook.Status__c     = ConstantsClass.scheduledStatus;
                                                    befBook.Remarks__c    = 'Booking for before trial';
                                                    befBook.Category__c   = 'Travel';
                                                    //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                    befBook.End_Time__c   = befBook.Start_Time__c;
                                                    befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                    //befBook.End_Time__c   = befBook.Start_Time__c;
                                                    bookList.add(befBook);
                                                }
                                            }
                                        }
                                    }else{
                                        //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                        String remStr    =  String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName +' '+ parentAcc.LastName : parentAcc.LastName;
                                        remStr   =  remStr +':'+(String.isNotBlank(stdnt.FirstName) ? stdnt.FirstName +' '+ stdnt.LastName : stdnt.LastName);
                                        
                                        //Added by Rajesh: 25th July 2019, for Adding placeholder bookings before enrolment lesson start
                                        Date tempDt  = lessDate;
                                        tempDt = tempDt.addDays(-7); 
                                        while(System.today() < tempDt){
                                            Booking__c bTemp = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, tempDt);
                                            bTemp.Status__c  = ConstantsClass.scheduledStatus;
                                            bTemp.Type__c    = ConstantsClass.busyBookingType;
                                            bTemp.Category__c= 'Placeholder';                                            
                                            bTemp.Remarks__c = 'A future regular enrolemnt starting from '+lessDate+' for '+remStr;
                                            bookList.add(bTemp);    
                                           
                                            //Adding trial time during Aureus at home center
                                            if(lw.selectedCenter == Label.Aureus_at_Home_Id && lw.cntrTravHour > 0){
                                                
                                                String currDay =  DateTime.newInstance(tempDt, Time.newInstance(0, 0, 0, 0)).format('E');
                                                String key = lw.selectedTeacher+'#'+lw.selectedCenter+'#'+currDay;
                                                
                                                if(tcrWrkHourMap.containsKey(key)){
                                                    Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                    
                                                    Time tempT;
                                                    if(String.isNotBlank(lw.lessonSlctSlot)){
                                                        List<String> timeList = lw.lessonSlctSlot.split(':');
                                                        tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                    }
                                                    
                                                    if(tchrworkH.Start_Time__c != tempT){
                                                        //Traveling booking Before
                                                        Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', tempDt);
                                                        befBook.RecordTypeId  = bookLessRecId;
                                                        befBook.Status__c     = ConstantsClass.scheduledStatus;
                                                        befBook.Type__c       = ConstantsClass.busyBookingType;
                                                        befBook.Category__c   = 'Travel';
                                                        befBook.Remarks__c    = 'Booking for before trial.'+remStr;
                                                        befBook.End_Time__c   = bTemp.Start_Time__c;
                                                        befBook.Start_Time__c = bTemp.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                        
                                                        bookList.add(befBook);
                                                    }
                                                }
                                            }
                                            tempDt = tempDt.addDays(-7); 
                                        }
                                        
                                        Date stDate  = lessDate;
                                        Date endDate = stDate.addMonths(12); 
                                        
                                        Integer numberOfDays = Date.daysInMonth(endDate.year(), endDate.month());
                                        Date lastDayOfEndDateMonth = Date.newInstance(endDate.year(), endDate.month(), numberOfDays);
                                        
                                        Date dt=lessDate;   
                                       // Integer curDtMonth;
                                        Integer countBookingForMonth = 0;
                                        Date currLesDt; 
                                        
                                        //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                        //String remStr    =  String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName +' '+ parentAcc.LastName : parentAcc.LastName;
                                        //remStr   =  remStr +':'+(String.isNotBlank(stdnt.FirstName) ? stdnt.FirstName +' '+ stdnt.LastName : stdnt.LastName);
                                        remStr    =     'Placeholder booking for 5th lesson of '+remStr;
                                        
                                        while(dt<=lastDayOfEndDateMonth){
                                            //if(subLItm.Next_Bill_Date__c > dt){
                                            if(promPerEndDate != null && promPerEndDate >= dt){
                                               /* Boolean isCreateBooking = false;
                                                if(countBookingForMonth == 0){
                                                    countBookingForMonth = countBookingForMonth+1;
                                                    curDtMonth = dt.month();
                                                    isCreateBooking = true;
                                                }else if(countBookingForMonth < 4){
                                                    countBookingForMonth = countBookingForMonth+1;
                                                    isCreateBooking = true;
                                                }else{
                                                    countBookingForMonth = 0;
                                                }*/
                                                
                                                //Boolean isCreateBooking = false;
                                                Boolean isCreate5thPlaceBooking = false;
                                                if(currLesDt == null)
                                                    currLesDt = dt;
                                                
                                                if(currLesDt.month() == dt.month()){
                                                    if(countBookingForMonth < 4){
                                                        countBookingForMonth = countBookingForMonth+1;
                                                        //isCreateBooking = true;
                                                    }else{
                                                        isCreate5thPlaceBooking = true;
                                                    }
                                                }else{
                                                    currLesDt = dt;
                                                    countBookingForMonth = 1;
                                                   // isCreateBooking = true;
                                                }
                                                
                                                /*if(isCreateBooking){
                                                    bookList.add(EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, dt));
                                                 */  
                                                    Booking__c bTemp = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, dt);
                                                    
                                                    if(isCreate5thPlaceBooking){   
                                                        bTemp.Status__c  = ConstantsClass.scheduledStatus;
                                                        bTemp.Type__c    = ConstantsClass.busyBookingType;
                                                        bTemp.Category__c= 'Placeholder';
                                                        
                                                        //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                                        bTemp.Remarks__c = remStr;
                                                    }
                                                    bookList.add(bTemp);    
                                                
                                                     //Adding trial time during Aureus at home center
                                                    if(lw.selectedCenter == Label.Aureus_at_Home_Id && lw.cntrTravHour > 0){
                                                        
                                                        String currDay =  DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('E');
                                                        String key = lw.selectedTeacher+'#'+lw.selectedCenter+'#'+currDay;
                                                        
                                                        if(tcrWrkHourMap.containsKey(key)){
                                                            Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                            
                                                            Time tempT;
                                                            if(String.isNotBlank(lw.lessonSlctSlot)){
                                                                List<String> timeList = lw.lessonSlctSlot.split(':');
                                                                tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                            }
                                                            
                                                            if(tchrworkH.Start_Time__c != tempT){
                                                                //Traveling booking Before
                                                                Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                                                befBook.RecordTypeId  = bookLessRecId;
                                                                befBook.Status__c    = ConstantsClass.scheduledStatus;
                                                                befBook.Type__c       = ConstantsClass.busyBookingType;
                                                                befBook.Category__c   = 'Travel';
                                                                befBook.Remarks__c    = 'Booking for before trial';
                                                                //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                                befBook.End_Time__c   = befBook.Start_Time__c;
                                                                befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                                //befBook.End_Time__c   = befBook.Start_Time__c;
                                                                
                                                                if(isCreate5thPlaceBooking){   
                                                                    befBook.Type__c    = ConstantsClass.busyBookingType;
                                                                    befBook.Category__c= 'Placeholder';
                                                                    
                                                                    //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                                                    befBook.Remarks__c = remStr; 
                                                                }   
                                                                
                                                                bookList.add(befBook);
                                                            }
                                                        }
                                                  //  }
                                                }
                                            }else if(lessDate.month() == dt.month() && lessDate.year() == dt.year()){
                                                bookList.add(EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.scheduledStatus, dt));
                                               
                                                 //Adding trial time during Aureus at home center
                                                if(lw.selectedCenter == Label.Aureus_at_Home_Id && lw.cntrTravHour > 0){
                                                    String currDay =  DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('E');
                                                    String key = lw.selectedTeacher+'#'+lw.selectedCenter+'#'+currDay;
                                                    
                                                    if(tcrWrkHourMap.containsKey(key)){
                                                        Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                        
                                                        Time tempT;
                                                        if(String.isNotBlank(lw.lessonSlctSlot)){
                                                            List<String> timeList = lw.lessonSlctSlot.split(':');
                                                            tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                        }
                                                        
                                                        if(tchrworkH.Start_Time__c != tempT){
                                                           //Traveling booking Before
                                                            Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                                            befBook.RecordTypeId  = bookLessRecId;
                                                            befBook.Type__c       = ConstantsClass.busyBookingType;
                                                            befBook.Status__c    = ConstantsClass.scheduledStatus;
                                                            befBook.Category__c   = 'Travel';
                                                            befBook.Remarks__c    = 'Travel time slot for home regular booking'; 
                                                            //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                            befBook.End_Time__c   = befBook.Start_Time__c;
                                                            befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                            //befBook.End_Time__c   = befBook.Start_Time__c;
                                                            bookList.add(befBook);
                                                        }
                                                    }
                                                }                                                
                                            }else{
                                                //Boolean isCreateBooking = false;
                                                Boolean isCreate5thPlaceBooking = false;
                                                if(currLesDt == null)
                                                    currLesDt = dt;
                                                
                                                if(currLesDt.month() == dt.month()){
                                                    if(countBookingForMonth < 4){
                                                        countBookingForMonth = countBookingForMonth+1;
                                                        //isCreateBooking = true;
                                                    }else{
                                                        isCreate5thPlaceBooking = true;
                                                    }
                                                }else{
                                                    currLesDt = dt;
                                                    countBookingForMonth = 1;
                                                   // isCreateBooking = true;
                                                }
                                                /*Boolean isCreateBooking = false;
                                                if(countBookingForMonth == 0){
                                                    countBookingForMonth = countBookingForMonth+1;
                                                    curDtMonth = dt.month();
                                                    isCreateBooking = true;
                                                }else if(countBookingForMonth < 4){
                                                    countBookingForMonth = countBookingForMonth+1;
                                                    isCreateBooking = true;
                                                }else{
                                                    countBookingForMonth = 0;
                                                }*/
                                                
                                                /*if(isCreateBooking){
                                                    bookList.add(EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.pendingStatus, dt));
                                                  */  
                                                    
                                                    Booking__c bTemp = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.pendingStatus, dt);
                                                    if(isCreate5thPlaceBooking){   
                                                        bTemp.Type__c    = ConstantsClass.busyBookingType;
                                                        bTemp.Status__c  = ConstantsClass.scheduledStatus;
                                                        bTemp.Category__c= 'Placeholder';
                                                        
                                                        //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                                        bTemp.Remarks__c = remStr; 
                                                    }
                                                    bookList.add(bTemp);
                                                
                                                     //Adding trial time during Aureus at home center
                                                    if(lw.selectedCenter == Label.Aureus_at_Home_Id && lw.cntrTravHour > 0){
                                                        String currDay =  DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('E');
                                                        String key = lw.selectedTeacher+'#'+lw.selectedCenter+'#'+currDay;
                                                        
                                                        if(tcrWrkHourMap.containsKey(key)){
                                                            Teacher_Working_Hour__c tchrworkH = tcrWrkHourMap.get(key); 
                                                            
                                                            Time tempT;
                                                            if(String.isNotBlank(lw.lessonSlctSlot)){
                                                                List<String> timeList = lw.lessonSlctSlot.split(':');
                                                                tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                                                            }
                                                            
                                                            if(tchrworkH.Start_Time__c != tempT){
                                                               //Traveling booking Before
                                                                Booking__c befBook = EnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                                                befBook.Status__c     = ConstantsClass.scheduledStatus;
                                                                befBook.Type__c       = ConstantsClass.busyBookingType;
                                                                befBook.Remarks__c    = 'Booking for before trial';
                                                                befBook.Category__c   = 'Travel';
                                                                //Added by Rajesh: 12th July 2019, To solve Start and Endtime as same issue
                                                            	befBook.End_Time__c   = befBook.Start_Time__c;
                                                                befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-lw.cntrTravHour);
                                                                //befBook.End_Time__c   = befBook.Start_Time__c;
                                                                
                                                                if(isCreate5thPlaceBooking){   
                                                                    befBook.Type__c    = ConstantsClass.busyBookingType;
                                                                    befBook.Category__c= 'Placeholder';
                                                                    
                                                                    //Added by Rajesh, 28th June 2019, for fill 5th lesson placeholder booking remarks
                                                                    befBook.Remarks__c = remStr; 
                                                                }                                                                
                                                                bookList.add(befBook);
                                                            }
                                                        }
                                                   // }
                                                }
                                            }
                                            if(lw.slcdPakgPrgScdlType.equalsIgnoreCase(ConstantsClass.pkgWeeklyType))
                                                dt = dt.addDays(7);
                                            else 
                                                dt = dt.addMonths(1);
                                        }
                                    }        
                                }
                                
                                //Filling Invoice Line items
                                if(lw.prgFees> 0){
                                    String remStr = ConstantsClass.pkgPrgFeesDes;
                                    
                                    //Added by Rajesh: 25th June 2019, Calcuating prg fee and discount on invoice line item on the bases of Lessons
                                    if(lw.pkgFeesPromtnalDis > 0 && lw.prmtnalPkgInMonth > 0 && lw.proNoOfLess >0){
                                        Decimal prgFeeForSingleLess = lw.prgFees/lw.proNoOfLess;
                                        Decimal prgDisFeeForSingleLess = 0;
                                        if(lw.pkgFeesPromtnalDis > 0)
                                            prgDisFeeForSingleLess = lw.pkgFeesPromtnalDis/lw.proNoOfLess;
                                        
                                        Date stDt = Date.parse(lw.lessonSlcdDate);
                                        
                                        Date currLesDt;
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
                                                //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                                //Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, tempPrgFee.setScale(2), remStr, lw.selectedTeacher);
                                                Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(tempPrgFee), remStr, lw.selectedTeacher);
                                                invLnItm.Package__c   = lw.selectedPlan;
                                                invLnItm.Invoice__r   = inv;
                                                invLnItm.Enrolment__r = enrl;
                                                invLnItm.Subscription_Line_Item__r = subLItm;
                                                invLnItm.Month__c = currLesDt;
                                                if(prgDisFeeForSingleLess > 0){
                                                    //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                                    //invLnItm.Discount_Amount__c = (prgDisFeeForSingleLess*countDtforMonth).setScale(2); 
                                                    invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(prgDisFeeForSingleLess*countDtforMonth); 
                                                }
                                                invLineItmList.add(invLnItm);
                                                
                                                currLesDt = stDt;
                                                countDtforMonth = 1;
                                            }                                            
                                            stDt = stDt.addDays(7);
                                        }
                                        
                                        if(countDtforMonth > 0){
                                            Decimal tempPrgFee = prgFeeForSingleLess*countDtforMonth;
                                            //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                            //Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, tempPrgFee.setScale(2), remStr, lw.selectedTeacher);
                                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(tempPrgFee), remStr, lw.selectedTeacher);
                                            invLnItm.Package__c   = lw.selectedPlan;
                                            invLnItm.Invoice__r   = inv;
                                            invLnItm.Enrolment__r = enrl;
                                            invLnItm.Subscription_Line_Item__r = subLItm;
                                            invLnItm.Month__c = currLesDt;
                                            if(prgDisFeeForSingleLess > 0){
                                                //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                               // invLnItm.Discount_Amount__c = (prgDisFeeForSingleLess*countDtforMonth).setScale(2); 
                                                invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(prgDisFeeForSingleLess*countDtforMonth); 
                                            }
                                            invLineItmList.add(invLnItm);
                                        }
                                    }else{
                                        //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                        //Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, lw.prgFees.setScale(2), remStr, lw.selectedTeacher);
                                        Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(lw.prgFees), remStr, lw.selectedTeacher);
                                        invLnItm.Package__c   = lw.selectedPlan;
                                        invLnItm.Invoice__r   = inv;
                                        invLnItm.Enrolment__r = enrl;
                                        invLnItm.Subscription_Line_Item__r = subLItm;
                                        invLnItm.Month__c     =  Date.parse(lw.lessonSlcdDate);
                                        if(lw.pkgFeesPromtnalDis > 0){
                                            //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                           // invLnItm.Discount_Amount__c = lw.pkgFeesPromtnalDis.setScale(2); 
                                            invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(lw.pkgFeesPromtnalDis); 
                                        }
                                        invLineItmList.add(invLnItm);
                                    }
                                }
                                if(lw.regiFees> 0){
                                    String remStr = ConstantsClass.pkgRegFeesDes;
                                    //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                    // Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, lw.regiFees.setScale(2), remStr, lw.selectedTeacher);
                                    Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null,  BillingUtility.roundOffAmount(lw.regiFees), remStr, lw.selectedTeacher);
                                    invLnItm.Package__c   = lw.selectedPlan;
                                    invLnItm.Invoice__r   = inv;
                                    invLnItm.Enrolment__r = enrl;
                                    invLnItm.Subscription_Line_Item__r = subLItm;
                                    //Added by Rajesh: 25th June 2019, for poulating month on invoice
                                    invLnItm.Month__c     =  Date.parse(lw.lessonSlcdDate);
                                    if(lw.regiFeesDis> 0){
                                        //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                       // invLnItm.Discount_Amount__c = lw.regiFeesDis.setScale(2); 
                                        invLnItm.Discount_Amount__c =  BillingUtility.roundOffAmount(lw.regiFeesDis); 
                                    }
                                    invLineItmList.add(invLnItm);
                                }
                                if(lw.depFees > 0){
                                    String remStr = ConstantsClass.pkgDepFeesDes;
                                    //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
                                    //Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, lw.depFees.setScale(2), remStr, lw.selectedTeacher);
                                    Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null,  BillingUtility.roundOffAmount(lw.depFees), remStr, lw.selectedTeacher);
                                    invLnItm.Package__c  = lw.selectedPlan;
                                    invLnItm.Invoice__r   = inv;
                                    invLnItm.Enrolment__r = enrl;
                                    invLnItm.Subscription_Line_Item__r = subLItm;
                                    invLnItm.Is_Deposit__c = true;
                                    //Added by Rajesh: 25th June 2019, for poulating month on invoice
                                    invLnItm.Month__c     =  Date.parse(lw.lessonSlcdDate);
                                    invLineItmList.add(invLnItm);
                                }
                            }
                        }
                        
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
                                pay.Payment_Amount__c = BillingUtility.roundOffAmount(pay.Payment_Amount__c);
                            }
                                
                            insert cntrPayMap.values(); 
                        }
                        
                        //Insert Payment
                        //pay.Invoice__c =  pay.Invoice__r.Id;
                        //insert pay;
                        
                        if(studentList.size() > 0){
                            upsert studentList;
                            
                            if(enrolmentList.size() > 0){
                                for(Enrolment__c enr : enrolmentList)
                                    enr.Student__c = enr.Student__r.Id; 
                                
                                upsert enrolmentList;
            
                                
                                if(subLinItmList.size() > 0){
                                    for(Subscription_Line_Item__c subsItm: subLinItmList){
                                        subsItm.Subscription__c = subsItm.Subscription__r.Id;
                                        subsItm.Student__c      = subsItm.Student__r.Id;
                                        subsItm.Enrolment__c    = subsItm.Enrolment__r.Id;
                                    }
                                    insert subLinItmList;
                                }
                                
                                if(bookList.size() > 0){
                                    for(Booking__c book:bookList){
                                        book.Student__c = book.Student__r.Id;
                                        book.Enrolment__c = book.Enrolment__r.Id;
                                    }
                                    insert bookList;
                                }
                                
                                if(invLineItmList.size() > 0){
                                    for(Invoice_Line_Item__c invLnItm: invLineItmList){
                                        invLnItm.Invoice__c = invLnItm.Invoice__r.Id;
                                        invLnItm.Enrolment__c = invLnItm.Enrolment__r.Id;
                                        invLnItm.Subscription_Line_Item__c = invLnItm.Subscription_Line_Item__r.Id;
                                    }
                                    
                                    insert invLineItmList;
                                }
                            }
                        }
                     
                        if(base64SignImg!=null && base64SignImg.trim().length()>0 && enrolmentList.size() > 0){
                            List<Attachment> attListForSign = new List<Attachment>();
                            base64SignImg = base64SignImg.replace('data:image/png;base64,','');
                            
                            for(Enrolment__c enr : [SELECT Id,Name,Parent__c FROM Enrolment__c WHERE Id IN:enrolmentList]){
                                Attachment att = new Attachment();
                                att.Name     = enr.Name+'_'+ConstantsClass.defAttSignName;
                                att.parentId = enr.Id;
                                att.body     = EncodingUtil.base64Decode(base64SignImg);
                                attListForSign.add(att);
                                
                                Attachment att1 = new Attachment();
                                att1.Name     = enr.Name+'_'+ConstantsClass.defAttSignName;
                                att1.parentId = enr.Parent__c;
                                att1.body     = EncodingUtil.base64Decode(base64SignImg);
                                attListForSign.add(att1);
                            }
                            if(attListForSign.size() > 0)
                                insert attListForSign;
                        }
                        
                        PageReference pageRef = new PageReference('/apex/Thankyoupage');
                        
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
                        /*
                        String invNumbers = '';
                        for(Invoice__c inv: [SELECT Id,Name FROM Invoice__c WHERE Id IN: invIds]){
                            invNumbers =+ inv.Name + ',';
                        }
                        if(invNumbers.endsWith(','))
                            invNumbers = invNumbers.substring(0, (invNumbers.length()-1));
                        */
                        //Update invoice number on Stripe
                        //BillingUtility.updateCharge(sc.id, invNumbers);
                        return pageRef.setRedirect(true); 
                        //return new pagereference('/apex/Thankyoupage?type=Enrolment&invId='+inv.Id).setRedirect(true); 
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
        }else{
             errorMsg = 'Some problem with your card. Please try again.';
             isError = true;
             return null;
        }
        return null;
        //return new PageReference('/apex/Thankyoupage');
   }
    
   private Static Booking__c fillBook(Account stdnt, LessonWrapper lw, String recTypeId, Enrolment__c enrl, String status, Date bookDate){
        Booking__c book   = new Booking__c(Student__r = stdnt, Teacher_Account__c = lw.selectedTeacher, Enrolment__r = enrl);
        book.RecordTypeId = recTypeId;
        book.Package__c   = lw.selectedPlan;
        book.Center__c    = lw.selectedCenter;
        book.Type__c      = ConstantsClass.bookTypeRegular;
        book.Status__c    = status;     
        book.Booking_Date__c = bookDate;
        if(String.isNotBlank(lw.lessonSlctSlot)){
            List<String> timeList = lw.lessonSlctSlot.split(':');
            
            Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            book.Start_Time__c = startTime;
            if(lw.pkgDuration > 0)
                book.End_Time__c = book.Start_Time__c.addMinutes(lw.pkgDuration);
        }
        
        return book;
   }
    
   public class TimeSlotModelCntrl{
        public List<String>  morningSlot{get;set;}
        public List<String>  afternoonSlot{get;set;}  
        public Boolean isAvlMrgSlot{get;set;}
        public Boolean isAvlAfternoonSlot{get;set;}
        
        public TimeSlotModelCntrl(){
            morningSlot   = new List<String>();
            afternoonSlot = new List<String>();
            isAvlMrgSlot = false;
            isAvlAfternoonSlot = false;
        }
    }
    
    public class AccountWrapper{
        public String firstName{get;set;}
        public String lastName{get;set;}
        public String gender{get;set;}
        public String mobile{get;set;}
        public String Nationality{get;set;}
        public String Phone{get;set;}
        public String Occupation{get;set;}
        public String Email{get;set;}
        public String Address{get;set;}
        public String City{get;set;}
        public String BillingPostalCode{get;set;}
        public String BillingCountryCode{get;set;}
        public String school{get;set;}
        
        String accId;
        public AccountWrapper(){}
        public AccountWrapper(String firstName, String lastName, String gender, String mobile, String Nationality, String Phone, String Occupation, String Email, String Address, String City, String BillingPostalCode, String BillingCountryCode, String school){
            this.firstName = firstName;
            this.lastName  = lastName;
            this.gender    = gender;
            this.mobile    = mobile;
            this.Nationality = Nationality; 
            this.Phone     = Phone;
            this.Occupation= Occupation; 
            this.Email     = Email;
            this.Address   = Address;
            this.City      = City;
            this.BillingPostalCode = BillingPostalCode;
            this.BillingCountryCode = BillingCountryCode;
            this.school    = school;
        } 
    }
    
    public class StudentWrapper{
        public AccountWrapper stuAccWrap{get;set;}
        public Enrolment__c enrBirthdateField{get;set;}
        
        public List<LessonWrapper> lessonList{get;set;}
        //Account student;
        public StudentWrapper(){
            stuAccWrap   = new AccountWrapper();
            enrBirthdateField = new Enrolment__c();
            
            lessonList = new List<LessonWrapper>();
        }
    }
    
    public class LessonWrapper{
        public String selectedCenter{get;set;}
        public String selectedPlan{get;set;}
        public String selectedTeacher{get;set;}
        public String lessonSlcdDate{get;set;}
        public String lessonSlctSlot{get;set;}
        public String lessonSlctSlotT{get;set;}
        public Date   lessonSlcdDateD{get;set;}
        
        public String selectedCenterName{get;set;}
        public String selectedPlanName{get;set;}
        public String selectedTeacherName{get;set;}
        
        public List<SelectOption> centerOptions{get;set;}
        public List<SelectOption> planOptions{get;set;}
        public List<SelectOption> teacherOptions{get;set;}
        
        //Fee calculation variables
        public Decimal selPckMonthFees{get;set;}
        public Decimal depFees{get;set;}
        public Decimal prgFees{get;set;}
        public Decimal pkgFeesPromtnalDis{get;set;}
        public Decimal regiFees{get;set;}
        public Decimal regiFeesDis{get;set;}
        public Decimal totAmt{get;set;}
        public Decimal gstAmt{get;set;}
        
        Integer  pkgDuration;
        Integer  proNoOfLess;
        String   pkgAftPro;
        String   slcdPakgPrgBillingType;
        String   slcdPakgPrgScdlType;
        String   enrId;
        Integer  prmtnalPkgInMonth;
        //Added by Rajesh: 3rd aug 2018, To populate instrumet in person account assign by prashant
        String   instrument;
        
        //Used for Aureus at Home
        Integer cntrTravHour;
        public LessonWrapper(){
            centerOptions = new List<SelectOption>();
            planOptions = new List<SelectOption>();
            teacherOptions = new List<SelectOption>();
            
            centerOptions.add(new SelectOption('', '--None--'));
            planOptions.add(new SelectOption('', '--None--'));
            teacherOptions.add(new SelectOption('', '--None--'));
            
            lessonSlcdDate = System.today().day()+'/'+System.today().month()+'/'+System.today().year() ;
            lessonSlcdDateD = System.today();
            //---------Fee intialisation
            selPckMonthFees = depFees = prgFees = regiFees = totAmt = gstAmt = regiFeesDis = pkgFeesPromtnalDis = prmtnalPkgInMonth = pkgDuration = proNoOfLess = 0;
        }
    }
    
    public class GrandTotalWrapper{
        public Decimal disTot{get;set;}
        public Decimal feesTot{get;set;}
        public Decimal gstTot{get;set;}
        public Decimal subsTot{get;set;}
        public Decimal depositTot{get;set;}
        public Decimal grandTot{get;set;}
        
        public GrandTotalWrapper(){
            disTot = feesTot = gstTot = subsTot =depositTot = grandTot = 0;
        }
    }
}