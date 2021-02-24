/*
Name    :  
Test Class  :        AureusCalendarControllerTest2
Component   :		 AureusCalendarCMP
*/
public with Sharing class AureusCalendarController{
    public String centerName{get;set;}
    public String teacherName{get;set;}
    public String instrumentName{get;set;}
    private String recordTypeTeacher;
    public List<Account> accListForCenter{get;set;}
    public List<Account> accListForTeacher{get;set;}
    public List<Account> accListForEmployee{get;set;}
    public String calView{get;set;}
    public static string caseId;
    //public String bookingStatus{get;set;}
    public String resourceId{get;set;}
    public String employeeId{get;set;}
    public AureusCalendarController(){
        accListForTeacher = new List<Account>();
        accListForEmployee = new List<Account>();
        recordTypeTeacher = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        caseId = ApexPages.currentPage().getParameters().get('caseId');
        calView = 'agendaDay';
    }
    
    
    public List<SelectOption> getCenters() {
        Id recordTypeCenter = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        accListForCenter = [SELECT id, Name FROM Account WHERE recordTypeId =: recordTypeCenter AND Centre_Status__c =: ConstantsClass.activeStatus ORDER BY Name];
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
        system.debug('accListForTeacher--->'+accListForTeacher);
        getTeacherByCenter();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Select Teacher' , 'Select Teacher'));
        options.add(new SelectOption('AllRosteredStaff' , 'All rostered staff'));
        options.add(new SelectOption('AllStaff' , 'All staff'));
        for(Account acc : accListForTeacher){
            options.add(new SelectOption(acc.id , acc.name));
        }
        
        if(accListForTeacher.size() > 0 && calView == 'agendaTwoDay'){
            teacherName = accListForTeacher[0].id;
        }else if(calView == 'agendaDay'){
            teacherName = 'AllRosteredStaff';
        }else{      
            teacherName = '';       
        }
        
        return options;
    }
    
    public void getTeacherByCenter(){
        system.debug('centerName---------->'+centerName);
        system.debug('accListForCenter'+accListForCenter.size());
         system.debug('accListForCenter'+accListForCenter);
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
        selectListForResource.add(new SelectOption('AllResource','All Studios'));
        // start :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson
        selectListForResource.add(new SelectOption('AllLesson','All Lesson Studios'));
        selectListForResource.add(new SelectOption('AllNonLesson','All Non-Lesson Studios'));
         // start :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson
                                                  
        if(String.isBlank(centerName)){
            centerName = accListForCenter[0].Id;
        }
        List<Resource__c> listOfResources = AureusCalendarControllerHelper.getListOfResource(centerName);
        for(Resource__c objResource :listOfResources){
            selectListForResource.add(new SelectOption(objResource.Id,objResource.Name));    
        }
        system.debug('selectListForResource-->'+selectListForResource);
        return selectListForResource;
    }
     /*Commented by jatin: 11-mar-2020: for employee Calendar not Deploye*/
    public void getEmployeeByCenter(){
        if(String.isBlank(centerName) && accListForCenter.size() > 0){
            centerName = accListForCenter[0].Id;
        }
        accListForEmployee  = PianoRentalEditCalendarController.getListOfEmployee(centerName,new set<string>());
         
    }
   
    //20-Jan-2020:get select list of Employees
    public List<SelectOption> getEmployeeList(){
        getEmployeeByCenter();
        List<SelectOption> selectListForEmployees = new List<SelectOption>();
        selectListForEmployees.add(new SelectOption('','Select Employee'));
        if(accListForEmployee != null && accListForEmployee.size() > 0){
            selectListForEmployees.add(new SelectOption('AllRosteredStaff' , 'All rostered staff'));
            selectListForEmployees.add(new SelectOption('AllStaff' , 'All staff'));
            for(Account objEmployee :accListForEmployee){
                selectListForEmployees.add(new SelectOption(objEmployee.Id,objEmployee.Name));    
            }
            if(accListForEmployee.size() > 0 && calView == 'agendaTwoDay'){
                employeeId = accListForEmployee[0].id;
            }else if(calView == 'agendaDay'){
                employeeId = 'All Employees';
            }else{      
                employeeId = '';       
            }
        }
        
        return selectListForEmployees;
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
        List<Events> eventsList = new List<Events>();
        List<Events> validationBusinessHours = new List<Events>();
        List<String> weekDays = new List<String>();
        Map<String, String> mapOfweekDays = new Map<String, String>();
        List<Center_Working_Hours__c> centerWorkingHours = new List<Center_Working_Hours__c>();
        TeacherWorkingHours workingHoursOfTeacher = new TeacherWorkingHours();
        ResourceWorkingHours workingHoursOfResource = new ResourceWorkingHours();
        List<Account> listOfAcc = new List<Account>();
        List<Resource__c> listOfResource = new List<Resource__c>();
        List<Resources> listOfResources = new List<Resources>();
        List<Resources> listOfTeachersFilter = new List<Resources>();
        Calendar objCalendar = new Calendar();
        Map<String, List<businessHour>> businessHours = new Map<String, List<businessHour>>();
        
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
            //System.debug('workingHoursOfTeacher'+workingHoursOfTeacher);
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
                        Resources objResource = new Resources();
                        objResource.id = objAcc.id;
                        objResource.title = objAcc.name;
                        
                        listOfTeachersFilter.add(objResource);
                    }
                }
            }
            
            if(teacherId != 'AllStaff' && teacherId != 'AllRosteredStaff'){
                teach.add(teacherId);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                
                eventsList.addAll(bookingLst);

                //Get List of teacher on selected center
                listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId, teacherId);
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                        
                    }
                }
            }else if(teacherId != 'AllRosteredStaff' && teacherId == 'AllStaff' && String.isBlank(instrument)){
                teach.addAll(workingHoursOfTeacher.setOfTeachers);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of teacher on selected center
                listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId);
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                        
                    }
                }
            }else if(teacherId == 'AllRosteredStaff' && teacherId != 'AllStaff' && String.isBlank(instrument)){
                teach.addAll(workingHoursOfTeacher.setOfTeachers);
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                if(String.isNotBlank(centerId) && teach.size() > 0){
                    //Get List of teacher on selected center and teacher
                    listOfAcc = AureusCalendarControllerHelper.getListOfTeacher(centerId, teach);
                }
                
                if(listOfAcc.size() > 0){
                    for(Account objAcc : listOfAcc){
                        listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                        
                        
                    }
                }
            }else if((teacherId == 'AllRosteredStaff' || teacherId == 'AllStaff') && String.isNotBlank(instrument)){
                teach.addAll(workingHoursOfTeacher.setOfTeachers);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
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
                        
                        listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
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
            // start :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
            //   if(resourceId != 'AllResource' && resourceId != 'AllRosteredResource'){
            if(resourceId != 'AllResource' && resourceId != 'AllRosteredResource' && resourceId != 'AllLesson' && resourceId != 'AllNonLesson'  ){
            // end :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
                resourceIds.add(resourceId);
                
                //get Events list of teacher/resource on perticular date or perticular range                 
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //get List of resources according to the center Id and Resource Id
                listOfResource = AureusCalendarControllerHelper.getListOfResource(centerId, resourceId);
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                        
                        listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                    }
                }
            } // start :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
            //else if(resourceId != 'AllRosteredResource' && resourceId == 'AllResource'){
            else if(resourceId != 'AllRosteredResource' &&  resourceId != 'AllLesson' && resourceId != 'AllNonLesson' && resourceId == 'AllResource'){
            // end :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
           
                resourceIds.addAll(workingHoursOfResource.setOfResources);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of resources according to the center
                listOfResource = AureusCalendarControllerHelper.getListOfResource(centerId);
                
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                        listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                    }
                }
            }
            // start :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
            // else if(resourceId == 'AllRosteredResource' && resourceId != 'AllResource'){
            else if(resourceId == 'AllRosteredResource'  && resourceId != 'AllLesson' && resourceId != 'AllNonLesson' && resourceId != 'AllResource'){
            // end :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
                resourceIds.addAll(workingHoursOfResource.setOfResources);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of resources according to the center and multiple resources
                listOfResource = AureusCalendarControllerHelper.getListOfResource(centerId, resourceIds);
                
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                         listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                    }
                }
            }
            // start :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
            else if(resourceId != 'AllRosteredResource'  && resourceId == 'AllLesson' && resourceId != 'AllNonLesson' && resourceId != 'AllResource'){
                resourceIds.addAll(workingHoursOfResource.setOfResources);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of resources according to the center and multiple resources
                listOfResource = AureusCalendarControllerHelper.getListOfAvailableAureusLessonResource(centerId,true);
                
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                          listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                    }
                }
            }
            // end :Nishi - 30 -jul-2020 : for show all Availabel lesson Resource we added new value  AllLesson mangge this value
            // start :Nishi - 31 -jul-2020 : for show all non Availabel lesson Resource we added new value  All Non Lesson mangge this value
            else if(resourceId != 'AllRosteredResource'  && resourceId != 'AllLesson' && resourceId == 'AllNonLesson' && resourceId != 'AllResource'){
                resourceIds.addAll(workingHoursOfResource.setOfResources);
                
                //get Events list of teacher/resource on perticular date or perticular range
                List<Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
                eventsList.addAll(bookingLst);
                
                //Get List of resources according to the center and multiple resources
                listOfResource = AureusCalendarControllerHelper.getListOfAvailableAureusLessonResource(centerId,false);
                
                if(listOfResource.size() > 0){
                    for(Resource__c objAcc : listOfResource){
                            listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                    }
                }
            }
            // end :Nishi - 31 -jul-2020 : for show all non Availabel lesson Resource we added new value  All Non Lesson mangge this value
            
        }
        objCalendar.listOfResources = listOfResources;
        objCalendar.listOfEvents = eventsList;
        objCalendar.teachersWorkingHours = new List<Events>();
        objCalendar.listOfTeachersFilters = new List<Resources>();
        objCalendar.listOfTeachersFilters = listOfTeachersFilter;
        objCalendar.teachersWorkingHours = validationBusinessHours;
       ////system.debug('validationBusinessHours'+validationBusinessHours);
       ////system.debug('objCalendar.teachersWorkingHours'+objCalendar.teachersWorkingHours);
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
    
    private static List<Events> getWorkingHoursResource(ResourceWorkingHours workingHoursOfResource, String resourceId, Map<String, String> mapOfweekDays){
        List<Events> eventsList = new List<Events>();
        Events currentEvent ;
        if(workingHoursOfResource.resourcesHours.size() > 0){
            for(Resource_Working_Hour__c currentResource : workingHoursOfResource.resourcesHours){
                currentEvent = new Events();
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
    
    //@13-Nov-2019:  Jatin : for get Teacher working hours for update enrollment new Effective dates
    @RemoteAction 
    public static Set<string> getNewEffectiveDateSlots(String centerId, String teacherId){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherWorkingHoursQuery = 'SELECT Id, Name, Teacher_Name__c, Teacher_Name__r.Name, Teacher_Name__r.Status__c, Center_Name__c, Active__c, Working_Day__c, Start_Time__c, End_Time__c, Break_Time__c FROM Teacher_Working_Hour__c';
        //teacher working hours should be active and it should not be break hour and its start time and end time should not be null
        teacherWorkingHoursQuery += ' WHERE Active__c = true AND Break_Time__c = false AND Start_Time__c != NULL AND End_Time__c != NULL AND Teacher_Name__r.Status__c =: teacherWorkingStatus AND ';
        //Belongs to a perticular center
        if(String.isNotBlank(centerId)){
            teacherWorkingHoursQuery += 'Center_Name__r.Id =: centerId';
        }
        //belongs to perticular teacher
        if(String.isNotBlank(teacherId)){
            teacherWorkingHoursQuery += ' AND Teacher_Name__c =: teacherId';
        } 
        teacherWorkingHoursQuery += ' AND Teacher_Name__c != NULL';
        List<Teacher_Working_Hour__c> listOfTeacherWorkingHours = database.query(teacherWorkingHoursQuery);
        Set<string> weekdays = new Set<String>();
        if(listOfTeacherWorkingHours != NULL && listOfTeacherWorkingHours.size() > 0){
            for(Teacher_Working_Hour__c objTeacher_Working_Hour : listOfTeacherWorkingHours){
                weekdays.add(objTeacher_Working_Hour.Working_Day__c);
            }
        }
        ///system.debug('@@weekdays'+weekdays);
        return weekdays;
    }
    
   @RemoteAction 
    public static ProcessResult updateBooking(String bookingId, String startDate, String endDate,
     String teacherId, String placeholder, String isFuture, String redirectCase, String caseId,
     String isResourceId){
        
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
            bookingObjList = [SELECT Id, Name, Enrolment__c,Package__c , Student__c, Student__r.Name, Resource__c,Center__r.Organisation__r.Name,
                              Enrolment__r.Teacher__c, Individual_Booking__c, Type__c, Enrolment__r.Lesson_Day__c, 
                              Enrolment__r.Lesson_Start_time__c, Booking_Date__c, Start_Time__c, End_Time__c, 
                              Status__c, Center__c, Teacher_Account__c, Teacher_Account__r.Name, Lesson_Type__c,
                              Duration__c, RecordType.Name, Category__c, Appointment_Day__c,Enrolment__r.Resource__c
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
           //system.Debug('isResourceId'+isResourceId);
            //start: nishi: 31-Jul-2020: for udpate resource if isResourceId is true other wise we update teacher
            if(isResourceId =='true'){
                    bookingObj.Resource__c = teacherId;
            }else{
            //end: nishi: 31-Jul-2020: for udpate resource if isResourceId is true other wise we update teacher
                if(String.isNotBlank(teacherId)){
                    //Start: 31-jul-2020 Nishi: if Booking Lesson_Type__c equals to In Center and resource is blank.
                    //if teacher is change then related teacher working hrs resource Id we are update in Booking Resource field 
                     //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                    /*if(//bookingObj.Lesson_Type__c != ConstantsClass.Online &&
                     (string.isBlank(bookingObj.Resource__c) ||
                    string.isNotBlank(bookingObj.Resource__c) && teacherId != bookingObj.Teacher_Account__c)){
                        if(String.isNotBlank(teacherId)){        
                            List<String> weekDay =  new List<String>(); 
                            weekDay.add(startDateTime.format('EEE'));     
                            AureusCalendarController.TeacherWorkingHours teachersHours = AureusCalendarControllerHelper.getTeacherWorkingHours(bookingObj.Center__c, teacherId, weekDay );   
                               
                            if(teachersHours.setOfTeachers.size() > 0 && teachersHours.teachersHours.size() > 0){      
                                for(Teacher_Working_Hour__c th : teachersHours.teachersHours){     
                                    if(teachersHours.setOfTeachers.contains(th.Teacher_Name__c)){      
                                        bookingObj.Resource__c  = th.Resource__c;
                                    }      
                                }      
                            }   
                        }
                    }*/
                     //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
                    //end: 31-jul-2020 Nishi: if Booking Lesson_Type__c equals to In Center and resource is blank.
                    //if teacher is change then related teacher working hrs resource Id we are update in Booking Resource field 

                    if(bookingObj.RecordType.Name == lessonRecordType){
                        bookingObj.Prev_Teacher__c = bookingObj.Teacher_Account__r.Name;
                        bookingObj.Teacher_Account__c = teacherId;
                    }else if(bookingObj.RecordType.Name == facilityRecordtype){
                        bookingObj.Resource__c = teacherId;
                    }
                    
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
                /*if(bookingObj.Enrolment__r.Lesson_Day__c != dateChange.format('EEEE')){
                    isDayChange = true;
                }*/

                if(bookingObj.Booking_Date__c != dateChange.date()){
                    isDayChange = true;
                }
                
                if(String.isNotBlank(bookingObj.Enrolment__c)){
                    enrolObj = fetchEnrolment(bookingObj.Enrolment__c);
                    studentId = enrolObj.student__c; 
                    oldTeacherId = enrolObj.teacher__c;
                    lessonDay = enrolObj.Lesson_Day__c; 
                    oldDuration = Integer.valueOf(enrolObj.Package__r.duration__c);  
                    startTime = enrolObj.Lesson_start_Time__c; 
                    //Start: 31-jul-2020 Nishi: if Booking Lesson_Type__c equals to In Center and resource is blank.
                    //if teacher is change then related teacher working hrs resource Id we are update in Booking Resource field 
                     //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
                    /*if(//enrolObj.Lesson_Mode__c != ConstantsClass.Online &&//
                     (string.isBlank(enrolObj.Resource__c) || 
                        string.isNotBlank(enrolObj.Resource__c) && oldTeacherId != teacherId)){
                        if(String.isNotBlank(teacherId)){        
                            List<String> weekDay =  new List<String>();     
                            weekDay.add(dateChange.format('EEE'));     
                            AureusCalendarController.TeacherWorkingHours teachersHours = AureusCalendarControllerHelper.getTeacherWorkingHours(enrolObj.Center__c, teacherId, weekDay );   
                            if(teachersHours.setOfTeachers.size() > 0 && teachersHours.teachersHours.size() > 0){      
                                for(Teacher_Working_Hour__c th : teachersHours.teachersHours){     
                                    if(teachersHours.setOfTeachers.contains(th.Teacher_Name__c)){      
                                        enrolObj.Resource__c  = th.Resource__c;
                                    }      
                                }      
                            }   
                        }
                    }
                     //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                    */
                    //end: 31-jul-2020 Nishi: if Booking Lesson_Type__c equals to In Center and resource is blank.
                    //if teacher is change then related teacher working hrs resource Id we are update in Booking Resource field 
                    if(String.isNotBlank(teacherId)){
                        enrolObj.Teacher__c  = teacherId;
                    }
                    if(isDayChange){
                        enrolObj.Lesson_Day__c = dateChange.format('EEEE');
                    }
                    if(String.isNotBlank(startDate)){
                        enrolObj.Lesson_Start_time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0); 
                    } 
                    //Start : added by Nishi : 4-Feb-2021 :Aureus Q1 2021: for update Waitlist_Status__c   emailed to  Assigned
                    if(string.isnotBlank(enrolObj.Waitlist_Status__c) && string.isnotBlank(enrolObj.Preferred_Day__c) && string.isnotBlank(enrolObj.Preferred_Teacher__c) 
                        && enrolObj.Preferred_End_time__c != null && enrolObj.Preferred_Start_Time__c != null 
                        && (enrolObj.Lesson_Start_time__c >= enrolObj.Preferred_Start_Time__c && enrolObj.Lesson_Start_time__c < enrolObj.Preferred_End_time__c)
                        && enrolObj.Waitlist_Status__c.equalsIgnoreCase('Emailed') && enrolObj.Lesson_Day__c.equalsIgnoreCase(enrolObj.Preferred_Day__c) 
                        && enrolObj.Teacher__c == enrolObj.Preferred_Teacher__c){
                        enrolObj.Waitlist_Status__c ='Assigned';
                    }
                    //end : added by Nishi : 4-Feb-2021 :Aureus Q1 2021: for update Waitlist_Status__c   emailed to  Assigned when center admin reschadle all bookings according to Preferred time slot
                }
                
                if(String.isNotBlank(enrolObj.Id)){
                    UPDATE enrolObj;
                }
                
               //system.debug('####dateChange.date()'+dateChange.date());
                /*Section of reschedule all regular booking*/
                if(String.isNotBlank(bookingObj.Enrolment__c)){
                    RescheduleForAllFutureBookings allReschedule = new RescheduleForAllFutureBookings(isDayChange, enrolObj, dateChange.date(), bookingObj.Booking_Date__c);

                    /*if(String.isNotBlank(studentId) && String.isNotBlank(oldTeacherId) && oldDuration > 0 && startTime != NULL && String.isNotBlank(lessonDay)){
                        AureusCalendarControllerHelper.processBookingsAfterDateChange(enrolObj, dateChange.date(), bookingObj.Booking_Date__c, studentId, oldTeacherId, oldDuration, startTime, lessonDay);
                    }*/
                    
                }/*else{
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
                }*/
                /*End of Section of reschedule all regular booking*/
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
                     //start: commented by nishi: 31-Jul-2020: for udpate resource if isResourceId is true other wise we update teacher
                    if(isResourceId =='true'){
                        bookingObj.Resource__c = teacherId;
                    }else{
                     //start: commented by nishi: 31-Jul-2020: for udpate resource if isResourceId is true other wise we update teacher
        
                        if(String.isNotBlank(teacherId) && teacherId != bookingObj.Teacher_Account__c && bookingObj.RecordType.Name == lessonRecordType){
                            busyBookObj.Teacher_Account__c = teacherId;
                        }else if(bookingObj.RecordType.Name == facilityRecordtype){
                            bookingObj.Resource__c = teacherId;
                        }
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
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                      //system.Debug('@@The following error has occurred.');                    
                      //system.Debug('@@@@'+err.getStatusCode() + ': ' + err.getMessage());
                      //system.Debug('@@@@Account fields that affected this error: ' + err.getFields());
                    }
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
    

 // NISHI: 30-JUL-2020: for update resource Id to all future booking according to new selected resource
    
   @RemoteAction 
   public static ProcessResult updateResourceBooking(String bookingId, String startDate, String endDate,
        String resourceId, String placeholder, String isFuture, 
        String redirectCase, String caseId){
       
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
                             Duration__c, RecordType.Name, Category__c, Appointment_Day__c,resource__c
                             FROM Booking__c WHERE Id =: bookingId];
       }
       if(bookingObjList.size() > 0 && isFuture == 'false'){
           bookingObj = bookingObjList[0];
           bookingObj.resource__c = resourceId;
           
       }else if(bookingObjList.size() > 0 && isFuture == 'true'){
           bookingObj = bookingObjList[0];
            Enrolment__c enrolObj = new Enrolment__c();
            if(String.isNotBlank(bookingObj.Enrolment__c)){
                enrolObj = fetchEnrolment(bookingObj.Enrolment__c);
                enrolObj.resource__c = resourceId;
                UPDATE enrolObj;
                if(bookingObj.Booking_Date__c != NULL){
                    Set<string> bookingType = new Set<string>{ConstantsClass.bookTypeRegular,ConstantsClass.typeMakeup};
                    Date maxDate = getMaxDateOfEnrolmentBookings(bookingObj.Enrolment__c);
                    Integer lastDayOfMonth = Date.daysInMonth(maxDate.year(), maxDate.month());
                    maxDate = Date.newInstance(maxDate.year(), maxDate.month(), lastDayOfMonth);
                    if(String.isNotBlank(bookingObj.Enrolment__c) && bookingObj.Booking_Date__c != NULL){
                            List<Booking__c> bookingListToDelete = new List<Booking__c>();
                            List<Booking__c> bookingsToUpsert = new List<Booking__c>();
                            for(Booking__c bookObj : [SELECT Id, Type__c, Status__c, Booking_Date__c,resource__c,Lesson_Type__c,Is_Lesson_Type_Change__c, Available_Make_up_Units__c, Duration__c, Make_up_Utilize_Bookings__c, 
                                Teacher_Account__r.Employee_Duty_Type__c FROM Booking__c 
                                WHERE Enrolment__c = :bookingObj.Enrolment__c 
                                AND Booking_Date__c >= :bookingObj.Booking_Date__c
                                AND Type__c In:bookingType
                                AND Status__c !=:ConstantsClass.statusCanceled
                                ]){
                                bookObj.resource__c = resourceId;
                                bookingsToUpsert.add(bookObj);
                            }
                            if(bookingsToUpsert.size() > 0){
                                UPDATE bookingsToUpsert;
                            }
                    } 
                }
            }
       }
       
       if(bookingObj != NULL && isFuture == 'false'){
           bookingList.add(bookingObj);
           //oldBookList.add(oldBooking);
       }
       if(bookingList.size() > 0){
           Database.SaveResult[] saveResults = Database.update(bookingList, false);
           for(Database.SaveResult sr : saveResults){
              
               if(!sr.isSuccess()){
                   // Operation failed, so get all errors                
                   for(Database.Error err : sr.getErrors()) {
                      //system.debug('@@The following error has occurred.');                    
                      //system.debug('@@@@'+err.getStatusCode() + ': ' + err.getMessage());
                      //system.debug('@@@@Account fields that affected this error: ' + err.getFields());
                   }
                   isError = true;
               }
           }
       }
       if(isError){
           objResult.msg = 'Some Error Occured';
       }else{
           /*if(bookingList.size() > 0 && bookingList[0].Type__c != ConstantsClass.typeBusy && redirectCase == 'true'){
               Case objCase =  AureusCalendarControllerHelper.createCase(caseId, bookingList[0].id,'Reschedule');
               objResult.caseId = objCase.Id;
           }*/
           objResult.msg = 'Success';
       }
       
       return objResult;
   }
  // get maximum booking date related to enrolment
   public static Date getMaxDateOfEnrolmentBookings(String enrolId){
    Date maxDate;
    List<AggregateResult> AggregateResultList = [select Max(Booking_Date__c)maxDate from Booking__c where Enrolment__c =: enrolId AND Type__c =: ConstantsClass.typeRegular];
    if(AggregateResultList.size() > 0){
        for(AggregateResult agg : AggregateResultList){ 
            maxDate = (Date)agg.get('maxDate');
        }
    }
    return maxDate;
}
//end: NISHI: 30-JUL-2020: for update resource Id to all future booking according to new selected resource

    
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
            bookingList = [SELECT id, Name,Lesson_Type__c,Online_Lesson_URL__c,Online_Lesson_Passcode__c, Booking_Date__c, Start_Time__c, End_Time__c, Duration__c,Type__c, Status__c, Price__c, Teacher_Account__r.Name, Package__r.Name, Resource__c, Resource__r.Name, 
                           Student__r.FirstName,  Student__r.LastName, Student__r.Parent__r.FirstName, Student__r.Parent__r.LastName, Student__r.Parent__r.PersonMobilePhone, Student__r.PersonMobilePhone, Student__r.Phone, Student__r.PersonEmail,
                           Student__r.Parent__r.Phone, Student__r.Parent__r.PersonEmail, Student__r.id, RecordType.Name, Individual_Booking__c,  Student__r.Also_a_Student__c, Student__r.Parent__r.Also_a_Student__c, Enrolment__c, Enrolment__r.Package_Process_Type__c, 
                           Enrolment__r.New_Package_Id__r.Name, Enrolment__r.Package_Process_Request_Date__c, Enrolment__r.Effective_Date__c, Enrolment__r.Notice_Period_Start_Date__c, Enrolment__r.Notice_Period_End_Date__c, Enrolment__r.Package_Process_Status__c,
                           Enrolment__r.Advance_Action_Requested_By__r.Name, Center__c, Center__r.Name, Remarks__c 
                           FROM Booking__c WHERE id =: bookingId];
            //System.debug('@@@bookingList'+bookingList);
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
                ed.resourceName = bookingObj.Resource__r.Name;
                ed.resourceId = bookingObj.Resource__c;
                ed.centerId = bookingObj.center__c;
                ed.centerName = bookingObj.center__r.Name;
                ed.dateAndTime = bookingDate+' at '+bookingTime;
                ed.duration = bookingObj.Duration__c;
                ed.price = bookingObj.Price__c;
                ed.type = bookingObj.Type__c;
                ed.placeholder = bookingObj.Remarks__c;
                ed.studentFirstName = bookingObj.Student__r.FirstName;
                ed.studentLastName = bookingObj.Student__r.LastName;
                ed.lessonType=bookingObj.Lesson_Type__c;// added by ravi on 3rd july 2020 for online lesson 
                ed.lessonPassCode=bookingObj.Online_Lesson_Passcode__c;// added by ravi on 8 july 2020 for online lesson 
                ed.lessonURL=bookingObj.Online_Lesson_URL__c;// added by ravi on 8 july 2020 for online lesson 
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
                 //Start: added by nishi: 30-Jul-2020: for get all Available_For_Aureus_Lesson__c resources
                ed.listOfAvailableResources = AureusCalendarControllerHelper.getListOfAvailableAureusLessonResource(bookingObj.center__c,true); 
                 //end: added by nishi: 30-Jul-2020: for get all Available_For_Aureus_Lesson__c resources
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
    public static ProcessResult cancelBooking(String bookingId, String cancelReason, String makeUpReason, String makeupRemark, 
    String redirectCase, string caseId, String isFuture){
        ProcessResult objResult = new ProcessResult();
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Booking__c> placeholderList = new List<Booking__c>();
       //system.debug('@@bookingId'+bookingId);
      //system.debug('@@cancelReason'+cancelReason);
       //system.debug('@@makeUpReason'+makeUpReason);
      //system.debug('@@makeupRemark'+makeupRemark);
       //system.debug('@@redirectCase'+redirectCase);
      //system.debug('@@caseId'+caseId);
      //system.debug('@@isFuture'+isFuture);
        
        //to check that booking is adhoc and it should be fifth
        Boolean adhocInvoiceCheck = false;
        
        Boolean isNoMakeup = false;
        if(makeUpReason == 'NoMakeUpForToday'){
            isNoMakeup = true;
            makeUpReason = '';
        }
        //String msg = '';
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Status__c, Type__c, Make_up_Utilize_Bookings__c, Center__c,Group_Class__c,
                           Make_up_Expiry_Date__c, Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, 
                           Make_up_Credit_Note__c, Start_Time__c, Duration__c, Student__c, Student__r.Name, 
                           Student__r.Parent__c, End_Time__c, Available_Make_up_Units__c, Cancellation_Reason__c, Is_Complimentary_Credit__c,
                           RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c, Is_fifth_booking__c FROM Booking__c 
                           WHERE Id =: bookingId];
            if(bookingList.size() > 0){
               //system.debug('@@@bookingList'+bookingList);
                Date expiryDate;
                // @@jatin : 17-dec-2019: added Booking type is 'Group lesson' then this booking work same as regular booking 
                if(bookingList[0].Type__c == ConstantsClass.typeRegular || 
                    bookingList[0].Type__c == ConstantsClass.typePianoViewing || 
                    bookingList[0].Type__c == ConstantsClass.groupLessonTypeBooking   ||
                    bookingList[0].Type__c == ConstantsClass.typeAdhoc){
                      
                    bookingList[0].Status__c = ConstantsClass.statusCanceled;
                    
                    //Check that booking is adhoc and its Invoice status is paid -- @jatin Due to change in Functionality by julius
                    if((bookingList[0].Type__c == ConstantsClass.typeAdhoc /*&& checkAdhocIsPaid(bookingList[0].Id)*/) 
                        || bookingList[0].Type__c == ConstantsClass.typeRegular
                         // @@jatin : 17-dec-2019: added Booking type is 'Group lesson' then this booking work same as regular booking 
                        || bookingList[0].Type__c == ConstantsClass.groupLessonTypeBooking){
                        if(bookingList[0].Booking_Date__c != null){
                            expiryDate = bookingList[0].Booking_Date__c.addDays(120);
                        }
                        if(isNoMakeup == false && makeUpReason != 'Student MC'){
                            bookingList[0].Available_Make_up_Units__c = bookingList[0].Duration__c; 
                            bookingList[0].Make_up_Expiry_Date__c  = expiryDate;
                        }
                        
                        
                        
                        if(String.isNotBlank(makeUpReason) && (makeUpReason == ConstantsClass.makeupReasonOther 
                        ||  makeUpReason == ConstantsClass.makeupAdminException) 
                            && String.isNotBlank(makeupRemark)){
                            bookingList[0].Makeup_Reason__c =  makeUpReason;
                            bookingList[0].Make_up_Credit_Note__c = makeupRemark;
                        }else if(String.isNotBlank(makeUpReason)){
                            bookingList[0].Makeup_Reason__c =  makeUpReason;
                        }    
                    }
                }else if(bookingList[0].Type__c == ConstantsClass.typeTrial 
                    || bookingList[0].Type__c == ConstantsClass.typeMakeup
                    || bookingList[0].Type__c == ConstantsClass.typeBusy ){
                    if(bookingList[0].Type__c == ConstantsClass.typeBusy && isFuture == 'true'){
                        if(!cancelAllFutureBusyBookings(getFutureBusyBookings(bookingList[0]))){
                            objResult.msg = 'Error';
                        }
                    }
                    bookingList[0].Status__c = ConstantsClass.statusCanceled;
                    
                    if(bookingList[0].Type__c == ConstantsClass.typeMakeup){
                        // added by nishi: 24-Feb-2021:start : Cancelling a complimentary credit will add back the complimentary credit on the same record
                        if(bookingList[0].Is_Complimentary_Credit__c){
                            List<String> makeupReferenceList = new List<String>();
                            Set<String> complementryCreditIds = new Set<String>();
                            List<Booking__c> bookingListObj = new List<Booking__c>();
                            List<Booking__c> bookingUpdatedList = new List<Booking__c>();
                            Map<string,Complementary_Credit__c> complementaryCreditUpdatedMap = new Map<string,Complementary_Credit__c>();
                            if(String.isNotBlank(bookingList[0].Make_up_Utilize_Bookings__c)){
                                makeupReferenceList.addAll(bookingList[0].Make_up_Utilize_Bookings__c.split(';'));
                                if(makeupReferenceList != null && makeupReferenceList.size() > 0){
                                    for(String makeup : makeupReferenceList){
                                        if(String.isNotBlank(makeup)){
                                            complementryCreditIds.add(makeup.split('-')[0]);
                                        }
                                    }
                                }    
                                if(complementryCreditIds != null && complementryCreditIds.size() > 0){
                                    List<Complementary_Credit__c> listOfComplementaryCredit = [SELECT Credit_Apply_date__c, Credit_Expiry_date__c, Credit_Reason__c, Enrolment__c, Teacher_Name__c, Parent__c, Available_credit_Min__c, Package_Name__c, Is_Active__c, Name, Id 
                                                                                                FROM Complementary_Credit__c
                                                                                                WHERE Id IN: complementryCreditIds];
                                    if(listOfComplementaryCredit != null && listOfComplementaryCredit.size() > 0){
                                        Map<string,Decimal> complementaryCreditMinsMap = new Map<string,Decimal>();
                                        for(Complementary_Credit__c booking : listOfComplementaryCredit){
                                            for(String currentMakeup : makeupReferenceList){
                                                if(currentMakeup.contains(booking.Id)){
                                                    decimal complementaryCreditMins = 0;
                                                    if(complementaryCreditMinsMap.containsKey(booking.Id)){
                                                        complementaryCreditMins = complementaryCreditMinsMap.get(booking.Id);
                                                    }
                                                    complementaryCreditMins += Decimal.valueOf(currentMakeup.split('-')[1]);
                                                    complementaryCreditUpdatedMap.put(booking.Id,new Complementary_Credit__c(Id = booking.Id, 
                                                    Available_credit_Min__c = booking.Available_credit_Min__c + complementaryCreditMins));
                                                    complementaryCreditMinsMap.put(booking.Id,complementaryCreditMins);
                                                }
                                            }
                                        }
                                    }
                                }
                                if(complementaryCreditUpdatedMap.size() > 0){
                                    update complementaryCreditUpdatedMap.values();
                                }
                                bookingList[0].Make_up_Utilize_Bookings__c = '';
                            }
                        }// added by nishi: 24-Feb-2021:start : Cancelling a complimentary credit will add back the complimentary credit on the same record
                        else{
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
                                    bookingListObj = [SELECT Id, Available_Make_up_Units__c, Make_up_Expiry_Date__c
                                    FROM Booking__c WHERE Make_up_Expiry_Date__c >= TODAY AND Id IN: bookingIds];
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
                }
                bookingList[0].Cancellation_Reason__c = cancelReason;
                Database.SaveResult saveResult = Database.update(bookingList[0], false);
                
                if (saveResult.isSuccess()) {
                    Boolean isError = false;
                   //system.debug('@@@bookingList'+bookingList[0]);
                    List<Booking__c> bookList = new List<Booking__c>();
                    bookList.add(bookingList[0]);
                    objResult.msg = 'Event Cancelled Successfully';
                    String parentId='';
                    
                    if(bookList[0].Type__c == ConstantsClass.typeRegular ){
                        placeholderList.addAll(createPlaceholder(bookList, 'cancel', ''));
                    }
                    /// @@jatin: 1-jan-2020 for create placeholder for group lesson
                    if(bookList[0].Type__c == ConstantsClass.groupLessonTypeBooking ){
                        placeholderList.addAll(createPlaceholderForGroupClass(bookList, 'cancel', ''));
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
                      //system.debug('@@@The following error has occurred. '+err.getStatusCode() + ' : ' + err.getMessage());
                        objResult.msg = 'The following error has occurred. '+err.getStatusCode() + ' : ' + err.getMessage();
                    }
                }
                
                
            }
        }
        return objResult;
    }
    
     Public static List<Booking__c> createPlaceholderForGroupClass(List<Booking__c> bookingObjList, String origin, String newSlot){
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
            placeholderObj.status__c = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = bookingCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c = bookingCurrentObj.Center__c;
            if(origin == 'reschedule'){
                placeholderObj.remarks__c = 'placeholder booking for rescheduling '+ bookingCurrentObj.Student__r.Name + ' booking to ' + newSlotTime.format('h:mm a');
            }
            if(origin == 'cancel'){
                placeholderObj.remarks__c = 'placeholder booking for cancelling '+ bookingCurrentObj.Student__r.Name + ' booking';
            }
             placeholderObj.recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
             placeholderObj.Group_Class__c = bookingCurrentObj.Group_Class__c;
            placeholderList.add(placeholderObj);
        }
        return placeholderList;
        
    }
    
    @RemoteAction
    public static Boolean createAdhocBookings(String packageId, String centerId, String teacherId, String studentId, String recurring, String bookingDate,
    String lessonMode,String resourceId,String enrolmentId){
        Country__c countryOfCentre = new Country__c();
        Organisation__c organisationOfCentre = new Organisation__c();
        Boolean isOssiaOrganization = false;
        Boolean isSuccess = false;
        Double totalAmount = 0;
        string recordTypeCustomer = ConstantsClass.recordTypeCustomer;
        string recordTypeCentre = ConstantsClass.centerRecTypeName;
        String stripeId = '';
        List<Booking__c> bookingList = new List<Booking__c>();
        String parentId ;
        List<Account> accList = new List<Account>();
        if(String.isNotBlank(studentId) && String.isNotBlank(centerId)){
            accList = new List<Account>([SELECT Id, Name, Parent__c, RecordType.Name ,  Also_a_Student__c, Stripe_Customer_Id__c, Parent__r.Stripe_Customer_Id__c, 
                                         Country__c, Country__r.Id, Country__r.Tax_Rate__c, Country__r.Stripe_Base_Url__c, Country__r.Stripe_Secret_Key__c, 
                                         Country__r.Currency_Code__c,Organisation__r.Name,Organisation__r.Id, Organisation__r.Tax_Rate__c, Organisation__r.Stripe_Base_Url__c,
                                          Organisation__r.Stripe_Secret_Key__c, 
                                         Organisation__r.country__r.Currency_Code__c
                                          FROM Account 
                                         WHERE (RecordType.Name =: recordTypeCustomer AND Id =: studentId) OR Id =: centerId]);
        }
        
        if(accList.size() > 0){
            for(account acc : accList){
                if(acc.RecordType.Name == recordTypeCustomer){
                    if(String.isNotBlank(acc.Parent__c) && acc.Also_a_Student__c == false){
                        parentId = acc.Parent__c;
                        stripeId = acc.Parent__r.Stripe_Customer_Id__c;
                       ////system.debug('stripeId...'+stripeId);
                    }else if(String.isBlank(acc.Parent__c) && acc.Also_a_Student__c == true){
                        parentId = acc.Id;
                        stripeId = acc.Stripe_Customer_Id__c;
                        //System.debug('parent stripeId...'+stripeId);
                    }    
                }else if(acc.RecordType.Name == recordTypeCentre){
                    countryOfCentre = acc.Country__r;
                    organisationOfCentre = acc.Organisation__r;//@nishi 24 Aug 2020,Organisation wise charge as per new logic
                    // added by nishi:17-aug-2020: for related to Ossia Organisation Center  then we manage facility fees
                    if(string.isnotBlank(acc.Organisation__c) && string.isnotBlank(acc.Organisation__r.Name) && 
                        acc.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name) ){
                            isOssiaOrganization= true;
                    }
                    // added by nishi:17-aug-2020: for related to Ossia Organisation Center  then we manage facility feee
                }
            }
            
        }
        
        List<Package__c> listOfPackage =[SELECT Name, Id, Unit_Fee__c, Duration__c//,facility_Fee__c
                                         FROM Package__c
                                         Where id =: packageId];
        
        Invoice__c objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.dueStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                    Invoice_Date__c =system.today(), Parent_Account__c = parentId,Center__c=centerId);
        //insert objectOfInvoice;
        if(listOfPackage.size() > 0){
           //system.debug(bookingDate);
            Double gstAdded = 0;
            Date bookDate = Date.newInstance(Integer.valueOf(bookingDate.split('T')[0].split('-')[0]), Integer.valueOf(bookingDate.split('T')[0].split('-')[1]), Integer.valueOf(bookingDate.split('T')[0].split('-')[2]));
            if(isOssiaOrganization){
                 bookingList = AureusCalendarControllerHelper.createAppointmentForAdhoc(listOfPackage[0], teacherId, studentId, centerId, Integer.valueOf(recurring), bookingDate,
                                                                                  parentId,lessonMode,resourceId,enrolmentId); //add ParentId
            }else{
                 bookingList = AureusCalendarControllerHelper.createAppointmentForAdhoc(listOfPackage[0], teacherId, studentId, centerId, Integer.valueOf(recurring), bookingDate,
                                                                                    parentId,lessonMode,resourceId,''); //add ParentId
            }
                                                                              
            Boolean isChecked = validateBookingTime(bookingList[0].Teacher_Account__c,bookDate,bookingList[0].End_Time__c);
            List<Invoice_Line_Item__c> listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
            Stripe_Payment_Log__c iLog = new Stripe_Payment_Log__c();
            Double packageFee =0;
            for(Integer i = 0; i < bookingList.size(); i++){
                packageFee =0;
                packageFee = Double.valueOf(listOfPackage[0].unit_Fee__c);
                // if(packageFee > 0 && isOssiaOrganization){
                //     packageFee+= Double.valueOf(listOfPackage[0].facility_Fee__c /4);
                // }
                 totalAmount += BillingUtility.roundOffAmount(packageFee);
                  if(packageFee > 0 && countryOfCentre.Tax_Rate__c > 0){
                     gstAdded += BillingUtility.roundOffAmount(packageFee) * (countryOfCentre.Tax_Rate__c / 100);
                 }
                
            }
            if(totalAmount > 0 && gstAdded > 0){
                totalAmount += gstAdded;
            }
            /*for( Integer i = 0;i < bookingList.size();i++ ){
                totalAmount += Double.valueOf(listOfPackage[0].unit_Fee__c);
            }
            if(totalAmount > 0 && countryOfCentre.Tax_Rate__c > 0){
                double gstAdded = totalAmount * (countryOfCentre.Tax_Rate__c / 100);
                totalAmount += gstAdded;
            }
           //system.debug('@@@totalAmount'+totalAmount);
            if(totalAmount > 0){
                totalAmount = BillingUtility.roundOffAmount(totalAmount);
            }*/
           ////system.debug('@@@totalAmount roundoff '+totalAmount);
            if(objectOfInvoice != NULL && totalAmount > 0 &&  isChecked && String.isNotBlank(organisationOfCentre.Id)){
                if(String.isNotBlank(stripeId)){
                    BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
                    //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                    //objStripeCharge = updateInvoice(objectOfInvoice, totalAmount, stripeId, countryOfCentre.Currency_Code__c, organisationOfCentre.Stripe_Base_Url__c, countryOfCentre.Stripe_Secret_Key__c);
                    //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                                    
                    objStripeCharge = updateInvoice(objectOfInvoice, totalAmount, stripeId, organisationOfCentre.country__r.Currency_Code__c, organisationOfCentre.Stripe_Base_Url__c, organisationOfCentre.Stripe_Secret_Key__c);
                    
                    if(objStripeCharge.statusCode == 200 && objStripeCharge.paid && bookingList.size() > 0){
                        objectOfInvoice.status__c = ConstantsClass.paidStatus;
                        string invoiceId = createDueInvoice(objectOfInvoice,bookingList,listOfPackage,countryOfCentre.Tax_Rate__c);
                        if(String.isNotBlank(invoiceId)){
                            isSuccess = true;
                            objectOfInvoice = [SELECT Id,Name,Parent_Account__c,Total_Amount__c FROM Invoice__c WHERE Id=: invoiceId];
                            BillingUtility.createAttachment(new Set<String>{objectOfInvoice.Id});
                            Payment__c objPayment = BillingUtility.fillPayment(objectOfInvoice.Parent_Account__c,objectOfInvoice.Id,totalAmount,ConstantsClass.successStatus); 
                            objPayment.Transaction_ID__c = objStripeCharge.Id;
                            objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                            insert objPayment;
                            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                            // if(String.isNotBlank(countryOfCentre.Id)){
                            //     BillingUtility.updateCharge(objStripeCharge.Id,objectOfInvoice.Name, countryOfCentre.Stripe_Base_Url__c, countryOfCentre.Stripe_Secret_Key__c);    
                            // }
                            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                            if(String.isNotBlank(organisationOfCentre.Id)){
                                BillingUtility.updateCharge(objStripeCharge.Id,objectOfInvoice.Name, organisationOfCentre.Stripe_Base_Url__c, organisationOfCentre.Stripe_Secret_Key__c);    
                            }

                            // added by jatin: 31-Dec-2019 : for adhoc invoice to push on the sage
                            SageIntacctIntegrationUtility.adhocInvoice(objectOfInvoice.id);
                        }
                    }else{
                        isSuccess = false;
                            //if ossia organisation adhoc should be allowed and invoice should be still generated even if the card is failed
                        if(isOssiaOrganization){
                            string invoiceId = createDueInvoice(objectOfInvoice,bookingList,listOfPackage,countryOfCentre.Tax_Rate__c);
                            if(String.isNotBlank(invoiceId)){
                                BillingUtility.createAttachment(new Set<String>{invoiceId});
                                // added : for adhoc invoice to push on the sage
                                SageIntacctIntegrationUtility.adhocInvoice(invoiceId);
                            }
                            isSuccess = true;
                        }
                           //if ossia organisation adhoc should be allowed and invoice should be still generated even if the card is failed
                    }
                }else{
                    isSuccess = false;
                     //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                     if(isOssiaOrganization){
                        string invoiceId = createDueInvoice(objectOfInvoice,bookingList,listOfPackage,countryOfCentre.Tax_Rate__c);
                        if(String.isNotBlank(invoiceId)){
                            // added : for adhoc invoice to push on the sage
                            SageIntacctIntegrationUtility.adhocInvoice(invoiceId);
                            BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{invoiceId});
                        }
                        isSuccess = true;
                    }//19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                }
            }else{
                isSuccess = false;
            }
        }
        return isSuccess;
    }

    public static string createDueInvoice(invoice__c objectOfInvoice,List<Booking__c> bookingList,List<Package__c> listOfPackage,Decimal taxRate){
        insert objectOfInvoice;
        if(bookingList != null && bookingList.size() > 0){
            insert bookingList;
            List<Invoice_Line_Item__c> listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
            if(objectOfInvoice.id != null){
                for(Integer i = 0; i < bookingList.size(); i++){
                    Double amount =listOfPackage[0].unit_Fee__c;
                    Double taxAmount = 0;
                    if(amount > 0 && taxRate > 0){
                        taxAmount = BillingUtility.roundOffAmount(amount * (taxRate / 100));
                    }
                    listOfInvoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                                                                    Amount__c=BillingUtility.roundOffAmount(amount),
                                                                    package__c=listOfPackage[0].id, 
                                                                    Booking__c = bookingList[i].Id, month__c = System.today(), 
                                                                    GST_Amount__c = taxAmount));
                     //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    // Double facilityAmount = 0;
                    // Double facilitytaxAmount = 0;
                    // if(isOssiaOrganization){
                    //     facilityAmount = BillingUtility.roundOffAmount(listOfPackage[0].facility_Fee__c/4);
                    //     if(facilityAmount > 0 && countryOfCentre.Tax_Rate__c > 0){
                    //         facilitytaxAmount = BillingUtility.roundOffAmount(facilityAmount * (countryOfCentre.Tax_Rate__c / 100));
                    //     }
                        
                    // }
                    // if(facilityAmount >0){
                    //     listOfInvoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                    //             Amount__c=facilityAmount,
                    //             package__c=packageId, 
                    //             Booking__c = bookingList[i].Id, month__c = System.today(), 
                    //             GST_Amount__c = facilitytaxAmount,
                    //             Remarks__c = 'Facility Fee'));   
                    // }     
                    //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee                                                                        
                }
            }
            if(listOfInvoiceLineItem.size() > 0){
                insert listOfInvoiceLineItem;
            }
            return objectOfInvoice.id;
        }
        return '';
    } 
    
    Public static BillingUtility.StripeCharge updateInvoice(Invoice__c invoice, Decimal total, String stripeId, String currencyCode,String baseUrl, String apiKey){
        BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
        if(invoice != NULL && total > 0){
            objStripeCharge = BillingUtility.createChargeForCustomer(
                stripeId, total, currencyCode, baseUrl, apiKey);
            //System.debug('@@@objStripeCharge_'+objStripeCharge);
        }
        return objStripeCharge;
    }
    
    public static List<Booking__c> createPlaceholder(List<Booking__c> bookingObjList, String origin, String newSlot){
        Booking__c placeholderObj = new Booking__c();
        Boolean isError = false;
        DateTime newSlotTime;
        if(String.isNotBlank(newSlot)){
            newSlotTime = DateTime.newInstance(Date.newInstance(0,0,0), Time.newInstance(Integer.valueOf(newSlot.split('T')[1].split(':')[0]), Integer.valueOf(newSlot.split('T')[1].split(':')[1]), Integer.valueOf(newSlot.split('T')[1].split(':')[2]), 0));
        }
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Booking__c bookingCurrentObj : bookingObjList){
            placeholderObj = new Booking__c();
            // Added By Ravi on 16 july 2020
            placeholderObj.Lesson_Type__c='';
            // Added By Ravi on 16 july 2020
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = bookingCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = bookingCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = bookingCurrentObj.End_Time__c;
            placeholderObj.status__c = ConstantsClass.scheduledStatus;
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
    public static Boolean completedOrNoShow(String bookingId, String type, String status,Boolean isPianoBooking){
        Boolean isSuccess = false;
        Booking__c bookingObj = new Booking__c();
        if(String.isNotBlank(bookingId) && String.isNotBlank(status) && String.isNotBlank(type)){
            bookingObj.Id = bookingId;
            if((!(status == ConstantsClass.statusNoshow && type == ConstantsClass.typeBusy)) && !((status == ConstantsClass.statusNoshow || status == ConstantsClass.statusCompleted) && (/*type == ConstantsClass.typeTrial || */type == ConstantsClass.typeAudition))){
                bookingObj.Status__c = status;
                //System.debug('@@@@bookingObj'+bookingObj);
                //Commenter byCommented by jatin: 11-mar-2020: for employee Calendar not Deploye  if(!isPianoBooking){
                if(!isPianoBooking){
                    if(ConstantsClass.typeTrial == type && (status == ConstantsClass.statusCompleted || status ==ConstantsClass.statusNoshow) && String.isNotBlank(bookingId)){
                        List<Booking__c> bookingList = new List<Booking__c>();
                        bookingList = [SELECT Id, Name, Enrolment__c FROM Booking__c WHERE Id =: bookingId];
                        if(bookingList.size() > 0){
                            Enrolment__c enroll = new Enrolment__c();
                            if(String.isNotBlank(bookingList[0].Enrolment__c) ){
                                enroll.id = bookingList[0].Enrolment__c;
                                if(status == ConstantsClass.statusCompleted){
                                    enroll.stage__c = ConstantsClass.enrollStageAttended;
                                }else if(status == ConstantsClass.statusNoshow){
                                    enroll.stage__c = ConstantsClass.statusNoshow;                                
                                }
                                update enroll;
                            }
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
        List<Resource__c> resourceList = new List<Resource__c>();
        List<Booking__c> bookObjList = new List<Booking__c>();
        List<Attachment> attachList = new List<Attachment>();
        Booking__c bookingObj = new Booking__c();
        EventDetails ed = new EventDetails();
        if(bookingReschedule.containsKey('Id')){
            bookObjList = [SELECT id, Booking_Date__c,Lesson_Type__c, Start_Time__c, Center__c,Center__r.name, End_Time__c, Duration__c,Type__c, Status__c, Price__c, Teacher_Account__r.Name, Package__r.Name, 
                           Student__r.FirstName, Resource__c,Resource__r.Name, Student__r.LastName, Student__r.Parent__r.FirstName, Student__r.Parent__r.LastName, Student__r.Parent__r.PersonMobilePhone, 
                           Student__r.Parent__r.Phone, Student__r.Parent__r.PersonEmail, Student__r.id, Student__r.PersonMobilePhone, Student__r.Phone, Student__r.PersonEmail,Student__r.Also_a_Student__c, Student__r.Parent__r.Also_a_Student__c, RecordType.Name
                           FROM Booking__c WHERE id =: String.valueOf(bookingReschedule.get('Id'))];
            if(bookObjList.size() > 0){
                bookingObj = bookObjList[0];
                // Added By Ravi on 16 july 2020
                 ed.lessonType=bookingObj.Lesson_Type__c;
                // Added By Ravi on 16 july 2020
                ed.Id = bookingObj.Id;
                ed.centerName = bookingObj.Center__r.name;
                ed.centerId = bookingObj.Center__c;
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
                ed.resourceName =  bookingObj.Resource__r.Name;
                ed.resourceId = bookingObj.Resource__c;
                if(bookingReschedule.containsKey('resource')){
                    if(bookingReschedule.get('resource') != bookingObj.Teacher_Account__c){
                        accList = AureusCalendarControllerHelper.getListOfTeacher(bookingObj.Center__c, String.valueOf(bookingReschedule.get('resource')));
                        if(accList.size() > 0){
                            ed.staffMember = accList[0].Name;
                            ed.staffMemberId = accList[0].id;
                            attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                          WHERE parentid=:accList[0].Id AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                          ORDER BY LastModifiedDate DESC LIMIT 1];
                            if(attachList.size() > 0){
                                ed.teacherAttachmentId = attachList[0].Id;
                            }
                        }else{
                        //start: nish: 31-Jul-2020: If resource Calendar exist then teacher records not found then we check existing booking Teacher_Account__c details    
                            accList = AureusCalendarControllerHelper.getListOfTeacher(bookingObj.Center__c, bookingObj.Teacher_Account__c);
                            if(accList.size() > 0){
                                ed.staffMember = accList[0].Name;
                                ed.staffMemberId = accList[0].id;
                                attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                              WHERE parentid=:accList[0].Id AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                              ORDER BY LastModifiedDate DESC LIMIT 1];
                                if(attachList.size() > 0){
                                    ed.teacherAttachmentId = attachList[0].Id;
                                }
                            }
                            // get Resource Detail if change resource then we get resource 
                            if(bookingReschedule.get('resource') != bookingObj.Resource__c){
                                resourceList = AureusCalendarControllerHelper.getListOfResource(bookingObj.Center__c, String.valueOf(bookingReschedule.get('resource')));
                                if(resourceList.size() > 0){
                                    ed.resourceName = resourceList[0].Name;
                                    ed.resourceId = resourceList[0].id;
                                }
                            }

                        //start: nish: 31-Jul-2020: If resource Calendar exist then teacher records not found then we check existing booking Teacher_Account__c details    
                        
                        }
                    }else{
                        ed.staffMember = bookingObj.Teacher_Account__r.Name;
                        ed.staffMemberId = bookingObj.Teacher_Account__c;
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
    
    public static List<BookingHistory> getBookingHistory(String bookingId){
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
    public static string findObjectAPIName(String recordId){
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
    
    public static Set<String> getWeekDaySet(List<integer> startEnd){
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
           //system.debug('Function Calling Error...');
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
            
            Booking_Note__c bookingNote = new Booking_Note__c();
            bookingNote.Booking__c = eventId;
            bookingNote.Title__c = title;
            bookingNote.Description__c = note;
            bookingNote.Note_Created_Date__c = System.today();
            bookingNote.Note_Created_By__c = Userinfo.getFirstName() + ' ' + Userinfo.getLastName();
            insert bookingNote;
            
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
  
      //start: added by nishi: 5-Aug:2020: for change all future Lesson Mode and update Online Url PassCode
    @RemoteAction
    public Static String updateOnlineLesson(string lessonMode,string eventId,string isFuture,string changedate){
        if( String.isNotBlank(eventId) && String.isNotBlank(lessonMode)){
             //  Added by Ravi.. 0n 8 july 2020 to update Lesson Type
            if(isFuture =='false'){
                Booking__c bookingObj = new Booking__c();
                bookingObj.Id = eventId;
                bookingObj.Lesson_Type__c = lessonMode=='In Centre'?'Online':'In Centre';
                bookingObj.Is_Lesson_Type_Change__c=true;
                Update bookingObj;
                
                return 'SUCCESS';
            }  
            // End Added by Ravi.. 0n 8 july 2020
            else If(isFuture =='true'){
                Enrolment__c enrolmentObj  = fetchEnrolment(eventId);
                enrolmentObj.Id = eventId;
                enrolmentObj.Lesson_Mode__c = lessonMode=='In Centre'?'Online':'In Centre';
                if(enrolmentObj.Lesson_Mode__c == ConstantsClass.Online){
                    enrolmentObj.Online_Lesson_URL__c=System.Label.Twilio_Meeting_URL+enrolmentObj.Name;
                    enrolmentObj.Online_Lesson_Passcode__c= AureusUtility.getRandomSixDigit(); 
                    
                }else if(enrolmentObj.Lesson_Mode__c ==ConstantsClass.InCentre){
                    enrolmentObj.Online_Lesson_URL__c='';
                    enrolmentObj.Online_Lesson_Passcode__c='';
                }
                update enrolmentObj;
                DateTime dateChange = DateTime.newInstance(Date.valueOf(changedate.split('T')[0]), Time.newInstance(0, 0, 0, 0));
               //system.Debug('dateChange'+dateChange);
                List<Booking__c> updateBookingList = [SELECT Id, Type__c,Lesson_Type__c,Online_Lesson_URL__c,Online_Lesson_Passcode__c
                                                         FROM Booking__c 
                                                        WHERE Enrolment__c = :eventId
                                                        AND Booking_Date__c >= :dateChange.date()
                                                        AND Status__c !=:ConstantsClass.statusCanceled
                                                        ];
                if(updateBookingList != null && updateBookingList.size() >0){
                    updateOnlineURL(updateBookingList,enrolmentObj.Online_Lesson_URL__c,enrolmentObj.Online_Lesson_Passcode__c,enrolmentObj.Lesson_Mode__c );
                }
                return 'SUCCESS';
            }  
        }
        return 'ERROR FOUND';  
    }

    //udpate online Url and Passcode 
     public static void updateOnlineURL(List<Booking__c> updateBookingList,string onlineLessonURL,string passcode,string lessonMode){
        // it basically update the Online url and Pass code value 
        if(updateBookingList != NULL && updateBookingList.size()>0 ){
            for(Booking__c book:updateBookingList){
                book.Lesson_Type__c = lessonMode;
                if(book.Lesson_Type__c == ConstantsClass.Online){
                    book.Online_Lesson_URL__c=onlineLessonURL;
                    book.Online_Lesson_Passcode__c= AureusUtility.getRandomSixDigit();//passcode; 
                    
                }else if(book.Lesson_Type__c ==ConstantsClass.InCentre){
                    book.Online_Lesson_URL__c='';
                    book.Online_Lesson_Passcode__c='';
                }
            }
            
            update updateBookingList;
        }
        
    }
  //end: added by nishi: 5-Aug:2020: for change all future Lesson Mode and update Online Url PassCode

   
   
    public static NewBookingWrapper getTeacherAndCenterWrapper(List<String> idList,NewBookingWrapper newBookingWrapperObj){
        TeacherAndCenter tcObj = new TeacherAndCenter();
        List<TeacherAndCenter> teacherAndCenterList = new List<TeacherAndCenter>();
        List<Account> accList = [SELECT Id, Name, Organisation__c,Organisation__r.Name, RecordType.Name FROM Account WHERE Id IN :idList];
            for(Account acc : accList){
                tcObj = new TeacherAndCenter();
                tcObj.id = acc.Id;
                tcObj.Name = acc.Name;
                if(acc.RecordType.Name == ConstantsClass.centerRecTypeName){
                         // nishi: 22-Jul-2020: start: for get current center is related to ossia organization or not 
                        if(String.isNotBlank(acc.Organisation__c) && 
                        String.isNotBlank(acc.Organisation__r.Name) && 
                        acc.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                            newBookingWrapperObj.isOssia =  true;
                        }else{
                            newBookingWrapperObj.isOssia =  false;
                        }
                     // nishi: 22-Jul-2020: end: for get current center is related to ossia organization or not
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
        // Added by Ravi on 13 july 2020
        List<string> options = new List<string>();
        
        Schema.DescribeFieldResult fieldResult =
            Booking__c.Lesson_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getValue());
        }      
        newBookingWrapperObj.lessonTypeList=options;
        // // Added by Ravi on 13 july 2020
            return newBookingWrapperObj;
    }
     public static NewBookingWrapper getPackageWrapper(List<Package__c> packageList,NewBookingWrapper newBookingWrapperObj){
         List<packageWrapper> packageWrapperList = new List<packageWrapper>();
         packageWrapper pw = new packageWrapper();
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
        return newBookingWrapperObj;
     }
    @RemoteAction
    public static String getTeacherAndCenter(String centerId, String teacherId){
         //List<TeacherAndCenter> teacherAndCenterList = new List<TeacherAndCenter>();
       // TeacherAndCenter tcObj = new TeacherAndCenter();
        List<String> idList = new List<String>();
        //List<Account> accList = new List<Account>();
        List<Attachment> attachIdList = new List<Attachment>();
        List<Package__c> packageList = new List<Package__c>();
        //List<packageWrapper> packageWrapperList = new List<packageWrapper>();
        NewBookingWrapper newBookingWrapperObj = new NewBookingWrapper();
        
        if(String.isNotBlank(centerId)){
            idList.add(centerId);
        }
        if(String.isNotBlank(teacherId)){
            idList.add(teacherId);
        }
        
        if(idList.size() > 0){
            /*accList = [SELECT Id, Name, RecordType.Name FROM Account WHERE Id IN :idList];
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
            }*/
             newBookingWrapperObj=  getTeacherAndCenterWrapper(idList,newBookingWrapperObj);
        }
        if(String.isNotBlank(centerId)){
            //packageWrapper pw = new packageWrapper();
            packageList = [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, Unit_Fee__c, Active__c
             FROM Package__c WHERE Location__c =: centerId AND Active__c = true AND (Type__c = 'Makeup' OR Type__c = 'Adhoc' OR Type__c = 'Trial')];
            /*for(Package__c packageObj : packageList){
                pw = new packageWrapper();
                pw.id = packageObj.Id;
                pw.name = packageObj.Name;
                pw.duration = packageObj.Duration__c;
                pw.type = packageObj.Type__c;
                packageWrapperList.add(pw);
            }
            if(packageWrapperList.size() > 0){
                newBookingWrapperObj.packages = packageWrapperList;
            }*/
             newBookingWrapperObj =  getPackageWrapper(packageList,newBookingWrapperObj);
            
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
          //Start: added by nishi: 30-Jul-2020: for get all Available_For_Aureus_Lesson__c resources
          newBookingWrapperObj.listOfAvailableResources = AureusCalendarControllerHelper.getListOfAvailableAureusLessonResource(centerId,true); 
          //end: added by nishi: 30-Jul-2020: for get all Available_For_Aureus_Lesson__c resources
    
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
            accList = [SELECT Id, Name, RecordType.Name, Available_Make_up_Units__c, Also_a_Student__c, Parent__c, 
            Parent__r.Available_Make_up_Units__c, Parent__r.Name, PersonEmail, Parent__r.PersonEmail, PersonMobilePhone , 
            Parent__r.Available_Complementary_Credit_mins__c,Available_Complementary_Credit_mins__c,// Added By nishi on 24 Feb 2021: for show Complimentary credit mins
            Parent__r.PersonMobilePhone FROM Account WHERE RecordType.Name =:recordTypeCustomer  
            AND ((Also_a_Student__c = true AND Parent__c = NULL) OR 
            (Parent__c != NULL AND Also_a_Student__c = false)) AND (Name LIKE :'%'+str+'%') LIMIT 10];
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
                    sObj.complementryHours= acc.Available_Complementary_Credit_mins__c != null ? Integer.valueOf(acc.Available_Complementary_Credit_mins__c) :0; // Added By nishi on 24 Feb 2021: for show Complimentary credit mins
                }else if(acc.Also_a_Student__c == false && String.isNotBlank(acc.Parent__c)){
                    sObj.parentId = acc.Parent__c;
                    sObj.parentName = acc.Parent__r.Name;
                    sObj.email = acc.Parent__r.PersonEmail;
                    sObj.phone = acc.Parent__r.PersonMobilePhone;
                    sObj.makeupHours = Integer.valueOf(acc.Parent__r.Available_Make_up_Units__c);
                    sObj.complementryHours= acc.Parent__r.Available_Complementary_Credit_mins__c != null ? Integer.valueOf(acc.Parent__r.Available_Complementary_Credit_mins__c) :0; // Added By nishi on 24 Feb 2021: for show Complimentary credit mins
                }
                if(sObj.makeupHours == NULL){
                    sObj.makeupHours = 0;
                }
                 // Added By nishi on 24 Feb 2021: for show Complimentary credit mins
                if(sObj.complementryHours == NULL){
                    sObj.complementryHours=0;
                }
                 // // Added By nishi on 24 Feb 2021: for show Complimentary credit mins
                sObjList.add(sObj);
            }
            
        }
        return JSON.serialize(sObjList);
    }
    
    @RemoteAction
    public static ProcessResult /*String*/ createBooking(String bookingJson, String redirectCase, String caseId,string lessonMode){
        
        ProcessResult  objResult = new ProcessResult();
        //String errorMsg = 'false';
        objResult.msg = 'false';
        Boolean isError = false;
        Map<String, Object> bookingMap = new Map<String, Object>();
        Booking__c bookingObj = new Booking__c();
        List<Booking__c> bookingList = new List<Booking__c>();
        DateTime bookingDateTime;
        String parentId;
        Date bookDate;
        Boolean isComplimentaryCredit = false;// nishi: 24-feb-2021 :start: check booking use available makeup mins or available Complimentary Credit hours 
        if(String.isNotBlank(bookingJson)){
           ////system.debug(bookingJson);
            bookingMap = (Map<String, Object>)JSON.deserializeUntyped(bookingJson);
            if(bookingMap.containsKey('date')){
                String bd = String.valueOf(bookingMap.get('date'));
                if(String.isNotBlank(bd)){                   
                    bookingDateTime = DateTime.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]), Integer.valueOf(bd.split('T')[1].split(':')[0]), Integer.valueOf(bd.split('T')[1].split(':')[1]), 0);
                    bookDate = Date.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]));
                }
                //System.debug('bookingDateTime'+bookDate);
                // Added By Ravi on 16 july 2020
                bookingObj.Lesson_Type__c=lessonMode;
                if(lessonMode== ConstantsClass.Online){
                   bookingObj.Is_Lesson_Type_Change__c=true; 
                }
                // Added By Ravi on 16 july 2020
            }
            if(bookingMap.containsKey('isRecurring')){
                if(String.valueOf(bookingMap.get('isRecurring')) == 'false'){
                    if(bookingMap.containsKey('centerId')){
                        bookingObj.Center__c = String.valueOf(bookingMap.get('centerId'));
                    }
                    if(bookingMap.containsKey('teacherId')){
                        bookingObj.Teacher_Account__c = String.valueOf(bookingMap.get('teacherId'));
                    }
                    //start: 30-jul-2020 added by nishi id resourceId is not blank then we added in resource lookup 
                   // if(bookingObj.Lesson_Type__c != ConstantsClass.Online){
                        if(bookingMap.containsKey('resourceId') && string.isNotBlank(String.valueOf(bookingMap.get('resourceId')))){
                            bookingObj.Resource__c = String.valueOf(bookingMap.get('resourceId'));
                        }
                        /* //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
                        else{
                            if(String.isNotBlank(String.valueOf(bookingMap.get('teacherId')))){        
                                List<String> weekDay =  new List<String>();     
                                weekDay.add(bookingDateTime.format('EEE'));     
                                AureusCalendarController.TeacherWorkingHours teachersHours = AureusCalendarControllerHelper.getTeacherWorkingHours(String.valueOf(bookingMap.get('centerId')), String.valueOf(bookingMap.get('teacherId')), weekDay );   
                                if(teachersHours.setOfTeachers.size() > 0 && teachersHours.teachersHours.size() > 0){      
                                    for(Teacher_Working_Hour__c th : teachersHours.teachersHours){     
                                        if(teachersHours.setOfTeachers.contains(th.Teacher_Name__c)){      
                                            bookingObj.Resource__c  = th.Resource__c;
                                        }      
                                    }      
                                }   
                            }
                        }
                         //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
                        */
                  //  }
                    //start: 30-jul-2020 added by nishi id resourceId is not blank then we added in resource lookup 
                       
                    if(bookingMap.containsKey('studentId')){
                        bookingObj.Student__c = String.valueOf(bookingMap.get('studentId'));
                    }
                    if(bookingMap.containsKey('packageId')){
                        bookingObj.Package__c = String.valueOf(bookingMap.get('packageId'));
                    }
                    if(bookingMap.containsKey('type')){
                        if(String.valueOf(bookingMap.get('type')) == ConstantsClass.pakageTypeMakeup){
                            bookingObj.Type__c = ConstantsClass.typeMakeup;
                            // nishi: 24-feb-2021 :start: check booking use available makeup mins or available Complimentary Credit hours 
                            if(bookingMap.containsKey('isComplimentaryCredit')){
                                if(Boolean.valueOf(bookingMap.get('isComplimentaryCredit'))){
                                    bookingObj.Is_Complimentary_Credit__c = true;
                                    isComplimentaryCredit = true;
                                }
                                system.debug('isComplimentaryCredit'+bookingMap.get('isComplimentaryCredit'));
                            }
                            // nishi: 24-feb-2021 :end: check booking use available makeup mins or available Complimentary Credit hours 
                            //Nishi:22-Jul-2020:Start: if ossian student is create new booking then we added enrolment Id  for only makeup bookings
                            if(bookingMap.containsKey('enrolmentId') && string.isNotBlank(String.valueOf(bookingMap.get('enrolmentId')))){
                                bookingObj.Enrolment__c = String.valueOf(bookingMap.get('enrolmentId'));
                            }
                            //Nishi:22-Jul-2020:End: if ossian student is create new booking then we added enrolment Id 
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
                   ////system.debug('Integer.valueOf(bookingMap.get(duration))'+Integer.valueOf(bookingMap.get('duration')));
                    //if(bookingObj != NULL){
                    if(String.valueOf(bookingMap.get('type')) == 'home-trial'){
                        createBusyTime(bookingObj);
                    }
                    Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:bookingObj.Student__c ];
                    parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                    //System.debug(parentId);
                    //add ParentId in Booking parent
                    bookingObj.Parent__c = parentId;
                    if(bookingObj.Type__c == ConstantsClass.typeTrial){
                        /*@ 18 April 2019 Aureus office, ParentId is not coming in JSON so I made a query here, 
*/
                        
                        Enrolment__c objEnrol = createEnrolmentForTrial(bookingObj,parentId);
                        bookingObj.Enrolment__c = objEnrol.Id;
                    }
                   
                    
                    Boolean isChecked = validateBookingTime(bookingObj.Teacher_Account__c,bookDate,bookingObj.End_Time__c);
                    //SYstem.debug(isChecked);
                    Database.SaveResult saveResult;
                    if(isChecked){
                        saveResult = Database.insert(bookingObj, false);
                    }
                    if(isChecked == False && saveResult == null){//&& !saveResult.isSuccess()
                        isError = true;
                        objResult.msg = 'error';
                    }else{
                        if(bookingObj.Type__c == ConstantsClass.typeMakeup  || bookingObj.Type__c == ConstantsClass.typeTrial){
                            if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                                bookingList.add(bookingObj); 
                                // nishi: 24-feb-2021 : deduct available Complimentary Credit hours and minus and calculate utilize min then update parent 
                                if(isComplimentaryCredit){
                                    deductComplimentaryCreditHours(bookingList, parentId);
                                }
                                // nishi: 24-feb-2021 : deduct available Complimentary Credit hours and minus and calculate utilize min then update parent 
                                else{
                                    deductMakeupHours(bookingList, parentId);
                                }
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
                        String center, teacher, student, packageId, type, status = '',resourceId,enrolmentId;
                        Integer duration = 0;
                        Boolean isOssia = false;
                        if(bookingMap.containsKey('centerId')){
                            center = String.valueOf(bookingMap.get('centerId'));
                        }
                        //start: 30-jul-2020 added by nishi id resourceId is not blank then we added in resource lookup 
                        if(bookingMap.containsKey('resourceId') && string.isNotBlank(String.valueOf(bookingMap.get('resourceId'))) ){
                            resourceId = String.valueOf(bookingMap.get('resourceId'));
                        }
                         //end: 30-jul-2020 added by nishi id resourceId is not blank then we added in resource lookup 
                        // added by nishi: 23-Jul-2020: Start:if center is ossian then this enrolment id is exist
                        if(bookingMap.containsKey('enrolmentId')){
                            enrolmentId = String.valueOf(bookingMap.get('enrolmentId'));
                        }
                        if(bookingMap.containsKey('isOssia') && Boolean.valueOf(bookingMap.get('isOssia'))){
                            isOssia = Boolean.valueOf(bookingMap.get('isOssia'));
                        }
                        // added by nishi: 23-Jul-2020: End:if center is ossian then this enrolment id is exist
                       
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
                                // nishi: 24-feb-2021 :start: check booking use available makeup mins or available Complimentary Credit hours 
                                if(bookingMap.containsKey('isComplimentaryCredit')){
                                    if(Boolean.valueOf(bookingMap.get('isComplimentaryCredit'))){
                                        bookingObj.Is_Complimentary_Credit__c = true;
                                        isComplimentaryCredit = true;
                                    }
                                    system.debug('isComplimentaryCredit'+bookingMap.get('isComplimentaryCredit'));
                                }
                                // nishi: 24-feb-2021 :start: check booking use available makeup mins or available Complimentary Credit hours 
                                if(type == ConstantsClass.typeMakeup){
                                    status = ConstantsClass.statusScheduled;
                                }
                            }else{
                                status = ConstantsClass.statusPending;
                            }
                        }
                        
                         // nishi: 24-feb-2021 :start: check booking use available makeup mins or available Complimentary Credit hours 
                        if(isComplimentaryCredit ){
                            if(bookingMap.containsKey('complentryHours') && Integer.valueOf(bookingMap.get('complentryHours')) > 0){
                                availableHours = Integer.valueOf(bookingMap.get('complentryHours'));
                            }
                        }
                         // nishi: 24-feb-2021 :start: check booking use available makeup mins or available Complimentary Credit hours 
                        else{
                            if(bookingMap.containsKey('availableHours') && Integer.valueOf(bookingMap.get('availableHours')) > 0){
                                availableHours = Integer.valueOf(bookingMap.get('availableHours'));
                            }
                        }
                        
                        if(bookingMap.containsKey('duration') && Integer.valueOf(bookingMap.get('duration')) > 0){
                            duration = Integer.valueOf(bookingMap.get('duration'));
                            //System.debug('duration'+duration);
                        }
                        duplicate = bookingDateTime;
                        bookingList = new List<Booking__c>();
                        totalDuration = countOfOccurence * duration;
                        Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:student];
                        parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                        
                        for(Integer i=1;i<=countOfOccurence;i++){
                            bookingObj = new Booking__c();
                            bookingObj.Center__c = center;
                            bookingObj.Lesson_Type__c = lessonMode;
                             //start: 30-jul-2020 added by nishi id resourceId is not blank then we added in resource lookup 
                            //if(bookingObj.Lesson_Type__c != ConstantsClass.Online){
                                if(string.isnotBlank(resourceId)){
                                    bookingObj.resource__c =resourceId;
                                }
                                 //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                                /*else{
                                   if(String.isNotBlank(teacher)){        
                                        List<String> weekDays =  new List<String>();     
                                        weekDays.add(duplicate.format('EEE'));     
                                        AureusCalendarController.TeacherWorkingHours teachersHours = AureusCalendarControllerHelper.getTeacherWorkingHours(center, teacher, weekDays );   
                                        if(teachersHours.setOfTeachers.size() > 0 && teachersHours.teachersHours.size() > 0){      
                                            for(Teacher_Working_Hour__c th : teachersHours.teachersHours){     
                                                if(teachersHours.setOfTeachers.contains(th.Teacher_Name__c)){      
                                                    bookingObj.Resource__c  = th.Resource__c;
                                                }      
                                            }      
                                        }   
                                    } 
                                }*/
                                 //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
                            //}
                             //end: 30-jul-2020 added by nishi id resourceId is not blank then we added in resource lookup 
                            bookingObj.Teacher_Account__c = teacher;
                              // added by nishi: 23-Jul-2020: Start:if center is ossian then this enrolment id is exist
                            if(string.isNotBlank(enrolmentId)){
                                 bookingObj.enrolment__c = enrolmentId;
                            }
                            // added by nishi: 23-Jul-2020: Start:if center is ossian then this enrolment id is exist
                           
                            bookingObj.Student__c = student;
                            bookingObj.Package__c = packageId;
                            bookingObj.Type__c = type;
                            bookingObj.status__c = status;
                            bookingObj.Booking_Date__c = duplicate.date();
                            bookingObj.Start_Time__c = Time.newInstance(duplicate.hour(), duplicate.minute(), 0, 0);
                            bookingObj.end_Time__c = Time.newInstance(duplicate.hour(), duplicate.minute() + duration, 0, 0);
                            bookingObj.Parent__c = parentId;
                            bookingList.add(bookingObj);
                            duplicate = duplicate.addDays(addDaysCount);
                        }
                        Boolean isChecked = validateBookingTime(bookingObj.Teacher_Account__c,bookDate,bookingObj.End_Time__c);
                        if(isChecked){
                            
                           ////system.debug('@@@bookingList'+bookingList.size());
                           ////system.debug('@@@bookingList'+bookingList.size());
                            String msg = validateMakupRecurringBookings(bookingList, totalDuration, availableHours);
                            if(bookingList.size() > 0 && String.isBlank(msg)){
                                Database.SaveResult[] saveResults = Database.insert(bookingList, false);
                                for(Database.SaveResult saveResult : saveResults){
                                    if(!saveResult.isSuccess()){
                                        isError = true;
                                    }
                                }
                                //Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:student ];
                                //Stri parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                               ////system.debug('bookingList '+bookingList.size());
                               ////system.debug('parentId '+parentId);
                                if(!isError && bookingList.size() > 0){
                                    if(bookingList[0].Type__c == ConstantsClass.typeMakeup){
                                        // nishi: 24-feb-2021 : deduct available Complimentary Credit hours and minus and calculate utilize min then update parent 
                                        if(isComplimentaryCredit){
                                            deductComplimentaryCreditHours(bookingList, parentId);
                                        }else{
                                            deductMakeupHours(bookingList, parentId);
                                        }
                                        // nishi: 24-feb-2021 : deduct available Complimentary Credit hours and minus and calculate utilize min then update parent 
                                    }
                                }
                                
                            }else{
                                isError = true;
                                objResult.msg = msg;
                            }
                        }else{
                            isError = true;
                            objResult.msg = 'error';
                        }
                        
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
        //system.debug('@@@bookList.size()'+bookList.size());
       ////system.debug('@@@isCorrect'+isCorrect);
        if(bookList.size() > 0 && isCorrect){
           //system.debug('@@@ifbookList.size()'+bookList.size());
            for(Booking__c book : bookList){
                dates.add(book.Booking_Date__c);
                centerId = book.Center__c;
                teacherId = book.Teacher_Account__c;
            }
            if(String.isNotBlank(centerId) && String.isNotBlank(teacherId) && dates.size() > 0){
                existingBookingList = getBookingsOnSelectedDates(centerId, teacherId, dates, '', true);
                
            }    
        }
        Boolean isBreak = false;
        if(existingBookingList.size() > 0 && bookList.size() > 0){
            for(Booking__c newBookingObj : bookList){
                for(Booking__c oldBookingObj : existingBookingList){
                    if(newBookingObj.Booking_Date__c == oldBookingObj.Booking_Date__c){
                        if((oldBookingObj.Start_Time__c <= newBookingObj.Start_Time__c && oldBookingObj.End_Time__c >= newBookingObj.End_Time__c) || (newBookingObj.Start_Time__c <= oldBookingObj.Start_Time__c && newBookingObj.End_Time__c >= oldBookingObj.End_Time__c) || (newBookingObj.Start_Time__c > oldBookingObj.Start_Time__c && newBookingObj.End_Time__c > oldBookingObj.End_Time__c && newBookingObj.Start_Time__c < oldBookingObj.End_Time__c) || (newBookingObj.Start_Time__c < oldBookingObj.Start_Time__c && newBookingObj.End_Time__c < oldBookingObj.End_Time__c && newBookingObj.End_Time__c > oldBookingObj.Start_Time__c)){
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
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.typeTrial, ConstantsClass.typeRegular, ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc};
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};     
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
        
        if(dates.size() > 0 && String.isBlank(enrolmentId)){
            queryStr += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND type__c IN: bookTypeSet';
            
        }else if(dates.size() > 0 && String.isNotBlank(enrolmentId)){
            //bookTypeSet.add(ConstantsClass.typeBusy);
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
            queryStr += ' AND status__c IN: bookingStatus AND Enrolment__c !=: enrolmentId AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType AND Category__c NOT IN: busyStatusSet))';
        }

       //system.Debug('@@@@queryStr'+queryStr);
        
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
    
    // deduct makeup hours and minus available mins and calculate utilize min then update parent 
    public static void deductMakeupHours(List<Booking__c> bookingObjList, String bookingParentId){
        //System.debug('Deduct Makeup hours called');
        String statusCanceled = ConstantsClass.statusCanceled;
        Boolean isError = false;
        String studentId;
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        Integer hoursToDeduct = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Booking__c> ossiaBookingList = new List<Booking__c>();
        Booking__c bookObj = new Booking__c();
        Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        //System.debug('bookingParentId '+bookingParentId);
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = getParentsChild(bookingParentId);
        }
        if(bookingObjList.size() > 0){
            studentId = bookingObjList[0].Student__c;
            for(Booking__c bObj : bookingObjList){
                setOfBookings.add(bObj.Id);
            }
            if(setOfBookings.size() > 0){
                 // Start:added By nishi:  12-aug-2020: according to new requiremnt While utilizing Make up credit, 
                //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
                Set<string> enrolmentIds = new Set<string>();                        
                for(Booking__c objBook: [SELECT Id,Student__c, Duration__c,Enrolment__c, Make_up_Utilize_Bookings__c ,Center__r.Organisation__r.Name
                                        FROM Booking__c 
                                        WHERE Id IN:setOfBookings]){
                    if(String.isNotBlank(objBook.Center__c) && 
                        String.isNotBlank(objBook.Center__r.Organisation__c) && 
                        String.isNotBlank(objBook.Center__r.Organisation__r.Name) && 
                        objBook.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                            ossiaBookingList.add(objBook);  
                    }else{
                        bookingList.add(objBook);
                    }
                }
                // commented by nishi: if booking center is ossian then we manage makeup mins in enrolment 
                // bookingList = [SELECT Id, Duration__c, Make_up_Utilize_Bookings__c 
                //                 FROM Booking__c 
                //                 WHERE Id IN:setOfBookings];
            
               system.debug('##ossiaBookingList '+ossiaBookingList);
               system.debug('##bookingList '+bookingList);
                if(ossiaBookingList != null && ossiaBookingList.size() > 0){
                    OssiaCenterCalendarController.deductOssiaMakeupHours(ossiaBookingList,bookingParentId,new Set<String>());
                }
                // end:added By nishi: 12-aug-2020: according to new requiremnt While utilizing Make up credit, 
                //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
                if(bookingList != null && bookingList.size() > 0){                               
                    if(setOfParentStudent.size() > 0){
                        List<Booking__c> cancelBookings = new List<Booking__c>([SELECT Id, Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                                                                                Student__c, Type__c, Duration__c FROM Booking__c
                                                                                WHERE Status__c =: statusCanceled 
                                                                                AND Student__c IN: setOfParentStudent AND 
                                                                                Make_up_Expiry_Date__c >= TODAY 
                                                                                AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
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
                                //System.debug('bookObj '+bookObj);
                                bookingUpdatedList.add(bookObj);
                            }
                        }
                        for(String keysetValue : mapOfHours.keyset()){
                            if(mapOfHours.containsKey(keysetValue)){
                                bookingUpdatedList.add(new Booking__c(Id = keysetValue, 
                                Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                            }
                        }
                        System.debug('##bookingUpdatedList '+bookingUpdatedList);
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
                            List<Account> accList = new List<Account>([SELECT Id, Name, Parent__c, RecordType.Name ,
                                                                        Also_a_Student__c 
                                                                        FROM Account 
                                                                        WHERE RecordType.Name =: recordTypeCustomer 
                                                                        AND Id =: studentId]);
                            if(accList.size() > 0){
                                if(String.isNotBlank(accList[0].Parent__c) && accList[0].Also_a_Student__c == false){
                                    parentId = accList[0].Parent__c;
                                }else if(String.isBlank(accList[0].Parent__c) && accList[0].Also_a_Student__c == true){
                                    parentId = accList[0].Id;
                                }
                            }
                        }
                        /// update parent available mins for cancel bookings only 
                        // beacuse trigger not calculate canceled booking available mins
                        if(String.isNotBlank(parentId)){
                            AureusCalendarControllerHelper.cancelBookingProceed(parentId);
                        }
                    }   
                }
            }
        }
    }


    // nishi: 24-feb-2021 : deduct available Complimentary Credit hours and minus and calculate utilize min then update parent 
    public static void deductComplimentaryCreditHours(List<Booking__c> bookingObjList, String bookingParentId){
        //System.debug('Deduct Makeup hours called');
        String statusCanceled = ConstantsClass.statusCanceled;
        Boolean isError = false;
        String studentId;
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        List<Complementary_Credit__c> complementaryCreditUpdatedList = new List<Complementary_Credit__c>();
        Integer hoursToDeduct = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Booking__c> ossiaBookingList = new List<Booking__c>();
        Booking__c bookObj = new Booking__c();
        Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        //System.debug('bookingParentId '+bookingParentId);
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = getParentsChild(bookingParentId);
        }
        if(bookingObjList.size() > 0){
            studentId = bookingObjList[0].Student__c;
            for(Booking__c bObj : bookingObjList){
                setOfBookings.add(bObj.Id);
            }
            if(setOfBookings.size() > 0){
                 // according to new requiremnt While utilizing Make up credit, 
                //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
                Set<string> enrolmentIds = new Set<string>();                        
                for(Booking__c objBook: [SELECT Id,Student__c, Duration__c,Enrolment__c, Make_up_Utilize_Bookings__c ,Center__r.Organisation__r.Name
                                        FROM Booking__c 
                                        WHERE Id IN:setOfBookings]){
                    bookingList.add(objBook);
                }
                if(bookingList != null && bookingList.size() > 0){                               
                    if(setOfParentStudent.size() > 0){
                        List<Complementary_Credit__c> listOfComplementaryCredit = [SELECT Credit_Apply_date__c, Credit_Expiry_date__c, Credit_Reason__c, Enrolment__c, Teacher_Name__c, Parent__c, Available_credit_Min__c, Package_Name__c, Is_Active__c, Name, Id 
                                                                        FROM Complementary_Credit__c
                                                                        WHERE Is_Active__c = TRUE 
                                                                        AND Parent__c IN: setOfParentStudent AND 
                                                                        Credit_Expiry_date__c >= TODAY 
                                                                        AND (Available_credit_Min__c > 0 AND Available_credit_Min__c != NULL) 
                                                                        ORDER BY Available_credit_Min__c];
                        if(listOfComplementaryCredit != null && listOfComplementaryCredit.size() > 0){
                            for(Complementary_Credit__c objComplementaryCredit : listOfComplementaryCredit){
                                mapOfHours.put(objComplementaryCredit.Id, Integer.valueOf(objComplementaryCredit.Available_credit_Min__c)); 
                            }
                        }
                        if(bookingList.size() > 0){
                            for(Booking__c bookingObj : bookingList){
                                hoursToDeduct = Integer.valueOf(bookingObj.duration__c);
                                bookObj = new Booking__c();
                                bookObj.Id = bookingObj.Id;
                                bookObj.Make_up_Utilize_Bookings__c = '';
                                for(Complementary_Credit__c objComplementaryCredit : listOfComplementaryCredit){
                                    if(mapOfHours.containsKey(objComplementaryCredit.Id) && mapOfHours.get(objComplementaryCredit.Id) > 0 ){
                                        //if(mapOfHours.get(key) > 0){
                                        if(hoursToDeduct > mapOfHours.get(objComplementaryCredit.Id)){
                                            bookObj.Make_up_Utilize_Bookings__c  += objComplementaryCredit.Id +'-'+mapOfHours.get(objComplementaryCredit.Id)+';';
                                            hoursToDeduct -= mapOfHours.get(objComplementaryCredit.Id);
                                            mapOfHours.put(objComplementaryCredit.Id, 0);
                                        }else if(hoursToDeduct <= mapOfHours.get(objComplementaryCredit.Id)){
                                            mapOfHours.put(objComplementaryCredit.Id, mapOfHours.get(objComplementaryCredit.Id) - hoursToDeduct);
                                            bookObj.Make_up_Utilize_Bookings__c  += objComplementaryCredit.Id +'-'+hoursToDeduct+';';
                                            hoursToDeduct = 0;
                                        }
                                        //}
                                        if(hoursToDeduct <= 0){
                                            break;   
                                        }
                                    }
                                }
                                //System.debug('bookObj '+bookObj);
                                bookingUpdatedList.add(bookObj);
                            }
                        }
                        for(String keysetValue : mapOfHours.keyset()){
                            if(mapOfHours.containsKey(keysetValue)){
                                complementaryCreditUpdatedList.add(new Complementary_Credit__c(Id = keysetValue, 
                                Available_credit_Min__c = (Decimal)mapOfHours.get(keysetValue)));
                            }
                        }
                        System.debug('##bookingUpdatedList '+bookingUpdatedList);
                        if(bookingUpdatedList.size() > 0){
                            Database.SaveResult[] saveResults = Database.update(bookingUpdatedList, false);
                            for(Database.SaveResult saveResult : saveResults){
                                if(!saveResult.isSuccess()){
                                    isError = true;
                                }
                            }
                        }
                        if(complementaryCreditUpdatedList.size() > 0){
                            Database.SaveResult[] saveResults = Database.update(complementaryCreditUpdatedList, false);
                            for(Database.SaveResult saveResult : saveResults){
                                if(!saveResult.isSuccess()){
                                    isError = true;
                                }
                            }
                        }
                    }   
                }
            }
        }
    }
    
      //commentd by nishi: 28-Jul-2020:private static Set<String> getParentsChild(String parentId){
    Public  static Set<String> getParentsChild(String parentId){
        Set<String> setOfAccId = new Set<String>();
        List<Account> accList = [SELECT Id FROM Account WHERE (Id =: parentId OR Parent__c =: parentId)];
        for(Account acc : accList){
            setOfAccId.add(acc.Id);
        }
        return setOfAccId;
    }
    
    @RemoteAction
    public static String getEventsRealTime(String teacherId, String resourceId, String centerId, String datesOfClicked, String instrument){
        List<Events> listOfEvents = new List<Events>();
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
            for(Package__c packageObj : [SELECT Id, Name, RecordType.Name, Location__r.Name, Location__r.Country__r.Tax_Rate__c, Location__r.Organisation__r.Tax_Rate__c, 
                                        of_Units__c, Package_Fee__c, Unit_Fee__c, Duration__c ,/*facility_Fee__c,*/Location__r.Organisation__r.Name
                                        FROM Package__c WHERE RecordType.Name =: recordTypeLesson AND Id =: packageId]){
                
                adhocDetails.packageName = packageObj.Name; 
                adhocDetails.packageId = packageObj.Id;
                adhocDetails.packageFee = packageObj.Package_Fee__c;
                adhocDetails.unitFee = packageObj.Unit_Fee__c ;
                adhocDetails.units = Integer.valueOf(packageObj.of_Units__c);
                adhocDetails.duration = packageObj.Duration__c;
                //Start: added by nishi: 17-Aug-2020: for manage facility fee is ossia related centers 
                if(String.isNotBlank(packageObj.Location__c)){
                    //adhocDetails.gstRate = packageObj.Location__r.Country__r.Tax_Rate__c; //Commented by nishi@nishi 24 Aug 2020,Organisation wise charge as per new logic
                    adhocDetails.gstRate = packageObj.Location__r.Organisation__r.Tax_Rate__c;
                    adhocDetails.centerName = packageObj.Location__r.Name;
                    // if(string.isnotBlank(packageObj.Location__r.Organisation__c) && string.isnotBlank(packageObj.Location__r.Organisation__r.Name) &&
                    // packageObj.Location__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    //     adhocDetails.unitFee += (packageObj.facility_Fee__c/4);
                    // }
                }   
                //End: added by nishi: 17-Aug-2020: for manage facility fee is ossia related centers
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
          //@JAtin on 9-Dec-2019 to check that User has the access of the Change Enrolment Admin
        details.isChange_Enrolment_Admin = FeatureManagement.checkPermission('Change_Enrolment_Admin') ? true : false;
         //@Nishi on 27-Aug-2019 to check that User has the access of the Change Center
        details.isChangeEnrolmentCentre = FeatureManagement.checkPermission('Change_Enrolment_Center') ? true : false;
         //@Nishi on 27-Aug-2019 : if Promotional enrolment but user want to Enhancement(downgrade ,withdrwal) so we check that User has the access of the Prepayment_Advance_Action premission or not 
        details.isPrepayment_Advance_Action_Admin = FeatureManagement.checkPermission('Change_Enrolment_Admin') ? true : false;
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Enrolment__c, Enrolment__r.Lessons_Start_Date__c, Enrolment__r.Lesson_Start_time__c, 
                            Enrolment__r.Lesson_Day__c, Enrolment__r.Package__r.Name,Center__r.Organisation__r.Name,
                            Enrolment__r.Package__r.Is_Promotion_Discount__c,
                            Enrolment__r.Package__r.Type_of_package__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                details.id = bookingList[0].Id;
                details.packageName = bookingList[0].Enrolment__r.Package__r.Name;
                details.packageId = bookingList[0].Enrolment__r.Package__c;
                details.isPackagePromotional = (bookingList[0].Enrolment__r.Package__r.Is_Promotion_Discount__c || 
                bookingList[0].Enrolment__r.Package__r.Type_of_package__c == ConstantsClass.prePaymentType ||
                                                bookingList[0].Enrolment__r.Package__r.Type_of_package__c==ConstantsClass.PromoTypePayment) ? true : false;
                 if(String.isNotBlank(bookingList[0].Enrolment__c)){
                   //system.debug('bookingList[0].Enrolment__c'+bookingList[0].Enrolment__c);
                    List<Enrolment__c> enrollList = new List<Enrolment__c>([SELECT Id, Lesson_Day__c,Package_Process_Status__c,Center__r.Organisation__r.Name,
                                                                                (SELECT Id, Subscription__c,Next_Bill_Date__c, Subscription__r.Payment_Frequency__c, 
                                                                                Subscription__r.Subscription_Start_Date__c
                                                                                FROM Subscription_Line_Items__r 
                                                                                WHERE Subscription__c != NULL
                                                                                and Status__c =:ConstantsClass.activeStatus //4-sep-2020: added by nishi for new requirement one enrolment have two subscrition so we get active line item
                                                                                And Next_Bill_Date__c != null),
                                                                                Lesson_Start_time__c 
                                                                                FROM Enrolment__c 
                                                                                WHERE Id =: bookingList[0].Enrolment__c]);
                    if(enrollList.size() > 0){
                       //system.debug('enrollList'+enrollList);
                         //10-Aug-2020:nishi:start- manage ossia Upgrade ,downGrade Subscription model 
                        details.isOssia = false;
                        if( String.isNotBlank(enrollList[0].Center__c) && String.isNotBlank(enrollList[0].Center__r.Organisation__c) &&     
                        String.isNotBlank(enrollList[0].Center__r.Organisation__r.Name) &&  
                        enrollList[0].Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){   
                            details.isOssia = true;
                        }
                        //10-Aug-2020:nishi:end- manage ossia Upgrade ,downGrade Subscription model 
                        Time startTime = enrollList[0].Lesson_Start_time__c;
                        
                        Date startDate;
                        DateTime dt = DateTime.newInstance(System.today(), startTime);
                        details.timeSlot = 'Every '+ enrollList[0].Lesson_Day__c.toUppercase().left(3) + '@' + dt.format('h:mma');
                        DateTime timeslot;
                        if(enrollList[0].Subscription_Line_Items__r.size() > 0){
                            startDate = enrollList[0].Subscription_Line_Items__r[0].Subscription__r.Subscription_Start_Date__c;
                           ////system.debug('@@@startDate'+startDate);
                           ////system.debug('@@@startTime'+startTime);
                            timeslot = DateTime.newInstance(startDate, startTime);
                            
                            details.startDate = timeslot.format('dd-MM-yyyy');
                            details.frequency = enrollList[0].Subscription_Line_Items__r[0].Subscription__r.Payment_Frequency__c;
                            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1); // 1-10-2020
                             //@Nishi on 27-Aug-2019 to check An advance invoice is generated Change Or Package_Process_Status__c is Pending
                             // then we disable Change Centre Button
                            //system.debug('Next_Bill_Date__c'+(enrollList[0].Subscription_Line_Items__r[0].Next_Bill_Date__c >= nextMonthDate));
                            //system.debug('status'+((string.isNotBlank(enrollList[0].Package_Process_Status__c) && enrollList[0].Package_Process_Status__c !='Completed')));
                            if(enrollList[0].Subscription_Line_Items__r[0].Next_Bill_Date__c < nextMonthDate && 
                                (string.isBlank(enrollList[0].Package_Process_Status__c) || (string.isNotBlank(enrollList[0].Package_Process_Status__c)
                                 && enrollList[0].Package_Process_Status__c =='Completed'))){
                                    details.isEnableChangeCentre = false;
                            }else{
                                details.isEnableChangeCentre = true;
                            }
                             //@Nishi on 27-Aug-2019 to check An advance invoice is generated Change Or Package_Process_Status__c is Pending
                             // then we disable Change Centre Button
                        }
                    }
                }    
            }
        }
        return details;
    } 
    
    // show package details for upgrade packages according to based on enrollement package duration  
    // and if booking type is group then show package based on their monthly fees.
    @RemoteAction
    public static GradePackageDetails getUpgradedDetails(String bookingId,string bookingType){
        GradePackageDetails details = new GradePackageDetails();
        details.packages = new List<GradePackage>();
        List<Package__c> packageList = new List<Package__c>();
        List<Booking__c> bookingList = new List<Booking__c>();
        GradePackage gp = new GradePackage();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Package__c,Type__c, Package__r.Name, Package__r.Active__c, enrolment__r.Package__c,
                            enrolment__r.Package__r.Package_Fee__c, enrolment__c,
                            enrolment__r.Package__r.Duration__c, enrolment__r.Lesson_Day__c, enrolment__r.Package__r.Type__c, 
                            enrolment__r.Package__r.Location__c, enrolment__r.Package__r.Program__r.Instrument__c
                            FROM Booking__c 
                            WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                details.lessonDay = bookingList[0].enrolment__r.Lesson_Day__c;
                // 23-nov-2019 : jatin : Upgrading from Group class to individual class  
                //Available packages should be shown based on their monthly fees. All higher monthly fees packages can be shown.
                if(string.isNotBlank(bookingType) && bookingType == bookingList[0].Type__c && bookingType ==ConstantsClass.groupLessonTypeBooking){
                   ////system.debug('@@bookingType'+bookingType);
                    packageList =  [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c
                                        FROM Package__c 
                                        WHERE Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                        Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                                        /*@Jatin : 2-Jan-2020 : shown all instuments for user can upgrade package of any teacher  
                                        Program__r.Instrument__c =: bookingList[0].enrolment__r.Package__r.Program__r.Instrument__c AND*/ 
                                        Active__c = true AND 
                                        Package_Fee__c >= :bookingList[0].enrolment__r.Package__r.Package_Fee__c AND 
                                        Is_Promotion_Discount__c = false AND 
                                        Type_of_package__c = 'Normal' AND
                                        Id !=: bookingList[0].enrolment__r.Package__c
                                        ORDER BY Duration__c];  
                                       ////system.debug('@@packageList'+packageList);              
                }else{
                    packageList =  [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c
                                        FROM Package__c 
                                        WHERE Duration__c > :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                        Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                        Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                                        Program__r.Instrument__c =: bookingList[0].enrolment__r.Package__r.Program__r.Instrument__c AND 
                                        Active__c = true AND 
                                        Is_Promotion_Discount__c = false AND 
                                        Type_of_package__c = 'Normal'
                                        ORDER BY Duration__c];
                }
                
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


    
    

    
    // show package details for downgrade packages according to based on enrollement package duration  
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
   // 
    @RemoteAction
    public static String updatePackageOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 Map<String, String> caseValues){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpgradeEnrolmentProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                    oldPackageId, timeSlot, myCaseId, caseRedirect, caseValues,
                                                                                                                    // added by nishi:start-11-Aug-2020: for we added new teacher in Ossia Oraganisation case
                                                                                                                    '','');
                                                                                                                    // added by nishi:start-11-Aug-2020: for we added new teacher in Ossia Oraganisation case
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
                                                    
                                                 }
    
    /*/* Commented by jatin:11-Mar-2020: this function is not using in Calendar
    private static Invoice__c fetchInvoice(String invoiceId){
        return [SELECT Id,Name  FROM Invoice__c WHERE Id =: invoiceId LIMIT 1];
    }
    
    private static UpgradeEnrolmentProcessController.UpgradeCaseCreation updatePackageRequestCallout(String enrolmentId, Date effectiveDate, Date nextBillDate, String newPackageId, String oldPackageId, Time newTimeSlot, Country__c countryObj){
        UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradeCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
        Boolean isSuccess = false;
        String invoiceId;
        if(String.isNotBlank(enrolmentId) && nextBillDate != Null && effectiveDate != Null &&
           String.isNotBlank(newPackageId) && String.isNotBlank(oldPackageId) && newTimeSlot != Null && String.isNotBlank(countryObj.Id)){
               upgradeCaseDetails = upgradeDowngradeController.upgradePackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, countryObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c, countryObj.Tax_Rate__c);
               //System.debug('@@@upgradeCaseDetails'+upgradeCaseDetails);
           }
        return upgradeCaseDetails;
    }
    
    private static UpgradeEnrolmentProcessController.UpgradeCaseCreation updatePackageRequestOnGreaterEffectiveDate(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId, Country__c centreCountry){
        Boolean isSuccess = false;
        UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
        String invoiceId = '';
        String stripeId = '', parentId = '';
        Decimal currentPackageDeposit = 0;
        Package__c newPackage, oldPackage = new Package__c();
        Set<String> invoiceIds = new Set<String>();
        UpgradeDowngradePackageSummary summary = getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
        newPackage = summary.newPackage;
        oldPackage = summary.oldPackage; 
        
        if(String.isNotBlank(enrolmentObj.Id)){
            currentPackageDeposit = getDepositFromFile(enrolmentObj.Id);
        }
        
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Decimal depositeFee = BillingUtility.roundOffAmount((newPackage.Deposit_Fee__c - currentPackageDeposit)); 
        if(enrolmentObj != Null){
            stripeId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c;
            parentId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
        
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
        upgradePackageCaseDetails.total = depositeFee;
        upgradePackageCaseDetails.isSuccess = true;
        
        if(String.isNotBlank(stripeId) && depositeFee > 0 && String.isNotBlank(centreCountry.Id)){
            Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c); 
            
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){                
                isSuccess = true;
                Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.paidStatus);
                objInvoice.Center__c = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.center__c;
                
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
                if(!Test.isRunningTest() && String.isNotBlank(centreCountry.Id)){
                    BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                }
                
                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, BillingUtility.roundOffAmount(objInvoice.Total_Amount__c), ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = chargeResponse.Id;
                objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
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
    }*/
    
    
    public static List<Enrolment__c> getNextBillingDateSubscription(String enrollmentId){
        return [SELECT Id, Name, Parent__c, Parent__r.Name, effective_Date__c, Lesson_Day__c, New_Package_Id__r.Unit_Fee__c, class__r.name,
                Package__r.Unit_Fee__c, Center__c, Teacher__c, package__r.Duration__c, new_package_Id__r.Duration__c, (SELECT Id, Subscription__c, Subscription__r.Center__c, Enrolment__c, Next_Bill_Date__c , Subscription__r.Parent__c, 
                                                                                                                       Subscription__r.Parent__r.Stripe_Customer_Id__c FROM Subscription_Line_Items__r 
                                                                                                                       WHERE Subscription__c != NULL
                                                                                                                       ANd Status__c =:ConstantsClass.activeStatus //4-sep-2020: added by nishi for new requirement one enrolment have two subscrition so we get active line item
                                                                                                                       And Next_Bill_Date__c != null) 
                FROM Enrolment__c WHERE Id =: enrollmentId];
    }
    @RemoteAction
    public static Boolean createBusyAppointments(String centerId, String teacherId, String timeSlot, Integer duration, String description, String category, integer countOfOccurence, String source, String bookingId){
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
                if(String.isNotBlank(bookingId)){
                    busyBooking.Id = bookingId;
                }
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
                
                Database.UpsertResult[] saveResults = Database.upsert(bookingList, false);
                for(Database.UpsertResult sr : saveResults){
                    if(!sr.isSuccess()){
                        /*for(Database.Error err : sr.getErrors()) {
                           //system.debug('$$$The following error has occurred.');                    
                           //system.debug('$$$$'+err.getStatusCode() + ': ' + err.getMessage());
                           //system.debug('$$$Fields that affected this error: ' + err.getFields());
                        }*/
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
        String campClassRecordtype = ConstantsClass.bookingRecordsTypeCampLesson; 
        String facilityRecordType = ConstantsClass.recordTypeFacility;
        List<Booking__c> bookingList = new List<Booking__c>();
        BusyAppointment busy = new BusyAppointment();
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Name, Center__r.Name,Center__c,Teacher_Account__c, Teacher_Account__r.Name, Booking_Date__c,Start_Time__c, End_Time__c, 
                           Category__c, Remarks__c, Duration__c, RecordType.Name, Resource__c, Resource__r.Name, Resource_Category__c, Status__c, 
                           Enrolment__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                Booking__c objBooking = bookingList[0];
                DateTime start, endT;
                start = DateTime.newInstance(objBooking.Booking_Date__c, objBooking.Start_Time__c);
                endT = DateTime.newInstance(objBooking.Booking_Date__c, objBooking.End_Time__c);
                busy.name = objBooking.Name;
                busy.bookingId = objBooking.Id;
                busy.duration = String.valueOf((((endT.getTime() - start.getTime()) / 1000) / 60));
                busy.timeOfBooking = DateTime.newInstance(objBooking.Booking_Date__c, objBooking.Start_Time__c).format('YYYY-MM-dd hh:mma');
                if(objBooking.RecordType.Name == lessonRecordtype){
                    
                    busy.teacher = objBooking.Teacher_Account__r.Name;
                    busy.category = objBooking.Category__c;
                    busy.teacherId = objBooking.Teacher_Account__c;
                    busy.origin = 'teacher';
                    busy.status = objBooking.status__c;
                    busy.enrolmentId = objBooking.Enrolment__c;
                }// added by jatin: 19-Feb:2020:start: for add placholder booking details for camp class show teacher ,status,category
                else if(objBooking.RecordType.Name == campClassRecordtype){
                    
                    busy.teacher = objBooking.Teacher_Account__r.Name;
                    busy.category = objBooking.Category__c;
                    busy.teacherId = objBooking.Teacher_Account__c;
                    busy.origin = 'teacher';
                    busy.status = objBooking.status__c;
                }// added by jatin: 19-Feb:2020:end: for add placholder booking details for camp class 
                else if(objBooking.RecordType.Name == facilityRecordType){
                    busy.teacher = objBooking.Resource__r.Name;
                    busy.category = objBooking.Resource_Category__c;
                    busy.teacherId = objBooking.Resource__c;
                    busy.origin = 'resource';
                }// added by jatin: 1-jan-2019:start:for add group lesson details
                else if(objBooking.RecordType.Name == ConstantsClass.groupLessonBookingRecordType){
                    
                    busy.teacher = objBooking.Teacher_Account__r.Name;
                    busy.category = objBooking.Category__c;
                    busy.teacherId = objBooking.Teacher_Account__c;
                    busy.origin = 'teacher';
                    busy.status = objBooking.status__c;
                    busy.enrolmentId = objBooking.Enrolment__c;
                }// added by jatin: 1-jan2019:end:for add group lesson details
                // added by jatin: 2-jan-2019:start: for add group class details
                else if(objBooking.RecordType.Name == ConstantsClass.groupBookingRecordType){
                    
                    busy.teacher = objBooking.Teacher_Account__r.Name;
                    busy.category = objBooking.Category__c;
                    busy.teacherId = objBooking.Teacher_Account__c;
                    busy.origin = 'teacher';
                    busy.status = objBooking.status__c;
                    busy.enrolmentId = objBooking.Enrolment__c;
                }// added by jatin: 2-jan2019:end: for add group class details
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
                                                          String caseIdToReturn;
                                                            if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                                String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)){
                                                                IAdvanceAction downgradePackageObj;
                                                                downgradePackageObj = new DowngradeEnrolmentProcessController
                                                                    (bookingId, effectiveDateStr, newPackageId, 
                                                                     oldPackageId, timeSlot, myCaseId, caseRedirect,
                                                                     amount,depositAmount,lessonsFees, caseValues,
                                                                     // added by nishi:start-11-Aug-2020: for we added new teacher in Ossia Oraganisation case
                                                                     '','');
                                                                    // added by nishi:start-11-Aug-2020: for we added new teacher in Ossia Oraganisation case
                                                                caseIdToReturn = downgradePackageObj.initProcess();
                                                            }
                                                            return caseIdToReturn;
                                                         
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
                //system.debug('##bookingList'+bookingList.size());
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
        String caseIdToReturn;
        //system.debug('@@bookingId'+bookingId);
        //system.debug('@myCase'+myCase);
        if(String.isNotBlank(bookingId)){
                IAdvanceAction withdrawlPackageObj;
                withdrawlPackageObj = new WithDrawlEnrolmentProcessController(bookingId, endDate, lastLessonDate, 
                                                                         myCase,redirectCase);
                caseIdToReturn = WithdrawlPackageObj.initProcess();
        }
         //system.debug('@@caseIdToReturn'+caseIdToReturn);
        return caseIdToReturn;
       
    }
    
    
    
    //added by nishi: 20-oct-2020: for get current month invoice payment entry for prepayment and promo enrolments
    public static String fetchCurrentMonthPrepaymentEntry(Enrolment__c objEnrol,Date lastLessonDateObj,Date nextBillingDate){
        Date firstDate = Date.newInstance(lastLessonDateObj.Year(),lastLessonDateObj.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
       //system.debug('firstDate'+firstDate);
       //system.debug('lastDate'+lastDate);
        String chargeId ='';
        List<Invoice__c> listOfInvoice =[SELECT Id,Stripe_Charge_Id__c FROM Invoice__c WHERE 
                                         Id IN (SELECT Invoice__c FROM 
                                                Invoice_Line_Item__c 
                                                WHERE Enrolment__c=: objEnrol.id
                                                AND Month__C >=: firstDate
                                                AND Month__C <=: nextBillingDate 
                                                //commented by nishi: 20-Aug-2020: Createddate >=: firstDate AND createddate <=: lastDate 
                                                AND Booking__c = NULL)
                                         AND Invoice_Date__c <=: lastDate 
                                         AND Status__c = 'Paid' 
                                         Order By total_amount__c ];
                                        //system.debug('listOfInvoice'+listOfInvoice);
        if(listOfInvoice.size()>0){
            chargeId = listOfInvoice[0].Stripe_charge_id__c;
        }
       //system.debug('chargeId'+chargeId);
        return chargeId;                                  
    }

    // get current month invoice payment entry
    public static String fetchCurrentMonthPaymentEntry(Enrolment__c objEnrol,Date lastLessonDateObj){
        Date firstDate = Date.newInstance(lastLessonDateObj.Year(),lastLessonDateObj.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
       //system.debug('firstDate'+firstDate);
       //system.debug('lastDate'+lastDate);
        String chargeId ='';
        List<Invoice__c> listOfInvoice =[SELECT Id,Stripe_Charge_Id__c FROM Invoice__c WHERE 
                                         Id IN (SELECT Invoice__c FROM 
                                         Invoice_Line_Item__c WHERE Enrolment__c=: objEnrol.id AND
                                                Month__C >=: firstDate AND Month__C <=: lastDate 
                                                //commented by nishi: 20-Aug-2020: Createddate >=: firstDate AND createddate <=: lastDate 
                                                AND Booking__c = NULL)
                                         //AND Invoice_Date__c >=: firstDate 
                                        // AND Invoice_Date__c <=: lastDate 
                                        AND Status__c = 'Paid' 
                                         Order By total_amount__c ];
                                        //system.debug('listOfInvoice'+listOfInvoice);
        if(listOfInvoice.size()>0){
            chargeId = listOfInvoice[0].Stripe_charge_id__c;
        }
       //system.debug('chargeId'+chargeId);
        return chargeId;                                  
    }
    /* Commented by jatin: this function is not using in Calendar
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
    */
    
    
    Public  static Enrolment__c initEnroll(Enrolment__c enroll){
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
    
    /* Commented by jatin: for now this function is not used in Calendar    
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
    }      */ 
    
    @RemoteAction       
    public static EnrolmentProcessTeacherData getAllTeachersAccordingToCenter(String bookingId, String centerId){       
        EnrolmentProcessTeacherData processData = new EnrolmentProcessTeacherData();        
        Map<String, String> mapOfteacher = new Map<String, String>();       
        TeacherWorkingHours teachersHours = new TeacherWorkingHours();      
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
    
    
    /*@RemoteAction   Commented by jatin: for now this function is not used in Calendar    
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
}*     
    } */
    
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
        Country__c countryObj = new Country__c();//commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
        Organisation__c  organisationObj = new Organisation__c();
        if(String.isNotBlank(withdrawEndDate)){
            withdrawEndDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(lastLessonDate)){
            lastLessonDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(bookingId)){
            enrolment = getEnrolDetails(bookingId);
            if(String.isNotBlank(enrolment.Center__r.Country__r.Id)){
                countryObj = enrolment.Center__r.Country__r;    
            }
        }
        Boolean isPromotionalEnrolment = false;
        if(enrolment.Type_of_Package__c == ConstantsClass.prePaymentType || enrolment.Type_of_Package__c == ConstantsClass.PromoTypePayment){
            isPromotionalEnrolment = true;
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
                if(total > 0 && countryObj.Tax_Rate__c > 0){
                    gst = total  * (countryObj.Tax_Rate__c / 100);
                }
                
            }
            withdrawSummary.refund = 0;
            withdrawSummary.total = total + gst;
            withdrawSummary.gst = gst;
            if(withdrawSummary.deposit > 0){
                withdrawSummary.refund = withdrawSummary.deposit - withdrawSummary.total;
            }
           //system.debug('lastLessonDateObj'+lastLessonDateObj);
           //system.debug('withdrawSummary.refund'+withdrawSummary.refund);
           //system.debug('withdrawSummary.deposit'+withdrawSummary.deposit);
           //system.debug('withdrawSummary.total'+withdrawSummary.total);
            String chargeId = '';
            if(isPromotionalEnrolment){
                chargeId = fetchCurrentMonthPrepaymentEntry(enrolment,lastLessonDateObj,nextBillingDate);
            }else{
                chargeId = fetchCurrentMonthPaymentEntry(enrolment,lastLessonDateObj);
            }
            // 14 Sep, 2020 <  01/10/2020
            if(String.isNotBlank(chargeId) && (lastLessonDateObj < nextBillingDate)){
                //nishi: 20-oct-2020: we get all refund amount according to  current date to next billing date bookings.
                withdrawSummary.refund += getLessonRefundAmount(enrolment,lastLessonDateObj,nextBillingDate,isPromotionalEnrolment); 
               /* withdrawSummary.refund += getLessonRefundAmount(enrolment,lastLessonDateObj);  
                 //start:  added by nishi: 21-aug-2020: if next Billing date is greated then next month
                    date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1); // 1-10-2020
                    if(nextBillingDate >= nextMonthDate && lastLessonDateObj.Month() < nextMonthDate.addMonths(-1).Month()){ 
                        withdrawSummary.refund += getLessonRefundAmount(enrolment,nextMonthDate.addMonths(-1));  
                    }
               */
               //start:  added by nishi: 21-aug-2020: if next Billing date is greated then next month
       
            }
           system.debug('withdrawSummary.refund'+withdrawSummary.refund);
        }
        return withdrawSummary;
    }
    
    public static Map<String, String> getInvoiceFromEnrolment(String enrolmentId){
        Map<String, String> invoiceNameMap = new Map<String, String>();
        if(String.isNotBlank(enrolmentId)){
            List<Invoice_Line_Item__c> invoiceLineItem = [SELECT Id, Invoice__c, Invoice__r.Name FROM Invoice_Line_Item__c 
                                                          WHERE Enrolment__c =: enrolmentId 
                                                          AND Month__c = THIS_MONTH 
                                                          //AND Invoice_Date__c = THIS_MONTH 
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
        Decimal invoiceDeposit = 0;
        Decimal paymentDeposit = 0;
        Decimal depositToReturn = 0;
        Set<String> statusSet = new Set<String>{ConstantsClass.voidInvoiceStatus, ConstantsClass.cancelledInvoiceStatus};
            for(Invoice_Line_Item__c objLineItem : [SELECT Id,Amount__c FROM Invoice_Line_Item__c 
                                                    WHERE IS_Deposit__c = TRUE 
                                                    AND Enrolment__c =:enrolId 
                                                    AND Invoice__r.Status__c NOT IN :statusSet]){
                invoiceDeposit += objLineItem.amount__c;
            }
        for(Payment__c payment : [SELECT Id, Payment_Amount__c 
                                    FROM Payment__c 
                                    WHERE Enrolment__c =: enrolId 
                                    AND ((RecordType.Name =: ConstantsClass.paymentAsDepositRecordType 
                                    AND Payment_Status__c != :ConstantsClass.paymentVoid) OR
                                     (RecordType.Name = 'Refund' AND Payment_Status__c =: ConstantsClass.paymentSuccessStatus))]){
            paymentDeposit += payment.Payment_Amount__c;
        }
       //system.debug('invoiceDeposit'+invoiceDeposit);
       //system.debug('paymentDeposit'+paymentDeposit);
        depositToReturn = invoiceDeposit - paymentDeposit;
      //system.debug('depositToReturn'+depositToReturn);
        return depositToReturn;
    }  


    public  static Date getNextBillingDate(String enrolId){
        Date nextBillingDate;
        List<Subscription_Line_Item__c> subscriptionLineItemList = [SELECT Id, Next_Bill_Date__c FROM Subscription_Line_Item__c
                                                                    WHERE Enrolment__c =: enrolId
                                                                    And Status__c =: ConstantsClass.activeStatus];
        if(subscriptionLineItemList.size() > 0){
            nextBillingDate = subscriptionLineItemList[0].Next_Bill_Date__c;
        }
        return nextBillingDate;
    }
    
    public static Decimal getLessonRefundAmount(Enrolment__c objEnrol,Date lastLessonDate,Date nextBillingDate,Boolean isPromotionalEnrolment){
        Decimal amount = 0;
        List<Booking__c> bookings = getCurrentBilledBooking(objEnrol.id,lastLessonDate,nextBillingDate);
       //system.debug('bookings'+bookings);
        Integer count= 0;
        Integer regularcount= 0;
        for(Booking__c objBook : bookings){
            if(objBook.booking_date__c > lastLessonDate){
                count+=1;
                if(objBook.Type__c=='Regular'){
                    regularcount+=1;
                }
            }
        }
       system.debug('count'+count);
        if(count >0){
            amount = count * objEnrol.package__r.unit_fee__c;
            if(objEnrol.Center__r != null 
            && objEnrol.Center__r.Country__r != null 
            && objEnrol.Center__r.Country__r.Tax_Rate__c != null
            && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                amount+= (amount  * objEnrol.Center__r.Country__r.Tax_Rate__c)  / 100;
            }
            system.debug('amount'+amount);
        }
        if(isPromotionalEnrolment){
            if(regularcount >0){
                Decimal noOfMonths = String.isNotBlank(objEnrol.Package__r.Promotion_period_In_months__c) ? Integer.valueOf(objEnrol.Package__r.Promotion_period_In_months__c) : 1;
                Decimal preUnitDiscountAmount = objEnrol.Package__r.Promotion_Discount__c != null ?(((objEnrol.Package__r.Promotion_Discount__c / noOfMonths)/4)*regularcount) :0;
                if(objEnrol.Center__r != null 
                    && objEnrol.Center__r.Country__r != null 
                    && objEnrol.Center__r.Country__r.Tax_Rate__c != null
                    && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                    preUnitDiscountAmount += (preUnitDiscountAmount * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
                }
                system.debug('preUnitDiscountAmount'+preUnitDiscountAmount);
                amount-=preUnitDiscountAmount;
            }
        }
       system.debug('amount'+amount);
        return amount;
    }
    
    
    // return currentBilledBookings

    //1-aug-2020 last lesson and 1-Oct-2020 is nextBillingDate then we get all Booking upto nextBillingDate
    private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDateObj,Date nextBillingDate){
       system.debug('nextBillingDate'+nextBillingDate);
       system.debug('lastLessonDateObj'+lastLessonDateObj);

        return [SELECT Booking_Date__c,Type__c FROM Booking__c 
                WHERE Enrolment__c=: enrolId 
                AND Booking_Date__c >=: lastLessonDateObj 
                AND Booking_Date__c <: nextBillingDate
                AND (Type__c='Regular' or Type__c ='Ad-hoc') 
                and (Status__c = :ConstantsClass.statusScheduled OR Status__c = :ConstantsClass.statusPending)];
    }   

    

    // added by nishi:20-oct-2020:End for get Promo and prepayment enrolment withdrwal refund amount
    
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
                                  Package__r.Name, Package__r.Unit_Fee__c, Student__r.Name 
                                  FROM Booking__c 
                                  WHERE Enrolment__c =: enrolId 
                                  AND Type__c =: typeRegular 
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
           //system.debug('nextBillingDate'+nextBillingDate);
           //system.debug('bookObj.Booking_Date__c'+bookObj.Booking_Date__c);
            if(bookObj.Booking_Date__c < nextBillingDate){
                if(mapOfInvoiceName.keyset().size() > 0){
                    lesson.status = mapOfInvoiceName.get('Id')+':'+ mapOfInvoiceName.get('Name');
                }else{
                    lesson.status = 'Billed';
                }
                
            }else if(bookObj.Booking_Date__c >= nextBillingDate){
                lesson.status = 'Deposit';
            }
           //system.debug('lesson.status'+lesson.status);
            reverselessonList.add(lesson); 
        }
       //system.debug('reverselessonList'+reverselessonList);
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
        for(Booking__c bookObj : [SELECT Id, Student__r.Name, Booking_Date__c, Canceled_Date__c, Start_Time__c, 
        Available_Make_up_Units__c, Make_up_Expiry_Date__c 
        FROM Booking__c WHERE enrolment__c =: enrolId 
        AND Type__c IN: bookingTypes AND Status__c =: statusCanceled 
        AND Available_Make_up_Units__c > 0 AND Make_up_Expiry_Date__c >= TODAY ORDER BY Canceled_Date__c]){
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
       //system.debug('lessonsList'+lessonsList);
        return lessonsList;
    } 
    
    public static Enrolment__c getEnrolDetails(String bookingId){
        Enrolment__c enrol = new Enrolment__c();
        List<Enrolment__c> enrolList = [SELECT Id,Name, Student__r.Name,Parent__c, Package__r.Name, Package__r.Deposit_Fee__c, Package__r.Unit_Fee__c,
                                        Center__r.Name, Lessons_Start_Date__c, Lesson_Start_time__c, Notice_Period_End_Date__c, Effective_Date__c, 
                                        Center__r.country__r.Id, Center__r.Country__r.Stripe_Base_Url__c, Center__r.Country__r.Stripe_Secret_Key__c, 
                                        Center__r.Country__r.Tax_Rate__c ,Type_of_Package__c,Center__r.Organisation__r.Stripe_Base_Url__c, Center__r.Organisation__r.Stripe_Secret_Key__c, Center__r.Organisation__r.Tax_Rate__c,
                                        Package__r.Is_Promotion_Discount__c,Package__r.Package_after_Promotion__c, Package__r.Promotion_period_In_months__c, Package__r.Promotion_Discount__c
                                        FROM Enrolment__c WHERE Id IN 
                                        (SELECT Enrolment__c FROM Booking__c WHERE Id =: bookingId)];
        if(enrolList.size() > 0){
            enrol = enrolList[0];
        }
        
        return enrol;
    }
    
    public  static List<Lessons> getFinalDepositSummary(List<lessons> lessons){
        List<Lessons> depositLessons = new List<Lessons>();
        Lessons currentLesson = new Lessons();
       //system.debug('lessons'+lessons);
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
       //system.debug('depositLessons'+depositLessons);
        return depositLessons;
    }
    
// @jatin:28-Nov-2019 :get classes details according to centerid, teacherid, new selected package , weekday and new effective date
    @RemoteAction
    public static List<ClassDetail> getUpgradedClassDetails(String centerId,String teacherId,String selectedPackage,String effectiveDateStr,string oldClassId){
        List<ClassDetail> classDetails = new List<ClassDetail>();
        List<Class__c> listofClass = new List<Class__c>();
        if(String.isNotBlank(centerId) && String.isNotBlank(teacherId) && String.isNotBlank(selectedPackage) &&  String.isNotBlank(effectiveDateStr)  &&  String.isNotBlank(oldClassId)){
            Date effectiveDate; string weekday;
            if(String.isNotBlank(effectiveDateStr)){
                effectiveDate = Date.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
                 weekday =DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2])).format('EEE');
            }
            //system.debug('@effectiveDate'+effectiveDate);
            listofClass = [SELECT Id, Name
                            FROM Class__c 
                            WHERE Centre_Name__c =: centerId 
                            AND Teacher__c =: teacherId
                            AND Package__c =:selectedPackage
                            AND Class_Day__c =:weekday
                            AND Class_Start_Date__c <=:effectivedate
                            AND Active__c = TRUE];
                            //system.debug('@@listofClass'+listofClass);
            if(listofClass.size() > 0){
                for(Class__c objClass :listofClass){
                    ClassDetail objClassDetail = new ClassDetail();
                    objClassDetail.name = objClass.name;
                    objClassDetail.id = objClass.id;
                    classDetails.add(objClassDetail);
                }
            }
        }
        //system.debug('classDetails'+classDetails);
        return classDetails;
    }

    // @jatin:9-dec-2019:Change enrolment enhancement requirment  :
            //New timeslot should also include non-working timeslots starting 8:00 AM to 8:00 PM 
            //for all working days and all non-working days
    @RemoteAction
    public static List<String> getTimeSlotsAccordinglyToChangeEnrolSpecificUsers(String centerId, String teacherId, String upgradePackage, String enrolmentId, String effectiveDateStr){
        List<String> availTimeSlots = new List<String>();
        Set<Integer> timeSlotsToRemove = new Set<Integer>();
        Set<String> bookingTimeSlots, unOrderedTimeSlots = new Set<String>();
        Set<String> fifthLessonTimeSlots = new Set<String>();
        DateTime effectiveDate;
        List<Package__c> newPackageList = new List<Package__c>();
        if(String.isNotBlank(effectiveDateStr)){
            effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
        }
        DateTime startTime = DateTime.newInstance(effectiveDate.date(),  Time.newInstance(8, 0, 0, 0));
        DateTime endTime = DateTime.newInstance(effectiveDate.date(),  Time.newInstance(20, 0, 0, 0));
        if(startTime != NULL && endTime != NULL){
            availTimeSlots = getFormatedTimeSlotList(startTime, endTime);
        }
       return getAvailTimeSlots( centerId,  teacherId,  upgradePackage,  enrolmentId, 
                                                    effectiveDate,availTimeSlots);

    }

    Private static List<String> getAvailTimeSlots(String centerId, String teacherId, String upgradePackage, String enrolmentId, 
                                                    DateTime effectiveDate,List<String> availTimeSlots){
        Set<Integer> timeSlotsToRemove = new Set<Integer>();
        Set<String> bookingTimeSlots, unOrderedTimeSlots = new Set<String>();
        Set<String> fifthLessonTimeSlots = new Set<String>();
        Set<String> groupClassTimeSlots = new Set<String>();
        List<Package__c> newPackageList = new List<Package__c>();
        if(String.isNotBlank(upgradePackage)){
            newPackageList = [SELECT Id, Duration__c FROM Package__c WHERE Id =: upgradePackage];
        }
        system.debug('@availTimeslots'+availTimeslots);
        if(availTimeSlots.size() > 0 && String.isNotBlank(enrolmentId)){
            bookingTimeSlots = getScheduledBookingSlots(enrolmentId, effectiveDate.date(), centerId, teacherId);
        }
       system.debug('@bookingTimeSlots'+bookingTimeSlots);
        if(bookingTimeSlots != Null && bookingTimeSlots.size() > 0){
            for(String currentValue : bookingTimeSlots){
                system.debug('@currentValue'+currentValue);
                if(availTimeslots.contains(currentValue)){
                    availTimeslots.remove(availTimeslots.indexOf(currentValue));    
                }
            }
        }
        system.debug('@availTimeslots'+availTimeslots);
        // @@jatin:2Jan-2020: for get Group class bookings time slots
        if(availTimeSlots.size() > 0  && String.isNotBlank(enrolmentId)){
            groupClassTimeSlots = fetchSelectedGroupClassTimeSlots(effectiveDate.date(), centerId, teacherId);
        }
        system.debug('@groupClassTimeSlots'+groupClassTimeSlots);
        if(groupClassTimeSlots != Null && groupClassTimeSlots.size() > 0){
            for(String currentValue : groupClassTimeSlots){
                if(availTimeslots.contains(currentValue)){
                    availTimeslots.remove(availTimeslots.indexOf(currentValue));    
                }
            }
        }
      system.debug('@availTimeslots'+availTimeslots);
        if(availTimeSlots.size() > 0  && String.isNotBlank(enrolmentId)){
            fifthLessonTimeSlots = fetchSelectedFifthLessons(effectiveDate.date(), centerId, teacherId, enrolmentId);
        }
       system.debug('@fifthLessonTimeSlots'+fifthLessonTimeSlots);
        if(fifthLessonTimeSlots != Null && fifthLessonTimeSlots.size() > 0){
            for(String currentValue : fifthLessonTimeSlots){
                if(availTimeslots.contains(currentValue)){
                    availTimeslots.remove(availTimeslots.indexOf(currentValue));    
                }
            }
        }
       system.debug('@availTimeslots'+availTimeslots);
       system.debug('@newPackageList'+newPackageList);
        if(availTimeSlots != null && availTimeSlots.size() > 0 && newPackageList.size() > 0){
            unOrderedTimeSlots  = removeUnselectableSlots(availTimeSlots, Integer.valueOf(newPackageList[0].Duration__c));
        }
      system.debug('@unOrderedTimeSlots'+unOrderedTimeSlots);
        if(unOrderedTimeSlots != Null && unOrderedTimeSlots.size() > 0){
            for(String currentValue : unOrderedTimeSlots){
                if(availTimeslots.contains(currentValue)){
                    availTimeslots.remove(availTimeslots.indexOf(currentValue));
                }
            }
        }
      system.debug('availTimeSlots'+availTimeSlots);
        return availTimeSlots;
    }

    //// @@jatin:2Jan-2020: for get Group class bookings time slots
    public static Set<String> fetchSelectedGroupClassTimeSlots(Date bookingsDate, String centerId, String teacherId){
        Set<Date> dt = new Set<Date>();
        dt.add(bookingsDate);
        List<Booking__c> bookingList = getGroupClassBookingsOnSelectedDates(centerId, teacherId, dt);
        Set<String> bookingSlots = new Set<String>();
        if(bookingList.size() > 0){
            for(Booking__c currentBook : bookingList){
                bookingSlots.addAll(getFormatedTimeSlotList(DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c).addMinutes(-15)));
            }
        }
        return bookingSlots;
    }

    // @@jatin:2Jan-2020: for Group class type bookings query
    private static List<Booking__c> getGroupClassBookingsOnSelectedDates(String centerId, String teacherId, Set<Date> dates){
        String groupBookingRecordType = ConstantsClass.groupBookingRecordType;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.groupTypeBooking};
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};     
        Date dt, endDt;
        String busyType = ConstantsClass.typeBusy;
       
        String weekDay;
        String queryStr = 'SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c';
        queryStr += ' WHERE RecordType.Name =: groupBookingRecordType AND Start_Time__c != NULL AND End_Time__c != NULL AND Class__C != null ';
        if(String.isNotBlank(centerId)){
            queryStr += ' AND Center__c =: centerId';
        }
        if(String.isNotBlank(teacherId)){
            queryStr += ' AND Teacher_Account__c =: teacherId';
        }
        
        if(dates.size() > 0){
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
            queryStr += ' AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType AND Category__c NOT IN: busyStatusSet))';
            
        }

        //System.debug('@@@@queryStr'+queryStr);
        
        return Database.query(queryStr);
    }

    @RemoteAction
    public static List<String> getTimeSlotsAccordingly(String centerId, String teacherId, String upgradePackage, String enrolmentId, String effectiveDateStr){
        List<String> availTimeSlots = new List<String>();
        Set<Integer> timeSlotsToRemove = new Set<Integer>();
        Set<String> bookingTimeSlots, unOrderedTimeSlots = new Set<String>();
        Set<String> fifthLessonTimeSlots = new Set<String>();
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
       system.debug('availTimeSlots'+availTimeSlots);
        return  getAvailTimeSlots( centerId,  teacherId,  upgradePackage,  enrolmentId, 
                                                    effectiveDate,availTimeSlots);
       
    }
    
    private static List<String> getTeacherWorkingHourTimeSlotList(String teacherId, String centerId, String weekDay){
        List<String> availTimeSlots = new List<String>();
        DateTime startTime, endTime;
        List<Teacher_Working_Hour__c> teachersHours = [SELECT Id, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId 
                                                       AND Teacher_Name__c =: teacherId AND Working_Day__c =: weekDay AND Active__c =: True 
                                                       AND Break_Time__c =: False];
        
        if(teachersHours.size() > 0){
            startTime = DateTime.newInstance(Date.today(), teachersHours[0].Start_Time__c);
            endTime = DateTime.newInstance(Date.today(), teachersHours[0].End_Time__c );
            if(startTime != NULL && endTime != NULL){
                availTimeSlots = getFormatedTimeSlotList(startTime, endTime);
            }
        }
        return availTimeSlots;
    }
    
    public static Set<String> getScheduledBookingSlots(String enrolmentId, Date bookingsDate, String centerId, String teacherId){
        Set<Date> dt = new Set<Date>();
        dt.add(bookingsDate);
        List<Booking__c> bookingList = getBookingsOnSelectedDates(centerId, teacherId, dt, enrolmentId, false);
        for(Booking__c obj : bookingList){
           system.debug('@@@BookingObj '+obj.start_Time__c + '- '+obj.Id);
        }
        
        Set<String> bookingSlots = new Set<String>();
        if(bookingList.size() > 0){
            for(Booking__c currentBook : bookingList){
                bookingSlots.addAll(getFormatedTimeSlotList(DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c).addMinutes(-15)));
            }
        }
        return bookingSlots;
    }

    Public static Set<String> fetchSelectedFifthLessons(Date lessonDate, String centerId, String teacherId, String enrolmentId){
        Date endTime;
        String weekDay;
        if(lessonDate != NULL){
            endTime = lessonDate.addMonths(1);
            weekDay = DateTime.newInstance(lessonDate, Time.newInstance(0, 0, 0, 0)).format('EEEE');
        }
        Set<String> lessonSlots = new Set<String>();    
        if(lessonDate != NULL && String.isNotBlank(centerId) && String.isNotBlank(teacherId) && String.isNotBlank(weekDay)){
            List<Fifth_Lesson__c> fifthLessonsList = [SELECT Id, Start_Time__c, End_Time__c, Booking_Date__c FROM Fifth_Lesson__c WHERE IsActive__c = TRUE 
                                                      AND Teacher_Account__c =: teacherId AND Center__c =: centerId AND Enrolment__c != :enrolmentId AND 
                                                      Booking_Date__c >=: lessonDate AND Booking_Date__c <= :endTime AND Booking_Day__c =: weekDay];
            
            if(fifthLessonsList.size() > 0){
                for(Fifth_Lesson__c currentlesson : fifthLessonsList){
                    lessonSlots.addAll(getFormatedTimeSlotList(DateTime.newInstance(currentlesson.Booking_Date__c, currentlesson.Start_Time__c), DateTime.newInstance(currentlesson.Booking_Date__c, currentlesson.end_Time__c).addMinutes(-15)));
                }
            }
            
        }
        return lessonSlots;
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
            innerLoop = (i + duration / 15) > timeSlots.size() ? false : true; //commented by nishi:15-Dec-2020: (i + duration / 15) >= timeSlots.size() ? false : true;
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
    public  static DateTime getDateTimeFromString(String currentTime){
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

    // 9-dec-2019:jatin: if user change enrllment then show this summary
    @RemoteAction
    public static UpgradeDowngradePackageSummary getChangeEnrollmentPackageSummary(String typeOfSummary,String enrolmentId,
                                                                                     String newTeacher, String oldTeacher,                 
                                                                                    String newPackageId, String oldPackageId, 
                                                                                    String newEffectiveDate, String currentEffectiveDate, 
                                                                                    String newAvailTimeSlots,String oldAvailTimeSlots){
        Map<String, String> enrolSummary = new Map<String, String>();
        UpgradeDowngradePackageSummary summary = new UpgradeDowngradePackageSummary();
        DateTime newDateTime,currentDateTime;
        //system.debug('@@oldPackageId'+oldPackageId);
        //system.debug('@@newPackageId'+newPackageId);
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            summary = getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
            //system.debug('@@summary.newPackageId = '+summary.newPackageId);
            //system.debug('@@summary.newPackageName = '+summary.newPackageName);
        }
        if(String.isNotBlank(newEffectiveDate) && String.isNotBlank(newAvailTimeSlots)){
            newDateTime = getDateTimeFromString(newAvailTimeSlots);
            newDateTime = DateTime.newInstance(Date.valueOf(newEffectiveDate), newDateTime.time());
            //summary.newDayAndTime = newDateTime.format('EEE, MMM dd YYYY h:mm a');
            summary.newDayAndTime = newDateTime.format('EEE @ h:mm a');
            summary.effectiveDate = newDateTime.format('EEE, MMM dd YYYY');
        }
        
        if(string.isNotBlank(newTeacher) && string.isNotBlank(oldTeacher) ){
            set<String> teacherIds = new Set<String>{newTeacher,oldTeacher};
            Map<String,Account> mapOfAccount = New Map<String,Account>([Select id,Name from Account where Id in :teacherIds]);
            if(mapOfAccount.containsKey(newTeacher)){
                summary.newTeacherName = mapOfAccount.get(newTeacher).Name;
                summary.newTeacherId = mapOfAccount.get(newTeacher).Id;
            }
            /*if(mapOfAccount.containsKey(oldTeacher)){
                summary.oldTeacherName = mapOfAccount.get(oldTeacher).Name;
                summary.oldTeacherId = mapOfAccount.get(oldTeacher).Id;
            }*/
            
        }
         if(String.isNotBlank(currentEffectiveDate)  && String.isNotBlank(oldAvailTimeSlots) ){
            currentDateTime = getDateTimeFromString(oldAvailTimeSlots);
            currentDateTime = DateTime.newInstance(Date.valueOf(currentEffectiveDate), currentDateTime.time());
            summary.currentDayAndTime = newDateTime.format('EEE @ h:mm a');
            summary.currentEffectiveDate = currentDateTime.format('EEE, MMM dd YYYY');
        }
         // 12-dec-2019:jatin: get all pervious fields teacher,package,parent , studentname ,day
        if(String.isNotBlank(enrolmentId)){
            enrolSummary = getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
            if(enrolSummary.containsKey('currentTeacher')){
                summary.oldTeacherName = enrolSummary.get('currentTeacher');
            }
            if(enrolSummary.containsKey('currentTeacherId')){
                summary.oldTeacherId = enrolSummary.get('currentTeacherId');
            }
            if(enrolSummary.containsKey('currentPackage')){
                summary.oldPackageName = enrolSummary.get('currentPackage');
            } 
            if(enrolSummary.containsKey('currentPackageId')){
                summary.oldPackageId = enrolSummary.get('currentPackageId');
            } 
                
            if(enrolSummary.containsKey('currentDay')){
                summary.currentDayAndTime = enrolSummary.get('currentDay');
            }
             if(enrolSummary.containsKey('studentName')){
                summary.studentName = enrolSummary.get('studentName');
            }
            if(enrolSummary.containsKey('parentName')){
                summary.parentName = enrolSummary.get('parentName');
            }
        }
        return summary;
    }
     // @jatin 28-Nov-2019 : get summury related with new and old class details
    @RemoteAction
    public static UpgradeDowngradePackageSummary  getUpgradeDowngradePackageSummary(String oldPackageId, String newPackageId, 
                                                                                    String effectiveDate, String availTimeSlots, 
                                                                                    String enrolmentId, String typeOfSummary){
                                                                                        
        Map<String, String> enrolSummary = new Map<String, String>();
        DateTime newDateTime;
        Date nextBillDate;
        Package__c newPackg, oldPackg = new Package__c();
        Integer minutesOfFifthBooking = 0;
        Integer countWithNewPackage = 0;
        string typeofpackage ='';
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>(); 
        UpgradeDowngradePackageSummary summary = new UpgradeDowngradePackageSummary();
       
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            summary = getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
            newPackg = summary.newPackage;
            oldPackg = summary.oldPackage;            
        }
        if(String.isNotBlank(enrolmentId)){
            summary.currentPackageDeposit = getDepositFromFile(enrolmentId);
            enrolSummary = getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
            // added by nishi: 20-Oct-2020: for now user also can change enrolment process which type of package is promo and prepayment
            if(enrolSummary.containsKey('enrolentpackagetype')){
                typeofpackage = enrolSummary.get('enrolentpackagetype');
            }
            // added by nishi:end: 20-Oct-2020: for now user also can change enrolment process which type of package is promo and prepayment
            if(enrolSummary.containsKey('currentDay')){
                summary.currentDayAndTime = enrolSummary.get('currentDay');
            }
            if(enrolSummary.containsKey('currentMonthInvoice')){
                summary.invoiceForCurrentMonth = Decimal.valueOf(enrolSummary.get('currentMonthInvoice'));
               //added by nishi:14-Aug-2020: for manage facility fee
               // summary.invoiceForCurrentMonth += summary.oldfacilityFee;
                
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
        boolean isPromotionalEnrolment = false;
        if(typeofpackage == ConstantsClass.prePaymentType || typeofpackage == ConstantsClass.PromoTypePayment){
            isPromotionalEnrolment = true;
        }
        Decimal noOfMonths = isPromotionalEnrolment && String.isNotBlank(oldPackg.Promotion_period_In_months__c) ? Integer.valueOf(oldPackg.Promotion_period_In_months__c) : 1;
        decimal oldpackageunitFee= isPromotionalEnrolment ? (oldPackg.Package_Fee__c/noOfMonths)/4 :oldPackg.Unit_Fee__c;                  
        if((typeOfSummary == 'upgrade' || typeOfSummary == 'downgrade') && newDateTime != NULL && String.isNotBlank(enrolmentId)){
            List<Date> dates =  getMonthDates(newDateTime);
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
            Decimal depositeFee = BillingUtility.roundOffAmount(newPackg.Deposit_Fee__c - summary.currentPackageDeposit);
            summary.invoiceDepositTopup = depositeFee;
            Decimal newPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNewPackage ;
            Decimal newPackageFacilityPrice = 0;
            system.debug('newPackageUnitPrice'+newPackageUnitPrice);
             //start: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
            // if(summary.newfacilityFee >  0 && summary.oldfacilityFee > 0){
            //     newPackageFacilityPrice =  (summary.newfacilityFee - summary.oldfacilityFee)*countWithNewPackage ;
            // }
             //end: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                  
           //system.debug('oldPackg.Unit_Fee__c'+oldPackg.Unit_Fee__c);
           //system.debug('newPackg.Unit_Fee__c'+newPackg.Unit_Fee__c);
           //system.debug('countWithNewPackage'+countWithNewPackage);
           //system.debug('newPackageUnitPrice'+newPackageUnitPrice);
            if(typeOfSummary == 'upgrade'){
                if(summary.taxRate>0){
                    newPackageUnitPrice += (newPackageUnitPrice * (Decimal.valueOf(summary.taxRate)/100));
                    system.debug('totalAmount'+totalAmount);
                     //start: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                    // if(newPackageFacilityPrice > 0){
                    //     newPackageFacilityPrice += newPackageFacilityPrice * (Decimal.valueOf(summary.taxRate)/100);
                    // }
                     //end: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
            
                }
                totalAmount = newPackageUnitPrice;
                //system.debug('newPackageFacilityPrice with gst - '+newPackageFacilityPrice);
                //start: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                // if(newPackageFacilityPrice > 0){
                //     totalAmount += newPackageFacilityPrice;
                //     newPackageUnitPrice+= newPackageFacilityPrice;
                // }
                 //end: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
            
                //system.debug('newPackageUnitPrice'+newPackageUnitPrice);
                totalAmount +=   depositeFee ;
               //system.debug('totalAmount - '+totalAmount);
                if(newDateTime < nextBillDate){
                    ////system.debug('totalAmount'+totalAmount);
                      // added by Nishi: 12-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
                        //  ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 
                        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
                        ////system.debug('nextMonthDate'+nextMonthDate);
                        ////system.debug('nextBillDate'+nextBillDate);
                        Integer countWithNextPackage = 0;
                        Decimal nextPackageUnitPrice =0;
                        // added by nishi: 20-Oct-2020: for now user also can upgrade enrolment process which type of package is promo and prepayment
                        if(isPromotionalEnrolment){
                            // added by nishi: 28-Oct-2020: if enrolment package is promitional then we show  invoice topup amount is current month to next billing date
                           
                            Map<String, List<Date>> mapOfDates = BillingUtility.getDateMap(newDateTime.date(),nextBillDate);
                            decimal countWithPackage = 0;
                            if(enrolmentList.size() > 0 && String.isNotBlank(enrolmentList[0].Lesson_Day__c) && mapOfDates.containsKey(enrolmentList[0].Lesson_Day__c)){
                                List<Date> listOfDates = mapOfDates.get(enrolmentList[0].Lesson_Day__c);
                                listOfBookings = fetchBookingsForUpgrade(enrolmentId, listOfDates);
                                for(Booking__c objBooking : listOfBookings){
                                    if(objBooking.Booking_Date__c >= newDateTime.date() && objBooking.Booking_Date__c < nextBillDate){
                                        if(objBooking.Type__c == ConstantsClass.bookTypeRegular){
                                            countWithNewPackage +=1;
                                        }
                                    }
                                }
                            }
                            system.debug('@@countWithNewPackage'+countWithNewPackage);
                            system.debug('@@oldpackageunitFee'+oldpackageunitFee);
                            newPackageUnitPrice = (newPackg.Unit_Fee__c - oldpackageunitFee)*countWithNewPackage ;
                            if(summary.taxRate>0){
                                newPackageUnitPrice += (newPackageUnitPrice * (Decimal.valueOf(summary.taxRate)/100));
                            }
                            system.debug('@@newPackageUnitPrice'+newPackageUnitPrice);
                            totalAmount = newPackageUnitPrice;
                            totalAmount +=   depositeFee ;
                            system.debug('@@totalAmount'+totalAmount);
                            // added by nishi: 28-Oct-2020: if enrolment package is promitional then we show  invoice topup amount is current month to next billing date 

                            Decimal preUnitDiscountAmount = oldPackg.Promotion_Discount__c != null ?(((oldPackg.Promotion_Discount__c / noOfMonths)/4)*countWithNewPackage) :0;
                            Decimal gstDiscountAmount=0;
                            if(summary.taxRate>0){
                                preUnitDiscountAmount += (preUnitDiscountAmount * (Decimal.valueOf(summary.taxRate)/100));
                            }
                            newPackageUnitPrice +=preUnitDiscountAmount;
                            totalAmount +=preUnitDiscountAmount;
                            system.debug('@@@totalAmount'+totalAmount);
                        }else{
                            if(nextBillDate >= nextMonthDate && newDateTime.month() < nextMonthDate.addMonths(-1).month()){
                                if(String.isNotBlank(enrolmentId)){
                                    List<Booking__c> nextMonthlistOfBookings =UpgradeDowngradeController.fetchListOfNextMonthBookings(enrolmentId);
                                    //system.debug('nextMonthlistOfBookings'+nextMonthlistOfBookings);
                                    for(Booking__c objBooking : nextMonthlistOfBookings){
                                        if(objBooking.Booking_Date__c <= nextMonthDate){
                                            if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){
                                                countWithNextPackage += 1;
                                            }
                                        }
                                    }
                                }
                                nextPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNextPackage ;
                            //system.debug('nextPackageUnitPrice'+nextPackageUnitPrice);
                                Decimal nextPackageFacilityPrice = 0;
                                //start: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                                // if(summary.newfacilityFee > 0 && summary.oldfacilityFee > 0){
                                //     nextPackageFacilityPrice =  (summary.newfacilityFee - summary.oldfacilityFee)*countWithNextPackage ;
                                // }
                                // if(summary.taxRate > 0 && nextPackageFacilityPrice > 0){
                                //     nextPackageFacilityPrice += nextPackageFacilityPrice * (Decimal.valueOf(summary.taxRate)/100);
                                // }
                                //end: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                                if(summary.taxRate > 0 && nextPackageUnitPrice > 0){
                                    nextPackageUnitPrice += (nextPackageUnitPrice * (Decimal.valueOf(summary.taxRate)/100));
                                }
                                totalAmount +=  nextPackageUnitPrice;
                                //start: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                                // if(nextPackageFacilityPrice > 0){
                                //     totalAmount +=   nextPackageFacilityPrice ; 
                                //     nextPackageUnitPrice+= nextPackageFacilityPrice;
                                // }
                                //end: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                                
                                //system.debug('totalAmount - '+totalAmount);
                            }
                        }
                        // added by Nishi: 12-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
                        summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                        system.debug('@@totalAmount'+totalAmount);
                        system.debug('n@@ewPackageUnitPrice'+newPackageUnitPrice);
                        summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice+nextPackageUnitPrice);
                }else{
                    summary.invoiceTopup = depositeFee;
                    summary.invoiceDepositLessonTopup = 0;
                   //system.debug('depositeFee'+depositeFee);
                }
            }else if(typeOfSummary == 'downgrade'){
                totalAmount = 0;

                Date firstDate = Date.newInstance(newDateTime.year(), newDateTime.month(), 01);
                Integer daysInMonth = Date.daysInMonth(newDateTime.year(), newDateTime.month());
                Date lastDate = Date.newInstance(newDateTime.year(), newDateTime.month(), daysInMonth);
                Map<String, List<Date>> mapOfDates = new Map<String, List<Date>>();
                if(newDateTime >= nextBillDate){
                    //2020-08-01 - 2020-08-31
                    mapOfDates = BillingUtility.getDateMap(firstDate,lastDate);
                }else{
                    //2020-08-22 - 2020-08-31
                    mapOfDates = BillingUtility.getDateMap(newDateTime.date(),lastDate);
                }
               //system.debug('newDateTime'+newDateTime); //2020-08-22
               //system.debug('firstDate'+firstDate);//2020-08-01
               //system.debug('lastDate'+lastDate);//2020-08-31
               //system.debug('mapOfDates'+mapOfDates);
                Integer countWithOldPackage = 0;
                Integer countWithNewPackageDowngrade = 0;
                if(enrolmentList.size() > 0 && String.isNotBlank(enrolmentList[0].Lesson_Day__c) && mapOfDates.containsKey(enrolmentList[0].Lesson_Day__c)){
                    List<Date> listOfDates = mapOfDates.get(enrolmentList[0].Lesson_Day__c);
                    if(listOfDates.size() == 5){
                        listOfDates.remove(4);
                    }
                   //system.debug('listOfDates'+listOfDates);//listOfDates(2020-08-22 00:00:00, 2020-08-29 00:00:00)
                    for(Date objDate : listOfDates){
                        if(objDate.day() <29){
                            //2020-08-1 < 2020-08-22
                            if(objDate < newDateTime.date() ){
                                countWithOldPackage +=1;   
                            }else if(objDate >= newDateTime.date()){
                                countWithNewPackageDowngrade +=1;
                            }
                        }
                    }
                }
               //system.debug('mapOfDates'+mapOfDates);
               //system.debug('countWithOldPackage'+countWithOldPackage); // 3
               //system.debug('countWithNewPackageDowngrade'+countWithNewPackageDowngrade);//1
                //22-aug-2020 >= 1-Aug-2020
                if(newDateTime >= nextBillDate){
                    Decimal newPackageLessonFee = 0;
                    Decimal newPackageFacilityFee = 0;
                    Decimal oldPackageFacilityFee = 0;
                    newPackageUnitPrice = 0;
                    newPackageUnitPrice = newPackg.Unit_Fee__c * countWithNewPackageDowngrade ;
                    Decimal oldPackageUnitPrice = oldPackg.Unit_Fee__c* countWithOldPackage;
                    // start:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                    // if(summary.newfacilityFee > 0){
                    //     newPackageFacilityFee = summary.newfacilityFee * countWithNewPackageDowngrade ;
                    // }
                    
                    // if(summary.newfacilityFee > 0){
                    //     oldPackageFacilityFee = summary.oldfacilityFee * countWithOldPackage ;
                    // }
                    // newPackageFacilityFee = newPackageFacilityFee + oldPackageFacilityFee;
                     //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                    newPackageUnitPrice = newPackageUnitPrice + oldPackageUnitPrice;
                    if(summary.taxRate > 0){
                        newPackageUnitPrice += newPackageUnitPrice * ((Decimal.valueOf(summary.taxRate))/100);
                        // start:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                        // if(newPackageFacilityFee > 0){
                        //     newPackageFacilityFee += newPackageFacilityFee * ((Decimal.valueOf(summary.taxRate))/100);
                        // }
                        //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                    
                    }
                   // summary.invoiceFacilityLessonTopup = newPackageFacilityFee;
                    summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice) ;
                    totalAmount += newPackageUnitPrice;
                    //totalAmount += newPackageFacilityFee;
                    totalAmount += depositeFee;
                    summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                } // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020  (If next month biiling Advance created Paid September payment) 
                // ex: 12-Aug-2020 effective date and next Billing date 1-sep-2020  (If current month biiling created Paid Augest payment)   
                else if(newDateTime < nextBillDate){
                    Decimal newPackageFacilityFee = 0;
                    Decimal oldPackageFacilityFee = 0;
                    Integer countWithNextMonthPackageDowngrade = 0;
                    Decimal newNextMonthPackageUnitPrice =0;
                    Decimal preUnitDiscountAmount =0;
                      // added by nishi: 23-Oct-2020: for now user also can upgrade enrolment process which type of package is promo and prepayment
                    if(isPromotionalEnrolment){
                        preUnitDiscountAmount = oldPackg.Promotion_Discount__c != null ?(((oldPackg.Promotion_Discount__c / noOfMonths)/4)*countWithNewPackage) :0;
                        Decimal gstDiscountAmount=0;
                        if(summary.taxRate>0){
                            preUnitDiscountAmount += (preUnitDiscountAmount * (Decimal.valueOf(summary.taxRate)/100));
                        }
                        summary.invoiceDiscountLessonCurrentMonthTopup = preUnitDiscountAmount;
                        system.debug('preUnitDiscountAmount'+preUnitDiscountAmount);
                    }else{
                    // added by nishi: 23-Oct-2020: for now user also can upgrade enrolment process which type of package is promo and prepayment
                        // added by Nishi: 19-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
                        // 1-oct-2020
                        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
                        if(nextBillDate >= nextMonthDate && newDateTime.month() < nextMonthDate.addMonths(-1).month()){
                            firstDate = Date.newInstance(nextMonthDate.addMonths(-1).year(), nextMonthDate.addMonths(-1).Month(), 1);
                            mapOfDates = BillingUtility.getDateMap(firstDate,nextMonthDate.addDays(-1));
                            if(enrolmentList.size() > 0 && String.isNotBlank(enrolmentList[0].Lesson_Day__c) && mapOfDates.containsKey(enrolmentList[0].Lesson_Day__c)){
                                List<Date> listOfDates = mapOfDates.get(enrolmentList[0].Lesson_Day__c);
                                if(listOfDates.size() == 5){
                                    listOfDates.remove(4);
                                }
                                for(Date objDate : listOfDates){
                                    if(objDate.day() <29){
                                        if(objDate < nextMonthDate){
                                            countWithNextMonthPackageDowngrade +=1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                     // added by Nishi: 12-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
                    system.debug('countWithNewPackageDowngrade'+countWithNewPackageDowngrade);//1 
                    if(summary.currentPackageDeposit == null){
                        summary.currentPackageDeposit = 0;
                    }
                    depositeFee = (newPackg.Deposit_Fee__c - summary.currentPackageDeposit);    
                   //system.debug('depositeFee'+depositeFee);
                    summary.invoiceDepositTopup = BillingUtility.roundOffAmount(depositeFee);
                    summary.positiveInvoiceAmount = BillingUtility.roundOffAmount(countWithNewPackageDowngrade * newPackg.Unit_Fee__c) ;
                    if(countWithNextMonthPackageDowngrade > 0){
                        summary.positiveNextMonthInvoiceAmount = BillingUtility.roundOffAmount(countWithNextMonthPackageDowngrade * newPackg.Unit_Fee__c) ;
                    }
                   //system.debug('summary.positiveInvoiceAmount'+summary.positiveInvoiceAmount);
                   //system.debug('summary.newfacilityFee'+summary.newfacilityFee);
                   
                   // start:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                //    if(summary.newfacilityFee > 0){
                //         summary.positiveFacilityInvoiceAmount = BillingUtility.roundOffAmount(countWithNewPackageDowngrade * summary.newfacilityFee) ;
                //     }
                   // end:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                    
                    summary.negativeInvoiceAmount = - (BillingUtility.roundOffAmount(countWithNewPackageDowngrade * oldpackageunitFee));
                    
                    if(countWithNextMonthPackageDowngrade > 0){
                        summary.negativeNextMonthInvoiceAmount =- (BillingUtility.roundOffAmount(countWithNextMonthPackageDowngrade * oldPackg.Unit_Fee__c)) ;
                    }
                   //system.debug('summary.negativeInvoiceAmount'+summary.negativeInvoiceAmount);
                   //system.debug('summary.oldfacilityFee'+summary.oldfacilityFee);
                   //start: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                //    if(summary.oldfacilityFee > 0){
                //         summary.negativeFacilityInvoiceAmount = - (BillingUtility.roundOffAmount(countWithNewPackageDowngrade * summary.oldfacilityFee));
                //     }
                    //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                    
                   //system.debug('summary.negativeFacilityInvoiceAmount'+summary.negativeFacilityInvoiceAmount);
                   //system.debug('summary.positiveFacilityInvoiceAmount'+summary.positiveFacilityInvoiceAmount);

                    newPackageUnitPrice = countWithNewPackageDowngrade * 
                                        (newPackg.Unit_Fee__c - oldpackageunitFee);
                    if(countWithNextMonthPackageDowngrade > 0){
                        newNextMonthPackageUnitPrice  =   countWithNextMonthPackageDowngrade *  (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);   
                       // newNextMonthPackageUnitPrice += (BillingUtility.roundOffAmount(newPackg.Unit_Fee__c) / Integer.valueOf(newPackg.duration__c))*minutesOfFifthBooking; 
                        if(summary.taxRate > 0){
                            newNextMonthPackageUnitPrice += newNextMonthPackageUnitPrice * (Decimal.valueOf(summary.taxRate)/100);
                        }
                    }              
                   //system.debug('newPackageUnitPrice'+newPackageUnitPrice);
                    //start: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                //    if(summary.newfacilityFee > 0 && summary.oldfacilityFee > 0){
                //         newPackageFacilityFee = countWithNewPackageDowngrade *  (summary.newfacilityFee - summary.oldfacilityFee);
                //     }
                     //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                  
                    //system.debug('newPackageFacilityFee'+newPackageFacilityFee);
                    //newPackageUnitPrice += ((newPackg.Unit_Fee__c) / Integer.valueOf(newPackg.duration__c))*minutesOfFifthBooking;
                    if(summary.taxRate > 0){
                        newPackageUnitPrice += newPackageUnitPrice * (Decimal.valueOf(summary.taxRate)/100);
                         //start: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                        // if(newPackageFacilityFee != 0){
                        //     newPackageFacilityFee += newPackageFacilityFee * (Decimal.valueOf(summary.taxRate)/100);
                        // }
                         //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                  
                    }
                    // added by nishi: 23-Oct-2020: for now user also can upgrade enrolment process which type of package is promo and prepayment
                    if(isPromotionalEnrolment && preUnitDiscountAmount > 0){
                        newPackageUnitPrice+=preUnitDiscountAmount;
                    }
                    // added by nishi: 23-Oct-2020: for now user also can upgrade enrolment process which type of package is promo and prepayment
                   system.debug('newPackageUnitPrice'+newPackageUnitPrice);
                   //system.debug('newPackageFacilityFee'+newPackageFacilityFee);
                   // summary.invoiceFacilityLessonTopup = newPackageFacilityFee;
                    summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice);
                    totalAmount = newPackageUnitPrice;
                   //system.debug('newNextMonthPackageUnitPrice'+newNextMonthPackageUnitPrice);
                   //system.debug('countWithNextMonthPackageDowngrade'+countWithNextMonthPackageDowngrade);
                    if(newNextMonthPackageUnitPrice != 0){
                        summary.invoiceDepositLessonNextMonthTopup = BillingUtility.roundOffAmount(newNextMonthPackageUnitPrice);
                        totalAmount += newNextMonthPackageUnitPrice;
                    }
                   // totalAmount += newPackageFacilityFee;
                    totalAmount += depositeFee;
                    summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                   //system.debug('totalAmount'+totalAmount);
                }
            }
            
        }
        //system.debug('@@summary'+summary);
        return summary;
    }

    Public static UpgradeDowngradePackageSummary  getPackageDetailsUpgradeDowngrade(String oldPackageId, String newPackageId){
        UpgradeDowngradePackageSummary summary = new UpgradeDowngradePackageSummary();
        Set<String> packageIds = new Set<String>();
        List<Package__c> packageList = new List<Package__c>();
        //system.debug('@@oldPackageId'+oldPackageId);
        //system.debug('@@newPackageId'+newPackageId);
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            packageIds.add(oldPackageId);
            packageIds.add(newPackageId);
        }
        ////system.debug('@@packageIds'+packageIds);
        if(packageIds.size() > 0){
            packageList = [SELECT Id, Name, Deposit_Fee__c, duration__c, Unit_Fee__c, Location__r.Country__r.Tax_Rate__c  ,Package_Fee__c,
                             /*facility_Fee__c,*/Grade_New__c,Location__r.Organisation__r.Name,Location__r.Organisation__r.Tax_Rate__c,  
                             Is_Promotion_Discount__c,type_of_package__C, Package_after_Promotion__c, Promotion_period_In_months__c, Promotion_Discount__c
                            FROM Package__c 
                            WHERE Id IN: packageIds];
            //commented by jatin : 13-dec-2019: for if any package is same then list size is one
            ///if(packageList.size() ==2){
            if(packageList.size() > 0){
                for(Package__c packageObj : packageList){
                    if(packageObj.Id == oldPackageId){
                        summary.oldPackage = packageObj;
                        summary.oldPackageName = packageObj.Name; 
                        summary.oldPackageId = packageObj.Id;
                        summary.oldDuration = packageObj.duration__c;
                        summary.currentPackageDeposit = packageObj.Deposit_Fee__c ;
                        //added by nishi: 14-Aug-2020: added facility if package organisation is ossia 
                        // if(String.isNotBlank(packageObj.Location__c) && String.isNotBlank(packageObj.Location__r.Organisation__c) && String.isNotBlank(packageObj.Location__r.Organisation__r.Name) && packageObj.facility_Fee__c != null){
                        //     summary.oldfacilityFee = (packageObj.facility_Fee__c/4);
                        // }else{
                        //     summary.oldfacilityFee = 0;
                        // }
                        //added by nishi: 14-Aug-2020: added facility if package organisation is ossia 
                        //Added by jatin 5-Dec-2019 : for add Change Enrolment
                        summary.currentUnitFee = packageObj.Unit_Fee__c;
                        
                        if(String.isNotBlank(packageObj.Location__c) && String.isNotBlank(packageObj.Location__r.Country__c) && packageObj.Location__r.Country__r.Tax_Rate__c != null ){
                            summary.taxRate = packageObj.Location__r.Country__r.Tax_Rate__c;
                        }else{
                            summary.taxRate = 0;
                        }
                        
                    }
                    if(packageObj.Id == newPackageId){
                        summary.newPackage = packageObj;
                        summary.newPackageName = packageObj.Name; 
                        summary.newPackageId = packageObj.Id;
                        summary.newDuration = packageObj.Duration__c;
                        summary.newPackageDeposit = packageObj.Deposit_Fee__c ;
                        //added by nishi: 14-Aug-2020: added facility if package organisation is ossia 
                        // if(String.isNotBlank(packageObj.Location__c) && String.isNotBlank(packageObj.Location__r.Organisation__c) && String.isNotBlank(packageObj.Location__r.Organisation__r.Name) && packageObj.facility_Fee__c != null){
                        //     summary.newfacilityFee = (packageObj.facility_Fee__c/4);
                        // }else{
                        //     summary.newfacilityFee = 0;
                        // }
                        //added by nishi: 14-Aug-2020: added facility if package organisation is ossia 
                        //Added by jatin 5-Dec-2019 : for add Change Enrolment
                        summary.newUnitFee = packageObj.Unit_Fee__c;
                        if(String.isNotBlank(packageObj.Location__c) && String.isNotBlank(packageObj.Location__r.Country__c) && packageObj.Location__r.Country__r.Tax_Rate__c != null ){
                            summary.taxRate = packageObj.Location__r.Country__r.Tax_Rate__c;
                        }else{
                            summary.taxRate = 0;
                        }
                       
                    }
                }
            }
            ////system.debug('@@summary.newPackageId '+summary.newPackageId );
        }
        return summary;
    }
    
    public static Map<String, String> getEnrolmentDetailsUpgradeDowngrade(String enrolmentId){
        Map<String, String> mapToReturn = new Map<String, String>();
        DateTime dt;
        List<Enrolment__c> enrolList = [SELECT Id, Lessons_Start_Date__c, Lesson_Day__c, Parent__c, Lesson_Start_time__c, 
                                        Package__c, Package__r.Package_Fee__c, Package__r.Deposit_Fee__c,Class__r.name ,
                                        Package__r.Instrument__c,Class__c,Center__r.Organisation__r.Name,
                                        //start: added by nishi: 14-aug-2020 for if user select package then we show related details like: duration,monthly fee, grade,Facility fee
                                        /*Package__r.facility_Fee__c,*/Package__r.Grade_New__c,Package__r.Promotion_period_In_months__c,Package__r.Promotion_Discount__c,
                                         // end:added by nishi: 14-aug-2020 for if user select package then we show related details like: duration,monthly fee, grade,Facility fee
                                        Package__r.Name, Teacher__c, Teacher__r.Name, Package__r.Duration__c, Type_of_Package__c,
                                        Student__r.name,Parent__r.name,Student__r.Also_a_Student__c,Student__r.Parent__c,
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
                    // added by jatin:20-dec-2019: for get lessonday(dddd)format in  Upgrade to individual class 
                    mapToReturn.put('currentLessonDay', objEnrol.Lesson_Day__c);
                }
            }
            
            // added by nishi: 20-Oct-2020: for now user also can change enrolment process which type of package is promo and prepayment
            mapToReturn.put('enrolentpackagetype', objEnrol.Type_of_Package__c);  

            // added by nishi: 10-aug-2020: for manage ossia Upgrade ,downGrade Subscription model
            if( String.isNotBlank(objEnrol.Center__c) && String.isNotBlank(objEnrol.Center__r.Organisation__c) &&   
            String.isNotBlank(objEnrol.Center__r.Organisation__r.Name) &&   
            objEnrol.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){    
                mapToReturn.put('isOssia', 'true'); 
            }   else{
                mapToReturn.put('isOssia', 'false'); 
            }
             // added by nishi: 10-aug-2020: for manage ossia Upgrade ,downGrade Subscription model
             mapToReturn.put('currentCenter', objEnrol.center__c);
            mapToReturn.put('currentOrganisation', objEnrol.Center__r.Organisation__c);
            mapToReturn.put('currentCenterName', objEnrol.center__r.name);
            mapToReturn.put('currentPackage', objEnrol.Package__r.Name);
            mapToReturn.put('parentId', objEnrol.Parent__c);
             mapToReturn.put('instrument', objEnrol.Package__r.Instrument__c);
             
              // @jatin: 4:Jan:2020 : for show Class name in upgrade group class
              mapToReturn.put('currentClass', objEnrol.Class__c);
              mapToReturn.put('currentClassName', objEnrol.Class__r.Name);
            // @jatin: 12:dec :2019: for show parent and student  name in change enrollement
            if(objEnrol.Student__r.Also_a_Student__c && String.isBlank(objEnrol.Student__r.Parent__c)){
                mapToReturn.put('parentName','');
            }else{
                mapToReturn.put('parentName', objEnrol.Parent__r.name);
            }
            mapToReturn.put('studentName', objEnrol.Student__r.name);
            
            mapToReturn.put('currentTeacher', objEnrol.Teacher__r.Name);              
            mapToReturn.put('currentPackageDuration', objEnrol.Package__r.Duration__c);
            mapToReturn.put('currentPackageDepositFee', String.valueOf(objEnrol.Package__r.Deposit_Fee__c));
            Decimal packageFee = objEnrol.Package__r.Package_Fee__c;
            //20-Oct-2020 : @@nishi  :start:if Enrolment package type is Prepayemnt or promo then we manage current Month Invoice amount devided into Promotion_period_In_months__c
            if(objEnrol.Type_of_Package__c == ConstantsClass.prePaymentType || objEnrol.Type_of_Package__c != ConstantsClass.PromoTypePayment){
                Decimal noOfMonths = String.isNotBlank(objEnrol.Package__r.Promotion_period_In_months__c) ? Integer.valueOf(objEnrol.Package__r.Promotion_period_In_months__c) : 1;
                packageFee = BillingUtility.roundOffAmount(objEnrol.Package__r.Package_Fee__c/noOfMonths);
                if(objEnrol.Package__r.Promotion_Discount__c != null && objEnrol.Package__r.Promotion_Discount__c !=0)
                    packageFee -= objEnrol.Package__r.Promotion_Discount__c != null ?(objEnrol.Package__r.Promotion_Discount__c / noOfMonths) :0;
            }
             //20-Oct-2020 : @@nishi:end:if Enrolment package type is Prepayemnt or promo then we manage current Month Invoice amount devided into Promotion_period_In_months__c
            mapToReturn.put('currentMonthInvoice', String.valueOf(packageFee));
             //start:14-Aug-2020 added by nishi for show ossia change package details
           // mapToReturn.put('currentPackageFacilityFee', String.valueOf(objEnrol.Package__r.facility_Fee__c));
            mapToReturn.put('currentPackageGrade', String.valueOf(objEnrol.Package__r.Grade_New__c));
             //end: 14-Aug-2020 added by nishi for show ossia change package details
            
             //28-Nov-2019 added by jatin for change class details
            //mapToReturn.put('currentClass', String.valueOf(objEnrol.Class__r.name));
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
            // @jatin:19-dec-2019: added instument for group class upgrade to regular user get packages list according to instruments
       
            if(enrolDetails.containsKey('instrument')){
                enrolEdit.currentInstrument = enrolDetails.get('instrument');
            }
           // added by nishi: 10-aug-2020:start: for manage ossia Upgrade ,downGrade Subscription model
            if(enrolDetails.containsKey('isOssia')){
                enrolEdit.isOssia = enrolDetails.get('isOssia');
            }
            // added by nishi: 10-aug-2020:end: for manage ossia Upgrade ,downGrade Subscription model
            enrolEdit.currentTeacherId = enrolDetails.containsKey('currentTeacherId') ? enrolDetails.get('currentTeacherId') : '';
            enrolEdit.currentPackageId = enrolDetails.containsKey('currentPackageId') ? enrolDetails.get('currentPackageId') : '';
            
            //14-Aug-2020 added by nishi for show ossia change package details
            enrolEdit.currentPackageduration = enrolDetails.containsKey('currentPackageDuration') && string.isnotBlank(enrolDetails.get('currentPackageDuration'))? enrolDetails.get('currentPackageDuration') : '0';
            /*enrolEdit.currentPackagefacilityFee = enrolDetails.containsKey('currentPackageFacilityFee') && string.isnotBlank( enrolDetails.get('currentPackageFacilityFee'))?
                                                decimal.valueOf(enrolDetails.get('currentPackageFacilityFee')) : 0;*/
            enrolEdit.currentPackagegrade = enrolDetails.containsKey('currentPackageGrade') && string.isnotBlank(enrolDetails.get('currentPackageGrade'))? enrolDetails.get('currentPackageGrade') : '';
            enrolEdit.currentPackageMonthlyFee = enrolDetails.containsKey('currentMonthInvoice') && string.isnotBlank(enrolDetails.get('currentMonthInvoice'))?
                                                decimal.valueOf(enrolDetails.get('currentMonthInvoice')) : 0;
            //14-Aug-2020 added by nishi for show ossia change package details

            // added by nishi: 10-aug-2020:end: for manage ossia Upgrade ,downGrade Subscription model
            if(enrolDetails.containsKey('currentCenter')){
                enrolEdit.center = enrolDetails.get('currentCenter');
                 //start: added by nishi: 27-Aug-2020: for get All center accoding to organisation
                 enrolEdit.centerName = enrolDetails.get('currentCenterName');
                 enrolEdit.centers = new List<Data>();
                List<Data> multipleCentersData = new List<Data>();
                Data centerdata = new Data();
                List<Account> centers = getOrganisationRelatedCenters(enrolDetails.get('currentOrganisation'));
                for(Account center : centers){
                    centerdata = new Data();
                    centerdata.Id = center.Id;
                    centerdata.name = center.Name;
                    multipleCentersData.add(centerdata); 
                }    
                if(multipleCentersData.size() > 0){
                    enrolEdit.centers = multipleCentersData;
                }
                 //end added by nishi: 27-Aug-2020: for get All center accoding to organisation
                enrolEdit.teachers = new List<Data>();
                List<Data> multipleTeachersData = new List<Data>();
                Data teacherdata = new Data();
                List<Account> teachers = AureusCalendarControllerHelper.getListOfTeacher(enrolDetails.get('currentCenter'));
                for(Account teacher : teachers){
                    teacherdata = new Data();
                    teacherdata.Id = teacher.Id;
                    teacherdata.name = teacher.Name;
                    multipleTeachersData.add(teacherdata); 
                }    
                if(multipleTeachersData.size() > 0){
                    enrolEdit.teachers = multipleTeachersData;
                }
            }       
        }
        return enrolEdit; 
    }
    // added by nishi: 27-Aug-2020: for get All center accoding to organisation
    public static List<Account> getOrganisationRelatedCenters(string organisationId) {
        Id recordTypeCenter = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        return [SELECT id, Name FROM Account 
                WHERE recordTypeId =: recordTypeCenter 
                AND Centre_Status__c =: ConstantsClass.activeStatus 
                AND Organisation__c=:organisationId
                ORDER BY Name];
    }
    
     // added by nishi: 28-oct-2020: if enrolment packages type is prepayement and user want to change enrolment then we show prepayment  packages not normal packages
    @RemoteAction
    public static List<Data> getPackagePromotionalAccordingToTeacher(String centerId, String teacherId, Integer duration,string bookingId){
        List<Data> packageList = new List<Data>();
        Data dt = new Data();
        Set<String> instruments =  new Set<String>();       
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(teacherId)){
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                    FROM Account WHERE Id =:teacherId];
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
            system.debug('instruments'+instruments);
            system.debug('bookingId'+bookingId);
            if(instruments.size() > 0 && String.isNotBlank(centerId) && String.isNotBlank(bookingId)){  
                string enrolmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
                Enrolment__C objEnrolment = fetchEnrolment(enrolmentId);
                system.debug('objEnrolment'+objEnrolment);
                for(Package__c pkg : [SELECT Id, Name FROM Package__c 
                                    WHERE Location__c =: centerId 
                                    AND Program__r.Status__c =: ConstantsClass.activeStatus  
                                    AND Program__r.Instrument__c IN: instruments       
                                    AND Program__r.Billing__c != null AND Program__r.Scheduling__c != null 
                                    AND Active__c = True 
                                    AND (Type__c = 'Individual' OR Type__c = 'Home') 
                                    AND RecordtypeId =: pkgLessRecId 
                                    AND Duration__c =: String.valueOf(duration) 
                                    AND Type_of_package__c =: objEnrolment.Package__r.Type_of_package__c
                                    And Promotion_period_In_months__c =:objEnrolment.Package__r.Promotion_period_In_months__c
                                    And Promotion_Discount__c =:objEnrolment.Package__r.Promotion_Discount__c
                                    ORDER BY Program__r.Name]){
                                                            dt = new Data();
                                          dt.Id = pkg.Id;
                                          dt.name = pkg.Name;
                                          packageList.add(dt);
                                      }    
                                      system.debug('packageList'+packageList);
            }
        }
        return packageList;
    }

    @RemoteAction
    public static List<Data> getPackageAccordingToTeacher(String centerId, String teacherId, Integer duration){
        List<Data> packageList = new List<Data>();
        Data dt = new Data();
        Set<String> instruments =  new Set<String>();       
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(teacherId)){
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                    FROM Account WHERE Id =:teacherId];
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
                                    RecordtypeId =: pkgLessRecId AND Duration__c =: String.valueOf(duration) 
                                    AND Type_of_package__c = 'Normal' ORDER BY Program__r.Name]){
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
                                         String currentEffectiveDateStr,String newEffectiveDateStr, String timeStr, String myCaseId, 
                                         String caseRedirect, String previousTime, String oldPackageName, String newPackageName){
                                            String caseIdToReturn;
                                        if(String.isNotBlank(enrolmentId)){
                                                IAdvanceAction updatePackageObj;
                                                
                                                updatePackageObj = new UpdateEnrolmentProcessController(enrolmentId, teacherId, packageId, 
                                                                                                        currentEffectiveDateStr,
                                                                                                        newEffectiveDateStr,timeStr,myCaseId,caseRedirect,
                                                                                                        previousTime,oldPackageName,newPackageName);
                                                caseIdToReturn = updatePackageObj.initProcess();
                                                //caseIdToReturn ='5000p000002XyAkAAK';
                                        }
                                        return caseIdToReturn;
                                          
                                         }
    
    private static Enrolment__c fetchEnrolment(String enrolmentId){
        Enrolment__c enrolmentObj = new Enrolment__c();
        // Added By Ravi.. on 17 july 2020 Lesson_Mode__c in query
        List<Enrolment__c> enrolmentList = [SELECT Id, Effective_Date__c, Lesson_Day__c, Teacher__c, Teacher__r.Employee_Duty_Type__c, 
                                            Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, Next_Lesson_Start_time__c,
                                            Package__c, Package__r.Duration__c,Parent__c, Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, 
                                            Center__r.Country__r.Stripe_Secret_Key__c, Center__r.Country__r.Stripe_Base_Url__c,Center__r.Country__r.Id,Center__r.Organisation__c,
                                            // added by nishi: 28-Oct-2020: for if enrolment package type is Promotionl then we get Promotion detials 
                                            Package__r.Promotion_period_In_months__c,Package__r.Promotion_Discount__c,Package__r.Type_of_package__c,Package__r.Package_Fee__c,
                                            Center__r.Organisation__r.Tax_Rate__c, Center__r.Organisation__r.Country__r.Currency_Code__c, 
                                            Center__r.Organisation__r.Stripe_Secret_Key__c, Center__r.Organisation__r.Stripe_Base_Url__c,Center__r.Organisation__r.Name, 
                                             (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                             Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c FROM Subscription_Line_Items__r
                                             Where Status__c =:ConstantsClass.activeStatus //4-sep-2020: added by nishi for new requirement one enrolment have two subscrition so we get active line item
                                             And Next_Bill_Date__c != null),
                                            //Start : added by Nishi : 30-Jul-2020 for update Resource id in reschadul future booking
                                             Resource__c ,Lesson_Mode__c,Online_Lesson_Passcode__c,Online_Lesson_URL__c,name,
                                             //End: added by Nishi : 30-Jul-2020 for update Resource id in reschadul future booking
                                             //Start : added by Nishi : 4-Feb-2021 :Aureus Q1 2021: for update Waitlist_Status__c   emailed to  Assigned
                                             Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c 
                                              //Start : added by Nishi : 4-Feb-2021:Aureus Q1 2021:  for update Waitlist_Status__c  emailed to  Assigned
                                            FROM Enrolment__c WHERE Id =: enrolmentId];
        if(enrolmentList.size() > 0){
            enrolmentObj = enrolmentList[0];
        } 
        return enrolmentObj;                                          
    }
    
    public  static Date getNextBillingSubscriptionLineItemDate(List<Enrolment__c> enrolmentList){
        Date nextBillDate;
        if(enrolmentList.size() > 0 && enrolmentList[0].Subscription_Line_Items__r != null && enrolmentList[0].Subscription_Line_Items__r.size() >0 ){
            nextBillDate = enrolmentList[0].Subscription_Line_Items__r[0].Next_Bill_Date__c;
        }
        return nextBillDate; 
    }
    
    public  static List<Booking__c> fetchBookingsForUpgrade(String enrolmentId, List<Date> dates){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c FROM Booking__c WHERE Enrolment__c=:enrolmentId AND 
                Booking_Date__c IN: dates AND 
                //jatin:7-jan-2020 : for now we calculate all booking Status__c !=: ConstantsClass.statusCanceled 
                Type__c =: ConstantsClass.bookTypeRegular];
    }
    
    public  static List<Date> getMonthDates(DateTime effectiveDate){
        List<Date> dates = new List<Date>();
        effectiveDate = DateTime.newInstance(effectiveDate.date().toStartOfMonth(), effectiveDate.time());
        Integer currentMonth = effectiveDate.month();
        
        while(effectiveDate.month() == currentMonth){
            dates.add(effectiveDate.date());
            effectiveDate = effectiveDate.addDays(1);
            
        }
        return dates;
    }

    public  static List<Date> getPromotinalMonthDates(DateTime effectiveDate,date nextbillingdate){
        List<Date> dates = new List<Date>();
        effectiveDate = DateTime.newInstance(effectiveDate.date().toStartOfMonth(), effectiveDate.time());
        Integer currentMonth = nextbillingdate.addMonths(-1).month();
        system.debug('@@effectiveDate'+effectiveDate);
        system.debug('@@currentMonth'+currentMonth);
        while(effectiveDate.month() == currentMonth){
            dates.add(effectiveDate.date());
            effectiveDate = effectiveDate.addDays(1);
        }
        system.debug('@@dates'+dates);
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
      // Commented by nishi: 20:jul:2020: change private to public for use in OssiaCalendarController 
    //private static List<Booking__c> getFutureBusyBookings(Booking__c BookingObj){
     public  static List<Booking__c> getFutureBusyBookings(Booking__c BookingObj){
        String typeBusy = ConstantsClass.typeBusy;
        String statusCanceled = ConstantsClass.statusCanceled;
        return [SELECT Id, start_Time__c, End_Time__c, Duration__c, Booking_Date__c, Type__c,
                /*added by nishi: 30-Jul-2020: for manage ResourceId*/
                Resource__c
                /*added by nishi: 30-Jul-2020: for manage ResourceId*/
                FROM Booking__c 
                WHERE RecordTypeId = :BookingObj.RecordTypeId AND Type__c = :typeBusy AND 
                Booking_Date__c >= :BookingObj.Booking_Date__c AND Teacher_Account__c = :BookingObj.Teacher_Account__c AND 
                Center__c =: BookingObj.Center__c AND 
                Start_Time__c = :BookingObj.Start_Time__c  AND End_Time__c = :BookingObj.End_Time__c AND 
                Category__c = :BookingObj.Category__c AND Appointment_Day__c =: BookingObj.Appointment_Day__c AND Status__c != :statusCanceled];
    }
    
    //Cancel all Future Busy Bookings 
    // Commented by nishi: 20:jul:2020: chante private to public for use in OssiaCalendarController 
   // Private  static boolean cancelAllFutureBusyBookings(List<Booking__c> listOfBookings){
    public  static boolean cancelAllFutureBusyBookings(List<Booking__c> listOfBookings){
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
        //system.debug('bookingsToUpdate '+bookingsToUpdate.size());
        return isSuccess;
    }
    
    public  static Integer getTimeStampBetween(Time startTime, Time endTime){
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
                                         (SELECT Id, Next_Bill_Date__c FROM Subscription_Line_Items__r
                                         Where Status__c =:ConstantsClass.activeStatus //4-sep-2020: added by nishi for new requirement one enrolment have two subscrition so we get active line item
                                         And Next_Bill_Date__c != null)
                                          FROM Enrolment__c WHERE Id =: enrolId LIMIT 1]){
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
    
    /*
*  Update Enrolment Link Creation Field on PrePayment Link
*/
    @RemoteAction
    public static Boolean updateEnrolmentLink(String enrolId){
        Boolean isSucess = false;
        Enrolment__c enrolObj = new Enrolment__c();
        if(String.isNotBlank(enrolId)){
            enrolObj.Id = enrolId;
            enrolObj.Link_Creation_Date__c  = DateTime.now();
        }
        if(String.isNotBlank(enrolObj.Id)){
            update enrolObj;
            isSucess = true;
        }
        return isSucess;
    }
    
    /*
* This method is use to check that the fifth adhoc booking is paid or due
* if it is due then we will not revert the makeup hours to parent and trigger will 
* void the invoice for that adhoc booking. And if it is paid then we will allow to 
* revert makeup minutes for that booking. 
*/ 
//@jatin Due to change in Functionality by julius
    /*public static Boolean checkAdhocIsPaid(String bookingId){
        Boolean needToRevert = false;
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        if(String.isNotBlank(bookingId)){
            invoiceLineItems = [SELECT Id, Invoice__c, Invoice__r.Status__c FROM Invoice_Line_Item__c WHERE Booking__c =: bookingId];
            if(invoiceLineItems.size() > 0 && String.isNotBlank(invoiceLineItems[0].Invoice__c)){
                if(invoiceLineItems[0].Invoice__r.Status__c == ConstantsClass.paidStatus){
                    needToRevert = true;    
                }else if(invoiceLineItems[0].Invoice__r.Status__c == ConstantsClass.dueStatus){
                    needToRevert = false;    
                }
            }
        }
        return needToRevert;
    }*/
    //@Arpit Date:-7/8/2019 This method is used to attach withdrawlSummaryPdf on enrollment account
   /* @future (callout=true)
    private static void attachWithdrawlSummaryPdf(String enrollName,String enrollId,String enrollParent){
        PageReference pdf = Page.WithdrawlSummaryPdf;
        pdf.getParameters().put('id',enrollId);
        Blob pdfBody;
        if(Test.isRunningTest()) { 
            pdfBody = blob.valueOf('Unit.Test');
        }else{
            pdfBody = pdf.getContentAsPDF();
        }
        
        Attachment enrollParentAttachment = new Attachment(Body=pdfBody,
                                                           name = enrollName+'_WithdrawlSummaryPdf', 
                                                           parentid = enrollParent, 
                                                           contentType = 'application/pdf');
        
        insert enrollParentAttachment;
        
    }*/
    //This Method is used to validate Booking Time
    public static boolean validateBookingTime(String teacherId,Date bookDate,Time endTime){
        boolean isCreated;
        Datetime dt = DateTime.newInstance(bookDate, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek=dt.format('EE');
        List<Teacher_Working_Hour__c> teacherWorkingHour = new List<Teacher_Working_Hour__c>();
        teacherWorkingHour = [select id,Start_Time__c,End_Time__c,Working_Day__c from Teacher_Working_Hour__c 
                                where Teacher_Name__c=:teacherId 
                                AND Active__c = True 
                                AND Break_Time__c = false
                                 AND Working_Day__c=:dayOfWeek
                                  AND End_Time__c >=:endTime];
       //system.debug('teacherWorkingHour'+teacherWorkingHour);                     
        if(teacherWorkingHour.size() > 0){
            isCreated = true;
        }else{
            isCreated=false;
        }
        return isCreated;
    } 
    
    /*
* Fetch all Group type Packages for the centre to create class record from Calendar UI.
*/ 
    @RemoteAction
    public static List<GroupPackage> fetchGroupPackages(String centreId,String teacherId){
        List<GroupPackage> grpPackages = new List<GroupPackage>();
        List<string> instruments = New List<string>();
        GroupPackage grpPackage = new GroupPackage(); 

        if(String.isNotBlank(centreId) && String.isNotBlank(teacherId)){
            //start: 1-Sep-2020: added by nishi: for get organisation is related to  ossia then we show Grade list not packages
            List<Account> ossiaCenterList = [Select id,Organisation__r.Name 
                                        from Account
                                         Where Id=:centreId 
                                        and Organisation__r.Name =:System.Label.Ossia_Organisation_Name];
            if(ossiaCenterList != null && ossiaCenterList.size() > 0){
                grpPackage = new GroupPackage();
                grpPackage.isOssia = true;
                grpPackages.add(grpPackage);
            } else{   
            //end: 1-Sep-2020: added by nishi: for get organisation is related to  ossia then we show Grade list not packages      

                // 7-jan-2020: show packages according to teachers instruements
                List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                        FROM Account WHERE Id =:teacherId];
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
            //system.debug('instruments'+instruments);
                if(instruments != null && instruments.size() > 0){
                    for(Package__c packageObj : [SELECT Id, Name, of_Students__c, Duration__c, Package_Fee__c,Instrument__c
                                                FROM Package__c WHERE
                                                Type__c =: ConstantsClass.packageTypeGroup
                                                AND Active__c = TRUE 
                                                AND Location__c =: centreId
                                                AND Program__r.Status__c =:  ConstantsClass.activeStatus
                                                AND Program__r.Instrument__c IN: instruments]){
                                                    
                                                    grpPackage = new GroupPackage();
                                                    grpPackage.isOssia = false; //added by nishi: for get organisation is related to  ossia or not
                                                    grpPackage.id =  packageObj.Id;
                                                    grpPackage.name = packageObj.Name;
                                                    grpPackage.price = packageObj.Package_Fee__c;
                                                    grpPackage.duration = packageObj.Duration__c;
                                                    grpPackage.studentCapacity = packageObj.of_Students__c != null ?packageObj.of_Students__c :0;
                                                    // @jatin: 18-dec-2019:for show instrument
                                                    grpPackage.instrument = packageObj.Instrument__c;
                                                    grpPackages.add(grpPackage);
                                                } 
                }   
            }
        }
        return grpPackages;
    }
   
    
    /*
* Save Class object record for whole year for that perticular centre, teacher and package.
*/ 
    @RemoteAction
    public static Boolean saveNewClass(String centreId, String teacherId, String packageId, 
                                        String classDateStr, String classTimeStr, 
                                        String duration, Integer countOfStudent,
                                        string classType,Integer minAge,Integer maxAge,Boolean isMakeupGroupclass,String classEndDateStr){
        Boolean isSuccess = false;
                                            
        string insertedClassid =  saveNewGroupClass(centreId,  teacherId,  packageId,  classDateStr, classTimeStr,  duration, countOfStudent,
                                    classType, minAge, maxAge,false,'',isMakeupGroupclass, classEndDateStr);
        if(string.isNotBlank(insertedClassid)){
            isSuccess = true;
        }         
        return isSuccess;
    }

    public static string saveNewGroupClass(String centreId, String teacherId, String packageId, 
                                        String classDateStr, String classTimeStr, 
                                        String duration, Integer countOfStudent,
                                        string classType,Integer minAge,Integer maxAge,Boolean isOssia,string grade,Boolean isMakeupGroupclass,String classEndDateStr){
        Class__c currentClass = new Class__c();
        DateTime startDateTime, endDateTime;
        
        if(String.isNotBlank(classDateStr) && String.isNotBlank(classTimeStr)){
            startDateTime = DateTime.newInstance(Date.valueOf(classDateStr), Time.newInstance(Integer.valueOf(classTimeStr.split(':')[0]), 
                                                                                              Integer.valueOf(classTimeStr.split(':')[1]), 
                                                                                              Integer.valueOf(classTimeStr.split(':')[2]), 0));
        }  
        if(startDateTime != NULL && !isMakeupGroupclass){
            classEndDateStr = '';
           // endDateTime = startDateTime.addYears(ConstantsClass.periodOfClassesInMonths);
        }else if(isMakeupGroupclass && String.isNotBlank(classEndDateStr) && String.isNotBlank(classTimeStr)){
            endDateTime = DateTime.newInstance(Date.valueOf(classEndDateStr), Time.newInstance(Integer.valueOf(classTimeStr.split(':')[0]), 
                            Integer.valueOf(classTimeStr.split(':')[1]), 
                            Integer.valueOf(classTimeStr.split(':')[2]), 0));
        }
        
        if(startDateTime != NULL && String.isNotBlank(centreId) && String.isNotBlank(teacherId) && 
           String.isNotBlank(duration) && ((!isOssia && String.isNotBlank(packageId)) || (isOssia && String.isBlank(packageId)))){
               currentClass.Centre_Name__c = centreId;
               currentClass.Class_Date__c = startDateTime.date();
               currentClass.Teacher__c = teacherId;
               currentClass.Package__c = (!isOssia && String.isNotBlank(packageId)) ? packageId : null;
               currentClass.Class_Start_Date__c = startDateTime.date();
               currentClass.Start_Time__c = startDateTime.time();
                if(isMakeupGroupclass && endDateTime != null){
                    currentClass.Class_End_Date__c = endDateTime.date();
                }
                currentClass.Is_Makeup_Class__c = isMakeupGroupclass;
               currentClass.Minimum_age__c = minAge;
               currentClass.Maximum_age__c = maxAge;
               currentClass.Class_Type__c = classType;
               currentClass.grade__c =  String.isNotBlank(grade) ? grade :'';
               if(countOfStudent > 0){
                   currentClass.Total_Capacity__c = countOfStudent;
               }
               currentClass.End_Time__c = currentClass.Start_Time__c.addMinutes(Integer.valueOf(duration));
               insert currentClass;
               return  currentClass.id;
           }
        
        return '';
    }
    
    /*
     * This Method will Change the status of enrolment to attended and delete all related blocked bookings for that enrolment
     * and create case for that. 
     *
    */     
    
    @RemoteAction
    Public static String releaseBlockBooking(String enrolmentId, String reason, String myCaseId){
        String caseId = '';
        Enrolment__c enrolObj = new Enrolment__c();
        if(String.isNotBlank(enrolmentId) && String.isNotBlank(reason)){
            enrolObj.Id = enrolmentId;
            enrolObj.Stage__c = ConstantsClass.enrollStageAttended;
            enrolObj.Releasing_Block_Reason__c = reason;
            UPDATE enrolObj;
        }
        if(String.isNotBlank(enrolObj.Id)){
            List<Booking__c> bookingList = [SELECT Id FROM Booking__c WHERE Status__c =: ConstantsClass.blockStatus AND Enrolment__c =: enrolObj.Id];
            if(bookingList.size() > 0){
                DELETE bookingList;
            }
            Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrolObj.Id, 'Release Block Booking', TRUE);
            /*objCase.Booking__c = bookingId;
            INSERT objCase;*/
            caseId = objCase.Id;
        }
        return caseId;
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
        public String centerName; //start: added by nishi: 27-Aug-2020: for get All center accoding to organisation
        public Integer duration;
        public List<Data> teachers;
        public List<Data> centers; //start: added by nishi: 27-Aug-2020: for get All center accoding to organisation
        public String currentWeekDay;
      
        // @jatin:19-dec-2019: added instument for group class upgrade to regular user get packages list according to instruments
       public String currentInstrument;
       public String isOssia; // added by nishi: 10-aug-2020 for manage ossia center Upgrade downGrade requirement
       //added by nishi: for if user select package then we show related details like: duration,monthly fee, grade,Facility fee
       public String currentTeacherId;
       public String currentPackageId;
       public String currentPackageduration; 
       //public Decimal currentPackagefacilityFee; 
       public String currentPackagegrade; 
       public Decimal currentPackageMonthlyFee; 
        //added by nishi: for if user select package then we show related details like: duration,monthly fee, grade,Facility fee
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
        public Decimal invoiceNextMonthTopup; //added by nishi:26-Aug-2020 : for manage NextMonth calclulation
        public Decimal invoiceDepositLessonNextMonthTopup; //added by nishi:26-Aug-2020 : for manage NextMonth calclulation
        public Decimal invoiceDiscountLessonCurrentMonthTopup; //added by nishi:26-Aug-2020 : for manage promotinal package Current month adjustment discount
        //public Decimal invoiceFacilityLessonTopup; //added by nishi:19-Aug-2020 : for manage Facility fee calclulation
        //public Decimal positiveFacilityInvoiceAmount; //added by nishi:19-Aug-2020 : for manage Facility fee calclulation
        //public Decimal negativeFacilityInvoiceAmount; //added by nishi:19-Aug-2020 : for manage Facility fee calclulation
        public Decimal positiveNextMonthInvoiceAmount; //added by nishi:26-Aug-2020 : for manage NextMonth calclulation
        public Decimal negativeNextMonthInvoiceAmount; //added by nishi:26-Aug-2020 : for manage NextMonth calclulation
        public Decimal positiveInvoiceAmount;
        public Decimal negativeInvoiceAmount;
        Public Double taxRate;
      
        // added jatin 28-Nov-2019 : for add class details
        public String oldClassName;
        public String newClassName;
        public String oldClassId;
        public String newClassId;
        
        //Added by jatin 4-Dec-2019 : for add Change Enrolment
        public string currentEffectiveDate;
        public String newTeacherId;
        public String newTeacherName;
        public String oldTeacherId;
        public String oldTeacherName;
         // @jatin: 12:dec : for show parent name,studentname  in change enrollement
        public String parentName;
        public String studentName;
        //Added by jatin 5-Dec-2019 : for add Change Enrolment
        public Decimal currentUnitFee;
        public Decimal newUnitFee;
        //public Decimal newfacilityFee; //added by nishi: 14-Aug-2020: for manage facilityFee if package center is ossia
        //public Decimal oldfacilityFee; //added by nishi: 14-Aug-2020: for manage facilityFee if package center is ossia
        //satrt: added by nishi: 28-aug:2020: for added new and old center details
        public String newCenterId;
        public String newCenterName;
        public String oldCenterId;
        public String oldCenterName;
        //end: added by nishi: 28-aug:2020: for added new and old center details

    }
    
    public class WithdrawalSummary{
        public List<Lessons> lastLessons{get;set;}
        public List<Lessons> makeupLessons{get;set;}
        public List<Lessons> finalDeposits{get;set;}
        public String student{get;set;}
        public String packageName{get;set;}
        public String centre{get;set;}
        public String LessonDay{get;set;}
        public String lastDate{get;set;}
        public String noticeDate{get;set;}
        public Decimal gst{get;set;}
        public Decimal total{get;set;}
        public Decimal deposit{get;set;}
        public Decimal refund{get;set;}
    }
    public class Lessons{
        public String bookingId{get;set;}
        public String Lesson{get;set;}
        public String bookingDate{get;set;}
        public String bookingTime{get;set;}
        public Decimal duration{get;set;}
        public String status{get;set;}
        public String student{get;set;}
        public String cancelDate{get;set;}
        public String expiryDate{get;set;}
        public String nextExpiryDate{get;set;}
        public Decimal unitPrice{get;set;}
        public Decimal total{get;set;}
        public integer qty{get;set;}
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
        String name;
        String duration;
        String timeOfBooking;
        String center;
        String teacher;
        String discription; 
        String category; 
        String teacherId;
        String centerId; 
        String origin;    
        String status;
        String enrolmentId;
    }
    public class AdhocLessonDetails{
        public String studentId;
        public String studentFirstName;
        public String studentLastName;
        public String packageId;
        public String packageName;
        public Integer units;
        public Double packageFee;
        public Double unitFee;
        public String centerName;
        public String duration;
        public String teacherId;
        public String teacherName;
        public Decimal gstRate;
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
        //@JAtin on 9-Dec-2019 to check that User has the access of the Change Enrolment Admin
        Boolean  isChange_Enrolment_Admin;
        Boolean  isPrepayment_Advance_Action_Admin;
        Boolean isOssia; // added by nishi: 10-aug-2020 for manage ossia center Upgrade downGrade requirement
        Boolean isChangeEnrolmentCentre;
        Boolean isEnableChangeCentre;
    }
    
    public class GradePackage{
        String id;
        String name;
        Decimal price;
    }
    
    
    
    public class Students{
        public String id;
        public String label;
       public String parentId;
        public String parentName;
       public  String email;
        public String phone;
        public integer makeupHours;
        public integer complementryHours; // added by nishi: 24-feb-2021: for get complementry credit Hours
        
    }
    
    public class NewBookingWrapper{
        public List<TeacherAndCenter> entities;
        public List<packageWrapper> packages;
          public Boolean isOssia; // added by nishi: 22-Jul-2020 for manage ossia center new Booking
        Public List<Resource__c> listOfAvailableResources;  // added by nishi: 30-jul-2020: for get all aureus lesson avalilable resources
        // Added By Ravi on 13 july 2020
        public List<string> lessonTypeList;
        // Added By Ravi on 13 july 2020    
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
    //Jatin: 20-jan-2020 :Wrapper Class for list of teacher Working hours and map of teachers
    public class EmployeeWorkingHours{
        public List<Employee_Work_Week__c> employeeHours;
        public Set<String> setOfEmployees;
    } 
    //Wrapper Class for Calendar
    public class EmployeeCalendar{
        public List<Events> listOfEvents;
        public List<Resources> listOfEmployeFilters;
        public String minTime;
        public String maxTime;
        public List<Events> employeeWorkingHours;
        public List<Resources> listOfResources;
    }

    //Wrapper Class for list of Resource Working hours and map of Resources
    public class resourceWorkingHours{
        public List<Resource_Working_Hour__c> resourcesHours;
        public Set<String> setOfResources;
    }
    //Wrapper Class for Calendar
    public class Calendar{
        List<Resources> listOfResources;
        List<Events> listOfEvents;
        List<Resources> listOfTeachersFilters;
        
        String minTime;
        String maxTime;
        List<Events> teachersWorkingHours;
    }
    //Wrapper Class for Resource
    
    public class Resources{
        public String id;
        public String title;
        public List<businessHour> businessHours;
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
        public Boolean isClass;
        public String availablemins;//nishi: 3-Feb-2021 :Aureus Q1 2021: show Avl makeup minutes on all future bookings.
        public Boolean isavailablemins;//nishi: 3-Feb-2021 :Aureus Q1 2021: show Avl makeup minutes on all future bookings.
        public Boolean isShowpreferedEnrolmentDetails;//nishi: 4-Feb-2021 :Aureus Q1 2021: show enrollment waitlist status  then show  icon for center admin.
        public preferedEnrolmentDetail preferedEnrolmentDetails{get;set;}//nishi: 5-Feb-2021 :Aureus Q1 2021: show prefered enrollment details show in tooltip for center admin.
         public Boolean isOssia; // added by Arpit 16-Jul-2020 : for manage Ossia Organization student
        // Added By Ravi on 2nd july 2020 
        public String lessonType;
        // Added By Ravi on 2nd july 2020 
        public Events(){
            isClass = false;
             isOssia = false;
             isavailablemins = false;//nishi: 3-Feb-2021 :Aureus Q1 2021: show Avl makeup minutes on all future bookings.
             isShowpreferedEnrolmentDetails= false;//nishi: 4-Feb-2021 :Aureus Q1 2021: show enrollment waitlist status is 'waiting' then show wait icon for center admin.
             preferedEnrolmentDetails = new preferedEnrolmentDetail();//nishi: 5-Feb-2021 :Aureus Q1 2021: show prefered enrollment details show in tooltip for center admin.
        }
    }
    //nishi: 5-Feb-2021 :Aureus Q1 2021: show prefered enrollment details show in tooltip for center admin.
    public class preferedEnrolmentDetail{
        public String preferredStartTime{get;set;}
        public String PreferredEndTime{get;set;}
        public String PreferredDay{get;set;}
        public String Preferredteacher{get;set;}
        public String status{get;set;}
        public preferedEnrolmentDetail(){
            preferredStartTime = null;
            PreferredEndTime = null;
            PreferredDay = '';
            Preferredteacher = '';
            status ='';
        }
        public preferedEnrolmentDetail( String preferredStartTime,String PreferredEndTime,String PreferredDay,String Preferredteacher,String status){
            this.preferredStartTime = preferredStartTime;
            this.PreferredEndTime = PreferredEndTime;
            this.PreferredDay = PreferredDay;
            this.Preferredteacher = Preferredteacher;
            this.status =status;
        }
    }
    //nishi: 5-Feb-2021 :Aureus Q1 2021: show enrollment waitlist status is 'waiting' then show wait icon for center admin.
   
    //Wrapper class for Event Details 
    public class EventDetails{
        public String Id;
        public String name; 
        public String service;
        public String staffMember;
        public String staffMemberId;
        public String centerId;
        public String centerName;
         //Start: added by nishi : for manage resouce Id or name on calendar
        public String resourceName;
        public String resourceId;
        //end: added by nishi : for manage resouce Id or name on calendar 
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
        public String placeholder;
        public Decimal amm;
        
        public List<Subscription_Line_Item__c> subscriptionLineItemList;
        
        public String oldValue;
        public String newValue;
        // List for ContentNote of Booking Object
        public List<ContentNote> contentNoteList;
        
        // List for BookingHistory of Booking Object
        public List<BookingHistory> bookingHistoryList;
        // Added By Ravi on 3 july 2020 
        public string lessonType;
        public string lessonURL;
        public string lessonPassCode;
        Public List<Resource__c> listOfAvailableResources; //added by nishi: 30-Jul-2020: for get all Available_For_Aureus_Lesson__c resources
        public Boolean isOssia; // added by Arpit 13-aug-2020 : for manage Ossia Organization student  
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
    
    //Class Packages
    public class GroupPackage{
        public String id{get;set;}
        public String name{get;set;}
        public Decimal price{get;set;}
        public String duration{get;set;}
        //@jatin: 13-dec-2019 :for show package capacity 
        public Decimal studentCapacity{get;set;}
        // @jatin:18-dec-2019 :for show instrument 
        public String instrument {get;set;}
        public Boolean isOssia{get;set;} //added by nishi: 1-Sep-2020 : for check new group class created in ossia org or aureus 
        public decimal deposit{get;set;}
    }
    
    // class details
    public class ClassDetail{
        String id;
        String name;
    }
}