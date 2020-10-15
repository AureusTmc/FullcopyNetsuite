/*
Name        :        WithDrawlEnrolmentClassProcessController
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        This Controller help for Class editController .
*/
public without sharing class WithDrawlEnrolmentClassProcessController implements IAdvanceAction{
    Private String bookingId;
    Private Date endDate;
    Private Date lastLessonDate;
    Private String myCase; 
    Private String redirectCase;
    Private Enrolment__c enrolObj;
    Private List<Booking__c> bookingListToDelete;    
    public virtual class RefundException extends Exception  {}
    public WithDrawlEnrolmentClassProcessController(String bookingId, String endDate, String lastLessonDate, 
                                                String myCase, String redirectCase) {
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
        Country__c countryObj = new Country__c();
        string enrollmentId;
        if(String.isNotBlank(bookingId)){
            enrolObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(bookingId);
            if(String.isNotBlank(enrolObj.Center__r.Country__r.Id)){
            countryObj = enrolObj.Center__r.Country__r;
        }
             enrollmentId = enrolObj.Id;
        }
        date nextBillDate =   AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolObj);
       //system.debug('@@@enrolmentObj.id'+enrolObj.id);
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
           //system.debug('enroll '+enroll);
            Database.SaveResult saveResult = Database.Update(enroll, false);
            if(saveResult.isSuccess()){
                isSuccess = true;
                //Called method for attach WithdrawlSummaryPdf Attchment on enroll parent
                attachWithdrawlSummaryPdf(enrolObj.Name,enrolObj.id,enrolObj.Parent__c);
            }
        }

       //system.debug('@@@isSuccess'+isSuccess);
       if(String.isNotBlank(enroll.id)){
            enroll = AdvanceActionsHelper.fetchEnrolment(enroll.id);                
        }
        
           //system.debug('@@@enrolmentObj'+enroll);
        if(isSuccess && String.isNotBlank(enrollmentId)){
            createPaymentRecordForWithdrawalProcess(enrolObj, lastLessonDate,nextBillDate);
            
            bookingListToDelete.addAll([SELECT ID FROM Booking__c 
                                        WHERE Booking_Date__c > :enroll.Effective_Date__c AND 
                                        Enrolment__c = :enroll.Id 
                                        AND Status__c != :ConstantsClass.statusCanceled 
                                        AND Type__c =: ConstantsClass.groupLessonTypeBooking]);

            processFutureMakeupBookingsForWithdrawal(enroll, bookingListToDelete);
            
            if(String.isNotBlank(enrolObj.Parent__c)){
                markMakeupExpiryDateAsLastLessonDate(enrolObj.Parent__c);
            }
        }
       //system.debug('@@isSuccess'+isSuccess);
        if(!isSuccess){
            caseIdToReturn = 'error';
        }
        
        if(isSuccess && redirectCase == 'true'){
            Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(myCase, enroll.Id, 'withdrawal', true);
           //system.debug('@@caseObj'+objCase);
            caseIdToReturn = objCase.Id;
        }else if(isSuccess){
            caseIdToReturn = '';
        }else{
            caseIdToReturn = 'error';
        }
        
        return caseIdToReturn;
    }

    public static void processFutureMakeupBookingsForWithdrawal(Enrolment__c enrolObj, List<Booking__c> bookingListToDelete){
        List<Booking__c> bookingListToUpdate = new List<Booking__c>();
        
        if(String.isNotBlank(enrolObj.Student__c) && String.isNotBlank(enrolObj.Teacher__c) && 
           Integer.valueOf(enrolObj.Package__r.Duration__c) > 0 && enrolObj.Lesson_Start_time__c != NULL && 
           enrolObj.Effective_Date__c != NULL && String.isNotBlank(enrolObj.Lesson_Day__c)){
               
               for(Booking__c bookingObj : getGroupLessonOfMakeupBookings(enrolObj.Student__c, enrolObj.Teacher__c,
                                            Integer.valueOf(enrolObj.Package__r.Duration__c),
                                             enrolObj.Lesson_Start_time__c, 
                                             enrolObj.Effective_Date__c, enrolObj.Lesson_Day__c)){
                       bookingListToUpdate.add(bookingObj);
                   
               }
               
               if(bookingListToDelete.size() > 0){
                   DELETE bookingListToDelete;
               }
               
               if(bookingListToUpdate.size() > 0){
                   AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(bookingListToUpdate);  
               }
           }      
    }

    public static List<Booking__c> getGroupLessonOfMakeupBookings(String studentId,String teacherId,Integer Duration, 
                                                                Time startTime, Date effectiveDate, String lessonDay){
        return [SELECT Id,Start_time__c,End_time__c, Booking_Date__c, Available_Make_up_Units__c, 
                Student__r.Name, Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c, Duration__c, Type__c, Category__c 
                FROM Booking__c 
                WHERE Student__c=:studentId 
                AND Teacher_Account__c=: teacherId 
                AND Type__c =: ConstantsClass.typeMakeup
                AND  recordType.Name =:ConstantsClass.groupLessonBookingRecordType
                AND Appointment_Day__c =: lessonDay];
    }
    //Set Expiry date to last lesson date if their is no active enrolment of parent
    public static void markMakeupExpiryDateAsLastLessonDate(String parentId){
        List<Enrolment__c> enrolListForMaxDate = new List<Enrolment__c>();
        Boolean needToMakeupChange = false;
        String cancelStatus = ConstantsClass.enrollmentStageCancelled;
        List<Enrolment__c> enrolList = [SELECT Id, Package_Process_Type__c, Package_Process_Status__c, 
                                        Effective_Date__c  
                                        FROM Enrolment__c 
                                        WHERE Parent__c =: parentId 
                                        AND Stage__c = :ConstantsClass.enroledStatus
                                        AND Type__c = :ConstantsClass.enrolGroupType];
        
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
            }
            if(count == 0){
                needToMakeupChange = true;
            }
        }
        
        if(needToMakeupChange && String.isNotBlank(parentId)){
            Date maxDate = findMaxDate(enrolListForMaxDate);
            if(String.isNotBlank(parentId) && maxDate != NULL){
               //system.debug('parentId'+parentId);
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
       //system.debug('maxDate'+maxDate);
        for(Booking__c bookingObj : [SELECT Id, Make_up_Expiry_Date__c 
                                    FROM Booking__c
                                     WHERE RecordType.Name =: ConstantsClass.groupLessonBookingRecordType
                                     AND Parent__c =: parentId AND 
                                     Make_up_Expiry_Date__c >= :System.today() 
                                     AND Available_Make_up_Units__c > 0 AND 
                                     Type__c =: ConstantsClass.groupLessonTypeBooking
                                      AND Status__c =: ConstantsClass.statusCanceled]){
                                         
                                         bookingObj.Make_up_Expiry_Date__c = maxDate;
                                         bookingList.add(bookingObj);                                           
                                         
                                     }
        if(bookingList.size() > 0){
            update bookingList;
        }
        
    }

    //To Create Payment Record After the Enrolment Withdrawal Request
    private static void createPaymentRecordForWithdrawalProcess(Enrolment__c objEnrol, Date lastLessonDateObj,Date nextBillDate){
        Boolean isRefund = nextBillDate > lastLessonDateObj;
        
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        
        
        Boolean hasMoreEnrolment = checkParentHasMultipleEnrolments(objEnrol.parent__c);
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment__c> refundPayments = new List<Payment__c>();
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,Credit_memo_line_item__c> listOfCreditmemolineitem = new map<string,Credit_memo_line_item__c>();
        Payment__c paymentObj  = new Payment__c();
        
       //for add transaction id in payment reocrds
        Map<String, Payment__c> mapOfInvoicePayments = new Map<String, Payment__c>();
        

        Decimal depositAmount = 0;
        if(String.isNotBlank(objEnrol.Id)){
            depositAmount = AureusCalendarController.getDepositFromFile(objEnrol.Id);
        }

        if(depositAmount > 0){
             paymentObj = new Payment__c();
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
            
            if(invoiceIds.size() > 0){
                for(Payment__c payment : [SELECT Id, Transaction_ID__c, Invoice__c ,Method_of_Payment__c 
                                            FROM Payment__c 
                                            WHERE Invoice__c IN: invoiceIds AND 
                                            RecordType.Name =:ConstantsClass.paymentTransactionRecType]){
                                            if(string.isNotBlank( payment.Transaction_ID__c)){
                                                mapOfInvoicePayments.put(payment.Invoice__c, payment);
                                            }
                                        }
            }
            if(hasMoreEnrolment){
                 /*//commented by nishi: 6-Oct-2020 : for new requirement we Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
                  paymentObj = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentPendingStatus);
                if(isRefund){
                    paymentObj.Payment_Date__c = System.today();
                }else{
                    paymentObj.Payment_Date__c = lastLessonDateObj;
                }
                for( string invoiceId : mapOfInvoicePayments.keyset()){
                    if(mapOfInvoicePayments.containsKey(invoiceId)){
                        paymentObj.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;    
                        // added by nishi: 10-Sep-2020: if the deposit was paid by card then we can set it to Card and vice-versa
                        paymentObj.Method_of_Payment__c =   mapOfInvoicePayments.get(invoiceId).Method_of_Payment__c; 
                    }
                }
                paymentObj.RecordTypeId =  paymentRecordTypeId;
                paymentObj.Enrolment__c = objEnrol.id;
                paymentObj.last_lesson_date__c = lastLessonDateObj;
               //system.debug('paymentObj'+paymentObj);
                paymentList.add(paymentObj);*/
                Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, null,  System.today(),'Deposit Adjustment');
                if(isRefund){
                    objCreditMemo.Credit_Memo_Date__c = System.today();
                }else{
                    objCreditMemo.Credit_Memo_Date__c = lastLessonDateObj;
                   }
                for( string invoiceId : mapOfInvoicePayments.keyset()){
                    if(mapOfInvoicePayments.containsKey(invoiceId)){
                       objCreditMemo.Payment_Method__c =   mapOfInvoicePayments.get(invoiceId).Method_of_Payment__c; 
                       objCreditMemo.From_Invoice__c = invoiceId;
                       Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(depositAmount,null,invoicemap.get(invoiceId).Package__c,
                                                        objEnrol.id,invoicemap.get(invoiceId).Id,'Deposit Adjustment');
                                                        objCreditLineItem.Is_Deposit__c = true;
                                                        objCreditLineItem.Month__c = lastLessonDateObj;
                       listOfCreditmemolineitem.put('Deposit Adjustment',objCreditLineItem);
                    }
                }
                newPendingCreditMemos.put('Deposit Adjustment',objCreditMemo);

            }/*/*Commented by jatin: 13-jan-2020: for now change requirement only multiple enrollment exist then we create payment record
            otherwise not
            else{
                paymentObj = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentSuccessStatus);
            }*/

            
            
        }
        
        if(!hasMoreEnrolment){
           //system.debug('paymentObj'+paymentList);
            /*for(Payment__c objPay : paymentList){
                Payment__c refund = objPay.clone(false,false,false,false);
                refund.Payment_amount__c = -1*refund.Payment_amount__c;
                refund.recordTypeId = refundRecType;
                refund.Payment_Date__c = lastLessonDateObj;
                refund.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                refundPayments.add(refund);
            } */  
             //14-jan-2020: for create refund amount
             /*
         Commented by nishi: 15-Oct-2020:start:for new requirement Create a Credit Memo record with the status pending instead of the pending Payment as credit record.
          
             Payment__c  refund = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentPendingStatus);
            refund.Payment_amount__c = -1*refund.Payment_amount__c;
            refund.recordTypeId = refundRecType;
            refund.Payment_Date__c = lastLessonDateObj;
            refund.Payment_Status__c = ConstantsClass.paymentPendingStatus;
            refund.Enrolment__c = objEnrol.Id;
            for( string invoiceId : mapOfInvoicePayments.keyset()){
                if(mapOfInvoicePayments.containsKey(invoiceId)){
                    paymentObj.Transaction_ID__c = mapOfInvoicePayments.get(invoiceId).Transaction_ID__c;  
                }
            }
            refundPayments.add(refund);   */
            Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, null,  lastLessonDateObj,'Refund Deposit');
            Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(depositAmount,0,null,objEnrol.id,null,'Refund Deposit');
                                            objCreditLineItem.Month__c = lastLessonDateObj;
                                            objCreditLineItem.Is_Deposit__c = true;
            listOfCreditmemolineitem.put('Refund Deposit',objCreditLineItem);
            system.debug('objCreditLineItem'+objCreditLineItem);
            system.debug('objCreditMemo'+objCreditMemo);
            newPendingCreditMemos.put('Refund Deposit',objCreditMemo);
        }

         // we need to refund current month amount if applicable
        if(isRefund){
            String chargeId =  AureusCalendarController.fetchCurrentMonthPaymentEntry(objEnrol,lastLessonDateObj);
            Decimal refundAmount = classEditController.getLessonRefundAmount(objEnrol,lastLessonDateObj);
            string refundAmountWithTax = getLessonRefundAmountWithTax(objEnrol,lastLessonDateObj);
            // added by nishi: 21-Sep-2020: for if next month invoice already generated then we create next month payment records
            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1); // 1-10-2020
            Boolean isNextMonthInvoicCreated = false;
            //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
            Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
            for(Invoice__c objInvoice : [Select id,Invoice_Date__c,(Select id from Invoice_Line_Items__r 
                                        where Enrolment__C =:objEnrol.id)
                                        From Invoice__C 
                                        Where  Parent_Account__c =: objEnrol.Parent__c
                                        And invoice_type__c = 'Recurring']){
                if(nextBillDate >= nextMonthDate && lastLessonDateObj.month() < nextMonthDate.addMonths(-1).month() && objInvoice.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() ){
                        mapofinvoice.put('Next Month',objInvoice);
                }else{
                    if(objInvoice.Invoice_Date__c.month() == system.today().month()){
                        mapofinvoice.put('Current',objInvoice);
                    }
                }
            }
             //added by nishi: 15-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
             
            // 1-10-2020 >= 1-10-2020 && 8<9
           //system.debug('nextBillDate'+nextBillDate);
           //system.debug('nextMonthDate'+nextMonthDate);
           //system.debug('lastLessonDateObj'+lastLessonDateObj);
           //system.debug('nextMonthDate.addMonths(-1).Month()'+nextMonthDate.addMonths(-1).Month());
            if(nextBillDate >= nextMonthDate && lastLessonDateObj.Month() < nextMonthDate.addMonths(-1).Month()){ 
                Decimal refundNextMonthAmount = classEditController.getLessonRefundAmount(objEnrol,nextMonthDate.addMonths(-1)); // 1-9-2020
                string refundNextMontAmountWithTax = getLessonRefundAmountWithTax(objEnrol,nextMonthDate.addMonths(-1));
                if(refundNextMonthAmount > 0){
                    String invoiceId = null;
                    String invoicelineitemId = null;
                    if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                        if(mapofinvoice.containskey('Next Month')){
                            invoiceId = mapofinvoice.get('Next Month').id;
                            if(mapofinvoice.get('Next Month').Invoice_Line_Items__r != null && mapofinvoice.get('Next Month').Invoice_Line_Items__r.size()>0){
                                invoicelineitemId =mapofinvoice.get('Next Month').Invoice_Line_Items__r[0].id; 
                            }
                        }
                    }
                    Payment__c objPay = new Payment__c();
                    if(hasMoreEnrolment){
                         //added by nishi: 6-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the pending Payment as credit record.
                        //objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundNextMonthAmount, ConstantsClass.paymentPendingStatus);
                        if(refundNextMontAmountWithTax.split('@') != null &&  refundNextMontAmountWithTax.split('@').size() > 0){
                            Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  lastLessonDateObj,'Refund  (Next month invoice amount)');
                            Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Decimal.valueOf(refundNextMontAmountWithTax.split('@')[0]),
                                                            Decimal.valueOf(refundNextMontAmountWithTax.split('@')[1]),null,
                                                            objEnrol.id,invoicelineitemId,'Refund  (Next month invoice amount)');
                                                            objCreditLineItem.Month__c = lastLessonDateObj;
                            listOfCreditmemolineitem.put('Refund  (Next month invoice amount)',objCreditLineItem);
                        
                            newPendingCreditMemos.put('Refund  (Next month invoice amount)',objCreditMemo);
                        }
                         //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the pending Payment as credit record.
                    }else{
                         //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
                        
                            /*objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundNextMonthAmount, ConstantsClass.paymentSuccessStatus);
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
                           //system.debug('objPay'+objPay);
                            paymentList.add(objPay);*/
                            if(refundNextMontAmountWithTax.split('@') != null &&  refundNextMontAmountWithTax.split('@').size() > 0){
                                Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  lastLessonDateObj,'Refund  (Next month invoice amount)');
                                Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Decimal.valueOf(refundNextMontAmountWithTax.split('@')[0]),
                                                                Decimal.valueOf(refundNextMontAmountWithTax.split('@')[1]),null,
                                                                objEnrol.id,invoicelineitemId,'Refund  (Next month invoice amount)');
                                                                objCreditLineItem.Month__c = lastLessonDateObj;
                                listOfCreditmemolineitem.put('Refund  (Next month invoice amount)',objCreditLineItem);
                                system.debug('objCreditLineItem'+objCreditLineItem);
                                system.debug('objCreditMemo'+objCreditMemo);
                                newPendingCreditMemos.put('Refund  (Next month invoice amount)',objCreditMemo);
                            }   
                    }
                   
                    isNextMonthInvoicCreated = true;
                }
               //system.debug('refundNextMonthAmount'+refundNextMonthAmount);
               //system.debug('paymentList'+paymentList);
            }
             //end: added by nishi: 21-Sep-2020: for if next month invoice already generated then we create next month payment records
            if(refundAmount > 0){
                String invoiceId = null;
                String invoicelineitemId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                    if(mapofinvoice.containskey('Current')){
                        invoiceId = mapofinvoice.get('Current').id;
                        if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                            invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                        }
                    }
                }
                Payment__c objPay = new Payment__c();
                if(hasMoreEnrolment){
                    //added by nishi: 6-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the pending Payment as credit record.
                    //objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundAmount, ConstantsClass.paymentPendingStatus);
                    Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  lastLessonDateObj,'Refund  (Effective month invoice amount)');
                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Decimal.valueOf(refundAmountWithTax.split('@')[0]),
                                                    Decimal.valueOf(refundAmountWithTax.split('@')[1]),null,
                                                    objEnrol.id,invoicelineitemId,'Refund  (Effective month invoice amount)');
                                                    objCreditLineItem.Month__c = lastLessonDateObj;
                    listOfCreditmemolineitem.put('Refund  (Effective month invoice amount)',objCreditLineItem);
                   
                    newPendingCreditMemos.put('Refund  (Effective month invoice amount)',objCreditMemo);
                     //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the pending Payment as credit record.
                }else{
                      //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
                    /*
                        objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundAmount, ConstantsClass.paymentSuccessStatus);
                        objPay.RecordTypeId =  payAsCredit ;
                        objPay.Payment_Date__c = lastLessonDateObj;
                        if(String.isNotBlank(chargeId)){
                                objPay.Transaction_ID__c = chargeId;
                        }// If current month payment is not get then we send error .
                        else{
                            throw new RefundException('Refund Failed. Charge Id Not found');
                        }
                        objPay.last_lesson_date__c = lastLessonDateObj;
                        if(isNextMonthInvoicCreated){
                            objPay.Remarks__c ='Refund  (Effective month invoice amount)';
                        }
                        paymentList.add(objPay);*/
                    Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  lastLessonDateObj,'Refund  (Effective month invoice amount)');
                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Decimal.valueOf(refundAmountWithTax.split('@')[0]),
                                                    Decimal.valueOf(refundAmountWithTax.split('@')[1]),null,
                                                    objEnrol.id,invoicelineitemId,'Refund  (Effective month invoice amount)');
                                                    objCreditLineItem.Month__c = lastLessonDateObj;
                    listOfCreditmemolineitem.put('Refund  (Effective month invoice amount)',objCreditLineItem);
                    
                    newPendingCreditMemos.put('Refund  (Effective month invoice amount)',objCreditMemo);
                }
               
            }
                                                                     
        }
        
        if(refundPayments.size() > 0){
            paymentList.addAll(refundPayments);
        }
          //added by nishi: 6-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
          if(newPendingCreditMemos.size() > 0){
            Insert newPendingCreditMemos.values();  
           system.debug('newPendingCreditMemos'+newPendingCreditMemos);
            List<Credit_memo_line_item__c> listOfnewCreditmemolineitem = new list<Credit_memo_line_item__c>();
            for(string creditMemoRemark : newPendingCreditMemos.keyset()){
                if(listOfCreditmemolineitem.containskey(creditMemoRemark)){
                    Credit_memo_line_item__c objCreditLineItem= listOfCreditmemolineitem.get(creditMemoRemark);
                    objCreditLineItem.Credit_Memo_Number__c = newPendingCreditMemos.get(creditMemoRemark).id;
                    listOfnewCreditmemolineitem.add(objCreditLineItem);
                }
            } 
            if(listOfnewCreditmemolineitem != null && listOfnewCreditmemolineitem.size() > 0){
                insert listOfnewCreditmemolineitem;
            }
        }
         //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
        if(paymentList.size() > 0){
            insert paymentList;
        }
       //system.debug('paymentList'+paymentList);
    }

     // @@nishi:6-Oct-2020 for withdrawal group lesson get Lesson Refund Amount according to group lesson bookings
     public static String getLessonRefundAmountWithTax(Enrolment__c objEnrol,Date lastLessonDate){
        Decimal amount = 0;
        Decimal taxamount = 0;
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
                taxamount+= (amount  * objEnrol.Center__r.Country__r.Tax_Rate__c)  / 100;
            }
            
        }
        return amount+'@'+taxamount;
    }
        // @@nishi:6-Oct-2020 return currentBilledBookings
         private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDate){
            Date firstDate = Date.newInstance(lastLessonDate.year(),lastLessonDate.month(),01);
            Date lastDate = firstDate.addMonths(1).addDays(-1);
            return [SELECT Booking_Date__c 
                    FROM Booking__c
                    WHERE Enrolment__c=: enrolId 
                    AND Booking_Date__c >=: firstDate 
                    AND Booking_Date__c <=: lastDate
                    AND (Type__c =: ConstantsClass.groupLessonTypeBooking) 
            ];
        }  
    
    //check that the Parent Has other Enrolment or Not
    private static Boolean checkParentHasMultipleEnrolments(String parentId){
        Boolean flag = false;
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.enrolGroupType};
        List<Enrolment__c> enrolList = [SELECT Id FROM Enrolment__c WHERE Parent__c =: parentId 
                                        AND Stage__c = :ConstantsClass.enroledStatus 
                                        AND Type__c = :enrolTypes];
        if(enrolList.size() > 0 ){
            flag = true;
        }
        return flag;
    }
    //@Arpit Date:-7/8/2019 This method is used to attach withdrawlSummaryPdf on enrollment account
    @future (callout=true)
    private static void attachWithdrawlSummaryPdf(String enrollName,String enrollId,String enrollParent){
        PageReference pdf = Page.WithDrawlEnrolmentClassSummaryPdf;
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