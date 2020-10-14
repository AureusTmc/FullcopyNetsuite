/*
Name        :        DowngradeEnrolmentProcessController
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        This Controller help for AureusCalendarController.
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
            downgradeSavePoint = Database.setSavepoint();
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
            system.debug('isSuccessCreatePaymentsDowngradeProcess'+depositamount);
            if(String.isNotBlank(enrollmentId)){
                isSuccess = isSuccessCreatePaymentsDowngradeProcess(mapOfCase, enroll, effectiveDate, depositamount, lessonsFees, 
                            oldPackageId, newPackageId,newTeacherId,organisationObj);//centreCountry);
            }
        //system.debug('isSuccess'+isSuccess); 

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
                    date nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enroll);
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
        //system.debug('caseRedirect'+caseRedirect); 
            if(isSuccess && caseRedirect == 'true'){
                caseIdToReturn = getCaseIdToReturn(mapOfCase,myCaseId,enrollmentId,amount,lessonsFees,depositAmount);
            }else if(!isSuccess){
                caseIdToReturn = 'error';
            }else{
                caseIdToReturn = '';
            }
        }catch (Exception e){
            //On 14-Oct-2020: Nishi to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(downgradeSavePoint);
            caseIdToReturn  += e.getStackTraceString()+'-'+e.getMessage() +';';
            System.debug('@@caseIdToReturn'+caseIdToReturn);
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
                ObjCase.Lesson_Charge_Topup__c += math.abs(decimal.valueOf(caseValues.get('lessonNextLessonCharge')));    
            }
            ObjCase.Lesson_Charge_Topup__c = math.abs(lessonsFees);
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
     Organisation__c  organisationObj/*Country__c centreCountry*/,Map<String, String> mapOfCase ){
         
        // added by nishi: 19_aug-2020: for added facility fee is exist
        // Decimal facilityFee =  mapOfCase.containsKey('facilityFee') ? Decimal.valueOf(mapOfCase.get('facilityFee')) : 0;
        // Decimal negativeFacilityInvoiceAmount =  mapOfCase.containsKey('negativeFacilityInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('negativeFacilityInvoiceAmount')) : 0;
        // Decimal positiveFacilityInvoiceAmount =  mapOfCase.containsKey('positiveFacilityInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('positiveFacilityInvoiceAmount')) : 0;
        // // added by nishi: 19_aug-2020: for added facility fee is exist
        Decimal positiveNextMonthInvoiceAmount  = mapOfCase.containsKey('positiveNextMonthInvoiceAmount') && mapOfCase.get('positiveNextMonthInvoiceAmount') != null? Decimal.valueOf(mapOfCase.get('positiveNextMonthInvoiceAmount')) : 0;
        Decimal negativeNextMonthInvoiceAmount =  mapOfCase.containsKey('negativeNextMonthInvoiceAmount') && mapOfCase.get('negativeNextMonthInvoiceAmount') != null? Decimal.valueOf(mapOfCase.get('negativeNextMonthInvoiceAmount')) : 0;
        Decimal nextMonthAmount =  mapOfCase.containsKey('lessonNextLessonCharge') && mapOfCase.get('lessonNextLessonCharge') != null? Decimal.valueOf(mapOfCase.get('lessonNextLessonCharge')) : 0;
        Boolean isTransaction = false;
        Subscription_Line_Item__c objSubLineItem;
        String stripeId;
        Invoice__c objInvoice = new Invoice__c();
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        List<Payment__c> listOfPayments = new List<Payment__c>(); 
        // added by nishi: 6-oct-2020: for create credit memo records
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        Credit_memo_line_item__c objCreditLineItem = new  Credit_memo_line_item__c();    
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
       //system.debug('@depositAmount'+depositAmount);
        if(depositAmount > 0 && objEnrol.Subscription_Line_Items__r.size() > 0){
            
            objSubLineItem = objEnrol.Subscription_Line_Items__r[0];
            stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c; 
            if(String.isNotBlank(stripeId)){
               //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                //BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositAmount, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);                 
                
                BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositAmount, organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);                 
                if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                    isTransaction = true;
                    
                    //Insert Invoice if effective date is less than next bill date and deposit amount is positive
                    objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c, objSubLineItem.Subscription__r.Parent__c, constantsClass.paidStatus);
                    objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
                    insert objInvoice;
                    
                    //add deposit invoice line item for the invoice
                    Invoice_Line_Item__c inlineItemForDeposit = new Invoice_Line_Item__c();
                    inlineItemForDeposit = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, objSubLineItem, depositAmount, newPackId, true, '');
                    inlineItemForDeposit.Is_Deposit__c = True;
                    inlineItemForDeposit.month__c = effectiveDate;
                    
                    invoiceLineItems.add(inlineItemForDeposit);
                    
                    if(String.isNotBlank(objInvoice.Id)){
                        objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                        if(!Test.isRunningTest()){
                            ////commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                            //  BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                            BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
                        }
                        Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c, objInvoice.Id, depositAmount, ConstantsClass.successStatus);
                        objPayment.Transaction_ID__c = chargeResponse.Id;
                        objPayment.recordTypeId = paymentTransaction;
                        objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                        listOfPayments.add(objPayment);
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
            for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c ,Package__c
                                                FROM Invoice_Line_Item__c 
                                                WHERE Enrolment__c =: objEnrol.id 
                                                AND Is_Deposit__c = true 
                                                AND Subscription_Line_Item__c != NULL]){
                                                    invoiceIds.add(lineItem.Invoice__c);
                                                    invoicemap.put(lineItem.Invoice__c,lineItem);
                                                }
                for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c  ,Method_of_Payment__c 
                                        FROM Payment__c 
                                        WHERE Invoice__c In: invoiceIds AND 
                                        RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                           if(string.isNotBlank(payment.Transaction_ID__c)){
                                                mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                            }
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
                objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, null,  lastLessonDateObj,'Deposit Adjustment');
                objCreditMemo.Credit_Memo_Date__c = lastLessonDateObj;
                if(mapOfInvoicePayments != null && mapOfInvoicePayments.size() > 0){
                    for( string invoiceId : mapOfInvoicePayments.keyset()){
                        if(mapOfInvoicePayments.containsKey(invoiceId)){
                            objCreditMemo.Payment_Method__c =   mapOfInvoicePayments.get(invoiceId).Method_of_Payment__c; 
                            objCreditMemo.From_Invoice__c = invoiceId;
                            objCreditLineItem = BillingUtility.createCreditMemoLineRec(Math.abs(depositAmount),null,invoicemap.get(invoiceId).Package__c,
                                                            objEnrol.id,invoicemap.get(invoiceId).Id,'Deposit Adjustment');
                                                            objCreditLineItem.Is_Deposit__c = true;
                                                            objCreditLineItem.Month__c = lastLessonDateObj;
                            listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                            listOfCreditmemolineitem.add(objCreditLineItem);           
                            system.debug('objCreditLineItem'+objCreditLineItem);                                         
                            mapOfCreditmemolineitem.put('Deposit Adjustment',listOfCreditmemolineitem);
                        }
                    }
                }
                system.debug('objCreditMemo'+objCreditMemo);  
                
                newPendingCreditMemos.put('Deposit Adjustment',objCreditMemo);
                 //added by nishi: 6-Oct-2020 : start:for new requirement we Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
            }
           //system.debug('@listOfPayments'+listOfPayments);
        }   
        
        if(lastLessonDateObj < nextBillDate){
            //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                    
            Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
            for(Invoice__c invoiceobj : [Select id,Invoice_Date__c,(Select id from Invoice_Line_Items__r 
                                        where Enrolment__C =:objEnrol.id)
                                        From Invoice__C 
                                        Where  Parent_Account__c =: objEnrol.Parent__c
                                        And invoice_type__c = 'Recurring']){
                if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && invoiceobj.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() ){
                        mapofinvoice.put('Next Month',invoiceobj);
                }else{
                    if(invoiceobj.Invoice_Date__c.month() == system.today().month()){
                        mapofinvoice.put('Current',invoiceobj);
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
            //added by nishi: 7-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
           
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
           
            if(positiveInvoiceAmount != NULL && negativeInvoiceAmount != NULL && String.isNotBlank(objInvoice.Id)){
                if(positiveInvoiceAmount != NULL && gstAmount > 0){
                     positiveInvoiceAmountGST  = (BillingUtility.roundOffAmount(positiveInvoiceAmount) * gstAmount) /100;
                }
                if(negativeInvoiceAmount != NULL  && gstAmount > 0){
                     negativeInvoiceAmountGST  = (BillingUtility.roundOffAmount(negativeInvoiceAmount) * gstAmount) /100;
                }
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
                    //Line Item for positive amount
                  //System.debug('@positiveFacilityInvoiceAmountGST'+positiveFacilityInvoiceAmountGST);
                  //System.debug('@negativeFacilityInvoiceAmountGST'+negativeFacilityInvoiceAmountGST);
                    invoiceLineItems.add(new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount), 
                                        GST_Amount__c = positiveNextMonthInvoiceAmountGST,
                                        Teacher_Id__c = newTeacherId,Package__c=newPackId,Month__c= nextMonthDate.addMonths(-1), 
                                        Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));

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
                    objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(math.abs(negativeNextMonthInvoiceAmount)),
                                                    math.abs(negativeNextMonthInvoiceAmountGST),oldPackId,
                                                    objEnrol.id,invoicelineitemId,'');
                                                    objCreditLineItem.Month__c = nextMonthDate.addMonths(-1);
                                                    objInvoice.Credit_Memo_Amount__c += (math.abs(negativeNextMonthInvoiceAmount) + math.abs(negativeNextMonthInvoiceAmountGST));
                    listOfCreditmemolineitem.add(objCreditLineItem);                                      
                    mapOfCreditmemolineitem.put('Downgrade Enrolment Adjustment',listOfCreditmemolineitem);  
                    system.debug('listOfCreditmemolineitem'+listOfCreditmemolineitem);      
                    //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.                                      
                }
                 // added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice

                //Line Item for positive amount
               
                    invoiceLineItems.add(new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(positiveInvoiceAmount), 
                                                             GST_Amount__c = positiveInvoiceAmountGST,
                                                             Teacher_Id__c = objEnrol.Teacher__c,Package__c=newPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
                //Line Item for negative amount.
                /* //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
                  
                invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(negativeInvoiceAmount), 
                                                               GST_Amount__c = negativeInvoiceAmountGST,
                                                              Teacher_Id__c = objEnrol.Teacher__c,Package__c=oldPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
               
                */
                String invoicelineitemId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                    if(mapofinvoice.containskey('Current')){
                        if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                            invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                        }
                    }
                }
                objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(math.abs(negativeInvoiceAmount)),
                                                math.abs(negativeInvoiceAmountGST),oldPackId,
                                                objEnrol.id,invoicelineitemId,'');
                                                objCreditLineItem.Month__c = effectiveDate;
                                                objInvoice.Credit_Memo_Amount__c += (math.abs(negativeInvoiceAmount) + math.abs(negativeInvoiceAmountGST));
                listOfCreditmemolineitem.add(objCreditLineItem);     
                system.debug('objCreditLineItem'+objCreditLineItem);                                        
                mapOfCreditmemolineitem.put('Downgrade Enrolment Adjustment',listOfCreditmemolineitem);      
                //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record. 

               //start: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                // if(facilityFee  != null && facilityFee != 0){
                //     lessonsAmt+=facilityFee;
                // }
                 //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                if(nextMonthAmount  != null && nextMonthAmount != 0){
                    lessonsAmt+=nextMonthAmount;
                }
                //added by nishi: 6-Oct-2020 :end: Create a Credit Memo record with the status pending instead of the Payment as Credit record for the remaining lessons.   
               //System.debug('lessonsAmt'+lessonsAmt);
                 //end: added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                /* listOfPayments.add(new Payment__c(RecordTypeId = payAsCredit, Payment_Amount__c = BillingUtility.roundOffAmount(lessonsAmt), Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                                  
                                                  Parent_Account__c = objEnrol.Parent__c, Payment_Date__c = lastLessonDateObj));
                                                  */
                Decimal taxAmount = 0;
                if(gstAmount != null && gstAmount != 0){
                    taxAmount =(gstAmount/100)*lessonsAmt; 
                }
                system.debug('taxAmount'+taxAmount);
                system.debug('lessonsAmt'+lessonsAmt);
                objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, null,lastLessonDateObj,'Remaining Lessons Adjustment');
                newPendingCreditMemos.put('Remaining Lessons Adjustment',objCreditMemo);
                system.debug('objCreditMemo'+objCreditMemo);
                 objCreditLineItem = BillingUtility.createCreditMemoLineRec(lessonsAmt - BillingUtility.roundOffAmount(taxAmount),
                                                BillingUtility.roundOffAmount(taxAmount),NULL,
                                                objEnrol.id,NULL,'Remaining Lessons Adjustment');
                                                objCreditLineItem.Month__c = lastLessonDateObj;
                listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                listOfCreditmemolineitem.add(objCreditLineItem);              
                system.debug('objCreditLineItem'+objCreditLineItem);                        
                mapOfCreditmemolineitem.put('Remaining Lessons Adjustment',listOfCreditmemolineitem);
                    //added by nishi: 6-Oct-2020 :end: Create a Credit Memo record with the status pending instead of the Payment as Credit record for the remaining lessons.                                                      
                                                               
                // 8-jan-2020: jatin for add Balanced invoices
                decimal balancedInvoice =0;
                decimal balancedInvoiceGST = 0;
                if(BillingUtility.roundOffAmount(positiveInvoiceAmount) > math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount))){
                    balancedInvoice = -(BillingUtility.roundOffAmount(positiveInvoiceAmount) - math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)));
                }if( math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) > BillingUtility.roundOffAmount(positiveInvoiceAmount)){
                    balancedInvoice =  math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) - BillingUtility.roundOffAmount(positiveInvoiceAmount);
                }
              //System.debug('@@@balancedInvoice'+balancedInvoice);
               // start:added by nishi: 19-Aug-2020: for is facility Fee is differce and differce is greater then 0 then we manage Invoice
                if(positiveNextMonthInvoiceAmount != NULL && positiveNextMonthInvoiceAmount != 0 && negativeNextMonthInvoiceAmount != NULL && negativeNextMonthInvoiceAmount != 0){
                        if(BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount) > math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount))){
                            balancedInvoice += -(BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount) - math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)));
                        }if( math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)) > BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount)){
                            balancedInvoice +=  math.abs(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount)) - BillingUtility.roundOffAmount(positiveNextMonthInvoiceAmount);
                        }
                    }
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
                if(balancedInvoice != NULL && balancedInvoice != 0){
                    if(balancedInvoice != NULL  && balancedInvoice != 0 && gstAmount > 0){
                        balancedInvoiceGST  = (BillingUtility.roundOffAmount(balancedInvoice) * gstAmount) /100;
                    }
                    invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,
                                            Amount__c = BillingUtility.roundOffAmount(balancedInvoice), 
                                            GST_Amount__c = balancedInvoiceGST,
                                            Month__c= effectiveDate, 
                                            Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id,
                                            Remarks__c ='Credit Note Adjustment'));
                }
            }
           

           
            
        }
        
        if(invoiceLineItems.size() > 0){
            insert invoiceLineItems;
        }
      System.debug('@@@invoiceLineItems'+invoiceLineItems);
       
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
       //system.debug('@@@listOfPayments'+listOfPayments);
       //system.debug('@@@isTransaction'+isTransaction);
        return isTransaction;
        
    }
    
    private Static Boolean isSuccessCreatePaymentsDowngradeProcess(Map<String, String> mapOfCase,Enrolment__c enrolmentObj,
    Date effectiveDate, Decimal depositamount,Decimal lessonsFees,Id oldPackageId,Id newPackageId ,string newTeacherId,Organisation__c  organisationObj/*Country__c centreCountry*/){
        
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
                                                        effectiveDate,organisationObj,mapOfCase);    
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