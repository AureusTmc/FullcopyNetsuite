public with sharing class AutomatingMakeupEnrolmentCtrl {
    public Date enrolmentEffectiveDate{get;set;}
    public string bookingDate{get;set;}
    public String weekday{get;set;}
    public String enrolmentId{get;set;}
    public String regularBookingId{get;set;}
    public Boolean isOssiaOrg{get;set;}
     public Boolean isError{get;set;}
     public Boolean isSucess{get;set;}
    public String errorMessage{get;set;}
    public String selectedtimeslotRealTime{get;set;}
    public String selectedtimeSlot{get;set;}
    public String selectedduration{get;set;}
    
    List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
    Enrolment__c objEnrolment = new Enrolment__c();
    List<Booking__c> listOfBooking = new List<Booking__c>();
    Booking__c objBooking = new Booking__c();
   public AutomatingMakeupEnrolmentCtrl() {
        listOfEnrolment = new List<Enrolment__c>();
        isError = false;
        isOssiaOrg = false;
        isSucess = false;
        //enrolmentId = ApexPages.currentPage().getParameters().get('Id'); 
    }
   
    public void createNewBooking(){
        if(string.isNotBlank(ApexPages.currentPage().getParameters().get('BookingId'))){    
            regularBookingId = ApexPages.currentPage().getParameters().get('BookingId'); 
            selectedtimeslotRealTime = ApexPages.currentPage().getParameters().get('timeslotRealTime'); 
            selectedtimeSlot = ApexPages.currentPage().getParameters().get('bookingTime'); 
            selectedduration = ApexPages.currentPage().getParameters().get('duration'); 
            system.debug('regularBookingId'+regularBookingId);
            system.debug('selectedtimeslotRealTime'+selectedtimeslotRealTime);
            system.debug('selectedtimeSlot'+selectedtimeSlot);
            system.debug('selectedduration'+selectedduration);
           // map<string,set<string>> mapOfavailTimeslots = getmapOfMakeupAvailTimeslots();
            List<AutoMakeupBooking> listOfAutoMakeupBooking = getmapOfMakeupAvailTimeslots();
            system.debug('listOfAutoMakeupBooking'+listOfAutoMakeupBooking);
            createBooking();
        }
    }

    public List<AutoMakeupBooking>  getmapOfMakeupAvailTimeslots(){
        listOfEnrolment = new List<Enrolment__c>();
        isError = false;
        isOssiaOrg = false;
        isSucess = false;
        system.debug('enrolmentId'+regularBookingId);
        // map<string,set<string>> mapOfavailTimeslots = new map<string,set<string>>();
        List<AutoMakeupBooking> listOfAutoMakeupBooking = new List<AutoMakeupBooking>(); 
        if(string.isNotBlank(regularBookingId)){
            listOfBooking = getRegularBookingList(regularBookingId);
            if(listOfBooking != null && listOfBooking.size()>0 ){
                objBooking = listOfBooking[0];
                if(string.isNotBlank(objBooking.enrolment__c)){
                listOfEnrolment = getEnrolmentList(objBooking.enrolment__c,false,null);
                    if(listOfEnrolment != null && listOfEnrolment.size()>0 ){
                        system.debug('listOfEnrolment'+listOfEnrolment);
                        objEnrolment = listOfEnrolment[0];
                        enrolmentEffectiveDate =  objBooking.Booking_date__c;
                        system.debug('enrolmentEffectiveDate'+enrolmentEffectiveDate);
                        if(enrolmentEffectiveDate != null && enrolmentEffectiveDate > System.today()){
                            weekday = Datetime.newInstance(objBooking.Booking_date__c, system.now().time()).format('EEEE');
                            bookingDate = Datetime.newInstance(objBooking.Booking_date__c, system.now().time()).format('dd, MMM yyyy');
                           // mapOfavailTimeslots = getMakeupBookingTimeSlots(objEnrolment.id,Datetime.newInstance(objBooking.Booking_date__c,system.now().time()));
                           listOfAutoMakeupBooking = getAutoMakeupBookingslots(objEnrolment.id,Datetime.newInstance(objBooking.Booking_date__c,system.now().time()));
                            system.debug('listOfAutoMakeupBooking'+listOfAutoMakeupBooking);
                            if(listOfAutoMakeupBooking == null || listOfAutoMakeupBooking.size() == 0){
                                isError = true;
                                errorMessage ='It\'s too late. Now there is no free time slot for your booking. Please contact the contact system.';
                            }
                        }else{
                            isError = true;
                            errorMessage ='It\'s too late. Now there is no free time slot for your booking. Please contact the contact system administrator.' ;
                        }
                        if(objEnrolment.Center__r.Organisation__r.Name == System.Label.Ossia_Organisation_Name){
                            isOssiaOrg= true;
                        } 
                    }else{
                        isError = true;
                        errorMessage ='Enrolment Not Found';
                    }
                }else{
                    isError = true;
                    errorMessage ='Booking Enrolment Not Found';
                }
            }else{
                isError = true;
                errorMessage ='Booking Not Found';
            }
        }else{
            isError = true;
            errorMessage ='Link is incorrect. Please Check this link again.';
        }
        return listOfAutoMakeupBooking;//mapOfavailTimeslots;
    }
 
    public map<string,set<string>> getMakeupBookingTimeSlots(string enrolmentId,datetime enrolmentEffectiveDate){
        listOfEnrolment = getEnrolmentList(enrolmentId,true,enrolmentEffectiveDate);
        map<string,set<string>> mapOfMakeupavailTimeslots = new map<string,set<string>>(); 
        system.debug('#enrolmentEffectiveDate'+enrolmentEffectiveDate);
        Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails> mapOfEnrolmentDetails = MakeupEnrolmentBatchHelper.newMakeupBookingNotification(listOfEnrolment, enrolmentEffectiveDate);
        system.debug('#mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
        //Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days 
        //if any slot is blank then we send out an email notification to Parent for booking the timeslot
        if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
            system.debug('#mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
            Set<string> availabletime =new Set<string>() ;  
            if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                for(MakeupEnrolmentBatchHelper.EnrolmentDetails objEnrolmentDetails: mapOfEnrolmentDetails.values()){
                    if(objEnrolmentDetails.mapOfavailTimeslots != null && objEnrolmentDetails.mapOfavailTimeslots.size() > 0){
                        availabletime =new Set<string>();
                        for(string duration : objEnrolmentDetails.mapOfavailTimeslots.keyset()){
                            availabletime =objEnrolmentDetails.mapOfavailTimeslots.get(duration);
                            if(availabletime != null && availabletime.size() > 0){
                                mapOfMakeupavailTimeslots.put(duration,availabletime);
                            }
                        }
                    }
                    system.debug('#objEnrolmentDetails'+objEnrolmentDetails.objEnrolment.name);
                    system.debug('#objEnrolmentDetails.mapOfavailTimeslots'+objEnrolmentDetails.mapOfavailTimeslots);
                }
            }
        }
        return mapOfMakeupavailTimeslots;
    }

     public class AutoMakeupBooking{
        public string bookinglabel{get;set;}
        public string bookingStartTime{get;set;}
        public string bookingEndTime{get;set;}
        public string timeslotRealTime{get;set;}
        public boolean isShowMakeupBookingButton{get;set;}
        public string makeupBookingDuration{get;set;}
        public AutoMakeupBooking(string bookinglabel,string bookingStartTime,string bookingEndTime,boolean isShowMakeupBookingButton,string duration,string timeslotRealTime){
            this.bookinglabel = bookinglabel;
            this.bookingStartTime = bookingStartTime;
            this.bookingEndTime = bookingEndTime;
            this.isShowMakeupBookingButton = isShowMakeupBookingButton;
            this.makeupBookingDuration = duration;
            this.timeslotRealTime =timeslotRealTime;
        }
     }
    public List<AutoMakeupBooking> getAutoMakeupBookingslots(string enrolmentId,datetime enrolmentEffectiveDate){
        listOfEnrolment = getEnrolmentList(enrolmentId,true,enrolmentEffectiveDate);
        Map<string,AutoMakeupBooking> mapOfAutoMakeupBooking = new Map<string,AutoMakeupBooking>(); 
        system.debug('#enrolmentEffectiveDate'+enrolmentEffectiveDate);
        Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails> mapOfEnrolmentDetails = MakeupEnrolmentBatchHelper.newMakeupBookingNotification(listOfEnrolment, enrolmentEffectiveDate);
        system.debug('#mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
        //Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days 
        //if any slot is blank then we send out an email notification to Parent for booking the timeslot
        if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
            system.debug('#mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
            Set<string> availabletime =new Set<string>() ;  
            if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                for(MakeupEnrolmentBatchHelper.EnrolmentDetails objEnrolmentDetails: mapOfEnrolmentDetails.values()){
                    if(objEnrolmentDetails.mapOfavailTimeslots != null && objEnrolmentDetails.mapOfavailTimeslots.size() > 0){
                        for(string duration : objEnrolmentDetails.mapOfavailTimeslots.keyset()){
                            DateTime enrolmentBeforeStartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c).addMinutes(-integer.valueOf(duration));
                            DateTime enrolmentBeforeEndTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c);
                            set<String> enrolmentBeforeTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentBeforeStartTime, enrolmentBeforeEndTime);
                            string durationString = duration+ ' Mins ';
                            if(objEnrolmentDetails.mapOfavailTimeslots.get(duration) != null && objEnrolmentDetails.mapOfavailTimeslots.get(duration).size() > 0){
                                for(string availTimeSlot: objEnrolmentDetails.mapOfavailTimeslots.get(duration)){
                                    system.debug('availTimeSlot'+availTimeSlot);
                                    system.debug('enrolmentBeforeTimeSlots'+enrolmentBeforeTimeSlots);
                                    if(enrolmentBeforeTimeSlots.contains(availTimeSlot)){
                                        durationString =duration+ ' Mins Before Current Time Slot :';
                                        mapOfAutoMakeupBooking.put(durationString,(new AutoMakeupBooking(durationString,enrolmentBeforeStartTime.format('h:mm a'),enrolmentBeforeEndTime.format('h:mm a'),true,duration,enrolmentBeforeStartTime.format('HH:mm:ss'))));
                                    }
                                }
                            }
                        }
                        DateTime enrolmentstartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c);
                        DateTime enrolmentendTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)));
                        set<String> enrolmentCurrentTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentstartTime, enrolmentendTime);
                        mapOfAutoMakeupBooking.put('Current Time Slot :',(new AutoMakeupBooking('Current Time Slot :',enrolmentstartTime.format('h:mm a'),enrolmentendTime.format('h:mm a'),false,objEnrolment.Package__r.Duration__c,enrolmentstartTime.format('HH:mm:ss'))));
                                   
                        for(string duration : objEnrolmentDetails.mapOfavailTimeslots.keyset()){
                            DateTime enrolmentAfterStartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),enrolmentendTime.time());
                            DateTime enrolmentAfterEndTime = DateTime.newInstance(enrolmentEffectiveDate.date(), enrolmentendTime.time()).addMinutes(Integer.valueOf(duration));
                            set<String> enrolmentAfterTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentAfterStartTime, enrolmentAfterEndTime);
                            string durationString = duration+ ' Mins ';
                            if(objEnrolmentDetails.mapOfavailTimeslots.get(duration) != null && objEnrolmentDetails.mapOfavailTimeslots.get(duration).size() > 0){
                                for(string availTimeSlot: objEnrolmentDetails.mapOfavailTimeslots.get(duration)){
                                    if(enrolmentAfterTimeSlots.contains(availTimeSlot)){
                                        durationString = duration+ ' Mins After Current Time Slot :';
                                        mapOfAutoMakeupBooking.put(durationString,(new AutoMakeupBooking(durationString,enrolmentAfterStartTime.format('h:mm a'),enrolmentAfterEndTime.format('h:mm a'),true,duration,enrolmentAfterStartTime.format('HH:mm:ss'))));
                                    }
                                }
                            }
                        }
                    }
                    system.debug('#objEnrolmentDetails'+objEnrolmentDetails.objEnrolment.name);
                    system.debug('#objEnrolmentDetails.mapOfavailTimeslots'+objEnrolmentDetails.mapOfavailTimeslots);
                }
            }
        }
        return mapOfAutoMakeupBooking.values();
    }
    public List<Booking__C> getRegularBookingList(string bookingid){
        decimal makeupcreditdays  =  decimal.valueOf(System.Label.Total_Make_up_Credits);
        string  organisation =System.Label.Ossia_Organisation_Name;
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled};
        Set<String> bookTypeSet = new Set<String>{ ConstantsClass.typeRegular};
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus}; 
        String enroledStage = ConstantsClass.enroledStatus;
        String queryString = 'SELECT Id,enrolment__c, Name, start_Time__c, Lesson_Type__c, Duration__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
        queryString += ' And Id =: bookingid AND status__c IN: bookingStatus AND Type__c IN: bookTypeSet ';
        queryString += ' And enrolment__r.Type__c In: enrolTypes';
         queryString+= ' AND enrolment__r.Stage__c =: enroledStage ';
         queryString+= ' And (( enrolment__r.Center__r.Organisation__r.Name =: organisation And enrolment__r.Available_Make_up_mins__c  >: makeupcreditdays ) ';
         queryString+= ' Or ( enrolment__r.Center__r.Organisation__r.Name !=: organisation And Parent__r.Available_Make_up_Units__c  >: makeupcreditdays ) )  ';
       system.debug(queryString);
        return Database.query(queryString);
    }
    
    public List<Enrolment__c> getEnrolmentList(string enrolmentid,Boolean isQueryBooking,datetime enrolmentEffectiveDate){
        decimal makeupcreditdays  =  decimal.valueOf(System.Label.Total_Make_up_Credits);
        string  organisation =System.Label.Ossia_Organisation_Name;
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled};
        Set<String> bookTypeSet = new Set<String>{ ConstantsClass.typeRegular};
        Set<Date> dates = new  Set<Date>();
        if(enrolmentEffectiveDate != null ){
            dates.add(enrolmentEffectiveDate.date());
        }
        system.debug('dates'+dates);
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus}; 
        String enroledStage = ConstantsClass.enroledStatus;
       string queryString = 'SELECT Id,Name,Student__c,Lesson_Mode__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
        queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
        queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Resource__c,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId,Parent__r.FCM_Token__c,';
        if(isQueryBooking){
            queryString+= ' (Select id from Bookings__r WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
            queryString += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND Type__c IN: bookTypeSet ), ';
        }
         queryString += ' instrument__c,Automation_make_up_booking_Date__c  FROM Enrolment__c WHERE id != null';
         queryString+= ' AND Type__c In: enrolTypes ';
         queryString+= ' AND Stage__c =: enroledStage ';
        if(isQueryBooking  && string.isNotBlank(weekday)){
            queryString+= ' AND Lesson_Day__c =: weekday ';
        }
         queryString+= ' And (( Center__r.Organisation__r.Name =: organisation And Available_Make_up_mins__c  >: makeupcreditdays ) ';
         queryString+= ' Or ( Center__r.Organisation__r.Name !=: organisation And Parent__r.Available_Make_up_Units__c  >: makeupcreditdays ) )  ';
       queryString+= ' And id=: enrolmentid';
       system.debug(queryString);
        return Database.query(queryString);
    }
    private Boolean checkTimeSlotExist(string selectedtimeSlot,string selectedduration){
        boolean isTimeSlotExist = false;
        map<string,set<string>> mapOfMakeupavailTimeslots = new map<string,set<string>>(); 
        mapOfMakeupavailTimeslots = getMakeupBookingTimeSlots(objEnrolment.id,Datetime.newInstance(enrolmentEffectiveDate, system.now().time()));
        if(mapOfMakeupavailTimeslots != null || mapOfMakeupavailTimeslots.size() > 0){
            if(mapOfMakeupavailTimeslots.containsKey(selectedduration)){
                Set<string> availabletime =new Set<string>() ;  
                availabletime = mapOfMakeupavailTimeslots.get(selectedduration);
                if(availabletime != null || availabletime.size() > 0){
                    if(availabletime.contains(selectedtimeSlot)){
                        isTimeSlotExist = true;
                    }else{
                        isTimeSlotExist = false;
                    }
                }else{
                    isTimeSlotExist = false;
                }
            }else{
                isTimeSlotExist = false;
            }
        }else{
            isTimeSlotExist = false;
        }
        system.debug('###isTimeSlotExist'+isTimeSlotExist);
        return isTimeSlotExist;
    }
    public void createBooking(){
        Savepoint createBookingSavePoint;
        try{
            isError = false;
            isSucess = false;
            createBookingSavePoint = Database.setSavepoint();
           
            if(checkTimeSlotExist(selectedtimeSlot,selectedduration)){
                Booking__c bookingObj = new Booking__c();
                String lessonRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();   
                List<Booking__c> bookingList = new List<Booking__c>();
                List<Package__c> packageList = new List<Package__c>();
                if(string.isNotBlank(objEnrolment.Center__c) && string.isNotBlank(selectedduration)){
                    packageList = [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, Unit_Fee__c, Active__c
                    FROM Package__c WHERE Location__c =: objEnrolment.Center__c AND Active__c = true AND (Type__c = 'Makeup') and Duration__c =:selectedduration];
                }
                system.debug('###packageList'+packageList);
                if(packageList != null && packageList.size() > 0){
                    bookingObj.recordTypeId = lessonRecordType ;
                    bookingObj.Lesson_Type__c=objEnrolment.Lesson_Mode__c;
                    if(objEnrolment.Lesson_Mode__c== ConstantsClass.Online){
                        bookingObj.Is_Lesson_Type_Change__c=true; 
                    }
                    if(string.isNotBlank(objEnrolment.Center__c)){
                        bookingObj.Center__c =objEnrolment.Center__c;
                    }
                    if(string.isNotBlank(objEnrolment.Teacher__c)){
                        bookingObj.Teacher_Account__c = objEnrolment.Teacher__c;
                    }
                    if(string.isNotBlank(objEnrolment.Resource__c)){
                        bookingObj.Resource__c = objEnrolment.Resource__c;
                    }
                    
                    if(string.isNotBlank(objEnrolment.Student__c)){
                        bookingObj.Student__c =objEnrolment.Student__c;
                    }
                    bookingObj.Package__c = packageList[0].id;
                    bookingObj.Type__c = ConstantsClass.typeMakeup;
                    if(isOssiaOrg){
                        bookingObj.Enrolment__c =objEnrolment.id;
                    }
                    bookingObj.status__c = ConstantsClass.statusScheduled;
                    bookingObj.Booking_Date__c = enrolmentEffectiveDate;
                    bookingObj.Start_Time__c = Time.newInstance(Integer.valueOf(selectedtimeslotRealTime.split(':')[0]), Integer.valueOf(selectedtimeslotRealTime.split(':')[1]), Integer.valueOf(selectedtimeslotRealTime.split(':')[2]), 0);
                    if(string.isNotBlank(selectedduration)){
                        bookingObj.End_Time__c =  Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.Start_Time__c).addMinutes(Integer.valueOf(selectedduration)).time();
                    }
                    if(string.isNotBlank(objEnrolment.Parent__c)){
                        bookingObj.Parent__c =objEnrolment.Parent__c;
                    }else{
                        bookingObj.Parent__c = bookingObj.Student__c;
                    }
                    system.debug('##bookingObj'+bookingObj);
                    Boolean isChecked = AureusCalendarController.validateBookingTime(bookingObj.Teacher_Account__c,bookingObj.Booking_Date__c,bookingObj.End_Time__c);
                    system.debug('##isChecked'+isChecked);
                    Database.SaveResult saveResult;
                    if(isChecked){
                        insert bookingObj;
                        system.debug('##bookingObj'+bookingObj);
                        bookingList.add(bookingObj); 
                       AureusCalendarController.deductMakeupHours(bookingList,  bookingObj.Parent__c);
                        Case objCase = AureusCalendarControllerHelper.createCase('', bookingObj.Id, bookingObj.Type__c);
                        system.debug('##objCase'+objCase);
                        if(string.isNotBlank(objCase.id)){
                            isSucess = true;
                            string schaduleStartTime = Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.Start_Time__c).format('h:mm a');
                            string schaduleEndTime = Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.End_Time__c).addMinutes(Integer.valueOf(selectedduration)).format('h:mm a');
                            errorMessage ='Your '+ schaduleStartTime+' - '+ schaduleEndTime +' ('+selectedduration+' mins) makeup booking has been successfully made for '+Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.Start_Time__c).format('dd, MMM')+'!... ';
                        }else{
                            isError = true;
                            errorMessage ='Something went wrong on this page, but the server could not be more specific on what the exact problem is. Please Contact System Admin...';
                        }
                        // isSucess = true;
                        // string schaduleStartTime = Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.Start_Time__c).format('h:mm a');
                        // string schaduleEndTime = Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.End_Time__c).addMinutes(Integer.valueOf(selectedduration)).format('h:mm a');
                        // errorMessage ='Your '+ schaduleStartTime+' - '+ schaduleEndTime +' ('+selectedduration+' mins) makeup booking has been successfully made for '+Datetime.newInstance(bookingObj.Booking_Date__c,  bookingObj.Start_Time__c).format('dd, MMM')+'!... ';
                     
                       
                    }else{
                        isError = true;
                        errorMessage ='Something went wrong on this page, but the server could not be more specific on what the exact problem is. Please Contact System Admin...';
                    }
                }else{
                    isError = true;
                    errorMessage ='Oops !.... A makeup package was not found for this period. Please Contact System Admin...';
                }
            }else{
                isError = true;
                errorMessage ='It\'s too late. Now there is no free time slot for your booking. Please contact the contact system administrator.';
            }
        }catch(Exception e){
            Database.rollback(createBookingSavePoint);
            isError = true;
            system.debug('##error='+e.getMessage());
            errorMessage = 'Something went wrong on this page, but the server could not be more specific on what the exact problem is. Please Contact System Admin...';
        }
    }
}