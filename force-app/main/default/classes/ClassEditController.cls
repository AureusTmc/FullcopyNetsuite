/*
	Class Name	:	ClassEditController
	Date        :   2019/08/20      
	Description :   This is a Controller for Class Edit Functionality.
*/
public class ClassEditController {
	/*
		This Method will return the Edit Screen Group lesson details 
	 */
    @RemoteAction
    Public static BookDetails fetchBookDetailsForScreen(String bookingId){
    	BookDetails bookDetails;
       // List<AureusCalendarController.GroupPackage> groupPackages;
        List<Booking__c> bookingList = new List<Booking__c>();
        Boolean isOssia = false; //added by nishi:2-sep-2020;
                 
        if(String.isNotBlank(bookingId)){
            // selected Group lesson details
            Booking__c bookObj = fetchSelectedBookingDetails(bookingId);
            /* 27-Feb-2020: commented by jatin for this pacakge list is not using in calendar
            if(String.isNotBlank(bookObj.Center__c)){
            	groupPackages = AureusCalendarController.fetchGroupPackages(bookObj.Center__c,bookObj.Teacher_Account__c); 
                //groupPackages = AureusCalendarController.fetchGroupPackages(bookObj.Center__c,bookObj.Package__r.Package_Fee__c);    
            }*/
            // selected Group lesson Booking details
            if(String.isNotBlank(bookObj.Id)){
                bookingList = fetchAllBookingsForClass(bookObj.Id);
                //start:added by nishi: 2-Sep-2020: for get selected class center is related to Ossia organization group class 
                if(String.isNotBlank(bookObj.Class__r.Centre_Name__c) && String.isNotBlank(bookObj.Class__r.Centre_Name__r.Organisation__c) && String.isNotBlank(bookObj.Class__r.Centre_Name__r.Organisation__r.Name) &&
                bookObj.Class__r.Centre_Name__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    isOssia = true; 
                }
                //end:added by nishi: 2-Sep-2020: for get selected class center is related to Ossia organization group class 
            }
            
            
            // selected Group lesson history details
            bookDetails = new BookDetails(bookObj, /*groupPackages, */bookingList,isOssia);
            bookDetails.bookingHistoryList = AureusCalendarController.getBookingHistory(bookingId);
        }
        return bookDetails;
    }
    
    //@@jatin:17-Dec-2019:get All Group type students for manage available group lesson min.
    @RemoteAction
    public static String getGroupStudents(String studentName,string centerId){
        string recordTypeCustomer = ConstantsClass.recordTypeCustomer;
        Map<Id, Integer> parentMakeupHours = new Map<Id, Integer>();
        List<Account> accList = new List<Account>();
        List<AureusCalendarController.Students> sObjList = new List<AureusCalendarController.Students>();
        AureusCalendarController.Students sObj = new AureusCalendarController.Students();
        List<String> listOfEnrolmentStudents = new List<String>(); 
        For(Enrolment__c objEnrolment :[Select Id,Student__c 
                                                From Enrolment__c
                                                Where Class__C != Null
                                                And type__c =: ConstantsClass.enrolGroupType]){
            listOfEnrolmentStudents.add(objEnrolment.Student__c);
        }
        system.debug('!!!listOfEnrolmentStudents'+listOfEnrolmentStudents);
        system.debug('!!!studentName'+studentName);
        if(listOfEnrolmentStudents!= null && listOfEnrolmentStudents.size() > 0){
            accList = [SELECT Id, Name, RecordType.Name, available_Make_up_mins_For_Group__c, Also_a_Student__c, Parent__c, 
                        Parent__r.available_Make_up_mins_For_Group__c, Parent__r.Name, PersonEmail, Parent__r.PersonEmail, PersonMobilePhone ,
                        Parent__r.PersonMobilePhone FROM
                        Account 
                        WHERE RecordType.Name =:recordTypeCustomer 
                        AND ((Also_a_Student__c = true AND Parent__c = NULL)
                        OR (Parent__c != NULL AND Also_a_Student__c = false)) 
                        AND Id IN :listOfEnrolmentStudents
                        AND (Name LIKE :'%'+studentName+'%')
                        AND Centre_Name__c=:centerId LIMIT 10];
            system.debug('!!!accList'+accList);
            if(accList != null && accList.size() >0 ){
                for(Account acc : accList){
                    sObj = new AureusCalendarController.Students();
                    sObj.id = acc.Id;
                    sObj.label = acc.Name;
                    
                    if(acc.Also_a_Student__c && String.isBlank(acc.Parent__c)){
                        sObj.parentId = '';
                        sObj.parentName = '';
                        sObj.email = acc.PersonEmail;
                        sObj.phone = acc.PersonMobilePhone;
                        sObj.makeupHours = Integer.valueOf(acc.available_Make_up_mins_For_Group__c);
                    }else if(acc.Also_a_Student__c == false && String.isNotBlank(acc.Parent__c)){
                        sObj.parentId = acc.Parent__c;
                        sObj.parentName = acc.Parent__r.Name;
                        sObj.email = acc.Parent__r.PersonEmail;
                        sObj.phone = acc.Parent__r.PersonMobilePhone;
                        sObj.makeupHours = Integer.valueOf(acc.Parent__r.available_Make_up_mins_For_Group__c);
                    }
                    if(sObj.makeupHours == NULL){
                        sObj.makeupHours = 0;
                    }
                    sObjList.add(sObj);
                }
            }
        }
         return JSON.serialize(sObjList);
    }


    //@@jatin: 2-dec-2019: getLastLessonDate method is use for getting last date of lesson on selecting the withdraw end Date.
        
