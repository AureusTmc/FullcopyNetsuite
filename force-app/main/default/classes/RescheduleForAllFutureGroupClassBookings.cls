/*
Name        :        RescheduleForAllFutureGroupClassBookings
Date        :        2020/09/11       
Description :        This class will take care of Reschedule all group class Bookings Functionality. It will Work on the Following basis
                        	If 5th lesson object & Reschedule All

                            o	Remove all future 5th lesson group classbookings
                            o	And create a fresh 5th lesson group class bookings based on the new timeslot
                        
                           if reschadule group class then we update related all enrolments 

                        	If makeup/adhoc/placeholder & Reschedule All group lesson on different day

                            o	Create a fresh 5th group class lesson record based on the new timeslot and Remove all old future 5th lesson record
                            o	All future Makeup/Adhoc related to 5th week will be cancelled and makeup credit will be added back to the parent record
                            o	Makeup for adhoc booking will be added if the adhoc invoice was paid.
                            o   create a fresh group class and relaed group Bookings
                            

                        	If makeup/adhoc/placeholder & Reschedule All on same day

                            o	All future Makeup related to 5th week will be rescheduled for the timeslot
                            o	All future 5th lesson record will be rescheduled to the timeslot
                            o   All  group class and related group lesson Bookings get Reschedule
*/
public with sharing class RescheduleForAllFutureGroupClassBookings {
    Public Boolean dayChange;
    Public Boolean isOssia; // added by nishi: 24-Aug-2020: if teacher Leave is found and we update  Ossia org enrolment then we added 180 expiry days otherwise we added 120 days for other students
    Public Class__c classObj;
    Public Date effectiveDate;
    Public Date startDate;
    Public Map<String, Booking__c> mapOfGroupLessonBooking = new Map<String, Booking__c>();
    Public Map<String, Booking__c> mapOfGroupClassBooking = new Map<String, Booking__c>();
    Public String centreOrgId;
    public List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings;
    //Constructor or start point of the functionality
    public RescheduleForAllFutureGroupClassBookings(Boolean dayChange, Class__c classObj, Date effectiveDate, Date startDate) {
         listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
         Language, NamespacePrefix,Makeup_Expiry_Days_For_Public_Holiday__c, Label, QualifiedApiName, Makeup_Expiry_Days__c,
         Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
         WHERE Label =:System.Label.Ossia_Organisation_Name];
        this.dayChange = dayChange;
        this.classObj = classObj;
        this.effectiveDate = effectiveDate;
        this.startDate = startDate;
        this.isOssia = false;
        system.debug('@@@RescheduleAllBookings classObj - '+classObj);
        System.debug('@@@RescheduleAllBookings effectiveDate--'+effectiveDate);
        System.debug('@@@RescheduleAllBookings startDate--'+startDate);
        System.debug('@@@RescheduleAllBookings dayChange--'+dayChange);
        // for ossia students booking will cancel then we added expiry date 180
        // otherwise we added 120 days for other students
        if(String.isNotBlank(classObj.Centre_Name__c) && 
        String.isNotBlank(classObj.Centre_Name__r.Organisation__c) && 
        String.isNotBlank(classObj.Centre_Name__r.Organisation__r.Name) && 
        classObj.Centre_Name__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){ 
            this.isOssia= true;
        } 
        if(this.dayChange && String.isNotBlank(classObj.Id) && effectiveDate != NULL && startDate != NULL){
            //Day Change
            System.debug('@@@effectiveDate'+effectiveDate);
            if(classObj.Centre_Name__r != null && string.isNotBlank(classObj.Centre_Name__r.Organisation__c))
                centreOrgId = classObj.Centre_Name__r.Organisation__c;
            system.debug('@@@centreOrgId'+centreOrgId);
            dayIsChanged(classObj, effectiveDate, startDate);
        }else{
            //Day Not Changed
            dayIsNotChanged(classObj, effectiveDate);
        }
    }
    // get all group classes bookings 
    Private static List<Booking__c> fetchSelectedGroupClassBookings(string classId,date effectivedate){
        return  [SELECT Id, Name, Center__r.Name, Teacher_Account__r.Name, Duration__c, Start_Time__c, 
                    Booking_Date__c, Package__r.Name, Package__r.Duration__C,Class__r.Instrument__c,
                    Class__r.Class_Type__c,Class__r.Maximum_age__c,Class__r.Minimum_age__c,
                    Class__r.Class_Start_Date__c,Resource__r.Name, 
                    Class__c,Package__r.Package_Fee__c, Class__r.Start_Time__c,Class__r.Total_Capacity__c,
                    Class__r.Name, Class__r.Available_Capacity__c ,
                    Class__r.Centre_Name__r.Organisation__r.Name,Class__r.grade__c,Class__r.Duration__c,
                    (SELECT Id, Name, Enrolment__c,Package__c , Student__c, Student__r.Name, Resource__c,Prev_Teacher__c,
                        Enrolment__r.Teacher__c, Individual_Booking__c, Type__c, Enrolment__r.Lesson_Day__c, Prev_Start_Time__c,
                        Enrolment__r.Lesson_Start_time__c, Booking_Date__c, Start_Time__c, End_Time__c, Prev_Booking_Date__c,
                        Status__c, Center__c, Teacher_Account__c, Teacher_Account__r.Name, Lesson_Type__c,
                        Duration__c, RecordType.Name, Category__c, Appointment_Day__c,Enrolment__r.Resource__c,
                        Package__r.Type__c, Available_Make_up_Units__c, Make_up_Utilize_Bookings__c 
                        FROM Bookings1__r
                        order by Booking_Date__c Desc
                        )
                    FROM Booking__c WHERE
                    Class__c =: classId
                    AND Booking_date__c >=:effectivedate
                    order by Booking_Date__c Desc];
    }
   
    // get all group class enrolment 
    private static List<Enrolment__c>  fetchEnrolments(String classId,Set<string> enromentids){
        string activeStatus =ConstantsClass.activeStatus;
        string enrolGroupType =ConstantsClass.enrolGroupType;
        string enrollmentStageCancelled =ConstantsClass.enrollmentStageCancelled;
        string enrolmentQuery ='SELECT Id, Effective_Date__c, Lesson_Day__c, Teacher__c, Teacher__r.Employee_Duty_Type__c, Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, Next_Lesson_Start_time__c,';
                enrolmentQuery +=' Package__c, Package__r.Duration__c,Parent__c, Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, Class__c,';
                enrolmentQuery +=' Center__r.Country__r.Stripe_Secret_Key__c, Center__r.Country__r.Stripe_Base_Url__c,Center__r.Country__r.Id, Center__r.Organisation__c, ';
                enrolmentQuery +=' (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,';
                enrolmentQuery +=' Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c FROM Subscription_Line_Items__r';
                enrolmentQuery +=' Where Status__c =: activeStatus';
                enrolmentQuery +=' And Next_Bill_Date__c != null),';
                enrolmentQuery +=' Resource__c ,Lesson_Mode__c,Online_Lesson_Passcode__c,Online_Lesson_URL__c,name';
                enrolmentQuery +=' FROM Enrolment__c';
                enrolmentQuery +=' WHERE type__c =: enrolGroupType';
                enrolmentQuery +=' And stage__c !=: enrollmentStageCancelled';
                if(string.isNotBlank(classId)){
                    enrolmentQuery +=' And Class__C =: classId';
                }
                if(enromentids != null && enromentids.size() > 0){
                    enrolmentQuery +=' And Id In: enromentids';
                }
        List<Enrolment__c>  listOfenrolment = Database.query(enrolmentQuery);
        return listOfenrolment;                            
    }
      /*
     *  This Method will Run when the Day is Changed and it will perform the following actions
     *      o	All future Makeup/Adhoc/Placeholder related to group class be rescheduled for the timeslot
     *      o	All future 5th lesson record will be rescheduled to the timeslot
     *      o   All group class Bookings get Reschedule
     */
    private void dayIsNotChanged(Class__c classObj, Date effectiveDate){
        if(string.isNotBlank(classObj.id)){
            List<Booking__c> listofGroupClassBookings = fetchSelectedGroupClassBookings(classObj.Id, effectiveDate);
            set<string> enromentids = new set<string>();
            system.debug('listofGroupClassBookings'+listofGroupClassBookings);
            List<Booking__c> bookingsToUpdate = new  List<Booking__c>();
            if(listofGroupClassBookings != null && listofGroupClassBookings.size() >0){
                for(Booking__c objGroupClassBooking :listofGroupClassBookings){
                    objGroupClassBooking.Start_Time__c = classObj.Start_Time__c;
                    objGroupClassBooking.End_Time__c =  objGroupClassBooking.Start_Time__c.addMinutes(Integer.valueOf(objGroupClassBooking.Duration__c));
                    objGroupClassBooking.Teacher_Account__c =  classObj.Teacher__c;
                    bookingsToUpdate.add(objGroupClassBooking);
                    if(objGroupClassBooking.Bookings1__r != null && objGroupClassBooking.Bookings1__r.size() > 0){
                        system.debug('objGroupClassBooking.Bookings1__r'+objGroupClassBooking.Bookings1__r); 
                        for(Booking__c objGroupLessonBooking : objGroupClassBooking.Bookings1__r ){
                            if(string.isNotBlank(objGroupLessonBooking.enrolment__c) && objGroupLessonBooking.Type__c == ConstantsClass.groupLessonTypeBooking && 
                               objGroupLessonBooking.Status__c != ConstantsClass.statusCanceled){
                                enromentids.add(objGroupLessonBooking.enrolment__c);
                            }
                            objGroupLessonBooking.Start_Time__c = classObj.Start_Time__c;
                            objGroupLessonBooking.End_Time__c =  objGroupLessonBooking.Start_Time__c.addMinutes(Integer.valueOf(objGroupLessonBooking.Duration__c));
                            objGroupLessonBooking.Teacher_Account__c =  classObj.Teacher__c;
                            bookingsToUpdate.add(objGroupLessonBooking);

                        }
                    }
                }  
                system.debug('enromentids'+enromentids); 
                List<Enrolment__c>  listOfEnrolment =updateGroupEnrolement(enromentids,classObj);
                if(bookingsToUpdate != null && bookingsToUpdate.size() > 0){
                    update bookingsToUpdate;
                    system.debug('bookingsToUpdate'+bookingsToUpdate);
                }
            }
        }
    }

    private List<Enrolment__c>  updateGroupEnrolement(set<string> enromentids,Class__c classObj){
        List<Enrolment__c>  listOfEnrolment  = new  List<Enrolment__c> ();
        if(string.isNotBlank(classObj.id)){
            listOfEnrolment =  fetchEnrolments(classObj.id,enromentids);
            system.debug('listOfEnrolment'+listOfEnrolment);
            DateTime dateChange = DateTime.newInstance(classObj.Class_Date__c, Time.newInstance(0, 0, 0, 0));
            for(Enrolment__c objenrolment : listOfEnrolment){
                if(objenrolment.Class__c == classObj.id){
                    objenrolment.Lesson_Start_time__c =   classObj.Start_Time__c;
                    objenrolment.Teacher__c = classObj.Teacher__c;
                    objenrolment.Lesson_Day__c =  dateChange.format('EEEE');
                }
            }
            update listOfEnrolment;
            system.debug('listOfEnrolment'+listOfEnrolment);
        }
        return listOfEnrolment;
    }
    private void dayIsChanged(Class__c classObj, Date effectiveDate, Date startDate){
        List<Booking__c> listofGroupClassBookings = fetchSelectedGroupClassBookings(classObj.Id, startDate);
        set<string> enromentids = new set<string>();
        Set<String> bookingtype = new Set<string>{ConstantsClass.typeAdhoc,ConstantsClass.typeMakeup};
        system.debug('listofGroupClassBookings'+listofGroupClassBookings);
        List<Booking__c> makeupAdhocbookingsToUpdate = new  List<Booking__c>();
        List<Booking__c> existingBookingsToDelete = new  List<Booking__c>();
        List<Booking__c> existingCancelBookingsToUpdate = new  List<Booking__c>();
        Map<String,string> mapofEnrolmentLastBookingDates = new  Map<String,string>();
        Map<String,Booking__c> mapofEnrolmentStartBookingDates = new  Map<String,Booking__c>();
        string lastGroupClassDate ;
        if(listofGroupClassBookings != null && listofGroupClassBookings.size() >0){
            for(Booking__c objGroupClassBooking :listofGroupClassBookings){
                if(string.isBlank(lastGroupClassDate)){
                    lastGroupClassDate = string.valueOf(objGroupClassBooking.Booking_Date__c);
                }
                existingBookingsToDelete.add(objGroupClassBooking);
                if(objGroupClassBooking.Bookings1__r != null && objGroupClassBooking.Bookings1__r.size() > 0){
                    system.debug('objGroupClassBooking.Bookings1__r'+objGroupClassBooking.Bookings1__r); 
                    for(Booking__c objGroupLessonBooking : objGroupClassBooking.Bookings1__r ){
                        // group lessons booking are makeup or adhoc then we update
                        if(bookingtype.contains(objGroupLessonBooking.Type__c)){
                            makeupAdhocbookingsToUpdate.add(objGroupLessonBooking);
                        }// regular group lesson bookings exist then we check if those bookings are canclled or not
                        else if(objGroupLessonBooking.Type__c == ConstantsClass.groupLessonTypeBooking){
                            if (objGroupLessonBooking.Status__c == ConstantsClass.statusCanceled && objGroupLessonBooking.Available_Make_up_Units__c != NULL && objGroupLessonBooking.Available_Make_up_Units__c > 0){
                                existingCancelBookingsToUpdate.add(new Booking__c(Id = objGroupLessonBooking.Id, Available_Make_up_Units__c = objGroupLessonBooking.Available_Make_up_Units__c - objGroupLessonBooking.Duration__c));
                            }else{
                                existingBookingsToDelete.add(objGroupLessonBooking);
                                if(string.isNotBlank(objGroupLessonBooking.enrolment__c)){
                                    Date lastBookingdate;
                                    if(!mapofEnrolmentLastBookingDates.containsKey(objGroupLessonBooking.enrolment__c)){
                                        mapofEnrolmentLastBookingDates.put(objGroupLessonBooking.enrolment__c,string.valueOf(objGroupLessonBooking.Booking_Date__c)+'@'+objGroupLessonBooking.Package__c);
                                    }
                                }
                            }
                       }else { 
                           // delete all busy type bookings
                            existingBookingsToDelete.add(objGroupLessonBooking);
                       }
                    }
                }
            }
            system.debug('makeupAdhocbookingsToUpdate'+makeupAdhocbookingsToUpdate);
            if(makeupAdhocbookingsToUpdate != null && makeupAdhocbookingsToUpdate.size() > 0){
                List<Booking__c> adhocBookingsToUpdate  = processmakeupAdhocbookings(makeupAdhocbookingsToUpdate);
                if(adhocBookingsToUpdate != null && adhocBookingsToUpdate.size() > 0){
                    existingCancelBookingsToUpdate.addAll(adhocBookingsToUpdate);
                }
            }
            system.debug('existingCancelBookingsToUpdate'+existingCancelBookingsToUpdate);
            if(existingCancelBookingsToUpdate != null && existingCancelBookingsToUpdate.size() > 0){
                update existingCancelBookingsToUpdate;
            }
            system.debug('existingBookingsToDelete'+existingBookingsToDelete);
            if(existingBookingsToDelete != null && existingBookingsToDelete.size() > 0){
                delete existingBookingsToDelete;
            }
            Map<String,Map<Date,String>> mapOfClassDates = reCreateRegularGroupClassBookingsAndFifthLesson(classObj,date.valueOf(lastGroupClassDate),effectiveDate);
            system.debug('mapOfClassDates'+mapOfClassDates);
            if(mapOfClassDates != null && mapOfClassDates.size() > 0 ){
                reCreateRegularGroupLessonBookings(mapofEnrolmentLastBookingDates,mapOfClassDates,classObj);
            }
            if(date.valueOf(lastGroupClassDate) != NULL && String.isNotBlank(classObj.Id) && String.isNotBlank(classObj.Teacher__c) && effectiveDate != NULL){
                processTeacherLeaves(classObj.Teacher__c, effectiveDate,  date.valueOf(lastGroupClassDate));
            }
            system.debug('classObj.Teacher__c'+classObj.Teacher__c);
            if(date.valueOf(lastGroupClassDate) != NULL && String.isNotBlank(classObj.Id) && String.isNotBlank(classObj.Teacher__c) && effectiveDate != NULL && String.isNotBlank(centreOrgId)){
                List<Account> teacherlist = [select id,Employee_Duty_Type__c from Account where Id =: classObj.Teacher__c]; 
                if(teacherlist != null && teacherlist.size() > 0)
                    processPublicHolidays(effectiveDate, date.valueOf(lastGroupClassDate), centreOrgId, teacherlist[0]);
            }
        }
    }
    private Map<String,Map<Date,String>> reCreateRegularGroupClassBookingsAndFifthLesson(Class__c objClass, Date lastLesson, Date startDate){
        List<Booking__c> bookingListForClass = new  List<Booking__c>();
        Map<String,Map<Date,String>> mapOfClassDates = new Map<String,Map<Date,String>>();
        
        if(objClass.Start_Time__c != null && lastLesson != null && startDate != null){    
            DateTime startTime  =DateTime.newInstance(startDate,objClass.Start_Time__c);
            DateTime endTime = DateTime.newInstance(lastLesson,objClass.Start_Time__c);
            bookingListForClass.addAll(ClassTriggerHelper.createBookingsForClass(objClass,startTime,endTime));
            if(bookingListForClass != null && bookingListForClass.size()>0){
                upsert bookingListForClass;
            }
            if(bookingListForClass.size() > 0){
                upsert   bookingListForClass;    
                Map<Date,String> mapOfDateGroupLesson = new  Map<Date,String>();
                for(Booking__c objBook: bookingListForClass){
                    if(objBook.Type__c == ConstantsClass.groupTypeBooking){
                        mapOfGroupClassBooking.put(objBook.Booking_Date__c + '-' + objBook.Teacher_Account__c, objBook);
                        mapOfDateGroupLesson = mapOfClassDates.containsKey(objBook.Class__c) ?  mapOfClassDates.get(objBook.Class__c):New Map<Date,String>();
                        mapOfDateGroupLesson.put(objBook.Booking_Date__c ,objBook.id);
                        mapOfClassDates.put(objBook.Class__c,mapOfDateGroupLesson);
                    }
                }
                system.debug('mapOfClassDates'+mapOfClassDates); 
                system.debug('mapOfGroupClassBooking'+mapOfGroupClassBooking); 
            }
        }
        return mapOfClassDates;
    }
    private  void  reCreateRegularGroupLessonBookings(Map<String,String> mapofEnrolmentLastBookingDates,Map<String,Map<Date,String>> mapOfClassDates,Class__c classObj ){
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        Map<Date,String> mapOfDateGroupLesson = new  Map<Date,String>();
        String groupLessonBookingRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
        
        if(mapofEnrolmentLastBookingDates != null && mapofEnrolmentLastBookingDates.size() > 0){
            List<Enrolment__c>  listOfEnrolment  = updateGroupEnrolement(mapofEnrolmentLastBookingDates.keyset(),classObj);
            system.debug('@@@New Bookings are Inserted mapofEnrolmentLastBookingDates '+mapofEnrolmentLastBookingDates);
            system.debug('@@@New Bookings are Inserted listOfEnrolment '+listOfEnrolment);
            system.debug('@@@New Bookings are Inserted mapOfClassDates '+mapOfClassDates);
            system.debug('@@@New Bookings are Inserted classObj '+classObj);
            if(mapOfClassDates != null && mapOfClassDates.size() >0){
                for(Enrolment__c enrolmentObj : listOfEnrolment){
                    List<Subscription_Line_Item__c>  sublineItemList =  enrolmentObj.Subscription_Line_Items__r;
                    system.debug('@@@New Bookings are Inserted sublineItemList '+sublineItemList);
                    mapOfDateGroupLesson = new  Map<Date,String>();
                    if(mapOfClassDates != null && mapOfClassDates.size() > 0 && mapOfClassDates.containsKey(classObj.id)){
                        mapOfDateGroupLesson = mapOfClassDates.get(classObj.id);
                    }
                    if(mapOfDateGroupLesson != null && mapOfDateGroupLesson.size() > 0){
                        for(Date objDate : mapOfDateGroupLesson.keySet()){
                            date objlastEnrolmentDate = date.valueOf(mapofEnrolmentLastBookingDates.get(enrolmentObj.id).split('@')[0]); 
                            system.debug('@@@New Bookings are Inserted objlastEnrolmentDate '+objlastEnrolmentDate);
                            system.debug('@@@New Bookings are Inserted objDate '+objDate);
                            if(mapOfDateGroupLesson.containsKey(objDate) && objDate <= objlastEnrolmentDate){
                                Booking__c objBooking = new Booking__c();
                                objBooking.Student__c = enrolmentObj.Student__c;
                                objBooking.Center__c = enrolmentObj.Center__c;
                                objBooking.Booking_Date__c = objDate;
                                objBooking.recordTypeId = groupLessonBookingRecordType;
                                objBooking.parent__c = String.isNotBlank(enrolmentObj.parent__c) && enrolmentObj.parent__c !=null ? enrolmentObj.parent__c : null;
                                objBooking.Start_Time__c = classObj.Start_Time__c;
                                objBooking.End_Time__c =  objBooking.Start_Time__c.addMinutes(Integer.valueOf(classObj.Duration__c));
                                objBooking.Teacher_Account__c =  classObj.Teacher__c;
                                objBooking.Enrolment__c = enrolmentObj.Id; 
                                objBooking.Package__c = mapofEnrolmentLastBookingDates.get(enrolmentObj.id).split('@')[1];
                                objBooking.type__c = ConstantsClass.groupLessonTypeBooking;
                                if(sublineItemList != null && sublineItemList.size() > 0 && sublineItemList[0].Next_Bill_Date__c != null && objDate != null &&  objDate >= sublineItemList[0].Next_Bill_Date__c){
                                    objBooking.Status__c = ConstantsClass.pendingStatus;
                                }else{
                                    objBooking.Status__c = ConstantsClass.scheduledStatus;
                                }
                                objBooking.Status__c = ConstantsClass.pendingStatus;
                                objBooking.Group_Class__c = mapOfDateGroupLesson.get(objDate);
                                bookingsToInsert.add(objBooking);
                            }
                            
                        }
                    }
                }
            }
            if(bookingsToInsert.size() > 0){
                INSERT bookingsToInsert;
                system.debug('@@@New Bookings are Inserted '+bookingsToInsert);
    
                for(Booking__c bookingObj : bookingsToInsert){
                    mapOfGroupLessonBooking.put(bookingObj.Booking_Date__c + '-' + bookingObj.Teacher_Account__c, bookingObj);
                }
                system.debug('@@@New Bookings are mapOfGroupLessonBooking '+mapOfGroupLessonBooking);
            }
        }
    }

    /*
    *   This Method will Process Future Makeup Type Bookings for the enrolment 
    *   by cancelling them and Rollback Makeup Minutes to parent
        and 
    *   This Method will Process Future Adhoc Type Bookings for the Enrolment
    *   by cancelling them and Rollback the makeup minutes to parent if its invoice is Paid
    *   and if its invoice is due then it gets cancelled and no makeup is rollback to parent.   
    */

    private  List<Booking__c> processmakeupAdhocbookings(List<Booking__c> makeupAdhocbookingsToUpdate){
        List<Booking__c> adhocBookingsToUpdate = new List<Booking__c>();
        List<Booking__c> makeupBooking = new List<Booking__c>();
        if(makeupAdhocbookingsToUpdate != null && makeupAdhocbookingsToUpdate.size() > 0){
            for(Booking__c bookObj : makeupAdhocbookingsToUpdate){
                if(bookObj.type__C == ConstantsClass.typeMakeup){
                    makeupBooking.add(bookObj);
                }else{
                    bookObj.Available_Make_up_Units__c = bookObj.Duration__c;
                    // for ossia students booking will cancel then we added expiry date 180 otherwise we added 120 days for other students
                    if(isOssia){
                            if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                bookObj.Make_up_Expiry_Date__c=bookObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days__c)));
                            }
                        }else{
                            bookObj.Make_up_Expiry_Date__c = bookObj.Booking_date__c.addDays(120);
                        }
                    //for ossia students booking will cancel then we added expiry date 180 otherwise we added 120 days for other students
                    bookObj.status__c = ConstantsClass.statusCanceled;
                    adhocBookingsToUpdate.add(bookObj);
                }
            }
        
            if(makeupBooking != null && makeupBooking.size() > 0){
                AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(makeupBooking);
            }
        }
        return adhocBookingsToUpdate;
    }

    private void processTeacherLeaves(String teacherId, Date effectiveDate, Date maxDate){
        Set<String> setOfTeachersLeaves = new Set<String>();

        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
     
        Map<String, Booking__c> updatedGroupLessonBookingMap = new Map<String, Booking__c>(); 
        Map<String, Booking__c> updatedGroupClassBookingMap = new Map<String, Booking__c>(); 
        system.debug('@@@processTeacherLeaves teacherId -'+teacherId);
        system.debug('@@@processTeacherLeaves effectiveDate -'+effectiveDate);
        system.debug('@@@processTeacherLeaves maxDate -'+maxDate);
        if(String.isNotBlank(teacherId) && effectiveDate != NULL && maxDate != NULL){
            setOfTeachersLeaves = fetchTeacherLeavesRequestDateSet(teacherId, effectiveDate, maxDate);
        }
        system.debug('@@@processTeacherLeaves mapOfGroupClassBooking -'+mapOfGroupClassBooking);
        for(String keySetValue : mapOfGroupClassBooking.keySet()){
            if(setOfTeachersLeaves.contains(keySetValue)){
                Booking__c bookObj = mapOfGroupClassBooking.get(keySetValue);
                bookObj.Status__c = ConstantsClass.statusCanceled;
                bookObj.Cancellation_Reason__c = 'Teacher Mc';
                bookObj.Remarks__c = 'Teacher Leave';
                bookingtoUpdate.add(bookObj);
                updatedGroupClassBookingMap.put(keySetValue, bookObj);
            }
        }
        system.debug('@@@processTeacherLeaves mapOfGroupLessonBooking -'+mapOfGroupLessonBooking);
        for(String keySetValue : mapOfGroupLessonBooking.keySet()){
            if(setOfTeachersLeaves.contains(keySetValue)){
                Booking__c bookObj = mapOfGroupLessonBooking.get(keySetValue);
                bookObj.Status__c = ConstantsClass.statusCanceled;
                bookObj.Available_Make_up_Units__c = bookObj.Duration__c; 
                if(isOssia){
                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                        bookObj.Make_up_Expiry_Date__c=bookObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c)));
                    }
                }else{
                    bookObj.Make_up_Expiry_Date__c  = bookObj.Booking_Date__c.addDays(120);
                }
                bookObj.Makeup_Reason__c = 'Teacher Mc';
                bookObj.Cancellation_Reason__c = 'Teacher Mc';
                bookObj.Remarks__c = 'Teacher Leave';
                bookingtoUpdate.add(bookObj);
                updatedGroupLessonBookingMap.put(keySetValue, bookObj);
            }
        }
        
        
        if(updatedGroupLessonBookingMap.size() > 0){
            mapOfGroupLessonBooking.putAll(updatedGroupLessonBookingMap);
        }
        if(updatedGroupClassBookingMap.size() > 0){
            mapOfGroupClassBooking.putAll(updatedGroupClassBookingMap);
        }
        system.debug('@@@processTeacherLeaves bookingtoUpdate -'+bookingtoUpdate);
        if(bookingtoUpdate.size() > 0){
            
            List<Case> caseList = AureusUtility.createCase(bookingtoUpdate);
            insert caseList;
            system.debug('@@ inserted case for bookings are =='+caseList);
            bookingtoUpdate.addAll(createPlaceholderFromBooking(bookingtoUpdate));
            UPSERT bookingtoUpdate;
            Set<Id> csIds = new Set<Id>();
            for(Case c : caseList)
                csIds.add(c.Id);
            AureusUtility.sendCaseEmail(csIds);
        }

    }

    private void processPublicHolidays(Date effectiveDate, Date maxDate, String centreOrgId, Account teacherObj){
        Map<String, Public_Holiday__c> mapOfPublicLeaves = new Map<String, Public_Holiday__c>();
        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
       
        Map<String, Booking__c> updatedGroupLessonBookingMap = new Map<String, Booking__c>(); 
        Map<String, Booking__c> updatedGroupClassBookingMap = new Map<String, Booking__c>(); 
        system.debug('@@processPublicHolidays effectiveDate'+effectiveDate);
        system.debug('@@processPublicHolidays teacherObj'+teacherObj);
        system.debug('@@processPublicHolidays centreOrgId'+centreOrgId);
        system.debug('@@processPublicHolidays maxDate'+maxDate);
        system.debug('@@processPublicHolidays teacherObj.id'+teacherObj.Id);
        if(effectiveDate != NULL && maxDate != NULL && teacherObj != NULL && String.isNotBlank(centreOrgId) && String.isNotBlank(teacherObj.Id)){
            mapOfPublicLeaves = fetchPublicHolidaysDateMap(effectiveDate, maxDate, centreOrgId, teacherObj);
        }

        system.debug('@@processPublicHolidays mapOfGroupClassBooking'+mapOfGroupClassBooking);
        for(String keySetValue : mapOfGroupClassBooking.keySet()){
            if(mapOfPublicLeaves != null && mapOfPublicLeaves.size() > 0 &&
               mapOfPublicLeaves.containsKey(keySetValue) && mapOfGroupClassBooking.get(keySetValue).Status__c != ConstantsClass.statusCanceled){
                Booking__c bookObj = mapOfGroupClassBooking.get(keySetValue);
                bookObj.Status__c = ConstantsClass.statusCanceled;
                bookObj.Remarks__c = 'Public Holiday';
                bookObj.Cancellation_Reason__c   = 'Holidays';
                bookObj.Public_Holiday_Status__c = mapOfPublicLeaves.get(keySetValue).Organisation_Status__c;
                bookingtoUpdate.add(bookObj);
                updatedGroupClassBookingMap.put(keySetValue, bookObj);
            }
        }
        system.debug('@@processPublicHolidays mapOfGroupLessonBooking'+mapOfGroupLessonBooking);
        for(String keySetValue : mapOfGroupLessonBooking.keySet()){
            if(mapOfPublicLeaves != null && mapOfPublicLeaves.size() > 0 &&
               mapOfPublicLeaves.containsKey(keySetValue) && mapOfGroupLessonBooking.get(keySetValue).Status__c != ConstantsClass.statusCanceled){
                Booking__c bookObj = mapOfGroupLessonBooking.get(keySetValue);
                bookObj.Status__c = ConstantsClass.statusCanceled;
                bookObj.Available_Make_up_Units__c = bookObj.Duration__c; 
                if(isOssia){
                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                        bookObj.Make_up_Expiry_Date__c=bookObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_For_Public_Holiday__c)));
                    }
                }else{
                    bookObj.Make_up_Expiry_Date__c  = bookObj.Booking_Date__c.addDays(120);
                }
                bookObj.Remarks__c = 'Public Holiday';
                bookObj.Cancellation_Reason__c   = 'Holidays';
                bookObj.Public_Holiday_Status__c = mapOfPublicLeaves.get(keySetValue).Organisation_Status__c;
                bookingtoUpdate.add(bookObj);
                updatedGroupLessonBookingMap.put(keySetValue, bookObj);
            }
        }
       
        system.debug('@@@deActivate updatedGroupLessonBookingMap '+updatedGroupLessonBookingMap);
        system.debug('@@@deActivate updatedGroupClassBookingMap '+updatedGroupClassBookingMap);
        if(updatedGroupLessonBookingMap.size() > 0){
            mapOfGroupLessonBooking.putAll(updatedGroupLessonBookingMap);
        }
        if(updatedGroupClassBookingMap.size() > 0){
            mapOfGroupClassBooking.putAll(updatedGroupClassBookingMap);
        }
        if(bookingtoUpdate.size() > 0){
            
            List<Case> caseList = AureusUtility.createCase(bookingtoUpdate);
            insert caseList;
            system.debug('@@ create case for bookings '+caseList);
            bookingtoUpdate.addAll(createPlaceholderFromBooking(bookingtoUpdate));
            UPSERT bookingtoUpdate;
            system.debug('@@@processPublicHolidays bookingtoUpdate '+bookingtoUpdate);
            Set<Id> csIds = new Set<Id>();
            for(Case c : caseList)
                csIds.add(c.Id);
            AureusUtility.sendCaseEmail(csIds);
        }    
    }

    private Set<String> fetchTeacherLeavesRequestDateSet(String teacherId, Date effectiveDate, Date maxDate){
        Set<String> setOfTeachersLeave = new Set<String>();
        for(Leave_Request__c leaveRequest : [SELECT Id, Name, Leave_Type__c, Employee__c, Leave_Start_Date__c, Leave_End_Date__c 
                                             FROM Leave_Request__c WHERE Employee__c = :teacherId
                                              AND Leave_Start_Date__c >= :effectiveDate AND 
                                             Leave_Start_Date__c <= :maxDate AND Status__c = :ConstantsClass.approvedTeacherLeave]){
            Date startDateLeave = leaveRequest.Leave_Start_Date__c;
            While(startDateLeave <= leaveRequest.Leave_End_Date__c){
                setOfTeachersLeave.add(startDateLeave + '-' + leaveRequest.Employee__c);
                startDateLeave = startDateLeave.addDays(1);
            }
        }
         System.debug('@@@@@setOfTeachersLeave'+setOfTeachersLeave);
        return setOfTeachersLeave;
    }

    private Map<String, Public_Holiday__c> fetchPublicHolidaysDateMap(Date effectiveDate, Date maxDate, String centreOrgId, Account teacherObj){
        Map<String, Public_Holiday__c> mapOfHolidaysLeave = new Map<String, Public_Holiday__c>();
        for(Public_Holiday__c holiday : [SELECT Id, Name, Public_Holiday_Date__c,Organisation_Status__c 
                                            FROM Public_Holiday__c 
                                            WHERE Organisation__c =: centreOrgId AND Public_Holiday_Date__c >= :effectiveDate AND Public_Holiday_Date__c <= :maxDate 
                                            AND Status__c IN('Execution completed') AND Organisation_Status__c != null]){
                if(holiday.Organisation_Status__c == 'Closed' || (holiday.Organisation_Status__c == 'Open' && teacherObj.Employee_Duty_Type__c=='Duty')){
                    mapOfHolidaysLeave.put(holiday.Public_Holiday_Date__c + '-' + teacherObj.Id, holiday);
                }
        }
        system.debug('@@@ mapOfHolidaysLeave dates are ='+mapOfHolidaysLeave);
        return mapOfHolidaysLeave;
    }

    private List<Booking__c> createPlaceholderFromBooking(List<Booking__c> bookingObjList){
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Booking__c bookingCurrentObj : bookingObjList){
            Booking__c placeholderObj = new Booking__c();
            placeholderObj.RecordTypeId = bookingCurrentObj.RecordTypeId;
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            placeholderObj.Booking_Date__c = bookingCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = bookingCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = bookingCurrentObj.End_Time__c;
            placeholderObj.status__c = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = bookingCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c = bookingCurrentObj.Center__c;
            if(string.isNotBlank(bookingCurrentObj.Class__c)){
                placeholderObj.Class__c =bookingCurrentObj.Class__c;
                placeholderObj.remarks__c = 'placeholder booking for cancelling '+ bookingCurrentObj.Class__r.Name + ' booking';
            }else{
                placeholderObj.Group_Class__c =bookingCurrentObj.Group_Class__c;
                placeholderObj.remarks__c = 'placeholder booking for cancelling '+ bookingCurrentObj.Student__r.Name + ' booking';
            }
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            placeholderObj.Enrolment__c= bookingCurrentObj.Enrolment__c;
            placeholderObj.Student__c  = bookingCurrentObj.Student__c;
            placeholderObj.Package__c  = bookingCurrentObj.Package__c;
            placeholderList.add(placeholderObj);
        }
        system.debug('@@@ create new Placeholder for bookings =='+placeholderList);
        return placeholderList;
    }
    
    
}
