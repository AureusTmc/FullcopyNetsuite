/*
    Name        :    MakeupEnrolmentBatchHelper
    Date        :    15-feb-2021
    Author      :    Nishi
    Description :    this helper class use in MakeupEnrolmentBatch,AutomatingMakeupEnrolmentCtrl
    test class:MakeupEnrolmentBatchtest
*/

public with sharing class MakeupEnrolmentBatchHelper {
    public static Map<string,MakeupAvailMinDetails> getMultipleTeacherWorkingHourTimeSlotList(set<string> setofCenterIds ,set<String> teacherIds,set<String> allWeekdays,
        list<string> listOfDuration,datetime enrolmentEffectiveDate,Boolean isMakeup){
            Map<string,MakeupAvailMinDetails> mapOfMakeupAvailMinDetails  = new Map<string,MakeupAvailMinDetails>();
            if( listOfDuration!= null && listOfDuration.size() > 0){
                 //Get working hours According to the centre, multiple  Teacher and week day
                mapOfMakeupAvailMinDetails = getAvailableTeacherWorkingTimeSlot(setofCenterIds, teacherIds,allWeekdays, listOfDuration,enrolmentEffectiveDate.date());
              //system.debug('@@@@mapOfMakeupAvailMinDetails after getAvailableTeacherWorkingTimeSlot --'+mapOfMakeupAvailMinDetails);
                if(mapOfMakeupAvailMinDetails != null && mapOfMakeupAvailMinDetails.size() > 0){
                    // get Bookings according to selected date 
                    Map<string,MakeupAvailMinDetails> mapOfScheduledBookingTimeSlots = getScheduledBookingTimeSlots(setofCenterIds, teacherIds, enrolmentEffectiveDate.date(), listOfDuration,isMakeup);
                 ////system.debug('@@@@availTimeslots after mapOfScheduledBookingTimeSlots --'+mapOfScheduledBookingTimeSlots);
                    //  remove booking records
                    if(mapOfScheduledBookingTimeSlots != null && mapOfScheduledBookingTimeSlots.size() >0){
                        mapOfMakeupAvailMinDetails = getTimeSlotsListRemoval(mapOfMakeupAvailMinDetails ,mapOfScheduledBookingTimeSlots,listOfDuration);
                    }
                    
                    Map<string,MakeupAvailMinDetails> mapOfGroupClassTimeSlots = fetchSelectedGroupClassTimeSlots(setofCenterIds, teacherIds,  enrolmentEffectiveDate.date(),listOfDuration,isMakeup);
                    if(mapOfGroupClassTimeSlots != null && mapOfGroupClassTimeSlots.size() >0){
                        mapOfMakeupAvailMinDetails = getTimeSlotsListRemoval(mapOfMakeupAvailMinDetails ,mapOfGroupClassTimeSlots,listOfDuration);
                    }

                 //system.debug('@@@@availTimeslots after remove slots --'+mapOfMakeupAvailMinDetails);
                    Map<string,MakeupAvailMinDetails> mapOfFifthBookingTimeSlots = getFifthBookingSlots(setofCenterIds, teacherIds,  enrolmentEffectiveDate.date(),listOfDuration);
                  //system.debug('@@@@availTimeslots after mapOfFifthBookingTimeSlots --'+mapOfFifthBookingTimeSlots);
                    //  remove Fifth booking records
                    if(mapOfFifthBookingTimeSlots != null && mapOfFifthBookingTimeSlots.size() > 0){
                        mapOfMakeupAvailMinDetails = getTimeSlotsListRemoval(mapOfMakeupAvailMinDetails ,mapOfFifthBookingTimeSlots ,listOfDuration);
                    }
                 //system.debug('@@@@availTimeslots after remove slots --'+mapOfMakeupAvailMinDetails);
            
                  // get unselected slots
                     Map<string,MakeupAvailMinDetails> mapOfUnOrderedTimeSlots = getUnOrderedTimeSlots(mapOfMakeupAvailMinDetails,listOfDuration); 
                   //system.debug('@@@@availTimeslots after mapOfUnOrderedTimeSlots --'+mapOfUnOrderedTimeSlots);
                    //  remove Fifth booking records
                    if(mapOfUnOrderedTimeSlots != null && mapOfUnOrderedTimeSlots.size() > 0){
                        mapOfMakeupAvailMinDetails = getTimeSlotsListRemoval(mapOfMakeupAvailMinDetails ,mapOfUnOrderedTimeSlots,listOfDuration );
                    }
               //system.debug('@@@@availTimeslots after remove slots --'+mapOfMakeupAvailMinDetails);
                }
            }
         return mapOfMakeupAvailMinDetails;
    }

    // 2-Mar-2021: Nishi : for add Fifthbooking time slots
    private static Map<string,MakeupAvailMinDetails> fetchSelectedGroupClassTimeSlots( set<string> setofCenterIds ,set<String> teacherIds,date bookingsDate,list<string> listOfDuration,Boolean isMakeup){
        Map<string,MakeupAvailMinDetails> mapOfFifthBookingTimeSlots = new Map<string,MakeupAvailMinDetails> ();
        List<Booking__c> fifthlessonList = getGroupClassBookingsOnSelectedDates(setofCenterIds, teacherIds, new Set<Date>{bookingsDate},isMakeup);
     //system.debug('@@@@getFifthBookingSlots fifthlessonList--> '+fifthlessonList);
        map<id,BookingDetails> fifthlessonDetailsmap= new map<id,BookingDetails>();
        if(fifthlessonList != null && fifthlessonList.size() > 0 ){
            //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
            for(Booking__c currentBook : fifthlessonList){
                string weekday = DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c).format('EEE');
             //system.debug('@@@weekday --'+weekday);
              fifthlessonDetailsmap.put(currentBook.id,new BookingDetails(currentBook.Center__c,currentBook.Teacher_Account__c,weekday,
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c))); 
            }
            mapOfFifthBookingTimeSlots = getAvailableTimeSlots(fifthlessonDetailsmap,listOfDuration,false);
        }
     //system.debug('@@@fifthbookingSlots --'+mapOfFifthBookingTimeSlots);
        return mapOfFifthBookingTimeSlots;
    }


    // @@Nishi:2-Mar-2021: for Group class type bookings query
    private static List<Booking__c> getGroupClassBookingsOnSelectedDates(Set<String> centerIds, Set<String> teacherIds, Set<Date> dates,Boolean isMakeup){
        String groupBookingRecordType = ConstantsClass.groupBookingRecordType;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.groupTypeBooking};
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};     
        Date dt, endDt;
        String busyType = ConstantsClass.typeBusy;
       
        String weekDay;
        String queryStr = 'SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c';
        queryStr += ' WHERE RecordType.Name =: groupBookingRecordType AND Start_Time__c != NULL AND End_Time__c != NULL AND Class__C != null ';
        if(centerIds != null && centerIds.size() > 0){
            queryStr += ' AND Center__c in: centerIds';
        }
        if(teacherIds != null && teacherIds.size() > 0){
            queryStr += ' AND Teacher_Account__c in: teacherIds';
        }
        if(isMakeup){
            queryStr += ' AND Booking_Date__c In: dates';
        }else{
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
            }
        }
        queryStr += ' AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType AND Category__c NOT IN: busyStatusSet))';
        //System.debug('@@@@queryStr'+queryStr);
        
        return Database.query(queryStr);
    }

    //Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days 
        //if any slot is blank then we send out an email notification to Parent for booking the timeslot
    public static Map<string,EnrolmentDetails> newMakeupBookingNotification(List<Enrolment__c>listOfEnrolment,datetime enrolmentEffectiveDate,Map<String,Booking__c> mapOfBookingEnrolmentIds){
        set<string> setofCenterIds = new set<string>();
        set<String> teacherIds = new set<String>();
        Map<string,EnrolmentDetails> mapOfEnrolmentDetails = new Map<string,EnrolmentDetails>();
        list<string> listOfTeacherWithDuration = new list<string>{'15','30'};
        for(Enrolment__c objEnrolment: listOfEnrolment){
           //system.debug('@ objEnrolment.Lesson_Start_time__c'+ objEnrolment.Lesson_Start_time__c);
           //system.debug('@ objEnrolment.Package__r.Duration__c'+ objEnrolment.Package__r.Duration__c);
            DateTime enrolmentstartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c);
            time endtime =  ((string.isNotBlank(objEnrolment.Package__c)  && objEnrolment.Package__r.Duration__c != null) ? 
                            objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)) :objEnrolment.Lesson_Start_time__c);
            DateTime enrolmentendTime = DateTime.newInstance(enrolmentEffectiveDate.date(),objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)) );
            if(mapOfBookingEnrolmentIds.containsKey(objEnrolment.id)){
                enrolmentstartTime = DateTime.newInstance(mapOfBookingEnrolmentIds.get(objEnrolment.id).Booking_Date__c,  mapOfBookingEnrolmentIds.get(objEnrolment.id).start_Time__c);
                enrolmentendTime = DateTime.newInstance(mapOfBookingEnrolmentIds.get(objEnrolment.id).Booking_Date__c,  mapOfBookingEnrolmentIds.get(objEnrolment.id).End_Time__c);
            }
            if(enrolmentstartTime != NULL && enrolmentendTime != NULL){
                setofCenterIds.add(objEnrolment.Center__c);
                teacherIds.add(objEnrolment.Teacher__c);
            }
           //system.debug('@objEnrolment'+objEnrolment.name);
        }
       //system.debug('@setofCenterIds'+setofCenterIds);
       //system.debug('@teacherIds'+teacherIds);
       //system.debug('@enrolmentEffectiveDate.format'+enrolmentEffectiveDate.format('EEE'));
       //system.debug('@enrolmentEffectiveDate'+enrolmentEffectiveDate);
        Map<string,MakeupAvailMinDetails> mapOfMakeupAvailMinDetails = getMultipleTeacherWorkingHourTimeSlotList(setofCenterIds ,teacherIds,new set<string>{enrolmentEffectiveDate.format('EEE')},listOfTeacherWithDuration,enrolmentEffectiveDate,true);
        //Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days 
        //if any slot is blank then we send out an email notification to Parent for booking the timeslot
        if(mapOfMakeupAvailMinDetails != null && mapOfMakeupAvailMinDetails.size() > 0){
           //system.debug('@mapOfMakeupAvailMinDetails'+mapOfMakeupAvailMinDetails);
            mapOfEnrolmentDetails = sendMakeupEnrolmentNotification(listOfEnrolment,mapOfMakeupAvailMinDetails,listOfTeacherWithDuration,enrolmentEffectiveDate,mapOfBookingEnrolmentIds);
        }
        return mapOfEnrolmentDetails;   
    }
    public static Map<string,EnrolmentDetails> sendMakeupEnrolmentNotification(List<Enrolment__c>listOfEnrolment,Map<string,MakeupAvailMinDetails> availTeacherTimeSlots,
    List<String> listOfDuration,datetime enrolmentEffectiveDate,Map<String,Booking__c> mapOfBookingEnrolmentIds){
       Map<string,EnrolmentDetails> mapOfEnrolmentDetails = new Map<string,EnrolmentDetails>();
       
        set<String> enrolmentRequiredTimeSlots = new set<String>();
        set<String> teacherAvailTimeSlots = new set<String>();
        MakeupAvailMinDetails objMakeupAvailMinDetails = new MakeupAvailMinDetails();
        TeacherDetails objAvailTeacherDetails = new TeacherDetails();
        map<string,set<string>> mapOfavailTimeslots = new map<string,set<string>>();
        map<string,set<string>> mapOfNewavailTimeslots = new map<string,set<string>>();
        for(Enrolment__c objEnrolment: listOfEnrolment){
            string  weekday = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c).format('EEE');
            teacherAvailTimeSlots = new set<String>();
            for(string duration : listOfDuration){
                DateTime enrolmentAddedStartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c).addMinutes(-integer.valueOf(duration));//-30
                DateTime enrolmentAddedEndTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)));//.addMinutes(15);
                DateTime enrolmentstartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c);
                DateTime enrolmentendTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)));
                if(mapOfBookingEnrolmentIds.containsKey(objEnrolment.id)){
                    enrolmentAddedStartTime = DateTime.newInstance(mapOfBookingEnrolmentIds.get(objEnrolment.id).Booking_Date__c,  mapOfBookingEnrolmentIds.get(objEnrolment.id).start_Time__c).addMinutes(-integer.valueOf(duration));
                    enrolmentAddedEndTime = DateTime.newInstance(mapOfBookingEnrolmentIds.get(objEnrolment.id).Booking_Date__c,  mapOfBookingEnrolmentIds.get(objEnrolment.id).End_Time__c);
                    enrolmentstartTime = DateTime.newInstance(mapOfBookingEnrolmentIds.get(objEnrolment.id).Booking_Date__c,  mapOfBookingEnrolmentIds.get(objEnrolment.id).start_Time__c);
                    enrolmentendTime = DateTime.newInstance(mapOfBookingEnrolmentIds.get(objEnrolment.id).Booking_Date__c,  mapOfBookingEnrolmentIds.get(objEnrolment.id).End_Time__c);
                }
                if(enrolmentstartTime != NULL && enrolmentendTime != NULL && enrolmentAddedStartTime != NULL && enrolmentAddedEndTime != NULL){
                    enrolmentRequiredTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentAddedStartTime, enrolmentAddedEndTime);
                    List<String> enrolmentRealTimeSlots = new List<string>(MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentstartTime, enrolmentendTime));
               //system.debug('@enrolmentRequiredTimeSlots'+enrolmentRequiredTimeSlots);
               //system.debug('@enrolmentRealTimeSlots'+enrolmentRealTimeSlots);
                    for(Integer counterSlots=0;counterSlots < (enrolmentRealTimeSlots.size()-1);counterSlots++){
                        enrolmentRequiredTimeSlots.remove(enrolmentRealTimeSlots[0]);
                    }
                //  enrolmentRequiredTimeSlots.removeAll(enrolmentRealTimeSlots);
               //system.debug('@enrolmentRequiredTimeSlots'+enrolmentRequiredTimeSlots);
                   //system.debug('@objEnrolment.Bookings__r'+objEnrolment.Bookings__r);
               //system.debug('@##objEnrolment.name'+objEnrolment.name);
                    if(enrolmentRequiredTimeSlots != null && enrolmentRequiredTimeSlots.size() > 0 && objEnrolment.Bookings__r != null && objEnrolment.Bookings__r.size() > 0 
                    && availTeacherTimeSlots.containsKey(objEnrolment.Center__c)){
                        objMakeupAvailMinDetails = availTeacherTimeSlots.get(objEnrolment.Center__c);
                        if(objMakeupAvailMinDetails.mapOfTeachers != null && objMakeupAvailMinDetails.mapOfTeachers.size() > 0 
                            && objMakeupAvailMinDetails.mapOfTeachers.containsKey(objEnrolment.Teacher__c)){
                            objAvailTeacherDetails = objMakeupAvailMinDetails.mapOfTeachers.get(objEnrolment.Teacher__c);
                            if(  objAvailTeacherDetails.weekdaysWithDuration != null && objAvailTeacherDetails.weekdaysWithDuration.size() > 0){
                                for(WeekdaysDetails objAvailWeekdaysDetails: objAvailTeacherDetails.weekdaysWithDuration.values()){
                                    mapOfavailTimeslots = new map<string,set<string>>();
                                    //for(string duration :listOfDuration){
                                        if(mapOfEnrolmentDetails.containskey(objEnrolment.id)){
                                            EnrolmentDetails objEnrolmentDetails = mapOfEnrolmentDetails.get(objEnrolment.id);
                                            mapOfavailTimeslots =objEnrolmentDetails.mapOfavailTimeslots;
                                        }
                                        teacherAvailTimeSlots = objAvailWeekdaysDetails.mapOfavailTimeslots.get(duration);
                                        if(teacherAvailTimeSlots != null && teacherAvailTimeSlots.size() >0){
                                            Set<string> availabletime =new Set<string>() ;
                                            for(string enroltime : teacherAvailTimeSlots){
                                                if(enrolmentRequiredTimeSlots.contains(enroltime)){
                                                    availabletime.add(enroltime);
                                                }
                                            }
                                            if(availabletime != null && availabletime.size() > 0){
                                                mapOfavailTimeslots.put(duration,availabletime);
                                            }
                                        }
                                    //} 
                                }
                            }
                        }
                        if(mapOfavailTimeslots != null && mapOfavailTimeslots.size()> 0 ){
                            mapOfEnrolmentDetails.put(objEnrolment.id,new EnrolmentDetails(objEnrolment,mapOfavailTimeslots,enrolmentstartTime.format('dd, MMM')));
                        }
                    }
                }
            }
        }
        return mapOfEnrolmentDetails;
    }

    public static Map<string,EnrolmentDetails> sendPreferredEnrolmentNotification(List<Enrolment__c>listOfEnrolment,Map<string,MakeupAvailMinDetails> availTeacherTimeSlots,
    List<String> listOfDuration,datetime enrolmentEffectiveDate){
       Map<string,EnrolmentDetails> mapOfEnrolmentDetails = new Map<string,EnrolmentDetails>();
       
        set<String> enrolmentRequiredTimeSlots = new set<String>();
        set<String> teacherAvailTimeSlots = new set<String>();
        MakeupAvailMinDetails objMakeupAvailMinDetails = new MakeupAvailMinDetails();
        TeacherDetails objAvailTeacherDetails = new TeacherDetails();
        map<string,set<string>> mapOfavailTimeslots = new map<string,set<string>>();
        map<string,set<string>> mapOfNewavailTimeslots = new map<string,set<string>>();
        for(Enrolment__c objEnrolment: listOfEnrolment){
            string  weekday = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Preferred_Start_Time__c).format('EEE');
            teacherAvailTimeSlots = new set<String>();
            string duration =objEnrolment.Package__r.Duration__c;
            DateTime enrolmentAddedStartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Preferred_Start_Time__c);
            DateTime enrolmentAddedEndTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolment.Preferred_End_time__c);
            DateTime enrolmentstartTime = DateTime.newInstance(enrolmentEffectiveDate.date(), (objEnrolment.Lesson_Start_time__c != null ? objEnrolment.Lesson_Start_time__c :objEnrolment.Trial_Start_Time__c) );
            DateTime enrolmentendTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  (objEnrolment.Lesson_Start_time__c != null ? objEnrolment.Lesson_Start_time__c :objEnrolment.Trial_Start_Time__c).addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)));
            if(enrolmentstartTime != NULL && enrolmentendTime != NULL && enrolmentAddedStartTime != NULL && enrolmentAddedEndTime != NULL){
                enrolmentRequiredTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentAddedStartTime, enrolmentAddedEndTime);
                List<String> enrolmentRealTimeSlots = new List<string>(MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentstartTime, enrolmentendTime));
               //system.debug('@enrolmentRequiredTimeSlots'+enrolmentRequiredTimeSlots);
               //system.debug('@enrolmentRealTimeSlots'+enrolmentRealTimeSlots);
                for(Integer counterSlots=0;counterSlots < (enrolmentRealTimeSlots.size()-1);counterSlots++){
                    enrolmentRequiredTimeSlots.remove(enrolmentRealTimeSlots[0]);
                }
               //system.debug('@enrolmentRequiredTimeSlots'+enrolmentRequiredTimeSlots);
               //system.debug('@objEnrolment.Bookings__r'+objEnrolment.Bookings__r);
               //system.debug('@##objEnrolment.name'+objEnrolment.name);
                if(enrolmentRequiredTimeSlots != null && enrolmentRequiredTimeSlots.size() > 0 && availTeacherTimeSlots.containsKey(objEnrolment.Center__c)){
                    objMakeupAvailMinDetails = availTeacherTimeSlots.get(objEnrolment.Center__c);
                    if(objMakeupAvailMinDetails.mapOfTeachers != null && objMakeupAvailMinDetails.mapOfTeachers.size() > 0 
                        && objMakeupAvailMinDetails.mapOfTeachers.containsKey(objEnrolment.Preferred_Teacher__c)){
                        objAvailTeacherDetails = objMakeupAvailMinDetails.mapOfTeachers.get(objEnrolment.Preferred_Teacher__c);
                        if(  objAvailTeacherDetails.weekdaysWithDuration != null && objAvailTeacherDetails.weekdaysWithDuration.size() > 0){
                            for(WeekdaysDetails objAvailWeekdaysDetails: objAvailTeacherDetails.weekdaysWithDuration.values()){
                                mapOfavailTimeslots = new map<string,set<string>>();
                                    if(mapOfEnrolmentDetails.containskey(objEnrolment.id)){
                                        EnrolmentDetails objEnrolmentDetails = mapOfEnrolmentDetails.get(objEnrolment.id);
                                        mapOfavailTimeslots =objEnrolmentDetails.mapOfavailTimeslots;
                                    }
                                    teacherAvailTimeSlots = objAvailWeekdaysDetails.mapOfavailTimeslots.get(duration);
                                    if(teacherAvailTimeSlots != null && teacherAvailTimeSlots.size() >0){
                                        Set<string> availabletime =new Set<string>() ;
                                        for(string enroltime : teacherAvailTimeSlots){
                                            if(enrolmentRequiredTimeSlots.contains(enroltime)){
                                                availabletime.add(enroltime);
                                            }
                                        }
                                        if(availabletime != null && availabletime.size() > 0){
                                            mapOfavailTimeslots.put(duration,availabletime);
                                        }
                                    }
                            }
                        }
                    }
                    if(mapOfavailTimeslots != null && mapOfavailTimeslots.size()> 0 ){
                        mapOfEnrolmentDetails.put(objEnrolment.id,new EnrolmentDetails(objEnrolment,mapOfavailTimeslots,enrolmentstartTime.format('dd, MMM')));
                    }
                }
            }
            
        }
        return mapOfEnrolmentDetails;
    }
    public class EnrolmentDetails{
        public Enrolment__c objEnrolment{get;set;}
        public map<string,set<string>> mapOfavailTimeslots{get;set;}
        public string enrolmentDate{get;set;}
        public EnrolmentDetails(Enrolment__c objEnrolment,map<string,set<string>> mapOfavailTimeslots,string enrolmentDate){
            this.objEnrolment = new Enrolment__c();
            this.objEnrolment = objEnrolment;
            this.mapOfavailTimeslots = new map<string,set<string>>();
            this.mapOfavailTimeslots = mapOfavailTimeslots;
            this.enrolmentDate =enrolmentDate;
        }
    }
    private static Map<string,MakeupAvailMinDetails> getUnOrderedTimeSlots(Map<string,MakeupAvailMinDetails> mapOfMakeupAvailMinDetails,list<string> listOfDuration){
        Map<string,MakeupAvailMinDetails> mapOfUnOrderedTimeSlots = new Map<string,MakeupAvailMinDetails>();
        if( listOfDuration!= null &&  mapOfMakeupAvailMinDetails != null && mapOfMakeupAvailMinDetails.size() > 0 && listOfDuration.size() > 0){
            Map<string,WeekdaysDetails> availweekdaysWithDuration = new Map<string,WeekdaysDetails>();
            Map<string,TeacherDetails> mapOfAvailTeachers = new Map<string,TeacherDetails>();
            map<String,set<string>> mapOfavailTimeslots = new map<String,set<string>>();
            for(MakeupAvailMinDetails objMakeupAvailMinDetails: mapOfMakeupAvailMinDetails.values()){
                mapOfavailTimeslots = new map<String,set<string>>();
                mapOfAvailTeachers = new Map<string,TeacherDetails>();
                availweekdaysWithDuration = new Map<string,WeekdaysDetails>();
                if(objMakeupAvailMinDetails.mapOfTeachers != null && objMakeupAvailMinDetails.mapOfTeachers.size() > 0){
                    //mapOfAvailTeachers = objMakeupAvailMinDetails.mapOfTeachers;
                    for(TeacherDetails objAvailTeacherDetails: objMakeupAvailMinDetails.mapOfTeachers.values()){
                        if(  objAvailTeacherDetails.weekdaysWithDuration != null && objAvailTeacherDetails.weekdaysWithDuration.size() > 0){
                            //availweekdaysWithDuration = objAvailTeacherDetails.weekdaysWithDuration; 
                            for(WeekdaysDetails objAvailWeekdaysDetails: objAvailTeacherDetails.weekdaysWithDuration.values()){
                                //mapOfavailTimeslots = objAvailWeekdaysDetails.mapOfavailTimeslots;
                                for(string duration :listOfDuration){
                                    Set<String> availTimeslots = objAvailWeekdaysDetails.mapOfavailTimeslots.get(duration);
                                    if(availTimeslots != null && availTimeslots.size() >0){
                                        mapOfavailTimeslots.put(duration, removeUnselectableSlots(availTimeslots, duration));
                                    }
                                } 
                                if(mapOfavailTimeslots!= null && mapOfavailTimeslots.size() >0){
                                    availweekdaysWithDuration.put(objAvailWeekdaysDetails.weekdayname,new WeekdaysDetails(objAvailWeekdaysDetails.weekdayname, mapOfavailTimeslots));
                                }
                            }
                            if(availweekdaysWithDuration!= null && availweekdaysWithDuration.size() >0){
                                mapOfAvailTeachers.put(objAvailTeacherDetails.teacherId,new TeacherDetails(objAvailTeacherDetails.teacherId,availweekdaysWithDuration));
                            }
                        }
                    }
                    if(mapOfAvailTeachers!= null && mapOfAvailTeachers.size() >0){
                        mapOfUnOrderedTimeSlots.put(objMakeupAvailMinDetails.centerId,new MakeupAvailMinDetails(objMakeupAvailMinDetails.centerId,mapOfAvailTeachers)); 
                    }
                }
            }
        }
       //system.debug('@@@mapOfUnOrderedTimeSlots --'+mapOfUnOrderedTimeSlots);
       //system.debug('@@@mapOfMakeupAvailMinDetails --'+mapOfMakeupAvailMinDetails);
        return mapOfUnOrderedTimeSlots;
    }

     // remove Unselectable time Slots
     private static Set<String> removeUnselectableSlots(Set<String> setOfTimeSlot, String timeSlotDuration){
        Set<String> elementsToRemove = new Set<String>();
        DateTime currentDT;
        Boolean innerLoop = false;
        if(setOfTimeSlot != null && setOfTimeSlot.size() >0){
            List<string> timeSlots= new list<String>(setOfTimeSlot);
            integer duration = integer.valueOf(timeSlotDuration);
            for(integer i = 0; i< timeSlots.size(); i++){
                currentDT = getDateTimeFromString(timeSlots[i]);
                innerLoop = (i + duration / 15) > timeSlots.size() ? false : true;
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
        }
        return elementsToRemove;
    }

    //this function return Date time according to given AM PM formated Time
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

    //Get working hours According to the centre, multiple  Teacher and week day
    private static Map<string,MakeupAvailMinDetails> getAvailableTeacherWorkingTimeSlot(set<string> setofCenterIds ,set<String> teacherIds,set<String> allWeekdays,list<string> listOfDuration,date effectivedate){
        List<Teacher_Working_Hour__c> teachersHours = getMultipleTeachersWorkingHours(teacherIds,setofCenterIds, allWeekdays);
        Map<string,MakeupAvailMinDetails> mapOfMakeupAvailMinDetails = new Map<string,MakeupAvailMinDetails>();
     //system.debug('@@@allWeekdays --'+allWeekdays);
     //system.debug('@@@teachersHours --'+teachersHours);
        if( listOfDuration!= null&&  teachersHours != null && teachersHours.size() > 0 && listOfDuration.size() > 0){
            map<id,BookingDetails> teacherWorkinghrsDetailsmap = new map<id,BookingDetails>();
            for(Teacher_Working_Hour__c teachersHour :teachersHours){
                Long timeAvailable = gettimeAvailable(teachersHour.Start_Time__c, teachersHour.End_Time__c);
                // check Available time but is not common then we remove this days
               //system.debug('@@@teachersHour.Working_Day__c --'+teachersHour.Working_Day__c);
                teacherWorkinghrsDetailsmap.put(teachersHour.id,new BookingDetails(teachersHour.Center_Name__c,teachersHour.Teacher_Name__c,teachersHour.Working_Day__c,
                            DateTime.newInstance(effectivedate, teachersHour.Start_Time__c),DateTime.newInstance(effectivedate, teachersHour.End_Time__c),timeAvailable));
            }
            mapOfMakeupAvailMinDetails = getAvailableTimeSlots(teacherWorkinghrsDetailsmap,listOfDuration,true);
        }
     //system.debug('@@@getAvailableTeacherWorkingTimeSlot --'+mapOfMakeupAvailMinDetails);
        return mapOfMakeupAvailMinDetails;
    }

    // add schaduled booking time slots
    private static Map<string,MakeupAvailMinDetails> getScheduledBookingTimeSlots(set<string> setofCenterIds ,set<String> teacherIds,date bookingsDate,list<string> listOfDuration,Boolean isMakeup){
        Map<string,MakeupAvailMinDetails> mapOfScheduledBookingTimeSlots = new Map<string,MakeupAvailMinDetails> ();
        List<Booking__c> bookingList = getBookingsOnSelectedDates(new List<string>(setofCenterIds), new List<string>(teacherIds), new Set<Date>{bookingsDate}, isMakeup);
        map<id,BookingDetails> bookingDetailsmap = new map<id,BookingDetails>();
        if(bookingList != null && bookingList.size() > 0 ){
            //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
            for(Booking__c currentBook : bookingList){
                string weekday = DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c).format('EEE');
             //system.debug('@@@weekday --'+weekday);
              bookingDetailsmap.put(currentBook.id, new BookingDetails(currentBook.Center__c,currentBook.Teacher_Account__c,weekday,
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c),DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c)));  
            }
            mapOfScheduledBookingTimeSlots = getAvailableTimeSlots(bookingDetailsmap,listOfDuration,false);
        }
     //system.debug('@@@getScheduledBookingTimeSlots --'+mapOfScheduledBookingTimeSlots);
        return mapOfScheduledBookingTimeSlots;
    }

     // 14-Oct-2019: Nishi : for add Fifthbooking time slots
     private static Map<string,MakeupAvailMinDetails> getFifthBookingSlots( set<string> setofCenterIds ,set<String> teacherIds,date bookingsDate,list<string> listOfDuration){
        Map<string,MakeupAvailMinDetails> mapOfFifthBookingTimeSlots = new Map<string,MakeupAvailMinDetails> ();
        List<Fifth_Lesson__c> fifthlessonList = getBookingsOnFifthDates(setofCenterIds, teacherIds, new Set<Date>{bookingsDate});
     //system.debug('@@@@getFifthBookingSlots fifthlessonList--> '+fifthlessonList);
        map<id,BookingDetails> fifthlessonDetailsmap= new map<id,BookingDetails>();
        if(fifthlessonList != null && fifthlessonList.size() > 0 ){
            //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
            for(Fifth_Lesson__c currentBook : fifthlessonList){
                string weekday = DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c).format('EEE');
             //system.debug('@@@weekday --'+weekday);
              fifthlessonDetailsmap.put(currentBook.id,new BookingDetails(currentBook.Center__c,currentBook.Teacher_Account__c,weekday,
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c))); 
            }
            mapOfFifthBookingTimeSlots = getAvailableTimeSlots(fifthlessonDetailsmap,listOfDuration,false);
        }
     //system.debug('@@@fifthbookingSlots --'+mapOfFifthBookingTimeSlots);
        return mapOfFifthBookingTimeSlots;
    }

    private static  List<Fifth_Lesson__c> getBookingsOnFifthDates(set<String> centerIds, set<String> teacherIds, Set<Date> dates){
        return  [SELECT Id, Start_Time__c, End_Time__c, Teacher_Account__c, Booking_Date__c,Center__c FROM Fifth_Lesson__c WHERE IsActive__c = TRUE 
                                                     AND Teacher_Account__c in: teacherIds AND Center__c In: centerIds AND 
                                                     Booking_Date__c In :dates ];
   }
    

    private static Map<string,MakeupAvailMinDetails> getTimeSlotsListRemoval(Map<string,MakeupAvailMinDetails> mapOfavailCenterTimeslots, Map<string,MakeupAvailMinDetails> mapOfRemovalCenterTimeslots,
    list<string> listOfDuration){
        Set<String> bookingSlots = new Set<String>();
        Map<string,WeekdaysDetails> availweekdaysWithDuration = new Map<string,WeekdaysDetails>();
        Map<string,TeacherDetails> mapOfRemovalTeachers = new Map<string,TeacherDetails>();
        Map<string,TeacherDetails> mapOfAvailTeachers = new Map<string,TeacherDetails>();
        map<String,set<string>> mapOfavailTimeslots = new map<String,set<string>>();
        MakeupAvailMinDetails objMakeupAvailMinDetails = new MakeupAvailMinDetails();
        TeacherDetails objAvailTeacherDetails = new TeacherDetails();
        WeekdaysDetails objAvailWeekdaysDetails = new WeekdaysDetails();
        for(MakeupAvailMinDetails objRemovalAvailMinDetails: mapOfRemovalCenterTimeslots.values()){
            mapOfAvailTeachers = new Map<string,TeacherDetails>();
            availweekdaysWithDuration = new Map<string,WeekdaysDetails>();
            if(mapOfavailCenterTimeslots.containsKey(objRemovalAvailMinDetails.centerId)){
                objMakeupAvailMinDetails = mapOfavailCenterTimeslots.get(objRemovalAvailMinDetails.centerId);
                if(objRemovalAvailMinDetails.mapOfTeachers != null && objRemovalAvailMinDetails.mapOfTeachers.size() > 0 && objMakeupAvailMinDetails.mapOfTeachers != null && objMakeupAvailMinDetails.mapOfTeachers.size() > 0){
                    mapOfAvailTeachers = objMakeupAvailMinDetails.mapOfTeachers;
                    for(TeacherDetails objRemovalTeacherDetails: objRemovalAvailMinDetails.mapOfTeachers.values()){
                        if(mapOfAvailTeachers.containsKey(objRemovalTeacherDetails.teacherId)){
                            objAvailTeacherDetails = mapOfAvailTeachers.get(objRemovalTeacherDetails.teacherId); 
                            if(  objAvailTeacherDetails.weekdaysWithDuration != null && objAvailTeacherDetails.weekdaysWithDuration.size() > 0 &&
                                objRemovalTeacherDetails.weekdaysWithDuration != null && objRemovalTeacherDetails.weekdaysWithDuration.size() > 0){
                                availweekdaysWithDuration = objAvailTeacherDetails.weekdaysWithDuration; 
                                for(WeekdaysDetails objRemovalweekdays: objRemovalTeacherDetails.weekdaysWithDuration.values()){
                                    if(availweekdaysWithDuration.containsKey(objRemovalweekdays.weekdayname)){
                                        objAvailWeekdaysDetails = availweekdaysWithDuration.get(objRemovalweekdays.weekdayname);
                                        mapOfavailTimeslots = new map<String,set<string>>();
                                        //mapOfavailTimeslots = objAvailWeekdaysDetails.mapOfavailTimeslots;
                                     //system.debug('@mapOfavailTimeslots'+mapOfavailTimeslots);
                                     //system.debug('@objRemovalweekdays.mapOfavailTimeslots'+objRemovalweekdays.mapOfavailTimeslots);
                                        for(string duration :listOfDuration){
                                            Set<String> availdurationSet = new Set<String>();
                                            Set<String> removaldurationSet = new Set<String>();
                                         //system.debug('@duration'+duration);
                                            if(objAvailWeekdaysDetails.mapOfavailTimeslots.containsKey(duration)){
                                                removaldurationSet = objRemovalweekdays.mapOfavailTimeslots.get(duration);
                                                if(objAvailWeekdaysDetails.mapOfavailTimeslots != null && objAvailWeekdaysDetails.mapOfavailTimeslots.size() >0){
                                                    for(string slots :objAvailWeekdaysDetails.mapOfavailTimeslots.get(duration)){
                                                        if(!removaldurationSet.contains(slots)){
                                                            availdurationSet.add(slots);
                                                        }
                                                    }
                                                }
                                            }
                                            if(availdurationSet != null && availdurationSet.size() >0){
                                                mapOfavailTimeslots.put(duration, availdurationSet);
                                            }
                                        } 
                                        if(mapOfavailTimeslots != null && mapOfavailTimeslots.size() > 0){
                                            availweekdaysWithDuration.put(objRemovalweekdays.weekdayname,new WeekdaysDetails(objRemovalweekdays.weekdayname, mapOfavailTimeslots));
                                        }
                                    }
                                }
                                if(availweekdaysWithDuration != null && availweekdaysWithDuration.size() > 0){
                                    mapOfAvailTeachers.put(objRemovalTeacherDetails.teacherId,new TeacherDetails(objRemovalTeacherDetails.teacherId,availweekdaysWithDuration));
                                }
                            }

                        }
                    }
                    if(mapOfAvailTeachers != null && mapOfAvailTeachers.size() > 0){
                        mapOfavailCenterTimeslots.put(objRemovalAvailMinDetails.centerId,new MakeupAvailMinDetails(objRemovalAvailMinDetails.centerId,mapOfAvailTeachers)); 
                    }
                }
            }
        }
        return mapOfavailCenterTimeslots;
    }

    // add schaduled booking time slots
    private static Map<string,MakeupAvailMinDetails> getAvailableTimeSlots( map<id, BookingDetails> bookingList,list<string> listOfDuration,Boolean checkTeacherTimeAvailable){
        Map<string,MakeupAvailMinDetails> mapOfMakeupAvailMinDetails = new Map<string,MakeupAvailMinDetails>();
        if(listOfDuration!= null&&  bookingList != null && bookingList.size() > 0 && listOfDuration.size() > 0){
            Map<string,WeekdaysDetails> weekdaysWithDuration = new Map<string,WeekdaysDetails>();
            Map<string,TeacherDetails> mapOfTeachers = new Map<string,TeacherDetails>();
            Set<String> bookingSlots = new Set<String>();
            map<String,set<string>> mapOfavailTimeslots = new map<String,set<string>>();
            map<String,set<string>> mapOfavailTimeslotsDublicate = new map<String,set<string>>();
            MakeupAvailMinDetails objMakeupAvailMinDetails = new MakeupAvailMinDetails();
            TeacherDetails objTeacherDetails = new TeacherDetails();
            WeekdaysDetails objWeekdaysDetails = new WeekdaysDetails();
            //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
            for(string  bookingId : bookingList.keyset()){
                    BookingDetails currentBook = bookingList.get(bookingId);
                    bookingSlots = new Set<String>();
                    objMakeupAvailMinDetails = new MakeupAvailMinDetails();
                    mapOfTeachers = new Map<string,TeacherDetails>();
                    mapOfavailTimeslots = new map<String,set<string>>();
                    weekdaysWithDuration = new Map<string,WeekdaysDetails>();
                    mapOfavailTimeslotsDublicate = new map<String,set<string>>();
                    string weekday = currentBook.startTime.format('EEE');
                   if(mapOfMakeupAvailMinDetails.containsKey(currentBook.centerId)){
                        objMakeupAvailMinDetails = mapOfMakeupAvailMinDetails.get(currentBook.centerId);
                        if(objMakeupAvailMinDetails.mapOfTeachers != null && objMakeupAvailMinDetails.mapOfTeachers.size() > 0){
                            mapOfTeachers = objMakeupAvailMinDetails.mapOfTeachers;
                            if(mapOfTeachers.containsKey(currentBook.teacherid)){
                                objTeacherDetails = mapOfTeachers.get(currentBook.teacherid); 
                                if( objTeacherDetails.weekdaysWithDuration != null && objTeacherDetails.weekdaysWithDuration.size() > 0){
                                    weekdaysWithDuration = objTeacherDetails.weekdaysWithDuration;
                                    if(weekdaysWithDuration != null && weekdaysWithDuration.size() > 0){
                                        if(weekdaysWithDuration.containsKey(weekday)){
                                        objWeekdaysDetails =  weekdaysWithDuration.get(weekday);
                                        if(objWeekdaysDetails.mapOfavailTimeslots != null && objWeekdaysDetails.mapOfavailTimeslots.size() > 0 ){
                                            mapOfavailTimeslots = objWeekdaysDetails.mapOfavailTimeslots;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            
                bookingSlots.addAll(getFormatedTimeSlotListForBooking(currentBook.startTime, currentBook.endTime));
             //system.debug('@@@currentBook.startTime --'+currentBook.startTime);
             //system.debug('@@@currentBook.endTime --'+currentBook.endTime);
                if(bookingSlots != null && bookingSlots.size() > 0){
                    for(string duration : listOfDuration){
                        If(mapOfavailTimeslots.containsKey(duration)){
                            bookingSlots.addAll(mapOfavailTimeslots.get(duration));
                        }
                        if(checkTeacherTimeAvailable){
                            if(currentBook.duration >= Integer.valueOf(duration)){
                                mapOfavailTimeslots.put(duration,bookingSlots);
                            }
                        }else{
                            mapOfavailTimeslots.put(duration,bookingSlots);
                        }
                    } 
                    // for(string slots:bookingSlots){
                    //  //system.debug('@@@slots --'+slots);
                    // }
                 //system.debug('@@@mapOfavailTimeslots --'+mapOfavailTimeslots); 
                    if(mapOfavailTimeslots != null && mapOfavailTimeslots.size() > 0){
                        weekdaysWithDuration.put(weekday,new WeekdaysDetails(weekday, mapOfavailTimeslots));
                        mapOfTeachers.put(currentBook.teacherid,new TeacherDetails(currentBook.teacherid,weekdaysWithDuration));
                        mapOfMakeupAvailMinDetails.put(currentBook.centerId,new MakeupAvailMinDetails(currentBook.centerId,mapOfTeachers));   
                    }
                }
            }
        }
     //system.debug('@@@mapOfMakeupAvailMinDetails --'+mapOfMakeupAvailMinDetails);
        return mapOfMakeupAvailMinDetails;
    }

    private static List<Booking__c> getBookingsOnSelectedDates(List<String> centerIds, List<String> teacherIds, Set<Date> dates, Boolean isMakeup){
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.typeTrial, ConstantsClass.typeRegular, ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc};
        Date dt, endDt;
        String regularType = ConstantsClass.typeRegular;
        String busyType = ConstantsClass.typeBusy;
        String weekDay;
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};
        string placeholderCategory= ConstantsClass.bookingCategoryPlaceHolder;
        
        String queryStr = 'SELECT Id, Name, start_Time__c, Lesson_Type__c, Duration__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
        if(centerIds!= null && centerIds.size() > 0){
            queryStr += ' AND Center__c In: centerIds';
        }
        if(teacherIds!= null && teacherIds.size() > 0){
            queryStr += ' AND Teacher_Account__c in: teacherIds';
        }
        if(isMakeup){
            if(dates!= null && dates.size() > 0 ){
                queryStr += ' AND Booking_Date__c IN: dates ';
            }
            
        }else{
            if(dates!= null && dates.size() > 0 ){
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
        }
        queryStr += ' AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType  AND Category__c !=: placeholderCategory))';
        
     //system.debug('@!!!queryStr'+queryStr);
        return Database.query(queryStr);
    }

   

    
   

    private static List<String> getFormatedTimeSlotListForBooking(DateTime startTime, DateTime endTime){
        List<String> timeSlots = new List<String>();
        if(startTime < endTime){
            while(startTime < endTime){
                timeSlots.add(startTime.format('h:mm a'));
                startTime = startTime.addMinutes(15);
            }
        }
        return timeSlots;
    }
    private static List<Teacher_Working_Hour__c> getMultipleTeachersWorkingHours(set<String> teacherIds, set<String> centreId, set<String> weekDays){
        return [SELECT Id, Start_Time__c, End_Time__c,Teacher_Name__c,Center_Name__c,Working_Day__c FROM Teacher_Working_Hour__c 
                WHERE Center_Name__c In: centreId AND Teacher_Name__c in: teacherIds
                AND Working_Day__c In: weekDays AND Active__c = True AND Break_Time__c = False];
    }
    

     // we get templete according to Enrolment organisation
     public static Messaging.SingleEmailMessage getEmailInformation(Map<String,EmailTemplate> mapOfEmailTemplate,Enrolment__c objPreferredEnrolment,string templatename){
        Messaging.SingleEmailMessage objsendSingleEmailMessage = new Messaging.SingleEmailMessage();
        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
            string centerId,personContactId;
            if(objPreferredEnrolment.Parent__c != null && objPreferredEnrolment.Parent__r.Centre_Name__r != null &&
                string.isNotBlank(objPreferredEnrolment.Parent__r.Centre_Name__r.Location__c) ){
                centerId = objPreferredEnrolment.Parent__r.Centre_Name__r.Location__c;
            }
            if(objPreferredEnrolment.Parent__c != null && string.isNotBlank(objPreferredEnrolment.Parent__r.PersonContactId)){
                personContactId = objPreferredEnrolment.Parent__r.PersonContactId;
            }
            if(mapOfEmailTemplate.containsKey(templatename)){
                objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get(templatename).Id,personContactId,objPreferredEnrolment.id,centerId);
            }
        
        }
        return objsendSingleEmailMessage;
    }

    // we get templete according to Enrolment organisation
    public static Messaging.SingleEmailMessage getBookingEmailInformation(Map<String,EmailTemplate> mapOfEmailTemplate,Booking__c objBooking,string templatename){
        Messaging.SingleEmailMessage objsendSingleEmailMessage = new Messaging.SingleEmailMessage();
        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
            string centerId,personContactId;
            if(objBooking.Parent__c != null && objBooking.Parent__r.Centre_Name__r != null &&
                string.isNotBlank(objBooking.Parent__r.Centre_Name__r.Location__c) ){
                centerId = objBooking.Parent__r.Centre_Name__r.Location__c;
            }
            if(objBooking.Parent__c != null && string.isNotBlank(objBooking.Parent__r.PersonContactId)){
                personContactId = objBooking.Parent__r.PersonContactId;
            }
            if(mapOfEmailTemplate.containsKey(templatename)){
                objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get(templatename).Id,personContactId,objBooking.id,centerId);
            }
        
        }
        return objsendSingleEmailMessage;
    }
    // for reutrn available minutes according to starttime  and endtime
    public static long gettimeAvailable(Time Start_Time, Time End_Time){
        dateTime curst = DateTime.newInstance(Date.today(), Start_Time );
        dateTime endst = DateTime.newInstance(Date.today(),End_Time);
        Long timeAvailable = endst.getTime() - curst.getTime();
        timeAvailable /= 60000;
        return timeAvailable;
    }

    public static set<String> getFormatedTimeSlotList(DateTime startTime, DateTime endTime){
        set<String> timeSlots = new set<String>();
        if(startTime < endTime){
            while(startTime <= endTime){
                timeSlots.add(startTime.format('h:mm a'));
                startTime = startTime.addMinutes(15);
            }
        }
        return timeSlots;
    } 

    public static Mobile_Notification__c getMobileNotificationMsg(Enrolment__c objEnrolment,string availabletime,string bookingdate){
        String  title =  'Make-Up Credit Available before/after Your Bookings ';
        String  bodymsg = 'You will be use your make-up credits before/after you regular bookings. Make-up times are : '+availabletime + ' of ' + bookingdate ;
        bodymsg +='! Please use our app to book a make-up lesson and use your make-up credits. If you\'re having trouble finding any available times, contact our team as we are happy to help!';
        String to = objEnrolment.Parent__r.FCM_Token__c;
        return FirebaseNotificationHelper.sendNotificationBatch(objEnrolment.Parent__c, to, title, bodymsg);
        
    }
    
   

    public class MakeupAvailMinDetails{
        public string centerId{get;set;}
        public Map<string,TeacherDetails> mapOfTeachers{get;set;}
        public MakeupAvailMinDetails(string centerId,Map<string,TeacherDetails> mapOfTeachers){
            this.mapOfTeachers = new Map<string,TeacherDetails>(); 
            this.mapOfTeachers = mapOfTeachers;
            this.centerId = centerId;
        } 
        public MakeupAvailMinDetails(){
            this.mapOfTeachers = new Map<string,TeacherDetails>(); 
        }
    }

    public class TeacherDetails{
        public string teacherId{get;set;}
        public Map<string,WeekdaysDetails> weekdaysWithDuration{get;set;}
        public TeacherDetails(string teacherId,Map<string,WeekdaysDetails> weekdaysWithDuration){
            this.weekdaysWithDuration = new Map<string,WeekdaysDetails>();
            this.weekdaysWithDuration = weekdaysWithDuration;
            this.teacherId = teacherId;
        }
        public TeacherDetails(){
            this.weekdaysWithDuration = new Map<string,WeekdaysDetails>();
        }
    }

    public class WeekdaysDetails{
        public string weekdayname{get;set;}
        public map<string,set<string>> mapOfavailTimeslots{get;set;}
        public WeekdaysDetails(string weekdayname,map<string,set<string>> mapOfavailTimeslots){
            this.mapOfavailTimeslots =new map<string,set<string>>();
            this.mapOfavailTimeslots = mapOfavailTimeslots;
            this.weekdayname = weekdayname;
        }
        public WeekdaysDetails(){
            this.mapOfavailTimeslots =new map<string,set<string>>();
        }
    }

    public class BookingDetails{
        public string centerId;
        public string teacherid;
        public string weekday;
        public DateTime startTime;
        public DateTime endTime;
        public Long duration;
        public BookingDetails(string centerId,string teacherid,string weekday,DateTime startTime,DateTime endTime){
            this.centerId = centerId;
            this.teacherid = teacherid;
            this.weekday = weekday;
            this.startTime =startTime;
            this.endTime =endTime;
            this.duration =0;
        }
        public BookingDetails(string centerId,string teacherid,string weekday,DateTime startTime,DateTime endTime,Long duration){
            this.centerId = centerId;
            this.teacherid = teacherid;
            this.weekday = weekday;
            this.startTime =startTime;
            this.endTime =endTime;
            this.duration =duration;
        }
    }

    public static List<Enrolment__c> getEnrolmentlist(Set<string> enrolmentIds,datetime enrolmentEffectiveDate){
        decimal makeupcreditdays  =  decimal.valueOf(System.Label.Total_Make_up_Credits);
        string  organisation =System.Label.Ossia_Organisation_Name;
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled};
        Set<String> bookTypeSet = new Set<String>{ ConstantsClass.typeRegular};
        Set<Date> dates = new  Set<Date>{enrolmentEffectiveDate.date()};
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus}; 
        String enroledStage = ConstantsClass.enroledStatus;
        string weekday = enrolmentEffectiveDate.format('EEEE');
        string queryString = 'SELECT Id,Name,Student__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
            queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
            queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId,Parent__r.FCM_Token__c,';
            queryString+= ' (Select id from Bookings__r WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
            queryString += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND Type__c IN: bookTypeSet ), ';
            queryString += ' instrument__c  FROM Enrolment__c ';
            queryString+= ' WHERE Type__c In: enrolTypes ';
            queryString+= ' AND Stage__c =: enroledStage ';
            queryString+= ' AND Lesson_Day__c =: weekday ';
            queryString+= ' And (( Center__r.Organisation__r.Name =: organisation And Available_Make_up_mins__c  >: makeupcreditdays ) ';
            queryString+= ' Or ( Center__r.Organisation__r.Name !=: organisation And Parent__r.Available_Make_up_Units__c  >: makeupcreditdays ) )  ';
            if(enrolmentIds != null && enrolmentIds.size() > 0){
                queryString+= ' And Id=: enrolmentIds';
            }
        return Database.query(queryString);    
    }

    public static  Map<string,set<string>> getCenterQueueMap(){
        Map<string,set<string>> mapOfCenterQueueEmails = new Map<string,set<String>>();
        set<string> userIds = new set<string>();
        
        map<Id,User> mapOfUser= new map<Id,User>([select id,Email from user]);
        for(GroupMember objQueueSObject :   [SELECT UserOrGroupId, Group.developername
                                                FROM GroupMember 
                                                WHERE Group.Type = 'Queue']){
            userIds = new set<string>();
            if(mapOfCenterQueueEmails.containsKey(objQueueSObject.Group.developername)){
                userIds = mapOfCenterQueueEmails.get(objQueueSObject.Group.developername);
            }
            if(mapOfUser.containsKey(objQueueSObject.UserOrGroupId)){
                //userIds.add(mapOfUser.get(objQueueSObject.UserOrGroupId).Email);
                userIds.add(objQueueSObject.UserOrGroupId);
            }
            mapOfCenterQueueEmails.put(objQueueSObject.Group.developername,userIds);  
        }  
        return mapOfCenterQueueEmails;
    }
    public static void sendEmailToCenterQueueMember( map<string,string> centerIds){
        Map<string,set<string>> mapOfCenterQueue = getCenterQueueMap();
        Map<String, Manage_Queue__c> queueSetting = Manage_Queue__c.getAll();
       //system.debug('queueSetting'+queueSetting);
        List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
        Set<String> paymentFailedEmails=new Set<string>{'Ossia_Waitlist_Enrolment_Time_Available','Waitlist_Enrolment_Time_Available','Preferred_Enrolment_Time_Available'};
        Map<String,EmailTemplate> mapOfEmailTemplate = new Map<String,EmailTemplate>();
         // we get templete according to organisation
        
        for(EmailTemplate objEmailTemplate: [SELECT Id, Name,DeveloperName,Subject, HtmlValue  
                                            FROM EmailTemplate 
                                            WHERE DeveloperName In:paymentFailedEmails]){
                                                mapOfEmailTemplate.put(objEmailTemplate.DeveloperName,objEmailTemplate);
                                            }
        for(Account centerObj : [Select id,name,Organisation__r.Name,Location__c from Account where id In:centerIds.keySet()])  {
           //system.debug('queueSetting.containsKey(centerObj.name)'+queueSetting.containsKey(centerObj.name));
           //system.debug('queueSetting.containsKey(centerObj.name)'+mapOfCenterQueue);
            if(queueSetting.containsKey(centerObj.name) && string.isNotBlank(queueSetting.get(centerObj.name).Queue_Name__c) &&
             mapOfCenterQueue.containsKey(queueSetting.get(centerObj.name).Queue_Name__c)){
                List<String> sendTo = new List<String>();
                sendTo.addAll(mapOfCenterQueue.get(queueSetting.get(centerObj.name).Queue_Name__c));
               //system.debug('sendTo'+sendTo);
                string templatename='';
                // if(centerObj.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                //     templatename = 'Ossia_Waitlist_Enrolment_Time_Available';
                // }else{
                //     templatename = 'Waitlist_Enrolment_Time_Available';
                // }
                templatename = 'Preferred_Enrolment_Time_Available';
                if(mapOfEmailTemplate.containsKey(templatename) && sendTo != null && sendTo.size() > 0){
                    sendSingleEmailMessage.addAll(getSingleEmailMessage(mapOfEmailTemplate.get(templatename),sendTo,centerObj.id,centerObj.Location__c,centerIds.get(centerObj.id)));
                }
            }
        } 
        // Send the email you have created.
        if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
            Messaging.SendEmailResult[] result = Messaging.sendEmail(sendSingleEmailMessage);//false
            /*Set<Id> targetIdsFailed = new Set<Id>();
            for(Messaging.SendEmailResult resObj: result){
                if(!resObj.isSuccess()){
                    targetIdsFailed.add(resObj.getErrors()[0].getTargetObjectId());
                }
            }
           //system.debug('targetIdsFailed'+targetIdsFailed);*/
        }
    }
    public static List<Messaging.SingleEmailMessage> getSingleEmailMessage(EmailTemplate template,List<String> sendTo,String relatedId,String location,string whatId){
        Map<String,OrgWideEmailAddress> mapOfOrgWide = new  Map<String,OrgWideEmailAddress>();
        mapOfOrgWide  = new Map<String,OrgWideEmailAddress>();
        for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
            mapOfOrgWide.put(objAddress.DisplayName,objAddress);
        }
        List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
        for(string userId:sendTo){
            //system.debug('whatId'+whatId);
           //system.debug('relatedId'+relatedId);
            Messaging.SingleEmailMessage mail = new  Messaging.SingleEmailMessage(); 
            mail.setTemplateId(template.id);
            mail.setWhatId(relatedId);
            //mail.setToAddresses(sendTo);
            mail.setTargetObjectId(userId);//0056F00000BPHwM
            if(String.isNotBlank(location) && mapOfOrgWide.containsKey(location)){
                mail.setOrgWideEmailAddressId(mapOfOrgWide.get(location).Id);
            }
            mail.setSaveAsActivity(False);    
            sendSingleEmailMessage.add(mail);
        }
        return sendSingleEmailMessage;
    }
}