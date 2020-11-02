/*
Name        :        AureusCalendarControllerHelper
Date        :        2019/03/23      
Description :        This is a helper class for AureusCalendarController. 
Test Class  :        AureusCalendarControllerTest2
Component   :		 AureusCalendarCMP
*/
public without Sharing class AureusCalendarControllerHelper{
    
    
    /*
getMapOfWeekDate method takes the list dates selected by the calendar UI.
This method returns the map of string of string which returns the date and its weekday in EEE format.
*/
    
    public static Map<String, String> getMapOfWeekDate(List<String> datesOfAppointment){
        Map<String, String> mapOfWeekDate = new Map<String, String>();
        if(datesOfAppointment.size() == 2){
            DateTime currentDate = DateTime.newInstance(Date.valueOf(datesOfAppointment[0]), Time.newInstance(0, 0, 0, 0));
            DateTime endDate = DateTime.newInstance(Date.valueOf(datesOfAppointment[1]), Time.newInstance(0, 0, 0, 0));
            while(currentDate <= endDate){
                mapOfWeekDate.put(currentDate.format('E'), String.valueOf(currentDate).split(' ')[0]);
                currentDate = currentDate.addDays(1);
            }
        }else if(datesOfAppointment.size() == 1){
            DateTime currentDate = DateTime.newInstance(Date.valueOf(datesOfAppointment[0]), Time.newInstance(0, 0, 0, 0));
            mapOfWeekDate.put(currentDate.format('E'), String.valueOf(currentDate).split(' ')[0]);
        }
        return mapOfWeekDate;
    }
    
    /*
getCenterWorkingHours method takes the center Id and List of weekDays as actual arguments.
This method returns the list of center working hours according to the dates selected by the user from the calendar UI.         
*/
    
    public static List<Center_Working_Hours__c> getCenterWorkingHours(String centerId, List<String> weekDays){
        List<Center_Working_Hours__c> listOfCenterWorkingHours = new List<Center_Working_Hours__c>();
        Map<String, integer> MapOfWeek = new Map<String, integer>{'Mon' => 2, 'Tue' => 3, 'Wed' => 4, 'Thu' => 5, 'Fri' => 6, 'Sat' => 7, 'Sun' => 1};
            String centerWorkingHoursQuery = 'SELECT Id, Name, Start_Time_1st_Shift__c, End_Time_1st_Shift__c, Start_Time_2nd_Shift__c, End_Time_2nd_Shift__c, Active__c, Working_Day__c, Center_Name__c  FROM Center_Working_Hours__c';
        
        //center working hour should be active 
        if(String.isNotBlank(centerId) || weekDays.size() > 0){
            centerWorkingHoursQuery += ' WHERE Active__c = true AND ';
        }
        
        //belongs to the perticular center
        if(String.isNotBlank(centerId)){
            centerWorkingHoursQuery += 'Center_Name__r.Id =: centerId';
        }
        
        //belongs to the perticular weekdays
        if(weekDays.size() > 0){
            List<integer> weekList = new List<integer>();
            for(String current : weekDays){
                if(MapOfWeek.containsKey(current)){
                    weekList.add(MapOfWeek.get(current));
                }
            }
            //fill the set of weekdays from start day to end day
            if(weekList.size() > 0){ 
                Set<String> weekDaySet = getWeekDaySet(weekList);
                centerWorkingHoursQuery += ' AND Working_Day__c IN :weekDaySet';
            }
            
        }
        
        if(String.isNotBlank(centerWorkingHoursQuery)){
            for(Center_Working_Hours__c centerHour : Database.query(centerWorkingHoursQuery)){
                listOfCenterWorkingHours.add(centerHour);
            }
        }
        
        return listOfCenterWorkingHours;
        
    }

    public static AureusCalendarController.Resources addResources(string resourceId, string resourceName, Map<String, List<AureusCalendarController.businessHour>> businessHours){
        AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
        objResource.id = resourceId;
        objResource.title = resourceName;
        if(businessHours.containsKey(resourceId)){
            objResource.businessHours = new List<AureusCalendarController.businessHour>();
            objResource.businessHours = businessHours.get(resourceId);
        }else{
            AureusCalendarController.businessHour businessh = new AureusCalendarController.businessHour();
            businessh.start = '00:00:00';
            businessh.end_c = '00:00:00';
            businessh.dow = new List<Integer>();
            businessh.dow.add(0);
            objResource.businessHours = new List<AureusCalendarController.businessHour>();
            objResource.businessHours.add(businessh);
        }
        return objResource;
    }
    
    /*
getWeekDaySet methods takes the list of start day and end day
this method returns the set of weekdays which comes under start day and end day
If the list has only start day it retures only that day.

*/
    
    private static Set<String> getWeekDaySet(List<integer> startEnd){
        Map<integer, String> MapOfWeek = new Map<integer, String>{1 => 'Mon', 2 => 'Tue', 3=> 'Wed', 4=> 'Thu' , 5=> 'Fri', 6=> 'Sat',7=> 'Sun'};
            
            Set<String> weekDays = new Set<String>();
        if(startEnd.size() > 1){
            for(integer i = startEnd[0]; i <= startEnd[1]; i++){
                if(MapOfWeek.containsKey(i)){
                    weekDays.add(MapOfWeek.get(i));
                }
                
            }
        }else if(startEnd.size() > 0){
            if(MapOfWeek.containsKey(startEnd[0])){
                weekDays.add(MapOfWeek.get(startEnd[0]));
            }
            
        }
        
        return weekDays;
    }
    
    /*
getMinTime methods takes the list of center working hours
this method returns the minimum time or start time of the center
if the calendar is in week mode then this method returns the minimum start time from the week.

*/
    
    public static String getMinTime(List<Center_Working_Hours__c> centerWorkingHours){
        Time min;
        
        if(centerWorkingHours[0].Start_Time_1st_Shift__c != null){
            min = centerWorkingHours[0].Start_Time_1st_Shift__c;
        }else if(centerWorkingHours[0].Start_Time_2nd_Shift__c != null){
            min = centerWorkingHours[0].Start_Time_2nd_Shift__c;
        }
        
        for(Center_Working_Hours__c centerHour : centerWorkingHours){
            
            if(centerHour.Start_Time_1st_Shift__c != null && min > centerHour.Start_Time_1st_Shift__c){
                min = centerHour.Start_Time_1st_Shift__c;
            }else if(centerHour.Start_Time_2nd_Shift__c != null && min > centerHour.Start_Time_2nd_Shift__c){
                min = centerHour.Start_Time_2nd_Shift__c;
            }
            
        }
        return String.valueOf(min).split('\\.')[0];
    }
    
    /*
getMaxTime methods takes the list of center working hours
this method returns the maximum time or end time of the center
if the calendar is in week mode then this method returns the maximum end time from the week.

*/
    
    public static String getMaxTime(List<Center_Working_Hours__c> centerWorkingHours){
        Time max;
        if(centerWorkingHours.size() > 0){
            
            if(centerWorkingHours[0].End_Time_2nd_Shift__c != null){
                max = centerWorkingHours[0].End_Time_2nd_Shift__c.addHours(1);
            }else if(centerWorkingHours[0].End_Time_1st_Shift__c != null){
                max = centerWorkingHours[0].End_Time_1st_Shift__c.addHours(1);
            }    
            
            for(Center_Working_Hours__c centerHour : centerWorkingHours){
                if(centerHour.End_Time_2nd_Shift__c != null && max < centerHour.End_Time_2nd_Shift__c){
                    max = centerHour.End_Time_2nd_Shift__c.addHours(1);
                }else if(centerHour.End_Time_1st_Shift__c != null && max < centerHour.End_Time_1st_Shift__c){
                    max = centerHour.End_Time_1st_Shift__c.addHours(1);
                }
            }
        }
        return String.valueOf(max).split('\\.')[0];
    }
    
    /*
getTeacherWorkingHours methods takes the following arguments

1. center Id
2. teacher Id
3. List of weekdays

this method returns the teachers working hours according to selected center, teacher and date from the calendar UI.

*/
    
    public static AureusCalendarController.TeacherWorkingHours getTeacherWorkingHours(String centerId, String teacherId, List<String> weekDays){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        Map<String, integer> MapOfWeek = new Map<String, integer>{'Mon' => 2, 'Tue' => 3, 'Wed' => 4, 'Thu' => 5, 'Fri' => 6, 'Sat' => 7, 'Sun' => 1};
            AureusCalendarController.TeacherWorkingHours teacherHours = new AureusCalendarController.TeacherWorkingHours();
        String teacherWorkingHoursQuery = 'SELECT Id, Name, Teacher_Name__c,Resource__c, Teacher_Name__r.Name, Teacher_Name__r.Status__c, Center_Name__c, Active__c, Working_Day__c, Start_Time__c, End_Time__c, Break_Time__c FROM Teacher_Working_Hour__c';
        
        //teacher working hours should be active and it should not be break hour and its start time and end time should not be null
        if(String.isNotBlank(centerId) || weekDays.size() > 0){
            teacherWorkingHoursQuery += ' WHERE Active__c = true AND Break_Time__c = false AND Start_Time__c != NULL AND End_Time__c != NULL AND Teacher_Name__r.Status__c =: teacherWorkingStatus AND ';
        }
        
        //Belongs to a perticular center
        if(String.isNotBlank(centerId)){
            teacherWorkingHoursQuery += 'Center_Name__r.Id =: centerId';
        }
        
        //belongs to perticular teacher
        if(teacherId != 'AllRosteredStaff' && teacherId != 'AllStaff'){
            teacherWorkingHoursQuery += ' AND Teacher_Name__c =: teacherId';
        } 
        
        if(weekDays.size() == 1){
            String weekDay = weekDays[0];
            teacherWorkingHoursQuery += ' AND Working_Day__c =: weekDay ';
        }else if(weekDays.size() == 2){
            
            List<integer> weekList = new List<integer>(); 
            for(String current : weekDays){
                if(MapOfWeek.containsKey(current)){
                    weekList.add(MapOfWeek.get(current));
                }
            }
            if(weekList.size() >= 2){
                Set<String> weekDaySet = getWeekDaySet(weekList);
                teacherWorkingHoursQuery += ' AND Working_Day__c IN :weekDaySet';
            }
        }
        
        teacherWorkingHoursQuery += ' AND Teacher_Name__c != NULL';
        
        if(String.isNotBlank(teacherWorkingHoursQuery)){
            teacherHours.teachersHours = new List<Teacher_Working_Hour__c>();
            teacherHours.setOfTeachers = new Set<String>();
            for(Teacher_Working_Hour__c teacherCurrentHour : Database.query(teacherWorkingHoursQuery)){
                teacherHours.teachersHours.add(teacherCurrentHour);
                teacherHours.setOfTeachers.add(teacherCurrentHour.Teacher_Name__r.Id);
            }
        }
        
        //If the user selects perticular teacher instead of All Staff and All roasted staff from the calendar UI.
        if(String.isNotBlank(teacherId) && teacherId != 'AllRosteredStaff' && teacherId != 'AllStaff'){
            teacherHours.setOfTeachers = new Set<String>();
            teacherHours.setOfTeachers.add(teacherId);
        }
        
        return teacherHours;
    }
    
    /*
teacheEmployeeWorkWeek methods takes the following arguments

1. TeacherWorkingHours from the getTeacherWorkingHours method
2. teacher Id
3. Map of weekdays

this method returns the list of events as teachers working hours so through javascript, 
so calendar can validate the teachers working hours

*/
    
    public static List<AureusCalendarController.Events> getWorkingHoursTeachers(AureusCalendarController.TeacherWorkingHours workingHoursOfTeacher, String teacherId, Map<String, String> mapOfweekDays){
        List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
        AureusCalendarController.Events currentEvent ;
        
        if(workingHoursOfTeacher.teachersHours.size() > 0){
            for(Teacher_Working_Hour__c currentTeacher : workingHoursOfTeacher.teachersHours){
                currentEvent = new AureusCalendarController.Events();
                currentEvent.id = currentTeacher.Id;
                currentEvent.title = '';
                currentEvent.resourceId = currentTeacher.Teacher_Name__r.Id;
                
                // teachers working hours start time and end time
                if(mapOfweekDays.containsKey(currentTeacher.Working_Day__c)){
                    currentEvent.start =  mapOfweekDays.get(currentTeacher.Working_Day__c)+'T'+String.valueOf(currentTeacher.Start_Time__c ).split('\\.')[0];
                    currentEvent.end_c = mapOfweekDays.get(currentTeacher.Working_Day__c)+'T'+String.valueOf(currentTeacher.End_Time__c).split('\\.')[0];
                }
                
                if(currentTeacher.Break_Time__c){
                    currentEvent.overlap = false;
                    currentEvent.rendering = '';
                    currentEvent.className = 'bookingNotAvailable';
                    currentEvent.eventColor = ConstantsClass.notAvailableWorkingHoursColor;
                    currentEvent.title = 'Lunch '+String.valueOf(currentTeacher.Start_Time__c).split('\\.')[0];
                    currentEvent.eventTextColor = ConstantsClass.eventTextColor;
                    
                }else{
                    currentEvent.eventColor = ConstantsClass.availableWorkingHoursColor;
                    currentEvent.overlap = true;
                    
                    currentEvent.rendering = 'background';
                    currentEvent.className = 'teacherWorkingHours';
                } 
                
                //Only availbale working hours will add in the list  
                if(currentEvent.className != 'bookingNotAvailable'){
                    eventsList.add(currentEvent);
                }
                
            }
        }
        return eventsList;
    }
    
    /*
getTeachersWorkingHours methods takes the following arguments

1. TeacherWorkingHours from the getTeacherWorkingHours method
2. teacher Id
3. Map of weekdays

this method returns the map of teacherId and their teachers working hours for using 
the full calendar property of working hours.

*/
    
    public static Map<String, List<AureusCalendarController.businessHour>> getTeachersWorkingHours(AureusCalendarController.TeacherWorkingHours workingHoursOfTeacher, String teacherId, Map<String, String> mapOfweekDays){
        Map<String, Integer> MapOfWeek = new Map<String, Integer>{'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6, 'Sun' => 0};
            AureusCalendarController.businessHour bh = new AureusCalendarController.businessHour();
        
        Map<String, List<AureusCalendarController.businessHour>> businessHoursMap = new Map<String, List<AureusCalendarController.businessHour>>();
        if(workingHoursOfTeacher.teachersHours.size() > 0){
            for(Teacher_Working_Hour__c currentTeacher : workingHoursOfTeacher.teachersHours) {
                if(businessHoursMap.containsKey(currentTeacher.Teacher_Name__r.Id)) {
                    bh = new AureusCalendarController.businessHour();
                    List<AureusCalendarController.businessHour> hours = businessHoursMap.get(currentTeacher.Teacher_Name__r.Id);
                    if(String.isNotBlank(String.valueOf(currentTeacher.Start_Time__c ))){
                        bh.start = String.valueOf(currentTeacher.Start_Time__c ).split('\\.')[0];
                    }
                    if(String.isNotBlank(String.valueOf(currentTeacher.End_Time__c))){
                        bh.end_c = String.valueOf(currentTeacher.End_Time__c).split('\\.')[0];
                    }
                    bh.dow = new List<Integer>();
                    if(MapOfWeek.containsKey(currentTeacher.Working_Day__c)){
                        bh.dow.add(MapOfWeek.get(currentTeacher.Working_Day__c));
                    }
                    hours.add(bh);
                    businessHoursMap.put(currentTeacher.Teacher_Name__r.Id, hours);
                    
                }else{
                    bh = new AureusCalendarController.businessHour();
                    if(String.isNotBlank(String.valueOf(currentTeacher.Start_Time__c ))){
                        bh.start = String.valueOf(currentTeacher.Start_Time__c ).split('\\.')[0];
                    }
                    if(String.isNotBlank(String.valueOf(currentTeacher.End_Time__c))){
                        bh.end_c = String.valueOf(currentTeacher.End_Time__c).split('\\.')[0];
                    }
                    
                    bh.dow = new List<Integer>();
                    if(MapOfWeek.containsKey(currentTeacher.Working_Day__c)){
                        bh.dow.add(MapOfWeek.get(currentTeacher.Working_Day__c));
                    }
                    
                    businessHoursMap.put(currentTeacher.Teacher_Name__r.Id, new List<AureusCalendarController.businessHour> { bh });
                }
            }
        }
        return businessHoursMap;
    }
    
    /*
getEventsListOfBooking methods takes the following arguments

1. Set of Teacher Id's (Person Acount Id's)
2. Set of Resource Id's (Resource__c Object Id's)
3. Id of the center (Account Id)
4. List of the range of date selected by the user from the calendar UI
5. Id of the Instrument

this method returns the list of events or bookings to show on the calendar for the selected center on selected date or range of week day.

*/

    public static string BookingObjectQueryFields(String classLessonBookingType){
        return ' Id,Enrolment__r.Package_Process_Type__c,Center__r.Organisation__r.Name,Enrolment__r.Effective_Date__c,Lesson_Type__c,Camp_Id__r.id, Name, Class__r.Class_Type__c, Class__r.grade__c, Class__r.Id, Class__r.package__r.name,Class__r.Total_Enrolment__c,(Select id from Bookings1__r where type__c=:classLessonBookingType), Class__r.Available_Capacity__c,Class__r.Total_Capacity__c, Class__r.Name, Category__c, Teacher_Account__r.Name, start_Time__c, Event_Color__c, End_Time__c, status__c, type__c, Student__r.Name, RecordTypeId, Student__r.Parent__r.Name, Center_Id__c, Booking_Date__c, Instrument__c, Resource__c, Resource__r.Name, Individual_Booking__c, Remarks__c ';
    }
    public static List<AureusCalendarController.Events> getEventsListOfBooking(Set<String> setOfTeacher, Set<String> setOfResources, String centerId, List<String> datesOfAppointments, String instrument){
        // commneted by jatin: 19-feb:2020 :start: for add camp lesson record_type condition 
        Set<string> bookingRecordtype = new Set<String>{ConstantsClass.recordTypeLesson,ConstantsClass.groupBookingRecordType};
        //String groupClassRecordtype = ConstantsClass.groupBookingRecordType;
        //String lessonRecordtype = ConstantsClass.recordTypeLesson;
        String campClassRecordtype = ConstantsClass.bookingRecordsTypeCampLesson; //  19-Feb:2020:for camp lesson record_type name
        String busyType = ConstantsClass.typeBusy;
        string classLessonBookingType = ConstantsClass.trialStatus;
        //String categoryPlaceHolder = ConstantsClass.bookingCategoryPlaceHolder;
        String bookingCategoryCamp = ConstantsClass.bookingCategoryCamp; // 2-Feb-2020: new catagory add for camp class
        // commneted by jatin: 19-feb:2020 :end for add camp lesson record_type condition   
        String facilityRecordtype = ConstantsClass.recordTypeFacility ;
        String statusCanceled = ConstantsClass.statusCanceled;
        //Create Dynamic Query According to the parameters got from the calendar UI.
        //String eventsQuery = 'SELECT Id, Name, Category__c, Teacher_Account__r.Name, start_Time__c, Event_Color__c, End_Time__c, status__c, type__c, Student__r.Name, RecordTypeId, Student__r.Parent__r.Name, Center_Id__c, Booking_Date__c, Instrument__c, Resource__c, Resource__r.Name, Individual_Booking__c, Remarks__c FROM Booking__c';
        // Start:Nishi:27-Jul-2020: for manage same query field for teacher and employe Booking object
        //String eventsQuery = 'SELECT  Id,Lesson_Type__c,Camp_Id__r.id, Name, Class__r.Id, Class__r.package__r.name,Class__r.Total_Enrolment__c,(Select id from Bookings1__r where type__c=:classLessonBookingType), Class__r.Available_Capacity__c,Class__r.Total_Capacity__c, Class__r.Name, Category__c, Teacher_Account__r.Name, start_Time__c, Event_Color__c, End_Time__c, status__c, type__c, Student__r.Name, RecordTypeId, Student__r.Parent__r.Name, Center_Id__c, Booking_Date__c, Instrument__c, Resource__c, Resource__r.Name, Individual_Booking__c, Remarks__c  FROM Booking__c';
        string bookingfields =BookingObjectQueryFields(classLessonBookingType);
        String eventsQuery = 'SELECT '+bookingfields+' FROM Booking__c';
        // End:Nishi:27-Jul-2020: for manage same query field for teacher and employe Booking object
        
        if(String.isNotBlank(centerId)){
            eventsQuery += '  WHERE (Center_Id__c =: centerId OR Center__c =: centerId)';
           //system.debug('setOfResources'+setOfResources);
            if(setOfResources.size() > 0 && String.isNotBlank(centerId)){
                //Start: commented by nishi: 29-jul-2020: for show all bookings according to resource Id and manage Resounce id on calendar so we set true in  boolean value
                eventsQuery += ' AND Resource__c IN :setOfResources';
                //eventsQuery += ' AND RecordType.Name =: facilityRecordtype AND Resource__c IN :setOfResources';
                 //End: commented by nishi: 29-jul-2020: for show all bookings according to resource Id
                eventsQuery += ' AND (status__c !=: statusCanceled)';
            }else if(setOfTeacher.size() > 0 && String.isNotBlank(centerId)){
                /*commneted by jatin: 19-feb:2020 : for add camp_lesson record_type condition :
                eventsQuery += ' AND (RecordType.Name =: lessonRecordtype OR RecordType.Name =: groupClassRecordtype) AND Teacher_Account__c IN :setOfTeacher';
                //eventsQuery += ' AND RecordType.Name =: lessonRecordtype AND Teacher_Account__c IN :setOfTeacher';
                eventsQuery += ' AND (status__c !=: statusCanceled)';*/
                 // added by jatin:end: 19-Feb:2020: start :for add camp class placholder booking details  this placholder of camp class teachers
                 eventsQuery += ' AND ((RecordType.Name in:bookingRecordtype AND status__c !=: statusCanceled)';
                //commented by jatin: 26-Feb-2020: for new catogry add for camp class 
                // eventsQuery += ' OR (RecordType.Name =: campClassRecordtype AND Type__c =: busyType AND Category__c =:categoryPlaceHolder)';
                eventsQuery += ' OR (RecordType.Name =: campClassRecordtype AND Type__c =: busyType AND Category__c =:bookingCategoryCamp)';
                eventsQuery +=')';
                eventsQuery += ' AND (Teacher_Account__c IN :setOfTeacher) ';
                 // added by jatin:end: 19-Feb:2020:end: for add camp class placholder booking details  this placholder of camp class teachers
            }
            
            if(String.isNotBlank(instrument) && setOfTeacher.size() > 0){
                eventsQuery += ' AND (Instrument__c  =: instrument)';
            }
            
            if(datesOfAppointments.size() == 1){
                Date dateOfEvent = Date.valueOf(datesOfAppointments[0]);
                eventsQuery += ' AND Booking_Date__c =: dateOfEvent AND start_Time__c != NULL AND End_Time__c != NULL';
            }else if(datesOfAppointments.size() == 2){
                Date startEventDate = Date.valueOf(datesOfAppointments[0]);
                Date endEventDate = Date.valueOf(datesOfAppointments[1]);
                eventsQuery += ' AND Booking_Date__c >= :startEventDate AND Booking_Date__c <= :endEventDate AND start_Time__c != NULL AND End_Time__c != NULL';
            }
            
        }
       //system.debug('eventsQuery'+eventsQuery);
        Set<String> setOfBookings = new Set<String>();
        List<Booking__c> bookingList = new List<Booking__c>();
        if(String.isNotBlank(eventsQuery)){
           //system.debug('Database.query(eventsQuery)'+Database.query(eventsQuery));
            for(Booking__c book: Database.query(eventsQuery)){
                bookingList.add(book);
                setOfBookings.add(book.Id);
            }
        }
        //Start: commented by nishi: 29-jul-2020: for show all bookings according to resource Id and manage Resounce id on calendar so we set true in  boolean value
        Boolean isGetResource= (setOfResources != null && setOfResources.size() > 0)? true:false;
        //end: commented by nishi: 29-jul-2020: for show all bookings according to resource Id and manage Resounce id on calendar so we set true in  boolean value
       //system.debug('isGetResource'+isGetResource);
       //system.debug('setOfResources'+setOfResources);
       //system.debug('bookingList'+bookingList);
        return getEventsListOfBookingOrEmployees(setOfBookings,bookingList,centerId,setOfTeacher,datesOfAppointments,true,isGetResource);
    }
    public static List<AureusCalendarController.Events> getEventsListOfBookingOrEmployees(Set<String> setOfBookings,List<Booking__c> bookingList,String centerId,Set<String> setOfTeacher,List<String> datesOfAppointments,Boolean isTeacherEvent,Boolean isGetResourceId){
        List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
        Map<String, Integer> countOfBookings = new Map<String, Integer>();
        AureusCalendarController.Events currentEvent = new AureusCalendarController.Events();
        //Get list of booking content notes count. If the count of notes is more than 0.
        // we will show the message icon on event on calendar.
        // this method takes the set of booking Id's and returns the count of notes for perticular booking.
        countOfBookings  = getContentNoteCount(setOfBookings);
        
        if(bookingList.size() > 0){
            
            for(Booking__c book: bookingList){
                String eventTitle = '';
                
                if(String.isNotBlank(book.Student__r.Name)){
                    eventTitle += book.Student__r.Name;
                }else{
                    eventTitle += '';
                }
                
                if(String.isNotBlank(book.Student__r.Parent__r.Name)){
                    eventTitle +=  ' - ' +book.Student__r.Parent__r.Name;    
                }else{
                    eventTitle += '';
                }
                
                
                
                if(book.Type__c == ConstantsClass.typeBusy){
                    eventTitle = book.Remarks__c;
                }
                
                currentEvent = new AureusCalendarController.Events();
                currentEvent.id = book.Id;
                if(isTeacherEvent){
                    if(String.isNotBlank(book.Camp_Id__r.id)){
                        currentEvent.isClass = TRUE;
                    }
                     //added by Nishi:Start: 17-Jul-2020: for manage Ossia Organization student	
                    if( String.isNotBlank(book.Center__c) && String.isNotBlank(book.Center__r.Organisation__c) && 	
                        String.isNotBlank(book.Center__r.Organisation__r.Name) && 	
                        book.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){	
                        currentEvent.isOssia = TRUE;	
                    }	
                      //added by End:Start: 17-Jul-2020: for manage Ossia Organization student
                    if(String.isNotBlank(book.Class__r.Id)){
                        // eventTitle = book.Class__r.Name;
                        // eventTitle = book.Class__r.package__r.Name+' '+book.Class__r.Available_Capacity__c+'/'+book.Class__r.Total_Capacity__c;
                        // 7-Jan-2020:jatin:Need to Replace the Available Capacity to Total Enrolment on the Calendar View of Class Booking 
                        string classCapacity = ''+(string.valueOf(book.Class__r.Total_Enrolment__c) != null ? string.valueOf(book.Class__r.Total_Enrolment__c) :  '0' )+'/';
                        classCapacity += ''+(string.valueOf(book.Class__r.Total_Capacity__c) != null ? string.valueOf(book.Class__r.Total_Capacity__c) : '0' );
                        // 15-Jan-2020: add Group Class Trial Count 
                        String  trialBookingSize = '';
                        if(book.Bookings1__r != null && book.Bookings1__r.size() > 0){
                            trialBookingSize += ' T:'+book.Bookings1__r.size(); 
                        }
                        
                        eventTitle = book.Class__r.package__r.Name+' '+classCapacity + trialBookingSize;
                        currentEvent.isClass = TRUE;
                        if(currentEvent.isOssia){
                            eventTitle = book.Class__r.Class_Type__c +' '+classCapacity + trialBookingSize;
                        }
                    }
                }
                currentEvent.title = eventTitle ;
                //currentEvent.overlap = false;
                //Start:Added By nishi: for manage Resource Id and Teacher Id 
                if(isGetResourceId){
                    if(String.isNotBlank(book.Resource__c)){
                        currentEvent.resourceId = book.Resource__c;
                    }
                }else{
                    if(String.isNotBlank(book.Teacher_Account__c)){
                        currentEvent.resourceId = book.Teacher_Account__c;
                    }
                }
                //End:Added By nishi: for manage Resource Id and Teacher Id
                
                currentEvent.Status = book.status__c;
                currentEvent.Type = book.type__c;
                
                currentEvent.start = String.valueOf(book.Booking_Date__c)+'T'+String.valueOf(book.start_Time__c).split('\\.')[0];
                currentEvent.end_c = String.valueOf(book.Booking_Date__c)+'T'+String.valueOf(book.End_Time__c).split('\\.')[0];
               // added by jatin:20-mar-2020: for show group class background color
                if(String.isNotBlank(book.Class__r.Id) && book.type__c != 'busy'){
                    currentEvent.eventColor ='#FFBF00';
                }else{
                    currentEvent.eventColor = book.Event_Color__c;
                }
                if(countOfBookings.containsKey(book.Id)){
                    currentEvent.Notes = String.valueOf(countOfBookings.get(book.Id));
                }
                currentEvent.eventTextColor = ConstantsClass.eventTextColor;
                currentEvent.parentId = String.valueOf(book.Student__r.Parent__c);
                currentEvent.Individual = String.valueOf(book.Individual_Booking__c);
                currentEvent.category = book.Category__c;
                // Added By Ravi on 2nd july 2020 
                if(String.isNotBlank(book.Lesson_Type__c) && book.Lesson_Type__c != NULL ){
                   currentEvent.lessonType=book.Lesson_Type__c; 
                   integer dateDiffrence =0;
                    if(book.Enrolment__r.Effective_Date__c != null){
                        dateDiffrence = book.Booking_Date__c.daysBetween(book.Enrolment__r.Effective_Date__c);
                    }else{
                        dateDiffrence = system.Today().daysBetween(book.Booking_Date__c);
                    }
                   if(book.Lesson_Type__c == 'Online' && string.isNotBlank(book.Enrolment__r.Package_Process_Type__c) && 
                        book.Enrolment__r.Package_Process_Type__c == 'Cancellation'&& 
                        book.Type__c == 'Regular' &&  dateDiffrence <=28 ){
                        currentEvent.className = book.Type__c.trim().replaceAll('-','_') +'CancelClass'; 
                   }else{
                        if(book.Lesson_Type__c == 'Online' && string.isNotBlank(book.Instrument__c)  && book.Type__c == 'Regular'){
                                currentEvent.className = book.Instrument__c.trim().replaceAll(' ','_') +'Class';
                        }else if(book.Lesson_Type__c == 'Online'){
                            if(book.Type__c == 'Trial' && book.Status__c =='Blocked'){
                                currentEvent.className = book.Type__c.trim().replaceAll('-','_') +book.Status__c+'Class'; 
                            }else{
                                currentEvent.className = book.Type__c.trim().replaceAll('-','_') +'Class'; 
                            }
                        }
                    }
                }else{
                    currentEvent.lessonType='';
                }
                // Added By Ravi on 2nd july 2020
                eventsList.add(currentEvent);
                
            }
            
        }
        if(isTeacherEvent)
             eventsList.addAll(getFifthLessonEvents(centerId, setOfTeacher, datesOfAppointments));
        return eventsList;
    }
    /*
getContentNoteCount methods takes the following arguments

1. Set of bookings Id's

This method return the Map of Id and its associative count of booking notes.

*/
    public static Map<String, integer> getContentNoteCount(set<String> setOfBookings){
        List<Id> contentNotes = new List<Id>();
        Map<String, integer> countOfNotes = new Map<String, integer>();
        
        if(setOfBookings.size() > 0){
            AggregateResult[] groupedResults = [SELECT  LinkedEntityId, Count(ContentDocumentId) notes FROM ContentDocumentLink WHERE ContentDocument.FileType = 'SNOTE' AND LinkedEntityId IN :setOfBookings  GROUP BY LinkedEntityId];
            for(AggregateResult result : groupedResults){
                countOfNotes.put(String.valueOf(result.get('LinkedEntityId')), (Integer)result.get('notes'));
            }
        }
        
        return countOfNotes;
    }

    

    /*
getListOfTeacher is a overloaded methods which invoks according to the parameters
there are four methods
1. By center
2. By center and teacher
3. By center and multiple teacher
4. By center and teachers and instruments

These methods returns the List of accounts according to the respective parameters

*/
    //---------------List of teachers methods--------------------------- 
    
    
    public static List<Account> getListOfTeacher(String centerId){
        List<Account> accList = new List<Account>();
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        Set<String> teachersIdSet = new Set<String>();
        
        if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        
        String query = '';             
        if(teachersIdSet.size() > 0){
            query = 'SELECT Id, Name FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus';
            query+= ' AND id IN : teachersIdSet';
            query+= ' ORDER BY Name';
        }
        if(String.isNotBlank(query))
            accList = Database.query(query);
        
        return accList;
    }
    
    public static List<Account> getListOfTeacher(String centerId, String teacherId){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        
        String query;
        if(String.isNotBlank(teacherId)){
            query = 'SELECT Id, Name FROM Account WHERE RecordType.Name =: teacherRecType  AND Status__c =: teacherWorkingStatus AND Id =: teacherId ORDER BY Name';
        }
        
        return Database.query(query);
    }
    public static List<Account> getListOfTeacher(String centerId, Set<String> teacherId){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        String query;
        if(teacherId.size() > 0){
            query = 'SELECT Id, Name FROM Account WHERE RecordType.Name =: teacherRecType  AND Status__c =: teacherWorkingStatus AND Id IN :teacherId ORDER BY Name';
        }
        return Database.query(query);
    }
    public static List<Account> getListOfTeacher(String centerId, Set<String> teacherId, String instrument){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        String query;
        if(teacherId.size() > 0 && String.isNotBlank(instrument)){
            query = 'SELECT Id, Name, Minor_Instruments_Disciplines__c, Major_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecType  AND Status__c =: teacherWorkingStatus AND Id IN :teacherId AND (Minor_Instruments_Disciplines__c includes (:instrument) OR Major_Instruments_Disciplines__c includes (:instrument)) ORDER BY Name';
        }
        return Database.query(query);
    }
    
    public static List<Account> getListOfTeachersByInstrument(String centerId, String instrument){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        Set<String> teachersIdSet = new Set<String>();
        
        if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        
        String query = 'SELECT Id, Name, Minor_Instruments_Disciplines__c, Major_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus';
        if(teachersIdSet.size() > 0){
            query+= ' AND (Minor_Instruments_Disciplines__c includes (:instrument) OR Major_Instruments_Disciplines__c includes (:instrument)) AND id IN : teachersIdSet';
        }
        
        query+= ' ORDER BY Name';
        
        return Database.query(query);
    }
    //---------------xxx-------------------
    /*
getResourceWorkingHours method takes the following arguments

1. Center Id
2. Resource Id
3. List of week days

This Method return Resources working hours according to the parameters.

*/
    public static AureusCalendarController.ResourceWorkingHours getResourceWorkingHours(String centerId, String resourceId, List<String> weekDays){
        String resourceStatusAvailable = ConstantsClass.resourceStatusAvailable;
        Map<String, integer> MapOfWeek = new Map<String, integer>{'Mon' => 2, 'Tue' => 3, 'Wed' => 4, 'Thu' => 5, 'Fri' => 6, 'Sat' => 7, 'Sun' => 1};
            AureusCalendarController.ResourceWorkingHours resourceHours = new AureusCalendarController.ResourceWorkingHours();
        String resourceWorkingHoursQuery = 'SELECT Id, Name, Resource_Name__c, Resource_Name__r.Name, Resource_Name__r.status__c, Center_Name__c, Active__c, Working_Day__c, Start_Time__c, End_Time__c, Break_Time__c FROM Resource_Working_Hour__c';
        
        if(String.isNotBlank(centerId) || weekDays.size() > 0){
            resourceWorkingHoursQuery += ' WHERE Active__c = true AND Resource_Name__r.status__c =: resourceStatusAvailable AND ';
        }
        
        if(String.isNotBlank(centerId)){
            resourceWorkingHoursQuery += 'Center_Name__r.Id =: centerId';
        }
        
        if(resourceId != 'AllRosteredResource' && resourceId != 'AllResource' && resourceId != 'AllLesson' && resourceId != 'AllNonLesson'){
            resourceWorkingHoursQuery += ' AND Resource_Name__c =: resourceId';
        }
        
        if(weekDays.size() == 1){
            String weekDay = weekDays[0];
            resourceWorkingHoursQuery += ' AND Working_Day__c =: weekDay ';
        }else if(weekDays.size() == 2){
            
            List<integer> weekList = new List<integer>(); 
            for(String current : weekDays){
                if(MapOfWeek.containsKey(current)){
                    weekList.add(MapOfWeek.get(current));
                }
            }
            
            if(weekList.size() >= 2){
                Set<String> weekDaySet = getWeekDaySet(weekList);
                resourceWorkingHoursQuery += ' AND Working_Day__c IN :weekDaySet';
            }
        }
        
        if(String.isNotBlank(resourceWorkingHoursQuery)){
            resourceHours.resourcesHours = new List<Resource_Working_Hour__c>();
            resourceHours.setOfResources = new Set<String>();
            for(Resource_Working_Hour__c ResourceCurrentHour : Database.query(resourceWorkingHoursQuery)){
                resourceHours.resourcesHours.add(ResourceCurrentHour);
                resourceHours.setOfResources.add(ResourceCurrentHour.Resource_Name__r.Id);
            }
        }
        return resourceHours;
    }
    
    /*
getResourcesWorkingHours method takes the following arguments

1. ResourcesWorkingHours from the getResourceWorkingHours method
2. resource Id
3. Map of weekdays

This Method returns the map of Resources working hours for the fullcalendar.

*/
    
    public static Map<String, List<AureusCalendarController.businessHour>> getResourcesWorkingHours(AureusCalendarController.ResourceWorkingHours workingHoursOfResource, String resourceId, Map<String, String> mapOfweekDays){
        Map<String, Integer> MapOfWeek = new Map<String, Integer>{'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6, 'Sun' => 0};
            AureusCalendarController.businessHour bh = new AureusCalendarController.businessHour();
        Map<String, List<AureusCalendarController.businessHour>> businessHoursMap = new Map<String, List<AureusCalendarController.businessHour>>();
        
        if(workingHoursOfResource.resourcesHours.size() > 0){
            for(Resource_Working_Hour__c currentResource : workingHoursOfResource.resourcesHours) {
                
                if(businessHoursMap.containsKey(currentResource.Resource_Name__r.Id)) {
                    
                    bh = new AureusCalendarController.businessHour();
                    List<AureusCalendarController.businessHour> hours = businessHoursMap.get(currentResource.Resource_Name__r.Id);
                    
                    if(String.isNotBlank(String.valueOf(currentResource.Start_Time__c ))){
                        bh.start = String.valueOf(currentResource.Start_Time__c ).split('\\.')[0];
                    }
                    
                    if(String.isNotBlank(String.valueOf(currentResource.End_Time__c))){
                        bh.end_c = String.valueOf(currentResource.End_Time__c).split('\\.')[0];
                    }
                    
                    bh.dow = new List<Integer>();
                    
                    if(MapOfWeek.containsKey(currentResource.Working_Day__c)){
                        bh.dow.add(MapOfWeek.get(currentResource.Working_Day__c));
                    }
                    
                    hours.add(bh);
                    businessHoursMap.put(currentResource.Resource_Name__r.Id, hours);
                    
                }else{
                    
                    bh = new AureusCalendarController.businessHour();
                    
                    if(String.isNotBlank(String.valueOf(currentResource.Start_Time__c ))){
                        bh.start = String.valueOf(currentResource.Start_Time__c ).split('\\.')[0];
                    }
                    
                    if(String.isNotBlank(String.valueOf(currentResource.End_Time__c))){
                        bh.end_c = String.valueOf(currentResource.End_Time__c).split('\\.')[0];
                    }
                    
                    bh.dow = new List<Integer>();
                    
                    if(MapOfWeek.containsKey(currentResource.Working_Day__c)){
                        bh.dow.add(MapOfWeek.get(currentResource.Working_Day__c));
                    }
                    
                    businessHoursMap.put(currentResource.Resource_Name__r.Id, new List<AureusCalendarController.businessHour> { bh });
                }
            }
        }
        return businessHoursMap;
    }
    
    /*
getListOfResource is a overloaded methods which invoks according to the parameters
there are three methods
1. By center
2. By center and resource
3. By center and multiple resources

These methods returns the List of Resource__c according to the respective parameters

*/
    public static List<Resource__c> getListOfResource(String centerId){
        String statusAvailable = ConstantsClass.resourceStatusAvailable;
        return [SELECT Id, Name, status__c FROM Resource__c WHERE Center__c =: centerId AND status__c =: statusAvailable ORDER BY Name];       
    }
    
    public static List<Resource__c> getListOfResource (String centerId, String resourceId){
        return [SELECT Id, Name, Type__c, Status__c, Center__c, Capacity__c FROM Resource__c WHERE Center__c =: centerId AND Id =: resourceId ORDER BY Name];
    }
    
    public static List<Resource__c> getListOfResource (String centerId, Set<String> resourceId){
        return [SELECT Id, Name, Type__c, Status__c, Center__c, Capacity__c FROM Resource__c WHERE Center__c =: centerId AND Id IN : resourceId ORDER BY Name];
    }

    //Start: added by nishi: 30-Jul-2020: for get allResource__c according to  Available_For_Aureus_Lesson__c 
    public static List<Resource__c> getListOfAvailableAureusLessonResource (String centerId, Boolean availableForAureusLesson){
        return [SELECT Id, Name, Type__c, Status__c, Center__c, Capacity__c 
                FROM Resource__c
                WHERE Center__c =: centerId 
                AND Available_For_Aureus_Lesson__c =:availableForAureusLesson
                ORDER BY Name];
    }
    //End: added by nishi: 30-Jul-2020: for get all Available_For_Aureus_Lesson__c resources
    
    //
    public static void cancelBookingProceed(String parentId){
        String customerRecordType = ConstantsClass.recordTypeCustomer;
        string lessonRecordtype = ConstantsClass.recordTypeLesson;
        string grouplessonRecordtype = ConstantsClass.groupLessonBookingRecordType;
        string statusCanceled = ConstantsClass.statusCanceled; 
        Map<String, Integer> sumOfParentMakupHours = new Map<String, Integer>();
         // Added by :19-dec:2019 jatin for manage group lesson bookings available mins 
        Map<String, Integer> sumOfParentGroupMakupHours = new Map<String, Integer>();
        List<Account> studentList = new List<Account>();
        List<Account> parentList = new List<Account>();
        Set<Id> setOfStudents = new Set<Id>();
        if(String.isNotBlank(parentId)){
            setOfStudents.add(parentId);
            studentList = [SELECT Id, Parent__c, RecordType.Name
                             FROM Account 
                             WHERE RecordType.Name = :customerRecordType 
                             AND Parent__c =: parentId];
            if(studentList.size() > 0){
                for(Account student : studentList){
                    setOfStudents.add(student.Id);
                }
            }
            if(setOfStudents.size() > 0){
                integer count = 0;integer groupCount = 0;
                for (AggregateResult ar : [SELECT  Student__c, SUM(Available_Make_up_Units__c) 
                                            sumOfHours 
                                            FROM Booking__c 
                                            WHERE Recordtype.Name =: lessonRecordtype 
                                            AND status__c =: statusCanceled 
                                            AND Student__c IN :setOfStudents 
                                            AND Make_up_Expiry_Date__c > TODAY
                                            AND Make_up_Expiry_Date__c != NULL 
                                            GROUP BY Student__c ])  {
                    if(ar.get('sumOfHours') != NULL){
                        sumOfParentMakupHours.put(String.valueOf(ar.get('Student__c')),
                         Integer.valueOf(ar.get('sumOfHours'))); 
                    }
                    
                }
                 if(sumOfParentMakupHours.values().size() > 0){
                    for(integer counter : sumOfParentMakupHours.values()){
                        if(counter != NULL){
                            count += counter;
                        }
                    }
                }
                // @@jatin: 19-dec-2019: manages Availabel makeup booking for group type
                
                for (AggregateResult ar : [SELECT  Student__c, SUM(Available_Make_up_Units__c) 
                                            sumOfHours 
                                            FROM Booking__c 
                                            WHERE Recordtype.Name =: grouplessonRecordtype 
                                            AND status__c =: statusCanceled 
                                            AND Student__c IN :setOfStudents 
                                            AND Make_up_Expiry_Date__c > TODAY
                                            AND Make_up_Expiry_Date__c != NULL 
                                            GROUP BY Student__c ])  {
                    if(ar.get('sumOfHours') != NULL){
                        sumOfParentGroupMakupHours.put(String.valueOf(ar.get('Student__c')),
                         Integer.valueOf(ar.get('sumOfHours'))); 
                    }
                    
                }
                
                 if(sumOfParentGroupMakupHours.values().size() > 0){
                    for(integer counter : sumOfParentGroupMakupHours.values()){
                        if(counter != NULL){
                            groupCount += counter;
                        }
                    }
                }
              //system.debug('count'+count);
                /*for(String currentParent : sumOfParentMakupHours.keyset()){
count += sumOfParentMakupHours.get(currentParent);
if(sumOfParentMakupHours.containsKey(currentParent)){
parentList.add(new Account(Id = currentParent, Available_Make_up_Units__c = sumOfParentMakupHours.get(currentParent)));
}
}*/
               //system.debug('groupCount'+groupCount);
                if(count >= 0 || groupCount >= 0){
                    parentList.add(new Account(Id = parentId, Available_Make_up_Units__c = count,
                   // added by jatin:19-dec-2019: for add makeupmins for group type booking 
                    Available_Make_up_mins_For_Group__c = groupCount ));
                    
                }
            }
            
        }
        
        if(parentList.size() > 0){
            update parentList;
        }
    }
    
    public static List<Booking__c> createAppointmentForAdhoc(Package__c packageObj, String teacherId, String studentId, String centerId, Integer recurring, 
    String bookingDate, String parentId,String lessonMode,String resourceId,String enrolmentId){
        Date bookDate;
        Time bookStartTime;
        Time bookEndTime;
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c bookingObj = new Booking__c();
        if(String.isNotBlank(bookingDate) && packageObj != NULL && packageObj.Duration__c != 'Trial'){
            bookDate = Date.valueOf(bookingDate.split('T')[0]);
            bookStartTime = Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
            bookEndTime = bookStartTime;
            bookEndTime = bookEndTime.addMinutes(Integer.valueOf(packageObj.Duration__c));
        }
        if(String.isNotBlank(teacherId) && String.isNotBlank(centerId) && String.isNotBlank(bookingDate) && recurring > 0 && packageObj != NULL && String.isNotBlank(studentId)){
            for(integer i=1;i<=recurring;i++){
                bookingObj = new Booking__c();
                bookingObj.recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
                bookingObj.Center__c = centerId;
                bookingObj.Package__c = packageObj.Id;
                bookingObj.Student__c = studentId;
                bookingObj.Teacher_Account__c = teacherId;
                bookingObj.Booking_Date__c = bookDate;
                bookingObj.Start_Time__c = bookStartTime;
                bookingObj.End_Time__c = bookEndTime;
                bookingObj.Type__c = ConstantsClass.typeAdhoc;
                bookingObj.Status__c = ConstantsClass.statusScheduled;
                // added by nishi: 18-Aug:2020: for manage enolment id in Adhoc bookings
                if(string.isNotBlank(enrolmentId)){
                    bookingObj.enrolment__c = enrolmentId;
                }
                 // added by nishi: 18-Aug:2020: for manage enolment id in Adhoc bookings
                  // added by nishi: 18-sep:2020: for manage Resouce and lesson type
                if(string.isNotBlank(lessonMode)){
                    bookingObj.Lesson_Type__c = lessonMode;
                }
                if(string.isNotBlank(resourceId)){
                    bookingObj.resource__c = resourceId;
                } 
                // added by nishi: 18-sep:2020: for manage Resouce and lesson type
                bookingObj.Parent__c = String.isNotBlank(parentId)  ? parentId : null;
                bookingList.add(bookingObj);
                bookDate = bookDate.addDays(7);
            }
        }
        return bookingList;
    }

    // added by nishi: 2-nov-2020: for creating adhoc booking for group lessons
    public static List<Booking__c> createAppointmentForAdhocGroupLesson(Package__c packageObj, String teacherId, String studentId, String centerId, Integer recurring, 
    String bookingDate, String parentId,String groupLessonId,String enrolmentId){
        Date bookDate;
        Time bookStartTime;
        Time bookEndTime;
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c bookingObj = new Booking__c();
        if(String.isNotBlank(bookingDate) && packageObj != NULL && packageObj.Duration__c != 'Trial'){
            bookDate = Date.valueOf(bookingDate.split('T')[0]);
            bookStartTime = Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
            bookEndTime = bookStartTime;
            bookEndTime = bookEndTime.addMinutes(Integer.valueOf(packageObj.Duration__c));
        }
        if(String.isNotBlank(teacherId) && String.isNotBlank(centerId) && String.isNotBlank(bookingDate) && recurring > 0 && packageObj != NULL && String.isNotBlank(studentId)){
            for(integer i=1;i<=recurring;i++){
                bookingObj = new Booking__c();
                bookingObj.recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
                bookingObj.Center__c = centerId;
                bookingObj.Group_Class__c = string.isNotBlank(groupLessonId) ? groupLessonId :null;
                bookingObj.Package__c = packageObj.Id;
                bookingObj.Student__c = studentId;
                bookingObj.Teacher_Account__c = teacherId;
                bookingObj.Booking_Date__c = bookDate;
                bookingObj.Start_Time__c = bookStartTime;
                bookingObj.End_Time__c = bookEndTime;
                bookingObj.Type__c = ConstantsClass.typeAdhoc;
                bookingObj.Status__c = ConstantsClass.statusScheduled;
                // added by nishi: 18-Aug:2020: for manage enolment id in Adhoc bookings
                if(string.isNotBlank(enrolmentId)){
                    bookingObj.enrolment__c = enrolmentId;
                }
                bookingObj.Parent__c = String.isNotBlank(parentId)  ? parentId : null;
                bookingList.add(bookingObj);
                bookDate = bookDate.addDays(7);
            }
        }
        return bookingList;
    }
    
    public static Case createCase(String caseId, String bookingId, String origin){
        Case currentCase = new Case();
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c objBooking;
        if(String.isNotBlank(bookingId)){
            bookingList = [SELECT Id, Center__c, Center__r.Location__c, Student__c, Student__r.PersonContactId, Student__r.Parent__c, Student__r.Parent__r.PersonContactId  
                           , Enrolment__c FROM Booking__c WHERE Id =: bookingId];
            if(bookingList.size() > 0){
                objBooking = bookingList[0]; 
                if(String.isNotBlank(caseId)){
                    currentCase.Id = caseId;
                }
                currentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.caseServiceEnqRecTypeName).getRecordTypeId();
                currentCase.Booking__c = objBooking.Id;
                if(String.isNotBlank(objBooking.Student__r.Parent__c)){
                    currentCase.ContactId = objBooking.Student__r.Parent__r.PersonContactId;
                    currentCase.AccountId = objBooking.Student__r.Parent__c;
                }else if(String.isNotBlank(objBooking.Student__c) && String.isBlank(objBooking.Student__r.Parent__c)){
                    currentCase.ContactId = objBooking.Student__r.PersonContactId;
                    currentCase.AccountId = objBooking.Student__c;
                }
                if(String.isNotBlank(objBooking.Enrolment__c) && origin == 'Trial'){
                    currentCase.Enrolment__c = objBooking.Enrolment__c;
                }else if(String.isNotBlank(objBooking.Enrolment__c) && (origin == 'Ad-hoc' || origin == 'Make-Up')){
                    currentCase.Enrolment__c = objBooking.Enrolment__c;
                }
                currentCase.Student_Name__c = objBooking.Student__c;
                currentCase.Centre_Name__c = objBooking.Center__c;
                currentCase.Location__c = objBooking.Center__r.Location__c;
                
                currentCase.Status =  ConstantsClass.caseOpenStatus;  // ConstantsClass.casePendingStatus;
                if(origin == 'cancel'){
                    currentCase.Type = ConstantsClass.cancelType;
                }else if(origin == 'Reschedule'){
                    currentCase.Type = ConstantsClass.rescheduleType;
                }else if(origin == 'Make-Up'){
                    currentCase.Type = ConstantsClass.caseMakeupType;
                }
                if(String.isNotBlank(caseId)){
                    currentCase.Subject = currentCase.Type; 
                }
                currentCase.Priority = 'Medium';
            }  
            //if(currentCase != NULL){
            upsert currentCase; 
            //}          
        }
        /*if(String.isNotBlank(currentCase.Id)){
sendBookingCancelMail(currentCase.Id);
system.debug('@@About to sendBookingCancelMail');
}*/
        return currentCase;
    }
    public static Case createCaseForEnrolment(String caseId, String enrolmentId, String origin, Boolean isDML){
        Case currentCase = new Case();
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
        Enrolment__c objEnrolment;
        if(String.isNotBlank(enrolmentId)){
            enrolmentList = [SELECT Id, Parent__c, Parent__r.PersonContactId, Student__c, Center__c, Center__r.Location__c
                             FROM Enrolment__c WHERE Id =: enrolmentId];
            if(enrolmentList.size() > 0){
                objEnrolment = enrolmentList[0];
                
            }
            if(String.isNotBlank(caseId)){
                currentCase.Id = caseId;
            }
            currentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.caseServiceEnqRecTypeName).getRecordTypeId();
            currentCase.Enrolment__c = enrolmentId;
            currentCase.ContactId = objEnrolment.Parent__r.PersonContactId;
            currentCase.AccountId = objEnrolment.Parent__c;
            currentCase.Student_Name__c = objEnrolment.Student__c;
            currentCase.Centre_Name__c = objEnrolment.Center__c;
            currentCase.Location__c = objEnrolment.Center__r.Location__c;
            if(origin == 'withdrawal'){
                currentCase.Type = ConstantsClass.enrolmentProcessWithdrawalTypeForCase;
            }else if(origin == 'upgrade'){
                currentCase.Type = ConstantsClass.enrolmentProcessUpgradeTypeForCase;
            }else if(origin == 'downgrade'){
                currentCase.Type = ConstantsClass.enrollmentProcessDowngradeType;
            }else if(origin == 'change'){
                currentCase.Type = ConstantsClass.enrollmentProcessChanged;
            } 
            //added by nishi: 28-Aug:2020: for if user can change center then we added this type
            else if(origin == 'changeCenter'){
                currentCase.Type = ConstantsClass.enrollmentProcessChangedCenter;
            } 
            currentCase.Priority = 'Medium';
            currentCase.Subject = currentCase.Type;
            if(isDML){
                upsert currentCase;
            }
            
        }
        return currentCase;
    }
    
    public static void processFutureBookings(Enrolment__c enrolObj, String type){
        Integer timeDuration = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        for(Booking__c objBook : [SELECT Id, Start_Time__c, end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                  Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                  Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c 
                                  FROM Booking__c WHERE Enrolment__c =: enrolObj.Id AND Booking_Date__c >=:enrolObj.effective_Date__c
                                  AND Type__c =: ConstantsClass.typeRegular AND Status__c !=: ConstantsClass.statusCanceled]){
                                      
                                     //system.debug('@@@objBook'+objBook.package__r);
                                      if(objBook.Enrolment__r.Next_Lesson_Start_time__c != NULL && (type == 'downgrade' || type == 'upgrade' || type == 'change')){
                                          
                                          //Arpit commented this
                                          objBook.start_time__c = objBook.Enrolment__r.Next_Lesson_Start_time__c;
                                      }else if(objBook.Enrolment__r.Lesson_Start_time__c != NULL){
                                          //Arpit commented this
                                          objBook.start_time__c = objBook.Enrolment__r.Lesson_Start_time__c;
                                      }
                                      
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__r.Duration__c) && String.isNotBlank(objBook.package__r.Duration__c)){
                                          timeDuration =  Integer.valueOf(objBook.Enrolment__r.new_package_Id__r.Duration__c) - Integer.valueOf(objBook.package__r.Duration__c);                      
                                      }
                                      if(String.isNotBlank(objBook.Enrolment__r.New_Teacher__c)){
                                          objBook.teacher_Account__c = objBook.Enrolment__r.New_Teacher__c;
                                      }    
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__c) && !objBook.Is_fifth_booking__c){
                                          objBook.package__c = objBook.Enrolment__r.new_package_Id__c; 
                                      }
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__c) && !objBook.Is_fifth_booking__c){
                                          objBook.end_time__c = objBook.start_Time__c.addMinutes(Integer.valueOf(objBook.Enrolment__r.new_package_Id__r.Duration__c));
                                      }else{
                                          objBook.end_time__c = objBook.start_Time__c.addMinutes(Integer.valueof(objBook.package__r.Duration__c));
                                      }
                                      
                                      bookingList.add(objBook);
                                  }
        if(bookingList.size() >0){
            UPSERT bookingList;
        }
    }
    
    public static Package__c fetchDesiredPackage(String centreId, String packageDuration){
        return [SELECT Id FROM Package__c WHERE Location__c =: centreId AND Type__c =: ConstantsClass.pakageTypeMakeup AND 
                Duration__c =: packageDuration AND Active__c = True LIMIT 1];
    }
    
    public static Package__c fetchDesiredPackage(String packageId){
        return [SELECT Id, Duration__c FROM Package__c WHERE Id =: packageId LIMIT 1];
    }
    
    public static Decimal fetchParentMakeup(String parentId){
        Decimal availableMakeUps = 0; 
        List<Account> parentObjList = [SELECT Id, Name, RecordType.Name, Available_Make_up_Units__c FROM Account WHERE Id =: parentId AND RecordType.Name =:ConstantsClass.recordTypeCustomer];
        if(parentObjList.size() > 0){
            if(parentObjList[0].Available_Make_up_Units__c != NULL){
                availableMakeUps = parentObjList[0].Available_Make_up_Units__c;
            }
        }
        return availableMakeUps;
    }
    
    
    public static void createFifthBookingOnUpgrade(Enrolment__c enrol, Map<String, Booking__c> mapOfFifthBookings, Integer timeDiff, Time startTime, Integer duration){
        List<Booking__c> bookingsinsertList = new List<Booking__c>();
        map<string,Booking__c> mapbookingsupdate = new map<string,Booking__c>();
        List<Booking__c> cancelBookings = new List<Booking__c>();
        Decimal availableUnits = 0;
       
        Package__c makeupPackage = fetchDesiredPackage(enrol.Center__c , String.valueOf(timeDiff));
        String utilizedBookings = '';
        if(String.isNotBlank(enrol.Parent__c)){
            availableUnits = fetchParentMakeup(enrol.Parent__c);
        }
        if(availableUnits >= timeDiff && String.isNotBlank(enrol.Parent__c)){
            cancelBookings = fetchCancelBookings(fetchChildrens(enrol.Parent__c));
        }
       //System.debug('cancelBookings'+cancelBookings);
       //System.debug('availableUnits'+availableUnits);
       Booking__c bookObj = new Booking__c();
       Booking__c newBook = new Booking__c();
        for(String bookingId : mapOfFifthBookings.keySet()){
            bookObj = mapOfFifthBookings.get(bookingId);
            newBook = new Booking__c();
            if(startTime != NULL && duration > 0){
                bookObj.start_Time__c = startTime;
                bookObj.end_Time__c = bookObj.start_Time__c.addMinutes(duration);
            }
            
            newBook.Booking_Date__c = bookObj.Booking_Date__c;
            if(bookObj.Type__c == ConstantsClass.typeMakeup){
                
                if(availableUnits >= timeDiff){
                    newBook.Type__c = ConstantsClass.typeMakeup;
                    newBook.Status__c = ConstantsClass.statusScheduled;
                    newBook.Package__c = makeupPackage.Id;
                    newBook.Student__c = bookObj.Student__c;
                    for(Booking__c bookingObj : cancelBookings){
                        Integer hoursToDeduct = timeDiff;
                        if(hoursToDeduct <= bookingObj.Available_Make_up_Units__c){
                            bookingObj.Available_Make_up_Units__c = bookingObj.Available_Make_up_Units__c - hoursToDeduct;
                            utilizedBookings += bookingObj.Id+'-'+hoursToDeduct+';'; 
                            hoursToDeduct = 0;
                        }else{
                            utilizedBookings += bookingObj.Id+'-'+bookingObj.Available_Make_up_Units__c+';';
                            hoursToDeduct -= Integer.valueOf(bookingObj.Available_Make_up_Units__c);
                            bookingObj.Available_Make_up_Units__c = 0;
                        }
                        mapbookingsupdate.put(bookingObj.id,bookingObj);
                        if(hoursToDeduct == 0){
                            break;
                        }
                    }   
                }else{
                    newBook.Type__c = ConstantsClass.typeBusy;
                    newBook.Status__c = ConstantsClass.statusScheduled;
                    newBook.package__c = NULL;
                    newBook.Remarks__c = 'Placeholder for '+bookObj.Student__r.Name;
                    newBook.Category__c = 'Placeholder';
                    newBook.enrolment__c = NULL;
                    newBook.Student__c = bookObj.Student__c;
                }
                newBook.start_Time__c = bookObj.end_Time__c;
                newBook.End_Time__c = bookObj.end_Time__c.addMinutes(timeDiff);
                newBook.Center__c = bookObj.Center__c;
                newBook.Teacher_Account__c = bookObj.Teacher_Account__c;
                
            }else if(bookObj.Type__c == ConstantsClass.typeBusy){
                bookObj.end_Time__c = bookObj.end_Time__c.addMinutes(timeDiff);
            }
            
            //bookingsList.add(bookObj);
            mapbookingsupdate.put(bookingId,bookObj);
            bookingsinsertList.add(newBook);
            
        }
        if(bookingsinsertList.size() > 0){
            upsert bookingsinsertList; 
        }
        if(mapbookingsupdate.size() > 0){
            upsert mapbookingsupdate.values(); 
        }
       //System.debug('bookingsList'+bookingsList);
        
    }
    public  static Set<String> fetchChildrens(String setOfParentIds){
        Set<String> setOfStuParentIds = new Set<String>();
        if(String.isNotBlank(setOfParentIds)){
            for( Account objAcc : [SELECT Id, also_A_Student__c FROM Account WHERE Id =: setOfParentIds OR Parent__c =: setOfParentIds]){
                setOfStuParentIds.add(objAcc.Id);
            }
        }
        return setOfStuParentIds;
    }
    
    private static List<Booking__c> fetchCancelBookings(Set<String> setOfStuParentIds){
        return [SELECT Id, Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                Student__c, Type__c, Duration__c FROM Booking__c WHERE 
                Status__c =: ConstantsClass.statusCanceled AND Student__c IN: setOfStuParentIds AND 
                Make_up_Expiry_Date__c >= TODAY AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                ORDER BY Make_up_Expiry_Date__c];
        
    }
    
    /*public static void AddFifthMakeupMinutesToParent(String studentId,String teacherId,Integer duration, Time startTime,Date effectiveDate, String lessonDay, Integer timediff, Time newStartTime, Integer newPackageDuration, String centreId){
        List<Booking__c> bookingListToUpsert = new List<Booking__c>();
        Map<String, Integer> makeupReferencMap = new Map<String, Integer>();
        String utilizeBookings = '';
        Package__c makeupPackage = fetchDesiredPackage(centreId , String.valueOf(newPackageDuration));
        Boolean flag = false;
        if(String.isNotBlank(studentId) && String.isNotBlank(teacherId) && duration > 0 && startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay)){
            
            for(Booking__c bookingObj : processMakeupBooking(studentId, teacherId, duration, startTime, effectiveDate, lessonDay)){
                Booking__c newBookObj = new Booking__c();
                flag = false;
                if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                    if(String.isNotBlank(bookingObj.Make_up_Utilize_Bookings__c)){
                        utilizeBookings = '';
                        if(bookingObj.Make_up_Utilize_Bookings__c.split(';').size() > 0){
                            for(String makeup : bookingObj.Make_up_Utilize_Bookings__c.split(';')){
                                if(Integer.valueOf(makeup.split('-')[1]) >= timediff && !flag){
                                    if(Integer.valueOf(makeup.split('-')[1]) - timediff > 0){
                                        utilizeBookings += makeup.split('-')[0]+'-'+String.valueOf(Integer.valueOf(makeup.split('-')[1]) - timediff)+';';
                                        makeupReferencMap.put(makeup.split('-')[0], timediff);
                                    }
                                    flag = true;
                                }else{
                                    utilizeBookings += makeup+';';
                                }
                            }
                        }
                    }
                    
                    newBookObj.Id = bookingObj.Id;
                    newBookObj.Make_up_Utilize_Bookings__c  = utilizeBookings;
                    if(newStartTime != NULL && newPackageDuration > 0 && String.isNotBlank(makeupPackage.Id)){
                        newBookObj.start_Time__c = newStartTime;
                        newBookObj.end_Time__c = newBookObj.start_Time__c.addMinutes(newPackageDuration);
                        newBookObj.Package__c = makeupPackage.Id;
                    }
                    utilizeBookings = '';
                    for(Booking__c bookobj : fetchSelectedBookings(makeupReferencMap.keySet())){
                        bookingListToUpsert.add(new Booking__c(Id = bookobj.Id, Available_Make_up_Units__c =  bookobj.Available_Make_up_Units__c + makeupReferencMap.get(bookobj.Id)));
                    }
                    bookingListToUpsert.add(newBookObj);                                                                         
                }else if(bookingObj.Type__c == ConstantsClass.typeBusy){
                    bookingObj.start_Time__c = newStartTime;
                    bookingObj.End_Time__c = bookingObj.start_Time__c.addMinutes(newPackageDuration);
                    bookingListToUpsert.add(bookingObj);
                }            
            }
        }
        
        if(bookingListToUpsert.size() > 0){
            update bookingListToUpsert;
        }
    }*/
    private static List<Booking__c> fetchSelectedBookings(Set<String> bookingIds){
        return [SELECT Id, Available_Make_up_Units__c, Make_up_Expiry_Date__c, Duration__c FROM Booking__c WHERE Make_up_Expiry_Date__c >= TODAY AND Id IN: bookingIds];
    }
    
    /*
This Method will call after the change of date of enrolment bookings.
It will perform following tasks
*/ 
    
    /*public static void processBookingsAfterDateChange(Enrolment__c enrolmentObj, Date effectiveDate, Date CurrentDate, String studentId, String teacherId, Integer duration, 
                                                      Time startTime, String lessonDay){
                                                          Date bookingsActionDateLimit;
                                                          //Type of Bookings List
                                                          List<Booking__c> allTypesBooking = new List<Booking__c>();
                                                          List<Booking__c> regularBookings = new List<Booking__c>();
                                                          List<Booking__c> makeupBookings = new List<Booking__c>();
                                                          List<Booking__c> cancelBookings = new List<Booking__c>();
                                                          List<Booking__c> bookingToUpsert = new List<Booking__c>();
                                                          Set<String> setOfCancelBookings = new Set<String>();
                                                          
                                                          
                                                          if(String.isNotBlank(enrolmentObj.Id)){
                                                              bookingsActionDateLimit = getMaxDateOfEnrolmentBookings(enrolmentObj.Id);   
                                                              
                                                              Integer lastDayOfMonth = Date.daysInMonth(bookingsActionDateLimit.year(), bookingsActionDateLimit.month());
                                                              bookingsActionDateLimit = Date.newInstance(bookingsActionDateLimit.year(),bookingsActionDateLimit.month(),lastDayOfMonth);
                                                          }
                                                          
                                                          if(String.isNotBlank(enrolmentObj.Id) && effectiveDate != NULL){
                                                              for(Booking__c bookObj : fetchAllFutureBookingsOfEnrolment(enrolmentObj, CurrentDate)){
                                                                  if(bookObj.Type__c == ConstantsClass.typeRegular || (bookObj.Type__c == ConstantsClass.busyBookingType && bookObj.Category__c == ConstantsClass.bookingCategoryPlaceHolder) && bookObj.Status__c != ConstantsClass.statusCanceled){
                                                                      //Fill Regular Type Bookings to delete them
                                                                      regularBookings.add(bookObj);
                                                                  }else if(bookObj.Type__c == ConstantsClass.typeRegular && bookObj.Status__c == ConstantsClass.statusCanceled){
                                                                      //Fill Regular Canceled Type Bookings to subtract their avaiable makeup minutes to their durations 
                                                                      cancelBookings.add(bookObj);
                                                                  }
                                                                  
                                                              }
                                                          } 
                                                          
                                                          //delete Regular types Bookings
                                                          if(regularBookings.size() > 0){
                                                              deleteRegularFutureBooking(regularBookings);
                                                          }
                                                          if(String.isNotBlank(studentId) && String.isNotBlank(teacherId) && duration > 0 && startTime != NULL && String.isNotBlank(lessonDay) && effectiveDate != NULL){                                        
                                                              makeupBookings = AureusCalendarControllerHelper.processMakeupBooking(studentId, teacherId, Duration, startTime, effectiveDate, lessonDay); 
                                                          }
                                                          
                                                          
                                                          if(makeupBookings.size() > 0){
                                                              cancelAllFutureMakeupBookings(makeupBookings);
                                                              
                                                          }
                                                          
                                                          if(cancelBookings.size() > 0){
                                                              for(Booking__c bookingObj : cancelBookings){
                                                                  setOfCancelBookings.add(bookingObj.Id);
                                                              }
                                                              if(setOfCancelBookings.size() > 0){
                                                                  cancelBookings = fetchSelectedBookings(setOfCancelBookings);
                                                              }
                                                          }
                                                          
                                                          //Update Regular Canceled Types Bookings
                                                          if(cancelBookings.size() > 0){
                                                              bookingToUpsert.addAll(processCanceledRegularBookings(cancelBookings));
                                                          }
                                                          
                                                          if(String.isNotBlank(enrolmentObj.Id) && effectiveDate != NULL && bookingsActionDateLimit != NULL){
                                                              bookingToUpsert.addAll(reCreateRegularBookings(enrolmentObj, effectiveDate, bookingsActionDateLimit));    
                                                          }
                                                          
                                                          
                                                          if(bookingToUpsert.size() > 0){
                                                              upsert bookingToUpsert;
                                                          }
                                                          
                                                      }*/
    
    /*
* Get max date of Bookings for perticular enrolment
*/
    private static Date getMaxDateOfEnrolmentBookings(String enrolId){
        Date maxDate;
        List<AggregateResult> AggregateResultList = [select Max(Booking_Date__c)maxDate from Booking__c where Enrolment__c =: enrolId AND Type__c =: ConstantsClass.typeRegular];
        if(AggregateResultList.size() > 0){
            for(AggregateResult agg : AggregateResultList){ 
                maxDate = (Date)agg.get('maxDate');
            }
        }
        return maxDate;
    }
    
    /*
* This method will fetch all bookings of Enrolment greater than effective date except ad-hoc type bookings
*/
    /*commented by nishi: 24-Sep-2020: this funciton not use in our class 
    private static List<Booking__c> fetchAllFutureBookingsOfEnrolment(Enrolment__c enrolObj, Date effectiveDate){
        DateTime weekDayDT = effectiveDate;
        List<Booking__c> bookingList = new List<Booking__c>();
        if(String.isNotBlank(enrolObj.Id) && effectiveDate != NULL){
            bookingList = [SELECT Id, Type__c, Status__c, Booking_Date__c, Available_Make_up_Units__c, Duration__c, 
                           Make_up_Utilize_Bookings__c, Category__c FROM Booking__c WHERE Enrolment__c =: enrolObj.Id /*((Enrolment__c =: enrolObj.Id) OR 
(Type__c =: ConstantsClass.typeMakeup AND Status__c !=: ConstantsClass.statusCanceled AND 
Student__c =: enrolObj.Student__c AND Teacher_Account__c =: enrolObj.Teacher__c AND 
start_Time__c =: enrolObj.Lesson_Start_time__c AND Duration__c = :Decimal.valueOf(enrolObj.Package__r.Duration__c)))* AND 
                           Booking_Date__c >=: effectiveDate AND Type__c !=: ConstantsClass.typeAdhoc];
        }
        return bookingList;
    }*/
   
    /*
* This method will delete all non canceled and makeup bookings greater than effective date
*/
   /* commented by nishi: 24-Sep-2020: this funciton not use in our class 
    private static void deleteRegularFutureBooking(List<Booking__c> bookingsToBeDeleted){
        DELETE bookingsToBeDeleted;
    }*/
    
    /*
* This method will return the canceled bookings whose available makeup hours
* will be processed with the following formula : Available Makeup Minutes = (Available Makeup Minutes - Duration)
*/
    /*commented by nishi: 24-Sep-2020: this funciton not use in our class 
    private static List<Booking__c> processCanceledRegularBookings(List<Booking__c> canceledBookings){
        List<Booking__c> bookingsToUpsert = new List<Booking__c>();
        for(Booking__c bookObj : canceledBookings){
            bookingsToUpsert.add(new Booking__c(Id = bookObj.Id, Available_Make_up_Units__c = bookObj.Available_Make_up_Units__c - bookObj.Duration__c));
        }
        
        return bookingsToUpsert;
    }
    */
    /*
* This method will Re-Create all Regular Bookings for the enrolment which is deleted by previous step.  
*/
    
    /*private static List<Booking__c> reCreateRegularBookings(Enrolment__c enrolObj, Date effectiveDate, Date maxdate){
        DateTime effectiveDateTime;
        //Set<Date> fifthBookingsSet = new Set<Date>();
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        
        if(effectiveDate != NULL && maxdate != NULL){
            effectiveDateTime = DateTime.newInstance(effectiveDate, Time.newInstance(0, 0, 0, 0));
            //fifthBookingsSet.addAll(fetchFifthBookingSet(effectiveDateTime, maxDate));
        }
        
        if(String.isNotBlank(enrolObj.Id)){
            Booking__c bookingObj = new Booking__c();
            while(effectiveDateTime.date() <= maxdate){
                
                bookingObj = new Booking__c();
                bookingObj.Booking_Date__c = effectiveDateTime.date();
                bookingObj.Teacher_Account__c = enrolObj.Teacher__c;
                bookingObj.Center__c = enrolObj.Center__c;
                bookingObj.Student__c = enrolObj.Student__c;
                bookingObj.Start_Time__c = enrolObj.Lesson_Start_time__c;
                bookingObj.Enrolment__c = enrolObj.Id;
                
                if(enrolObj.Package__r.Duration__c != NULL){
                    bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolObj.Package__r.Duration__c));       
                }
                
                if(bookingObj.Booking_Date__c.day() > 28){
                    //fifthBookingsSet.contains(effectiveDateTime.date())
                    bookingObj.Type__c = ConstantsClass.typeBusy;
                    bookingObj.Status__c = ConstantsClass.scheduledStatus;
                    bookingObj.Is_fifth_booking__c = True;
                    bookingObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
                    bookingObj.Remarks__c = 'Placeholder for Fifth Booking of '+enrolObj.Student__r.Name;
                    
                }else{
                    bookingObj.Package__c = enrolObj.Package__c;
                    
                    bookingObj.Type__c = ConstantsClass.typeRegular;
                    if(effectiveDateTime.date() >= enrolObj.Subscription_Line_Items__r[0].Next_Bill_Date__c){
                        bookingObj.Status__c = ConstantsClass.pendingStatus;
                    }else{
                        bookingObj.Status__c = ConstantsClass.scheduledStatus;
                    }
                }
                bookingsToInsert.add(bookingObj);
                effectiveDateTime = effectiveDateTime.addDays(7);
            }       
        }
        return bookingsToInsert;
        
    }*/
    
    /*
* This method will fetch all fifth dates of month to create busy booking on that day
*/
    
    /*private static Set<Date> fetchFifthBookingSet(DateTime effectiveDateTime, Date maxDate){
DateTime duplicate;
DateTime firstDate, LastDate;
Set<Date> setOfFifthDates = new Set<Date>();
Map<String, List<Date>> allFifthDatesMap = new Map<String, List<Date>>();
if(effectiveDateTime != NULL){
duplicate = effectiveDateTime;
firstDate = Date.newInstance(duplicate.year(), duplicate.month(), 01);
LastDate = maxDate.addMonths(1).addDays(-1);
}

if(firstDate != NULL && LastDate != NULL){
while(firstDate <= lastDate){
if(firstDate.format('EEEE') == duplicate.format('EEEE')){
if(allFifthDatesMap.containsKey(firstDate.format('MMM'))){
List<Date> dates = allFifthDatesMap.get(firstDate.format('MMM'));
dates.add(firstDate.date());
allFifthDatesMap.put(firstDate.format('MMM'), dates);
}else{
allFifthDatesMap.put(firstDate.format('MMM'), new List<Date> {firstDate.date()});
}
}

if(firstDate.format('EEEE') != duplicate.format('EEEE'))
firstDate = firstDate.addDays(1);
else
firstDate = firstDate.addDays(7);
}
}

for(String month : allFifthDatesMap.keySet()){
if(allFifthDatesMap.get(month).size() == 5){
setOfFifthDates.add(allFifthDatesMap.get(month)[4]);
}
}

return setOfFifthDates;
} */   
    
    /*
* This method will cancel All scheduled Make-up type bookings to revert makeup minutes to parent 
*/
    
    public static void cancelAllFutureMakeupBookings(List<Booking__c> makeupBookingList){
        List<Booking__c> bookingsToUpsert = new List<Booking__c>();
        Map<String, Integer> makeupReferenceList = new Map<String, Integer>();
        Set<String> bookingIds = new Set<String>();
        String utilizeBookings = '';
        
        for(Booking__c bookingObj :  makeupBookingList){
            if(String.isNotBlank(bookingObj.Make_up_Utilize_Bookings__c)){
                utilizeBookings = bookingObj.Make_up_Utilize_Bookings__c;
                if(bookingObj.Make_up_Utilize_Bookings__c.split(';').size() > 0){
                    for(String makeup : bookingObj.Make_up_Utilize_Bookings__c.split(';')){
                        if(String.isNotBlank(makeup)){
                            if(makeupReferenceList.containsKey(makeup.split('-')[0])){
                                Integer previousMinutes = makeupReferenceList.get(makeup.split('-')[0]);
                                previousMinutes += Integer.valueOf(makeup.split('-')[1]);
                                makeupReferenceList.put(makeup.split('-')[0], previousMinutes);
                            }else{
                                makeupReferenceList.put(makeup.split('-')[0], Integer.valueOf(makeup.split('-')[1]));
                            }
                            
                            bookingIds.add(makeup.split('-')[0]);
                        }
                    }
                    
                }
            }
            bookingObj.Make_up_Utilize_Bookings__c = '';
            bookingObj.Status__c = ConstantsClass.statusCanceled;
            bookingsToUpsert.add(bookingObj);
        }
       //system.debug('@@@makeupReferenceList '+makeupReferenceList);
        for(Booking__c bookobj : fetchSelectedBookings(makeupReferenceList.keySet())){
            bookingsToUpsert.add(new Booking__c(Id = bookobj.Id, Available_Make_up_Units__c =  bookobj.Available_Make_up_Units__c + makeupReferenceList.get(bookobj.Id)));
        }
       //system.debug('@@@ update makeup bookings  = '+bookingsToUpsert);
        if(bookingsToUpsert.size() > 0){
            Upsert bookingsToUpsert;    
        }
    }
    
    /*
* Fetch Makeup Packages According to its duration 
*/
    Public static String fetchMakeupPackages(String centreId, String duration){
        String packageId = '';
        List<Package__c> packageList = [SELECT Id FROM Package__c WHERE Location__c =: centreId AND
                                        Type__c =:ConstantsClass.pakageTypeMakeup AND Duration__c =: duration];
        if(packageList.size() > 0){
            packageId = packageList[0].Id;
        }
        return packageId;
    }
    
    /*
This method is used for upgrade downgrade 5th booking
@16July19 ,as per discussion with ashish, we fetch booking with same student,same teacher, same time slot,
and booking date > 28 of month.
*/
    public static List<Booking__c> processMakeupBooking(String studentId,String teacherId,Integer Duration, Time startTime, Date effectiveDate, String lessonDay){
       //system.debug('studentId '+studentId+' teacherId '+ teacherId + 'duration ' + duration + 'startTime '+ startTime + 'effectiveDate' + effectiveDate + 'lessonDay' + lessonDay);
        List<Booking__c> listOfBookings = new List<Booking__c>();
        for(Booking__c objBook : [SELECT Id,Start_time__c,End_time__c, Booking_Date__c, Available_Make_up_Units__c, 
                                  Student__r.Name, Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c, Duration__c, Type__c, Category__c FROM 
                                  Booking__c WHERE Student__c=:studentId AND Teacher_Account__c=: teacherId AND Duration__c =: duration 
                                  AND Start_time__c =: startTime AND Booking_Date__c >=: effectiveDate AND 
                                  ((Type__c =: ConstantsClass.typeMakeup) OR (Type__c =: ConstantsClass.typeBusy AND 
                                                                              Category__c =: ConstantsClass.bookingCategoryPlaceHolder)) AND Appointment_Day__c =: lessonDay]){
                                                                                  if(objBook.Booking_Date__c.day() > 28){
                                                                                      listOfBookings.add(objBook);                
                                                                                  }
                                                                              }
        
        return listOfBookings;
    }
    
    
    /*
*  This method is use for Cancel the future makeup bookings of the enrolment and delete the busy placeholder.
*/
   /* public static void processFutureMakeupAndBusyBookingsForWithdrawal(Enrolment__c enrolObj, List<Booking__c> bookingListToDelete, Set<String> setOfMakeupBookings){
        List<Booking__c> bookingListToUpdate = new List<Booking__c>();
        
        if(String.isNotBlank(enrolObj.Student__c) && String.isNotBlank(enrolObj.Teacher__c) && 
           Integer.valueOf(enrolObj.Package__r.Duration__c) > 0 && enrolObj.Lesson_Start_time__c != NULL && 
           enrolObj.Effective_Date__c != NULL && String.isNotBlank(enrolObj.Lesson_Day__c)){
               
               for(Booking__c bookingObj : processMakeupBooking(enrolObj.Student__c, enrolObj.Teacher__c,Integer.valueOf(enrolObj.Package__r.Duration__c), enrolObj.Lesson_Start_time__c, enrolObj.Effective_Date__c, enrolObj.Lesson_Day__c)){
                   
                   if(bookingObj.Type__c == ConstantsClass.busyBookingType && bookingObj.Category__c == ConstantsClass.bookingCategoryPlaceHolder){
                       bookingListToDelete.add(bookingObj);            
                   }else if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                       bookingListToUpdate.add(bookingObj);
                   }
                   
               }
               
               if(bookingListToDelete.size() > 0){
                   DELETE bookingListToDelete;
               }
               
               if(bookingListToUpdate.size() > 0){
                   cancelAllFutureMakeupBookings(bookingListToUpdate);  
               }
           }      
    }*/
    //Comment This Due to change in fifth lesson
    /*public static void processFutureMakeupAndBusyBookingsForWithdrawal(Enrolment__c enrolObj, List<Booking__c> bookingListToDelete){
        List<Booking__c> bookingListToUpdate = new List<Booking__c>();
        
        if(String.isNotBlank(enrolObj.Student__c) && String.isNotBlank(enrolObj.Teacher__c) && 
           Integer.valueOf(enrolObj.Package__r.Duration__c) > 0 && enrolObj.Lesson_Start_time__c != NULL && 
           enrolObj.Effective_Date__c != NULL && String.isNotBlank(enrolObj.Lesson_Day__c)){
               
               for(Booking__c bookingObj : processMakeupBooking(enrolObj.Student__c, enrolObj.Teacher__c,Integer.valueOf(enrolObj.Package__r.Duration__c), enrolObj.Lesson_Start_time__c, enrolObj.Effective_Date__c, enrolObj.Lesson_Day__c)){
                   
                   if(bookingObj.Type__c == ConstantsClass.busyBookingType && bookingObj.Category__c == ConstantsClass.bookingCategoryPlaceHolder){
                       bookingListToDelete.add(bookingObj);            
                   }else if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                       bookingListToUpdate.add(bookingObj);
                   }
                   
               }
               
               if(bookingListToDelete.size() > 0){
                   DELETE bookingListToDelete;
               }
               
               if(bookingListToUpdate.size() > 0){
                   cancelAllFutureMakeupBookings(bookingListToUpdate);  
               }
           }      
    }*/
    
    /*
* Fetch 5th Booking Lesson...
*/ 
    Private static List<Fifth_Lesson__c> fetchFifthLessonsBooking(String centreId, Set<String> teachersId, List<String> datesOfAppointment){
        String queryStr = 'SELECT Id, Booking_Date__c, Center__c, End_Time__c, Enrolment__c, Event_Color__c, Parent__r.Name, Start_Time__c, Student__r.Name, Teacher_Account__c FROM Fifth_Lesson__c WHERE IsActive__c = TRUE AND ';
        if(String.isNotBlank(centreId)){
            queryStr += ' Center__c =: centreId AND';
        }
        if(teachersId.size() > 0){
            queryStr += ' Teacher_Account__c IN: teachersId AND ';
        }
        if(datesOfAppointment.size() > 0){
            if(datesOfAppointment.size() == 1){
                Date dateOfEvent = Date.valueOf(datesOfAppointment[0]);
                queryStr += ' Booking_Date__c =: dateOfEvent AND start_Time__c != NULL AND End_Time__c != NULL';
            }else if(datesOfAppointment.size() == 2){
                Date startEventDate = Date.valueOf(datesOfAppointment[0]);
                Date endEventDate = Date.valueOf(datesOfAppointment[1]);
                queryStr += ' Booking_Date__c >= :startEventDate AND Booking_Date__c <= :endEventDate AND start_Time__c != NULL AND End_Time__c != NULL';
            }
        }
       //system.debug(queryStr);
        return Database.query(queryStr);
    }
    
    /*
*	Return Events For Fifth Booking Of Month
* 
*/
    Public static List<AureusCalendarController.Events> getFifthLessonEvents(String centreId, Set<String> teachersId, List<String> datesOfAppointment){
        AureusCalendarController.Events currentEvent; 
        List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
        for(Fifth_Lesson__c fifthLesson : fetchFifthLessonsBooking(centreId, teachersId, datesOfAppointment)){
            String eventTitle = '';
            
            if(String.isNotBlank(fifthLesson.Student__r.Name)){
                eventTitle += fifthLesson.Student__r.Name;
            }else{
                eventTitle += '';
            }
            
            if(String.isNotBlank(fifthLesson.Parent__r.Name)){
                eventTitle +=  ' - ' +fifthLesson.Parent__r.Name;    
            }else{
                eventTitle += '';
            }
            
            
            currentEvent = new AureusCalendarController.Events();
            currentEvent.id = fifthLesson.Id;
            
            
            currentEvent.title = eventTitle ;
            //currentEvent.overlap = false;
            if(String.isNotBlank(fifthLesson.Teacher_Account__c)){
                currentEvent.resourceId = fifthLesson.Teacher_Account__c;
            }
            
            currentEvent.start = String.valueOf(fifthLesson.Booking_Date__c)+'T'+String.valueOf(fifthLesson.start_Time__c).split('\\.')[0];
            currentEvent.end_c = String.valueOf(fifthLesson.Booking_Date__c)+'T'+String.valueOf(fifthLesson.End_Time__c).split('\\.')[0];
            currentEvent.eventColor = fifthLesson.Event_Color__c;
            currentEvent.className = 'fifthClass';
            currentEvent.Type = 'FifthLesson';
            /*if(countOfBookings.containsKey(fifthLesson.Id)){
                currentEvent.Notes = String.valueOf(countOfBookings.get(book.Id));
            }*/
            currentEvent.eventTextColor = ConstantsClass.eventTextColor;
            currentEvent.parentId = String.valueOf(fifthLesson.Parent__c);
            //currentEvent.Individual = String.valueOf(book.Individual_Booking__c);
            eventsList.add(currentEvent);
            
        }
        return eventsList;
    }

    /*
    *   This Method Will Fetch the desired the Fifth Lesson
    */

    Public static List<Fifth_Lesson__c> fetchFifthLessson(Set<String> fifthLesson){
        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        if(fifthLesson.size() > 0){
            fifthLessons = [SELECT Id, Name, Booking_Date__c, Booking_Day__c, Center__r.Name, Duration__c,
                            End_Time__c, Enrolment__c, Event_Color__c, Package__r.Name, Parent__r.FirstName, Parent__r.LastName, Parent__r.Stripe_Customer_Id__c, 
                            Parent__r.PersonMobilePhone, Parent__r.PersonEmail, Parent__r.Available_Make_up_Units__c,
                            Enrolment__r.package__r.Program__r.Instrument__c,Enrolment__r.package__r.Grade_new__c, //added by nishi: for ossia center we get adhoc packages accoding to enrolment grade and instrument
                            //Start: added by nishi: 31-Jul-2020: if enrolment Lesson mode is Is center ther we added resource Id
                            Enrolment__r.Lesson_Mode__c,  Enrolment__r.Resource__c,Center__r.Organisation__r.Name,Enrolment__r.Available_Make_up_mins__c,
                            Enrolment__r.Center__r.Organisation__r.Tax_Rate__c,  Enrolment__r.Center__r.Organisation__r.Country__r.Currency_Code__c, 
                            Enrolment__r.Center__r.Organisation__r.Stripe_Base_Url__c, Enrolment__r.Center__r.Organisation__r.Stripe_Secret_Key__c ,
                            //end: added by nishi: 31-Jul-2020: if enrolment Lesson mode is Is center ther we added resource Id
                            Start_Time__c, Student__r.FirstName, Student__r.LastName, Teacher_Account__r.FirstName,
                            Teacher_Account__r.LastName, IsActive__c, Enrolment__r.center__c,  Enrolment__r.Package__r.Duration__c, 
                            Enrolment__r.Center__r.Country__r.Tax_Rate__c,  Enrolment__r.Center__r.Country__r.Currency_Code__c, 
                            Enrolment__r.Center__r.Country__r.Stripe_Base_Url__c, Enrolment__r.Center__r.Country__r.Stripe_Secret_Key__c 
                            FROM Fifth_Lesson__c WHERE Id IN:fifthLesson];
        }
        return fifthLessons;
    }


   /*
     *This Method will Clone the FifthLesson To Placeholder Booking
    */

    Public static List<Booking__c> createBookingFromFifthLesson(List<Fifth_Lesson__c> fifthLessons, String type){
        
        String lessonRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        List<Booking__c> bookList = new List<Booking__c>();  
        Booking__c bookObj;

        Map<String, Id> mapOfMakeup = AureusUtility.getPackageMap();

        Set<String> centerIds = new Set<String>();
        Set<String> durations = new Set<String>();

        for(Fifth_Lesson__c fifthLesson : fifthLessons){
            centerIds.add(fifthLesson.center__c);
            durations.add(String.valueOf(Integer.valueOf(fifthLesson.duration__c)));
        }

        Map<String, Package__c> mapOfAdhoc = new  Map<String, Package__c> ();
        mapOfAdhoc = AureusUtility.getAdhocPackages(centerIds, durations);
        for(Fifth_Lesson__c fifthLesson : fifthLessons){
            bookObj = new Booking__c();
            bookObj.Booking_Date__c = fifthLesson.Booking_Date__c;
            bookObj.recordTypeId = lessonRecordType;
            bookObj.Center__c = fifthLesson.Center__c;
            bookObj.End_Time__c = fifthLesson.End_Time__c;
            //Start:added by nishi: if fifth lesson convert Makeup booking and this center is ossia then we manage Enrolment Id
            if(String.isNotBlank(fifthLesson.Center__c) && 
            String.isNotBlank(fifthLesson.Center__r.Organisation__c) && 
            String.isNotBlank(fifthLesson.Center__r.Organisation__r.Name) && 
            fifthLesson.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                bookObj.Enrolment__c = fifthLesson.Enrolment__c;
            }
            //End:added by nishi: if fifth lesson convert Makeup booking and this center is ossia then we manage Enrolment Id

            //Start: added by nishi: 31-Jul-2020: if enrolment Lesson mode is Is center ther we added resource Id
             //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
            /*if( string.isnotBlank(fifthLesson.Enrolment__r.Resource__c)){
                bookObj.Resource__c = fifthLesson.Enrolment__r.Resource__c;
            }else{
                List<String> weekDay =  new List<String>(); 
                weekDay.add(DateTime.newInstance(fifthLesson.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('EEE'));     
                AureusCalendarController.TeacherWorkingHours teachersHours = AureusCalendarControllerHelper.getTeacherWorkingHours(fifthLesson.Center__c,fifthLesson.Teacher_Account__c, weekDay );   
                
                if(teachersHours.setOfTeachers.size() > 0 && teachersHours.teachersHours.size() > 0){      
                    for(Teacher_Working_Hour__c th : teachersHours.teachersHours){     
                        if(teachersHours.setOfTeachers.contains(th.Teacher_Name__c)){      
                            bookObj.Resource__c  = th.Resource__c;
                        }      
                    }      
                }   
            }*/
             //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
            
            //End: added by nishi: 31-Jul-2020: if enrolment Lesson mode is Is center ther we added resource Id
           
            bookObj.Package__c = fifthLesson.Package__c;
            bookObj.Parent__c = fifthLesson.Parent__c;
            bookObj.Start_Time__c = fifthLesson.Start_Time__c;
            bookObj.Student__c = fifthLesson.Student__c;
            bookObj.Teacher_Account__c = fifthLesson.Teacher_Account__c;

            if(type == 'placeholder'){
                bookObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
                bookObj.Type__c = ConstantsClass.busyBookingType;    
                bookObj.Status__c = ConstantsClass.scheduledStatus;
                bookObj.remarks__c = 'Placeholder booking for Replacing the Fifth Lesson '+ fifthLesson.Student__r.FirstName + ' ' + fifthLesson.Student__r.LastName + ' booking';
            }else if(type == 'makeup'){
                bookObj.Type__c = ConstantsClass.typeMakeup;    
                bookObj.Status__c = ConstantsClass.scheduledStatus;
                bookObj.Package__c = (mapOfMakeup.containsKey(fifthLesson.duration__c + '-' + fifthLesson.Center__r.Name)) ? mapOfMakeup.get(fifthLesson.duration__c + '-' + fifthLesson.Center__r.Name) : NULL;
                
            }else if(type == 'adhoc'){
                bookObj.Type__c = ConstantsClass.typeAdhoc;    
                bookObj.Status__c = ConstantsClass.scheduledStatus;
                bookObj.Package__c = (mapOfAdhoc.containsKey(fifthLesson.Center__c+'-'+fifthLesson.Duration__c)) ? mapOfAdhoc.get(fifthLesson.Center__c+'-'+fifthLesson.Duration__c).Id : NULL;
            }
            
            bookList.add(bookObj);
        }
        return bookList;
    }
    
    /*
    * This Method will Process the Future Fifth Lessons 
    */
    public static void processFutureFifthLessons(Enrolment__c enrolObj, String type){
        Integer timeDuration = 0;
        List<Fifth_Lesson__c> fifthLessonList = new List<Fifth_Lesson__c>();
        for(Fifth_Lesson__c fifthLesson : [SELECT Id, Start_Time__c, end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                  Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                  Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c  
                                  FROM Fifth_Lesson__c WHERE Enrolment__c =: enrolObj.Id AND Booking_Date__c >=:enrolObj.effective_Date__c]){
                                      
                                      
                                      if(fifthLesson.Enrolment__r.Next_Lesson_Start_time__c != NULL && (type == 'downgrade' || type == 'upgrade' || type == 'change')){                                         
                                          fifthLesson.start_time__c = fifthLesson.Enrolment__r.Next_Lesson_Start_time__c;
                                      }else if(fifthLesson.Enrolment__r.Lesson_Start_time__c != NULL){
                                          fifthLesson.start_time__c = fifthLesson.Enrolment__r.Lesson_Start_time__c;
                                      }
                                      
                                      
                                      if(String.isNotBlank(fifthLesson.Enrolment__r.new_package_Id__r.Duration__c) && String.isNotBlank(fifthLesson.package__r.Duration__c)){
                                          timeDuration =  Integer.valueOf(fifthLesson.Enrolment__r.new_package_Id__r.Duration__c) - Integer.valueOf(fifthLesson.package__r.Duration__c);                      
                                      }

                                      if(String.isNotBlank(fifthLesson.Enrolment__r.New_Teacher__c)){
                                          fifthLesson.teacher_Account__c = fifthLesson.Enrolment__r.New_Teacher__c;
                                      }

                                      if(String.isNotBlank(fifthLesson.Enrolment__r.new_package_Id__c)){
                                          fifthLesson.package__c = fifthLesson.Enrolment__r.new_package_Id__c; 
                                      }

                                      if(String.isNotBlank(fifthLesson.Enrolment__r.new_package_Id__c)){
                                          fifthLesson.end_time__c = fifthLesson.start_Time__c.addMinutes(Integer.valueOf(fifthLesson.Enrolment__r.new_package_Id__r.Duration__c));
                                      }else{
                                          fifthLesson.end_time__c = fifthLesson.start_Time__c.addMinutes(Integer.valueof(fifthLesson.package__r.Duration__c));
                                      }
                                      
                                      fifthLessonList.add(fifthLesson);
                                  }
        if(fifthLessonList.size() >0){
            UPSERT fifthLessonList;
        }
    }
}