    @RemoteAction      
    public static AureusCalendarController.WithdrawalSummary getWithdrawGroupClassSummary(String bookingId, String withdrawEndDate, String lastLessonDate){
        AureusCalendarController.WithdrawalSummary withdrawSummary = new AureusCalendarController.WithdrawalSummary();
        Date withdrawEndDateObj, lastLessonDateObj, nextBillingDate;
        List<AureusCalendarController.Lessons> lastLessonsList = new List<AureusCalendarController.Lessons>();
        List<AureusCalendarController.Lessons> makeupPendingList = new List<AureusCalendarController.Lessons>();
        Enrolment__c enrolment;
        Country__c countryObj = new Country__c();
        
        if(String.isNotBlank(withdrawEndDate)){
            withdrawEndDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(lastLessonDate)){
            lastLessonDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(bookingId)){
            
            enrolment = AureusCalendarController.getEnrolDetails(bookingId);
            if(String.isNotBlank(enrolment.Center__r.Country__r.Id)){
                countryObj = enrolment.Center__r.Country__r;    
            }
            
        }
        
        if(String.isNotBlank(enrolment.Id)){
            nextBillingDate = AureusCalendarController.getNextBillingDate(enrolment.Id);
            if(String.isNotBlank(enrolment.Id) && lastLessonDateObj != NULL && nextBillingDate != NULL){
                withdrawSummary.lastLessons = getLast4Lessons(enrolment.Id, lastLessonDateObj, nextBillingDate);
                withdrawSummary.finalDeposits = AureusCalendarController.getFinalDepositSummary(withdrawSummary.lastLessons);
                withdrawSummary.makeupLessons = getPendingMakeupBookings(enrolment.Id, lastLessonDateObj);
            }
        }
        if(enrolment != NULL){
            Decimal total = 0, gst = 0;
            DateTime dt = DateTime.newInstance(enrolment.Lessons_Start_Date__c, enrolment.Lesson_Start_time__c);
            withdrawSummary.student = enrolment.student__r.Name;
            withdrawSummary.packageName = enrolment.Package__r.Name;
            withdrawSummary.centre = enrolment.Center__r.Name;
            withdrawSummary.LessonDay = dt.format('dd MMM, yyyy hh:mma');
            dt = DateTime.newInstance(withdrawEndDateObj, enrolment.Lesson_Start_time__c);
            withdrawSummary.noticeDate = dt.format('dd MMM, yyyy');
            dt = DateTime.newInstance(lastLessonDateObj, enrolment.Lesson_Start_time__c);
            withdrawSummary.lastDate = dt.format('dd MMM, yyyy');
            withdrawSummary.deposit =   AureusCalendarController.getDepositFromFile(enrolment.id);     //enrolment.Package__r.Deposit_Fee__c;
            if(withdrawSummary.finalDeposits != NULL && withdrawSummary.finalDeposits.size() != 0){
                for(AureusCalendarController.Lessons currentLesson : withdrawSummary.finalDeposits){
                    total += currentLesson.unitPrice;
                }
                if(total > 0 && countryObj.Tax_Rate__c > 0){
                    gst = total  * (countryObj.Tax_Rate__c / 100);
                }
            }
            withdrawSummary.refund = 0;
            withdrawSummary.total = total + gst;
            withdrawSummary.gst = gst;
            if(withdrawSummary.deposit > 0){
                withdrawSummary.refund = withdrawSummary.deposit - withdrawSummary.total;
            }
            //System.debug('lastLessonDateObj'+lastLessonDateObj);
            String chargeId = AureusCalendarController.fetchCurrentMonthPaymentEntry(enrolment,lastLessonDateObj);
            if(String.isNotBlank(chargeId) && (lastLessonDateObj < nextBillingDate)){
                withdrawSummary.refund += getLessonRefundAmount(enrolment,lastLessonDateObj);        
            }
        }
        return withdrawSummary;
    }

