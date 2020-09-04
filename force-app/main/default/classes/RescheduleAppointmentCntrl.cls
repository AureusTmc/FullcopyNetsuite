public without sharing class RescheduleAppointmentCntrl {
    public String slcdCenterName{get;set;}
    public String slcdSlot{get;set;}
    public String slcdTechr{get;set;}
    public String slcdDate{get;set;}
    public TimeSlotModelCntrl tSlotMap{get;set;}
    public Map<String,TimeSlotModelCntrl> tSlotDateMap{get;set;}
    
    //public AccountModel parModel{get;set;}
    //public AccountModel stuModel{get;set;}
    
    public Boolean isError{get;set;}
    public Boolean isSuccess{get;set;}
    public String  errorMsg{get;set;}
    public String tSlotStr{get;set;}
    //public Boolean isAureusAtHome{get;set;}
    //Integer trvlDuration;
    //String  centerId;
    
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
    public RescheduleAppointmentCntrl(){
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
            /*Updated booking query by Rajesh, 8th July 2019
             * Remove 'Is Reschedule Booking' condition from soql restriction given by Prashant
            */
            //Updated by Rajesh, 20th Aug 2019. Updated soql to filter centres on the bases of centre status
            List<Booking__c> bookList = [SELECT Id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Student__r.Name, Enrolment__r.Parent__r.Name, 
                                                Center__c, Package__c, Enrolment__c, Type__c, Status__c, Center__r.Name,
                                                Duration__c, Teacher_Account__c, Teacher_Account__r.Name, Instrument__c, Package__r.Duration__c
                                         FROM Booking__c       
                                         WHERE Id =:bookId AND Status__c =:ConstantsClass.scheduledStatus AND Booking_Date__c != null AND Start_Time__c != null AND End_Time__c != null AND 
                                               Center__c != null AND Center__r.Centre_Status__c =:ConstantsClass.activeStatus AND Package__c != null AND Enrolment__c != null AND Instrument__c != null];
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
                errorMsg = 'The validity of your Unique Link has been expired!';
                isError = true;
            }
        }else{
            errorMsg = 'Booking not available please contact to center admin.';
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
   /* public List<SelectOption> getCenters(){
        List<SelectOption> centerOptions = new List<SelectOption>();
        for(Account acc : [SELECT Id, Name,CentreName_Cust__c FROM Account WHERE Id =: slcdCenter])
            centerOptions.add(new SelectOption(acc.Id, acc.CentreName_Cust__c));
        return centerOptions;
    }*/
    
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
     	
        //Added by Rajesh, 8th Sept 2019, To solve timeslot issue, Addressed by Prashant         
        Set<String> bookSet       = new Set<String>();              
        Integer tempMintsDiff = durationInMin-ConstantsClass.defMinutes;
        
        Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up'};
        Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Make-Up', 'Blocked'};
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
        
       /* for(Booking__c b : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                              FROM Booking__c 
                              WHERE Teacher_Account__c =:techrId AND RecordTypeId =: bookLessRecId 
                                    AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND ((Type__c IN: bookTypeSet AND Status__c IN: bookStatusSet) OR (Type__c = 'Busy'))]){
         */
        for(Booking__c b : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                              FROM Booking__c 
                              WHERE Teacher_Account__c =:techrId AND RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null
                                    AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND Status__c IN: bookStatusSet
                                    AND ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Placeholder'))]){
            //if(book.Id != b.Id && book.Teacher_Account__c != b.Teacher_Account__c){
                String key = b.Teacher_Account__c +':'+ b.Booking_Date__c +':'+ b.Start_Time__c;
                bookMap.put(key, b);   
           // }
            
           	 //Added by Rajesh, 8th Sept 2019, To solve timeslot issue, Addressed by Prashant   
             Time temStartTime = b.Start_Time__c.addMinutes(-tempMintsDiff); 
             Time endTempT     = b.End_Time__c;
             while(temStartTime < endTempT){
                key = b.Teacher_Account__c +':'+ b.Booking_Date__c +':'+ temStartTime;
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
                    
                    //Updated by Rajesh: 8th Aug 2019, to solve timeslot issue, its was showing timeslot on page after teacher working hours
                    while(stTime <= teachWorkSch.End_Time__c.addMinutes(-durationInMin)){
                    //while(stTime < teachWorkSch.End_Time__c.addMinutes(-15)){                           
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
                                    if(!(bookSet.contains(key)) && stTime.addMinutes(ConstantsClass.defMinutes) < teachWorkSch.End_Time__c){
                                        //Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                        //currTime = currTime.addHours(4); 
                                        DateTime tempTodayTime = System.now().addHours(4);
                                    	DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                        
                                        //if(st > System.today() || (st == System.today() &&  stTime > currTime)){
                                        if(tempStDtTime > tempTodayTime){
                                            morningTimesTemp.add(stTime);
                                        }
                                    }
                                    stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                }else{  
                                    //Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                    //currTime = currTime.addHours(4); 
                                    DateTime tempTodayTime = System.now().addHours(4);
                                    DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                    
                                    //if(st > System.today() || (st == System.today() && stTime > currTime)){
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
    
    public void saveBooking(){
        Savepoint sp = Database.setSavepoint();
        isError = false;
        isSuccess   = false;
        errorMsg = '';
        try{
            //List<Booking__c> bookList = RescheduleAppointmentCntrl.queryBooking(book.Id);
            if(Book.Id != null){
               // Booking__c bo = bookList.get(0);
                /*
                Booking__c newBooking = book.clone(false, false, false, false);
                newBooking.Is_Reschedule_Booking__c = true;
                newBooking.Reschedule_Booking__c 	= Book.Id;
                newBooking.Teacher_Account__c 		= slcdTechr;
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
				*/
                
                book.Is_Reschedule_Booking__c = true;
                book.Prev_Teacher__c = book.Teacher_Account__r.Name; 
                book.Prev_Booking_Date__c = book.Booking_Date__c;
                book.Prev_Start_Time__c = book.Start_Time__c;
                
                book.Teacher_Account__c 		= slcdTechr;
                if(String.isNotBlank(slcdDate))
                	book.Booking_Date__c = Date.parse(slcdDate);
                if(String.isNotBlank(slcdSlot)){
                    List<String> timeList = slcdSlot.split(':');
                	Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                	
                    book.Start_Time__c = startTime;
                    if(String.isNotBlank(book.Package__r.Duration__c)){
                        Integer durInMin = 0;
                        try {
                            durInMin = Integer.valueOf(book.Package__r.Duration__c);
                        }Catch (exception e) {}
                        
                        book.End_Time__c = book.Start_Time__c.addMinutes(durInMin);
                    }
                }
				
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
    /*
    public static List<Booking__c> queryBooking(String bookId){
        List<Booking__c> bookList = new List<Booking__c>();
            
        String objectName = 'Booking__c';
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        
        for(Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
            Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
            if (fd.isCreateable()){ // field is creatable
                selectFields.add(fd.getName());
            }
        }
        String soql = 'SELECT ' + String.join(selectFields, ',') +
            ' FROM Booking__c WHERE Id =:bookId ';
        
        bookList = Database.query(soql);
        return bookList;
    }*/
    
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