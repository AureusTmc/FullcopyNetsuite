/*
Name        :    AureusUtility
Date        :    29th May 2019 
Description :    This class is used for common methods to use.
Author      :    Arpit vijayvergiya  
*/
public class AureusUtility{
    public static Map<String,OrgWideEmailAddress> mapOfOrgWide;
/*
    @Param
    templateId : template to be used.
    whatId :  contact Id
    relatedId : id of record which information to be populated
    location : center.location to populate dynamic orgwideaddress.

*/
    public static Messaging.SingleEmailMessage getSingleEmailMessage(String templateId,String whatId,String relatedId,String location){
        fillOrgWideAddressMap();
        
        System.debug('###templateId'+templateId);
        System.debug('###whatId'+whatId);
        System.debug('###whatId'+relatedId);
        System.debug('###relatedId'+relatedId);
         System.debug('###location'+location);
        Messaging.SingleEmailMessage mail = new  Messaging.SingleEmailMessage();  //Messaging.renderStoredEmailTemplate(templateId, whatId, relatedId);
        mail.setTemplateId(templateId);
        mail.setWhatId(relatedId);
        mail.setTargetObjectId(whatId);
        mail.saveAsActivity = true;
        if(String.isNotBlank(location) && mapOfOrgWide.containsKey(location)){
            mail.setOrgWideEmailAddressId(mapOfOrgWide.get(location).Id);
        }
        return mail;
    }
    public static void fillOrgWideAddressMap(){
        if(mapOfOrgWide == NULL){
            mapOfOrgWide  = new Map<String,OrgWideEmailAddress>();
            for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
                mapOfOrgWide.put(objAddress.DisplayName,objAddress);
            }
        }
    }
    
    //@Arpit 08August19 This method is used for getting email template id
    public static String getEmailTemplateId(String templateName){
        String templateId;
        if(String.isNotBlank(templateName)){
            List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: templateName];
            if(!emailTemplates.isEmpty()){
                templateId = emailTemplates[0].Id;
            }
        }
        return templateId;
    }
    
    /* Performs Two Task:
1. change status of current Month Bookings
2. 5th weekday booking of month, if weekday occur
*/
    public static void preInvoiceJobOnEnrolment(List<Enrolment__c> enrolmentList){
        Map<String, Enrolment__c> enrolmentMap = new Map<String, Enrolment__c>();
        
        //Fill the set of Enrolments and map of enrolment
        for(Enrolment__c enrol : enrolmentList){
                enrolmentMap.put(enrol.Id, enrol);
        }
        
        if(enrolmentMap.keySet().size() > 0){
            changeCurrentMonthBookingStatus(enrolmentMap.keySet());
        }
        
        if(enrolmentList.size() > 0){
            createFifthBookingOfMonth(enrolmentMap.values());
        }
    } 
    
    /* Performs Two Task:
1. Perform Advance Actions like:
A. Upgrade Enrolment
B. Downgrade Enrolment
C. Withdrawal of Enrolment
D. Change of Enrolment
2. creating 13th Month Bookings
*/
    public static void postInvoiceJobOnEnrolment(List<Enrolment__c> enrolmentList,date startingDate){
        
        Map<String, Enrolment__c> enrolmentMap = new Map<String, Enrolment__c>();
        Set<String> cancelledEnrolmentSet = new Set<String>();
        Map<String, Enrolment__c> groupEnrolmentMap = new Map<String, Enrolment__c>();
        Set<String> cancelledGroupEnrolmentSet = new Set<String>();
        
        Map<String, Enrolment__c> enrolmentRegularMap = new Map<String, Enrolment__c>();
         //Fill the map of Enrolments and map of enrolment
         List<Id> classIds = new List<Id>();
        for(Enrolment__c enrol : enrolmentList){
             enrolmentMap.put(enrol.Id, enrol); 
             if(enrol.type__c == ConstantsClass.enrolGroupType){
                groupEnrolmentMap.put(enrol.Id, enrol);
                if(string.isNotBlank(enrol.Class__c)){
                        classIds.add(enrol.Class__c); 
                }
             }else{
                enrolmentRegularMap.put(enrol.Id, enrol);     
             }
            
        }
        // commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
        //list<Enrolment__c> listOfUpdatedEnrolment = enrolmentAdvanceAction(enrolmentMap);

        list<Enrolment__c> listOfUpdatedEnrolment = enrolmentAdvanceAction(enrolmentMap,startingDate);
        // @@jatin: 9-jan-2020: for manage Group lesson and regular bookings
        if(listOfUpdatedEnrolment.size() > 0){
            for(Enrolment__c enrolObj : listOfUpdatedEnrolment){
                if(groupEnrolmentMap.containsKey(enrolObj.Id) && enrolObj.Stage__c != ConstantsClass.enrollmentStageCancelled){
                    // @@jatin: 10-jan-2020if any enrolment upgrade group class to individual then me remove this groupmap and added in regular booking
                    if(enrolObj.type__c == ConstantsClass.enrolRegularStatus && groupEnrolmentMap.containsKey(enrolObj.Id)){
                        groupEnrolmentMap.remove(enrolObj.Id);
                        enrolmentRegularMap.put(enrolObj.Id, enrolObj);
                    }else{
                        groupEnrolmentMap.put(enrolObj.Id, enrolObj);
                        if(string.isNotBlank(enrolObj.Class__c)){
                            classIds.add(enrolObj.Class__c); 
                        }
                    }
                }else if(groupEnrolmentMap.containsKey(enrolObj.Id) && enrolObj.Stage__c == ConstantsClass.enrollmentStageCancelled){
                        cancelledGroupEnrolmentSet.add(enrolObj.Id);
                }
            }
        }
        system.debug('!!groupEnrolmentMap'+groupEnrolmentMap);
        system.debug('!!enrolmentRegularMap'+enrolmentRegularMap);
        system.debug('!!cancelledGroupEnrolmentSet'+cancelledGroupEnrolmentSet);
        ///listOfUpdatedEnrolment = enrolmentAdvanceAction(enrolmentRegularMap);
        if(listOfUpdatedEnrolment.size() > 0){
            for(Enrolment__c enrolObj : listOfUpdatedEnrolment){
                if(enrolmentRegularMap.containsKey(enrolObj.Id) && enrolObj.Stage__c != ConstantsClass.enrollmentStageCancelled){
                    enrolmentRegularMap.put(enrolObj.Id, enrolObj);
                    
                }else if(enrolmentRegularMap.containsKey(enrolObj.Id) && enrolObj.Stage__c == ConstantsClass.enrollmentStageCancelled){
                    cancelledEnrolmentSet.add(enrolObj.Id);
                }   
            }
        }
        system.debug('!!groupEnrolmentMap'+groupEnrolmentMap);
        system.debug('!!enrolmentRegularMap'+enrolmentRegularMap);
        Date current = startingDate.addMonths(13);
        Date firstDate = Date.newInstance(current.year(),current.month(),01);
        Date lastDate = Date.newInstance(current.year(),current.month(),Date.daysInMonth(current.month(),current.year()));
         // nishi: 6-Oct-2020: for get all enrolment ids if 13 month booking exist
        Set<string> existing13MonthBookingEnrolmentIds = getexisting13MonthBookingEnrolmentIds(enrolmentMap,firstDate,lastDate);
        if(enrolmentRegularMap != null && enrolmentRegularMap.size() > 0 ){
             // commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
             //createBookingFor13Month(enrolmentRegularMap.values(), cancelledEnrolmentSet);
           createBookingFor13Month(enrolmentRegularMap.values(), cancelledEnrolmentSet,startingDate,existing13MonthBookingEnrolmentIds);
        }
        if(groupEnrolmentMap!= null && groupEnrolmentMap.size() > 0 ){
            //@@jatin: 9-jan-2020 Create 4 group lesson bookings of per enrolment for 13 month
            // commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
            //createGroupLessonBookingFor13Month(groupEnrolmentMap.values(), cancelledGroupEnrolmentSet,getmapOfEffectiveDateGroupLesson(classIds));
            createGroupLessonBookingFor13Month(groupEnrolmentMap.values(), cancelledGroupEnrolmentSet,getmapOfEffectiveDateGroupLesson(classIds,startingDate),existing13MonthBookingEnrolmentIds);
        }
    }     
    // /@@jatin: 9-jan-2020  get date and group lesson of 13th months according to classIds  
    private  static Map<String,Map<Date,String>> getmapOfEffectiveDateGroupLesson(List<Id> classIds,Date startingDate){
        Map<String,Map<Date,String>> mapOfClassDates = New  Map<String,Map<Date,String>>();
        Map<Date,String> mapOfDateGroupLesson = New  Map<Date,String>();
       // Date current = System.today().addMonths(13); // commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
        Date current = startingDate.addMonths(13);
        Date firstDate = Date.newInstance(current.year(),current.month(),01);
        Date lastDate = Date.newInstance(current.year(),current.month(),Date.daysInMonth(current.month(),current.year()));
        system.debug('firstDate'+firstDate);
        system.debug('lastDate'+lastDate);
        for(Booking__c objBook : [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                  Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                  Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c ,
                                  Class__c
                                  FROM Booking__c 
                                  WHERE Type__c = :ConstantsClass.groupTypeBooking
                                  AND Status__c != :ConstantsClass.statusCanceled
                                  AND Booking_Date__c >=: firstDate
                                  AND Booking_Date__c <=: lastDate
                                  AND Class__c IN: classIds]){
                                        mapOfDateGroupLesson = mapOfClassDates.containsKey(objBook.Class__c) ?
                                                               mapOfClassDates.get(objBook.Class__c):
                                                                New Map<Date,String>();
                                        mapOfDateGroupLesson.put(objBook.Booking_Date__c ,objBook.id);
                                        mapOfClassDates.put(objBook.Class__c,mapOfDateGroupLesson);
                                  }
        system.debug('mapOfClassDates'+mapOfClassDates);
        mapOfClassDates = check13MonthGroupLessonExistOrNot(classIds,firstDate,lastDate,mapOfClassDates);  
        system.debug('mapOfClassDates'+mapOfClassDates);  
        return mapOfClassDates;
    }
    
     // added by nishi: 9-Sep-2020: for if group lesson instance creates.
        //we firslty check the group lesson booking is already created or not is group lesson booking not found then we are  creating new group lesson instance. 
    private static Map<String,Map<Date,String>> check13MonthGroupLessonExistOrNot(List<Id> classIds,Date firstDate,Date lastDate,Map<String,Map<Date,String>> mapOfClassDates){
        if(classIds != null && classIds.size() > 0){
            if(mapOfClassDates != null && mapOfClassDates.size() > 0 ){
                List<Id> newClassIds = new List<Id>();
                for(string classId : classIds){
                    if(!mapOfClassDates.containsKey(classId)){
                        newClassIds.add(classId);
                    }
                }
                system.debug('newClassIds'+newClassIds);
                if(newClassIds != null && newClassIds.size()>0 ){
                    mapOfClassDates = createGroupClassInstance(newClassIds,firstDate,lastDate,mapOfClassDates);    
                }
            }else{
                system.debug('classIds'+classIds);
                mapOfClassDates = createGroupClassInstance(classIds,firstDate,lastDate,mapOfClassDates);    
            }
        }
        return mapOfClassDates;
    }

     // added by nishi: 9-Sep-2020: for we creating group lesson instance  
    private static  Map<String,Map<Date,String>> createGroupClassInstance(List<Id> classIds,Date firstDate,Date lastDate,Map<String,Map<Date,String>> mapOfClassDates){
        Map<Date,String> mapOfDateGroupLesson = New  Map<Date,String>();
        List<Booking__c> bookingListForClass = new List<Booking__c>();
        
        if(classIds != null && classIds.size() > 0){
            for(Class__c objClass :[SELECT Id,name, Centre_Name__c, Package_Fee__c, Program__c, Total_Capacity__c, Class_Type__c, Class_Start_Date__c, End_Time__c, Start_Time__c, Teacher__c,
                                        Package__c, Active__c, Total_Enrolment__c, Class_Date__c, Class_End_Date__c, Class_Day__c, Minimum_age__c, Maximum_age__c, Instrument__c, Available_Capacity__c 
                                        FROM Class__c 
                                        WHERE Active__c = true 
                                        AND Class_Start_Date__c <= THIS_MONTH 
                                        And (Class_End_Date__c = null OR Class_End_Date__c >=:lastDate)
                                        AND Id In: classIds]){
                if(objClass.Start_Time__c != null ){ 
                    system.debug('firstDate'+firstDate);    
                    system.debug('lastDate'+lastDate);    
                    DateTime startTime  = AureusUtility.getFirstWeekDayDate(objClass.Class_Day__c,firstDate.month(),firstDate.year());
                    DateTime endTime =objClass.Class_End_Date__c != null && objClass.Class_End_Date__c.month() == firstDate.month() ? 
                            DateTime.newInstance(objClass.Class_End_Date__c,objClass.Start_Time__c) :
                            DateTime.newInstance(Date.newInstance(lastDate.year(),lastDate.month(),Date.daysInMonth(lastDate.month(),lastDate.year())),objClass.Start_Time__c);
                    system.debug('startTime'+startTime);    
                    system.debug('endTime'+endTime);   
                    bookingListForClass.addAll(ClassTriggerHelper.createBookingsForClass(objClass,startTime,endTime));
                }
            }
            if(bookingListForClass.size() > 0){
                upsert   bookingListForClass;    
                system.debug('bookingListForClass'+bookingListForClass); 
                for(Booking__c objBook: bookingListForClass){
                    // 14-Sep-2020: for get only group class not busy (fifth lesson bookings)
                    if(objBook.Type__c == ConstantsClass.groupTypeBooking){
                        mapOfDateGroupLesson = mapOfClassDates.containsKey(objBook.Class__c) ?  mapOfClassDates.get(objBook.Class__c):New Map<Date,String>();
                        mapOfDateGroupLesson.put(objBook.Booking_Date__c ,objBook.id);
                        mapOfClassDates.put(objBook.Class__c,mapOfDateGroupLesson);
                    }
                }
                system.debug('mapOfClassDates'+mapOfClassDates); 
            }
        }
        return mapOfClassDates;
    }

    // @@jatin: get first week day date according to class start day
    public static date getFirstWeekDayDate(string dayOfWeekName, integer month, integer year){
         map<string,integer> dowMap = new map<string,integer>{'Mon'=>0, 'Tue'=>1, 'Wed'=>2,'Thu'=>3,'Fri'=>4,'Sat'=>5,'Sun'=>6};                                                           

        list<date> returnList = new list<date>();
        date d = date.newInstance(year,month,1);
        d=d.addDays(math.mod(7-dayOfWeek(d)+dowMap.get(dayOfWeekName),7));//brings you to the first instance of the specified dayOfWeekName of the month
        return d;
    }
    public static integer dayOfWeek(date d){
        return math.mod(date.newInstance(1900,1,8).daysBetween(d),7); 
    }


    //@@jatin: 9-jan-2020 Create 4 group lesson bookings of per enrolment for 13 month
    private static void createGroupLessonBookingFor13Month(List<Enrolment__c> enrolmentList, Set<String> cancelledBookingsSet,Map<String,Map<Date,String>> mapOfClassDates, Set<string> existing13MonthBookingEnrolmentIds){
        String groupLessonBookingRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
        
        List<Booking__c> listOfBookings = new List<Booking__c>();
        Map<String, Teacher_Working_Hour__c> mapOfHomeTeachersHours = fetchWorkingHoursHome();
        Teacher_Working_Hour__c workingHour = new Teacher_Working_Hour__c();
         Map<Date,String> mapOfDateGroupLesson = new  Map<Date,String>();
        Boolean isHome = FALSE;
        if(enrolmentList.size() > 0){
            for(Enrolment__c enrolmentObj : enrolmentList){
                 // nishi: 6-Oct-2020: for if any enrolment ids is exist in existing13MonthBookingEnrolmentIds this set 
                 //that a 13-month booking has already been created, so we do not want to make the 13th month booking again
                if(!existing13MonthBookingEnrolmentIds.contains(enrolmentObj.id)){
                    isHome = FALSE;
                    //Check that the enrolment is of Aureus home centre or not....
                    workingHour = new Teacher_Working_Hour__c();
                    if(enrolmentObj.Center__c == Label.Aureus_at_Home_Id && String.isNotBlank(enrolmentObj.Lesson_Day__c) && String.isNotBlank(enrolmentObj.Teacher__c)){
                        workingHour = (mapOfHomeTeachersHours.containsKey(enrolmentObj.Teacher__c + '-'+enrolmentObj.Lesson_Day__c.left(3)) ? mapOfHomeTeachersHours.get(enrolmentObj.Teacher__c + '-'+enrolmentObj.Lesson_Day__c.left(3)) : NULL);
                        isHome = TRUE;
                    }
                    //If the cancelledBookingsSet contains the enrolment Id then loop will skip the further process of creating regular bookings for that enrolment.
                    if(cancelledBookingsSet.contains(enrolmentObj.Id)){
                        continue;
                    }
                    
                    if(String.isNotBlank(enrolmentObj.Lesson_Day__c)){
                        mapOfDateGroupLesson = new  Map<Date,String>();
                        if(mapOfClassDates != null && mapOfClassDates.size() > 0 && mapOfClassDates.containsKey(enrolmentObj.class__c)){
                            mapOfDateGroupLesson = mapOfClassDates.get(enrolmentObj.class__c);
                        }
                        System.debug('enrolmentObj.class__c'+enrolmentObj.class__c);
                        System.debug('mapOfDateGroupLesson'+mapOfDateGroupLesson);
                        System.debug('enrolmentObj.Lesson_Day__c'+enrolmentObj.Lesson_Day__c);
                        if(mapOfDateGroupLesson != null && mapOfDateGroupLesson.size() > 0){
                            for(Date objDate : mapOfDateGroupLesson.keySet()){
                                
                                    if(mapOfDateGroupLesson.containsKey(objDate)){
                                        Booking__c objBooking = new Booking__c();
                                        objBooking.Student__c = enrolmentObj.Student__c;
                                        objBooking.Center__c = enrolmentObj.Center__c;
                                        objBooking.Teacher_Account__c = enrolmentObj.Teacher__c;
                                        objBooking.Booking_Date__c = objDate;
                                        objBooking.recordTypeId = groupLessonBookingRecordType;
                                        objBooking.parent__c = String.isNotBlank(enrolmentObj.parent__c) && enrolmentObj.parent__c !=null ? enrolmentObj.parent__c : null;
                                        objBooking.start_time__c = enrolmentObj.Lesson_Start_time__c;
                                        if(objBooking.start_time__c != NULL){
                                            objBooking.End_time__c = objBooking.start_time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));
                                        }
                                        objBooking.Enrolment__c = enrolmentObj.Id; 
                                        objBooking.Package__c = enrolmentObj.Package__c;
                                        objBooking.type__c = ConstantsClass.groupLessonTypeBooking;
                                        objBooking.Status__c = ConstantsClass.pendingStatus;
                                        objBooking.Group_Class__c = mapOfDateGroupLesson.get(objDate);
                                                    
                                        listOfBookings.add(objBooking);
                                    }
                                if(isHome && enrolmentObj.Lesson_Start_time__c != NULL &&
                                    String.isNotBlank(workingHour.Id) && 
                                    workingHour.start_Time__c < enrolmentObj.Lesson_Start_time__c){
                                    if(mapOfDateGroupLesson.containsKey(objDate)){
                                        Booking__c objBooking = new Booking__c();
                                        objBooking.Center__c = enrolmentObj.Center__c;
                                        objBooking.Teacher_Account__c = enrolmentObj.Teacher__c;
                                        objBooking.Booking_Date__c = objDate;
                                        objBooking.recordTypeId = groupLessonBookingRecordType;
                                        objBooking.End_time__c = enrolmentObj.Lesson_Start_time__c;
                                        if(objBooking.End_time__c != NULL){
                                            objBooking.start_time__c = objBooking.End_time__c.addMinutes(-30);
                                        }
                                        objBooking.Enrolment__c = enrolmentObj.Id; 
                                        objBooking.type__c = ConstantsClass.typeBusy;
                                        objBooking.Status__c = ConstantsClass.statusScheduled;
                                        objBooking.Category__c = ConstantsClass.categoryTravel;
                                        objBooking.Remarks__c = 'Travel';
                                        objBooking.Group_Class__c = mapOfDateGroupLesson.get(objDate);
                                        listOfBookings.add(objBooking);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            system.debug('listOfBookings'+listOfBookings);
            if(listOfBookings.size() > 0){
                insert listOfBookings;
            }
        }
    }

    //Change the status of Current Month From pending to Scheduled
    private static void changeCurrentMonthBookingStatus(Set<String> setOfEnrolment){
        List<Booking__c> listOfBookings = new List<Booking__c>();
        Set<String> bookingTypes = new Set<String>{ConstantsClass.typeRegular,ConstantsClass.groupLessonTypeBooking};
        for(Booking__c objBooking : [SELECT Id, Status__c 
                                        FROM Booking__c
                                        WHERE Enrolment__c IN :setOfEnrolment AND
                                        Status__c = :ConstantsClass.pendingStatus
                                        AND Booking_Date__c = THIS_MONTH 
                                        And Type__c IN: bookingTypes]){
                                        ////Commented by jatin: 9-jan-2020 : For manage regular and grouplesson type Bookings
                                        //Type__c =: ConstantsClass.typeRegular
                                         objBooking.Status__c = ConstantsClass.statusScheduled;
                                         listOfBookings.add(objBooking);
                                     }
        system.debug('listOfBookings'+listOfBookings);
        if(listOfBookings.size() > 0){
            update listOfBookings;
        }
    }
    
    //Create Fifth Booking of the month for perticular enrolments
    private static void createFifthBookingOfMonth(List<Enrolment__c> enrolmentList){
        
        Date current = System.today();
        Date firstDate = Date.newInstance(current.year(),current.month(),01);
        Date lastDate = Date.newInstance(current.year(),current.month(),Date.daysInMonth(current.year(), current.month()));
        Map<String, List<Date>> mapOfDates = getDateMap(firstDate,lastDate);
        Map<Enrolment__c,Date> fifthBookingMap = new Map<Enrolment__c,Date>();
        Map<Enrolment__c,Date> fifthOssiaBookingMap = new Map<Enrolment__c,Date>();
        if(enrolmentList.size() > 0){
            for(Enrolment__c enrolObj : enrolmentList){
                if(enrolObj.type__c != ConstantsClass.enrolGroupType){
                    //Start:added by nishi: 13-aug-2020: for if enrolment is Ossia then we manage available makeup mins in enroment otherwise we mange parent records
                    if(mapOfDates.containskey(enrolObj.Lesson_Day__c) && mapOfDates.get(enrolObj.Lesson_Day__c).size() == 5 && mapOfDates.get(enrolObj.Lesson_Day__c)[4].day() > 28){
                        if(String.isNotBlank(enrolObj.Center__c) && String.isNotBlank(enrolObj.Center__r.Organisation__c) && 
                        String.isNotBlank(enrolObj.Center__r.Organisation__r.Name) && enrolObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                            //7-Sep:2020:Start: added by nishi: if teacher Engagement_Type__c type is part-time then not creating fifth lesson booking 
                            Boolean isTeaacherPartTime = false;
                            if(string.isNotBlank(enrolObj.Teacher__c) && string.isNotBlank(enrolObj.Teacher__r.Engagement_Type__c) && 
                             ConstantsClass.teacherPartTimeEngagementStatus.contains(enrolObj.Teacher__r.Engagement_Type__c)){
                                isTeaacherPartTime = true;
                            }
                            //7-Sep:2020:Start: added by nishi: if teacher Engagement_Type__c type is part-time then not creating fifth lesson booking 
                            if(!isTeaacherPartTime){
                                    fifthOssiaBookingMap.put(enrolObj, mapOfDates.get(enrolObj.Lesson_Day__c)[4]);
                            }
                        }else{
                            fifthBookingMap.put(enrolObj, mapOfDates.get(enrolObj.Lesson_Day__c)[4]);
                        }
                    }
                     //end:added by nishi: 13-aug-2020: for if enrolment is Ossia then we manage available makeup mins in enroment otherwise we mange parent records
                   //fifthBookingMap.put(enrolObj, mapOfDates.get(enrolObj.Lesson_Day__c)[4]);
                }
            }
        }
        
        if(fifthBookingMap.size()>0){
            System.debug('@@fifthBookingMap'+fifthBookingMap);
            createFifthBooking(fifthBookingMap);
        }
         //start:added by nishi: 13-aug-2020: for if enrolment is Ossia then we manage available makeup mins in enroment otherwise we mange parent records
        if(fifthOssiaBookingMap.size()>0){
            System.debug('@@fifthBookingMap'+fifthOssiaBookingMap);
            OssiaCenterCalendarController.createOssiaFifthBooking(fifthOssiaBookingMap);
        }
         //end:added by nishi: 13-aug-2020: for if enrolment is Ossia then we manage available makeup mins in enroment otherwise we mange parent records
                 
    }
    
    //Returns the Map of weekdays and its list of dates
    public static Map<String,List<Date>> getDateMap(Date firstDate, Date lastDate){
        Map<String,List<Date>> datesMap = new Map<String,List<Date>>();
        while(firstDate <= lastDate ){
            DateTime myDateTime = (DateTime) firstDate;
            String day = myDateTime.format('EEEE');
            List<Date> dateList = new List<Date>();
            if(datesMap.containskey(day)){
                dateList = datesMap.get(day);
            }
            dateList.add(firstDate);
            firstDate = firstDate.addDays(1);
            datesMap.put(day,dateList);
        }
        return datesMap;
    }
    
    
    //Create 5th Booking for the month of the enrolments
    private static void createFifthBooking(Map<Enrolment__c,Date> enrollmentMap){

        List<Enrolment__c> makeupsCreated = new List<Enrolment__c>();
        List<Enrolment__c> makeupsNotCreated = new List<Enrolment__c>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        
        Map<String,List<Booking__c>> parentBookingMap = getParentBookingMap(enrollmentMap);
        Set<String> existingFifthBookings = processFifthBookingsOfMonth();
        Map<String,Id> packageMap = getPackageMap();

        Map<String,Booking__c> bookingsToUpsert = new Map<String,Booking__c>();
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        List<Booking__c> finalBookingsToDML = new List<Booking__c>();

        Map<String, Package__c> mapOfAdhocPackage = fetchAdocPackage(enrollmentMap);
        Map<String, String> mapOfFifthLesson =  processFifthLessonsOfMonth();
		System.debug('@@@mapOfFifthLesson'+mapOfFifthLesson);
        Map<String, Integer> parentAvailableMinutes = new Map<String, Integer>();
        Integer parentMakeupHours = 0;

        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();
        for(Enrolment__c enrol : enrollmentMap.keySet()){

            parentMakeupHours = 0;
            Date bookingDate = enrollmentMap.get(enrol);
            String type='';
            String status ='';
            String packageId = '';
            String utilizedBookings ='';

            
            if(!parentAvailableMinutes.containsKey(enrol.Parent__r.Id)){
                parentMakeupHours = Integer.valueOf(enrol.Parent__r.Available_Make_up_Units__c);
                parentAvailableMinutes.put(enrol.Parent__r.Id, Integer.valueOf(enrol.Parent__r.Available_Make_up_Units__c));
            }
            System.debug('@@@enrol.Center__c'+enrol.Center__c);
			System.debug('@@+enrol.Teacher__c..'+enrol.Teacher__c);
            system.debug('@@+enrol.Lesson_Day__c'+enrol.Lesson_Day__c);
            system.debug('@@enrol.Lesson_Start_time__c'+enrol.Lesson_Start_time__c);
            system.debug('@@enrol.Package__r.Duration__c'+enrol.Package__r.Duration__c);
            system.debug('@@bookingDate'+bookingDate);
            System.debug('@@condition..'+!existingFifthBookings.contains(enrol.Center__c+'-'+enrol.Teacher__c+'-'+enrol.Lesson_Day__c+'-'+enrol.Lesson_Start_time__c+'-'+enrol.Package__r.Duration__c+'-'+bookingDate));
            if(/*(!existingFifthBookings.contains(enrol.Center__c+'-'+enrol.Teacher__c+'-'+enrol.Lesson_Day__c+'-'+enrol.Lesson_Start_time__c+'-'+enrol.Package__r.Duration__c+'-'+bookingDate)) &&*/ 
                (mapOfFifthLesson.containsKey(enrol.Center__c+'-'+enrol.Teacher__c+'-'+enrol.Id+'-'+bookingDate+'-'+enrol.Lesson_Start_time__c+'-'+enrol.Package__r.Duration__c))){
                
                
                if(parentAvailableMinutes.containsKey(enrol.Parent__r.Id) && parentAvailableMinutes.get(enrol.Parent__r.Id) != NULL && 
                   parentAvailableMinutes.get(enrol.Parent__r.Id) >= Integer.valueOf(enrol.package__r.Duration__c) 
                   && parentBookingMap.containsKey(enrol.Parent__c)){
                       
                       // check is parent has make up , then creates make up booking
                       fifthLesson = new Fifth_Lesson__c();
                       fifthLesson.Id = mapOfFifthLesson.get(enrol.Center__c+'-'+enrol.Teacher__c+'-'+enrol.Id+'-'+bookingDate+'-'+enrol.Lesson_Start_time__c+'-'+enrol.Package__r.Duration__c);
                       fifthLesson.isActive__c = FALSE;
                       type = ConstantsClass.typeMakeup;
                       status = ConstantsClass.statusScheduled;

                       if(packageMap.containsKey(enrol.package__r.Duration__c+'-'+enrol.Center__r.Name)){
                           packageId = packageMap.get(enrol.package__r.Duration__c+'-'+enrol.Center__r.Name);
                       }

                       Integer hoursToDeduct = Integer.valueOf(enrol.package__r.Duration__c);
                       parentMakeupHours -= hoursToDeduct;
                       for(Booking__c objBook : parentBookingMap.get(enrol.Parent__c)){
                           if(objBook.Available_Make_up_Units__c > 0){
                               if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                                   objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                                   utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                                   hoursToDeduct = 0;
                               }else{
                                   utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                                   hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                                   objBook.Available_Make_up_Units__c = 0;
                                   
                               }
                               //bookingsToUpsert.add(objBook); // add cancelled booking to reset credits.
                               bookingsToUpsert.put(objBook.id,objBook);
                               
                               if(hoursToDeduct == 0){
                                   break;
                               }    
                           }  
                       }
                       parentAvailableMinutes.put(enrol.Parent__r.Id, parentMakeupHours);
                       
                       makeupsCreated.add(enrol);
                       Booking__c objBook = addBooking(enrol, type, status, bookingDate, TRUE, packageId, utilizedBookings);
                       fifthLesson.Booking__r = objBook;
                       bookingsToInsert.add(objBook);
                       fifthLessons.add(fifthLesson);
                       
                   }else{
                       makeupsNotCreated.add(enrol);
                   }/*else{
                       System.debug('In adhoc schenario...');
                       Invoice__c invoiceObj = new Invoice__c();
                       Invoice_Line_Item__c invoiceLineItemObj = new Invoice_Line_Item__c();
                       //Create adhoc booking for that day
                        System.debug('@@@mapOfAdhocPackage'+mapOfAdhocPackage);
                       if(mapOfAdhocPackage.size() > 0){
                           //Insert Adhoc booking
                          
                           type = ConstantsClass.typeAdhoc;
                           status = ConstantsClass.statusPending;//ConstantsClass.statusScheduled;
                           utilizedBookings = '';
                           packageId = (mapOfAdhocPackage.containsKey(enrol.Center__c+'-'+enrol.Package__r.Duration__c)) ? mapOfAdhocPackage.get(enrol.Center__c+'-'+enrol.Package__r.Duration__c).Id : NULL;
                           Booking__c objBook = addBooking(enrol, type, status, bookingDate, TRUE, packageId, utilizedBookings);
                           bookingsToInsert.add(objBook);
                           
                           //Insert Adhoc Due Invoices and its Line item
                           invoiceObj.Status__c = ConstantsClass.dueStatus;
                           invoiceObj.Due_Date__c = bookingDate.addDays(-7);
                           invoiceObj.Invoice_Type__c = ConstantsClass.invoiceTypeAdhoc;
                           invoiceObj.Invoice_Date__c = System.today();
                           invoiceObj.Parent_Account__c = enrol.Parent__c;
                           invoiceObj.Center__c = enrol.Center__c;
                           invoices.add(invoiceObj);
                           
                           invoiceLineItemObj.invoice__r = invoiceObj;
                           invoiceLineItemObj.Amount__c = (mapOfAdhocPackage.containsKey(enrol.Center__c+'-'+enrol.Package__r.Duration__c)) ? mapOfAdhocPackage.get(enrol.Center__c+'-'+enrol.Package__r.Duration__c).unit_Fee__c : 0;
                           invoiceLineItemObj.package__c = packageId;
                           invoiceLineItemObj.Booking__r = objBook;
                           invoiceLineItemObj.Month__c = System.today();                           
                           invoiceLineItems.add(invoiceLineItemObj);
                       }
                   }*/    
            }
            
        }
        if(bookingsToInsert.size() > 0){
            finalBookingsToDML.addAll(bookingsToInsert);
        }
        if(bookingsToUpsert.size() > 0){
            finalBookingsToDML.addAll(bookingsToUpsert.values());
        }
        
        if(finalBookingsToDML.size() > 0){
            upsert finalBookingsToDML;
        }

        for(Fifth_Lesson__c fifthLessonObj : fifthLessons){
            fifthLessonObj.Booking__c = fifthLessonObj.Booking__r.Id;
            fifthLessonToUpdate.add(fifthLessonObj);
        }

        if(fifthLessonToUpdate.size() > 0){
            update fifthLessonToUpdate;
        }
        
        if(invoices.size() > 0){
            insert invoices;        
        }
        
        for(Invoice_Line_Item__c lineItemObj : invoiceLineItems){
            lineItemObj.Invoice__c = lineItemObj.Invoice__r.Id;
            lineItemObj.Booking__c = lineItemObj.Booking__r.Id;
        }
        
        if(invoiceLineItems.size() > 0){
            insert invoiceLineItems;
        }

        if(makeupsCreated.size() > 0 || makeupsNotCreated.size() > 0){
            makeupCreationNotification(makeupsCreated, makeupsNotCreated);
        }
    }
    

    // this method return the list of cancelled booking of all students including parent itself, within 120 days
    public static Map<String,List<Booking__c>> getParentBookingMap(Map<Enrolment__c,Date> enrollmentMap){
        Map<String,List<Booking__c>> parentBookingMap = new Map<String,List<Booking__c>>();
        Set<String> setOfParentIds = new Set<String>(); // hold ids of parent which has available makeup minutes
        Set<String> setOfStuParentIds = new Set<String>(); // hold id of student and parent to fetch cancelled bookings.
        
        // fill set of parentIds from enrollment which has available makeup credits.
        for(Enrolment__c enroll : enrollmentMap.keyset()){
            if(String.isNotBlank(enroll.Student__c) && String.isNotBlank(enroll.Parent__c) && enroll.Parent__r.Available_Make_up_Units__c > 0){
                setOfParentIds.add(enroll.Parent__c); 
            }
        }
        
        // fill the set of student and parent for which we fetch bookings.
        if(setOfParentIds.size() > 0){
            for( Account objAcc : [SELECT Id, also_A_Student__c FROM Account WHERE Id IN: setOfParentIds OR Parent__c IN: setOfParentIds]){
                setOfStuParentIds.add(objAcc.Id);
            }
        }
        
         if(setOfStuParentIds.size() > 0){
            for(Booking__c booking : [SELECT  Id,Student__c,Parent__c,Available_Make_up_Units__c,Enrolment__c,Enrolment__r.Package__r.Duration__c FROM Booking__c 
                                      WHERE status__c =: ConstantsClass.statusCanceled  AND Student__c IN :setOfStuParentIds AND Make_up_Expiry_Date__c > today
                                              AND Available_Make_up_Units__c != Null
                                              ORDER BY Make_up_Expiry_Date__c asc  ] ){
                                              
                String parentId = String.isNotBlank(booking.Parent__c) ?booking.Parent__c : booking.Student__c;
                if(String.isNotBlank(parentId)){
                    List<Booking__c> bookingList = parentBookingMap.containsKey(parentId) ?parentBookingMap.get(parentId) : new List<Booking__c>();
                    bookingList.add(booking);
                    parentBookingMap.put(parentId, bookingList);
                }
            }
        }
        return parentBookingMap;
    }
    
    //Fetch All Adhoc Package For Centre
    public static Map<String, Package__c> fetchAdocPackage(Map<Enrolment__c, Date> enrolMap){
        Set<String> setOfCentre = new Set<String>();
        Set<String> setOfDuration = new Set<String>();
       Map<String, Package__c> mapOfAdhocPackage = new Map<String, Package__c>();
        
        for(Enrolment__c enrolObj : enrolMap.keySet()){
            setOfCentre.add(enrolObj.Center__c);
            setOfDuration.add(enrolObj.package__r.Duration__c);
        }
        
        if(setOfCentre.size() > 0 && setOfDuration.size() > 0){
            for(Package__c packageObj : [SELECT Id, Location__c, Duration__c, unit_Fee__c FROM Package__c 
                                         WHERE Active__c = TRUE AND Type__c = 'Adhoc' AND Location__c IN :setOfCentre AND 
                                         Duration__c IN :setOfDuration]){
                mapOfAdhocPackage.put(packageObj.Location__c + '-' + packageObj.Duration__c, packageObj);
            } 
        }
        
        
        return mapOfAdhocPackage;
    }
    
    public static Map<String,Id> getPackageMap(){
        String pakageTypeMakeup = ConstantsClass.pakageTypeMakeup;
        Map<String,Id> packageMap = new Map<String,Id>();
        for(Package__c packg : [Select Id,type__c,Duration__c,Location__r.Name From Package__c where type__c =: pakageTypeMakeup]){
            packageMap.put(packg.Duration__c+'-'+packg.Location__r.Name,packg.Id); 
        }
        return packageMap;
    }
    
    Public static Booking__c addBooking(Enrolment__c objEnrol,String type,String status,date bookDate , Boolean isFifthBooking,
                                        String packageId,String utilizedBookings){
        Booking__c objBooking = new Booking__c();
        objBooking.Student__c = objEnrol.Student__c;
        objBooking.Center__c = objEnrol.Center__c;
        objBooking.Teacher_Account__c = objEnrol.Teacher__c;
        objBooking.Enrolment__c = objEnrol.Id;
        objBooking.start_time__c = objEnrol.Lesson_Start_time__c;
        objBooking.End_time__c = objBooking.start_time__c.addMinutes(Integer.valueOf(objEnrol.Package__r.Duration__c));
        objBooking.Booking_Date__c = bookDate;
        objBooking.type__c = type;
        objBooking.Status__c = status;
        objBooking.Package__c = packageId;
        objBooking.is_Fifth_Booking__c = isFifthBooking;
        if(String.isNotBlank(utilizedBookings)){
            objBooking.Make_up_Utilize_Bookings__c = utilizedBookings;
        }
        objBooking.Parent__c= String.isNotBlank(objEnrol.Parent__c) && objEnrol.Parent__c !=null ? objEnrol.Parent__c : null;
        return objBooking;
    }
    
    //Update Enrolment According to the Advance Action
    public static List<Enrolment__c> enrolmentAdvanceAction(Map<String, Enrolment__c> enrolmentMap,Date startingDate){
        system.debug('enrolmentAdvanceAction');
        Enrolment__c objEnrolment;
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
        
        //Date startDate = System.today().toStartOfMonth();// commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
        Date startDate = startingDate.toStartOfMonth();
        Date endDate = startDate.addMonths(1).addDays(-1);
        system.debug('!!endDate'+endDate);
        for(String enrolId : enrolmentMap.keyset()){
            objEnrolment = enrolmentMap.get(enrolId);
            system.debug('!!objEnrolment.effective_Date__c'+objEnrolment.effective_Date__c);
            system.debug('!!objEnrolment.Package_Process_Type__c'+objEnrolment.Package_Process_Type__c);
            system.debug('!!objEnrolment.Package_Process_Status__c'+objEnrolment.Package_Process_Status__c);
            if(String.isNotBlank(objEnrolment.Package_Process_Type__c) && 
               objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus && 
               objEnrolment.effective_Date__c <= endDate){
                   //objEnrolment.effective_Date__c >= startDate && 
                   if(objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessUpgradeType || 
                      objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessDowngradeType){
                         if(objEnrolment.New_Package_Id__c != NULL){ 
                            objEnrolment.package__c = objEnrolment.New_Package_Id__c;
                            objEnrolment.New_Package_Id__c = NULL;
                         }
                        if(objEnrolment.Next_Lesson_Start_time__c != NULL){
                            objEnrolment.Lesson_Start_Time__c = objEnrolment.Next_Lesson_Start_time__c;
                            objEnrolment.Next_Lesson_Start_time__c = NULL;
                        }
                        // added by jatin: 9-jan-2020: for add new class id in class field
                        if(objEnrolment.type__c == ConstantsClass.enrolGroupType && 
                            objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessUpgradeType &&
                            objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus){
                            // check class is class is not found than we remove class
                            // because enrolment upgrade group class to individual 
                            if(objEnrolment.New_Class__c != NULL){
                                objEnrolment.Class__c = objEnrolment.New_Class__c;
                                objEnrolment.New_Class__c = NULL;
                            }else{
                                objEnrolment.Class__c = NULL;
                                objEnrolment.type__c = ConstantsClass.enrolRegularStatus;
                            }
                            // 10-jan-2020: jatin: for change teacher and lesson day
                            if(String.isNotBlank(objEnrolment.New_Teacher__c)){
                                objEnrolment.teacher__c = objEnrolment.New_Teacher__c;
                                objEnrolment.New_Teacher__c = NULL;
                            }
                            
                            if(String.isNotBlank(objEnrolment.New_Lesson_Day__c)){
                                objEnrolment.Lesson_Day__c = objEnrolment.New_Lesson_Day__c;
                                objEnrolment.New_Lesson_Day__c = '';
                            }
                            system.debug('objEnrolment.type__c'+objEnrolment.type__c);
                        }
                         objEnrolment.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
                       
                    }else if(objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType){
                        objEnrolment.Stage__c = ConstantsClass.enrollmentStageCancelled;
                        objEnrolment.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
                         system.debug('objEnrolment.Stage__c'+objEnrolment.Stage__c);
                          system.debug('objEnrolment.Package_Process_Status__c'+objEnrolment.Package_Process_Status__c);
                    }else if(objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessChanged){
                        
                        if(String.isNotBlank(objEnrolment.New_Package_Id__c)){
                            objEnrolment.package__c = objEnrolment.New_Package_Id__c;
                            objEnrolment.New_Package_Id__c = NULL;
                        }
                        
                        if(objEnrolment.Next_Lesson_Start_time__c != NULL){
                            objEnrolment.Lesson_Start_Time__c = objEnrolment.Next_Lesson_Start_time__c;
                            objEnrolment.Next_Lesson_Start_time__c = NULL;
                        }
                        
                        if(String.isNotBlank(objEnrolment.New_Teacher__c)){
                            objEnrolment.teacher__c = objEnrolment.New_Teacher__c;
                            objEnrolment.New_Teacher__c = NULL;
                        }
                        
                        if(String.isNotBlank(objEnrolment.New_Lesson_Day__c)){
                            objEnrolment.Lesson_Day__c = objEnrolment.New_Lesson_Day__c;
                            objEnrolment.New_Lesson_Day__c = '';
                        }
                        // added by jatin: 9-jan-2020: for add new class id in class field
                        if(objEnrolment.type__c == ConstantsClass.enrolGroupType){
                            if(objEnrolment.New_Class__c != NULL){
                                objEnrolment.Class__c = objEnrolment.New_Class__c;
                                objEnrolment.New_Class__c = NULL;
                            }
                        }
                        objEnrolment.Package_Process_Status__c =  ConstantsClass.enrollmentProcessCompletedStatus; //'Completed';
                    }
                    //added by nishi: 4-sep-2020: for if enrolment process is pending and Package_Process_Type__c == change center then we update enrolment
                    else if(objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessChangedCenter){
                        
                        if(String.isNotBlank(objEnrolment.New_Package_Id__c)){
                            objEnrolment.package__c = objEnrolment.New_Package_Id__c;
                            objEnrolment.New_Package_Id__c = NULL;
                        }
                        
                        if(objEnrolment.Next_Lesson_Start_time__c != NULL){
                            objEnrolment.Lesson_Start_Time__c = objEnrolment.Next_Lesson_Start_time__c;
                            objEnrolment.Next_Lesson_Start_time__c = NULL;
                        }
                        
                        if(String.isNotBlank(objEnrolment.New_Teacher__c)){
                            objEnrolment.teacher__c = objEnrolment.New_Teacher__c;
                            objEnrolment.New_Teacher__c = NULL;
                        }
                        
                        if(String.isNotBlank(objEnrolment.New_Lesson_Day__c)){
                            objEnrolment.Lesson_Day__c = objEnrolment.New_Lesson_Day__c;
                            objEnrolment.New_Lesson_Day__c = '';
                        }
                        if(String.isNotBlank(objEnrolment.New_Centre__c)){
                            objEnrolment.Center__c = objEnrolment.New_Centre__c;
                            objEnrolment.New_Centre__c = Null;
                        }
                       
                        objEnrolment.Package_Process_Status__c =  ConstantsClass.enrollmentProcessCompletedStatus; //'Completed';
                    }
                   //added by nishi: 4-sep-2020: for if enrolment process is pending and Package_Process_Type__c == change center then we update enrolment
                   enrolmentList.add(objEnrolment);
               }
            
        }
        if(enrolmentList.size() > 0){
            update enrolmentList;
            system.debug('enrolmentAdvanceAction'+enrolmentList);
        }
        return enrolmentList;
    }
    
    //Create 4 bookings of per enrolment for 13 month
    private static void createBookingFor13Month(List<Enrolment__c> enrolmentList, Set<String> cancelledBookingsSet,Date startingdate, Set<string> existing13MonthBookingEnrolmentIds){
        String lessonRecorType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        
        List<Booking__c> listOfBookings = new List<Booking__c>();
        //Date current = System.today().addMonths(13); // commented by nishi: 9-Sep-2020: for creating next month invoice requirement we send next month date with enrolment id
        Date current = startingdate.addMonths(13);
        Date firstDate = Date.newInstance(current.year(),current.month(),01);
        Date lastDate = Date.newInstance(current.year(),current.month(),Date.daysInMonth(current.month(),current.year()));
        Map<String, List<Date>> mapOfDates = getDateMap(firstDate,lastDate);
        integer counter = 0;
        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        Map<String, Teacher_Working_Hour__c> mapOfHomeTeachersHours = fetchWorkingHoursHome();
        Teacher_Working_Hour__c workingHour = new Teacher_Working_Hour__c();
        Boolean isHome = FALSE;
        if(enrolmentList.size() > 0){
            for(Enrolment__c enrolmentObj : enrolmentList){
                 // nishi: 6-Oct-2020: for if any enrolment ids is exist in existing13MonthBookingEnrolmentIds this set 
                 //that a 13-month booking has already been created, so we do not want to make the 13th month booking again
                if(!existing13MonthBookingEnrolmentIds.contains(enrolmentObj.id)){
                    isHome = FALSE;
                    //Check that the enrolment is of Aureus home centre or not....
                    workingHour = new Teacher_Working_Hour__c();
                    if(enrolmentObj.Center__c == Label.Aureus_at_Home_Id && String.isNotBlank(enrolmentObj.Lesson_Day__c) && String.isNotBlank(enrolmentObj.Teacher__c)){
                        workingHour = (mapOfHomeTeachersHours.containsKey(enrolmentObj.Teacher__c + '-'+enrolmentObj.Lesson_Day__c.left(3)) ? mapOfHomeTeachersHours.get(enrolmentObj.Teacher__c + '-'+enrolmentObj.Lesson_Day__c.left(3)) : NULL);
                        isHome = TRUE;
                    }
                    //If the cancelledBookingsSet contains the enrolment Id then loop will skip the further process of creating regular bookings for that enrolment.
                    if(cancelledBookingsSet.contains(enrolmentObj.Id)){
                        continue;
                    }
                    
                    counter = 0;
                    if(String.isNotBlank(enrolmentObj.Lesson_Day__c)){
                        List<Date> listOfDates = mapOfDates.get(enrolmentObj.Lesson_Day__c);
                        
                        for(Date objDate : listOfDates){
                            ++counter;
                            if(counter == 5){
                                Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();
                                fifthLesson.Enrolment__c = enrolmentObj.Id;
                                fifthLesson.Student__c = enrolmentObj.Student__c;
                                fifthLesson.Center__c = enrolmentObj.Center__c;
                                fifthLesson.Teacher_Account__c = enrolmentObj.Teacher__c;
                                fifthLesson.Booking_Date__c = objDate;
                                fifthLesson.parent__c = String.isNotBlank(enrolmentObj.parent__c) && enrolmentObj.parent__c !=null ? enrolmentObj.parent__c : null;
                                fifthLesson.start_time__c = enrolmentObj.Lesson_Start_time__c;
                                if(fifthLesson.start_time__c != NULL){
                                    fifthLesson.End_time__c = fifthLesson.start_time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));
                                }
                                fifthLesson.Package__c = enrolmentObj.Package__c;
                                fifthLesson.Remarks__c = '5th lesson '+enrolmentObj.Parent__r.Name+'-'+enrolmentObj.Student__r.Name;
                                fifthLessons.add(fifthLesson);
                                
                            }else{
                                Booking__c objBooking = new Booking__c();
                                objBooking.Student__c = enrolmentObj.Student__c;
                                objBooking.Center__c = enrolmentObj.Center__c;
                                objBooking.Teacher_Account__c = enrolmentObj.Teacher__c;
                                objBooking.Booking_Date__c = objDate;
                                objBooking.recordTypeId = lessonRecorType;
                                objBooking.parent__c = String.isNotBlank(enrolmentObj.parent__c) && enrolmentObj.parent__c !=null ? enrolmentObj.parent__c : null;
                                objBooking.start_time__c = enrolmentObj.Lesson_Start_time__c;
                                if(objBooking.start_time__c != NULL){
                                    objBooking.End_time__c = objBooking.start_time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));
                                }
                                objBooking.Enrolment__c = enrolmentObj.Id; 
                                objBooking.Package__c = enrolmentObj.Package__c;
                                objBooking.type__c = ConstantsClass.typeRegular;
                                objBooking.Status__c = ConstantsClass.pendingStatus;
                                listOfBookings.add(objBooking);
                            }

                            if(isHome && enrolmentObj.Lesson_Start_time__c != NULL && String.isNotBlank(workingHour.Id) && workingHour.start_Time__c < enrolmentObj.Lesson_Start_time__c){
                                Booking__c objBooking = new Booking__c();
                                objBooking.Center__c = enrolmentObj.Center__c;
                                objBooking.Teacher_Account__c = enrolmentObj.Teacher__c;
                                objBooking.Booking_Date__c = objDate;
                                objBooking.recordTypeId = lessonRecorType;
                                objBooking.End_time__c = enrolmentObj.Lesson_Start_time__c;
                                if(objBooking.End_time__c != NULL){
                                    objBooking.start_time__c = objBooking.End_time__c.addMinutes(-30);
                                }
                                objBooking.Enrolment__c = enrolmentObj.Id; 
                                objBooking.type__c = ConstantsClass.typeBusy;
                                objBooking.Status__c = ConstantsClass.statusScheduled;
                                objBooking.Category__c = ConstantsClass.categoryTravel;
                                objBooking.Remarks__c = 'Travel';
                                listOfBookings.add(objBooking);
                            }
                        }
                    }
                }
            }
            if(listOfBookings.size() > 0){
                insert listOfBookings;
            }
            if(fifthLessons.size() > 0){
                insert fifthLessons;
            }
        }
    }
    // nishi: 6-Oct-2020: for get all enrolment ids if 13 month booking exist
    public static set<string> getexisting13MonthBookingEnrolmentIds(map<string,Enrolment__c> enrolmentmap,Date firstDate,Date lastDate){
        Set<string> existing13MonthBookingEnrolmentIds = new Set<string>();
        Set<string> bookingTypes = new Set<string>{ConstantsClass.groupLessonTypeBooking,ConstantsClass.typeRegular};
        for(Booking__c objBook : [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                    Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                    Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c ,
                                    Class__c
                                    FROM Booking__c 
                                    WHERE type__c in: bookingTypes
                                    AND Booking_Date__c >=: firstDate
                                    AND Booking_Date__c <=: lastDate
                                    And Enrolment__c In:enrolmentmap.keySet()]){
                                        existing13MonthBookingEnrolmentIds.add(objBook.Enrolment__c);                          
        }
        return existing13MonthBookingEnrolmentIds;
    }
    /*
    * 
    */
    //process Fifth Bookings(Adhoc/Makeup) of current month for every enrolment 
    public static Set<String> processFifthBookingsOfMonth(){   
        Set<String> bookingTypes = new Set<String>{ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc};
        Set<String> setOfFifthBookings = new Set<String>();
        for(Booking__c objBook : [SELECT Id, Start_time__c, End_time__c, Booking_Date__c, Available_Make_up_Units__c, Student__r.Name, 
                                  Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c, Duration__c, Type__c, Appointment_Day__c FROM Booking__c 
                                  WHERE Type__c IN: bookingTypes AND DAY_IN_MONTH(Booking_Date__c) > 28 AND Booking_Date__c = THIS_MONTH]){
                                  
          setOfFifthBookings.add(objBook.Center__c+'-'+objBook.Teacher_Account__c+'-'+objBook.Appointment_Day__c+'-'+objBook.Start_time__c+'-'+objBook.Duration__c+'-'+objBook.Booking_Date__c);                                                                                               
        }
        return setOfFifthBookings;
    }

    //Fetch Fifth Lessons of the current month for every enrolment
    public static Map<String, String> processFifthLessonsOfMonth(){
        Map<String, String> fifthLessonMap = new Map<String, String>();
        for(Fifth_Lesson__c fifthLesson : [SELECT Id, Start_time__c, End_time__c, Booking_Date__c, Center__c, Teacher_Account__c, Duration__c, Enrolment__c  
                                            FROM Fifth_Lesson__c WHERE DAY_IN_MONTH(Booking_Date__c) > 28 AND Booking_Date__c = THIS_MONTH AND 
                                            Enrolment__c != NULL AND IsActive__c = TRUE]){
            fifthLessonMap.put(fifthLesson.Center__c+'-'+fifthLesson.Teacher_Account__c+'-'+fifthLesson.Enrolment__c+'-'+fifthLesson.Booking_Date__c+'-'+fifthLesson.Start_time__c+'-'+fifthLesson.Duration__c, fifthLesson.Id);

        }
        return fifthLessonMap;
    }
    
    // get pdf of invoice page in a blob value
    public static Blob getInvoicePDF(String invoiceId){
        Blob value;
        PageReference pdf = Page.SubscriptionInvoicePdfClone;
        pdf.getParameters().put('Id', invoiceId);
        pdf.setRedirect(true);
        if(!Test.isRunningTest()) {
           value = pdf.getContent();
        }else{
            value = blob.valueOf('Unit.Test');
        }
        
        return value;
    }
    
    //Send Email Notification To Parent
    Public static void makeupCreationNotification(List<Enrolment__c> makeupsCreated, List<Enrolment__c> makeupsNotCreated){

        EmailTemplate templateForMakeupCreation = new EmailTemplate();
        EmailTemplate templateForMakeupCreationFailed = new EmailTemplate();
        Messaging.SingleEmailMessage mailNotification = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>(); 
        for(EmailTemplate templateObj : [SELECT Id, Developername FROM EmailTemplate WHERE Developername ='Makeup_Booking_Creation_Notification' OR Developername ='Makeup_Booking_Creation_Fails_Notification']){
            if(templateObj.Developername == 'Makeup_Booking_Creation_Notification'){
                templateForMakeupCreation = templateObj;
            }else if(templateObj.Developername == 'Makeup_Booking_Creation_Fails_Notification'){
                templateForMakeupCreationFailed = templateObj;
            }
        }
        
        for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
            mapOfOrgWide.put(objAddress.DisplayName,objAddress);
        }
        if(String.isNotBlank(templateForMakeupCreation.id)){
            for(Enrolment__c makeupCreated : makeupsCreated){
                String location = makeupCreated.Center__r.Location__c;
                mailNotification = new Messaging.SingleEmailMessage();
                mailNotification = getSingleEmailMessage(templateForMakeupCreation.id, makeupCreated.Parent__r.personContactId, makeupCreated.Id, location);
                emailList.add(mailNotification);
            }
        }
        
        if(String.isNotBlank(templateForMakeupCreationFailed.id)){
            for(Enrolment__c makeupnotCreated : makeupsNotCreated){
                String location = makeupnotCreated.Center__r.Location__c;
                mailNotification = new Messaging.SingleEmailMessage();
                mailNotification = getSingleEmailMessage(templateForMakeupCreationFailed.id, makeupnotCreated.Parent__r.personContactId, makeupnotCreated.Id, location);
                emailList.add(mailNotification);
            }
        }
        if(emailList.size() > 0){
            Messaging.sendEmail(emailList, FALSE);
        }
    }

    /*Create Fifth Bookings for the Month of the Enrolment
        It will create the adhoc and Makeup Booking if Fifth Lesson Exist. 
    */
    public static void createFifthBookingBefore6Days(List<Fifth_Lesson__c> pendingFifthLessons){
        system.debug('pendingFifthLessons'+pendingFifthLessons);
        Map<String, Integer> parentAvailableMinutes = new Map<String, Integer>();
        Integer currentParentMakeup = 0;
        List<Fifth_Lesson__c> fifthLessonsToUpdate = new List<Fifth_Lesson__c>();
        List<Fifth_Lesson__c> fifthLessonsFinalDML = new List<Fifth_Lesson__c>();
        String type, status, packageId, utilizedBookings = '', stripe;
        Enrolment__c enrolObj = new Enrolment__c();
        Date bookingDate;
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
        Map<String,Id> packageMakeupMap = getPackageMap();  

        List<Booking__c> bookingFifthList = new List<Booking__c>();
        Map<String, Booking__c> cancelBookingToUpdate = new Map<String, Booking__c>();

        Set<String> centreIds = new Set<String>();
        Set<String> durations = new Set<String>();
        
        Country__c countryObj = new Country__c();
        Map<String,Decimal> countryTaxRate = new Map<String,Decimal>();
        map<string,string> mapOfteacherType = new map<string,string>(); //added by nishi: 3-Sep-2020: for check teacher type is part-time then we not creating bookings
         //Start: added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
        Map<String, Integer> enrolmentAvailableMinutes = new Map<String, Integer>();
        Set<String> ossiaEnrolmentIds = new Set<String>();
         //end: added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
        for(Fifth_Lesson__c fifthLessons : pendingFifthLessons){
             //Start: added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
            if(string.isNotBlank(fifthLessons.Enrolment__c) &&  String.isNotBlank(fifthLessons.Enrolment__r.Center__c) && 
                String.isNotBlank(fifthLessons.Enrolment__r.Center__r.Organisation__c) && 
                String.isNotBlank(fifthLessons.Enrolment__r.Center__r.Organisation__r.Name) && 
                fifthLessons.Enrolment__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){ 
                    ossiaEnrolmentIds.add(fifthLessons.Enrolment__c);
            }else{
             //end: added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
                enrolmentList.add(fifthLessons.Enrolment__r);
            }

            centreIds.add(fifthLessons.center__c);
            durations.add(String.valueOf(Integer.valueOf(fifthLessons.duration__c)));
             //Start: added by nishi: 3-Sep-2020: for check teacher type is part-time then we not creating bookings
            if(string.isNotBlank(fifthLessons.Enrolment__c) && string.isNotBlank(fifthLessons.Enrolment__r.Teacher__c) && 
                string.isNotBlank(fifthLessons.Enrolment__r.Teacher__r.Engagement_Type__c)){
                mapOfteacherType.put( fifthLessons.Enrolment__r.Teacher__c, fifthLessons.Enrolment__r.Teacher__r.Engagement_Type__c);
            }
             //end: added by nishi: 3-Sep-2020: for check teacher type is part-time then we not creating bookings
            // Jatin: 13-jan:2020: for add GST according to enrolment Center
            if(fifthLessons.Enrolment__r != null && fifthLessons.Enrolment__r.Center__r != null && 
                fifthLessons.Enrolment__r.Center__r.Country__r != null && 
                String.isNotBlank(fifthLessons.Enrolment__r.Center__r.Country__r.Id)){
                countryTaxRate.put(fifthLessons.Enrolment__r.Center__r.Country__r.Id,fifthLessons.Enrolment__r.Center__r.Country__r.Tax_Rate__c);
            }
        }
        system.debug('countryTaxRate'+countryTaxRate);
		system.debug('centreIds'+centreIds);
        system.debug('durations'+durations);
        Map<String, Package__c> packageAdhocMap = new Map<String, Package__c>();
        if(centreIds.size() > 0 && durations.size() > 0){
            packageAdhocMap = getAdhocPackages(centreIds, durations);
        }
        system.debug('packageAdhocMap'+packageAdhocMap);
        Map<String, List<Booking__c>> mapOfParentCancelBookings = getParentCancelBookings(enrolmentList);
        
        // Start:added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
        // first we deduct makeup mins to teacher leave canceled booking then if makeup utlization mins is remaning then we get all canceled bookings 
        Map<String,List<Booking__c>> ossiateacherLeaveCancelBookingMap = OssiaCenterCalendarController.getCancelBookingMap(new Map<Enrolment__c,Date>(),ossiaEnrolmentIds,true);
        Map<String,List<Booking__c>> ossiateacherLeaveWithoutCancelBookingMap = OssiaCenterCalendarController.getCancelBookingMap(new Map<Enrolment__c,Date>(),ossiaEnrolmentIds,false);
         //End: added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
        // first we deduct makeup mins to teacher leave canceled booking then if makeup utlization mins is remaning then we get all canceled bookings

        //Adhoc Bookings Creation
        List<Invoice__c> invoicesObjList = new List<Invoice__c>();
        List<Invoice_Line_Item__c> invoiceLineItemsList = new List<Invoice_Line_Item__c>();
        List<Payment__c> paymentList = new List<Payment__c>();
        
        List<Invoice_Line_Item__c> invoiceLineItemsListToInsert = new List<Invoice_Line_Item__c>();
        List<Payment__c> paymentListToInsert = new List<Payment__c>();
        Boolean isCreateFifthlessonBooking = true;  //added by nishi: 3-Sep-2020: for check teacher type is part-time then we not creating bookings
        Boolean isOssiaFifthlessonBooking = false;
        for(Fifth_Lesson__c fifthLessons : pendingFifthLessons){
            isOssiaFifthlessonBooking = false;

            //Start: added by nishi: 3-Sep-2020: for check teacher type is part-time then we not creating bookings
            isCreateFifthlessonBooking = true;
            if(string.isNotBlank(fifthLessons.Enrolment__c) && string.isNotBlank(fifthLessons.Enrolment__r.Teacher__c) && mapOfteacherType != null && mapOfteacherType.size() > 0
            && ossiaEnrolmentIds != null && ossiaEnrolmentIds.size() > 0 && ossiaEnrolmentIds.contains(fifthLessons.Enrolment__c)){
                if(mapOfteacherType.containsKey(fifthLessons.Enrolment__r.Teacher__c) &&
                ConstantsClass.teacherPartTimeEngagementStatus.contains(mapOfteacherType.get(fifthLessons.Enrolment__r.Teacher__c))){
                    isCreateFifthlessonBooking = false;
                }
            }
            if(isCreateFifthlessonBooking){
              //End: added by nishi: 3-Sep-2020: for check teacher type is part-time then we not creating bookings

                enrolObj = new Enrolment__c();
                enrolObj = fifthLessons.Enrolment__r;
                bookingDate = fifthLessons.Booking_Date__c;
                utilizedBookings ='';
                
                if(String.isNotBlank(fifthLessons.Enrolment__r.Center__r.Country__r.Id)){
                    countryObj = new Country__c();
                    countryObj = fifthLessons.Enrolment__r.Center__r.Country__r;
                }
                
                if(String.isNotBlank(fifthLessons.Parent__c)){
                    stripe = fifthLessons.Parent__r.Stripe_Customer_Id__c;
                }
                
                // if fifth lesson booking belog
                if(string.isNotBlank(fifthLessons.Enrolment__c) && !enrolmentAvailableMinutes.containsKey(fifthLessons.Enrolment__c) &&  
                    ossiaEnrolmentIds != null && ossiaEnrolmentIds.size() > 0 && ossiaEnrolmentIds.contains(fifthLessons.Enrolment__c) ){
                    currentParentMakeup = Integer.valueOf(fifthLessons.Enrolment__r.Available_Make_up_mins__c);
                    enrolmentAvailableMinutes.put(fifthLessons.Enrolment__c, Integer.valueOf(fifthLessons.Enrolment__r.Available_Make_up_mins__c));
                    isOssiaFifthlessonBooking = true;
                }
                if(!isOssiaFifthlessonBooking && String.isNotBlank(fifthLessons.Parent__c) && !parentAvailableMinutes.containsKey(fifthLessons.Parent__c)){
                    currentParentMakeup = Integer.valueOf(fifthLessons.Parent__r.Available_Make_up_Units__c);
                    parentAvailableMinutes.put(fifthLessons.Parent__c, Integer.valueOf(fifthLessons.Parent__r.Available_Make_up_Units__c));
                }
                system.debug('parentAvailableMinutes'+parentAvailableMinutes);
                if(!isOssiaFifthlessonBooking && parentAvailableMinutes != null && parentAvailableMinutes.size() > 0 &&
                parentAvailableMinutes.containsKey(fifthLessons.Parent__c) && parentAvailableMinutes.get(fifthLessons.Parent__c) >= Integer.valueOf(fifthLessons.Package__r.Duration__c)){
                    //Create Makeup
                    type = ConstantsClass.typeMakeup;
                    status = ConstantsClass.scheduledStatus;
                    
                    if(packageMakeupMap.containsKey(enrolObj.package__r.Duration__c+'-'+enrolObj.Center__r.Name)){
                        packageId = packageMakeupMap.get(enrolObj.package__r.Duration__c+'-'+enrolObj.Center__r.Name);
                    }   
                    Integer hoursToDeduct = Integer.valueOf(enrolObj.package__r.Duration__c);
                    currentParentMakeup -= hoursToDeduct;
                    if(mapOfParentCancelBookings.containsKey(enrolObj.Parent__c)){
                        for(Booking__c objBook : mapOfParentCancelBookings.get(enrolObj.Parent__c)){
                            if(objBook.Available_Make_up_Units__c > 0){
                                if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                                    objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                                    utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                                    hoursToDeduct = 0;
                                }else{
                                    utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                                    hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                                    objBook.Available_Make_up_Units__c = 0;
                                    
                                }
                                
                                cancelBookingToUpdate.put(objBook.id,objBook);
                                
                                if(hoursToDeduct == 0){
                                    break;
                                }  
                                
                            }  
                        }    
                    }
                    

                    parentAvailableMinutes.put(enrolObj.Parent__r.Id, currentParentMakeup);
                    if(String.isNotBlank(packageId)){
                        Booking__c objBook = addBooking(enrolObj, type, status, bookingDate, TRUE, packageId, utilizedBookings); 
                        fifthLessons.Booking__r = objBook;
                        bookingFifthList.add(objBook);

                        fifthLessonsToUpdate.add(fifthLessons);
                    }else{
                        System.debug('@@@@enrolObj Makeup Package Not Found'+enrolObj.Id);
                    }
                    
                } 
                // added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
                // first we deduct makeup mins to teacher leave canceled booking then if makeup utlization mins is remaning then we get all canceled bookings
                else if( isOssiaFifthlessonBooking && enrolmentAvailableMinutes != null && enrolmentAvailableMinutes.size() > 0 && 
                enrolmentAvailableMinutes.containsKey(fifthLessons.Enrolment__C) && enrolmentAvailableMinutes.get(fifthLessons.Enrolment__C) >= Integer.valueOf(fifthLessons.Package__r.Duration__c)){
                    //Create Makeup
                    type = ConstantsClass.typeMakeup;
                    status = ConstantsClass.scheduledStatus;
                    if(packageMakeupMap.containsKey(enrolObj.package__r.Duration__c+'-'+enrolObj.Center__r.Name)){
                        packageId = packageMakeupMap.get(enrolObj.package__r.Duration__c+'-'+enrolObj.Center__r.Name);
                    }   
                    Integer hoursToDeduct = Integer.valueOf(enrolObj.package__r.Duration__c);
                    currentParentMakeup -= hoursToDeduct;
                    if(ossiateacherLeaveCancelBookingMap != null && ossiateacherLeaveCancelBookingMap.size() > 0 && ossiateacherLeaveCancelBookingMap.containsKey(enrolObj.Id)){
                        for(Booking__c objBook : ossiateacherLeaveCancelBookingMap.get(enrolObj.Id)){
                            if(objBook.Available_Make_up_Units__c > 0){
                                if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                                    objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                                    utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                                    hoursToDeduct = 0;
                                }else{
                                    utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                                    hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                                    objBook.Available_Make_up_Units__c = 0;
                                    
                                }
                                
                                cancelBookingToUpdate.put(objBook.id,objBook);
                                
                                if(hoursToDeduct == 0){
                                    break;
                                }  
                                
                            }  
                        }    
                    }
                    if(hoursToDeduct > 0 && ossiateacherLeaveWithoutCancelBookingMap != null && ossiateacherLeaveWithoutCancelBookingMap.size() > 0 && ossiateacherLeaveWithoutCancelBookingMap.containsKey(enrolObj.id)){
                        for(Booking__c objBook : ossiateacherLeaveWithoutCancelBookingMap.get(enrolObj.id)){
                            if(objBook.Available_Make_up_Units__c > 0){
                                if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                                    objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                                    utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                                    hoursToDeduct = 0;
                                }else{
                                    utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                                    hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                                    objBook.Available_Make_up_Units__c = 0;
                                    
                                }
                                
                                cancelBookingToUpdate.put(objBook.id,objBook);
                                
                                if(hoursToDeduct == 0){
                                    break;
                                }  
                                
                            }  
                        }    
                    }
                    

                    enrolmentAvailableMinutes.put(enrolObj.Id, currentParentMakeup);
                    if(String.isNotBlank(packageId)){
                        Booking__c objBook = addBooking(enrolObj, type, status, bookingDate, TRUE, packageId, utilizedBookings); 
                        fifthLessons.Booking__r = objBook;
                        objBook.Enrolment__c = fifthLessons.Enrolment__c;
                        bookingFifthList.add(objBook);

                        fifthLessonsToUpdate.add(fifthLessons);
                    }else{
                        System.debug('@@@@enrolObj Makeup Package Not Found'+enrolObj.Id);
                    }
                    
                }
                // end: added by nishi: 3-sep-2020: for check enrolment have makeup min greater then fifth lesson duration then we deduct makeup min
                // first we deduct makeup mins to teacher leave canceled booking then if makeup utlization mins is remaning then we get all canceled bookings
                else{

                    //Insert Adhoc booking
                    Invoice__c invoiceObj = new Invoice__c();
                    Invoice_Line_Item__c invoiceLineItemObj = new Invoice_Line_Item__c();
                    Payment__c paymentObj = new Payment__c();
                    //Create adhoc booking for that day
                    System.debug('@@@packageAdhocMap'+packageAdhocMap);
                    
                    if(packageAdhocMap.size() > 0){
                    
                        type = ConstantsClass.typeAdhoc;
                        status = ConstantsClass.statusScheduled;//ConstantsClass.statusScheduled;
                        utilizedBookings = '';

                        packageId = (packageAdhocMap.containsKey(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c)) ? packageAdhocMap.get(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c).Id : NULL;
                        if(String.isNotBlank(packageId)){
                            Booking__c objBook = addBooking(enrolObj, type, status, bookingDate, TRUE, packageId, utilizedBookings);
                            fifthLessons.Booking__r = objBook;
                            bookingFifthList.add(objBook);
                            fifthLessonsToUpdate.add(fifthLessons); 

                            //Insert Adhoc Due Invoices and its Line item
                            invoiceObj.Status__c = ConstantsClass.dueStatus;
                            invoiceObj.Due_Date__c = System.today();
                            invoiceObj.Invoice_Type__c = ConstantsClass.invoiceTypeAdhoc;
                            invoiceObj.Invoice_Date__c = System.today();
                            invoiceObj.Parent_Account__c = enrolObj.Parent__c;
                            invoiceObj.Center__c = enrolObj.Center__c;
                            invoicesObjList.add(invoiceObj);
                            
                            invoiceLineItemObj.invoice__r = invoiceObj;
                            decimal taxAmount = 0;
                            decimal amount = (packageAdhocMap.containsKey(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c))
                                                            ? packageAdhocMap.get(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c).unit_Fee__c : 0;
                            invoiceLineItemObj.Amount__c = BillingUtility.roundOffAmount(amount);
                            invoiceLineItemObj.package__c = packageId;
                            invoiceLineItemObj.Booking__r = objBook;
                            invoiceLineItemObj.Month__c = bookingDate;
                            if(countryTaxRate.size() > 0 && countryTaxRate.containsKey(fifthLessons.Enrolment__r.Center__r.Country__r.Id)
                            && amount > 0 && countryTaxRate.get(fifthLessons.Enrolment__r.Center__r.Country__r.Id) > 0){
                                taxAmount = BillingUtility.roundOffAmount(amount * (countryTaxRate.get(fifthLessons.Enrolment__r.Center__r.Country__r.Id) / 100));
                            }
                            invoiceLineItemObj.GST_Amount__c = taxAmount;
                            invoiceLineItemsList.add(invoiceLineItemObj);
                        }else{
                            System.debug('@@@@enrolObj Adhoc Package Not Found'+enrolObj.Id);
                        }                
                        

                        /*paymentObj.Invoice__r = invoiceObj;
                        paymentObj.Payment_Date__c = System.today();
                        paymentObj.Parent_Account__c = enrolObj.Parent__c;
                        paymentObj.Payment_Amount__c = (packageAdhocMap.containsKey(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c)) ? packageAdhocMap.get(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c).unit_Fee__c : 0;
                        paymentObj.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                        paymentList.add(paymentObj);*/
                    }
                }/*else{
                    Decimal total; Decimal gst = 0;
                    type = ConstantsClass.typeAdhoc;
                    status = ConstantsClass.scheduledStatus;
                    
                    utilizedBookings = '';
                    Booking__c objBook = addBooking(enrolObj, type, status, bookingDate, TRUE, packageId, utilizedBookings);
                    fifthLessons.Booking__r = objBook;
                    Package__c packageObj = new Package__c();
                    if(packageAdhocMap.containsKey(fifthLessons.Enrolment__r.Center__c + '-'+ fifthLessons.Enrolment__r.Package__r.Duration__c)){
                        packageObj = packageAdhocMap.get(fifthLessons.Enrolment__r.Center__c + '-'+ fifthLessons.Enrolment__r.Package__r.Duration__c);
                        packageId = (packageAdhocMap.containsKey(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c)) ? packageAdhocMap.get(enrolObj.Center__c+'-'+enrolObj.Package__r.Duration__c).Id : NULL;
                        invoiceObj = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                        Invoice_Date__c =system.today(), Parent_Account__c = fifthLessons.Parent__c, Center__c = fifthLessons.Center__c);

                        if(String.isNotBlank(packageObj.Id)){
                            total = packageObj.unit_Fee__c;
                        }

                        if(String.isNotBlank(countryObj.Id) && countryObj.Tax_Rate__c > 0){
                            gst = total * (countryObj.Tax_Rate__c / 100);
                            total += gst;
                        }
                        if(total > 0){
                            total = BillingUtility.roundOffAmount(total);
                        }   
                        if(invoiceObj != NULL && total > 0 && String.isNotBlank(stripe) && String.isNotBlank(countryObj.Id)){
                            BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
                            objStripeCharge = BillingUtility.createChargeForCustomer(stripe, total, countryObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c);
                            if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                                objBook = addBooking(enrolObj, type, status, bookingDate, TRUE, packageId, utilizedBookings); 
                                fifthLessons.Booking__r = objBook;
                                bookingFifthList.add(objBook);
                                fifthLessonsToUpdate.add(fifthLessons); 
                                invoicesObjList.add(invoiceObj);
                                lineItemObj.invoice__r = invoiceObj;
                                lineItemObj.Booking__r = objBook;
                                lineItemObj.Amount__c = total;
                                lineItemObj.package__c = packageId;
                                lineItemObj.month__c = System.today();
                                invoiceLineItemsList.add(lineItemObj);

                            }
                        }
                    }
                }*/
            }
        }


        //UPSERT Bookings 

        if(cancelBookingToUpdate.size() > 0){
            bookingFifthList.addAll(cancelBookingToUpdate.values());
        }
        if(bookingFifthList.size() > 0){
            UPSERT bookingFifthList;
        }

        //Update Fifth Lessons
        for(Fifth_Lesson__c fifthLesson : fifthLessonsToUpdate){
            fifthLesson.Booking__c = fifthLesson.Booking__r.Id;
            fifthLesson.isActive__c = FALSE;
            fifthLessonsFinalDML.add(fifthLesson);
        }
        if(fifthLessonsFinalDML.size() > 0){
            UPDATE fifthLessonsFinalDML;
        }
        system.debug('invoicesObjList'+invoicesObjList);
        //Insert Invoices
        if(invoicesObjList.size() > 0){
            INSERT invoicesObjList;
        }
        system.debug('paymentList'+paymentList);
        //Insert Payments
        for(Payment__c payObj : paymentList){
            payObj.Invoice__c = payObj.Invoice__r.Id;
            paymentListToInsert.add(payObj);
        }
        if(paymentListToInsert.size() > 0){
            INSERT paymentListToInsert;
        }
        system.debug('invoiceLineItemsList'+invoiceLineItemsList);
        //Insert Invoice Line Items...
        for(Invoice_Line_Item__c invoiceLineObj : invoiceLineItemsList){
            invoiceLineObj.invoice__c = invoiceLineObj.invoice__r.Id;
            invoiceLineObj.Booking__c = invoiceLineObj.Booking__r.Id;
            invoiceLineItemsListToInsert.add(invoiceLineObj);
        }
        system.debug('invoiceLineItemsList'+invoiceLineItemsList);
        if(invoiceLineItemsListToInsert.size() > 0){
            INSERT invoiceLineItemsListToInsert;
        }
    }

    private static Map<String,List<Booking__c>> getParentCancelBookings(List<Enrolment__c> enrolmentList){
        Map<String,List<Booking__c>> parentBookingMap = new Map<String,List<Booking__c>>();
        Set<String> setOfParentIds = new Set<String>(); // hold ids of parent which has available makeup minutes
        Set<String> setOfStuParentIds = new Set<String>(); // hold id of student and parent to fetch cancelled bookings.
        
        // fill set of parentIds from enrollment which has available makeup credits.
        for(Enrolment__c enroll : enrolmentList){
            if(String.isNotBlank(enroll.Student__c) && String.isNotBlank(enroll.Parent__c) && enroll.Parent__r.Available_Make_up_Units__c > 0){
                setOfParentIds.add(enroll.Parent__c); 
            }
        }
        
        // fill the set of student and parent for which we fetch bookings.
        if(setOfParentIds.size() > 0){
            for( Account objAcc : [SELECT Id, also_A_Student__c FROM Account WHERE Id IN: setOfParentIds OR Parent__c IN: setOfParentIds]){
                setOfStuParentIds.add(objAcc.Id);
            }
        }
        
         if(setOfStuParentIds.size() > 0){
            for(Booking__c booking : [SELECT  Id,Student__c,Parent__c,Available_Make_up_Units__c,Enrolment__c,Enrolment__r.Package__r.Duration__c FROM Booking__c 
                                      WHERE status__c =: ConstantsClass.statusCanceled  AND Student__c IN :setOfStuParentIds AND Make_up_Expiry_Date__c > today
                                      AND Available_Make_up_Units__c != Null ORDER BY Make_up_Expiry_Date__c asc  ] ){
                                              
                String parentId = String.isNotBlank(booking.Parent__c) ?booking.Parent__c : booking.Student__c;
                if(String.isNotBlank(parentId)){
                    List<Booking__c> bookingList = parentBookingMap.containsKey(parentId) ? parentBookingMap.get(parentId) : new List<Booking__c>();
                    bookingList.add(booking);
                    parentBookingMap.put(parentId, bookingList);
                }
            }
        }
        System.debug('@@@parentBookingMap'+parentBookingMap);
        return parentBookingMap;
    }

    //Fetch All Adhoc Type Packages of desired centres and durations
    public static Map<String, Package__c> getAdhocPackages(Set<String> centreIds, Set<String> durations){
        Map<String, Package__c> mapOfAdhocPackage = new Map<String, Package__c>();
        if(centreIds.size() > 0 && durations.size() > 0){
            for(Package__c packageObj : [SELECT Id, Location__c, Duration__c, unit_Fee__c FROM Package__c 
                                         WHERE Active__c = TRUE AND Type__c = 'Adhoc' AND Location__c IN :centreIds AND 
                                         Duration__c IN :durations]){
                mapOfAdhocPackage.put(packageObj.Location__c + '-' + packageObj.Duration__c, packageObj);
            } 
        }
        return mapOfAdhocPackage;
    }

    //Fetch all Aureus Teachers Working Hours
    Private Static Map<String, Teacher_Working_Hour__c> fetchWorkingHoursHome(){
        Map<String, Teacher_Working_Hour__c> mapOfTeacherHours = new Map<String, Teacher_Working_Hour__c>();
        for(Teacher_Working_Hour__c workingHour : [SELECT Id, Teacher_Name__c, Center_Name__c, Start_Time__c, End_Time__c, Working_Day__c
                                                    FROM Teacher_Working_Hour__c WHERE Active__c = TRUE AND Break_Time__c != TRUE 
                                                    AND Teacher_Name__c != NULL AND Center_Name__c =: Label.Aureus_at_Home_Id AND 
                                                    Start_Time__c != NULL AND End_Time__c != NULL]){
            mapOfTeacherHours.put(workingHour.Teacher_Name__c+'-'+workingHour.Working_Day__c, workingHour);
        }
        return mapOfTeacherHours;
    }

    //Create Case for enrolment process and Reschedule all process
    public static List<Case> createCase(List<Booking__c> bookingObjList){
        List<Case> caseList = new List<Case>();
     
        for(Booking__c objBooking: bookingObjList){  
            Case currentCase = new Case();
            currentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.caseServiceEnqRecTypeName).getRecordTypeId();
            currentCase.Booking__c = objBooking.Id;
            currentCase.Enrolment__c = objBooking.Enrolment__c;            
            currentCase.Student_Name__c = objBooking.Student__c;
            currentCase.Centre_Name__c = objBooking.Center__c;
            currentCase.Location__c = objBooking.Center__r.Location__c;            
            currentCase.Status =  ConstantsClass.caseOpenStatus;  // ConstantsClass.casePendingStatus;
            currentCase.Type = ConstantsClass.cancelType;            
            currentCase.Leave_Start_Date__c = objBooking.Booking_Date__c;
            currentCase.Priority = 'Medium';    
            
            if(String.isNotBlank(objBooking.Student__r.Parent__c)){
                currentCase.ContactId = objBooking.Student__r.Parent__r.PersonContactId;
                currentCase.AccountId = objBooking.Student__r.Parent__c;
            }else if(String.isNotBlank(objBooking.Student__c) && String.isBlank(objBooking.Student__r.Parent__c)){
                currentCase.ContactId = objBooking.Student__r.PersonContactId;
                currentCase.AccountId = objBooking.Student__c;
            }
            caseList.add(currentCase);
        }
        return caseList;
    }


    //Send Email to the customer for Public Holiday and Teacher Leave
    @future
    public static void sendCaseEmail(Set<Id> caseIds){
        // template when teacher is on Holiday
        
        Map<String,Id> templateMap = new Map<String,Id>();
        for(EmailTemplate et: [Select Id,Name,DeveloperName from EmailTemplate where (DeveloperName  = 'Teacher_Leave_Enrolment' OR 
                                                                                      DeveloperName  = 'Holiday_Enrolment_Open' OR 
                                                                                      DeveloperName  = 'Holiday_Enrolment_Closed')]){
        	templateMap.put(et.DeveloperName, et.Id);
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Case CasObject:[select Id,Booking__r.Type__c,Booking__r.Status__c,Booking__r.Cancellation_Reason__c, Booking__r.Public_Holiday_Status__c,
                            	   Booking__r.Start_Time__c,Booking__r.Parent__r.PersonContactId,Booking__r.Parent__r.personEmail,Booking__r.Center__c,
                                   Booking__r.Center__r.Location__c,Booking__r.Teacher_Account__c 
                            FROM Case WHERE Id IN:caseIds]){
             
            String templateId;
            if(CasObject.Booking__r.Cancellation_Reason__c.equalsIgnoreCase('Teacher Mc') && templateMap.containsKey('Teacher_Leave_Enrolment')){
                templateId = templateMap.get('Teacher_Leave_Enrolment');
            }else if(CasObject.Booking__r.Cancellation_Reason__c.equalsIgnoreCase('Holidays') && String.isNotBlank(CasObject.Booking__r.Public_Holiday_Status__c)){
                if(CasObject.Booking__r.Public_Holiday_Status__c.equalsIgnoreCase('Open') && templateMap.containsKey('Holiday_Enrolment_Open'))
                	templateId = templateMap.get('Holiday_Enrolment_Open');
                else if(CasObject.Booking__r.Public_Holiday_Status__c.equalsIgnoreCase('Closed') && templateMap.containsKey('Holiday_Enrolment_Closed'))
                	templateId = templateMap.get('Holiday_Enrolment_Closed');
            }
            
            if(String.isNotBlank(templateId) && String.isNotBlank(CasObject.Booking__r.Parent__r.PersonEmail)){
                //personEmailList.add(CasObject.Booking__r.Parent__r.personEmail);
                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                //mail.setToAddresses(personEmailList);
                emailList.add(mail);
            }
        }
            system.debug('emailList'+emailList);
        if(!test.isRunningTest())
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }    
    }
    
    //@Juneid 26 Aug 2020, Method for organization wiseEmail Tempaltes
    Public static void sendOssiaCaseEmail(Set<Id> caseIds){
        // template when teacher is on Holiday
        
        Map<String,Id> templateMap = new Map<String,Id>();
        for(EmailTemplate et: [Select Id,Name,DeveloperName from EmailTemplate where (DeveloperName  = 'Ossia_Teacher_Leave_Enrolment' OR 
                                                                                      DeveloperName  = 'Ossia_Holiday_Enrolment_Open' OR 
                                                                                      DeveloperName  = 'Ossia_Holiday_Enrolment_Closed')]){
                                                                                          templateMap.put(et.DeveloperName, et.Id);
                                                                                      }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Case CasObject:[select Id,Booking__r.Type__c,Booking__r.Status__c,Booking__r.Cancellation_Reason__c, Booking__r.Public_Holiday_Status__c,
                            Booking__r.Start_Time__c,Booking__r.Parent__r.PersonContactId,Booking__r.Parent__r.personEmail,Booking__r.Center__c,
                            Booking__r.Center__r.Location__c,Booking__r.Teacher_Account__c 
                            FROM Case WHERE Id IN:caseIds]){
                                
                                String templateId;
                                if(CasObject.Booking__r.Cancellation_Reason__c.equalsIgnoreCase('Teacher Mc') && templateMap.containsKey('Ossia_Teacher_Leave_Enrolment')){
                                    templateId = templateMap.get('Ossia_Teacher_Leave_Enrolment');
                                }else if(CasObject.Booking__r.Cancellation_Reason__c.equalsIgnoreCase('Holidays') && String.isNotBlank(CasObject.Booking__r.Public_Holiday_Status__c)){
                                    if(CasObject.Booking__r.Public_Holiday_Status__c.equalsIgnoreCase('Open') && templateMap.containsKey('Ossia_Holiday_Enrolment_Open'))
                                        templateId = templateMap.get('Ossia_Holiday_Enrolment_Open');
                                    else if(CasObject.Booking__r.Public_Holiday_Status__c.equalsIgnoreCase('Closed') && templateMap.containsKey('Ossia_Holiday_Enrolment_Closed'))
                                        templateId = templateMap.get('Ossia_Holiday_Enrolment_Closed');
                                }
                                
                                if(String.isNotBlank(templateId) && String.isNotBlank(CasObject.Booking__r.Parent__r.PersonEmail)){
                                    //personEmailList.add(CasObject.Booking__r.Parent__r.personEmail);
                                    Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                                    //mail.setToAddresses(personEmailList);
                                    emailList.add(mail);
                                }
                            }
        system.debug('emailList'+emailList);
        if(!test.isRunningTest())
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }    
    }
    
    // Added By Ravi ...it return the six digit random code
    public static string getRandomSixDigit(){
        return String.valueOf(Math.round((Math.random() * (900000) + 100000)));
    }
    
}