public class WithDrawlEnrolmentClassSummaryController {
    public  AureusCalendarController.WithdrawalSummary withdrawSummary{get;set;}  
    public string bookingId {get;set;}
    
    public Enrolment__c enrollmentObj{get;set;}
    public String bank_Name{get;set;}
    public String bank_Account_No{get;set;}
    public String refundMethod{get;set;}
    public WithDrawlEnrolmentClassSummaryController(){
        String parentId = '';
        Decimal unitTotal= 0;
        bookingId=ApexPages.currentPage().getParameters().get('id');
        list<Enrolment__c> enrol = new list<Enrolment__c>([SELECT Id, Package_Process_Request_Date__c, Effective_Date__c, 
                                                           Reason_of_Withdraw__c,Package__r.Name,Parent__r.Name,Student__r.Name, 
                                                           Feedback_Comments__c, Lesson_Day__c, Refund_Method__c, Lesson_Start_Time__c, 
                                                           Notice_Period_Start_Date__c, Notice_Period_End_Date__c, 
                                                           Parent__r.Bank_Name__c, Parent__r.Bank_Account_No__c,Package_Process_Status__c FROM Enrolment__c 
                                                           WHERE id =: bookingId]);
        System.debug('@@@enrol '+enrol);
        if(enrol.size()>0){
        
            enrollmentObj = new Enrolment__c();
            enrollmentObj = enrol[0];
            bank_Name = enrollmentObj.Parent__r.Bank_Name__c;
            bank_Account_No =  enrollmentObj.Parent__r.Bank_Account_No__c;
            Date withdrawEndDate = enrol[0].Package_Process_Request_Date__c;
            Date lastLessonDate= enrol[0].Effective_Date__c;
            System.debug('enrol[0].Effective_Date__c; '+enrol[0].Effective_Date__c);
            withdrawSummary = new AureusCalendarController.WithdrawalSummary();
            Date withdrawEndDateObj, lastLessonDateObj, nextBillingDate;
            Map<String, List<Date>> dtMap = new Map<String, List<Date>>();
            List<AureusCalendarController.Lessons> lastLessonsList = new List<AureusCalendarController.Lessons>();
            List<AureusCalendarController.Lessons> makeupPendingList = new List<AureusCalendarController.Lessons>();
            parentId = enrollmentObj.Parent__c;
            checkRefundMethod(enrollmentObj.Id, parentId, withdrawEndDate);
            Enrolment__c enrolment;
            
            if(withdrawEndDate <> null){
                withdrawEndDateObj = Date.valueOf(withdrawEndDate);
            }
            if(lastLessonDate <> null){
                lastLessonDateObj = Date.valueOf(lastLessonDate);
            }
            if(String.isNotBlank(bookingId)){
                enrolment = getEnrolDetails(bookingId);
            }
            if(enrolment <> null){
                if(String.isNotBlank(enrolment.Id)){
                    nextBillingDate = getNextBillingDate(enrolment.Id);
                    if(String.isNotBlank(enrolment.Id) && lastLessonDateObj != NULL && nextBillingDate != NULL){
                        withdrawSummary.lastLessons = classEditController.getLast4Lessons(enrolment.Id, lastLessonDateObj, nextBillingDate);
                        withdrawSummary.finalDeposits = AureusCalendarController.getFinalDepositSummary(withdrawSummary.lastLessons);
                        withdrawSummary.makeupLessons = classEditController.getPendingMakeupBookings(enrolment.Id, lastLessonDateObj);   
                    }
                }
            }
            if(enrolment != NULL){
                Decimal total = 0, gst = 0;
                DateTime dt;
                if(enrolment.Lessons_Start_Date__c <> null){
                   dt = DateTime.newInstance(enrolment.Lessons_Start_Date__c, enrolment.Lesson_Start_time__c); 
                }
                
                withdrawSummary.student = enrolment.student__r.Name;
                withdrawSummary.packageName = enrolment.Package__r.Name;
                withdrawSummary.centre = enrolment.Center__r.Name;
                withdrawSummary.refund = 0;
                if(dt <> null){
                    withdrawSummary.LessonDay = dt.format('dd MMM, yyyy hh:mma');   
                }
                if(withdrawEndDateObj <> null){
                     dt = DateTime.newInstance(withdrawEndDateObj, enrolment.Lesson_Start_time__c); 
                }
                if(dt <> null){
                    withdrawSummary.noticeDate = dt.format('dd MMM, yyyy');   
                }
                 if(lastLessonDateObj <> null){
                     dt = DateTime.newInstance(lastLessonDateObj, enrolment.Lesson_Start_time__c);
                }
                if(dt <> null){
                    withdrawSummary.lastDate = dt.format('dd MMM, yyyy');  
                }
                
                //withdrawSummary.deposit = enrolment.Package__r.Deposit_Fee__c;
                withdrawSummary.deposit = AureusCalendarController.getDepositFromFile(enrolment.id);
                System.debug('withdrawSummary.deposit'+withdrawSummary.deposit);
                if(withdrawSummary.finalDeposits <> null){
                    if(withdrawSummary.finalDeposits.size() > 0){
                        for(AureusCalendarController.Lessons currentLesson : withdrawSummary.finalDeposits){
                            total += currentLesson.unitPrice;
                        }
                        if(total > 0 && enrolment.Center__r.Country__r.Tax_Rate__c > 0){
                            gst = total  * (enrolment.Center__r.Country__r.Tax_Rate__c / 100);
                        }
                    } 
                }
                
                
                String chargeId = AureusCalendarController.fetchCurrentMonthPaymentEntry(enrolment,lastLessonDateObj);
                if(lastLessonDateObj != NULL){
                     Date firstDate = Date.newInstance(lastLessonDateObj.year(),lastLessonDateObj.month(),01);
                     Date lastDate = firstDate.addMonths(1).addDays(-1);
                     dtMap = BillingUtility.getDateMap(firstDate, lastDate);
                     System.debug(dtMap);
                }
                System.debug(total + '-'+gst+'-'+chargeId );
                if(gst > 0){
                    withdrawSummary.total = total + gst;
                }else{
                    withdrawSummary.total = total;
                }
                
                withdrawSummary.gst = gst;
                withdrawSummary.refund = withdrawSummary.deposit - withdrawSummary.total;
                if(String.isNotBlank(chargeId) && (lastLessonDateObj < nextBillingDate) && dtMap.containsKey(enrolment.Lesson_Day__c)){
                    Set<Date> cancelledBookingDates = getThisMonthCancelledLessons(enrolment.Id);
                    for(Date dateObj : dtMap.get(enrolment.Lesson_Day__c)){
                        if((dateObj > lastLessonDateObj) && !cancelledBookingDates.contains(dateObj)){
                            unitTotal += enrolment.Package__r.Unit_Fee__c;
                        }
                    }
                    if(unitTotal > 0 && enrolment.Center__r.Country__r.Tax_Rate__c > 0){
                        withdrawSummary.refund += unitTotal;
                        withdrawSummary.refund += unitTotal * (enrolment.Center__r.Country__r.Tax_Rate__c / 100);  
                    }else{
                        withdrawSummary.refund += unitTotal;
                    }
                    
                }
            }
        }
    } 
    // we do not need to refund amount of cancelled dates, when we refund amount of next month.
    private static Set<Date> getThisMonthCancelledLessons(String EnrolId){
        Set<Date> cancelledDates  = new Set<Date>();
        String typeRegular = ConstantsClass.typeRegular;
        String statusCancelled = ConstantsClass.statusCanceled;
        
        for(Booking__c booking : [SELECT Booking_Date__c FROM Booking__c 
                                    WHERE Enrolment__c =: enrolId 
                                    AND Type__c=:ConstantsClass.groupLessonTypeBooking AND 
                                  Status__c =:statusCancelled]){
            cancelledDates.add(booking.Booking_Date__c);
        }
        return cancelledDates;
    }
    
    
    private static Enrolment__c getEnrolDetails(String bookingId){
        Enrolment__c enrol = new Enrolment__c();
        List<Enrolment__c> enrolList = [SELECT Id, Student__r.Name, Package__r.Name, Package__r.Deposit_Fee__c, Package__r.Unit_Fee__c, 
                                        Center__r.Name, Lessons_Start_Date__c, Lesson_Start_time__c, Notice_Period_End_Date__c, 
                                        Effective_Date__c, Lesson_Day__c,Center__r.Country__r.Tax_rate__c 
                                        FROM Enrolment__c 
                                        WHERE Id =:bookingId];
        return enrolList.size() > 0 ? enrolList[0] : null;
    }
    
