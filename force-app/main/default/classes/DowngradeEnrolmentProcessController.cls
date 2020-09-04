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
    Private Time timeslot;
    Private Map<String, String> mapOfCase;
    
    //Data Members for Additional Work
    Private Enrolment__c enroll;
    Private Date nextBillDate;
    Private Country__c countryObj;
    public DowngradeEnrolmentProcessController(String bookingId, String effectiveDateStr, String newPackageId, 
                                               String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                               String amount, String depositAmount, String lessonsFees, Map<String, String> caseValues) {
                                                   this.bookingId = bookingId;
                                                   effectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(effectiveDateStr);
                                                   this.newPackageId = newPackageId;
                                                   this.oldPackageId = oldPackageId;
                                                   this.timeslot = AdvanceActionsHelper.getDateTimeFromString(timeSlot).time();
                                                   this.myCaseId = myCaseId;
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
        Boolean isSuccess = true;
        String caseIdToReturn;String enrollmentId;
        Country__c centreCountry = new Country__c();
        String studentId, teacherId, lessonDay, oldPackage, newPackage, centreId;
                                                          Integer duration, newPackageDuration; 
                                                          Time startTime, newStartTime;
        if(String.isNotBlank(bookingId)){
            enrollmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
        }
        system.debug('@@@enrolmentObj'+enroll);
        // get old and new Package Time Differnce
        Integer timeDiff = 0;
        AdvanceActionsHelper.UpDownSummary objSummary =  AdvanceActionsHelper.getOldNewPackage(oldPackageId,newPackageId);                                         
        if(String.isNotBlank(objSummary.oldPack.Id) && String.isNotBlank(objSummary.newPack.Id)){
            timeDiff =   Integer.valueOf(objSummary.oldPack.Duration__c) - Integer.valueOf(objSummary.newPack.Duration__c);                                                
        }
        System.debug('@@@timeDiff'+timeDiff);
        if(String.isNotBlank(enrollmentId)){
            enroll = AdvanceActionsHelper.fetchEnrolment(enrollmentId);
            
            if(String.isNotBlank(enroll.Center__r.country__r.Id)){
                centreCountry = enroll.Center__r.country__r;    
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
                        oldPackageId, newPackageId,centreCountry);
        }
         

        if(isSuccess){
            if(String.isNotBlank(enrollmentId)){
                enroll.Id = enrollmentId;
                enroll = AdvanceActionsHelper.initEnroll(enroll);
                enroll.New_Package_Id__c = newPackageId;
                
                
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
        
        if(isSuccess && caseRedirect == 'true'){
            caseIdToReturn = getCaseIdToReturn(mapOfCase,myCaseId,enrollmentId,amount,lessonsFees,depositAmount);
        }else if(!isSuccess){
            caseIdToReturn = 'error';
        }else{
            caseIdToReturn = '';
        }
        
        return caseIdToReturn ;
    }
    
    Private Static string getCaseIdToReturn(Map<String, String> caseValues,string myCaseId,String enrollmentId,Decimal amount,Decimal lessonsFees,Decimal depositAmount){
        String caseIdToReturn;
        Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrollmentId, 'downgrade', false);
        if(amount >= 0){
            objCase.Total_Invoice_topup__c = amount;
            ObjCase.Lesson_Charge_Topup__c = math.abs(lessonsFees);
            ObjCase.deposit_Topup__c = depositAmount;
            if(caseValues.containsKey('previousPackage')){
                objCase.Previous_Package__c = caseValues.get('previousPackage');    
            }
            if(caseValues.containsKey('newPackage')){
                objCase.New_Package__c = caseValues.get('newPackage');    
            }
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
        System.debug('@@caseObj'+objCase);
        caseIdToReturn = objCase.Id;
        return caseIdToReturn;
    }
    
    private static Boolean createPaymentsForDowngradeProcess(Enrolment__c objEnrol, Date lastLessonDateObj, Date nextBillDate, Decimal depositAmount, Decimal lessonsAmt, Decimal positiveInvoiceAmount, Decimal negativeInvoiceAmount, String oldPackId,String newPackId, Date effectiveDate, Country__c centreCountry){
        
        Boolean isTransaction = false;
        Subscription_Line_Item__c objSubLineItem;
        String stripeId;
        Invoice__c objInvoice = new Invoice__c();
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        List<Payment__c> listOfPayments = new List<Payment__c>(); 
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String paymentTransaction = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        
        if(depositAmount > 0){
            depositAmount = BillingUtility.roundOffAmount(depositAmount);
        }
        system.debug('@depositAmount'+depositAmount);
        if(depositAmount > 0 && objEnrol.Subscription_Line_Items__r.size() > 0){
            
            objSubLineItem = objEnrol.Subscription_Line_Items__r[0];
            stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c; 
            if(String.isNotBlank(stripeId)){
                BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositAmount, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);                 
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
                        if(!Test.isRunningTest())
                            BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                        
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
            
            //Invoice If the deposit amount is less than 0.
            objInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus,
                                        Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                        Invoice_Date__c =system.today(),
                                        Parent_Account__c = objEnrol.Parent__c, 
                                        Center__c=objEnrol.Center__c);
            INSERT objInvoice;
            // JATIN  25-Nov-2019 :for add transaction id in payment reocrds
            Map<String, Payment__c> mapOfInvoicePayments = new Map<String, Payment__c>();
            List<Id> invoiceIds = NEW List<Id>();
            for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c 
                                                FROM Invoice_Line_Item__c 
                                                WHERE Enrolment__c =: objEnrol.id 
                                                AND Is_Deposit__c = true 
                                                AND Subscription_Line_Item__c != NULL]){
                                                    invoiceIds.add(lineItem.Invoice__c);
                                                }
                for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c  
                                        FROM Payment__c 
                                        WHERE Invoice__c In: invoiceIds AND 
                                        RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                           if(string.isNotBlank(payment.Transaction_ID__c)){
                                                mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                            }
                                        }
            
            if(depositAmount != 0){
                string transactionID ='';
                if(mapOfInvoicePayments != null && mapOfInvoicePayments.size() > 0){
                    for(string invoiceId : mapOfInvoicePayments.keyset()){
                        if(mapOfInvoicePayments.containsKey(invoiceId)){
                           transactionID = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                        }
                    } 
                }
                system.debug('@@transactionID'+transactionID);
                listOfPayments.add(new Payment__c(Payment_Date__c = lastLessonDateObj, 
                                                  RecordTypeId = paymentRecordTypeId, 
                                                  Transaction_ID__c = transactionID,
                                                  Payment_Amount__c = Math.abs(depositAmount), 
                                                  Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                                  Parent_Account__c = objEnrol.Parent__c, 
                                                  Enrolment__c = objEnrol.Id));    
            }
            
        }   
        
        if(lastLessonDateObj < nextBillDate){
            decimal gstAmount = 0;
            decimal positiveInvoiceAmountGST =0;
            decimal negativeInvoiceAmountGST =0;
            if( string.isNotBlank(objEnrol.Center__c) && string.isNotBlank(objEnrol.Center__r.Country__c) &&
             objEnrol.Center__r.Country__r.Tax_Rate__c != null ){
                 gstAmount = BillingUtility.roundOffAmount(objEnrol.Center__r.Country__r.Tax_Rate__c);
             }

            if(positiveInvoiceAmount != NULL && negativeInvoiceAmount != NULL && String.isNotBlank(objInvoice.Id)){
                if(positiveInvoiceAmount != NULL && gstAmount > 0){
                     positiveInvoiceAmountGST  = (BillingUtility.roundOffAmount(positiveInvoiceAmount) * gstAmount) /100;
                }
                if(negativeInvoiceAmount != NULL  && gstAmount > 0){
                     negativeInvoiceAmountGST  = (BillingUtility.roundOffAmount(negativeInvoiceAmount) * gstAmount) /100;
                }
                //Line Item for positive amount
                
                invoiceLineItems.add(new Invoice_Line_Item__c(Invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(positiveInvoiceAmount), 
                                                             GST_Amount__c = positiveInvoiceAmountGST,
                                                             Teacher_Id__c = objEnrol.Teacher__c,Package__c=newPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
                
                //Line Item for negative amount.
                
                invoiceLineItems.add(new Invoice_Line_Item__c(invoice__c = objInvoice.id,Amount__c = BillingUtility.roundOffAmount(negativeInvoiceAmount), 
                                                               GST_Amount__c = negativeInvoiceAmountGST,
                                                              Teacher_Id__c = objEnrol.Teacher__c,Package__c=oldPackId,Month__c= effectiveDate, Subscription_Line_Item__c = objEnrol.Subscription_Line_Items__r[0].Id));
                
                listOfPayments.add(new Payment__c(RecordTypeId = payAsCredit, Payment_Amount__c = BillingUtility.roundOffAmount(lessonsAmt), Payment_Status__c = ConstantsClass.paymentPendingStatus,
                                                  
                                                  Parent_Account__c = objEnrol.Parent__c, Payment_Date__c = lastLessonDateObj));

                // 8-jan-2020: jatin for add Balanced invoices
                 decimal balancedInvoice =0;
                  decimal balancedInvoiceGST = 0;
                if(BillingUtility.roundOffAmount(positiveInvoiceAmount) > math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount))){
                    balancedInvoice = -(BillingUtility.roundOffAmount(positiveInvoiceAmount) - math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)));
                }if( math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) > BillingUtility.roundOffAmount(positiveInvoiceAmount)){
                    balancedInvoice =  math.abs(BillingUtility.roundOffAmount(negativeInvoiceAmount)) - BillingUtility.roundOffAmount(positiveInvoiceAmount);
                }
                system.debug('@@@balancedInvoice'+balancedInvoice);
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
        
        if(String.isNotBlank(objInvoice.id) && isTransaction){
            SageIntacctIntegrationUtility.changeEnrolment(objInvoice.Id);
            BillingUtility.createAttachment(new Set<String> {objInvoice.id});
        }  
        
        if(listOfPayments.size() > 0){
            insert listOfPayments;
        }
        system.debug('@@@listOfPayments'+listOfPayments);
        
        return isTransaction;
        
    }
    
    private Static Boolean isSuccessCreatePaymentsDowngradeProcess(Map<String, String> mapOfCase,Enrolment__c enrolmentObj,
    Date effectiveDate, Decimal depositamount,Decimal lessonsFees,Id oldPackageId,Id newPackageId ,Country__c centreCountry){
        
        Decimal positiveAmt  = mapOfCase.containsKey('positiveInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('positiveInvoiceAmount')) : 0;
        Decimal negativeAmt =  mapOfCase.containsKey('negativeInvoiceAmount') ? Decimal.valueOf(mapOfCase.get('negativeInvoiceAmount')) : 0;
        if(centreCountry != null && String.isNotBlank(centreCountry.Id)
           && String.isNotBlank(centreCountry.Currency_Code__c) 
           && String.isNotBlank(centreCountry.Stripe_Base_Url__c) 
           && String.isNotBlank(centreCountry.Stripe_Secret_Key__c) 
           && effectiveDate != NULL && enrolmentObj.Subscription_Line_Items__r != null && 
           enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c != null){
               system.debug('@@@enrolmentObj.Center__r.country__r'+enrolmentObj.Center__r.country__r);
               return createPaymentsForDowngradeProcess(enrolmentObj, effectiveDate, enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c,
                                                        depositamount, lessonsFees, positiveAmt,negativeAmt, oldPackageId,newPackageId, 
                                                        effectiveDate,centreCountry);    
           }
        return false;    
    }
    
    
    /*Private Static Boolean updatedEnrollment(Enrolment__c enroll,Date effectiveDate,String newPackageId,String centreId,AdvanceActionsHelper.UpDownSummary objSummary,Time startTime, Time timeSlot,Integer timediff, boolean isSuccess){
        if(String.isNotBlank(enroll.id)){
            system.debug('@@enroll.id'+enroll.id);
            enroll = AdvanceActionsHelper.getUpdatedEnrollmentFields(enroll.Id,ConstantsClass.enrollmentProcessDowngradeType,
                    effectiveDate.addDays(-30),effectiveDate,newPackageId,timeSlot);
            system.debug('@@enroll'+enroll);
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