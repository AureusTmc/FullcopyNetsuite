public class FreeTrialController{
    public String slcdCenter{get;set;}
    public String slcdCenterName{get;set;}
    public String slcdInstrument{get;set;}
    public String slcdSlot{get;set;}
    public String slcdSlotT{get;set;}
    public String slcdTechr{get;set;}
    public String slcdTechrName{get;set;}
    public String mapAddress{get;set;}
    public String slcdDate{get;set;}
    public Date   slcdDateD{get;set;}
    public String stuPreExperience{get;set;}
    public String tSlotStr{get;set;}
    public String pkgName{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,String> disabledInstrument{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    
    public Account      parentAcc{get;set;}
    public Account      studentAcc{get;set;}
    public AccountModel parModel{get;set;}
    public AccountModel stuModel{get;set;}
    
    public Boolean iWantReceivedLatestNew{get;set;}
    public Boolean isValidateFuture{get;set;}
    public Boolean isParAlsoAStudent{get;set;}
    
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    
    public Boolean isAureusAtHome{get;set;}
    Integer trvlDuration;
    //String  centerId;
    String formName;
    
    //Added by Rajesh, 6th Aug 2019. To store trial source on case object and country for filtercentre
    String trialSource;
    public String countryCode{get;set;}
    
    // 16-04-2019 Add by Dilip Start
    public string PersonMobilePhoneCustom{get;set;}  
    //public string PhoneCustom{get;set;}   
    // 16-04-2019 Add by Dilip End
    
    //Added by Rajesh, 28th July 2019. To find existing student for the sepecific parent
    public List<AccountModel> existingStuList{get;set;}
    public String slcdExistingStu{get;set;}
    public FreeTrialController(){
        PersonMobilePhoneCustom = '';
        //PhoneCustom = '';
        //Commented by Rajesh: 9th sept 2019, to populate address according to country parameter
       // mapAddress = ConstantsClass.mapDefAdd;
        iWantReceivedLatestNew = true;
        tSlotStr   = '';
        slcdCenter = '';
        slcdDate   = System.today().day()+'/'+System.today().month()+'/'+System.today().year() ;
        tSlotMap   = new TimeSlotModelCntrl();
        parentAcc  = new Account();
        studentAcc = new Account();
        parModel   = new AccountModel();
        stuModel   = new AccountModel();
        disabledInstrument = new Map<String,String>();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        //Added by Rajesh, 28th July 2019. To find existing student for the sepecific parent
        existingStuList = new List<AccountModel>();
        String recId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        parentAcc.RecordTypeId = recId;
        recId    =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        studentAcc.RecordTypeId = recId;
        isError  = false;
        errorMsg = '';
        isValidateFuture = false;
        isParAlsoAStudent= false; 
        
        isAureusAtHome = false;
        trvlDuration   = 0; 
        
        formName = ApexPages.currentPage().getParameters().get('Formname');
        
        //Added by Rajesh, 6th Aug 2019. To store trial source on case object and country for filtercentre
        trialSource	 = ApexPages.currentPage().getParameters().get('ts');
        countryCode	 = ApexPages.currentPage().getParameters().get('country');
        if(String.isBlank(countryCode))
            countryCode = 'SG';
         
         //Added by Rajesh: 9th sept 2019, to populate address according to country parameter
         mapAddress = countryCode.endsWithIgnoreCase('HK') ? ConstantsClass.mapDefAddHK : ConstantsClass.mapDefAdd;
        
        //Aureus at Home id
        //centerId     = ApexPages.currentPage().getParameters().get('cntId');
        //isAureusAtHome = String.isNotBlank(centerId) ? true : false;
        
        //if(isAureusAtHome)
           // slcdCenter = centerId;
    }
    
    public list<SelectOption> getCenters(){
        list<SelectOption> options = new list<SelectOption>();
        
        /*if(isAureusAtHome){
            for(Account acc: [SELECT Id,Name,CentreName_Cust__c,Travel_Time__c 
                              FROM Account 
                              WHERE Id =: centerId  LIMIT 1]){
                options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
                trvlDuration = acc.Travel_Time__c > 0 ? Integer.valueOf(acc.Travel_Time__c) : 30;
            }
        }else{
            String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
            options.add(new SelectOption('','Please select')); 
            
            for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                              WHERE RecordtypeId =: cenRecId AND Id !=: Label.Aureus_at_Home_Id ORDER BY CentreName_Cust__c]){
                options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
            }
        }*/
        
        String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        options.add(new SelectOption('','Please select')); 
        
        //updated by Rajesh, 7th Aug 2019. updated soql To package centre bases of the country
        //Updated by Rajesh, 13th Aug 2019. Updated soql to remove hardcoded centre and filter centres on the bases of centre status
        for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                          WHERE RecordtypeId =: cenRecId AND Centre_Status__c =:ConstantsClass.activeStatus AND Country__r.Name =:countryCode AND CentreName_Cust__c != null ORDER BY CentreName_Cust__c]){
            options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
        }
        
        return options;
    }
    
    public String getAddr(){
        String address = '';
         
        if(String.isNotBlank(slcdCenter)){
            List<Account> accList = [SELECT Id,BillingStreet,BillingPostalCode,BillingCity,BillingState,BillingCountry from account where Id =: slcdCenter ];
            
            if(accList.size() > 0){
                Account ac = accList.get(0);
                String add =  String.isNotBlank(ac.BillingStreet)     ? ac.BillingStreet     + ' ':'';
                       add += String.isNotBlank(ac.BillingCity)       ? ac.BillingCity       + ' ':'';
                       add += String.isNotBlank(ac.BillingState)      ? ac.BillingState      + ' ':'';
                       add += String.isNotBlank(ac.BillingPostalCode) ? ac.BillingPostalCode + ' ':'';
                       add += String.isNotBlank(ac.BillingCountry)    ? ac.BillingCountry    + ' ':''; 
                        
                address = add;  
                mapAddress = address; 
            }
        }
        
        return address;
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
    
    public List<String> getInstrument(){
        List<String> instrumentList = new List<String>();
        disabledInstrument = new Map<String,String>();
        
        Set<String> instrumentTempSet = new Set<String>();
        if(String.isNotBlank(slcdCenter)){
            
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,
                                                                    End_Time__c,Active__c,Center_Name__c,Center_Name__r.Name,Teacher_Name__r.Major_Instruments_Disciplines__c 
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                                   Teacher_Name__r.Major_Instruments_Disciplines__c != null AND Center_Name__r.Country__r.Name =:countryCode];
            //Filling active Instruments for the selected Center
            for(Teacher_Working_Hour__c teachTemp: techWorkSchList){
                if(teachTemp.Center_Name__c == slcdCenter) {
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
        instrumentList.sort();
        return instrumentList;
    }
    
    public void fetchTimeSlot(){
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
        
        List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,
                                                                Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Center_Name__c =: slcdCenter AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False 
                                                         AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null AND
                                                             Teacher_Name__r.Major_Instruments_Disciplines__c includes(:slcdInstrument)];
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
        
        //Update by-: Rajesh | Date-: 04/10/2019
        Map<String,Fifth_Lesson__c> fifthLsnMap = new Map<String,Fifth_Lesson__c>();
        Map<String,Booking__c> bookMap 			= new Map<String,Booking__c>();
        Date startDt = System.today();
        Date endDt   = startDt.addMonths(1);
        //Update by-: Nishant | Date-: 18/06/2019
		//Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up'};
        //Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled'};
        Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed','Blocked'};
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
        
        for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                              FROM Booking__c 
                              WHERE Teacher_Account__c IN:teachAttaImageMap.keySet() AND RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null
                                    AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND Status__c IN: bookStatusSet
                                    AND ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Placeholder'))]){
            if(book.End_Time__c > book.Start_Time__c){
            	String key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ book.Start_Time__c;
            	bookMap.put(key, book);   
            }
        }
        
        //Update by-: Rajesh | Date-: 04/10/2019
        for(Fifth_Lesson__c fifthLsn : [SELECT Id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Teacher_Account__c  
                                        FROM Fifth_Lesson__c 
                                        WHERE Teacher_Account__c IN:teachAttaImageMap.keySet() AND IsActive__c = True AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)]){
            if(fifthLsn.End_Time__c > fifthLsn.Start_Time__c){   
                String key = fifthLsn.Teacher_Account__c +':'+ fifthLsn.Booking_Date__c +':'+ fifthLsn.Start_Time__c;
                fifthLsnMap.put(key, fifthLsn);  
            }
        }
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
            TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
            
            Set<Time> morningTimesTemp      = new Set<Time>();
            Set<Time> afternoonTimesTemp    = new Set<Time>();
            Map<Id,TeacherModel> accTcrMap  = new Map<Id,TeacherModel>();
            
            String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
            
            if(teachWorkSchMap.containsKey(currDay)){
                List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                
                for(Teacher_Working_Hour__c teachWorkSch: tchWorSchLst){
                    if(!(accTcrMap.containsKey(teachWorkSch.Teacher_Name__c))){
                       // String hstTechMod = tcrQualMap.get(teachWorkSch.Teacher_Name__c) !=null ? tcrQualMap.get(teachWorkSch.Teacher_Name__c).Programme_Name__c : '';
                        List<String> tchrQual =  new List<String>();
                        if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                            tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                        TeacherModel acc  = new TeacherModel(teachWorkSch.Teacher_Name__c, teachWorkSch.Teacher_Name__r.Name,
                                                            teachWorkSch.Teacher_Name__r.Teacher_Bio__c, '', tchrQual);
                        
                        if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
                            acc.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
                        accTcrMap.put(teachWorkSch.Teacher_Name__c, acc);
                    }
                    
                    Time stTime = teachWorkSch.Start_Time__c;
                   /* if(st == System.today() && System.now().time() > stTime){
                        stTime = System.now().time();
                    }*/
                    while(stTime < teachWorkSch.End_Time__c.addMinutes(-15)){
						if(st != date.Parse(slcdDate) && (morningTimesTemp.size() > 0 && afternoonTimesTemp.size() > 0)){
                            break;
                        } 			
                        
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
                            }
                            else{
                                if(stTime.hour() < 12){
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
                                            morningTimesTemp.add(stTime);
                                            
                                            //Filling teacher according to time slot
                                            List<TeacherModel> tchTempList = new List<TeacherModel>();
                                            String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                            
                                            if(tSlotMapTemp.teachModSlotMap.get(timeStr) != null)
                                                tchTempList = tSlotMapTemp.teachModSlotMap.get(timeStr);
                                            
                                            //String hstTechModTemp = tcrQualMap.get(teachWorkSch.Teacher_Name__c) !=null ? tcrQualMap.get(teachWorkSch.Teacher_Name__c).Programme_Name__c : '';
                                            
                                            List<String> tchrQual =  new List<String>();
                                            if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                                                tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                                            tchTempList.add(new TeacherModel(teachWorkSch.Teacher_Name__c,teachWorkSch.Teacher_Name__r.Name,
                                                                                teachWorkSch.Teacher_Name__r.Teacher_Bio__c,'',tchrQual));
                                            tSlotMapTemp.teachModSlotMap.put(timeStr,tchTempList);
                                           // stTime = stTime.addMinutes(15);
                                       }
                                    }
                                    stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                }else{  
                                    //Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                    //currTime = currTime.addHours(4);     
                                   
                                    //DateTime tempTodayTime = System.now().addHours(4);
                                    //Updated by Rajesh 13th Aug 2019, Add 2 hours window for today
                                    DateTime tempTodayTime = System.now().addHours(2);
									//DateTime tempTodayTime = System.now();
                                    DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                    
                                     //if(st > System.today() || (st == System.today() && stTime > currTime)){
                                    if(tempStDtTime > tempTodayTime){
                                        afternoonTimesTemp.add(stTime);
                                       
                                        //Filling teacher according to time slot
                                        List<TeacherModel> tchTempList = new List<TeacherModel>();
                                        String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                        
                                        if(tSlotMapTemp.teachModSlotMap.get(timeStr) != null)
                                            tchTempList = tSlotMapTemp.teachModSlotMap.get(timeStr);
                                        
                                        //String hstTechModTemp = tcrQualMap.get(teachWorkSch.Teacher_Name__c) !=null ? tcrQualMap.get(teachWorkSch.Teacher_Name__c).Programme_Name__c : '';
                                        List<String> tchrQual =  new List<String>();
                                        if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                                            tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                                        
                                        tchTempList.add(new TeacherModel(teachWorkSch.Teacher_Name__c,teachWorkSch.Teacher_Name__r.Name,
                                                                         teachWorkSch.Teacher_Name__r.Teacher_Bio__c,'', tchrQual));
                                        tSlotMapTemp.teachModSlotMap.put(timeStr,tchTempList);
                                    }
                                    
                                    stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                }
                            }
                        }
                    }
                }
            }
            
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
            
            tSlotDateMap.put(st.day()+'/'+st.month()+'/'+st.year() , tSlotMapTemp2);
        }
        
        tSlotStr = JSON.serialize(tSlotDateMap);
        system.debug('tSlotStr------> '+tSlotStr);
        tSlotMap = tSlotDateMap.get(slcdDate);
    }
    
    public void refreshSlotsAndTchr(){
        if(String.isNotBlank(slcdSlot)){
            if(tSlotMap.teachModSlotMap.containsKey(slcdSlot)){
                tSlotMap.teachModList = tSlotMap.teachModSlotMap.get(slcdSlot);
                /*  Querying attachment to show the teacher image.  */
                Set<String> teacherIds = new Set<String>();
                for(TeacherModel tcr : tSlotMap.teachModList){
                    teacherIds.add(tcr.tecId);
                }
                
                Map<String, String> attachmentMap = new Map<String, String>();
                for(Account acc : [SELECT Id, (SELECT Id FROM Attachments WHERE  Name Like '%Profile Image%' AND ContentType IN ('image/png', 'image/jpeg', 'image/gif') 
                                              ORDER BY LastModifiedDate DESC LIMIT 1) 
                                   FROM Account WHERE Id IN : teacherIds]){
                    if(acc.Attachments != null && acc.Attachments.size()>0){
                        attachmentMap.put(acc.Id, acc.Attachments.get(0).Id);
                    }
                }
                
                for(TeacherModel tcr : tSlotMap.teachModList){
                    if(attachmentMap.containsKey(tcr.tecId))
                        tcr.attachmentId = attachmentMap.get(tcr.tecId);
                }
            }
        }
    }
    
    public void refreshTeacherOnSelectSlot(){
        if(String.isNotBlank(slcdSlot)){
            if(tSlotMap.teachModSlotMap.containsKey(slcdSlot))
                tSlotMap.teachModList = tSlotMap.teachModSlotMap.get(slcdSlot);
        }
    }
    
    public void validateSlcdSlotInFuture(){
        isValidateFuture = false; 
        
        if( String.isNotBlank(slcdCenter) && String.isNotBlank(slcdDate) && String.isNotBlank(slcdSlot) && String.isNotBlank(slcdTechr)){
            Date startDt   = Date.parse(slcdDate);
            Date endDtTemp = startDt.addMonths(4);
            
            List<String> timeList = slcdSlot.split(':');            
            Time sltdStartTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            Time sltdEndTime   = sltdStartTime.addMinutes(30); 
            String slcdDay     =  DateTime.newInstance(startDt, Time.newInstance(0, 0, 0, 0)).format('E');
            
            List<Booking__c> booList = [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                                        FROM Booking__c 
                                        WHERE Teacher_Account__c =: slcdTechr
                                              AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDtTemp)];
            
            for(Booking__c book : booList){    
               String bookDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
               
               if(slcdDay == bookDay && (sltdStartTime >= book.Start_Time__c && sltdEndTime <= book.End_Time__c) && (sltdEndTime >= book.Start_Time__c && sltdEndTime <= book.End_Time__c)){
                    isValidateFuture = true;
                    break;          
               }
            }
        }
    }
    
    public void fetchSummaryDetails(){
        //Fetch center name
        for(Account acc: [SELECT Id,Name,CentreName_Cust__c,Travel_Time__c 
                          FROM Account 
                          WHERE Id =: slcdCenter  LIMIT 1]){
            slcdCenterName = acc.CentreName_Cust__c;                   
        }
        
        //Fetch teacher name
        for(Account acc: [SELECT Id,Name FROM Account 
                          WHERE Id =: slcdTechr  LIMIT 1]){
            slcdTechrName = acc.Name;                   
        }
        
        List<Package__c> packLst = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name 
                                    FROM Package__c 
                                    WHERE Location__c =: slcdCenter  AND Program__r.Status__c = 'Active' AND Active__c = True AND
                                          Program__r.Instrument__c =: slcdInstrument AND Type__c = 'Trial' AND Duration__c = '30' LIMIT 1];
        if(packLst.size() > 0)
            pkgName = packLst.get(0).Name;
        
        slcdDateD = Date.parse(slcdDate);
        
        if(String.isNotBlank(slcdSlot)){
            List<String> timeList = slcdSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            slcdSlotT = DateTime.newInstance(slcdDateD, tempT).format('hh:mm a');
        }
    }
    
    //Added by Rajesh, 28th July 2019. To find existing student for the sepecific parent
    public void fetchExistingStuDetail(){
        existingStuList = new List<AccountModel>();
        slcdExistingStu = '';
        if(studentAcc.Gender__c != null && studentAcc.PersonBirthdate != null && parentAcc.PersonEmail != null){
            List<Account> stuList = [SELECT Id,Name FROM Account WHERE Gender__c =:studentAcc.Gender__c AND  
                                     								   PersonBirthdate =: studentAcc.PersonBirthdate AND
                                     								   Parent__r.PersonEmail =: parentAcc.PersonEmail]; 
            if(stuList.size() > 0){
            	for(Account ac: stuList)
                	existingStuList.add(new AccountModel(ac.Name, ''+ac.Id));
            }
            
        }
        existingStuList.add(new AccountModel('Create new student', 'new'));
    }
    
    public pagereference saveData(){
        Savepoint sp = Database.setSavepoint();
        isError = false;
        errorMsg = '';
      //  try{
            
            List<Package__c> packLst = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name 
                                        FROM Package__c 
                                        WHERE Location__c =: slcdCenter  AND Program__r.Status__c = 'Active' AND Active__c = True AND
                                              Program__r.Instrument__c =: slcdInstrument AND Type__c = 'Trial' AND Duration__c = '30' LIMIT 1];
         
            if(packLst.size() == 0){
                errorMsg = 'Trial Package is not configured for this '+slcdInstrument+', Please contact to center admin.';
                isError = true;
                return null;
            }
            
            parentAcc.FirstName = parModel.firstName;
            parentAcc.LastName  = parModel.lastName;
            
            //added by Rajesh:3rd Aug 2019, To populate instrument or location for Pardot, as per discussion with Prashant
            parentAcc.Centre_Name__c = slcdCenter;
            parentAcc.Instrument__c  = slcdInstrument;
            List<Account> centrList  = [SELECT Id, Name, Location__c, Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
            if(centrList.size() > 0){
                parentAcc.Location__c = centrList.get(0).Location__c;
                //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                if(centrList.get(0).Country__r.Country_Name__c != null)
                	parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
            }
            //Check that customer is already exist or not on the bases of email
            if(parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
                if(accList.size() > 0)
                    parentAcc.Id = accList.get(0).Id;
            }
            
            if(isParAlsoAStudent){
                parentAcc.Also_a_Student__c = true;
                parentAcc.PersonBirthdate   = studentAcc.PersonBirthdate;
                parentAcc.Learning_Style__c = studentAcc.Learning_Style__c;
                parentAcc.Description       = studentAcc.Description;
                parentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                parentAcc.Gender__c = studentAcc.Gender__c;
            }
            //system.debug('PersonMobilePhoneCustom---> '+PersonMobilePhoneCustom);
            parentAcc.PersonMobilePhone = PersonMobilePhoneCustom;
            parentAcc.Phone = PersonMobilePhoneCustom;
            /*if(PhoneCustom!=''){
                parentAcc.Phone = PhoneCustom;
            }else{
                parentAcc.Phone = PersonMobilePhoneCustom;
            }*/    
            //system.debug('parentAcc---> '+parentAcc);
            upsert parentAcc;
            
            if(!isParAlsoAStudent){
                //Added by Rajesh, 28th July 2019. To find existing student for the sepecific parent
                if(String.isNotBlank(slcdExistingStu) && !slcdExistingStu.equalsIgnoreCase('new'))
                    studentAcc.Id = slcdExistingStu;
                    
                studentAcc.FirstName = stuModel.firstName;
                studentAcc.LastName  = stuModel.lastName;
                studentAcc.Parent__c = parentAcc.Id;
                studentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                
                studentAcc.Centre_Name__c = slcdCenter;
                if(centrList.size() > 0){
                    studentAcc.Location__c = centrList.get(0).Location__c;
                    if(centrList.get(0).Country__r.Country_Name__c != null)
                        studentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                }
                //updated by Rajesh, 28th July 2019. To find existing student for the sepecific parent
                upsert studentAcc;
                //insert studentAcc;
            }else{
                studentAcc = parentAcc;
            }
            
            /*List<Package__c> packLst = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name 
                                        FROM Package__c 
                                        WHERE Location__c =: slcdCenter  AND Program__r.Status__c = 'Active' AND Active__c = True AND
                                              Program__r.Instrument__c =: slcdInstrument AND Type__c = 'Trial' AND Duration__c = '30' LIMIT 1];
            */
            Enrolment__c enrl  = new Enrolment__c();
            enrl.Parent__c     = parentAcc.Id;
            enrl.Learning_Style__c = studentAcc.Learning_Style__c;
            enrl.Student__c    = studentAcc.Id;
            enrl.Type__c       = ConstantsClass.typeTrial;
            enrl.Stage__c      = ConstantsClass.requestedSubStatus;
            enrl.Center__c     = slcdCenter;
            enrl.Teacher__c    = slcdTechr;
            enrl.Previous_Experience_if_any__c  = stuPreExperience;
            enrl.Cancellation_Policy_Agreed__c  = true;
            enrl.I_want_to_receive_latest_newsletter__c = iWantReceivedLatestNew;
            if(packLst.size() > 0)
                enrl.Package__c = packLst.get(0).Id;
            
            if(String.isNotBlank(slcdDate))
                enrl.Trial_Date__c = date.Parse(slcdDate);
            
            if(String.isNotBlank(slcdSlot)){
                List<String> timeList = slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                enrl.Trial_Start_Time__c = startTime;
            }
            
            if(String.isNotBlank(formName))
                enrl.Form_Name__c = formName;
            
             //Added by Rajesh, 6th Aug 2019. To store trial source on enrolment/case object 
            if(String.isNotBlank(trialSource))
                enrl.Trial_Source__c = trialSource;
            
            insert enrl;
            
            if(String.isNotBlank(slcdDate) && String.isNotBlank(slcdSlot)){
                String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();    
                
                List<Booking__c> bookList = new List<Booking__c>();
                Booking__c book = new Booking__c(Student__c = studentAcc.Id, Teacher_Account__c = slcdTechr, Enrolment__c = enrl.Id);
                book.Center__c =  slcdCenter;
                book.Type__c   = ConstantsClass.typeTrial;
                book.Status__c = ConstantsClass.statusPending;
                book.RecordTypeId = bookLessRecId;
                if(packLst.size() > 0)
                    book.Package__c = packLst.get(0).Id;
                
                List<String> timeList = slcdSlot.split(':');                
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                book.Start_Time__c = startTime;
                book.End_Time__c = book.Start_Time__c.addMinutes(30);
                book.Booking_Date__c = date.Parse(slcdDate);
                bookList.add(book);
                
                if(isAureusAtHome){
                    String currDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                    List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,
                                                                            Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                                       FROM Teacher_Working_Hour__c 
                                                                      WHERE Teacher_Name__c =: slcdTechr AND Working_Day__c =: currDay AND Center_Name__c =: slcdCenter AND Active__c = true AND Break_Time__c = False 
                                                                            AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null 
                                                                            LIMIT 1];
                    
                    if(techWorkSchList.size() > 0 && techWorkSchList.get(0).Start_Time__c != startTime){
                        //Filling booking for the Before travel  
                        Booking__c befBook = new Booking__c(Student__c = studentAcc.Id, Teacher_Account__c = slcdTechr, Enrolment__c = enrl.Id);
                        befBook.RecordTypeId  = bookLessRecId;
                        befBook.Type__c    = ConstantsClass.busyBookingType;
                        book.Status__c 	   = ConstantsClass.scheduledStatus;
                        befBook.Category__c= 'Travel';
                        befBook.Remarks__c = 'Travel time slot for home trial booking';
                        if(packLst.size() > 0)
                            befBook.Package__c = packLst.get(0).Id;
                        befBook.Center__c =  slcdCenter;
                        befBook.Start_Time__c = book.Start_Time__c.addMinutes(-trvlDuration);
                        befBook.End_Time__c   = book.Start_Time__c;
                        befBook.Booking_Date__c = date.Parse(slcdDate);
                        bookList.add(befBook);    
                    }
                }
                
                insert bookList;
            }
            
            //return new pagereference('/apex/trialthankyou').setRedirect(true);
            return new pagereference(Label.Trial_booking_confirmation_url);
     /*  }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError = true;
            return null;
        }*/
    }
    public List<SelectOption> getAccoungGenderPicklist(){     
        return getPicklistValues('Account','Gender__c');
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
    public class AccountModel{
        public String firstName{get;set;}
        public String lastName{get;set;}
        //Added by Rajesh, 28th July 2019, to check that a student is already exist or not for a specific parent
        public String stuId{get;set;}
        public AccountModel(){
            this.firstName = firstName;
            this.lastName  = lastName;
        }
        
        //Added by Rajesh, 28th July 2019, to check that a student is already exist or not for a specific parent
        public AccountModel(String name, String stuId){
            this.lastName  = name;
            this.stuId 	   = stuId;
        }
    }
    
    public class TimeSlotModelCntrl{
        public List<String>  morningSlot{get;set;}
        public List<String>  afternoonSlot{get;set;}
        public List<TeacherModel> teachModList{get;set;}        
        public Boolean isAvlMrgSlot{get;set;}
        public Boolean isAvlAfternoonSlot{get;set;}
        
        Map<String, List<TeacherModel>> teachModSlotMap;
        
        public TimeSlotModelCntrl(){
            morningSlot   = new List<String>();
            afternoonSlot = new List<String>();
            teachModList  = new List<TeacherModel>();
            isAvlMrgSlot = false;
            isAvlAfternoonSlot = false;
            
            teachModSlotMap = new Map<String, List<TeacherModel>>();
        }
    }
    
    public class TeacherModel{
        public String tecId{get;set;}
        public String tecName{get;set;}
        public String teacBio{get;set;}
        public String teacBioDescribe{get;set;}
        public String highestQualification{get;set;}
        public List<String> highestQualificationLst{get;set;}
        
        public String attachmentId{get;set;}
        
        public TeacherModel(String tecId,String tecName,String teacBioCon,String highestQualification, List<String> highestQualificationLst){
            this.tecId   = tecId;
            this.tecName = tecName;
            this.teacBio = teacBioCon;
            this.teacBioDescribe = teacBioCon;
            this.highestQualification = highestQualification;
            this.highestQualificationLst = highestQualificationLst;
        }
    }
}