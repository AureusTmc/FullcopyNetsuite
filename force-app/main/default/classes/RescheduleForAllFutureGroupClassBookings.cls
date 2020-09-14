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
    Public Map<String, Booking__c> mapOfBooking = new Map<String, Booking__c>();
    Public Map<String, Fifth_Lesson__c> mapOfFifthLesson = new Map<String, Fifth_Lesson__c>();
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
                        order by Booking_Date__c
                        )
                    FROM Booking__c WHERE
                    Class__c =: classId
                    AND Booking_date__c >=:effectivedate
                    order by Booking_Date__c];
    }
   
    // get all group class enrolment 
    private static List<Enrolment__c>  fetchEnrolments(String classId,Set<string> enromentids){
        string activeStatus =ConstantsClass.activeStatus;
        string enrolGroupType =ConstantsClass.enrolGroupType;
        string enrollmentStageCancelled =ConstantsClass.enrollmentStageCancelled;
        string enrolmentQuery ='SELECT Id, Effective_Date__c, Lesson_Day__c, Teacher__c, Teacher__r.Employee_Duty_Type__c, Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, Next_Lesson_Start_time__c,';
                enrolmentQuery +=' Package__c, Package__r.Duration__c,Parent__c, Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, ';
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
                updateGroupEnrolement(enromentids,classObj);
                if(bookingsToUpdate != null && bookingsToUpdate.size() > 0){
                    update bookingsToUpdate;
                    system.debug('bookingsToUpdate'+bookingsToUpdate);
                }
            }
        }
    }

    private void updateGroupEnrolement(set<string> enromentids,Class__c classObj){
        if(string.isNotBlank(classObj.id)){
            List<Enrolment__c>  listOfEnrolment =  fetchEnrolments(classObj.id,enromentids);
            system.debug('listOfEnrolment'+listOfEnrolment);
            DateTime dateChange = DateTime.newInstance(classObj.Class_Date__c, Time.newInstance(0, 0, 0, 0));
            for(Enrolment__c objenrolment : listOfEnrolment){
                objenrolment.Lesson_Start_time__c =   classObj.Start_Time__c;
                objenrolment.Teacher__c = classObj.Teacher__c;
                objenrolment.Lesson_Day__c =  dateChange.format('EEEE');
            }
            update listOfEnrolment;
            system.debug('listOfEnrolment'+listOfEnrolment);
        }
    }
    private void dayIsChanged(Class__c classObj, Date effectiveDate, Date startDate){
        List<Booking__c> listofGroupClassBookings = fetchSelectedGroupClassBookings(classObj.Id, effectiveDate);
        set<string> enromentids = new set<string>();
        Set<String> bookingtype = new Set<string>{ConstantsClass.typeAdhoc,ConstantsClass.typeMakeup};
        system.debug('listofGroupClassBookings'+listofGroupClassBookings);
        List<Booking__c> makeupAdhocbookingsToUpdate = new  List<Booking__c>();
        List<Booking__c> existingBookingsToDelete = new  List<Booking__c>();
        List<Booking__c> existingCancelBookingsToUpdate = new  List<Booking__c>();
        Map<String,date> mapofEnrolmentLastBookingDates = new  Map<String,date>();
        Map<String,date> mapofEnrolmentStartBookingDates = new  Map<String,date>();
        if(listofGroupClassBookings != null && listofGroupClassBookings.size() >0){
            for(Booking__c objGroupClassBooking :listofGroupClassBookings){
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
                                    if(mapofEnrolmentLastBookingDates.containsKey(objGroupLessonBooking.enrolment__c)){
                                        lastBookingdate = mapofEnrolmentLastBookingDates.get(objGroupLessonBooking.enrolment__c);
                                        if(lastBookingdate > objGroupLessonBooking.Booking_Date__c){
                                            mapofEnrolmentLastBookingDates.put(objGroupLessonBooking.enrolment__c,objGroupLessonBooking.Booking_Date__c);
                                        }
                                    }else{
                                        mapofEnrolmentLastBookingDates.put(objGroupLessonBooking.enrolment__c,objGroupLessonBooking.Booking_Date__c);
                                    }
                                    if(!mapofEnrolmentStartBookingDates.containsKey(objGroupLessonBooking.enrolment__c)){
                                        mapofEnrolmentStartBookingDates.put(objGroupLessonBooking.enrolment__c,objGroupLessonBooking.Booking_Date__c);
                                    }
                                }
                            }
                       }
                      
                       
                    }
                }
            }

            if(makeupAdhocbookingsToUpdate != null && makeupAdhocbookingsToUpdate.size() > 0){
                List<Booking__c> adhocBookingsToUpdate  = processmakeupAdhocbookings(makeupAdhocbookingsToUpdate);
                if(adhocBookingsToUpdate != null && adhocBookingsToUpdate.size() > 0){
                    existingCancelBookingsToUpdate.addAll(adhocBookingsToUpdate);
                }
            }
            if(existingCancelBookingsToUpdate != null && existingCancelBookingsToUpdate.size() > 0){
                update existingCancelBookingsToUpdate;
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

    
    
}