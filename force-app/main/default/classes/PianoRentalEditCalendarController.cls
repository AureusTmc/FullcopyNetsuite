/**
 * Name: PianoRentalEditCalendarController
 * author: JAtin
 * Date: 21-Jan-2020
 * Desciption : for show Employee calendar
 * 
 */
public with sharing class PianoRentalEditCalendarController{
    
    //jatin: 20 Jan-2020: for  get Employee list according to center , effectivedate and employee id
    public static List<Account> getListOfEmployee(String centerId,Set<String> employeeIds){
       List<Account> accList = new List<Account>();
       Set<String>  employeeWorkingStatus = new Set<String>{ConstantsClass.employeeConfirmStatus,ConstantsClass.employeeProbationStatus};
       String employeeRecType = ConstantsClass.employeeRecTypeName;
       string job_title = ConstantsClass.employeeJobTitle;
       Set<String> employeeIdSet = new Set<String>();
       if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            string query = 'SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId ';
           if(employeeIds != null && employeeIds.size() > 0){
               query +=' AND Teacher_Name__c in: employeeIds ';
           }
          //System.debug('@@@getListOfEmployee'+query);
            teacherWorkingHourList = Database.query(query);
            if(teacherWorkingHourList != null && teacherWorkingHourList.size() > 0)
               for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                   employeeIdSet.add(twh.Teacher_Name__c);
               }
       }
       
       String query = '';             
       if(employeeIdSet.size() > 0){
           query = 'SELECT Id, Name FROM Account WHERE RecordType.Name =: employeeRecType AND Employee_Status__c in: employeeWorkingStatus AND Job_Title__c =: job_title ';
           query+= ' AND id IN : employeeIdSet';
           query+= ' ORDER BY Name';
       }
       if(String.isNotBlank(query))
           accList = Database.query(query);
       
       return accList;
   }

   //Jatin: 20-jan-2020 : get Calandar according to employee id 
   @RemoteAction
   public static String getCalendarAllEmployeeData(String centerId, String employeeId, List<String> datesOfAppointment){
       String max;
       String min;
       List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
       List<AureusCalendarController.Events> validationBusinessHours = new List<AureusCalendarController.Events>();
       List<String> weekDays = new List<String>();
       Map<String, String> mapOfweekDays = new Map<String, String>();
       List<Center_Working_Hours__c> centerWorkingHours = new List<Center_Working_Hours__c>();
       AureusCalendarController.TeacherWorkingHours workingHoursOfEmployee = new AureusCalendarController.TeacherWorkingHours();
       AureusCalendarController.ResourceWorkingHours workingHoursOfResource = new AureusCalendarController.ResourceWorkingHours();
       List<Account> listOfAcc = new List<Account>();
       List<Resource__c> listOfResource = new List<Resource__c>();
       List<AureusCalendarController.Resources> listOfResources = new List<AureusCalendarController.Resources>();
       List<AureusCalendarController.Resources> listOfEmployeeFilter = new List<AureusCalendarController.Resources>();
       AureusCalendarController.EmployeeCalendar objCalendar = new AureusCalendarController.EmployeeCalendar();
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
       if((weekDays.size() > 0 && String.isNotBlank(centerId)) || String.isNotBlank(EmployeeId)){
           
           centerWorkingHours  = AureusCalendarControllerHelper.getCenterWorkingHours(centerId, weekDays);
           
           //get the min time and max time of center from the helper controller
           if(centerWorkingHours.size() > 0){
               min = AureusCalendarControllerHelper.getMinTime(centerWorkingHours);
               max = AureusCalendarControllerHelper.getMaxTime(centerWorkingHours);
           }
       }
       
       //get the Employee, Employee working hours and Employee business hours of selected Employee from the calendar
       if(String.isNotBlank(employeeId)){
           Set<String> teach = new Set<String>();
           Set<String> resourceIds = new Set<String>();
           
           //get Employee working hours from the helper controller
           workingHoursOfEmployee  = getEmployeeWorkingHours(centerId, employeeId, weekDays);
          //system.debug('@@@workingHoursOfEmployee'+workingHoursOfEmployee);
           //System.debug('workingHoursOfTeacher'+workingHoursOfTeacher);
           //get events of Employee working hours for validating the calendar from helper controller
           validationBusinessHours.addAll(AureusCalendarControllerHelper.getWorkingHoursTeachers(workingHoursOfEmployee, employeeId, mapOfweekDays));
          //system.debug('@@@validationBusinessHours'+validationBusinessHours);
           //get events of Employee working hours for validating the calendar from helper controller
           businessHours = AureusCalendarControllerHelper.getTeachersWorkingHours(workingHoursOfEmployee, employeeId, mapOfweekDays);

          //system.debug('@@@businessHours'+businessHours);
           if(String.isNotBlank(centerId)){
               List<Account> filtersList = getListOfEmployee(centerId,new set<string>());
               if(filtersList.size() > 0){
                   for(Account objAcc : filtersList){
                       AureusCalendarController.Resources objResource = new AureusCalendarController.Resources();
                       objResource.id = objAcc.id;
                       objResource.title = objAcc.name;
                       
                       listOfEmployeeFilter.add(objResource);
                   }
               }
           }
           
           if(employeeId != 'AllStaff' && employeeId != 'AllRosteredStaff'){
               teach.add(employeeId);
               
               //get Events list of teacher/resource on perticular date or perticular range
               List<AureusCalendarController.Events> bookingLst = getEventsListOfEmployeeBooking(teach, centerId, datesOfAppointment);
               
               eventsList.addAll(bookingLst);

               //Get List of teacher on selected center
               listOfAcc = getListOfEmployee(centerId, new set<string>{employeeId});
               
               if(listOfAcc.size() > 0){
                   for(Account objAcc : listOfAcc){
                       listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                  
                   }
               }
           }else if(employeeId != 'AllRosteredStaff' && employeeId == 'AllStaff'){
               teach.addAll(workingHoursOfEmployee.setOfTeachers);
               
               //get Events list of employee/resource on perticular date or perticular range
               List<AureusCalendarController.Events> bookingLst = AureusCalendarControllerHelper.getEventsListOfBooking(teach, resourceIds, centerId, datesOfAppointment, /*instrument*/'');
               eventsList.addAll(bookingLst);
               
               //Get List of employee on selected center
               listOfAcc = getListOfEmployee(centerId,new set<string>());
               
               if(listOfAcc.size() > 0){
                   for(Account objAcc : listOfAcc){
                       listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                  
                   }
               }
           }else if(employeeId == 'AllRosteredStaff' && employeeId != 'AllStaff'){
               teach.addAll(workingHoursOfemployee.setOfTeachers);
               //get Events list of teacher/resource on perticular date or perticular range
               List<AureusCalendarController.Events> bookingLst = getEventsListOfEmployeeBooking(teach,centerId, datesOfAppointment);
               eventsList.addAll(bookingLst);
               
               if(String.isNotBlank(centerId) && teach.size() > 0){
                   //Get List of employee on selected center and teacher
                   listOfAcc = getListOfEmployee(centerId, teach);
               }
               
               if(listOfAcc.size() > 0){
                   for(Account objAcc : listOfAcc){
                       listOfResources.add(AureusCalendarControllerHelper.addResources(objAcc.id,objAcc.Name,businessHours));
                   }
               }
           }
       }
      //system.debug('@@@listOfResources'+listOfResources);
        objCalendar.listOfResources = listOfResources;
       objCalendar.listOfEvents = eventsList;
       objCalendar.employeeWorkingHours = new List<AureusCalendarController.Events>();
       objCalendar.listOfEmployeFilters = new List<AureusCalendarController.Resources>();
       objCalendar.listOfEmployeFilters = listOfEmployeeFilter;
       objCalendar.employeeWorkingHours = validationBusinessHours;
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


    /* 21-Jan-2020 
getEmployeeWorkingHours methods takes the following arguments

1. center Id
2. employeeId Id
3. List of weekdays

this method returns the employee working hours according to selected center, employee and date from the calendar UI.

*/
   
   public static AureusCalendarController.TeacherWorkingHours getEmployeeWorkingHours(String centerId, String employeeId, List<String> weekDays){
        Set<String>  employeeWorkingStatus = new Set<String>{ConstantsClass.employeeConfirmStatus,ConstantsClass.employeeProbationStatus};
       
       Map<String, integer> MapOfWeek = new Map<String, integer>{'Mon' => 2, 'Tue' => 3, 'Wed' => 4, 'Thu' => 5, 'Fri' => 6, 'Sat' => 7, 'Sun' => 1};
           AureusCalendarController.TeacherWorkingHours teacherHours = new AureusCalendarController.TeacherWorkingHours();
       String teacherWorkingHoursQuery = 'SELECT Id, Name, Teacher_Name__c, Teacher_Name__r.Name, Teacher_Name__r.Employee_Status__c , Center_Name__c, Active__c, Working_Day__c, Start_Time__c, End_Time__c, Break_Time__c FROM Teacher_Working_Hour__c';
       
       //teacher working hours should be active and it should not be break hour and its start time and end time should not be null
       if(String.isNotBlank(centerId) || weekDays.size() > 0){
           teacherWorkingHoursQuery += ' WHERE Active__c = true AND Break_Time__c = false AND Start_Time__c != NULL AND End_Time__c != NULL AND Teacher_Name__r.Employee_Status__c in: employeeWorkingStatus AND ';
       }
       
       //Belongs to a perticular center
       if(String.isNotBlank(centerId)){
           teacherWorkingHoursQuery += ' Center_Name__r.Id =: centerId';
       }
       
       //belongs to perticular teacher
       if(employeeId != 'AllRosteredStaff' && employeeId != 'AllStaff'){
           teacherWorkingHoursQuery += ' AND Teacher_Name__c =: employeeId';
       } 
      //system.debug('weekDays'+weekDays);
       if(weekDays.size() == 1){
           String weekDay = weekDays[0];
          //system.debug('weekDay'+weekDay);
           teacherWorkingHoursQuery += ' AND Working_Day__c =: weekDay ';
       }else if(weekDays.size() == 2){
           
           List<integer> weekList = new List<integer>(); 
          //system.debug('weekDays'+weekDays);
           for(String current : weekDays){
               if(MapOfWeek.containsKey(current)){
                   weekList.add(MapOfWeek.get(current));
               }
           }
           if(weekList.size() >= 2){
              //system.debug('weekList'+weekList);
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
       if(String.isNotBlank(employeeId) && employeeId != 'AllRosteredStaff' && employeeId != 'AllStaff'){
           teacherHours.setOfTeachers = new Set<String>();
           teacherHours.setOfTeachers.add(employeeId);
       }
      //system.debug('@@@teacherHours'+teacherHours);
       return teacherHours;
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
   

   public static List<AureusCalendarController.Events> getEventsListOfEmployeeBooking(Set<String> setOfEmployeeId, String centerId, List<String> datesOfAppointments){
       
       String lessonRecordtype = ConstantsClass.recordTypeLesson;
       String facilityRecordtype = ConstantsClass.recordTypeFacility ;
       String statusCanceled = ConstantsClass.statusCanceled;
       string classLessonBookingType = ConstantsClass.trialStatus;
       List<AureusCalendarController.Events> eventsList = new List<AureusCalendarController.Events>();
       Map<String, Integer> countOfBookings = new Map<String, Integer>();
       AureusCalendarController.Events currentEvent = new AureusCalendarController.Events();
       Set<String> bookingTypes = new Set<String>{ConstantsClass.trialStatus,ConstantsClass.typePianoViewing};
       //Create Dynamic Query According to the parameters got from the calendar UI.
       //String eventsQuery = 'SELECT Id, Name, Category__c, Teacher_Account__r.Name, start_Time__c, Event_Color__c, End_Time__c, status__c, type__c, Student__r.Name, RecordTypeId, Student__r.Parent__r.Name, Center_Id__c, Booking_Date__c, Instrument__c, Resource__c, Resource__r.Name, Individual_Booking__c, Remarks__c FROM Booking__c';
       // Start:Nishi:27-Jul-2020: for manage same query field for teacher and employe Booking object
       string bookingfields =AureusCalendarControllerHelper.BookingObjectQueryFields(classLessonBookingType);
        String eventsQuery = 'SELECT '+bookingfields+' FROM Booking__c';
        // Start:Nishi:27-Jul-2020: for manage same query field for teacher and employe Booking object
       if(String.isNotBlank(centerId)){
           eventsQuery += '  WHERE (Center_Id__c =: centerId OR Center__c =: centerId)';
           if(setOfEmployeeId!= null && setOfEmployeeId.size() > 0){
               eventsQuery += ' AND (RecordType.Name =: lessonRecordtype) AND Teacher_Account__c IN :setOfEmployeeId';
               eventsQuery += ' AND (  Type__c In: bookingTypes AND status__c !=: statusCanceled)';
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
       Set<String> setOfBookings = new Set<String>();
       List<Booking__c> bookingList = new List<Booking__c>();
       
       if(String.isNotBlank(eventsQuery)){
           for(Booking__c book: Database.query(eventsQuery)){
               bookingList.add(book);
               setOfBookings.add(book.Id);
           }
       }
       
       return AureusCalendarControllerHelper.getEventsListOfBookingOrEmployees(setOfBookings,bookingList,centerId,setOfEmployeeId,datesOfAppointments,false,false);
   }
  

}