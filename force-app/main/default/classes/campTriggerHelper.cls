/*
    Name    : campTriggerHelper 
   date: 29-Feb-2020
   author: jatin
   description : this triggerhelper for creating Placeholder for all camp teachers for the duration. This should be done once the camp is activated.
    
*/
public with sharing class campTriggerHelper {
    // 19-Feb-2020:create placeholer type booking for camp teachers
    public static void createCampTeachersPlaceholder(Map<string,Camp__c> mapOfCamp) {
        List<Booking__c> listOfCampTeachersPlaceholder = new List<Booking__c>();
        if(mapOfCamp != null && mapOfCamp.size() >= 0){
            
            List<Camp_Days__c> listOFCampDays =  [SELECT  Dates_Of_The_Camp__c,Camp_Start_Time__c,
                                                    Status__c, Camp_Name__c, Id, Name,
                                                    (select Camp_Teacher__c,End_Time__c,Start_time__c,Status__c,Camp_Day__c
                                                        FROM Camp_Day_Teachers__r
                                                        where Status__c =:ConstantsClass.campTeacherActiveStatus) 
                                                    FROM Camp_Days__c
                                                    WHERE Camp_Name__c in:mapOfCamp.keySet()
                                                    AND Status__c =: ConstantsClass.campDaysActiveStatus];
            if(listOFCampDays != null && listOFCampDays.size() > 0){
                set<string> campTeacherIds = new set<string>();
                Set<string> campDays = new set<string>();
                map<string,set<id>> mapOfCampTeacherDays = new map<string,set<id>>();
                map<id,Camp_Day_Teachers__c> mapOfCampTeachers = new  map<id,Camp_Day_Teachers__c>();
                for(Camp_Days__c campDayObj : listOFCampDays){
                    mapOfCampTeachers = new  map<id,Camp_Day_Teachers__c>();
                    //System.debug('!!campDayObj'+campDayObj);
                    if(campDayObj.Camp_Day_Teachers__r!= null && campDayObj.Camp_Day_Teachers__r.size() > 0){
                        mapOfCampTeachers = new  map<id,Camp_Day_Teachers__c>(campDayObj.Camp_Day_Teachers__r);
                        for(Camp_Day_Teachers__c campDayTeachersObj  : mapOfCampTeachers.values()){
                            campTeacherIds.Add(campDayTeachersObj.Camp_Teacher__c);
                        }
                    }
                    campDays.add(DateTime.newInstance(campDayObj.Dates_Of_The_Camp__c, campDayObj.Camp_Start_Time__c).format('E'));
                    mapOfCampTeacherDays.put(campDayObj.Camp_Name__c +'-'+campDayObj.Dates_Of_The_Camp__c,
                    mapOfCampTeachers.keySet());
                }  
                map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours = new map<string,list<Teacher_Working_Hour__c>>();
                if(campTeacherIds != null && campDays != null && campTeacherIds.size() > 0 && campDays.size() > 0) 
                        mapOfTeacherWorkingHours = CampClassUtilityController.getTeacherWorkingHoursList(campTeacherIds,campDays,''); 
                
                        
                for(Camp_Days__c objCampDays : listOFCampDays){
                   // system.debug('--objCampDays ----'+objCampDays.name);
                    //system.debug('--objCampDays.Camp_Day_Teachers__r ----'+objCampDays.Camp_Day_Teachers__r);
                    if(objCampDays.Camp_Day_Teachers__r!= null && objCampDays.Camp_Day_Teachers__r.size() > 0){
                        listOfCampTeachersPlaceholder.AddAll(createPlaceholderForCampClass(objCampDays.Camp_Day_Teachers__r,DateTime.newInstance(objCampDays.Dates_Of_The_Camp__c, objCampDays.Camp_Start_Time__c),
                                                            mapOfCamp.get(objCampDays.Camp_Name__c),mapOfTeacherWorkingHours,mapOfCampTeacherDays ));
                    }
                }
                if(listOfCampTeachersPlaceholder != null && listOfCampTeachersPlaceholder.size() >0){
                    insert listOfCampTeachersPlaceholder;
                }
                system.debug('listOfCampTeachersPlaceholder'+listOfCampTeachersPlaceholder);
            }
        }
    }

    // 19-Feb-2020:creating Placeholder for all camp teachers for the duration. This should be done once the camp is activated.
    Public static List<Booking__c> createPlaceholderForCampClass(List<Camp_Day_Teachers__c> campDayTeachersList,dateTime campDate,Camp__c objCamp,
                                                                    map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours,
                                                                    map<string,set<id>> mapOfCampTeacherDays ){
        Booking__c placeholderObj = new Booking__c();
        String campLessonRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.bookingRecordsTypeCampLesson).getRecordTypeId();    
                
        List<Booking__c> placeholderList = new List<Booking__c>();
        set<id> campDateTeacherIds = new set<id>();
        if(mapOfCampTeacherDays.containsKey(objCamp.Id+'-'+campDate.date())){
            campDateTeacherIds = mapOfCampTeacherDays.get(objCamp.Id+'-'+campDate.date());
        }
     //  system.debug('campDateTeacherIds'+campDateTeacherIds);
        for(Camp_Day_Teachers__c campDayTeachersObj : campDayTeachersList){
            //system.debug('campDateTeacherIds.contains(campDayTeachersObj.id)'+campDateTeacherIds.contains(campDayTeachersObj.id));
                if(campDateTeacherIds.contains(campDayTeachersObj.id)){
                  //  system.debug('mapOfTeacherWorkingHours.containsKey(campDayTeachersObj.Camp_Teacher__c)'+mapOfTeacherWorkingHours.containsKey(campDayTeachersObj.Camp_Teacher__c));
                    if(mapOfTeacherWorkingHours.containsKey(campDayTeachersObj.Camp_Teacher__c)){
                        string centerId = '';
                        for(Teacher_Working_Hour__c techWorkSchObj: mapOfTeacherWorkingHours.get(campDayTeachersObj.Camp_Teacher__c)){
                          //  system.debug('techWorkSchObj.Working_Day__c'+techWorkSchObj.Working_Day__c);
                           // system.debug('campDate.format(E)'+campDate.format('E'));
                            
                            if(techWorkSchObj.Working_Day__c.equalsIgnoreCase(campDate.format('E'))){
                                centerId = techWorkSchObj.Center_Name__c;
                            }
                            //system.debug('centerId'+centerId);
                        }
                        if(string.isNotBlank(centerId)){
                            placeholderObj = CampClassUtilityController.createCampBooking('','',campDate.date(),campDayTeachersObj.End_Time__c,campDayTeachersObj.Start_time__c,
                                                                                    centerId,'','',campDayTeachersObj.Camp_Day__c,
                                                                                    campDayTeachersObj.Camp_Teacher__c);
                            placeholderObj.Type__c = ConstantsClass.typeBusy;
                            placeholderObj.status__c = ConstantsClass.scheduledStatus;
                            placeholderObj.remarks__c = objCamp.Name + '.';
                            placeholderObj.recordTypeId = campLessonRecId;
                            placeholderObj.Category__c = ConstantsClass.bookingCategoryCamp;
                            placeholderList.add(placeholderObj);
                        }
                    }
                }
            }
        
        system.debug('placeholderList'+placeholderList);
        return placeholderList;
        
    }

    // 19-Feb-2020: delete all active camp teacher 'placeholder' type  bookings if camp is deleted or canceled
    public static void deleteCampTeachersPlaceholder(Map<string,Camp__c> mapOfCamp) {
        List<Booking__c> listOfCampTeachersPlaceholder = new List<Booking__c>();
        if(mapOfCamp != null && mapOfCamp.size() >= 0){
            set<string> teacherIds = new  set<string>();
            map<string,Set<String>> campDaysTeachers = new  map<string,Set<String>>();
            List<Camp_Days__c> listOFCampDays =  [SELECT  Dates_Of_The_Camp__c,
                                                    Status__c, Camp_Name__c, Id, Name,
                                                    (select Camp_Teacher__c,End_Time__c,Start_time__c,Status__c,Camp_Day__c
                                                        FROM Camp_Day_Teachers__r
                                                        where Status__c =:ConstantsClass.campTeacherActiveStatus) 
                                                    FROM Camp_Days__c
                                                    WHERE Camp_Name__c in:mapOfCamp.keySet()
                                                    AND Status__c =: ConstantsClass.campDaysActiveStatus];
                                                    system.debug('listOFCampDays'+listOFCampDays);
            if(listOFCampDays != null && listOFCampDays.size() > 0){
                for(Camp_Days__c objCampDays : listOFCampDays){
                    if(objCampDays.Camp_Day_Teachers__r!= null && objCampDays.Camp_Day_Teachers__r.size() > 0){
                        set<string> campTeacherIds  = new set<string>();
                        for(Camp_Day_Teachers__c campDayTeachersObj :objCampDays.Camp_Day_Teachers__r){
                            teacherIds.add(campDayTeachersObj.Camp_Teacher__c);
                            campTeacherIds.add(campDayTeachersObj.Camp_Teacher__c);
                        }
                        if(objCampDays.Dates_Of_The_Camp__c != null){
                            campDaysTeachers.put(objCampDays.id,campTeacherIds);
                        }
                    }
                }
                List<Booking__c> listOfDeleteBooking = new List<Booking__c>();
                //system.debug('teacherIds'+teacherIds);
               // system.debug('campDaysTeachers'+campDaysTeachers);
                // get placeholder type bookings and then we check camp days and related teacher is found then we deleted this bookings
                Map<string,List<Booking__c>> mapOfCampDayBooking = getCampDayPlaceholderBooking(teacherIds,campDaysTeachers.keySet(),mapOfCamp.keySet());
               // system.debug('mapOfCampDayBooking'+mapOfCampDayBooking);
                for(string campDayId : mapOfCampDayBooking.keySet()){
                    List<Booking__c> listOfBooking = mapOfCampDayBooking.get(campDayId);
                    for(Booking__c objBooking:listOfBooking){
                        if(campDaysTeachers.containsKey(objBooking.Camp_Days__c)){
                            set<string> campTeacherIds  = campDaysTeachers.get(objBooking.Camp_Days__c);
                            if(campTeacherIds.contains(objBooking.Teacher_Account__c)){
                                listOfDeleteBooking.add(objBooking);
                            }
                        }
                    }
                }
                system.debug('listOfDeleteBooking'+listOfDeleteBooking);
                if(listOfDeleteBooking != null && listOfDeleteBooking.size() >0){
                    delete listOfDeleteBooking;
                }
                
            }
        }
    }

    // 19-Feb-2020: for get camp days place holder bookings for related teacher and camp_days id 
    // return map of dates and related date wise bookings
    public static Map<string,List<Booking__c>> getCampDayPlaceholderBooking(set<string> teacherIds,Set<String> campDaysIds,set<string> campIds){
        Map<string,List<Booking__c>> mapOfCampDayBooking = new Map<string,List<Booking__c>>();
        List<Booking__c> listOfPlaceholderBooking = new List<Booking__c>();
        if(teacherIds != null && campDaysIds != null && campIds != null && campIds.size() > 0 && campDaysIds.size() > 0 &&  teacherIds.size() > 0 )
        for(Booking__c objBooking: [Select Id,Camp_Days__c,Booking_Date__c,Teacher_Account__c FROM Booking__c
                where Teacher_Account__c In : teacherIds
                AND  recordType.Name  =:ConstantsClass.bookingRecordsTypeCampLesson
                //AND Camp_Id__c In : campIds
                AND Camp_Days__c In : campDaysIds
                AND Type__c =: ConstantsClass.typeBusy
                AND status__c =: ConstantsClass.scheduledStatus
                AND Category__c =: ConstantsClass.bookingCategoryCamp]){
                    listOfPlaceholderBooking = new List<Booking__c>();
                    if(mapOfCampDayBooking.containsKey(objBooking.Camp_Days__c)){
                        listOfPlaceholderBooking = mapOfCampDayBooking.get(objBooking.Camp_Days__c);
                    }
                    listOfPlaceholderBooking.add(objBooking);
                    mapOfCampDayBooking.put(objBooking.Camp_Days__c,listOfPlaceholderBooking);
        }
        return mapOfCampDayBooking;
    }
}