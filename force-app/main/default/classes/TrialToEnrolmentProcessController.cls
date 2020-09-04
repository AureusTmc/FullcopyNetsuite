public class TrialToEnrolmentProcessController{
    //First Page variables
    public Account parentAcc{get;set;}
    
    public StudentWrapper studentWrap{get;set;}
    public LessonWrapper lessonWrap{get;set;}
    public List<StudentWrapper> studentWrapList{get;set;}
    public Boolean       isAddMoreButtonCheck{get;set;}
    public String        buttonType{get;set;}
    public Boolean isParAlsoAStudent{get;set;}
    
    public Integer selectedStudentIndex{get;set;}
    public Integer selectedLessonIndex{get;set;}
    
   // public String slcdDate{get;set;}
    public String tSlotStr{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    
    //public string base64SignImg{get;set;}
    
   // public GrandTotalWrapper grndTotModel{get;set;}
    
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    
    //public string stripeToken{get;set;}
    
    public String enrolId{get;set;}
    public String bookId{get;set;}
    //Free trial Opportunity
    public Boolean isFreeTrialOpp{get;set;}
    //Opportunity freeTrailOpp;
    Enrolment__c freeTrailEnr;
    public string PersonMobilePhoneCustom{get;set;}  
    public TrialToEnrolmentProcessController(){
        PersonMobilePhoneCustom = '';
        String recId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        parentAcc    = new Account(RecordTypeId = recId);
        
        studentWrap = new StudentWrapper();
        lessonWrap  = new LessonWrapper();
        studentWrapList = new List<StudentWrapper>();
        isAddMoreButtonCheck = false;
        
        tSlotMap = new TimeSlotModelCntrl();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        
      //  grndTotModel = new GrandTotalWrapper();
        isError = false;
        errorMsg = '';
        
        isFreeTrialOpp = false;
        freeTrailEnr   = new Enrolment__c();
        bookId = ApexPages.currentPage().getParameters().get('id');
        
        
        if(String.isNotBlank(bookId)){  
            List<Booking__c> bookList = [SELECT Id,Name,Enrolment__c FROM Booking__c WHERE Id =:bookId AND Type__c = 'Trial' AND Enrolment__c != null];
            
            if(bookList.size() > 0){
                enrolId = bookList.get(0).Enrolment__c;
                List<Enrolment__c> enrList = [SELECT Id, Center__c, Teacher__c, Package__c, Package__r.Program__r.Instrument__c, Parent__r.Also_a_Student__c,
                                                     Student__c, Parent__c, Trial_Date__c, Trial_Start_Time__c, Center__r.Travel_Time__c
                                              FROM Enrolment__c
                                              WHERE Id =: enrolId AND Student__c != null AND Parent__c != null 
                                                    AND Center__c != null AND Teacher__c != null AND Package__c != null Limit 1];
                if(enrList.size() > 0){
                    freeTrailEnr      = enrList.get(0);
                    isFreeTrialOpp    = true;
                    
                    isParAlsoAStudent = freeTrailEnr.Parent__r.Also_a_Student__c;
                    
                    fromFreeTrial();
                }
            }else{
                //Trial booking is not available please contact with center admin
            }
        }else{
            //Please check booking error
            //Need to show error
            //fillCenterAndPlan();
        }
    }
    
    private void fromFreeTrial(){
         if(freeTrailEnr.Id != null){
            fillCenterAndPlan();    
            
            //Fetching Parent Account
            List<Account> accList = [SELECT Id, FirstName, LastName, PersonMobilePhone, PersonOtherPhone, PersonEmail, BillingCountryCode, Gender__c, Nationality__c, Phone, Occupation__c, BillingStreet, BillingCity, BillingPostalCode, BillingCountry
                                     FROM Account WHERE Id =: freeTrailEnr.Parent__c];
            if(accList.size() > 0){
                parentAcc = accList.get(0);
                PersonMobilePhoneCustom = accList.get(0).PersonMobilePhone;
            }    
            
            //Fetching Student Account
            accList = [SELECT Id, FirstName, LastName, PersonBirthdate, Learning_Style__c, Description, Gender__c, Nationality__c, School__c
                       FROM Account WHERE Id =: freeTrailEnr.Student__c];
            if(accList.size() > 0)
                studentWrap.student = accList.get(0);
            
            lessonWrap.selectedCenter = freeTrailEnr.Center__c;
            fetchPlans();
            String trailSlcdIns = freeTrailEnr.Package__r.Program__r.Instrument__c;
            for(SelectOption selOpt : lessonWrap.planOptions){
                String optPlanLbl = selOpt.getLabel();
                if(optPlanLbl.contains(trailSlcdIns)){
                    lessonWrap.selectedPlan  = selOpt.getValue(); 
                    break;
                }  
            }
            if(String.isNotBlank(lessonWrap.selectedPlan)){
                fetchTeachers();
                if(freeTrailEnr.Trial_Date__c != null && freeTrailEnr.Trial_Start_Time__c != null){
                   for(SelectOption selOpt : lessonWrap.teacherOptions){
                        String optTchrValue = selOpt.getValue();
                        if(optTchrValue == String.valueOf(freeTrailEnr.Teacher__c)){
                            lessonWrap.selectedTeacher =  freeTrailEnr.Teacher__c; 
                            break;
                        }  
                    }
                     
                    if(String.isNotBlank(lessonWrap.selectedTeacher)){
                        Date tempTrailDT = freeTrailEnr.Trial_Date__c.addDays(7);
                        lessonWrap.lessonSlcdDate = tempTrailDT.day()+'/'+tempTrailDT.month()+'/'+tempTrailDT.year() ;
                        //fetchTimeSlot();
                        
                        String minTmp = freeTrailEnr.Trial_Start_Time__c.minute() != 0 ?  (freeTrailEnr.Trial_Start_Time__c.minute() +'') : '00';
                        String tempTSlot = freeTrailEnr.Trial_Start_Time__c.hour() + ':' + minTmp;
                        lessonWrap.lessonSlctSlot = tempTSlot;
                        
                        fetchTimeSlot();
                    }
                }
            }
        }
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
    
    //  Method to add centers and plans.
    private void fillCenterAndPlan(){
        //  Fetching center recordtype to query the center accounts.
        String centerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        //  Creating selectoption for center.
        lessonWrap = new LessonWrapper();
        for(Account acc : [SELECT Id, Name,CentreName_Cust__c FROM Account WHERE RecordType.Id =: centerRecId AND Name IN:ConstantsClass.activatedCenNames AND CentreName_Cust__c != null ORDER BY CentreName_Cust__c])
            lessonWrap.centerOptions.add(new SelectOption(acc.Id, acc.CentreName_Cust__c));
    }
    
    //  Method to get plans based on the centers.
    public void fetchPlans(){
       
        String selCenter = lessonWrap.selectedCenter;
        
        lessonWrap.planOptions = new List<SelectOption>();
        lessonWrap.teacherOptions = new List<SelectOption>();
        
        lessonWrap.planOptions.add(new SelectOption('', '--None--'));
        lessonWrap.teacherOptions.add(new SelectOption('', '--None--'));
        
        tSlotMap = new TimeSlotModelCntrl();
        
        if(String.isNotBlank(selCenter)){
            String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
            for(Package__c pkg : [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name, Location__r.Travel_Time__c 
                                  FROM Package__c 
                                  WHERE Location__c =: selCenter AND Program__r.Status__c =: ConstantsClass.activeStatus AND Program__r.Instrument__c != NULL 
                                        AND Duration__c !=: ConstantsClass.trialStatus AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND
                                        Active__c = True AND (Type__c = 'Individual' OR Type__c = 'Home') AND RecordtypeId =: pkgLessRecId ORDER BY Program__r.Name,Duration__c]){
                lessonWrap.planOptions.add(new SelectOption(pkg.Id, pkg.Name));
                lessonWrap.selectedCenterName = pkg.Location__r.Name;
            }
        }
    }
    
    //  Method to get teachers based on the centers.
    public void fetchTeachers(){
        String selCenter = lessonWrap.selectedCenter; 
        String selPlan = lessonWrap.selectedPlan;           
        
        lessonWrap.teacherOptions = new List<SelectOption>();
        lessonWrap.teacherOptions.add(new SelectOption('', '--None--'));            
        tSlotMap = new TimeSlotModelCntrl();
        lessonWrap.selectedTeacher = '';
        lessonWrap.selectedTeacherName = '';
        
        List<Package__c> pkgLst = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name,Duration__c, Location__r.Name FROM Package__c WHERE Id =: selPlan];
        
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
                                                                   Teacher_Name__r.Major_Instruments_Disciplines__c includes(:pkgPrgInstrument)  ORDER BY Teacher_Name__r.Name]; 
           
           Map<String,String> tchrMap = new Map<String,String>();
           for(Teacher_Working_Hour__c teachWorkHour : techWorkSchList)
                tchrMap.put(teachWorkHour.Teacher_Name__c, teachWorkHour.Teacher_Name__r.Name);
           
           for(String tchrId: tchrMap.keySet())
                lessonWrap.teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
        }      
    }
    
    public void fetchTimeSlot(){
        
        String slcdCenter = lessonWrap.selectedCenter;
        String slcdTeacher = lessonWrap.selectedTeacher;
        system.debug('slcdTeacher'+slcdTeacher);
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
                            
                            String addTimeSlotTempKey =  lWrap.selectedCenter + ':' + lWrap.selectedPlan + ':' + lWrap.selectedTeacher + ':' +lWrap.lessonSlcdDate + ':' +stTimeTmp;
                            addTimeSlotMap.put(addTimeSlotTempKey, lWrap);
                            
                            startTime = startTime.addMinutes(15);
                        }
                    }
                }
            }
        }
        
        String addTimeSlotKey =  slcdCenter + ':' + lessonWrap.selectedPlan + ':' + slcdTeacher; 
        
        Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
        Map<String,Booking__c> bookDayMap = new Map<String,Booking__c>();
        Date startDt   = System.today();
        Date endDtTemp = startDt.addMonths(4);
        
        Set<String> bookTypeSet    = new Set<String>{'Regular'};
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled'};
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();   
        
        for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c, Status__c
                               FROM Booking__c 
                               WHERE Teacher_Account__c =: slcdTeacher AND RecordTypeId =: bookLessRecId
                               AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDtTemp) AND (Type__c IN: bookTypeSet AND Status__c IN: bookStatusSet)]){                        
           
               String key =  book.Booking_Date__c +':'+ book.Start_Time__c;
               bookMap.put(key, book);   
               
               String currDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
               key = currDay +':'+ book.Start_Time__c;
               bookDayMap.put(key, book);  
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
                    if(freeTrailEnr.Id == Label.Aureus_at_Home_Id && freeTrailEnr.Center__r.Travel_Time__c != null){
                        endTimeDef = endTimeDef + Integer.valueOf(freeTrailEnr.Center__r.Travel_Time__c); 
                    }
                    
                    //while(stTime < teachWorkSch.End_Time__c.addMinutes(-15)){
                    while(stTime <= teachWorkSch.End_Time__c.addMinutes(-endTimeDef)){
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
                                        DateTime tempTodayTime = System.now().addHours(4);
                                        DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                        
                                        //if(st > System.today() || (st == System.today() && stTime > currTime)){
                                        if(tempStDtTime > tempTodayTime){
                                            String dayKey  =  currDay + ':'+ stTime;
                                            
                                            //Checking that time slot is already added in student or not
                                            String cuDtStr = st.day() +'/'+ st.month()+'/'+ st.year();
                                            String minTmp = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                            String addTimeSlotKeyTemp = addTimeSlotKey + ':'+ cuDtStr +':'+ minTmp;
                                            
                                            if(!(bookDayMap.containsKey(dayKey) || addTimeSlotMap.containsKey(addTimeSlotKeyTemp))){                                            
                                                morningTimesTemp.add(stTime);   
                                            }    
                                        }
                                    }
                                    stTime = stTime.addMinutes(ConstantsClass.defaultMinutesDiffinSlot);
                                }else{
                                    //Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                    DateTime tempTodayTime = System.now().addHours(4);
                                    DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                        
                                    //if(st > System.today() || (st == System.today() && stTime > currTime)){
                                    if(tempStDtTime > tempTodayTime){
                                        String dayKey  =  currDay + ':'+ stTime;
                                        
                                        //Checking that time slot is already added in student or not
                                        String cuDtStr = st.day() +'/'+ st.month()+'/'+ st.year();
                                        String minTmp = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                        String addTimeSlotKeyTemp = addTimeSlotKey + ':'+ cuDtStr +':'+ minTmp;
                                        
                                        if(!(bookDayMap.containsKey(dayKey) || addTimeSlotMap.containsKey(addTimeSlotKeyTemp))){ 
                                            afternoonTimesTemp.add(stTime);
                                        }
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
        if(String.isNotBlank(lessonWrap.lessonSlcdDate))
            fetchTimeSlot();
    }
    
    public void editLesson(){
        if(selectedStudentIndex != null && selectedLessonIndex != null){
            StudentWrapper studentWrapTemp = studentWrapList.get(selectedStudentIndex);
            studentWrap.student =   studentWrapTemp.student;
            
            lessonWrap  = studentWrapTemp.lessonList.get(selectedLessonIndex);            
            fetchTimeSlot();
        }
    }
    
    public void deleteLesson(){
        if(selectedStudentIndex != null && selectedLessonIndex != null){
            if(selectedStudentIndex == selectedLessonIndex){
                studentWrapList.remove(selectedStudentIndex);
                //fillCenterAndPlan();  
            
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
        
        if(buttonType != null && buttonType.equalsIgnoreCase('EditRowBtn')  && selectedStudentIndex != null && selectedLessonIndex != null){
            studentWrapList[selectedStudentIndex].student = studentWrap.student;
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
        //studentWrap.lessonList[0] = lessonWrap;
        
        tSlotMap = new TimeSlotModelCntrl();
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        tSlotStr = '';
        buttonType = '';
        system.debug('#### '+studentWrapList.size());
    }
    
    public void saveStuAndLessonOnGrid(){
         if(buttonType != null && buttonType.equalsIgnoreCase('EditRowBtn')  && selectedStudentIndex != null && selectedLessonIndex != null){
            studentWrapList.get(selectedStudentIndex).student = studentWrap.student;
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
                }
                
                Integer lstSize = studentWrapList.size();
                studentWrapList.get(lstSize-1).lessonList.add(lessonWrap);  
            }
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
    }
    /*
    public void thirdScreenFeeCalculation(){
        Map<String,Package__c> packMap = new Map<String,Package__c>();
         
        for(StudentWrapper sWrap : studentWrapList){
            for(LessonWrapper lWrap : sWrap.lessonList){
                if(String.isNotBlank(lWrap.selectedPlan))
                    packMap.put(lWrap.selectedPlan, null);
            }
        }
        
        packMap = new Map<String,Package__c>([SELECT Id,Name,Program__c,Deposit_Fee__c,Registration_Fee__c,Package_Fee__c,Unit_Fee__c,Duration__c,
                                                     Program__r.Billing__c,Program__r.Scheduling__c  
                                              FROM Package__c WHERE Id IN: packMap.keySet()]);
        
        for(StudentWrapper sWrap : studentWrapList){
            for(LessonWrapper lWrap : sWrap.lessonList){
                if(String.isNotBlank(lWrap.selectedPlan) && packMap.get(lWrap.selectedPlan) != null){
                    Package__c pack = packMap.get(lWrap.selectedPlan);
                    
                    lWrap.selPckMonthFees = pack.Package_Fee__c;
                    lWrap.depFees  = pack.Deposit_Fee__c;
                    lWrap.regiFees = pack.Registration_Fee__c;
                    
                    if(String.isNotBlank(lWrap.lessonSlcdDate) && pack.Unit_Fee__c > 0){
                        Date lessDate = date.Parse(lWrap.lessonSlcdDate);
                        lWrap.prgFees = BillingUtility.calculateCurrentMonthPckFees(lessDate, pack.Unit_Fee__c);
                    }
                    
                    Decimal totTemp = lWrap.regiFees + lWrap.prgFees;
                    
                    Integer gstTaxPer = ConstantsClass.defGST;
                    try{
                        gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                    }catch(Exception e){}
                    
                    lWrap.gstAmt = totTemp > 0 ? ((totTemp * gstTaxPer) / 100):0;
                    
                    lWrap.totAmt = totTemp + lWrap.gstAmt;
                    
                    lWrap.gstAmt = lWrap.gstAmt.setScale(2);
                    lWrap.totAmt = lWrap.totAmt.setScale(2);
                    
                    grndTotModel.feesTot += lWrap.totAmt;
                    grndTotModel.depositTot += lWrap.depFees != null ? lWrap.depFees : 0;
                    
                    lWrap.slcdPakgPrgBillingType = pack.Program__r.Billing__c;
                    lWrap.slcdPakgPrgScdlType    = pack.Program__r.Scheduling__c;
                    
                    try {
                        lWrap.pkgDuration = Integer.valueOf(pack.Duration__c);
                    }Catch (exception e) {}
                }   
            }
        }
        
        grndTotModel.grandTot = grndTotModel.feesTot + grndTotModel.depositTot;
        
        grndTotModel.feesTot    = grndTotModel.feesTot.setScale(2);
        grndTotModel.depositTot = grndTotModel.depositTot.setScale(2);
        grndTotModel.grandTot   = grndTotModel.grandTot.setScale(2);
    }
    */
    
    public void completeEnrolment(){
        Savepoint sp = Database.setSavepoint();
        isError = false;
        errorMsg = '';
        
        try{         
            
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();    
            
            //Check that customer is already exist or not on the bases of email
            if(parentAcc.Id == null && parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
                if(accList.size() > 0)
                    parentAcc.Id = accList.get(0).Id;
            }
            parentAcc.PersonMobilePhone = PersonMobilePhoneCustom;
            upsert parentAcc;
            
            //Inserting subscription
            Date subTempDt       = System.today().addMonths(1);
            
           /* Subscription__c subs = new Subscription__c();
            List<Subscription__c> subList = [SELECT Id FROM Subscription__c  WHERE Parent__c =:parentAcc.Id AND Status__c =: 'Active'];
            if(subList.size() > 0){
                subs = subList.get(0);
            }else{
                Date subsDt = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                subs = BillingUtility.fillSubscription(parentAcc.Id, ConstantsClass.activeStatus, subsDt);
                if(studentWrapList.size() > 0){
                    if(studentWrapList.get(0).lessonList.size() >0)
                        subs.Center__c = studentWrapList.get(0).lessonList.get(0).selectedCenter;
                }
                insert subs;
            }*/
            
            Set<String> centSet = new Set<String>();
            Set<String> tchrSet = new Set<String>();
            Set<String> daySet = new Set<String>();
            Map<String,Teacher_Working_Hour__c> tcrWrkHourMap = new Map<String,Teacher_Working_Hour__c>();
            for(StudentWrapper stu : studentWrapList){
                for(LessonWrapper lw : stu.lessonList){
                    if(lw.selectedCenter == Label.Aureus_at_Home_Id){
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
            
            List<Account> studentList = new List<Account>(); 
            List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
            List<Booking__c> bookList = new List<Booking__c>();
            
            Integer counter = 0;
            for(StudentWrapper stu : studentWrapList){
                Account stdnt = new Account();
                if(isParAlsoAStudent && counter == 0){
                    stdnt = parentAcc;
                    stdnt.Also_a_Student__c = true;
                    stdnt.PersonBirthdate   = stu.student.PersonBirthdate;
                    stdnt.Gender__c = stu.student.Gender__c;
                    stdnt.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                }else{
                    stdnt = stu.student;
                    stdnt.Parent__c = parentAcc.Id;
                    stdnt.Current_Engagement_Status__c = ConstantsClass.activeStatus; 
                }
                counter = counter+1;
                studentList.add(stdnt);                         
                
                for(LessonWrapper lw : stu.lessonList){
                    
                    //Filling custom enrolment
                   // String enrName  =  String.isNotBlank(stdnt.FirstName) ? stdnt.FirstName + ' ' : '';
                    //enrName += String.isNotBlank(stdnt.LastName)  ? stdnt.LastName : '';
                    
                    Date lessDt; 
                    if(String.isNotBlank(lw.lessonSlcdDate))
                        lessDt =  date.Parse(lw.lessonSlcdDate);
                    
                    Time startTime;
                    if(String.isNotBlank(lw.lessonSlctSlot)){
                        List<String> timeList = lw.lessonSlctSlot.split(':');
                        
                        startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                    }
                    Enrolment__c enrl   = BillingUtility.fillEnrolment(parentAcc.Id, null, lw.selectedCenter, lw.selectedTeacher, lw.selectedPlan, lessDt, startTime, ConstantsClass.requestedSubStatus);
                    enrl.Student__r     = stdnt;
                    enrl.Cancellation_Policy_Agreed__c = true;
                    enrl.Type__c        = 'Trial';
                    enrl.Trial_Requested_Date__c       = System.Now();
                    enrolmentList.add(enrl);
                    
                    //Populating Booking list
                    if(String.isNotBlank(lw.lessonSlcdDate)){
                        Date lessDate = date.Parse(lw.lessonSlcdDate);
                        
                        Date stDate  = lessDate;
                        Date endDate = stDate.addMonths(12); 
                        
                        Integer numberOfDays = Date.daysInMonth(endDate.year(), endDate.month());
                        Date lastDayOfEndDateMonth = Date.newInstance(endDate.year(), endDate.month(), numberOfDays);
                        
                        Date dt=lessDate;   
                        Integer countBookingForMonth = 0;
                        Date currLesDt; 
                        while(dt<=lastDayOfEndDateMonth){
                            Boolean isCreateBooking = false;
                            if(currLesDt == null)
                                currLesDt = dt;
                            
                            if(currLesDt.month() == dt.month()){
                                if(countBookingForMonth < 4){
                                    countBookingForMonth = countBookingForMonth+1;
                                    isCreateBooking = true;
                                }
                            }else{
                                currLesDt = dt;
                                countBookingForMonth = 1;
                                isCreateBooking = true;
                            }
                            
                            if(isCreateBooking){
                            
                                bookList.add(TrialToEnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, ConstantsClass.pendingStatus, dt));
                                
                                //Adding trial time during Aureus at home center
                                if(freeTrailEnr.Center__c == Label.Aureus_at_Home_Id && freeTrailEnr.Center__r.Travel_Time__c != null){
                                    
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
                                            Integer trvlDuration = Integer.valueOf(freeTrailEnr.Center__r.Travel_Time__c);     
                                            //Traveling booking Before
                                            Booking__c befBook = TrialToEnrolmentProcessController.fillBook(stdnt, lw, bookLessRecId, enrl, '', dt);
                                            befBook.Type__c       = ConstantsClass.busyBookingType;
                                            befBook.Remarks__c    = 'Booking for before trial';
                                            befBook.Start_Time__c = befBook.Start_Time__c.addMinutes(-trvlDuration);
                                            befBook.End_Time__c   = befBook.Start_Time__c;
                                            bookList.add(befBook);
                                        }
                                    }
                                }
                            }
                            
                            dt = dt.addDays(7);
                        }
                    }
                }
            }
            
             System.debug('@@@@'+bookList);
            
            if(studentList.size() > 0){
                if(freeTrailEnr.Student__c != null)
                    studentList.get(0).Id = freeTrailEnr.Student__c;
                upsert studentList;
                
                if(enrolmentList.size() > 0){
                    for(Enrolment__c enr : enrolmentList)
                        enr.Student__c = enr.Student__r.Id; 
                    
                    if(freeTrailEnr.Id != null){
                        enrolmentList.get(0).Id = freeTrailEnr.Id;
                    }
                    upsert enrolmentList;
                    
                    /*
                    if(subLinItmList.size() > 0){
                        for(Subscription_Line_Item__c subsItm:subLinItmList){
                            subsItm.Student__c = subsItm.Student__r.Id;
                            subsItm.Enrolment__c = subsItm.Enrolment__r.Id;
                        }
                        insert subLinItmList;
                    }*/
                    
                    if(bookList.size() > 0){
                        for(Booking__c book:bookList){
                            book.Student__c = book.Student__r.Id;
                            book.Enrolment__c = book.Enrolment__r.Id;
                        }
                        insert bookList;
                    }
                }
            }
            System.debug('@@@@'+bookList);
        }catch(Exception e){
            Database.rollback(sp);
            
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError  = true;
           // return null;
        }
                  
        //return new PageReference('/apex/Thankyoupage');
    } 
    
    @RemoteAction
    public static Boolean sendEmail(String subject, String body, String parentId){
        System.debug('Send Email '+subject+' - -'+body+ '-- '+parentId);
        Boolean Success = false;
        String emailAddress = '';
        String targetId = '';
        if(String.isNotBlank(parentId)){
            List<Account> accList = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE RecordType.Name = 'Customer' AND Id =:parentId ];
            if(accList.size() > 0){
                emailAddress = accList[0].PersonEmail;
                targetId = accList[0].PersonContactId;
            }
        }
        if(String.isNotBlank(emailAddress) && String.isNotBlank(subject) && String.isNotBlank(body)){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {emailAddress};
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Aureus Calendar');
            if(String.isNotBlank(targetId)){
                mail.setTargetObjectId(targetId);
            }
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setSaveAsActivity(true);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            Success = true;
        }
        
        return Success;
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
    
    public class StudentWrapper{
        public Account student{get;set;}
       
        public List<LessonWrapper> lessonList{get;set;}
        public StudentWrapper(){
            String recId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
            student = new Account(RecordTypeId = recId);
            
            lessonList = new List<LessonWrapper>();
        }
    }
    
    public class LessonWrapper{
        public String selectedCenter{get;set;}
        public String selectedPlan{get;set;}
        public String selectedTeacher{get;set;}
        public String lessonSlcdDate{get;set;}
        public String lessonSlctSlot{get;set;}
        
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
        public Decimal regiFees{get;set;}
        public Decimal totAmt{get;set;}
        public Decimal gstAmt{get;set;}
        
        Integer pkgDuration;
        String  slcdPakgPrgBillingType;
        //String  slcdPakgPrgScdlType;
        public LessonWrapper(){
            centerOptions = new List<SelectOption>();
            planOptions = new List<SelectOption>();
            teacherOptions = new List<SelectOption>();
            
            centerOptions.add(new SelectOption('', '--None--'));
            planOptions.add(new SelectOption('', '--None--'));
            teacherOptions.add(new SelectOption('', '--None--'));
            
            lessonSlcdDate = System.today().day()+'/'+System.today().month()+'/'+System.today().year() ;
            
            //---------Fee intialisation
            selPckMonthFees = depFees = prgFees = regiFees = totAmt = gstAmt = pkgDuration = 0;
        }
    }
}