    // @@jatin:26-dec-2019 for withdrawal group lesson get Lesson Refund Amount according to group lesson bookings
    public static Decimal getLessonRefundAmount(Enrolment__c objEnrol,Date lastLessonDate){
        Decimal amount = 0;
        List<Booking__c> bookings = getCurrentBilledBooking(objEnrol.id,lastLessonDate);
        Integer count= 0;
        for(Booking__c objBook : bookings){
            if(objBook.booking_date__c > lastLessonDate){
                count+=1;
            }
        }
        if(count >0){
            amount = count * objEnrol.package__r.unit_fee__c;
            if(objEnrol.Center__r != null 
            && objEnrol.Center__r.Country__r != null 
            && objEnrol.Center__r.Country__r.Tax_Rate__c != null
            && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                amount+= (amount  * objEnrol.Center__r.Country__r.Tax_Rate__c)  / 100;
            }
            
        }
        return amount;
    }
      // @@jatin:26-dec-2019 : return currentBilledBookings
    private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDate){
        Date firstDate = Date.newInstance(lastLessonDate.year(),lastLessonDate.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
        return [SELECT Booking_Date__c 
                FROM Booking__c
                WHERE Enrolment__c=: enrolId 
                AND Booking_Date__c >=: firstDate 
                AND Booking_Date__c <=: lastDate
                AND (Type__c =: ConstantsClass.groupLessonTypeBooking) 
                //commented by :jatin: 7-Jan-2020: for show all type of bookings
                //AND (Status__c = :ConstantsClass.statusScheduled OR Status__c = :ConstantsClass.statusPending)
                ];
    }   
    // @@jatin:26-dec-2019 for withdrawal group lesson get last 4 lesson 
    public static List<AureusCalendarController.Lessons> getLast4Lessons(String enrolId, Date lastLessonDateObj, Date nextBillingDate){
            Map<String, String> mapOfInvoiceName = new Map<String, String>();
            mapOfInvoiceName = AureusCalendarController.getInvoiceFromEnrolment(enrolId);
            List<AureusCalendarController.Lessons> lessonsList = new List<AureusCalendarController.Lessons>();
            AureusCalendarController.Lessons lesson = new AureusCalendarController.Lessons();
            Set<String> bookingIdSet = new Set<String>();
            List<AureusCalendarController.Lessons> reverselessonList = new List<AureusCalendarController.Lessons>();
            Set<String> bookingStatus = new Set<String>();
            
            bookingStatus.add(ConstantsClass.statusScheduled); 
            bookingStatus.add(ConstantsClass.statusPending);
            bookingStatus.add(ConstantsClass.statusCompleted);
            bookingStatus.add(ConstantsClass.statusNoshow);
            
            Datetime formatedDate;
            
            for(Booking__c bookObj : [SELECT Id, Name, type__c, Status__c, Booking_Date__c, Start_Time__c, Duration__c, Package__c,
                                    Package__r.Name, Package__r.Unit_Fee__c, Student__r.Name 
                                    FROM Booking__c 
                                    WHERE Enrolment__c =: enrolId 
                                    AND Type__c =: ConstantsClass.groupLessonTypeBooking 
                                    AND Booking_Date__c <= :lastLessonDateObj 
                                    ORDER BY Booking_Date__c DESC LIMIT 4]){
                                        lesson = new AureusCalendarController.Lessons();
                                        bookingIdSet.add(bookObj.Id);                          
                                        formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
                                        lesson.bookingId = bookObj.Id;
                                        lesson.Lesson = bookObj.Package__r.Name;
                                        lesson.bookingDate = formatedDate.format('dd MMM, yyyy');
                                        lesson.bookingTime = formatedDate.format('hh:mma');
                                        lesson.duration = bookObj.Duration__c;
                                        lesson.unitPrice = bookObj.Package__r.Unit_Fee__c;
                                        lesson.student = bookObj.Student__r.Name;
                                        lesson.qty = 1;
                                        if(bookObj.Booking_Date__c < nextBillingDate){
                                            if(mapOfInvoiceName.keyset().size() > 0){
                                                lesson.status = mapOfInvoiceName.get('Id')+':'+ mapOfInvoiceName.get('Name');
                                            }else{
                                                lesson.status = 'Billed';
                                            }
                                            
                                        }else if(bookObj.Booking_Date__c >= nextBillingDate){
                                            lesson.status = 'Deposit';
                                        }
                                        reverselessonList.add(lesson); 
                                    }
            if(reverselessonList.size() > 0){
                for(integer i = reverselessonList.size() - 1; i >= 0; i--){
                    lessonsList.add(reverselessonList[i]);
                }
            }
            
            return lessonsList;
        }  


    // @@jatin: 26-dec-2019: for withdrawal group lesson  get Pending Makeup Bookings
    public static List<AureusCalendarController.Lessons> getPendingMakeupBookings(String enrolId, Date lastLessonDateObj){
        List<AureusCalendarController.Lessons> lessonsList = new List<AureusCalendarController.Lessons>();
        AureusCalendarController.Lessons lesson = new AureusCalendarController.Lessons();
        Set<String> bookingTypes = new Set<String>();
        bookingTypes.add(ConstantsClass.groupLessonTypeBooking);
        String statusCanceled = ConstantsClass.statusCanceled;
        Datetime formatedDate, lastDateObj;
        lastDateObj = DateTime.newInstance(lastLessonDateObj, Time.newInstance(0, 0, 0, 0));
        for(Booking__c bookObj : [SELECT Id, Student__r.Name, Booking_Date__c, Canceled_Date__c, Start_Time__c, 
                                    Available_Make_up_Units__c, Make_up_Expiry_Date__c 
                                    FROM Booking__c
                                    WHERE enrolment__c =: enrolId 
                                    AND Type__c IN: bookingTypes 
                                    AND Status__c =: statusCanceled 
                                    AND Available_Make_up_Units__c > 0 
                                    AND Make_up_Expiry_Date__c >= TODAY 
                                    ORDER BY Canceled_Date__c]){
            lesson = new AureusCalendarController.Lessons();
            formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
            lesson.bookingId = bookObj.Id;
            lesson.duration = bookObj.Available_Make_up_Units__c;
            lesson.bookingTime = formatedDate.format('hh:mma');
            lesson.student = bookObj.student__r.Name;
            
            if(bookObj.Canceled_Date__c != NULL){
                
                DateTime bookingDate = DateTime.newInstance(bookObj.Booking_Date__c, Time.newInstance(0, 0, 0, 0));
                lesson.cancelDate = bookingDate.format('dd MMM, yyyy'); 
            }else{
                lesson.cancelDate = '';
            }
            
            formatedDate = DateTime.newInstance(bookObj.Make_up_Expiry_Date__c, bookObj.Start_Time__c);
            lesson.expiryDate = formatedDate.format('dd MMM, yyyy');
            lesson.nextExpiryDate = lastDateObj.format('dd MMM, yyyy');
            lessonsList.add(lesson);
        }
        return lessonsList;
    }  
    // @@jatin: 26-dec-2019: for withdrawal group lesson  type booking 
     @RemoteAction
    public static String cancelGroupLessonSubscriptionRequest(String bookingId, String endDate, String lastLessonDate, String myCase, String redirectCase){
        String caseIdToReturn;
        if(String.isNotBlank(bookingId)){
                IAdvanceAction withdrawlPackageObj;
                withdrawlPackageObj = new WithDrawlEnrolmentClassProcessController(bookingId, endDate, lastLessonDate, 
                                                                         myCase,redirectCase);
                caseIdToReturn = WithdrawlPackageObj.initProcess();
        }
        return caseIdToReturn;
    }
    //@jatin:03-Dec-2019 : for manage upgrade group class bookings  
    @RemoteAction
    public static String upgradePackageClassOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 Map<String, String> caseValues,string oldClassId,String newClassId,string newTeacherId){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldClassId) && String.isNotBlank(newClassId)
                                                        && String.isNotBlank(newTeacherId)  ){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpgradeEnrolmentClassProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                oldPackageId,newTeacherId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                caseValues,oldClassId, newClassId);
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
    }

    //@jatin:04-Jan-2019 : for manage update group class to same other class bookings  
    @RemoteAction
    public static String updateGroupClassToSamePackageOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 string oldClassId,String newClassId,string newTeacherId){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldClassId) && String.isNotBlank(newClassId)
                                                        && String.isNotBlank(newTeacherId)  ){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpdateEnrolmentClassProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                oldPackageId,newTeacherId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                oldClassId, newClassId);
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
    }

    //@jatin:24-Dec-2019 : for manage upgrade To Individual Class Of Customer bookings  
    @RemoteAction
    public static String upgradeToIndividualClassOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 Map<String, String> caseValues,string oldTeacherId,String newTeacherId){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldTeacherId) && String.isNotBlank(newTeacherId)  ){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpgradeToIndividualProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                oldPackageId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                caseValues, newTeacherId);
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
    }

