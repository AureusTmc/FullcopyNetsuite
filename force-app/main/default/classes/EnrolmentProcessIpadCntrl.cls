public class EnrolmentProcessIpadCntrl {

   // public String count { get; set; }
    public List<StudentWrapper> studentWrapList{get;set;} 
    public Integer selectedIndex{get;set;}
    public String  slcdDate{get;set;}
    public String  slcdSlot{get;set;}
    
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    public Boolean isAmcClubMember{get;set;}
    public String userAuthCode{get;set;}
    public Boolean isSiteGuestUser{get;set;}
    
    public Integer currSlcd{get;set;}   
    public String perEmail{get;set;}
    
    public String slcdLsnType{get;set;}
    
    //Added by Rajesh, 16th Sep 2019. To store enrolment source on Enrolment/Case object and country for filtercentre
    String enrolmentSource;
    String countryCode;
    string currentOrg;//@Juneid 19 Aug 2020, Storing current organization id
    public string defaultOrg{get;set;}//@Juneid 19 Aug 2020, Storing current users organization name
    public string pagetype{get;set;}// nishi: 5Feb2021: Aureus Q1 2021 : for get page name is found that means user use direct entolment process
    public EnrolmentProcessIpadCntrl(){
        studentWrapList = new List<StudentWrapper>();
        isAmcClubMember = false;
        isSiteGuestUser = (UserInfo.getName()).contains('Site');
        currSlcd = 1;  
        selectedIndex=1;
        slcdLsnType = 'Individual';
        Set<String> enrIds = new Set<String>();
        system.debug('currebt org -->'+ApexPages.currentPage().getParameters().get('currentOrg'));
        currentOrg = ApexPages.currentPage().getParameters().get('currentOrg');//@Juneid 19 Aug 2020, Current Organization id
        system.debug('org default--->'+ApexPages.currentPage().getParameters().get('orgType'));
        defaultOrg = ApexPages.currentPage().getParameters().get('orgType');
        // nishi: 5Feb2021: Aureus Q1 2021 : for get page name is found that means user use direct entolment process
        if(string.isnotBlank(ApexPages.currentPage().getParameters().get('pagetype'))){
            pagetype= ApexPages.currentPage().getParameters().get('pagetype');
        }
        // nishi: 5Feb2021:end: Aureus Q1 2021 : for get page name is found that means user use direct entolment process

        Map<String, String> params  =  ApexPages.currentPage().getParameters(); 
        if(params != null && params.size() > 0){
            for(String strKey : params.keySet()){
                if(strKey == 'es')
                    enrolmentSource = params.get(strKey);
                else   
                    enrIds.add(params.get(strKey));
                /*else if(strKey == 'country')
                    countryCode  = params.get(strKey);
                else   
                    enrIds.add(params.get(strKey)); */
            }
        }
        
         //Added by Rajesh, 7th Aug 2019. country for filtercentre
        //if(String.isBlank(countryCode))
            //countryCode = 'HK';
        
        if(enrIds.size() > 0){     
            //Updated by Rajesh: 12th Nov 2011, Added lost condition for the pardot trial as per discussion with Ashish ji
            List<Enrolment__c> enrList = new List<Enrolment__c>();
            // nishi: 5Feb2021: Aureus Q1 2021 : for get page name is found that means user use direct entolment process
            if(string.isNotBlank(pagetype)){
                enrList = [SELECT Id, Center__c, Teacher__c, Package__c, Package__r.Type__c,Package__r.Duration__c, Package__r.Program__r.Instrument__c, Parent__r.Also_a_Student__c, Parent__r.Personemail,
                                    Student__c, Student__r.Name, Parent__c, Parent__r.Name, Trial_Date__c, Trial_Start_Time__c, Center__r.Travel_Time__c, Center__r.Name, Parent__r.Is_Club_Member__c,
                                    Parent__r.Membership_Type__c, Parent__r.personContactId, Lessons_Start_Date__c, Lesson_Start_Time__c,Type__c,Stage__c,
                                Center__r.Country__r.Name
                            FROM Enrolment__c
                            WHERE Id IN: enrIds AND (Type__c = 'Trial' OR Type__c = 'Group') 
                            AND Student__c != null AND Parent__c != null AND 
                            Stage__c =: ConstantsClass.enrollStageAttended
                            AND Center__c != null ORDER BY Student__c];
            }else{
                // nishi: 5Feb2021: Aureus Q1 2021 : end: for get page name is found that means user use direct entolment process
             enrList = [SELECT Id, Center__c, Teacher__c, Package__c, Package__r.Type__c,Package__r.Duration__c, Package__r.Program__r.Instrument__c, Parent__r.Also_a_Student__c, Parent__r.Personemail,
                                Student__c, Student__r.Name, Parent__c, Parent__r.Name, Trial_Date__c, Trial_Start_Time__c, Center__r.Travel_Time__c, Center__r.Name, Parent__r.Is_Club_Member__c,
                                Parent__r.Membership_Type__c, Parent__r.personContactId, Lessons_Start_Date__c, Lesson_Start_Time__c,Type__c,Stage__c,
                            Center__r.Country__r.Name
                        FROM Enrolment__c
                        WHERE Id IN: enrIds AND (Type__c = 'Trial' OR Type__c = 'Group') AND Student__c != null AND Parent__c != null AND 
                        ((Stage__c =: ConstantsClass.enrollStageAttended AND Trial_Date__c != null AND Trial_Start_Time__c != null) OR 
                        (Stage__c =: ConstantsClass.enrollStageLost AND Trial_Date__c != null AND Trial_Start_Time__c != null) OR
                        (Stage__c =: ConstantsClass.PendingEnrolment AND Lessons_Start_Date__c != null AND Lesson_Start_Time__c != null))
                        AND Center__c != null  AND Teacher__c != null AND Package__c != null ORDER BY Student__c];
            }
            
            if(enrList.size() > 0){
                countryCode = String.isNotBlank(enrList.get(0).Center__r.Country__r.Name) ? enrList.get(0).Center__r.Country__r.Name : 'SG';
                
                list<SelectOption> centOpt = getCenters();
                for(Enrolment__c enr: enrList){
                    StudentWrapper st = new StudentWrapper();
                    LessonWrapper lsn = new LessonWrapper();
                    
                    st.enrl = enr;
                    st.stuAcc = new Account(Id = enr.Student__c, Name = enr.Student__r.Name);
                    lsn.selectedCenter = enr.Center__c;
                    lsn.selectedTeacher = enr.Teacher__c;     
                    lsn.selectedTeacherT = enr.Teacher__c;   
                    lsn.centerOptions = centOpt;
                    
                    Date tempDT;
                    Time tempTime;
                    
                    if(string.isBlank(pagetype)){// nishi: 5Feb2021: Aureus Q1 2021 : for get page name is found that means user use direct entolment process
                        if(enr.Stage__c.equalsIgnoreCase('Attended') && enr.Trial_Date__c != null && enr.Trial_Start_Time__c != null ){
                            tempDT= enr.Trial_Date__c.addDays(7);
                            tempTime= enr.Trial_Start_Time__c;
                        //Updated by Rajesh: 12th Nov 2011, Added lost condition for the pardot trial as per discussion with Ashish ji
                        }else if(enr.Stage__c.equalsIgnoreCase('Lost') && enr.Trial_Date__c != null && enr.Trial_Start_Time__c != null){
                            tempDT= enr.Trial_Date__c.addDays(7);
                            tempTime= enr.Trial_Start_Time__c;
                        }else if(enr.Stage__c.equalsIgnoreCase('Pending Enrolment') && enr.Lessons_Start_Date__c != null && enr.Lesson_Start_Time__c != null){
                            tempDT = enr.Lessons_Start_Date__c;
                            tempTime = enr.Lesson_Start_Time__c;
                        }
                        if(tempDT != null && tempTime != null){
                            lsn.lessonSlcdDate = tempDT.day()+'/'+tempDT.month()+'/'+tempDT.year() ;
                            lsn.lessonSlcdDateD = tempDT;
                            
                            String minTmp = tempTime.minute() != 0 ?  (tempTime.minute() +'') : '00';
                            String tempTSlot = tempTime.hour() + ':' + minTmp;
                            lsn.lessonSlctSlot = tempTSlot;
                            lsn.lessonSlctSlotT = DateTime.newInstance(tempDT, tempTime).format('hh:mm a');
                        }
                    }
                    st.lesson = lsn;
                    
                    studentWrapList.add(st);
                
                }     
                
                //Process for first enrolment
                StudentWrapper st  =  studentWrapList.get(0);               
                st.lesson.teacherOptions= fetchTeachers(st.lesson);
                Boolean isTrialAtt = true;
                if(st.enrl.Stage__c.equalsIgnoreCase('Pending Enrolment')){
                    isTrialAtt = false;      
                    if(string.isNotBlank(st.enrl.Package__c) && string.isBlank(pagetype)){  // nishi: 5Feb2021: Aureus Q1 2021 : for get page name is found that means user use direct entolment process            
                        st.lesson.selectedPlan = st.enrl.Package__c;
                        st.lesson.pkgDuration  = Integer.valueOf(st.enrl.Package__r.Duration__c);
                    }
                }
                st.lesson.planOptions   =  fetchPlans(st.lesson, isTrialAtt);
                
                //fetchTimeSlot(st.lesson);
                // nishi: 5Feb2021: Aureus Q1 2021 : for get page name is found that means user use direct entolment process
                //fetchTimeSlot(st);
                if(string.isBlank(pagetype) && (enrList.get(0).Trial_Date__c != null && enrList.get(0).Trial_Start_Time__c != null) || (enrList.get(0).Lessons_Start_Date__c != null && enrList.get(0).Lesson_Start_Time__c != null)){
                    fetchTimeSlot(st);
                }
                // nishi: 5Feb2021: Aureus Q1 2021 end: for get page name is found that means user use direct entolment process
                
                if(enrList.get(0).Parent__r.Is_Club_Member__c && enrList.get(0).Parent__r.Membership_Type__c == ConstantsClass.amcClubMember)
                    isAmcClubMember = true;
                
                perEmail = enrList.get(0).Parent__r.PersonEmail;
            }
        }
        
        List<User> usrList = [SELECT Id,Name,Authentication_code__c FROM User WHERE Id=:Userinfo.getUserId() AND Authentication_code__c != null];
        if(usrList.size() > 0){
            userAuthCode = usrList.get(0).Authentication_code__c;
        }
    }
    
    private list<SelectOption> getCenters(){
        list<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        
        String centerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        if(slcdLsnType.equalsIgnoreCase('Individual')){
            //@Juneid 19 Aug 2020, Organization ise centre logic
            for(Account acc : [SELECT Id, Name,CentreName_Cust__c FROM Account WHERE (RecordType.Id =: centerRecId AND Centre_Status__c =:ConstantsClass.activeStatus) AND (CentreName_Cust__c != null AND Country__r.Name =:countryCode) AND Organisation__c=:currentOrg ORDER BY CentreName_Cust__c])
                options.add(new SelectOption(acc.Id, acc.CentreName_Cust__c));
        }else if(slcdLsnType.equalsIgnoreCase('Group')){
            Map<Id,String> centMap = new Map<Id,String>();
            for(Class__c cls : [SELECT Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.CentreName_Cust__c FROM Class__c 
                               WHERE Centre_Name__r.RecordType.Id =: centerRecId AND Centre_Name__r.Centre_Status__c =:ConstantsClass.activeStatus 
                               AND Centre_Name__r.CentreName_Cust__c != null AND Centre_Name__r.Country__r.Name =:countryCode 
                                // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                And Is_Makeup_Class__c = false
                               ORDER BY Centre_Name__r.CentreName_Cust__c
                               ]){
                centMap.put(cls.Centre_Name__c, cls.Centre_Name__r.CentreName_Cust__c);
            }
            if(centMap.size() > 0){
                for(String strKey : centMap.keySet())
                    options.add(new SelectOption(strKey, centMap.get(strKey)));
            }            
        }
        return options;
    }
    
     //  Method to get teachers based on the centers.
    private list<SelectOption> fetchTeachers(LessonWrapper lessonWrap){
        String selCenter = lessonWrap.selectedCenter;
        List<SelectOption> teacherOptions = new List<SelectOption>();
        teacherOptions.add(new SelectOption('', '--None--'));
        
        String teacherRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();
        
        if(lessonWrap.selectedLsnType.equalsIgnoreCase('Individual')){
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Center_Name__c =: selCenter AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                             (Teacher_Name__r.Major_Instruments_Disciplines__c != null OR Teacher_Name__r.Minor_Instruments_Disciplines__c != null) ORDER BY Teacher_Name__r.Name]; 
            
            Map<String,String> tchrMap = new Map<String,String>();
            for(Teacher_Working_Hour__c teachWorkHour : techWorkSchList)
                tchrMap.put(teachWorkHour.Teacher_Name__c, teachWorkHour.Teacher_Name__r.Name);
            
            for(String tchrId: tchrMap.keySet())
                teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
        }else if(lessonWrap.selectedLsnType.equalsIgnoreCase('Group')){
            List<Class__c> clsList = [SELECT Id,Name,Teacher__c,Teacher__r.Name FROM Class__c WHERE Centre_Name__c =: selCenter AND Active__c= true
                                        // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                        And Is_Makeup_Class__c = false]; 
            
            Map<String,String> tchrMap = new Map<String,String>();
            for(Class__c cls : clsList)
                tchrMap.put(cls.Teacher__c, cls.Teacher__r.Name);
            
            for(String tchrId: tchrMap.keySet()){
                if(string.isNotBlank(tchrId)&& tchrMap.containskey(tchrId))
                	teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
            }
        }
        return teacherOptions;
    }        
    
    public list<SelectOption> fetchPlans(LessonWrapper lessonWrap, Boolean isSelectDefPkg){
        list<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        
        if(String.isNotBlank(lessonWrap.selectedCenter) && String.isNotBlank(lessonWrap.selectedTeacher)){
            String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
            if(lessonWrap.selectedLsnType.equalsIgnoreCase('Individual')){
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
                List<Package__c> pkgList = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name, Location__r.Travel_Time__c, Type__c, Duration__c  
                                            FROM Package__c 
                                            WHERE Location__c =: lessonWrap.selectedCenter AND Program__r.Status__c =: ConstantsClass.activeStatus  AND Program__r.Instrument__c IN:instrumentTempSet
                                                AND Duration__c !=: ConstantsClass.trialStatus AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND
                                                Active__c = True AND (Type__c = 'Individual' OR Type__c = 'American Club') AND RecordtypeId =: pkgLessRecId 
                                                AND (Type_of_package__c = 'Normal' OR Type_of_package__c = 'Promo')
                                                ORDER BY Program__r.Name,Duration__c];
                if(pkgList.size() > 0){
                    //Added by Rajesh on 12th Dec 2019
                    List<String> pkgIds = new List<String>();
                    for(Package__c pkg : pkgList){
                        Boolean isAddPkg = false;
                        if(isAmcClubMember){
                            if(pkg.Type__c == 'American Club')                       
                                isAddPkg = true;
                        }else if(pkg.Type__c == 'Individual'){
                            isAddPkg = true;
                        }
                        
                        if(isAddPkg){
                            options.add(new SelectOption(pkg.Id, pkg.Name)); 
                            //Added by Rajesh on 12th Dec 2019
                            pkgIds.add(pkg.Id);
                        }
                    }
                    if(isSelectDefPkg){
                        //Updated by Rajesh on 12th Dec 2019
                       // lessonWrap.selectedPlan = pkgList.get(0).Id;
                        lessonWrap.selectedPlan = pkgIds.get(0);
                        lessonWrap.pkgDuration  = Integer.valueOf(pkgList.get(0).Duration__c);
                    }
                }
            }else if(lessonWrap.selectedLsnType.equalsIgnoreCase('Group')){
                Set<String> pkgSet = new Set<String>();
                // Start :added by nishi: 1-sep-2020: for if class related to ossia organisation then we show package list into  
                //new created object Ossia_Group_Grade_Packages__r other wise we get package list into package field 
                if(defaultOrg=='ossia'){ 
                    for(Class__c cls: [SELECT Id,Name,Package__c,Package__r.Name,
                                        Package__r.Type__c,Package__r.RecordtypeId,Package__r.Type_of_package__c,
                                        Centre_Name__r.Organisation__r.Name,
                                        (SELECT Class_Name__c, Package__c,Package__r.Name,  Name, Id ,
                                            Package__r.Type__c,Package__r.RecordtypeId,Package__r.Type_of_package__c
                                            FROM Ossia_Group_Grade_Packages__r 
                                            WHERE  Package__r.Type__c = 'Group' 
                                            AND Package__r.RecordtypeId =: pkgLessRecId 
                                            AND (Package__r.Type_of_package__c = 'Normal' 
                                            OR Package__r.Type_of_package__c = 'Promo')
                                            ORDER BY Package__r.Program__r.Name, Package__r.Duration__c)
                                        FROM Class__c 
                                        WHERE Centre_Name__c =:  lessonWrap.selectedCenter
                                        AND Teacher__c =: lessonWrap.selectedTeacher 
                                        AND Active__c = True 
                                        AND Available_Capacity__c > 0 
                                         // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                         And Is_Makeup_Class__c = false
                                    ]){
                        if(string.isNotBlank(cls.Centre_Name__c) && string.isNotBlank(cls.Centre_Name__r.Organisation__c) &&
                        cls.Centre_Name__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                            if(cls.Ossia_Group_Grade_Packages__r != null && cls.Ossia_Group_Grade_Packages__r.size() > 0){
                                for(Ossia_Group_Grade_Package__c objpackage: cls.Ossia_Group_Grade_Packages__r){
                                    if(!pkgSet.contains(objpackage.Package__c)){
                                        pkgSet.add(objpackage.Package__c);
                                        options.add(new SelectOption(objpackage.Package__c, objpackage.Package__r.Name));                 
                                    }
                                }
                            }
                        }
                    }
                }
                // End :added by nishi: 1-sep-2020: for if class related to ossia organisation then we show package list into  
                //new created object Ossia_Group_Grade_Packages__r other wise we get package list into package field 
                else{
                    for(Class__c cls: [SELECT Id,Name,Package__c,Package__r.Name,
                                        Package__r.Type__c,Package__r.RecordtypeId,Package__r.Type_of_package__c
                                            FROM Class__c 
                                            WHERE Centre_Name__c =:  lessonWrap.selectedCenter
                                            AND Teacher__c =: lessonWrap.selectedTeacher 
                                            AND Active__c = True 
                                            AND Available_Capacity__c > 0 
                                             // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                             And Is_Makeup_Class__c = false
                                           ]){
                            if(!pkgSet.contains(cls.Package__c)){
                                pkgSet.add(cls.Package__c);
                                options.add(new SelectOption(cls.Package__c, cls.Package__r.Name));                 
                            }
                    }
                }
                
            }
        }
        return options;
    }
    
    public void slcdLessonType(){
       // slcdLsnType
        /*list<SelectOption> centOpt = getCenters();
        
        for(StudentWrapper st : studentWrapList){            
            LessonWrapper lsn = new LessonWrapper();
            lsn.centerOptions = centOpt;
            
            st.lesson = lsn;
        }*/
        if(selectedIndex > 0){
            Integer selectedInd = selectedIndex-1;
            if(String.isNotBlank(slcdLsnType)){
                StudentWrapper stuWrap = studentWrapList.get(selectedInd);
               
                LessonWrapper lsn = new LessonWrapper();
                lsn.centerOptions = getCenters();
                lsn.selectedLsnType= slcdLsnType;
                
                stuWrap.lesson = lsn;
            }
        }
    }
    
    //public void fetchTimeSlot(LessonWrapper lessonWrap){
    public void fetchTimeSlot(StudentWrapper stuWrap){
        //List<Package__c> pkgLst = [SELECT Id, Name, Program__r.Instrument__c, Program__c, Program__r.Name,Duration__c, Location__r.Name 
          //                         FROM Package__c WHERE Id =: lessonWrap.selectedPlan];
        
        LessonWrapper lessonWrap = stuWrap.lesson;
        String slcdCenter = lessonWrap.selectedCenter;
        String slcdTeacher = lessonWrap.selectedTeacher;
        Map<String,TimeSlotModelCntrl> tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        
        if(stuWrap.lesson.selectedLsnType.equalsIgnoreCase('Individual')){
            Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Engagement_Type__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,
                                                             Start_Time__c,End_Time__c,Active__c
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Center_Name__c =: slcdCenter AND Active__c = true AND Working_Day__c != null AND 
                                                             Break_Time__c = False AND Teacher_Name__c =: slcdTeacher];
            
            //lessonWrap.selectedTeacherName = techWorkSchList.size() > 0 ? techWorkSchList.get(0).Teacher_Name__r.Name : '';
            
            for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){                                                               
                List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
                if(tchList == null)
                    tchList = new List<Teacher_Working_Hour__c>();
                
                tchList.add(tchWrkSch);                                                  
                teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);                                                  
            }
            
            Map<String,LessonWrapper> addTimeSlotMap = new Map<String,LessonWrapper>();
            /*        
            for(StudentWrapper sWrap : studentWrapList){
                LessonWrapper lWrap = sWrap.lesson;
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
           */
            
           // String addTimeSlotKey =  slcdCenter + ':' + lessonWrap.selectedPlan + ':' + slcdTeacher; 
            String addTimeSlotKey =  slcdTeacher; 
            
            Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
            Map<String,List<Date>> bookDayMap = new Map<String,List<Date>>();
            Date startDt   = System.today();
            //Updated by-: Rajesh| Date-: 21st Aug 2019, to compare enrolments only for 4 weeks from the selected date
            Date endDtTemp = startDt.addMonths(2);
            
            Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc','Group Class'};
            Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed', 'Blocked'};
            Set<String> busyStatusSet  = new Set<String>{'Leave', 'Holiday'};     
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();   
            String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();
            
            for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c, Status__c
                                   FROM Booking__c 
                                   WHERE Teacher_Account__c =: slcdTeacher AND (RecordTypeId =: bookLessRecId OR RecordTypeId =: bookGrpClsRecId)  AND Status__c IN: bookStatusSet
                                   AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDtTemp) AND Enrolment__c !=: stuWrap.enrl.Id AND
                                   ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c NOT IN: busyStatusSet))]){                        
                    
              if(book.End_Time__c > book.Start_Time__c){                    
                    String key =  book.Booking_Date__c +':'+ book.Start_Time__c;
                    bookMap.put(key, book);   
                    
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
                         // start:nishi: 4-Sep-2020: for check teacher engagement type is part-time and is day is greater then 28 mean (5th lesson booking) so we not consider this teacher
                       //remove any timeslot for 5th days for part-time teachers.
                       Boolean isPartTimeTeacher = false; 
                       if(ConstantsClass.teacherPartTimeEngagementStatus.contains(teachWorkSch.Teacher_Name__r.Engagement_Type__c) && st.day() > 28 && defaultOrg=='ossia'){
                           isPartTimeTeacher = true;
                       }
                       system.debug('%%%%isPartTimeTeacher'+isPartTimeTeacher +'  '+st); 
                       if(!isPartTimeTeacher){
                        //end: nishi: 4-Sep-2020: for check teacher engagement type is part-time and is day is greater then 28 mean (5th lesson booking) so we not consider this teacher
                        //remove any timeslot for 5th days for part-time teachers.

                            Time stTime = teachWorkSch.Start_Time__c;
                            
                            Integer endTimeDef = lessonWrap.pkgDuration  > 0 ? lessonWrap.pkgDuration : 30;
                            
                            //Adding trial time during Aureus at home center
                            /*if(currFreeTrailEnr.Id != null && currFreeTrailEnr.Center__c == Label.Aureus_at_Home_Id && currFreeTrailEnr.Center__r.Travel_Time__c != null){
                                endTimeDef = endTimeDef + Integer.valueOf(currFreeTrailEnr.Center__r.Travel_Time__c); 
                            }*/
                            
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
        }else if(stuWrap.lesson.selectedLsnType.equalsIgnoreCase('Group')){
            Map<String,List<Class__c>> clsSchMap = new Map<String,List<Class__c>>();
            Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
            String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();   
            
            Date startDt   = System.today();
            Date endDtTemp = startDt.addMonths(2);
            //added by nishi: 1-sep-2020: for is organaization belongs to ossia then we show time slots according to pacakge list
            // selected package is exist to Ossia_Group_Grade_Package__c records that group class slots we show  
            if(defaultOrg=='ossia'){ 
                set<String> listOfGradePackageClass= new set<String>();
                for(Ossia_Group_Grade_Package__c objGradePackage: [SELECT Class_Name__c, Package__c,  Name, Id 
                                                                        FROM Ossia_Group_Grade_Package__c
                                                                        Where Package__c =: lessonWrap.selectedPlan ]){
                        listOfGradePackageClass.add(objGradePackage.Class_Name__c);
                    }
                if(listOfGradePackageClass != null &&listOfGradePackageClass.size()> 0){                                                        
                    for(Class__c cls: [SELECT Id, Name, Package__c, Package__r.Name, Teacher__c, Class_Day__c, Start_Time__c,End_Time__c,
                                (SELECT Id, Booking_Date__c 
                                    FROM Bookings__r 
                                    WHERE RecordTypeId =: bookGrpClsRecId 
                                    AND (Booking_Date__c >=: startDt 
                                    AND Booking_Date__c <=: endDtTemp))
                                FROM Class__c 
                                WHERE Teacher__c =:slcdTeacher 
                                AND Id IN:listOfGradePackageClass 
                                AND Centre_Name__c =:  lessonWrap.selectedCenter 
                                AND Active__c = True AND Available_Capacity__c > 0
                                 // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                 And Is_Makeup_Class__c = false]){
                        List<Class__c> clsList = clsSchMap.get(cls.Class_Day__c);
                        if(clsList == null)
                            clsList = new List<Class__c>();
                        
                        clsList.add(cls);                                                  
                        clsSchMap.put(cls.Class_Day__c, clsList);   
                                                
                        for(Booking__c book: cls.Bookings__r)
                            bookMap.put(cls.Id+'#'+book.Booking_Date__c, book);                 
                    } 
                } 
            }else{
                //end by nishi: 1-sep-2020: for is organaization belongs to ossia then we show time slots according to pacakge list
            // selected package is exist to Ossia_Group_Grade_Package__c records that group class slots we show
            
                for(Class__c cls:[SELECT Id, Name, Package__c, Package__r.Name, Teacher__c, Class_Day__c, Start_Time__c,End_Time__c,
                                (SELECT Id, Booking_Date__c 
                                    FROM Bookings__r 
                                    WHERE RecordTypeId =: bookGrpClsRecId 
                                    AND (Booking_Date__c >=: startDt 
                                    AND Booking_Date__c <=: endDtTemp))
                                FROM Class__c
                                WHERE Teacher__c =:slcdTeacher 
                                AND Package__c =: lessonWrap.selectedPlan 
                                AND Centre_Name__c =:  lessonWrap.selectedCenter 
                                AND Active__c = True AND Available_Capacity__c > 0
                                 // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                 And Is_Makeup_Class__c = false]){
                    List<Class__c> clsList = clsSchMap.get(cls.Class_Day__c);
                    if(clsList == null)
                        clsList = new List<Class__c>();
                    
                    clsList.add(cls);                                                  
                    clsSchMap.put(cls.Class_Day__c, clsList);   
                                            
                    for(Booking__c book: cls.Bookings__r)
                        bookMap.put(cls.Id+'#'+book.Booking_Date__c, book);                 
                } 
            }
            
            Date endDt = startDt.addMonths(1);
            for(Date st=startDt; st<=endDt; st=st.addDays(1)){
                TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
                Set<Time> morningTimesTemp      = new Set<Time>();
                Set<Time> afternoonTimesTemp    = new Set<Time>();
                
                String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
                
                if(clsSchMap.containsKey(currDay)){
                    List<Class__c> clsSchLst = clsSchMap.get(currDay);
                    
                    for(Class__c clsSch: clsSchLst){    
                        if(bookMap.containsKey(clsSch.Id+'#'+st)){
                            Time stTime = clsSch.Start_Time__c;
                            if(stTime.hour() < 12){
                                morningTimesTemp.add(stTime); 
                            }else{
                                afternoonTimesTemp.add(stTime);
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
        }
        
        lessonWrap.tSlotStr = JSON.serialize(tSlotDateMap);
        lessonWrap.tSlotMap = tSlotDateMap.get(lessonWrap.lessonSlcdDate);
    }
    
    public pageReference redirectOnSrch(){
        
        PageReference pageRef = Page.searchtrial_ipad; 
        pageRef.getParameters().put('country', countrycode);    
        return pageRef;
    }
        
    public void refreshSlots(){
        if(selectedIndex > 0){
            Integer selectedInd = selectedIndex-1;
            if(String.isNotBlank(slcdDate)){
                StudentWrapper stuWrap = studentWrapList.get(selectedInd);
                stuWrap.lesson.lessonSlcdDate = slcdDate;
                stuWrap.lesson.lessonSlcdDateD = date.Parse(slcdDate);
               // fetchTimeSlot(stuWrap.lesson);
                fetchTimeSlot(stuWrap);
            }
        }
        
        //selectedIndex = 0;
    }
    
    public void assignSlots(){        
        if(selectedIndex > 0){
            Integer selectedInd = selectedIndex-1;
            if(String.isNotBlank(slcdSlot)){
                StudentWrapper stuWrap = studentWrapList.get(selectedInd);
                stuWrap.lesson.lessonSlctSlot = slcdSlot;
            }
        }
       // selectedIndex = 0;
    }
    
    public void fetchTchrs(){
        if(selectedIndex > 0){
            Integer selectedInd =  selectedIndex-1;
            StudentWrapper stuWrap = studentWrapList.get(selectedInd);
            
            stuWrap.lesson.teacherOptions = fetchTeachers(stuWrap.lesson);
            stuWrap.lesson.selectedTeacher ='';
            stuWrap.lesson.selectedPlan='';
            stuWrap.lesson.tSlotMap = new TimeSlotModelCntrl();
            stuWrap.lesson.tSlotStr = '';
        }
       // selectedIndex =0;
    }  
    
    public void fetchPkgPlans(){
        if(selectedIndex > 0){
            Integer selectedInd =  selectedIndex-1;
            StudentWrapper stuWrap = studentWrapList.get(selectedInd);
            
            stuWrap.lesson.planOptions = fetchPlans(stuWrap.lesson, false);
            stuWrap.lesson.selectedPlan='';
            stuWrap.lesson.tSlotMap = new TimeSlotModelCntrl();
            stuWrap.lesson.tSlotStr = '';
        }
        //selectedIndex = 0;
    }
    
    public void fetchTSlots(){
        if(selectedIndex > 0){
            Integer selectedInd = selectedIndex-1;
            StudentWrapper stuWrap = studentWrapList.get(selectedInd);
           
            stuWrap.lesson.tSlotMap = new TimeSlotModelCntrl();
            stuWrap.lesson.tSlotStr = '';
            
            if(stuWrap.lesson.selectedPlan != null){
                List<Package__c> pkgList = [SELECT Id, Duration__c FROM Package__c WHERE Id=:stuWrap.lesson.selectedPlan LIMIT 1];
                //if(stuWrap.lesson.pkgDuration == null){                
                    stuWrap.lesson.pkgDuration  = Integer.valueOf(pkgList.get(0).Duration__c);
                //}
                
                fetchTimeSlot(stuWrap);
            }else{
                fetchPkgPlans();
            } 
            //fetchTimeSlot(stuWrap.lesson);
             
           
        }
        //selectedIndex = 0;
    } 
    
    public void showSlcdEnrolment(){
        if(selectedIndex > 0){
            currSlcd = selectedIndex;
            Integer selectedInd = selectedIndex-1;
            StudentWrapper stuWrap = studentWrapList.get(selectedInd);
            stuWrap.lesson.tSlotMap = new TimeSlotModelCntrl();
            stuWrap.lesson.tSlotStr = '';
            
            if(stuWrap.lesson.teacherOptions.size() == 1 && stuWrap.lesson.selectedTeacher == null){
                stuWrap.lesson.selectedTeacher = stuWrap.lesson.selectedTeacherT;
                stuWrap.lesson.selectedPlan = stuWrap.lesson.selectedPlanT;
            }
                
            Boolean defPkg = String.isBlank(stuWrap.lesson.selectedPlan);
                
            stuWrap.lesson.teacherOptions= fetchTeachers(stuWrap.lesson);
            stuWrap.lesson.planOptions   =  fetchPlans(stuWrap.lesson, defPkg);
            
            //fetchTimeSlot(stuWrap.lesson);
            fetchTimeSlot(stuWrap);
        }
    }
    
    public void addFreshEnrolment(){
        if(studentWrapList.size() > 0){
            Enrolment__c tempEnr = studentWrapList.get(0).enrl;
        
            StudentWrapper st = new StudentWrapper();
            LessonWrapper lsn = new LessonWrapper();
            
            st.enrl = new Enrolment__c(Student__c = tempEnr.Student__c, Parent__c = tempEnr.Parent__c);
            st.stuAcc = new Account(Name = tempEnr.Student__r.Name);
            lsn.centerOptions = getCenters();
            
            st.lesson = lsn;
            studentWrapList.add(st);
        }
    }
    
     public void deleteEnrolment(){
        if(studentWrapList.size() > 0 && selectedIndex > 0){
           Integer selectedInd = selectedIndex-1;
           studentWrapList.remove(selectedInd);
           //selectedIndex = studentWrapList.size()-1;  
        }
        //selectedIndex = 0; 
    }
    
    public pageReference sendEmail(){
        List<Enrolment__c> updEnrList = new List<Enrolment__c>();
        for(StudentWrapper stu : studentWrapList){
            Enrolment__c enrl = new Enrolment__c(Id = stu.enrl.Id, Enrolment_Email_Date__c = System.now());
            enrl.Enrolment_Owner__c = UserInfo.getUserId(); // updated by nishi: 11- mar-2021: to store center staff on enrolment to track Who sent the enrolment email to be tracked via enrolment link from calendar

            //updated by Rajesh, 7th Aug 2019. to store enrolmentsource on enrolment/case object
            if(String.isNotBlank(enrolmentSource))
                enrl.Enrolment_Source__c = enrolmentSource;
            
             updEnrList.add(enrl);
        }
        
        if(updEnrList.size() > 0){
            update updEnrList;
            
            List<Enrolment__c> enrListT  = [SELECT Id, Parent__r.Name, Student__r.Name, Center__c, Teacher__c, Package__c, Package__r.Duration__C, Package__r.Program__r.Instrument__c,Field_1__c,
                        Parent__r.Also_a_Student__c, Student__c,  Parent__c, Trial_Date__c,  Trial_Start_Time__c, Center__r.Travel_Time__c, Lessons_Start_Date__c, Lesson_Start_Time__c ,
                        Parent__r.personContactId, Center__r.Location__c
                        FROM Enrolment__c  
                        WHERE  Id =: updEnrList.get(0).Id];
            
            sendEmail(enrListT);
            errorMsg = 'success';
            return null;
        }else{
            errorMsg = 'Error: Enrolment not found..';
            return null;
        }
    }
    
    
    public pageReference saveStudentAndSendEmail(){
      
        Boolean isNotCompleted = false;
        String enrId;
        for(StudentWrapper stu : studentWrapList){
            
            if(String.isBlank(stu.lesson.selectedCenter))
                isNotCompleted = true;
            else if(String.isBlank(stu.lesson.selectedTeacher))
                isNotCompleted = true;
            else if(String.isBlank(stu.lesson.selectedPlan))
                isNotCompleted = true;
            else if(String.isBlank(stu.lesson.lessonSlcdDate))
                isNotCompleted = true;
            else if(String.isBlank(stu.lesson.lessonSlctSlot))
                isNotCompleted = true;
            
            if(isNotCompleted){
                enrId = stu.enrl.Id;    
                break;
            }
        }
        
        if(isNotCompleted){
            List<Enrolment__c> enrListT  = [SELECT Id, Parent__r.Name, Student__r.Name, Center__c, Teacher__c, Package__c, Package__r.Duration__C, Package__r.Program__r.Instrument__c,Field_1__c,
                        Parent__r.Also_a_Student__c, Student__c,  Parent__c, Trial_Date__c,  Trial_Start_Time__c, Center__r.Travel_Time__c, Lessons_Start_Date__c, Lesson_Start_Time__c ,
                        Parent__r.personContactId, Center__r.Location__c
                        FROM Enrolment__c  
                        WHERE  Id =:enrId];
            
            errorMsg = 'success';
            return null;
        }else{
            return saveEnrolment();
        }
    }
    
    public pageReference saveEnrolment(){
        Savepoint sp;
        isError = false;
        errorMsg = 'success';
            
        try{
            sp = Database.setSavepoint();
            List<Enrolment__c> enrList = new List<Enrolment__c>();
            List<Booking__c> bookList  = new List<Booking__c>();
            
            Set<String> centSet = new Set<String>();
            Set<String> tchrSet = new Set<String>();
            Set<String> pkgSet  = new Set<String>();
            for(StudentWrapper stu : studentWrapList){
                if(stu.lesson.selectedLsnType.equalsIgnoreCase('Group')){
                    centSet.add(stu.lesson.selectedCenter);
                    tchrSet.add(stu.lesson.selectedTeacher);
                    pkgSet.add(stu.lesson.selectedPlan);
                }
            }
            System.debug('@@@centSet'+centSet);
            System.debug('@@@tchrSet'+tchrSet);
            System.debug('@@@pkgSet'+pkgSet);
            Map<String,Class__c> clsSchMap = new Map<String,Class__c>();
            if(centSet.size() > 0 && tchrSet.size() > 0 && pkgSet.size() > 0){
                if(defaultOrg=='ossia'){ 
                   // start :added by nishi: 1-sep-2020: for if class related to ossia organisation then we show package list into  
                 //new created object Ossia_Group_Grade_Packages__r other wise we get package list into package field 
                    for(Class__c cls: [SELECT Id, Name, Centre_Name__c, Teacher__c, Package__c, Class_Day__c, Start_Time__c,End_Time__c, 
                                        (SELECT Class_Name__c, Package__c,Package__r.Name,  Name, Id ,
                                            Package__r.Type__c,Package__r.RecordtypeId,Package__r.Type_of_package__c
                                            FROM Ossia_Group_Grade_Packages__r 
                                            WHERE  Package__c =: pkgSet
                                        )
                                        FROM Class__c 
                                        WHERE Teacher__c IN:tchrSet 
                                        AND Centre_Name__c IN:centSet 
                                        AND Active__c = True
                                        AND Available_Capacity__c > 0
                                         // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                         And Is_Makeup_Class__c = false]){  
                        if(cls.Ossia_Group_Grade_Packages__r != null && cls.Ossia_Group_Grade_Packages__r.size() > 0){ 
                            for(Ossia_Group_Grade_Package__c objGradePackage: cls.Ossia_Group_Grade_Packages__r)    {                                                                            
                                String key = cls.Centre_Name__c +'#'+ cls.Teacher__c +'#'+ objGradePackage.Package__c +'#'+ cls.Class_Day__c +'#'+ cls.Start_Time__c;
                                clsSchMap.put(key, cls);
                                System.debug('key'+key); 
                            }
                        }    
                        System.debug('@@cls.Ossia_Group_Grade_Packages__r'+cls.Ossia_Group_Grade_Packages__r);             
                    } 
                    
                }else{
                // end :added by nishi: 1-sep-2020: for if class related to ossia organisation then we show package list into  
                 //new created object Ossia_Group_Grade_Packages__r other wise we get package list into package field 
                    for(Class__c cls: [SELECT Id, Name, Centre_Name__c, Teacher__c, Package__c, Class_Day__c, Start_Time__c,End_Time__c FROM Class__c WHERE Teacher__c IN:tchrSet AND Package__c IN:pkgSet 
                                    AND Centre_Name__c IN:centSet AND Teacher__c IN:tchrSet AND Package__c IN:pkgSet AND Active__c = True AND Available_Capacity__c > 0
                                     // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                     And Is_Makeup_Class__c = false]){                                                               
                        String key = cls.Centre_Name__c +'#'+ cls.Teacher__c +'#'+ cls.Package__c +'#'+ cls.Class_Day__c +'#'+ cls.Start_Time__c;
                        clsSchMap.put(key, cls);                                                  
                    }
                    System.debug('@@clsSchMap'+clsSchMap);
                }
            }
            System.debug('@@clsSchMap'+clsSchMap);
            
            Set<String> grpClsBookSet = new Set<String>();
            for(StudentWrapper stu : studentWrapList){
                Date lessDt; 
                if(String.isNotBlank(stu.lesson.lessonSlcdDate))
                    lessDt =  date.Parse(stu.lesson.lessonSlcdDate);
                
                Time startTime;
                if(String.isNotBlank(stu.lesson.lessonSlctSlot)){
                    List<String> timeList = stu.lesson.lessonSlctSlot.split(':');
                    
                    startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                }
                if(stu.enrl.Id == null){
                    stu.enrl.Type__c = 'Trial';
                }
                System.debug('@@startTime'+startTime);
                stu.enrl.Stage__c   = 'Pending Enrolment';    
                stu.enrl.Center__c  = stu.lesson.selectedCenter;
                stu.enrl.Teacher__c = stu.lesson.selectedTeacher;
                stu.enrl.Package__c = stu.lesson.selectedPlan;
                stu.enrl.Lessons_Start_Date__c =  lessDt;
                stu.enrl.Lesson_Start_time__c =  startTime;
                stu.enrl.Enrolment_Email_Date__c = System.now();
                stu.enrl.Enrolment_Owner__c = UserInfo.getUserId(); // updated by nishi: 11- mar-2021: to store center staff on enrolment to track Who sent the enrolment email to be tracked via enrolment link from calendar

                //updated by Rajesh, 7th Aug 2019. to store enrolmentsource on enrolment/case object
                if(String.isNotBlank(enrolmentSource))
                    stu.enrl.Enrolment_Source__c = enrolmentSource;
                
                if(stu.lesson.selectedLsnType.equalsIgnoreCase('Group')){
                    String currDay =  DateTime.newInstance(lessDt, Time.newInstance(0, 0, 0, 0)).format('E');
                    System.debug('@@currDay'+currDay);
                    String key = stu.enrl.Center__c +'#'+ stu.enrl.Teacher__c +'#'+stu.enrl.Package__c +'#'+ currDay +'#'+ startTime;
                    System.debug('key'+key);
                    System.debug('@@clsSchMap'+clsSchMap);
                    if(clsSchMap.containsKey(key)){
                        stu.enrl.Class__c = clsSchMap.get(key).Id;
                        grpClsBookSet.add(stu.enrl.Class__c);
                        System.debug('@@@'+clsSchMap.get(key).Id);
                    }
                    stu.enrl.Type__c    = 'Group';
                }
                
                enrList.add(stu.enrl);
            }      
            upsert enrList;
            
            System.debug('@@@grpClsBookSet'+grpClsBookSet);
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
            System.debug('@@@grpClsBookMap'+grpClsBookMap);
            //For aureus home centers 
            centSet = new Set<String>();
            tchrSet = new Set<String>();
            Set<String> daySet = new Set<String>();
            Map<String,Teacher_Working_Hour__c> tcrWrkHourMap = new Map<String,Teacher_Working_Hour__c>();
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
            
            enrList  = [SELECT Id, Parent__r.Name, Student__r.Name, Center__c, Teacher__c, Package__c, Package__r.Duration__C, Package__r.Program__r.Instrument__c,Field_1__c, Type__c, Class__c,
                                        Parent__r.Also_a_Student__c, Student__c,  Parent__c, Trial_Date__c,  Trial_Start_Time__c, Center__r.Travel_Time__c, Lessons_Start_Date__c, Lesson_Start_Time__c ,
                                        Parent__r.personContactId, Center__r.Location__c
                                        FROM Enrolment__c  
                                        WHERE  Id IN: enrList];
            
            List<Booking__c> bookLstForDel = [SELECT Id,Name FROM Booking__c WHERE Status__c = 'Blocked' AND Enrolment__c IN: enrList];
            if(bookLstForDel.size() > 0)
                delete bookLstForDel;
           
            for(Enrolment__c enr : enrList){
                String remStr    =  enr.Parent__r.Name;
                remStr   =  remStr +':'+enr.Student__r.Name;
                
                String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();  
                Boolean isGrpEnrolment = false;
                if(enr.Type__c.equalsIgnoreCase('Group')){
                    bookLessRecId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Lesson').getRecordTypeId();
                    isGrpEnrolment = true;
                }
                
                //Added by Rajesh: 25th July 2019, for Adding placeholder bookings before enrolment lesson start
                if(!isGrpEnrolment){
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
                    system.debug('@@@grpClsBookMap'+grpClsBookMap);
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
                    system.debug('@@@bookList'+bookList);
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
            return null;
               
        }catch(Exception e){
             Database.rollback(sp);
             
             System.debug('Error:  '+e.getMessage());
             errorMsg = e.getMessage();
             isError  = true;
         }
        return null;
    }
    
    public pageReference saveAndNextProcess(){
        Savepoint sp;
        isError = false;
        errorMsg = 'success';
            
        try{
            sp = Database.setSavepoint();
            
            Set<String> centSet = new Set<String>();
            Set<String> tchrSet = new Set<String>();
            Set<String> pkgSet  = new Set<String>();
            for(StudentWrapper stu : studentWrapList){
                if(stu.lesson.selectedLsnType.equalsIgnoreCase('Group')){
                    centSet.add(stu.lesson.selectedCenter);
                    tchrSet.add(stu.lesson.selectedTeacher);
                    pkgSet.add(stu.lesson.selectedPlan);
                }
            }
            system.debug('@@pkgSet'+pkgSet);
            Map<String,Class__c> clsSchMap = new Map<String,Class__c>();
            if(centSet.size() > 0 && tchrSet.size() > 0 && pkgSet.size() > 0){
                if(defaultOrg=='ossia'){ 
                    // start :added by nishi: 1-sep-2020: for if class related to ossia organisation then we show package list into  
                  //new created object Ossia_Group_Grade_Packages__r other wise we get package list into package field 
                     for(Class__c cls: [SELECT Id, Name, Centre_Name__c, Teacher__c, Package__c, Class_Day__c, Start_Time__c,End_Time__c, Available_Capacity__c,
                                         (SELECT Class_Name__c, Package__c,Package__r.Name,  Name, Id ,
                                             Package__r.Type__c,Package__r.RecordtypeId,Package__r.Type_of_package__c
                                             FROM Ossia_Group_Grade_Packages__r 
                                             WHERE  Package__c =: pkgSet
                                         )
                                         FROM Class__c 
                                         WHERE Teacher__c IN:tchrSet 
                                         AND Centre_Name__c IN:centSet 
                                         AND Active__c = True
                                         AND Available_Capacity__c > 0
                                          // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                          And Is_Makeup_Class__c = false]){  
                         if(cls.Ossia_Group_Grade_Packages__r != null && cls.Ossia_Group_Grade_Packages__r.size() > 0){ 
                             for(Ossia_Group_Grade_Package__c objGradePackage: cls.Ossia_Group_Grade_Packages__r)    {                                                                            
                                 String key = cls.Centre_Name__c +'#'+ cls.Teacher__c +'#'+ objGradePackage.Package__c +'#'+ cls.Class_Day__c +'#'+ cls.Start_Time__c;
                                 clsSchMap.put(key, cls);
                                 System.debug('key'+key); 
                             }
                         }    
                         System.debug('@@cls.Ossia_Group_Grade_Packages__r'+cls.Ossia_Group_Grade_Packages__r);             
                     } 
                     
                 }else{
                 // end :added by nishi: 1-sep-2020: for if class related to ossia organisation then we show package list into  
                  //new created object Ossia_Group_Grade_Packages__r other wise we get package list into package field 
                    
                    for(Class__c cls: [SELECT Id, Name, Centre_Name__c, Teacher__c, Package__c, Class_Day__c, Start_Time__c,End_Time__c,Available_Capacity__c 
                                        FROM Class__c WHERE Teacher__c IN:tchrSet AND Package__c IN:pkgSet 
                                        AND Centre_Name__c IN:centSet AND Teacher__c IN:tchrSet AND Package__c IN:pkgSet AND Active__c = True AND Available_Capacity__c > 0
                     // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                     And Is_Makeup_Class__c = false]){                                                               
                        String key = cls.Centre_Name__c +'#'+ cls.Teacher__c +'#'+ cls.Package__c +'#'+ cls.Class_Day__c +'#'+ cls.Start_Time__c;
                        clsSchMap.put(key, cls);                                                  
                    }
                }

            }
            system.debug('@@clsSchMap'+clsSchMap);
            Set<string> setOfTeacherAndTime =new Set<string>();
            
            List<Enrolment__c> enrList = new List<Enrolment__c>();            
            for(StudentWrapper stu : studentWrapList){
                Date lessDt; 
                if(String.isNotBlank(stu.lesson.lessonSlcdDate))
                    lessDt =  date.Parse(stu.lesson.lessonSlcdDate);
                
                Time startTime;
                if(String.isNotBlank(stu.lesson.lessonSlctSlot)){
                    List<String> timeList = stu.lesson.lessonSlctSlot.split(':');
                    
                    startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                }
                if(stu.enrl.Id == null){
                    stu.enrl.Type__c = 'Trial';
                }
                
                stu.enrl.Stage__c   = 'Pending Enrolment';    
                stu.enrl.Center__c  = stu.lesson.selectedCenter;
                stu.enrl.Teacher__c = stu.lesson.selectedTeacher;
                stu.enrl.Package__c = stu.lesson.selectedPlan;
                stu.enrl.Lessons_Start_Date__c =  lessDt;
                stu.enrl.Lesson_Start_time__c =  startTime;
                //updated by Rajesh, 7th Aug 2019. to store enrolmentsource on enrolment/case object
                if(String.isNotBlank(enrolmentSource))
                    stu.enrl.Enrolment_Source__c = enrolmentSource;
                String currDay =  DateTime.newInstance(lessDt, Time.newInstance(0, 0, 0, 0)).format('E');
                if(stu.lesson.selectedLsnType.equalsIgnoreCase('Group')){
                    String key = stu.enrl.Center__c +'#'+ stu.enrl.Teacher__c +'#'+stu.enrl.Package__c +'#'+ currDay +'#'+ startTime;
                    system.debug('@@clsSchMap'+clsSchMap);

                    if(clsSchMap.containsKey(key))
                        stu.enrl.Class__c = clsSchMap.get(key).Id;
                    stu.enrl.Type__c    = 'Group';
                   //start: 14-Sep-2020:nishi: If a user added two enrolment and both enrolment types were grouped then we allowed the user to select the same teacher, time slot
                  // otherwise the enrolment type is individual then we showed an error message
                    if(!setOfTeacherAndTime.contains(currDay+'-'+startTime+'-'+stu.lesson.selectedTeacher+clsSchMap.get(key).Id)){
                        setOfTeacherAndTime.add(currDay+'-'+startTime+'-'+stu.lesson.selectedTeacher+clsSchMap.get(key).Id);
                    }else{
                        if(clsSchMap.get(key).Available_Capacity__c < 2){
                            errorMsg = 'Error: You can\'t book the same Teacher for \'the Same Time\'.';
                            isError  = true;
                            break; 
                        }
                    }
                }else{
                    if(!setOfTeacherAndTime.contains(currDay+'-'+startTime+'-'+stu.lesson.selectedTeacher)){
                        setOfTeacherAndTime.add(currDay+'-'+startTime+'-'+stu.lesson.selectedTeacher);
                    }else{
                        errorMsg = 'Error: You can\'t book the same Teacher for \'the Same Time\'.';
                        isError  = true;
                        break; 
                    }
                }
                //end: 14-Sep-2020:nishi: If a user added two enrolment and both enrolment types were grouped then we allowed the user to select the same teacher, time slot
                  // otherwise the enrolment type is individual then we showed an error message
                enrList.add(stu.enrl);
            }   
            system.debug('setOfTeacherAndTime'+setOfTeacherAndTime);
            system.debug('errorMsg'+errorMsg);
            system.debug('isError'+isError);
            if(!isError){   
                upsert enrList;      
                system.debug('@@enrList'+enrList);
                List<Booking__c> bookLstForDel = [SELECT Id,Name FROM Booking__c WHERE Status__c = 'Blocked' AND Enrolment__c IN: enrList];
                if(bookLstForDel.size() > 0)
                    delete bookLstForDel;
                
                PageReference pageRef = new PageReference('/apex/EnrolmentProcessForClass');
                
                Integer counter = 1;
                for(Enrolment__c enr: enrList){
                    String enrlStr = 'enr'+counter;
                    pageRef.getParameters().put(enrlStr, enr.Id); 
                
                    counter = counter+1;            
                }        
                return pageRef;
            }
        }catch(Exception e){
             Database.rollback(sp);
             System.debug('Error:  '+e.getMessage());
             errorMsg = e.getMessage();
             isError  = true;
         }
        return null;
    }
    
    private void sendEmail(List<Enrolment__c> enrListTemp){
          List<EmailTemplate> templateList =  new List<EmailTemplate>();
                //@Juneid 26 Aaug 2020, Orgnization wise templates
                if(defaultOrg=='ossia'){
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
                Messaging.sendEmail(emailList);
            }
        }
    }
   
    
    @TestVisible
    private Static Booking__c fillBook(LessonWrapper lw, String recTypeId, Enrolment__c enrl, String status, Date bookDate){
        Booking__c book   = new Booking__c(Student__c=enrl.Student__c, Teacher_Account__c = lw.selectedTeacher, Enrolment__c = enrl.Id);
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
    
    public class StudentWrapper{
        public Account stuAcc{get;set;}
        public LessonWrapper lesson{get;set;}
        
        Enrolment__c enrl;
        //Account student;
        public StudentWrapper(){
            stuAcc            = new Account();
            lesson = new LessonWrapper();
            
            enrl   = new Enrolment__c();
        }
    }
    
    public class LessonWrapper{
        public String selectedLsnType{get;set;}
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
        
        public String tSlotStr{get;set;}
        public TimeSlotModelCntrl tSlotMap{get;set;}
        
        public Integer  pkgDuration;
        String selectedPlanT;
        String selectedTeacherT;
        public LessonWrapper(){
            centerOptions = new List<SelectOption>();
            planOptions = new List<SelectOption>();
            teacherOptions = new List<SelectOption>();
            
            centerOptions.add(new SelectOption('', '--None--'));
            planOptions.add(new SelectOption('', '--None--'));
            teacherOptions.add(new SelectOption('', '--None--'));
            
            lessonSlcdDateD = System.today();
            lessonSlcdDate  = lessonSlcdDateD.day()+'/'+lessonSlcdDateD.month()+'/'+lessonSlcdDateD.year() ;
            
            selectedLsnType = 'Individual';
            tSlotMap = new TimeSlotModelCntrl();
        }
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
}