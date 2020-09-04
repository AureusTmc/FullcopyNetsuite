/*
Name    : 

*/
public with Sharing class AureusCalendarClone{
    public String centerName{get;set;}
    public String teacherName{get;set;}
    public String instrumentName{get;set;}
    private String recordTypeTeacher;
    public List<Account> accListForCenter{get;set;}
    public List<Account> accListForTeacher{get;set;}
    public static string caseId;
    //public String bookingStatus{get;set;}
    public String resourceId{get;set;}
    public AureusCalendarClone(){
        accListForTeacher = new List<Account>();
        recordTypeTeacher = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        caseId = ApexPages.currentPage().getParameters().get('id');
    }
    
    
    public List<SelectOption> getCenters() {
        Id recordTypeCenter = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        accListForCenter = [SELECT id, Name FROM Account WHERE recordTypeId =: recordTypeCenter ORDER BY Name];
        List<Centre_Users__c> centerUsers = [SELECT Centre_Name__c, Designation__c FROM Centre_Users__c WHERE User_Name__c =: UserInfo.getUserId() LIMIT 1];
        List<SelectOption> options = new List<SelectOption>();
        for(Account acc : accListForCenter){
            options.add(new SelectOption(acc.id , acc.name));
        }
        if(accListForCenter.size() > 0){
            if(String.isBlank(centerName) && centerUsers.size() > 0){
                centerName = centerUsers[0].Centre_Name__c;
            }else if(String.isBlank(centerName)){
                centerName = accListForCenter[0].id;
            }
        }
        return options;
    }
    
    public List<SelectOption> getTeachers() {
        getTeacherByCenter();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Select Teacher' , 'Select Teacher'));
        options.add(new SelectOption('AllRosteredStaff' , 'All rostered staff'));
        options.add(new SelectOption('AllStaff' , 'All staff'));
        for(Account acc : accListForTeacher){
            options.add(new SelectOption(acc.id , acc.name));
        }
        if(accListForTeacher.size() > 0){
            teacherName = accListForTeacher[0].id;
        }else{      
            teacherName = '';       
        }
        
        return options;
    }
    
    public void getTeacherByCenter(){
        if(String.isBlank(centerName) && accListForCenter.size() > 0){
            centerName = accListForCenter[0].Id;
        }
        accListForTeacher  = AureusCalendarControllerHelper.getListOfTeacher(centerName);
        getResources();
    }
    
    @RemoteAction
    public static List<String> getInstruments(Object[] teachersId){
        Set<String> teachersIds = new Set<String>();
        Set<String> instruments = new Set<String>();
        List<String> instrumentList = new List<String>();
        for(Object obj : teachersId){
            teachersIds.add(String.valueOf(obj));
        }
        List<Account> teacherInstruments = new List<Account>();
        if(teachersId.size() > 0){
            String teacherRecordtype = ConstantsClass.teacherRecordType;
            teacherInstruments = [SELECT Id, Major_Instruments_Disciplines__c, Minor_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecordtype AND Id IN :teachersIds];
        }
        if(teacherInstruments.size() > 0){
            for(Account accObj : teacherInstruments){
                if(String.isNotBlank(accObj.Major_Instruments_Disciplines__c)){
                    instruments.addAll(accObj.Major_Instruments_Disciplines__c.split(';'));
                }
                if(String.isNotBlank(accObj.Minor_Instruments_Disciplines__c) && accObj.Minor_Instruments_Disciplines__c.countMatches(';') > 0){
                    instruments.addAll(accObj.Major_Instruments_Disciplines__c.split(';'));
                }
            }
            
        }    
        instrumentList.addAll(instruments);
        instrumentList.sort();
        return instrumentList;
    }
    
    //get select list of resources
    public List<SelectOption> getResources(){
        List<SelectOption> selectListForResource = new List<SelectOption>();
        selectListForResource.add(new SelectOption('','Select Resource'));
        selectListForResource.add(new SelectOption('AllRosteredResource','All rostered resources'));
        selectListForResource.add(new SelectOption('AllResource','All Resources'));
        if(String.isBlank(centerName)){
            centerName = accListForCenter[0].Id;
        }
        List<Resource__c> listOfResources = AureusCalendarControllerHelper.getListOfResource(centerName);
        for(Resource__c objResource :listOfResources){
            selectListForResource.add(new SelectOption(objResource.Id,objResource.Name));    
        }
        return selectListForResource;
    }
    
    
    /*
getCalendarData Method is Use for returning the JSON for FullCalendar data on any action perform on full calendar UI.

JSON includes: 
1. teachers working hours 
2. bookings
3. busy bookings
4. resources list with their business hours
5. center working hours

with the help of Above data, calendar will show the dynamic data. 

this method takes 5 actual arguments
1. Center Id
2. Teacher Id
3. Resource Id
4. List of String - dates selected on calendar min size of list is 1 and max is 2
5. Instrument Id

*/
    
    
    @RemoteAction
    public static String getCalendarData(String centerId, String teacherId, String resourceId, List<String> datesOfAppointment, String instrument){
        String max;
        String min;
        List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
        List<AureusCalendarController.Events> validationBusinessHours = new List<AureusCalendarController.Events>();
        List<String> weekDays = new List<String>();
        Map<String, String> mapOfweekDays = new Map<String, String>();
        List<Center_Working_Hours__c> centerWorkingHours = new List<Center_Working_Hours__c>();
        AureusCalendarController.TeacherWorkingHours workingHoursOfTeacher = new AureusCalendarController.TeacherWorkingHours();
        AureusCalendarController.ResourceWorkingHours workingHoursOfResource = new AureusCalendarController.ResourceWorkingHours();
        List<Account> listOfAcc = new List<Account>();
        List<Resource__c> listOfResource = new List<Resource__c>();
        List<AureusCalendarController.Resources> listOfResources = new List<AureusCalendarController.Resources>();
        List<AureusCalendarController.Resources> listOfTeachersFilter = new List<AureusCalendarController.Resources>();
        Calendar objCalendar = new Calendar();
        Map<String, List<AureusCalendarController.businessHour>> businessHours = new Map<String, List<AureusCalendarController.businessHour>>();
        
        //Fill the weekday list from the datesOfAppointment List
        if(datesOfAppointment.size() == 2 || datesOfAppointment.size() == 1){
            for(String dateOfCenter : datesOfAppointment){
                String weekDay;
                DateTime dateOfEvents = DateTime.newInstance(Date.valueOf(dateOfCenter), Time.newInstance(0, 0, 0, 0));
                weekDay = dateOfEvents.format('E');
                weekDays.add(weekDay);
            }
        }
        
        if(datesOfAppointment.size() == 2 || datesOfAppointment.size() == 1){
            // got the map of weekday name and date from the helper controller
            mapOfweekDays = AureusCalendarControllerHelper.getMapOfWeekDate(datesOfAppointment);
            
        }
        
        // Fill the Center working Hours according to the center Id, weekdays from the helper controller
        if((weekDays.size() > 0 && String.isNotBlank(centerId)) || String.isNotBlank(teacherId)){
            
            centerWorkingHours  = AureusCalendarControllerHelper.getCenterWorkingHours(centerId, weekDays);
            
            //get the min time and max time of center from the helper controller
            if(centerWorkingHours.size() > 0){
                min = AureusCalendarControllerHelper.getMinTime(centerWorkingHours);
                max = AureusCalendarControllerHelper.getMaxTime(centerWorkingHours);
            }
        }
        
        //get the teacher, teachers working hours and teachers business hours of selected teacher from the calendar
        if(String.isNotBlank(teacherId)){
            Set<String> teach = new Set<String>();
            Set<String> resourceIds = new Set<String>();
            
            //get teachers working hours from the helper controller
            workingHoursOfTeacher  = AureusCalendarControllerHelper.getTeacherWorkingHours(centerId, teacherId, weekDays);
            
            //get events of teachers working hours for validating the calendar from helper controller
            validationBusinessHours.addAll(AureusCalendarControllerHelper.getWorkingHoursTeachers(workingHoursOfTeacher, teacherId, mapOfweekDays));
            
            //get events of teachers working hours for validating the calendar from helper controller
            businessHours = AureusCalendarControllerHelper.getTeachersWorkingHours(workingHoursOfTeacher, teacherId, mapOfweekDays);
            
            if(String.isNotBlank(centerId)){
                List<Account> filtersList = new List<Account>();
                if(String.isNotBlank(instrument)){
                    filtersList = AureusCalendarControllerHelper.getListOfTeachersByInstrument(centerId, instrument);
                }
                else if(String.isBlank(instrument)){
                    filtersList = AureusCalendarControllerHelper.getListOfTeacher(centerId);
                }
                if(filtersList.size() > 0){
                    for(Account objAcc : filtersList){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        
                        listOfTeachersFilter.add(objResource);
                    }
                }
            }
            
            if(teacherId != 'AllStaff' && teacherId != 'AllRosteredStaff'){
                teach.add(teacherId);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                
                eventsList.addAll(bookingLst);
                
                //Get List of teacher on selected center
                listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId, teacherId);
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }else if(teacherId != 'AllRosteredStaff' && teacherId == 'AllStaff' && String.isBlank(instrument)){
                teach.addAll(workingHoursOfTeacher.setOfTeachers);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of teacher on selected center
                listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId);
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }else if(teacherId == 'AllRosteredStaff' && teacherId != 'AllStaff' && String.isBlank(instrument)){
                teach.addAll(workingHoursOfTeacher.setOfTeachers);
                //get Events list of teacher/resource on perticular date or perticular range
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                if(String.isNotBlank(centerId) && teach.size() > 0){
                    //Get List of teacher on selected center and teacher
                    listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId, teach);
                }
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }else if((teacherId == 'AllRosteredStaff' || teacherId == 'AllStaff') && String.isNotBlank(instrument)){
                teach.addAll(workingHoursOfTeacher.setOfTeachers);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                if(String.isNotBlank(centerId) && String.isNotBlank(instrument) && teach.size() > 0){
                    //Get List of teacher on selected center, teacher and instrument
                    if(teacherId == 'AllRosteredStaff'){
                        listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId, teach, instrument);
                    }else if(teacherId == 'AllStaff'){
                        listOfAcc = AureusCalendarControllerHelper.getListOfTeachersByInstrument(centerId, instrument);
                    }
                    
                }
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }
            
            
        }else if(String.isNotBlank(resourceId)){
            
            Set<String> teach = new Set<String>();
            Set<String> resourceIds = new Set<String>();
            
            //Get the list of resources working hours from the helper class
            workingHoursOfResource = AureusCalendarControllerHelper.getResourceWorkingHours(centerId, resourceId, weekDays);
            validationBusinessHours.addAll(getWorkingHoursResource(workingHoursOfResource , resourceId, mapOfweekDays));
            
            //Get Business Hours of the resources from helper class
            businessHours = AureusCalendarControllerHelper.getResourcesWorkingHours(workingHoursOfResource , resourceId, mapOfweekDays);
            if(resourceId != 'AllResource' && resourceId != 'AllRosteredResource'){
                resourceIds.add(resourceId);
                
                //get Events list of teacher/resource on perticular date or perticular range                 
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //get List of resources according to the center Id and Resource Id
                listOfResource = AureusCalendarControllerHelper.getListOfResource(centerId, resourceId);
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }else if(resourceId != 'AllRosteredResource' && resourceId == 'AllResource'){
                resourceIds.addAll(workingHoursOfResource.setOfResources);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of resources according to the center
                listOfResource = AureusCalendarControllerHelper.getListOfResource(centerId);
                
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }else if(resourceId == 'AllRosteredResource' && resourceId != 'AllResource'){
                resourceIds.addAll(workingHoursOfResource.setOfResources);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of resources according to the center and multiple resources
                listOfResource = AureusCalendarControllerHelper.getListOfResource(centerId, resourceIds);
                
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        if(businessHours.containsKey(objAcc.id)){
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours = businessHours.get(objAcc.id);
                        }else{
                            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
                            businessh.start = '00:00:00';
                            businessh.end_c = '00:00:00';
                            businessh.dow = new List<Integer>();
                            businessh.dow.add(0);
                            objResource.businessHours = new List<AureusCalendarController.businessHour>();
                            objResource.businessHours.add(businessh);
                        }
                        listOfResources.add(objResource);
                    }
                }
            }
        }
        
        objCalendar.listOfResources = listOfResources;
        objCalendar.listOfEvents = eventsList;
        objCalendar.teachersWorkingHours = new List<AureusCalendarController.Events>();
        objCalendar.listOfTeachersFilters = new List<AureusCalendarController.Resources>();
        objCalendar.listOfTeachersFilters = listOfTeachersFilter;
        objCalendar.teachersWorkingHours = validationBusinessHours;
        if(String.isNotBlank(min) && String.isNotBlank(max)){
            objCalendar.maxTime = max;
            objCalendar.minTime = min;
        }else{
            objCalendar.maxTime = ConstantsClass.calendarMaxTime;
            objCalendar.minTime = ConstantsClass.calendarMinTime;
        }
        String calJSon = JSON.Serialize(objCalendar).replaceAll('end_c','end');
        
        return calJSon ;
    }
    
    private static List<AureusCalendarController.Events> getWorkingHoursResource(AureusCalendarController.ResourceWorkingHours workingHoursOfResource, String resourceId, Map<String, String> mapOfweekDays){
        List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
        AureusCalendarController.Events currentEvent ;
        if(workingHoursOfResource.resourcesHours.size() > 0){
            for(Resource_Working_Hour__c currentResource : workingHoursOfResource.resourcesHours){
                currentEvent = new AureusCalendarController.Events();
                currentEvent.id = currentResource.Id;
                currentEvent.title = '';
                currentEvent.resourceId = currentResource.Resource_Name__r.Id;
                currentEvent.start =  mapOfweekDays.get(currentResource.Working_Day__c)+'T'+String.valueOf(currentResource.Start_Time__c ).split('\\.')[0];
                currentEvent.end_c = mapOfweekDays.get(currentResource.Working_Day__c)+'T'+String.valueOf(currentResource.End_Time__c).split('\\.')[0];
                if(currentResource.Break_Time__c){
                    currentEvent.overlap = false;
                    currentEvent.rendering = '';
                    currentEvent.className = 'bookingNotAvailable';
                    currentEvent.eventColor = ConstantsClass.notAvailableWorkingHoursColor;
                    currentEvent.title = 'Lunch '+String.valueOf(currentResource.Start_Time__c).split('\\.')[0];
                    currentEvent.eventTextColor = ConstantsClass.eventTextColor;
                    
                }else{
                    currentEvent.eventColor = ConstantsClass.availableWorkingHoursColor;
                    currentEvent.overlap = true;
                    
                    currentEvent.rendering = 'background';
                    
                    currentEvent.className = 'teacherWorkingHours';
                }   
                if(currentEvent.className != 'bookingNotAvailable'){
                    eventsList.add(currentEvent);
                }
                
            }
        }
        return eventsList;
    }
    
    
    
    @RemoteAction 
    public static ProcessResult updateBooking(String bookingId, String startDate, String endDate, String teacherId, String placeholder, String isFuture, String redirectCase, String caseId){
        
        ProcessResult objResult = new ProcessResult();
        Booking__c bookingObj = new Booking__c();
        List<Booking__c> bookingObjList = new List<Booking__c>(); 
        List<Booking__c> bookingList = new List<Booking__c>(); 
        List<Booking__c> bookList = new List<Booking__c>();
        List<Booking__c> oldBookList = new List<Booking__c>();
        Booking__c oldBooking = new Booking__c();
        List<Booking__c> placeholderList = new List<Booking__c>();
        Map<Id ,Enrolment__c> enrollMap = new Map<Id, Enrolment__c>();
        DateTime startDateTime, endDateTime;
        Integer duration = 0;
        Boolean isError = false;
        String lessonRecordType = ConstantsClass.recordTypeLesson;
        String facilityRecordtype = ConstantsClass.recordTypeFacility;
        String busyType = ConstantsClass.typeBusy;
        if(String.isNotBlank(bookingId)){
            bookingObjList = [SELECT Id, Name, Enrolment__c,Package__c , Student__c, Student__r.Name, 
                              Enrolment__r.Teacher__c, Individual_Booking__c, Type__c, Enrolment__r.Lesson_Day__c, 
                              Enrolment__r.Lesson_Start_time__c, Booking_Date__c, Start_Time__c, End_Time__c, 
                              Status__c, Center__c, Teacher_Account__c, Teacher_Account__r.Name, 
                              Duration__c, RecordType.Name, Category__c, Appointment_Day__c
                              FROM Booking__c WHERE Id =: bookingId];
        }
        if(bookingObjList.size() > 0 && isFuture == 'false'){
            bookingObj = bookingObjList[0];
            startDateTime = DateTime.newInstance(bookingObj.Booking_Date__c, bookingObj.Start_Time__c);
            endDateTime = DateTime.newInstance(bookingObj.Booking_Date__c, bookingObj.End_Time__c);
            duration = (Integer)(((endDateTime.getTime() - startDateTime.getTime()) / 1000) / 60);
            oldBooking = bookingObjList[0].clone(false, false, false, false);
            if(String.isNotBlank(startDate)){
                bookingObj.Prev_Start_Time__c = bookingObj.Start_Time__c;
                bookingObj.Start_Time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0); 
                
                bookingObj.Prev_Booking_Date__c = bookingObj.Booking_Date__c;
                bookingObj.Booking_Date__c = Date.valueOf(startDate.split('T')[0]);
            }
            if(String.isNotBlank(endDate)){
                bookingObj.End_Time__c = Time.newInstance(Integer.valueOf(endDate.split('T')[1].split(':')[0]), Integer.valueOf(endDate.split('T')[1].split(':')[1]), Integer.valueOf(endDate.split('T')[1].split(':')[2]), 0);    
            }else if(String.isBlank(endDate)){
                if(bookingObj.Duration__c != NULL){
                    bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(Integer.valueOf(bookingObj.Duration__c));
                }else if(duration > 0){
                    
                    bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(duration);
                }
                
            }
            if(String.isNotBlank(teacherId)){
                if(bookingObj.RecordType.Name == lessonRecordType){
                    bookingObj.Prev_Teacher__c = bookingObj.Teacher_Account__r.Name;
                    bookingObj.Teacher_Account__c = teacherId;
                }else if(bookingObj.RecordType.Name == facilityRecordtype){
                    bookingObj.Resource__c = teacherId;
                }
                
            }
            if(bookingObj.Type__c == ConstantsClass.typeRegular){
                bookingObj.Individual_Booking__c = true;
            }
        }else if(bookingObjList.size() > 0 && isFuture == 'true'){
            bookingObj = bookingObjList[0];
            if(bookingObj.Type__c == ConstantsClass.typeRegular){
                
                String studentId, oldTeacherId, lessonDay;
                Integer oldDuration;
                Time startTime;
                
                DateTime dateChange = DateTime.newInstance(Date.valueOf(startDate.split('T')[0]), Time.newInstance(0, 0, 0, 0));
                Boolean isDayChange = false;
                Enrolment__c enrolObj = new Enrolment__c();
                if(bookingObj.Enrolment__r.Lesson_Day__c != dateChange.format('EEEE')){
                    isDayChange = true;
                }
                
                if(String.isNotBlank(bookingObj.Enrolment__c)){
                    enrolObj = fetchEnrolment(bookingObj.Enrolment__c);
                    studentId = enrolObj.student__c; 
                    oldTeacherId = enrolObj.teacher__c;
                    lessonDay = enrolObj.Lesson_Day__c; 
                    oldDuration = Integer.valueOf(enrolObj.Package__r.duration__c);  
                    startTime = enrolObj.Lesson_start_Time__c; 
                    if(String.isNotBlank(teacherId)){
                        enrolObj.Teacher__c  = teacherId;
                    }
                    if(isDayChange){
                        enrolObj.Lesson_Day__c = dateChange.format('EEEE');
                    }
                    if(String.isNotBlank(startDate)){
                        enrolObj.Lesson_Start_time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0); 
                    } 
                    
                }
                
                if(String.isNotBlank(enrolObj.Id)){
                    UPDATE enrolObj;
                }
                
                if(isDayChange && String.isNotBlank(bookingObj.Enrolment__c)){
                    
                    System.debug('day changed');
                    System.debug('studentId'+studentId);
                    System.debug('oldTeacherId' +oldTeacherId);
                    System.debug('oldDuration'+oldDuration);
                    System.debug('startTime '+startTime);
                    System.debug('lessonDay'+lessonDay);
                    
                    if(String.isNotBlank(studentId) && String.isNotBlank(oldTeacherId) && oldDuration > 0 && startTime != NULL && String.isNotBlank(lessonDay)){
                        AureusCalendarControllerHelper.processBookingsAfterDateChange(enrolObj, dateChange.date(), bookingObj.Booking_Date__c, studentId, oldTeacherId, oldDuration, startTime, lessonDay);
                    }
                    
                }else{
                    bookList  = [SELECT Id, Name, Enrolment__c,Recordtype.Name, Package__c, Student__c, Student__r.Name, Enrolment__r.Teacher__c, Individual_Booking__c, Type__c, Enrolment__r.Lesson_Day__c, Enrolment__r.Lesson_Start_time__c, Booking_Date__c, Start_Time__c, End_Time__c, Status__c, Center__c, Teacher_Account__c,Duration__c FROM Booking__c WHERE 
                                 (Center__c =: bookingObj.Center__c AND Teacher_Account__c =: bookingObj.Teacher_Account__c AND Student__c =: bookingObj.Student__c AND Package__c =: bookingObj.Package__c AND Booking_Date__c >=: bookingObj.Booking_Date__c AND Start_Time__c =: bookingObj.Start_Time__c AND Individual_Booking__c = false)];
                    if(bookList.size() > 0 && String.isNotBlank(startDate)){
                        for(Booking__c book : bookList){
                            oldBookList.add(book.clone(false, false, false, false));
                        }
                        Date rescheduledDate =  Date.valueOf(startDate.split('T')[0]);
                        Date bookingDate = bookingObj.Booking_Date__c;
                        Integer daysdeff = bookingDate.daysBetween(rescheduledDate);
                        for(Booking__c bookObj : bookList){
                            if(String.isNotBlank(startDate)){
                                bookObj.Start_Time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0);
                                bookObj.Booking_Date__c = bookObj.Booking_Date__c.addDays(daysdeff);
                            }
                            if(String.isNotBlank(endDate)){
                                bookObj.End_Time__c = Time.newInstance(Integer.valueOf(endDate.split('T')[1].split(':')[0]), Integer.valueOf(endDate.split('T')[1].split(':')[1]), Integer.valueOf(endDate.split('T')[1].split(':')[2]), 0);
                            }else if(String.isBlank(endDate)){
                                bookObj.End_Time__c = bookObj.Start_Time__c.addMinutes(Integer.valueOf(bookObj.Duration__c));
                            }
                            if(String.isNotBlank(teacherId) && teacherId != bookingObj.Teacher_Account__c){
                                bookObj.Teacher_Account__c = teacherId;
                            }
                            bookingList.add(bookObj); 
                        }
                    }                    
                }
                
            }else if(bookingObj.Type__c == busyType){
                Date rescheduledDate =  Date.valueOf(startDate.split('T')[0]);
                Date bookingDate = bookingObj.Booking_Date__c;
                Integer daysdeff = bookingDate.daysBetween(rescheduledDate);
                
                for(Booking__c busyBookObj : getFutureBusyBookings(BookingObj)){
                    duration = getTimeStampBetween(busyBookObj.Start_Time__c, busyBookObj.End_Time__c);
                    if(String.isNotBlank(startDate)){
                        busyBookObj.Start_Time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0);
                        busyBookObj.Booking_Date__c = busyBookObj.Booking_Date__c.addDays(daysdeff);
                    }
                    
                    if(String.isNotBlank(endDate)){
                        busyBookObj.End_Time__c = Time.newInstance(Integer.valueOf(endDate.split('T')[1].split(':')[0]), Integer.valueOf(endDate.split('T')[1].split(':')[1]), Integer.valueOf(endDate.split('T')[1].split(':')[2]), 0);
                    }else if(String.isBlank(endDate)){
                        busyBookObj.End_Time__c = busyBookObj.Start_Time__c.addMinutes(duration);
                    }
                    
                    if(String.isNotBlank(teacherId) && teacherId != bookingObj.Teacher_Account__c){
                        busyBookObj.Resource__c = teacherId;
                    }
                    bookingList.add(busyBookObj); 
                }
            }
            
        }
        
        if(bookingObj != NULL && isFuture == 'false'){
            bookingList.add(bookingObj);
            oldBookList.add(oldBooking);
        }
        Booking__c placeholderObj = new Booking__c();
        if(bookingList.size() > 0 && placeholder == 'true'){
            placeholderList.addAll(createPlaceholder(oldBookList, 'reschedule', startDate));
        }
        if(bookingList.size() > 0){
            Database.SaveResult[] saveResults = Database.update(bookingList, false);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    isError = true;
                }
            }
        }
        
        if(placeholderList.size() > 0){
            insert placeholderList;
        }
        if(isError){
            objResult.msg = 'Some Error Occured';
        }else{
            if(/*isFuture == 'false' && */bookingList.size() > 0 && bookingList[0].Type__c != ConstantsClass.typeBusy && redirectCase == 'true'){
                Case objCase =  AureusCalendarControllerHelper.createCase(caseId, bookingList[0].id,'Reschedule');
                objResult.caseId = objCase.Id;
            }
            objResult.msg = 'Success';
        }
        
        return objResult;
    }
    
    /*@RemoteAction
public static Boolean sendEmail(String subject, String body, String parentId){
//System.debug('Send Email '+subject+' - -'+body+ '-- '+parentId);
String recordTypeCustomer = ConstantsClass.recordTypeCustomer; 
Boolean Success = false;
String emailAddress = '';
String targetId = '';
if(String.isNotBlank(parentId)){
List<Account> accList = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE RecordType.Name =: recordTypeCustomer AND Id =:parentId ];
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
}*/
    
    @RemoteAction
    public static String getEventDetails(String bookingId){
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c bookingObj = new Booking__c();
        Booking__c bookingObjForService = new Booking__c();
        EventDetails ed = new EventDetails();
        List<Attachment> attachList = new List<Attachment>();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Duration__c,Type__c, Status__c, Price__c, Teacher_Account__r.Name, Package__r.Name, Resource__c, Resource__r.Name, 
                           Student__r.FirstName,  Student__r.LastName, Student__r.Parent__r.FirstName, Student__r.Parent__r.LastName, Student__r.Parent__r.PersonMobilePhone, Student__r.PersonMobilePhone, Student__r.Phone, Student__r.PersonEmail,
                           Student__r.Parent__r.Phone, Student__r.Parent__r.PersonEmail, Student__r.id, RecordType.Name, Individual_Booking__c,  Student__r.Also_a_Student__c, Student__r.Parent__r.Also_a_Student__c, Enrolment__c, Enrolment__r.Package_Process_Type__c, 
                           Enrolment__r.New_Package_Id__r.Name, Enrolment__r.Package_Process_Request_Date__c, Enrolment__r.Effective_Date__c, Enrolment__r.Notice_Period_Start_Date__c, Enrolment__r.Notice_Period_End_Date__c, Enrolment__r.Package_Process_Status__c,
                           Enrolment__r.Advance_Action_Requested_By__r.Name, Center__c, Center__r.Name 
                           FROM Booking__c WHERE id =: bookingId];
            
            if(bookingList.size() > 0){
                String parentID;    
                string teacherProfileName = ConstantsClass.teacherProfileName;
                bookingObj = bookingList[0];
                if(bookingObj.Student__r.Also_a_Student__c && String.isBlank(bookingObj.Student__r.Parent__c)){
                    parentID = '';
                }else{
                    parentID = bookingObj.Student__r.Parent__r.id;
                }
                
                String studentID = bookingObj.Student__r.id;
                datetime mydate = DateTime.newInstance(bookingObj.Booking_Date__c, Time.newInstance(0, 0, 0, 0));
                String bookingDate = mydate.format('dd MMM yyyy');
                
                datetime myTime = DateTime.newInstance(Date.newInstance(0,0,0), bookingObj.Start_Time__c);
                String bookingTime = myTime.format('h:mma');
                
                datetime dtime = DateTime.newInstance(bookingObj.Booking_Date__c, bookingObj.Start_Time__c);
                
                
                
                
                /*List<Subscription__c> subscriptionLst = [SELECT id FROM Subscription__c WHERE Parent__c =: parentID];
Subscription__c subscription = new Subscription__c ();*/
                
                ed.Id = bookingObj.Id;
                ed.name = bookingObj.name;
                ed.service = bookingObj.Package__r.Name;
                ed.staffMember = bookingObj.Teacher_Account__r.Name;
                ed.staffMemberId = bookingObj.Teacher_Account__c;
                ed.resource = bookingObj.Resource__r.Name;
                ed.centerId = bookingObj.center__c;
                ed.centerName = bookingObj.center__r.Name;
                ed.dateAndTime = bookingDate+' at '+bookingTime;
                ed.duration = bookingObj.Duration__c;
                ed.price = bookingObj.Price__c;
                ed.type = bookingObj.Type__c;
                
                ed.studentFirstName = bookingObj.Student__r.FirstName;
                ed.studentLastName = bookingObj.Student__r.LastName;
                if(String.isNotBlank(parentID)){
                    ed.parentFirstName = bookingObj.Student__r.Parent__r.FirstName;
                    ed.parentLastName = bookingObj.Student__r.Parent__r.LastName;
                    ed.parentMobile = bookingObj.Student__r.Parent__r.PersonMobilePhone;
                    ed.parentPhone = bookingObj.Student__r.Parent__r.Phone;
                    ed.parentEmail = bookingObj.Student__r.Parent__r.PersonEmail;
                    ed.studentId = studentID;
                    ed.parentId = parentID;
                }else{
                    ed.parentFirstName = '';
                    ed.parentLastName = '';
                    ed.parentMobile = bookingObj.Student__r.PersonMobilePhone;
                    ed.parentPhone = bookingObj.Student__r.Phone;
                    ed.parentEmail = bookingObj.Student__r.PersonEmail;
                    ed.studentId = studentID;
                    ed.parentId = parentID;
                }
                
                
                ed.status = bookingObj.status__c;
                ed.contentNoteList = getContentNotes(bookingId);
                ed.bookingHistoryList = getBookingHistory(bookingId);
                DateTime dt = DateTime.newInstance(bookingObj.Booking_Date__c , bookingObj.End_Time__c);
                ed.rType = String.valueOf(bookingObj.RecordType.Name);
                ed.endDateTime = dt.format('YYYY-MM-d\'T\'kk:mm:ss');
                ed.timeOfBooking = dtime.format('hh:mma');
                ed.eventDateTime = String.valueOf(dtime.format('yyyy-MM-dd') + 'T' +dtime.format('kk:mm:ss'));
                ed.Individual = String.valueOf(bookingObj.Individual_Booking__c);
                /*if(String.isNotBlank(bookingObj.Teacher_Account__c)){
attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
WHERE parentid=:bookingObj.Teacher_Account__c AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
ORDER BY LastModifiedDate DESC LIMIT 1];
if(attachList.size() > 0){
ed.teacherAttachmentId = attachList[0].Id;
}
}*/
                
                if(String.isNotBlank(bookingObj.Enrolment__c)){
                    ed.enrolment = bookingObj.Enrolment__c;
                    ed.processType = bookingObj.Enrolment__r.Package_Process_Type__c;
                    ed.processStatus = bookingObj.Enrolment__r.Package_Process_Status__c;
                    ed.newPackage = bookingObj.Enrolment__r.New_Package_Id__c;
                    ed.newPackageName = bookingObj.Enrolment__r.New_Package_Id__r.Name;
                    ed.processRequestDate = String.valueOf(bookingObj.Enrolment__r.Package_Process_Request_Date__c);
                    ed.processEffectiveDate = String.valueOf(bookingObj.Enrolment__r.Effective_Date__c);
                    ed.noticeStartDate = String.valueOf(bookingObj.Enrolment__r.Notice_Period_Start_Date__c);
                    ed.noticeEndDate = String.valueOf(bookingObj.Enrolment__r.Notice_Period_End_Date__c);
                    ed.requestedBy = bookingObj.Enrolment__r.Advance_Action_Requested_By__r.Name;
                }
                
                
            }
            String bookingJson = JSON.Serialize(ed);
            return bookingJson;
        }
        
        return null;
    }
    
    @RemoteAction
    public static String getParentId(String bookingId){
        String parentId='';
        List<Booking__c> bookingList = new List<Booking__c>();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Student__c, Student__r.PersonEmail, Student__r.Parent__c, Student__r.Also_a_Student__c, Student__r.Parent__r.PersonEmail, Student__r.Parent__r.Also_a_Student__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                if(String.isNotBlank(bookingList[0].Student__c) && String.isBlank(bookingList[0].Student__r.Parent__c) /*&& bookingList[0].Student__r.Also_a_Student__c*/){
                    parentId = bookingList[0].Student__c;
                }else if((String.isNotBlank(bookingList[0].Student__c)) && String.isNotBlank(bookingList[0].Student__r.Parent__c)/* && !bookingList[0].Student__r.Also_a_Student__c*/){
                    parentId = bookingList[0].Student__r.Parent__c;
                }
            }
        }
        return parentId;
    }
    
    @RemoteAction 
    public static ProcessResult cancelBooking(String bookingId, String cancelReason, String makeUpReason, String makeupRemark, String redirectCase, string caseId, String isFuture){
        ProcessResult objResult = new ProcessResult();
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Booking__c> placeholderList = new List<Booking__c>();
        Boolean isNoMakeup = false;
        if(makeUpReason == 'NoMakeUpForToday'){
            isNoMakeup = true;
            makeUpReason = '';
        }
        //String msg = '';
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Status__c, Type__c, Make_up_Utilize_Bookings__c, Center__c,
                           Make_up_Expiry_Date__c, Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, 
                           Make_up_Credit_Note__c, Start_Time__c, Duration__c, Student__c, Student__r.Name, 
                           Student__r.Parent__c, End_Time__c, Available_Make_up_Units__c, Cancellation_Reason__c, 
                           RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                
                Date expiryDate;
                if(bookingList[0].Type__c == ConstantsClass.typeRegular || bookingList[0].Type__c == ConstantsClass.typeAdhoc){
                    
                    bookingList[0].Status__c = ConstantsClass.statusCanceled;
                    
                    if(bookingList[0].Booking_Date__c != null){
                        expiryDate = bookingList[0].Booking_Date__c.addDays(120);
                    }
                    if(isNoMakeup == false && makeUpReason != 'Student MC'){
                        bookingList[0].Available_Make_up_Units__c = bookingList[0].Duration__c; 
                    }
                    bookingList[0].Make_up_Expiry_Date__c  = expiryDate;
                    
                    
                    if(String.isNotBlank(makeUpReason) && (makeUpReason == ConstantsClass.makeupReasonOther || makeUpReason == ConstantsClass.makeupAdminException) && String.isNotBlank(makeupRemark)){
                        bookingList[0].Makeup_Reason__c =  makeUpReason;
                        bookingList[0].Make_up_Credit_Note__c = makeupRemark;
                    }else if(String.isNotBlank(makeUpReason)){
                        bookingList[0].Makeup_Reason__c =  makeUpReason;
                    }
                }else if(bookingList[0].Type__c == ConstantsClass.typeTrial || bookingList[0].Type__c == ConstantsClass.typeMakeup || bookingList[0].Type__c == ConstantsClass.typeBusy){
                    if(bookingList[0].Type__c == ConstantsClass.typeBusy && isFuture == 'true'){
                        if(!cancelAllFutureBusyBookings(getFutureBusyBookings(bookingList[0]))){
                            objResult.msg = 'Error';
                        }
                    }
                    bookingList[0].Status__c = ConstantsClass.statusCanceled;
                    
                    if(bookingList[0].Type__c == ConstantsClass.typeMakeup){
                        List<String> makeupReferenceList = new List<String>();
                        Set<String> bookingIds = new Set<String>();
                        List<Booking__c> bookingListObj = new List<Booking__c>();
                        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
                        if(String.isNotBlank(bookingList[0].Make_up_Utilize_Bookings__c)){
                            makeupReferenceList.addAll(bookingList[0].Make_up_Utilize_Bookings__c.split(';'));
                            if(makeupReferenceList.size() > 0){
                                for(String makeup : makeupReferenceList){
                                    if(String.isNotBlank(makeup)){
                                        bookingIds.add(makeup.split('-')[0]);
                                    }
                                }
                            }    
                            if(bookingIds.size() > 0){
                                bookingListObj = [SELECT Id, Available_Make_up_Units__c, Make_up_Expiry_Date__c FROM Booking__c WHERE Make_up_Expiry_Date__c >= TODAY AND Id IN: bookingIds];
                                if(bookingListObj.size() > 0){
                                    for(Booking__c booking : bookingListObj){
                                        for(String currentMakeup : makeupReferenceList){
                                            if(currentMakeup.contains(booking.Id)){
                                                bookingUpdatedList.add(new Booking__c(Id = booking.Id, Available_Make_up_Units__c = booking.Available_Make_up_Units__c + Decimal.valueOf(currentMakeup.split('-')[1])));
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            if(bookingUpdatedList.size() > 0){
                                update bookingUpdatedList;
                            }
                            bookingList[0].Make_up_Utilize_Bookings__c = '';
                        }
                    }
                }
                bookingList[0].Cancellation_Reason__c = cancelReason;
                
                Database.SaveResult saveResult = Database.update(bookingList[0], false);
                
                if (saveResult.isSuccess()) {
                    Boolean isError = false;
                    List<Booking__c> bookList = new List<Booking__c>();
                    bookList.add(bookingList[0]);
                    objResult.msg = 'Event Cancelled Successfully';
                    String parentId='';
                    
                    if(bookList[0].Type__c == ConstantsClass.typeRegular){
                        placeholderList.addAll(createPlaceholder(bookList, 'cancel', ''));
                    }
                    
                    Database.SaveResult[] saveResults = Database.insert(placeholderList, false);
                    for(Database.SaveResult sr : saveResults){
                        if (!sr.isSuccess()) {
                            isError = true;
                        }
                    }
                    
                    if(!isError && bookList.size() > 0 && bookList[0].Type__c != ConstantsClass.typeBusy && redirectCase == 'true'){
                        Case objCase =  AureusCalendarControllerHelper.createCase(caseId, bookList[0].Id, 'cancel');
                        objResult.caseId = objCase.Id;
                    }
                    
                }else{
                    for(Database.Error err : saveResult.getErrors()) {
                        objResult.msg = 'The following error has occurred. '+err.getStatusCode() + ' : ' + err.getMessage();
                    }
                }
                
                
            }
        }
        return objResult;
    }
    
    @RemoteAction
    public static Boolean createAdhocBookings(String packageId, String centerId, String teacherId, String studentId, String recurring, String bookingDate){
        Boolean isSuccess;
        Double totalAmount = 0;
        string recordTypeCustomer = ConstantsClass.recordTypeCustomer;
        String stripeId = '';
        List<Booking__c> bookingList = new List<Booking__c>();
        String parentId ;
        List<Account> accList = new List<Account>();
        if(String.isNotBlank(studentId)){
            accList = new List<Account>([SELECT Id, Name, Parent__c, RecordType.Name ,  Also_a_Student__c, Stripe_Customer_Id__c, Parent__r.Stripe_Customer_Id__c 
                                         FROM Account 
                                         WHERE RecordType.Name =: recordTypeCustomer AND Id =: studentId]);
        }
        
        if(accList.size() > 0){
            if(String.isNotBlank(accList[0].Parent__c) && accList[0].Also_a_Student__c == false){
                parentId = accList[0].Parent__c;
                stripeId = accList[0].Parent__r.Stripe_Customer_Id__c;
            }else if(String.isBlank(accList[0].Parent__c) && accList[0].Also_a_Student__c == true){
                parentId = accList[0].Id;
                stripeId = accList[0].Stripe_Customer_Id__c;
            }
        }
        List<Package__c> listOfPackage =[SELECT Name, Id, Unit_Fee__c, Duration__c
                                         FROM Package__c
                                         Where id =: packageId];
        
        Invoice__c objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                    Invoice_Date__c =system.today(), Parent_Account__c = parentId,Center__c=centerId);
        //insert objectOfInvoice;
        if(listOfPackage.size() > 0){
            bookingList = AureusCalendarControllerHelper.createAppointmentForAdhoc(listOfPackage[0], teacherId, studentId, centerId, Integer.valueOf(recurring), bookingDate);
            List<Invoice_Line_Item__c> listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
            Stripe_Payment_Log__c iLog = new Stripe_Payment_Log__c();
            for( Integer i = 0;i < bookingList.size();i++ ){
                totalAmount += Double.valueOf(listOfPackage[0].unit_Fee__c);
            }
            if(totalAmount > 0){
                double gstAdded = totalAmount * (Double.valueOf(System.Label.GST_Tax_Rate) / 100);
                totalAmount += gstAdded;
            }
            if(objectOfInvoice != NULL && totalAmount > 0 && String.isNotBlank(stripeId)){
                BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
                objStripeCharge = updateInvoice(objectOfInvoice, totalAmount, stripeId);
                if(objStripeCharge.statusCode == 200 && objStripeCharge.paid && bookingList.size() > 0){
                    insert bookingList;
                    insert objectOfInvoice;
                    if(objectOfInvoice != NULL){
                        BillingUtility.createInvoiceAttachment(new List<Invoice__c>{objectOfInvoice});
                        
                    }
                    objectOfInvoice = [SELECT Id,Name,Parent_Account__c,Total_Amount__c FROM Invoice__c WHERE Id=: objectOfInvoice.Id];
                    if(objectOfInvoice.id != null){
                        for(Integer i = 0; i < bookingList.size(); i++){
                            listOfInvoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c=listOfPackage[0].unit_Fee__c,package__c=packageId, Booking__c = bookingList[i].Id));
                        }
                    }
                    if(listOfInvoiceLineItem.size() > 0){
                        insert listOfInvoiceLineItem;
                    }
                    Payment__c objPayment = BillingUtility.fillPayment(objectOfInvoice.Parent_Account__c,objectOfInvoice.Id,totalAmount,ConstantsClass.successStatus); 
                    objPayment.Transaction_ID__c = objStripeCharge.Id;
                    insert objPayment;
                    
                    BillingUtility.updateCharge(objStripeCharge.Id,objectOfInvoice.Name);
                }else{
                    isSuccess = false;
                }
            }
            
        }
        return isSuccess;
    }
    
    private static BillingUtility.StripeCharge updateInvoice(Invoice__c invoice, Double total, String stripeId){
        BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
        if(invoice != NULL && total > 0){
            objStripeCharge = BillingUtility.createChargeForCustomer(
                stripeId, total, ConstantsClass.currencyCode);
        }
        return objStripeCharge;
    }
    
    private static List<Booking__c> createPlaceholder(List<Booking__c> bookingObjList, String origin, String newSlot){
        Booking__c placeholderObj = new Booking__c();
        Boolean isError = false;
        DateTime newSlotTime;
        if(String.isNotBlank(newSlot)){
            newSlotTime = DateTime.newInstance(Date.newInstance(0,0,0), Time.newInstance(Integer.valueOf(newSlot.split('T')[1].split(':')[0]), Integer.valueOf(newSlot.split('T')[1].split(':')[1]), Integer.valueOf(newSlot.split('T')[1].split(':')[2]), 0));
        }
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Booking__c bookingCurrentObj : bookingObjList){
            placeholderObj = new Booking__c();
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = bookingCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = bookingCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = bookingCurrentObj.End_Time__c;
            placeholderObj.Teacher_Account__c = bookingCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c = bookingCurrentObj.Center__c;
            if(origin == 'reschedule'){
                placeholderObj.remarks__c = 'placeholder booking for rescheduling '+ bookingCurrentObj.Student__r.Name + ' booking to ' + newSlotTime.format('h:mm a');
            }
            if(origin == 'cancel'){
                placeholderObj.remarks__c = 'placeholder booking for cancelling '+ bookingCurrentObj.Student__r.Name + ' booking';
            }
            if(bookingCurrentObj.RecordType.Name == ConstantsClass.recordTypeLesson){
                placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            }else if(bookingCurrentObj.RecordType.Name == ConstantsClass.recordTypeFacility){
                placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeFacility).getRecordTypeId();
            }
            
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            
            placeholderList.add(placeholderObj);
        }
        return placeholderList;
        
    }
    
    @RemoteAction
    public static Boolean completedOrNoShow(String bookingId, String type, String status){
        Boolean isSuccess = false;
        Booking__c bookingObj = new Booking__c();
        if(String.isNotBlank(bookingId) && String.isNotBlank(status) && String.isNotBlank(type)){
            bookingObj.Id = bookingId;
            if((!(status == ConstantsClass.statusNoshow && type == ConstantsClass.typeBusy)) && !((status == ConstantsClass.statusNoshow || status == ConstantsClass.statusCompleted) && (/*type == ConstantsClass.typeTrial || */type == ConstantsClass.typeAudition))){
                bookingObj.Status__c = status;
                if(ConstantsClass.typeTrial == type && status == ConstantsClass.statusCompleted && String.isNotBlank(bookingId)){
                    List<Booking__c> bookingList = new List<Booking__c>();
                    bookingList = [SELECT Id, Name, Enrolment__c FROM Booking__c WHERE Id =: bookingId];
                    if(bookingList.size() > 0){
                        Enrolment__c enroll = new Enrolment__c();
                        if(String.isNotBlank(bookingList[0].Enrolment__c)){
                            enroll.id = bookingList[0].Enrolment__c;
                            enroll.stage__c = ConstantsClass.enrollStageAttended;
                            update enroll;
                        }
                    }
                }
                
            }    
        }
        if(bookingObj != NULL){
            Database.SaveResult saveResult = Database.update(bookingObj, false);
            if(saveResult.isSuccess()){
                isSuccess = true;
            }
        }
        return isSuccess;
    }    
    @RemoteAction
    public static String showRescheduledBookings(Map<String, Object> bookingReschedule){
        String teacherProfileName = ConstantsClass.teacherProfileName;
        List<Account> accList = new List<Account>();
        List<Booking__c> bookObjList = new List<Booking__c>();
        List<Attachment> attachList = new List<Attachment>();
        Booking__c bookingObj = new Booking__c();
        EventDetails ed = new EventDetails();
        if(bookingReschedule.containsKey('Id')){
            bookObjList = [SELECT id, Booking_Date__c, Start_Time__c, Center__c, End_Time__c, Duration__c,Type__c, Status__c, Price__c, Teacher_Account__r.Name, Package__r.Name, 
                           Student__r.FirstName,  Student__r.LastName, Student__r.Parent__r.FirstName, Student__r.Parent__r.LastName, Student__r.Parent__r.PersonMobilePhone, 
                           Student__r.Parent__r.Phone, Student__r.Parent__r.PersonEmail, Student__r.id, Student__r.PersonMobilePhone, Student__r.Phone, Student__r.PersonEmail,Student__r.Also_a_Student__c, Student__r.Parent__r.Also_a_Student__c, RecordType.Name
                           FROM Booking__c WHERE id =: String.valueOf(bookingReschedule.get('Id'))];
            if(bookObjList.size() > 0){
                bookingObj = bookObjList[0];
                ed.Id = bookingObj.Id;
                
                ed.studentFirstName = bookingObj.Student__r.FirstName;
                ed.studentLastName = bookingObj.Student__r.LastName;
                ed.studentId = bookingObj.Student__c;
                if(bookingObj.Student__r.Also_a_Student__c && String.isBlank(bookingObj.Student__r.Parent__c)){
                    ed.parentId = '';
                }else{
                    ed.parentId = bookingObj.Student__r.Parent__c;
                }
                if(String.isNotBlank(ed.parentId)){
                    ed.parentFirstName = bookingObj.Student__r.Parent__r.FirstName;
                    ed.parentLastName = bookingObj.Student__r.Parent__r.LastName;
                    ed.parentMobile = bookingObj.Student__r.Parent__r.PersonMobilePhone;
                    ed.parentPhone = bookingObj.Student__r.Parent__r.Phone;
                    ed.parentEmail = bookingObj.Student__r.Parent__r.PersonEmail;
                    
                }else{
                    ed.parentFirstName = '';
                    ed.parentLastName = '';
                    ed.parentMobile = bookingObj.Student__r.PersonMobilePhone;
                    ed.parentPhone = bookingObj.Student__r.Phone;
                    ed.parentEmail = bookingObj.Student__r.PersonEmail;
                }             
                
                
                ed.status = bookingObj.status__c;
                ed.duration = bookingObj.Duration__c;
                ed.price = bookingObj.Price__c;
                ed.type = bookingObj.Type__c;
                ed.service = bookingObj.Package__r.Name;
                if(bookingReschedule.containsKey('resource')){
                    if(bookingReschedule.get('resource') != bookingObj.Teacher_Account__c){
                        accList = AureusCalendarControllerHelper.getListOfTeacher(bookingObj.Center__c, String.valueOf(bookingReschedule.get('resource')));
                        if(accList.size() > 0){
                            ed.staffMember = accList[0].Name;
                            attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                          WHERE parentid=:accList[0].Id AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                          ORDER BY LastModifiedDate DESC LIMIT 1];
                            if(attachList.size() > 0){
                                ed.teacherAttachmentId = attachList[0].Id;
                            }
                        }
                    }else{
                        ed.staffMember = bookingObj.Teacher_Account__r.Name;
                        attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                      WHERE parentid=:bookingObj.Teacher_Account__c AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                      ORDER BY LastModifiedDate DESC LIMIT 1];
                        if(attachList.size() > 0){
                            ed.teacherAttachmentId = attachList[0].Id;
                        }
                    }
                    
                }
                if(bookingReschedule.containsKey('date')){
                    ed.timeOfBooking = String.valueOf(bookingReschedule.get('date')).split('T')[1];
                    ed.dateAndTime = String.valueOf(bookingReschedule.get('date'));
                }
                
            }
        }
        String calJSon = JSON.Serialize(ed);
        return calJSon ;
    }
    
    /*private static Boolean createPlaceholder(Booking__c bookingObj){
Boolean isError = false;
Booking__c placeholderObj = new Booking__c();
placeholderObj.Type__c = ConstantsClass.typeBusy;
placeholderObj.Start_Time__c = bookingObj.Start_Time__c;
placeholderObj.End_Time__c = bookingObj.End_Time__c;
placeholderObj.Teacher_Account__c = bookingObj.Teacher_Account__c;
placeholderObj.Booking_Date__c = bookingObj.Booking_Date__c;    
placeholderObj.Center__c = bookingObj.Center_Id__c;              
Database.SaveResult saveResultInsert = Database.insert(placeholderObj, false);
if (!saveResultInsert.isSuccess() ) {
isError = true;
}
return isError; 
}*/
    //Commented due to change in requirment
    /* @RemoteAction
public static Boolean updateStudent(Map<String, Object> accObj){
System.debug('accObj '+accObj);
Boolean isError = false;
List<Account> accList = new List<Account>();
if(accObj.containsKey('id')){
Account acc = new Account();
acc.id = String.valueOf(accObj.get('id'));
acc.FirstName = String.valueOf(accObj.get('firstName'));
acc.LastName = String.valueOf(accObj.get('lastName'));
accList.add(acc);
}
if(accObj.containsKey('parentId')){
Account acc = new Account();
acc.id = String.valueOf(accObj.get('parentId'));
acc.FirstName = String.valueOf(accObj.get('parentFirstName'));
acc.LastName = String.valueOf(accObj.get('parentLastName'));
acc.PersonMobilePhone = String.valueOf(accObj.get('telephone'));
acc.Phone = String.valueOf(accObj.get('sms'));
acc.PersonEmail = String.valueOf(accObj.get('parentEmail'));
accList.add(acc);
}
if(accList.size() > 0){
System.debug(accList.size()+'  '+accList);
Database.SaveResult[] saveResults = Database.update(accList, false);
System.debug(accList.size()+'  '+saveResults);

for(Database.SaveResult saveResult : saveResults) {
if(!saveResult.isSuccess()) {

isError = true;
}    
}
}
return isError;
}*/
    
    
    
    /*private static void cancelBookingProceed(Id studentId, Id parentId){
System.debug('cancelBookingProceed we come here...');
Map<String, Integer> sumOfStudentMakupHours = new Map<String, Integer>();
Map<String, Integer> sumOfParentMakupHours = new Map<String, Integer>();        
List<Account> studentList = new List<Account>();
List<Account> parentList = new List<Account>();

if(String.isNotBlank(studentId)){
AggregateResult[] groupedResults  = [SELECT  Student__c, SUM(Available_Make_up_Units__c) sumOfHours FROM Booking__c WHERE status__c = 'Makeup Pending' AND Student__c = :studentId GROUP BY Student__c ];
for (AggregateResult ar : groupedResults)  {
sumOfStudentMakupHours.put(String.valueOf(ar.get('Student__c')), Integer.valueOf(ar.get('sumOfHours'))); 
}
if(sumOfStudentMakupHours.keyset().size() > 0){
for(String currentStudent : sumOfStudentMakupHours.keyset()){
if(sumOfStudentMakupHours.containsKey(currentStudent)){
studentList.add(new Account(Id=currentStudent, Available_Make_up_Units__c=sumOfStudentMakupHours.get(currentStudent)));
}
}
}
System.debug('studentList '+studentList);
if(studentList.size() > 0){
update studentList;
}
}

if(String.isNotBlank(parentId)){
AggregateResult[] groupedResults  = [SELECT  Parent__c, SUM(Available_Make_up_Units__c ) sumOfHours FROM Account WHERE Parent__r.Id =:parentId  GROUP BY Parent__c];
for (AggregateResult ar : groupedResults)  {
sumOfParentMakupHours.put(String.valueOf(ar.get('Parent__c')), Integer.valueOf(ar.get('sumOfHours'))); 
}
if(sumOfParentMakupHours.keyset().size() > 0){
for(String currentParent : sumOfParentMakupHours.keyset()){
if(sumOfParentMakupHours.containsKey(currentParent)){
parentList.add(new Account(Id=currentParent, Available_Make_up_Units__c=sumOfParentMakupHours.get(currentParent)));
}
}
}
System.debug('parentList '+parentList);
if(parentList.size() > 0){
update parentList;
}
}


}*/
    
    
    private static Map<String, String> getNameFromId(Map<String, String> mapOfBookingHistory){
        Map<String, String> mapOfIdAndName = new Map<String, String>();
        Set<String> objNames = new Set<String>();
        Map<String, Set<Id>> mapOfObjectId = new Map<String, Set<Id>>();
        
        List<String> queryList = new List<String>();
        for(String objName : mapOfBookingHistory.keySet()){
            objNames.add(objName.split('-')[1]);
            //Fill mapOfObjectId
            if(mapOfObjectId.containsKey(objName.split('-')[1])) {
                Set<Id> objId = mapOfObjectId.get(objName.split('-')[1]);
                objId.add(objName.split('-')[2]);
                mapOfObjectId.put(objName.split('-')[1], objId);
            } else {
                mapOfObjectId.put(objName.split('-')[1], new Set<Id> { objName.split('-')[2] });
            }             
        }
        for(String objName : objNames){
            String query = '';
            if(mapOfObjectId.containsKey(objName)){
                Set<Id> objId = mapOfObjectId.get(objName);
                query = 'SELECT Id, Name FROM ' + objName + ' WHERE Id IN :objId';
                queryList.add(query);
            }
        }
        for(String query : queryList){
            List<SObject> sObjectList = Database.query(query); 
            If(sObjectList.size() > 0){
                for(SObject objectObj : sObjectList){
                    mapOfIdAndName.put(String.valueOf(objectObj.get('Id')), String.valueOf(objectObj.get('Name')));
                }
            }
            
        }
        return mapOfIdAndName;
        
    }
    
    private static List<ContentNote> getContentNotes(String bookingId){
        List<Id> contentNotes = new List<Id>();
        for(ContentDocumentLink link :[SELECT ContentDocumentId, Id, LinkedEntityId, IsDeleted, SystemModstamp, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId =:bookingId]){
            contentNotes.add(link.ContentDocumentId);
        }
        
        List<ContentNote> contentNoteList = new List<ContentNote>([SELECT Id, Title, FileType, TextPreview, ContentSize, FileExtension, Content, IsReadOnly, createdDate, Owner.Name FROM ContentNote WHERE Id IN :contentNotes]);
        return contentNoteList;
    }
    
    private static List<BookingHistory> getBookingHistory(String bookingId){
        Map<String, String> mapOfIdAndName = new Map<String, String>();
        List<BookingHistory> ListOfBookingHistory = new List<BookingHistory>();
        BookingHistory currentHistory = new BookingHistory();
        Map<String, String> mapOfBookingHistory = new Map<String, String>(); 
        List<Booking__History> bookingHistoryList = new List<Booking__History>();
        bookingHistoryList = [SELECT IsDeleted, Id, ParentId, CreatedBy.Name, CreatedDate, toLabel(Field), NewValue, OldValue FROM Booking__History WHERE ParentId =: bookingId AND Field !=: 'Field_1__c' ORDER BY CreatedDate DESC];
        if(bookingHistoryList.size() > 0){
            for(Booking__History currentHistoryObj : bookingHistoryList){
                String newValueId = String.valueOf(currentHistoryObj.NewValue);
                String oldValueId = String.valueOf(currentHistoryObj.OldValue);
                if(String.isNotBlank(newValueId) && newValueId instanceOf Id){
                    String mapKey = currentHistoryObj.Id +'-'+findObjectAPIName(newValueId)+'-'+newValueId;
                    mapOfBookingHistory.put(mapKey, newValueId); 
                }
                if(String.isNotBlank(oldValueId) && oldValueId instanceOf Id){
                    String mapKey = currentHistoryObj.Id +'-'+findObjectAPIName(oldValueId)+'-'+oldValueId;
                    mapOfBookingHistory.put(mapKey, oldValueId); 
                }
            }
        } 
        if(mapOfBookingHistory.size() > 0){
            mapOfIdAndName = getNameFromId(mapOfBookingHistory);
        }
        if(bookingHistoryList.size() > 0){
            for(Booking__History history : bookingHistoryList){
                String description = '';
                currentHistory = new BookingHistory();
                currentHistory.HistoryId = history.Id;
                currentHistory.BookingId = history.ParentId;
                //currentHistory.DateOfHistory = history.CreatedDate.format('dd MMM yyyy h:mma');
                currentHistory.DateOfHistory = history.CreatedDate.format('EEE, MMM dd yyyy h:mm a');
                currentHistory.HistoryBy = history.CreatedBy.Name;
                description = 'Booking ' +history.Field + ' changed from ';
                if(String.valueOf(history.OldValue) instanceOf Id){
                    if(mapOfIdAndName.containsKey(String.valueOf(history.OldValue))){
                        description += mapOfIdAndName.get(String.valueOf(history.OldValue)) + ' to '; 
                    }else{
                        description += history.OldValue + ' to '; 
                    } 
                }else{
                    description += history.OldValue + ' to '; 
                }
                
                if(String.valueOf(history.NewValue) instanceOf Id){
                    if(mapOfIdAndName.containsKey(String.valueOf(history.NewValue))){
                        description += mapOfIdAndName.get(String.valueOf(history.NewValue)); 
                    }else{
                        description += history.NewValue; 
                    } 
                }else{
                    description += history.NewValue; 
                }
                currentHistory.Description = description;
                ListOfBookingHistory.add(currentHistory);
            }
        }
        
        return ListOfBookingHistory;
    }
    private static string findObjectAPIName(String recordId){
        if(recordId == null)
            return null;
        String objectAPIName = '';
        String keyPrefix = recordId.substring(0,3);
        for( Schema.SObjectType obj : Schema.getGlobalDescribe().Values() ){
            String prefix = obj.getDescribe().getKeyPrefix();
            if(prefix == keyPrefix){
                objectAPIName = obj.getDescribe().getName();
                break;
            }
        }
        
        return objectAPIName;
        
    }
    
    private static Set<String> getWeekDaySet(List<integer> startEnd){
        Map<integer, String> MapOfWeek = new Map<integer, String>{1 => 'Mon', 2 => 'Tue', 3=> 'Wed', 4=> 'Thu' , 5=> 'Fri', 6=> 'Sat',7=> 'Sun'};
            
            Set<String> weekDays = new Set<String>();
        
        for(integer i = startEnd[0]; i <= startEnd[1]; i++){
            weekDays.add(MapOfWeek.get(i));
        }
        return weekDays;
    }
    @RemoteAction
    public static List<String> getPickListValues(String objName, String fieldName){
        List<String> values = new List<String>(); 
        if(String.isNotBlank(validateObjectNameAndPickList(objName, fieldName))){
            return values;
        }
        
        if(String.isNotBlank(objName) && String.isNotBlank(fieldName)){
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{objName});
            Schema.DescribeFieldResult dfrList = results[0].fields.getMap().get(fieldName).getDescribe();
            String type = String.valueOf(dfrList.getType());
            if(type.equalsIgnoreCase('PICKLIST') || type.equalsIgnoreCase('MULTIPICKLIST')){
                for(Schema.PicklistEntry currentEntry : dfrList.getPicklistValues()){
                    values.add(currentEntry.getValue());
                }
            }
        }else{
            System.debug('Function Calling Error...');
        }
        
        return values;
    }
    private static String validateObjectNameAndPickList(String objName, String fieldName){
        String error = '';
        Map<String, Schema.SObjectType> objResultMap = Schema.getGlobalDescribe();
        if(!objResultMap.containsKey(objName)){
            error += 'Please Insert Correct Object API Name!\n';
        }
        if(String.isBlank(error)){
            Map<String, Schema.SObjectField> fieldDetails = objResultMap.get(objName).getDescribe().fields.getMap();
            if(!fieldDetails.containsKey(fieldName)){
                error += 'Please Correct the Object Field API Name!\n';
            }
        }    
        return error ;
    }
    
    @RemoteAction
    public Static String saveBookingNote(String title, String note, String eventId){
        if(String.isNotBlank(title) && String.isNotBlank(eventId)){
            ContentNote cn = new ContentNote();
            cn.Title = title;
            String body = note;
            cn.Content = Blob.valueOf(body.escapeHTML4());
            insert cn;
            
            if(String.isNotBlank(cn.id)){
                ContentDocumentLink cdLink = new ContentDocumentLink();
                cdLink.ContentDocumentId = cn.id;
                cdLink.LinkedEntityId = eventId;
                cdLink.ShareType = 'V';
                cdLink.Visibility = 'AllUsers';
                insert cdLink;
            }
            List<ContentNote> cn1 = [SELECT id, title, TextPreview, createdDate, Owner.Name FROM ContentNote WHERE id =: cn.id];
            bookingNoteWrapper bn = new bookingNoteWrapper();
            if(cn1.size() > 0){
                
                bn.title = cn1[0].title;
                bn.createdDate = cn1[0].createdDate;
                bn.Body = cn1[0].TextPreview; 
                bn.CreatedBy = cn1[0].Owner.Name;
            }
            
            
            return JSON.serialize(bn);
        }  
        return 'ERROR FOUND';  
    }
    
    @RemoteAction
    public static String getTeacherAndCenter(String centerId, String teacherId){
        List<TeacherAndCenter> teacherAndCenterList = new List<TeacherAndCenter>();
        TeacherAndCenter tcObj = new TeacherAndCenter();
        List<String> idList = new List<String>();
        List<Account> accList = new List<Account>();
        List<Attachment> attachIdList = new List<Attachment>();
        List<Package__c> packageList = new List<Package__c>();
        List<packageWrapper> packageWrapperList = new List<packageWrapper>();
        NewBookingWrapper newBookingWrapperObj = new NewBookingWrapper();
        
        if(String.isNotBlank(centerId)){
            idList.add(centerId);
        }
        if(String.isNotBlank(teacherId)){
            idList.add(teacherId);
        }
        
        if(idList.size() > 0){
            accList = [SELECT Id, Name, RecordType.Name FROM Account WHERE Id IN :idList];
            for(Account acc : accList){
                tcObj = new TeacherAndCenter();
                tcObj.id = acc.Id;
                tcObj.Name = acc.Name;
                if(acc.RecordType.Name == ConstantsClass.centerRecTypeName){
                    tcObj.type = acc.RecordType.Name;
                    teacherAndCenterList.add(tcObj);
                }else if(acc.RecordType.Name == ConstantsClass.teacherRecordType){
                    tcObj.type = acc.RecordType.Name;
                    teacherAndCenterList.add(tcObj);
                }    
            }
            if(teacherAndCenterList.size() > 0){
                newBookingWrapperObj.entities = teacherAndCenterList;
            }
            
        }
        if(String.isNotBlank(centerId)){
            packageWrapper pw = new packageWrapper();
            packageList = [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, Unit_Fee__c, Active__c FROM Package__c WHERE Location__c =: centerId AND Active__c = true AND (Type__c = 'Makeup' OR Type__c = 'Adhoc' OR Type__c = 'Trial')];
            for(Package__c packageObj : packageList){
                pw = new packageWrapper();
                pw.id = packageObj.Id;
                pw.name = packageObj.Name;
                pw.duration = packageObj.Duration__c;
                pw.type = packageObj.Type__c;
                packageWrapperList.add(pw);
            }
            if(packageWrapperList.size() > 0){
                newBookingWrapperObj.packages = packageWrapperList;
            }
            
        }
        /*for(Account acc : [SELECT Id, Name, RecordType.Name, Also_a_Student__c, Parent__c, Parent__r.Name, PersonEmail, Parent__r.PersonEmail, PersonMobilePhone , Parent__r.PersonMobilePhone FROM Account WHERE RecordType.Name = 'Customer' AND ((Also_a_Student__c = true AND Parent__c = NULL) OR (Parent__c != NULL AND Also_a_Student__c = false))]){
sObj = new Students();
sObj.id = acc.Id;
sObj.label = acc.Name;
if(acc.Also_a_Student__c && String.isBlank(acc.Parent__c)){
sObj.parentId = '';
sObj.parentName = '';
sObj.email = acc.PersonEmail;
sObj.phone = acc.PersonMobilePhone;
}else if(acc.Also_a_Student__c == false && String.isNotBlank(acc.Parent__c)){
sObj.parentId = acc.Parent__c;
sObj.parentName = acc.Parent__r.Name;
sObj.email = acc.Parent__r.PersonEmail;
sObj.phone = acc.Parent__r.PersonMobilePhone;
}
sObjList.add(sObj);
}
if(sObjList.size() > 0){
newBookingWrapperObj.studentList = sObjList;
}*/
        
        
        return JSON.serialize(newBookingWrapperObj);
    }
    
    @RemoteAction
    public static String getStudents(String str){
        string recordTypeCustomer = ConstantsClass.recordTypeCustomer;
        Map<Id, Integer> parentMakeupHours = new Map<Id, Integer>();
        List<Account> accList = new List<Account>();
        List<Students> sObjList = new List<Students>();
        Students sObj = new Students();
        if(String.isNotBlank(str)){
            accList = [SELECT Id, Name, RecordType.Name, Available_Make_up_Units__c, Also_a_Student__c, Parent__c, Parent__r.Available_Make_up_Units__c, Parent__r.Name, PersonEmail, Parent__r.PersonEmail, PersonMobilePhone , Parent__r.PersonMobilePhone FROM Account WHERE RecordType.Name =:recordTypeCustomer  AND ((Also_a_Student__c = true AND Parent__c = NULL) OR (Parent__c != NULL AND Also_a_Student__c = false)) AND (Name LIKE :'%'+str+'%') LIMIT 10];
            for(Account acc : accList){
                sObj = new Students();
                sObj.id = acc.Id;
                sObj.label = acc.Name;
                
                if(acc.Also_a_Student__c && String.isBlank(acc.Parent__c)){
                    sObj.parentId = '';
                    sObj.parentName = '';
                    sObj.email = acc.PersonEmail;
                    sObj.phone = acc.PersonMobilePhone;
                    sObj.makeupHours = Integer.valueOf(acc.Available_Make_up_Units__c);
                }else if(acc.Also_a_Student__c == false && String.isNotBlank(acc.Parent__c)){
                    sObj.parentId = acc.Parent__c;
                    sObj.parentName = acc.Parent__r.Name;
                    sObj.email = acc.Parent__r.PersonEmail;
                    sObj.phone = acc.Parent__r.PersonMobilePhone;
                    sObj.makeupHours = Integer.valueOf(acc.Parent__r.Available_Make_up_Units__c);
                }
                if(sObj.makeupHours == NULL){
                    sObj.makeupHours = 0;
                }
                sObjList.add(sObj);
            }
            
        }
        return JSON.serialize(sObjList);
    }
    
    @RemoteAction
    public static ProcessResult /*String*/ createBooking(String bookingJson, String redirectCase, String caseId){
        ProcessResult  objResult = new ProcessResult();
        //String errorMsg = 'false';
        objResult.msg = 'false';
        Boolean isError = false;
        Map<String, Object> bookingMap = new Map<String, Object>();
        Booking__c bookingObj = new Booking__c();
        List<Booking__c> bookingList = new List<Booking__c>();
        DateTime bookingDateTime;
        if(String.isNotBlank(bookingJson)){
            bookingMap = (Map<String, Object>)JSON.deserializeUntyped(bookingJson);
            if(bookingMap.containsKey('date')){
                String bd = String.valueOf(bookingMap.get('date'));
                if(String.isNotBlank(bd)){                   
                    bookingDateTime = DateTime.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]), Integer.valueOf(bd.split('T')[1].split(':')[0]), Integer.valueOf(bd.split('T')[1].split(':')[1]), 0);
                }
            }
            if(bookingMap.containsKey('isRecurring')){
                if(String.valueOf(bookingMap.get('isRecurring')) == 'false'){
                    if(bookingMap.containsKey('centerId')){
                        bookingObj.Center__c = String.valueOf(bookingMap.get('centerId'));
                    }
                    if(bookingMap.containsKey('teacherId')){
                        bookingObj.Teacher_Account__c = String.valueOf(bookingMap.get('teacherId'));
                    }
                    if(bookingMap.containsKey('studentId')){
                        bookingObj.Student__c = String.valueOf(bookingMap.get('studentId'));
                    }
                    if(bookingMap.containsKey('packageId')){
                        bookingObj.Package__c = String.valueOf(bookingMap.get('packageId'));
                    }
                    if(bookingMap.containsKey('type')){
                        if(String.valueOf(bookingMap.get('type')) == ConstantsClass.pakageTypeMakeup){
                            bookingObj.Type__c = ConstantsClass.typeMakeup;
                        }else if(String.valueOf(bookingMap.get('type')) == 'home-trial'){
                            bookingObj.Type__c = ConstantsClass.typeTrial;
                        }else if(String.valueOf(bookingMap.get('type')) == ConstantsClass.typeTrial){
                            bookingObj.Type__c = ConstantsClass.typeTrial;
                        }
                    }
                    bookingObj.status__c = ConstantsClass.statusScheduled;
                    
                    if(bookingMap.containsKey('date')){
                        String bookingDate = String.valueOf(bookingMap.get('date'));
                        if(String.isNotBlank(bookingDate)){
                            bookingObj.Booking_Date__c = Date.valueOf(bookingDate.split('T')[0]);
                            bookingObj.Start_Time__c = Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
                            if(bookingMap.containsKey('duration')){
                                bookingObj.End_Time__c =  Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]) + Integer.valueOf(bookingMap.get('duration')), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
                            }
                        }
                    }
                    
                    //if(bookingObj != NULL){
                    if(String.valueOf(bookingMap.get('type')) == 'home-trial'){
                        createBusyTime(bookingObj);
                    }
                    Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:bookingObj.Student__c ];
                    String parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                    if(bookingObj.Type__c == ConstantsClass.typeTrial){
                        /*@ 18 April 2019 Aureus office, ParentId is not coming in JSON so I made a query here, 
*/
                        
                        Enrolment__c objEnrol = createEnrolmentForTrial(bookingObj,parentId);
                        bookingObj.Enrolment__c = objEnrol.Id;
                    }
                    
                    Database.SaveResult saveResult = Database.insert(bookingObj, false);
                    if(!saveResult.isSuccess()){
                        isError = true;
                        objResult.msg = 'error';
                    }else{
                        if(bookingObj.Type__c == ConstantsClass.typeMakeup  || bookingObj.Type__c == ConstantsClass.typeTrial){
                            if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                                bookingList.add(bookingObj);
                                deductMakeupHours(bookingList, parentId);
                            }
                            
                            //create case Here
                            if((bookingObj.Type__c == ConstantsClass.typeMakeup  || bookingObj.Type__c == ConstantsClass.typeTrial) && redirectCase == 'true'){
                                Case objCase = AureusCalendarControllerHelper.createCase(caseId, bookingObj.Id, bookingObj.Type__c);
                                objResult.caseId = objCase.Id;
                            }
                            
                        }
                        
                    }
                    //}
                }else if(String.valueOf(bookingMap.get('isRecurring')) == 'true'){
                    Integer totalDuration = 0;
                    Integer availableHours = 0;
                    DateTime duplicate = bookingDateTime;
                    String weekDay = duplicate.format('EEE');
                    Integer addDaysCount = 0;
                    Integer countOfOccurence = 0;
                    if(bookingMap.containsKey('Repeat') && String.valueOf(bookingMap.get('Repeat')) == 'Weeks'){
                        if(bookingMap.containsKey('RepeatEvery') && Integer.valueOf(bookingMap.get('RepeatEvery')) > 0){
                            addDaysCount = Integer.valueOf(bookingMap.get('RepeatEvery')) * 7;
                        }
                        
                        if(bookingMap.containsKey('EndsAfter') && Integer.valueOf(bookingMap.get('EndsAfter')) > 0){
                            countOfOccurence = Integer.valueOf(bookingMap.get('EndsAfter'));
                        }else if(bookingMap.containsKey('EndsOn') && String.isNotBlank(String.valueOf(bookingMap.get('EndsOn'))) && addDaysCount > 0){
                            String str = String.valueOf(bookingMap.get('EndsOn'));
                            countOfOccurence = 0;
                            DateTime dt ; 
                            dt = DateTime.newInstance(Integer.valueOf(str.split('/')[2]), Integer.valueOf(str.split('/')[0]), Integer.valueOf(str.split('/')[1]));
                            
                            while(dt.date() >= duplicate.date()){
                                if(duplicate.format('EEE') == weekDay){
                                    countOfOccurence++;
                                }
                                duplicate = duplicate.addDays(addDaysCount);
                            }
                        }
                    }
                    if(String.isNotBlank(weekDay) && addDaysCount > 0 && countOfOccurence > 0){
                        String center, teacher, student, packageId, type, status = '';
                        Integer duration = 0;
                        if(bookingMap.containsKey('centerId')){
                            center = String.valueOf(bookingMap.get('centerId'));
                        }
                        
                        if(bookingMap.containsKey('teacherId')){
                            teacher = String.valueOf(bookingMap.get('teacherId'));
                        }
                        if(bookingMap.containsKey('studentId')){
                            student = String.valueOf(bookingMap.get('studentId'));
                        }
                        if(bookingMap.containsKey('packageId')){
                            packageId = String.valueOf(bookingMap.get('packageId'));
                        }
                        if(bookingMap.containsKey('type')){
                            if(String.valueOf(bookingMap.get('type')) == ConstantsClass.pakageTypeMakeup){
                                type = ConstantsClass.typeMakeup;
                                if(type == ConstantsClass.typeMakeup){
                                    status = ConstantsClass.statusScheduled;
                                }
                            }else{
                                status = ConstantsClass.statusPending;
                            }
                        }
                        if(bookingMap.containsKey('availableHours') && Integer.valueOf(bookingMap.get('availableHours')) > 0){
                            availableHours = Integer.valueOf(bookingMap.get('availableHours'));
                        }
                        if(bookingMap.containsKey('duration') && Integer.valueOf(bookingMap.get('duration')) > 0){
                            duration = Integer.valueOf(bookingMap.get('duration'));
                        }
                        duplicate = bookingDateTime;
                        bookingList = new List<Booking__c>();
                        totalDuration = countOfOccurence * duration;
                        System.debug('@@@duplicate'+duplicate);
                        for(Integer i=1;i<=countOfOccurence;i++){
                            bookingObj = new Booking__c();
                            bookingObj.Center__c = center;
                            bookingObj.Teacher_Account__c = teacher;
                            bookingObj.Student__c = student;
                            bookingObj.Package__c = packageId;
                            bookingObj.Type__c = type;
                            bookingObj.status__c = status;
                            bookingObj.Booking_Date__c = duplicate.date();
                            bookingObj.Start_Time__c = Time.newInstance(duplicate.hour(), duplicate.minute(), 0, 0);
                            bookingObj.end_Time__c = Time.newInstance(duplicate.hour(), duplicate.minute() + duration, 0, 0);
                            bookingList.add(bookingObj);
                            duplicate = duplicate.addDays(addDaysCount);
                            System.debug('@@@NewBookingObj'+bookingObj);
                        }
                        
                        String msg = validateMakupRecurringBookings(bookingList, totalDuration, availableHours);
                        System.debug('@@@msg '+msg);
                         /*if(bookingList.size() > 0 && String.isBlank(msg)){
                           Database.SaveResult[] saveResults = Database.insert(bookingList, false);
                            for(Database.SaveResult saveResult : saveResults){
                                if(!saveResult.isSuccess()){
                                    isError = true;
                                }
                            }
                            Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:student ];
                            String parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                            if(!isError && bookingList.size() > 0){
                                if(bookingList[0].Type__c == ConstantsClass.typeMakeup){
                                    deductMakeupHours(bookingList, parentId);
                                }
                            }
                            
                        }else{
                            isError = true;
                            objResult.msg = msg;
                        }*/
                    }
                }
                
            }
            
        }
        return objResult;
    }
    
    private static Enrolment__c createEnrolmentForTrial(Booking__c objBooking,String parentId){
        
        List<Enrolment__c> listofEnrol = [SELECT Id, Previous_Experience_if_any__c,Cancellation_Policy_Agreed__c ,
                                          I_want_to_receive_latest_newsletter__c FROM Enrolment__c WHERE Student__c =: objBooking.Student__c];
        Enrolment__c enrl = new Enrolment__c();
        enrl.Parent__c     = parentId;
        enrl.Student__c    = objBooking.Student__c;
        enrl.Type__c       = ConstantsClass.typeTrial;
        enrl.Stage__c      = ConstantsClass.requestedSubStatus;
        enrl.Center__c     = objBooking.Center__c;
        enrl.Teacher__c    = objBooking.Teacher_Account__c;
        if(listOfEnrol.size() > 0){
            Enrolment__c oldEnrol = listOfEnrol[0];
            enrl.Previous_Experience_if_any__c  =  oldEnrol.Previous_Experience_if_any__c; //stuPreExperience;
            enrl.Cancellation_Policy_Agreed__c  = oldEnrol.Cancellation_Policy_Agreed__c;
            enrl.I_want_to_receive_latest_newsletter__c = oldEnrol.I_want_to_receive_latest_newsletter__c; //iWantReceivedLatestNew;
        }
        enrl.Package__c = objBooking.Package__c;
        enrl.Trial_Date__c = objBooking.Booking_Date__c;
        enrl.Trial_Start_Time__c = objBooking.Start_Time__c;
        insert enrl;
        return enrl;
    }
    
    private static String validateMakupRecurringBookings(List<Booking__c> bookList, Integer totalDuration, Integer availabelHours){
        String centerId, teacherId = '';
        String errorMsg = '';
        Boolean isCorrect = true;
        Set<Date> dates = new Set<Date>();
        List<Booking__c> existingBookingList = new List<Booking__c>();
        if(availabelHours < totalDuration){
            isCorrect = false;
            errorMsg = 'duration';
        }
        if(bookList.size() > 0 && isCorrect){
            for(Booking__c book : bookList){
                dates.add(book.Booking_Date__c);
                centerId = book.Center__c;
                teacherId = book.Teacher_Account__c;
            }
            System.debug('@@@dates'+dates);
            if(String.isNotBlank(centerId) && String.isNotBlank(teacherId) && dates.size() > 0){
                existingBookingList = getBookingsOnSelectedDates(centerId, teacherId, dates, '', true);
                
            }    
        }
        Boolean isBreak = false;
        System.debug('@@@existingBookingList.size()'+existingBookingList.size());
        System.debug('@@@bookList.size()'+bookList.size());
        if(existingBookingList.size() > 0 && bookList.size() > 0){
            for(Booking__c newBookingObj : bookList){
                for(Booking__c oldBookingObj : existingBookingList){
                    System.debug('@@@oldBookingObj'+oldBookingObj);
                    if(newBookingObj.Booking_Date__c == oldBookingObj.Booking_Date__c){
                        System.debug('Case 1 '+(oldBookingObj.Start_Time__c <= newBookingObj.Start_Time__c && oldBookingObj.End_Time__c >= newBookingObj.End_Time__c));
                        System.debug('Case 2 '+(newBookingObj.Start_Time__c <= oldBookingObj.Start_Time__c && newBookingObj.End_Time__c >= oldBookingObj.End_Time__c));
                        System.debug('Case 3 '+(newBookingObj.Start_Time__c > oldBookingObj.Start_Time__c && newBookingObj.End_Time__c > oldBookingObj.End_Time__c && newBookingObj.Start_Time__c < oldBookingObj.End_Time__c));
                        System.debug('Case 3 '+(newBookingObj.Start_Time__c < oldBookingObj.Start_Time__c && newBookingObj.End_Time__c < oldBookingObj.End_Time__c && newBookingObj.End_Time__c > oldBookingObj.Start_Time__c));
                        if((oldBookingObj.Start_Time__c <= newBookingObj.Start_Time__c && oldBookingObj.End_Time__c >= newBookingObj.End_Time__c) || (newBookingObj.Start_Time__c <= oldBookingObj.Start_Time__c && newBookingObj.End_Time__c >= oldBookingObj.End_Time__c) || (newBookingObj.Start_Time__c > oldBookingObj.Start_Time__c && newBookingObj.End_Time__c > oldBookingObj.End_Time__c && newBookingObj.Start_Time__c < oldBookingObj.End_Time__c) || (newBookingObj.Start_Time__c < oldBookingObj.Start_Time__c && newBookingObj.End_Time__c < oldBookingObj.End_Time__c && newBookingObj.End_Time__c > oldBookingObj.Start_Time__c)){
                            System.debug('In Existing case error...');
                            isBreak = true;
                            errorMsg = 'existing';
                            break;
                        }
                    }
                }
                if(isBreak == true){
                    break;
                }
            }
        }
        return errorMsg;
    }
    
    @RemoteAction
    public static Integer getCountOfBookings(Map<String, Object> mapOfBookingObject){
        DateTime bookingDateTime;
        Integer addDaysCount = 0;
        Integer countOfOccurence = 0;
        if(mapOfBookingObject.containsKey('date')){
            String bd = String.valueOf(mapOfBookingObject.get('date'));
            if(String.isNotBlank(bd)){                   
                bookingDateTime = DateTime.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]), Integer.valueOf(bd.split('T')[1].split(':')[0]), Integer.valueOf(bd.split('T')[1].split(':')[1]), 0);
                
            }
            
        }
        DateTime duplicate = bookingDateTime;
        String weekDay = duplicate.format('EEE');
        if(mapOfBookingObject.containsKey('isRecurring')){
            if(String.valueOf(mapOfBookingObject.get('isRecurring')) == 'true'){
                
                if(mapOfBookingObject.containsKey('Repeat') && String.valueOf(mapOfBookingObject.get('Repeat')) == 'Weeks'){
                    if(mapOfBookingObject.containsKey('RepeatEvery') && Integer.valueOf(mapOfBookingObject.get('RepeatEvery')) > 0){
                        addDaysCount = Integer.valueOf(mapOfBookingObject.get('RepeatEvery')) * 7;
                    }
                    
                    if(mapOfBookingObject.containsKey('EndsAfter') && Integer.valueOf(mapOfBookingObject.get('EndsAfter')) > 0){
                        countOfOccurence = Integer.valueOf(mapOfBookingObject.get('EndsAfter'));
                    }else if(mapOfBookingObject.containsKey('EndsOn') && String.isNotBlank(String.valueOf(mapOfBookingObject.get('EndsOn'))) && addDaysCount > 0){
                        String str = String.valueOf(mapOfBookingObject.get('EndsOn'));
                        countOfOccurence = 0;
                        DateTime dt ; 
                        dt = DateTime.newInstance(Integer.valueOf(str.split('/')[2]), Integer.valueOf(str.split('/')[0]), Integer.valueOf(str.split('/')[1]));
                        while(dt.date() >= duplicate.date()){
                            if(duplicate.format('EEE') == weekDay){
                                countOfOccurence++;
                            }
                            duplicate = duplicate.addDays(addDaysCount);
                        }
                    }
                }
            }
        }
        return countOfOccurence;
    }
    
    private static List<Booking__c> getBookingsOnSelectedDates(String centerId, String teacherId, Set<Date> dates, String enrolmentId, Boolean enrolBool){
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.typeTrial, ConstantsClass.typeRegular, ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc};
        Date dt, endDt;
        String regularType = ConstantsClass.typeRegular;
        String busyType = ConstantsClass.typeBusy;
        String weekDay;
        String queryStr = 'SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
        if(String.isNotBlank(centerId)){
            queryStr += ' AND Center__c =: centerId';
        }
        if(String.isNotBlank(teacherId)){
            queryStr += ' AND Teacher_Account__c =: teacherId';
        }
        System.debug('@@@dates'+dates);
        if(dates.size() > 0 && String.isBlank(enrolmentId)){
            queryStr += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND type__c IN: bookTypeSet';
            
        }else if(dates.size() > 0 && String.isNotBlank(enrolmentId)){
            bookTypeSet.add(ConstantsClass.typeBusy);
            DateTime dTime = DateTime.now();
            for(Date d : dates){
                dt = d;
                break;
            }
            if(dt != null){
                endDt = dt.addMonths(1);
                dTime = DateTime.newInstance(dt, dTime.time());
            }
            weekDay = dTime.format('EEEE');
            
            queryStr += ' AND Booking_Date__c >=: dt AND Booking_Date__c <= :endDt';
            if(String.isNotBlank(weekDay)){
                queryStr += ' AND Appointment_Day__c =: weekDay';
            }
        }
        if(String.isNotBlank(enrolmentId) && !enrolBool){
            queryStr += ' AND ((Enrolment__c !=: enrolmentId AND status__c IN: bookingStatus AND type__c IN: bookTypeSet))';
        }
        System.debug('@@@queryStr '+queryStr);
        return Database.query(queryStr);
    }
    private static void createBusyTime(Booking__c bookingObj){
        Booking__c busyBookingObj = new Booking__c();
        if(bookingObj != NULL){
            busyBookingObj.Center__c = bookingObj.Center__c;
            busyBookingObj.Type__c = ConstantsClass.typeBusy;
            busyBookingObj.start_Time__c = bookingObj.start_Time__c.addMinutes(-30);
            busyBookingObj.end_Time__c = bookingObj.start_Time__c;
            busyBookingObj.Teacher_Account__c = bookingObj.Teacher_Account__c;
            busyBookingObj.Booking_Date__c = bookingObj.Booking_Date__c;
            
            insert busyBookingObj;
        }
    }
    
    private static void deductMakeupHours(List<Booking__c> bookingObjList, String bookingParentId){
        
        String statusCanceled = ConstantsClass.statusCanceled;
        Boolean isError = false;
        String studentId;
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        Integer hoursToDeduct = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c bookObj = new Booking__c();
        Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = getParentsChild(bookingParentId);
        }
        if(bookingObjList.size() > 0){
            studentId = bookingObjList[0].Student__c;
            for(Booking__c bObj : bookingObjList){
                setOfBookings.add(bObj.Id);
            }
            if(setOfBookings.size() > 0){
                bookingList = [SELECT Id, Duration__c, Make_up_Utilize_Bookings__c FROM Booking__c WHERE Id IN:setOfBookings];
            }
            if(setOfParentStudent.size() > 0){
                List<Booking__c> cancelBookings = new List<Booking__c>([SELECT Id, Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                                                                        Student__c, Type__c, Duration__c FROM Booking__c WHERE 
                                                                        Status__c =: statusCanceled AND Student__c IN: setOfParentStudent AND 
                                                                        Make_up_Expiry_Date__c >= TODAY AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                                                                        ORDER BY Make_up_Expiry_Date__c]);
                if(cancelBookings.size() > 0){
                    for(Booking__c cancelBooking : cancelBookings){
                        mapOfHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                    }
                }
                if(bookingList.size() > 0){
                    for(Booking__c bookingObj : bookingList){
                        hoursToDeduct = Integer.valueOf(bookingObj.duration__c);
                        bookObj = new Booking__c();
                        bookObj.Id = bookingObj.Id;
                        bookObj.Make_up_Utilize_Bookings__c = '';
                        for(Booking__c canceledBookings : cancelBookings){
                            if(mapOfHours.containsKey(canceledBookings.Id) && mapOfHours.get(canceledBookings.Id) > 0 ){
                                //if(mapOfHours.get(key) > 0){
                                if(hoursToDeduct > mapOfHours.get(canceledBookings.Id)){
                                    bookObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+mapOfHours.get(canceledBookings.Id)+';';
                                    hoursToDeduct -= mapOfHours.get(canceledBookings.Id);
                                    mapOfHours.put(canceledBookings.Id, 0);
                                }else if(hoursToDeduct <= mapOfHours.get(canceledBookings.Id)){
                                    mapOfHours.put(canceledBookings.Id, mapOfHours.get(canceledBookings.Id) - hoursToDeduct);
                                    bookObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+hoursToDeduct+';';
                                    hoursToDeduct = 0;
                                }
                                //}
                                if(hoursToDeduct <= 0){
                                    break;   
                                }
                            }
                        }
                        bookingUpdatedList.add(bookObj);
                    }
                }
                for(String keysetValue : mapOfHours.keyset()){
                    if(mapOfHours.containsKey(keysetValue)){
                        bookingUpdatedList.add(new Booking__c(Id = keysetValue, Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                    }
                }
                if(bookingUpdatedList.size() > 0){
                    Database.SaveResult[] saveResults = Database.update(bookingUpdatedList, false);
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()){
                            isError = true;
                        }
                    }
                }
                String parentId;
                if(isError == false){
                    String recordTypeCustomer = ConstantsClass.recordTypeCustomer;
                    List<Account> accList = new List<Account>([SELECT Id, Name, Parent__c, RecordType.Name ,  Also_a_Student__c FROM Account WHERE RecordType.Name =: recordTypeCustomer AND Id =: studentId]);
                    if(accList.size() > 0){
                        if(String.isNotBlank(accList[0].Parent__c) && accList[0].Also_a_Student__c == false){
                            parentId = accList[0].Parent__c;
                        }else if(String.isBlank(accList[0].Parent__c) && accList[0].Also_a_Student__c == true){
                            parentId = accList[0].Id;
                        }
                    }
                }
                if(String.isNotBlank(parentId)){
                    AureusCalendarControllerHelper.cancelBookingProceed(parentId);
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
    
    @RemoteAction
    public static String getEventsRealTime(String teacherId, String resourceId, String centerId, String datesOfClicked, String instrument){
        List<AureusCalendarController.Events> listOfEvents = new List<AureusCalendarController.Events>();
        Set<String> setOfTeacher = new Set<String>();
        Set<String> setOfResources = new Set<String>();
        List<String> datesOfAppointment = new List<String>();
        if(String.isNotBlank(teacherId)){
            setOfTeacher.add(teacherId);
        }else if(String.isNotBlank(resourceId)){
            setOfResources.add(resourceId);
        }
        if(String.isNotBlank(datesOfClicked)){
            datesOfAppointment.add(datesOfClicked);
        }
        if(setOfTeacher.size() > 0 && String.isNotBlank(centerId) && datesOfAppointment.size() > 0){
            listOfEvents = AureusCalendarControllerHelper.getEventsListOfBooking(setOfTeacher, setOfResources, centerId, datesOfAppointment, /*instrument*/'');
            
        }
        return JSON.serialize(listOfEvents).replaceAll('end_c','end');
    }
    
    @RemoteAction
    public static AdhocLessonDetails  getPackageDetail(String student, String packageId, String teacherId){
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        AdhocLessonDetails adhocDetails = new AdhocLessonDetails();
        if(String.isNotBlank(packageId)){
            for(Package__c packageObj : [SELECT Id, Name, RecordType.Name, Location__r.Name, Location__c, of_Units__c, Package_Fee__c, Unit_Fee__c, Duration__c FROM Package__c WHERE RecordType.Name =: recordTypeLesson AND Id =: packageId]){
                adhocDetails.centerName = packageObj.Location__r.Name;
                adhocDetails.packageName = packageObj.Name; 
                adhocDetails.packageId = packageObj.Id;
                adhocDetails.packageFee = packageObj.Package_Fee__c;
                adhocDetails.unitFee = packageObj.Unit_Fee__c ;
                adhocDetails.units = Integer.valueOf(packageObj.of_Units__c);
                adhocDetails.duration = packageObj.Duration__c;
                break;
            }
        }
        if(String.isNotBlank(student)){
            for(Account acc : [SELECT Id, FirstName, LastName, RecordType.Name FROM Account WHERE RecordType.Name = 'Customer' AND Id =: student]){
                adhocDetails.studentId = acc.Id;
                adhocDetails.studentFirstName = acc.FirstName;
                adhocDetails.studentLastName = acc.LastName;
                break;
            }
            
        }
        if(String.isNotBlank(teacherId)){
            for(Account acc : [SELECT Id, FirstName, LastName, RecordType.Name FROM Account WHERE RecordType.Name = 'Teacher' AND Id =: teacherId]){
                adhocDetails.teacherId = acc.Id;
                adhocDetails.teacherName = acc.FirstName + ' ' +acc.LastName;
                break;
            }
        }
        return adhocDetails;
    }   
    
    @RemoteAction
    public static AdvanceDetails getAdvanceDetails(String bookingId){
        List<Booking__c> bookingList = new List<Booking__c>();
        AdvanceDetails details = new AdvanceDetails();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Enrolment__c, Enrolment__r.Lessons_Start_Date__c, Enrolment__r.Lesson_Start_time__c, Enrolment__r.Lesson_Day__c, Enrolment__r.Package__r.Name, Enrolment__r.Package__r.Is_Promotion_Discount__c, Enrolment__r.Package__r.Type_of_package__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                details.id = bookingList[0].Id;
                details.packageName = bookingList[0].Enrolment__r.Package__r.Name;
                details.packageId = bookingList[0].Enrolment__r.Package__c;
                details.isPackagePromotional = (bookingList[0].Enrolment__r.Package__r.Is_Promotion_Discount__c || bookingList[0].Enrolment__r.Package__r.Type_of_package__c == ConstantsClass.prePaymentType) ? true : false;
                if(String.isNotBlank(bookingList[0].Enrolment__c)){
                    List<Enrolment__c> enrollList = new List<Enrolment__c>([SELECT Id, Lesson_Day__c, (SELECT Id, Subscription__c, Subscription__r.Payment_Frequency__c, Subscription__r.Subscription_Start_Date__c FROM Subscription_Line_Items__r WHERE Subscription__c != NULL), Lesson_Start_time__c FROM Enrolment__c WHERE Id =: bookingList[0].Enrolment__c]);
                    if(enrollList.size() > 0){
                        
                        Time startTime = enrollList[0].Lesson_Start_time__c;
                        
                        Date startDate;
                        DateTime dt = DateTime.newInstance(System.today(), startTime);
                        details.timeSlot = 'Every '+ enrollList[0].Lesson_Day__c.toUppercase().left(3) + '@' + dt.format('h:mma');
                        DateTime timeslot;
                        if(enrollList[0].Subscription_Line_Items__r.size() > 0){
                            startDate = enrollList[0].Subscription_Line_Items__r[0].Subscription__r.Subscription_Start_Date__c;
                            timeslot = DateTime.newInstance(startDate, startTime);
                            
                            details.startDate = timeslot.format('dd-MM-yyyy');
                            details.frequency = enrollList[0].Subscription_Line_Items__r[0].Subscription__r.Payment_Frequency__c;
                        }
                    }
                }    
            }
        }
        return details;
    } 
    
    @RemoteAction
    public static GradePackageDetails getUpgradedDetails(String bookingId){
        GradePackageDetails details = new GradePackageDetails();
        details.packages = new List<GradePackage>();
        List<Package__c> packageList = new List<Package__c>();
        List<Booking__c> bookingList = new List<Booking__c>();
        GradePackage gp = new GradePackage();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Active__c, Package__r.Package_Fee__c, enrolment__c, enrolment__r.Package__r.Duration__c, enrolment__r.Lesson_Day__c, enrolment__r.Package__r.Type__c, enrolment__r.Package__r.Location__c, enrolment__r.Package__r.Program__r.Instrument__c  FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                details.lessonDay = bookingList[0].enrolment__r.Lesson_Day__c;
                packageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c
                               FROM Package__c WHERE Duration__c > :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                               Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                               Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                               Program__r.Instrument__c =: bookingList[0].enrolment__r.Package__r.Program__r.Instrument__c AND 
                               Active__c = true AND Is_Promotion_Discount__c = false AND Type_of_package__c = 'Normal' ORDER BY Duration__c];
                details.packageId = bookingList[0].package__c;
                details.packageName = bookingList[0].package__r.Name;
                if(packageList.size() > 0){
                    for(Package__c packageObj : packageList){
                        gp = new GradePackage();
                        gp.id = packageObj.Id;
                        gp.name = packageObj.Name;
                        gp.price = packageObj.Package_Fee__c;
                        details.packages.add(gp);
                    }
                }
            }
        }
        return details;
    }
    
    @RemoteAction
    public static GradePackageDetails getDowngradedDetails(String bookingId){
        GradePackageDetails details = new GradePackageDetails();
        details.packages = new List<GradePackage>();
        List<Package__c> packageList = new List<Package__c>();
        List<Booking__c> bookingList = new List<Booking__c>();
        GradePackage gp = new GradePackage();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Active__c, Package__r.Package_Fee__c, enrolment__c, enrolment__r.Package__r.Duration__c, enrolment__r.Lesson_Day__c, enrolment__r.Package__r.Type__c, enrolment__r.Package__r.Location__c, enrolment__r.Package__r.Program__r.Instrument__c  FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                details.lessonDay = bookingList[0].enrolment__r.Lesson_Day__c;
                packageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c 
                               FROM Package__c WHERE Duration__c < :bookingList[0].enrolment__r.Package__r.Duration__c 
                               AND Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                               Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                               Program__r.Instrument__c =: bookingList[0].enrolment__r.Package__r.Program__r.Instrument__c AND 
                               Active__c = true AND Is_Promotion_Discount__c = false AND Type_of_package__c = 'Normal' ORDER BY Duration__c];
                details.packageId = bookingList[0].package__c;
                details.packageName = bookingList[0].package__r.Name;
                System.debug('@@@@packageList'+packageList);
                if(packageList.size() > 0){
                    for(Package__c packageObj : packageList){
                        gp = new GradePackage();
                        gp.id = packageObj.Id;
                        gp.name = packageObj.Name;
                        gp.price = packageObj.Package_Fee__c;
                        details.packages.add(gp);
                    }
                }
            }
        }
        return details;
    }
    
    //Upgrade The Package Of Customer with Package and timeslot.
    
    @RemoteAction
    public static String updatePackageOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 Map<String, String> caseValues){
                                                     String enrolmentId;
                                                     Boolean isSuccess = false;
                                                     Date effectiveDate, nextBillingDate;
                                                     String caseIdToReturn = '';
                                                     Time newTimeSlot;
                                                     
                                                     String studentId, teacherId, lessonDay, oldPackage, newPackage;
                                                     Integer duration;
                                                     Time startTime;
                                                     
                                                     Enrolment__c enroll = new Enrolment__c();
                                                     AureusCalendarController.UpgradeCaseCreation invoiceDetails;
                                                     List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
                                                     
                                                     if(String.isNotBlank(bookingId)){
                                                         enrolmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
                                                     }
                                                     if(String.isNotBlank(effectiveDateStr)){
                                                         List<String> dtStr = effectiveDateStr.split('/');
                                                         if(dtStr.size() > 1){
                                                             effectiveDate = Date.valueOf(dtStr[2]+'-'+dtStr[0]+'-'+dtStr[1]);
                                                         }
                                                     }
                                                     if(String.isNotBlank(enrolmentId)){
                                                         enrolmentList = getNextBillingDateSubscription(enrolmentId);
                                                         if(enrolmentList.size() > 0){
                                                             nextBillingDate = getNextBillingSubscriptionLineItemDate(enrolmentList);
                                                         }
                                                     }
                                                     if(String.isNotBlank(timeSlot)){
                                                         newTimeSlot = getDateTimeFromString(timeSlot).time();  
                                                     }
                                                     if(String.isNotBlank(enrolmentId)){
                                                         enroll    = fetchEnrolment(enrolmentId); 
                                                         
                                                         studentId = enroll.Student__c;
                                                         teacherId = enroll.Teacher__c;
                                                         duration = Integer.valueOf(enroll.Package__r.duration__c);
                                                         startTime = enroll.Lesson_Start_time__c;
                                                         lessonDay = enroll.Lesson_Day__c;
                                                         oldPackage = enroll.Package__c;
                                                     }
                                                     system.debug('====+++effectiveDate'+effectiveDate +'nextBillingDate'+nextBillingDate);
                                                     if(effectiveDate <= nextBillingDate){
                                                         invoiceDetails = updatePackageRequestCallout(enrolmentId, effectiveDate, nextBillingDate , newPackageId, oldPackageId, newTimeSlot);
                                                         enroll = invoiceDetails.enrolObj;
                                                         newPackage = newPackageId;
                                                     }else{
                                                         invoiceDetails = updatePackageRequestOnGreaterEffectiveDate(enrolmentList[0], oldPackageId, newPackageId);
                                                         if(invoiceDetails.isSuccess && String.isNotBlank(enrolmentId)){
                                                             enroll.Id = enrolmentId;
                                                             enroll = initEnroll(enroll);
                                                             
                                                             newPackage = newPackageId;
                                                             enroll.New_Package_Id__c = newPackageId;
                                                             enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
                                                             enroll.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
                                                             enroll.Effective_Date__c = effectiveDate;
                                                             enroll.Package_Process_Request_Date__c = System.today();
                                                             enroll.Advance_Action_Requested_By__c = Userinfo.getUserId();
                                                             enroll.Next_Lesson_Start_time__c = getDateTimeFromString(timeSlot).time();
                                                             
                                                             if(enroll != NULL){
                                                                 Database.SaveResult saveResult = Database.Update(enroll, false);
                                                                 if(!saveResult.isSuccess()){
                                                                     isSuccess = false;
                                                                 }
                                                             }
                                                         }
                                                     }
                                                     
                                                     
                                                     AureusCalendarControllerHelper.processFutureBookings(enroll, 'upgrade'); 
                                                     //Makeup Bookings Process
                                                     Map<String, Booking__c> mapOfFifthBooking = new Map<String, Booking__c>();
                                                     
                                                     if(String.isNotBlank(studentId) && String.isNotBlank(teacherId) && duration > 0 && startTime != NULL && String.isNotBlank(lessonDay) && effectiveDate != NULL){
                                                         
                                                         for(Booking__c bookObj : AureusCalendarControllerHelper.processMakeupBooking(studentId, teacherId, Duration, startTime, effectiveDate, lessonDay)){
                                                             mapOfFifthBooking.put(bookObj.Id, bookObj);
                                                         }  
                                                     }
                                                     Integer timeDiff = 0;
                                                     if(String.isNotBlank(enroll.Id) && mapOfFifthBooking.size() > 0){
                                                         if(String.isNotBlank(oldPackage) && String.isNotBlank(newPackage)){
                                                             AureusCalendarController.UpgradeDowngradePackageSummary summary = getPackageDetailsUpgradeDowngrade(oldPackage, newPackage);
                                                             
                                                             timeDiff = Integer.valueOf(summary.newDuration) - Integer.valueOf(summary.oldDuration);   
                                                             
                                                             AureusCalendarControllerHelper.createFifthBookingOnUpgrade(enroll, mapOfFifthBooking, timeDiff, getDateTimeFromString(timeSlot).time(), Integer.valueOf(summary.oldDuration));
                                                         }
                                                         
                                                         
                                                     }
                                                     if(caseRedirect == 'true'){
                                                         Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrolmentId, 'upgrade', false);
                                                         if(String.isNotBlank(invoiceDetails.invoiceId)){
                                                             objCase.Invoice__c = invoiceDetails.invoiceId;
                                                         }
                                                         objCase.deposit_Topup__c = invoiceDetails.depositAmount;
                                                         objCase.Lesson_Charge_Topup__c = invoiceDetails.lessonCharge;
                                                         objCase.Total_Invoice_topup__c  = invoiceDetails.total;
                                                         if(caseValues.containsKey('previousPackage')){
                                                             objCase.Previous_Package__c = caseValues.get('previousPackage');    
                                                         }
                                                         if(caseValues.containsKey('newPackage')){
                                                             objCase.New_Package__c = caseValues.get('newPackage');    
                                                         }
                                                         if(caseValues.containsKey('previousLessonDayTime')){
                                                             objCase.Previous_Lesson_Day_Time__c = caseValues.get('previousLessonDayTime');    
                                                         }
                                                         if(caseValues.containsKey('newLessonDayTime')){
                                                             objCase.New_Lesson_Day_Time__c = caseValues.get('newLessonDayTime');    
                                                         }
                                                         if(caseValues.containsKey('currentDepositonFile')){
                                                             objCase.Current_Deposit_on_File__c = Decimal.valueOf(caseValues.get('currentDepositonFile'));    
                                                         }
                                                         if(caseValues.containsKey('newPackageDeposit')){
                                                             objCase.New_Package_Deposit__c = Decimal.valueOf(caseValues.get('newPackageDeposit'));    
                                                         }
                                                         if(caseValues.containsKey('invoiceForCurrentMonth')){
                                                             objCase.Invoice_for_Current_Month__c = Decimal.valueOf(caseValues.get('invoiceForCurrentMonth'));    
                                                         }
                                                         
                                                         upsert objCase;
                                                         caseIdToReturn = objCase.Id;
                                                     }
                                                     if(!invoiceDetails.isSuccess)
                                                         caseIdToReturn = 'error';
                                                     return caseIdToReturn;
                                                 }
    
    private static Invoice__c fetchInvoice(String invoiceId){
        return [SELECT Id,Name  FROM Invoice__c WHERE Id =: invoiceId LIMIT 1];
    }
    
    private static AureusCalendarController.UpgradeCaseCreation updatePackageRequestCallout(String enrolmentId, Date effectiveDate, Date nextBillDate, String newPackageId, String oldPackageId, Time newTimeSlot){
        AureusCalendarController.UpgradeCaseCreation upgradeCaseDetails = new AureusCalendarController.UpgradeCaseCreation();
        Boolean isSuccess = false;
        String invoiceId;
        if(String.isNotBlank(enrolmentId) && nextBillDate != Null && effectiveDate != Null &&
           String.isNotBlank(newPackageId) && String.isNotBlank(oldPackageId) && newTimeSlot != Null){
               upgradeCaseDetails = upgradeDowngradeController.upgradePackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot);
           }
        return upgradeCaseDetails;
    }
    
    private static AureusCalendarController.UpgradeCaseCreation updatePackageRequestOnGreaterEffectiveDate(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId){
        Boolean isSuccess = false;
        AureusCalendarController.UpgradeCaseCreation upgradePackageCaseDetails = new AureusCalendarController.UpgradeCaseCreation();
        String invoiceId = '';
        String stripeId = '', parentId = '';
        Decimal currentPackageDeposit = 0;
        Package__c newPackage, oldPackage = new Package__c();
        Set<String> invoiceIds = new Set<String>();
        AureusCalendarController.UpgradeDowngradePackageSummary summary = getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
        newPackage = summary.newPackage;
        oldPackage = summary.oldPackage; 
        
        if(String.isNotBlank(enrolmentObj.Id)){
            currentPackageDeposit = getDepositFromFile(enrolmentObj.Id);
        }
        
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Decimal depositeFee = (newPackage.Deposit_Fee__c - currentPackageDeposit); 
        if(enrolmentObj != Null){
            stripeId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c;
            parentId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
        
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
        upgradePackageCaseDetails.total = depositeFee;
        upgradePackageCaseDetails.isSuccess = true;
        
        if(String.isNotBlank(stripeId) && depositeFee > 0){
            Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, ConstantsClass.currencyCode); 
            
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                
                isSuccess = true;
                Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.paidStatus);
                insert objInvoice;
                
                if(String.isNotBlank(objInvoice.Id)){
                    upgradePackageCaseDetails.invoiceId = objInvoice.Id;
                }
                if(depositeFee > 0){
                    inlineItemforChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolmentObj.Subscription_Line_Items__r[0], depositeFee, newPackage.Id, true, '');
                    inlineItemforChange.Month__c = System.today();
                    inlineItemforChange.Is_Deposit__c = True;
                    listOfInvoiceLineItems.add(inlineItemforChange);
                }
                
                if(listOfInvoiceLineItems.size() > 0){
                    INSERT listOfInvoiceLineItems;
                } 
                
                objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                if(!Test.isRunningTest()){
                    BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name);
                }
                
                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, objInvoice.Total_Amount__c, ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = chargeResponse.Id;
                INSERT objPayment; 
                
                if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                    SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                }
                
                if(objInvoice != NULL){
                    invoiceIds.add(objInvoice.Id);
                    BillingUtility.createAttachment(invoiceIds);
                }
            }else{
                isSuccess = false;
                upgradePackageCaseDetails.isSuccess = false;
            }
        }else{
            isSuccess = false;
        }
        return upgradePackageCaseDetails;
    }
    
    public static List<Enrolment__c> getNextBillingDateSubscription(String enrollmentId){
        return [SELECT Id, Name, Parent__c, Parent__r.Name, effective_Date__c, Lesson_Day__c, New_Package_Id__r.Unit_Fee__c, 
                Package__r.Unit_Fee__c, Center__c, Teacher__c, package__r.Duration__c, new_package_Id__r.Duration__c, (SELECT Id, Subscription__c, Enrolment__c, Next_Bill_Date__c , Subscription__r.Parent__c, 
                                                                                                                       Subscription__r.Parent__r.Stripe_Customer_Id__c FROM Subscription_Line_Items__r WHERE Subscription__c != NULL) 
                FROM Enrolment__c WHERE Id =: enrollmentId];
    }
    @RemoteAction
    public static Boolean createBusyAppointments(String centerId, String teacherId, String timeSlot, Integer duration, String description, String category, integer countOfOccurence, String source){
        Boolean isError = false;
        DateTime dt, duplicate;
        Booking__c busyBooking = new Booking__c();
        String lessonRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();     
        String facilityRecordtype = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeFacility).getRecordTypeId();     
        List<Booking__c> bookingList = new List<Booking__c>();
        if(String.isNotBlank(centerId) && String.isNotBlank(teacherId) && String.isNotBlank(timeSlot) && duration > 0){
            dt = DateTime.newInstance(Integer.valueOf(timeSlot.split('T')[0].split('-')[0]), Integer.valueOf(timeSlot.split('T')[0].split('-')[1]), Integer.valueOf(timeSlot.split('T')[0].split('-')[2]), Integer.valueOf(timeSlot.split('T')[1].split(':')[0]), Integer.valueOf(timeSlot.split('T')[1].split(':')[1]), 0);
            duplicate = dt;
            for(Integer i = 1; i<=countOfOccurence; i++){
                busyBooking = new Booking__c();
                busyBooking.center__c = centerId;
                busyBooking.Remarks__c = description;
                busyBooking.Booking_Date__c = duplicate.date();
                busyBooking.Start_Time__c = dt.time();
                busyBooking.End_Time__c = dt.addMinutes(duration).time();
                busyBooking.Type__c = ConstantsClass.typeBusy;
                busyBooking.status__c = ConstantsClass.scheduledStatus;
                if(source == 'teacher'){
                    busyBooking.Category__c = category;
                    busyBooking.recordTypeId = lessonRecordType ;
                    busyBooking.Teacher_Account__c = teacherId;
                }else if(source == 'resource'){
                    busyBooking.Resource_Category__c = category;
                    busyBooking.recordTypeId = facilityRecordtype ;
                    busyBooking.Resource__c = teacherId;
                }
                
                bookingList.add(busyBooking);
                duplicate = duplicate.addDays(7);
            }
            if(bookingList.size() > 0){
                
                Database.SaveResult[] saveResults = Database.insert(bookingList, false);
                for(Database.SaveResult sr : saveResults){
                    if(!sr.isSuccess()){
                        isError = true;
                    }
                }
                
            }
            
        }
        return isError;
    }
    
    /*
getBusyBookingDetails method takes the argument of busy bookingId 
and returns the details of busy booking to show on the popup.

*/
    
    @RemoteAction
    public static BusyAppointment getBusyBookingDetails(String bookingId){
        String lessonRecordtype = ConstantsClass.recordTypeLesson; 
        String facilityRecordType = ConstantsClass.recordTypeFacility;
        List<Booking__c> bookingList = new List<Booking__c>();
        BusyAppointment busy = new BusyAppointment();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Center__r.Name,Center__c,Teacher_Account__c, Teacher_Account__r.Name, Booking_Date__c,Start_Time__c, End_Time__c, Category__c, Remarks__c, Duration__c, RecordType.Name, Resource__c, Resource__r.Name, Resource_Category__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                Booking__c objBooking = bookingList[0];
                DateTime start, endT;
                start = DateTime.newInstance(objBooking.Booking_Date__c, objBooking.Start_Time__c);
                endT = DateTime.newInstance(objBooking.Booking_Date__c, objBooking.End_Time__c);
                busy.bookingId = objBooking.Id;
                busy.duration = String.valueOf((((endT.getTime() - start.getTime()) / 1000) / 60));
                busy.timeOfBooking = DateTime.newInstance(objBooking.Booking_Date__c, objBooking.Start_Time__c).format('YYYY-MM-dd hh:mma');
                if(objBooking.RecordType.Name == lessonRecordtype){
                    busy.teacher = objBooking.Teacher_Account__r.Name;
                    busy.category = objBooking.Category__c;
                    busy.teacherId = objBooking.Teacher_Account__c;
                    busy.origin = 'teacher';
                }else if(objBooking.RecordType.Name == facilityRecordType){
                    busy.teacher = objBooking.Resource__r.Name;
                    busy.category = objBooking.Resource_Category__c;
                    busy.teacherId = objBooking.Resource__c;
                    busy.origin = 'resource';
                }
                busy.center = objBooking.Center__r.Name;
                busy.discription = objBooking.Remarks__c;
                busy.centerId = objBooking.Center__c;
            }
        }
        return busy;
    }
    
    /*
getNoticePeriod method takes the argument of bookingId and effective Date
Selected by the user from the calendar UI.

*/
    @RemoteAction
    public static Map<String, String> getNoticePeriod(String bookingId, String effectiveDateStr){
        Map<String, String> mapOfNoticePeriod = new Map<String, String>();
        String lessonRecordType = ConstantsClass.recordTypeLesson;
        List<Booking__c> bookingList = new List<Booking__c>();
        String enrollmentID;
        Date effectiveDate;
        if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr)){
            List<String> dtStr = effectiveDateStr.split('/');
            if(dtStr.size() > 1){
                effectiveDate = Date.valueOf(dtStr[2]+'-'+dtStr[0]+'-'+dtStr[1]);
            }
            enrollmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
            if(String.isNotBlank(enrollmentId)){
                bookingList = [SELECT Id, enrolment__c, Booking_Date__c, Type__c, Status__c, RecordType.Name FROM Booking__c WHERE RecordType.Name =: lessonRecordType AND enrolment__c =: enrollmentId AND Booking_Date__c >= :effectiveDate AND Type__c != 'Make-up' AND (Status__c = 'Scheduled' OR Status__c = 'Pending') ORDER BY Booking_Date__c LIMIT 5];
                if(bookingList.size() > 0 && bookingList.size() == 5){
                    mapOfNoticePeriod.put('startDate', String.valueOf(effectiveDate.addDays(1)));
                    mapOfNoticePeriod.put('endDate', String.valueOf(bookingList[3].Booking_Date__c));
                    mapOfNoticePeriod.put('effectiveDate', String.valueOf(bookingList[4].Booking_Date__c));
                }else{
                    mapOfNoticePeriod.put('error', 'You can\'t select this effictive date....');
                }
            }
        }
        return mapOfNoticePeriod;
    }
    
    @RemoteAction
    public static String downgradeSubscriptionRequest(String bookingId, String effectiveDateStr, String newPackageId, 
                                                      String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                      String amount, String depositAmount, String lessonsFees, Map<String, String> caseValues){
                                                          
                                                          System.debug('@@@@caseValues '+caseValues);
                                                          
                                                          Boolean isSuccess = true;
                                                          String enrollmentId, caseIdToReturn;
                                                          Date effectiveDate, nextBillingDate;
                                                          
                                                          Enrolment__c enroll = new Enrolment__c();
                                                          
                                                          if(String.isNotBlank(effectiveDateStr)){
                                                              List<String> dtStr = effectiveDateStr.split('/');
                                                              if(dtStr.size() > 1){
                                                                  effectiveDate = Date.valueOf(dtStr[2]+'-'+dtStr[0]+'-'+dtStr[1]);
                                                                  
                                                              }
                                                          }
                                                          
                                                          String studentId, teacherId, lessonDay, oldPackage, newPackage, centreId;
                                                          Integer duration, newPackageDuration; 
                                                          Time startTime, newStartTime;
                                                          
                                                          if(String.isNotBlank(bookingId)){
                                                              enrollmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
                                                          }
                                                          
                                                          Integer timeDiff = 0;                                                  
                                                          UpDownSummary objSummary = new UpDownSummary();
                                                          for(Package__c objPack : [SELECT Id,Name, Duration__c FROM Package__c WHERE Id=:oldPackageId OR Id =: newPackageId]){
                                                              if(objPack.Id == oldPackageId){
                                                                  objSummary.oldPack = objPack;
                                                              }else if(objPack.Id == newPackageId){
                                                                  objSummary.newPack = objPack;
                                                              }
                                                          }                                                 
                                                          if(String.isNotBlank(objSummary.oldPack.Id) && String.isNotBlank(objSummary.newPack.Id)){
                                                              timeDiff =   Integer.valueOf(objSummary.oldPack.Duration__c) - Integer.valueOf(objSummary.newPack.Duration__c);                                                
                                                          }
                                                          
                                                          
                                                          
                                                          if(String.isNotBlank(enrollmentId)){
                                                              enroll = fetchEnrolment(enrollmentId);
                                                              newPackage = newPackageId;
                                                              studentId = enroll.Student__c;
                                                              teacherId = enroll.Teacher__c;
                                                              duration = Integer.valueOf(enroll.Package__r.duration__c);
                                                              startTime = enroll.Lesson_Start_time__c;
                                                              lessonDay = enroll.Lesson_Day__c;
                                                              oldPackage = enroll.Package__c;
                                                              centreId = enroll.center__c;
                                                          }
                                                          
                                                          Decimal positiveAmt  = caseValues.containsKey('positiveInvoiceAmount') ? Decimal.valueOf(caseValues.get('positiveInvoiceAmount')) : 0;
                                                          Decimal negativeAmt =  caseValues.containsKey('negativeInvoiceAmount') ? Decimal.valueOf(caseValues.get('negativeInvoiceAmount')) : 0;
                                                          isSuccess = createPaymentsForDowngradeProcess(enroll, effectiveDate, enroll.Subscription_Line_Items__r[0].Next_Bill_Date__c, Decimal.valueOf(depositamount), Decimal.valueOf(lessonsFees), positiveAmt,negativeAmt, oldPackageId,newPackageId);
                                                          
                                                          if(isSuccess){
                                                              if(String.isNotBlank(enrollmentId)){
                                                                  enroll.Id = enrollmentId;
                                                                  enroll = initEnroll(enroll);
                                                                  enroll.New_Package_Id__c = newPackageId;
                                                                  
                                                                  
                                                                  enroll.Package_Process_Type__c = ConstantsClass.enrollmentProcessDowngradeType;
                                                                  if(effectiveDate != NULL){
                                                                       enroll.Effective_Date__c = effectiveDate;
                                                                  }
                                                                  
                                                                  if(enroll.Effective_Date__c != NULL){
                                                                      enroll.Notice_Period_End_Date__c = enroll.Effective_Date__c;
                                                                      enroll.Notice_Period_Start_Date__c = enroll.Notice_Period_End_Date__c.addDays(-30);
                                                                  }
                                                                  
                                                                  if(enroll.Effective_Date__c >= enroll.Subscription_Line_Items__r[0].Next_Bill_Date__c){
                                                                      enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;       
                                                                  }else{
                                                                      enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;      
                                                                      enroll.Package__c = newPackageId;
                                                                  }
                                                                  enroll.Next_Lesson_Start_time__c = getDateTimeFromString(timeSlot).time();
                                                                  enroll.Advance_Action_Requested_By__c = Userinfo.getUserId();
                                                                  enroll.Package_Process_Request_Date__c = System.today();
                                                              }
                                                              
                                                              if(enroll != NULL){
                                                                  Database.SaveResult saveResult = Database.Update(enroll, false);
                                                                  if(!saveResult.isSuccess()){
                                                                      isSuccess = false;
                                                                  }else{
                                                                      List<Enrolment__c> enrolmentList = getNextBillingDateSubscription(enroll.id);
                                                                      if(enrolmentList.size() > 0){
                                                                          enroll = enrolmentList[0];
                                                                      }
                                                                      AureusCalendarControllerHelper.processFutureBookings(enroll, 'downgrade');
                                                                      
                                                                      if(String.isNotBlank(studentId) && String.isNotBlank(teacherId) && duration > 0 && 
                                                                         startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay) && 
                                                                         getDateTimeFromString(timeSlot).time() != NULL && String.isNotBlank(objSummary.newPack.Duration__c) && String.isNotBlank(centreId)){
                                                                             AureusCalendarControllerHelper.AddFifthMakeupMinutesToParent(studentId, teacherId, duration, startTime, effectiveDate, lessonDay, timediff, getDateTimeFromString(timeSlot).time(), Integer.valueOf(objSummary.newPack.Duration__c), centreId);
                                                                         }
                                                                      
                                                                  }
                                                              }                                                             
                                                          }
                                                          
                                                          if(isSuccess && caseRedirect == 'true'){
                                                              Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrollmentId, 'downgrade', false);
                                                              if(String.isNotBlank(amount)){
                                                                  objCase.Total_Invoice_topup__c = Decimal.valueOf(amount);
                                                                  ObjCase.Lesson_Charge_Topup__c = math.abs(Decimal.valueOf(lessonsFees));
                                                                  ObjCase.deposit_Topup__c = Decimal.valueOf(depositAmount);
                                                                  if(caseValues.containsKey('previousPackage')){
                                                                      objCase.Previous_Package__c = caseValues.get('previousPackage');    
                                                                  }
                                                                  if(caseValues.containsKey('newPackage')){
                                                                      objCase.New_Package__c = caseValues.get('newPackage');    
                                                                  }
                                                                  if(caseValues.containsKey('previousLessonDayTime')){
                                                                      objCase.Previous_Lesson_Day_Time__c = caseValues.get('previousLessonDayTime');    
                                                                  }
                                                                  if(caseValues.containsKey('newLessonDayTime')){
                                                                      objCase.New_Lesson_Day_Time__c = caseValues.get('newLessonDayTime');    
                                                                  }
                                                                  if(caseValues.containsKey('currentDepositonFile')){
                                                                      objCase.Current_Deposit_on_File__c = Decimal.valueOf(caseValues.get('currentDepositonFile'));    
                                                                  }
                                                                  if(caseValues.containsKey('newPackageDeposit')){
                                                                      objCase.New_Package_Deposit__c = Decimal.valueOf(caseValues.get('newPackageDeposit'));    
                                                                  }
                                                                  if(caseValues.containsKey('invoiceForCurrentMonth')){
                                                                      objCase.Invoice_for_Current_Month__c = Decimal.valueOf(caseValues.get('invoiceForCurrentMonth'));    
                                                                  }
                                                              }
                                                              upsert objCase; 
                                                              caseIdToReturn = objCase.Id;
                                                          }else if(!isSuccess){
                                                              caseIdToReturn = 'error';
                                                          }else{
                                                              caseIdToReturn = '';
                                                          }
                                                          
                                                          return caseIdToReturn ;
                                                      }
    
    
    
    
    @RemoteAction
    public static Map<String, String> getNoticePeriodByEndDate(String bookingId, String LessonLastDate){
        Map<String, String> mapOfNoticePeriod = new Map<String, String>();
        String lessonRecordType = ConstantsClass.recordTypeLesson;
        List<Booking__c> bookingList = new List<Booking__c>();
        String enrollmentID;
        Date effectiveDate;
        if(String.isNotBlank(bookingId) && String.isNotBlank(LessonLastDate)){
            List<String> dtStr = LessonLastDate.split('/');
            if(dtStr.size() > 1){
                effectiveDate = Date.valueOf(dtStr[2]+'-'+dtStr[0]+'-'+dtStr[1]);
            }
            enrollmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
            if(String.isNotBlank(enrollmentId)){
                bookingList = [SELECT Id, enrolment__c, Booking_Date__c, Type__c, Status__c, RecordType.Name FROM Booking__c WHERE RecordType.Name =: lessonRecordType AND enrolment__c =: enrollmentId AND Booking_Date__c <= :effectiveDate AND Type__c != 'Make-up' AND (Status__c = 'Scheduled' OR Status__c = 'Pending') ORDER BY Booking_Date__c DESC LIMIT 4];
                if(bookingList.size() > 0 && bookingList.size() == 4){
                    mapOfNoticePeriod.put('requestDate', String.valueOf(bookingList[3].Booking_Date__c.addDays(-1)));
                    mapOfNoticePeriod.put('startDate', String.valueOf(bookingList[3].Booking_Date__c));
                    mapOfNoticePeriod.put('endDate', String.valueOf(bookingList[0].Booking_Date__c));
                    mapOfNoticePeriod.put('effectiveDate', String.valueOf(bookingList[0].Booking_Date__c));
                }else{
                    mapOfNoticePeriod.put('error', 'You can\'t select this effictive date....');
                }
            }
        }
        return mapOfNoticePeriod;
    }
    
    @RemoteAction
    public static String cancelSubscriptionRequest(String bookingId, String endDate, String lastLessonDate, String myCase, String redirectCase){
        Enrolment__c enrolObj = new Enrolment__c();
        String enrollmentId, caseIdToReturn;
        Enrolment__c enroll = new Enrolment__c();
        Boolean isSuccess = true;
        Date endDateObj, lastLessonDateObj, nextBillDate;
        String statusCanceled = ConstantsClass.statusCanceled;
        String typeRegular = ConstantsClass.typeRegular;
        if(String.isNotBlank(endDate)){
            endDateObj = Date.valueOf(endDate);
        }
        
        if(String.isNotBlank(lastLessonDate)){
            lastLessonDateObj = Date.valueOf(lastLessonDate);
        }
        
        if(String.isNotBlank(bookingId)){
            enrolObj  = getEnrolDetails(bookingId);
            enrollmentId = enrolObj.Id;
        }
        
        if(String.isNotBlank(enrollmentId)){
            nextBillDate = getNextBillingDate(enrollmentId); 
        }
        
        if(String.isNotBlank(enrollmentId) && endDateObj != NULL && lastLessonDateObj  != NULL){
            enroll.Id = enrollmentId;
            enroll = initEnroll(enroll);
            enroll.Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
            enroll.Effective_Date__c = lastLessonDateObj;
            enroll.Package_Process_Request_Date__c = System.today();
            enroll.Notice_Period_Start_Date__c = endDateObj.addDays(-30);
            enroll.Notice_Period_End_Date__c = endDateObj;
            enroll.Advance_Action_Requested_By__c = Userinfo.getUserId();
            if(lastLessonDateObj >= nextBillDate){
                enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
            }else{
                enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
                enroll.Stage__c = 'Cancelled';
            }
            
        }
        
        if(enroll != NULL){
            Database.SaveResult saveResult = Database.Update(enroll, false);
            if(saveResult.isSuccess()){
                isSuccess = true;
                //  DELETE [SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND Enrolment__c =: enroll.Id AND Status__c != : statusCanceled AND Type__c =: typeRegular];
            }
        }
        
        if(isSuccess && String.isNotBlank(enrollmentId)){
            createPaymentRecordForWithdrawalProcess(enrolObj, lastLessonDateObj,nextBillDate);
            DELETE [SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND 
                    Enrolment__c =: enroll.Id AND Status__c != : statusCanceled AND Type__c =: typeRegular];
            
            if(String.isNotBlank(enrolObj.Parent__c)){
                markMakeupExpiryDateAsLastLessonDate(enrolObj.Parent__c);
            }
            
        }
        if(!isSuccess){
            caseIdToReturn = 'error';
        }
        if(isSuccess && redirectCase == 'true'){
            Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCase, enroll.Id, 'withdrawal', true);
            caseIdToReturn = objCase.Id;
        }else if(isSuccess){
            caseIdToReturn = '';
        }else{
            caseIdToReturn = 'error';
        }
        return caseIdToReturn;
    }
    
    //check that the Parent Has other Enrolment or Not
    private static Boolean checkParentHasMultipleEnrolments(String parentId){
        Boolean flag = false;
        List<Enrolment__c> enrolList = [SELECT Id FROM Enrolment__c WHERE Parent__c =: parentId AND Stage__c = :ConstantsClass.enroledStatus AND Type__c = :ConstantsClass.enrolRegularStatus];
        if(enrolList.size() > 0 ){
            flag = true;
        }
        return flag;
    }
    
    private static Boolean createPaymentsForDowngradeProcess(Enrolment__c objEnrol, Date lastLessonDateObj, Date nextBillDate, Decimal depositAmount, Decimal lessonsAmt, Decimal positiveInvoiceAmount, Decimal negativeInvoiceAmount, String oldPackId,String newPackId){
        System.debug('@@@depositAmount'+depositAmount);
        Boolean isTransaction = false;
        Subscription_Line_Item__c objSubLineItem;
        String stripeId;
        Invoice__c objInvoice = new Invoice__c();
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        List<Payment__c> listOfPayments = new List<Payment__c>(); 
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String paymentTransaction = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        
        if(depositAmount > 0 && objEnrol.Subscription_Line_Items__r.size() > 0){
            
            objSubLineItem = objEnrol.Subscription_Line_Items__r[0];
            stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c; 
            if(String.isNotBlank(stripeId)){
                BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositAmount, ConstantsClass.currencyCode);                 
                if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                    isTransaction = true;
                    
                    //Insert Invoice if effective date is less than next bill date and deposit amount is positive
                    objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c, objSubLineItem.Subscription__r.Parent__c, constantsClass.paidStatus);
                    objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
                    insert objInvoice;
                    
                    //add deposit invoice line item for the invoice
                    Invoice_Line_Item__c inlineItemForDeposit = new Invoice_Line_Item__c();
                    inlineItemForDeposit = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, objSubLineItem, depositAmount, newPackId, true, '');
                    inlineItemForDeposit.Is_Deposit__c = True;
                    inlineItemForDeposit.month__c = System.today();
                    
                    invoiceLineItems.add(inlineItemForDeposit);
                    
                    if(String.isNotBlank(objInvoice.Id)){
                        objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                        
                        BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name);
                        
                        Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c, objInvoice.Id, depositAmount, ConstantsClass.successStatus);
                        objPayment.Transaction_ID__c = chargeResponse.Id;
                        objPayment.recordTypeId = paymentTransaction;
                        listOfPayments.add(objPayment);
                    }
                }
            }
        }else if(depositAmount <= 0){
            isTransaction = true;
            
            //Invoice If the deposit amount is less than 0.
            objInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                        Invoice_Date__c =system.today(), Parent_Account__c = objEnrol.Parent__c, Center__c=objEnrol.Center__c);
            INSERT objInvoice;
            
            if(depositAmount != 0){
                listOfPayments.add(new Payment__c(Payment_Date__c = lastLessonDateObj, RecordTypeId = paymentRecordTypeId, 
                                                  Payment_Amount__c = Math.abs(depositAmount), Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                                  Parent_Account__c = objEnrol.Parent__c));    
            }
            
        }   
        
        if(lastLessonDateObj < nextBillDate){
            
            if(positiveInvoiceAmount != NULL && negativeInvoiceAmount != NULL && String.isNotBlank(objInvoice.Id)){
                
                //Line Item for positive amount
                
                invoiceLineItems.add(new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = positiveInvoiceAmount, 
                                                              Teacher_Id__c = objEnrol.Teacher__c,Package__c=newPackId,Month__c= System.today(), Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
                
                //Line Item for negative amount.
                
                invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,Amount__c = negativeInvoiceAmount, 
                                                              Teacher_Id__c = objEnrol.Teacher__c,Package__c=oldPackId,Month__c= System.today(), Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
                
                listOfPayments.add(new Payment__c(RecordTypeId = payAsCredit, Payment_Amount__c = lessonsAmt, Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                              Parent_Account__c = objEnrol.Parent__c, Payment_Date__c = lastLessonDateObj));
            }
            
            
        }
        
        if(invoiceLineItems.size() > 0){
            insert invoiceLineItems;
        }
        
        if(String.isNotBlank(objInvoice.id) && isTransaction){
            SageIntacctIntegrationUtility.changeEnrolment(objInvoice.Id);
            BillingUtility.createAttachment(new Set<String> {objInvoice.id});
        }  
        
        if(listOfPayments.size() > 0){
            insert listOfPayments;
        }
      
        
        return isTransaction;
        
    }
    //To Create Payment Record After the Enrolment Withdrawal Request
    private static void createPaymentRecordForWithdrawalProcess(Enrolment__c objEnrol, Date lastLessonDateObj,Date nextBillDate){
        Boolean isRefund = nextBillDate > lastLessonDateObj;
        
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        
        
        Boolean hasMoreEnrolment = checkParentHasMultipleEnrolments(objEnrol.parent__c);
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment__c> refundPayments = new List<Payment__c>();
        
        Payment__c paymentObj  = new Payment__c();
        Map<String, Invoice_Line_Item__c> mapOfInvoiceLineItems = new Map<String, Invoice_Line_Item__c>();
        Map<String, Payment__c> mapOfInvoicePayments = new Map<String, Payment__c>();
        
        for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c 
                                             FROM Invoice_Line_Item__c WHERE Enrolment__c =: objEnrol.id AND Is_Deposit__c = true]){
                                                 mapOfInvoiceLineItems.put(lineItem.Invoice__c, lineItem);
                                             }
        
        if(mapOfInvoiceLineItems.keySet().size() > 0){
            for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c  FROM Payment__c WHERE Invoice__c IN: mapOfInvoiceLineItems.keySet() AND 
                                      RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                          mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                      }
        }
        
        if(mapOfInvoiceLineItems.size() > 0 && mapOfInvoicePayments.size() > 0){
            for(String invoiceId : mapOfInvoiceLineItems.keySet()){
                paymentObj  = new Payment__c();
                if(isRefund){
                    //paymentObj.RecordTypeId =  refundRecType;
                    //paymentObj.Payment_Date__c = lastLessonDateObj;
                    paymentObj.Payment_Date__c = System.today();
                }else{
                    //paymentObj.RecordTypeId =  paymentRecordTypeId;
                    paymentObj.Payment_Date__c = mapOfInvoiceLineItems.get(invoiceId).Subscription_Line_Item__r.Next_Bill_Date__c;
                }
                paymentObj.RecordTypeId =  paymentRecordTypeId;
                if(hasMoreEnrolment){
                    paymentObj.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                }else{
                    paymentObj.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                    
                }
                
                paymentObj.Payment_Amount__c = Integer.valueOf(mapOfInvoiceLineItems.get(invoiceId).Amount__c);
                paymentObj.Parent_Account__c = mapOfInvoiceLineItems.get(invoiceId).Invoice__r.Parent_Account__c;
                paymentObj.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;
                paymentObj.last_lesson_date__c = lastLessonDateObj;
                paymentList.add(paymentObj);
            }
            
        }
        // we need to refund current month amount if applicable
        if(isRefund){
            String chargeId =  fetchCurrentMonthPaymentEntry(objEnrol,lastLessonDateObj);
            if(String.isNotBlank(chargeId)){
                Decimal refundAmount = getLessonRefundAmount(objEnrol,lastLessonDateObj);
                if(refundAmount > 0){
                    Payment__c objPay = new Payment__c();
                    objPay.RecordTypeId =  payAsCredit ;
                    objPay.Payment_Date__c = lastLessonDateObj;
                    if(hasMoreEnrolment){
                        objPay.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                    }else{
                        objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                    }
                    objPay.Payment_Amount__c = refundAmount;
                    objPay.Parent_Account__c = objEnrol.Parent__c;
                    objPay.Transaction_ID__c = chargeId;
                    objPay.last_lesson_date__c = lastLessonDateObj;
                    paymentList.add(objPay);
                }
            }                                                           
        }
        if(!hasMoreEnrolment){
            for(Payment__c objPay : paymentList){
                Payment__c refund = objPay.clone(false,false,false,false);
                refund.Payment_amount__c = -1*refund.Payment_amount__c;
                refund.recordTypeId = refundRecType;
                refund.Payment_Date__c = lastLessonDateObj;
                refund.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                refundPayments.add(refund);
            }    
        }
        
        if(refundPayments.size() > 0){
            paymentList.addAll(refundPayments);
        }
        
        if(paymentList.size() > 0){
            insert paymentList;
        }
    }
    
    
    // get current month invoice payment entry
    public static String fetchCurrentMonthPaymentEntry(Enrolment__c objEnrol,Date lastLessonDateObj){
        Date firstDate = Date.newInstance(lastLessonDateObj.Year(),lastLessonDateObj.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
        String chargeId ='';
        List<Invoice__c> listOfInvoice =[SELECT Id,Stripe_Charge_Id__c FROM Invoice__c WHERE 
                                         Id IN (SELECT Invoice__c FROM Invoice_Line_Item__c WHERE Enrolment__c=: objEnrol.id AND
                                                Createddate >=: firstDate AND createddate <=: lastDate AND Booking__c = NULL)
                                         AND Invoice_Date__c >=: firstDate AND Invoice_Date__c <=: lastDate AND Status__c = 'Paid' 
                                         Order By total_amount__c ];
        if(listOfInvoice.size()>0){
            chargeId = listOfInvoice[0].Stripe_charge_id__c;
        }
        return chargeId;                                  
    }
    private static Enrolment__c getEnrolFromBooking(String bookingId){
        Enrolment__c enrolObj = new Enrolment__c();
        List<Booking__c> bookingList = [SELECT Id, Enrolment__c, Enrolment__r.Parent__c FROM Booking__c WHERE Id =: bookingId];
        if(bookingList.size() > 0){
            enrolObj = new Enrolment__c();
            enrolObj.Id =  bookingList[0].Enrolment__c;
            enrolObj.Parent__c = bookingList[0].Enrolment__r.Parent__c;
        }
        return enrolObj;
    }
    
    //Set Expiry date to last lesson date if their is no active enrolment of parent
    private static void markMakeupExpiryDateAsLastLessonDate(String parentId){
        List<Enrolment__c> enrolListForMaxDate = new List<Enrolment__c>();
        Boolean needToMakeupChange = false;
        String cancelStatus = ConstantsClass.enrollmentStageCancelled;
        List<Enrolment__c> enrolList = [SELECT Id, Package_Process_Type__c, Package_Process_Status__c, Effective_Date__c  FROM Enrolment__c WHERE Parent__c =: parentId AND Stage__c = :ConstantsClass.enroledStatus AND Type__c = :ConstantsClass.enrolRegularStatus];
        
        if(enrolList.size() == 1){
            needToMakeupChange = true;
            enrolListForMaxDate.add(enrolList[0]);
        }else if(enrolList.size() > 1){
            Integer count = 0;
            for(Enrolment__c enrolObj : enrolList){
                enrolListForMaxDate.add(enrolObj);
                if(enrolObj.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType && 
                   enrolObj.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus){
                       count += 1;   
                   }
            }
            if(count == 1){
                needToMakeupChange = true;
            }
        }
        
        if(needToMakeupChange && String.isNotBlank(parentId)){
            Date maxDate = findMaxDate(enrolListForMaxDate);
            if(String.isNotBlank(parentId) && maxDate != NULL){
                updateAllBookingForParent(parentId, maxDate);
            }
        }
        
    }
    
    private static Date findMaxDate(List<Enrolment__c> enrolList){
        List<Date> dateList = new List<Date>();
        for(Enrolment__c enrolObj : enrolList){
            dateList.add(enrolObj.Effective_Date__c);
        }
        dateList.sort();
        return dateList[dateList.size() - 1];
    }  
    
    private static void updateAllBookingForParent(String parentId, Date maxDate){
        List<Booking__c> bookingList = new List<Booking__c>();
        for(Booking__c bookingObj : [SELECT Id, Make_up_Expiry_Date__c FROM Booking__c
                                     WHERE RecordType.Name =: ConstantsClass.recordTypeLesson AND Parent__c =: parentId AND 
                                     Make_up_Expiry_Date__c >= :System.today() AND Available_Make_up_Units__c > 0 AND 
                                     Type__c =: ConstantsClass.bookTypeRegular AND Status__c =: ConstantsClass.statusCanceled]){
                                         
                                         bookingObj.Make_up_Expiry_Date__c = maxDate;
                                         bookingList.add(bookingObj);                                           
                                         
                                     }
        if(bookingList.size() > 0){
            update bookingList;
        }
        
    }  
    
    
    private static Enrolment__c initEnroll(Enrolment__c enroll){
        enroll.Package_Process_Type__c = '';
        enroll.Package_Process_Request_Date__c = Null;
        enroll.Notice_Period_Start_Date__c = Null;
        enroll.Reason_of_Withdraw__c  = ''; 
        enroll.Feedback_Comments__c = '';
        enroll.New_Package_Id__c = Null;
        enroll.Package_Process_Status__c = '';  
        enroll.Notice_Period_End_Date__c = Null;
        enroll.Refund_Method__c = '';
        
        return enroll;
    }
    
    @RemoteAction
    public static Case getCaseDetails(String caseId){
        List<Case> caseList = new List<Case>();
        Case currentCase = new Case();
        if(String.isNotBlank(caseId)){
            caseList = [SELECT Id, CaseNumber, ContactId, Contact.Name, Type FROM Case WHERE Id =: caseId];
            if(caseList.size() > 0){
                currentCase = caseList[0];
            }
        }
        return currentCase;
    }
    
    @RemoteAction
    public static Centre_Users__c getCenterUsers(){
        Centre_Users__c currentCenterUser = new Centre_Users__c();
        List<Centre_Users__c> centerUsers = [SELECT Centre_Name__c, Designation__c FROM Centre_Users__c WHERE User_Name__c =: UserInfo.getUserId() LIMIT 1];
        if(centerUsers.size() > 0){
            currentCenterUser = centerUsers[0];
        }
        return currentCenterUser;
    }
    
    @RemoteAction 
    public static Integer getCancellationDetails(String bookingId,String lastLessonDate){
        Integer total = 0;
        Booking__c objBooking = getBookingEnrolData(bookingId);
        Date lessonDate = Date.valueOf(lastLessonDate);
        Date firstDate = Date.newInstance(lessonDate.year(), lessonDate.month(), 01);
        Integer daysInMonth = Date.daysInMonth(lessonDate.year(), lessonDate.month());
        Date lastDate = Date.newInstance(lessonDate.year(), lessonDate.month(), daysInMonth);
        Map<String,List<Date>> mapOfDates = BillingUtility.getDateMap(firstDate,lastDate);
        List<Date> listOfDates = mapOfDates.get(objBooking.Enrolment__r.Lesson_Day__c);
        if(listOfDates.size() == 5){
            listOfDates.remove(4);
        }
        for(Date objDate : listOfDates){
            if(lessonDate >= objDate){
                total+=1;    
            }
        }
        return total; 
    }
    @RemoteAction
    public static UpDownSummary getUpgradeDowngradeSummary(String bookingId,String oldPackId,String newPackId,String effectDate){
        UpDownSummary objSummary = new UpDownSummary();
        objSummary.noOfBookingWithNewPack = 0;
        objSummary.noOfBookingWithOldPack = 0;
        
        for(Package__c objPack : [SELECT Id,Name FROM Package__c WHERE Id=:oldPackId OR Id =: newPackId]){
            if(objPack.Id == oldPackId){
                objSummary.oldPack = objPack;
            }else if(objPack.Id == newPackId){
                objSummary.newPack = objPack;
            }
        }
        
        Booking__c objBooking = getBookingEnrolData(bookingId);
        Date lessonDate ;
        if(String.isNotBlank(effectDate)){
            if(effectDate.contains('/')){
                List<String> dtStr =  effectDate.split('/');
                if(dtStr.size() > 1){
                    lessonDate = Date.valueOf(dtStr[2]+'-'+dtStr[0]+'-'+dtStr[1]);
                }
            }else{
                lessondate = Date.valueOf(effectDate);
            }
        }
        
        Date firstDate = Date.newInstance(lessonDate.year(), lessonDate.month(), 01);
        Integer daysInMonth = Date.daysInMonth(lessonDate.year(), lessonDate.month());
        Date lastDate = Date.newInstance(lessonDate.year(), lessonDate.month(), daysInMonth);
        Map<String,List<Date>> mapOfDates = BillingUtility.getDateMap(firstDate,lastDate);
        List<Date> listOfDates = mapOfDates.get(objBooking.Enrolment__r.Lesson_Day__c);
        if(listOfDates.size() == 5){
            listOfDates.remove(4);
        }
        for(Date objDate : listOfDates){
            if(objDate < lessonDate ){
                objSummary.noOfBookingWithOldPack +=1;
            }else if(objDate >= lessonDate){
                objSummary.noOfBookingWithNewPack +=1;
            }       
        }
        return objSummary;
    }
    
    private static Booking__c getBookingEnrolData(String bookingId){
        return [SELECT Id,Enrolment__r.Lesson_Day__c FROM Booking__c WHERE Id=: bookingId];
    }
    
    @RemoteAction       
    public static EnrolmentProcessCenterData getEnrolmentProcessData(String bookingId){     
        EnrolmentProcessCenterData processData = new EnrolmentProcessCenterData();      
        List<Booking__c> bookingList = new List<Booking__c>();      
        Data currentC = new Data();     
        
        if(String.isNotBlank(bookingId)){       
            
            bookingList = getBookingListById(bookingId);        
            
            if(bookingList.size() > 0){     
                processData.currentCenter = new Data();     
                processData.currentCenter.Id = bookingList[0].Center__c;        
                processData.currentCenter.Name = bookingList[0].Center__r.Name;     
                
            }       
            processData.centersList = new List<Data>();     
            
            for(Account acc : getAllCenters()){     
                currentC = new Data();      
                currentC.Id = acc.Id;       
                currentC.Name = acc.Name;       
                processData.centersList.add(currentC);      
            }       
        }       
        return processData;     
    }       
    
    @RemoteAction       
    public static EnrolmentProcessTeacherData getAllTeachersAccordingToCenter(String bookingId, String centerId){       
        EnrolmentProcessTeacherData processData = new EnrolmentProcessTeacherData();        
        Map<String, String> mapOfteacher = new Map<String, String>();       
        AureusCalendarController.TeacherWorkingHours teachersHours = new AureusCalendarController.TeacherWorkingHours();      
        Data currentC = new Data();     
        processData.currentTeacher =  new Data();       
        List<Booking__c> bookingList = new List<Booking__c>();      
        
        
        if(String.isNotBlank(bookingId)){       
            
            bookingList = getBookingListById(bookingId);        
            
            if(bookingList.size() > 0){     
                processData.currentTeacher = new Data();        
                processData.currentTeacher.Id = bookingList[0].Teacher_Account__c;      
                processData.currentTeacher.Name = bookingList[0].Teacher_Account__r.Name;       
                processData.bookingDate = String.valueOf(bookingList[0].Booking_Date__c);       
            }       
        }       
        if(String.isNotBlank(centerId)){        
            List<String> weekDay =  new List<String>();     
            weekDay.add('Sun');     
            weekDay.add('Sat');     
            teachersHours = AureusCalendarControllerHelper.getTeacherWorkingHours(centerId, 'AllRosteredStaff', weekDay );   
        }       
        if(teachersHours.setOfTeachers.size() > 0 && teachersHours.teachersHours.size() > 0){      
            processData.hoursList = new List<Teacher_Working_Hour__c>();       
            processData.hoursList = teachersHours.teachersHours;       
            for(Teacher_Working_Hour__c th : teachersHours.teachersHours){     
                
                if(teachersHours.setOfTeachers.contains(th.Teacher_Name__c)){      
                    mapOfteacher.put(th.Teacher_Name__c, th.Teacher_Name__r.Name);     
                    
                }      
            }      
        }       
        processData.teachersList = new List<Data>();        
        
        if(mapOfteacher.size() > 0){        
            for(String key : mapOfteacher.keyset()){        
                currentC = new Data();      
                currentC.Id = key;      
                currentC.Name = mapOfteacher.get(key);      
                processData.teachersList.add(currentC);     
            }       
        }       
        return processData;     
    }       
    
    @RemoteAction       
    public static EnrolmentProcessPlanData getPlans(String bookingId, String centerId, String teacherId){       
        Set<String> instruments =  new Set<String>();       
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();     
        List<Booking__c> bookingList = new List<Booking__c>();      
        EnrolmentProcessPlanData processData = new EnrolmentProcessPlanData();      
        Data currentC = new Data();     
        List<Package__c> packageList = new List<Package__c>();      
        if(String.isNotBlank(centerId) && String.isNotBlank(teacherId)){        
            
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c FROM Account WHERE Id =:teacherId];       
            
            if(tchrList.size() > 0){        
                
                for(Account acc: tchrList){        
                    
                    if(acc.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    
                    if(acc.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    
                }       
                
                if(instruments.size() > 0){     
                    processData.planList = new List<Data>();        
                    packageList = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name, Location__r.Travel_Time__c, Duration__c        
                                   FROM Package__c       
                                   WHERE Location__c =: centerId AND Program__r.Status__c =: ConstantsClass.activeStatus  AND Program__r.Instrument__c IN: instruments       
                                   AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND        
                                   Active__c = True AND (Type__c = 'Individual' OR Type__c = 'Home') AND RecordtypeId =: pkgLessRecId ORDER BY Program__r.Name,Duration__c];     
                    
                    if(packageList.size() > 0){     
                        for(Package__c pkg : packageList){      
                            currentC = new Data();      
                            currentC.Id = pkg.Id;       
                            currentC.Name = pkg.Name;       
                            processData.planList.add(currentC);     
                        }       
                    }       
                    
                }       
            }       
        }       
        processData.currentPlan = new Data();       
        if(String.isNotBlank(bookingId)){       
            bookingList = getBookingListById(bookingId);        
            if(bookingList.size() > 0 && packageList.size() > 0){
                for(Package__c pkg : packageList){      
                    if(pkg.Program__r.Instrument__c == bookingList[0].Instrument__c && pkg.Duration__c == String.valueOf(bookingList[0].Duration__c) && pkg.Location__c == bookingList[0].Center__c){       
                        processData.currentPlan.Id = pkg.Id;        
                        processData.currentPlan.Name = pkg.Name;        
                        break;      
                    }       
                }       
            }       
        }       
        return processData;     
    }       
    
    
    private static List<Account> getAllCenters(){       
        Id recordTypeCenter = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();        
        return [SELECT Id, Name FROM Account WHERE RecordTypeId =: recordTypeCenter ORDER BY Name];     
    }       
    
    private static List<Booking__c> getBookingListById(String bookingId){       
        String trialType = ConstantsClass.typeTrial;        
        String completedStatus = ConstantsClass.statusCompleted;        
        return [SELECT Id, Center__c, Center__r.Name, Teacher_Account__c, Teacher_Account__r.Name, Instrument__c, Duration__c, Booking_Date__c FROM Booking__c WHERE Id =: bookingId AND Type__c =: trialType AND Status__c =: completedStatus];        
    }       
    
    
    @RemoteAction       
    public static void sendEnrolToIpad(String messsage){        
        /*String processType = 'Enrolment';       
iPad_Process_Event__e processEvent = new iPad_Process_Event__e();       
processEvent.Process_Type__c = processType;     
processEvent.Direction__c = Label.From_Laptop;      
processEvent.UserId__c = UserInfo.getUserId();      
if(String.isNotBlank(messsage)){        
processEvent.Message__c = messsage;       
}       
Database.SaveResult sr = EventBus.publish(processEvent);        
// Inspect publishing result        
if (sr.isSuccess()) {       
System.debug('Successfully published event.');      
} else {        
for(Database.Error err : sr.getErrors()) {      
System.debug('Error returned: ' +       
err.getStatusCode() +      
' - ' +        
err.getMessage());     
}       
}*/       
    } 
    
    /*
getLastLessonDate method is use for getting last date of lesson on selecting the withdraw end Date.
*/
    @RemoteAction      
    public static WithdrawalSummary getWithrawalSummary(String bookingId, String withdrawEndDate, String lastLessonDate){
        WithdrawalSummary withdrawSummary = new WithdrawalSummary();
        Date withdrawEndDateObj, lastLessonDateObj, nextBillingDate;
        List<Lessons> lastLessonsList = new List<Lessons>();
        List<Lessons> makeupPendingList = new List<Lessons>();
        Enrolment__c enrolment;
        
        if(String.isNotBlank(withdrawEndDate)){
            withdrawEndDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(lastLessonDate)){
            lastLessonDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(bookingId)){
            enrolment = getEnrolDetails(bookingId);
        }
        
        if(String.isNotBlank(enrolment.Id)){
            nextBillingDate = getNextBillingDate(enrolment.Id);
            if(String.isNotBlank(enrolment.Id) && lastLessonDateObj != NULL && nextBillingDate != NULL){
                withdrawSummary.lastLessons = getLast4Lessons(enrolment.Id, lastLessonDateObj, nextBillingDate);
                withdrawSummary.finalDeposits = getFinalDepositSummary(withdrawSummary.lastLessons);
                withdrawSummary.makeupLessons = getPendingMakeupBookings(enrolment.Id, lastLessonDateObj);
            }
        }
        if(enrolment != NULL){
            Decimal total = 0, gst = 0;
            DateTime dt = DateTime.newInstance(enrolment.Lessons_Start_Date__c, enrolment.Lesson_Start_time__c);
            withdrawSummary.student = enrolment.student__r.Name;
            withdrawSummary.packageName = enrolment.Package__r.Name;
            withdrawSummary.centre = enrolment.Center__r.Name;
            withdrawSummary.LessonDay = dt.format('dd MMM, yyyy hh:mma');
            dt = DateTime.newInstance(withdrawEndDateObj, enrolment.Lesson_Start_time__c);
            withdrawSummary.noticeDate = dt.format('dd MMM, yyyy');
            dt = DateTime.newInstance(lastLessonDateObj, enrolment.Lesson_Start_time__c);
            withdrawSummary.lastDate = dt.format('dd MMM, yyyy');
            withdrawSummary.deposit =   getDepositFromFile(enrolment.id);     //enrolment.Package__r.Deposit_Fee__c;
            if(withdrawSummary.finalDeposits != NULL && withdrawSummary.finalDeposits.size() != 0){
                for(Lessons currentLesson : withdrawSummary.finalDeposits){
                    total += currentLesson.unitPrice;
                }
                if(total > 0){
                    gst = total  * (Decimal.valueOf(Label.GST_Tax_Rate) / 100);
                }
            }
            withdrawSummary.refund = 0;
            withdrawSummary.total = total + gst;
            withdrawSummary.gst = gst;
            if(withdrawSummary.deposit > 0){
                withdrawSummary.refund = withdrawSummary.deposit - withdrawSummary.total;
            }
            String chargeId = fetchCurrentMonthPaymentEntry(enrolment,lastLessonDateObj);
            if(String.isNotBlank(chargeId) && (lastLessonDateObj < nextBillingDate)){
                withdrawSummary.refund += getLessonRefundAmount(enrolment,lastLessonDateObj);        
            }
        }
        return withdrawSummary;
    }
    
    public static Map<String, String> getInvoiceFromEnrolment(String enrolmentId){
        Map<String, String> invoiceNameMap = new Map<String, String>();
        if(String.isNotBlank(enrolmentId)){
            List<Invoice_Line_Item__c> invoiceLineItem = [SELECT Id, Invoice__c, Invoice__r.Name FROM Invoice_Line_Item__c 
                                                          WHERE Enrolment__c =: enrolmentId AND Invoice_Date__c = THIS_MONTH 
                                                          ORDER BY Amount__c DESC LIMIT 1];
            if(invoiceLineItem.size() > 0){
                invoiceNameMap.put('Id', invoiceLineItem[0].Invoice__c);
                invoiceNameMap.put('Name', invoiceLineItem[0].Invoice__r.Name);
            }
        }
        return invoiceNameMap;
    }
    //return sum of all deposit amount for enrolment
    public static Decimal getDepositFromFile(String enrolId){
        Decimal deposit = 0;
        for(Invoice_Line_Item__c objLineItem : [SELECT Id,Amount__c FROM Invoice_Line_Item__c WHERE IS_Deposit__c = TRUE AND Enrolment__c =:enrolId]){
            deposit += objLineItem.amount__c;
        }
        return deposit;
    }  
    private static Date getNextBillingDate(String enrolId){
        Date nextBillingDate;
        List<Subscription_Line_Item__c> subscriptionLineItemList = [SELECT Id, Next_Bill_Date__c FROM Subscription_Line_Item__c WHERE Enrolment__c =: enrolId];
        if(subscriptionLineItemList.size() > 0){
            nextBillingDate = subscriptionLineItemList[0].Next_Bill_Date__c;
        }
        return nextBillingDate;
    }
    
    public static Decimal getLessonRefundAmount(Enrolment__c objEnrol,Date lastLessonDate){
        Decimal amount = 0;
        List<Booking__c> bookings = getCurrentBilledBooking(objEnrol.id,lastLessonDate);
        Integer count= 0;
        for(Booking__c objBook : bookings){
            if(objBook.booking_date__c > lastLessonDate){
                count+=1;
            }
        }
        if(count >0){
            amount = count * objEnrol.package__r.unit_fee__c;
            amount+= amount  * (DEcimal.valueOf(Label.GST_Tax_Rate) / 100);
            
        }
        return amount;
    }
    
    
    // return currentBilledBookings
    private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDate){
        Date firstDate = Date.newInstance(lastLessonDate.year(),lastLessonDate.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
        return [SELECT Booking_Date__c FROM Booking__c WHERE Enrolment__c=: enrolId AND Booking_Date__c >=: firstDate AND Booking_Date__c <=: lastDate
                AND (Type__c='Regular' or Type__c ='Ad-hoc') and (Status__c = :ConstantsClass.statusScheduled OR Status__c = :ConstantsClass.statusPending)];
    }   
    
    private static List<Lessons> getLast4Lessons(String enrolId, Date lastLessonDateObj, Date nextBillingDate){
        Map<String, String> mapOfInvoiceName = new Map<String, String>();
        mapOfInvoiceName = getInvoiceFromEnrolment(enrolId);
        List<Lessons> lessonsList = new List<Lessons>();
        Lessons lesson = new Lessons();
        Set<String> bookingIdSet = new Set<String>();
        List<Lessons> reverselessonList = new List<Lessons>();
        String typeRegular = ConstantsClass.typeRegular;
        Set<String> bookingStatus = new Set<String>();
        
        bookingStatus.add(ConstantsClass.statusScheduled); 
        bookingStatus.add(ConstantsClass.statusPending);
        bookingStatus.add(ConstantsClass.statusCompleted);
        bookingStatus.add(ConstantsClass.statusNoshow);
        
        Datetime formatedDate;
        
        for(Booking__c bookObj : [SELECT Id, Name, type__c, Status__c, Booking_Date__c, Start_Time__c, Duration__c, Package__c,
                                  Package__r.Name, Package__r.Unit_Fee__c, Student__r.Name FROM Booking__c WHERE Enrolment__c =: enrolId AND Type__c =: typeRegular 
                                  AND Booking_Date__c <= :lastLessonDateObj ORDER BY Booking_Date__c DESC LIMIT 4]){
                                      lesson = new Lessons();
                                      bookingIdSet.add(bookObj.Id);                          
                                      formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
                                      lesson.bookingId = bookObj.Id;
                                      lesson.Lesson = bookObj.Package__r.Name;
                                      lesson.bookingDate = formatedDate.format('dd MMM, yyyy');
                                      lesson.bookingTime = formatedDate.format('hh:mma');
                                      lesson.duration = bookObj.Duration__c;
                                      lesson.unitPrice = bookObj.Package__r.Unit_Fee__c;
                                      lesson.student = bookObj.Student__r.Name;
                                      lesson.qty = 1;
                                      if(bookObj.Booking_Date__c < nextBillingDate){
                                          if(mapOfInvoiceName.keyset().size() > 0){
                                              lesson.status = mapOfInvoiceName.get('Id')+':'+ mapOfInvoiceName.get('Name');
                                          }else{
                                              lesson.status = 'Billed';
                                          }
                                          
                                      }else if(bookObj.Booking_Date__c >= nextBillingDate){
                                          lesson.status = 'Deposit';
                                      }
                                      reverselessonList.add(lesson); 
                                  }
        if(reverselessonList.size() > 0){
            for(integer i = reverselessonList.size() - 1; i >= 0; i--){
                lessonsList.add(reverselessonList[i]);
            }
        }
        
        return lessonsList;
    }   
    
    private static List<Lessons> getPendingMakeupBookings(String enrolId, Date lastLessonDateObj){
        List<Lessons> lessonsList = new List<Lessons>();
        Lessons lesson = new Lessons();
        Set<String> bookingTypes = new Set<String>();
        bookingTypes.add(ConstantsClass.typeRegular);
        bookingTypes.add(ConstantsClass.typeAdhoc);
        String statusCanceled = ConstantsClass.statusCanceled;
        Datetime formatedDate, lastDateObj;
        lastDateObj = DateTime.newInstance(lastLessonDateObj, Time.newInstance(0, 0, 0, 0));
        for(Booking__c bookObj : [SELECT Id, Student__r.Name, Booking_Date__c, Canceled_Date__c, Start_Time__c, Available_Make_up_Units__c, Make_up_Expiry_Date__c FROM Booking__c WHERE enrolment__c =: enrolId AND Type__c IN: bookingTypes AND Status__c =: statusCanceled AND Available_Make_up_Units__c > 0 AND Make_up_Expiry_Date__c >= TODAY ORDER BY Canceled_Date__c]){
            lesson = new Lessons();
            formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
            lesson.bookingId = bookObj.Id;
            lesson.duration = bookObj.Available_Make_up_Units__c;
            lesson.bookingTime = formatedDate.format('hh:mma');
            lesson.student = bookObj.student__r.Name;
            
            if(bookObj.Canceled_Date__c != NULL){
                
                DateTime bookingDate = DateTime.newInstance(bookObj.Booking_Date__c, Time.newInstance(0, 0, 0, 0));
                lesson.cancelDate = bookingDate.format('dd MMM, yyyy'); 
            }else{
                lesson.cancelDate = '';
            }
            
            formatedDate = DateTime.newInstance(bookObj.Make_up_Expiry_Date__c, bookObj.Start_Time__c);
            lesson.expiryDate = formatedDate.format('dd MMM, yyyy');
            lesson.nextExpiryDate = lastDateObj.format('dd MMM, yyyy');
            lessonsList.add(lesson);
        }
        return lessonsList;
    } 
    
    private static Enrolment__c getEnrolDetails(String bookingId){
        Enrolment__c enrol = new Enrolment__c();
        List<Enrolment__c> enrolList = [SELECT Id, Student__r.Name,Parent__c, Package__r.Name, Package__r.Deposit_Fee__c, Package__r.Unit_Fee__c,
                                        Center__r.Name, Lessons_Start_Date__c, Lesson_Start_time__c, Notice_Period_End_Date__c, Effective_Date__c 
                                        FROM Enrolment__c WHERE Id IN (SELECT Enrolment__c FROM Booking__c WHERE Id =: bookingId)];
        if(enrolList.size() > 0){
            enrol = enrolList[0];
        }
        system.debug('objEnrol'+enrol);
        return enrol;
    }
    
    private static List<Lessons> getFinalDepositSummary(List<lessons> lessons){
        List<Lessons> depositLessons = new List<Lessons>();
        Lessons currentLesson = new Lessons();
        if(lessons.size() > 0){
            for(Lessons lesson : lessons){
                if(lesson.status == 'Deposit'){
                    currentLesson = new Lessons();
                    currentLesson.Lesson = lesson.Lesson + ' - ' +lesson.bookingDate;
                    currentLesson.student = lesson.student;
                    currentLesson.qty = lesson.qty;
                    currentLesson.unitPrice = lesson.unitPrice ;
                    currentLesson.total = lesson.unitPrice * lesson.qty;
                    depositLessons.add(currentLesson);
                }
                
            }
        }
        return depositLessons;
    }
    
    @RemoteAction
    public static List<String> getTimeSlotsAccordingly(String centerId, String teacherId, String upgradePackage, String enrolmentId, String effectiveDateStr){
        List<String> availTimeSlots = new List<String>();
        Set<Integer> timeSlotsToRemove = new Set<Integer>();
        Set<String> bookingTimeSlots, unOrderedTimeSlots = new Set<String>();
        
        DateTime effectiveDate;
        List<Package__c> newPackageList = new List<Package__c>();
        if(String.isNotBlank(upgradePackage)){
            newPackageList = [SELECT Id, Duration__c FROM Package__c WHERE Id =: upgradePackage];
        }
        if(String.isNotBlank(effectiveDateStr)){
            effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
        }
        
        if(String.isNotBlank(teacherId) && String.isNotBlank(centerId) && effectiveDate != NULL){
            availTimeSlots = getTeacherWorkingHourTimeSlotList(teacherId, centerId, effectiveDate.format('EEE'));
        }
        
        System.debug('availTimeSlots '+availTimeSlots.size());
        
        if(availTimeSlots.size() > 0 && String.isNotBlank(enrolmentId)){
            bookingTimeSlots = getScheduledBookingSlots(enrolmentId, effectiveDate.date(), centerId, teacherId);
        }
        
        if(bookingTimeSlots != Null && bookingTimeSlots.size() > 0){
            for(String currentValue : bookingTimeSlots){
                if(availTimeslots.contains(currentValue)){
                    availTimeslots.remove(availTimeslots.indexOf(currentValue));    
                }
            }
        }
        
        if(availTimeSlots != null || availTimeSlots.size() > 0 && newPackageList.size() > 0){
            unOrderedTimeSlots  = removeUnselectableSlots(availTimeSlots, Integer.valueOf(newPackageList[0].Duration__c));
        }
        
        System.debug('unOrderedTimeSlots '+unOrderedTimeSlots.size());
        if(unOrderedTimeSlots != Null && unOrderedTimeSlots.size() > 0){
            for(String currentValue : unOrderedTimeSlots){
                if(availTimeslots.contains(currentValue)){
                    availTimeslots.remove(availTimeslots.indexOf(currentValue));
                }
            }
        }
        
        return availTimeSlots;
    }
    
    private static List<String> getTeacherWorkingHourTimeSlotList(String teacherId, String centerId, String weekDay){
        List<String> availTimeSlots = new List<String>();
        DateTime startTime, endTime;
        List<Teacher_Working_Hour__c> teachersHours = [SELECT Id, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId 
                                                       AND Teacher_Name__c =: teacherId AND Working_Day__c =: weekDay AND Active__c =: True 
                                                       AND Break_Time__c =: False];
        System.debug('teachersHours '+teachersHours.size());
        System.debug('centerId '+centerId);
        System.debug('teacherId '+teacherId);
        System.debug('weekDay '+weekDay);
        
        if(teachersHours.size() > 0){
            startTime = DateTime.newInstance(Date.today(), teachersHours[0].Start_Time__c);
            endTime = DateTime.newInstance(Date.today(), teachersHours[0].End_Time__c );
            if(startTime != NULL && endTime != NULL){
                availTimeSlots = getFormatedTimeSlotList(startTime, endTime);
            }
        }
        return availTimeSlots;
    }
    
    private static Set<String> getScheduledBookingSlots(String enrolmentId, Date bookingsDate, String centerId, String teacherId){
        Set<Date> dt = new Set<Date>();
        dt.add(bookingsDate);
        List<Booking__c> bookingList = getBookingsOnSelectedDates(centerId, teacherId, dt, enrolmentId, false);
        
        Set<String> bookingSlots = new Set<String>();
        if(bookingList.size() > 0){
            for(Booking__c currentBook : bookingList){
                bookingSlots.addAll(getFormatedTimeSlotList(DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c).addMinutes(-15)));
            }
        }
        return bookingSlots;
    }
    
    private static List<String> getFormatedTimeSlotList(DateTime startTime, DateTime endTime){
        List<String> timeSlots = new List<String>();
        if(startTime < endTime){
            while(startTime <= endTime){
                timeSlots.add(startTime.format('h:mm a'));
                startTime = startTime.addMinutes(15);
            }
        }
        return timeSlots;
    }
    
    private static Set<String> removeUnselectableSlots(List<String> timeSlots, Integer duration){
        Set<String> elementsToRemove = new Set<String>();
        DateTime currentDT;
        Boolean innerLoop = false;
        for(integer i = 0; i< timeSlots.size(); i++){
            currentDT = getDateTimeFromString(timeSlots[i]);
            innerLoop = (i + duration / 15) >= timeSlots.size() ? false : true;
            if(innerLoop){
                for(integer j = i ; j < i + duration / 15; j++){
                    if(currentDT.format('h:mm a') != timeSlots[j]){
                        elementsToRemove.add(timeSlots[i]);
                    }
                    currentDT = currentDT.addMinutes(15);
                }
            }else{
                elementsToRemove.add(timeSlots[i]);
            }
            
        }
        return elementsToRemove;
    }
    private static DateTime getDateTimeFromString(String currentTime){
        DateTime dt;
        Time currentTimeObj;
        Integer hours, minutes;
        if(String.isNotBlank(currentTime)){
            if(currentTime.contains('AM')){
                hours = Integer.valueOf(currentTime.split(':')[0]); 
            }else if(currentTime.contains('PM') && !currentTime.contains('12')){
                hours = Integer.valueOf(currentTime.split(':')[0]) + 12; 
            }else if(currentTime.contains('PM') && currentTime.contains('12')){
                hours = Integer.valueOf(currentTime.split(':')[0]); 
            } 
            minutes = Integer.valueOf(currentTime.split(':')[1].split(' ')[0]);
            currentTimeObj = Time.newInstance(hours, minutes, 0, 0);
        }
        if(currentTimeObj != NULL){
            dt = DateTime.newInstance(Date.today(), currentTimeObj);
        }
        return dt;
    }
    
    @RemoteAction
    public static AureusCalendarController.UpgradeDowngradePackageSummary  getUpgradeDowngradePackageSummary(String oldPackageId, String newPackageId, 
                                                                                    String effectiveDate, String availTimeSlots, 
                                                                                    String enrolmentId, String typeOfSummary){
                                                                                        
                                                                                        Map<String, String> enrolSummary = new Map<String, String>();
                                                                                        DateTime newDateTime;
                                                                                        Date nextBillDate;
                                                                                        Package__c newPackg, oldPackg = new Package__c();
                                                                                        Integer minutesOfFifthBooking = 0;
                                                                                        Integer countWithNewPackage = 0;
                                                                                        List<Enrolment__c> enrolmentList = new List<Enrolment__c>(); 
                                                                                        AureusCalendarController.UpgradeDowngradePackageSummary summary = new AureusCalendarController.UpgradeDowngradePackageSummary();
                                                                                        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
                                                                                            summary = getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
                                                                                            newPackg = summary.newPackage;
                                                                                            oldPackg = summary.oldPackage;            
                                                                                        }
                                                                                        if(String.isNotBlank(enrolmentId)){
                                                                                            summary.currentPackageDeposit = getDepositFromFile(enrolmentId);
                                                                                            enrolSummary = getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
                                                                                            if(enrolSummary.containsKey('currentDay')){
                                                                                                summary.currentDayAndTime = enrolSummary.get('currentDay');
                                                                                            }
                                                                                            if(enrolSummary.containsKey('currentMonthInvoice')){
                                                                                                summary.invoiceForCurrentMonth = Decimal.valueOf(enrolSummary.get('currentMonthInvoice'));
                                                                                            }
                                                                                            enrolmentList = getNextBillingDateSubscription(enrolmentId);
                                                                                            if(enrolmentList.size() > 0){
                                                                                                nextBillDate = getNextBillingSubscriptionLineItemDate(enrolmentList);
                                                                                            } 
                                                                                        }
                                                                                        if(String.isNotBlank(effectiveDate) && String.isNotBlank(availTimeSlots)){
                                                                                            newDateTime = getDateTimeFromString(availTimeSlots);
                                                                                            newDateTime = DateTime.newInstance(Date.valueOf(effectiveDate), newDateTime.time());
                                                                                            //summary.newDayAndTime = newDateTime.format('EEE, MMM dd YYYY h:mm a');
                                                                                            summary.newDayAndTime = newDateTime.format('EEE @ h:mm a');
                                                                                            summary.effectiveDate = newDateTime.format('EEE, MMM dd YYYY');
                                                                                        }
                                                                                        if((typeOfSummary == 'upgrade' || typeOfSummary == 'downgrade') && newDateTime != NULL && String.isNotBlank(enrolmentId)){
                                                                                            List<Date> dates = getMonthDates(newDateTime);
                                                                                            List<Booking__c> listOfBookings = fetchBookingsForUpgrade(enrolmentId, dates);
                                                                                            for(Booking__c objBooking : listOfBookings){
                                                                                                if(objBooking.Booking_Date__c >= newDateTime.date()){
                                                                                                    if(objBooking.Type__c == ConstantsClass.bookTypeRegular){
                                                                                                        countWithNewPackage +=1;
                                                                                                    }
                                                                                                    
                                                                                                    // @8July2019 as per julius feedback we do not calculate price of 5th booking. 
                                                                                                    /*if(objBooking.is_Fifth_Booking__c && (objBooking.Type__c == ConstantsClass.typeAdhoc || objBooking.Type__c == ConstantsClass.typeMakeup)){
minutesOfFifthBooking += Integer.valueOf(newPackg.duration__c) - Integer.valueOf(oldPackg.duration__c);     
}else{
countWithNewPackage +=1;
}*/
                                                                                                }
                                                                                            }
                                                                                            
                                                                                            Decimal totalAmount = 0;
                                                                                            Decimal depositeFee = (newPackg.Deposit_Fee__c - summary.currentPackageDeposit);
                                                                                            summary.invoiceDepositTopup = depositeFee;
                                                                                            Decimal newPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNewPackage ;
                                                                                            
                                                                                            
                                                                                            if(typeOfSummary == 'upgrade'){
                                                                                                
                                                                                                newPackageUnitPrice += newPackageUnitPrice * ((Decimal.valueOf(Label.GST_Tax_Rate)/100));
                                                                                                summary.invoiceDepositLessonTopup = newPackageUnitPrice;
                                                                                                totalAmount = newPackageUnitPrice;
                                                                                                totalAmount +=   depositeFee ;
                                                                                                if(newDateTime <= nextBillDate){
                                                                                                    summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                                                                                                }else{
                                                                                                    summary.invoiceTopup = BillingUtility.roundOffAmount(depositeFee);
                                                                                                    summary.invoiceDepositLessonTopup = 0;
                                                                                                }
                                                                                            }else if(typeOfSummary == 'downgrade'){
                                                                                                totalAmount = 0;
                                                                                                Date firstDate = Date.newInstance(newDateTime.year(), newDateTime.month(), 01);
                                                                                                Integer daysInMonth = Date.daysInMonth(newDateTime.year(), newDateTime.month());
                                                                                                Date lastDate = Date.newInstance(newDateTime.year(), newDateTime.month(), daysInMonth);
                                                                                                Map<String, List<Date>> mapOfDates = new Map<String, List<Date>>();
                                                                                                if(newDateTime >= nextBillDate){
                                                                                                    mapOfDates = BillingUtility.getDateMap(firstDate,lastDate);
                                                                                                }else{
                                                                                                    mapOfDates = BillingUtility.getDateMap(newDateTime.date(),lastDate);
                                                                                                }
                                                                                                
                                                                                                Integer countWithOldPackage = 0;
                                                                                                Integer countWithNewPackageDowngrade = 0;
                                                                                                if(enrolmentList.size() > 0 && String.isNotBlank(enrolmentList[0].Lesson_Day__c) && mapOfDates.containsKey(enrolmentList[0].Lesson_Day__c)){
                                                                                                    List<Date> listOfDates = mapOfDates.get(enrolmentList[0].Lesson_Day__c);
                                                                                                    if(listOfDates.size() == 5){
                                                                                                        listOfDates.remove(4);
                                                                                                    }
                                                                                                    for(Date objDate : listOfDates){
                                                                                                        if(objDate.day() <29){
                                                                                                            if(objDate < newDateTime.date() ){
                                                                                                                countWithOldPackage +=1;
                                                                                                            }else if(objDate >= newDateTime.date()){
                                                                                                                countWithNewPackageDowngrade +=1;
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                                if(newDateTime >= nextBillDate){
                                                                                                    Decimal newPackageLessonFee = 0;
                                                                                                    
                                                                                                    newPackageUnitPrice = 0;
                                                                                                    newPackageUnitPrice = (newPackg.Unit_Fee__c)*countWithNewPackageDowngrade ;
                                                                                                    Decimal oldPackageUnitPrice = (oldPackg.Unit_Fee__c)*countWithOldPackage;
                                                                                                    newPackageUnitPrice = newPackageUnitPrice + oldPackageUnitPrice;
                                                                                                    
                                                                                                    newPackageUnitPrice += newPackageUnitPrice * ((Decimal.valueOf(Label.GST_Tax_Rate)/100));
                                                                                                    summary.invoiceDepositLessonTopup = newPackageUnitPrice;
                                                                                                    totalAmount += newPackageUnitPrice;
                                                                                                    totalAmount += depositeFee;
                                                                                                    summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                                                                                                }else if(newDateTime < nextBillDate){
                                                                                                    if(summary.currentPackageDeposit == null){
                                                                                                        summary.currentPackageDeposit = 0;
                                                                                                    }
                                                                                                    depositeFee = (newPackg.Deposit_Fee__c - summary.currentPackageDeposit);    
                                                                                                    summary.invoiceDepositTopup = BillingUtility.roundOffAmount(depositeFee);
                                                                                                    
                                                                                                    
                                                                                                    summary.positiveInvoiceAmount = countWithNewPackageDowngrade * newPackg.Unit_Fee__c ;
                                                                                                    summary.negativeInvoiceAmount = - (countWithNewPackageDowngrade * oldPackg.Unit_Fee__c);
                                                                                                    
                                                                                                    newPackageUnitPrice = countWithNewPackageDowngrade * (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                                                                                                    newPackageUnitPrice += (newPackg.Unit_Fee__c / Integer.valueOf(newPackg.duration__c))*minutesOfFifthBooking;
                                                                                                    newPackageUnitPrice += newPackageUnitPrice * ((Decimal.valueOf(Label.GST_Tax_Rate)/100));
                                                                                                    summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice);
                                                                                                    totalAmount = newPackageUnitPrice;
                                                                                                    totalAmount += depositeFee;
                                                                                                    summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                                                                                                }
                                                                                            }
                                                                                            
                                                                                        }
                                                                                        return summary;
                                                                                    }
    private static AureusCalendarController.UpgradeDowngradePackageSummary  getPackageDetailsUpgradeDowngrade(String oldPackageId, String newPackageId){
        AureusCalendarController.UpgradeDowngradePackageSummary summary = new AureusCalendarController.UpgradeDowngradePackageSummary();
        Set<String> packageIds = new Set<String>();
        List<Package__c> packageList = new List<Package__c>();
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            packageIds.add(oldPackageId);
            packageIds.add(newPackageId);
        }
        if(packageIds.size() > 0){
            packageList = [SELECT Id, Name, Deposit_Fee__c, duration__c, Unit_Fee__c  FROM Package__c WHERE Id IN: packageIds];
            if(packageList.size() == 2){
                for(Package__c packageObj : packageList){
                    if(packageObj.Id == oldPackageId){
                        summary.oldPackage = packageObj;
                        summary.oldPackageName = packageObj.Name; 
                        summary.oldPackageId = packageObj.Id;
                        summary.oldDuration = packageObj.duration__c;
                        summary.currentPackageDeposit = packageObj.Deposit_Fee__c;
                    }else if(packageObj.Id == newPackageId){
                        summary.newPackage = packageObj;
                        summary.newPackageName = packageObj.Name; 
                        summary.newPackageId = packageObj.Id;
                        summary.newDuration = packageObj.Duration__c;
                        summary.newPackageDeposit = packageObj.Deposit_Fee__c;
                    }
                }
            }
        }
        return summary;
    }
    
    public static Map<String, String> getEnrolmentDetailsUpgradeDowngrade(String enrolmentId){
        Map<String, String> mapToReturn = new Map<String, String>();
        DateTime dt;
        List<Enrolment__c> enrolList = [SELECT Id, Lessons_Start_Date__c, Lesson_Day__c, Parent__c, Lesson_Start_time__c, 
                                        Package__c, Package__r.Package_Fee__c, Package__r.Deposit_Fee__c, 
                                        Package__r.Name, Teacher__c, Teacher__r.Name, Package__r.Duration__c, 
                                        center__c, center__r.Name FROM Enrolment__c WHERE Id =: enrolmentId];
        if(enrolList.size() > 0){
            Enrolment__c objEnrol = enrolList[0];
            dt = DateTime.newInstance(objEnrol.Lessons_Start_Date__c, objEnrol.Lesson_Start_time__c);  
            if(dt != Null){
                //mapToReturn.put('currentDay', dt.format('EEE, MMM dd YYYY h:mm a'));
                if(String.isNotBlank(objEnrol.Lesson_Day__c)){
                    String currentTime = objEnrol.Lesson_Day__c.left(3);
                    currentTime += ' @ ' + dt.format('h:mm a');
                    mapToReturn.put('currentDay', currentTime);
                    
                    mapToReturn.put('currentWeekDay', objEnrol.Lesson_Day__c.left(3));
                }
            }
            mapToReturn.put('currentCenter', objEnrol.center__c);
            mapToReturn.put('currentPackage', objEnrol.Package__r.Name);
            mapToReturn.put('parentId', objEnrol.Parent__c);
            mapToReturn.put('currentTeacher', objEnrol.Teacher__r.Name);              
            mapToReturn.put('currentPackageDuration', objEnrol.Package__r.Duration__c);
            mapToReturn.put('currentMonthInvoice', String.valueOf(objEnrol.Package__r.Package_Fee__c));
            mapToReturn.put('currentPackageDepositFee', String.valueOf(objEnrol.Package__r.Deposit_Fee__c));
            // added by arpit for change enrolment process
            mapToReturn.put('currentTeacherId',objEnrol.Teacher__c);
            mapToReturn.put('currentPackageId',objEnrol.Package__c);
        }
        return mapToReturn;
    }
    
    @RemoteAction
    public static EnrolmentEdit getEnrolmentUpdateDetails(String enrolmentId){
        EnrolmentEdit enrolEdit = new EnrolmentEdit();
        Map<String, String> enrolDetails = new Map<String, String>();
        if(String.isNotBlank(enrolmentId)){
            enrolDetails = getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
            if(enrolDetails.containsKey('currentTeacher')){
                enrolEdit.currentTeacher = enrolDetails.get('currentTeacher');
            } 
            if(enrolDetails.containsKey('currentPackage')){
                enrolEdit.currentPackage = enrolDetails.get('currentPackage');
            } 
            if(enrolDetails.containsKey('currentDay')){
                enrolEdit.currentDayTimeSlot = enrolDetails.get('currentDay');
            }   
            if(enrolDetails.containsKey('currentPackageDuration')){
                enrolEdit.duration = Integer.valueOf(enrolDetails.get('currentPackageDuration'));
            }
            if(enrolDetails.containsKey('currentWeekDay')){
                enrolEdit.currentWeekDay = enrolDetails.get('currentWeekDay');
            }
            
            enrolEdit.currentTeacherId = enrolDetails.containsKey('currentTeacherId') ? enrolDetails.get('currentTeacherId') : '';
            enrolEdit.currentPackageId = enrolDetails.containsKey('currentPackageId') ? enrolDetails.get('currentPackageId') : '';
            
            if(enrolDetails.containsKey('currentCenter')){
                enrolEdit.center = enrolDetails.get('currentCenter');
                enrolEdit.teachers = new List<Data>();
                List<Data> multipleData = new List<Data>();
                Data data = new Data();
                List<Account> teachers = AureusCalendarControllerHelper.getListOfTeacher(enrolDetails.get('currentCenter'));
                for(Account teacher : teachers){
                    data = new Data();
                    data.Id = teacher.Id;
                    data.name = teacher.Name;
                    multipleData.add(data); 
                }    
                if(multipleData.size() > 0){
                    enrolEdit.teachers = multipleData;
                }
            }       
        }
        return enrolEdit; 
    }
    
    @RemoteAction
    public static List<Data> getPackageAccordingToTeacher(String centerId, String teacherId, Integer duration){
        List<Data> packageList = new List<Data>();
        Data dt = new Data();
        Set<String> instruments =  new Set<String>();       
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(teacherId)){
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c FROM Account WHERE Id =:teacherId];
            if(tchrList.size() > 0){        
                
                for(Account acc: tchrList){        
                    
                    if(acc.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    
                    if(acc.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    
                }
            }
            if(instruments.size() > 0 && String.isNotBlank(centerId)){        
                for(Package__c pkg : [SELECT Id, Name FROM Package__c WHERE Location__c =: centerId AND Program__r.Status__c =: ConstantsClass.activeStatus  AND Program__r.Instrument__c IN: instruments       
                                      AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null AND        
                                      Active__c = True AND (Type__c = 'Individual' OR Type__c = 'Home') AND 
                                      RecordtypeId =: pkgLessRecId AND Duration__c =: String.valueOf(duration) AND Type_of_package__c = 'Normal' ORDER BY Program__r.Name]){
                                          dt = new Data();
                                          dt.Id = pkg.Id;
                                          dt.name = pkg.Name;
                                          packageList.add(dt);
                                      }    
                
            }
        }
        return packageList;
    }
    @RemoteAction
    public static String updateEnrolment(String enrolmentId, String teacherId, String packageId, 
                                         String effectiveDateStr, String timeStr, String myCaseId, 
                                         String caseRedirect, String previousTime, String oldPackageName, String newPackageName){
                                             Boolean error = true;
                                             Boolean dayChange = false;
                                             Boolean teacherPackageChange = false;
                                             
                                             String oldTeacher, caseReturn, lessonDay,oldPackage, studentId,invoiceId;
                                             Integer duration;
                                             Time startTime;
                                             Date effectiveDate;
                                             Date nextBillDate;
                                             Enrolment__c enrol = new Enrolment__c();
                                             if(String.isNotBlank(enrolmentId)){
                                                 enrol = fetchEnrolment(enrolmentId);
                                                 nextBillDate = enrol.Subscription_Line_Items__r[0].Next_Bill_Date__c;
                                                 oldTeacher = enrol.Teacher__c;
                                                 oldPackage = enrol.Package__c;
                                                 lessonDay = enrol.Lesson_Day__c;
                                                 studentId = enrol.student__c;
                                                 duration = Integer.valueOf(enrol.Package__r.Duration__c);
                                                 startTime = enrol.Lesson_start_Time__c;
                                                 if(teacherId != enrol.Teacher__c || packageId != enrol.Package__c){
                                                     teacherPackageChange =  true;                                      
                                                 }
                                             }
                                             if(String.isNotBlank(effectiveDateStr)){
                                                 effectiveDate = Date.valueOf(effectiveDateStr);
                                                 enrol.Effective_Date__c = effectiveDate;
                                                 /*
* commented by arpit as we are not allowing for day change
* if(effectiveDate.format('EEEE') != lessonDay){
dayChange = true; 
}*/
                                             }
                                             Boolean isSameMonth = nextBillDate > effectiveDate ? true : false;
                                             
                                             
                                             enrol.Package_Process_Status__c = isSameMonth ? ConstantsClass.enrollmentProcessCompletedStatus :   
                                             ConstantsClass.enrollmentProcessPendingStatus;             
                                             if(String.isNotBlank(teacherId)){
                                                 if(isSameMonth){
                                                     enrol.Teacher__c = teacherId;
                                                 }
                                                 enrol.New_Teacher__c = teacherId;
                                             }
                                             if(String.isNotBlank(packageId)){
                                                 if(isSameMonth){
                                                     enrol.Package__c = packageId;
                                                 }
                                                 enrol.new_package_Id__c = packageId;
                                             }
                                             
                                             if(String.isNotBlank(timeStr)){
                                                 if(isSameMonth){
                                                     enrol.Lesson_Start_time__c = getDateTimeFromString(timeStr).time();
                                                 }
                                                 enrol.Next_Lesson_Start_time__c = getDateTimeFromString(timeStr).time();
                                             }
                                             enrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
                                             enrol.Package_Process_Request_Date__c = System.today();
                                             enrol.Advance_Action_Requested_By__c = UserInfo.getUserId();
                                             
                                             /*
* commented by arpit on 17july as we are not allowing day change
*  if(dayChange){
enrol.New_Lesson_Day__c = effectiveDate.format('EEEE');
enrol.Lesson_Day__c = effectiveDate.format('EEEE');
}
*/
                                             System.debug('enrol '+enrol);
                                             if(String.isNotBlank(enrol.Id)){
                                                 List<Booking__c> listOfMakeupBoookings = new List<Booking__c>();
                                                 Database.SaveResult saveResult = Database.update(enrol, false);
                                                 if(saveResult.isSuccess()){
                                                     AureusCalendarControllerHelper.processFutureBookings(enrol, 'change');
                                                     if(String.isNotBLank(studentId) && String.isNotBlank(oldTeacher) && duration > 0 && startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay)){
                                                         for(Booking__c bookingObj : AureusCalendarControllerHelper.processMakeupBooking(studentId, oldTeacher, Duration, startTime, effectiveDate, lessonDay)){
                                                             bookingObj.start_Time__c = getDateTimeFromString(timeStr).time();
                                                             bookingObj.end_Time__c = bookingObj.start_Time__c.addMinutes(duration);
                                                             bookingObj.Teacher_Account__c = teacherId;
                                                             listOfMakeupBoookings.add(bookingObj);
                                                         }
                                                     }
                                                     /*@Arpit 17july19 Requiremt for makeup booking that's why we change this*/
                                                     if(listOfMakeupBoookings.size() > 0){
                                                         update listOfMakeupBoookings;
                                                     }
                                                 }
                                                 
                                                 if(saveResult.isSuccess() && enrol.Subscription_Line_Items__r[0].Next_Bill_Date__c > effectiveDate && teacherPackageChange){
                                                     invoiceId =  createInvoiceAndLineItemsChangeEnrol(enrol, effectiveDate, enrol.Subscription_Line_Items__r[0].Next_Bill_Date__c, oldTeacher,oldPackage,teacherId,packageId);
                                                 }
                                                 
                                                 error = false;
                                             }
                                             if(caseRedirect == 'true' && error == false && enrol != NULL){
                                                 Case caseObj = AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrol.Id, 'change', false);
                                                 if(String.isNotBlank(oldPackageName)){
                                                     caseObj.Previous_Package__c = oldPackageName; 
                                                 }
                                                 if(String.isNotBlank(newPackageName)){
                                                     caseObj.New_Package__c = newPackageName; 
                                                 }
                                                 caseObj.New_Teacher__c =  teacherId;   
                                                 caseObj.Previous_teacher__c = oldTeacher; 
                                                 if(String.isNotBlank(timeStr) && effectiveDate != null){
                                                     DateTime newformatTime = DateTime.newInstance(effectiveDate, getDateTimeFromString(timeStr).time());
                                                     caseObj.New_Lesson_Day_Time__c = newformatTime.format('EEE @ h:mm a');
                                                 }
                                                 
                                                 caseObj.Previous_Lesson_Day_Time__c = previousTime;
                                                 caseObj.Invoice__c = invoiceId;     
                                                 upsert caseObj;    
                                                 caseReturn = caseObj.Id;
                                             }else if(error == false){
                                                 caseReturn = '';
                                             }else{
                                                 caseReturn = 'error';
                                             }
                                             system.debug('@@@caseId'+caseReturn);                                    
                                             return caseReturn;
                                         }
    
    private static Enrolment__c fetchEnrolment(String enrolmentId){
        Enrolment__c enrolmentObj = new Enrolment__c();
        
        List<Enrolment__c> enrolmentList = [SELECT Id, Effective_Date__c, Lesson_Day__c, Teacher__c, 
                                            Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, 
                                            Package__c, Package__r.Duration__c,Parent__c, 
                                            (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c, 
                                             Subscription__c, Subscription__r.Center__c, Enrolment__c FROM Subscription_Line_Items__r) 
                                            FROM Enrolment__c WHERE Id =: enrolmentId];
        if(enrolmentList.size() > 0){
            enrolmentObj = enrolmentList[0];
        } 
        return enrolmentObj;                                          
    }
    
    private static String createInvoiceAndLineItemsChangeEnrol(Enrolment__c objEnrol, Date effectiveDate, Date nextBillingDate, 
                                                               String oldTeacher,String oldPackage,String newTeacher,String newPackage){
                                                                   Invoice__c objectOfInvoice = new Invoice__c();
                                                                   decimal totalAmount = 0;
                                                                   String regularType = ConstantsClass.typeRegular;
                                                                   String canceledStatus = ConstantsClass.statusCanceled; 
                                                                   List<Invoice_Line_Item__c> invoiceLineItem = new List<Invoice_Line_Item__c>();
                                                                   String subLineItemId  ='';
                                                                   Integer noOfOldLesson,noOfNewLesson;
                                                                   List<Booking__c> bookingList = [SELECT Id, Package__c, center__c, Teacher_Account__c, Package__r.Unit_Fee__c, Student__c, Student__r.Parent__c FROM Booking__c WHERE 
                                                                                                   Enrolment__c =: objEnrol.id AND Booking_Date__c >= :effectiveDate AND 
                                                                                                   Booking_Date__c < :nextBillingDate AND Type__c =: regularType AND 
                                                                                                   Status__c !=: canceledStatus ORDER BY Booking_Date__c ];
                                                                   
                                                                   if(objEnrol != NULL && objEnrol.subscription_line_items__r.size() > 0 ){
                                                                       subLineItemId = objEnrol.subscription_line_items__r[0].id;
                                                                   }
                                                                   if(bookingList.size() > 0){
                                                                       String parentId = String.isNotBlank(bookingList[0].Student__r.Parent__c) ? bookingList[0].Student__r.Parent__c : bookingList[0].Student__c;
                                                                       for(Booking__c booking : bookingList){
                                                                           totalAmount += booking.Package__r.Unit_Fee__c;
                                                                       }
                                                                       System.debug('totalAmount '+totalAmount );
                                                                       if(totalAmount > 0 && String.isNotBlank(parentId)){
                                                                           objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                                                                            Invoice_Date__c =system.today(), Parent_Account__c = parentId, Center__c=bookingList[0].center__c);
                                                                           INSERT objectOfInvoice;
                                                                           if(objectOfInvoice != NULL){
                                                                               invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = totalAmount, 
                                                                                                                            Teacher_Id__c = newTeacher,Month__c= System.today(),Enrolment__c =objEnrol.id, 
                                                                                                                            Subscription_line_item__c = subLineItemId,Package__c= newPackage ));
                                                                               totalAmount = -totalAmount;
                                                                               invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = totalAmount, 
                                                                                                                            Teacher_Id__c = oldTeacher,Month__c= System.today(),Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                                                                            Package__c = oldPackage));
                                                                               
                                                                           }
                                                                           System.debug('objectOfInvoice '+objectOfInvoice.id);
                                                                           if(invoiceLineItem.size() > 0){
                                                                               INSERT invoiceLineItem;
                                                                           }
                                                                           if(String.isNotBlank(objectOfInvoice.id)){
                                                                               SageIntacctIntegrationUtility.changeEnrolment(objectOfInvoice.Id);
                                                                           }
                                                                           if(objectOfInvoice != NULL){
                                                                               
                                                                               BillingUtility.createAttachment(new Set<String>{objectOfInvoice.id});
                                                                           }
                                                                           
                                                                       }
                                                                   }
                                                                   return objectOfInvoice.Id;
                                                               }
    
    private static Date getNextBillingSubscriptionLineItemDate(List<Enrolment__c> enrolmentList){
        Date nextBillDate;
        if(enrolmentList.size() > 0){
            nextBillDate = enrolmentList[0].Subscription_Line_Items__r[0].Next_Bill_Date__c;
        }
        return nextBillDate; 
    }
    
    private static List<Booking__c> fetchBookingsForUpgrade(String enrolmentId, List<Date> dates){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c FROM Booking__c WHERE Enrolment__c=:enrolmentId AND 
                Booking_Date__c IN: dates AND Status__c !=: ConstantsClass.statusCanceled AND Type__c =: ConstantsClass.bookTypeRegular];
    }
    
    private static List<Date> getMonthDates(DateTime effectiveDate){
        List<Date> dates = new List<Date>();
        effectiveDate = DateTime.newInstance(effectiveDate.date().toStartOfMonth(), effectiveDate.time());
        Integer currentMonth = effectiveDate.month();
        
        while(effectiveDate.month() == currentMonth){
            dates.add(effectiveDate.date());
            effectiveDate = effectiveDate.addDays(1);
            
        }
        return dates;
    }
    
    @RemoteAction
    public static String sendEnrolmentLinkByCase(String caseObjId, String bookingId, String type){
        String caseIdToReturn, enrolmentId = '';
        
        if(String.isNotBlank(bookingId) && String.isNotBlank(type)){
            if(String.isNotBlank(bookingId)){
                enrolmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
            }
            if(String.isNotBlank(enrolmentId) && String.isBlank(caseObjId)){
                caseObjId = checkExistingCases(bookingId, enrolmentId);
            }
            Case caseObj = AureusCalendarControllerHelper.createCase(caseObjId, bookingId, type);
            if(caseObj != NULL && String.isNotBlank(caseObj.id)){
                caseIdToReturn = caseObj.Id;
            }
        }
        return caseIdToReturn;
    } 
    
    private static String checkExistingCases(String bookingId, String enrolmentId){
        String currentCase = '';
        List<Case> cases = [SELECT Id FROM Case WHERE Booking__c =: bookingId AND Enrolment__c =: enrolmentId];
        if(cases.size() > 0){
            currentCase = cases[0].Id;
        }
        return currentCase;
    }
    
    
    //Get All Future Busy Bookings According to the category
    private static List<Booking__c> getFutureBusyBookings(Booking__c BookingObj){
        String typeBusy = ConstantsClass.typeBusy;
        String statusCanceled = ConstantsClass.statusCanceled;
        return [SELECT Id, start_Time__c, End_Time__c, Duration__c, Booking_Date__c, Type__c FROM Booking__c 
                WHERE RecordTypeId = :BookingObj.RecordTypeId AND Type__c = :typeBusy AND 
                Booking_Date__c >= :BookingObj.Booking_Date__c AND Teacher_Account__c = :BookingObj.Teacher_Account__c AND 
                Center__c =: BookingObj.Center__c AND 
                Start_Time__c = :BookingObj.Start_Time__c  AND End_Time__c = :BookingObj.End_Time__c AND 
                Category__c = :BookingObj.Category__c AND Appointment_Day__c =: BookingObj.Appointment_Day__c AND Status__c != :statusCanceled];
    }
    
    //Cancel all Future Busy Bookings 
    private static boolean cancelAllFutureBusyBookings(List<Booking__c> listOfBookings){
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        Boolean isSuccess = true;
        if(listOfBookings.size() > 0){
            for(Booking__c bookingObj : listOfBookings){
                bookingsToUpdate.add(new Booking__c(Id = bookingObj.Id, Status__c = ConstantsClass.statusCanceled));
            }
        }
        if(bookingsToUpdate.size() > 0){
            Database.SaveResult[] saveResults = Database.update(bookingsToUpdate, false);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    isSuccess = false;
                }
            }
        }
        system.debug('bookingsToUpdate '+bookingsToUpdate.size());
        return isSuccess;
    }
    
    private static Integer getTimeStampBetween(Time startTime, Time endTime){
        DateTime startDTime, endDTime;
        Integer difference = 0;
        if(startTime != Null){
            startDTime = DateTime.newInstance(System.today(), startTime );
        }
        
        if(endTime != Null){
            endDTime = DateTime.newInstance(System.today(), endTime);
        }
        
        if(startDTime != NULL && endDTime != NULL){
            difference = (Integer)((endDTime.getTime() - startDTime.getTime()) / 1000) / 60;
        }
        return difference;
    } 
    
    
    //Get the Pre Payment Packages from the calendar
    @RemoteAction
    public static Map<String, String> getPrePaymentPackage(String enrolId){
        Map<String, String> mapOfPrePaymentPackages = new Map<String, String>();
        String instrument, duration, center;
        if(String.isNotBlank(enrolId)){
            for(Enrolment__c enrolObj : [SELECT Id, Center__c, Package__r.Duration__c, Package__r.Program__r.Instrument__c, 
                                         (SELECT Id, Next_Bill_Date__c FROM Subscription_Line_Items__r) FROM Enrolment__c WHERE Id =: enrolId LIMIT 1]){
                                             instrument =  enrolObj.Package__r.Program__r.Instrument__c;
                                             duration = enrolObj.Package__r.Duration__c; 
                                             center = enrolObj.Center__c;
                                             if(enrolObj.Subscription_Line_Items__r.size() > 0){
                                                 DateTime nextBillFormat = DateTime.newInstance(enrolObj.Subscription_Line_Items__r[0].Next_Bill_Date__c, Time.newInstance(0, 0, 0, 0));
                                                 mapOfPrePaymentPackages.put('nextBillDate', nextBillFormat.format('EEE, MMM dd yyyy')); 
                                             }
                                         }
            if(String.isNotBlank(center) && String.isNotBlank(duration) && String.isNotBlank(instrument)){
                for(Package__c pkgPrePayment : [SELECT Id, Name FROM Package__c WHERE 
                                                Location__c =: center AND Type_of_package__c = :ConstantsClass.prePaymentType 
                                                AND Duration__c =: duration AND Program__r.Instrument__c =: instrument
                                                AND Active__c = True order by Promotion_period_In_months__c]){
                                                    mapOfPrePaymentPackages.put(pkgPrePayment.Id, pkgPrePayment.Name); 
                                                }
            }
        }
        
        return mapOfPrePaymentPackages;
    }    
    public class UpgradeEnrolmentCaseCreate{
        public String caseId;
        public Date nextBillDate;
    }
    
    public class EnrolmentEdit{
        public String currentTeacher;
        public String currentPackage;
        public String currentDayTimeSlot;
        public String center;
        public Integer duration;
        public List<Data> teachers;
        public String currentWeekDay;
        public String currentTeacherId;
        public String currentPackageId;
    }
    public class UpgradeDowngradePackageSummary{
        public String oldPackageId;
        public String newPackageId;
        public String oldPackageName;
        public String newduration;
        public String oldduration;
        public String newPackageName;
        public Decimal currentPackageDeposit;
        public Decimal newPackageDeposit;
        public String currentDayAndTime;
        public String effectiveDate; 
        public Decimal invoiceForCurrentMonth;
        public String newDayAndTime;
        public Package__c oldPackage;
        public Package__c newPackage;
        public Decimal invoiceTopup;
        public Decimal invoiceDepositTopup;
        public Decimal invoiceDepositLessonTopup;
        public Decimal positiveInvoiceAmount;
        public Decimal negativeInvoiceAmount;
    }
    
    public class WithdrawalSummary{
        public List<Lessons> lastLessons;
        public List<Lessons> makeupLessons;
        public List<Lessons> finalDeposits;
        public String student;
        public String packageName;
        public String centre;
        public String LessonDay;
        public String lastDate;
        public String noticeDate;
        public Decimal gst;
        public Decimal total;
        public Decimal deposit;
        public Decimal refund;
    }
    
    public class Lessons{
        public String bookingId;
        public String Lesson;
        public String bookingDate;
        public String bookingTime;
        public Decimal duration;
        public String status;
        public String student;
        public String cancelDate;
        public String expiryDate;
        public String nextExpiryDate;
        public Decimal unitPrice;
        public Decimal total;
        public integer qty;
    }   
    public class Data{      
        public String Id;       
        public String Name;     
    }       
    public class EnrolmentProcessCenterData{        
        Data currentCenter;     
        List<Data> centersList;     
    }       
    
    public class EnrolmentProcessTeacherData{       
        Data currentTeacher;        
        List<Data> teachersList;        
        List<Teacher_Working_Hour__c> hoursList;        
        String BookingDate;     
    }       
    
    public class EnrolmentProcessPlanData{      
        Data currentPlan;       
        List<Data> planList;        
    }   
    
    public class UpDownSummary{
        public Package__c oldPack;
        public Package__c newPack;
        public Integer noOfBookingWithNewPack;
        public Integer noOfBookingWithOldPack;
    }
    public class BusyAppointment{
        String bookingId;
        String duration;
        String timeOfBooking;
        String center;
        String teacher;
        String discription; 
        String category; 
        String teacherId;
        String centerId; 
        String origin;      
    }
    public class AdhocLessonDetails{
        String studentId;
        String studentFirstName;
        String studentLastName;
        String packageId;
        String packageName;
        Integer units;
        Double packageFee;
        Double unitFee;
        String centerName;
        String duration;
        String teacherId;
        String teacherName;
    }
    
    public class GradePackageDetails{
        String packageId;
        String packageName;
        List<GradePackage> packages;
        String LessonDay;
    }
    
    public class AdvanceDetails{
        String id;
        String timeSlot;
        String startDate;
        String frequency;
        String packageName;
        String packageId;
        Boolean isPackagePromotional;
    }
    
    public class GradePackage{
        String id;
        String name;
        Decimal price;
    }
    
    public class Students{
        String id;
        String label;
        String parentId;
        String parentName;
        String email;
        String phone;
        integer makeupHours;
    }
    
    public class NewBookingWrapper{
        List<TeacherAndCenter> entities;
        List<packageWrapper> packages;
    }
    public class TeacherAndCenter{
        String name;
        String id;
        String type;
        
    }
    public class packageWrapper{
        public String id;
        public String name;
        public String duration;
        public String type;
    }
    public class bookingNoteWrapper{
        public String title;
        public DateTime createdDate;
        public String Body;
        public String CreatedBy;
    }
    
    //Wrapper Class for list of teacher Working hours and map of teachers
    public class TeacherWorkingHours{
        public List<Teacher_Working_Hour__c> teachersHours;
        public Set<String> setOfTeachers;
    } 
    //Wrapper Class for list of Resource Working hours and map of Resources
    public class resourceWorkingHours{
        public List<Resource_Working_Hour__c> resourcesHours;
        public Set<String> setOfResources;
    }
    //Wrapper Class for Calendar
    public class Calendar{
        List<AureusCalendarController.Resources> listOfResources;
        List<AureusCalendarController.Events> listOfEvents;
        List<AureusCalendarController.Resources> listOfTeachersFilters;
        String minTime;
        String maxTime;
        List<AureusCalendarController.Events> teachersWorkingHours;
    }
    //Wrapper Class for Resource
    
    public class Resources{
        public String id;
        public String title;
        public List<AureusCalendarController.businessHour> businessHours;
    }
    //Wrapper class for businessHours
    public class businessHour{
        public string start ;
        public string end_c;
        public List<Integer> dow;    
        
    }
    
    //Wrapper class for Event 
    public class Events{
        public String id;
        public String title;
        public String resourceId;
        public String start;
        public String end_c;
        public String rendering;
        public String eventColor;
        public String eventTextColor;
        public Boolean overlap;
        public String className;
        public String Type;
        public String Status;
        public String Notes;
        public String parentId;
        public boolean editable;
        public String Individual;
        public String category;
    }
    
    //Wrapper class for Event Details 
    public class EventDetails{
        public String Id;
        public String name; 
        public String service;
        public String staffMember;
        public String staffMemberId;
        public String centerId;
        public String centerName;
        public String resource;
        public String dateAndTime;
        public Decimal duration;
        public Decimal price;
        public String parentFirstName;
        public String parentLastName;
        public String parentMobile;
        public String parentPhone;
        public String parentEmail;
        public String studentFirstName;
        public String studentLastName;        
        public String type;
        public String studentId;
        public String parentId;
        public String status;
        public String endDateTime;
        public String timeOfBooking;
        public string rType;
        public String eventDateTime;  
        public String teacherAttachmentId;     
        public String Individual; 
        
        public string enrolment;
        public string processType;
        public string processStatus;
        public string newPackage;
        public string newPackageName;
        public string processRequestDate;
        public string processEffectiveDate;
        public string noticeStartDate;
        public string noticeEndDate;
        public String requestedBy;
        
        public List<Subscription_Line_Item__c> subscriptionLineItemList;
        
        public String oldValue;
        public String newValue;
        
        // List for ContentNote of Booking Object
        public List<ContentNote> contentNoteList;
        
        // List for BookingHistory of Booking Object
        public List<BookingHistory> bookingHistoryList;
    }
    //Booking History Wrapper Class
    public class BookingHistory{
        String HistoryId;
        String BookingId;
        String DateOfHistory;
        String HistoryBy;
        String Description;
    }
    
    // wrapper class to return message with case 
    public class ProcessResult{
        public String msg;
        public String caseId;
    }
    public class UpgradeCaseCreation{
        public String invoiceId;
        public Decimal depositAmount;
        public Decimal lessonCharge;
        public Decimal total;
        public Enrolment__c enrolObj;
        public Boolean isSuccess = false;
    }
}