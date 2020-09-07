/*
Name        :        WithDrawlEnrolmentProcessController
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        This Controller help for AureusCalendarController.
*/
public without sharing class WithDrawlEnrolmentProcessController implements IAdvanceAction{
    Private String bookingId;
    Private Date endDate;
    Private Date lastLessonDate;
    Private String myCase; 
    Private String redirectCase;
    Private Enrolment__c enrolObj;
    Private List<Booking__c> bookingListToDelete;   
    public virtual class RefundException extends Exception  {} 
    public WithDrawlEnrolmentProcessController(String bookingId, String endDate, String lastLessonDate, String myCase, String redirectCase) {
        this.bookingId = bookingId;
        if(String.isNotBlank(endDate)){
            this.endDate = Date.valueOf(endDate);
        }
        if(String.isNotBlank(lastLessonDate)){
            this.lastLessonDate = Date.valueOf(lastLessonDate);
        }
        this.myCase =myCase;
        this.redirectCase =redirectCase;
        enrolObj = new Enrolment__c();
        bookingListToDelete = new List<Booking__c>();
    }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        Boolean isSuccess = true;
        String caseIdToReturn;
        //Country__c countryObj = new Country__c();
        Organisation__c  organisationObj = new Organisation__c();
        string enrollmentId;
        if(String.isNotBlank(bookingId)){
            enrolObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(bookingId);
        // if(String.isNotBlank(enrolObj.Center__r.Country__r.Id)){
        //     countryObj = enrolObj.Center__r.Country__r;
        // }
        if(String.isNotBlank(enrolObj.Center__r.Organisation__r.Id)){
            organisationObj = enrolObj.Center__r.Organisation__r;
        }
             enrollmentId = enrolObj.Id;
        }
        date nextBillDate =   AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolObj);
        system.debug('@@@enrolmentObj.id'+enrolObj.id);
        Enrolment__c enroll = new Enrolment__c();
         if(String.isNotBlank(enrollmentId) && endDate != NULL && lastLessonDate  != NULL){
            enroll.Id = enrollmentId;
            enroll = AdvanceActionsHelper.initEnroll(enroll);
            enroll.Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
            enroll.Effective_Date__c = lastLessonDate;
            enroll.Package_Process_Request_Date__c = System.today();
            enroll.Notice_Period_Start_Date__c = endDate.addDays(-30);
            enroll.Notice_Period_End_Date__c = endDate;
            enroll.Advance_Action_Requested_By__c = Userinfo.getUserId();
            if(lastLessonDate >= nextBillDate){
                enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
            }else{
                enroll.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
                enroll.Stage__c = 'Cancelled';
            }

         }
         if(enroll != NULL){
            System.debug('enroll '+enroll);
            Database.SaveResult saveResult = Database.Update(enroll, false);
            if(saveResult.isSuccess()){
                isSuccess = true;
                //Called method for attach WithdrawlSummaryPdf Attchment on enroll parent
                attachWithdrawlSummaryPdf(enrolObj.Name,enrolObj.id,enrolObj.Parent__c);
                //DELETE [SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND Enrolment__c =: enroll.Id AND Status__c != : statusCanceled AND Type__c =: typeRegular];
            }
        }

        system.debug('@@@isSuccess'+isSuccess);
       if(String.isNotBlank(enroll.id)){
            enroll = AdvanceActionsHelper.fetchEnrolment(enroll.id);                
        }
        
        system.debug('@@@enrolmentObj'+enroll);
        if(isSuccess && String.isNotBlank(enrollmentId)){
            Set<String> setOfMakeupBookings = new Set<String>();
            system.debug('@@@lastLessonDate'+lastLessonDate);
            system.debug('@@@nextBillDate'+nextBillDate);
            createPaymentRecordForWithdrawalProcess(enrolObj, lastLessonDate,nextBillDate);
            
            bookingListToDelete.addAll([SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND 
                                        Enrolment__c = :enroll.Id AND Status__c != :ConstantsClass.statusCanceled AND Type__c =: ConstantsClass.typeRegular]);
            setOfMakeupBookings = AdvanceActionsHelper.deleteFutureFifthLessons(enroll);
            AdvanceActionsHelper.processFutureMakeupAndBusyBookingsForWithdrawal(enroll, bookingListToDelete, setOfMakeupBookings);
            
            if(String.isNotBlank(enrolObj.Parent__c)){
                markMakeupExpiryDateAsLastLessonDate(enrolObj.Parent__c);
            }
        }
        system.debug('@@isSuccess'+isSuccess);
        if(!isSuccess){
            caseIdToReturn = 'error';
        }
        
        if(isSuccess && redirectCase == 'true'){
            Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCase, enroll.Id, 'withdrawal', true);
            System.debug('@@caseObj'+objCase);
            caseIdToReturn = objCase.Id;
        }else if(isSuccess){
            caseIdToReturn = '';
        }else{
            caseIdToReturn = 'error';
        }
        
        return caseIdToReturn;
    }

    //Set Expiry date to last lesson date if their is no active enrolment of parent
    public static void markMakeupExpiryDateAsLastLessonDate(String parentId){
        List<Enrolment__c> enrolListForMaxDate = new List<Enrolment__c>();
        Boolean needToMakeupChange = false;
        String cancelStatus = ConstantsClass.enrollmentStageCancelled;
        List<Enrolment__c> enrolList = [SELECT Id, Package_Process_Type__c, Package_Process_Status__c, Effective_Date__c  FROM Enrolment__c 
        WHERE Parent__c =: parentId AND Stage__c = :ConstantsClass.enroledStatus AND Type__c = :ConstantsClass.enrolRegularStatus];
        system.debug('enrolList'+enrolList);
        if(enrolList.size() == 1){
            needToMakeupChange = true;
            enrolListForMaxDate.add(enrolList[0]);
        }else if(enrolList.size() > 1){
            Integer count = 0;
            for(Enrolment__c enrolObj : enrolList){
                enrolListForMaxDate.add(enrolObj);
                if(!(enrolObj.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType && 
                   enrolObj.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus)){
                       count += 1;   
                   }
                   /*commented by jatin: 12 -mar-2020: for check enrolment is withdrawl but  if multiple regular booking is exist and 
                   this regular enrolment is not cancelled type then we not Set Expiry dates
                   if(enrolObj.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType && 
                   enrolObj.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus){
                       count += 1;   
                   }**/
            }
            if(count == 0){
                needToMakeupChange = true;
            }
        }
        system.debug('needToMakeupChange'+needToMakeupChange);
        if(needToMakeupChange && String.isNotBlank(parentId)){
            Date maxDate = findMaxDate(enrolListForMaxDate);
            if(String.isNotBlank(parentId) && maxDate != NULL){
                system.debug('parentId'+parentId);
                updateAllBookingForParent(parentId, maxDate);
            }
        }
        
    }

    private static Date findMaxDate(List<Enrolment__c> enrolList){
        List<Date> dateList = new List<Date>();
        for(Enrolment__c enrolObj : enrolList){
            dateList.add(enrolObj.Effective_Date__c);
        }
        dateList.sort();
        return dateList[dateList.size() - 1];
    }  
    
    private static void updateAllBookingForParent(String parentId, Date maxDate){
        List<Booking__c> bookingList = new List<Booking__c>();
        system.debug('maxDate'+maxDate);
        for(Booking__c bookingObj : [SELECT Id, Make_up_Expiry_Date__c, RecordType.Name,Parent__c,Available_Make_up_Units__c,Type__c,Status__c FROM Booking__c WHERE Parent__c =: parentId]){
        	system.debug('[SELECT Id, Make_up_Expiry_Date__c FROM Booking__c]'+bookingObj);
        }
        for(Booking__c bookingObj : [SELECT Id, Make_up_Expiry_Date__c FROM Booking__c
                                     WHERE RecordType.Name =: ConstantsClass.recordTypeLesson AND Parent__c =: parentId AND 
                                     Make_up_Expiry_Date__c >= :System.today() AND Available_Make_up_Units__c > 0 AND 
                                     Type__c =: ConstantsClass.bookTypeRegular AND Status__c =: ConstantsClass.statusCanceled]){
                                         
                                         bookingObj.Make_up_Expiry_Date__c = maxDate;
                                         bookingList.add(bookingObj);                                           
                                         
                                     }
        if(bookingList.size() > 0){
            update bookingList;
        }
        system.debug('bookingList'+bookingList);
    }

    //To Create Payment Record After the Enrolment Withdrawal Request
    private static void createPaymentRecordForWithdrawalProcess(Enrolment__c objEnrol, Date lastLessonDateObj,Date nextBillDate){
        Boolean isRefund = nextBillDate > lastLessonDateObj;
        system.debug('isRefund'+isRefund);
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        
        
        Boolean hasMoreEnrolment = checkParentHasMultipleEnrolments(objEnrol.parent__c);
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment__c> refundPayments = new List<Payment__c>();
         system.debug('hasMoreEnrolment'+hasMoreEnrolment);
        Payment__c paymentObj  = new Payment__c();
        
        //@JAtin Commented on 15th Nov Due to Fetch Deposit Amount from current Deposit
        
        //Map<String, Invoice_Line_Item__c> mapOfInvoiceLineItems = new Map<String, Invoice_Line_Item__c>();
       
        // JATIN uncommented 25-Nov-2019 :for add transaction id in payment reocrds
        Map<String, Payment__c> mapOfInvoicePayments = new Map<String, Payment__c>();
        

        Decimal depositAmount = 0;
        if(String.isNotBlank(objEnrol.Id)){
            depositAmount = AureusCalendarController.getDepositFromFile(objEnrol.Id);
        }
system.debug('depositAmount'+depositAmount);
        //@JAtin Commented on 15th Nov Due to Fetch Deposit Amount from current Deposit
        /*for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c 
                                             FROM Invoice_Line_Item__c 
                                             WHERE Enrolment__c =: objEnrol.id 
                                             AND Is_Deposit__c = true 
                                             AND Subscription_Line_Item__c != NULL]){
                                                 mapOfInvoiceLineItems.put(lineItem.Invoice__c, lineItem);
                                             }
        
        if(mapOfInvoiceLineItems.keySet().size() > 0){
            for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c  
                                    FROM Payment__c 
                                    WHERE Invoice__c IN: mapOfInvoiceLineItems.keySet() AND 
                                      RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                          mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                      }
        }*/
        
        if(depositAmount > 0){
             paymentObj = new Payment__c();
            List<Id> invoiceIds = NEW List<Id>();
            for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c 
                                                FROM Invoice_Line_Item__c 
                                                WHERE Enrolment__c =: objEnrol.id 
                                                AND Is_Deposit__c = true 
                                                AND Subscription_Line_Item__c != NULL]){
                                                    invoiceIds.add(lineItem.Invoice__c);
                                                }
            
            if(invoiceIds.size() > 0){
                for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c  
                                            FROM Payment__c 
                                            WHERE Invoice__c IN: invoiceIds AND 
                                            RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                            if(string.isNotBlank( payment.Transaction_ID__c)){
                                                mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                            }
                                        }
            }
            if(hasMoreEnrolment){
                paymentObj = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentPendingStatus);
                System.debug('isRefund'+isRefund);
                if(isRefund){
                     paymentObj.Payment_Date__c = System.today();
                }else{
                    //@JAtin Commented on 21st Nov 2019 Due to Deposit should be applied in the last month of the lesson
                    paymentObj.Payment_Date__c = lastLessonDateObj;
                    /*if(objEnrol.Subscription_Line_Items__r.size() > 0 && objEnrol.Subscription_Line_Items__r[0].Next_Bill_Date__c != NULL){
                        paymentObj.Payment_Date__c = objEnrol.Subscription_Line_Items__r[0].Next_Bill_Date__c;
                    }*/
                    
                }
                for( string invoiceId : mapOfInvoicePayments.keyset()){
                    if(mapOfInvoicePayments.containsKey(invoiceId)){
                        paymentObj.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                    }
                }
                paymentObj.RecordTypeId =  paymentRecordTypeId;
                paymentObj.Enrolment__c = objEnrol.id;
                paymentObj.last_lesson_date__c = lastLessonDateObj;
                system.debug('paymentObj'+paymentObj);
                paymentList.add(paymentObj);
            }/*Commented by jatin: 13-jan-2020: for now change requirement only multiple enrollment exist then we create payment record
            otherwise not
            else{
                paymentObj = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentSuccessStatus);
            }

            /*if(isRefund){
                paymentObj.Payment_Date__c = System.today();
            }else{
                //@JAtin Commented on 21st Nov 2019 Due to Deposit should be applied in the last month of the lesson
                paymentObj.Payment_Date__c = lastLessonDateObj;
                /-*if(objEnrol.Subscription_Line_Items__r.size() > 0 && objEnrol.Subscription_Line_Items__r[0].Next_Bill_Date__c != NULL){
                    paymentObj.Payment_Date__c = objEnrol.Subscription_Line_Items__r[0].Next_Bill_Date__c;
                }*-/
                
            }
            for( string invoiceId : mapOfInvoicePayments.keyset()){
                if(mapOfInvoicePayments.containsKey(invoiceId)){
                    paymentObj.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                }
            }
            paymentObj.RecordTypeId =  paymentRecordTypeId;
            paymentObj.Enrolment__c = objEnrol.id;
            paymentObj.last_lesson_date__c = lastLessonDateObj;
            system.debug('paymentObj'+paymentObj);
            paymentList.add(paymentObj);*/
            
        }
        //@JAtin Commented on 15th Nov Due to Fetch Deposit Amount from current Deposit
        /*if(mapOfInvoiceLineItems.size() > 0 && mapOfInvoicePayments.size() > 0){
            for(String invoiceId : mapOfInvoiceLineItems.keySet()){
                paymentObj = new Payment__c();
                
                if(hasMoreEnrolment){
                    paymentObj = BillingUtility.fillPayment(mapOfInvoiceLineItems.get(invoiceId).Invoice__r.Parent_Account__c,null,
                                 mapOfInvoiceLineItems.get(invoiceId).Amount__c, ConstantsClass.paymentPendingStatus);
                    //PaymentObj.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                }else{
                    paymentObj = BillingUtility.fillPayment(mapOfInvoiceLineItems.get(invoiceId).Invoice__r.Parent_Account__c, null,
                                 mapOfInvoiceLineItems.get(invoiceId).Amount__c, ConstantsClass.paymentSuccessStatus);
                    //paymentObj.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                    
                }
                if(isRefund){
                    //paymentObj.RecordTypeId =  refundRecType;
                    //paymentObj.Payment_Date__c = lastLessonDateObj;
                    paymentObj.Payment_Date__c = System.today();
                }else{
                    //paymentObj.RecordTypeId =  paymentRecordTypeId;
                    paymentObj.Payment_Date__c = mapOfInvoiceLineItems.get(invoiceId).Subscription_Line_Item__r.Next_Bill_Date__c;
                }
                paymentObj.RecordTypeId =  paymentRecordTypeId;
                //paymentObj.Payment_Amount__c = Integer.valueOf(mapOfInvoiceLineItems.get(invoiceId).Amount__c);
                //paymentObj.Parent_Account__c = mapOfInvoiceLineItems.get(invoiceId).Invoice__r.Parent_Account__c;
                if(mapOfInvoicePayments.containsKey(invoiceId)){
                    paymentObj.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                }
                paymentObj.Enrolment__c = objEnrol.id;
                paymentObj.last_lesson_date__c = lastLessonDateObj;
                paymentList.add(paymentObj);
            }
            
        }*/


       
        if(!hasMoreEnrolment){
            system.debug('paymentObj'+paymentList);
           /* for(Payment__c objPay : paymentList){
                Payment__c refund = objPay.clone(false,false,false,false);
                refund.Payment_amount__c = -1*refund.Payment_amount__c;
                refund.recordTypeId = refundRecType;
                refund.Payment_Date__c = lastLessonDateObj;
                refund.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                refund.Enrolment__c = objEnrol.Id;
                refundPayments.add(refund);
            }  */
            //14-jan-2020: for create refund amount
            Payment__c  refund = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentPendingStatus);
            refund.Payment_amount__c = -1*refund.Payment_amount__c;
            refund.recordTypeId = refundRecType;
            refund.Payment_Date__c = lastLessonDateObj;
            refund.Payment_Status__c = ConstantsClass.paymentPendingStatus;
            refund.Enrolment__c = objEnrol.Id;
            // 12-mar-2020: added transaction Id in refund payment records.
            for( string invoiceId : mapOfInvoicePayments.keyset()){
                if(mapOfInvoicePayments.containsKey(invoiceId)){
                    refund.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                }
            }
            refundPayments.add(refund);  
        }
        System.debug('isRefund'+isRefund);
         // we need to refund current month amount if applicable
        if(isRefund){
            String chargeId =  fetchCurrentMonthPaymentEntry(objEnrol,lastLessonDateObj); // 21-8-2020
            Decimal refundAmount = getLessonRefundAmount(objEnrol,lastLessonDateObj);//8
            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1); // 1-10-2020
            Boolean isNextMonthInvoicCreated = false;
            // 1-10-2020 >= 1-10-2020 && 8<9
            system.debug('nextBillDate'+nextBillDate);
            system.debug('nextMonthDate'+nextMonthDate);
            system.debug('lastLessonDateObj'+lastLessonDateObj);
            system.debug('nextMonthDate.addMonths(-1).Month()'+nextMonthDate.addMonths(-1).Month());
            if(nextBillDate >= nextMonthDate && lastLessonDateObj.Month() < nextMonthDate.addMonths(-1).Month()){ 
                Decimal refundNextMonthAmount = getLessonRefundAmount(objEnrol,nextMonthDate.addMonths(-1)); // 1-9-2020
                if(refundNextMonthAmount > 0){
                    Payment__c objPay = new Payment__c();
                    if(hasMoreEnrolment){
                            objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundNextMonthAmount, ConstantsClass.paymentPendingStatus);
                    }else{
                            objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundNextMonthAmount, ConstantsClass.paymentSuccessStatus);
                    }
                    objPay.RecordTypeId =  payAsCredit ;
                    objPay.Payment_Date__c = lastLessonDateObj;
                    if(String.isNotBlank(chargeId)){
                            objPay.Transaction_ID__c = chargeId;
                    }//14-Jan:2020 If current month payment is not get then we send error .
                    else{
                        throw new RefundException('Refund Failed. Charge Id Not found');
                    }
                    objPay.Remarks__c ='Refund  (Next month invoice amount)';
                    objPay.last_lesson_date__c = lastLessonDateObj;
                    system.debug('objPay'+objPay);
                    paymentList.add(objPay);
                    isNextMonthInvoicCreated = true;
                }
                system.debug('refundNextMonthAmount'+refundNextMonthAmount);
                system.debug('paymentList'+paymentList);
            }
            
            system.debug(refundAmount);
            if(refundAmount > 0){
                Payment__c objPay = new Payment__c();
                if(hasMoreEnrolment){
                        objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundAmount, ConstantsClass.paymentPendingStatus);
                }else{
                        objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundAmount, ConstantsClass.paymentSuccessStatus);
                }
                objPay.RecordTypeId =  payAsCredit ;
                objPay.Payment_Date__c = lastLessonDateObj;
                if(String.isNotBlank(chargeId)){
                        objPay.Transaction_ID__c = chargeId;
                }//14-Jan:2020 If current month payment is not get then we send error .
                else{
                    throw new RefundException('Refund Failed. Charge Id Not found');
                }
                objPay.last_lesson_date__c = lastLessonDateObj;
                if(isNextMonthInvoicCreated){
                    objPay.Remarks__c ='Refund  (Effective month invoice amount)';
                }
                /*Payment__c objPay = new Payment__c();
                objPay.RecordTypeId =  payAsCredit ;
                objPay.Payment_Date__c = lastLessonDateObj;
                if(hasMoreEnrolment){
                    objPay.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                }else{
                    objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                }
                objPay.Payment_Amount__c = refundAmount;
                objPay.Parent_Account__c = objEnrol.Parent__c;
                objPay.Transaction_ID__c = chargeId;
                objPay.last_lesson_date__c = lastLessonDateObj;*/
                system.debug('objPay'+objPay);
                paymentList.add(objPay);
            }
            
        }
        
        if(refundPayments.size() > 0){
            paymentList.addAll(refundPayments);
        }
        
        if(paymentList.size() > 0){
            insert paymentList;
        }
        system.debug('paymentList'+paymentList);
    }

    // get current month invoice payment entry
    public static String fetchCurrentMonthPaymentEntry(Enrolment__c objEnrol,Date lastLessonDateObj){
        Date firstDate = Date.newInstance(lastLessonDateObj.Year(),lastLessonDateObj.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
        String chargeId ='';
        List<Invoice__c> listOfInvoice =[SELECT Id,Stripe_Charge_Id__c FROM Invoice__c WHERE 
                                         Id IN (SELECT Invoice__c FROM Invoice_Line_Item__c WHERE Enrolment__c=: objEnrol.id AND
                                                //commented by nishi: 20_aug-2020: Createddate >=: firstDate AND createddate <=: lastDate
                                                Month__C >=: firstDate AND Month__C <=: lastDate 
                                                 AND Booking__c = NULL)
                                         AND Invoice_Date__c >=: firstDate AND Invoice_Date__c <=: lastDate AND Status__c = 'Paid' 
                                         Order By total_amount__c ];
        if(listOfInvoice.size()>0){
            chargeId = listOfInvoice[0].Stripe_charge_id__c;
        }
        system.debug('listOfInvoice'+listOfInvoice);
        system.debug('chargeId'+chargeId);
        return chargeId;   
                                       
    }

    Private static Decimal getLessonRefundAmount(Enrolment__c objEnrol,Date lastLessonDate){
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
            if(String.isNotBlank(objEnrol.Id) && String.isNotBlank(objEnrol.Center__c) && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                amount+= (amount  *  objEnrol.Center__r.Country__r.Tax_Rate__c) / 100;
            }
            
        }
        return amount;
    }
    
    // return currentBilledBookings
    private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDate){ // 21-aug-2020  /// 1-Sep-2020
        Date firstDate = Date.newInstance(lastLessonDate.year(),lastLessonDate.month(),01);//1-aug-2020 ///// 1-Sep-2020
        Date lastDate = firstDate.addMonths(1).addDays(-1);//31-aug-2020///// 30-Sep-2020
        return [SELECT Booking_Date__c FROM Booking__c WHERE Enrolment__c=: enrolId AND Booking_Date__c >=: firstDate AND Booking_Date__c <=: lastDate
                AND (Type__c='Regular' or Type__c ='Ad-hoc') 
                and (Status__c = :ConstantsClass.statusScheduled OR Status__c = :ConstantsClass.statusPending)];
    }   

    //check that the Parent Has other Enrolment or Not
    private static Boolean checkParentHasMultipleEnrolments(String parentId){
        Boolean flag = false;
        List<Enrolment__c> enrolList = [SELECT Id FROM Enrolment__c WHERE Parent__c =: parentId AND Stage__c = :ConstantsClass.enroledStatus AND Type__c = :ConstantsClass.enrolRegularStatus];
        if(enrolList.size() > 0 ){
            flag = true;
        }
        return flag;
    }

    
    /*Private Static Boolean updateEnrollment(Enrolment__c enrollmentObj,Date endDateObj,Date effectiveDate, Date nextBillDate, Boolean isSuccess){
        Enrolment__c enroll = new Enrolment__c ();
        if(String.isNotBlank(enrollmentObj.id) && endDateObj != NULL && effectiveDate  != NULL){
            enroll = AdvanceActionsHelper.getUpdatedEnrollmentFields(enrollmentObj.id,ConstantsClass.enrollmentProcessCancelType,
                    endDateObj.addDays(-30),effectiveDate,null,null);
        }
        system.debug('@@@enroll'+enroll);
        if(enroll != NULL){
            Database.SaveResult saveResult = Database.Update(enroll, false);
            if(saveResult.isSuccess()){
                isSuccess = true;
                //Called method for attach WithdrawlSummaryPdf Attchment on enroll parent
                attachWithdrawlSummaryPdf(enrollmentObj.Name,enrollmentObj.id,enrollmentObj.Parent__c);
                //DELETE [SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND Enrolment__c =: enroll.Id AND Status__c != : statusCanceled AND Type__c =: typeRegular];
            }
        }
        
        return isSuccess;
    }*/

    //@Arpit Date:-7/8/2019 This method is used to attach withdrawlSummaryPdf on enrollment account
    @future (callout=true)
    private static void attachWithdrawlSummaryPdf(String enrollName,String enrollId,String enrollParent){
        PageReference pdf = Page.WithdrawlSummaryPdf;
        pdf.getParameters().put('id',enrollId);
        Blob pdfBody;
        if(Test.isRunningTest()) { 
            pdfBody = blob.valueOf('Unit.Test');
        }else{
            pdfBody = pdf.getContentAsPDF();
        }
        
        Attachment enrollParentAttachment = new Attachment(Body=pdfBody,
                                                           name = enrollName+'_WithdrawlSummaryPdf', 
                                                           parentid = enrollParent, 
                                                           contentType = 'application/pdf');
        
        insert enrollParentAttachment;
        
    }
}