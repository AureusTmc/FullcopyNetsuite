/*
    Name    : CampDayTeacherTriggerHelper 
   date: 4-Mar-2020
   author: jatin
   description : this triggerhelper for creating Placeholder for all camp teachers for the duration. 
                    
    
*/
public with sharing class CampDayTeacherTriggerHelper {
    // 4-Mar-2020:create placeholer type booking for camp teachers if camp status is active then we are createing otherwise not
    public static void createCampTeachersPlaceholder(Map<string,Camp_Day_Teachers__c> mapOfActiveCampTeachers) {
        List<Booking__c> listOfCampTeachersPlaceholder = new List<Booking__c>();
        if(mapOfActiveCampTeachers != null && mapOfActiveCampTeachers.size() >= 0){
            
            List<Camp_Day_Teachers__c> listOFCampDaysTeachers =  [select Camp_Teacher__c,End_Time__c,Start_time__c,Status__c,Camp_Day__c,Camp_Day__r.Camp_Name__r.Name,
                                                                    Camp_Day__r.Camp_Name__c,Camp_Day__r.Dates_Of_The_Camp__c,Camp_Day__r.Camp_Start_Time__c
                                                                    FROM Camp_Day_Teachers__c
                                                                    where Id In: mapOfActiveCampTeachers.keySet()
                                                                    And Camp_Day__r.Camp_Name__r.Status__c =: ConstantsClass.campActiveStatus];
          //  system.debug('listOFCampDaysTeachers'+listOFCampDaysTeachers);
            if(listOFCampDaysTeachers != null && listOFCampDaysTeachers.size() > 0){
                set<string> campTeacherIds = new set<string>();
                Set<string> campDays = new set<string>();
                map<string,id> mapOfCampTeacherDays = new map<string,id>();
                map<id,Camp_Day_Teachers__c> mapOfCampTeachers = new  map<id,Camp_Day_Teachers__c>();
                for(Camp_Day_Teachers__c campDayTeacherObj : listOFCampDaysTeachers){
                    campTeacherIds.add(campDayTeacherObj.Camp_Teacher__c);
                    campDays.add(DateTime.newInstance(campDayTeacherObj.Camp_Day__r.Dates_Of_The_Camp__c, campDayTeacherObj.Camp_Day__r.Camp_Start_Time__c).format('E'));
                    mapOfCampTeacherDays.put(campDayTeacherObj.id +'-'+campDayTeacherObj.Camp_Day__r.Dates_Of_The_Camp__c,
                    campDayTeacherObj.Camp_Teacher__c);
                }  
                map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours = new map<string,list<Teacher_Working_Hour__c>>();
                if(campTeacherIds != null && campDays != null && campTeacherIds.size() > 0 && campDays.size() > 0) 
                        mapOfTeacherWorkingHours = CampClassUtilityController.getTeacherWorkingHoursList(campTeacherIds,campDays,''); 
                
                        
                for(Camp_Day_Teachers__c campDayTeacherObj : listOFCampDaysTeachers){
                        listOfCampTeachersPlaceholder.AddAll(createPlaceholderForCampDayTeacher(campDayTeacherObj,
                                                            DateTime.newInstance(campDayTeacherObj.Camp_Day__r.Dates_Of_The_Camp__c, campDayTeacherObj.Camp_Day__r.Camp_Start_Time__c),
                                                            mapOfTeacherWorkingHours,mapOfCampTeacherDays ));
                }
                if(listOfCampTeachersPlaceholder != null && listOfCampTeachersPlaceholder.size() >0){
                    insert listOfCampTeachersPlaceholder;
                }
               // system.debug('listOfCampTeachersPlaceholder'+listOfCampTeachersPlaceholder);
            }
        }
    }

    // 19-Feb-2020:creating Placeholder for all camp teachers for the duration. This should be done once the camp is activated.
    Public static List<Booking__c> createPlaceholderForCampDayTeacher(Camp_Day_Teachers__c campDayTeacherObj,dateTime campDate,
                                                                    map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours,
                                                                    map<string,id> mapOfCampTeacherDays ){
        Booking__c placeholderObj = new Booking__c();
        String campLessonRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.bookingRecordsTypeCampLesson).getRecordTypeId();    
                
        List<Booking__c> placeholderList = new List<Booking__c>();
        string campTeacherId ;
        if(mapOfCampTeacherDays.containsKey(campDayTeacherObj.Id+'-'+campDate.date())){
            campTeacherId = mapOfCampTeacherDays.get(campDayTeacherObj.Id+'-'+campDate.date());
        }
        //system.debug('campTeacherId'+campTeacherId);
        if(string.isNotBlank(campTeacherId)){
          //  system.debug('mapOfTeacherWorkingHours.containsKey(campDayTeacherObj.Camp_Teacher__c)'+mapOfTeacherWorkingHours.containsKey(campDayTeacherObj.Camp_Teacher__c));
            if(mapOfTeacherWorkingHours.containsKey(campDayTeacherObj.Camp_Teacher__c)){
                string centerId = '';
                //system.debug('mapOfTeacherWorkingHours.get(campDayTeacherObj.Camp_Teacher__c)'+mapOfTeacherWorkingHours.get(campDayTeacherObj.Camp_Teacher__c));
            
                for(Teacher_Working_Hour__c techWorkSchObj: mapOfTeacherWorkingHours.get(campDayTeacherObj.Camp_Teacher__c)){
                   // system.debug('techWorkSchObj.Working_Day__c'+techWorkSchObj.Working_Day__c);
                   // system.debug('campDate.format(E)'+campDate.format('E'));
                    
                    if(techWorkSchObj.Working_Day__c.equalsIgnoreCase(campDate.format('E'))){
                        centerId = techWorkSchObj.Center_Name__c;
                    }
                }
               // system.debug('centerId'+centerId);
                if(string.isNotBlank(centerId)){
                    placeholderObj = CampClassUtilityController.createCampBooking('','',campDate.date(),campDayTeacherObj.End_Time__c,campDayTeacherObj.Start_time__c,
                                                                            centerId,'',/*campDayTeacherObj.Camp_Day__r.Camp_Name__c*/'',campDayTeacherObj.Camp_Day__c,
                                                                            campDayTeacherObj.Camp_Teacher__c);
                    placeholderObj.Type__c = ConstantsClass.typeBusy;
                    placeholderObj.status__c = ConstantsClass.scheduledStatus;
                    placeholderObj.remarks__c = campDayTeacherObj.Camp_Day__r.Camp_Name__r.Name + '.';
                    placeholderObj.recordTypeId = campLessonRecId;
                    placeholderObj.Category__c = ConstantsClass.bookingCategoryCamp;
                    placeholderList.add(placeholderObj);
                }
            }
        }
            
        
       // system.debug('placeholderList'+placeholderList);
        return placeholderList;
        
    }

    // update camp placeholder bookings if camp day teacher not change status they change other fields 
    public static void UpdateCampTeachersPlaceholder(Map<string,Camp_Day_Teachers__c> mapOfUpdateNewCampTeacher,Map<string,Camp_Day_Teachers__c> mapOfUpdateOldCampTeacher){
        map<string,Set<String>> mapOfupdateOldCampDayTeacher = new  map<string,Set<String>>();
        set<string> campTeacherIds  = new set<string>();
        set<string> teacherIds = new  set<string>();
       // system.debug('!!mapOfUpdateNewCampTeacher'+mapOfUpdateNewCampTeacher);
        // system.debug('!!mapOfUpdateOldCampTeacher'+mapOfUpdateOldCampTeacher);
        Map<Id,Camp_Day_Teachers__c> mapOfNewCampDaysTeachers =  new Map<Id,Camp_Day_Teachers__c>([select Camp_Teacher__c,End_Time__c,Start_time__c,Status__c,Camp_Day__c,
                                                            Camp_Day__r.Camp_Name__c,Camp_Day__r.Dates_Of_The_Camp__c,Camp_Day__r.Camp_Start_Time__c
                                                            FROM Camp_Day_Teachers__c
                                                            where Id In:mapOfUpdateNewCampTeacher.keySet()
                                                            And Camp_Day__r.Camp_Name__r.Status__c =: ConstantsClass.campActiveStatus]);
        //system.debug('!!mapOfNewCampDaysTeachers'+mapOfNewCampDaysTeachers);
        //system.debug('mapOfUpdateOldCampTeacher'+mapOfUpdateOldCampTeacher);
        for(Camp_Day_Teachers__c objCampTeacher : mapOfUpdateOldCampTeacher.values()){ 
            if(mapOfupdateOldCampDayTeacher.containsKey(objCampTeacher.Camp_Day__c)){
                campTeacherIds = mapOfupdateOldCampDayTeacher.get(objCampTeacher.Camp_Day__c);
            }
            campTeacherIds.add(objCampTeacher.id);
            mapOfupdateOldCampDayTeacher.put(objCampTeacher.Camp_Day__c,campTeacherIds);
            teacherIds.add(objCampTeacher.Camp_Teacher__c);
        }
    //   system.debug('!!mapOfupdateOldCampDayTeacher'+mapOfupdateOldCampDayTeacher);
        if(mapOfupdateOldCampDayTeacher != null && mapOfupdateOldCampDayTeacher.size() >= 0){
            List<Booking__c> listOfPlaceholderBooking = getAllCampDayPlaceholderBooking(teacherIds,mapOfupdateOldCampDayTeacher.keySet());
           // system.debug('!!listOfPlaceholderBooking'+listOfPlaceholderBooking);
            if(listOfPlaceholderBooking != null && mapOfNewCampDaysTeachers != null && mapOfNewCampDaysTeachers.size() > 0 &&  listOfPlaceholderBooking.size() > 0){
                for(Booking__c objBooking:listOfPlaceholderBooking){
                    if(mapOfupdateOldCampDayTeacher.containsKey(objBooking.Camp_Days__c)){
                        for(string campDayTeacherId : mapOfupdateOldCampDayTeacher.get(objBooking.Camp_Days__c)){
                            if(mapOfNewCampDaysTeachers.containsKey(campDayTeacherId)){
                                if(mapOfNewCampDaysTeachers.get(campDayTeacherId).Start_time__c != null)
                                    objBooking.Start_Time__c = mapOfNewCampDaysTeachers.get(campDayTeacherId).Start_time__c;   
                                if(mapOfNewCampDaysTeachers.get(campDayTeacherId).End_Time__c != null)
                                    objBooking.End_Time__c = mapOfNewCampDaysTeachers.get(campDayTeacherId).End_Time__c;
                                if(mapOfNewCampDaysTeachers.get(campDayTeacherId).Camp_Day__r.Dates_Of_The_Camp__c != null)
                                    objBooking.Booking_Date__c = mapOfNewCampDaysTeachers.get(campDayTeacherId).Camp_Day__r.Dates_Of_The_Camp__c; 
                                if(string.isNotBlank(mapOfNewCampDaysTeachers.get(campDayTeacherId).Camp_Day__c))
                                    objBooking.Camp_Days__c = mapOfNewCampDaysTeachers.get(campDayTeacherId).Camp_Day__c;
                                /*if(string.isNotBlank(mapOfNewCampDaysTeachers.get(campDayTeacherId).Camp_Day__r.Camp_Name__c))
                                    objBooking.Camp_Id__c = mapOfNewCampDaysTeachers.get(campDayTeacherId).Camp_Day__r.Camp_Name__c; */
                            }
                        }
                    }
                }
            }
           // system.debug('!!listOfPlaceholderBooking'+listOfPlaceholderBooking);
            if(listOfPlaceholderBooking != null && listOfPlaceholderBooking.size() >0){
                update listOfPlaceholderBooking;
            }
        }
    }
    // 4-mar-2020: delete all active camp teacher 'placeholder' type  bookings if campteacher  is deleted or change status 
    public static void deleteCampTeachersPlaceholder(map<string,Set<String>> mapOfCancelledCampTeacher) {
        List<Booking__c> listOfCampTeachersPlaceholder = new List<Booking__c>();
        //system.debug('mapOfCancelledCampTeacher'+mapOfCancelledCampTeacher);
        if(mapOfCancelledCampTeacher != null && mapOfCancelledCampTeacher.size() >= 0){
            set<string> teacherIds = new  set<string>();
            for(string campDayId :  mapOfCancelledCampTeacher.keySet()){
                teacherIds.addAll(mapOfCancelledCampTeacher.get(campDayId));
            }
            List<Booking__c> listOfDeleteBooking = new List<Booking__c>();
           // system.debug('teacherIds'+teacherIds);
            //system.debug('mapOfCancelledCampTeacher'+mapOfCancelledCampTeacher);
            // get placeholder type bookings and then we check camp days and related teacher is found then we deleted this bookings
            Map<string,List<Booking__c>> mapOfCampDayBooking = getCampDayPlaceholderBooking(teacherIds,mapOfCancelledCampTeacher.keySet());
           // system.debug('mapOfCampDayBooking'+mapOfCampDayBooking);
            if(mapOfCampDayBooking != null && mapOfCampDayBooking.size() > 0){
                for(string campDayId : mapOfCampDayBooking.keySet()){
                    List<Booking__c> listOfBooking = mapOfCampDayBooking.get(campDayId);
                    for(Booking__c objBooking:listOfBooking){
                        if(mapOfCancelledCampTeacher.containsKey(objBooking.Camp_Days__c)){
                            set<string> campTeacherIds  = mapOfCancelledCampTeacher.get(objBooking.Camp_Days__c);
                            if(campTeacherIds.contains(objBooking.Teacher_Account__c)){
                                listOfDeleteBooking.add(objBooking);
                            }
                        }
                    }
                }
            }
          //  system.debug('listOfDeleteBooking'+listOfDeleteBooking);
            if(listOfDeleteBooking != null && listOfDeleteBooking.size() >0){
                delete listOfDeleteBooking;
            }
                
        }
    }
