/*
Name        :        RescheduleAllCenterBookings
Date        :        2020/Aug/28       
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

*/
public without sharing class RescheduleAllCenterBookings {

    Public Boolean dayChange;
    Public Boolean isOssia; // added by nishi: 24-Aug-2020: if teacher Leave is found and we update  Ossia org enrolment then we added 180 expiry days otherwise we added 120 days for other students
    Public Enrolment__c enrolObj;
    Public Date effectiveDate;
    Public Date effectivestartDate;
    Public Map<String, Booking__c> mapOfBooking = new Map<String, Booking__c>();
    Public Map<String, Fifth_Lesson__c> mapOfFifthLesson = new Map<String, Fifth_Lesson__c>();
    Public String centreOrgId;
    public List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings;
    //Constructor or start point of the functionality
    public RescheduleAllCenterBookings(Enrolment__c enrolObj, Date effectiveDate) {
         // added by nishi: 22-Aug-2020: for manage ossia organization student we added 180 days in expiry dates
         listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
         Language, NamespacePrefix,Makeup_Expiry_Days_For_Public_Holiday__c, Label, QualifiedApiName, Makeup_Expiry_Days__c,
         Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
         WHERE Label =:System.Label.Ossia_Organisation_Name];
         system.debug('listOfOssia_Organisation_Settings'+listOfOssia_Organisation_Settings);
         // added by nishi: 22-Aug-2020: for manage ossia organization student  we added 180 days in expiry dates
        this.enrolObj = enrolObj;
        this.effectiveDate = effectiveDate;
        //11-Sep-2020: Nishi:user can change lesson day so we manage this new lesson so we delete all future booking with the start of effective month
        this.effectivestartDate = Date.newInstance(effectiveDate.year(),effectiveDate.month(),1);
        this.isOssia = false;
        // Added by nishi: 24-Aug-2020:Start: for ossia students booking will cancel then we added expiry date 180
        // otherwise we added 120 days for other students
        if(String.isNotBlank(enrolObj.Center__c) && 
        String.isNotBlank(enrolObj.Center__r.Organisation__c) && 
        String.isNotBlank(enrolObj.Center__r.Organisation__r.Name) && 
        enrolObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){ 
            this.isOssia= true;
        } 
        if(enrolObj.Center__r != null && string.isNotBlank(enrolObj.Center__r.Organisation__c))
            centreOrgId = enrolObj.Center__r.Organisation__c;
        system.debug('@@@centreOrgId'+centreOrgId);
        dayIsChanged(enrolObj, effectiveDate,effectivestartDate);
        
    }

   
    /*
     *  This Method will Run when the Day is Changed and it will perform the following actions 
     *  o	Create a fresh 5th lesson record based on the new timeslot,new teacher and new package
     *  o	All future Makeup/Adhoc related to 5th week will be cancelled and makeup credit will be added back to the parent record
     *  o	Makeup for adhoc booking will be added if the adhoc invoice was paid.
     *  o	All future placeholder related to 5th week will be cancelled 
     *  o	Remove all 5th lesson record
     */
    private void dayIsChanged(Enrolment__c enrolmentObj, Date effectiveDate,Date effectivestartDate){

        Set<String> makeupBookingSet = new Set<String>();
        Set<String> adhocBookingSet = new Set<String>();
        Set<String> placeholderBookingSet = new Set<String>();
        Date maxDate;
        List<Fifth_Lesson__c> allFifthLessonsToDelete = new List<Fifth_Lesson__c>();

        //Fifth Lesson Section
        for(Fifth_Lesson__c fifthLesson : fetchAllFutureFifthLesson(enrolmentObj.Id, effectivestartDate)){
            if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.pakageTypeMakeup){
                makeupBookingSet.add(fifthLesson.Booking__c);
            }else if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.adhocPackageType){
                adhocBookingSet.add(fifthLesson.Booking__c);
            }else if((!fifthLesson.isActive__c) && String.isNotBlank(fifthLesson.Booking__c) && fifthLesson.Booking__r.Type__c == ConstantsClass.busyBookingType){
                placeholderBookingSet.add(fifthLesson.Booking__c);
            }
            allFifthLessonsToDelete.add(fifthLesson);
        }
        // system.debug('@@dayIsChanged all future makeupBooking =='+makeupBookingSet );
        // system.debug('@@dayIsChanged all future adhocBookingSet  =='+adhocBookingSet );
        // system.debug('@@dayIsChanged all future placeholderBookingSet  =='+placeholderBookingSet );
       
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
        if(String.isNotBlank(enrolmentObj.Id) && effectiveDate != NULL){
            maxDate = getMaxDateOfEnrolmentBookings(enrolmentObj.Id);
            Integer lastDayOfMonth = Date.daysInMonth(maxDate.year(), maxDate.month());
            maxDate = Date.newInstance(maxDate.year(), maxDate.month(), lastDayOfMonth);
            //11-Sep-2020: Nishi:user can change lesson day so we manage this new lesson so we delete all future booking with the start of effective month
            processOldRegularBookings(enrolmentObj.Id, effectivestartDate);
        }
         system.debug('@@dayIsChanged all future FifthLessons To Delete =='+allFifthLessonsToDelete );
        if(allFifthLessonsToDelete.size() > 0){
            DELETE allFifthLessonsToDelete;
        }

        if(String.isNotBlank(enrolmentObj.Id)){
            if(maxDate != NULL && effectiveDate != NULL){
                reCreateRegularBookingsAndFifthLesson(enrolmentObj, effectiveDate, maxDate);
            }
        }
        if(maxDate != NULL && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.New_Teacher__c) && effectiveDate != NULL){
            processTeacherLeaves(enrolmentObj.New_Teacher__c, effectiveDate,  maxDate);
        }
        system.debug('enrolmentObj.New_Teacher__c'+enrolmentObj.New_Teacher__c);
        if(maxDate != NULL && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.New_Teacher__c) && effectiveDate != NULL && String.isNotBlank(centreOrgId)){
            List<Account> teacherlist = [select id,Employee_Duty_Type__c from Account where Id =: enrolmentObj.New_Teacher__c]; 
            if(teacherlist != null && teacherlist.size() > 0)
                processPublicHolidays(effectiveDate, maxDate, centreOrgId, teacherlist[0]);
        }
        
    }

    /*
     *  fetch all Future Fifth Lesson For the perticular Enrolment.... 
     */
    private List<Fifth_Lesson__c> fetchAllFutureFifthLesson(String enrolId, Date bookingDate){
        return [SELECT Id, IsActive__c, Booking__r.Package__r.Type__c, Booking__r.Type__c FROM Fifth_Lesson__c 
                WHERE Enrolment__c = :enrolId AND Booking_Date__c >= :bookingDate];
    }

   /*
    *   Fetch all Future Regular Bookings For the Perticular Enrolment....
    */

    private List<Booking__c> fetchAllFutureRegularBookings(String enrolId, Date bookingDate){
        return [SELECT Id, Type__c, Status__c, Booking_Date__c, Available_Make_up_Units__c, Duration__c, Make_up_Utilize_Bookings__c, 
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
        system.debug('@@regular booking maxDate =='+maxDate);
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
        system.debug('@@ deleted fifthPlacholder bookings are =' +fifthPlacholder);
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
        system.debug('@@ for  update makeup Booking  are =' +makeupBooking);
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
            bookObj.Available_Make_up_Units__c = bookObj.Duration__c;
            if(isOssia){
                if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                    bookObj.Make_up_Expiry_Date__c=bookObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days__c)));
                }
            }else{
                bookObj.Make_up_Expiry_Date__c  = bookObj.Booking_Date__c.addDays(120);
            }
            bookObj.status__c = ConstantsClass.statusCanceled;
            bookingList.add(bookObj);
        }
        system.debug('@@@ updated process Adhoc Bookings are == '+bookingList);
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
            system.debug('@@@processOldRegularBookings effectiveDate'+effectiveDate);
            for(Booking__c bookObj : fetchAllFutureRegularBookings(enrolId, effectiveDate)){
                if(bookObj.Type__c == ConstantsClass.typeRegular && bookObj.Status__c == ConstantsClass.statusCanceled && bookObj.Available_Make_up_Units__c != NULL && bookObj.Available_Make_up_Units__c > 0){
                    bookingsToUpsert.add(new Booking__c(Id = bookObj.Id, Available_Make_up_Units__c = bookObj.Available_Make_up_Units__c - bookObj.Duration__c));
                }else{
                    bookingListToDelete.add(new Booking__c(Id = bookObj.Id));
                }
            }
            system.debug('@@processOldRegularBookings bookingsToUpsert'+bookingsToUpsert);
            if(bookingsToUpsert.size() > 0){
                UPDATE bookingsToUpsert;
            }
            system.debug('@@processOldRegularBookings bookingListToDelete'+bookingListToDelete);
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
        System.debug('@@@@reCreateRegularBookingsAndFifthLesson maxDate'+maxDate);
        System.debug('@@@@reCreateRegularBookingsAndFifthLesson enrolmentObj'+enrolmentObj);
        System.debug('@@@@reCreateRegularBookingsAndFifthLesson effectiveDate'+effectiveDate);
        if(String.isNotBlank(enrolmentObj.Id)){
            // get new active subscription invoice 
            List<Subscription_Line_Item__c> sublineItemList = ChangeCenterEnrolmentProcessController.fetchsublineItemList(enrolmentObj.id);
            Booking__c bookingObj = new Booking__c();
            Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();
            while(effectiveDate <= maxdate){
                if(effectiveDate.day() > 28){
                    fifthLesson = new Fifth_Lesson__c();
                    if(effectiveDate != null )
                        fifthLesson.Booking_Date__c = effectiveDate;
                    if(string.isNotBlank(enrolmentObj.New_Centre__c))
                        fifthLesson.Center__c = enrolmentObj.New_Centre__c;
                    else if(string.isNotBlank(enrolmentObj.Center__c))
                        fifthLesson.Center__c = enrolmentObj.Center__c;

                    if(string.isNotBlank(enrolmentObj.Id))
                        fifthLesson.Enrolment__c = enrolmentObj.Id;
                    fifthLesson.IsActive__c = TRUE;
                    
                    if(string.isNotBlank(enrolmentObj.new_package_Id__c))
                        fifthLesson.Package__c = enrolmentObj.new_package_Id__c;
                    else if(string.isNotBlank(enrolmentObj.package__c))    
                        fifthLesson.Package__c = enrolmentObj.package__c;
                    
                    if(string.isNotBlank(enrolmentObj.Parent__c))
                        fifthLesson.Parent__c = enrolmentObj.Parent__c;
                    
                    if(enrolmentObj.Next_Lesson_Start_time__c != null)
                        fifthLesson.Start_Time__c = enrolmentObj.Next_Lesson_Start_time__c;
                    else if(enrolmentObj.Lesson_Start_time__c != null)
                        fifthLesson.Start_Time__c = enrolmentObj.Lesson_Start_time__c;
                    if(string.isNotBlank(enrolmentObj.Student__c))
                        fifthLesson.Student__c = enrolmentObj.Student__c;
                    if(string.isNotBlank(enrolmentObj.New_Teacher__c))
                        fifthLesson.Teacher_Account__c = enrolmentObj.New_Teacher__c;
                    else if(string.isNotBlank(enrolmentObj.Teacher__c))    
                        fifthLesson.Teacher_Account__c = enrolmentObj.Teacher__c;
                    
                    if(fifthLesson.Start_Time__c != null && enrolmentObj.new_package_Id__r != null && enrolmentObj.new_package_Id__r.Duration__c != NULL){
                            fifthLesson.End_Time__c =  fifthLesson.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.new_package_Id__r.Duration__c));       
                    
                    }else if(fifthLesson.Start_Time__c != null && enrolmentObj.Package__r != null && enrolmentObj.Package__r.Duration__c != NULL){
                            fifthLesson.End_Time__c =  fifthLesson.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));       
                    }

                    fifthLessonToInsert.add(fifthLesson);

                }else{
                    bookingObj = new Booking__c();
                    if(effectiveDate != null )
                        bookingObj.Booking_Date__c = effectiveDate;
                    
                    if(string.isNotBlank(enrolmentObj.New_Teacher__c))
                        bookingObj.Teacher_Account__c = enrolmentObj.New_Teacher__c;
                    else if(string.isNotBlank(enrolmentObj.Teacher__c)) 
                        bookingObj.Teacher_Account__c = enrolmentObj.Teacher__c;
                    
                    if(string.isNotBlank(enrolmentObj.Parent__c))
                        bookingObj.Parent__c = enrolmentObj.Parent__c;
                    if(string.isNotBlank(enrolmentObj.Student__c))
                        bookingObj.Student__c = enrolmentObj.Student__c;

                    if(string.isNotBlank(enrolmentObj.New_Centre__c))
                        bookingObj.Center__c = enrolmentObj.New_Centre__c;
                    else if(string.isNotBlank(enrolmentObj.Center__c))
                        bookingObj.Center__c = enrolmentObj.Center__c;    
                    
                    if(enrolmentObj.Next_Lesson_Start_time__c != NULL)
                     bookingObj.Start_Time__c = enrolmentObj.Next_Lesson_Start_time__c;
                    else if(enrolmentObj.Lesson_Start_time__c != NULL)
                        bookingObj.Start_Time__c = enrolmentObj.Lesson_Start_time__c;
                    
                    if(string.isNotBlank(enrolmentObj.Id))
                        bookingObj.Enrolment__c = enrolmentObj.Id;
                    
                    if(string.isNotBlank(enrolmentObj.new_package_Id__c))
                        bookingObj.Package__c = enrolmentObj.new_package_Id__c;
                    else if(string.isNotBlank(enrolmentObj.package__c))
                        bookingObj.Package__c = enrolmentObj.package__c;
                    
                    bookingObj.Type__c = ConstantsClass.typeRegular;
                    if(  bookingObj.Start_Time__c != null && enrolmentObj.new_package_Id__r != null && enrolmentObj.new_package_Id__r.Duration__c != NULL){
                        bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.new_package_Id__r.Duration__c));       
                    }else if(  bookingObj.Start_Time__c != null && enrolmentObj.Package__r != null && enrolmentObj.Package__r.Duration__c != NULL){
                        bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));       
                    }

                    if(sublineItemList != null && sublineItemList.size() > 0 && 
                    sublineItemList[0].Next_Bill_Date__c != null && effectiveDate != null && 
                       effectiveDate >= sublineItemList[0].Next_Bill_Date__c){
                       bookingObj.Status__c = ConstantsClass.pendingStatus;
                    }else{
                        bookingObj.Status__c = ConstantsClass.scheduledStatus;
                    }
                    bookingsToInsert.add(bookingObj);
                }
                
                effectiveDate = effectiveDate.addDays(7);
                system.debug('@@@new effectiveDate'+effectiveDate);
            }       
        }

        if(bookingsToInsert.size() > 0){
            INSERT bookingsToInsert;
            system.debug('@@@New Bookings are Inserted '+bookingsToInsert);

            for(Booking__c bookingObj : bookingsToInsert){
                mapOfBooking.put(bookingObj.Booking_Date__c + '-' + bookingObj.Teacher_Account__c, bookingObj);
            }
        }
        System.debug('@@@@mapOfBooking --'+mapOfBooking);
        if(fifthLessonToInsert.size() > 0){
            INSERT fifthLessonToInsert;
            system.debug('@@@New fifthLesson are Inserted '+fifthLessonToInsert);
            for(Fifth_Lesson__c lessonFifth : fifthLessonToInsert){
                mapOfFifthLesson.put(lessonFifth.Booking_Date__c + '-' + lessonFifth.Teacher_Account__c, lessonFifth);
            }
        }
        System.debug('@@@@mapOfFifthLesson --'+mapOfFifthLesson);
    }
   
  

    private void processTeacherLeaves(String teacherId, Date effectiveDate, Date maxDate){
        Set<String> setOfTeachersLeaves = new Set<String>();

        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();

        Map<String, Booking__c> updatedBookingMap = new Map<String, Booking__c>(); 
        Map<String, Fifth_Lesson__c> updatedLessonMap = new Map<String, Fifth_Lesson__c>();
        system.debug('@@@processTeacherLeaves teacherId -'+teacherId);
        system.debug('@@@processTeacherLeaves effectiveDate -'+effectiveDate);
        system.debug('@@@processTeacherLeaves maxDate -'+maxDate);
        if(String.isNotBlank(teacherId) && effectiveDate != NULL && maxDate != NULL){
            setOfTeachersLeaves = fetchTeacherLeavesRequestDateSet(teacherId, effectiveDate, maxDate);
        }
        for(String keySetValue : mapOfBooking.keySet()){
            if(setOfTeachersLeaves.contains(keySetValue)){
                Booking__c bookObj = mapOfBooking.get(keySetValue);
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
                updatedBookingMap.put(keySetValue, bookObj);
            }
        }
        system.debug('@@@@ teacher leave then cancel booking and updated booking are =='+bookingtoUpdate);
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
            system.debug('@@ create Placeholder booking for fifth lesson  '+fifthLessonToUpdate);
            for(Fifth_Lesson__c fifthLesson : fifthLessonToUpdate){
                fifthLesson.Booking__c = fifthLesson.Booking__r.Id;
            }
            UPDATE fifthLessonToUpdate;
        }
        system.debug('@@@upated fifth bookings are  fifthLessonToUpdate'+fifthLessonToUpdate);
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
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();

        Map<String, Booking__c> updatedBookingMap = new Map<String, Booking__c>(); 
        Map<String, Fifth_Lesson__c> updatedLessonMap = new Map<String, Fifth_Lesson__c>();
        system.debug('@@processPublicHolidays effectiveDate'+effectiveDate);
        system.debug('@@processPublicHolidays teacherObj'+teacherObj);
        system.debug('@@processPublicHolidays centreOrgId'+centreOrgId);
        system.debug('@@processPublicHolidays maxDate'+maxDate);
        system.debug('@@processPublicHolidays teacherObj.id'+teacherObj.Id);
        if(effectiveDate != NULL && maxDate != NULL && teacherObj != NULL && String.isNotBlank(centreOrgId) && String.isNotBlank(teacherObj.Id)){
            mapOfPublicLeaves = fetchPublicHolidaysDateMap(effectiveDate, maxDate, centreOrgId, teacherObj);
        }

        for(String keySetValue : mapOfBooking.keySet()){
            if(mapOfPublicLeaves != null && mapOfPublicLeaves.size() > 0 &&
               mapOfPublicLeaves.containsKey(keySetValue) && mapOfBooking.get(keySetValue).Status__c != ConstantsClass.statusCanceled){
                Booking__c bookObj = mapOfBooking.get(keySetValue);
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
                updatedBookingMap.put(keySetValue, bookObj);
            }
        }
        system.debug('@@@cancel booking for public holiday to Update'+bookingtoUpdate);

        for(String keySetValue : mapOfFifthLesson.keySet()){
            if(mapOfPublicLeaves.containsKey(keySetValue)){
                Fifth_Lesson__c lesson = mapOfFifthLesson.get(keySetValue);
                lesson.IsActive__c = FALSE;
                fifthLessonToUpdate.add(lesson);
                updatedLessonMap.put(keySetValue, lesson);
            }
        }
        system.debug('@@@deActivate Fifth bookings '+fifthLessonToUpdate);
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
        system.debug('@@@updated  fifthLessonToUpdate '+fifthLessonToUpdate);
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
    // update 21 09 2020 @nishi jain 
	@TestVisible
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
        system.debug('@@@ inserted placeholder bookings are  ='+bookList);

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
        system.debug('@@@ create new Placeholder for bookings =='+placeholderList);
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