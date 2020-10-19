/***
Name: UpdateEnrolmentClassProcessController
Date: 03-Dec-2019
Author: Jatin
Description: this controller for update Enrolment Of group class Customer
*/
public without sharing class UpdateEnrolmentClassProcessController implements IAdvanceAction{
    //Data Members for the Upgrade Package of the Customer
    Private String booking;
    Private Date effectiveDate;
    Private String oldPackage;
    Private String newPackage;
    Private String oldClassId;
    Private String newClassId;
    Private String newTeacherId;
    Private Time timeslot;
    Private String caseId;
    Private String caseRedirect;
    
    
    //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    Private Date nextBillDate;
    Private Country__c countryObj;
    Private UpgradeCaseCreation upgradeDetails;
    
    //Constructor to Initialize all the data members
    public UpdateEnrolmentClassProcessController(String booking, String effectiveDateStr, String newPackage, 
                                                 String oldPackage,string newTeacherId,String timeSlot, String caseId, String caseRedirect, 
                                                 string oldClassId,string newClassId) {
                                                     this.booking = booking;
                                                     effectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(effectiveDateStr);
                                                     this.newPackage = newPackage;
                                                     this.oldPackage = oldPackage;
                                                     this.timeslot = AdvanceActionsHelper.getDateTimeFromString(timeSlot).time();
                                                     this.caseId = caseId;
                                                     this.caseRedirect = caseRedirect;
                                                     this.newClassId = newClassId;
                                                     this.oldClassId =oldClassId;
                                                     this.newTeacherId = newTeacherId;
                                                     enrolmentObj = new Enrolment__c();
                                                     
                                                     countryObj = new Country__c();
                                                     upgradeDetails = new UpgradeCaseCreation();
                                                     
                                                 }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
        String caseIdToReturn;
        Boolean  error = false;
        Set<String> setOfBookings = new Set<String>();
        Map<String, Booking__c> mapOfMakeupBooking = new Map<String, Booking__c>();
        string invoiceId;
        string oldTeacher;
        string oldPackage;
        STRING previousTime;
        Time oldTimeSlot;
        Integer duration=0;
        Boolean isGroupLessonChange = false;
        Boolean teacherPackageChange = false;
        if( String.isNotBlank(newClassId)  &&  String.isNotBlank(oldClassId) && newClassId != oldClassId){
            isGroupLessonChange = true;
        }
        if(newTeacherId != enrolmentObj.Teacher__c || newPackage != enrolmentObj.Package__c){
            teacherPackageChange =  true;                                      
        }
        DateTime newEffectiveDateTime = DateTime.newInstance(effectiveDate, timeslot);
        Boolean isSameMonth = false;
        if(String.isNotBlank(enrolmentObj.Id)){
            //Fetch Next Bill Date From Enrolment
            nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
            
            //Fetch the Country Object From Enrolment
            countryObj = AdvanceActionsHelper.fetchCountryFromEnrolment(enrolmentObj);
            isSameMonth = nextBillDate > effectiveDate ? true : false;
            enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentObj.id);
            oldTeacher = enrolmentObj.Teacher__c;
            oldPackage = enrolmentObj.Package__c;
            oldTimeSlot = enrolmentObj.Lesson_Start_time__c;
            previousTime =  DateTime.newInstance(enrolmentObj.Lessons_Start_Date__c, enrolmentObj.Lesson_Start_time__c).format('EEE @ h:mm a');
            if(isSameMonth){
                enrolmentObj.Package__c = newPackage;
                enrolmentObj.Class__c = newClassId;
                enrolmentObj.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
                enrolmentObj.Lesson_Start_time__c = timeslot;
                enrolmentObj.Effective_Date__c = effectiveDate;
                enrolmentObj.New_Package_Id__c = newPackage;
                enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
                enrolmentObj.Package_Process_Request_Date__c = System.today();
                enrolmentObj.Advance_Action_Requested_By__c = Userinfo.getUserId();
                enrolmentObj.Next_Lesson_Start_time__c = timeslot;
                enrolmentObj.new_Class__c = newClassId;
                enrolmentObj.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
                enrolmentObj.Lesson_Day__c = newEffectiveDateTime.format('EEEE');
                enrolmentObj.Teacher__c = newTeacherId;
                enrolmentObj.New_Teacher__c = newTeacherId;
            }else{
                enrolmentObj.New_Package_Id__c = newPackage;
                enrolmentObj.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
                enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
                enrolmentObj.Effective_Date__c = effectiveDate;
                enrolmentObj.Package_Process_Request_Date__c = System.today();
                enrolmentObj.Advance_Action_Requested_By__c = Userinfo.getUserId();
                enrolmentObj.Next_Lesson_Start_time__c = timeslot;
                enrolmentObj.New_Class__c = newClassId;
                enrolmentObj.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
                enrolmentObj.New_Teacher__c = newTeacherId;  
            }
            Database.SaveResult saveResult = Database.Update(enrolmentObj, false);
            if(saveResult.isSuccess()){
                enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentObj.id);
                // Manage future makeup booking  and if duration is differ then create new 
                Map<Date,String> mapOfEffectiveDateGroupLesson = getmapOfEffectiveDateGroupLesson(enrolmentObj,enrolmentObj.new_Class__c); 
                processFutureMakeupGroupLessonBookings(enrolmentObj,mapOfEffectiveDateGroupLesson);
                  //uncommented by jatin:6-jan-2020 now we change our logic we change you class with new lesson day so thats why we deleted all previous lesson then create new one.
                processFutureGroupLessonBookings(enrolmentObj, mapOfEffectiveDateGroupLesson);
                if( isSameMonth && (isGroupLessonChange || teacherPackageChange)){
                    invoiceId =  createInvoiceAndLineItemsChangeEnrol(enrolmentObj, effectiveDate, nextBillDate, oldTeacher,oldPackage,newTeacherId,newPackage);
                }    
            }
            error = false;
        }
        if(caseRedirect == 'true' && error == false && enrolmentObj != NULL){
            Case caseObj =  AureusCalendarControllerHelper.createCaseForEnrolment(caseId, enrolmentObj.Id, 'change', false);
            if(String.isNotBlank(invoiceId)){
                caseObj.Invoice__c = invoiceId;
            }
            if(String.isNotBlank(oldPackage)){
                caseObj.Previous_Package__c = oldPackage; 
            }
            if(String.isNotBlank(newPackage)){
                caseObj.New_Package__c = newPackage; 
            }
            if(String.isNotBlank(newTeacherId)){
                caseObj.New_Teacher__c =  newTeacherId;   
            }
            if(String.isNotBlank(oldTeacher)){
                caseObj.Previous_Teacher__c = oldTeacher; 
            }
            if(effectiveDate != null){
                DateTime newformatTime = DateTime.newInstance(effectiveDate, timeslot);
                caseObj.New_Lesson_Day_Time__c = newformatTime.format('EEE @ h:mm a');
            }
            
            caseObj.Previous_Lesson_Day_Time__c = previousTime;
            upsert caseObj;
            caseIdToReturn = caseObj.Id;
        }else if(error == false){
            caseIdToReturn = '';
        }else{
            caseIdToReturn = 'error';
        }
        return caseIdToReturn;
    }
    
    // 27-Dec-2019: process Future Makeup Group Lesson Bookings
    public static void processFutureMakeupGroupLessonBookings(Enrolment__c enrolmentObj,Map<Date,String> mapOfEffectiveDateGroupLesson){
        map<Id,booking__c> mapOfMakeupBooking =new  map<Id,booking__c> ();
        List<Booking__c> makeupBookingList = new List<Booking__c>();
        for(Booking__c bookingObj : [SELECT Id,Start_time__c,End_time__c, Booking_Date__c, Available_Make_up_Units__c, 
                                     Student__r.Name, Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c, Duration__c, Type__c, Category__c 
                                     FROM Booking__c 
                                     WHERE Student__c=:enrolmentObj.Student__c 
                                     AND Parent__c = :enrolmentObj.Parent__c
                                     AND Teacher_Account__c=: enrolmentObj.Teacher__c 
                                     AND Booking_Date__c >=: enrolmentObj.Effective_Date__c 
                                     AND Type__c =: ConstantsClass.typeMakeup
                                     AND  recordType.Name =:ConstantsClass.groupLessonBookingRecordType
                                    ]){
                                        mapOfMakeupBooking.put(bookingObj.id,bookingObj);
                                        makeupBookingList.add(bookingObj);
                                    }
        if(String.isNotBlank(enrolmentObj.Id) && mapOfMakeupBooking.size() > 0){
            updateMakeUpBookingOnUpgrade(enrolmentObj, mapOfMakeupBooking,mapOfEffectiveDateGroupLesson);
        }
        
    }
    // 27-Dec-2019: update makeup bookings if booking date is match in class booking_date
    //commented by nishi: 25-Sep-2020: for according to new class we dont manage makup booking so we cancle all future makup bookings
     public static void updateMakeUpBookingOnUpgrade(Enrolment__c enrolmentObj, map<Id,booking__c> mapOfMakeupBooking,Map<Date,String> mapOfEffectiveDateGroupLesson){
         
        if(mapOfMakeupBooking != null && mapOfMakeupBooking.size() > 0){
            Map<Id, Booking__c> mapOfUpdateMakeUpBooking = new   Map<Id, Booking__c>();
            for(Id bookingId : mapOfMakeupBooking.keySet()){
                Booking__c bookingObj = mapOfMakeupBooking.get(bookingId);
                if(mapOfEffectiveDateGroupLesson.containsKey(bookingObj.Booking_Date__c)){
                    if(enrolmentObj.Next_Lesson_Start_time__c != NULL)
                        bookingObj.Start_Time__c = enrolmentObj.Next_Lesson_Start_time__c;
                    else if(enrolmentObj.Lesson_Start_time__c != NULL)
                        bookingObj.Start_Time__c = enrolmentObj.Lesson_Start_time__c;
                    if(string.isNotBlank(enrolmentObj.new_package_Id__c))
                        bookingObj.Package__c = enrolmentObj.new_package_Id__c;
                    else if(string.isNotBlank(enrolmentObj.package__c))
                        bookingObj.Package__c = enrolmentObj.package__c;
                    if(  bookingObj.Start_Time__c != null && enrolmentObj.new_package_Id__r != null && enrolmentObj.new_package_Id__r.Duration__c != NULL){
                        bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.new_package_Id__r.Duration__c));       
                    }else if(  bookingObj.Start_Time__c != null && enrolmentObj.Package__r != null && enrolmentObj.Package__r.Duration__c != NULL){
                        bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c)); 
                    }
                    bookingObj.Group_Class__c = mapOfEffectiveDateGroupLesson.get(bookingObj.Booking_Date__c);
                    mapOfUpdateMakeUpBooking.put(bookingId,bookingObj);
                }
            } 
            if(mapOfUpdateMakeUpBooking != null && mapOfUpdateMakeUpBooking.size () > 0){
                update mapOfUpdateMakeUpBooking.values();
                string parentId = String.isNotBlank(enrolmentObj.Parent__c) ? enrolmentObj.Parent__c : enrolmentObj.Student__c;
                deductMakeupHours(mapOfUpdateMakeUpBooking.keySet(),parentId,enrolmentObj.id);
            }
        }
    }
    // 28-dec-2019: deduct makeup hours and minus available mins and calculate utilize min then update parent 
    public static void deductMakeupHours(set<id> bookingIds, String bookingParentId,string enrolmentObjId){
        //System.debug('Deduct Makeup hours called');
        String statusCanceled = ConstantsClass.statusCanceled;
        Boolean isError = false;
        String studentId;
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        Integer hoursToDeduct = 0;
        Booking__c bookObj = new Booking__c();
        Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = getParentsChild(bookingParentId);
        }
        List<Booking__c> bookingObjList = new List<Booking__c>();
        List<Booking__c> ossiaBookingList = new List<Booking__c>();
         //start:added By nishi: 21-sep-2020:deduct makeup hours and minus available mins and calculate utilize min then update parent 
        //  according to new requiremnt While utilizing Make up credit, 
        //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
        for(Booking__c objBook:[SELECT Id,Start_time__c,End_time__c, Booking_Date__c, Available_Make_up_Units__c, 
                                            Student__r.Name, Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c,
                                            Duration__c, Type__c, Category__c ,Center__r.Organisation__r.Name
                                            FROM Booking__c 
                                            WHERE id IN: bookingIds
                                           ]){
                                            if(String.isNotBlank(objBook.Center__c) && 
                                            String.isNotBlank(objBook.Center__r.Organisation__c) && 
                                            String.isNotBlank(objBook.Center__r.Organisation__r.Name) && 
                                            objBook.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                                ossiaBookingList.add(objBook);  
                                            }else{
                                                bookingObjList.add(objBook);
                                            }
                                           }
        if(ossiaBookingList != null && ossiaBookingList.size() > 0){
            OssiaCenterCalendarController.deductOssiaMakeupHours(ossiaBookingList,bookingParentId,new Set<String>{enrolmentObjId});
        }
        // end:added By nishi: 21-sep-2020:deduct makeup hours and minus available mins and calculate utilize min then update parent 
     //  according to new requiremnt While utilizing Make up credit, 
     //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
                                                    
        if(bookingObjList.size() > 0){
            
            if(setOfParentStudent.size() > 0){
                List<Booking__c> cancelBookings = new List<Booking__c>([SELECT Id, Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                                                                        Student__c, Type__c, Duration__c FROM Booking__c
                                                                        WHERE Status__c =: statusCanceled 
                                                                        AND Student__c IN: setOfParentStudent AND 
                                                                        Make_up_Expiry_Date__c >= TODAY 
                                                                        AND (Available_Make_up_Units__c > 0 
                                                                             AND Available_Make_up_Units__c != NULL) 
                                                                        ORDER BY Make_up_Expiry_Date__c]);
                if(cancelBookings.size() > 0){
                    for(Booking__c cancelBooking : cancelBookings){
                        mapOfHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                    }
                }
                if(bookingObjList.size() > 0){
                    map<string,Integer> mapOfUtilizeBookings = new  map<string,Integer>();
                    string makeupUtilizeBookings ='';
                    for(Booking__c bookingObj : bookingObjList){
                        hoursToDeduct = 0;
                        integer totalUtilizeHours = 0;
                        bookObj = new Booking__c();
                        bookObj.Id = bookingObj.Id;
                        mapOfUtilizeBookings = new  map<string,Integer>();
                       //system.debug(bookingObj.Make_up_Utilize_Bookings__c);
                        // if makeup Utilize mins is exist then get old utilize mins for updation
                        if(string.isNotBlank(bookingObj.Make_up_Utilize_Bookings__c)){
                           //system.debug(bookingObj.Make_up_Utilize_Bookings__c.split(';'));
                            for(string bookingWithDuration : bookingObj.Make_up_Utilize_Bookings__c.split(';')){
                                if(string.isNotBlank(bookingWithDuration)){
                                    mapOfUtilizeBookings.put(bookingWithDuration.split('-')[0],Integer.valueOf(bookingWithDuration.split('-')[1]));
                                    totalUtilizeHours += Integer.valueOf(bookingWithDuration.split('-')[1]);
                                }
                            }
                        }
                        hoursToDeduct = Integer.valueOf(bookingObj.duration__c) - totalUtilizeHours;
                        if(hoursToDeduct > 0){
                            for(Booking__c canceledBookings : cancelBookings){
                                if(mapOfHours.containsKey(canceledBookings.Id) && mapOfHours.get(canceledBookings.Id) > 0 ){
                                    // if Deduct makeup hours is greate then  Available_Make_up_Units__c 
                                    if(hoursToDeduct > mapOfHours.get(canceledBookings.Id)){
                                        // if  Utilize Bookings id is already exist in Make_up_Utilize_Bookings__c field then we update  
                                        if(mapOfUtilizeBookings!= null && mapOfUtilizeBookings.size() > 0 && mapOfUtilizeBookings.containsKey(canceledBookings.Id)){
                                            Integer addedSameCancelBookingHours = mapOfUtilizeBookings.get(canceledBookings.Id) + mapOfHours.get(canceledBookings.Id);
                                            mapOfUtilizeBookings.put(canceledBookings.Id,addedSameCancelBookingHours);
                                        }else{
                                            mapOfUtilizeBookings.put(canceledBookings.Id,mapOfHours.get(canceledBookings.Id));
                                        }
                                        hoursToDeduct -= mapOfHours.get(canceledBookings.Id);
                                        mapOfHours.put(canceledBookings.Id, 0);
                                    }// if Deduct makeup hours is less or equals to  Available_Make_up_Units__c 
                                    else if(hoursToDeduct <= mapOfHours.get(canceledBookings.Id)){
                                        // if  Utilize Bookings id is already exist in Make_up_Utilize_Bookings__c field then we update 
                                        if(mapOfUtilizeBookings!= null && mapOfUtilizeBookings.size() > 0 && mapOfUtilizeBookings.containsKey(canceledBookings.Id)){
                                            Integer addedSameCancelBookingHours = mapOfUtilizeBookings.get(canceledBookings.Id) + hoursToDeduct;
                                            mapOfUtilizeBookings.put(canceledBookings.Id,addedSameCancelBookingHours);
                                        }else{
                                            mapOfUtilizeBookings.put(canceledBookings.Id,hoursToDeduct);
                                        }
                                        mapOfHours.put(canceledBookings.Id, mapOfHours.get(canceledBookings.Id) - hoursToDeduct);
                                        hoursToDeduct = 0;
                                    }
                                    
                                    if(hoursToDeduct <= 0){
                                        break;   
                                    }
                                }
                            }
                            if(mapOfUtilizeBookings != null && mapOfUtilizeBookings.size() > 0){
                                bookObj.Make_up_Utilize_Bookings__c ='';
                                for(string bookingid: mapOfUtilizeBookings.keySet()){
                                    bookObj.Make_up_Utilize_Bookings__c +=  bookingid +'-'+mapOfUtilizeBookings.get(bookingid)+';';
                                }
                            }
                            bookingUpdatedList.add(bookObj);
                        }
                    }
                }
                for(String keysetValue : mapOfHours.keyset()){
                    if(mapOfHours.containsKey(keysetValue)){
                        bookingUpdatedList.add(new Booking__c(Id = keysetValue, 
                                                              Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                    }
                }
               //system.debug('@@@bookingUpdatedList '+bookingUpdatedList);
                if(bookingUpdatedList.size() > 0){
                    Database.SaveResult[] saveResults = Database.update(bookingUpdatedList, false);
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()){
                            isError = true;
                        }
                    }
                }
                /// update parent available mins for cancel bookings only 
                // beacuse trigger not calculate canceled booking available mins
                if(String.isNotBlank(bookingParentId)){
                    AureusCalendarControllerHelper.cancelBookingProceed(bookingParentId);
                }
            }   
        }
    }
    private static Set<String> getParentsChild(String parentId){
        Set<String> setOfAccId = new Set<String>();
        List<Account> accList = [SELECT Id FROM Account WHERE (Id =: parentId OR Parent__c =: parentId)];
        for(Account acc : accList){
            setOfAccId.add(acc.Id);
        }
        return setOfAccId;
    }
    public  static List<Booking__c> fetchCancelBookings(Set<String> setOfStuParentIds){
        return [SELECT Id, Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                Student__c, Type__c, Duration__c FROM Booking__c WHERE 
                Status__c =: ConstantsClass.statusCanceled AND Student__c IN: setOfStuParentIds AND 
                Make_up_Expiry_Date__c >= TODAY AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                ORDER BY Make_up_Expiry_Date__c];
        
    }
    public static Set<String> fetchChildrens(String setOfParentIds){
        Set<String> setOfStuParentIds = new Set<String>();
        if(String.isNotBlank(setOfParentIds)){
            for( Account objAcc : [SELECT Id, also_A_Student__c FROM Account WHERE Id =: setOfParentIds OR Parent__c =: setOfParentIds]){
                setOfStuParentIds.add(objAcc.Id);
            }
        }
        return setOfStuParentIds;
    }
    
    public static Decimal fetchParentMakeup(String parentId){
        Decimal availableMakeUps = 0; 
        List<Account> parentObjList = [SELECT Id, Name, RecordType.Name, Available_Make_up_mins_For_Group__c FROM 
                                       Account WHERE Id =: parentId AND RecordType.Name =:ConstantsClass.recordTypeCustomer];
        if(parentObjList.size() > 0){
            if(parentObjList[0].Available_Make_up_mins_For_Group__c != NULL){
                availableMakeUps = parentObjList[0].Available_Make_up_mins_For_Group__c;
            }
        }
        return availableMakeUps;
    }
    
    public  static Map<Date,String> getmapOfEffectiveDateGroupLesson(Enrolment__c enrolmentObj, string classId){
        Map<Date,String> mapOfEffectiveDateGroupLesson = New  Map<Date,String>();
        for(Booking__c objBook : [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                  Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                  Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c 
                                  FROM Booking__c 
                                  WHERE Type__c = :ConstantsClass.groupTypeBooking
                                  AND Status__c != :ConstantsClass.statusCanceled
                                  AND Booking_Date__c >= :enrolmentObj.effective_Date__c
                                  AND Class__c =:classId]){
                                      mapOfEffectiveDateGroupLesson.put(objBook.Booking_Date__c ,objBook.id);
                                  }
        return mapOfEffectiveDateGroupLesson;
    }
    
    private Static void processFutureGroupLessonBookings(Enrolment__c enrolmentObj, Map<Date,String> mapOfEffectiveDateGroupLesson){
        List<Booking__c> delbookingList = [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                           Group_Class__r.Booking_Date__c,Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                           Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c 
                                           FROM Booking__c 
                                           WHERE Enrolment__c = :enrolmentObj.Id
                                           AND Booking_Date__c >= :enrolmentObj.effective_Date__c
                                           AND Type__c = :ConstantsClass.groupLessonTypeBooking 
                                           And RecordType.name =: ConstantsClass.groupLessonBookingRecordType 
                                           AND Status__c != :ConstantsClass.statusCanceled];
        if(delbookingList.size() > 0){
            DELETE delbookingList;
        }     
        reCreateGroupLessonBookings(enrolmentObj,mapOfEffectiveDateGroupLesson);
        
    }
    private static void reCreateGroupLessonBookings(Enrolment__c  enrolmentObj, Map<Date,String> mapOfEffectiveDateGroupLesson){					
      //system.debug('enrolmentObj.new_teacher__c'+enrolmentObj.new_teacher__c);
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        if(mapOfEffectiveDateGroupLesson!= null && mapOfEffectiveDateGroupLesson.size() > 0){
            for(date effectiveDate : mapOfEffectiveDateGroupLesson.keySet()){
                if(effectiveDate.day() <= 28){
                    if(mapOfEffectiveDateGroupLesson.containsKey(effectiveDate)){
                        Booking__c bookingObj = new Booking__c();
                        if(effectiveDate != null )
                            bookingObj.Booking_Date__c = effectiveDate;
                        if(string.isNotBlank(enrolmentObj.new_teacher__c)) 
                            bookingObj.Teacher_Account__c = enrolmentObj.new_teacher__c;
                        else if(string.isNotBlank(enrolmentObj.Teacher__c)) 
                            bookingObj.Teacher_Account__c = enrolmentObj.Teacher__c;

                        if(string.isNotBlank(enrolmentObj.Parent__c))
                            bookingObj.Parent__c = enrolmentObj.Parent__c;
                        if(string.isNotBlank(enrolmentObj.Center__c))    
                            bookingObj.Center__c = enrolmentObj.Center__c;
                        if(string.isNotBlank(enrolmentObj.Student__c))
                            bookingObj.Student__c = enrolmentObj.Student__c;
                        
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
                        
                        
                        if(  bookingObj.Start_Time__c != null && enrolmentObj.new_package_Id__r != null && enrolmentObj.new_package_Id__r.Duration__c != NULL){
                            bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.new_package_Id__r.Duration__c));       
                        }else if(  bookingObj.Start_Time__c != null && enrolmentObj.Package__r != null && enrolmentObj.Package__r.Duration__c != NULL){
                            bookingObj.End_Time__c =  bookingObj.Start_Time__c.addMinutes(Integer.valueOf(enrolmentObj.Package__r.Duration__c));       
                        }
                        
                        if(enrolmentObj.Subscription_Line_Items__r != null && enrolmentObj.Subscription_Line_Items__r.size() > 0 && 
                           enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c != null && effectiveDate != null && 
                           effectiveDate >= enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c){
                               bookingObj.Status__c = ConstantsClass.pendingStatus;
                           }else{
                               bookingObj.Status__c = ConstantsClass.scheduledStatus;
                           }
                        bookingObj.Type__c = ConstantsClass.groupLessonTypeBooking;
                        bookingObj.recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
                        bookingObj.Group_Class__c = mapOfEffectiveDateGroupLesson.get(effectiveDate);
                        bookingsToInsert.add(bookingObj);
                    }
                }
            }
        }
        if(bookingsToInsert.size() > 0){
           //system.debug('@@bookingsToInsert'+bookingsToInsert);
            UPSERT bookingsToInsert;
        }
    }
    private static String getPackageInvoiceAmount(Enrolment__c objEnrol,Map<Id,Package__c> mapOfPackages,map<id,String> packageInvoiceAmount,string packageId){
        decimal totalAmount = 0;
        decimal gstAmount = 0;
       //system.debug('@@@packageId --'+ packageId);
        if(packageInvoiceAmount.containsKey(packageId)){
            totalAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[0]);
        }
       //system.debug('@@unit fee '+ mapOfPackages.get(packageId).Unit_Fee__c);
        totalAmount += mapOfPackages.get(packageId).Unit_Fee__c;
        if(String.isNotBlank(objEnrol.Id) &&  String.isNotBlank(objEnrol.Center__c)
           && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0
           && mapOfPackages.get(packageId).Unit_Fee__c  > 0 ){
               if(packageInvoiceAmount.containsKey(packageId)){
                   gstAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[1]);
               }
              //system.debug('@@@Gst Amount= '+ (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100);
              //system.debug('@@@Tax_Rate__c = '+ (objEnrol.Center__r.Country__r.Tax_Rate__c)/100);
               gstAmount += (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
           }
        return totalAmount+';'+gstAmount;
    }
    private static String createInvoiceAndLineItemsChangeEnrol(Enrolment__c objEnrol, Date effectiveDate, Date nextBillingDate, 
                                                               String oldTeacher,String oldPackage,String newTeacher,String newPackage){
        Invoice__c objectOfInvoice = new Invoice__c();
        decimal totalAmount = 0;
        decimal gstAmount = 0;
        String canceledStatus = ConstantsClass.statusCanceled; 
        List<Invoice_Line_Item__c> invoiceLineItem = new List<Invoice_Line_Item__c>();
        String subLineItemId ;
        Integer noOfOldLesson,noOfNewLesson;
        Set<String> packageIds = new Set<string>();
          // added by nishi: 7-oct-2020: for create credit memo records
          map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
          map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
          List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
          map<String,Invoice_Line_Item__c> updateInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        packageIds.add(oldPackage);
        packageIds.add(newPackage);
        Map<id,Package__c> mapOfPackage = new Map<Id,package__c>([Select Id,Unit_Fee__c from Package__c where Id In:packageIds]);
        List<Booking__c> bookingList = [SELECT Id, Package__c, center__c, Teacher_Account__c, Package__r.Unit_Fee__c, Student__c,
                                        Student__r.Parent__c ,Booking_date__c
                                        FROM Booking__c WHERE 
                                        Enrolment__c =: objEnrol.id 
                                        AND Booking_Date__c >= :effectiveDate AND 
                                        Booking_Date__c < :nextBillingDate AND 
                                        Type__c =:  ConstantsClass.groupLessonTypeBooking
                                         //jatin:7-jan-2020 : for now we calculate all booking Status__c !=: ConstantsClass.statusCanceled 
                                         ORDER BY Booking_Date__c ];
       //system.debug('@@@ get bookingList'+bookingList);
        if(objEnrol != NULL && objEnrol.subscription_line_items__r != null && objEnrol.subscription_line_items__r.size() > 0 ){
            subLineItemId = objEnrol.subscription_line_items__r[0].id;
        }
        if(bookingList.size() > 0){
            String parentId = String.isNotBlank(bookingList[0].Student__r.Parent__c) ? bookingList[0].Student__r.Parent__c : bookingList[0].Student__c;
           //system.debug('@@@@@bookingList.size()--'+bookingList.size());
            map<id,String> packageInvoiceAmount = new Map<Id,String>();
            map<id,String> packageInvoiceNextMonthAmount = new Map<Id,String>();
            Map<Id,Package__c> mapOfPackages =New Map<Id,Package__c>([Select Id,Unit_Fee__c from Package__c where Id In:packageIds]);
           //system.debug('@@@@@mapOfPackages'+mapOfPackages);
            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
               //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
             Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
             for(Invoice__c objInvoice : [Select id,Invoice_Date__c,(Select id from Invoice_Line_Items__r 
                                         where Enrolment__C =:objEnrol.id)
                                         From Invoice__C 
                                         Where  Parent_Account__c =: parentId
                                         And invoice_type__c = 'Recurring']){
                 if(nextBillingDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && objInvoice.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() ){
                         mapofinvoice.put('Next Month',objInvoice);
                }else{
                     if(objInvoice.Invoice_Date__c.month() == system.today().month()){
                         mapofinvoice.put('Current',objInvoice);
                     }
                 }
                 if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0){
                    for(Invoice_Line_Item__c lineItem :objInvoice.Invoice_Line_Items__r){
                       updateInvoiceLineItem.put(lineItem.id,lineItem);
                    }
                }
             }
              //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
            
            // 6 Dec 2019: jatin for manage packages fee  old package and new package unit fee
            for(Booking__c booking : bookingList){
                if(nextBillingDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && booking.Booking_date__c.month() == nextMonthDate.addMonths(-1).month() ){
                   //system.debug('@@@@@next Month'+booking.Booking_date__c);
                    if(string.isNotBlank(booking.Package__c)){
                        if(mapOfPackages.containsKey(newPackage)){
                            packageInvoiceNextMonthAmount.put(newPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceNextMonthAmount,newPackage));    
                        }if(mapOfPackages.containsKey(oldPackage)){
                            packageInvoiceNextMonthAmount.put(oldPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceNextMonthAmount,oldPackage)); 
                        } 
                    }
                }else{
                    if(string.isNotBlank(booking.Package__c)){
                        if(mapOfPackages.containsKey(newPackage)){
                            packageInvoiceAmount.put(newPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,newPackage));    
                        }if(mapOfPackages.containsKey(oldPackage)){
                            packageInvoiceAmount.put(oldPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,oldPackage)); 
                        } 
                    }
                }
            }
            decimal newPackageTotalAmount = 0;
            decimal oldPackageTotalAmount = 0;
            decimal newPackageNextMonthTotalAmount = 0;
            decimal oldPackageNextMonthTotalAmount = 0;
            if(packageInvoiceAmount.containsKey(newPackage)){
                newPackageTotalAmount += decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[0]);
            }
            if(packageInvoiceAmount.containsKey(oldPackage)){
                oldPackageTotalAmount += decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[0]);
            }
            if(packageInvoiceNextMonthAmount.containsKey(newPackage)){
                newPackageNextMonthTotalAmount += decimal.valueOf(packageInvoiceNextMonthAmount.get(newPackage).split(';')[0]);
            }
            if(packageInvoiceNextMonthAmount.containsKey(oldPackage)){
                oldPackageNextMonthTotalAmount += decimal.valueOf(packageInvoiceNextMonthAmount.get(oldPackage).split(';')[0]);
            }
            
           //system.debug('@@@@@packageInvoiceAmount'+packageInvoiceAmount);
           //system.debug('@@parentId'+parentId);
            if(oldPackageTotalAmount > 0 && newPackageTotalAmount > 0 && String.isNotBlank(parentId)){
                objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                Invoice_Date__c =system.today(), Parent_Account__c = parentId, Center__c=bookingList[0].center__c);
                                                objectOfInvoice.Credit_Memo_Amount__c =  0;
                INSERT objectOfInvoice;
               //system.debug('@@@ created objectOfInvoice'+objectOfInvoice);
                if(objectOfInvoice != NULL){
                     //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                     String invoiceId = null;
                     if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                         if(mapofinvoice.containskey('Current')){
                             invoiceId = mapofinvoice.get('Current').id;
                         }
                     }
                      Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  system.today(),'Update Enrolment invoice Adjustment');
                     objCreditMemo.Status__c = ConstantsClass.creditMemoSuccessStatus;
                     objCreditMemo.Invoice_Number__c = objectOfInvoice.Id;
                     newPendingCreditMemos.put('Update Enrolment invoice Adjustment',objCreditMemo);
                     //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                    
                    if(packageInvoiceAmount.containsKey(newPackage)){
                        if(packageInvoiceAmount.get(newPackage).split(';') != null && packageInvoiceAmount.get(newPackage).split(';').size() >0){
                            newPackageTotalAmount = decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[0]);
                            gstAmount = decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[1]);
                            
                            if(newPackageTotalAmount != 0){
                                newPackageTotalAmount = BillingUtility.roundOffAmount(newPackageTotalAmount);
                            }
                            if(gstAmount != 0){
                                gstAmount = BillingUtility.roundOffAmount(gstAmount);
                            }
                        //system.debug('@@@totalAmount'+totalAmount);
                        //system.debug('@@@gstAmount'+gstAmount);
                            invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                                                                        Amount__c = newPackageTotalAmount, 
                                                                        Teacher_Id__c = newTeacher, Month__c= effectiveDate, Enrolment__c =objEnrol.id, 
                                                                        Subscription_line_item__c = subLineItemId,Package__c= newPackage ,
                                                                        GST_Amount__c = gstAmount));
                        }
                    }
                    if(packageInvoiceAmount.containsKey(oldPackage)){
                        if(packageInvoiceAmount.get(oldPackage).split(';') != null && packageInvoiceAmount.get(oldPackage).split(';').size() >0){
                            oldPackageTotalAmount = decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[0]);
                            gstAmount = decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[1]);
                            if(oldPackageTotalAmount != 0){
                                oldPackageTotalAmount = BillingUtility.roundOffAmount(oldPackageTotalAmount);
                            }
                            if(gstAmount != 0){
                                gstAmount = BillingUtility.roundOffAmount(gstAmount);
                            }
                            /*Commenter by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
                            oldPackageTotalAmount = -oldPackageTotalAmount;
                            if(gstAmount > 0){
                                gstAmount = -gstAmount;
                            }*/
                        //system.debug('@@@totalAmount'+totalAmount);
                        //system.debug('@@@gstAmount'+gstAmount);
                            //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                            /*invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = oldPackageTotalAmount, 
                                                                        Teacher_Id__c = oldTeacher,Month__c= effectiveDate,
                                                                        Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                        Package__c = oldPackage,  GST_Amount__c = gstAmount));*/
                            String invoicelineitemId = null;
                            if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                                if(mapofinvoice.containskey('Current')){
                                    if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                                        invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                                    }
                                }
                            }
                            Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Math.abs(oldPackageTotalAmount),gstAmount,oldPackage,
                            objEnrol.id,invoicelineitemId,'');
                            objCreditLineItem.Month__c = effectiveDate;
                            objectOfInvoice.Credit_Memo_Amount__c +=  (Math.abs(oldPackageTotalAmount)+gstAmount);
                            listOfCreditmemolineitem.add(objCreditLineItem);                                                  
                            mapOfCreditmemolineitem.put('Update Enrolment invoice Adjustment',listOfCreditmemolineitem);             
                            //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                            
                             //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                             if(string.isNotBlank(invoicelineitemId)){
                                decimal invoicelineItemCreditAmount=0;
                                decimal invoicelineItemCreditGst=0;
                                
                                if(updateInvoiceLineItem.containskey(invoicelineitemId)){
                                    invoicelineItemCreditAmount =updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c :0;
                                    invoicelineItemCreditGst = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c :0;
                                }
                                updateInvoiceLineItem.put(invoicelineitemId,new Invoice_Line_Item__c(id=invoicelineitemId,
                                                        Credit_Memo_Amount__c =invoicelineItemCreditAmount+(Math.abs(oldPackageTotalAmount)),
                                                        Credit_Memo_tax__c=invoicelineItemCreditGst+gstAmount));
                            }
                        }
                    }
                    if(packageInvoiceNextMonthAmount.containsKey(newPackage)){
                        if(packageInvoiceNextMonthAmount.get(newPackage).split(';') != null && packageInvoiceNextMonthAmount.get(newPackage).split(';').size() >0){
                            newPackageNextMonthTotalAmount = decimal.valueOf(packageInvoiceNextMonthAmount.get(newPackage).split(';')[0]);
                            gstAmount = decimal.valueOf(packageInvoiceNextMonthAmount.get(newPackage).split(';')[1]);
                        
                            if(newPackageNextMonthTotalAmount != 0){
                                newPackageNextMonthTotalAmount = BillingUtility.roundOffAmount(newPackageNextMonthTotalAmount);
                            }
                            if(gstAmount != 0){
                                gstAmount = BillingUtility.roundOffAmount(gstAmount);
                            }
                        //system.debug('@@@totalAmount'+totalAmount);
                        //system.debug('@@@gstAmount'+gstAmount);
                            invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                                                                        Amount__c = newPackageNextMonthTotalAmount, 
                                                                        Teacher_Id__c = newTeacher, Month__c= nextMonthDate.addMonths(-1), Enrolment__c =objEnrol.id, 
                                                                        Subscription_line_item__c = subLineItemId,Package__c= newPackage ,
                                                                        GST_Amount__c = gstAmount));
                        }
                    }
                    if(packageInvoiceNextMonthAmount.containsKey(oldPackage)){
                        if(packageInvoiceNextMonthAmount.get(oldPackage).split(';') != null && packageInvoiceNextMonthAmount.get(oldPackage).split(';').size() >0){
                            oldPackageNextMonthTotalAmount = decimal.valueOf(packageInvoiceNextMonthAmount.get(oldPackage).split(';')[0]);
                            gstAmount = decimal.valueOf(packageInvoiceNextMonthAmount.get(oldPackage).split(';')[1]);
                            if(oldPackageNextMonthTotalAmount != 0){
                                oldPackageNextMonthTotalAmount = BillingUtility.roundOffAmount(oldPackageNextMonthTotalAmount);
                            }
                            if(gstAmount != 0){
                                gstAmount = BillingUtility.roundOffAmount(gstAmount);
                            }
                            /*Commented by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                            oldPackageNextMonthTotalAmount = -oldPackageNextMonthTotalAmount;
                            if(gstAmount > 0){
                                gstAmount = -gstAmount;
                            }
                            //system.debug('@@@totalAmount'+totalAmount);
                            //system.debug('@@@gstAmount'+gstAmount);
                            
                            /*invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = oldPackageNextMonthTotalAmount, 
                                                                    Teacher_Id__c = oldTeacher,Month__c= nextMonthDate.addMonths(-1),
                                                                    Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                    Package__c = oldPackage,  GST_Amount__c = gstAmount));*/
                            //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
                            String invoicelineitemId = null;
                            if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                                if(mapofinvoice.containskey('Next Month')){
                                    if(mapofinvoice.get('Next Month').Invoice_Line_Items__r != null && mapofinvoice.get('Next Month').Invoice_Line_Items__r.size()>0){
                                        invoicelineitemId =mapofinvoice.get('Next Month').Invoice_Line_Items__r[0].id; 
                                    }
                                }
                            }
                            Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Math.abs(oldPackageNextMonthTotalAmount),gstAmount,oldPackage,
                            objEnrol.id,invoicelineitemId,'');
                            objCreditLineItem.Month__c = nextMonthDate.addMonths(-1);
                            listOfCreditmemolineitem.add(objCreditLineItem); 
                            objectOfInvoice.Credit_Memo_Amount__c +=  (Math.abs(oldPackageNextMonthTotalAmount) +gstAmount);                                                 
                            mapOfCreditmemolineitem.put('Update Enrolment invoice Adjustment',listOfCreditmemolineitem);  
                            //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.

                             //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                             if(string.isNotBlank(invoicelineitemId)){
                                decimal invoicelineItemCreditAmount=0;
                                decimal invoicelineItemCreditGst=0;
                                
                                if(updateInvoiceLineItem.containskey(invoicelineitemId)){
                                    invoicelineItemCreditAmount =updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c :0;
                                    invoicelineItemCreditGst = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c :0;
                                }
                                updateInvoiceLineItem.put(invoicelineitemId,new Invoice_Line_Item__c(id=invoicelineitemId,
                                                        Credit_Memo_Amount__c =invoicelineItemCreditAmount+(Math.abs(oldPackageNextMonthTotalAmount)),
                                                        Credit_Memo_tax__c=invoicelineItemCreditGst+gstAmount));
                            }
                        }
                    }
                }
                
                if(invoiceLineItem.size() > 0){
                    INSERT invoiceLineItem;
                }
                 //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                 if(newPendingCreditMemos.size() > 0){
                     update objectOfInvoice;
                    Insert newPendingCreditMemos.values();  
                    system.debug('newPendingCreditMemos'+newPendingCreditMemos);
                    List<Credit_memo_line_item__c> listOfnewCreditmemolineitem = new list<Credit_memo_line_item__c>();
                    for(string creditMemoRemark : newPendingCreditMemos.keyset()){
                        if(mapOfCreditmemolineitem.containskey(creditMemoRemark)){
                            for(Credit_memo_line_item__c objCreditLineItem: mapOfCreditmemolineitem.get(creditMemoRemark)){
                                objCreditLineItem.Credit_Memo_Number__c = newPendingCreditMemos.get(creditMemoRemark).id;
                                listOfnewCreditmemolineitem.add(objCreditLineItem);
                            }
                        }
                    } 
                    if(listOfnewCreditmemolineitem != null && listOfnewCreditmemolineitem.size() > 0){
                        insert listOfnewCreditmemolineitem;
                    }
                                            
                }
                //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
              
                if(updateInvoiceLineItem != null && updateInvoiceLineItem.size() > 0){
                    update updateInvoiceLineItem.values();
                }
                
                //system.debug('@@ create new invoiceLineItem'+invoiceLineItem);
                if(String.isNotBlank(objectOfInvoice.id)){
                    SageIntacctIntegrationUtility.changeEnrolment(objectOfInvoice.Id);
                }
                if(objectOfInvoice != NULL){
                    
                    BillingUtility.createAttachment(new Set<String>{objectOfInvoice.id});
                }
                
            }
        }
       //system.debug('@@objectOfInvoice.Id'+objectOfInvoice.Id);
        return objectOfInvoice.Id;
    }
    
    //Wrapper Class For Upgrade Enrolment Callout
    public class UpgradeCaseCreation{
        public String invoiceId;
        public Decimal depositAmount;
        public Decimal lessonCharge;
        public Decimal total;
        public Enrolment__c enrolObj;
        public Boolean isSuccess = false;
    }
}