// @jatin 28-Nov-2019 : get summary with new and old class details
    @RemoteAction
    public static AureusCalendarController.UpgradeDowngradePackageSummary  getUpgradeGroupClassPackageSummary(String oldPackageId, String newPackageId, 
                                                                                    String currentEffectiveDateObj,String newEffectiveDate,
                                                                                     String availTimeSlots, String oldavailableTimeSlots,
                                                                                    String enrolmentId, String typeOfSummary,
                                                                                    string newTeacher,string oldTeacher,
                                                                                    String oldClassId,string newClassId){
        Map<String, String> enrolSummary = new Map<String, String>();
        DateTime newDateTime;
        DateTime currentDateTime;
        Date nextBillDate;
        Package__c newPackg, oldPackg = new Package__c();
        Integer minutesOfFifthBooking = 0;
        Integer countWithNewPackage = 0;
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>(); 
        AureusCalendarController.UpgradeDowngradePackageSummary summary = new AureusCalendarController.UpgradeDowngradePackageSummary();
        Set<id> setOfClassIds = new Set<Id>();
                                                                                        system.debug('!!oldClassId'+oldClassId);
                                                                                        system.debug('!!newClassId'+newClassId);
        if(String.isNotBlank(oldClassId) && String.isNotBlank(newClassId) &&   (typeOfSummary == 'GroupToHigherPackage' || typeOfSummary == 'GroupToSameClass' )){
            setOfClassIds.add(oldClassId);
            setOfClassIds.add(newClassId);
        }
        
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            summary = AureusCalendarController.getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
            newPackg = summary.newPackage;
            oldPackg = summary.oldPackage;            
        }
         /*jatin:24-dec-2019: for upgrade to individual booking add teachers  */
        if(string.isNotBlank(newTeacher) && string.isNotBlank(oldTeacher) ){
            set<String> teacherIds = new Set<String>{newTeacher,oldTeacher};
            Map<String,Account> mapOfAccount = New Map<String,Account>([Select id,Name from Account where Id in :teacherIds]);
            if(mapOfAccount.containsKey(newTeacher)){
                summary.newTeacherName = mapOfAccount.get(newTeacher).Name;
                summary.newTeacherId = mapOfAccount.get(newTeacher).Id;
            }
            if(mapOfAccount.containsKey(oldTeacher)){
                summary.oldTeacherName = mapOfAccount.get(oldTeacher).Name;
                summary.oldTeacherId = mapOfAccount.get(oldTeacher).Id;
            }
            
        }
        // @jatin 28-Nov-2019 : added new and old class details
        if(setOfClassIds != null && setOfClassIds.size() >0 &&  (typeOfSummary == 'GroupToHigherPackage' || typeOfSummary == 'GroupToSameClass' )){
            map<id,Class__c> mapOfClasses = new Map<Id,class__c>([Select id, name from Class__c where id in:setOfClassIds]);
            if(mapOfClasses != null && mapOfClasses.size() >0 ){
                if(mapOfClasses.containsKey(newClassId)){
                    summary.newClassName = mapOfClasses.get(newClassId).Name;
                    summary.newClassId = mapOfClasses.get(newClassId).id;
                }
                if(mapOfClasses.containsKey(oldClassId)){
                    summary.oldClassName = mapOfClasses.get(oldClassId).Name;
                    summary.oldClassId = mapOfClasses.get(oldClassId).id;
                }
            }
        }
        if(String.isNotBlank(enrolmentId)){
            summary.currentPackageDeposit = AureusCalendarController.getDepositFromFile(enrolmentId);
            enrolSummary = AureusCalendarController.getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
           if(enrolSummary.containsKey('currentTeacher')){
                summary.oldTeacherName = enrolSummary.get('currentTeacher');
            }
            if(enrolSummary.containsKey('currentClass')){
                summary.oldClassId = enrolSummary.get('currentClass');
            } // @jatin: 4:Jan:2020 : for show Class name in upgrade group class
            if(enrolSummary.containsKey('currentClassName')){
                summary.oldClassName = enrolSummary.get('currentClassName');
            }
            if(enrolSummary.containsKey('currentTeacherId')){
                summary.oldTeacherId = enrolSummary.get('currentTeacherId');
            }
            if(enrolSummary.containsKey('currentMonthInvoice')){
                summary.invoiceForCurrentMonth = Decimal.valueOf(enrolSummary.get('currentMonthInvoice'));
            }
            if(enrolSummary.containsKey('studentName')){
                summary.studentName = enrolSummary.get('studentName');
            }
            if(enrolSummary.containsKey('parentName')){
                summary.parentName = enrolSummary.get('parentName');
            }
            enrolmentList = AureusCalendarController.getNextBillingDateSubscription(enrolmentId);
            if(enrolmentList.size() > 0){
                nextBillDate = AureusCalendarController.getNextBillingSubscriptionLineItemDate(enrolmentList);
            } 
        }
        
        
        if(String.isNotBlank(newEffectiveDate) && String.isNotBlank(availTimeSlots)){
            newDateTime = AureusCalendarController.getDateTimeFromString(availTimeSlots);
            newDateTime = DateTime.newInstance(Date.valueOf(newEffectiveDate), newDateTime.time());
            //summary.newDayAndTime = newDateTime.format('EEE, MMM dd YYYY h:mm a');
            summary.newDayAndTime = newDateTime.format('EEE @ h:mm a');
            summary.effectiveDate = newDateTime.format('EEE, MMM dd YYYY');
        }
        if(String.isNotBlank(currentEffectiveDateObj)  && String.isNotBlank(oldavailableTimeSlots) ){
            currentDateTime = AureusCalendarController.getDateTimeFromString(oldavailableTimeSlots.trim());
            currentDateTime = DateTime.newInstance(Date.valueOf(currentEffectiveDateObj), currentDateTime.time());
            summary.currentDayAndTime = currentDateTime.format('EEE @ h:mm a');
            summary.currentEffectiveDate = currentDateTime.format('EEE, MMM dd YYYY');
        }
        if((typeOfSummary == 'upgrade class' || typeOfSummary == 'GroupToIndividual' || typeOfSummary == 'GroupToHigherPackage' ) && newDateTime != NULL && String.isNotBlank(enrolmentId)){
            List<Date> dates = AureusCalendarController.getMonthDates(newDateTime);
            List<Booking__c> listOfBookings = fetchBookingsForUpgrade(enrolmentId, dates);
            for(Booking__c objBooking : listOfBookings){
                if(objBooking.Booking_Date__c >= newDateTime.date()){
                    if(objBooking.Type__c == ConstantsClass.groupLessonBookingRecordType){
                        countWithNewPackage +=1;
                    }
                }
            }
            
            Decimal totalAmount = 0;
            Decimal depositeFee = (newPackg.Deposit_Fee__c - summary.currentPackageDeposit);
            summary.invoiceDepositTopup = depositeFee;
            Decimal newPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNewPackage ;
            
            
            if(typeOfSummary =='upgrade class' || typeOfSummary =='GroupToIndividual' || typeOfSummary == 'GroupToHigherPackage' ){
                if(summary.taxRate>0){
                    newPackageUnitPrice += newPackageUnitPrice * Decimal.valueOf(summary.taxRate)/100;
                }
                summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice);
                totalAmount = BillingUtility.roundOffAmount(newPackageUnitPrice);
                totalAmount +=   BillingUtility.roundOffAmount(depositeFee) ;
                if(newDateTime <= nextBillDate){
                    summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                }else{
                    summary.invoiceTopup = BillingUtility.roundOffAmount(depositeFee);
                    summary.invoiceDepositLessonTopup = 0;
                }
            }
            
        }
        //system.debug('@@summary'+summary);
        return summary;
    }
    public  static List<Booking__c> fetchBookingsForUpgrade(String enrolmentId, List<Date> dates){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c 
                FROM Booking__c 
                WHERE Enrolment__c=:enrolmentId AND 
                Booking_Date__c IN: dates 
                //jatin:7-jan-2020 : for now we calculate all booking 
                //AND Status__c !=: ConstantsClass.statusCanceled 
                AND Type__c =: ConstantsClass.groupLessonBookingRecordType];
    }
    
    //@@jatin:20-dec-2019: for get enrollment for group lesson convert regular booking
    @RemoteAction
    public static AureusCalendarController.EnrolmentEdit getGroupLessonEnrolmentUpdateDetails(String enrolmentId,string grade){
        AureusCalendarController.EnrolmentEdit enrolEdit = new AureusCalendarController.EnrolmentEdit();
        Map<String, String> enrolDetails = new Map<String, String>();
        if(String.isNotBlank(enrolmentId)){
            enrolDetails = AureusCalendarController.getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
            if(enrolDetails.containsKey('currentTeacher')){
                enrolEdit.currentTeacher = enrolDetails.get('currentTeacher');
            } 
            if(enrolDetails.containsKey('currentPackage')){
                enrolEdit.currentPackage = enrolDetails.get('currentPackage');
            } 
            if(enrolDetails.containsKey('currentDay')){
                enrolEdit.currentDayTimeSlot = enrolDetails.get('currentDay');
            }   
            if(enrolDetails.containsKey('currentPackageDuration')){
                enrolEdit.duration = Integer.valueOf(enrolDetails.get('currentPackageDuration'));
            }
            if(enrolDetails.containsKey('currentLessonDay')){
                enrolEdit.currentWeekDay = enrolDetails.get('currentLessonDay');
            }
             if(enrolDetails.containsKey('currentWeekDay')){
                enrolEdit.currentWeekDay = enrolDetails.get('currentWeekDay');
            }
            // @jatin:19-dec-2019: added instument for group class upgrade to regular user get packages list according to instruments
       
            if(enrolDetails.containsKey('instrument')){
                enrolEdit.currentInstrument = enrolDetails.get('instrument');
            }
           
            enrolEdit.currentTeacherId = enrolDetails.containsKey('currentTeacherId') ? enrolDetails.get('currentTeacherId') : '';
            enrolEdit.currentPackageId = enrolDetails.containsKey('currentPackageId') ? enrolDetails.get('currentPackageId') : '';
            
            if(enrolDetails.containsKey('currentCenter')){
                enrolEdit.center = enrolDetails.get('currentCenter');
                enrolEdit.teachers = new List<AureusCalendarController.Data>();
                List<AureusCalendarController.Data> multipleData = new List<AureusCalendarController.Data>();
                AureusCalendarController.Data data = new AureusCalendarController.Data();
                // @@jatin: 3-JAN-2020: for show different teacher according to grade condintion
                //GroupToIndividual = show all teachers according to current center
                //'GroupToSameClass' = show teacher accrording to group class teachers
                //GroupToHigherPackage = same as GroupToSameClass teachers
                List<Account> teachers = new List<Account>();
                if(grade.equalsIgnoreCase('GroupToIndividual')){
                    teachers = AureusCalendarControllerHelper.getListOfTeacher(enrolDetails.get('currentCenter'));
                }else if(grade.equalsIgnoreCase('GroupToSameClass') || grade.equalsIgnoreCase('GroupToHigherPackage')){
                    teachers = getListOfClassTeacher(enrolDetails.get('currentCenter'), enrolEdit.currentPackageId,grade);
                }
                //commented by jatin: for now w get all teachers 
                //List<Account> teachers = AureusCalendarControllerHelper.getListOfTeachersByInstrument(enrolDetails.get('currentCenter'),enrolDetails.get('instrument'));
                if(teachers != null && teachers.size() > 0){
                    for(Account teacher : teachers){
                        data = new AureusCalendarController.Data();
                        data.Id = teacher.Id;
                        data.name = teacher.Name;
                        multipleData.add(data); 
                    }    
                }
                if(multipleData.size() > 0){
                    enrolEdit.teachers = multipleData;
                }
            }       
        }
        return enrolEdit; 
    }
    
    // show teachers list according to selected Advance action button if click GroupToSameClass then show same package fee reocrds
    // and GroupToHigherPackage show higher package fee records
    private static List<Account> getListOfClassTeacher(string centerId,string packageId,string changeEnrolType){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        Set<String> teachersIdSet = new Set<String>();
         Map<Id,Account> mapOfGroupClassTeachers = New  Map<Id,Account>();
        if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        
        String query = '';             
        if(teachersIdSet.size() > 0){
            query = 'SELECT Id, Name,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus';
            query+= ' AND id IN : teachersIdSet';
            query+= ' ORDER BY Name';
        }
        if(String.isNotBlank(query) && String.isNotBlank(centerId) && String.isNotBlank(packageId)){
            Map<Id,Account> mapOfTeachers = New  Map<Id,Account>();
            set<string>instruments = new set<string>();
            map<string,set<string>> mapOfInstruments = new map<string,set<string>> ();
            for(account objTeacher : Database.query(query)){
                mapOfTeachers.put(objTeacher.id,objTeacher);
                instruments = new set<string>();
                if(mapOfInstruments.containsKey(objTeacher.id)){
                    instruments.addAll(mapOfInstruments.get(objTeacher.id));
                }
                if(objTeacher.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : objTeacher.Major_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    if(objTeacher.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : objTeacher.Minor_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }
                mapOfInstruments.put(objTeacher.id,instruments);     
            }
            // 7-jan:2020: show teacher according to active classes
            if(mapOfTeachers != null && mapOfTeachers.size() >0){
                Package__c objpackage = [SELECT id,Package_Fee__c 
                                        From Package__c
                                        WHERE Id=: packageId];
                string queryClass= 'Select Id,Teacher__c,Package__r.Program__r.Instrument__c From Class__c Where Available_Capacity__c > 0 ';
                If(string.isNotBlank(centerId)){
                    queryClass += ' And Centre_Name__c =:centerId ';
                }
                If(mapOfTeachers != null && mapOfTeachers.size() > 0){
                    set<Id> teacherIds = mapOfTeachers.keySet();
                    queryClass += ' AND Teacher__c In:teacherIds ';
                }
                If(string.isNotBlank(objpackage.Id) && objpackage.Package_Fee__c != null && objpackage.Package_Fee__c > 0 ){
                    decimal packageFee = objpackage.Package_Fee__c;
                    if(changeEnrolType.equalsIgnoreCase('GroupToSameClass') ){
                        queryClass += ' AND package__r.Package_Fee__c =: packageFee ';
                    }else if(changeEnrolType.equalsIgnoreCase('GroupToHigherPackage')){
                        queryClass += ' AND package__r.Package_Fee__c >: packageFee ';
                    }
                }
                List<CLass__c> listOfCLass = DataBase.Query(queryClass);
                if(listOfCLass != null && listOfCLass.size() > 0){
                    for(CLass__C objClass :listOfCLass){
                        if(mapOfTeachers.containsKey(objClass.Teacher__c) && mapOfInstruments.containsKey(objClass.Teacher__c)){
                            if(mapOfInstruments.get(objClass.Teacher__c).contains(objClass.Package__r.Program__r.Instrument__c)){
                                mapOfGroupClassTeachers.put(objClass.Teacher__c,mapOfTeachers.get(objClass.Teacher__c));
                            }
                        }
                    }
                }
            }
        }
        if(mapOfGroupClassTeachers != null && mapOfGroupClassTeachers.size() > 0){
            return mapOfGroupClassTeachers.values();
        }
        return new List<Account>();
    }
   //@@jatin-19-dec-2019: for get packages according to teacher or previous instrument
   @RemoteAction
    public static List<AureusCalendarController.Data> getPackageAccordingToTeacherOrInstrument(String centerId,Integer duration,
                                                                                                string instrument){
        List<AureusCalendarController.Data> packageList = new List<AureusCalendarController.Data>();
        AureusCalendarController.Data dt = new AureusCalendarController.Data();
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(instrument)&& String.isNotBlank(centerId)){        
            for(Package__c pkg : [SELECT Id, Name FROM Package__c
                                    WHERE Location__c =: centerId 
                                    AND Program__r.Status__c =: ConstantsClass.activeStatus  
                                    AND Program__r.Instrument__c =: instrument       
                                    AND Program__r.Billing__c != null 
                                    AND Program__r.Scheduling__c != null 
                                    AND Active__c = True
                                    AND (Type__c = 'Individual' OR Type__c = 'Home') AND 
                                    RecordtypeId =: pkgLessRecId 
                                    AND Duration__c >=: string.valueOf(duration)
                                    AND Type_of_package__c = 'Normal'
                                    ORDER BY Program__r.Name]){
                                        dt = new AureusCalendarController.Data();
                                        dt.Id = pkg.Id;
                                        dt.name = pkg.Name;
                                        packageList.add(dt);
                                    }    
            
        }
        
        return packageList;
    }

    // 3-Jan-2020: package accorging to teacher, center duration and upgrade condition  
    @RemoteAction
    public static List<AureusCalendarController.Data> getUpgradePackageAccordingToTeacher(String centerId, String teacherId, 
                                                                                          string bookingId,  string grade){
         List<AureusCalendarController.Data> packageList = new List<AureusCalendarController.Data>();
        AureusCalendarController.Data dt = new AureusCalendarController.Data();
        Set<String> instruments =  new Set<String>();    
        List<Booking__c> bookingList = new List<Booking__c>();   
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(teacherId)){
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                    FROM Account WHERE Id =:teacherId];
            if(tchrList.size() > 0){        
                for(Account acc: tchrList){        
                    if(acc.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    if(acc.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                }
            }
           //system.debug('instruments'+instruments);
            if(String.isNotBlank(bookingId)){
                bookingList = [SELECT Id, Name, Package__c,Type__c, Package__r.Name, Package__r.Active__c, enrolment__r.Package__c,
                                enrolment__r.Package__r.Package_Fee__c, enrolment__c,
                                enrolment__r.Package__r.Duration__c, enrolment__r.Lesson_Day__c, enrolment__r.Package__r.Type__c, 
                                enrolment__r.Package__r.Location__c, enrolment__r.Package__r.Program__r.Instrument__c
                                FROM Booking__c 
                                WHERE Id =: bookingId];
            }
            //system.debug('bookingId'+bookingList);
            if(instruments != null && instruments.size() > 0 && String.isNotBlank(centerId)){   
                List<Package__c> listOfPackage = new List<Package__c>();
                set<string> packageType =  new Set<String>();
                string query ='';
                 String activeStatus =  ConstantsClass.activeStatus;
                query  += 'SELECT Id, Name FROM Package__c ';  
                query  += ' WHERE  Program__r.Status__c =: activeStatus '; 
                query  += ' AND Program__r.Instrument__c IN: instruments ';       
                query  += ' AND Program__r.Billing__c != null ';
                query  += ' AND Program__r.Scheduling__c != null ';
                query  += ' AND Active__c = True ';
                query  += ' AND RecordtypeId =: pkgLessRecId ';
                query  += ' AND Type_of_package__c = \'Normal\'';
                query += ' AND Location__c =: centerId';
                if(grade.equalsIgnoreCase('GroupToIndividual') && bookingList != null && bookingList.size() > 0){
                   decimal packageFee = bookingList[0].enrolment__r.Package__r.Package_Fee__c;
                   packageType =  new Set<String>{'Individual','Home'};
                   query  += ' AND Type__c In: packageType ';
                   query  += ' AND Package_Fee__c > :packageFee ';
                   query  += ' ORDER BY Program__r.Name';
                  //system.debug('@@query'+Database.query(query));
                    listOfPackage = Database.query(query);
                }else if(grade.equalsIgnoreCase('GroupToSameClass') && bookingList != null && bookingList.size() > 0 ){
                   decimal packageFee = bookingList[0].enrolment__r.Package__r.Package_Fee__c;
                   packageType =  new Set<String>{ConstantsClass.packageTypeGroup};
                   query  += ' AND Type__c In: packageType ';
                   query  += ' AND Package_Fee__c = :packageFee ';
                   //system.debug('@@query'+Database.query(query));
                    query  += ' ORDER BY Program__r.Name';
                    listOfPackage = Database.query(query);
                }else if(grade.equalsIgnoreCase('GroupToHigherPackage') && bookingList != null && bookingList.size() > 0){
                    decimal packageFee = bookingList[0].enrolment__r.Package__r.Package_Fee__c;
                    packageType =  new Set<String>{ConstantsClass.packageTypeGroup};
                    query  += ' AND Type__c In: packageType ';
                    query  += ' AND Package_Fee__c > :packageFee ';
                    query  += ' ORDER BY Program__r.Name';
                   //system.debug('@@query'+Database.query(query));
                    listOfPackage = Database.query(query);
                    
                }
                // jatin:7-jan-2020 : show package according to active classes  
                if(grade.equalsIgnoreCase('GroupToHigherPackage') || grade.equalsIgnoreCase('GroupToSameClass') ){
                    map<id,Package__c> mapOfpackages = New map<id,Package__c>();
                    map<id,Package__c> mapOfGroupClassPackage = New map<id,Package__c>();
                    for(Package__c pkg :  listOfPackage){
                        mapOfpackages.put(pkg.id ,pkg);
                    }
                    for(CLass__C objClass : [Select Id,Package__c From Class__c 
                                                WHERE Active__c = true  
                                                AND Centre_Name__c =:centerId 
                                                AND Teacher__c =: teacherId
                                                AND Package__r.Program__r.Instrument__c IN: instruments 
                                                And Available_Capacity__c > 0]){
                            if(mapOfpackages.containsKey(objClass.Package__c)){
                                mapOfGroupClassPackage.put(objClass.Package__c,mapOfpackages.get(objClass.Package__c));
                            }
                        }  
                    for(Package__c pkg :  mapOfGroupClassPackage.values()){
                        dt = new AureusCalendarController.Data();
                        dt.Id = pkg.Id;
                        dt.name = pkg.Name;
                        packageList.add(dt);
                    }    
                }else{// is grade condition is group to regular than show all package records 
                    for(Package__c pkg :  listOfPackage){
                        dt = new AureusCalendarController.Data();
                        dt.Id = pkg.Id;
                        dt.name = pkg.Name;
                        packageList.add(dt);
                    }  
                }

            }
        }
        return packageList;
    }
   
    Private static Booking__c fetchSelectedBookingDetails(string bookingId){
        Booking__c bookingObjToReturn;
        for(Booking__c bookObj : [SELECT Id, Name, Center__r.Name, Teacher_Account__r.Name, Duration__c, Start_Time__c, 
                                    Booking_Date__c, Package__r.Name, Package__r.Duration__C,Class__r.Instrument__c,
                                    Class__r.Class_Type__c,Class__r.Maximum_age__c,Class__r.Minimum_age__c,
                                    Class__r.Class_Start_Date__c,
                                   Class__c,Package__r.Package_Fee__c, Class__r.Start_Time__c,Class__r.Total_Capacity__c,
                                   Class__r.Name, Class__r.Available_Capacity__c ,
                                   Class__r.Centre_Name__r.Organisation__r.Name,Class__r.grade__c,Class__r.Duration__c // added by nishi: 2-sep-2020 : for get class grade and organisation 
                                   FROM Booking__c WHERE Id =: bookingId LIMIT 1]){
            bookingObjToReturn = bookObj;
        }
        return bookingObjToReturn;
    }
	
    // jatin: 19-dec-2019: for create group lesson for give makeup mins.
