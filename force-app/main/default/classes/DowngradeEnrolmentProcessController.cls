/*
Name        :        DowngradeEnrolmentProcessController
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        This Controller help for AureusCalendarController.
testClass:DowngradeEnrolmentProcessControllertest
*/
public without sharing class DowngradeEnrolmentProcessController implements IAdvanceAction{
    Private String bookingId;
    Private Date effectiveDate;
    Private String newPackageId;
    Private String oldPackageId;
    Private String caseRedirect;
    Private decimal amount;
    Private decimal depositAmount;
    Private decimal lessonsFees;
    Private String myCaseId;
    Private String oldTeacherId;
    Private String newTeacherId;
    Private Time timeslot;
    Private Map<String, String> mapOfCase;
    
    //Data Members for Additional Work
    Private Enrolment__c enroll;
    Private Date nextBillDate;
    Private Country__c countryObj;
    public DowngradeEnrolmentProcessController(String bookingId, String effectiveDateStr, String newPackageId, 
                                               String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                               String amount, String depositAmount, String lessonsFees, Map<String, String> caseValues,
                                               String oldTeacherId,String newTeacherId) {
                                                   this.bookingId = bookingId;
                                                   effectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(effectiveDateStr);
                                                   this.newPackageId = newPackageId;
                                                   this.oldPackageId = oldPackageId;
                                                   this.timeslot = AdvanceActionsHelper.getDateTimeFromString(timeSlot).time();
                                                   this.myCaseId = myCaseId;
                                                   this.newTeacherId = newTeacherId;
                                                   this.oldTeacherId = oldTeacherId;
                                                   this.caseRedirect =caseRedirect;
                                                   this.amount = Decimal.valueOf(amount);
                                                   this.depositAmount = Decimal.valueOf(depositAmount);
                                                   this.lessonsFees =  Decimal.valueOf(lessonsFees);
                                                   mapOfCase = new Map<String, String>();
                                                   if(caseValues != null && caseValues.size() > 0)
                                                       this.mapOfCase = caseValues;
                                                   enroll = new Enrolment__c();
                                                   countryObj = new Country__c();
                                               }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        Savepoint downgradeSavePoint;
        Boolean isSuccess = true;
        String caseIdToReturn;String enrollmentId;
        try{
            //Country__c centreCountry = new Country__c();
            Organisation__c  organisationObj = new Organisation__c();
            String studentId, teacherId, lessonDay, oldPackage, newPackage, centreId;
                                                            Integer duration, newPackageDuration; 
                                                            Time startTime, newStartTime;
            if(String.isNotBlank(bookingId)){
                enrollmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
            }
        //system.debug('@@@enrolmentObj'+enroll);
            // get old and new Package Time Differnce
            Integer timeDiff = 0;
            AdvanceActionsHelper.UpDownSummary objSummary =  AdvanceActionsHelper.getOldNewPackage(oldPackageId,newPackageId);                                         
            if(String.isNotBlank(objSummary.oldPack.Id) && String.isNotBlank(objSummary.newPack.Id)){
                timeDiff =   Integer.valueOf(objSummary.oldPack.Duration__c) - Integer.valueOf(objSummary.newPack.Duration__c);                                                
            }
        //system.debug('@@@timeDiff'+timeDiff);
            if(String.isNotBlank(enrollmentId)){
                enroll = AdvanceActionsHelper.fetchEnrolment(enrollmentId);
                
                // if(String.isNotBlank(enroll.Center__r.country__r.Id)){
                //     centreCountry = enroll.Center__r.country__r;    
                // }
                if(String.isNotBlank(enroll.Center__r.Organisation__r.Id)){
                    organisationObj = enroll.Center__r.Organisation__r;    
                }
                newPackage = newPackageId;
                studentId = enroll.Student__c;
                teacherId = enroll.Teacher__c;
                duration = Integer.valueOf(enroll.Package__r.duration__c);
                startTime = enroll.Lesson_Start_time__c;
                lessonDay = enroll.Lesson_Day__c;
                oldPackage = enroll.Package__c;
                centreId = enroll.center__c;
            }
            date nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enroll);
            // added by nishi: 22-Oct-2020: for some limited user can downgrade prepayment enrolment
            Boolean isPromotionalEnrolment=false;
            if( String.isNotBlank(enroll.Type_of_Package__c) && (enroll.Type_of_Package__c == ConstantsClass.prePaymentType
                                                                 || enroll.Type_of_Package__c == ConstantsClass.PromoTypePayment)){
                isPromotionalEnrolment= true;
            }
            // added by nishi: 22-Oct-2020: for some limited user can downgrade prepayment enrolment

            system.debug('isSuccessCreatePaymentsDowngradeProcess'+depositamount);
            if(String.isNotBlank(enrollmentId)){
                isSuccess = isSuccessCreatePaymentsDowngradeProcess(mapOfCase, enroll, effectiveDate, depositamount, lessonsFees, 
                            oldPackageId, newPackageId,newTeacherId,organisationObj,isPromotionalEnrolment);//centreCountry);
            }
        //system.debug('isSuccess'+isSuccess); 
            downgradeSavePoint = Database.setSavepoint();
            // added by nishi: 10-May-2021:start: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
            //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
            if(isPromotionalEnrolment){
                if(effectiveDate >= nextBillDate && enroll.Type_of_Package__c == ConstantsClass.PromoTypePayment){
                    map<string,Credit_Memo__c> newPendingCreditMemos = upgradeDowngradeController.createCreditMemoNextBillingDateForPromoPackage(enroll.Id,oldPackageId,effectiveDate,'Downgrade Enrolment Adjustment');
                }
            }
            // added by nishi: 10-May-2021:end: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
            //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
                
            if(isSuccess){
                if(String.isNotBlank(enrollmentId)){
                    enroll.Id = enrollmentId;
                    enroll = AdvanceActionsHelper.initEnroll(enroll);
                    enroll.New_Package_Id__c = newPackageId;
                    if(string.isNotBlank(newTeacherId)){
                        enroll.New_Teacher__c = newTeacherId;
                    }
                    
                    enroll.Package_Process_Type__c = ConstantsClass.enrollmentProcessDowngradeType;
                    if(effectiveDate != NULL){
                        enroll.Effective_Date__c = effectiveDate;
                    }
                    
                    if(enroll.Effective_Date__c != NULL){
                        enroll.Notice_Period_End_Date__c = enroll.Effective_Date__c;
                        enroll.Notice_Period_Start_Date__c = enroll.Notice_Period_End_Date__c.addDays(-30);
                    }
                    
                    if(enroll.Effective_Date__c >= nextBillDate){
                        enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;       
                    }else{
                        enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;      
                        enroll.Package__c = newPackageId;
                        if(string.isNotBlank(newTeacherId)){
                            enroll.Teacher__c = newTeacherId;
                        }
                    }
                    enroll.Next_Lesson_Start_time__c = timeslot;
                    enroll.Advance_Action_Requested_By__c = Userinfo.getUserId();
                    enroll.Package_Process_Request_Date__c = System.today();
                    
                }
                
                if(enroll != NULL){
                    Set<String> setOfMakeupBookings = new Set<String>();
                    Database.SaveResult saveResult = Database.Update(enroll, false);
                    if(!saveResult.isSuccess()){
                        isSuccess = false;
                    }else{
                        List<Enrolment__c> enrolmentList = AdvanceActionsHelper.getNextBillingDateSubscription(enroll.id);
                        if(enrolmentList.size() > 0){
                            enroll = enrolmentList[0];
                        }
                        AureusCalendarControllerHelper.processFutureBookings(enroll, 'downgrade');
                        setOfMakeupBookings = AdvanceActionsHelper.processFutureFifthLessons(enroll,  'downgrade');
                        if(setOfMakeupBookings.size() > 0){
                            AdvanceActionsHelper.AddFifthMakeupMinutesToParent(centreId, Integer.valueOf(objSummary.newPack.Duration__c), timediff, startTime, timeSlot, setOfMakeupBookings);
                        }
                        /*if(String.isNotBlank(studentId) && String.isNotBlank(teacherId) && duration > 0 && 
                            startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay) && 
                            getDateTimeFromString(timeSlot).time() != NULL && String.isNotBlank(objSummary.newPack.Duration__c) && String.isNotBlank(centreId)){
                                AureusCalendarControllerHelper.AddFifthMakeupMinutesToParent(studentId, teacherId, duration, startTime, effectiveDate, lessonDay, timediff, getDateTimeFromString(timeSlot).time(), Integer.valueOf(objSummary.newPack.Duration__c), centreId);
                            }*/

                        
                    }
                }                                                             
            }
             // 21-Oct-2020 : @@nishi  :if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
             if(isPromotionalEnrolment){
                enroll = AdvanceActionsHelper.fetchEnrolment(enrollmentId);
                enroll = AdvanceActionsHelper.updateSubscriptionNextBillDate(enroll,effectiveDate,nextBillDate);
            }
            // 21-Oct-2020 : @@nishi  End::if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
        
        //system.debug('caseRedirect'+caseRedirect); 
            if(isSuccess && caseRedirect == 'true'){
                caseIdToReturn = getCaseIdToReturn(mapOfCase,myCaseId,enrollmentId,amount,lessonsFees,depositAmount);
            }else if(!isSuccess){
                caseIdToReturn = 'error';
            }else{
                caseIdToReturn = '';
            }
        }catch (Exception e){
            caseIdToReturn = 'error';
            System.debug('@@caseIdToReturn'+e.getStackTraceString()+'-'+e.getMessage() +';');
              //On 14-Oct-2020: Nishi to Add Custom Save Points so If Error Occures we can trace that.
              Database.rollback(downgradeSavePoint);
        }
        
        return caseIdToReturn ;
    }
    
    Private Static string getCaseIdToReturn(Map<String, String> caseValues,string myCaseId,String enrollmentId,Decimal amount,Decimal lessonsFees,Decimal depositAmount){
        String caseIdToReturn;
        Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrollmentId, 'downgrade', false);
        if(amount >= 0){
            objCase.Total_Invoice_topup__c = amount;
            ObjCase.Lesson_Charge_Topup__c = math.abs(lessonsFees);
            if(caseValues.containsKey('lessonNextLessonCharge')){
                ObjCase.Lesson_Charge_Topup__c += caseValues.get('lessonNextLessonCharge') != null ? math.abs(decimal.valueOf(caseValues.get('lessonNextLessonCharge'))) : 0;    
            }
           //start: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
            // if(caseValues.containsKey('facilityFee') && Decimal.valueOf(caseValues.get('facilityFee')) != null && Decimal.valueOf(caseValues.get('facilityFee')) != 0){
            //     ObjCase.Lesson_Charge_Topup__c += Decimal.valueOf(caseValues.get('facilityFee'));
            // }
            //end: added by nishi: 17-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                            
            ObjCase.deposit_Topup__c = depositAmount;
            if(caseValues.containsKey('previousPackage')){
                objCase.Previous_Package__c = caseValues.get('previousPackage');    
            }
            if(caseValues.containsKey('newPackage')){
                objCase.New_Package__c = caseValues.get('newPackage');    
            }
             // added by nishi:start-18-Aug-2020: for manage ossia organisation new teacher
             if(caseValues.containsKey('previousTeacher')){
                objCase.Previous_teacher__c = caseValues.get('previousTeacher');     
            }
            if(caseValues.containsKey('newTeacher')){
                objCase.New_Teacher__c = caseValues.get('newTeacher');     
            }
             // added by nishi:end-19-Aug-2020: for manage ossia organisation new teacher
           
            if(caseValues.containsKey('previousLessonDayTime')){
                objCase.Previous_Lesson_Day_Time__c = caseValues.get('previousLessonDayTime');    
            }
            if(caseValues.containsKey('newLessonDayTime')){
                objCase.New_Lesson_Day_Time__c = caseValues.get('newLessonDayTime');    
            }
            if(caseValues.containsKey('currentDepositonFile')){
                objCase.Current_Deposit_on_File__c = Decimal.valueOf(caseValues.get('currentDepositonFile'));    
            }
            if(caseValues.containsKey('newPackageDeposit')){
                objCase.New_Package_Deposit__c = Decimal.valueOf(caseValues.get('newPackageDeposit'));    
            }
            if(caseValues.containsKey('invoiceForCurrentMonth')){
                objCase.Invoice_for_Current_Month__c = Decimal.valueOf(caseValues.get('invoiceForCurrentMonth'));    
            }
        }
        upsert objCase; 
       //system.debug('@@caseObj'+objCase);
        caseIdToReturn = objCase.Id;
        return caseIdToReturn;
    }
    
    private static Boolean createPaymentsForDowngradeProcess(Enrolment__c objEnrol, Date lastLessonDateObj, Date nextBillDate, Decimal depositAmount,
     Decimal lessonsAmt, Decimal positiveInvoiceAmount, Decimal negativeInvoiceAmount, String oldPackId,String newPackId,String newTeacherId, Date effectiveDate, 
     Organisation__c  organisationObj/*Country__c centreCountry*/,Map<String, String> mapOfCase,Boolean isPromotionalEnrolment ){
        Boolean isOssiaOrganization = false;
        if(string.isNotBlank(objEnrol.Center__c) && 
            string.isNotBlank(objEnrol.Center__r.Organisation__c) && string.isNotBlank(objEnrol.Center__r.Organisation__r.Name) &&
            objEnrol.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
            isOssiaOrganization = true;
        }
        // added by nishi: 19_aug-2020: for added facility fee is exist
        // Decimal facilityFee =  mapOfCase.containsKey('facilityFee') ? Decimal.valueOf(mapOfCase.get('facilityFee')) : 0;
        // Decimal negativeFacilityInvoiceAmount =  mapOfCase.containsKey('negativeFacilityInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('negativeFacilityInvoiceAmount')) : 0;
        // Decimal positiveFacilityInvoiceAmount =  mapOfCase.containsKey('positiveFacilityInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('positiveFacilityInvoiceAmount')) : 0;
        // // added by nishi: 19_aug-2020: for added facility fee is exist
        Decimal negativeInvoiceDiscountAmount =  mapOfCase.containsKey('negativeInvoiceDiscountAmount') && mapOfCase.get('negativeInvoiceDiscountAmount') != null? Decimal.valueOf(mapOfCase.get('negativeInvoiceDiscountAmount')) : 0;
        Decimal positiveNextMonthInvoiceAmount  = mapOfCase.containsKey('positiveNextMonthInvoiceAmount') && mapOfCase.get('positiveNextMonthInvoiceAmount') != null? Decimal.valueOf(mapOfCase.get('positiveNextMonthInvoiceAmount')) : 0;
        Decimal negativeNextMonthInvoiceAmount =  mapOfCase.containsKey('negativeNextMonthInvoiceAmount') && mapOfCase.get('negativeNextMonthInvoiceAmount') != null? Decimal.valueOf(mapOfCase.get('negativeNextMonthInvoiceAmount')) : 0;
        Decimal nextMonthAmount =  mapOfCase.containsKey('lessonNextLessonCharge') && mapOfCase.get('lessonNextLessonCharge') != null? Decimal.valueOf(mapOfCase.get('lessonNextLessonCharge')) : 0;
        Boolean isTransaction = false;
        List<Subscription_Line_Item__c> listSubLineItem = UpgradeDowngradeController.fetchSubsLineItems(objEnrol.Subscription_Line_Items__r[0].id);
        Subscription_Line_Item__c objSubLineItem;
        if(listSubLineItem != null && listSubLineItem.size() > 0 ){
            objSubLineItem  = listSubLineItem[0];
        }
        String stripeId;
        Invoice__c objInvoice = new Invoice__c();
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        map<string,Invoice_Line_Item__c> newinvoiceLineItems = new map<string,Invoice_Line_Item__c>();
        List<Payment__c> listOfPayments = new List<Payment__c>(); 
        // added by nishi: 6-oct-2020: for create credit memo records
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        Credit_memo_line_item__c objCreditLineItem = new  Credit_memo_line_item__c();    
        map<String,Invoice_Line_Item__c> updateInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        map<String,Invoice_Line_Item__c>  updateCreditMemoInvoiceLineItem = new map<String,Invoice_Line_Item__c> (); 
        Credit_Memo__c  objCreditMemo = new     Credit_Memo__c();
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String paymentTransaction = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
         
                    if(string.isBlank(newTeacherId)){
                        newTeacherId = objEnrol.Teacher__c;
                    }
      System.debug('nextMonthAmount'+nextMonthAmount);
      System.debug('positiveNextMonthInvoiceAmount'+positiveNextMonthInvoiceAmount);
      System.debug('negativeNextMonthInvoiceAmount'+negativeNextMonthInvoiceAmount);
      System.debug('negativeInvoiceAmount'+negativeInvoiceAmount);
      System.debug('positiveInvoiceAmount'+positiveInvoiceAmount);
      System.debug('lessonsAmt'+lessonsAmt);
      System.debug('depositAmount'+depositAmount);
        if(depositAmount > 0){
            depositAmount = BillingUtility.roundOffAmount(depositAmount);
        }
        Map<String,Decimal> parentCreditMemoTotal = new  Map<String,Decimal>();
        Map<String,List<Credit_Memo__c>> mapOfParentPrepaymentCreditMemo = new Map<String,List<Credit_Memo__c>>();
        List<Invoice__c> listOfInvoice = new List<Invoice__c>();
        if(isPromotionalEnrolment){
            listOfInvoice = UpgradeDowngradeController.getInvoiceDetails(objEnrol,lastLessonDateObj.addmonths(1),objSubLineItem) ;
            parentCreditMemoTotal =  UpgradeDowngradeController.getCreditMemoForPrepaymentInvoiceAmount(listOfInvoice, objEnrol, lastLessonDateObj);
        }
        boolean createprepayementCreditmemo = false;
        system.debug('@depositAmount'+depositAmount);
        if(depositAmount > 0 && objEnrol.Subscription_Line_Items__r.size() > 0){
            stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c; 
            decimal totalAmount = depositAmount;
            if(isPromotionalEnrolment && lastLessonDateObj < nextBillDate){
                Decimal accumulatedCreditMemoAmount =0;
                if(parentCreditMemoTotal.containsKey(objEnrol.parent__c)){
                    accumulatedCreditMemoAmount = parentCreditMemoTotal.get(objEnrol.parent__c);
                }
                if(accumulatedCreditMemoAmount != null && accumulatedCreditMemoAmount > 0 && accumulatedCreditMemoAmount < totalAmount){ 
                    totalAmount =  totalAmount - accumulatedCreditMemoAmount ;
                }
            }
            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
            //BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositAmount, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);                 
            Boolean isCreatedvoice = false;
            Boolean isChargeDepositAmount = false;
            Boolean isOssiaNonStripeCustomer = false;
        BillingUtility.StripeCharge chargeResponse;
            if(totalAmount > 0){  
                if(String.isNotBlank(stripeId)){
                    chargeResponse = BillingUtility.createChargeForCustomer(stripeId, totalAmount, organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);                 
                    if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                        isCreatedvoice = true;
                        isChargeDepositAmount=true;
                    }else{
                        if(isOssiaOrganization){
                            isCreatedvoice = true;
                        }
                    }
                }else{
                    if(isOssiaOrganization){
                        isCreatedvoice = true;
                        isOssiaNonStripeCustomer = true;
                    }
                }
            }else{
                if(isPromotionalEnrolment && lastLessonDateObj < nextBillDate){
                    isCreatedvoice = true;
                }
            }    
            if(isCreatedvoice){
                //Insert Invoice if effective date is less than next bill date and deposit amount is positive
                objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c, objSubLineItem.Subscription__r.Parent__c, constantsClass.dueStatus);
                objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
                objInvoice.Credit_Memo_Amount__c=0;
                insert objInvoice;
                    
                //add deposit invoice line item for the invoice
                Invoice_Line_Item__c inlineItemForDeposit = new Invoice_Line_Item__c();
                inlineItemForDeposit = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, objSubLineItem, depositAmount, newPackId, true, '');
                inlineItemForDeposit.Is_Deposit__c = True;
                inlineItemForDeposit.month__c = effectiveDate;
                
                //invoiceLineItems.add(inlineItemForDeposit);
                newinvoiceLineItems.put('deposit',inlineItemForDeposit);
                isTransaction = true;
                if(String.isNotBlank(objInvoice.Id)){
                        // added by nishi: 23-oct-2020: for check if enrolment has promotional then  
                        // This invoice is adjusted with a credit memo. If a credit memo adjustment amount is 
                        // less then the invoice amount then we charged via Stripe.
                    if(isPromotionalEnrolment && lastLessonDateObj < nextBillDate){
                        createprepayementCreditmemo = true;
                        mapOfParentPrepaymentCreditMemo =UpgradeDowngradeController.createCreditMemoForPrepaymentInvoice(listOfInvoice,objEnrol, lastLessonDateObj,'Downgrade Enrolment Adjustment');
                        UpgradeDowngradeController.adjustPendingCreditMemoDeposit(objEnrol,lastLessonDateObj,objInvoice.Id,mapOfParentPrepaymentCreditMemo,true);
                    }
                }
                if(String.isNotBlank(objInvoice.Id)){
                    if(isChargeDepositAmount){
                        isTransaction = true;
                        if(String.isNotBlank(objInvoice.Id)){
                            objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c,Status__C FROM Invoice__c WHERE Id =:objInvoice.Id];
                            objInvoice.Status__C = constantsClass.paidStatus;
                            update objInvoice;
                            if(!Test.isRunningTest()){
                                ////commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                                //  BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                                BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
                            }
                            Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c, objInvoice.Id, totalAmount, ConstantsClass.successStatus);
                            objPayment.Transaction_ID__c = chargeResponse.Id;
                            objPayment.recordTypeId = paymentTransaction;
                            objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                            listOfPayments.add(objPayment);
                        }
                    }
                    if(isOssiaNonStripeCustomer){
                        BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{objInvoice.Id});
                    }
                    
                }
            }
        }else if(depositAmount <= 0){
            isTransaction = true;
            
            //Invoice If the deposit amount is less than 0. Some time next dilling date is greater than effective date 
            // that time invoice line item not greated becaue that time we create no line item invioce (0 balance invoice) for manage sage 
            objInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus,
                                        Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                        Invoice_Date__c =system.today(),
                                        Parent_Account__c = objEnrol.Parent__c, 
                                        Center__c=objEnrol.Center__c,
                                        Credit_Memo_Amount__c=0
                                        );
                                        
            INSERT objInvoice;
            
             system.debug('@objInvoice'+objInvoice);
            // JATIN  25-Nov-2019 :for add transaction id in payment reocrds
            Map<String, Payment__c> mapOfInvoicePayments = new Map<String, Payment__c>();
            List<Id> invoiceIds = NEW List<Id>();
            Map<Id,Invoice_Line_Item__c> invoicemap = NEW Map<Id,Invoice_Line_Item__c>();
            for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c,Net_Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c ,Package__c,
                                                Credit_Memo_Amount__c,Credit_Memo_tax__c
                                                FROM Invoice_Line_Item__c 
                                                WHERE Enrolment__c =: objEnrol.id 
                                                AND Is_Deposit__c = true 
                                                AND Subscription_Line_Item__c != NULL]){
                                                    invoiceIds.add(lineItem.Invoice__c);
                                                    invoicemap.put(lineItem.Invoice__c,lineItem);
                                                    updateInvoiceLineItem.put(lineItem.id,lineItem);
                                                }
                for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c  ,Method_of_Payment__c 
                                        FROM Payment__c 
                                        WHERE Invoice__c In: invoiceIds AND 
                                        RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                          // if(string.isNotBlank(payment.Transaction_ID__c)){
                                                mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                            //}
                                        }
            
            if(depositAmount != 0){
                 //added by nishi: 6-Oct-2020 : start:for new requirement we Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
               /* string transactionID ='';
                if(mapOfInvoicePayments != null && mapOfInvoicePayments.size() > 0){
                    for(string invoiceId : mapOfInvoicePayments.keyset()){
                        if(mapOfInvoicePayments.containsKey(invoiceId)){
                           transactionID = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                        }
                    } 
                }
               //system.debug('@@transactionID'+transactionID);
               
                listOfPayments.add(new Payment__c(Payment_Date__c = lastLessonDateObj, 
                                                  RecordTypeId = paymentRecordTypeId, 
                                                  Transaction_ID__c = transactionID,
                                                  Payment_Amount__c = Math.abs(depositAmount), 
                                                  Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                                  Parent_Account__c = objEnrol.Parent__c, 
                                                  Enrolment__c = objEnrol.Id));   */
                Decimal creditMemodepositAmount =Math.abs(depositAmount);
                if(mapOfInvoicePayments != null && mapOfInvoicePayments.size() > 0){
                    for( string invoiceId : mapOfInvoicePayments.keyset()){
                        //26-apr-2021:Enrolments with multiple deposits meaning advancements at the time of downgrade should have a separate credit memo created for each line item that is equal to deposit. 
                        if(mapOfInvoicePayments.containsKey(invoiceId) && invoicemap.containsKey(invoiceId) && creditMemodepositAmount > 0){
                            depositAmount = (creditMemodepositAmount > invoicemap.get(invoiceId).Net_Amount__c ? //120 > 112
                                             invoicemap.get(invoiceId).Net_Amount__c :
                                             creditMemodepositAmount
                                            ); 
                            creditMemodepositAmount  =creditMemodepositAmount - invoicemap.get(invoiceId).Net_Amount__c; //120-112=8
                            objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId, 
                                                                               lastLessonDateObj,'Deposit Adjustment');
                            objCreditMemo.Credit_Memo_Date__c = lastLessonDateObj;
                            
                            objCreditMemo.Payment_Method__c =   mapOfInvoicePayments.get(invoiceId).Method_of_Payment__c; 
                            objCreditMemo.From_Invoice__c = invoiceId;
                            objCreditLineItem = BillingUtility.createCreditMemoLineRec(Math.abs(depositAmount),null,null,
                                                                                       objEnrol.id,null,'Deposit Adjustment');
                            objCreditLineItem.Package__c = invoicemap.get(invoiceId).Package__c;
                            objCreditLineItem.Invoice_Line_Item__c = invoicemap.get(invoiceId).Id;
                            objCreditLineItem.Is_Deposit__c = true;
                            objCreditLineItem.Month__c = lastLessonDateObj;
                            listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                            listOfCreditmemolineitem.add(objCreditLineItem);           
                            system.debug('objCreditLineItem'+objCreditLineItem);                                         
                            mapOfCreditmemolineitem.put('Deposit Adjustment'+invoiceId,listOfCreditmemolineitem);
                            system.debug('objCreditMemo'+objCreditMemo);  
                            newPendingCreditMemos.put('Deposit Adjustment'+invoiceId,objCreditMemo);
                            //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                            if(string.isNotBlank(invoicemap.get(invoiceId).Id)){
                                updateCreditMemoInvoiceLineItem.put(invoicemap.get(invoiceId).Id,
                                                                    updateInvoiceLineItemMap( updateInvoiceLineItem,math.abs(depositAmount),
                                                                                            0,invoicemap.get(invoiceId).Id));
                            }
                        }
                        //26-apr-2021:Enrolments with multiple deposits meaning advancements at the time of downgrade should have a separate credit memo created for each line item that is equal to deposit. 
                      
                    }
                }
                
                 //added by nishi: 6-Oct-2020 : start:for new requirement we Create a Credit Memo record with the status pending instead of the Payment as Deposit record.

               
            }
           //system.debug('@listOfPayments'+listOfPayments);
        }   
        objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c,Credit_Memo_Amount__c FROM Invoice__c WHERE Id =:objInvoice.Id];
        if(lastLessonDateObj < nextBillDate){
            // create credit memo for promotional enrolment remaining periods
            if(isPromotionalEnrolment && !createprepayementCreditmemo){
                mapOfParentPrepaymentCreditMemo =UpgradeDowngradeController.createCreditMemoForPrepaymentInvoice(listOfInvoice,objEnrol, lastLessonDateObj,'Downgrade Enrolment Adjustment');
            }
            //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                    
            Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
            Map<String,Invoice_line_item__c> mapofinvoicelineitem = new Map<String,Invoice_line_item__c>();
            for(Invoice__c invoiceobj : UpgradeDowngradeController.getInvoiceDetails(objEnrol,lastLessonDateObj,objSubLineItem)){
                if(objInvoice.id != invoiceobj.id){
                    if(isPromotionalEnrolment){
                        for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                            if(objlineitem.month__c.month() == lastLessonDateObj.month()){
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
                        //    string invoiceMonth ='';
                        //     if(invoiceobj.Invoice_Date__c.month() == lastLessonDateObj.month())
                        //         invoiceMonth = 'Current';
                        //     if(nextBillDate >= nextMonthDate && lastLessonDateObj.month() < nextMonthDate.addMonths(-1).month() && invoiceobj.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() )
                        //         invoiceMonth = 'Next Month';
                        //     system.debug('invoiceMonth'+invoiceMonth);
                        //     if(string.isnotBlank(invoiceMonth)){
                        //         mapofinvoice.put(invoiceMonth,invoiceobj);
                                for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                                    string invoiceMonth ='';
                                    if(objlineitem.month__c.month() == effectiveDate.month())
                                        invoiceMonth = 'Current';
                                    if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && objlineitem.month__c.month() == nextMonthDate.addMonths(-1).month() )
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
            }
            //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
            String invoiceId = null;
            if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                if(mapofinvoice.containskey('Current')){
                    invoiceId = mapofinvoice.get('Current').id;
                }
            }
            objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  system.today(),'Downgrade Enrolment Adjustment');
            objCreditMemo.Status__c = ConstantsClass.creditMemoSuccessStatus;
            objCreditMemo.Invoice_Number__c = objInvoice.Id;
            
            newPendingCreditMemos.put('Downgrade Enrolment Adjustment',objCreditMemo);
            system.debug('objCreditMemo'+objCreditMemo);    
            listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
           
            //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
            
            decimal gstAmount = 0;
            if( string.isNotBlank(objEnrol.Center__c) && string.isNotBlank(objEnrol.Center__r.Country__c) &&
            objEnrol.Center__r.Country__r.Tax_Rate__c != null ){
                gstAmount = BillingUtility.roundOffAmount(objEnrol.Center__r.Country__r.Tax_Rate__c);
            }
           
            
            decimal positiveInvoiceAmountGST =0;
            decimal negativeInvoiceAmountGST =0;
            decimal positiveFacilityInvoiceAmountGST =0;
            decimal negativeFacilityInvoiceAmountGST =0;
            decimal positiveNextMonthInvoiceAmountGST =0;
            decimal negativeNextMonthInvoiceAmountGST =0;
            // 8-jan-2020: jatin for add Balanced invoices
            decimal balancedInvoice =0;
            decimal balancedInvoiceGST = 0;
            decimal balancedInvoiceNextMonth =0;
            decimal balancedInvoiceNextMonthGST = 0;
            if(positiveInvoiceAmount != NULL && negativeInvoiceAmount != NULL && String.isNotBlank(objInvoice.Id)){
                if(positiveInvoiceAmount != NULL && gstAmount > 0){
                     positiveInvoiceAmountGST  = (BillingUtility.roundOffAmount(positiveInvoiceAmount) * gstAmount) /100;
                }
                if(negativeInvoiceAmount != NULL  && gstAmount > 0){
                     negativeInvoiceAmountGST  = (BillingUtility.roundOffAmount(negativeInvoiceAmount) * gstAmount) /100;
                }
                // 8-jan-2020: jatin for add Balanced invoices
                if(BillingUtility.roundOffAmount(positiveInvoiceAmount) > math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount))){ 
                    balancedInvoice = -(BillingUtility.roundOffAmount(positiveInvoiceAmount) - math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)));
                }if( math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) > BillingUtility.roundOffAmount(positiveInvoiceAmount)){
                    balancedInvoice =  math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) - BillingUtility.roundOffAmount(positiveInvoiceAmount);
                }
                if(balancedInvoice != NULL  && balancedInvoice != 0 && gstAmount > 0){
                    balancedInvoiceGST  = (BillingUtility.roundOffAmount(balancedInvoice) * gstAmount) /100;
                }
                // 8-jan-2020: jatin for add Balanced invoices
              //System.debug('@@@balancedInvoice'+balancedInvoice);
               // start:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
               
               
                

                // added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                // if(positiveFacilityInvoiceAmount != NULL && positiveFacilityInvoiceAmount != 0 && negativeFacilityInvoiceAmount != NULL && negativeFacilityInvoiceAmount != 0){
                //     if(positiveFacilityInvoiceAmount != NULL && gstAmount > 0){
                //         positiveFacilityInvoiceAmountGST  = (BillingUtility.roundOffAmount(positiveFacilityInvoiceAmount) * gstAmount) /100;
                //    }
                //    if(negativeFacilityInvoiceAmount != NULL  && gstAmount > 0){
                //          negativeFacilityInvoiceAmountGST  = (BillingUtility.roundOffAmount(negativeFacilityInvoiceAmount) * gstAmount) /100;
                //    }
                //     //Line Item for positive amount
                //    //system.debug('@positiveFacilityInvoiceAmountGST'+positiveFacilityInvoiceAmountGST);
                //    //system.debug('@negativeFacilityInvoiceAmountGST'+negativeFacilityInvoiceAmountGST);
                //     invoiceLineItems.add(new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(positiveFacilityInvoiceAmount), 
                //                         GST_Amount__c = positiveFacilityInvoiceAmountGST,Remarks__c='Facility Fee Positive Amount',
                //                         Teacher_Id__c = newTeacherId,Package__c=newPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));

                //         //Line Item for negative amount.

                //     invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(negativeFacilityInvoiceAmount), 
                //                             GST_Amount__c = negativeFacilityInvoiceAmountGST,Remarks__c='Facility Fee Negative Amount',
                //                             Teacher_Id__c = objEnrol.Teacher__c,Package__c=oldPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));

                // }
                 // added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice

                 // added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                if(positiveNextMonthInvoiceAmount != NULL && positiveNextMonthInvoiceAmount != 0 && negativeNextMonthInvoiceAmount != NULL && negativeNextMonthInvoiceAmount != 0){
                    if(positiveNextMonthInvoiceAmount != NULL && gstAmount > 0){
                        positiveNextMonthInvoiceAmountGST  = (BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount) * gstAmount) /100;
                   }
                   if(negativeNextMonthInvoiceAmount != NULL  && gstAmount > 0){
                     negativeNextMonthInvoiceAmountGST  = (BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount) * gstAmount) /100;
                   }
                   // 8-jan-2020: jatin for add Balanced invoices
                   if(BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount) > math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount))){
                        balancedInvoiceNextMonth = -(BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount) - math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)));
                    }if( math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)) > BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount)){
                        balancedInvoiceNextMonth +=  math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)) - BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount);
                    }
                    if(balancedInvoiceNextMonth != NULL  && balancedInvoiceNextMonth != 0 && gstAmount > 0){
                        balancedInvoiceNextMonthGST  = (BillingUtility.roundOffAmount(balancedInvoiceNextMonth) * gstAmount) /100;
                    }
                    // 8-jan-2020: jatin for add Balanced invoices
                    
                    //Line Item for positive amount
                  //System.debug('@positiveFacilityInvoiceAmountGST'+positiveFacilityInvoiceAmountGST);
                  //System.debug('@negativeFacilityInvoiceAmountGST'+negativeFacilityInvoiceAmountGST);
                  Invoice_Line_Item__c objinvoiceLineItem  = new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount), 
                                                            GST_Amount__c = positiveNextMonthInvoiceAmountGST,
                                                            Teacher_Id__c = newTeacherId,Package__c=newPackId,Month__c= nextMonthDate.addMonths(-1), 
                                                            Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id);
                                                   
                    //invoiceLineItems.add(objinvoiceLineItem);
                    newinvoiceLineItems.put((nextMonthDate.addMonths(-1)+'-'+objInvoice.id),objinvoiceLineItem);
                        //Line Item for negative amount.
                   //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                    /*invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount), 
                                            GST_Amount__c = negativeNextMonthInvoiceAmountGST,
                                            Teacher_Id__c = objEnrol.Teacher__c,Package__c=oldPackId,Month__c= nextMonthDate.addMonths(-1), 
                                            Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
                    */
                    String invoicelineitemId = null;
                    if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                        if(mapofinvoice.containskey('Next Month')){
                            if(mapofinvoice.get('Next Month').Invoice_Line_Items__r != null && mapofinvoice.get('Next Month').Invoice_Line_Items__r.size()>0){
                                invoicelineitemId =mapofinvoice.get('Next Month').Invoice_Line_Items__r[0].id; 
                            }
                        }
                    }
                    decimal negativeNextMonthInvoiceAmountAdjustement = 0;
                    decimal negativeNextMonthInvoiceAmountAdjustementGST = 0;
                    if( math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)) > BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount)){
                        negativeNextMonthInvoiceAmountAdjustement =  BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount);
                        negativeNextMonthInvoiceAmountAdjustementGST = BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmountGST);
                    }
                    objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(math.abs(negativeNextMonthInvoiceAmountAdjustement)),
                                                    math.abs(negativeNextMonthInvoiceAmountAdjustementGST),oldPackId,
                                                    objEnrol.id,invoicelineitemId,'',nextMonthDate.addMonths(-1));
                                                    objInvoice.Credit_Memo_Amount__c += (math.abs(negativeNextMonthInvoiceAmountAdjustement) + math.abs(negativeNextMonthInvoiceAmountAdjustementGST));
                    listOfCreditmemolineitem.add(objCreditLineItem);                                      
                    mapOfCreditmemolineitem.put('Downgrade Enrolment Adjustment',listOfCreditmemolineitem);  
                    system.debug('listOfCreditmemolineitem'+listOfCreditmemolineitem);      
                    //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.   
                    
                    
                    //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                    if(string.isNotBlank(invoicelineitemId) ){
                        updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,math.abs(negativeNextMonthInvoiceAmount),
                         math.abs(negativeNextMonthInvoiceAmountGST),invoicelineitemId));
                    }

                }
                 // added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice

                //Line Item for positive amount
                Invoice_Line_Item__c objinvoiceLineItem =  new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(positiveInvoiceAmount), 
                                        GST_Amount__c = positiveInvoiceAmountGST,
                                        Teacher_Id__c = objEnrol.Teacher__c,Package__c=newPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id);
                //invoiceLineItems.add(objinvoiceLineItem);
                
                newinvoiceLineItems.put(effectiveDate+'-'+objInvoice.id,objinvoiceLineItem);
                //Line Item for negative amount.
                /* //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                  
                invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(negativeInvoiceAmount), 
                                                               GST_Amount__c = negativeInvoiceAmountGST,
                                                              Teacher_Id__c = objEnrol.Teacher__c,Package__c=oldPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
               
                */
                String invoicelineitemId = null;
                if(isPromotionalEnrolment && mapofinvoicelineitem.containskey('Current')){
                    invoicelineitemId =mapofinvoicelineitem.get('Current').id; 
                }else{
                    if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                        if(mapofinvoice.containskey('Current')){
                            if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                                invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                            }
                        }
                    }
                }
                decimal negativeInvoiceAmountAdjustement = 0;
                decimal negativeInvoiceAmountAdjustementGST = 0;
                if( math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) > BillingUtility.roundOffAmount(positiveInvoiceAmount)){
                    negativeInvoiceAmountAdjustement =  BillingUtility.roundOffAmount(positiveInvoiceAmount);
                    negativeInvoiceAmountAdjustementGST = BillingUtility.roundOffAmount(positiveInvoiceAmountGST);
                }
                objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(math.abs(negativeInvoiceAmountAdjustement)),
                                                math.abs(negativeInvoiceAmountAdjustementGST),oldPackId,
                                                objEnrol.id,invoicelineitemId,'',effectiveDate);
                                                objInvoice.Credit_Memo_Amount__c += (math.abs(negativeInvoiceAmountAdjustement) + math.abs(negativeInvoiceAmountAdjustementGST));
                listOfCreditmemolineitem.add(objCreditLineItem);     
                system.debug('objCreditLineItem'+objCreditLineItem);                                        
                mapOfCreditmemolineitem.put('Downgrade Enrolment Adjustment',listOfCreditmemolineitem);      
                //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record. 

                
                //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                if(string.isNotBlank(invoicelineitemId) ){
                    updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,math.abs(negativeInvoiceAmount),
                    math.abs(negativeInvoiceAmountGST),invoicelineitemId));
                }


                 
               //start: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                // if(facilityFee  != null && facilityFee != 0){
                //     lessonsAmt+=facilityFee;
                // }
                 //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                //added by nishi: 6-Oct-2020 :end: Create a Credit Memo record with the status pending instead of the Payment as Credit record for the remaining lessons.   
               //System.debug('lessonsAmt'+lessonsAmt);
                 //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                /* listOfPayments.add(new Payment__c(RecordTypeId = payAsCredit, Payment_Amount__c = BillingUtility.roundOffAmount(lessonsAmt), Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                                  
                                                  Parent_Account__c = objEnrol.Parent__c, Payment_Date__c = lastLessonDateObj));
                                                  */
                

                
                
                invoiceId = null;
                invoicelineitemId = null;
                string nextMonthinvoicelineitemId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                    if(mapofinvoice.containskey('Current')){
                        invoiceId = mapofinvoice.get('Current').id;
                        if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                            invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                        }
                    }
                    if(mapofinvoice.containskey('Next Month')){
                        if(mapofinvoice.get('Next Month').Invoice_Line_Items__r != null && mapofinvoice.get('Next Month').Invoice_Line_Items__r.size()>0){
                            nextMonthinvoicelineitemId =mapofinvoice.get('Next Month').Invoice_Line_Items__r[0].id; 
                        }
                    }
                }
                objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,lastLessonDateObj,'Remaining Lessons Adjustment');
                newPendingCreditMemos.put('Remaining Lessons Adjustment',objCreditMemo);
                system.debug('objCreditMemo'+objCreditMemo);
                listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                //start: added by nishi: 23-Aug-2020: for now user also can change enrolment process which type of package is promo and prepayment then we manage discount amount
                if(isPromotionalEnrolment && negativeInvoiceDiscountAmount != null && negativeInvoiceDiscountAmount !=0){
                    lessonsAmt +=negativeInvoiceDiscountAmount;
                    String discountlineitemId = null;
                    if(isPromotionalEnrolment && mapofinvoicelineitem.containskey('DiscountInvoice')){
                        discountlineitemId =mapofinvoicelineitem.get('DiscountInvoice').id; 
                    }
                    decimal negativeInvoiceDiscountAmountGST = 0;
                    if(negativeInvoiceDiscountAmount != NULL  && gstAmount > 0){
                        negativeInvoiceDiscountAmountGST =negativeInvoiceDiscountAmount * gstAmount/(100+gstAmount); 
                    }
                    objCreditLineItem = BillingUtility.createCreditMemoLineRec(-BillingUtility.roundOffAmount(negativeInvoiceDiscountAmount - BillingUtility.roundOffAmount(negativeInvoiceDiscountAmountGST)),
                                                    -(negativeInvoiceDiscountAmountGST),oldPackId,
                                                    objEnrol.id,discountlineitemId,'Remaining Lessons Adjustment',lastLessonDateObj);
                                                    objCreditLineItem.Is_Discount__c = true;                                                    
                    listOfCreditmemolineitem.add(objCreditLineItem);     
                    if(string.isNotBlank(discountlineitemId) ){
                        updateCreditMemoInvoiceLineItem.put(discountlineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,(-BillingUtility.roundOffAmount(negativeInvoiceDiscountAmount - BillingUtility.roundOffAmount(negativeInvoiceDiscountAmountGST))),
                        (-negativeInvoiceDiscountAmountGST),discountlineitemId));
                    }
                }
                //start: added by nishi: 23-Aug-2020: for now user also can change enrolment process which type of package is promo and prepayment then we manage discount amount
                Decimal taxAmount = 0;
                if(lessonsAmt != null && lessonsAmt !=0){
                    if(gstAmount != null && gstAmount != 0){
                        taxAmount =lessonsAmt * gstAmount/(100+gstAmount); 
                    }
                    objCreditLineItem = BillingUtility.createCreditMemoLineRec(lessonsAmt - BillingUtility.roundOffAmount(taxAmount),
                                                    BillingUtility.roundOffAmount(taxAmount),oldPackId,
                                                    objEnrol.id,invoicelineitemId,'Remaining Lessons Adjustment',lastLessonDateObj);
                    listOfCreditmemolineitem.add(objCreditLineItem); 
                    if(string.isNotBlank(invoicelineitemId) ){
                        updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,(lessonsAmt - BillingUtility.roundOffAmount(taxAmount)),
                        BillingUtility.roundOffAmount(taxAmount),invoicelineitemId));
                    }
                }
                taxAmount =0;    
                if(nextMonthAmount  != null && nextMonthAmount != 0){
                    if(gstAmount != null && gstAmount != 0){
                        taxAmount =nextMonthAmount * gstAmount/(100+gstAmount); 
                    }
                    objCreditLineItem = BillingUtility.createCreditMemoLineRec(nextMonthAmount - BillingUtility.roundOffAmount(taxAmount),
                                            BillingUtility.roundOffAmount(taxAmount),oldPackId,
                                            objEnrol.id,nextMonthinvoicelineitemId,'Remaining Lessons Adjustment',nextMonthDate.addMonths(-1));
                    listOfCreditmemolineitem.add(objCreditLineItem); 
                    if(string.isNotBlank(nextMonthinvoicelineitemId) ){
                        updateCreditMemoInvoiceLineItem.put(nextMonthinvoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,math.abs(nextMonthAmount - BillingUtility.roundOffAmount(taxAmount)),
                        math.abs(taxAmount),nextMonthinvoicelineitemId));
                    }
                }

                
                
                         
                system.debug('objCreditLineItem'+objCreditLineItem);                        
                mapOfCreditmemolineitem.put('Remaining Lessons Adjustment',listOfCreditmemolineitem);
                    //added by nishi: 6-Oct-2020 :end: Create a Credit Memo record with the status pending instead of the Payment as Credit record for the remaining lessons.                                                      
                                                               
                
                 //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                // start:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
            //    if(positiveFacilityInvoiceAmount != NULL && positiveFacilityInvoiceAmount != 0 && negativeFacilityInvoiceAmount != NULL && negativeFacilityInvoiceAmount != 0){
            //         if(BillingUtility.roundOffAmount(positiveFacilityInvoiceAmount) > math.abs(BillingUtility.roundOffAmount(negativeFacilityInvoiceAmount))){
            //             balancedInvoice += -(BillingUtility.roundOffAmount(positiveFacilityInvoiceAmount) - math.abs(BillingUtility.roundOffAmount(negativeFacilityInvoiceAmount)));
            //         }if( math.abs(BillingUtility.roundOffAmount(negativeFacilityInvoiceAmount)) > BillingUtility.roundOffAmount(positiveFacilityInvoiceAmount)){
            //             balancedInvoice +=  math.abs(BillingUtility.roundOffAmount(negativeFacilityInvoiceAmount)) - BillingUtility.roundOffAmount(positiveFacilityInvoiceAmount);
            //         }
            //     }
                 //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
              //System.debug('@@@balancedInvoice'+balancedInvoice);
               /* if(balancedInvoice != NULL && balancedInvoice != 0){
                    /*Commented by nishi: 15-oct-2020: according to the new requirement we create one pending credit memo insteds of Credit Note Adjustment
                    invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,
                                            Amount__c = BillingUtility.roundOffAmount(balancedInvoice), 
                                            GST_Amount__c = balancedInvoiceGST,
                                            Month__c= effectiveDate, 
                                            Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id,
                                            Remarks__c ='Credit Note Adjustment'));
                     invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,
                                            Amount__c = BillingUtility.roundOffAmount(balancedInvoiceNextMonth), 
                                            GST_Amount__c = balancedInvoiceNextMonthGST,
                                            Month__c= nextMonthDate.addMonths(-1), 
                                            Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id,
                                            Remarks__c ='Credit Note Adjustment'));*-/
                     invoiceId = null;
                     invoicelineitemId = null;
                     nextMonthinvoicelineitemId = null;
                    if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                        if(mapofinvoice.containskey('Current')){
                            invoiceId = mapofinvoice.get('Current').id;
                            if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                                invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                            }
                        }
                        if(mapofinvoice.containskey('Next Month')){
                            if(mapofinvoice.get('Next Month').Invoice_Line_Items__r != null && mapofinvoice.get('Next Month').Invoice_Line_Items__r.size()>0){
                                nextMonthinvoicelineitemId =mapofinvoice.get('Next Month').Invoice_Line_Items__r[0].id; 
                            }
                        }
                        
                    }
                              
                    objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,effectiveDate,'Credit Note Adjustment');
                    newPendingCreditMemos.put('Credit Note Adjustment',objCreditMemo);
                    system.debug('objCreditMemo'+objCreditMemo);
                    listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                    string remark= 'Credit Note Adjustment '+ String.valueOf(math.abs(negativeInvoiceAmount)) +' adjusted with the final invoice to the extent of '+String.valueOf(positiveInvoiceAmount)+' and balance '+String.valueOf(math.abs(balancedInvoice))+' become pending deposit.';
                   
                    objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(balancedInvoice),
                                                    balancedInvoiceGST,newPackId,
                                                    objEnrol.id,invoicelineitemId,remark);
                                                    objCreditLineItem.Month__c = effectiveDate;
                    listOfCreditmemolineitem.add(objCreditLineItem);
                    if(balancedInvoiceNextMonth != NULL && balancedInvoiceNextMonth != 0){
                        remark= 'Credit Note Adjustment '+ String.valueOf(math.abs(negativeNextMonthInvoiceAmount)) +' adjusted with the final invoice to the extent of '+String.valueOf(positiveNextMonthInvoiceAmount)+' and balance '+String.valueOf(math.abs(balancedInvoiceNextMonth))+' become pending deposit.';
                    
                        objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(balancedInvoiceNextMonth),
                                                balancedInvoiceNextMonthGST,newPackId,objEnrol.id,nextMonthinvoicelineitemId,remark);
                                                objCreditLineItem.Month__c = nextMonthDate.addMonths(-1);
                                                                                    
                        listOfCreditmemolineitem.add(objCreditLineItem);  
                                       
                    }   
                    mapOfCreditmemolineitem.put('Credit Note Adjustment',listOfCreditmemolineitem); 
                }   */    
               
                
            }
           

           
            
        }
        
        /*if(invoiceLineItems.size() > 0){
            insert invoiceLineItems;
        }
      System.debug('@@@invoiceLineItems'+invoiceLineItems);
       */
        if(newinvoiceLineItems.size() > 0){
            insert newinvoiceLineItems.values();
        }
        System.debug('@@@newinvoiceLineItems'+newinvoiceLineItems);
        if(String.isNotBlank(objInvoice.id) && isTransaction){
            SageIntacctIntegrationUtility.changeEnrolment(objInvoice.Id);
            BillingUtility.createAttachment(new Set<String> {objInvoice.id});
        }  
       System.debug('@@@listOfPayments'+listOfPayments);
        if(listOfPayments.size() > 0){
             insert listOfPayments;
        }
        //added by nishi: 6-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
        if(newPendingCreditMemos.size() > 0){
            update objInvoice;
            Insert newPendingCreditMemos.values();  
           system.debug('newPendingCreditMemos'+newPendingCreditMemos);
           system.debug('mapOfCreditmemolineitem'+mapOfCreditmemolineitem);
           List<Credit_memo_line_item__c> listOfnewCreditmemolineitem = new list<Credit_memo_line_item__c>();
            for(string creditMemoRemark : newPendingCreditMemos.keyset()){
                if(mapOfCreditmemolineitem.containskey(creditMemoRemark)){
                    for(Credit_memo_line_item__c creditLineItemobj: mapOfCreditmemolineitem.get(creditMemoRemark)){
                        creditLineItemobj.Credit_Memo_Number__c = newPendingCreditMemos.get(creditMemoRemark).id;
                        listOfnewCreditmemolineitem.add(creditLineItemobj);
                    }
                }
            } 
            if(listOfnewCreditmemolineitem != null && listOfnewCreditmemolineitem.size() > 0){
                insert listOfnewCreditmemolineitem;
            }
                                       
        }
         //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
       
         if(updateCreditMemoInvoiceLineItem != null && updateCreditMemoInvoiceLineItem.size() > 0){
            update updateCreditMemoInvoiceLineItem.values();
        }

         system.debug('@@@updateCreditMemoInvoiceLineItem'+updateCreditMemoInvoiceLineItem);
       //system.debug('@@@isTransaction'+isTransaction);
        return isTransaction;
        
    }

    public static  Invoice_Line_Item__c updateInvoiceLineItemMap(Map<string,Invoice_Line_Item__c> updateInvoiceLineItem,decimal amount,decimal tax,string invoicelineitemId){
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
   
    
    private Static Boolean isSuccessCreatePaymentsDowngradeProcess(Map<String, String> mapOfCase,Enrolment__c enrolmentObj,
    Date effectiveDate, Decimal depositamount,Decimal lessonsFees,Id oldPackageId,Id newPackageId ,string newTeacherId,Organisation__c  organisationObj/*Country__c centreCountry*/,Boolean isPromotionalEnrolment){
        
        Decimal positiveAmt  = mapOfCase.containsKey('positiveInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('positiveInvoiceAmount')) : 0;
        Decimal negativeAmt =  mapOfCase.containsKey('negativeInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('negativeInvoiceAmount')) : 0;
        /*start:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
        if(centreCountry != null && String.isNotBlank(centreCountry.Id)
           && String.isNotBlank(centreCountry.Currency_Code__c) 
           && String.isNotBlank(centreCountry.Stripe_Base_Url__c) 
           && String.isNotBlank(centreCountry.Stripe_Secret_Key__c) 
           && effectiveDate != NULL && enrolmentObj.Subscription_Line_Items__r != null && 
           enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c != null){
              //system.debug('@@@enrolmentObj.Center__r.country__r'+enrolmentObj.Center__r.country__r);
               return createPaymentsForDowngradeProcess(enrolmentObj, effectiveDate, enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c,
                                                        depositamount, lessonsFees, positiveAmt,negativeAmt, oldPackageId,newPackageId, newTeacherId,
                                                        effectiveDate,centreCountry,mapOfCase);    
           }
           end:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
           if(organisationObj != null && String.isNotBlank(organisationObj.Id)
           && String.isNotBlank(organisationObj.country__r.Currency_Code__c) 
           && String.isNotBlank(organisationObj.Stripe_Base_Url__c) 
           && String.isNotBlank(organisationObj.Stripe_Secret_Key__c) 
           && effectiveDate != NULL && enrolmentObj.Subscription_Line_Items__r != null && 
           enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c != null){
              //system.debug('@@@enrolmentObj.Center__r.country__r'+enrolmentObj.Center__r.country__r);
               return createPaymentsForDowngradeProcess(enrolmentObj, effectiveDate, enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c,
                                                        depositamount, lessonsFees, positiveAmt,negativeAmt, oldPackageId,newPackageId, newTeacherId,
                                                        effectiveDate,organisationObj,mapOfCase,isPromotionalEnrolment);    
           }
        return false;    
    }
    
    
    /*Private Static Boolean updatedEnrollment(Enrolment__c enroll,Date effectiveDate,String newPackageId,String centreId,AdvanceActionsHelper.UpDownSummary objSummary,Time startTime, Time timeSlot,Integer timediff, boolean isSuccess){
        if(String.isNotBlank(enroll.id)){
           //system.debug('@@enroll.id'+enroll.id);
            enroll = AdvanceActionsHelper.getUpdatedEnrollmentFields(enroll.Id,ConstantsClass.enrollmentProcessDowngradeType,
                    effectiveDate.addDays(-30),effectiveDate,newPackageId,timeSlot);
           //system.debug('@@enroll'+enroll);
        }
        
        if(enroll != NULL){
            Set<String> setOfMakeupBookings = new Set<String>();
            Database.SaveResult saveResult = Database.Update(enroll, false);
            if(!saveResult.isSuccess()){
                return false;
            }else{
                enroll = AdvanceActionsHelper.fetchEnrolment(enroll.id);
                AureusCalendarControllerHelper.processFutureBookings(enroll, 'downgrade');
                setOfMakeupBookings = AdvanceActionsHelper.processFutureFifthLessons(enroll,  'downgrade');
                if(setOfMakeupBookings.size() > 0){
                    AdvanceActionsHelper.AddFifthMakeupMinutesToParent(centreId, Integer.valueOf(objSummary.newPack.Duration__c), timediff, startTime, timeSlot, setOfMakeupBookings);
                }
                /*if(String.isNotBlank(studentId) && String.isNotBlank(teacherId) && duration > 0 && 
                    startTime != NULL && effectiveDate != NULL && String.isNotBlank(lessonDay) && 
                    getDateTimeFromString(timeSlot).time() != NULL && String.isNotBlank(objSummary.newPack.Duration__c) && String.isNotBlank(centreId)){
                    AureusCalendarControllerHelper.AddFifthMakeupMinutesToParent(studentId, teacherId, duration, startTime, effectiveDate, lessonDay, timediff, getDateTimeFromString(timeSlot).time(), Integer.valueOf(objSummary.newPack.Duration__c), centreId);
                    }
                return true;   
            }
        } 
        return isSuccess; 
    }*/
    
}