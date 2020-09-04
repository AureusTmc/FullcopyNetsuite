/*
    Name    : BookingTrigger 
   
    
*/
trigger BookingTrigger on Booking__c (before insert,after update, after insert,after delete,after undelete) {
    
    Firebase_Settings__c settings = Firebase_Settings__c.getValues('setting');
    // added by jatin: 14-feb:2020: for calculate no.of enrolment in camp class 
    map<String,String> mapOfCampClassAndCampDay= new map<String,String>();
    if(trigger.isInsert && trigger.isBefore){
        //Populate parentId
        BookingTriggerHelper.populatePrentInBooking(Trigger.new);
        // start: Nishi- 4-Aug-2020: for if new booking created and resource id not found then we added resource Id using enrolment or teacher Working hrs. 
        BookingTriggerHelper.populateResourceInBooking(Trigger.new);
       // end: Nishi- 4-Aug-2020: for if new booking created and resource id not found then we added resource Id using enrolment or teacher Working hrs.
        for(Booking__c book : Trigger.new){
            book.Name = 'New Booking Name';
        }
    }
    
    //################### Added on 25 June 2019 By Karan Singh Soni ########################
    if(trigger.isInsert && trigger.isAfter){
        system.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.Start Trigger>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.');
       BookingTriggerHelper.createNoteForFreshBooking( Trigger.newMap );
        // Added By Ravi on 10 july 2020
        List<Booking__c> bookList = new List<Booking__c>();
        
        for(Booking__c objBooking : trigger.new){
            if(objBooking.Is_Lesson_Type_Change__c ==true || objBooking.Allow_Online_Guest_Joining__c==true){
                bookList.add(objBooking);
            }  
        }
        if(bookList.size()>0 && bookList!= NULL){
            BookingTriggerHelper.updateOnlineURL(bookList);
        }
       // Added By Ravi on 10 july 2020
      

    }
    //######################################################################################
    if(trigger.isAfter && trigger.isUpdate){
        
        Date oneWeekOld = System.today().addDays(7);
        // Added By Ravi on 29 june 2020
        List<Booking__c> bookList = new List<Booking__c>();
        // Added By Ravi on 29 june 2020
        Map<Id,Booking__c> oldMap = trigger.oldMap;
        Set<String> setOfFifthBookingIds = new Set<String>();
        Set<String> setOfStudentsForMakeup = new Set<String>();
        List<Booking__c> listOfTrailRescheduledBookings = new List<Booking__c>();
		Map<String,String> mapOfCancelBookings = new Map<String,String> ();		
        Map<String,String> mapOfscheduledBookings = new Map<String,String> ();		
        Set<String> setOfParentIds = new Set<String>();
        
        
        System.debug('@@@@'+settings);
        for(Booking__c objBooking : trigger.new){
            Booking__c oldBooking = oldMap.get(objBooking.Id);
            /*----- Fifth booking cancellation --*/
            /*-----booking cancellation		
                    developer : Nishi 		
                    Description: for any booking stage cancel and enrollment.stage= enroll then send notification --*/		
            if(objBooking.Status__c != oldBooking.Status__c && objBooking.Status__c == ConstantsClass.statusCanceled  		
            && objBooking.Enrolment__c != null && objBooking.Canceled_Date__c != oldBooking.Canceled_Date__c && settings.Enable_Notifications__c){		
                   mapOfCancelBookings.put(objBooking.id,objBooking.parent__c);		
            }		
            /*--  booking cancellation end--*/		
            
            /*@@Nishi:26-jul-2019: check reschedule Booking  and check prev booking date*/		
            if(objBooking.Prev_Booking_Date__c!= oldBooking.Prev_Booking_Date__c && 
               objBooking.Prev_Start_Date_Time_Text__c != oldBooking.Prev_Start_Date_Time_Text__c &&
               settings.Enable_Notifications__c){		
            //(objBooking.Status__c != oldBooking.Status__c && objBooking.Status__c == ConstantsClass.scheduledStatus)		
            		
                    system.debug('@@@objBooking.Status__c'+objBooking.Status__c);		
                    system.debug('@@@objBooking.Prev_Start_Time__c'+objBooking.Prev_Start_Time__c);		
                   mapOfscheduledBookings.put(objBooking.id,objBooking.parent__c);		
            }		
            //@Jatin Commented as per new requirement of Fifth Lesson
            /*if(objBooking.Status__c != oldBooking.Status__c && 
               objBooking.Status__c == ConstantsClass.statusCanceled && objBooking.Type__c == ConstantsClass.typeAdhoc){
                    setOfFifthBookingIds.add(objBooking.Id);
            }*/
            /*-- fifth booking cancellation end--*/
            
            /*---- makeup credits changed on the booking --*/
                if(String.isNotBlank(objBooking.student__c) && objBooking.Available_Make_up_Units__c != oldBooking.Available_Make_up_Units__c ){
                    setOfStudentsForMakeup.add(objBooking.student__c);
                }
            /*-- makeup credits changed on the booking end--*/
            
            /*--Trial booking is rescheduled--*/
                if(String.isNotBlank(objBooking.enrolment__c) && objBooking.type__c == ConstantsClass.typeTrial && (
                    objBooking.Start_Time__c != oldBooking.Start_Time__c || objBooking.Booking_Date__c != oldBooking.Booking_Date__c
                    || objBooking.Teacher_Account__c != oldBooking.Teacher_Account__c)){
                    listOfTrailRescheduledBookings.add(objBooking);
                }
            /*--Trial booking rescheduled end--*/


            // added by jatin: 14-feb:2020:Start: for check booking is related to camp class then we update related date in camp days   
            // if(string.isnotBlank(book.enrolment__c) && string.isnotBlank(book.Camp_Id__c) && string.isnotBlank(book.Camp_Days__c)){
               		
            if (oldBooking.Camp_Id__c != objBooking.Camp_Id__c ||
            oldBooking.Camp_Days__c != objBooking.Camp_Days__c){
                if(string.isNotBlank(objBooking.Camp_Days__c) && string.isNotBlank(objBooking.Camp_Id__c) && string.isNotBlank(objBooking.Enrolment__C)){
                    mapOfCampClassAndCampDay.put(objBooking.Camp_Days__c,objBooking.Camp_Id__c);
                }
                 if(string.isNotBlank(oldBooking.Camp_Id__c) || string.isNotBlank(oldBooking.Camp_Days__c)
                 && string.isNotBlank(oldBooking.Enrolment__C)){
                    mapOfCampClassAndCampDay.put(oldBooking.Camp_Days__c,oldBooking.Camp_Id__c);
                }
                
            } else if ((oldBooking.Status__c != objBooking.Status__c 
                    || oldBooking.Type__c != objBooking.Type__c)
                    && string.isNotBlank(objBooking.Camp_Days__c) && string.isNotBlank(objBooking.Camp_Id__c) 
                    && string.isNotBlank(objBooking.Enrolment__C)) {
                    mapOfCampClassAndCampDay.put(objBooking.Camp_Days__c,objBooking.Camp_Id__c);
                }
             // added by jatin: 14-feb:2020:END  for check booking is related to camp class then we update related date in camp days 
       		// added By Ravi on 29 june 2020
            if(objBooking.Is_Lesson_Type_Change__c ==true &&  oldBooking.Is_Lesson_Type_Change__c != objBooking.Is_Lesson_Type_Change__c || (objBooking.Allow_Online_Guest_Joining__c==true &&  oldBooking.Allow_Online_Guest_Joining__c != objBooking.Allow_Online_Guest_Joining__c)){
                bookList.add(objBooking);
            }
        } 
        //@Jatin Commented as per new requirement of Fifth Lesson
        /*if(setOfFifthBookingIds.size() > 0){
           BookingTriggerHelper.processFifthBookingCancellation(setOfFifthBookingIds);
        }*/
        system.debug('@@setOfStudentsForMakeup'+setOfStudentsForMakeup);
        if(setOfStudentsForMakeup.size() > 0){
            BillingUtility.rollUpMakeupCredits(setOfStudentsForMakeup);
        }
        if(listOfTrailRescheduledBookings.size() > 0){
            BookingTriggerHelper.processTrialRescheduleBookings(listOfTrailRescheduledBookings);
        }  
        
        if(mapOfCancelBookings.size() > 0){		
            BookingTriggerHelper.processCancelBooking(mapOfCancelBookings);		
        }		
        if(mapOfscheduledBookings .size() > 0){		
            BookingTriggerHelper.procesScheduledBooking(mapOfscheduledBookings );		
        }
        
        // Added By Ravi on 29 june 2020...// it basically update the Online url and Pass code value 
        if(bookList.size()>0 && bookList!= NULL){
            BookingTriggerHelper.updateOnlineURL(bookList);
        }
        // Added By Ravi on 29 june 2020
        
    }
     // added by jatin: 14-feb:2020: START : for check booking is related to camp class then we update related date in camp days 
    if((Trigger.isInsert || Trigger.isUndelete)){
        for(Booking__c book : Trigger.new){ 
            if(string.isnotBlank(book.enrolment__c) && string.isnotBlank(book.Camp_Id__c) && string.isnotBlank(book.Camp_Days__c)){
                mapOfCampClassAndCampDay.put(book.Camp_Days__c,book.Camp_Id__c);
            }
        }
    }
    if(Trigger.isDelete ){
        for(Booking__c book :Trigger.old){ 
            if(string.isnotBlank(book.enrolment__c) && string.isnotBlank(book.Camp_Id__c) && string.isnotBlank(book.Camp_Days__c)){
                mapOfCampClassAndCampDay.put(book.Camp_Days__c,book.Camp_Id__c);
            }
        }
    }
    system.debug('mapOfCampClassAndCampDay'+mapOfCampClassAndCampDay);
    if(mapOfCampClassAndCampDay != null && mapOfCampClassAndCampDay.size() > 0 ){
        BookingTriggerHelper.updateCampDayTotalStudent(mapOfCampClassAndCampDay);
    }


     // added by jatin: 14-feb:2020: END for check booking is related to camp class then we update related date in camp days 
    /*Set<Id> setOfStudents = new Set<Id>();
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            for(Booking__c currentBook : Trigger.new){
                if(currentBook.Status__c == 'Makeup Pending' || Trigger.oldMap.get(currentBook.Id).Status__c == 'Makeup Pending'){
                    setOfStudents.add(currentBook.Student__c);
                }
            }
            if(setOfStudents.size() > 0){
                BookingTriggerHelper.updateAccumulatedMakeUpHours(setOfStudents);
            }
        }
    }*/

}