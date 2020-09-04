public without sharing class MakeupAppointmentCntrl {
    public String parName{get;set;}
    public Integer makeAvlMinutes{get;set;}
    public Integer makeAvlBalanceMinutes{get;set;}
    public String slcdStu{get;set;}
    public String slcdPkg{get;set;}
    public String slcdTchr{get;set;}
    public String slcdDate{get;set;}
    public String slcdSlot{get;set;}
    //Added by Rajesh: 9th Jyly 2019, for add instrument filter
    public String slcdInstrument{get;set;}
    
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    public String tSlotStr{get;set;}
    
    public List<SelectOption> stuOptions{get;set;}    
    public Boolean isError{get;set;}
    public Boolean isSuccess{get;set;}
    public String  errorMsg{get;set;}
    
    public String stuName{get;set;}
    public String slcdCenterName{get;set;}
    public String slcdTechrNameNew{get;set;}
    public String slcdTimeNew{get;set;} 
    public Date   slcdDateNew{get;set;} 
    public Integer slcPkgdDuration{get;set;}
    
    String parId;
    String stuId;
    String cntrId;
    public MakeupAppointmentCntrl(){
        tSlotMap   = new TimeSlotModelCntrl();
        tSlotDateMap= new Map<String,TimeSlotModelCntrl>();
        stuOptions = new List<SelectOption>();
        makeAvlMinutes = 0;
        isSuccess   = false;
        tSlotStr   = '';
        slcdStu    = '';
        //Added by Rajesh: 9th Jyly 2019, for add instrument filter
        slcdInstrument = '';
        slcdDate   = System.today().day()+'/'+System.today().month()+'/'+System.today().year() ;
        
        parId = ApexPages.currentPage().getParameters().get('id');        
        if(String.isNotBlank(parId)){  
            List<Account> accList = [SELECT Id, FirstName, LastName, Name, PersonMobilePhone, PersonOtherPhone, 
                                     PersonEmail, BillingCountryCode, Gender__c, Nationality__c, Phone, Occupation__c, 
                                     BillingStreet, BillingCity, BillingPostalCode, BillingCountry, Available_Make_up_Units__c
                                     FROM Account WHERE Id =: parId];
            if(accList.size() > 0){
                Account ac = accList.get(0);
                parName = ac.Name;
                
                makeAvlMinutes = ac.Available_Make_up_Units__c != null ? Integer.valueOf(ac.Available_Make_up_Units__c) : 0;
                makeAvlBalanceMinutes = 0;
               // parLastName  = ac.LastName;
               
                 //Updated by Rajesh, 20th Aug 2019. Updated soql to filter centres on the bases of centre status
                stuOptions.add(new SelectOption('', '--None--')); 
                for(Enrolment__c enr : [SELECT Id,Name,Student__c,Student__r.Name,Instrument__c FROM Enrolment__c WHERE Parent__c =: parId AND Center__r.Centre_Status__c =:ConstantsClass.activeStatus AND Center__c != null])
                    stuOptions.add(new SelectOption(enr.Id, enr.Student__r.Name+' ('+enr.Instrument__c+')')); 
            }else{
                errorMsg = 'Parent Account no found, please contact with your center admin';
                isError = true;
            }            
        }else{
            errorMsg = 'Parent Account no found, please contact with your center admin';
            isError = true;
        } 
    }    
    
    public List<SelectOption> getMakeupPkg(){
        List<SelectOption> pkgOptions = new List<SelectOption>();
        pkgOptions.add(new SelectOption('', '--None--')); 
        
        if(String.isNotBlank(slcdStu)){
            List<Enrolment__c> enrList = [SELECT Id, Center__c FROM Enrolment__c WHERE Id =: slcdStu];
                
            String centId = enrList.get(0).Center__c;
            //Updated by Rajesh: On 9-07-2019, Added 15 minutes duration condition for remove 15 minutes package
            for(Package__c pkg : [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, 
                                  Unit_Fee__c, Active__c FROM Package__c 
                                  WHERE Location__c =: centId AND Active__c = true AND Type__c = 'Makeup'  AND Duration__c != null AND Duration__c != '15'  ORDER BY Duration__c]){
                
                pkgOptions.add(new SelectOption(pkg.Id, pkg.Name));                     
            }
        }
        
        return pkgOptions;
    }
    
    public String getCenterName(){
        if(String.isNotBlank(slcdStu)){
            List<Enrolment__c> enrList = [SELECT Id, Center__r.Name FROM Enrolment__c WHERE Id =: slcdStu];
            
            if(enrList.size() > 0)
                return enrList.get(0).Center__r.Name;
        }
        return '';
    }
    
    public List<SelectOption> getTeachers(){
        List<SelectOption> teacherOptions = new List<SelectOption>();
        teacherOptions.add(new SelectOption('', '--None--')); 
        //Updated by Rajesh: On 9-07-2019, Added condition For filtering teacher bases on the selected Instrument
        if(String.isNotBlank(slcdStu) && String.isNotBlank(slcdInstrument)){
            List<Enrolment__c> enrList = [SELECT Id, Center__c FROM Enrolment__c WHERE Id =: slcdStu];
            
            String centId = enrList.get(0).Center__c;
             //Updated by Rajesh: On 9-07-2019, For filtering teacher bases on the selected Instrument
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Center_Name__c =: centId AND Active__c = true AND Working_Day__c != null AND Teacher_Name__c != null 
                                                             AND Break_Time__c = False AND Teacher_Name__r.Major_Instruments_Disciplines__c INCLUDES(:slcdInstrument)
                                                         ORDER BY Teacher_Name__r.Name]; 
        
            Map<String,String> tchrMap = new Map<String,String>();
            for(Teacher_Working_Hour__c teachWorkHour : techWorkSchList)
                tchrMap.put(teachWorkHour.Teacher_Name__c, teachWorkHour.Teacher_Name__r.Name);
            
            for(String tchrId: tchrMap.keySet())
                teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
        }
        
        return teacherOptions;
    } 
    
     //Added by Rajesh: On 9-07-2019, Added new function For fetching instruments
    public List<SelectOption> getInstruments(){
        List<SelectOption> instrumentOptions = new List<SelectOption>();
        instrumentOptions.add(new SelectOption('', '--None--')); 
        if(String.isNotBlank(slcdStu)){
            List<Enrolment__c> enrList = [SELECT Id, Center__c FROM Enrolment__c WHERE Id =: slcdStu];
            
            String centId = enrList.get(0).Center__c;
            Set<String> instrumentTempSet = new Set<String>();
            for(Teacher_Working_Hour__c tchrWorHour: [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Major_Instruments_Disciplines__c 
                                                      FROM  Teacher_Working_Hour__c 
                                                      WHERE Center_Name__c =: centId AND Active__c = true AND Working_Day__c != null AND 
                                                      		Teacher_Name__c != null AND Break_Time__c = False AND Teacher_Name__r.Major_Instruments_Disciplines__c != null]){
       			 for(String strIns : tchrWorHour.Teacher_Name__r.Major_Instruments_Disciplines__c.split(';'))
                 	instrumentTempSet.add(strIns); 	                               
            } 
                
            for(String instName: instrumentTempSet)
                instrumentOptions.add(new SelectOption(instName, instName)); 
        }
        
        return instrumentOptions;
    } 
    
    public void changeStudent(){
        slcdTchr = '';
        slcdPkg = '';  
        isError = false;
        //Added by Rajesh: On 9-07-2019, For filtering teacher bases on the selected Instrument
        slcdInstrument = '';
        
        
        if(String.isNotBlank(slcdStu)){
            //Updated by Rajesh: On 9-07-2019, For showing defaut instrument when student changed on the page
            List<Enrolment__c> enrList = [SELECT Id, Center__r.Name, Teacher__c, Instrument__c FROM Enrolment__c WHERE Id =: slcdStu];
            
            if(enrList.size() > 0){
                slcdTchr =  enrList.get(0).Teacher__c;
                slcdInstrument = enrList.get(0).Instrument__c;
            }
        }
    }
    
    public void changeTchr(){
        slcdPkg = null;  
        isError = false;
        
        tSlotStr = '';
        tSlotMap   = new TimeSlotModelCntrl();
        tSlotDateMap= new Map<String,TimeSlotModelCntrl>();
    }
    
     //Added by Rajesh: On 9-07-2019, And this function is calling when instrument changed on the page
    public void changeInstrument(){
        slcdTchr = '';
        slcdPkg = null;  
        isError = false;
        
        tSlotStr = '';
        tSlotMap   = new TimeSlotModelCntrl();
        tSlotDateMap= new Map<String,TimeSlotModelCntrl>();
    }
    
    public void checkAvlMakeup(){ 
        isError = false;
        
        
        if(slcPkgdDuration > 0){
            List<Account> accList = [SELECT Id, Name, RecordType.Name, Available_Make_up_Units__c, Also_a_Student__c, Parent__c, Parent__r.Available_Make_up_Units__c
                                     FROM Account WHERE Id =: parId AND Available_Make_up_Units__c != null];
            if(accList.size() == 0 || Integer.valueOf(accList.get(0).Available_Make_up_Units__c) < slcPkgdDuration){
                isError = true;
                errorMsg = 'You dont have sufficient makeup units. Please contact Centre Admin for more details.';
            }
        }else{
            slcPkgdDuration = 0;
        }
    }
    
    public void fetchTimeSlot(){
        isError = false;  
        //Added by Rajesh: On 9-07-2019, For instrument condition
        tSlotStr = '';
        tSlotMap   = new TimeSlotModelCntrl();
        tSlotDateMap= new Map<String,TimeSlotModelCntrl>();
       
        
        List<Package__c> pkgList = [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Active__c 
                                    FROM Package__c WHERE Id =: slcdPkg]; 
        if(pkgList.size() > 0){
            slcPkgdDuration = Integer.valueOf(pkgList.get(0).Duration__c);
            makeAvlBalanceMinutes = makeAvlMinutes - slcPkgdDuration;
        }
        
        List<Enrolment__c> enrList = [SELECT Id, Center__c FROM Enrolment__c WHERE Id =: slcdStu];
         
        if(String.isNotBlank(slcdTchr) && enrList.size() > 0 && slcPkgdDuration > 0){
            String centId = enrList.get(0).Center__c;
            String techrId = slcdTchr;
            
            Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();        
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,
                                                                    Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Teacher_Name__c =: slcdTchr AND Center_Name__c =: centId AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False 
                                                             AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null];
            
            for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){   
                
                List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
                if(tchList == null)
                    tchList = new List<Teacher_Working_Hour__c>();
                                                                  
                tchList.add(tchWrkSch);                                                  
                teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);  
            }
            
            Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
            Set<String> bookSet       = new Set<String>();
            Date startDt = System.today();
            Date endDt   = startDt.addMonths(1);
            
            //Added by Rajesh, 27th June 2019, for solve timeslot issue.(Last time slot was not showing on calender)                    
            Integer tempMintsDiff = slcPkgdDuration-ConstantsClass.defMinutes;         
            
            //update by-: Nishant |  Date-: 17-06-2019
            //Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up'};
            //Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Make-Up'};
            Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
            Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed'};
            
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
            
         /*   for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                                  FROM Booking__c 
                                  WHERE Teacher_Account__c =:techrId AND RecordTypeId =: bookLessRecId 
                                        AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND ((Type__c IN: bookTypeSet AND Status__c IN: bookStatusSet) OR (Type__c = 'Busy'))]){*/
            for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                                   FROM Booking__c 
                                   WHERE Teacher_Account__c =:techrId AND RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null
                                    AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND Status__c IN: bookStatusSet
                                    AND ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Placeholder'))]){
                                            
                    String key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ book.Start_Time__c;
                    bookMap.put(key, book);   
                    
                    //Commented by Rajesh, 27th June 2019, for solve timeslot issue.(Last time slot was not showing on calender)                    
                    //Time temStartTime = book.Start_Time__c.addMinutes(-slcPkgdDuration); 
                               
                    Time temStartTime = book.Start_Time__c.addMinutes(-tempMintsDiff); 
                    Time endTempT     = book.End_Time__c;//.addMinutes(duraHalfInMinutes);
                    while(temStartTime < endTempT){
                        key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ temStartTime;
                        bookSet.add(key);
                        
                        temStartTime = temStartTime.addMinutes(15);
                    }                        
            }
            
            for(Date st=startDt; st<=endDt; st=st.addDays(1)){
                TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
                
                Set<Time> morningTimesTemp      = new Set<Time>();
                Set<Time> afternoonTimesTemp    = new Set<Time>();
              
                String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
                
                if(teachWorkSchMap.containsKey(currDay)){
                    List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                    
                    for(Teacher_Working_Hour__c teachWorkSch: tchWorSchLst){
                                        
                        Time stTime = teachWorkSch.Start_Time__c;
                        
                        //Updated by Rajesh, 27th June 2019, for solve timeslot issue.(Last time slot was not showing on calender)                    
                        //while(stTime < teachWorkSch.End_Time__c.addMinutes(-(slcPkgdDuration))){
                        while(stTime < teachWorkSch.End_Time__c.addMinutes(-tempMintsDiff)){
                                                    
                            String key = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime;
                            if(bookMap.containsKey(key)){
                                Booking__c bookTmp = bookMap.get(key);
                                stTime = bookTmp.End_Time__c;
                            }else{
                                //Updated by Rajesh, 27th June 2019, for solve timeslot issue.(Last time slot was not showing on calender)                    
                                //string key2 = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime.addMinutes(slcPkgdDuration);
                                string key2 = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime.addMinutes(tempMintsDiff);
                               
                                if(bookMap.containsKey(key2)){
                                    Booking__c bookTmp = bookMap.get(key2);
                                    stTime = bookTmp.End_Time__c;
                                }else{
                                    if(stTime.hour() < 12){
                                        if(!(bookSet.contains(key)) && stTime.addMinutes(slcPkgdDuration) < teachWorkSch.End_Time__c){
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
                
                TimeSlotModelCntrl tSlotMapTemp2 = new TimeSlotModelCntrl();
                if(slcdDate != null){
                    if(st == date.Parse(slcdDate)){
                        tSlotMapTemp.morningSlot = mrgSlotList;
                        tSlotMapTemp.afternoonSlot = aftSlotList;
                        
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
            tSlotMap = tSlotDateMap.get(slcdDate);
        }
    }
    
    public void refreshSummary(){
        List<Enrolment__c> enrList = [SELECT Id, Student__c, Student__r.Name, Parent__r.Name, Center__c, Center__r.Name FROM Enrolment__c WHERE Id =: slcdStu];
        if(enrList.size() > 0){
            stuName        = enrList.get(0).Student__r.Name;
            slcdCenterName = enrList.get(0).Center__r.Name;
            
            stuId  = enrList.get(0).Student__c;
            cntrId = enrList.get(0).Center__c;
        }
        
        
        slcdDateNew = Date.parse(slcdDate);        
        if(String.isNotBlank(slcdSlot)){
            List<String> timeList = slcdSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            slcdTimeNew = DateTime.newInstance(slcdDateNew, tempT).format('hh:mm a');
        }
        
        List<Account> tchrList = [SELECT Id,Name FROM Account WHERE Id=:slcdTchr];
        if(tchrList.size() > 0)
            slcdTechrNameNew = tchrList.get(0).Name;
    }
    
    public void saveBooking(){
        Savepoint sp = Database.setSavepoint();
        isError = false;
        isSuccess   = false;
        errorMsg = '';
        try{
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();    
            Booking__c bookingObj = new Booking__c(RecordtypeId = bookLessRecId);
            bookingObj.Center__c  = cntrId;
            bookingObj.Teacher_Account__c = slcdTchr;
            bookingObj.Enrolment__c = slcdStu;
            bookingObj.Student__c = stuId;
            bookingObj.Package__c = slcdPkg;
            bookingObj.Type__c    = ConstantsClass.typeMakeup;
            bookingObj.status__c  = ConstantsClass.statusScheduled;
            bookingObj.Booking_Date__c = slcdDateNew;
            
            Integer hoursToDeduct = 0;
            if(String.isNotBlank(slcdSlot)){
                List<String> timeList = slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                
                bookingObj.Start_Time__c = startTime;
                if(slcPkgdDuration > 0){                        
                    bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(slcPkgdDuration);
                    hoursToDeduct = slcPkgdDuration;
                }
            }
            
            //Deduct hours
            List<Booking__c> cancelBookings = [SELECT Id, Available_Make_up_Units__c, Make_up_Expiry_Date__c, Student__c, Duration__c 
                                               FROM Booking__c WHERE Status__c =: ConstantsClass.statusCanceled AND (Student__c =: parId OR Student__r.Parent__c =: parId)
                                               AND Make_up_Expiry_Date__c >= TODAY AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                                               ORDER BY Make_up_Expiry_Date__c];
            Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
            if(cancelBookings.size() > 0){
                for(Booking__c cancelBooking : cancelBookings)
                    mapOfHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                
                bookingObj.Make_up_Utilize_Bookings__c = '';
                
                for(Booking__c book : cancelBookings){
                    if(mapOfHours.containsKey(book.Id) && mapOfHours.get(book.Id) > 0 ){
                        if(hoursToDeduct > mapOfHours.get(book.Id)){
                            bookingObj.Make_up_Utilize_Bookings__c  += book.Id +'-'+mapOfHours.get(book.Id)+';';
                            hoursToDeduct -= mapOfHours.get(book.Id);
                            mapOfHours.put(book.Id, 0);
                        }else if(hoursToDeduct <= mapOfHours.get(book.Id)){
                            mapOfHours.put(book.Id, mapOfHours.get(book.Id) - hoursToDeduct);
                            bookingObj.Make_up_Utilize_Bookings__c  += book.Id +'-'+hoursToDeduct+';';
                            hoursToDeduct = 0;
                        }
                        if(hoursToDeduct <= 0){
                            break;   
                        }
                    }
                }               
            }
            insert bookingObj;
            
            List<Booking__c> bookingUpdatedList = new List<Booking__c>();
            for(String keysetValue : mapOfHours.keyset()){
                if(mapOfHours.containsKey(keysetValue)){
                    bookingUpdatedList.add(new Booking__c(Id = keysetValue, Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                }
            }
            if(bookingUpdatedList.size() > 0)
                update bookingUpdatedList;    
            
            AggregateResult[] groupedResults  = [SELECT  SUM(Available_Make_up_Units__c) sumOfHours 
                                                 FROM Booking__c 
                                                 WHERE Status__c =: ConstantsClass.statusCanceled AND Make_up_Expiry_Date__c > TODAY 
                                                 AND Make_up_Expiry_Date__c != NULL AND (Student__c =: parId OR Student__r.Parent__c =: parId)];
            if(groupedResults.size() > 0){
                AggregateResult ag = groupedResults.get(0);
                if(ag.get('sumOfHours') != null){
                    Account ac = new Account(Id = parId, Available_Make_up_Units__c = Integer.valueOf(ag.get('sumOfHours')));
                    update ac;
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
    
    /*public String slcdCenterName{get;set;}
    public String slcdSlot{get;set;}
    public String slcdTechr{get;set;}
    public String slcdDate{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    
    public Boolean isError{get;set;}
    public Boolean isSuccess{get;set;}
    public String  errorMsg{get;set;}
    public String tSlotStr{get;set;}
    
    public String stuName{get;set;}
    public String parName{get;set;}
    public Date   bookDate{get;set;}
    public String bookTime{get;set;}
    public Integer durationInMin{get;set;}
    public String instrumentName{get;set;}
    
    public String slcdTechrNameNew{get;set;}
    public String slcdTimeNew{get;set;} 
    public Date   slcdDateNew{get;set;} 
    
    Booking__c book;   
    Boolean isOnLoad;
    public MakeupAppointmentCntrl(){
        tSlotStr   = '';
        slcdCenterName = '';
        slcdDate   = System.today().day()+'/'+System.today().month()+'/'+System.today().year() ;
        tSlotMap   = new TimeSlotModelCntrl();
        tSlotDateMap= new Map<String,TimeSlotModelCntrl>();
        book        = new Booking__c();     
        isError     = false;
        isSuccess   = false;
        errorMsg    = '';
        isOnLoad    = true; 
        String bookId = ApexPages.currentPage().getParameters().get('id');
        if(String.isNotBlank(bookId)){  
            List<Booking__c> bookList = [SELECT Id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Student__r.Name, Enrolment__r.Parent__r.Name, 
                                                Center__c, Package__c, Enrolment__c, Type__c, Status__c, Center__r.Name,
                                                Duration__c, Teacher_Account__c, Instrument__c, Package__r.Duration__c
                                         FROM Booking__c       
                                         WHERE Id =:bookId AND Status__c =:ConstantsClass.scheduledStatus AND Booking_Date__c != null AND Start_Time__c != null AND End_Time__c != null AND 
                                               Center__c != null AND Package__c != null AND Enrolment__c != null AND Instrument__c != null];
            if(bookList.size() > 0){
                book = bookList.get(0);
                stuName    = book.Student__r.Name;
                parName    = book.Enrolment__r.Parent__r.Name;
                bookDate   = book.Booking_Date__c;  
                bookTime   = DateTime.newInstance(book.Booking_Date__c, book.Start_Time__c).format('hh:mm a'); 
                durationInMin = Integer.valueOf(book.Package__r.Duration__c);
                instrumentName= book.Instrument__c;
                slcdCenterName = book.Center__r.Name;
                init();
            }else{
                errorMsg = 'The validity of your Unique Links has been expired!';
                isError = true;
            }
        }else{
            errorMsg = 'Booking not available please contact with your center admin';
            isError = true;
        }
    } 
    
    private void init(){
        slcdTechr  = book.Teacher_Account__c;
        
        Date tempbookDT = book.Booking_Date__c;
        slcdDate   = tempbookDT.day()+'/'+tempbookDT.month()+'/'+tempbookDT.year();
        
        String minTmp = book.Start_Time__c.minute() != 0 ?  (book.Start_Time__c.minute() +'') : '00';
        String tempTSlot = book.Start_Time__c.hour() + ':' + minTmp;
        slcdSlot      = tempTSlot; 
        
        fetchTimeSlot();
    }
    
    //  Method to add centers and plans.
    public List<SelectOption> getTeachers(){
        List<SelectOption> teacherOptions = new List<SelectOption>();
        String teacherRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();
            
        List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Center_Name__c =: book.Center__c AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                         Teacher_Name__r.Major_Instruments_Disciplines__c includes(:book.Instrument__c)]; 
        
        Map<String,String> tchrMap = new Map<String,String>();
        for(Teacher_Working_Hour__c teachWorkHour : techWorkSchList)
            tchrMap.put(teachWorkHour.Teacher_Name__c, teachWorkHour.Teacher_Name__r.Name);
        
        for(String tchrId: tchrMap.keySet())
            teacherOptions.add(new SelectOption(tchrId, tchrMap.get(tchrId))); 
        return teacherOptions;
    }
    
    public void refreshSummary(){
        slcdDateNew = Date.parse(slcdDate);        
        if(String.isNotBlank(slcdSlot)){
            List<String> timeList = slcdSlot.split(':');
            Time tempT = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
            slcdTimeNew = DateTime.newInstance(slcdDateNew, tempT).format('hh:mm a');
        }
        
        List<Account> tchrList = [SELECT Id,Name FROM Account WHERE Id=:slcdTechr];
        if(tchrList.size() > 0)
            slcdTechrNameNew = tchrList.get(0).Name;
    }
    
    public void fetchTimeSlot(){
        String slcdInstrument = book.Instrument__c;
        String techrId = slcdTechr;
        
        if(isOnLoad){
            isOnLoad = false;
        }else{
            slcdSlot = '';
        }
        
        Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();
        
        List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,
                                                                Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                         FROM  Teacher_Working_Hour__c 
                                                         WHERE Teacher_Name__c =: slcdTechr AND Center_Name__c =: book.Center__c AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False 
                                                         AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null AND
                                                             Teacher_Name__r.Major_Instruments_Disciplines__c includes(:slcdInstrument)];
        
        for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){   
            
            List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
            if(tchList == null)
                tchList = new List<Teacher_Working_Hour__c>();
                                                              
            tchList.add(tchWrkSch);                                                  
            teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);  
        }
        
        Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
        Date startDt = System.today();
        Date endDt   = startDt.addMonths(1);
     
        Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular'};
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Make-Up'};
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
        
        for(Booking__c b : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                              FROM Booking__c 
                              WHERE Teacher_Account__c =:techrId AND RecordTypeId =: bookLessRecId 
                                    AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND ((Type__c IN: bookTypeSet AND Status__c IN: bookStatusSet) OR (Type__c = 'Busy'))]){
            
                String key = b.Teacher_Account__c +':'+ b.Booking_Date__c +':'+ b.Start_Time__c;
                bookMap.put(key, b);   
        }
        
        for(Date st=startDt; st<=endDt; st=st.addDays(1)){
            TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();
            
            Set<Time> morningTimesTemp      = new Set<Time>();
            Set<Time> afternoonTimesTemp    = new Set<Time>();
          
            String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
            
            if(teachWorkSchMap.containsKey(currDay)){
                List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                
                for(Teacher_Working_Hour__c teachWorkSch: tchWorSchLst){
                                    
                    Time stTime = teachWorkSch.Start_Time__c;
                    
                    while(stTime < teachWorkSch.End_Time__c.addMinutes(-15)){
                                                
                        String key = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime;
                        if(bookMap.containsKey(key)){
                            Booking__c bookTmp = bookMap.get(key);
                            stTime = bookTmp.End_Time__c;
                        }else{
                            string key2 = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime.addMinutes(15);
                           
                            if(bookMap.containsKey(key2)){
                                Booking__c bookTmp = bookMap.get(key2);
                                stTime = bookTmp.End_Time__c;
                            }else{
                                if(stTime.hour() < 12){
                                    if(stTime.addMinutes(ConstantsClass.defMinutes) < teachWorkSch.End_Time__c){
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
                                    
                                    if(tempStDtTime > tempTodayTime){
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
            
            TimeSlotModelCntrl tSlotMapTemp2 = new TimeSlotModelCntrl();
            if(slcdDate != null){
                if(st == date.Parse(slcdDate)){
                    tSlotMapTemp.morningSlot = mrgSlotList;
                    tSlotMapTemp.afternoonSlot = aftSlotList;
                    
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
        tSlotMap = tSlotDateMap.get(slcdDate);
    }
    
    public void saveBooking(){
        Savepoint sp = Database.setSavepoint();
        isError = false;
        isSuccess   = false;
        errorMsg = '';
        try{
            if(Book.Id != null){
                
                Booking__c newBooking = book.clone(false, false, false, false);
                newBooking.Is_Reschedule_Booking__c = true;
                newBooking.Reschedule_Booking__c    = Book.Id;
                newBooking.Teacher_Account__c       = slcdTechr;
                if(String.isNotBlank(slcdDate))
                    newBooking.Booking_Date__c = Date.parse(slcdDate);
                if(String.isNotBlank(slcdSlot)){
                    List<String> timeList = slcdSlot.split(':');
                    Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                    
                    newBooking.Start_Time__c = startTime;
                    if(String.isNotBlank(book.Package__r.Duration__c)){
                        Integer durInMin = 0;
                        try {
                            durInMin = Integer.valueOf(book.Package__r.Duration__c);
                        }Catch (exception e) {}
                        
                        newBooking.End_Time__c = newBooking.Start_Time__c.addMinutes(durInMin);
                    }
                }
                insert newBooking;
                
                book.Status__c =  'Canceled';
                update book;   
                
                isSuccess = true;
            }
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError = true;
            return;
        }
    }
    */
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