@RemoteAction
    public static AureusCalendarController.ProcessResult  createGroupbooking(String bookingJson, String redirectCase, String caseId){
        AureusCalendarController.ProcessResult  objResult = new AureusCalendarController.ProcessResult();
        //String errorMsg = 'false';
        objResult.msg = 'false';
        Boolean isError = false;
        Map<String, Object> bookingMap = new Map<String, Object>();
        Booking__c bookingObj = new Booking__c();
        List<Booking__c> bookingList = new List<Booking__c>();
        DateTime bookingDateTime;
        String parentId;
        Date bookDate;
        if(String.isNotBlank(bookingJson)){
           //system.debug('@@bookingJson'+bookingJson);
            bookingMap = (Map<String, Object>)JSON.deserializeUntyped(bookingJson);
           //system.debug('@@bookingMap'+bookingMap);
           //system.debug('@@redirectCase'+redirectCase);
           //system.debug('@@caseId'+caseId);
            if(bookingMap.containsKey('date')){
                String bd = String.valueOf(bookingMap.get('date'));
                if(String.isNotBlank(bd)){                   
                    bookingDateTime = DateTime.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]), Integer.valueOf(bd.split('T')[1].split(':')[0]), Integer.valueOf(bd.split('T')[1].split(':')[1]), 0);
                    bookDate = Date.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]));
                }
               //system.debug('bookingDateTime'+bookDate);
                
            }
            if(bookingMap.containsKey('isRecurring')){
                if(String.valueOf(bookingMap.get('isRecurring')) == 'false'){
                    if(bookingMap.containsKey('centerId')){
                        bookingObj.Center__c = String.valueOf(bookingMap.get('centerId'));
                    }
                     if(bookingMap.containsKey('groupClassId')){
                        bookingObj.Group_Class__c = String.valueOf(bookingMap.get('groupClassId'));
                    }
                    if(bookingMap.containsKey('teacherId')){
                        bookingObj.Teacher_Account__c = String.valueOf(bookingMap.get('teacherId'));
                    }
                    if(bookingMap.containsKey('studentId')){
                        bookingObj.Student__c = String.valueOf(bookingMap.get('studentId'));
                    }
                    if(bookingMap.containsKey('packageId')){
                        bookingObj.Package__c = String.valueOf(bookingMap.get('packageId'));
                    }
                    //added by nishi: in ossia orgnisation case we added enrolment Id with makeup bookings
                    if(bookingMap.containsKey('enrolementId')){
                        bookingObj.enrolment__c = String.valueOf(bookingMap.get('enrolementId'));
                    }
                    //added by nishi: in ossia orgnisation case we added enrolment Id with makeup bookings
                    if(bookingMap.containsKey('type')){
                        if(String.valueOf(bookingMap.get('type')) == ConstantsClass.groupLessonTypeBooking){
                            bookingObj.Type__c = ConstantsClass.typeMakeup;
                        }
                    }
                    bookingObj.status__c = ConstantsClass.statusScheduled;
                    bookingObj.recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();

                    if(bookingMap.containsKey('date')){
                        String bookingDate = String.valueOf(bookingMap.get('date'));
                        if(String.isNotBlank(bookingDate)){
                            bookingObj.Booking_Date__c = Date.valueOf(bookingDate.split('T')[0]);
                            bookingObj.Start_Time__c = Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
                            if(bookingMap.containsKey('duration')){
                                bookingObj.End_Time__c =  Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]) + Integer.valueOf(bookingMap.get('duration')), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
                            }
                        }
                    }
                    Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:bookingObj.Student__c ];
                    parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                    //add ParentId in Booking parent
                    bookingObj.Parent__c = parentId;
                    
                    Boolean isChecked = AureusCalendarController.validateBookingTime(bookingObj.Teacher_Account__c,bookDate,bookingObj.End_Time__c);
                   //system.debug('@@@isChecked'+isChecked);
                   //system.debug('@@@bookingObj'+bookingObj);
                    Database.SaveResult saveResult;
                    if(isChecked){
                        saveResult = Database.insert(bookingObj, false);
                    }
                    if(isChecked == False && saveResult == null){//&& !saveResult.isSuccess()
                        isError = true;
                        objResult.msg = 'error';
                    }else{
                            if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                                bookingList.add(bookingObj);
                                AureusCalendarController.deductMakeupHours(bookingList, parentId);
                            }
                            
                            //create case Here
                            if((bookingObj.Type__c == ConstantsClass.typeMakeup) && redirectCase == 'true'){
                                Case objCase = AureusCalendarControllerHelper.createCase(caseId, bookingObj.Id, bookingObj.Type__c);
                                objResult.caseId = objCase.Id;
                            }
                            
                        }
                        
                    }
                }
            }
            //system.debug('@@objResult'+objResult);
             return objResult;
            
        }
    
    
    // @jatin: 13-dec-2019 : for show time slots according to selected class 
    @RemoteAction
    public static List<String> getGroupLessonTimeSlotsAccordingly(String effectiveDateStr,string newClassId){
        List<String> availTimeSlots = new List<String>();
        DateTime effectiveDate;
        if(String.isNotBlank(effectiveDateStr)){
            effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
        }
       //system.debug('@@newClassId'+newClassId);
        List<class__c> listofClass = [select id,Class_Start_Date__c ,Class_End_Date__c ,Class__c.Start_Time__c
                                    from Class__c
                                    where id=:newClassId];
       //system.debug('@@@listofClass'+listofClass);
        if(listofClass != null && listofClass.size() > 0 ){
            DateTime startTime = DateTime.newInstance(effectiveDate.date(),listofClass[0].Start_Time__c);
            availTimeSlots.add(startTime.format('h:mm a'));
        }system.debug('@@@availTimeSlots'+availTimeSlots);
        
        return availTimeSlots;
    }
    
    

    private static List<Booking__c> fetchAllBookingsForClass(String bookingId){
        String groupLessonBookingRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
        //Set<String> statusSet = new Set<String>{ConstantsClass.pendingStatus, ConstantsClass.scheduledStatus};
        Set<String> bookingTypeSet = new Set<String>{ConstantsClass.groupLessonTypeBooking, ConstantsClass.busyBookingType,ConstantsClass.typeMakeup,ConstantsClass.trialStatus};
        return [SELECT Id, Name, Student__r.Name, Parent__r.Name, Status__c ,Booking_Date__c,start_Time__c ,
                Class__r.Instrument__c,Class__r.Class_Type__c,Type__c
                FROM Booking__c WHERE RecordTypeId =:groupLessonBookingRecordType 
                AND Group_Class__c =: bookingId
                AND Status__c !=: ConstantsClass.statusCanceled
                AND Type__c In:bookingTypeSet /*AND Status__c IN: statusSet*/];
    }
    
     //@3-jan-2020:  Jatin : for get Teacher or package accorging to class days for update enrollment new Effective dates
    @RemoteAction 
    public static  Set<string> getNewEffectiveGroupDateSlots(String packageId, String teacherId){
        Set<string> weekdays = new Set<String>();
        for(class__c objclass : [SELECT id,Class_Day__c,Start_Time__c ,Class_Start_Date__c,End_Time__c
                                FROM Class__C
                                WHERE Teacher__c =:teacherId
                                AND Package__c =: packageId
                                AND Active__c = true]){
            weekdays.add(objclass.Class_Day__c);
        }
        return weekdays;
    }
    private static set<String> getFormatedTimeSlotList(DateTime startTime, DateTime endTime){
        set<String> timeSlots = new set<String>();
        if(startTime < endTime){
            while(startTime <= endTime){
                timeSlots.add(startTime.format('h:mm a'));
                startTime = startTime.addMinutes(15);
            }
        }
        return timeSlots;
    }

    @RemoteAction
    public static Boolean markCompleteOrNoShow(String bookingIds, String actionStr){
        Boolean isSucess = FALSE;
       //system.debug('@@@mapOfAppointments'+bookingIds);
        List<Booking__c> bookingList = new List<Booking__c>();
        String action = (actionStr == 'noShow') ? ConstantsClass.statusNoshow : ConstantsClass.statusCompleted;
        if(String.isNotBlank(bookingIds)){
        	for(String bookingId : bookingIds.split(';')){
                bookingList.add(new Booking__c(Id = bookingId, Status__c = action));
            }    
        }
         
        if(bookingList.size() > 0){
            update bookingList;     
            isSucess = TRUE;
        }
        return isSucess;
    }
   	    
    //Json For Edit Class Popup
    Public Class BookDetails{
        Booking__c bookObj;
        //List<AureusCalendarController.GroupPackage> groupPackages;
        List<BookingDetais> bookingList;
        public List<AureusCalendarController.BookingHistory> bookingHistoryList;
        Boolean isOssia;
        public BookDetails(Booking__c bookObj, /*List<AureusCalendarController.GroupPackage> groupPackages,*/ List<Booking__c> bookList,Boolean isOssiaOrg ){
            this.bookObj = bookObj;
            this.isOssia =isOssiaOrg;
           // this.groupPackages = groupPackages;
            bookingList = new List<BookingDetais>();
            bookingHistoryList = new List<AureusCalendarController.BookingHistory>();
            for(Booking__c objBooking : bookList){
                bookingList.add(new BookingDetais(objBooking.student__r.name,objBooking.Parent__r.name,objBooking.status__c,objBooking.name,
                                objBooking.id,
                                String.valueOf(objBooking.Booking_Date__c)+'T'+String.valueOf(objBooking.start_Time__c).split('\\.')[0],objBooking.type__c));
            }
            //this.bookList = bookList;
            
        }
    }


    // @jatin: 4-Jan-2019 : for show time slots according to  date ,teacher,center,
    @RemoteAction
    public static Set<String> getTimeSlotsGroupClassAccordingly(String centerId, String teacherId, String selectedPackage,String effectiveDateStr){
        List<String> availTimeSlots = new List<String>();
        DateTime effectiveDate;
        if(String.isNotBlank(effectiveDateStr)){
            effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
        }
        Set<Date> dt = new Set<Date>();
        dt.add(effectiveDate.date());
        List<Booking__c> bookingList = getGroupClassBookingsOnSelectedDates(centerId, teacherId,selectedPackage, dt);
        Set<String> bookingSlots = new Set<String>();
        if(bookingList.size() > 0){
            for(Booking__c currentBook : bookingList){
                dateTime startTime =DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c);
                bookingSlots.add(currentBook.Class__C +'-'+startTime.format('h:mm a'));
            }
        }
        return bookingSlots;
    }

   private static List<Booking__c> getGroupClassBookingsOnSelectedDates(String centerId, String teacherId,string selectedPackage, Set<Date> dates){
        String groupBookingRecordType = ConstantsClass.groupBookingRecordType;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.groupTypeBooking};
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};     
        Date dt, endDt;
        String busyType = ConstantsClass.typeBusy;
       
        String weekDay;
        String queryStr = 'SELECT Id, Name,Class__C, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c';
        queryStr += ' WHERE RecordType.Name =: groupBookingRecordType AND Start_Time__c != NULL AND End_Time__c != NULL AND Class__C != null';
        if(String.isNotBlank(centerId)){
            queryStr += ' AND Center__c =: centerId';
        }
        if(String.isNotBlank(teacherId)){
            queryStr += ' AND Teacher_Account__c =: teacherId';
        }
         if(String.isNotBlank(selectedPackage)){
            queryStr += ' AND Package__c =: selectedPackage';
        }
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
            queryStr += ' AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType AND Category__c NOT IN: busyStatusSet))';
            
        }

        //System.debug('@@@@queryStr'+queryStr);
        
        return Database.query(queryStr);
    }
    public class ClassDateTimeSlot{
        public set<string> weekDays;
        public Map<String,Set<String>> dateTimeSlots;
    }
    public class BookingDetais{
        string studentName;
        string parentName;
        string status;
        string bookingName;
        string bookingId;
        string start;
         string bookingType;
        public BookingDetais(string studentName,string parentName,string status,string bookingName,string  bookingId,string start,string bookingType){
            this.studentName = studentName;
            this.parentName = parentName;
            this.status =status;
            this.bookingName =bookingName;
            this.bookingId =bookingId;
            this.start =start;
            this.bookingType = bookingType;
        }
    }
}