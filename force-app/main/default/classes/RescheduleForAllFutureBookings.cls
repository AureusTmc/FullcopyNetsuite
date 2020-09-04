/*
Name        :        RescheduleForAllFutureBookings
Date        :        2019/10/08       
Description :        This class will take care of Reschedule all Bookings Functionality. It will Work on the Following basis
                        	If 5th lesson object & Reschedule All

                            o	Remove all future 5th lesson bookings
                            o	And create a fresh 5th lesson bookings based on the new timeslot

                        	If makeup/adhoc/placeholder & Reschedule All on different day

                            o	Create a fresh 5th lesson record based on the new timeslot
                            o	All future Makeup/Adhoc related to 5th week will be cancelled and makeup credit will be added back to the parent record
                            o	Makeup for adhoc booking will be added if the adhoc invoice was paid.
                            o	All future placeholder related to 5th week will be cancelled 
                            o	Remove all 5th lesson record
                            

                        	If makeup/adhoc/placeholder & Reschedule All on same day

                            o	All future Makeup related to 5th week will be rescheduled for the timeslot
                            o	All future 5th lesson record will be rescheduled to the timeslot
                            o   All Regular Bookings get Reschedule
*/
public without sharing class RescheduleForAllFutureBookings {

    Public Boolean dayChange;
    Public Enrolment__c enrolObj;
    Public Date effectiveDate;
    Public Date startDate;
    Public Map<String, Booking__c> mapOfBooking = new Map<String, Booking__c>();
    Public Map<String, Fifth_Lesson__c> mapOfFifthLesson = new Map<String, Fifth_Lesson__c>();
    Public String centreOrgId;

    //Constructor or start point of the functionality
    public RescheduleForAllFutureBookings(Boolean dayChange, Enrolment__c enrolObj, Date effectiveDate, Date startDate) {

        this.dayChange = dayChange;
        this.enrolObj = enrolObj;
        this.effectiveDate = effectiveDate;
        this.startDate = startDate;

        if(this.dayChange && String.isNotBlank(enrolObj.Id) && effectiveDate != NULL && startDate != NULL){
            //Day Change
            System.debug('@@@effectiveDate'+effectiveDate);
            centreOrgId = enrolObj.Center__r.Organisation__c;
            dayIsChanged(enrolObj, effectiveDate, startDate);
        }else{
            //Day Not Changed
            dayIsNotChanged(enrolObj, effectiveDate);
        }
    }

     /*
     *  This Method will Run when the Day is Changed and it will perform the following actions
     *      o	All future Makeup/Adhoc/Placeholder related to 5th week will be rescheduled for the timeslot
     *      o	All future 5th lesson record will be rescheduled to the timeslot
     *      o   All Regular Bookings get Reschedule
     */
    private void dayIsNotChanged(Enrolment__c enrolmentObj, Date effectiveDate){
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> allFifthLessonsToUpdate = new List<Fifth_Lesson__c>();

        //Fifth Lesson Section
        for(Fifth_Lesson__c fifthLesson : fetchAllFutureFifthLesson(enrolmentObj.Id, effectiveDate)){
            if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.pakageTypeMakeup){
                bookingsToUpdate.add(fifthLesson.Booking__r);
            }else if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.adhocPackageType){
                bookingsToUpdate.add(fifthLesson.Booking__r);
            }else if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Type__c == ConstantsClass.busyBookingType){
                bookingsToUpdate.add(fifthLesson.Booking__r);
            }
            allFifthLessonsToUpdate.add(fifthLesson);
        }

        if(String.isNotBlank(enrolmentObj.Id) && effectiveDate != NULL){
            bookingsToUpdate.addAll(fetchAllFutureRegularBookings(enrolmentObj.Id, effectiveDate));
        }

        if(String.isNotBlank(enrolmentObj.Id)){
            updateExistingBookingsAndLesson(bookingsToUpdate, allFifthLessonsToUpdate, enrolmentObj);
        }
    }


    /*
     *  This Method will Run when the Day is Changed and it will perform the following actions 
     *  o	Create a fresh 5th lesson record based on the new timeslot
     *  o	All future Makeup/Adhoc related to 5th week will be cancelled and makeup credit will be added back to the parent record
     *  o	Makeup for adhoc booking will be added if the adhoc invoice was paid.
     *  o	All future placeholder related to 5th week will be cancelled 
     *  o	Remove all 5th lesson record
     */
    private void dayIsChanged(Enrolment__c enrolmentObj, Date effectiveDate, Date startDate){
		system.debug('effectiveDate 17 july chnage'+effectiveDate +'===>>>'+startDate);
        Set<String> makeupBookingSet = new Set<String>();
        Set<String> adhocBookingSet = new Set<String>();
        Set<String> placeholderBookingSet = new Set<String>();
        Date maxDate;
        List<Fifth_Lesson__c> allFifthLessonsToDelete = new List<Fifth_Lesson__c>();

        //Fifth Lesson Section
        for(Fifth_Lesson__c fifthLesson : fetchAllFutureFifthLesson(enrolmentObj.Id, effectiveDate)){
            if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.pakageTypeMakeup){
                makeupBookingSet.add(fifthLesson.Booking__c);
            }else if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.adhocPackageType){
                adhocBookingSet.add(fifthLesson.Booking__c);
            }else if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Type__c == ConstantsClass.busyBookingType){
                placeholderBookingSet.add(fifthLesson.Booking__c);
            }
            allFifthLessonsToDelete.add(fifthLesson);
        }

        //Delete all future Placeholder Type Bookings for the Enrolment.
        if(placeholderBookingSet.size() > 0){
            processPlaceholderBookings(placeholderBookingSet);
        }

        //Cancel All Makeup Bookings and Rollback the Makeup Minutes to the parent.
        if(makeupBookingSet.size() > 0){
            processMakeupBookings(makeupBookingSet);
        }

        //Cancel Adhoc Bookings and Rollback the Makeup Minutes to parent if its Invoice is Paid
        if(adhocBookingSet.size() > 0){
            processAdhocBookings(adhocBookingSet);
        }

        //Delete the Regular Future Bookings and deduct the makeup units from parent of future cancelled bookings.
        if(String.isNotBlank(enrolmentObj.Id) && startDate != NULL){
            maxDate = getMaxDateOfEnrolmentBookings(enrolmentObj.Id);
            Integer lastDayOfMonth = Date.daysInMonth(maxDate.year(), maxDate.month());
            maxDate = Date.newInstance(maxDate.year(), maxDate.month(), lastDayOfMonth);
            processOldRegularBookings(enrolmentObj.Id, startDate);
        }

        if(allFifthLessonsToDelete.size() > 0){
            DELETE allFifthLessonsToDelete;
        }

        if(String.isNotBlank(enrolmentObj.Id)){
            
            if(maxDate != NULL && effectiveDate != NULL){
                reCreateRegularBookingsAndFifthLesson(enrolmentObj, effectiveDate, maxDate);
            }
        }
        if(maxDate != NULL && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.Teacher__c) && effectiveDate != NULL){
            processTeacherLeaves(enrolmentObj.Teacher__c, effectiveDate,  maxDate);
        }
        if(maxDate != NULL && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.Teacher__c) && effectiveDate != NULL && String.isNotBlank(centreOrgId)){
            processPublicHolidays(startDate, maxDate, centreOrgId, enrolmentObj.Teacher__r);
        }
        
        
    }

    /*
     *  fetch all Future Fifth Lesson For the perticular Enrolment.... 
     */
    private List<Fifth_Lesson__c> fetchAllFutureFifthLesson(String enrolId, Date bookingDate){
        // Added By Ravi on 17 july 2020 Lesson_Type__c,Is_Lesson_Type_Change__c in query....
        return [SELECT Id, IsActive__c, Booking__r.Booking_Date__c,Booking__r.Package__r.Type__c, Booking__r.Type__c,Booking__r.Lesson_Type__c,
                Booking__r.Is_Lesson_Type_Change__c FROM Fifth_Lesson__c 
                WHERE Enrolment__c = :enrolId AND Booking_Date__c >= :bookingDate];
    }

   /*
    *   Fetch all Future Regular Bookings For the Perticular Enrolment....
    */

    private List<Booking__c> fetchAllFutureRegularBookings(String enrolId, Date bookingDate){
        // Added By Ravi on 17 july 2020 Lesson_Type__c,Is_Lesson_Type_Change__c in query...
        return [SELECT Id, Type__c, Status__c, Booking_Date__c,Lesson_Type__c,Is_Lesson_Type_Change__c, Available_Make_up_Units__c, Duration__c, Make_up_Utilize_Bookings__c, 
                Teacher_Account__r.Employee_Duty_Type__c FROM Booking__c 
                WHERE Enrolment__c = :enrolId AND Booking_Date__c >= :bookingDate AND Type__c = :ConstantsClass.bookTypeRegular];
    }

    /*
     * This Method will fetch all Bookings according to the Id's
     */
    private List<Booking__c> fetchAllBookings(Set<String> bookingIds){
        List<Booking__c> bookingObjList = new List<Booking__c>();
        if(bookingIds.size() > 0){
            bookingObjList = [SELECT Id, Type__c, Enrolment__c, Package__r.Type__c, Available_Make_up_Units__c, Make_up_Utilize_Bookings__c, Booking_Date__c,
                              Status__c, Duration__c FROM Booking__c WHERE Id IN :bookingIds];
        }
        return bookingObjList;
    }

    /*
    *   This Method will Fetch Max Date of the Enrolment Regular Bookings
    */
    private Date getMaxDateOfEnrolmentBookings(String enrolId){
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
    *   This Method will Delete all Placeholder type Bookings for the Enrolment...
    */
    private void processPlaceholderBookings(Set<String> bookingIds){
        List<Booking__c> fifthPlacholder = new List<Booking__c>();
        for(String placeholder : bookingIds){
            fifthPlacholder.add(new Booking__c(Id = placeholder));

        }
        if(fifthPlacholder.size() > 0){
            DELETE fifthPlacholder;
        }
    }

    /*
    *   This Method will Process Future Makeup Type Bookings for the enrolment 
    *   by cancelling them and Rollback Makeup Minutes to parent
    */
    private void processMakeupBookings(Set<String> bookingIds){
        //Process Makeup
        List<Booking__c> makeupBooking = new List<Booking__c>();
        if(bookingIds.size() > 0){
            makeupBooking = fetchAllBookings(bookingIds);
        }
        if(makeupBooking.size() > 0){
            AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(makeupBooking);
        }
    } 

    /*
    *   This Method will Process Future Adhoc Type Bookings for the Enrolment
    *   by cancelling them and Rollback the makeup minutes to parent if its invoice is Paid
    *   and if its invoice is due then it gets cancelled and no makeup is rollback to parent.   
    */

    private void processAdhocBookings(Set<String> bookingIds) {
        //Map<String, Boolean> checkAdhocIsPaidMap = checkAdhocIsPaid(bookingIds);
        List<Booking__c> bookingList = new List<Booking__c>();
        for(Booking__c bookObj : fetchAllBookings(bookingIds)){
            //if(checkAdhocIsPaidMap.containsKey(bookObj.Id)){
                bookObj.Available_Make_up_Units__c = bookObj.Duration__c;
                bookObj.Make_up_Expiry_Date__c = bookObj.Booking_date__c.addDays(120);
            //}
            bookObj.status__c = ConstantsClass.statusCanceled;
            bookingList.add(bookObj);
        }
        if(bookingList.size() > 0){
            UPDATE bookingList;
        }
    } 

    /*
    *   This Method will Delete the Regular Booking and process the Cancel Future Bookings.
    */

    private void processOldRegularBookings(String enrolId, Date effectiveDate){
        
        if(String.isNotBlank(enrolId) && effectiveDate != NULL){
            List<Booking__c> bookingListToDelete = new List<Booking__c>();
            List<Booking__c> bookingsToUpsert = new List<Booking__c>();
            for(Booking__c bookObj : fetchAllFutureRegularBookings(enrolId, effectiveDate)){
                if(bookObj.Type__c == ConstantsClass.typeRegular && bookObj.Status__c == ConstantsClass.statusCanceled && bookObj.Available_Make_up_Units__c != NULL && bookObj.Available_Make_up_Units__c > 0){
                    bookingsToUpsert.add(new Booking__c(Id = bookObj.Id, Available_Make_up_Units__c = bookObj.Available_Make_up_Units__c - bookObj.Duration__c));
                }else{
                    bookingListToDelete.add(new Booking__c(Id = bookObj.Id));
                }
            }
            if(bookingsToUpsert.size() > 0){
                UPDATE bookingsToUpsert;
            }
            if(bookingListToDelete.size() > 0){
                DELETE bookingListToDelete;
            }
        }
    } 

    /*
    *   This Method will Recreate the Regular Bookings for Enrolment and fifth Lesson Records.
    */
    private void reCreateRegularBookingsAndFifthLesson(Enrolment__c  enrolmentObj, Date effectiveDate, Date maxDate){
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToInsert = new List<Fifth_Lesson__c>();
        System.debug('@@@@maxDate'+maxDate);
        if(String.isNotBlank(enrolmentObj.Id)){
            Booking__c bookingObj = new Booking__c();
            Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();
            System.debug('@@@@effectiveDate'+effectiveDate);
            while(effectiveDate <= maxdate){
                if(effectiveDate.day() > 28){
                    fifthLesson = new Fifth_Lesson__c();
                    fifthLesson.Booking_Date__c = effectiveDate;
                    fifthLesson.Center__c = enrolmentObj.Center__c;
                    fifthLesson.Enrolment__c = enrolmentObj.Id;
                    fifthLesson.IsActive__c = TRUE;
                    fifthLesson.Package__c = enrolmentObj.Package__c;
                    fifthLesson.Parent__c = enrolmentObj.Parent__c;
                    fifthLesson.Start_Time__c = enrolmentObj.Lesson_Start_time__c;
                    fifthLesson.Student__c = enrolmentObj.Student__c;
                    fifthLesson.Teacher_Account__c = enrolmentObj.Teacher__c;
                    if(enrolmentObj.Package__r.Duration__c != NULL){
                        fifthLesson.End_Time__c =  fifthLesson.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));       
                    }
                    fifthLessonToInsert.add(fifthLesson);

                }else{
                    bookingObj = new Booking__c();
                    // Added By Ravi on 17 july 2020 ...
                    bookingObj.Lesson_Type__c = enrolmentObj.Lesson_Mode__c;
                    if(enrolmentObj.Lesson_Mode__c == ConstantsClass.Online){
                        bookingObj.Is_Lesson_Type_Change__c=true; 
                    }
                        // Added By Ravi on 17 july 2020 ...  
                        //Start : added by Nishi : 30-Jul-2020 for update Resource id in reschedule future booking
                        //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        /*if(string.isnotBlank(enrolmentObj.Resource__c)){
                            bookingObj.Resource__c = enrolmentObj.Resource__c;
                        }*/
                        //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        //end : added by Nishi : 30-Jul-2020 for update Resource id in reschedule future booking
                    
                    bookingObj.Booking_Date__c = effectiveDate;
                    bookingObj.Teacher_Account__c = enrolmentObj.Teacher__c;
                    bookingObj.Parent__c = enrolmentObj.Parent__c;
                    bookingObj.Center__c = enrolmentObj.Center__c;
                    bookingObj.Student__c = enrolmentObj.Student__c;
                    bookingObj.Start_Time__c = enrolmentObj.Lesson_Start_time__c;
                    bookingObj.Enrolment__c = enrolmentObj.Id;
                    bookingObj.Package__c = enrolmentObj.Package__c;
                    bookingObj.Type__c = ConstantsClass.typeRegular;
                    if(enrolmentObj.Package__r.Duration__c != NULL){
                        bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));       
                    }
                    if(effectiveDate >= enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c){
                        bookingObj.Status__c = ConstantsClass.pendingStatus;
                    }else{
                        bookingObj.Status__c = ConstantsClass.scheduledStatus;
                    }
                    bookingsToInsert.add(bookingObj);
                }
                
                effectiveDate = effectiveDate.addDays(7);
            }       
        }

        if(bookingsToInsert.size() > 0){
            INSERT bookingsToInsert;
            for(Booking__c bookingObj : bookingsToInsert){
                mapOfBooking.put(bookingObj.Booking_Date__c + '-' + bookingObj.Teacher_Account__c, bookingObj);
            }
        }
        System.debug('@@@@bookingsToInsert'+bookingsToInsert);
        if(fifthLessonToInsert.size() > 0){
            INSERT fifthLessonToInsert;
            for(Fifth_Lesson__c lessonFifth : fifthLessonToInsert){
                mapOfFifthLesson.put(lessonFifth.Booking_Date__c + '-' + lessonFifth.Teacher_Account__c, lessonFifth);
            }
        }
        System.debug('@@@@fifthLessonToInsert'+fifthLessonToInsert);
    }

    private void updateExistingBookingsAndLesson(List<Booking__c> bookingList, List<Fifth_Lesson__c> fifthLessons, Enrolment__c enrolObj){
        
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonsToUpdate = new List<Fifth_Lesson__c>();
        if(String.isNotBlank(enrolObj.Id)){
            for(Booking__c bookObj : bookingList){
                // Added By Ravi on 17 july 2020 to update lesson type as per the Enrolment
                
                if(bookObj.Booking_Date__c != effectiveDate){
                    bookObj.Lesson_Type__c=enrolObj.Lesson_Mode__c;
                    if(enrolObj.Lesson_Mode__c == ConstantsClass.Online){
                        bookObj.Is_Lesson_Type_Change__c=true;
                    }
                }
                 // Added By Ravi on 17 july 2020 to update lesson type as per the Enrolment
                bookObj.start_Time__c = enrolObj.Lesson_Start_time__c;
                if(enrolObj.Package__r.Duration__c != NULL){
                    bookObj.End_Time__c =  bookObj.Start_Time__c.addMinutes(Integer.valueOf(enrolObj.Package__r.Duration__c));       
                }
                bookObj.Teacher_Account__c = enrolObj.Teacher__c;
                bookingsToUpdate.add(bookObj);
            }
            for(Fifth_Lesson__c fifthLesson: fifthLessons){
                fifthLesson.Start_Time__c = enrolObj.Lesson_Start_time__c;
                if(enrolObj.Package__r.Duration__c != NULL){
                    fifthLesson.End_Time__c =  fifthLesson.Start_Time__c.addMinutes(Integer.valueOf(enrolObj.Package__r.Duration__c));       
                }
                fifthLesson.Teacher_Account__c = enrolObj.Teacher__c;
                fifthLessonsToUpdate.add(fifthLesson);
            }
        }
        if(bookingsToUpdate.size() > 0){
            UPDATE bookingsToUpdate;
        }
        if(fifthLessonsToUpdate.size() > 0){
            UPDATE fifthLessonsToUpdate;
        }
    }


    private void processTeacherLeaves(String teacherId, Date startDate, Date maxDate){
        Set<String> setOfTeachersLeaves = new Set<String>();

        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();

        Map<String, Booking__c> updatedBookingMap = new Map<String, Booking__c>(); 
        Map<String, Fifth_Lesson__c> updatedLessonMap = new Map<String, Fifth_Lesson__c>();

        if(String.isNotBlank(teacherId) && StartDate != NULL && maxDate != NULL){
            setOfTeachersLeaves = fetchTeacherLeavesRequestDateSet(teacherId, StartDate, maxDate);
        }
        for(String keySetValue : mapOfBooking.keySet()){
            if(setOfTeachersLeaves.contains(keySetValue)){
                Booking__c bookObj = mapOfBooking.get(keySetValue);
                bookObj.Status__c = ConstantsClass.statusCanceled;
                bookObj.Available_Make_up_Units__c = bookObj.Duration__c; 
                bookObj.Make_up_Expiry_Date__c  = bookObj.Booking_Date__c.addDays(120);
                bookObj.Makeup_Reason__c = 'Teacher Mc';
                bookObj.Cancellation_Reason__c = 'Teacher Mc';
                bookObj.Remarks__c = 'Teacher Leave';
                bookingtoUpdate.add(bookObj);
                updatedBookingMap.put(keySetValue, bookObj);
            }
        }
        for(String keySetValue : mapOfFifthLesson.keySet()){
            if(setOfTeachersLeaves.contains(keySetValue)){
                Fifth_Lesson__c lesson = mapOfFifthLesson.get(keySetValue);
                lesson.IsActive__c = FALSE;
                fifthLessonToUpdate.add(lesson);
                updatedLessonMap.put(keySetValue, lesson);
            }
        }
        if(updatedBookingMap.size() > 0){
            mapOfBooking.putAll(updatedBookingMap);
        }
        if(updatedLessonMap.size() > 0){
            mapOfFifthLesson.putAll(updatedLessonMap);
        }
        if(fifthLessonToUpdate.size() > 0){
            fifthLessonToUpdate = createPlaceholderBookingFromFifthLesson(fifthLessonToUpdate);
            for(Fifth_Lesson__c fifthLesson : fifthLessonToUpdate){
                fifthLesson.Booking__c = fifthLesson.Booking__r.Id;
            }
            UPDATE fifthLessonToUpdate;
        }
        if(bookingtoUpdate.size() > 0){
            
            List<Case> caseList = AureusUtility.createCase(bookingtoUpdate);
            insert caseList;
            bookingtoUpdate.addAll(createPlaceholderFromBooking(bookingtoUpdate));
            UPSERT bookingtoUpdate;
            Set<Id> csIds = new Set<Id>();
            for(Case c : caseList)
                csIds.add(c.Id);
            AureusUtility.sendCaseEmail(csIds);
        }

    }

    private void processPublicHolidays(Date startDate, Date maxDate, String centreOrgId, Account teacherObj){
        Map<String, Public_Holiday__c> mapOfPublicLeaves = new Map<String, Public_Holiday__c>();
        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();

        Map<String, Booking__c> updatedBookingMap = new Map<String, Booking__c>(); 
        Map<String, Fifth_Lesson__c> updatedLessonMap = new Map<String, Fifth_Lesson__c>();
        if(startDate != NULL && maxDate != NULL && String.isNotBlank(centreOrgId) && String.isNotBlank(teacherObj.Id)){
            mapOfPublicLeaves = fetchPublicHolidaysDateMap(startDate, maxDate, centreOrgId, teacherObj);
        }

        for(String keySetValue : mapOfBooking.keySet()){
            if(mapOfPublicLeaves.containsKey(keySetValue) && mapOfBooking.get(keySetValue).Status__c != ConstantsClass.statusCanceled){
                Booking__c bookObj = mapOfBooking.get(keySetValue);
                bookObj.Status__c = ConstantsClass.statusCanceled;
                bookObj.Available_Make_up_Units__c = bookObj.Duration__c; 
                bookObj.Make_up_Expiry_Date__c  = bookObj.Booking_Date__c.addDays(120);
                bookObj.Remarks__c = 'Public Holiday';
                bookObj.Cancellation_Reason__c   = 'Holidays';
                bookObj.Public_Holiday_Status__c = mapOfPublicLeaves.get(keySetValue).Organisation_Status__c;
                bookingtoUpdate.add(bookObj);
                updatedBookingMap.put(keySetValue, bookObj);
            }
        }

        for(String keySetValue : mapOfFifthLesson.keySet()){
            if(mapOfPublicLeaves.containsKey(keySetValue)){
                Fifth_Lesson__c lesson = mapOfFifthLesson.get(keySetValue);
                lesson.IsActive__c = FALSE;
                fifthLessonToUpdate.add(lesson);
                updatedLessonMap.put(keySetValue, lesson);
            }
        }

        if(updatedBookingMap.size() > 0){
            mapOfBooking.putAll(updatedBookingMap);
        }
        if(updatedLessonMap.size() > 0){
            mapOfFifthLesson.putAll(updatedLessonMap);
        } 

        if(fifthLessonToUpdate.size() > 0){
            fifthLessonToUpdate = createPlaceholderBookingFromFifthLesson(fifthLessonToUpdate);
            for(Fifth_Lesson__c fifthLesson : fifthLessonToUpdate){
                fifthLesson.Booking__c = fifthLesson.Booking__r.Id;
            }
            UPDATE fifthLessonToUpdate;
        }
        if(bookingtoUpdate.size() > 0){
            
            List<Case> caseList = AureusUtility.createCase(bookingtoUpdate);
            insert caseList;
            bookingtoUpdate.addAll(createPlaceholderFromBooking(bookingtoUpdate));
            UPSERT bookingtoUpdate;
            Set<Id> csIds = new Set<Id>();
            for(Case c : caseList)
                csIds.add(c.Id);
            AureusUtility.sendCaseEmail(csIds);
        }    
    }

    private Set<String> fetchTeacherLeavesRequestDateSet(String teacherId, Date startDate, Date maxDate){
        System.debug('@@@@@startDate'+startDate);
        System.debug('@@@@@maxDate'+maxDate);
        Set<String> setOfTeachersLeave = new Set<String>();
        for(Leave_Request__c leaveRequest : [SELECT Id, Name, Leave_Type__c, Employee__c, Leave_Start_Date__c, Leave_End_Date__c 
                                             FROM Leave_Request__c WHERE Employee__c = :teacherId AND Leave_Start_Date__c >= :startDate AND 
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

    private Map<String, Public_Holiday__c> fetchPublicHolidaysDateMap(Date startDate, Date maxDate, String centreOrgId, Account teacherObj){
        Map<String, Public_Holiday__c> mapOfHolidaysLeave = new Map<String, Public_Holiday__c>();
        for(Public_Holiday__c holiday : [SELECT Id, Name, Public_Holiday_Date__c,Organisation_Status__c 
                                            FROM Public_Holiday__c 
                                            WHERE Organisation__c =: centreOrgId AND Public_Holiday_Date__c >= :startDate AND Public_Holiday_Date__c <= :maxDate 
                                            AND Status__c IN('Execution completed') AND Organisation_Status__c != null]){
                if(holiday.Organisation_Status__c == 'Closed' || (holiday.Organisation_Status__c == 'Open' && teacherObj.Employee_Duty_Type__c=='Duty')){
                    mapOfHolidaysLeave.put(holiday.Public_Holiday_Date__c + '-' + teacherObj.Id, holiday);
                }
        }
        return mapOfHolidaysLeave;
    }

    private List<Fifth_Lesson__c> createPlaceholderBookingFromFifthLesson(List<Fifth_Lesson__c> fifthLessons){
        List<Booking__c> bookList = new List<Booking__c>();  
        Booking__c bookObj;
        
        for(Fifth_Lesson__c fifthLesson : fetchFifthLessons(fifthLessons)){
            bookObj = new Booking__c();
            bookObj.Booking_Date__c = fifthLesson.Booking_Date__c;
            bookObj.Center__c = fifthLesson.Center__c;
            bookObj.End_Time__c = fifthLesson.End_Time__c;
            bookObj.Enrolment__c = fifthLesson.Enrolment__c;
            bookObj.Package__c = fifthLesson.Package__c;
            bookObj.Parent__c = fifthLesson.Parent__c;
            bookObj.Start_Time__c = fifthLesson.Start_Time__c;
            bookObj.Student__c = fifthLesson.Student__c;
            bookObj.Teacher_Account__c = fifthLesson.Teacher_Account__c;
            bookObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            bookObj.Type__c = ConstantsClass.busyBookingType;    
            bookObj.Status__c = ConstantsClass.scheduledStatus;
            bookObj.remarks__c = 'placeholder booking for Fifth Lesson '+ fifthLesson.Student__r.Name + ' booking';
            fifthLesson.Booking__r = bookObj;
            fifthLesson.Remarks__c = 'Fifth Lesson Cancel Due to Holiday/Teacher Leave.';
            bookList.add(bookObj);
        }

        if(bookList.size() > 0){
            INSERT bookList;
        }


        return fifthLessons;
    }

    private List<Fifth_Lesson__c> fetchFifthLessons(List<Fifth_Lesson__c> fifthLesson){
        Set<String> fifthSet = new Set<String>();
        for(Fifth_Lesson__c fifthLessonObj : fifthLesson){
            fifthSet.add(fifthLessonObj.Id);
        }
        return [SELECT Id, Booking_Date__c, Center__c, End_Time__c, Enrolment__c, Event_Color__c, Parent__r.Name, Start_Time__c, 
                Student__r.Name, Teacher_Account__c, Package__c FROM Fifth_Lesson__c WHERE Id IN :fifthSet];
    }

    private List<Booking__c> createPlaceholderFromBooking(List<Booking__c> bookingObjList){
        
        List<Booking__c> placeholderList = new List<Booking__c>();
        for(Booking__c bookingCurrentObj : bookingObjList){
            Booking__c placeholderObj = new Booking__c();
            placeholderObj.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            placeholderObj.Type__c = ConstantsClass.typeBusy;
            
            //Start : added by Nishi : 30-Jul-2020 for update Resource id in reschedule future booking
             //start:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
            /*if(string.isnotBlank(bookingCurrentObj.Resource__c)){
                placeholderObj.Resource__c = bookingCurrentObj.Resource__c;
            }*/
             //end:Commented By nishi: 4-Aur-2020: Now this work managed in Booking trigger so we don't want to insert resource
                        
            //end : added by Nishi : 30-Jul-2020 for update Resource id in reschedule future booking

            placeholderObj.Booking_Date__c = bookingCurrentObj.Booking_Date__c;
            placeholderObj.Start_Time__c = bookingCurrentObj.Start_Time__c ;
            placeholderObj.End_Time__c = bookingCurrentObj.End_Time__c;
            placeholderObj.status__c = ConstantsClass.scheduledStatus;
            placeholderObj.Teacher_Account__c = bookingCurrentObj.Teacher_Account__c;
            placeholderObj.Center__c = bookingCurrentObj.Center__c;
            placeholderObj.remarks__c = 'placeholder booking for cancelling '+ bookingCurrentObj.Student__r.Name + ' booking';
            //placeholderObj.Category__c = bookingCurrentObj.Cancellation_Reason__c == 'Holidays' ? ConstantsClass.holidayCategory : ConstantsClass.leaveCategory;
            placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
            placeholderObj.Enrolment__c= bookingCurrentObj.Enrolment__c;
            placeholderObj.Student__c  = bookingCurrentObj.Student__c;
            placeholderObj.Package__c  = bookingCurrentObj.Package__c;
            placeholderList.add(placeholderObj);
        }
        return placeholderList;
    }

    /*
    *   This Method will Fetch all adhoc invoices status
    */
    /*private Map<String, Boolean> checkAdhocIsPaid(Set<String> bookingIds){
        Map<String, Boolean> checkAdhocIsPaidMap = new Map<String, Boolean>();
        Boolean needToRevert;
        for(Invoice_Line_Item__c invoiceLineItem : [SELECT Id, Invoice__c, Invoice__r.Status__c, Booking__c FROM Invoice_Line_Item__c WHERE Booking__c IN :bookingIds]){
            if(invoiceLineItem.Invoice__r.Status__c == ConstantsClass.paidStatus){
                needToRevert = true;    
            }else if(invoiceLineItem.Invoice__r.Status__c == ConstantsClass.dueStatus){
                needToRevert = false;    
            }
            checkAdhocIsPaidMap.put(invoiceLineItem.Booking__c, needToRevert);
        }
        return checkAdhocIsPaidMap;
    }*/
}