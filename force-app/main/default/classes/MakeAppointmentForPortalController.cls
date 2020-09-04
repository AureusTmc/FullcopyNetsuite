public class MakeAppointmentForPortalController{    
    public Set<ID> selectedPackageIds;
    String parId;
    public Boolean isSuccess{get;set;}
    public Date slcdDateNew{get;set;} 
    public String slcdTimeNew{get;set;}
    public String tempslcdTimeNew{get;set;}
    public Integer indexno{get;set;}    
    public Boolean assignFlagValue{get;set;}
    public Boolean slcdPkg{get;set;}
    public String slcdSlot{get;set;}
    public String tSlotStr{get;set;}
    public String slcdDate{get;set;}
    public String enrollmentId{get;set;}
    public Integer makeAvlMinutes{get;set;}
    public Integer makeAvlBalanceMinutes{get;set;}
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    public Integer slcPkgdDuration{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public list<MakeAppointmentForPortalModalClass> modelList {get;set;} 
    public list<MakeAppointmentForPortalModalClass> newModelList {get;set;}
    public List<Account> accList{get;set;}
    public String techerRecordtypeId;
    public Map<String,String> getTeacherName{get;set;}
    public Map<String,Integer> makeUpPackageMap;
    public List<selectoption> allslotslist{get;set;}
    public Boolean selectedTeacher{get;set;}
    
    public String  prcType{get;set;} 
    public Boolean isPrcAnyTime{get;set;}
    public MakeAppointmentForPortalModalClass currentStudent{get;set;}
    public MakeAppointmentForPortalController(){
        selectedPackageIds = new Set<ID>();
        selectedTeacher = false;
        allslotslist = new List<SelectOption>();
        slcdPkg = false;
        tSlotMap   = new TimeSlotModelCntrl();
        tSlotStr   = '';
        tSlotDateMap = new Map<String,TimeSlotModelCntrl>();
        
        isPrcAnyTime = false;
        currentStudent = new MakeAppointmentForPortalModalClass();
        indexNo = 0;
        //slcPkgdDuration = 135;
        makeAvlMinutes = 0;
        getTeacherName = new Map<String,String>();
        makeUpPackageMap = new Map<String,Integer>();
        slcdDate = System.today().day()+'/'+System.today().month()+'/'+System.today().year();
        parId = ApexPages.currentPage().getParameters().get('id');
        modelList = new list<MakeAppointmentForPortalModalClass>();
        newModelList = new list<MakeAppointmentForPortalModalClass>();
        for(Package__c pkg : [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, 
                                  Unit_Fee__c, Active__c FROM Package__c 
                                  WHERE Active__c = true AND Type__c = 'Makeup' AND Duration__c != null ORDER BY Duration__c]){
              makeUpPackageMap.put(pkg.id,Integer.valueOf(pkg.Duration__c));    
        }                              
        System.debug('###@@@&&&'+makeUpPackageMap);    
        techerRecordtypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();                 
        for(Account accObj : [select id,name,firstname,lastname,RecordType.ID,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c from account where RecordType.ID =: techerRecordtypeId]){
            getTeacherName.put(accObj.id,accObj.firstname+' '+accObj.lastname.substring(0,1)+'.');
        }
        if(String.isNotBlank(parId)){
            accList = [SELECT Id, FirstName, LastName, Name, PersonMobilePhone, PersonOtherPhone, 
                                     PersonEmail, BillingCountryCode, Gender__c, Nationality__c, Phone, Occupation__c, 
                                     BillingStreet, BillingCity, BillingPostalCode, BillingCountry, Available_Make_up_Units__c
                                     FROM Account WHERE Id =: parId];
            if(accList.size() > 0){
                Account ac = accList.get(0); 
                makeAvlMinutes = ac.Available_Make_up_Units__c != null ? Integer.valueOf(ac.Available_Make_up_Units__c) : 0;
                makeAvlBalanceMinutes = 0;
                //Add a new condition to the enrollment query if a enrollment package has a type group then we exclude that enrollment change made by sakib on 3/9/2019
                for(Enrolment__c enrolmentObj : [SELECT Id,Name,Center__r.Name,Center__c,Student__c,Student__r.Name,Package__r.Type__c,Student__r.Id,Instrument__c,Teacher__r.Name FROM Enrolment__c WHERE Parent__c =: parId AND Center__c != null AND Type__c =: ConstantsClass.typeRegular AND Stage__c =: ConstantsClass.enroledStatus AND Package__r.Type__c != 'Group']){
                    MakeAppointmentForPortalModalClass modalclass = new MakeAppointmentForPortalModalClass();
                    modalclass.flag = false;
                    modalclass.enrolmentObject = enrolmentObj;
                    modelList.add(modalclass);
                }
                system.debug('modallist'+modelList);
            }else{
                errorMsg = 'Parent Account no found, please contact with your center admin';
                isError = true;
            }
        }else{
            errorMsg = 'Parent Account no found, please contact with your center admin';
            isError = true;
        }
    }    
    public void updateFlagValue(){
        if(String.isNotEmpty(enrollmentId)){
            for(MakeAppointmentForPortalModalClass m : modelList){
                if(m.enrolmentObject.id == enrollmentId){
                    m.flag = assignFlagValue;
                    break;
                }/*else{
                    m.flag = false;
                }*/
            }
        }
        //system.debug('List = '+modelList);
    }
    public void selectedStudent(){
        slcdPkg = false;
        isPrcAnyTime = false;       
        
        newModelList.clear();
        for(MakeAppointmentForPortalModalClass m : modelList){
            MakeAppointmentForPortalModalClass model = new MakeAppointmentForPortalModalClass();
            if(m.flag){  
                model.studentName = m.enrolmentObject.Student__r.Name;
                model.enrolmentId = m.enrolmentObject.Id;
                model.instrumentName = m.enrolmentObject.instrument__c;
                model.studentLesson = getLessons(); 
                model.teacherId = m.enrolmentObject.Teacher__r.Id;
                model.teacherName = m.enrolmentObject.Teacher__r.Name;
                model.lessonTeacher = getTeachers(m.enrolmentObject.instrument__c,m.enrolmentObject.center__c);
                model.packageList = getPackages(m.enrolmentObject.center__c);
                model.enrolStudentCenterId = m.enrolmentObject.center__c;
                model.selectedPackageId = '';
                model.centerName = m.enrolmentObject.center__r.Name;
                model.studentId = m.enrolmentObject.student__c;
                newModelList.add(model);
            }
        }       
        
        if(prcType == 'Any Times Available' && newModelList.size() > 0){
            isPrcAnyTime = true;
            indexNo = 0;
            //currentStudent = newModelList.get(0);
        }
    }
    
    public void saveCurrentRecord(){
        /*MakeAppointmentForPortalModalClass model = newModelList.get(indexNo);
        //show time in correct format changes made by sakib on 27/8/2019
        List<String> timeList = slcdSlot.split(':');
        Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
        //slcdTimeNew = DateTime.newInstance(slcdDateNew, tempT).format('hh:mm a');
        model.slcdTime = DateTime.newInstance(Date.parse(slcdDate), tempT).format('hh:mm a');
        model.slcdDate = Date.parse(slcdDate);
        
        indexNo = indexNo+1;
        slcdDate = System.today().day()+'/'+System.today().month()+'/'+System.today().year();
        slcdSlot = '';*/
        MakeAppointmentForPortalModalClass model = newModelList.get(indexNo);
        model.slcdTime = slcdSlot;
        List<String> timeList = slcdSlot.split(':');
        Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);
        model.tempslcdTime = DateTime.newInstance(Date.parse(slcdDate), tempT).format('hh:mm a');
        model.slcdDate = Date.parse(slcdDate);
        
        indexNo = indexNo+1;
        slcdDate = System.today().day()+'/'+System.today().month()+'/'+System.today().year();
        slcdSlot = '';
        
        model = newModelList.get(indexNo);
        if(model.slcdDate != null && String.isNOtBlank(model.slcdTime)){
            Date tempDt = model.slcdDate;            
            slcdDate = tempDt.day()+'/'+tempDt.month()+'/'+tempDt.year();
            slcdSlot = model.slcdTime;   
        }
        
            
        fetchTimeSlot();
    }
    
    public void backSecondScreen(){
        indexNo = indexNo-1;
        
        MakeAppointmentForPortalModalClass model = newModelList.get(indexNo);
        Date tempDt = model.slcdDate;
        slcdDate = tempDt.day()+'/'+tempDt.month()+'/'+tempDt.year();
        slcdSlot = model.slcdTime;
        fetchTimeSlot();
    }
    
    public void checkAvlMakeup(){ 
        isError = false;
        System.debug('selectedpackage = '+slcPkgdDuration);
              
        if(slcPkgdDuration > 0){            
            if(accList.size() == 0 || Integer.valueOf(accList.get(0).Available_Make_up_Units__c) < slcPkgdDuration){
                isError = true;
                errorMsg = 'You dont have sufficient makeup units. Please contact Centre Admin for more details.';
            }
        }else{
            slcPkgdDuration = 0;
        }
        
    }
    public List<SelectOption> getLessons(){
        List<SelectOption> allLessons = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Account.Major_Instruments_Disciplines__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        allLessons.add(new SelectOption('', '--None--'));
        for( Schema.PicklistEntry f : ple){
            if( f.getValue() != 'Piano Rental' || f.getValue() != 'Piano Sales' ){
                allLessons.add(new SelectOption(f.getValue(),f.getLabel()));
            }
        }
        allLessons.sort();
        return allLessons;        
    }
    public List<SelectOption> getTeachers(String lessonName,String centerId){
        List<SelectOption> teacherOptions = new List<SelectOption>();
        Set<id> teacherids = new Set<id>();
        for(teacher_working_hour__c twhObj : [select id,teacher_name__c,center_name__c from teacher_working_hour__c where center_name__c =: centerId AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False ORDER BY Teacher_Name__r.Name]){
            teacherids.add(twhObj.teacher_name__c);
        }
        System.debug('teacherids = '+teacherids);
        techerRecordtypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();         
        teacherOptions.add(new SelectOption('', '--None--'));
        for(Account accObj : [select id,name,RecordType.ID,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c from account where RecordType.ID =: techerRecordtypeId AND (Major_Instruments_Disciplines__c INCLUDES (:lessonName) OR Minor_Instruments_Disciplines__c INCLUDES (:lessonName)) AND Major_Instruments_Disciplines__c != NULL AND id IN : teacherids]){
            teacherOptions.add(new SelectOption(accObj.id,accObj.Name));
        }
        return teacherOptions;
    }
    public List<SelectOption> getPackages(String centerId){
        List<SelectOption> pkgOptions = new List<SelectOption>();
        pkgOptions.add(new SelectOption('', '--None--'));         
        if(String.isNotBlank(centerId)){    
            Integer i = 0;
            for(Package__c pkg : [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, 
                                  Unit_Fee__c, Active__c FROM Package__c 
                                  WHERE Location__c =: centerId AND Active__c = true AND Type__c = 'Makeup' AND Duration__c != null AND Duration__c != '15' ORDER BY Duration__c]){
                //if(i!=0)
                    pkgOptions.add(new SelectOption(pkg.Id, pkg.Name));                     
                                      
            i++;                          
            }
        }        
        return pkgOptions;
    }
    public void changeTchr(){
        slcdPkg = false;  
        newModelList[indexno].selectedPackageId = '';
        isError = false;
    }
    public void refreshSummary(){ 
        slcdDateNew = Date.parse(slcdDate);        
        if(String.isNotBlank(slcdSlot)){
            List<String> timeList = slcdSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            slcdTimeNew = DateTime.newInstance(slcdDateNew, tempT).format('hh:mm a');
            
            if(isPrcAnyTime){
                //show time in correct format changes made by sakib on 27/8/2019
                /*MakeAppointmentForPortalModalClass model = newModelList.get(indexNo);
                model.slcdTime = DateTime.newInstance(slcdDateNew, tempT).format('hh:mm a');
                model.slcdDate = slcdDateNew;*/
                MakeAppointmentForPortalModalClass model = newModelList.get(indexNo);
                model.slcdTime = slcdSlot;
                model.tempslcdTime = DateTime.newInstance(slcdDateNew, tempT).format('hh:mm a');
                model.slcdDate = slcdDateNew;
            }
        }        
    }
    public void fetchTimeSlot(){
        slcPkgdDuration = 0;
        //Set<ID> selectedPackageIds = new Set<ID>(); commented by sakib on 26/8/2019 because the package ids are different for each student and in this case what happen list initialize every time when this function called and this will overwrite the list with last selected package.
        Set<ID> selectStudentenrolmentIds = new Set<ID>();
        Set<ID> selectedTeacherIds = new Set<ID>();
        Set<ID> centerIds = new Set<ID>();
        //selectedPackageIds.clear();
        Boolean isError = false;
        if(isPrcAnyTime){
            MakeAppointmentForPortalModalClass mo = newModelList.get(indexNo);
            System.debug('#### ids of packages'+mo.selectedPackageId);
            if(String.isNotBlank(mo.selectedPackageId)){
                selectedPackageIds.add(mo.selectedPackageId);    
            }else{
                isError = true;
            }           
            selectStudentenrolmentIds.add(mo.enrolmentId);
            if(String.isNotBlank(mo.teacherId)){
                selectedTeacherIds.add(mo.teacherId);
            }
            centerIds.add(mo.enrolStudentCenterId);  
        }else{
            for(MakeAppointmentForPortalModalClass mo : newModelList){
                if(String.isNotBlank(mo.selectedPackageId)){
                    selectedPackageIds.add(mo.selectedPackageId);    
                }else{
                    isError = true;
                }           
                selectStudentenrolmentIds.add(mo.enrolmentId);
                if(String.isNotBlank(mo.teacherId)){
                    selectedTeacherIds.add(mo.teacherId);
                }
                centerIds.add(mo.enrolStudentCenterId);                
            }
        }
        if(selectedTeacherIds.size() > 0){
            selectedTeacher = true;
        }
        if(selectedPackageIds.size() > 0){
            slcdPkg = true;
        }else{
            slcdPkg = false;
        }
        system.debug('package size = '+selectedPackageIds.size());
        system.debug('selected package ids'+selectedPackageIds);
        system.debug('selected enroll ids'+selectStudentenrolmentIds);
        system.debug('selected teacher ids '+selectedTeacherIds);
        
        Map<Id,Package__c> pkgMap = new Map<Id,Package__c>([SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Active__c 
                                                            FROM Package__c WHERE Id IN : selectedPackageIds AND Duration__c != null]);
        system.debug('package map = '+pkgMap);
        Integer maxDuration = 0;
        for(MakeAppointmentForPortalModalClass mo : newModelList){
            System.debug('$$$$'+mo.selectedPackageId);
            if(String.isNotBlank(mo.selectedPackageId) && pkgMap.containsKey(mo.selectedPackageId)){
                Integer tempduration = Integer.valueOf(pkgMap.get(mo.selectedPackageId).Duration__c);
                system.debug('%%%% = '+tempduration);
                slcPkgdDuration += tempduration;    
                mo.selectedPkgDuration = tempduration;
                
                if(tempduration > maxDuration)
                    maxDuration = tempduration;
            }
        }
        
        /*Integer maxDuration = 0;
        for(Package__c pkgList : pkgMap.values()){
            Integer tempduration = Integer.valueOf(pkgList.Duration__c);
            slcPkgdDuration += tempduration;        
            
            if(tempduration > maxDuration)
                maxDuration = tempduration;
        } */      
        
        maxDuration = maxDuration-ConstantsClass.defMinutes; 
        
        System.debug('@@@'+slcPkgdDuration);
        System.debug('!!!!'+makeAvlMinutes);
        
        makeAvlBalanceMinutes = makeAvlMinutes - slcPkgdDuration;
        List<Enrolment__c> enrList = [SELECT Id, Center__c FROM Enrolment__c WHERE Id IN : selectStudentenrolmentIds];
        system.debug('enrol list = '+enrList);
        if(selectedTeacherIds.size() > 0 && slcPkgdDuration > 0 && enrList.size() > 0){
            Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,
                                                             Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Teacher_Name__c IN : selectedTeacherIds AND Center_Name__c IN : centerIds AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False 
                                                             AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null];
            
            if(techWorkSchList.size() > 0){
                for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){               
                    List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
                    if(tchList == null)
                        tchList = new List<Teacher_Working_Hour__c>();
                    
                    tchList.add(tchWrkSch);                                                  
                    teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);  
                }
                //Update by-: Rajesh | Date-: 14/10/2019, To add fifth lesson record related changes
        		Map<String,Fifth_Lesson__c> fifthLsnMap = new Map<String,Fifth_Lesson__c>();
                Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
                Set<String> bookSet = new Set<String>();
                Date startDt = System.today();
                Date endDt   = startDt.addMonths(1);
                
                //Update by-: Rajesh | Date-: 14/10/2019, Added Blocked status to exclude time slot on calender
                Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
                Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed', 'Blocked'};
                String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
                for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                                      FROM Booking__c 
                                      WHERE Teacher_Account__c IN : selectedTeacherIds AND RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null
                                      AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND Status__c IN: bookStatusSet
                                      AND ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Placeholder'))]){
                                          
                    String key = book.Booking_Date__c +':'+ book.Start_Time__c;
                    bookMap.put(key, book); 
                    Time temStartTime = book.Start_Time__c.addMinutes(-maxDuration); 
                    Time endTempT     = book.End_Time__c;
                    while(temStartTime < endTempT){
                        key = book.Booking_Date__c +':'+ temStartTime;
                        bookSet.add(key);
                        
                        temStartTime = temStartTime.addMinutes(15);
                    }                    
                }
                
                //Update by-: Rajesh | Date-: 14/10/2019, Added Blocked status to exclude time slot on calender
                for(Fifth_Lesson__c fifthLsn : [SELECT Id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Teacher_Account__c  
                                                FROM Fifth_Lesson__c 
                                                WHERE Teacher_Account__c IN : selectedTeacherIds AND IsActive__c = True AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)]){
                    if(fifthLsn.End_Time__c > fifthLsn.Start_Time__c){   
                        String key = fifthLsn.Booking_Date__c +':'+ fifthLsn.Start_Time__c;
                        fifthLsnMap.put(key, fifthLsn);  
                        
                        Time temStartTime = fifthLsn.Start_Time__c.addMinutes(-maxDuration); 
                        Time endTempT     = fifthLsn.End_Time__c;
                        while(temStartTime < endTempT){
                            key = fifthLsn.Booking_Date__c +':'+ temStartTime;
                            bookSet.add(key);
                            
                            temStartTime = temStartTime.addMinutes(15);
                        }  
                    }
                }
                
                for(Date st=startDt; st<=endDt; st=st.addDays(1)){
                    TimeSlotModelCntrl mObj = new TimeSlotModelCntrl();
                    Set<Time> morningTimesTemp      = new Set<Time>();
                    Set<Time> afternoonTimesTemp    = new Set<Time>();              
                    String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
                    if(!(isError) && teachWorkSchMap.containsKey(currDay) && teachWorkSchMap.get(currDay).size() > 0){
                        Teacher_Working_Hour__c teachWorkSch = new Teacher_Working_Hour__c();
                        
                        List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                       
                        teachWorkSch = tchWorSchLst.get(0);
                        if(selectedTeacherIds.size() > 1 && selectedTeacherIds.size() != tchWorSchLst.size() && !(isPrcAnyTime)){
                            teachWorkSch.Start_Time__c = null;
                            teachWorkSch.End_Time__c = null;
                        }else if(tchWorSchLst.size() > 1){
                            Set<Id> tchrWorkHourTchSet = new Set<Id>();
                            Time maxStTime;
                            Time minEndTime;
                            
                            for(Teacher_Working_Hour__c tempTeachWorkSch: tchWorSchLst){
                                if(maxStTime == null && minEndTime == null){
                                    maxStTime = tempTeachWorkSch.Start_Time__c;
                                    minEndTime= tempTeachWorkSch.End_Time__c;
                                }else{
                                    if(tempTeachWorkSch.Start_Time__c > maxStTime)
                                        maxStTime = tempTeachWorkSch.Start_Time__c;
                                    if(tempTeachWorkSch.End_Time__c < minEndTime)
                                        minEndTime= tempTeachWorkSch.End_Time__c;
                                }
                                tchrWorkHourTchSet.add(tempTeachWorkSch.Teacher_Name__c);
                            }
                            
                            for(Id tchId: selectedTeacherIds){
                                if(!tchrWorkHourTchSet.contains(tchId)){
                                    maxStTime = null;
                                    minEndTime= null;
                                    break;
                                }
                            }
                            
                            teachWorkSch.Start_Time__c = maxStTime;
                            teachWorkSch.End_Time__c = minEndTime;
                        }    
                        if(teachWorkSch.Start_Time__c != null && teachWorkSch.End_Time__c != null){
                            Time stTime = teachWorkSch.Start_Time__c;
                            while(stTime < teachWorkSch.End_Time__c.addMinutes(-maxDuration)){
                                String key =  st + ':'+ stTime;
                                if(bookMap.containsKey(key)){
                                    Booking__c bookTmp = bookMap.get(key);
                                    stTime = bookTmp.End_Time__c;
                                }else if(fifthLsnMap.containsKey(key)){
                                    Fifth_Lesson__c fifthTmp = fifthLsnMap.get(key);
                                    stTime = fifthTmp.End_Time__c;
                                }else{
                                    string key2 = st + ':'+ stTime.addMinutes(maxDuration);
                                    if(bookMap.containsKey(key2)){
                                        Booking__c bookTmp = bookMap.get(key2);
                                        stTime = bookTmp.End_Time__c;
                                    }else if(fifthLsnMap.containsKey(key2)){
                                        Fifth_Lesson__c fifthTmp = fifthLsnMap.get(key2);
                                        stTime = fifthTmp.End_Time__c;
                                    }else{
                                        if(stTime.hour() < 12){
                                            if(!(bookSet.contains(key)) && stTime.addMinutes(maxDuration) < teachWorkSch.End_Time__c){
                                                DateTime tempTodayTime = System.now().addHours(4);
                                                DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                                
                                                if(tempStDtTime > tempTodayTime){
                                                    morningTimesTemp.add(stTime);
                                                }       
                                            }
                                            stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                        }else{
                                            DateTime tempTodayTime = System.now().addHours(4);
                                            DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                            if(!(bookSet.contains(key)) && tempStDtTime > tempTodayTime){
                                                afternoonTimesTemp.add(stTime);
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
                    TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
                    if(slcdDate != null){
                        if(st == date.Parse(slcdDate)){
                            mObj.morningSlot = mrgSlotList;
                            mObj.afternoonSlot = aftSlotList;                            
                            tSlotMapTemp = mObj;
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
                system.debug('sssss '+tSlotStr);
                allslotslist.clear();
                allslotslist.add(new SelectOption('','Select time'));
                if(tSlotMap != null){
                    if(tSlotMap.morningSlot.size() > 0){
                        for(String times : tSlotMap.morningSlot){
                            allslotslist.add(new SelectOption(times,times));           
                        }
                    }
                    if(tSlotMap.afternoonSlot.size() > 0){
                        for(String times : tSlotMap.afternoonSlot){
                            allslotslist.add(new SelectOption(times,times));            
                        }            
                    }
                }
            }    
        }        
    }
    public void saveBooking(){
        Savepoint sp = Database.setSavepoint();        
        isError = false;
        isSuccess   = false;
        errorMsg = '';
        System.debug('sssss'+slcdSlot);
        List<Booking__c> bookingListForInsert = new List<Booking__c>();
        List<App_Feeds__c> appFeedListForInsert = new List<App_Feeds__c>();
        try{
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            Integer hoursToDeduct = 0;
            Time startTime;            
            if(String.isNotBlank(slcdSlot)){
                List<String> timeList = slcdSlot.split(':');
                startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);
            }
            for(MakeAppointmentForPortalModalClass mObj : newModelList){
                Booking__c bookingObj = new Booking__c(RecordtypeId = bookLessRecId);
                bookingObj.Center__c  = mObj.enrolStudentCenterId;
                bookingObj.Teacher_Account__c = mObj.teacherId;
                bookingObj.Enrolment__c = mObj.enrolmentId;
                bookingObj.Student__c = mObj.studentId;
                bookingObj.Package__c = mObj.selectedPackageId;
                bookingObj.Type__c    = ConstantsClass.typeMakeup;
                bookingObj.status__c  = ConstantsClass.statusScheduled;
                bookingObj.Booking_Date__c = slcdDateNew; 
                bookingObj.Start_Time__c = startTime;
                System.debug('startTime'+startTime);
                if(isPrcAnyTime){
                    bookingObj.Booking_Date__c = mObj.slcdDate; 
                    
                    if(String.isNotBlank(slcdSlot)){
                        System.debug('slcdSlot = '+slcdSlot);
                        List<String> timeList = mObj.slcdTime.split(':');
                        bookingObj.Start_Time__c = startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);
                    }
                }
                if(slcPkgdDuration > 0){                        
                    bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(makeUpPackageMap.get(mObj.selectedPackageId));                    
                }
                 //Added by Rajesh 18th Dec 2019. To identify booking created from
                bookingObj.Booking_Created_Via__c     = 'Portal';
                bookingListForInsert.add(bookingObj);             
            }            
            if(bookingListForInsert.size() > 0){
               // if(bookingListForInsert[0].Type__c == ConstantsClass.typeMakeup){                    
                    deductMakeupHours(bookingListForInsert, parId,makeUpPackageMap);
                //}
                for(Booking__c book : bookingListForInsert){
                    App_Feeds__c appFeed = new App_feeds__c();
                    appFeed.Teacher__c = book.Teacher_Account__c;
                    appFeed.Booking_Id__c = book.Id;
                    appFeed.Student__c = book.Student__c;
                    appFeed.Type__c = 'Make-Up';
                    appFeed.Location__c = book.Location__c;
                    appFeed.Center__c = book.Center__c;
                    appFeed.Booking_Date__c = book.Booking_Date__c;
                    appFeed.Booking_Time__c = book.Start_Time__c;
                    appFeed.Parent__c = parId;
                    appFeed.Instrument__c = book.Instrument__c;
                    appFeedListForInsert.add(appFeed);
                    system.debug('%%%%'+appFeed);
                }
                if(appFeedListForInsert.size() > 0){
                    system.debug('###'+appFeedListForInsert);
                    insert appFeedListForInsert;
                }
            }
            
            isSuccess = true;
       }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError = true;
            return;
       }
    }
    public void deductMakeupHours(List<Booking__c> bookingObjList, String bookingParentId,Map<String,Integer> makeUpPackageMap){
        String statusCanceled = ConstantsClass.statusCanceled;
        //Boolean isError = false;
        //Set<Id> setStudentIds = new Set<Id>();
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        List<Booking__c> bookingInsertList = new List<Booking__c>();
        Integer hoursToDeduct = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        //Booking__c bookObj = new Booking__c();
        Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = getParentsChild(bookingParentId);
        }
        System.debug('@@@bookingObjList'+setOfParentStudent);
        System.debug('@@@bookingObjList'+bookingObjList);
        if(bookingObjList.size() > 0){
            //studentId = bookingObjList[0].Student__c;
            for(Booking__c bObj : bookingObjList){
                //setStudentIds.add(bObj.Student__c);
                setOfBookings.add(bObj.Id);
            }
            /*if(setOfBookings.size() > 0){
                bookingList = [SELECT Id, Duration__c, Make_up_Utilize_Bookings__c FROM Booking__c WHERE Id IN:setOfBookings];
            }*/
            if(setOfParentStudent.size() > 0){
                List<Booking__c> cancelBookings = new List<Booking__c>([SELECT Id, Student__r.Name,Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                                                                        Student__c, Type__c, Duration__c FROM Booking__c WHERE 
                                                                        Status__c =: statusCanceled AND Student__c IN : setOfParentStudent AND 
                                                                        Make_up_Expiry_Date__c >= TODAY AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                                                                        ORDER BY Make_up_Expiry_Date__c]);
                System.debug('@@@@cancelBookings '+cancelBookings.size());
                
                if(cancelBookings.size() > 0){
                    for(Booking__c cancelBooking : cancelBookings){
                        //System.debug('stu = '+cancelBooking.Student__r.Name);
                        //System.debug('par = '+cancelBooking.Parent__r.Name);
                        mapOfHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                    }
                }
                System.debug('@@@mapOfHours'+mapOfHours);
                //System.debug('@@@makeUpPackageMap'+makeUpPackageMap);
                for(Booking__c bookingObj : bookingObjList){
                    hoursToDeduct = makeUpPackageMap.get(bookingObj.Package__c);
                    bookingObj.Make_up_Utilize_Bookings__c = '';
                    for(Booking__c canceledBookings : cancelBookings){
                        if(mapOfHours.containsKey(canceledBookings.Id) && mapOfHours.get(canceledBookings.Id) > 0 ){                            
                            if(hoursToDeduct > mapOfHours.get(canceledBookings.Id)){
                                bookingObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+mapOfHours.get(canceledBookings.Id)+';';
                                hoursToDeduct -= mapOfHours.get(canceledBookings.Id);
                                mapOfHours.put(canceledBookings.Id, 0);
                            }else if(hoursToDeduct <= mapOfHours.get(canceledBookings.Id)){
                                mapOfHours.put(canceledBookings.Id, mapOfHours.get(canceledBookings.Id) - hoursToDeduct);
                                bookingObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+hoursToDeduct+';';
                                hoursToDeduct = 0;
                            }                            
                            if(hoursToDeduct <= 0){
                                break;   
                            }
                        }
                    }
                    System.debug('bookObj '+bookingObj);
                    bookingInsertList.add(bookingObj);
                }
                System.debug('@@@bookingInsertList'+bookingInsertList);
                if(bookingInsertList.size() > 0){
                    Database.SaveResult[] saveResults = Database.insert(bookingInsertList, false);
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()){
                            isError = true;
                        }
                    }      
                }
                for(String keysetValue : mapOfHours.keyset()){
                    if(mapOfHours.containsKey(keysetValue)){
                        bookingUpdatedList.add(new Booking__c(Id = keysetValue, Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                    }
                }
                System.debug('@@@bookingUpdatedList'+bookingUpdatedList); 
                if(bookingUpdatedList.size() > 0){
                    Database.SaveResult[] saveResults = Database.update(bookingUpdatedList, false);
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()){
                            isError = true;
                        }
                    }
                }
            }
        }
    }
    private static Set<String> getParentsChild(String parentId){
        Set<String> setOfAccId = new Set<String>();
        List<Account> accList = [SELECT Id FROM Account WHERE (Id =: parentId OR Parent__c =: parentId)];
        for(Account acc : accList){
            setOfAccId.add(acc.Id);
        }
        return setOfAccId;
    }
    public void getTeachersForSelectedLesson(){
        slcdPkg = false;
        //System.debug('index no'+indexno);
        //System.debug('@@@@'+newModelList.get(indexno));
        MakeAppointmentForPortalModalClass mclassObj = new MakeAppointmentForPortalModalClass();
        mclassObj = newModelList.get(indexno);
        newModelList[indexno].lessonTeacher = getTeachers(mclassObj.instrumentName,mclassObj.enrolStudentCenterId);
        newModelList[indexno].selectedPackageId = '';
        //System.debug('####'+newModelList[indexno].lessonTeacher);
    }
    public class MakeAppointmentForPortalModalClass{
        public boolean flag{get;set;}
        public Enrolment__c enrolmentObject{get;set;}        
        public String studentName{get;set;}
        public List<SelectOption> studentLesson{get;set;}
        public String instrumentName{get;set;}
        public String teacherId{get;set;}
        public String selectedPackageId{get;set;}
        public List<SelectOption> lessonTeacher{get;set;}
        public List<SelectOption> packageList{get;set;}
        public String enrolmentId{get;set;}
        public String enrolStudentCenterId{get;set;}
        public String teacherName{get;set;}
        public String centerName{get;set;}
        public Integer selectedPkgDuration{get;set;}
        public String studentId;
        public Date slcdDate{get;set;} 
        public String slcdTime{get;set;}
        public String tempslcdTime{get;set;}
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