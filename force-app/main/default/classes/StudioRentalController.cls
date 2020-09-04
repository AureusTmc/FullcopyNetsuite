public class StudioRentalController {
    public String slcdCenter{get;set;}
    public String selectedCenterName{get;set;}
    public String slcdResType{get;set;}
    public String slcdStudio{get;set;}
    public String slcdDuration{get;set;}
    public String slcdSlot{get;set;}
    public String slcdSlotT{get;set;}
    public String mapAddress{get;set;}
    public String slcdDate{get;set;}
    public Date   slcdDateD{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    public Map<String,String> studioTypeMap{get;set;}
    public String tSlotStr{get;set;}
    
    public Account parentAcc{get;set;}
    
    public Boolean iWantReceivedLatestNew{get;set;}
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    
    public String  slcdCenterName{get;set;}
    public Decimal pckFee{get;set;}
    public Decimal gstAmount{get;set;}
    public Decimal totAmount{get;set;}
    //public string  base64SignImg{get;set;}
    
    public String apiKey {get;set;}
    public string stripeToken{get;set;}
    public string PersonMobilePhoneCustom{get;set;}  
    
    //Added by Rajesh, 19th Aug 2019. Add country for filter centres
    String countryCode;
    Resource__c avlResWithPack;   
    
    //Added by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
    String stripeBaseUrl;
    String stripeApiSecKey;
    String countryCurrencyCode;
    Integer gstTaxPer;
    public StudioRentalController(){
        PersonMobilePhoneCustom = '';
        //Commented by Rajesh: 9th sept 2019, to populate address according to country parameter
       // mapAddress = ConstantsClass.mapDefAdd;
        tSlotStr   = '';
        slcdCenter = '';
        slcdDate   = System.today().day()+'/'+System.today().month()+'/'+System.today().year() ;
        tSlotMap   = new TimeSlotModelCntrl();
        parentAcc  = new Account();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        studioTypeMap = new map<String,String>();
        avlResWithPack = new Resource__c(); 
        
        String recId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        parentAcc.RecordTypeId = recId;
        isError = false;
        errorMsg = '';
        slcdDuration = '60';
        
        //Added by Rajesh, 19th Aug 2019. Add country for filter centres
        countryCode	 = ApexPages.currentPage().getParameters().get('country');
        if(String.isBlank(countryCode))
            countryCode = 'SG';
        
        //Added by Rajesh: 9th sept 2019, to populate address according to country parameter
        mapAddress = countryCode.endsWithIgnoreCase('HK') ? ConstantsClass.mapDefAddHK : ConstantsClass.mapDefAdd;
        
        //Commented by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
       /* List<Stripe_Settings__mdt> stripeSettings = [SELECT Id, Stripe_Base_Url__c, Stripe_Secret_Key__c, Stripe_Publishable_Key__c 
                                                     FROM   Stripe_Settings__mdt 
                                                     WHERE  DeveloperName =: ConstantsClass.cstmMetaDataStripe LIMIT 1];
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
    
    public list<SelectOption> getCenters(){
        list<SelectOption> options = new list<SelectOption>();
        
        String cenRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        
        options.add(new SelectOption('','Please select')); 
        //updated by Rajesh, 19th Aug 2019. updated soql To package centre bases of the country
        //Updated by Rajesh, 20th Aug 2019. Updated soql to filter centres on the bases of centre status
        for(Account acc: [SELECT Id, Name, CentreName_Cust__c,
                                (SELECT Id,Name,Type__c FROM Resources1__r 
                                        WHERE Status__c =: ConstantsClass.resourceStatusAvailable 
                                        AND Type__c != null AND Capacity__c != null LIMIT 1) 
                          FROM Account WHERE RecordtypeId =: cenRecId AND Centre_Status__c =:ConstantsClass.activeStatus AND Country__r.Name =:countryCode]){
            if(acc.Resources1__r.size() > 0)
                options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
        }
        
        return options;
    }
    public List<String> getResourceType(){
        List<String> resTypeList = new List<String>();
       
        if(String.isNotBlank(slcdCenter)){
            List<Resource__c> resList = [SELECT Id,Name,Type__c,Center__r.Name,Center__r.CentreName_Cust__c 
                                         FROM Resource__c 
                                         WHERE Center__c =:slcdCenter AND Status__c =: ConstantsClass.resourceStatusAvailable 
                                               AND Type__c != null AND Capacity__c != null ORDER BY Type__c];
            for(Resource__c res: resList){
                if(!resTypeList.contains(res.Type__c))
                    resTypeList.add(res.Type__c);
            }
            
            selectedCenterName = resList.size() > 0 ? resList.get(0).Center__r.CentreName_Cust__c : '';
        }
        fetchStudios();
        return resTypeList;
    }
    
    public List<String> getDuration(){
        List<String> durationList = new List<String>();
        durationList.add('60'); 
        durationList.add('90'); 
        durationList.add('120'); 
        durationList.add('150');
        
        return durationList;
    }
    
    public void fetchStudios(){
        studioTypeMap = new map<String,String>();
        
        if(String.isNotBlank(slcdResType) && slcdResType != ConstantsClass.standardResourceType){
            for(Resource__c res: [SELECT Id, Name, Type__c, Studio_Id__c 
                                  FROM Resource__c 
                                  WHERE Center__c =:slcdCenter 
                                  AND Status__c =: ConstantsClass.resourceStatusAvailable
                                 AND Available_For_Aureus_Lesson__c =true  // Nishi: 5-Aug-2020: Show resources which Available_For_Aureus_Lesson__c field value is true
                                 AND Type__c =:slcdResType  AND Capacity__c != null AND Studio_Id__c != null]){
                studioTypeMap.put(res.Id,res.Studio_Id__c); 
            }
        }
    }
    
    public Boolean getStudioMapIsEmpty(){
        return studioTypeMap.size() == 0;
    }
    
    public String getAddr(){
        String address = '';
        
        if(String.isNotBlank(slcdCenter)){
            List<Account> accList = [SELECT Id, BillingStreet, BillingPostalCode, BillingCity, BillingState, BillingCountry 
                                     FROM Account WHERE Id =: slcdCenter ];
            
            if(accList.size() > 0){
                Account ac = accList.get(0);
                String add =  String.isNotBlank(ac.BillingStreet) ? ac.BillingStreet     + ' ':'';
                add += String.isNotBlank(ac.BillingCity)          ? ac.BillingCity       + ' ':'';
                add += String.isNotBlank(ac.BillingState)         ? ac.BillingState      + ' ':'';
                add += String.isNotBlank(ac.BillingPostalCode)    ? ac.BillingPostalCode + ' ':'';
                add += String.isNotBlank(ac.BillingCountry)       ? ac.BillingCountry    + ' ':''; 
                
                address = add;  
                mapAddress = address; 
            }
        }
        
        return address;
    }
    public void fetchTimeSlot(){
        slcdDateD = date.Parse(slcdDate);
        
        List<Resource_Working_Hour__c> resWorkSchList = new List<Resource_Working_Hour__c>();
        if(slcdResType == ConstantsClass.standardResourceType){
            resWorkSchList =    [SELECT Id, Name, Center_Name__c, Center_Name__r.Name, Working_Day__c, Start_Time__c,
                                 End_Time__c, Active__c
                                 FROM  Resource_Working_Hour__c 
                                 WHERE Resource_Name__r.Type__c =: ConstantsClass.standardResourceType AND 
                                       Center_Name__c =: slcdCenter AND Active__c = true AND Working_Day__c != null];
        }else{
            resWorkSchList =    [SELECT Id, Name, Center_Name__c, Center_Name__r.Name, Working_Day__c, Start_Time__c,
                                 End_Time__c, Active__c
                                 FROM  Resource_Working_Hour__c 
                                 WHERE Center_Name__c =: slcdCenter AND Resource_Name__c =:slcdStudio AND 
                                       Active__c = true AND Working_Day__c != null];
            
        }

        Map<String,List<Resource_Working_Hour__c>> resWorkSchMap = new Map<String,List<Resource_Working_Hour__c>>();
        
        slcdCenterName = resWorkSchList.size() > 0 ? resWorkSchList.get(0).Center_Name__r.Name : '';
        for(Resource_Working_Hour__c cenWrkSch: resWorkSchList){                                                               
            List<Resource_Working_Hour__c> cenList = resWorkSchMap.get(cenWrkSch.Working_Day__c);
            if(cenList == null)
                cenList = new List<Resource_Working_Hour__c>();
            
            cenList.add(cenWrkSch);                                                  
            resWorkSchMap.put(cenWrkSch.Working_Day__c, cenList);   
        }
      
        Map<String,Time> bookMap  = new Map<String,Time>();
        Set<String> bookSet       = new Set<String>();
        List<Resource__c> resList = new List<Resource__c>();
        Date startDt = System.today();
        Date endDt = startDt.addMonths(1);
        
        Integer durationInMinutes = Integer.valueOf(slcdDuration);
        //Added by Rajesh, 9th July 2019, for solve duplicate issue.(due 15 minutes and 45 minutes)                    
        Integer tempMintsDiff = durationInMinutes-ConstantsClass.defMinutes;
        
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled'};
        Set<String> resCtgrySet  = new Set<String>{'Teacher recital', 'Aureus student', 'Conservatory', 'Others'};
        if(slcdResType == ConstantsClass.standardResourceType){
            for(Booking__c book : [SELECT Id, Name, Booking_Date__c, Duration__c, Start_Time__c, End_Time__c, Type__c, Resource__c 
                                   FROM Booking__c 
                                   WHERE Resource__r.Center__c =:slcdCenter AND Start_Time__c != null
                                         AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt) AND Status__c IN: bookStatusSet
                                         AND (Type__c =: ConstantsClass.studioBookingType OR (Type__c =: ConstantsClass.busyBookingType  AND Resource_Category__c IN:resCtgrySet))]){
                
                // Time temStartTime = book.Start_Time__c;                              
                //Updated by Rajesh, 9th July 2019, for solve duplicate issue.(due 15 minutes and 45 minutes)                               
                Time temStartTime = book.Start_Time__c.addMinutes(-tempMintsDiff);
               
                while(temStartTime < book.End_Time__c){
                    String key = book.Resource__c +':'+ book.Booking_Date__c +':'+ temStartTime;
                    bookMap.put(key, book.End_Time__c);   
                    
                    //temStartTime = temStartTime.addMinutes(30);
                    //Updated by Rajesh, 9th July 2019, for solve duplicate issue.(due 15 minutes and 45 minutes) 
                    temStartTime = temStartTime.addMinutes(ConstantsClass.defMinutes);
                }
            }
            
            resList = [SELECT Id FROM Resource__c WHERE Center__c =: slcdCenter];
        }else{
            List<Booking__c> resBookList = [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Resource__c,Resource__r.Name 
                                           FROM Booking__c 
                                           WHERE Resource__r.Center__c =:slcdCenter AND Resource__c =:slcdStudio AND Start_Time__c != null
                                           AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt) AND Status__c IN: bookStatusSet 
                                           AND (Type__c =: ConstantsClass.studioBookingType OR (Type__c =:ConstantsClass.busyBookingType AND Resource_Category__c IN:resCtgrySet))];
            
            if(resBookList.size() > 0){
                for(Booking__c book : resBookList){
                    String key = book.Resource__c +':'+ book.Booking_Date__c + ':' + book.Start_Time__c;
                    bookMap.put(key, book.End_Time__c);
                    
                    //Updated by Rajesh, 9th July 2019, for solve duplicate issue.(due 15 minutes and 45 minutes)
                    Time temStartTime = book.Start_Time__c.addMinutes(-tempMintsDiff); 
                    Time endTempT     = book.End_Time__c;//.addMinutes(duraHalfInMinutes);
                    while(temStartTime < endTempT){
                        key = book.Resource__c +':'+ book.Booking_Date__c +':'+ temStartTime;
                        bookSet.add(key);
                        
                        temStartTime = temStartTime.addMinutes(ConstantsClass.defMinutes);
                    } 
                    /*
                    Integer tempDurationInMinutes = durationInMinutes-30;
                    //duraHalfInMinutes = math.mod(duraHalfInMinutes, 30) == 0 ? duraHalfInMinutes : (duraHalfInMinutes +15);
                        
                    Time temStartTime = book.Start_Time__c.addMinutes(-tempDurationInMinutes); 
                    Time endTempT     = book.End_Time__c;//.addMinutes(duraHalfInMinutes);
                    while(temStartTime < endTempT){
                        key = book.Resource__c +':'+ book.Booking_Date__c +':'+ temStartTime;
                        bookSet.add(key);
                        
                        temStartTime = temStartTime.addMinutes(30);
                    }*/
                }
            
                //resList.add(new Resource__c(Id = resBookList.get(0).Resource__c, Name = resBookList.get(0).Resource__r.Name));
            }
            resList.add(new Resource__c(Id = slcdStudio));
        }
        
        for(Date st=startDt; st<=endDt; st=st.addDays(1)){
            TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
            
            Set<Time> morningTimesTemp      = new Set<Time>();
            Set<Time> afternoonTimesTemp    = new Set<Time>();
            
            String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
            
            if(resWorkSchMap.containsKey(currDay)){
                for(Resource_Working_Hour__c resWorkSch: resWorkSchMap.get(currDay)){
                    for(Resource__c res: resList){
                        //Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                        //currTime = currTime.addHours(4); 
                        DateTime tempTodayTime = System.now().addHours(4);
                        
                        //fetching for First Shift
                        if(resWorkSch.Start_Time__c != null && resWorkSch.End_Time__c != null){
                            Time stTime = resWorkSch.Start_Time__c;                            
                            DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                            
                           //Updated by Rajesh, 9th July 2019, for solve duplicate issue.(due 15 minutes and 45 minutes)
                            while(stTime < resWorkSch.End_Time__c.addMinutes(-(tempMintsDiff))){
                               if((!(morningTimesTemp.contains(stTime) || afternoonTimesTemp.contains(stTime))) && (tempStDtTime > tempTodayTime)){
                                    String key = res.Id + ':'+ st + ':'+ stTime;
                                    
                                    if(bookMap.containsKey(key)){
                                        stTime = bookMap.get(key);
                                    }else{
                                        if(stTime.hour() < 12){
                                            if(!(bookSet.contains(key)) && stTime.addMinutes(durationInMinutes) < resWorkSch.End_Time__c){    
                                                morningTimesTemp.add(stTime);
                                            }
                                            stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                        }else{
                                            if(!(bookSet.contains(key)))
                                                afternoonTimesTemp.add(stTime);
                                            
                                            stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                        }
                                    }
                                }else{
                                    stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                }
                            }
                            /*
                             //while(stTime < cenWorkSch.End_Time_1st_Shift__c.addMinutes(-30)){
                                while(stTime <= resWorkSch.End_Time__c.addMinutes(-(durationInMinutes))){
                                   // if((!(morningTimesTemp.contains(stTime) || afternoonTimesTemp.contains(stTime))) && (st > System.today() || (st == System.today() &&  stTime > currTime))){
                                    if((!(morningTimesTemp.contains(stTime) || afternoonTimesTemp.contains(stTime))) && (tempStDtTime > tempTodayTime)){
                                        String key = res.Id + ':'+ st + ':'+ stTime;
                                        
                                        if(bookMap.containsKey(key)){
                                            stTime = bookMap.get(key);
                                        }else{
                                            if(stTime.hour() < 12){
                                                //if(stTime.addMinutes(30) < cenWorkSch.End_Time_1st_Shift__c){
                                                if(!(bookSet.contains(key)) && stTime.addMinutes(durationInMinutes) < resWorkSch.End_Time__c){    
                                                    morningTimesTemp.add(stTime);
                                                }
                                                stTime = stTime.addMinutes(30);
                                            }else{
                                                if(!(bookSet.contains(key)))
                                                    afternoonTimesTemp.add(stTime);
                                                
                                                stTime = stTime.addMinutes(30);
                                            }
                                        }
                                    }else{
                                        stTime = stTime.addMinutes(30);
                                    }
                                }
                             */
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
            
            if(slcdDate != null){
                if(st == date.Parse(slcdDate)){
                    tSlotMapTemp.morningSlot   = mrgSlotList;
                    tSlotMapTemp.afternoonSlot = aftSlotList;
                    //tSlotMapTemp.teachModList = accTcrMap.values();  
                }
            }
            
            if(mrgSlotList.size() > 0)
                tSlotMapTemp.isAvlMrgSlot = true;
            if(aftSlotList.size() > 0)
                tSlotMapTemp.isAvlAfternoonSlot = true;
            
            tSlotDateMap.put(st.day()+'/'+st.month()+'/'+st.year() , tSlotMapTemp);
        }
        
        tSlotStr = JSON.serialize(tSlotDateMap);
        tSlotMap = tSlotDateMap.get(slcdDate);
    }
    
    public void fetchTimeSlotBasesOfDuration(){
        slcdDate   = System.today().day()+'/'+System.today().month()+'/'+System.today().year();
        slcdDateD = date.Parse(slcdDate);
        
        fetchTimeSlot();
    }
    
    public void cacluateTotal(){
        if(String.isNotBlank(slcdSlot)){
            List<String> timeList = slcdSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            slcdSlotT = DateTime.newInstance(System.today(), tempT).format('hh:mm a');
        }    
        
        Integer durationInMinutes = Integer.valueOf(slcdDuration);
        if(slcdResType == ConstantsClass.standardResourceType){
            Set<String> resBookMapSet = new Set<String>();            
            Date slcdDt = date.Parse(slcdDate);
            List<String> timeList = slcdSlot.split(':');
            
            Time tempStTime  = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            Time tempEndTime = tempStTime.addMinutes(durationInMinutes);
            
            tempStTime  = tempStTime.addMinutes(-(durationInMinutes/2));
            tempEndTime = tempEndTime.addMinutes((durationInMinutes/2));
            
            for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Resource__c 
                                   FROM Booking__c 
                                   WHERE Resource__r.Center__c =:slcdCenter AND Booking_Date__c =: slcdDt AND 
                                   Resource__r.Type__c =: ConstantsClass.standardResourceType AND Start_Time__c >=:tempStTime AND  End_Time__c <=: tempEndTime]){
                resBookMapSet.add(book.Resource__c);   
            }
            
            avlResWithPack = new Resource__c(); 
            
            for(Resource__c rePack : [SELECT Id, Name, Package__c, Package__r.Package_Fee__c
                                      FROM Resource__c
                                      WHERE Center__c =: slcdCenter AND Package__r.Active__c = True AND Status__c =: ConstantsClass.resourceStatusAvailable AND
                                      Type__c =: ConstantsClass.standardResourceType AND Capacity__c != null AND Package__r.Package_Fee__c != null]){
                if(!resBookMapSet.contains(rePack.Id)){
                    avlResWithPack = rePack;
                    break;
                }               
            }
            
        }else{
            for(Resource__c rePack : [SELECT Id, Name, Package__c, Package__r.Package_Fee__c
                                      FROM  Resource__c 
                                      WHERE Package__r.Active__c = True AND Id =: slcdStudio AND 
                                            Status__c =: ConstantsClass.resourceStatusAvailable AND 
                                            Package__r.Package_Fee__c != null LIMIT 1]){
                 avlResWithPack  = rePack;
            }
        }
        
        if(avlResWithPack.Id != null){
            /*Integer gstTaxPer = ConstantsClass.defGST;
            try{
                gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
            }catch(Exception e){}
            */
            Decimal  duraInHours = durationInMinutes / 60.0;
            //Updated by Rajesh: 11th Sept 2019. To solve rounding issue
           /* pckFee    = (avlResWithPack.Package__r.Package_Fee__c * duraInHours).setScale(2);
            gstAmount = (pckFee > 0 ? ((pckFee * gstTaxPer) / 100):0).setScale(2);
            totAmount = (pckFee + gstAmount).setScale(2);*/
            pckFee    = BillingUtility.roundOffAmount(avlResWithPack.Package__r.Package_Fee__c * duraInHours);
            gstAmount = BillingUtility.roundOffAmount(pckFee > 0 ? ((pckFee * gstTaxPer) / 100):0);
            totAmount = BillingUtility.roundOffAmount(pckFee + gstAmount);
        }else{
            pckFee    = 0;
            gstAmount = 0;
            totAmount = 0;
        }
    }
    
    public pagereference saveData(){
        Savepoint sp;
        isError = false;
        errorMsg = '';
        //Added by Prabhat (18-06-2019)
        EnrollmentProcessErrorLogs.errorLogObj errorObj = new EnrollmentProcessErrorLogs.errorLogObj();
        
        if(stripeToken!=null && stripeToken.trim().length()>0){
            if(String.isNotBlank(slcdDate) && String.isNotBlank(slcdSlot)){ 
                           
                Date slcdDt = date.Parse(slcdDate);
                List<String> timeList = slcdSlot.split(':');
                 
                Time tempStTime  = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                if(avlResWithPack.Id != null){
                    try{
                        Decimal amountInSmallUnit = totAmount;
                        //Updated by Rajesh 9th Sept 2019, for get stripe infromation bases of the country
                        //BillingUtility.stripeCharge sc = BillingUtility.createOneTimeCharge(stripeToken,amountInSmallUnit,'sgd');
                        BillingUtility.stripeCharge sc = BillingUtility.createOneTimeCharge(stripeToken,amountInSmallUnit,countryCurrencyCode, stripeBaseUrl, stripeApiSecKey);
                        system.debug('sc>>>'+sc);
                        if(sc.statusCode == 200 && sc.paid){
                            sp = database.setsavepoint();
                            
                             //Added By Prabhat(18-06-2019) to create error logs if exception occurs
                            //Below mapping will also be used to refund the amount back to the customer.
                            errorObj.stripeTransactionId = sc.id;
                            errorObj.stripeChargeAmount  = sc.amount;
                            errorObj.baseUrl = stripeBaseUrl;
                       	    errorObj.apiKey  = stripeApiSecKey;
                            
                            //Check that customer is already exist or not on the bases of email
                            if(parentAcc.PersonEmail != null){
                                List<Account> accList = [SELECT Id,Name FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
                                if(accList.size() > 0)
                                    parentAcc.Id = accList.get(0).Id;
                            }  
                            
                             //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                            parentAcc.Centre_Name__c = slcdCenter;
                            List<Account> centrList  = [SELECT Id, Name, Location__c, Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
                            if(centrList.size() > 0){
                                parentAcc.Location__c = centrList.get(0).Location__c;
                                if(centrList.get(0).Country__r.Country_Name__c != null)
                                    parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                            }
                            
                            parentAcc.PersonMobilePhone = PersonMobilePhoneCustom;
                            parentAcc.Phone = PersonMobilePhoneCustom;                 
                            upsert parentAcc;
                            
                            //Added By Prabhat(18-06-2019) to create error logs if exception occurs
                            //Below mapping will also be used to refund the amount back to the customer.
                            errorObj.customerSalesforceId = parentAcc.Id;
                            
                            //Filling Invoice
                            Invoice__c inv        = new Invoice__c();
                            inv.Parent_Account__c = parentAcc.Id;
                            inv.Status__c         = ConstantsClass.paidStatus;
                            inv.Invoice_Date__c   = System.today();
                            inv.Center__c         = slcdCenter; 
                             //Added by Rajesh 30th July 2019, to fill studio in 'invoice type'
                            inv.invoice_type__c   = 'Studio Booking';
                            inv.Due_Date__c       = inv.Invoice_Date__c.addDays(ConstantsClass.addInvoiceDueDays);
                            insert inv;
                            
                            Invoice_Line_Item__c invLneItm = new Invoice_Line_Item__c();
                            invLneItm.Package__c = avlResWithPack.Package__c;
                            invLneItm.Invoice__c = inv.Id;
                            invLneItm.Amount__c  = pckFee;
                            //Updated by Rajesh 27th June 2019, need to put date and time of the booking as per julius request
                            //invLneItm.Remarks__c = 'Studio Rental fees';
                            invLneItm.Remarks__c = avlResWithPack.Name+'_'+slcdDate+'_'+slcdSlot;
                            //Added by Rajesh 15th July 2019, Need to put selected date in Month field, As per Ashish discussion
                            invLneItm.Month__c   = date.Parse(slcdDate);
                            //Added by Rajesh on 22nd oct 2019. Individual gst amount for the line item
                            invLneItm.GST_Amount__c = gstAmount;
                            insert invLneItm;
                            
                            //Filling Payment
                            //Added By Rajesh: 1 July 2019, Set Payment Transaction recordtype on payment object
                            //Added By Rajesh: 20th Aug 2019, Set Method of payment as a Card on payment object
                            String payTrnRecId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
                            Payment__c pay  = new Payment__c(RecordTypeId	  = payTrnRecId, Method_of_Payment__c = 'Card');
                            pay.Invoice__c        = inv.Id;
                            pay.Payment_Date__c   = System.today(); 
                            pay.Parent_Account__c = parentAcc.Id;
                            pay.Payment_Amount__c = totAmount;
                            pay.Payment_Status__c = ConstantsClass.successStatus;
                            pay.Transaction_ID__c = sc.id;
                            insert pay;
                            
                            Integer durationInMinutes = Integer.valueOf(slcdDuration);
                            String recId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeFacility).getRecordTypeId();
                            Booking__c book  = new Booking__c();
                            book.RecordTypeId= recId;
                            book.Resource__c = avlResWithPack.Id;
                            book.Package__c  = avlResWithPack.Package__c;
                            book.Type__c     = ConstantsClass.studioBookingType;
                            book.Student__c  = parentAcc.Id;
                            book.Parent__c   = parentAcc.Id;
                            book.Center__c   = slcdCenter;
                            book.Status__c   = ConstantsClass.scheduledStatus;      
                            book.Booking_Date__c = date.Parse(slcdDate);
                            book.Start_Time__c = tempStTime;
                            book.End_Time__c = book.Start_Time__c.addMinutes(durationInMinutes);
                            book.Studio_Booking_Invoice_Number__c = inv.Id;
                            insert book;
                            /*
                            if(base64SignImg!=null && base64SignImg.trim().length()>0){
                                base64SignImg = base64SignImg.replace('data:image/png;base64,','');
                                Attachment att = new Attachment();
                                att.Name     = ConstantsClass.defAttSignName;
                                att.parentId = book.Id;
                                att.body     = EncodingUtil.base64Decode(base64SignImg);
                                insert att;
                            }*/
                            //return new pagereference('/apex/trialthankyou').setRedirect(true);      
                            
                            //Update invoice number on Stripe
                            /*List<Invoice__c> invList = [SELECT Id,Name FROM Invoice__c WHERE Id =: inv.Id];
                            if(invList.size() > 0)
                                BillingUtility.updateCharge(sc.id, invList.get(0).Name);              
                            */
                            
                            SageIntacctIntegrationUtility.newStudioRental(parentAcc.Id,inv.Id,pay.Id);
                            
                            return new pagereference('/apex/Thankyoupage?type=Studio&invId='+inv.Id+'&bookId='+book.Id+'&scId='+sc.id).setRedirect(true);                    
                        }else{
                            errorMsg = sc.error.message;
                            isError = true;
                            
                            //Added by Rajesh, 30th Sept 2019. showing custom error messagge if card decliend
                            if(String.isNotBlank(sc.error.decline_code))
                                errorMsg= 'Payment Failed. Please try with a different card.';
                        }
                    }catch(Exception e){
                        Database.rollback(sp);
                        System.debug('Error:  '+e.getMessage());
                        errorMsg = e.getMessage();
                        isError = true;
                        
                        //Create error log and refund amount
                        errorObj.exceptionMessage = errorMsg;
                        String jsonObj = JSON.serialize(errorObj);
                        EnrollmentProcessErrorLogs.generateErrorLogsAndRefundAmount(jsonObj);
                
                    }
                }else{
                    errorMsg = 'Resource is not available with Package.';
                    isError = true;
                }
            }else{
                errorMsg = 'Please select date or time on calendar screen.';
                isError = true;
            }
        }else{
            errorMsg = 'Some problem with your card. Please try again.';
            isError = true;
        }
        return null;
        //return new pagereference('/apex/trialthankyou').setRedirect(true);
    }
    
    public class TimeSlotModelCntrl{
        public List<String>  morningSlot{get;set;}
        public List<String>  afternoonSlot{get;set;}
        
        public Boolean isAvlMrgSlot{get;set;}
        public Boolean isAvlAfternoonSlot{get;set;}
        
        String resId;
        public TimeSlotModelCntrl(){
            morningSlot   = new List<String>();
            afternoonSlot = new List<String>();
            isAvlMrgSlot = false;
            isAvlAfternoonSlot = false;
        }
    }
    
}