    private static Date getNextBillingDate(String enrolId){
        Date nextBillingDate;
        List<Subscription_Line_Item__c> subscriptionLineItemList = [SELECT Id, Next_Bill_Date__c 
                                                                    FROM Subscription_Line_Item__c
                                                                     WHERE Enrolment__c =: enrolId];
        if(subscriptionLineItemList.size() > 0){
            nextBillingDate = subscriptionLineItemList[0].Next_Bill_Date__c;
        }
        return nextBillingDate;
    }
    private static List<AureusCalendarController.Lessons> getFinalDepositSummary(List<AureusCalendarController.lessons> lessons){
        List<AureusCalendarController.Lessons> depositLessons = new List<AureusCalendarController.Lessons>();
        AureusCalendarController.Lessons currentLesson = new AureusCalendarController.Lessons();
        if(lessons.size() > 0){
            for(AureusCalendarController.Lessons lesson : lessons){
                if(lesson.status == 'Deposit'){
                    currentLesson = new AureusCalendarController.Lessons();
                    currentLesson.Lesson = lesson.Lesson + ' - ' +lesson.bookingDate;
                    currentLesson.student = lesson.student;
                    currentLesson.qty = lesson.qty;
                    currentLesson.unitPrice = lesson.unitPrice ;
                    currentLesson.total = lesson.unitPrice * lesson.qty;
                    depositLessons.add(currentLesson);
                }
                
            }
        }
        return depositLessons;
    }
    
    
     public pageReference saveEnrollment(){
        Account acc = new Account();
        if(String.isNotBlank(enrollmentObj.Parent__c)){
            acc.Id = enrollmentObj.Parent__c;
            acc.Bank_Name__c = bank_Name;
            acc.Bank_Account_No__c = Bank_Account_No;
        }
        if(String.isNotBlank(acc.Id)){
            update acc;
        }
        if(enrollmentObj != null){
            enrollmentObj.Refund_Method__c = refundMethod;
            update enrollmentObj;
        }
        PageReference pageRef = new pageReference('/apex/thankyouPage');
        return pageRef;
    }
    
