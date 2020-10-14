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
        Savepoint updateSavePoint;
        
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
            try{
                updateSavePoint = Database.setSavepoint();

            if(String.isNotBlank(enrolmentId)){
                
                enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentId);
                
            //system.debug('@@@enrolmentObj'+enrolmentObj);
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
        //system.debug('###effectiveDate'+effectiveDate);
        //system.debug('###nextBillDate'+nextBillDate);
            //system.debug('###timeslot'+timeslot);
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
        //system.debug('@@enrolmentObj.Id'+enrolmentObj.Id);                                     
            if(String.isNotBlank(enrolmentObj.Id)){
                //Set<String> setOfMakeupBookings = new Set<String>();
                //List<Booking__c> listOfMakeupBoookings = new List<Booking__c>();
                Database.SaveResult saveResult = Database.update(enrolmentObj, false);
                if(saveResult.isSuccess()){
                    //system.debug('@@updated enrolmentObj -- '+enrolmentObj);   
                    Boolean isEffectiveDateAndTimeChange = true;
                //system.debug('@@isDifferEffectiveDate'+isDifferEffectiveDate);
                //system.debug('@@currentEffectiveDate'+currentEffectiveDate);
                //system.debug('@@effectiveDate'+effectiveDate);
                    if(!isDifferEffectiveDate){
                        //system.debug('@@oldTimeSlot'+oldTimeSlot);
                        //system.debug('@@timeslot'+timeslot);
                        string currentEffectiveTimeSlot =DateTime.newInstance(currentEffectiveDate, oldTimeSlot).format('EEE @ h:mm a');
                        string newEffectiveTimeSlot =DateTime.newInstance(effectiveDate, timeslot).format('EEE @ h:mm a');
                    //system.debug('@@@currentEffectiveTimeSlot'+currentEffectiveTimeSlot);
                    //system.debug('@@@newEffectiveTimeSlot'+newEffectiveTimeSlot);
                    //system.debug('@@@oldTimeSlot'+oldTimeSlot);
                    //system.debug('@@@timeslot'+newEffectiveTimeSlot);
                        isEffectiveDateAndTimeChange = (currentEffectiveTimeSlot.equals(newEffectiveTimeSlot) ? false : true);
                    }
                //system.debug('@@isEffectiveDateAndTimeChange'+isEffectiveDateAndTimeChange);
                    RescheduleAllBookings allReschedule = new RescheduleAllBookings(isEffectiveDateAndTimeChange, enrolmentObj, effectiveDate, currentEffectiveDate);
                //system.debug('@@@allReschedule --'+allReschedule);
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
        //system.debug('@@invoiceId'+invoiceId);
            if(caseRedirect == 'true' && error == false && enrolmentObj != NULL){
                caseReturn =    updateCase(myCaseId,enrolmentObj.id,oldPackageName,newPackageName,teacherId, oldTeacher,effectiveDate, timeslot,previousTime, invoiceId);
            }else if(error == false){
                caseReturn = '';
            }else{
                caseReturn = 'error';
            }
        }catch (Exception e){
            //On 14-Oct-2020: Nishi to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(updateSavePoint);
            caseReturn  += e.getStackTraceString()+'-'+e.getMessage() +';';
            System.debug('@@caseIdToReturn'+caseReturn);
        }
      //system.debug('@@@caseId'+caseReturn);                                    
        return caseReturn;
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
        /*//start:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
        if(String.isNotBlank(objEnrol.Id) &&  String.isNotBlank(objEnrol.Center__c)
        && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0
        && mapOfPackages.get(packageId).Unit_Fee__c  > 0 ){
            if(packageInvoiceAmount.containsKey(packageId)){
                gstAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[1]);
            }
           //system.debug('@@@Gst Amount= '+ (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100);
           //system.debug('@@@Tax_Rate__c = '+ (objEnrol.Center__r.Country__r.Tax_Rate__c)/100);
            gstAmount += (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
        }//end:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
        if(String.isNotBlank(objEnrol.Id) &&  String.isNotBlank(objEnrol.Center__c)
        && String.isNotBlank(objEnrol.Center__r.Organisation__c) && objEnrol.Center__r.Organisation__r.Tax_Rate__c > 0
        && mapOfPackages.get(packageId).Unit_Fee__c  > 0 ){
            if(packageInvoiceAmount.containsKey(packageId)){
                gstAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[1]);
            }
            gstAmount += (mapOfPackages.get(packageId).Unit_Fee__c * objEnrol.Center__r.Organisation__r.Tax_Rate__c)/100;
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
          // added by nishi: 6-oct-2020: for create credit memo records
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
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
        List<Booking__c> bookingList = [SELECT Id, Package__c, center__c, Teacher_Account__c, Package__r.Unit_Fee__c, Student__c, Student__r.Parent__c,Booking_date__c FROM Booking__c WHERE 
                                        Enrolment__c =: objEnrol.id AND Booking_Date__c >= :effectiveDate AND 
                                        Booking_Date__c < :nextBillingDate AND Type__c =: regularType AND 
                                        Status__c !=: canceledStatus ORDER BY Booking_Date__c ];
       
      //system.debug('@@@ get bookingList'+bookingList);
        if(objEnrol != NULL && objEnrol.subscription_line_items__r != null && objEnrol.subscription_line_items__r.size() > 0 ){
            subLineItemId = objEnrol.subscription_line_items__r[0].id;
        }
        if(bookingList.size() > 0){
            String parentId = String.isNotBlank(bookingList[0].Student__r.Parent__c) ? bookingList[0].Student__r.Parent__c : bookingList[0].Student__c;
          //system.debug('@@@@@bookingList.size()--'+bookingList.size());
            /*for(Booking__c booking : bookingList){
                if(string.isNotBlank(booking.Package__c))
                    totalAmount += booking.Package__r.Unit_Fee__c;
                if(String.isNotBlank(objEnrol.Id) && string.isNotBlank(booking.Package__c) && String.isNotBlank(objEnrol.Center__c)
                 && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0 && booking.Package__r.Unit_Fee__c  > 0 ){
                    gstAmount += (booking.Package__r.Unit_Fee__c * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
                }
                
            }*/
            map<id,String> packageInvoiceAmount = new Map<Id,String>();
            map<id,String> packageInvoiceNextMonthAmount = new Map<Id,String>();
            Map<Id,Package__c> mapOfPackages =New Map<Id,Package__c>([Select Id,Unit_Fee__c from Package__c where Id In:packageIds]);
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
            }
             //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
           //system.debug('@@@@@mapOfPackages'+mapOfPackages);
            // 6 Dec 2019: jatin for manage packages fee  old package and new package unit fee
            for(Booking__c booking : bookingList){
               //system.debug('@@@@@booking.Booking_date__c'+booking.Booking_date__c);
                // added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
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
                //end: added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
                   //system.debug('@@@@ Current Month'+booking.Booking_date__c);
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
             // added by nishi: 21-sep-2020: for if next month invoice already generated then we add  invoice line item amount
             if(packageInvoiceNextMonthAmount.containsKey(newPackage)){
                newPackageNextMonthTotalAmount += decimal.valueOf(packageInvoiceNextMonthAmount.get(newPackage).split(';')[0]);
            }
            if(packageInvoiceNextMonthAmount.containsKey(oldPackage)){
                oldPackageNextMonthTotalAmount += decimal.valueOf(packageInvoiceNextMonthAmount.get(oldPackage).split(';')[0]);
            }
            // added by nishi: 21-sep-2020: for if next month invoice already generated then  we add  invoice line item amount
            
           system.debug('@@@@@newPackageTotalAmount'+newPackageTotalAmount);
           system.debug('@@@@@oldPackageTotalAmount'+oldPackageTotalAmount);
           system.debug('@@@@@newPackageNextMonthTotalAmount'+newPackageNextMonthTotalAmount);
           system.debug('@@@@@oldPackageNextMonthTotalAmount'+oldPackageNextMonthTotalAmount);
           system.debug('@@@@@packageInvoiceAmount'+packageInvoiceAmount);
           //system.debug('@@parentId'+parentId);
           //nishi: 18-Sep-2020: No invoice when no change in teacher and package
           if(oldPackage != newPackage || oldTeacher != newTeacher){
                if(oldPackageTotalAmount > 0 && newPackageTotalAmount > 0 && String.isNotBlank(parentId)){
                    objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                    Invoice_Date__c =system.today(), Parent_Account__c = parentId, Center__c=bookingList[0].center__c);
                                                    objectOfInvoice.Credit_Memo_Amount__c  =0;
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
                        system.debug('@@createInvoiceAndLineItemsChangeEnrol objCreditMemo'+objCreditMemo);
                        newPendingCreditMemos.put('Update Enrolment invoice Adjustment',objCreditMemo);
                        listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
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
                            
                                /*Commented by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                                oldPackageTotalAmount = -oldPackageTotalAmount;
                                if(gstAmount > 0){
                                    gstAmount = -gstAmount;
                                }
                                //system.debug('@@@totalAmount'+totalAmount);
                            //system.debug('@@@gstAmount'+gstAmount);
                                /*
                                invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = oldPackageTotalAmount, 
                                                                        Teacher_Id__c = oldTeacher,Month__c= effectiveDate,
                                                                        Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                        Package__c = oldPackage,  GST_Amount__c = gstAmount));*/
                                //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
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
                                system.debug('@@createInvoiceAndLineItemsChangeEnrol objCreditLineItem'+objCreditLineItem);           
                                //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                            }                 
                        }
                         // start:added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
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
                            /*
                            invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = oldPackageNextMonthTotalAmount, 
                                                                        Teacher_Id__c = oldTeacher,Month__c= nextMonthDate.addMonths(-1),
                                                                        Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                        Package__c = oldPackage,  GST_Amount__c = gstAmount));*/
                                //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
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
                                objectOfInvoice.Credit_Memo_Amount__c +=  (Math.abs(oldPackageNextMonthTotalAmount)+gstAmount);        
                                system.debug('@@createInvoiceAndLineItemsChangeEnrol objCreditLineItem'+objCreditLineItem);                                           
                                mapOfCreditmemolineitem.put('Update Enrolment invoice Adjustment',listOfCreditmemolineitem);                                           
                            }
                            //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
                            // end:added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
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
                        system.debug('mapOfCreditmemolineitem'+mapOfCreditmemolineitem);
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
               //system.debug('@@ create new invoiceLineItem'+invoiceLineItem);
                    if(String.isNotBlank(objectOfInvoice.id)){
                        SageIntacctIntegrationUtility.changeEnrolment(objectOfInvoice.Id);
                    }
                    if(objectOfInvoice != NULL){
                        
                        BillingUtility.createAttachment(new Set<String>{objectOfInvoice.id});
                    }
                    
                }
            }
        }
       //system.debug('@@objectOfInvoice.Id'+objectOfInvoice.Id);
        return objectOfInvoice.Id;
    }
    
    Private Static String updateCase(String myCaseId,String enrolmentId,String oldPackageName,string newPackageName,string teacherId,String oldTeacher,
                                    date effectiveDate,time timeslot,string previousTime,string invoiceId){
       //system.debug('@@@updateCase myCaseId'+myCaseId);
       //system.debug('@@@updateCase enrolmentId'+enrolmentId);
       //system.debug('@@@updateCase oldPackageName'+oldPackageName);
       //system.debug('@@@updateCase newPackageName'+newPackageName);
       //system.debug('@@@updateCase teacherId'+teacherId);
      //system.debug('@@@updateCase oldTeacher'+oldTeacher);
   //system.debug('@@@updateCase effectiveDate'+effectiveDate);
       //system.debug('@@@updateCase timeslot'+timeslot);
      //system.debug('@@@updateCase previousTime'+previousTime);
       //system.debug('@@@updateCase invoiceId'+invoiceId);
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
           //system.debug('@@caseObj'+caseObj);
            return  caseObj.id;
    }
  /* Private static Boolean updatedEnrollement(boolean isSameMonth,Enrolment__c enrol, time timeslot, string teacherId, Integer duration,date effectiveDate,boolean isDayChange, date currentEffectiveDate,string packageId, boolean Error){
        enrol = AdvanceActionsHelper.getUpdatedEnrollmentFields(enrol.id,ConstantsClass.enrollmentProcessChanged,
                                                                           null,effectiveDate,packageId,timeslot);
        //Set<String> setOfMakeupBookings = new Set<String>();
       //system.debug('@@@enrol'+enrol);
        //List<Booking__c> listOfMakeupBoookings = new List<Booking__c>();
        if(String.isNotBlank(teacherId)){
            if(isSameMonth){
                enrol.Teacher__c = teacherId;
            }
            enrol.New_Teacher__c = teacherId;
        }
        Database.SaveResult saveResult = Database.update(enrol, false);
        if(saveResult.isSuccess()){
           //system.debug('@@@enrol'+enrol);
           //system.debug('@@@effectiveDate'+effectiveDate);
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
               //system.debug('##The following error has occurred.');                    
               //system.debug('###'+err.getStatusCode() + ': ' + err.getMessage());
               //system.debug('###Account fields that affected this error: ' + err.getFields());
            }
        }
        return saveResult.isSuccess();
    }*/
  
}