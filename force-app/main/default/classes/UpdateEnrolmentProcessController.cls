/*
Name    :  UpdateEnrolmentProcessController
Test Class  :        UpdateEnrolmentProcessControllertest
Component   :		 AureusCalendarCMP,ossiaCenterCmp
*/
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
            // 28-Oct-2020 : @@nishi  :check  Enrolment package type is Prepayemnt or promo or is normal packages       
            Boolean isPromotionalEnrolment=false;
            Boolean isPromoPackageEnrolment=false;
            if( String.isNotBlank(enrolmentObj.Type_of_Package__c) && (enrolmentObj.Type_of_Package__c == ConstantsClass.prePaymentType || enrolmentObj.Type_of_Package__c == ConstantsClass.PromoTypePayment)){
                isPromotionalEnrolment= true;
                if(enrolmentObj.Type_of_Package__c == ConstantsClass.PromoTypePayment){
                    isPromoPackageEnrolment = true;
                }
            }
            // 28-Oct-2020 : @@nishi  :check  Enrolment package type is Prepayemnt or promo or is normal packages
              
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
                system.debug('isSameMonth'+isSameMonth);
                if(saveResult.isSuccess() && teacherPackageChange){
                    if(isSameMonth){
                        invoiceId =  createInvoiceAndLineItemsChangeEnrol(enrolmentObj, effectiveDate, nextBillDate, oldTeacher,oldPackage,teacherId,packageId,isPromotionalEnrolment);
                    }else{
                         // added by nishi: 12-May-2021:start If enrolment Package is promo and Promotional_Period_End_Date is greated then next billing date then we get that month then we calculate paid invoice amount
                        if(isPromoPackageEnrolment){
                            map<string,Credit_Memo__c> newPendingCreditMemos = upgradeDowngradeController.createCreditMemoNextBillingDateForPromoPackage(enrolmentObj.Id,oldPackage, effectiveDate,'Update Enrolment invoice Adjustment');
                            AdvanceActionsHelper.updatePromotionalEnrolment(enrolmentObj,effectiveDate,nextBillDate);
                        }
                         // added by nishi: 12-May-2021:start If enrolment Package is promo and Promotional_Period_End_Date is greated then next billing date then we get that month then we calculate paid invoice amount
                
                    }
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
            caseReturn = 'error';
            System.debug('@@caseIdToReturn'+e.getStackTraceString()+'-'+e.getMessage() +';');
            Database.rollback(updateSavePoint);
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
   @TestVisible
    private static String getPrepaymentPackageInvoiceAmount(Enrolment__c objEnrol,Map<Id,Package__c> mapOfPackages,
                                                            map<id,String> packageInvoiceAmount,string packageId,boolean isDiscount){
        decimal totalAmount = 0;
        decimal gstAmount = 0;
        Decimal noOfMonths = String.isNotBlank(mapOfPackages.get(packageId).Promotion_period_In_months__c) ? Integer.valueOf(mapOfPackages.get(packageId).Promotion_period_In_months__c) : 1;
        Decimal preUnitDiscountAmount = 0;    
        if(packageInvoiceAmount.containsKey(packageId)){
            totalAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[0]);
        }
        Integer lessondays = 4;
        if(isDiscount){
            if(mapOfPackages.get(packageId).Promotion_Discount__c != null){
                preUnitDiscountAmount = ((mapOfPackages.get(packageId).Promotion_Discount__c / noOfMonths)/lessondays);
            }
        }else{
            if(mapOfPackages.get(packageId).Package_Fee__c != null){
                preUnitDiscountAmount = ((mapOfPackages.get(packageId).Package_Fee__c / noOfMonths)/lessondays);
            }
        }
        totalAmount += preUnitDiscountAmount;
        if(String.isNotBlank(objEnrol.Id) &&  String.isNotBlank(objEnrol.Center__c)
        && String.isNotBlank(objEnrol.Center__r.Organisation__c) && objEnrol.Center__r.Organisation__r.Tax_Rate__c > 0
        && preUnitDiscountAmount  > 0 ){
            if(packageInvoiceAmount.containsKey(packageId)){
                gstAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[1]);
            }
            gstAmount += (preUnitDiscountAmount * objEnrol.Center__r.Organisation__r.Tax_Rate__c)/100;
        }
        
        return totalAmount+';'+gstAmount;
    }
    private static String createInvoiceAndLineItemsChangeEnrol(Enrolment__c objEnrol, Date effectiveDate, Date nextBillingDate, 
                                                               String oldTeacher,String oldPackage,String newTeacher,String newPackage,Boolean isPromotionalEnrolment){
        Invoice__c objectOfInvoice = new Invoice__c();
        decimal totalAmount = 0;
        decimal gstAmount = 0;
        String regularType = ConstantsClass.typeRegular;
        String canceledStatus = ConstantsClass.statusCanceled; 
        List<Subscription_Line_Item__c> listSubLineItem = UpgradeDowngradeController.fetchSubsLineItems(objEnrol.Subscription_Line_Items__r[0].id);
        Subscription_Line_Item__c objSubLineItem;
        if(listSubLineItem != null && listSubLineItem.size() > 0 ){
            objSubLineItem  = listSubLineItem[0];
        }
        List<Invoice_Line_Item__c> invoiceLineItem = new List<Invoice_Line_Item__c>();
        map<String,Invoice_Line_Item__c> updateInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        map<String,Invoice_Line_Item__c> updateCreditMemoInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
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
       
      system.debug('@@@ get bookingList'+bookingList);
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
            map<id,String> packageInvoiceDiscountAmount = new Map<Id,String>();
            /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
             map<id,String> packageInvoiceoldAmount = new Map<Id,String>();
            map<id,String> packageInvoiceoldNextMonthAmount = new Map<Id,String>();
            map<id,String> packageInvoiceoldDiscountAmount = new Map<Id,String>();
            Map<Id,Package__c> mapOfPackages =New Map<Id,Package__c>([Select Id,Unit_Fee__c,Is_Promotion_Discount__c,type_of_package__C, Package_after_Promotion__c,Package_Fee__c, Promotion_period_In_months__c, Promotion_Discount__c from Package__c where Id In:packageIds]);
            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
           
            //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
            Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
            Map<String,Invoice_line_item__c> mapofinvoicelineitem = new Map<String,Invoice_line_item__c>();
            List<Invoice_line_item__c> invoiceLineItemList = new List<Invoice_line_item__c>();
            for(Invoice__c invoiceobj : UpgradeDowngradeController.getInvoiceDetails(objEnrol,effectiveDate,objSubLineItem)){
               if(isPromotionalEnrolment){
                   for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                        if(objlineitem.month__c.month() == effectiveDate.month()){
                            mapofinvoice.put('Current',invoiceobj);
                            if(!objlineitem.Is_Discount__c)
                                mapofinvoicelineitem.put('Current',objlineitem);
                            else if(objlineitem.Is_Discount__c)
                                mapofinvoicelineitem.put('DiscountInvoice',objlineitem);
                        }
                        updateInvoiceLineItem.put(objlineitem.id,objlineitem);
                   }
               }else{
                    if(invoiceobj.invoice_type__c == 'Recurring'){
                        // string invoiceMonth ='';
                        // if(invoiceobj.Invoice_Date__c.month() == effectiveDate.month())
                        //     invoiceMonth = 'Current';
                        // if(nextBillingDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && invoiceobj.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() )
                        //     invoiceMonth = 'Next Month';
                        // system.debug('invoiceMonth'+invoiceMonth);
                        // if(string.isnotBlank(invoiceMonth)){
                        //     mapofinvoice.put(invoiceMonth,invoiceobj);
                        for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                            string invoiceMonth ='';
                            if(objlineitem.month__c.month() == effectiveDate.month())
                            invoiceMonth = 'Current';
                            if(nextBillingDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && objlineitem.month__c.month() == nextMonthDate.addMonths(-1).month() )
                                invoiceMonth = 'Next Month';
                            if(string.isnotBlank(invoiceMonth)){
                                mapofinvoice.put(invoiceMonth,invoiceobj);
                                updateInvoiceLineItem.put(objlineitem.id,objlineitem);
                                system.debug('objlineitem'+objlineitem);
                                if(!objlineitem.Is_Discount__c)
                                    mapofinvoicelineitem.put(invoiceMonth,objlineitem);
                            }
                        }
                        //}
                    }
               }
               
               
            }
            system.debug('mapofinvoicelineitem'+mapofinvoicelineitem);
            system.debug('mapofinvoice'+mapofinvoice);
             //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
           //system.debug('@@@@@mapOfPackages'+mapOfPackages);
            // 6 Dec 2019: jatin for manage packages fee  old package and new package unit fee
            for(Booking__c booking : bookingList){
               //system.debug('@@@@@booking.Booking_date__c'+booking.Booking_date__c);
               if(isPromotionalEnrolment){
                    if(booking.Booking_date__c.month() == effectiveDate.month() && string.isNotBlank(booking.Package__c)){
                        if(mapOfPackages.containsKey(newPackage)){
                            packageInvoiceAmount.put(newPackage,getPrepaymentPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,newPackage,false));    
                            packageInvoiceDiscountAmount.put(newPackage,getPrepaymentPackageInvoiceAmount(objEnrol,mapOfPackages,
                                                                                                          packageInvoiceDiscountAmount,newPackage,true)); 
                        }
                        /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
                        if(mapOfPackages.containsKey(oldPackage)){
                            packageInvoiceoldAmount.put(oldPackage,getPrepaymentPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceoldAmount,oldPackage,false)); 
                            packageInvoiceoldDiscountAmount.put(oldPackage,getPrepaymentPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceoldDiscountAmount,oldPackage,true)); 
                        } 
                        /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
            
                    }
                }else{
                    // added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
                    if(nextBillingDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && booking.Booking_date__c.month() == nextMonthDate.addMonths(-1).month() ){
                    //system.debug('@@@@@next Month'+booking.Booking_date__c);
                        if(string.isNotBlank(booking.Package__c)){
                            if(mapOfPackages.containsKey(newPackage)){
                                packageInvoiceNextMonthAmount.put(newPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceNextMonthAmount,newPackage));    
                            }
                            /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
                            if(mapOfPackages.containsKey(oldPackage)){
                                packageInvoiceoldNextMonthAmount.put(oldPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceoldNextMonthAmount,oldPackage)); 
                            } 
                            /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
                        }
                    }else{
                    //end: added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
                    //system.debug('@@@@ Current Month'+booking.Booking_date__c);
                        if(string.isNotBlank(booking.Package__c)){
                            if(mapOfPackages.containsKey(newPackage)){
                                packageInvoiceAmount.put(newPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,newPackage));    
                            }
                            /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
                            if(mapOfPackages.containsKey(oldPackage)){
                                packageInvoiceoldAmount.put(oldPackage,getPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceoldAmount,oldPackage)); 
                            } 
                            /* 26-Apr-2021 Change Enrolment (Teacher Change) During a promo package was generated and the Credit Memo Line Item Amount for May was doubled so we added other map for old package amount calculation*/
                        }
                    }
                }
            }
            decimal newPackageTotalAmount = 0;
            decimal oldPackageTotalAmount = 0;
            decimal newPackageTotalDiscountAmount = 0;
            decimal oldPackageTotalDiscountAmount = 0;
            decimal newPackageNextMonthTotalAmount = 0;
            decimal oldPackageNextMonthTotalAmount = 0;
             if(packageInvoiceAmount.containsKey(newPackage)){
                 newPackageTotalAmount += decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[0]);
             }
             if(packageInvoiceoldAmount.containsKey(oldPackage)){
                 oldPackageTotalAmount += decimal.valueOf(packageInvoiceoldAmount.get(oldPackage).split(';')[0]);
             }
             // added by nishi: 21-sep-2020: for if next month invoice already generated then we add  invoice line item amount
             if(packageInvoiceNextMonthAmount.containsKey(newPackage)){
                newPackageNextMonthTotalAmount += decimal.valueOf(packageInvoiceNextMonthAmount.get(newPackage).split(';')[0]);
            }
            if(packageInvoiceoldNextMonthAmount.containsKey(oldPackage)){
                oldPackageNextMonthTotalAmount += decimal.valueOf(packageInvoiceoldNextMonthAmount.get(oldPackage).split(';')[0]);
            }
            // added by nishi: 21-sep-2020: for if next month invoice already generated then  we add  invoice line item amount
           system.debug('@@@@@newPackageTotalAmount'+newPackageTotalAmount);
           system.debug('@@@@@oldPackageTotalAmount'+oldPackageTotalAmount);
           system.debug('@@@@@newPackageNextMonthTotalAmount'+newPackageNextMonthTotalAmount);
           system.debug('@@@@@oldPackageNextMonthTotalAmount'+oldPackageNextMonthTotalAmount);
           system.debug('@@@@@packageInvoiceAmount'+packageInvoiceAmount);
           system.debug('@@@@@packageInvoiceDiscountAmount'+packageInvoiceDiscountAmount);
           //system.debug('@@parentId'+parentId);
           //nishi: 18-Sep-2020: No invoice when no change in teacher and package
           if(oldPackage != newPackage || oldTeacher != newTeacher){
                if((oldPackageTotalAmount > 0 && newPackageTotalAmount > 0) || (newPackageNextMonthTotalAmount > 0 && oldPackageNextMonthTotalAmount > 0) && String.isNotBlank(parentId)){
                    objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                    Invoice_Date__c =system.today(), Parent_Account__c = parentId, Center__c=bookingList[0].center__c);
                                                    objectOfInvoice.Credit_Memo_Amount__c  =0;
                    INSERT objectOfInvoice;
                  //system.debug('@@@ created objectOfInvoice'+objectOfInvoice);
                    if(objectOfInvoice != NULL){
                         //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                         String invoiceId = null;
                        if(mapofinvoice != null && mapofinvoice.size() > 0  && mapofinvoice.containskey('Current')){
                            invoiceId = mapofinvoice.get('Current').id;
                        }
                        listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
                        //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                        
                        if(packageInvoiceAmount.containsKey(newPackage)){
                            if(packageInvoiceAmount.get(newPackage).split(';') != null && packageInvoiceAmount.get(newPackage).split(';').size() >0){
                                newPackageTotalAmount = decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[0]);
                                gstAmount = (decimal.valueOf(packageInvoiceAmount.get(newPackage).split(';')[1]));
                                Invoice_Line_Item__c inlineItemForupdate = PackageUpgradeController.createInvoiceLineItem(objectOfInvoice.id,objSubLineItem,newPackageTotalAmount, newPackage,false, newTeacher);
                                inlineItemForupdate.month__c = effectiveDate;
                                invoiceLineItem.add(inlineItemForupdate);
                            }
                        }
                        if(packageInvoiceoldAmount.containsKey(oldPackage)){
                            if(packageInvoiceoldAmount.get(oldPackage).split(';') != null && 
                               packageInvoiceoldAmount.get(oldPackage).split(';').size() >0){
                                oldPackageTotalAmount = decimal.valueOf(packageInvoiceoldAmount.get(oldPackage).split(';')[0]);
                                gstAmount = decimal.valueOf(packageInvoiceoldAmount.get(oldPackage).split(';')[1]);
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
                                if(isPromotionalEnrolment){
                                    if(mapofinvoicelineitem.containskey('Current')){
                                        invoicelineitemId =mapofinvoicelineitem.get('Current').id; 
                                    }
                                }else{ 
                                    if(mapofinvoice != null && mapofinvoice.size() > 0 && mapofinvoice.containskey('Current') && mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                                        invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                                    }
                                }
                                Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(oldPackageTotalAmount,gstAmount,oldPackage,
                                objEnrol.id,invoicelineitemId,'',effectiveDate);
                                objectOfInvoice.Credit_Memo_Amount__c +=  oldPackageTotalAmount+gstAmount;
                                listOfCreditmemolineitem.add(objCreditLineItem);                                                  
                                //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.


                                //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                                if(string.isNotBlank(invoicelineitemId)){
                                    updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,oldPackageTotalAmount,gstAmount,invoicelineitemId));
                                }
                            }                 
                        }
                        // nishi: 28-Oct-2020: if enrolment package type is promotional then we Create a credit memo for the previous package and teacher for the leftover period.
                        //and Create an invoice for the new package and teacher for the remaining period and adjust the credit memo amount.
                        if(isPromotionalEnrolment){
                            system.debug('@@@@@packageInvoiceDiscountAmount'+packageInvoiceDiscountAmount);
                            if(packageInvoiceDiscountAmount.containsKey(newPackage)){
                                if(packageInvoiceDiscountAmount.get(newPackage).split(';') != null && packageInvoiceDiscountAmount.get(newPackage).split(';').size() >0){
                                    newPackageTotalDiscountAmount = -BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceDiscountAmount.get(newPackage).split(';')[0]));
                                    gstAmount = -BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceDiscountAmount.get(oldPackage).split(';')[1]));
                                    Invoice_Line_Item__c inlineItemForupdate = PackageUpgradeController.createInvoiceLineItem(objectOfInvoice.id,objSubLineItem,-(newPackageTotalDiscountAmount), newPackage,false, newTeacher);
                                    inlineItemForupdate.month__c = effectiveDate;
                                    inlineItemForupdate.Amount__c = newPackageTotalDiscountAmount;
                                    inlineItemForupdate.GST_Amount__c = gstAmount;
                                    inlineItemForupdate.Is_Discount__c = true; 
                                    invoiceLineItem.add(inlineItemForupdate);
                                }
                            }
                            if(packageInvoiceoldDiscountAmount.containsKey(oldPackage)){
                                if(packageInvoiceoldDiscountAmount.get(oldPackage).split(';') != null && 
                                   packageInvoiceoldDiscountAmount.get(oldPackage).split(';').size() >0){
                                    oldPackageTotalDiscountAmount = -BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceoldDiscountAmount.get(oldPackage).split(';')[0]));
                                    gstAmount = -BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceoldDiscountAmount.get(oldPackage).split(';')[1]));
                                    String invoicelineitemId = null;
                                    if(mapofinvoicelineitem.containskey('DiscountInvoice')){
                                        invoicelineitemId =mapofinvoicelineitem.get('DiscountInvoice').id; 
                                    }
                                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(oldPackageTotalDiscountAmount,gstAmount,oldPackage,
                                    objEnrol.id,invoicelineitemId,'',effectiveDate);
                                    objCreditLineItem.Is_Discount__c = true; 
                                    objectOfInvoice.Credit_Memo_Amount__c +=  oldPackageTotalDiscountAmount+gstAmount;
                                    listOfCreditmemolineitem.add(objCreditLineItem);                                                  
                                   if(string.isNotBlank(invoicelineitemId)){
                                        updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,oldPackageTotalDiscountAmount,gstAmount,invoicelineitemId));
                                    }
                                }                 
                            }
                            List<Invoice__c> listOfInvoice = UpgradeDowngradeController.getInvoiceDetails(objEnrol,effectiveDate.addmonths(1),objSubLineItem) ;
                            system.debug('@@@@@listOfInvoice'+listOfInvoice);
                            
                            if(listOfInvoice != null && listOfInvoice.size() >0){
                                List<Invoice_line_item__c> listOfInvoiceLineItemForPrepaymentInvoice = createInvoiceLineItemForPrepaymentInvoice(objectOfInvoice.id,listOfInvoice, objSubLineItem,objEnrol,newTeacher,newPackage);
                                if(listOfInvoiceLineItemForPrepaymentInvoice != null && listOfInvoiceLineItemForPrepaymentInvoice.size() > 0){
                                    invoiceLineItem.addAll(listOfInvoiceLineItemForPrepaymentInvoice);
                                }
                                Map<String,Decimal> parentCreditMemoTotal =  UpgradeDowngradeController.getCreditMemoForPrepaymentInvoiceAmount(listOfInvoice, objEnrol, effectiveDate);
                                if(parentCreditMemoTotal.containsKey(objEnrol.parent__c)){
                                    objectOfInvoice.Credit_Memo_Amount__c += parentCreditMemoTotal.get(objEnrol.parent__c);
                                }
                                system.debug('@@@@@listOfInvoiceLineItemForPrepaymentInvoice'+listOfInvoiceLineItemForPrepaymentInvoice);
                                system.debug('@@@@@parentCreditMemoTotal'+parentCreditMemoTotal);
                            }
                            
                            List<Credit_memo_line_item__c> listOfCreditMemoForPrepaymentInvoice = WithDrawlEnrolmentProcessController.createCreditMemoForPrepaymentInvoice( objSubLineItem,objEnrol,effectiveDate);
                            if(listOfCreditMemoForPrepaymentInvoice != null && listOfCreditMemoForPrepaymentInvoice.size() > 0){
                                listOfCreditmemolineitem.addAll(listOfCreditMemoForPrepaymentInvoice);                                                  
                            }
                            system.debug('@@@@@listOfCreditMemoForPrepaymentInvoice'+listOfCreditMemoForPrepaymentInvoice);
                        }else{
                            // start:added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
                            if(packageInvoiceNextMonthAmount.containsKey(newPackage)){
                                if(packageInvoiceNextMonthAmount.get(newPackage).split(';') != null && packageInvoiceNextMonthAmount.get(newPackage).split(';').size() >0){
                                    newPackageNextMonthTotalAmount = decimal.valueOf(packageInvoiceNextMonthAmount.get(newPackage).split(';')[0]);
                                    Invoice_Line_Item__c inlineItemForupdate = PackageUpgradeController.createInvoiceLineItem(objectOfInvoice.id,objSubLineItem,newPackageNextMonthTotalAmount, newPackage,false, newTeacher);
                                    inlineItemForupdate.month__c = nextMonthDate.addMonths(-1);
                                    invoiceLineItem.add(inlineItemForupdate);
                                }
                            }
                            if(packageInvoiceoldNextMonthAmount.containsKey(oldPackage)){
                                if(packageInvoiceoldNextMonthAmount.get(oldPackage).split(';') != null && packageInvoiceoldNextMonthAmount.get(oldPackage).split(';').size() >0){
                                    oldPackageNextMonthTotalAmount = BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceoldNextMonthAmount.get(oldPackage).split(';')[0]));
                                    gstAmount = BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceoldNextMonthAmount.get(oldPackage).split(';')[1]));
                                    /*Commented by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                                     oldPackageNextMonthTotalAmount = -oldPackageNextMonthTotalAmount;
                                    if(gstAmount > 0){
                                        gstAmount = -gstAmount;
                                    }
                                    invoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,Amount__c = oldPackageNextMonthTotalAmount, 
                                                                            Teacher_Id__c = oldTeacher,Month__c= nextMonthDate.addMonths(-1),
                                                                            Enrolment__c =objEnrol.id,Subscription_line_item__c = subLineItemId,
                                                                            Package__c = oldPackage,  GST_Amount__c = gstAmount));*/
                                    //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                            
                                    String invoicelineitemId = null;
                                    if(mapofinvoice != null && mapofinvoice.size() > 0 && mapofinvoice.containskey('Next Month') && mapofinvoice.get('Next Month').Invoice_Line_Items__r != null && mapofinvoice.get('Next Month').Invoice_Line_Items__r.size()>0){
                                        invoicelineitemId =mapofinvoice.get('Next Month').Invoice_Line_Items__r[0].id; 
                                    }
                                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(oldPackageNextMonthTotalAmount,gstAmount,oldPackage,
                                    objEnrol.id,invoicelineitemId,'',nextMonthDate.addMonths(-1));
                                    listOfCreditmemolineitem.add(objCreditLineItem);    
                                    objectOfInvoice.Credit_Memo_Amount__c +=  (oldPackageNextMonthTotalAmount+gstAmount);        
                                    //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                                    if(string.isNotBlank(invoicelineitemId)){
                                        updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,oldPackageNextMonthTotalAmount,gstAmount,invoicelineitemId));
                                    }
                                }
                                //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                            
                                // end:added by nishi: 21-sep-2020: for if next month invoice already generated then we create new invoice line item
                            }
                        }
                        system.debug('@@@@@listOfCreditmemolineitem'+listOfCreditmemolineitem);
                        if(listOfCreditmemolineitem != null && listOfCreditmemolineitem.size() > 0){
                            Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  system.today(),'Update Enrolment invoice Adjustment');
                            objCreditMemo.Status__c = ConstantsClass.creditMemoSuccessStatus;
                            objCreditMemo.Invoice_Number__c = objectOfInvoice.Id;
                            newPendingCreditMemos.put('Update Enrolment invoice Adjustment',objCreditMemo);
                            mapOfCreditmemolineitem.put('Update Enrolment invoice Adjustment',listOfCreditmemolineitem); 
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
                    if(updateCreditMemoInvoiceLineItem != null && updateCreditMemoInvoiceLineItem.size() > 0){
                        update updateCreditMemoInvoiceLineItem.values();
                    }
                    system.debug('@@@updateCreditMemoInvoiceLineItem'+updateCreditMemoInvoiceLineItem);
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

    private static  Invoice_Line_Item__c updateInvoiceLineItemMap(Map<string,Invoice_Line_Item__c> updateInvoiceLineItem,decimal amount,decimal tax,string invoicelineitemId){
        decimal invoicelineItemCreditAmount=0;
        decimal invoicelineItemCreditGst=0;
        
        if(updateInvoiceLineItem.containskey(invoicelineitemId)){
            invoicelineItemCreditAmount = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c :0;
            invoicelineItemCreditGst = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c :0;
        }

        return new Invoice_Line_Item__c(id=invoicelineitemId,
                                    Credit_Memo_Amount__c =invoicelineItemCreditAmount+(amount),
                                    Credit_Memo_tax__c=invoicelineItemCreditGst+tax);
    }

    public static List<invoice_Line_item__c> createInvoiceLineItemForPrepaymentInvoice(string objectOfInvoiceId,List<Invoice__c> listOfInvoice, 
    Subscription_Line_Item__c objSubLineItem ,Enrolment__c objEnrol,string newTeacher,string newPackage){
        List<invoice_Line_item__c> newPackageinvoiceLineItemList = new List<invoice_Line_item__c>();
        if(listOfInvoice != null && listOfInvoice.size() > 0){
            for(Invoice__c objInvoice : listOfInvoice){
                if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                    // if invoice line item month is greater then effective month then we create credit memo and added credit memo line item
                    for(invoice_Line_item__c objOldInvoiceLineItem : objInvoice.Invoice_Line_Items__r){
                        Invoice_Line_Item__c inlineItemForupdate = PackageUpgradeController.createInvoiceLineItem(objectOfInvoiceId,objSubLineItem,objOldInvoiceLineItem.Amount__c, newPackage,objOldInvoiceLineItem.Is_Deposit__c,  newTeacher);
                        inlineItemForupdate.Is_discount__c = objOldInvoiceLineItem.Is_discount__c;
                        inlineItemForupdate.Amount__c = objOldInvoiceLineItem.Amount__c;
                        inlineItemForupdate.GST_Amount__c = objOldInvoiceLineItem.GST_Amount__c;
                        inlineItemForupdate.month__c = objOldInvoiceLineItem.month__c;
                        newPackageinvoiceLineItemList.add(inlineItemForupdate);
                    }
                }
            }
        }
        return newPackageinvoiceLineItemList;
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