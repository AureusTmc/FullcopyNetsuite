/*
Name        :        WithDrawlEnrolmentProcessController
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        This Controller help for AureusCalendarController.
test class 	:		WithDrawlEnrolmentProcessControllertest
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
        Savepoint withdrawlSavePoint;
        Boolean isSuccess = true;
        String caseIdToReturn;
        try{
            withdrawlSavePoint = Database.setSavepoint();
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
             // added by nishi: 22-Oct-2020: for some limited user can downgrade prepayment enrolment
             Boolean isPromotionalEnrolment=false;
             if( String.isNotBlank(enrolObj.Type_of_Package__c) && (enrolObj.Type_of_Package__c == ConstantsClass.prePaymentType || enrolObj.Type_of_Package__c == ConstantsClass.PromoTypePayment)){
                 isPromotionalEnrolment= true;
             }
             // added by nishi: 22-Oct-2020: for some limited user can downgrade prepayment enrolment
 
            
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
                    //DELETE [SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND Enrolment__c =: enroll.Id AND Status__c != : statusCanceled AND Type__c =: typeRegular];
                }
            }

        //system.debug('@@@isSuccess'+isSuccess);
        if(String.isNotBlank(enroll.id)){
                enroll = AdvanceActionsHelper.fetchEnrolment(enroll.id);                
            }
            
        //system.debug('@@@enrolmentObj'+enroll);
            if(isSuccess && String.isNotBlank(enrollmentId)){
                Set<String> setOfMakeupBookings = new Set<String>();
            //system.debug('@@@lastLessonDate'+lastLessonDate);
            //system.debug('@@@nextBillDate'+nextBillDate);
                createPaymentRecordForWithdrawalProcess(enrolObj, lastLessonDate,nextBillDate,isPromotionalEnrolment);
                
                bookingListToDelete.addAll([SELECT ID FROM Booking__c WHERE Booking_Date__c > :enroll.Effective_Date__c AND 
                                            Enrolment__c = :enroll.Id AND Status__c != :ConstantsClass.statusCanceled AND Type__c =: ConstantsClass.typeRegular]);
                setOfMakeupBookings = AdvanceActionsHelper.deleteFutureFifthLessons(enroll);
                AdvanceActionsHelper.processFutureMakeupAndBusyBookingsForWithdrawal(enroll, bookingListToDelete, setOfMakeupBookings);
                
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
        }catch (Exception e){
            //On 14-Oct-2020: Nishi to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(withdrawlSavePoint);
            caseIdToReturn  = 'error';
            System.debug('@@caseIdToReturn'+e.getStackTraceString()+'-'+e.getMessage() +';');
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
       //system.debug('enrolList'+enrolList);
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
       //system.debug('needToMakeupChange'+needToMakeupChange);
        if(needToMakeupChange && String.isNotBlank(parentId)){
            Date maxDate = findMaxDate(enrolListForMaxDate);
            if(String.isNotBlank(parentId) && maxDate != NULL){
               //system.debug('parentId'+parentId);
                updateAllBookingForParent(parentId, maxDate);
            }
        }
        
    }
    @testVisible
    private static Date findMaxDate(List<Enrolment__c> enrolList){
        List<Date> dateList = new List<Date>();
        for(Enrolment__c enrolObj : enrolList){
            dateList.add(enrolObj.Effective_Date__c);
        }
        dateList.sort();
        return dateList[dateList.size() - 1];
    }  
    
    @testVisible
    private static void updateAllBookingForParent(String parentId, Date maxDate){
        List<Booking__c> bookingList = new List<Booking__c>();
       //system.debug('maxDate'+maxDate);
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
       //system.debug('bookingList'+bookingList);
    }

    //To Create Payment Record After the Enrolment Withdrawal Request
    private static void createPaymentRecordForWithdrawalProcess(Enrolment__c objEnrol, Date lastLessonDateObj,Date nextBillDate,Boolean isPromotionalEnrolment){
        Boolean isRefund = nextBillDate > lastLessonDateObj;
       //system.debug('isRefund'+isRefund);
        String paymentRecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        String payAsCredit = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
        String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        map<string,task> mapOfRefundReminderTasks = new map<string,task>();
        List<Subscription_Line_Item__c> listSubLineItem = UpgradeDowngradeController.fetchSubsLineItems(objEnrol.Subscription_Line_Items__r[0].id);
        Subscription_Line_Item__c objSubLineItem;
        if(listSubLineItem != null && listSubLineItem.size() > 0 ){
            objSubLineItem  = listSubLineItem[0];
        }
        system.debug('listSubLineItem'+listSubLineItem);    
        Boolean hasMoreEnrolment = checkParentHasMultipleEnrolments(objEnrol.parent__c);
        List<Payment__c> paymentList = new List<Payment__c>();
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
        List<Payment__c> refundPayments = new List<Payment__c>();
        //system.debug('hasMoreEnrolment'+hasMoreEnrolment);
        Payment__c paymentObj  = new Payment__c();
        map<String,Invoice_Line_Item__c> updateInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        map<String,Invoice_Line_Item__c> updateCreditMemoAmountInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        //@JAtin Commented on 15th Nov Due to Fetch Deposit Amount from current Deposit
        
        //Map<String, Invoice_Line_Item__c> mapOfInvoiceLineItems = new Map<String, Invoice_Line_Item__c>();
       
        // JATIN uncommented 25-Nov-2019 :for add transaction id in payment reocrds
        Map<String, Payment__c> mapOfInvoicePayments = new Map<String, Payment__c>();
        

        Decimal depositAmount = 0;
        if(String.isNotBlank(objEnrol.Id)){
            depositAmount = AureusCalendarController.getDepositFromFile(objEnrol.Id);
        }
       
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
        List<Id> invoiceIds = NEW List<Id>();
            Set<String> statusSet = new Set<String>{ConstantsClass.voidInvoiceStatus, ConstantsClass.cancelledInvoiceStatus};
            Map<Id,Invoice_Line_Item__c> invoicemap = NEW Map<Id,Invoice_Line_Item__c>();
            for(Invoice_Line_Item__c lineItem : [SELECT Id, Invoice__c, Amount__c, Invoice__r.Parent_Account__c, Subscription_Line_Item__r.Next_Bill_Date__c ,Package__c,
                                                Credit_Memo_Amount__c,Credit_Memo_tax__c,Net_Amount__c
                                                FROM Invoice_Line_Item__c 
                                                WHERE Enrolment__c =: objEnrol.id 
                                                AND Is_Deposit__c = true 
                                                AND Subscription_Line_Item__c != NULL
                                                AND Invoice__r.Status__c NOT IN :statusSet]){
                invoiceIds.add(lineItem.Invoice__c);
                invoicemap.put(lineItem.Invoice__c,lineItem);
                updateInvoiceLineItem.put(lineItem.id,lineItem);
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
        if(depositAmount > 0){
             paymentObj = new Payment__c();
             
            if(hasMoreEnrolment){
                /*//commented by nishi: 6-Oct-2020 : for new requirement we Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
                paymentObj = BillingUtility.fillPayment(objEnrol.Parent__c,null, depositAmount, ConstantsClass.paymentPendingStatus);
               //system.debug('isRefund'+isRefund);
                if(isRefund){
                     paymentObj.Payment_Date__c = System.today();
                }else{
                    //@JAtin Commented on 21st Nov 2019 Due to Deposit should be applied in the last month of the lesson
                    paymentObj.Payment_Date__c = lastLessonDateObj;
                    /*if(objEnrol.Subscription_Line_Items__r.size() > 0 && objEnrol.Subscription_Line_Items__r[0].Next_Bill_Date__c != NULL){
                        paymentObj.Payment_Date__c = objEnrol.Subscription_Line_Items__r[0].Next_Bill_Date__c;
                    }*-/
                    
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
               
                paymentList.add(paymentObj);*/
                system.debug('depositAmount'+depositAmount);
                //added by nishi: 6-Oct-2020 : start:for new requirement we Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
                 Decimal creditMemodepositAmount =Math.abs(depositAmount);
                for( string invoiceId : mapOfInvoicePayments.keyset()){
                    /* 26-Apr-2021  Enrolments with multiple deposits meaning advancements at the time of withdrawal should have a separate credit memo created for each line item that is equal to deposit. 
                    Finance must refund the credit memos separately to their original charges.*/
                    if(mapOfInvoicePayments.containsKey(invoiceId) && invoicemap.containsKey(invoiceId) && creditMemodepositAmount > 0){
                        depositAmount = (creditMemodepositAmount > invoicemap.get(invoiceId).Net_Amount__c ? //120 > 112
                                         invoicemap.get(invoiceId).Net_Amount__c :
                                         creditMemodepositAmount); 
                        creditMemodepositAmount  =creditMemodepositAmount - invoicemap.get(invoiceId).Net_Amount__c; //120-112=8
                        Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, null,  System.today(),'Deposit Adjustment');
                        system.debug('objCreditMemo'+objCreditMemo);
                        Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(depositAmount,0,null,
                                                                                                            objEnrol.id,null,'Deposit Adjustment');
                        objCreditLineItem.Is_Deposit__c = true;
                        if(isRefund){
                            objCreditMemo.Credit_Memo_Date__c = System.today();
                            objCreditLineItem.Month__c = System.today();
                        }else{
                            objCreditMemo.Credit_Memo_Date__c = lastLessonDateObj;
                            objCreditLineItem.Month__c = lastLessonDateObj;
                        }
                        objCreditMemo.Payment_Method__c =   mapOfInvoicePayments.get(invoiceId).Method_of_Payment__c; 
                        objCreditMemo.From_Invoice__c = invoiceId;
                        objCreditLineItem.Package__c = invoicemap.get(invoiceId).Package__c;
                        objCreditLineItem.Invoice_Line_Item__c = invoicemap.get(invoiceId).Id;
                        listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                        listOfCreditmemolineitem.add(objCreditLineItem);
                        mapOfCreditmemolineitem.put('Deposit Adjustment'+invoiceId,listOfCreditmemolineitem);
                        //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                        if(string.isNotBlank(objCreditLineItem.Invoice_Line_Item__c)){
                            updateCreditMemoAmountInvoiceLineItem.put(objCreditLineItem.Invoice_Line_Item__c,updateInvoiceLineItemMap( updateInvoiceLineItem,depositAmount,0,objCreditLineItem.Invoice_Line_Item__c));
                        }
                        newPendingCreditMemos.put('Deposit Adjustment'+invoiceId,objCreditMemo);
                         /* 26-Apr-2021 end: Enrolments with multiple deposits meaning advancements at the time of withdrawal should have a separate credit memo created for each line item that is equal to deposit. 
                    Finance must refund the credit memos separately to their original charges.*/
                    }
                }
              
                //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
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
           //system.debug('paymentObj'+paymentObj);
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


       
        if(!hasMoreEnrolment  && depositAmount!= null){
              
           //system.debug('paymentObj'+paymentList);
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
          /*
         Commented by nishi: 15-Oct-2020:start:for new requirement Create a Credit Memo record with the status pending instead of the pending Payment as credit record.
                           
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
            refundPayments.add(refund);  */
              Map<string,QueueSObject > mapOfQueue = BillingUtility.getTaskQueueMap();
          
              Decimal creditMemodepositAmount =depositAmount;
              
                for( string invoiceId : mapOfInvoicePayments.keyset()){
                     /* 26-Apr-2021  Enrolments with multiple deposits meaning advancements at the time of withdrawal should have a separate credit memo created for each line item that is equal to deposit. 
                    Finance must refund the credit memos separately to their original charges.*/
                    if(mapOfInvoicePayments.containsKey(invoiceId) && invoicemap.containsKey(invoiceId) && creditMemodepositAmount > 0){
                        depositAmount = (creditMemodepositAmount > invoicemap.get(invoiceId).Net_Amount__c ? //120 > 112
                                         invoicemap.get(invoiceId).Net_Amount__c :
                                         creditMemodepositAmount
                                        ); 
                        creditMemodepositAmount  =creditMemodepositAmount - invoicemap.get(invoiceId).Net_Amount__c; //120-112=8
                        Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, null,  lastLessonDateObj,'Refund Deposit');
                        Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(depositAmount,0,null,
                                                                                                            objEnrol.id,null,'Refund Deposit');
                        objCreditLineItem.Is_Deposit__c = true;
                        objCreditLineItem.Month__c = lastLessonDateObj;
                        objCreditMemo.Payment_Method__c =   mapOfInvoicePayments.get(invoiceId).Method_of_Payment__c; 
                        objCreditMemo.From_Invoice__c = invoiceId;
                        objCreditLineItem.Package__c = invoicemap.get(invoiceId).Package__c;
                        objCreditLineItem.Invoice_Line_Item__c = invoicemap.get(invoiceId).Id;
                        listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
                        listOfCreditmemolineitem.add(objCreditLineItem);
                        mapOfCreditmemolineitem.put('Refund Deposit'+invoiceId,listOfCreditmemolineitem);
                        newPendingCreditMemos.put('Refund Deposit'+invoiceId,objCreditMemo);
                        //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                        if(string.isNotBlank(objCreditLineItem.Invoice_Line_Item__c)){
                            updateCreditMemoAmountInvoiceLineItem.put(objCreditLineItem.Invoice_Line_Item__c,updateInvoiceLineItemMap( updateInvoiceLineItem,depositAmount,0,objCreditLineItem.Invoice_Line_Item__c));
                        }
                        // added by nishi: 5-Nov-2020: for if we not found any active enrolment all enrolments are withdrwal then we create a task to finance team for refund reminder.
                        if(mapOfQueue != null && mapOfQueue.size() > 0 && mapOfQueue.containskey('Finance Queue') && string.isNotBlank(mapOfQueue.get('Finance Queue').Queue.Id)){ 
                            mapOfRefundReminderTasks.put('Refund Deposit'+invoiceId,BillingUtility.createNewTask('Refund Reminder',objEnrol.id,lastLessonDateObj,mapOfQueue.get('Finance Queue').Queue.Id));
                        }
                        // added by nishi: 5-Nov-2020: for if we not found any active enrolment all enrolments are withdrwal then we create a task to finance team for refund reminder.  
                        /* 26-Apr-2021 end: rolments with multiple deposits meaning advancements at the time of withdrawal should have a separate credit memo created for each line item that is equal to deposit. 
                    Finance must refund the credit memos separately to their original charges.*/ 
                    }
                }
                 
        }
       //system.debug('isRefund'+isRefund);
         // we need to refund current month amount if applicable
        if(isRefund){
            String chargeId =  fetchCurrentMonthPaymentEntry(objEnrol,lastLessonDateObj); // 21-8-2020
             // added by nishi: 21-aug-2020: for if next month invoice already generated then we create next month payment records
            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1); // 1-10-2020
                      
            Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
            Map<String,Invoice_line_item__c> mapofinvoicelineitem = new Map<String,Invoice_line_item__c>();
            system.debug('@@@isPromotionalEnrolment'+isPromotionalEnrolment);
            for(Invoice__c invoiceobj : UpgradeDowngradeController.getInvoiceDetails(objEnrol,lastLessonDateObj,objSubLineItem)){
                //added by nishi: 23-oct-2020:start: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  and refund all prepayement effective months 
                if(isPromotionalEnrolment){
                    system.debug('@@@invoiceobj'+invoiceobj);
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
                //added by nishi: 23-oct-2020:end: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  and refund all prepayement effective months 
                    //string invoiceMonth ='';
                    // if(invoiceobj.Invoice_Date__c.month() == lastLessonDateObj.month())
                    //     invoiceMonth = 'Current';
                    // if(nextBillDate >= nextMonthDate && lastLessonDateObj.month() < nextMonthDate.addMonths(-1).month() && invoiceobj.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() )
                    //     invoiceMonth = 'Next Month';
                    // system.debug('invoiceMonth'+invoiceMonth);
                    // if(string.isnotBlank(invoiceMonth)){
                    //     mapofinvoice.put(invoiceMonth,invoiceobj);
                    if(invoiceobj.invoice_type__c == 'Recurring'){
                        for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                            string invoiceMonth ='';
                            if(objlineitem.month__c.month() == lastLessonDateObj.month())
                                        invoiceMonth = 'Current';
                            if(nextBillDate >= nextMonthDate && lastLessonDateObj.month() < nextMonthDate.addMonths(-1).month() && objlineitem.month__c.month() == nextMonthDate.addMonths(-1).month() )
                                invoiceMonth = 'Next Month';
                            if(string.isnotBlank(invoiceMonth)){
                                mapofinvoice.put(invoiceMonth,invoiceobj);
                                updateInvoiceLineItem.put(objlineitem.id,objlineitem);
                                system.debug('objlineitem'+objlineitem);
                                if(!objlineitem.Is_Discount__c)
                                mapofinvoicelineitem.put(invoiceMonth,objlineitem);
                            }
                        }
                    }
                    //}
                }
            }
            // added by nishi: 21-aug-2020: for if next month invoice already generated then we create next month payment records
            listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
            if(!isPromotionalEnrolment && nextBillDate >= nextMonthDate && lastLessonDateObj.Month() < nextMonthDate.addMonths(-1).Month()){ 
                Decimal refundNextMonthAmount = getLessonRefundAmount(objEnrol,nextMonthDate.addMonths(-1),false); // 1-9-2020
                if(refundNextMonthAmount > 0){
                     //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
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
                    String refundNextMontAmountWithTax = getLessonRefundAmountWithTax(objEnrol,nextMonthDate.addMonths(-1),false);//8
                    if(refundNextMontAmountWithTax.split('@') != null &&  refundNextMontAmountWithTax.split('@').size() > 0){
                        system.debug('refundNextMontAmountWithTax'+refundNextMontAmountWithTax);
                        Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Decimal.valueOf(refundNextMontAmountWithTax.split('@')[0]),
                                                        Decimal.valueOf(refundNextMontAmountWithTax.split('@')[1]),null,
                                                        objEnrol.id,invoicelineitemId,'Refund  (Next month invoice amount)');
                                                        objCreditLineItem.Month__c = lastLessonDateObj;
                        listOfCreditmemolineitem.add(objCreditLineItem);
                        //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                        if(string.isNotBlank(invoicelineitemId)){
                            updateCreditMemoAmountInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,Decimal.valueOf(refundNextMontAmountWithTax.split('@')[0]),Decimal.valueOf(refundNextMontAmountWithTax.split('@')[1]),invoicelineitemId));
                        }
                    }
                     //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.    
                    
                     //commented by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
                        /* Payment__c objPay = new Payment__c();
                        if(hasMoreEnrolment){  
                            objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundNextMonthAmount, ConstantsClass.paymentPendingStatus);
                        }else{
                        system.debug('refundNextMonthAmount'+refundNextMonthAmount);
                        //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
                        
                            objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundNextMonthAmount, ConstantsClass.paymentSuccessStatus);
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
                            paymentList.add(objPay);
                        }*/
                            //commented by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
                   
                }
               //system.debug('refundNextMonthAmount'+refundNextMonthAmount);
               //system.debug('paymentList'+paymentList);
            }
             //end: added by nishi: 21-aug-2020: for if next month invoice already generated then we create next month payment records
           //system.debug(refundAmount);
           
           //added by nishi: 23-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  and refund all prepayement effective months 
            if(isPromotionalEnrolment){
                List<Credit_memo_line_item__c> listOfCreditMemoForPrepaymentInvoice = createCreditMemoForPrepaymentInvoice( objSubLineItem,objEnrol,lastLessonDateObj);
                system.debug('listOfCreditMemoForPrepaymentInvoice'+listOfCreditMemoForPrepaymentInvoice);
                if(listOfCreditMemoForPrepaymentInvoice != null && listOfCreditMemoForPrepaymentInvoice.size() > 0) {
                    listOfCreditmemolineitem.addAll(listOfCreditMemoForPrepaymentInvoice);
                } 
                Decimal refundDiscountAmount = getLessonRefundAmount(objEnrol,lastLessonDateObj,isPromotionalEnrolment);//8
                if(refundDiscountAmount > 0){
                    String invoiceDiscountlineitemId = null;
                    if(mapofinvoicelineitem.containskey('DiscountInvoice')){
                        invoiceDiscountlineitemId =mapofinvoicelineitem.get('DiscountInvoice').id; 
                    }
                    String refundDiscountAmountWithTax = getLessonRefundAmountWithTax(objEnrol,lastLessonDateObj,isPromotionalEnrolment);
                    if(refundDiscountAmountWithTax.split('@') != null &&  refundDiscountAmountWithTax.split('@').size() > 0){
                        system.debug('refundAmountWithTax'+refundDiscountAmountWithTax);
                        Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(-Decimal.valueOf(refundDiscountAmountWithTax.split('@')[0]),
                                                        -Decimal.valueOf(refundDiscountAmountWithTax.split('@')[1]),null,
                                                        objEnrol.id,invoiceDiscountlineitemId,'Refund  (Effective month invoice amount)',lastLessonDateObj);
                                                        objCreditLineItem.is_Discount__c = true;
                        listOfCreditmemolineitem.add(objCreditLineItem); 
                        if(string.isNotBlank(invoiceDiscountlineitemId)){
                            updateCreditMemoAmountInvoiceLineItem.put(invoiceDiscountlineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,(-Decimal.valueOf(refundDiscountAmountWithTax.split('@')[0])),
                            (-Decimal.valueOf(refundDiscountAmountWithTax.split('@')[1])),invoiceDiscountlineitemId));
                        }
                    }
                } 
            }   
            //added by nishi: 23-oct-2020:end: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  and refund all prepayement effective months 
           
            //added by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
            Decimal refundAmount = getLessonRefundAmount(objEnrol,lastLessonDateObj,false);//8
            system.debug('listOfCreditmemolineitem'+listOfCreditmemolineitem);  
            if(refundAmount > 0){
                String invoicelineitemId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 && mapofinvoice.containskey('Current')){
                    if(mapofinvoice.get('Current').Invoice_Line_Items__r != null && mapofinvoice.get('Current').Invoice_Line_Items__r.size()>0){
                        invoicelineitemId =mapofinvoice.get('Current').Invoice_Line_Items__r[0].id; 
                    }
                }
                String refundAmountWithTax = getLessonRefundAmountWithTax(objEnrol,lastLessonDateObj,false);
                if(refundAmountWithTax.split('@') != null &&  refundAmountWithTax.split('@').size() > 0){
                    system.debug('refundAmountWithTax'+refundAmountWithTax);
                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(Decimal.valueOf(refundAmountWithTax.split('@')[0]),
                                                    Decimal.valueOf(refundAmountWithTax.split('@')[1]),null,
                                                    objEnrol.id,invoicelineitemId,'Refund  (Effective month invoice amount)',lastLessonDateObj);
                    listOfCreditmemolineitem.add(objCreditLineItem); 
                    //added by Nishi: 19-oct-2020: According to new requirement Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                    if(string.isNotBlank(invoicelineitemId)){
                        updateCreditMemoAmountInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,Decimal.valueOf(refundAmountWithTax.split('@')[0]),
                        Decimal.valueOf(refundAmountWithTax.split('@')[1]),invoicelineitemId));
                    }
                }
            }
            if(listOfCreditmemolineitem  != null && listOfCreditmemolineitem.size() > 0 ){
                string remark = isPromotionalEnrolment ?'Refund  (Prepayment Effective months invoice amount)':'Refund  (Effective month invoice amount)';
                String invoiceId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                    if(mapofinvoice.containskey('Current')){
                        invoiceId = mapofinvoice.get('Current').id;
                    }
                }
                Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId,  lastLessonDateObj,remark);
                newPendingCreditMemos.put(remark,objCreditMemo);
                mapOfCreditmemolineitem.put(remark,listOfCreditmemolineitem);
            }
            //added by nishi: 15-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.
            
            //commented by nishi: 15-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.

                /*if(hasMoreEnrolment){
                        objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundAmount, ConstantsClass.paymentPendingStatus);
                    
                }else{
                    objPay = BillingUtility.fillPayment(objEnrol.Parent__c,null, refundAmount, ConstantsClass.paymentSuccessStatus);
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
                    paymentList.add(objPay);
                    
                    
                   

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
                    objPay.last_lesson_date__c = lastLessonDateObj;*-/
                    //system.debug('objPay'+objPay);
                    
                }*/
                //commented by nishi: 15-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the success Payment as credit record.


                   
            
            
        }
        
        if(refundPayments.size() > 0){
            paymentList.addAll(refundPayments);
        }
         //added by nishi: 6-Oct-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
        if(newPendingCreditMemos.size() > 0){
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
             // added by nishi: 5-Nov-2020: for if we not found any active enrolment all enrolments are withdrwal then we create a task to finance team for refund reminder.
            if(mapOfRefundReminderTasks != null && mapOfRefundReminderTasks.size() > 0){
                for( string invoiceId : mapOfInvoicePayments.keyset()){
                    if(mapOfInvoicePayments.containsKey(invoiceId)){
                        if(mapOfRefundReminderTasks.containskey('Refund Deposit'+invoiceId)){
                            task objtask = mapOfRefundReminderTasks.get('Refund Deposit'+invoiceId);
                            objtask.WhatId = newPendingCreditMemos.get('Refund Deposit'+invoiceId).id;
                            mapOfRefundReminderTasks.put('Refund Deposit'+invoiceId,objtask);
                        }
                    }
                }
                insert mapOfRefundReminderTasks.values();
            }
            system.debug('mapOfRefundReminderTasks'+mapOfRefundReminderTasks);
            // added by nishi: 5-Nov-2020: for if we not found any active enrolment all enrolments are withdrwal then we create a task to finance team for refund reminder.
          
        }
         //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
      
        if(updateCreditMemoAmountInvoiceLineItem != null && updateCreditMemoAmountInvoiceLineItem.size() > 0){
            update updateCreditMemoAmountInvoiceLineItem.values();
        }
       
        system.debug('@@@updateInvoiceLineItem'+updateCreditMemoAmountInvoiceLineItem);
        if(paymentList.size() > 0){
            insert paymentList;
        }
       //system.debug('paymentList'+paymentList);
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


    public static List<Credit_memo_line_item__c>  createCreditMemoForPrepaymentInvoice(Subscription_Line_Item__c  objSubLineItem,enrolment__c enrolmentObj,Date effectDate){
        List<Invoice__c> listOfInvoice = UpgradeDowngradeController.getInvoiceDetails(enrolmentObj,effectDate.addmonths(1),objSubLineItem) ;
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
        List<Invoice_Line_Item__c> updateInvoiceLineItem = new List<Invoice_Line_Item__c>(); 
        system.debug('listOfInvoice'+listOfInvoice);
        set<string> creditmemoIds =new set<string>();
        if(listOfInvoice != null && listOfInvoice.size() > 0){
            for(Invoice__c objInvoice : listOfInvoice){
                if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                    // if invoice line item month is greater then effective month then we create credit memo and added credit memo line item
                    for(Invoice_Line_Item__c objInvLine : objInvoice.Invoice_Line_Items__r){
                        Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(objInvLine.Amount__c,
                                            objInvLine.GST_Amount__c,objInvLine.Package__c,
                                            objInvLine.Enrolment__c,objInvLine.id,objInvLine.Remarks__c,objInvLine.Month__c);
                        objCreditLineItem.Is_Deposit__c=objInvLine.Is_Deposit__c;
                        objCreditLineItem.Is_Discount__c=objInvLine.Is_Discount__c;
                        listOfCreditmemolineitem.add(objCreditLineItem);                                      
                        //Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                        objInvLine.Credit_Memo_Amount__c = objInvLine.Amount__c;
                        if( objInvLine.GST_Amount__c != Null ){
                            objInvLine.Credit_Memo_Tax__c = objInvLine.GST_Amount__c;
                        }
                        updateInvoiceLineItem.add(objInvLine);
                    }
                }
            }
            if(updateInvoiceLineItem != null && updateInvoiceLineItem.size() > 0){
                update updateInvoiceLineItem;
            }
        }
        
        return listOfCreditmemolineitem;
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
                                         //AND Invoice_Date__c >=: firstDate 
                                         //AND Invoice_Date__c <=: lastDate 
                                         AND Status__c = 'Paid' 
                                         Order By total_amount__c ];
        if(listOfInvoice.size()>0){
            chargeId = listOfInvoice[0].Stripe_charge_id__c;
        }
       //system.debug('listOfInvoice'+listOfInvoice);
       //system.debug('chargeId'+chargeId);
        return chargeId;   
                                       
    }

    Private static Decimal getLessonRefundAmount(Enrolment__c objEnrol,Date lastLessonDate,boolean isPromotionalEnrolment){
        Decimal amount = 0;
        List<Booking__c> bookings = getCurrentBilledBooking(objEnrol.id,lastLessonDate);
        Integer count= 0;
        Integer regularcount= 0;
        for(Booking__c objBook : bookings){
            if(objBook.booking_date__c > lastLessonDate){
                count+=1;
                if(objBook.Type__c=='Regular'){
                    regularcount+=1;
                }
            }
        }
        if(count >0){
            amount = count * objEnrol.package__r.unit_fee__c;
            if(String.isNotBlank(objEnrol.Id) && String.isNotBlank(objEnrol.Center__c) && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                amount+= (amount  *  objEnrol.Center__r.Country__r.Tax_Rate__c) / 100;
            }
        }
        //added by nishi: 24-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  
        if(isPromotionalEnrolment){
            if(regularcount >0){
                Decimal noOfMonths = String.isNotBlank(objEnrol.Package__r.Promotion_period_In_months__c) ? Integer.valueOf(objEnrol.Package__r.Promotion_period_In_months__c) : 1;
                amount = objEnrol.Package__r.Promotion_Discount__c != null ?(((objEnrol.Package__r.Promotion_Discount__c / noOfMonths)/4)*regularcount) :0;
                if(objEnrol.Center__r != null 
                    && objEnrol.Center__r.Country__r != null 
                    && objEnrol.Center__r.Country__r.Tax_Rate__c != null
                    && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                        amount += (amount * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
                }
            }
        }
        //added by nishi: 24-oct-2020:end: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  
        return amount;
    }
    Private static String getLessonRefundAmountWithTax(Enrolment__c objEnrol,Date lastLessonDate,Boolean isPromotionalEnrolment){
        Decimal amount = 0;
        Decimal taxamount = 0;
        List<Booking__c> bookings = getCurrentBilledBooking(objEnrol.id,lastLessonDate);
        Integer count= 0;
        Integer regularcount= 0;
        for(Booking__c objBook : bookings){
            if(objBook.booking_date__c > lastLessonDate){
                count+=1;
                if(objBook.Type__c=='Regular'){
                    regularcount+=1;
                }
            }
        }
        if(count >0){
            amount = count * objEnrol.package__r.unit_fee__c;
            if(String.isNotBlank(objEnrol.Id) && String.isNotBlank(objEnrol.Center__c) && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                taxamount+= (amount  *  objEnrol.Center__r.Country__r.Tax_Rate__c) / 100;
            }
        }
        //added by nishi: 24-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  
        if(isPromotionalEnrolment){
            if(regularcount >0){
                Decimal noOfMonths = String.isNotBlank(objEnrol.Package__r.Promotion_period_In_months__c) ? Integer.valueOf(objEnrol.Package__r.Promotion_period_In_months__c) : 1;
                amount = objEnrol.Package__r.Promotion_Discount__c != null ?(((objEnrol.Package__r.Promotion_Discount__c / noOfMonths)/4)*regularcount) :0;
                if(objEnrol.Center__r != null 
                    && objEnrol.Center__r.Country__r != null 
                    && objEnrol.Center__r.Country__r.Tax_Rate__c != null
                    && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                        taxamount = (amount * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
                }
            }
        }
        //added by nishi: 24-oct-2020:end: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  
        return  amount+'@'+taxamount  ;
    }
    
    // return currentBilledBookings
    private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDate){ // 21-aug-2020  /// 1-Sep-2020
        Date firstDate = Date.newInstance(lastLessonDate.year(),lastLessonDate.month(),01);//1-aug-2020 ///// 1-Sep-2020
        Date lastDate = firstDate.addMonths(1).addDays(-1);//31-aug-2020///// 30-Sep-2020
        return [SELECT Booking_Date__c,Type__c FROM Booking__c WHERE Enrolment__c=: enrolId AND Booking_Date__c >=: firstDate AND Booking_Date__c <=: lastDate
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
       //system.debug('@@@enroll'+enroll);
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