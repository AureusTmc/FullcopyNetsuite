public class InstrumentRental_IpadCntrl{
	public String slcdCenter{get;set;}
    public String slcdCentrName{get;set;}
    public String slcdNoOfStudent{get;set;}
   // public Map<String,String> disabledInstrument{get;set;}
    /*
    public Account      parentAcc{get;set;}
    public Account      studentAcc{get;set;}
    */
    //public Boolean isNextWithoutError{get;set;}
    
    //Variables according to ipad page
   // public List<String> instrumentList{get;set;}
    public List<TrialEnrModel> enrModelList{get;set;}
    public String countryCode{get;set;}
    
    public Integer slcdStuIndex{get;set;}
  //  public String  slcdInstrument{get;set;}
    public Integer slcdDuration{get;set;}
    public String  slcdDate{get;set;}
    public String  slcdSlot{get;set;}
    public String  slcdTchrId{get;set;}
    
    public Account parentAcc{get;set;}
    public Boolean isParAlsoAStudent{get;set;}
    
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    public Boolean iWantReceivedLatestNew{get;set;}
    public String  slcdExistingStu{get;set;}
    public Boolean isSiteGuestUser{get;set;}
    public string PersonMobilePhoneCustom{get;set;}  
    public string slcdParId{get;set;}  
    Boolean isAureusAtHome;
    Integer trvlDuration;
    String formName;
    
    //Added by Rajesh, 6th Aug 2019. To store trial source on case object and country for filtercentre
    String trialSource;
    public InstrumentRental_IpadCntrl(){
        enrModelList = new List<TrialEnrModel>(); 
        parentAcc = new Account();
        isAureusAtHome = false;
        isParAlsoAStudent = false;
        iWantReceivedLatestNew = false;
        isSiteGuestUser = (UserInfo.getName()).contains('Site');
        PersonMobilePhoneCustom = '';
        //isNextWithoutError = false;
        
       /* countryCode	 = ApexPages.currentPage().getParameters().get('country');
        if(String.isBlank(countryCode))
            countryCode = 'SG';
        */
        enrModelList.add(new TrialEnrModel());
        
        List<Centre_Users__c> cenUsrLst = [select Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.Country__c,Centre_Name__r.Country__r.Name, Centre_Name__r.Country__r.Country_Name__c
                               				from Centre_Users__c where User_Name__c=:UserInfo.getUserId()];
        if(cenUsrLst.size() > 0){
            slcdCenter= cenUsrLst.get(0).Centre_Name__c;
            countryCode = cenUsrLst.get(0).Centre_Name__r.Country__r.Name;
        }
        
        if(String.isBlank(countryCode))
             countryCode = 'SG';
        
        String cntryCodeForSiteUser = ApexPages.currentPage().getParameters().get('country');   
        if(isSiteGuestUser && String.isNotBlank(cntryCodeForSiteUser))
        	countryCode	 = cntryCodeForSiteUser;    
        
        slcdStuIndex = 1;
        fetchInstrument();
        
        TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
       // trialEnrMod.slcdInstrument = 'Piano';
        trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
        trialEnrMod.timeSlotStrMap = new Map<Date, String>();
        fetchTimeSlot(trialEnrMod);
    }
    public list<SelectOption> getCenters(){
        list<SelectOption> options = new list<SelectOption>();
        
        String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        options.add(new SelectOption('','Select Centre')); 
        
        //updated by Rajesh, 7th Aug 2019. updated soql To package centre bases of the country
        //Updated by Rajesh, 13th Aug 2019. Updated soql to remove hardcoded centre and filter centres on the bases of centre status
        for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                          WHERE Piano_Viewing_Available__c = True AND RecordtypeId =: cenRecId AND Centre_Status__c =:ConstantsClass.activeStatus AND Country__r.Name =:countryCode ORDER BY CentreName_Cust__c]){
            options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
        }
        
        return options;
    }
    
    public void fetchInstrument(){
       // instrumentList = new List<String>();
        //disabledInstrument = new Map<String,String>();
        /*
        Set<String> instrumentTempSet = new Set<String>();
        if(String.isNotBlank(slcdCenter)){  
            checkAtHome();
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,
                                                                    End_Time__c,Active__c,Center_Name__c,Center_Name__r.Name,Teacher_Name__r.Major_Instruments_Disciplines__c 
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                                   Teacher_Name__r.Major_Instruments_Disciplines__c != null AND Center_Name__r.Country__r.Name =:countryCode];
            //Filling active Instruments for the selected Center
            for(Teacher_Working_Hour__c teachTemp: techWorkSchList){
                if(teachTemp.Center_Name__c == slcdCenter) {
                    slcdCentrName = teachTemp.Center_Name__r.Name;
                    for(String strIns : teachTemp.Teacher_Name__r.Major_Instruments_Disciplines__c.split(';'))
                        instrumentTempSet.add(strIns); 
                }
            }
            
            if(!isAureusAtHome){
                //Filling disabled Instruments for the selected Center
                for(Teacher_Working_Hour__c teachTemp: techWorkSchList){
                    if(teachTemp.Center_Name__c != slcdCenter){
                        for(String strIns : teachTemp.Teacher_Name__r.Major_Instruments_Disciplines__c.split(';')){
                            
                            if(!instrumentTempSet.contains(strIns)){
                                String centNames =  disabledInstrument.containsKey(strIns) ? disabledInstrument.get(strIns) : teachTemp.Center_Name__r.Name;
                            
                                if(!(centNames.contains(teachTemp.Center_Name__r.Name)))
                                    centNames += ', '+teachTemp.Center_Name__r.Name;
                                
                                disabledInstrument.put(strIns, centNames);  
                            }   
                        }   
                    }
                }
            }
        }
        
        instrumentList.addAll(instrumentTempSet);
        instrumentList.sort();*/
        
       // Set<String> instrumentTempSet = new Set<String>();
        if(String.isNotBlank(slcdCenter)){
            Set<String> salesTeamList = new Set<String>();
            salesTeamList.add('Sales Executive');
            salesTeamList.add('Sales and Operations Executive');
            salesTeamList.add('Sales Manager');
                
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,
                                                                    End_Time__c,Active__c,Center_Name__c,Center_Name__r.Name,Teacher_Name__r.Major_Instruments_Disciplines__c 
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND Center_Name__c =: slcdCenter AND
                                                                   Teacher_Name__r.Job_Title__c IN:salesTeamList AND Center_Name__r.Country__r.Name =:countryCode];
            if(techWorkSchList.size() > 0){
               // instrumentTempSet.add('Piano');
                slcdCentrName = techWorkSchList.get(0).Center_Name__r.Name;
            }
            //Filling active Instruments for the selected Center
        }
        
        //instrumentList.addAll(instrumentTempSet);
        
        TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
        trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
        trialEnrMod.timeSlotStrMap = new Map<Date, String>();
        if(String.isNotBlank(slcdCenter))
        	fetchTimeSlot(trialEnrMod);
    }
    
    public void checkAtHome(){
        if(String.isNotBlank(slcdCenter))
            isAureusAtHome = (slcdCenter == Label.Aureus_at_Home_Id ? true : false);
        else
            isAureusAtHome = false;
        
        if(isAureusAtHome){
            for(Account acc: [SELECT Id,Name,CentreName_Cust__c,Travel_Time__c 
                              FROM Account 
                              WHERE Id =: slcdCenter  LIMIT 1]){
                trvlDuration = acc.Travel_Time__c > 0 ? Integer.valueOf(acc.Travel_Time__c) : 30;
            }
        }
    }
    /*
    public void getNoOfStudent(){
        enrModelList = new List<TrialEnrModel>();     
        
        if(String.isNotBlank(slcdNoOfStudent)){  
            for(Integer i=0; i<Integer.valueOf(slcdNoOfStudent); i++)
        		enrModelList.add(new TrialEnrModel());
        }
    }*/
    
    public void setTrialInsetrument(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            //trialEnrMod.slcdInstrument = slcdInstrument;
            trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
            trialEnrMod.timeSlotStrMap = new Map<Date, String>();
            fetchTimeSlot(trialEnrMod);
        }
    }
    
  /*  public PageReference backBtnCmp1(){
        return page.AdminHome;
    }
    public PageReference nextBtnCmp1(){
        return page.InstrumentRental_Ipad2;
    }*/
    
    public PageReference backBtnCmp2(){
        return page.AdminHome;
    }
    public PageReference nextBtnCmp2(){
        return page.InstrumentRental_Ipad3;
    }
    public PageReference backBtnCmp3(){
        return page.InstrumentRental_Ipad2;
    }
    public PageReference nextBtnCmp3(){
        if(isSiteGuestUser)
            return page.InstrumentRental_Ipad4;
        else
            return page.InstrumentRentalSearch_Ipad6;
        
    }
    public PageReference newCstmr(){
        slcdParId = null;
        parentAcc = new Account();
        return page.InstrumentRental_Ipad4;
    }
    public PageReference backCstmrSearchPage(){
        return page.InstrumentRental_Ipad3;
    }
    public PageReference backBtnCmp4(){
        //return page.InstrumentRental_Ipad3;
        if(isSiteGuestUser)
            return page.InstrumentRental_Ipad3;
        else
            return page.InstrumentRentalSearch_Ipad6;
    }
    
    public PageReference nextBtnCmp4(){  
        System.debug('@@@@'+slcdParId);
        parentAcc.phone = PersonMobilePhoneCustom;
        parentAcc.Id = slcdParId;
        if(slcdParId != null){
            List<Account> acList = [SELECT Id,FirstName,LastName,Phone,PersonEmail FROM Account WHERE Id =: slcdParId];
            if(acList.size() > 0)
                parentAcc = acList.get(0);
        }
        return page.InstrumentRental_Ipad5;
    }
    public PageReference backBtnCmp5(){   
        if(slcdParId == null)
        	return page.InstrumentRental_Ipad4;
        else 
            return page.InstrumentRentalSearch_Ipad6;
    }
    
    //Page2 functions        
    public void fetchPreWeekSlot(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(-7);
            trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(-7);
            trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
            trialEnrMod.timeSlotStrMap = new Map<Date, String>();
            fetchTimeSlot(trialEnrMod); 
        }
    }
    public void fetchNextWeekSlot(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(7);
            trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(7);
            trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
            trialEnrMod.timeSlotStrMap = new Map<Date, String>();
            fetchTimeSlot(trialEnrMod);
        }
    }
    
    public void processDuration(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdDuration = slcdDuration;
            fetchTimeSlot(trialEnrMod);
        }
    }
    
    public void slcdTeacher(){ 
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdTchrId = slcdTchrId;    
            trialEnrMod.slcdTchrName = '';
            
            List<Account> tchrlist = [SELECT Id,Name FROM Account WHERE Id =: slcdTchrId];
            if(tchrlist.size() > 0)
               trialEnrMod.slcdTchrName = tchrlist.get(0).Name;
        }    
    }
    
    public void processExistingStu(){ 
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdExistingStu = slcdExistingStu;
            System.debug('@@@@'+slcdExistingStu);
        }    
    }
	    
    public void fetchTimeSlot(TrialEnrModel trialEnrMod){
        trialEnrMod.teachModSlotMap = new Map<String,Map<String, List<TeacherModel>>>();
        /* validation
         if(String.isNotBlank(slcdCenter)){
            isError = true;
            ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'Please select atleast one location.'));
        }else if(String.isNotBlank(slcdInstrument)){
            isError = true;
            ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'Please select atleast one instrument.'));
        }*/
        
        Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();
        Map<String,String> teachAttaImageMap = new Map<String,String>();
        Set<String> tchrSet = new Set<String>();
		Map<Id,List<String>> tcrQualMap = new Map<Id,List<String>>();
        
        Set<String> salesTeamList = new Set<String>();
       // salesTeamList.add('Sales Executive');
       //salesTeamList.add('Sales and Operations Executive');
        //salesTeamList.add('Sales Manager');
        salesTeamList.add(Label.Sales_Employee_Piano_Viewing_Process);
        List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName, Teacher_Name__r.Job_Title__c,
                                                                Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Center_Name__c =: slcdCenter AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False 
                                                         AND  Start_Time__c != null AND End_Time__c != null 
                                                         AND Teacher_Name__r.Job_Title__c IN:salesTeamList];
        
        system.debug('techwork'+techWorkSchList);
        for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){                                                               
            List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
            if(tchList == null)
                tchList = new List<Teacher_Working_Hour__c>();
                                                              
            tchList.add(tchWrkSch);                                                  
            teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);  
            
            teachAttaImageMap.put(tchWrkSch.Teacher_Name__c,null);     
            
            tcrQualMap.put(tchWrkSch.Teacher_Name__c, null);
        }
        
        if(teachAttaImageMap.size() > 0){
            for(Account acc : [SELECT Id, (SELECT Id FROM Attachments WHERE Name Like '%Profile Image%' AND ContentType IN ('image/png', 'image/jpeg', 'image/gif') 
                                           ORDER BY LastModifiedDate DESC LIMIT 1) 
                               FROM Account WHERE Id IN : teachAttaImageMap.keySet()]){
                                  
                if(acc.Attachments != null && acc.Attachments.size()>0)
                    teachAttaImageMap.put(acc.Id, acc.Attachments.get(0).Id);
            }
        }
        
        Map<String,Fifth_Lesson__c> fifthLsnMap = new Map<String,Fifth_Lesson__c>();
        Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
        Date startDt = trialEnrMod.calStartDate;
        Date endDt   = trialEnrMod.calEndDate;
        
        //Update by-: Nishant | Date-: 18/06/2019
		//Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up'};
        //Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled'};
        Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed','Blocked'};
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
        
        Set<String> bookSet       = new Set<String>();
        for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                              FROM Booking__c 
                              WHERE Teacher_Account__c IN:teachAttaImageMap.keySet() AND RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null
                                    AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND Status__c IN: bookStatusSet
                                    AND ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Placeholder'))]){
            if(book.End_Time__c > book.Start_Time__c){
            	String key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ book.Start_Time__c;
            	bookMap.put(key, book); 
                
                if(trialEnrMod.slcdDuration == 0 || trialEnrMod.slcdDuration == 0)
                    trialEnrMod.slcdDuration = 30;
                        
                //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                String currDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                Time temStartTime = book.Start_Time__c.addMinutes(-(trialEnrMod.slcdDuration-15)); 
                Time endTempT     = book.End_Time__c;
                while(temStartTime < endTempT){
                    key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ temStartTime;
                    bookSet.add(key);
                    
                    temStartTime = temStartTime.addMinutes(15);
                }
            }
        }
        /*
        for(Fifth_Lesson__c fifthLsn : [SELECT Id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Teacher_Account__c  
                                        FROM Fifth_Lesson__c 
                                        WHERE Teacher_Account__c IN:teachAttaImageMap.keySet() AND IsActive__c = True AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)]){
          
           if(fifthLsn.End_Time__c > fifthLsn.Start_Time__c){
            	String key = fifthLsn.Teacher_Account__c +':'+ fifthLsn.Booking_Date__c +':'+ fifthLsn.Start_Time__c;
            	fifthLsnMap.put(key, fifthLsn); 
                
                if(trialEnrMod.slcdDuration == 0 || trialEnrMod.slcdDuration == 0)
                    trialEnrMod.slcdDuration = 30;
                        
                //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                String currDay =  DateTime.newInstance(fifthLsn.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                Time temStartTime = fifthLsn.Start_Time__c.addMinutes(-(trialEnrMod.slcdDuration-15)); 
                Time endTempT     = fifthLsn.End_Time__c;
                while(temStartTime < endTempT){
                    key = fifthLsn.Teacher_Account__c +':'+ fifthLsn.Booking_Date__c +':'+ temStartTime;
                    bookSet.add(key);
                    
                    temStartTime = temStartTime.addMinutes(15);
                }
            }                                 
        }*/
        
        System.debug('@@@'+bookSet);
        //Fetching teacher highest qualification
       /* Map<Id,List<String>> tcrQualMap = new Map<Id,List<String>>();
        for(Teacher_Working_Hour__c teachWorkSch: techWorkSchList)
            tcrQualMap.put(teachWorkSch.Teacher_Name__c, null);
        */
        if(tcrQualMap.size() > 0){
            for(Qualification__c qu : [SELECT Id,Name,Teacher__c,Programme_Name__c FROM Qualification__c 
                                       WHERE Teacher__c IN:tcrQualMap.keySet() ORDER BY Year_of_Graduation__c]){
                                           
                 List<String> tchrQual = new List<String>();
                 if(tcrQualMap.get(qu.Teacher__c) != null)
                     tchrQual = tcrQualMap.get(qu.Teacher__c);
                 
                 tchrQual.add(qu.Programme_Name__c);                          
                 tcrQualMap.put(qu.Teacher__c, tchrQual);                          
                // if(tcrQualMap.get(qu.Teacher__c) == null)
                   // tcrQualMap.put(qu.Teacher__c, qu);
            }
        }

        
        for(Date st=startDt; st<=endDt; st=st.addDays(1)){
            Map<String, List<TeacherModel>> tempSlotMap = new Map<String, List<TeacherModel>>();
            /*TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
            
            Set<Time> morningTimesTemp      = new Set<Time>();
            Set<Time> afternoonTimesTemp    = new Set<Time>();*/
         //   Map<Id,TeacherModel> accTcrMap  = new Map<Id,TeacherModel>();
            
            Set<Time> timeSlotTemp      = new Set<Time>();
            String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
            
            if(teachWorkSchMap.containsKey(currDay)){
                List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                
                for(Teacher_Working_Hour__c teachWorkSch: tchWorSchLst){
                   /* if(!(accTcrMap.containsKey(teachWorkSch.Teacher_Name__c))){
                        List<String> tchrQual =  new List<String>();
                        if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                            tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                        TeacherModel acc  = new TeacherModel(teachWorkSch.Teacher_Name__c, teachWorkSch.Teacher_Name__r.Name,
                                                            teachWorkSch.Teacher_Name__r.Teacher_Bio__c, '', tchrQual);
                        
                        if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
                            acc.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
                        accTcrMap.put(teachWorkSch.Teacher_Name__c, acc);
                    }*/
                    
                    Time stTime = teachWorkSch.Start_Time__c;
                   /* if(st == System.today() && System.now().time() > stTime){
                        stTime = System.now().time();
                    }*/
                    
                    Integer endTimeDef = trialEnrMod.slcdDuration  > 0 ? trialEnrMod.slcdDuration : 30;
                    
                    while(stTime <= teachWorkSch.End_Time__c.addMinutes(-endTimeDef)){
						/*if(st != date.Parse(slcdDate) && (morningTimesTemp.size() > 0 && afternoonTimesTemp.size() > 0)){
                            break;
                        } */			
                        
                        String key = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime;
                        if(bookMap.containsKey(key)){
                            Booking__c bookTmp = bookMap.get(key);
                            stTime = bookTmp.End_Time__c;
                        }else if(fifthLsnMap.containsKey(key)){
                            Fifth_Lesson__c fifthTmp = fifthLsnMap.get(key);
                            stTime = fifthTmp.End_Time__c;
                        }else{
                            string key2 = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime.addMinutes(15);
                           
                            if(bookMap.containsKey(key2)){
                                Booking__c bookTmp = bookMap.get(key2);
                                stTime = bookTmp.End_Time__c;
                            }else if(fifthLsnMap.containsKey(key2)){
                                Fifth_Lesson__c fifthTmp = fifthLsnMap.get(key2);
                                stTime = fifthTmp.End_Time__c;
                            }else{
                                //if(stTime.hour() < 12){
                                	String tempKey =  teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime;
                                    //if(!(bookSet.contains(tempKey)) && stTime.addMinutes(ConstantsClass.defMinutes) < teachWorkSch.End_Time__c){
                                    if(stTime.addMinutes(ConstantsClass.defMinutes) < teachWorkSch.End_Time__c){
                                       // Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                        //currTime = currTime.addHours(4);
                                        
                                        //DateTime tempTodayTime = System.now().addHours(4);
                                        //Updated by Rajesh 13th Aug 2019, Add 2 hours window for today
                                        DateTime tempTodayTime = System.now().addHours(2);
										//DateTime tempTodayTime = System.now();
                                        DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                            
                                        //if(st > System.today() || (st == System.today() &&  stTime > currTime)){
                                        if(tempStDtTime > tempTodayTime){
                                            timeSlotTemp.add(stTime);
                                            
                                            //Filling teacher according to time slot
                                            List<TeacherModel> tchTempList = new List<TeacherModel>();
                                            String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                            
                                           // if(trialEnrMod.teachModSlotMap.get(timeStr) != null)
                                             //   tchTempList = trialEnrMod.teachModSlotMap.get(timeStr);
                                            if(tempSlotMap.get(timeStr) != null)
                                            	tchTempList = tempSlotMap.get(timeStr);
                                            
                                           	List<String> tchrQual =  new List<String>();
                                            if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                                                tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                                           
                                         //   TeacherModel tMod = new TeacherModel(teachWorkSch.Teacher_Name__c,teachWorkSch.Teacher_Name__r.Name,teachWorkSch.Teacher_Name__r.Teacher_Bio__c,'',tchrQual);
                                            TeacherModel tMod = new TeacherModel(teachWorkSch.Teacher_Name__c, teachWorkSch.Teacher_Name__r.FirstName, teachWorkSch.Teacher_Name__r.Job_Title__c);
                                            
                                            if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
                                            	tMod.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
                                            tchTempList.add(tMod);
                                            
                                            tempSlotMap.put(timeStr, tchTempList);
                                           // Map<String, List<TeacherModel>> tempSlotMap = Map<String, List<TeacherModel>>();
                                            
                                            //Filling teacher according to time slot
                                        	/*List<TeacherModel> tchTempList = new List<TeacherModel>();
                                            String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                            
                                            if(trialEnrMod.teachModSlotMap.get(timeStr) != null)
                                                tchTempList = trialEnrMod.teachModSlotMap.get(timeStr);
                                            
                                            List<String> tchrQual =  new List<String>();
                                            if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                                                tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                                           
                                            TeacherModel tMod = new TeacherModel(teachWorkSch.Teacher_Name__c,teachWorkSch.Teacher_Name__r.Name,
                                                                                teachWorkSch.Teacher_Name__r.Teacher_Bio__c,'',tchrQual);
                                            if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
                                            	tMod.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
                                            tchTempList.add(tMod);
                                            
                                            trialEnrMod.teachModSlotMap.put(timeStr,tchTempList);*/
                                           // stTime = stTime.addMinutes(15);
                                       }
                                    }
                                    stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                              //  }
                            }
                        }
                    }
                }
            }
            /*
            List<String> mrgSlotList = new List<String>();
            List<Time> tmpLst        = new List<Time>();
            tmpLst.addAll(morningTimesTemp);tmpLst.sort();
            for(Time t : tmpLst){
                String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                mrgSlotList.add(t.hour() + ':' + minTmp);
            }
            
            List<String> aftSlotList = new List<String>();
            tmpLst                   = new List<Time>();
            tmpLst.addAll(afternoonTimesTemp);tmpLst.sort();
            for(Time t : tmpLst){
                String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                aftSlotList.add(t.hour() + ':' + minTmp);
            }
            
            TimeSlotModelCntrl tSlotMapTemp2 = new TimeSlotModelCntrl();
            if(slcdDate != null){
                if(st == date.Parse(slcdDate)){
                    tSlotMapTemp.morningSlot = mrgSlotList;
                    tSlotMapTemp.afternoonSlot = aftSlotList;
                    if(mrgSlotList.size() > 0 && aftSlotList.size() > 0)
                        tSlotMapTemp.teachModList = accTcrMap.values();  
                    
                    tSlotMapTemp2 = tSlotMapTemp;
                }
            }
            
            if(mrgSlotList.size() > 0)
                tSlotMapTemp2.isAvlMrgSlot = true;
            if(aftSlotList.size() > 0)
                tSlotMapTemp2.isAvlAfternoonSlot = true;
            
            tSlotDateMap.put(st.day()+'/'+st.month()+'/'+st.year() , tSlotMapTemp2);*/
            
            trialEnrMod.teachModSlotMap.put(st.format(),tempSlotMap);
            system.debug('timeSlotTemp------> '+timeSlotTemp);
            List<String> slotList = new List<String>();
            List<Time> tmpLst        = new List<Time>();
            tmpLst.addAll(timeSlotTemp);tmpLst.sort();
            
            String dayOfWeek  = ((DateTime)st).format('E');
            for(Time t : tmpLst){
                String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                slotList.add(dayOfWeek+'-'+t.hour() + ':' + minTmp);
            }
            trialEnrMod.timeSlotMap.put(st, slotList);
            trialEnrMod.timeSlotStrMap.put(st, st.format());
        }
        /*
        tSlotStr = JSON.serialize(tSlotDateMap);
        system.debug('tSlotStr------> '+tSlotStr);
        tSlotMap = tSlotDateMap.get(slcdDate);*/
    }
    
    public void fetchTeacherDetails(){        
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdDate 	= slcdDate;
            trialEnrMod.slcdDateDt  = date.parse(slcdDate);
            trialEnrMod.slcdFullSlot= slcdSlot;
            trialEnrMod.slcdSlot = trialEnrMod.slcdFullSlot.substring(4, trialEnrMod.slcdFullSlot.length());
            trialEnrMod.slcdSlotTchrs = new List<TeacherModel>();
            if(trialEnrMod.teachModSlotMap.get(slcdDate) != null && trialEnrMod.teachModSlotMap.get(slcdDate).get(trialEnrMod.slcdSlot) != null)
            	trialEnrMod.slcdSlotTchrs = trialEnrMod.teachModSlotMap.get(slcdDate).get(trialEnrMod.slcdSlot);
            
            System.debug('@@@@'+trialEnrMod.slcdSlotTchrs);
		    System.debug('@@@@'+trialEnrMod.slcdSlot);
        }
    }
    
    @RemoteAction
    public static list <EnrolmentModel> fetchEnrolments(String srchKey, String cntryCode){
        
        List<EnrolmentModel> enrList = new List<EnrolmentModel>(); 
        String type = ConstantsClass.typeTrial;
       // Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment};
        //Set<String> stgList = new Set<String>{'Piano Viewing Booked','Piano Viewing Completed'};
        if(String.isNotBlank(srchKey)){
            String tempSerch = srchKey + '%';
           
           /* String str = 'SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Student__r.Name,Teacher__c, '+
                				 'Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c,Center__c, Center__r.Name  '+
                		 'FROM Enrolment__c WHERE Center__r.Country__r.Name =:cntryCode AND Parent__r.Personemail != null AND Parent__c != null AND '+
                		 	  'Parent__r.Name != null AND Stage__c IN:stgList AND Type__c = \'Instrument\' AND (Name like: tempSerch OR Parent__r.Name like: tempSerch OR '+
                		 	  'Parent__r.PersonEmail like: tempSerch OR Parent__r.Phone like: tempSerch ) LIMIT 5';  */
            String str = 'SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Student__r.Name,Teacher__c, '+
                				 'Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c,Center__c, Center__r.Name  '+
                		 'FROM Enrolment__c WHERE Center__r.Country__r.Name =:cntryCode AND Parent__r.Personemail != null AND Parent__c != null AND '+
                		 	  'Parent__r.Name != null AND (Name like: tempSerch OR Parent__r.Name like: tempSerch OR '+
                		 	  'Parent__r.PersonEmail like: tempSerch OR Parent__r.Phone like: tempSerch ) LIMIT 5';
            
            List<Enrolment__c> enrListing= database.query(str);
            for(Enrolment__c enr:enrListing){
                String tempTSlot;
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
    
    public Pagereference saveTrialData(){
        Savepoint sp = Database.setSavepoint();
        isError = false;
        errorMsg = '';
        try{
            String csmrRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(); 
            
           // Map<String, Package__c> packMap = new Map<String, Package__c>();
            
           // Set<String> scldInst = new Set<String>();
           // for(TrialEnrModel trMd : enrModelList)
             //   scldInst.add(trMd.slcdInstrument);
			
            String pckgItmRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Item').getRecordTypeId(); 
            List<Package__c> packLst = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name 
                                        FROM Package__c 
                                        WHERE RecordTypeId=:pckgItmRecId AND Location__c =: slcdCenter  AND Active__c = True AND Type__c = 'Trial' AND Duration__c = '45' LIMIT 1];
         
            if(packLst.size() == 0){
                //errorMsg = 'Trial Package is not configured for this Poano, Please contact to center admin.'+packLst.size();
                errorMsg = 'Trial Package is not configured for this Piano, Please contact to center admin.';
                isError = true;
                return null;
            }
            
            if(validateSlcdSlot()){
                errorMsg = 'Timeslot not available.';
                isError = true;
                return null;
            }
            
            //for(Package__c pkg : packLst)
              //  packMap.put(pkg.Program__r.Instrument__c, pkg);
            
            //Fill Parent and Upasert parent record
            parentAcc.RecordTypeId   = csmrRecId;
            parentAcc.Centre_Name__c = slcdCenter;
           // parentAcc.Instrument__c  = (new list<string>(scldInst) )[0] ;
            List<Account> centrList  = [SELECT Id, Name,Organisation__c,Organisation__r.name, Location__c, Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
            if(centrList.size() > 0){
                parentAcc.Location__c = centrList.get(0).Location__c;
                //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                if(centrList.get(0).Country__r.Country_Name__c != null)
                	parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
            }
            //Check that customer is already exist or not on the bases of email
            if(parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name FROM Account 
                                        WHERE PersonEmail =: parentAcc.PersonEmail
                                        And Centre_Name__r.Organisation__c =: centrList.get(0).Organisation__c // Added by nishi: 30-nov-2020: for Change customer key from email address to email address+Organisation name
                                        ]; 
                if(accList.size() > 0)
                    parentAcc.Id = accList.get(0).Id;
                else{
                    // Added by nishi:Start: 30-nov-2020: for Change customer key from email address to email address+Organisation name
                    string useremail=parentAcc.PersonEmail+'.';
                    if(centrList.get(0).Organisation__r.name == Label.Ossia_Organisation_Name){
                        useremail +='ossia'+centrList.get(0).name; 
                    }else{
                        useremail += 'aureus'+centrList.get(0).name;
                    }
                    parentAcc.User_Email__c = useremail;
                    // Added by nishi:end: 30-nov-2020: for Change customer key from email address to email address+Organisation name     
                }
            }
           /* if(isParAlsoAStudent){
                Account stuAcc = enrModelList.get(0).studentAcc;
                parentAcc.Also_a_Student__c = true;
                parentAcc.PersonBirthdate   = stuAcc.PersonBirthdate;
                parentAcc.Learning_Style__c = stuAcc.Learning_Style__c;
                parentAcc.Description       = stuAcc.Description;
                parentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                parentAcc.Gender__c = stuAcc.Gender__c;
            }*/
                        
            //system.debug('PersonMobilePhoneCustom---> '+PersonMobilePhoneCustom);
            parentAcc.PersonMobilePhone = parentAcc.Phone;
            //parentAcc.Phone = PersonMobilePhoneCustom;
            
            if(slcdParId == null)
            	upsert parentAcc;
			
			List<Account> stuList = new List<Account>();
        	List<Enrolment__c> enrList = new List<Enrolment__c>();
            List<Booking__c> bookList = new List<Booking__c>();
            
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();   
            String enrInsRenRecId =  Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();  
            for(TrialEnrModel trMd : enrModelList){
                //Fill Student Details
               /* Account studentAcc = trMd.studentAcc;  
                studentAcc.RecordTypeId   = csmrRecId;
                if(!isParAlsoAStudent){
                    //To find existing student for the sepecific parent
                    if(String.isNotBlank(trMd.slcdExistingStu) && !trMd.slcdExistingStu.equalsIgnoreCase('new'))
                    	studentAcc.Id = trMd.slcdExistingStu;                        
                    studentAcc.Parent__c = parentAcc.Id;
                    studentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;                    
                    studentAcc.Centre_Name__c = slcdCenter;
                    if(centrList.size() > 0){
                        studentAcc.Location__c = centrList.get(0).Location__c;
                        if(centrList.get(0).Country__r.Country_Name__c != null)
                            studentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                    }     
                }else{
                    studentAcc = parentAcc;
                }   
                If(trMd.stuSameAsChild1){
                	studentAcc = stuList.get(0);
                }else{
                    stuList.add(studentAcc);
                }*/
                
                //Fill Enrolment details
                Enrolment__c enrl  = new Enrolment__c();
                enrl.Parent__c     = parentAcc.Id;
                enrl.RecordTypeId  = enrInsRenRecId;
                enrl.Student__c    = parentAcc.Id;
               // enrl.Learning_Style__c = studentAcc.Learning_Style__c;
                //enrl.Student__r    = studentAcc;
                enrl.Type__c       = 'Instrument';//ConstantsClass.typeTrial;
                enrl.Stage__c      = 'Piano Viewing Booked';//ConstantsClass.requestedSubStatus;
                enrl.Center__c     = slcdCenter;
                enrl.Teacher__c    = trMd.slcdTchrId;
                enrl.Previous_Experience_if_any__c  = trMd.stuPreExperience;
                enrl.Cancellation_Policy_Agreed__c  = true;
                enrl.I_want_to_receive_latest_newsletter__c = iWantReceivedLatestNew;
            //    if(packMap.containskey(trMd.slcdInstrument))
                enrl.Package__c = packLst.get(0).Id;
                
                enrl.Trial_Date__c = trMd.slcdDateDt;                    
                //Filling start time
                List<String> timeList = trMd.slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                enrl.Trial_Start_Time__c = startTime;
                
                
                if(String.isNotBlank(formName))
                    enrl.Form_Name__c = formName;
                
                //Added by Rajesh, 6th Aug 2019. To store trial source on enrolment/case object 
                if(String.isNotBlank(trialSource))
                    enrl.Trial_Source__c = trialSource;
                enrList.add(enrl);
                
                //Fill Bookings
                Booking__c book = new Booking__c(Teacher_Account__c = trMd.slcdTchrId, Enrolment__r = enrl);
                book.Parent__c = parentAcc.Id;
                book.Student__c = parentAcc.Id;
                book.Center__c =  slcdCenter;
                book.Type__c   = ConstantsClass.typeTrial;
                book.Status__c = ConstantsClass.scheduledStatus;//ConstantsClass.statusPending;
                book.RecordTypeId = bookLessRecId;
                book.Package__c = enrl.Package__c;
                book.Booking_Date__c = enrl.Trial_Date__c;
                book.Start_Time__c = enrl.Trial_Start_Time__c;
                book.End_Time__c = book.Start_Time__c.addMinutes(trMd.slcdDuration);
                bookList.add(book);
                /*
                if(isAureusAtHome){
                    Booking__c befBook = new Booking__c(Student__r = studentAcc, Teacher_Account__c = trMd.slcdTchrId, Enrolment__r = enrl);
                    befBook.RecordTypeId  = bookLessRecId;
                    befBook.Center__c =  slcdCenter;
                    befBook.Type__c    = ConstantsClass.busyBookingType;
                    book.Status__c 	   = ConstantsClass.scheduledStatus;
                    befBook.Category__c= 'Travel';
                    befBook.Remarks__c = 'Travel time slot for home trial booking';
                    book.Package__c = enrl.Package__c;
                    befBook.Start_Time__c = book.Start_Time__c.addMinutes(-trvlDuration);
                    befBook.End_Time__c   = book.Start_Time__c;
                    befBook.Booking_Date__c = book.Booking_Date__c;
                    bookList.add(befBook);    
                }*/
            }
			
           // if(stuList.size() > 0){
            	//upsert stuList;
                
                //for(Enrolment__c enrl: enrList)
                //    enrl.Student__c = enrl.Student__r.Id;
                insert enrList;
                
                for(Booking__c book : bookList){
                   // book.Student__c = book.Student__r.Id;
                    book.Enrolment__c = book.Enrolment__r.Id;
                }
                insert bookList;    
                
                if(!isSiteGuestUser){
                   /* for(Enrolment__c enrl: enrList)
                        enrl.Stage__c = 'Booked';
                    update enrList;
                    */
                   /* for(Booking__c book : bookList)
                        book.Status__c = ConstantsClass.scheduledStatus;
                    update bookList;*/
                }                
           // }
			if(isSiteGuestUser)
            	return new Pagereference(Label.Trial_booking_confirmation_url);  
            else
            	return new Pagereference('/apex/freetrial_thankIpad');  
            
            //Pagereference pg = new Pagereference('https://aureusacademy.com/trial-booking-confirmation'); 
           // errorMsg = 'success';
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError = true;
            return null;
        }
        
    }
    
    private Boolean validateSlcdSlot(){
        Boolean isValidateFuture = false; 
        
        if(enrModelList.size() > 0){
            Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
            Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed','Blocked'};
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
            
            String soqlStr = 'SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c FROM Booking__c ';
                   soqlStr += ' WHERE RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null AND ';
                   soqlStr += ' ((Type__c IN: bookTypeSet) OR (Type__c = \'Busy\' AND Category__c != \'Placeholder\')) ';
            
            Map<String, TrialEnrModel> trialEnrMap = new Map<String, TrialEnrModel>();
            for(TrialEnrModel trMd : enrModelList){
                String tchrId = trMd.slcdTchrId;
                Date   slcdDt = trMd.slcdDateDt;
            	soqlStr += ' AND (Teacher_Account__c =: tchrId AND (Booking_Date__c >=: slcdDt AND Booking_Date__c <=: slcdDt)) ';
                
                List<String> timeList = trMd.slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);                 
                String key = trMd.slcdTchrId+':'+trMd.slcdDateDt+':'+startTime;
                trialEnrMap.put(key,trMd);
            }
            System.debug('query -->'+soqlStr);
            for(Booking__c book : Database.query(soqlStr)){    
                String key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ book.Start_Time__c;
                if(trialEnrMap.containsKey(key)){
                    TrialEnrModel trMd = trialEnrMap.get(key);
                    List<String> timeList = trMd.slcdSlot.split(':');            
                    Time sltdStartTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                    Time sltdEndTime   = sltdStartTime.addMinutes(trMd.slcdDuration); 
                                      
                    if((sltdStartTime >= book.Start_Time__c && sltdEndTime <= book.End_Time__c) && (sltdEndTime >= book.Start_Time__c && sltdEndTime <= book.End_Time__c)){
                        isValidateFuture = true;
                        break;          
                   }
                }
            }
        }
        return isValidateFuture;
    }
    
    public Class TrialEnrModel{
        public String  slcdInstrument{get;set;}
        public Integer slcdDuration{get;set;}
        public String  slcdDate{get;set;}
        public Date    slcdDateDt{get;set;}
        public String  slcdFullSlot{get;set;}
        public String  slcdSlot{get;set;}
        public String  slcdTchrId{get;set;}
        public String  slcdTchrName{get;set;}
        public Date    calStartDate{get;set;}
        public Date    calEndDate{get;set;}
        public Account studentAcc{get;set;}
        public String  stuPreExperience{get;set;}
        public String slcdExistingStu{get;set;}
        public Map<Date, List<String>>  timeSlotMap{get;set;}
        public Map<Date, String>  timeSlotStrMap{get;set;}
        public List<TeacherModel> slcdSlotTchrs{get;set;}
        public Map<String,String> existingStuOpt{get;set;}
        public Boolean stuSameAsChild1{get;set;}
        
        Map<String,Map<String, List<TeacherModel>>> teachModSlotMap;
        public TrialEnrModel(){
            this.slcdInstrument = '';
            this.slcdDuration   = 45;
            this.slcdSlot = '';
            //this.calStartDate   = System.today().toStartofWeek();
            this.calStartDate   = System.today();
            this.calEndDate     = calStartDate.addDays(6);
            this.timeSlotMap    = new Map<Date, List<String>>();
            this.slcdSlotTchrs  = new List<TeacherModel>();
            this.timeSlotStrMap = new Map<Date, String>();
            this.existingStuOpt = new Map<String,String>();
            
            this.teachModSlotMap= new Map<String,Map<String, List<TeacherModel>>>();
            this.studentAcc     = new Account();
            this.stuSameAsChild1= false;
        }
    }
    /*
     public class TimeSlotModelCntrl{
        public List<TeacherModel> teachModList{get;set;}        
        Map<String, List<TeacherModel>> teachModSlotMap;
        
        public TimeSlotModelCntrl(){
            teachModList  = new List<TeacherModel>();
            teachModSlotMap = new Map<String, List<TeacherModel>>();
        }
    }*/
    
    
    public class TeacherModel{
        public String tecId{get;set;}
        public String tecName{get;set;}
        public String empType{get;set;}
    //    public String teacBio{get;set;}
     //   public String teacBioDescribe{get;set;}
       // public String highestQualification{get;set;}
        //public List<String> highestQualificationLst{get;set;}
        
        public String attachmentId{get;set;}
        
        public TeacherModel(String tecId,String tecName,String empType){
            this.tecId   = tecId;
            this.tecName = tecName;
            this.empType = empType;
          //  this.teacBio = teacBioCon;
           // this.teacBioDescribe = teacBioCon;
          //  this.highestQualification = highestQualification;
           // this.highestQualificationLst = highestQualificationLst;
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

}