// 4-mar-2020: for get camp days place holder bookings for related teacher and camp_days id 
    // return map of dates and related date wise bookings
    public static List<Booking__c> getAllCampDayPlaceholderBooking(set<string> teacherIds,Set<String> campDaysIds){
        List<Booking__c> listOfPlaceholderBooking = new List<Booking__c>();
        if(teacherIds != null && campDaysIds != null && campDaysIds.size() > 0 &&  teacherIds.size() > 0 ){
         listOfPlaceholderBooking  = [Select Id,Camp_Days__c,Booking_Date__c,Teacher_Account__c FROM Booking__c
                where Teacher_Account__c In : teacherIds
                AND  recordType.Name  =:ConstantsClass.bookingRecordsTypeCampLesson
                AND Camp_Days__c In : campDaysIds
                AND Camp_Days__r.Camp_Name__r.Status__c =: ConstantsClass.campActiveStatus
                AND Type__c =: ConstantsClass.typeBusy
                AND status__c =: ConstantsClass.scheduledStatus
                AND Category__c =: ConstantsClass.bookingCategoryCamp];
            return listOfPlaceholderBooking;
        }
        return listOfPlaceholderBooking;
    }
    // 4-mar-2020: for get camp days place holder bookings for related teacher and camp_days id 
    // return map of dates and related date wise bookings
    public static Map<string,List<Booking__c>> getCampDayPlaceholderBooking(set<string> teacherIds,Set<String> campDaysIds){
       
        Map<string,List<Booking__c>> mapOfCampDayBooking = new Map<string,List<Booking__c>>();
        List<Booking__c> listOfPlaceholderBooking = new List<Booking__c>();
        if(teacherIds != null && campDaysIds != null && campDaysIds.size() > 0 &&  teacherIds.size() > 0 ){
            List<Booking__c> listOfAllCampDayPlaceholderBooking =  getAllCampDayPlaceholderBooking(teacherIds,campDaysIds);
            if(listOfAllCampDayPlaceholderBooking != null && listOfAllCampDayPlaceholderBooking.size() > 0){
                for(Booking__c objBooking: listOfAllCampDayPlaceholderBooking){
                    listOfPlaceholderBooking = new List<Booking__c>();
                    if(mapOfCampDayBooking.containsKey(objBooking.Camp_Days__c)){
                        listOfPlaceholderBooking = mapOfCampDayBooking.get(objBooking.Camp_Days__c);
                    }
                    listOfPlaceholderBooking.add(objBooking);
                    mapOfCampDayBooking.put(objBooking.Camp_Days__c,listOfPlaceholderBooking);
                }
            }
        }   
       // system.debug('mapOfCampDayBooking'+mapOfCampDayBooking);
        return mapOfCampDayBooking;
    }

}