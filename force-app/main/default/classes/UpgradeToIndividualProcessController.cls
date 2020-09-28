/***
    Name: UpgradeToIndividualProcessController
    Date: 24-Dec-2019
    Author: Jatin
    Description: this controller for Upgrade Enrolment Of group class  To Individual Customer booking
 */
public without sharing class UpgradeToIndividualProcessController implements IAdvanceAction{
      //Data Members for the Upgrade Package of the Customer
    Private String booking;
    Private Date effectiveDate;
    Private String oldPackage;
    Private String newPackage;
    
    Private String newTeacherId;
    Private Time timeslot;
    Private String caseId;
    Private String caseRedirect;
    Private Map<String, String> mapOfCase;
    
    //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    Private Date nextBillDate;
   // Private Country__c countryObj;commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic*/
   Private Organisation__c organisationObj;
    Public Map<String, Booking__c> mapOfBooking = new Map<String, Booking__c>();
    Public Map<String, Fifth_Lesson__c> mapOfFifthLesson = new Map<String, Fifth_Lesson__c>();
    Private UpgradeEnrolmentClassProcessController.UpgradeCaseCreation upgradeDetails;
    Private string centreOrgId;
    Public Date startDate;
    //Constructor to Initialize all the data members
    public UpgradeToIndividualProcessController(String booking, String effectiveDateStr, String newPackage, 
                                             String oldPackage, String timeSlot, String caseId, String caseRedirect, 
                                             Map<String, String> caseValuesOfMap,string newTeacherId) {
        this.booking = booking;
        effectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(effectiveDateStr);
        this.newPackage = newPackage;
        this.oldPackage = oldPackage;
        this.timeslot = AdvanceActionsHelper.getDateTimeFromString(timeSlot).time();
        this.caseId = caseId;
        this.caseRedirect = caseRedirect;
        this.newTeacherId = newTeacherId;
        mapOfCase = new Map<String, String>();
        mapOfCase = caseValuesOfMap;

        enrolmentObj = new Enrolment__c();
        
        //countryObj = new Country__c();commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic*/
        organisationObj = new Organisation__c();
        upgradeDetails = new UpgradeEnrolmentClassProcessController.UpgradeCaseCreation();
	system.debug('booking'+booking);
                                                    //system.debug('effectiveDate'+effectiveDate);
                                                    //system.debug('newPackage'+newPackage);
                                                    //system.debug('oldPackage'+oldPackage);
                                                    //system.debug('timeslot'+timeslot);
                                                    //system.debug('caseId'+caseId);
                                                    //system.debug('caseRedirect'+caseRedirect);
                                                    //system.debug('caseValuesOfMap'+caseValuesOfMap);
                                                    //system.debug('newTeacherId'+newTeacherId);
    }
    //Init Method where all the process gets Start...
   Public String initProcess(){
        enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
       //system.debug('enrolmentObj'+enrolmentObj);
        String caseIdToReturn;
        Boolean isSuccess = FALSE;
        string oldTeacher;
        if(string.isNotBlank(enrolmentObj.id)){
            startDate = enrolmentObj.Effective_Date__c;
            //Fetch Next Bill Date From Enrolment
            nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
            oldTeacher = enrolmentObj.Teacher__c;
            //Fetch the Country Object From Enrolment
           // countryObj = AdvanceActionsHelper.fetchCountryFromEnrolment(enrolmentObj);
             if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.center__r.Organisation__c)){
                organisationObj = enrolmentObj.center__r.Organisation__r;
            } 
           //system.debug('upgradeDetails.nextBillDate = '+nextBillDate);
           //system.debug('upgradeDetails.effectiveDate = '+effectiveDate);
            //system.debug('upgradeDetails.countryObj = '+countryObj);
            /*if(effectiveDate <= nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
               //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
                upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, nextBillDate, newPackage, oldPackage, timeslot,
                                countryObj,newTeacherId );
                enrolmentObj = upgradeDetails.enrolObj;
               //system.debug('@@@upgradeDetails.enrolObj'+enrolmentObj);
               //system.debug('@@@upgradeDetails.enrolObj'+upgradeDetails.isSuccess);
            }else if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
                //Hit API and create Invoice and Line Items and Payment Record if the Effective Date is Greater than Next Bill Date
                upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, countryObj, effectiveDate);
               //system.debug('@@@upgradeDetails.enrolObj'+upgradeDetails.isSuccess);*/
            if(effectiveDate <= nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(organisationObj.Id)){
                //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
                upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, nextBillDate, newPackage, oldPackage, timeslot,
                                                                organisationObj,newTeacherId ); 
                enrolmentObj = upgradeDetails.enrolObj;
                //system.debug('@@@upgradeDetails.enrolObj'+enrolmentObj);
                //system.debug('@@@upgradeDetails.enrolObj'+upgradeDetails.isSuccess);
            }else if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(organisationObj.Id)){
                //Hit API and create Invoice and Line Items and Payment Record if the Effective Date is Greater than Next Bill Date
                upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, organisationObj, effectiveDate);
                //system.debug('@@@upgradeDetails.enrolObj'+upgradeDetails.isSuccess);    
                if(upgradeDetails.isSuccess){
                    enrolmentObj.New_Package_Id__c = newPackage;
                    enrolmentObj.New_Teacher__c = newTeacherId;
                    enrolmentObj.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
                    enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
                    enrolmentObj.Effective_Date__c = effectiveDate;
                    enrolmentObj.Package_Process_Request_Date__c = System.today();
                    enrolmentObj.Advance_Action_Requested_By__c = Userinfo.getUserId();
                    enrolmentObj.Next_Lesson_Start_time__c = timeslot;
                    // added by jatin: 4-jan-2020 : for add new changed enrollment day  
                    DateTime newEffectiveDateTime = DateTime.newInstance(effectiveDate, timeslot);
                    enrolmentObj.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
                    if(String.isNotBlank(enrolmentObj.Id)){
                        Database.SaveResult saveResult = Database.Update(enrolmentObj, false);
                        if(!saveResult.isSuccess()){
                            isSuccess = false;
                        }
                        
                    }
                }
               //system.debug('@@@upgradeDetails.enrolObj'+enrolmentObj);
            }
        }
       //system.debug('@@@upgradeDetails.isSuccess'+upgradeDetails.isSuccess);
        if(String.isNotBlank(enrolmentObj.Id) && upgradeDetails.isSuccess){
            enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentObj.id);
           //system.debug('@@@enrolmentObj'+enrolmentObj);
            if(enrolmentObj.Center__r != null && string.isNotBlank(enrolmentObj.Center__r.Organisation__c)){
                centreOrgId = enrolmentObj.Center__r.Organisation__c;
            }
            // 27-dec-2019: cancel all future makeup bookings
            WithDrawlEnrolmentClassProcessController.processFutureMakeupBookingsForWithdrawal(enrolmentObj, new List<Booking__c>());
        
            // create new Regular bookings and deleted all group lesson type bookings
            processFutureGroupLessonBookings(enrolmentObj,effectiveDate);
           }
        
        Integer timeDiff = 0;
       
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
            
            objCase.New_Teacher__c =  newTeacherId;   
            objCase.Previous_teacher__c = oldTeacher; 

            upsert objCase;
           //system.debug('@@objCase.Id'+objCase.Id);
            caseIdToReturn = objCase.Id;
        }
        if(!upgradeDetails.isSuccess)
            caseIdToReturn = 'error';
        return caseIdToReturn;
    }

     //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
    Private UpgradeEnrolmentClassProcessController.UpgradeCaseCreation updatePackageNextDateIsGreater(String enrolmentId, Date effectiveDate, Date nextBillDate, String newPackageId, String oldPackageId, 
                                Time newTimeSlot, /*Country__c countryObj*/Organisation__c  organisationObj,string newTeacherId){
        UpgradeEnrolmentClassProcessController.UpgradeCaseCreation upgradeCaseDetails = new UpgradeEnrolmentClassProcessController.UpgradeCaseCreation();
        Boolean isSuccess = false;
        String invoiceId;
        if(String.isNotBlank(enrolmentId) && nextBillDate != Null && effectiveDate != Null &&
           String.isNotBlank(newPackageId) && String.isNotBlank(oldPackageId) && newTimeSlot != Null &&String.isNotBlank(organisationObj.Id)){ //String.isNotBlank(countryObj.Id)){
            /*commented by nishi: 21-Sep-2020:Organisation wise charge as per new logic
            upgradeCaseDetails = upgradeGroupPackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, 
            organisationObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c,
                                  countryObj.Tax_Rate__c,newTeacherId);*/
                upgradeCaseDetails = upgradeGroupPackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, 
               organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c,
               organisationObj.Tax_Rate__c,newTeacherId);
           }
        return upgradeCaseDetails;
    }
    public static UpgradeEnrolmentClassProcessController.UpgradeCaseCreation upgradeGroupPackage(Id enrollMentId,Date effectDate,Id PackageId,Id OldPackage, 
                                    Time timeslot, String currencyCode, String baseUrl, String apiKey,
                                     Decimal taxRate, string newTeacherId){
        UpgradeEnrolmentClassProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentClassProcessController.UpgradeCaseCreation();
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
        
        //Create MAp for Create fifthBookings
        Map<String, Booking__c> mapOfFifthBookings = new Map<String, Booking__c>();
        Date effectiveDate = effectDate; //objSubLineItem.Enrolment__r.Effective_Date__c;
        List<Booking__c> listOfBookings = UpgradeDowngradeController.fetchListOfBookings(enrollmentId);
       //system.debug('@@listOfBookings'+listOfBookings);
       //system.debug('@@@effectDate'+effectDate);
        Decimal newPackageUnitPrice = 0;
        Decimal depositeFee = 0;
        Decimal totalAmount = 0; Decimal gstAmount = 0; Decimal totalWithNoGST = 0;
        Decimal fifthBookingPrice = 0;
        

        for(Booking__c objBooking : listOfBookings){
            if(objBooking.Booking_Date__c >= effectiveDate){
                   if(objBooking.Type__c == ConstantsClass.groupLessonTypeBooking ){
                        newPackageUnitPrice += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                        if(taxRate > 0){
                            gstAmount += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c) * taxRate/100;
                        }
                    } 
            }
        }
          // // added by Nishi: 21-Sep-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
       //  // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 
       date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
       date nextBillDate = objSubLineItem.Next_Bill_Date__c;
       if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month()){
           List<Booking__c> listOfNextMonthBookings = UpgradeDowngradeController.fetchListOfNextMonthBookings(enrollmentId);
           for(Booking__c objBooking : listOfNextMonthBookings){
               if(objBooking.Booking_Date__c >= effectiveDate){
                   if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){//||objBooking.Type__c == ConstantsClass.groupLessonTypeBooking
                       newPackageNextMonthPrice += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                       if(taxRate > 0){
                           gstNextMonthAmount += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c) * taxRate/100;
                       }
                   }      
               }
           }
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
        
        depositeFee = BillingUtility.roundOffAmount(newPackg.Deposit_Fee__c - currentPackageDeposit);
        newPackageUnitPrice = BillingUtility.roundOffAmount(newPackageUnitPrice);
        gstAmount = BillingUtility.roundOffAmount(gstAmount);
        
        totalAmount = BillingUtility.roundOffAmount(newPackageUnitPrice + gstAmount + depositeFee);
        totalWithNoGST = BillingUtility.roundOffAmount(newPackageUnitPrice + depositeFee);
        String stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c;
       //system.debug('@@@@@newPackageUnitPrice'+newPackageUnitPrice);
       //system.debug('@@@@@gstAmount'+gstAmount);
       //system.debug('@@@@@totalAmount'+totalAmount);
       //system.debug('@@@@@depositeFee'+depositeFee);
       //system.debug('@@@@@totalWithNoGST'+totalWithNoGST);
       //system.debug('@@@@@stripeId'+stripeId);
        //Summary Details for case for upgrade package.....
        upgradePackageCaseDetails.depositAmount = depositeFee;
        //upgradePackageCaseDetails.lessonCharge = BillingUtility.roundOffAmount(newPackageUnitPrice + gstAmount);
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
        totalAmount = BillingUtility.roundOffAmount(totalAmount);
        gstAmount = BillingUtility.roundOffAmount(gstAmount);
            
        if(String.isNotBlank(stripeId) && totalAmount > 0){
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId,totalAmount, currencyCode, baseUrl, apiKey); 
           //system.debug('@@chargeResponse'+chargeResponse);
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                flag = true;
                upgradePackageCaseDetails.isSuccess = true;
                Invoice__c objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objSubLineItem.Subscription__r.Parent__c,constantsClass.paidStatus);
                objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
                Invoice_Line_Item__c inlineItemForChange = new Invoice_Line_Item__c();
                List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
                insert objInvoice;
               //system.debug('@@objInvoice'+objInvoice);
                if(String.isNotBlank(objInvoice.Id)){
                    upgradePackageCaseDetails.invoiceId = objInvoice.Id;
                }
                if(depositeFee > 0){
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(depositeFee), newPackg.Id,true, '');
                    inlineItemForChange.Is_Deposit__c = True;
                    inlineItemForChange.month__c = effectiveDate;
                    listOfInvoiceLineItems.add(inlineItemForChange);
                    
                }
                if(upgradePackageCaseDetails.lessonCharge > 0){
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageUnitPrice), newPackg.Id,FALSE, objSubLineItem.Enrolment__r.teacher__c);
                    inlineItemForChange.month__c = effectiveDate;
                    listOfInvoiceLineItems.add(inlineItemForChange);
                      // 21-Sep=-2020: nishi: for added new line item for next month invoice already generated
                      if(newPackageNextMonthPrice != 0){
                        inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageNextMonthPrice), newPackg.Id,FALSE, objSubLineItem.Enrolment__r.teacher__c);
                        inlineItemForChange.month__c = nextMonthDate.addMonths(-1);
                        listOfInvoiceLineItems.add(inlineItemForChange);
                    }
                    // 21-Sep=-2020: nishi: for added new line item for next month invoice already generated
                }
                if(totalWithNoGST > 0){
                    upgradePackageCaseDetails.total = totalWithNoGST;
                }
                if(fifthBookingPrice > 0){
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(fifthBookingPrice),newPackg.Id,FALSE, objSubLineItem.Enrolment__r.teacher__c);
                    inlineItemForChange.month__c = effectiveDate;
                    listOfInvoiceLineItems.add(inlineItemForChange);
                }
                if(listOfInvoiceLineItems.size() > 0){
                    INSERT listOfInvoiceLineItems;
                } 
               //system.debug('@@listOfInvoiceLineItems'+listOfInvoiceLineItems);
                objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                
                if(String.isNotBlank(baseUrl) && String.isNotBlank(apiKey) && !test.isRunningTest()){
                	BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, baseUrl, apiKey);                    
                }

                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,totalAmount,ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = chargeResponse.Id;
				objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                INSERT objPayment; 
                 
               //system.debug('@@objPayment'+objPayment);
                if(objInvoice != NULL){
                    BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                }
                upgradePackageCaseDetails.enrolObj = updateEnrollment(enrollMentId,PackageId, timeslot, effectDate,newTeacherId);
                upgradePackageCaseDetails.enrolObj = UpgradeDowngradeController.fetchEnrolment(enrollMentId);
               //system.debug('@@@upgradePackageCaseDetails.enrolObj '+upgradePackageCaseDetails.enrolObj );
                if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                    SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                }
                
            }else{
               flag = false;
               upgradePackageCaseDetails.isSuccess = false;
            }    
        }else{
            flag = false;
            upgradePackageCaseDetails.isSuccess = false;
        }
       //system.debug('@@upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails ;
    }


     public static Enrolment__c updateEnrollment(Id enrolMentId,Id packageId, Time newTimeSlot,
                                                 Date effectiveDate,string newTeacherId){
        Enrolment__c enrol = new Enrolment__c();
        enrol.Id = enrolMentId;
        enrol.Package__c = packageId;
        enrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
        enrol.Lesson_Start_time__c = newTimeSlot;
        enrol.Effective_Date__c = effectiveDate;
        enrol.New_Package_Id__c = packageId;
        enrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        enrol.Package_Process_Request_Date__c = System.today();
        enrol.Advance_Action_Requested_By__c = Userinfo.getUserId();
        enrol.Next_Lesson_Start_time__c = newTimeSlot;
        enrol.Teacher__c = newTeacherId;
        enrol.New_Teacher__c = newTeacherId;
        // added by jatin: 4-Jan -2020 for add new changed enrollment day  
         DateTime newEffectiveDateTime = DateTime.newInstance(effectiveDate, newTimeSlot);
        enrol.New_Lesson_Day__c = newEffectiveDateTime.format('EEEE');
        enrol.Lesson_Day__c = newEffectiveDateTime.format('EEEE');
        // group enrolment also change in regular and class removed
        enrol.Type__c ='Regular';
        enrol.Class__c = Null;
        update enrol;
        return enrol;
    }

  //Hit API and create Invoice and Line Items and Payment Record if the Effective Date is Greater than Next Bill Date
    Private UpgradeEnrolmentClassProcessController.UpgradeCaseCreation updatePackageEffectiveDateIsGreater(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId,
    /* Country__c centreCountry*/Organisation__c  organisationObj, Date effectiveDate){
        Boolean isSuccess = false;
        UpgradeEnrolmentClassProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentClassProcessController.UpgradeCaseCreation();
        String invoiceId = '';
        String stripeId = '', parentId = '';
        Decimal currentPackageDeposit = 0;
        Package__c newPackage, oldPackage = new Package__c();
        Set<String> invoiceIds = new Set<String>();
        AureusCalendarController.UpgradeDowngradePackageSummary summary = AureusCalendarController.getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
        newPackage = summary.newPackage;
        oldPackage = summary.oldPackage; 
        
        if(String.isNotBlank(enrolmentObj.Id)){
           //system.debug('##currentPackageDeposit'+currentPackageDeposit);
            currentPackageDeposit = AdvanceActionsHelper.getDepositFromFile(enrolmentObj.Id);
        }
        
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Decimal depositeFee = BillingUtility.roundOffAmount((newPackage.Deposit_Fee__c - currentPackageDeposit)); 
        if(enrolmentObj != Null){
            stripeId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c;
            parentId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
        
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
        upgradePackageCaseDetails.total = depositeFee;
        upgradePackageCaseDetails.isSuccess = true;
        
        if(String.isNotBlank(stripeId) && depositeFee > 0 && String.isNotBlank(organisationObj.Id)){// commented by @nishi 21 Sep 2020,Organisation wise charge as per new logicString.isNotBlank(centreCountry.Id)){
           
            Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
            //commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic
            //BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c); 
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c); 
            
           //system.debug('@@@chargeResponse'+chargeResponse);
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){                
                isSuccess = true;
                Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.paidStatus);
                objInvoice.Center__c = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.center__c;
                
                insert objInvoice;
                
                if(String.isNotBlank(objInvoice.Id)){
                    upgradePackageCaseDetails.invoiceId = objInvoice.Id;
                }
                if(depositeFee > 0){
                    inlineItemforChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolmentObj.Subscription_Line_Items__r[0], depositeFee, newPackage.Id, true, '');
                    inlineItemforChange.Month__c = effectiveDate;
                    inlineItemforChange.Is_Deposit__c = True;
                    listOfInvoiceLineItems.add(inlineItemforChange);
                }
                
                if(listOfInvoiceLineItems.size() > 0){
                    INSERT listOfInvoiceLineItems;
                } 
                
                objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                if(!Test.isRunningTest() && String.isNotBlank(organisationObj.Id)){//commented by @nishi 21 Sep 2020,Organisation wise charge as per new logicString.isNotBlank(centreCountry.Id)){
                     //commented by @nishi 21 Sep 2020,Organisation wise charge as per new logic
                    //BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
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
            }else{
                isSuccess = false;
                upgradePackageCaseDetails.isSuccess = false;
            }
        }else{
            isSuccess = false;
        }
       //system.debug('@@@updatePackageEffectiveDateIsGreater upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails;
    }
    
    private void processFutureGroupLessonBookings(Enrolment__c enrolmentObj,date effectiveDate){
        Date maxDate;      
        if(String.isNotBlank(enrolmentObj.Id) && effectiveDate != NULL){
            // get max date for creating new Bookings end of the max date
            maxDate = getMaxDateOfEnrolmentBookings(enrolmentObj.Id);
            Integer lastDayOfMonth = Date.daysInMonth(maxDate.year(), maxDate.month());
            maxDate = Date.newInstance(maxDate.year(), maxDate.month(), lastDayOfMonth);
            // cancel all future bookings 
            processOldGroupLessonBookings(enrolmentObj.Id, effectiveDate);
        }
       //system.debug('@@maxDate'+maxDate);
         if(String.isNotBlank(enrolmentObj.Id)){
            if(maxDate != NULL && effectiveDate != NULL){
                reCreateRegularBookingsAndFifthLesson(enrolmentObj, effectiveDate, maxDate);
            }
        }
         if(maxDate != NULL && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.New_Teacher__c) && effectiveDate != NULL){
            processTeacherLeaves(enrolmentObj.New_Teacher__c, effectiveDate,  maxDate);
        }
       //system.debug('!!maxDate'+maxDate);
       //system.debug('enrolmentObj.New_Teacher__c'+enrolmentObj.New_Teacher__c);
       //system.debug('!!enrolmentObj.Id'+enrolmentObj.Id);
       //system.debug('!!effectiveDate'+effectiveDate);
       //system.debug('!!centreOrgId'+centreOrgId);
        if(maxDate != NULL && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.New_Teacher__c) && effectiveDate != NULL && String.isNotBlank(centreOrgId)){
            List<Account> teacherlist = [select id,Employee_Duty_Type__c from Account where Id =: enrolmentObj.New_Teacher__c]; 
            if(teacherlist != null && teacherlist.size() > 0)
                processPublicHolidays(effectiveDate, maxDate, centreOrgId, teacherlist[0]);
        }
}	
/*
    *   This Method will Recreate the Regular Bookings for Enrolment and fifth Lesson Records.

    */
    private void reCreateRegularBookingsAndFifthLesson(Enrolment__c  enrolmentObj, Date effectiveDate, Date maxDate){
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToInsert = new List<Fifth_Lesson__c>();
       //system.debug('@@@@reCreateRegularBookingsAndFifthLesson maxDate'+maxDate);
       //system.debug('@@@@reCreateRegularBookingsAndFifthLesson enrolmentObj'+enrolmentObj);
       //system.debug('@@@@reCreateRegularBookingsAndFifthLesson effectiveDate'+effectiveDate);
        if(String.isNotBlank(enrolmentObj.Id)){
            Booking__c bookingObj = new Booking__c();
            Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();
            while(effectiveDate <= maxdate){
                if(effectiveDate.day() > 28){
                    fifthLesson = new Fifth_Lesson__c();
                    if(effectiveDate != null )
                        fifthLesson.Booking_Date__c = effectiveDate;
                    if(string.isNotBlank(enrolmentObj.Center__c))
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
                   //system.debug('@@@new effectiveDate'+fifthLesson);
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
                    
                    bookingObj.Type__c = ConstantsClass.typeRegular;
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
                    bookingsToInsert.add(bookingObj);
                   //system.debug('@@@new effectiveDate'+bookingObj);
                }
                
                effectiveDate = effectiveDate.addDays(7);
               //system.debug('@@@new effectiveDate'+effectiveDate);
            }       
        }

        if(bookingsToInsert.size() > 0){
            INSERT bookingsToInsert;
           //system.debug('@@@New Bookings are Inserted '+bookingsToInsert);

            for(Booking__c bookingObj : bookingsToInsert){
                mapOfBooking.put(bookingObj.Booking_Date__c + '-' + bookingObj.Teacher_Account__c, bookingObj);
            }
        }
       //system.debug('@@@@mapOfBooking --'+mapOfBooking);
        if(fifthLessonToInsert.size() > 0){
            INSERT fifthLessonToInsert;
           //system.debug('@@@New fifthLesson are Inserted '+fifthLessonToInsert);
            for(Fifth_Lesson__c lessonFifth : fifthLessonToInsert){
                mapOfFifthLesson.put(lessonFifth.Booking_Date__c + '-' + lessonFifth.Teacher_Account__c, lessonFifth);
            }
        }
       //system.debug('@@@@mapOfFifthLesson --'+mapOfFifthLesson);
    }
 private Date getMaxDateOfEnrolmentBookings(String enrolId){
        Date maxDate;
        List<AggregateResult> AggregateResultList = [select Max(Booking_Date__c)maxDate 
                                                    from Booking__c where Enrolment__c =: enrolId
                                                    AND Type__c =: ConstantsClass.groupLessonTypeBooking];
        if(AggregateResultList.size() > 0){
            for(AggregateResult agg : AggregateResultList){
                maxDate = (Date)agg.get('maxDate');
            }
        }
       //system.debug('@@regular booking maxDate =='+maxDate);
        return maxDate;
    }
     private void processOldGroupLessonBookings(String enrolId, Date effectiveDate){
         if(String.isNotBlank(enrolId) && effectiveDate != NULL){
            List<Booking__c> bookingListToDelete = new List<Booking__c>();
            List<Booking__c> bookingsToUpsert = new List<Booking__c>();
           //system.debug('@@@processOldRegularBookings effectiveDate'+effectiveDate);
            for(Booking__c bookObj : [SELECT Id, Type__c, Status__c, Booking_Date__c, Available_Make_up_Units__c, Duration__c, Make_up_Utilize_Bookings__c, 
                                        Teacher_Account__r.Employee_Duty_Type__c 
                                        FROM Booking__c 
                                        WHERE Enrolment__c = :enrolId 
                                        AND Booking_Date__c >= :effectiveDate 
                                        AND Type__c = :ConstantsClass.groupLessonTypeBooking
                                        AND Status__c != :ConstantsClass.statusCanceled ]){
                /*if(bookObj.Type__c == ConstantsClass.groupLessonTypeBooking 
                && bookObj.Status__c == ConstantsClass.statusCanceled 
                && bookObj.Available_Make_up_Units__c != NULL 
                && bookObj.Available_Make_up_Units__c > 0){
                    bookingsToUpsert.add(new Booking__c(Id = bookObj.Id, Available_Make_up_Units__c
                     = bookObj.Available_Make_up_Units__c - bookObj.Duration__c));
                }else{*/
                    bookingListToDelete.add(new Booking__c(Id = bookObj.Id));
               // }
            }
            /*system.debug('@@processOldRegularBookings bookingsToUpsert'+bookingsToUpsert);
            if(bookingsToUpsert.size() > 0){
                UPDATE bookingsToUpsert;
            }*/
           //system.debug('@@processOldRegularBookings bookingListToDelete'+bookingListToDelete);
            if(bookingListToDelete.size() > 0){
                DELETE bookingListToDelete;
            }
        }
    } 
   
   
    
 private void processTeacherLeaves(String teacherId, Date effectiveDate, Date maxDate){
        Set<String> setOfTeachersLeaves = new Set<String>();

        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();

        Map<String, Booking__c> updatedBookingMap = new Map<String, Booking__c>(); 
        Map<String, Fifth_Lesson__c> updatedLessonMap = new Map<String, Fifth_Lesson__c>();
       //system.debug('@@@processTeacherLeaves teacherId -'+teacherId);
       //system.debug('@@@processTeacherLeaves effectiveDate -'+effectiveDate);
       //system.debug('@@@processTeacherLeaves maxDate -'+maxDate);
        if(String.isNotBlank(teacherId) && effectiveDate != NULL && maxDate != NULL){
            setOfTeachersLeaves = fetchTeacherLeavesRequestDateSet(teacherId, effectiveDate, maxDate);
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
       //system.debug('@@@@ teacher leave then cancel booking and updated booking are =='+bookingtoUpdate);
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
           //system.debug('@@ create Placeholder booking for fifth lesson  '+fifthLessonToUpdate);
            for(Fifth_Lesson__c fifthLesson : fifthLessonToUpdate){
                fifthLesson.Booking__c = fifthLesson.Booking__r.Id;
            }
            UPDATE fifthLessonToUpdate;
        }
       //system.debug('@@@upated fifth bookings are  fifthLessonToUpdate'+fifthLessonToUpdate);
        if(bookingtoUpdate.size() > 0){
            
            List<Case> caseList = AureusUtility.createCase(bookingtoUpdate);
            insert caseList;
           //system.debug('@@ inserted case for bookings are =='+caseList);
            bookingtoUpdate.addAll(createPlaceholderFromBooking(bookingtoUpdate));
            UPSERT bookingtoUpdate;
           //system.debug('@@ inserted bookingtoUpdate for bookings are =='+bookingtoUpdate);
            Set<Id> csIds = new Set<Id>();
            for(Case c : caseList)
                csIds.add(c.Id);
            AureusUtility.sendCaseEmail(csIds);
        }

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
       //system.debug('@@@ create new Placeholder for bookings =='+placeholderList);
        return placeholderList;
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
       //system.debug('@@@ inserted placeholder bookings are  ='+bookList);

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
    private Set<String> fetchTeacherLeavesRequestDateSet(String teacherId, Date effectiveDate, Date maxDate){
        Set<String> setOfTeachersLeave = new Set<String>();
        for(Leave_Request__c leaveRequest : [SELECT Id, Name, Leave_Type__c, Employee__c, Leave_Start_Date__c, Leave_End_Date__c 
                                             FROM Leave_Request__c 
                                             WHERE Employee__c = :teacherId 
                                             AND Leave_Start_Date__c >= :effectiveDate AND 
                                             Leave_Start_Date__c <= :maxDate 
                                             AND Status__c = :ConstantsClass.approvedTeacherLeave]){
            Date startDateLeave = leaveRequest.Leave_Start_Date__c;
            While(startDateLeave <= leaveRequest.Leave_End_Date__c){
                setOfTeachersLeave.add(startDateLeave + '-' + leaveRequest.Employee__c);
                startDateLeave = startDateLeave.addDays(1);
            }
        }
        //system.debug('@@@@@setOfTeachersLeave'+setOfTeachersLeave);
        return setOfTeachersLeave;
    }

    private void processPublicHolidays(Date effectiveDate, Date maxDate, String centreOrgId, Account teacherObj){
        Map<String, Public_Holiday__c> mapOfPublicLeaves = new Map<String, Public_Holiday__c>();
        List<Booking__c> bookingtoUpdate = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();

        Map<String, Booking__c> updatedBookingMap = new Map<String, Booking__c>(); 
        Map<String, Fifth_Lesson__c> updatedLessonMap = new Map<String, Fifth_Lesson__c>();
       //system.debug('@@processPublicHolidays effectiveDate'+effectiveDate);
       //system.debug('@@processPublicHolidays teacherObj'+teacherObj);
       //system.debug('@@processPublicHolidays centreOrgId'+centreOrgId);
       //system.debug('@@processPublicHolidays maxDate'+maxDate);
       //system.debug('@@processPublicHolidays teacherObj.id'+teacherObj.Id);
        if(effectiveDate != NULL && maxDate != NULL && teacherObj != NULL && String.isNotBlank(centreOrgId) && String.isNotBlank(teacherObj.Id)){
            mapOfPublicLeaves = fetchPublicHolidaysDateMap(effectiveDate, maxDate, centreOrgId, teacherObj);
        }

        for(String keySetValue : mapOfBooking.keySet()){
            if(mapOfPublicLeaves != null && mapOfPublicLeaves.size() > 0 &&
               mapOfPublicLeaves.containsKey(keySetValue) && mapOfBooking.get(keySetValue).Status__c != ConstantsClass.statusCanceled){
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
       //system.debug('@@@cancel booking for public holiday to Update'+bookingtoUpdate);

        for(String keySetValue : mapOfFifthLesson.keySet()){
            if(mapOfPublicLeaves.containsKey(keySetValue)){
                Fifth_Lesson__c lesson = mapOfFifthLesson.get(keySetValue);
                lesson.IsActive__c = FALSE;
                fifthLessonToUpdate.add(lesson);
                updatedLessonMap.put(keySetValue, lesson);
            }
        }
       //system.debug('@@@deActivate Fifth bookings '+fifthLessonToUpdate);
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
       //system.debug('@@@updated  fifthLessonToUpdate '+fifthLessonToUpdate);
        if(bookingtoUpdate.size() > 0){
            
            List<Case> caseList = AureusUtility.createCase(bookingtoUpdate);
            insert caseList;
           //system.debug('@@ create case for bookings '+caseList);
            bookingtoUpdate.addAll(createPlaceholderFromBooking(bookingtoUpdate));
            UPSERT bookingtoUpdate;
           //system.debug('@@@processPublicHolidays bookingtoUpdate '+bookingtoUpdate);
            Set<Id> csIds = new Set<Id>();
            for(Case c : caseList)
                csIds.add(c.Id);
            AureusUtility.sendCaseEmail(csIds);
        }    
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
       //system.debug('@@@ mapOfHolidaysLeave dates are ='+mapOfHolidaysLeave);
        return mapOfHolidaysLeave;
    }
}