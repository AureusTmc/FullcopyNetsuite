/***
Name: UpgradeEnrolmentClassProcessController
Date: 03-Dec-2019
Author: Jatin
Description: this controller for Upgrade Enrolment Of group class Customer
test class: UpgradeEnrolmentClassProcessctrltest
*/
public without sharing class UpgradeEnrolmentClassProcessController implements IAdvanceAction{
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
    Private Map<String, String> mapOfCase;
    
    //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    Private Date nextBillDate;
    /*Private Country__c countryObj;commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic*/
    Private Organisation__c organisationObj;
    Private UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradeDetails;
    
    //Constructor to Initialize all the data members
    public UpgradeEnrolmentClassProcessController(String booking, String effectiveDateStr, String newPackage, 
                                                  String oldPackage,string newTeacherId,String timeSlot, String caseId, String caseRedirect, 
                                                  Map<String, String> caseValuesOfMap,string oldClassId,string newClassId) {
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
                                                      mapOfCase = new Map<String, String>();
                                                      mapOfCase = caseValuesOfMap;
                                                      enrolmentObj = new Enrolment__c();
                                                      //countryObj = new Country__c();commented by @nishi 21 sep 2020,Organisation wise charge as per new logic
                                                      organisationObj = new Organisation__c();
                                                      upgradeDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
                                                      
                                                  }
    
    //Init Method where all the process gets Start...
    Public String initProcess(){
        String caseIdToReturn;
        Savepoint upgradeSavePoint;
        try{
            
            enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
            //system.debug('@@enrolmentObj'+enrolmentObj);
            string oldTeacher;
            Boolean isSuccess = FALSE;
            Set<String> setOfBookings = new Set<String>();
            Map<String, Booking__c> mapOfMakeupBooking = new Map<String, Booking__c>();
            Boolean isGroupLesson = false;
            Boolean isOssiaOrganization = false;
            if( String.isNotBlank(newClassId)  &&  String.isNotBlank(oldClassId)){
                isGroupLesson = true;
            }
            //Fetch Next Bill Date From Enrolment
            if(String.isNotBlank(enrolmentObj.Id)){
                nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
                
                //Fetch the Country Object From Enrolment
                // countryObj = AdvanceActionsHelper.fetchCountryFromEnrolment(enrolmentObj);
                if(String.isNotBlank(enrolmentObj.Id) && string.isNotBlank(enrolmentObj.Center__c) && String.isNotBlank(enrolmentObj.center__r.Organisation__c)){
                    organisationObj = enrolmentObj.center__r.Organisation__r;
                    if(string.isNotBlank(enrolmentObj.Center__r.Organisation__r.Name) &&
                        enrolmentObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        isOssiaOrganization = true;
                    }
                } 
                oldTeacher = enrolmentObj.Teacher__c;
            }
            //Start:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
            /*if(effectiveDate <= nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, nextBillDate, newPackage, oldPackage, timeslot, countryObj,newTeacherId);
enrolmentObj = upgradeDetails.enrolObj;
}*/
            //end:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
            if(effectiveDate < nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(organisationObj.Id)){
                upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, nextBillDate, newPackage, 
                                                                oldPackage, timeslot,
                                                                organisationObj,newClassId ,newTeacherId,isOssiaOrganization);
                enrolmentObj = upgradeDetails.enrolObj;
                //system.debug('@@enrolmentObj1'+enrolmentObj);
            }else if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(organisationObj.Id)){
                upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, organisationObj, effectiveDate,isOssiaOrganization);
                /*else if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
                upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, countryObj, effectiveDate);
                */ if(upgradeDetails.isSuccess){
                    enrolmentObj.New_Package_Id__c = newPackage;
                    enrolmentObj.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
                    enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
                    enrolmentObj.Effective_Date__c = effectiveDate;
                    enrolmentObj.Package_Process_Request_Date__c = System.today();
                    enrolmentObj.Advance_Action_Requested_By__c = Userinfo.getUserId();
                    enrolmentObj.Next_Lesson_Start_time__c = timeslot;
                    enrolmentObj.New_Class__c = newClassId;
                    
                    // added by jatin: 4-jan-2020 : for add new changed enrollment day  and teacher
                    DateTime newEffectiveDateTime = DateTime.newInstance(effectiveDate, timeslot);
                    enrolmentObj.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
                    enrolmentObj.New_Teacher__c = newTeacherId;  
                    if(String.isNotBlank(enrolmentObj.Id)){
                        Database.SaveResult saveResult = Database.Update(enrolmentObj, false);
                        if(!saveResult.isSuccess()){
                            isSuccess = false;
                        }
                        
                    }
                }
            }
            upgradeSavePoint = Database.setSavepoint();
            //system.debug('@@@@enrolmentObj.id'+enrolmentObj);
            enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentObj.id);
            if(String.isNotBlank(enrolmentObj.Id) && upgradeDetails.isSuccess){
                // Manage future makeup booking  and if duration is differ then create new 
                Map<Date,String> mapOfEffectiveDateGroupLesson = getmapOfEffectiveDateGroupLesson(enrolmentObj,enrolmentObj.new_Class__c); 
                processFutureMakeupGroupLessonBookings(enrolmentObj,mapOfEffectiveDateGroupLesson);
                // create new future group lesson booking and added group class inbookings
                //commented by jatin:28-dec-2019 now we change our logic Now we updated not inserted .
                //uncommented by jatin:6-jan-2020 now we change our logic we change you class with new lesson day so thats why we deleted all previous lesson then create new one.
                
                processFutureGroupLessonBookings(enrolmentObj, mapOfEffectiveDateGroupLesson);
                //commented by jatin:12-dec-2019 now we change our logic Now we create not updateed.
                //processFutureBookings(enrolmentObj, 'upgrade_Group_lesson',enrolmentObj.new_Class__c,mapOfEffectiveDateGroupLesson);
                
            }
            
            if(caseRedirect == 'true'){
                Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(caseId, enrolmentObj.Id, 'upgrade', false);
                if(String.isNotBlank(upgradeDetails.invoiceId)){
                    objCase.Invoice__c = upgradeDetails.invoiceId;
                }
                objCase.deposit_Topup__c = upgradeDetails.depositAmount;
                objCase.Lesson_Charge_Topup__c = upgradeDetails.lessonCharge;
                objCase.Total_Invoice_topup__c  = upgradeDetails.total;
                if(mapOfCase.containsKey('previousPackage')){
                    objCase.Previous_Package__c = mapOfCase.get('previousPackage');    
                }
                if(mapOfCase.containsKey('newPackage')){
                    objCase.New_Package__c = mapOfCase.get('newPackage');    
                }
                if(mapOfCase.containsKey('previousLessonDayTime')){
                    objCase.Previous_Lesson_Day_Time__c = mapOfCase.get('previousLessonDayTime');    
                }
                if(mapOfCase.containsKey('newLessonDayTime')){
                    objCase.New_Lesson_Day_Time__c = mapOfCase.get('newLessonDayTime');    
                }
                if(mapOfCase.containsKey('currentDepositonFile')){
                    objCase.Current_Deposit_on_File__c = Decimal.valueOf(mapOfCase.get('currentDepositonFile'));    
                }
                if(mapOfCase.containsKey('newPackageDeposit')){
                    objCase.New_Package_Deposit__c = Decimal.valueOf(mapOfCase.get('newPackageDeposit'));    
                }
                if(mapOfCase.containsKey('invoiceForCurrentMonth')){
                    objCase.Invoice_for_Current_Month__c = Decimal.valueOf(mapOfCase.get('invoiceForCurrentMonth'));    
                }
                if(String.isNotBlank(newTeacherId)){
                    objCase.New_Teacher__c =  newTeacherId;   
                }
                if(String.isNotBlank(oldTeacher)){
                    objCase.Previous_Teacher__c = oldTeacher; 
                }
                
                upsert objCase;
                //system.debug('@@objCase.Id'+objCase.Id);
                caseIdToReturn = objCase.Id;
            }
            if(!upgradeDetails.isSuccess)
                caseIdToReturn = 'error';
        }catch (Exception e){
            caseIdToReturn = 'error';
            System.debug('@@caseIdToReturn'+e.getStackTraceString()+'-'+e.getMessage() +';');
            //On 14-Oct-2020: Nishi to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(upgradeSavePoint);
        }
        return caseIdToReturn;
    }
    
    // 27-Dec-2019: process Future Makeup Group Lesson Bookings
    public static void processFutureMakeupGroupLessonBookings(Enrolment__c enrolmentObj,Map<Date,String> mapOfEffectiveDateGroupLesson){
        map<Id,booking__c> mapOfMakeupBooking =new  map<Id,booking__c> ();
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
                                    }
        if(String.isNotBlank(enrolmentObj.Id) && mapOfMakeupBooking.size() > 0){
            updateMakeUpBookingOnUpgrade(enrolmentObj, mapOfMakeupBooking,mapOfEffectiveDateGroupLesson);
        }
    }
    // 27-Dec-2019: update makeup bookings if booking date is match in class booking_date
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
        List<Booking__C> bookingObjList = new List<Booking__C>();
        List<Booking__C> ossiaBookingList = new List<Booking__C>();
         /* List<Booking__C> bookingObjList =[SELECT Id,Start_time__c,End_time__c, Booking_Date__c, Available_Make_up_Units__c, 
                                            Student__r.Name, Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c,
                                            Duration__c, Type__c, Category__c 
                                            FROM Booking__c 
                                            WHERE id IN: bookingIds
                                           ];*/
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
    /*public  static List<Booking__c> fetchCancelBookings(Set<String> setOfStuParentIds){
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
    }*/
    
    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
    Private UpgradeEnrolmentProcessController.UpgradeCaseCreation updatePackageNextDateIsGreater(String enrolmentId, Date effectiveDate, Date nextBillDate, String newPackageId, String oldPackageId, 
                                                               Time newTimeSlot,/* Country__c countryObj*/Organisation__c  organisationObj,string newClassId,string newTeacherId,boolean isOssiaOrganization){
                                                                UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradeCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
                                                                   Boolean isSuccess = false;
                                                                   String invoiceId;
                                                                   if(String.isNotBlank(enrolmentId) && nextBillDate != Null && effectiveDate != Null &&
                                                                      String.isNotBlank(newPackageId) && String.isNotBlank(oldPackageId) && newTimeSlot != Null && String.isNotBlank(organisationObj.Id) /*String.isNotBlank(countryObj.Id)*/){
                                                                        /*  upgradeCaseDetails = upgradeGroupPackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, 
                                                                                                                   countryObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c,
                                                                                                                   countryObj.Tax_Rate__c,newClassId,newTeacherId);*/
                                                                            upgradeCaseDetails = upgradeGroupPackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, 
                                                                            organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c,
                                                                            organisationObj.Tax_Rate__c,newClassId,newTeacherId,isOssiaOrganization);
                                                                      }
                                                                   return upgradeCaseDetails;
                                                               }
    public static UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradeGroupPackage(Id enrollMentId,Date effectDate,Id PackageId,Id OldPackage, 
                                                          Time timeslot, String currencyCode, String baseUrl, String apiKey,
                                                          Decimal taxRate, string newClassId,string newTeacherId,Boolean isOssiaOrganization){
                                                            UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
        enrolment__c enrolmentObj = UpgradeDowngradeController.fetchEnrolment(enrollMentId);
        Boolean flag = false;
        String invoiceId;
        Map<String,Package__c> mapOfPackageFee = UpgradeDowngradeController.getPackage(oldPackage,PackageId);
        Package__c oldPackg = mapOfPackageFee.get(OldPackage);
        Package__c newPackg = mapOfPackageFee.get(PackageId);
       //system.debug('@@@oldPackg'+oldPackg);
       //system.debug('@@@newPackg'+newPackg);
        Subscription_Line_Item__c objSubLineItem = UpgradeDowngradeController.fetchSubsLineItem(enrollmentId);
        Integer countWithOldPackage = 0;
        Integer countWithNewPackage = 0;
        Integer minutesOfFifthBooking = 0;
        Decimal currentPackageDeposit = 0;
        Decimal newPackageNextMonthPrice = 0;
        Decimal gstNextMonthAmount = 0;
        //Create MAp for Create makeup Booking
        Map<String, Booking__c> mapOfMakeupBooking = new Map<String, Booking__c>();
        Date effectiveDate = effectDate; //objSubLineItem.Enrolment__r.Effective_Date__c;
        List<Booking__c> listOfBookings = UpgradeDowngradeController.fetchListOfBookings(enrollmentId,effectDate);
       //system.debug('@@listOfBookings'+listOfBookings);
       //system.debug('@@@effectDate'+effectDate);
        //@Jatin, 23 October 2019, Change due to populate the tax amount on invoice line item. 
        
        Decimal newPackageUnitPrice = 0;
        Decimal depositeFee = 0;
        Decimal totalAmount = 0; Decimal gstAmount = 0; Decimal totalWithNoGST = 0;
        Decimal fifthBookingPrice = 0;
        
        Integer countWithNewPackageupgrade = 0;
        Integer countNextMonthPackageupgrade = 0;
        Map<string,Decimal> invoiceAdjustmentMap = new Map<string,Decimal>();
        for(Booking__c objBooking : listOfBookings){
            if(objBooking.Booking_Date__c >= effectiveDate){
                // @jatin:3 -dec: add group class
                if(objBooking.Type__c == ConstantsClass.groupLessonTypeBooking ){
                    countWithNewPackageupgrade +=1;
                    newPackageUnitPrice += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                    if(taxRate > 0){
                        gstAmount += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c) * taxRate/100;
                    }
                } 
            }
        }
        invoiceAdjustmentMap.put('positiveInvoiceAmount',(countWithNewPackageupgrade * newPackg.Unit_Fee__c));
        invoiceAdjustmentMap.put('negativeInvoiceAmount',(countWithNewPackageupgrade * oldPackg.Unit_Fee__c));
        // // added by Nishi: 21-Sep-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
       //  // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 
        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        date nextBillDate = objSubLineItem.Next_Bill_Date__c;
        if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month()){
            List<Booking__c> listOfNextMonthBookings = UpgradeDowngradeController.fetchListOfNextMonthBookings(enrollmentId);
            for(Booking__c objBooking : listOfNextMonthBookings){
                if(objBooking.Booking_Date__c >= effectiveDate){
                    if(objBooking.Type__c == ConstantsClass.groupLessonTypeBooking){
                        countNextMonthPackageupgrade+=1;
                        newPackageNextMonthPrice += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                        if(taxRate > 0){
                            gstNextMonthAmount += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c) * taxRate/100;
                        }
                    }      
                }
            }
            invoiceAdjustmentMap.put('positiveNextMonthInvoiceAmount',(countNextMonthPackageupgrade * newPackg.Unit_Fee__c));
            invoiceAdjustmentMap.put('negativeNextMonthInvoiceAmount',(countNextMonthPackageupgrade * oldPackg.Unit_Fee__c));
        }
           // // added by Nishi: 21-Sep-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
       //  // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 

       //system.debug('@@@@@newPackageUnitPrice'+newPackageUnitPrice);
       //system.debug('@@@@@gstAmount'+gstAmount);
       //system.debug('@@enrollMentId'+enrollMentId);
        
        //return sum of all deposit amount for enrolment
        if(String.isNotBlank(enrollMentId)){
            currentPackageDeposit = AureusCalendarController.getDepositFromFile(enrollMentId);
        }
        
        depositeFee = (newPackg.Deposit_Fee__c - currentPackageDeposit);
        
        totalAmount = (newPackageUnitPrice + gstAmount + depositeFee);
        totalWithNoGST = (newPackageUnitPrice + depositeFee);
        String stripeId = string.isNotBlank(objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c) ? objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c :'';
       //system.debug('@@@@@newPackageUnitPrice'+newPackageUnitPrice);
       //system.debug('@@@@@gstAmount'+gstAmount);
       //system.debug('@@@@@totalAmount'+totalAmount);
       //system.debug('@@@@@depositeFee'+depositeFee);
       //system.debug('@@@@@totalWithNoGST'+totalWithNoGST);
       //system.debug('@@@@@stripeId'+stripeId);
        //Summary Details for case for upgrade package.....
        upgradePackageCaseDetails.depositAmount = depositeFee;
        Decimal lessonCharge = newPackageUnitPrice + gstAmount;
        if(newPackageNextMonthPrice != 0){
            totalAmount += (newPackageNextMonthPrice + gstNextMonthAmount);
            totalWithNoGST += newPackageNextMonthPrice;
            lessonCharge += (newPackageNextMonthPrice + gstNextMonthAmount);
            gstNextMonthAmount = BillingUtility.roundOffAmount(gstNextMonthAmount);
        }
        upgradePackageCaseDetails.lessonCharge = BillingUtility.roundOffAmount(lessonCharge);
        totalAmount = BillingUtility.roundOffAmount(totalAmount);
        totalWithNoGST = BillingUtility.roundOffAmount(totalWithNoGST);
        if(totalAmount > 0){
            upgradePackageCaseDetails.isSuccess = true;
            upgradePackageCaseDetails = invoiceForupgradegroupleassonPackages( upgradePackageCaseDetails, enrolmentObj,
                                                stripeId,   currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, invoiceAdjustmentMap, newClassId,totalAmount,isOssiaOrganization);
            if(upgradePackageCaseDetails.isSuccess){
                if(totalWithNoGST > 0){
                    upgradePackageCaseDetails.total = totalWithNoGST;
                }
            }
        }else{
            //flag = false;
            upgradePackageCaseDetails.isSuccess = false;
        }
        
       //system.debug('@@upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails ;
    }

    Private static UpgradeEnrolmentProcessController.UpgradeCaseCreation invoiceForupgradegroupleassonPackages(UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,enrolment__c objEnrol,
                                                                        String stripeId, string currencyCode,string baseUrl,string apiKey,Subscription_Line_Item__c objSubLineItem ,Decimal depositeFee,
                                                                        Package__c oldPackg, Package__c newPackg, Date effectDate, Time timeslot, Decimal taxRate,string newTeacherId,
                                                                        Map<string,Decimal> invoiceAdjustmentMap,string newClassId,decimal totalAmount,Boolean isOssiaOrganization){
        Boolean isCreateEnrolment = false;
        if(totalAmount > 0){
            if(string.isNotBlank(stripeId)){
                BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId,totalAmount, currencyCode, baseUrl, apiKey); 
                //system.debug('@@chargeResponse'+chargeResponse);
                if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                        // added by nishi: 24-oct-2020:  We have created a new invoice for additional deposits and full lesson fees for the enhanced package for the remaining period in the current invoice. we create a credit memo for  the previous package for the remaining period
                    // and then adjust this credit memo to the newly upgraded package invoice And the remaining invoice amount we charged via Stripe.                                                                
                    Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = UpgradeDowngradeController.createCreditMemoForCurrentMonthUpgradeProcess(new List<Invoice__c>(),invoiceAdjustmentMap,objEnrol,effectDate,objSubLineItem, taxRate, false,oldPackg.id);
                    upgradePackageCaseDetails =  UpgradeDowngradeController.createUpgradedAmountInvoice(new List<Invoice__c>(), objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, objEnrol,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,false);
                    if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Balance_Amount__c,Status__c, Parent_Account__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                        objInvoice.Status__c = constantsClass.paidStatus;
                        update objInvoice;
                    
                        upgradePackageCaseDetails.isSuccess = true;
                        
                        if(!Test.isRunningTest()&& String.isNotBlank(baseUrl) && String.isNotBlank(apiKey)){
                            BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, baseUrl, apiKey);                    
                        }
                        Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,totalAmount,ConstantsClass.successStatus);
                        objPayment.Transaction_ID__c = chargeResponse.Id;
                        objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                        INSERT objPayment; 
                        isCreateEnrolment = true;
                        if(objInvoice != NULL){
                            BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                        }
                         if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                            SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                        }
                    }
                }else{
                    //flag = false;
                    upgradePackageCaseDetails.isSuccess = false;
                    if(isOssiaOrganization){
                        Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = UpgradeDowngradeController.createCreditMemoForCurrentMonthUpgradeProcess(new List<Invoice__c>(),invoiceAdjustmentMap,objEnrol,effectDate,objSubLineItem, taxRate, false,oldPackg.id);
                        upgradePackageCaseDetails =  UpgradeDowngradeController.createUpgradedAmountInvoice(new List<Invoice__c>(), objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, objEnrol,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,false);
                        if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                            isCreateEnrolment = true;
                            upgradePackageCaseDetails.isSuccess = true;
                            Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                            if(objInvoice != NULL){
                                BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                            }
                        }
                    }
                }  
            }else{
                upgradePackageCaseDetails.isSuccess = false;
                  //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                if(isOssiaOrganization){
                    Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = UpgradeDowngradeController.createCreditMemoForCurrentMonthUpgradeProcess(new List<Invoice__c>(),invoiceAdjustmentMap,objEnrol,effectDate,objSubLineItem, taxRate, false,oldPackg.id);
                    upgradePackageCaseDetails =  UpgradeDowngradeController.createUpgradedAmountInvoice(new List<Invoice__c>(), objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, objEnrol,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,false);
                    if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        isCreateEnrolment = true;
                        upgradePackageCaseDetails.isSuccess = true;
                        BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{upgradePackageCaseDetails.invoiceId});
                    }
                }
                  //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
            } 
        }else{
            upgradePackageCaseDetails.isSuccess = false;
        }  
        if(isCreateEnrolment){
            upgradePackageCaseDetails.enrolObj = updateEnrollment(objEnrol.id,newPackg.Id, timeslot, effectDate,newClassId,newTeacherId);
            upgradePackageCaseDetails.enrolObj = UpgradeDowngradeController.fetchEnrolment(objEnrol.id);
        }
        return upgradePackageCaseDetails;
    }
    
    
    public static Enrolment__c updateEnrollment(Id enrolMentId,Id packageId, Time newTimeSlot, Date effectiveDate,string newClassId,string newTeacherId){
        Enrolment__c enrol = new Enrolment__c();
        enrol.Id = enrolMentId;
        enrol.Package__c = packageId;
        enrol.Class__c = newClassId;
        enrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
        enrol.Lesson_Start_time__c = newTimeSlot;
        enrol.Effective_Date__c = effectiveDate;
        enrol.New_Package_Id__c = packageId;
        enrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        enrol.Package_Process_Request_Date__c = System.today();
        enrol.Advance_Action_Requested_By__c = Userinfo.getUserId();
        enrol.Next_Lesson_Start_time__c = newTimeSlot;
        enrol.new_Class__c = newClassId;
        // added by jatin: 4-Jan -2020 for add new changed enrollment day  
        DateTime newEffectiveDateTime = DateTime.newInstance(effectiveDate, newTimeSlot);
        enrol.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
        enrol.Lesson_Day__c = newEffectiveDateTime.format('EEEE');
        enrol.Teacher__c = newTeacherId;
        enrol.New_Teacher__c = newTeacherId;
        update enrol;
        return enrol;
    }
    
    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
    Private UpgradeEnrolmentProcessController.UpgradeCaseCreation updatePackageEffectiveDateIsGreater(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId,/* Country__c centreCountry*/
    Organisation__c  organisationObj, Date effectiveDate,Boolean isOssiaOrganization){
        Boolean isSuccess = false;
        UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
        String invoiceId = '';
        String stripeId = '', parentId = '';
        Decimal currentPackageDeposit = 0;
        Package__c newPackage, oldPackage = new Package__c();
        Set<String> invoiceIds = new Set<String>();
        AureusCalendarController.UpgradeDowngradePackageSummary summary = AureusCalendarController.getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
        newPackage = summary.newPackage;
        oldPackage = summary.oldPackage; 
        //system.debug('##newPackage'+newPackage);
        if(String.isNotBlank(enrolmentObj.Id)){
            currentPackageDeposit = AdvanceActionsHelper.getDepositFromFile(enrolmentObj.Id);
        }
        //system.debug('!!currentPackageDeposit'+currentPackageDeposit);
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        //system.debug('!!newPackage.Deposit_Fee__c'+newPackage.Deposit_Fee__c);
        Decimal depositeFee = BillingUtility.roundOffAmount((newPackage.Deposit_Fee__c - currentPackageDeposit)); 
        //system.debug('!!depositeFee'+depositeFee);
        if(enrolmentObj != Null){
            stripeId = string.isNotBlank(enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c) ? enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c :'';
            parentId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
        
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
        upgradePackageCaseDetails.total = depositeFee;
        upgradePackageCaseDetails.isSuccess = true;
       //system.debug('!!stripeId'+stripeId);
        //system.debug('!!depositeFee'+depositeFee);
         //system.debug('!!centreCountry.Id'+centreCountry.Id);
        if(depositeFee > 0 && String.isNotBlank(organisationObj.Id)){ //commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic*/String.isNotBlank(centreCountry.Id)){
           if(String.isNotBlank(stripeId)){ 
                Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
                //commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic*/
                //BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c); 
                BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c); 
                
            //system.debug('@@@chargeResponse'+chargeResponse);
                if(chargeResponse.statusCode == 200 && chargeResponse.paid){                
                    isSuccess = true;
                    upgradePackageCaseDetails = createDueInvoiceWithLineItem(enrolmentObj,parentId,upgradePackageCaseDetails,depositeFee,newPackage,effectiveDate);
                    if(String.isNotBlank(upgradePackageCaseDetails.invoiceId)){  
                        Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                        objInvoice.status__c = constantsClass.paidStatus;
                        update objInvoice;
                        if(!Test.isRunningTest() &&  String.isNotBlank(organisationObj.Id)){ //String.isNotBlank(centreCountry.Id)){
                        //commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic*/
                            // BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                            BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
                        }
                        
                        
                        Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, BillingUtility.roundOffAmount(objInvoice.Total_Amount__c), ConstantsClass.successStatus);
                        objPayment.Transaction_ID__c = chargeResponse.Id;
                        objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                        INSERT objPayment; 
                        
                        if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                            SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                        }
                        
                        if(objInvoice != NULL){
                            invoiceIds.add(objInvoice.Id);
                            BillingUtility.createAttachment(invoiceIds);
                        }
                    }
                }else{
                    isSuccess = false;
                    upgradePackageCaseDetails.isSuccess = false;
                    //upgrade should be allowed and invoice should be still generated even if the card is failed
                    if(isOssiaOrganization){
                        upgradePackageCaseDetails = createDueInvoiceWithLineItem(enrolmentObj,parentId,upgradePackageCaseDetails,depositeFee,newPackage,effectiveDate);
                        if(String.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                            Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                            if(objInvoice != NULL){
                                invoiceIds.add(objInvoice.Id);
                                BillingUtility.createAttachment(invoiceIds);
                            }
                            upgradePackageCaseDetails.isSuccess = true;
                        }
                    }
                }
            }else{
                isSuccess = false;
                upgradePackageCaseDetails.isSuccess = false;
                //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                if(isOssiaOrganization){
                    upgradePackageCaseDetails = createDueInvoiceWithLineItem(enrolmentObj,parentId,upgradePackageCaseDetails,depositeFee,newPackage,effectiveDate);
                    if(String.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{upgradePackageCaseDetails.invoiceId});
                        upgradePackageCaseDetails.isSuccess = true;
                    }
                }
                 //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
            }
        }else{
            isSuccess = false;
            upgradePackageCaseDetails.isSuccess = false;
        }
       //system.debug('@@@updatePackageEffectiveDateIsGreater upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails;
    }

    public static UpgradeEnrolmentProcessController.UpgradeCaseCreation createDueInvoiceWithLineItem(Enrolment__c enrolmentObj,string parentId,UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,
    Decimal depositeFee, package__c newPackage, date effectiveDate){
        Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.dueStatus);
        objInvoice.Center__c = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.center__c;

        insert objInvoice;

        if(String.isNotBlank(objInvoice.Id)){
            upgradePackageCaseDetails.invoiceId = objInvoice.Id;
        }
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        if(depositeFee > 0){
        Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
        inlineItemforChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolmentObj.Subscription_Line_Items__r[0], depositeFee, newPackage.Id, true, '');
        inlineItemforChange.Month__c = effectiveDate;
        inlineItemforChange.Is_Deposit__c = True;
        listOfInvoiceLineItems.add(inlineItemforChange);
        }

        if(listOfInvoiceLineItems.size() > 0){
        INSERT listOfInvoiceLineItems;
        }
        return upgradePackageCaseDetails; 
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
    
    /*Public Static void processFutureBookings(Enrolment__c enrolmentObj, String type, string newClassId,Map<Date,String> mapOfEffectiveDateGroupLesson){
        // add by jatin:5:Dec:2019 - upgraded booking then add same date Groupclass booking
       //system.debug('@@@enrolmentObj.class__c'+enrolmentObj.class__c);
        Integer timeDuration = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        for(Booking__c objBook : [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                  Group_Class__r.Booking_Date__c,Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                  Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c 
                                  FROM Booking__c WHERE Enrolment__c = :enrolmentObj.Id
                                  AND Booking_Date__c >= :enrolmentObj.effective_Date__c
                                  AND Type__c = :ConstantsClass.groupLessonTypeBooking 
                                  And RecordType.name =: ConstantsClass.groupLessonBookingRecordType 
                                  AND Status__c != :ConstantsClass.statusCanceled]){
                                      if(objBook.Enrolment__r.Next_Lesson_Start_time__c != NULL && type == 'upgrade_Group_lesson'){
                                          objBook.start_time__c = objBook.Enrolment__r.Next_Lesson_Start_time__c;
                                      }else if(objBook.Enrolment__r.Lesson_Start_time__c != NULL){
                                          objBook.start_time__c = objBook.Enrolment__r.Lesson_Start_time__c;
                                      }
                                      // add by jatin:5:Dec:2019 - upgraded booking then add same date Groupclass booking
                                      if(mapOfEffectiveDateGroupLesson!= null && mapOfEffectiveDateGroupLesson.size() > 0){
                                          if(mapOfEffectiveDateGroupLesson.containsKey(objBook.Group_Class__r.Booking_Date__c)){
                                              objBook.Group_Class__c = mapOfEffectiveDateGroupLesson.get(objBook.Group_Class__r.Booking_Date__c);
                                          }
                                      }
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__r.Duration__c) && String.isNotBlank(objBook.package__r.Duration__c)){
                                          timeDuration =  Integer.valueOf(objBook.Enrolment__r.new_package_Id__r.Duration__c) - Integer.valueOf(objBook.package__r.Duration__c);                      
                                      }
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.New_Teacher__c)){
                                          objBook.teacher_Account__c = objBook.Enrolment__r.New_Teacher__c;
                                      }   
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__c)){
                                          objBook.package__c = objBook.Enrolment__r.new_package_Id__c; 
                                      }
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__c)){
                                          objBook.end_time__c = objBook.start_Time__c.addMinutes(Integer.valueOf(objBook.Enrolment__r.new_package_Id__r.Duration__c));
                                      }else{
                                          objBook.end_time__c = objBook.start_Time__c.addMinutes(Integer.valueof(objBook.package__r.Duration__c));
                                      }
                                      
                                      bookingList.add(objBook);
                                  }
        if(bookingList.size() > 0){
           //system.debug('@@updateEnrollment'+bookingList);
            UPSERT bookingList;
        }
    }*/
    
    
}