    private String checkRefundMethod(String enrolmentId, String parentId, Date withdrawalEndDate){
        Date startDate, endDate;
        if(withdrawalEndDate != NULL){
            startDate = Date.newInstance(withdrawalEndDate.year(), withdrawalEndDate.month(), 01);
            endDate = startDate.addMonths(1).addDays(-1);
        }
        Boolean findRefundMethod = false;
        if(String.isNotBlank(parentId)){
            List<Enrolment__c> enrolList = [SELECT Id, Package_Process_Type__c, Package_Process_Status__c, Effective_Date__c 
                                            FROM Enrolment__c 
                                            WHERE Parent__c =: parentId 
                                            AND Stage__c = :ConstantsClass.enroledStatus AND 
                                            Type__c = :ConstantsClass.enrolGroupType
                                            AND Package_Process_Type__c != :ConstantsClass.enrollmentProcessCancelType
                                            AND (NOT(Effective_Date__c >= :startDate AND Effective_Date__c <= :endDate))];
            if(enrolList.size() > 1){
                refundMethod = 'Apply to Next Invoice';
                findRefundMethod = true;
            }
        }
        
        if(String.isNotBlank(enrolmentId) && String.isNotBlank(checkInvoiceIsDeposit(enrolmentId)) && !findRefundMethod){
            refundMethod = 'Credit Card on File';
            findRefundMethod = true;
        }else if(!findRefundMethod){
            refundMethod = 'GIRo';
            findRefundMethod = true;
        }
        return refundMethod;
    }
    
    private String checkInvoiceIsDeposit(String enrolId){
        String chargeId;
        List<Invoice_Line_Item__c> invoiceLineItems = [SELECT Id, Invoice__r.Stripe_Charge_Id__c 
                                                        FROM Invoice_Line_Item__c 
                                                        WHERE Enrolment__c =: enrolId
                                                        AND Is_Deposit__c = true];
        for(Invoice_Line_Item__c item : invoiceLineItems){
            if(String.isNotBlank(item.Invoice__r.Stripe_Charge_Id__c)){
                chargeId = item.Invoice__r.Stripe_Charge_Id__c;
                break;
            }
        }
        return chargeId;
    }
       
     
}