public without sharing class UpdateEnrolmentProcessController implements IAdvanceAction{
    Private String enrolmentId;
    Private String teacherId;
    Private String packageId;
    Private Date currentEffectiveDate;
    Private Date effectiveDate;
    Private Boolean isDifferEffectiveDate;
    
    Private Time timeslot;
    Private String myCaseId;
    Private String caseRedirect;
    Private String previousTime;
    Private String oldPackageName;
    Private String newPackageName;
    Private date nextBillDate;
     //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    public UpdateEnrolmentProcessController(String enrolmentId, String teacherId, String packageId, 
                                         String currentEffectiveDateStr,String newEffectiveDateStr,  String timeStr, String myCaseId, 
                                         String caseRedirect, String previousTime, String oldPackageName, 
                                         String newPackageName) {
                                            this.enrolmentId =enrolmentId;
                                            this.teacherId = teacherId;
                                            this.packageId =packageId;
                                            this.currentEffectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(currentEffectiveDateStr);
                                            this.effectiveDate =  AdvanceActionsHelper.convertToDateForUpgrade(newEffectiveDateStr);
                                            this.isDifferEffectiveDate = (currentEffectiveDateStr.equals(newEffectiveDateStr) ? false : true);
                                            timeslot = AdvanceActionsHelper.getDateTimeFromString(timeStr).time();
                                            this.myCaseId =myCaseId;
                                            this.caseRedirect =caseRedirect;
                                            this.previousTime =previousTime;
                                            this.oldPackageName =oldPackageName;
                                            this.newPackageName =newPackageName;
                                            enrolmentObj = new Enrolment__c();
    }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        Boolean error = true;
        Boolean dayChange = false;
        Boolean teacherPackageChange = false;
        string invoiceId;
        string caseReturn;
        string oldTeacher;
        string oldPackage;
        Time oldTimeSlot;
        Integer duration=0;

        //Added by Jatin on 4th December 2019
        Boolean isWeekdayChange = FALSE;

        

        if(String.isNotBlank(enrolmentId)){
            
            enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentId);
            
            system.debug('@@@enrolmentObj'+enrolmentObj);
            nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
            oldTeacher = enrolmentObj.Teacher__c;
            oldPackage = enrolmentObj.Package__c;
            oldTimeSlot = enrolmentObj.Lesson_Start_time__c;
            if(enrolmentObj.Package__r != null && enrolmentObj.Package__r.Duration__c != null ){
             duration = Integer.valueOf(enrolmentObj.Package__r.Duration__c);
            }
            if(teacherId != enrolmentObj.Teacher__c || packageId != enrolmentObj.Package__c){
                teacherPackageChange =  true;                                      
            }
            
        }
        system.debug('###effectiveDate'+effectiveDate);
        system.debug('###nextBillDate'+nextBillDate);
         system.debug('###timeslot'+timeslot);
         /*
        * commented by arpit as we are not allowing for day change
        * if(effectiveDate.format('EEEE') != lessonDay){
        dayChange = true; 
        }*/
         enrolmentObj.Effective_Date__c = effectiveDate;
        Boolean isSameMonth = nextBillDate > effectiveDate ? true : false;
        enrolmentObj.Package_Process_Status__c = isSameMonth ? ConstantsClass.enrollmentProcessCompletedStatus :  ConstantsClass.enrollmentProcessPendingStatus;             
        if(String.isNotBlank(teacherId)){
            if(isSameMonth){
                enrolmentObj.Teacher__c = teacherId;
            }
            enrolmentObj.New_Teacher__c = teacherId;
        }
        if(String.isNotBlank(packageId)){
            if(isSameMonth){
                enrolmentObj.Package__c = packageId;
            }
            enrolmentObj.new_package_Id__c = packageId;
        }
        
        if(timeslot != null){
            if(isSameMonth){
                enrolmentObj.Lesson_Start_time__c = timeslot;
            }
            enrolmentObj.Next_Lesson_Start_time__c = timeslot;
        }
        enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
        enrolmentObj.Package_Process_Request_Date__c = System.today();
        enrolmentObj.Advance_Action_Requested_By__c = UserInfo.getUserId();
        
        DateTime currectEffectiveDateTime;
        DateTime newEffectiveDateTime;
        
        if(currentEffectiveDate != NULL && effectiveDate != NULL){
            currectEffectiveDateTime = DateTime.newInstance(currentEffectiveDate, Time.newInstance(0, 0, 0, 0));
            newEffectiveDateTime = DateTime.newInstance(effectiveDate, Time.newInstance(0, 0, 0, 0));
            if(currectEffectiveDateTime.format('EEE') != newEffectiveDateTime.format('EEE')){
                isWeekdayChange = TRUE;
            }
        }

        if(isWeekdayChange && newEffectiveDateTime != NULL){
            
            enrolmentObj.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
        
            if(isSameMonth){
                enrolmentObj.Lesson_Day__c = newEffectiveDateTime.format('EEEE');
            }
        }
                                              /*
* commented by arpit on 17july as we are not allowing day change
*  if(dayChange){
enrol.New_Lesson_Day__c = effectiveDate.format('EEEE');
enrol.Lesson_Day__c = effectiveDate.format('EEEE');
}
*/
        system.debug('@@enrolmentObj.Id'+enrolmentObj.Id);                                     
        if(String.isNotBlank(enrolmentObj.Id)){
            //Set<String> setOfMakeupBookings = new Set<String>();
            //List<Booking__c> listOfMakeupBoookings = new List<Booking__c>();
             Database.SaveResult saveResult = Database.update(enrolmentObj, false);
            if(saveResult.isSuccess()){
                  system.debug('@@updated enrolmentObj -- '+enrolmentObj);   
                Boolean isEffectiveDateAndTimeChange = true;
                system.debug('@@isDifferEffectiveDate'+isDifferEffectiveDate);
               system.debug('@@currentEffectiveDate'+currentEffectiveDate);
             system.debug('@@effectiveDate'+effectiveDate);
                if(!isDifferEffectiveDate){
                     system.debug('@@oldTimeSlot'+oldTimeSlot);
                     system.debug('@@timeslot'+timeslot);
                    string currentEffectiveTimeSlot =DateTime.newInstance(currentEffectiveDate, oldTimeSlot).format('EEE @ h:mm a');
                    string newEffectiveTimeSlot =DateTime.newInstance(effectiveDate, timeslot).format('EEE @ h:mm a');
                 system.debug('@@@currentEffectiveTimeSlot'+currentEffectiveTimeSlot);
                    system.debug('@@@newEffectiveTimeSlot'+newEffectiveTimeSlot);
                   system.debug('@@@oldTimeSlot'+oldTimeSlot);
                   system.debug('@@@timeslot'+newEffectiveTimeSlot);
                    isEffectiveDateAndTimeChange = (currentEffectiveTimeSlot.equals(newEffectiveTimeSlot) ? false : true);
                }
                system.debug('@@isEffectiveDateAndTimeChange'+isEffectiveDateAndTimeChange);
                 RescheduleAllBookings allReschedule = new RescheduleAllBookings(isEffectiveDateAndTimeChange, enrolmentObj, effectiveDate, currentEffectiveDate);
                System.debug('@@@allReschedule --'+allReschedule);
                /* commented by jatin 14-Nov-2014 : for change enrollment new requirement 
                AureusCalendarControllerHelper.processFutureBookings(enrolmentObj, 'change');
                setOfMakeupBookings = AdvanceActionsHelper.processFutureFifthLessons(enrolmentObj, 'change');
                if(setOfMakeupBookings.size() > 0){
                    for(Booking__c bookingObj : AdvanceActionsHelper.fetchAllBooking(setOfMakeupBookings)){
                        bookingObj.start_Time__c = timeslot;
                        bookingObj.end_Time__c = bookingObj.start_Time__c.addMinutes(duration);
                        bookingObj.Teacher_Account__c = teacherId;
                        listOfMakeupBoookings.add(bookingObj);
                    }
                }*/
                /*if(String.isNotBLank(studentId) && String.isNotBlank(oldTeacher) && duration > 0 && startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay)){
                    for(Booking__c bookingObj : AureusCalendarControllerHelper.processMakeupBooking(studentId, oldTeacher, Duration, startTime, effectiveDate, lessonDay)){
                        bookingObj.start_Time__c = getDateTimeFromString(timeStr).time();
                        bookingObj.end_Time__c = bookingObj.start_Time__c.addMinutes(duration);
                        bookingObj.Teacher_Account__c = teacherId;
                        listOfMakeupBoookings.add(bookingObj);
                    }
                }*/
            
                /*@Arpit 17july19 Requiremt for makeup booking that's why we change this*/
                /*if(listOfMakeupBoookings.size() > 0){
                    update listOfMakeupBoookings;
                }*/
            }
            
            if(saveResult.isSuccess() && isSameMonth && teacherPackageChange){
                invoiceId =  createInvoiceAndLineItemsChangeEnrol(enrolmentObj, effectiveDate, nextBillDate, oldTeacher,oldPackage,teacherId,packageId);
            }
            
            error = false;
        }
        system.debug('@@invoiceId'+invoiceId);
        if(caseRedirect == 'true' && error == false && enrolmentObj != NULL){
            caseReturn =    updateCase(myCaseId,enrolmentObj.id,oldPackageName,newPackageName,teacherId, oldTeacher,effectiveDate, timeslot,previousTime, invoiceId);
        }else if(error == false){
            caseReturn = '';
        }else{
            caseReturn = 'error';
        }
       system.debug('@@@caseId'+caseReturn);                                    
        return caseReturn;
    }
    
    private static String getPackageInvoiceAmount(Enrolment__c objEnrol,Map<Id,Package__c> mapOfPackages,map<id,String> packageInvoiceAmount,string packageId){
        decimal totalAmount = 0;
        decimal gstAmount = 0;
        system.debug('@@@packageId --'+ packageId);
        if(packageInvoiceAmount.containsKey(packageId)){
            totalAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[0]);
        }
        system.debug('@@unit fee '+ mapOfPackages.get(packageId).Unit_Fee__c);
        totalAmount += mapOfPackages.get(packageId).Unit_Fee__c;
        if(String.isNotBlank(objEnrol.Id) &&  String.isNotBlank(objEnrol.Center__c)
        && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0
        && mapOfPackages.get(packageId).Unit_Fee__c  > 0 ){
            if(packageInvoiceAmount.containsKey(packageId)){
                gstAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[1]);
            }
            system.debug('@@@Gst Amount= '+ (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100);
            system.debug('@@@Tax_Rate__c = '+ (objEnrol.Center__r.Country__r.Tax_Rate__c)/100);
            gstAmount += (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
        }
        return totalAmount+';'+gstAmount;
    }
    private static String createInvoiceAndLineItemsChangeEnrol(Enrolment__c objEnrol, Date effectiveDate, Date nextBillingDate, 
                                                               String oldTeacher,String oldPackage,String newTeacher,String newPackage){
        Invoice__c objectOfInvoice = new Invoice__c();
        decimal totalAmount = 0;
        decimal gstAmount = 0;
        String regularType = ConstantsClass.typeRegular;
        String canceledStatus = ConstantsClass.statusCanceled; 
        List<Invoice_Line_Item__c> invoiceLineItem = new List<Invoice_Line_Item__c>();
        String subLineItemId ;
        Integer noOfOldLesson,noOfNewLesson;
        system.debug('@@createInvoiceAndLineItemsChangeEnrol objEnrol'+objEnrol);
        system.debug('@@createInvoiceAndLineItemsChangeEnrol effectiveDate'+effectiveDate);
    system.debug('@@createInvoiceAndLineItemsChangeEnrol nextBillingDate'+nextBillingDate);
        system.debug('@@createInvoiceAndLineItemsChangeEnrol oldTeacher'+oldTeacher);
        system.debug('@@createInvoiceAndLineItemsChangeEnrol oldPackage'+oldPackage);
        system.debug('@@createInvoiceAndLineItemsChangeEnrol newTeacher'+newTeacher);
       system.debug('@@createInvoiceAndLineItemsChangeEnrol newPackage'+newPackage);
        Set<String> packageIds = new Set<string>();
        packageIds.add(oldPackage);
        packageIds.add(newPackage);
        Map<id,Package__c> mapOfPackage = new Map<Id,package__c>([Select Id,Unit_Fee__c from Package__c where Id In:packageIds]);
        List<Booking__c> bookingList = [SELECT Id, Package__c, center__c, Teacher_Account__c, Package__r.Unit_Fee__c, Student__c, Student__r.Parent__c FROM Booking__c WHERE 
                                        Enrolment__c =: objEnrol.id AND Booking_Date__c >= :effectiveDate AND 
                                        Booking_Date__c < :nextBillingDate AND Type__c =: regularType AND 
                                        Status__c !=: canceledStatus ORDER BY Booking_Date__c ];
        system.debug('@@@ get bookingList'+bookingList);
        if(objEnrol != NULL && objEnrol.subscription_line_items__r != null && objEnrol.subscription_line_items__r.size() > 0 ){
            subLineItemId = objEnrol.subscription_line_items__r[0].id;
        }
        if(bookingList.size() > 0){
            String parentId = String.isNotBlank(bookingList[0].Student__r.Parent__c) ? bookingList[0].Student__r.Parent__c : bookingList[0].Student__c;
           system.debug('@@@@@bookingList.size()--'+bookingList.size());
            /*for(Booking__c booking : bookingList){
                if(string.isNotBlank(booking.Package__c))
                    totalAmount += booking.Package__r.Unit_Fee__c;
                if(String.isNotBlank(objEnrol.Id) && string.isNotBlank(booking.Package__c) && String.isNotBlank(objEnrol.Center__c)
                 && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0 && booking.Package__r.Unit_Fee__c  > 0 ){
                    gstAmount += (booking.Package__r.Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
                }
                
            }*/
            map<id,String> packageInvoiceAmount = new Map<Id,String>();
            Map<Id,Package__c> mapOfPackages =New Map<Id,Package__c>([Select Id,Unit_Fee__c from Package__c where Id In:packageIds]);
            system.debug('@@@@@mapOfPackages'+mapOfPackages);
            // 6 Dec 2019: jatin for manage packages fee  old package and new package unit fee
            for(Booking__c booking : bookingList){
                if(string.isNotBlank(booking.Package__c)){
                    if(mapOfPackages.containsKey(newPackage)){
                        packageInvoiceAmount.put(newPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,newPackage));    
                    }if(mapOfPackages.containsKey(oldPackage)){
                       packageInvoiceAmount.put(oldPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,oldPackage)); 
                    } 
                }
            }
            decimal newPackageTotalAmount = 0;
            decimal oldPackageTotalAmount = 0;
             if(packageInvoiceAmount.containsKey(newPackage)){
                 newPackageTotalAmount += decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[0]);
             }
             if(packageInvoiceAmount.containsKey(oldPackage)){
                 oldPackageTotalAmount += decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[0]);
             }
            system.debug('@@@@@packageInvoiceAmount'+packageInvoiceAmount);
            system.debug('@@parentId'+parentId);
            if(oldPackageTotalAmount > 0 && newPackageTotalAmount > 0 && String.isNotBlank(parentId)){
                objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                Invoice_Date__c =system.today(), Parent_Account__c = parentId, Center__c=bookingList[0].center__c);
                INSERT objectOfInvoice;
                system.debug('@@@ created objectOfInvoice'+objectOfInvoice);
                if(objectOfInvoice != NULL){
                    if(packageInvoiceAmount.containsKey(newPackage)){
                        newPackageTotalAmount = decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[0]);
                        gstAmount = decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[1]);
                    
                        if(newPackageTotalAmount != 0){
                            newPackageTotalAmount = BillingUtility.roundOffAmount(newPackageTotalAmount);
                        }
                        if(gstAmount != 0){
                            gstAmount = BillingUtility.roundOffAmount(gstAmount);
                        }
                        system.debug('@@@totalAmount'+totalAmount);
                        system.debug('@@@gstAmount'+gstAmount);
                        invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                                                                    Amount__c = newPackageTotalAmount, 
                                                                    Teacher_Id__c = newTeacher, Month__c= effectiveDate, Enrolment__c =objEnrol.id, 
                                                                    Subscription_line_item__c = subLineItemId,Package__c= newPackage ,
                                                                    GST_Amount__c = gstAmount));
                    }
                     if(packageInvoiceAmount.containsKey(oldPackage)){
                        oldPackageTotalAmount = decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[0]);
                        gstAmount = decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[1]);
                        if(oldPackageTotalAmount != 0){
                            oldPackageTotalAmount = BillingUtility.roundOffAmount(oldPackageTotalAmount);
                        }
                        if(gstAmount != 0){
                            gstAmount = BillingUtility.roundOffAmount(gstAmount);
                        }
                        oldPackageTotalAmount = -oldPackageTotalAmount;
                        if(gstAmount > 0){
                            gstAmount = -gstAmount;
                        }
                         system.debug('@@@totalAmount'+totalAmount);
                       system.debug('@@@gstAmount'+gstAmount);
                        invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = oldPackageTotalAmount, 
                                                                Teacher_Id__c = oldTeacher,Month__c= effectiveDate,
                                                                Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                Package__c = oldPackage,  GST_Amount__c = gstAmount));
                    }
                }
                
                if(invoiceLineItem.size() > 0){
                    INSERT invoiceLineItem;
                }
                system.debug('@@ create new invoiceLineItem'+invoiceLineItem);
                if(String.isNotBlank(objectOfInvoice.id)){
                    SageIntacctIntegrationUtility.changeEnrolment(objectOfInvoice.Id);
                }
                if(objectOfInvoice != NULL){
                    
                    BillingUtility.createAttachment(new Set<String>{objectOfInvoice.id});
                }
                
            }
        }
        system.debug('@@objectOfInvoice.Id'+objectOfInvoice.Id);
        return objectOfInvoice.Id;
    }
    
    Private Static String updateCase(String myCaseId,String enrolmentId,String oldPackageName,string newPackageName,string teacherId,String oldTeacher,
                                    date effectiveDate,time timeslot,string previousTime,string invoiceId){
        system.debug('@@@updateCase myCaseId'+myCaseId);
        system.debug('@@@updateCase enrolmentId'+enrolmentId);
        system.debug('@@@updateCase oldPackageName'+oldPackageName);
        system.debug('@@@updateCase newPackageName'+newPackageName);
        system.debug('@@@updateCase teacherId'+teacherId);
       system.debug('@@@updateCase oldTeacher'+oldTeacher);
    system.debug('@@@updateCase effectiveDate'+effectiveDate);
        system.debug('@@@updateCase timeslot'+timeslot);
       system.debug('@@@updateCase previousTime'+previousTime);
        system.debug('@@@updateCase invoiceId'+invoiceId);
        Case caseObj = AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrolmentId, 'change', false);
            if(String.isNotBlank(oldPackageName)){
                caseObj.Previous_Package__c = oldPackageName; 
            }
            if(String.isNotBlank(newPackageName)){
                caseObj.New_Package__c = newPackageName; 
            }
            caseObj.New_Teacher__c =  teacherId;   
            caseObj.Previous_teacher__c = oldTeacher; 
            if(effectiveDate != null){
                DateTime newformatTime = DateTime.newInstance(effectiveDate, timeslot);
                caseObj.New_Lesson_Day_Time__c = newformatTime.format('EEE @ h:mm a');
            }
            
            caseObj.Previous_Lesson_Day_Time__c = previousTime;
            caseObj.Invoice__c = invoiceId;     
            upsert caseObj; 
            System.debug('@@caseObj'+caseObj);
            return  caseObj.id;
    }
  /* Private static Boolean updatedEnrollement(boolean isSameMonth,Enrolment__c enrol, time timeslot, string teacherId, Integer duration,date effectiveDate,boolean isDayChange, date currentEffectiveDate,string packageId, boolean Error){
        enrol = AdvanceActionsHelper.getUpdatedEnrollmentFields(enrol.id,ConstantsClass.enrollmentProcessChanged,
                                                                           null,effectiveDate,packageId,timeslot);
        //Set<String> setOfMakeupBookings = new Set<String>();
        system.debug('@@@enrol'+enrol);
        //List<Booking__c> listOfMakeupBoookings = new List<Booking__c>();
        if(String.isNotBlank(teacherId)){
            if(isSameMonth){
                enrol.Teacher__c = teacherId;
            }
            enrol.New_Teacher__c = teacherId;
        }
        Database.SaveResult saveResult = Database.update(enrol, false);
        if(saveResult.isSuccess()){
            system.debug('@@@enrol'+enrol);
            system.debug('@@@effectiveDate'+effectiveDate);
            enrol = AdvanceActionsHelper.fetchEnrolment(enrol.id);
            RescheduleAllBookings allReschedule = new RescheduleAllBookings(isDayChange, enrol, effectiveDate, currentEffectiveDate);
            /*AureusCalendarControllerHelper.processFutureBookings(enrol, 'change');
            setOfMakeupBookings = AdvanceActionsHelper.processFutureFifthLessons(enrol, 'change');
            if(setOfMakeupBookings.size() > 0){
                for(Booking__c bookingObj : AdvanceActionsHelper.fetchAllBooking(setOfMakeupBookings)){
                    bookingObj.start_Time__c = timeslot;
                    bookingObj.end_Time__c = bookingObj.start_Time__c.addMinutes(duration);
                    bookingObj.Teacher_Account__c = teacherId;
                    listOfMakeupBoookings.add(bookingObj);
                }
            }
            /*if(String.isNotBLank(studentId) && String.isNotBlank(oldTeacher) && duration > 0 && startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay)){
                for(Booking__c bookingObj : AureusCalendarControllerHelper.processMakeupBooking(studentId, oldTeacher, Duration, startTime, effectiveDate, lessonDay)){
                    bookingObj.start_Time__c = getDateTimeFromString(timeStr).time();
                    bookingObj.end_Time__c = bookingObj.start_Time__c.addMinutes(duration);
                    bookingObj.Teacher_Account__c = teacherId;
                    listOfMakeupBoookings.add(bookingObj);
                }
            }*/
        
            /*@Arpit 17july19 Requiremt for makeup booking that's why we change this
            if(listOfMakeupBoookings.size() > 0){
                update listOfMakeupBoookings;
            }
            //system.debug('@@listOfMakeupBoookings'+listOfMakeupBoookings);
        }else{
            for(Database.Error err : saveResult.getErrors()) {
                System.debug('##The following error has occurred.');                    
                System.debug('###'+err.getStatusCode() + ': ' + err.getMessage());
                System.debug('###Account fields that affected this error: ' + err.getFields());
            }
        }
        return saveResult.isSuccess();
    }*/
  
}