public class WithdrawController {
    public  WithdrawalSummary withdrawSummary{get;set;}  
    public string bookingId {get;set;}
    
    public Enrolment__c enrollmentObj{get;set;}
    public String bank_Name{get;set;}
    public String bank_Account_No{get;set;}
    public String refundMethod{get;set;}
    public WithdrawController(){
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
            withdrawSummary = new WithdrawalSummary();
            Date withdrawEndDateObj, lastLessonDateObj, nextBillingDate;
            Map<String, List<Date>> dtMap = new Map<String, List<Date>>();
            List<Lessons> lastLessonsList = new List<Lessons>();
            List<Lessons> makeupPendingList = new List<Lessons>();
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
                        withdrawSummary.lastLessons = getLast4Lessons(enrolment.Id, lastLessonDateObj, nextBillingDate);
                        withdrawSummary.finalDeposits = getFinalDepositSummary(withdrawSummary.lastLessons);
                        withdrawSummary.makeupLessons = getPendingMakeupBookings(enrolment.Id, lastLessonDateObj);   
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
                        for(Lessons currentLesson : withdrawSummary.finalDeposits){
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
        
        for(Booking__c booking : [SELECT Booking_Date__c FROM Booking__c WHERE Enrolment__c =: enrolId AND Type__c=:typeRegular AND 
                                  Status__c =:statusCancelled]){
            cancelledDates.add(booking.Booking_Date__c);
        }
        return cancelledDates;
    }
    
    private static List<Lessons> getLast4Lessons(String enrolId, Date lastLessonDateObj, Date nextBillingDate){
        Map<String, String> mapOfInvoiceName = new Map<String, String>();
        mapOfInvoiceName = AureusCalendarController.getInvoiceFromEnrolment(enrolId);
        List<Lessons> lessonsList = new List<Lessons>();
        Lessons lesson = new Lessons();
        List<Lessons> reverselessonList = new List<Lessons>();
        String typeRegular = ConstantsClass.typeRegular;
        Set<String> bookingStatus = new Set<String>();
        bookingStatus.add(ConstantsClass.statusScheduled); 
        bookingStatus.add(ConstantsClass.statusPending);
        Datetime formatedDate;
        //system.debug('enrolId'+ enrolId+ 'lastLessonDateObj' + lastLessonDateObj + 'nextBillingDate' + nextBillingDate +'bookingStatus'+bookingStatus);
        for(Booking__c bookObj : [SELECT Id, Name, type__c, Status__c, Booking_Date__c, Start_Time__c, Duration__c, Package__c,
                                  Package__r.Name, Package__r.Unit_Fee__c, Student__r.Name FROM Booking__c WHERE Enrolment__c =: enrolId AND Type__c =: typeRegular 
                                  AND Booking_Date__c <= :lastLessonDateObj ORDER BY Booking_Date__c DESC LIMIT 4]){
                                      lesson = new Lessons();
                                      formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
                                      lesson.bookingId = bookObj.Id;
                                      lesson.Lesson = bookObj.Package__r.Name;
                                      lesson.bookingDate = formatedDate.format('dd MMM, yyyy');
                                      lesson.bookingTime = formatedDate.format('hh:mma');
                                      lesson.duration = bookObj.Duration__c;
                                      lesson.unitPrice = bookObj.Package__r.Unit_Fee__c;
                                      lesson.student = bookObj.Student__r.Name;
                                      lesson.qty = 1;
                                      if(bookObj.Booking_Date__c < nextBillingDate){
                                           if(mapOfInvoiceName.keyset().size() > 0){
                                                lesson.status = mapOfInvoiceName.get('Id')+':'+ mapOfInvoiceName.get('Name');
                                            }else{
                                                lesson.status = 'Billed';
                                            }
                                      }else if(bookObj.Booking_Date__c >= nextBillingDate){
                                          lesson.status = 'Deposit';
                                      }
                                      reverselessonList.add(lesson); 
                                  }
        if(reverselessonList.size() > 0){
            for(integer i = reverselessonList.size() - 1; i >= 0; i--){
                lessonsList.add(reverselessonList[i]);
            }
        }
        return lessonsList;
    }  
    
    
    private static Enrolment__c getEnrolDetails(String bookingId){
        Enrolment__c enrol = new Enrolment__c();
        List<Enrolment__c> enrolList = [SELECT Id, Student__r.Name, Package__r.Name, Package__r.Deposit_Fee__c, Package__r.Unit_Fee__c, 
                                        Center__r.Name, Lessons_Start_Date__c, Lesson_Start_time__c, Notice_Period_End_Date__c, 
                                        Effective_Date__c, Lesson_Day__c, Center__r.Country__r.Tax_rate__c FROM Enrolment__c WHERE Id =:bookingId];
        return enrolList.size() > 0 ? enrolList[0] : null;
    }
    
    private static Date getNextBillingDate(String enrolId){
        Date nextBillingDate;
        List<Subscription_Line_Item__c> subscriptionLineItemList = [SELECT Id, Next_Bill_Date__c FROM Subscription_Line_Item__c WHERE Enrolment__c =: enrolId];
        if(subscriptionLineItemList.size() > 0){
            nextBillingDate = subscriptionLineItemList[0].Next_Bill_Date__c;
        }
        return nextBillingDate;
    }
    private static List<Lessons> getFinalDepositSummary(List<lessons> lessons){
        List<Lessons> depositLessons = new List<Lessons>();
        Lessons currentLesson = new Lessons();
        if(lessons.size() > 0){
            for(Lessons lesson : lessons){
                if(lesson.status == 'Deposit'){
                    currentLesson = new Lessons();
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
    private static List<Lessons> getPendingMakeupBookings(String enrolId, Date lastLessonDateObj){
        List<Lessons> lessonsList = new List<Lessons>();
        Lessons lesson = new Lessons();
        Set<String> bookingTypes = new Set<String>();
        bookingTypes.add(ConstantsClass.typeRegular);
        bookingTypes.add(ConstantsClass.typeAdhoc);
        String statusCanceled = ConstantsClass.statusCanceled;
        Datetime formatedDate, lastLessonDate;
        lastLessonDate = DateTime.newInstance(lastLessonDateObj, Time.newInstance(0, 0, 0, 0));
        for(Booking__c bookObj : [SELECT Id, Student__r.Name, Booking_Date__c, Canceled_Date__c, Start_Time__c, Available_Make_up_Units__c, Make_up_Expiry_Date__c FROM Booking__c WHERE enrolment__c =: enrolId AND Type__c IN: bookingTypes AND Status__c =: statusCanceled AND Available_Make_up_Units__c > 0 AND Make_up_Expiry_Date__c >= TODAY ORDER BY Canceled_Date__c]){
            lesson = new Lessons();
            formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
            lesson.bookingId = bookObj.Id;
            lesson.duration = bookObj.Available_Make_up_Units__c;
            lesson.bookingTime = formatedDate.format('hh:mma');
            lesson.student = bookObj.student__r.Name;
            DateTime dtBooking = DateTime.newInstance(bookObj.Booking_Date__c, Time.newInstance(0, 0, 0, 0));
            if(bookObj.Canceled_Date__c != NULL){
                lesson.cancelDate = dtBooking.format('dd MMM, yyyy'); 
            }else{
                lesson.cancelDate = '';
            }
            formatedDate = DateTime.newInstance(bookObj.Make_up_Expiry_Date__c, bookObj.Start_Time__c);
            lesson.expiryDate = formatedDate.format('dd MMM, yyyy');
            lesson.nextExpiryDate = lastLessonDate.format('dd MMM, yyyy');
            lessonsList.add(lesson);
        }
        return lessonsList;
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
            List<Enrolment__c> enrolList = [SELECT Id, Package_Process_Type__c, Package_Process_Status__c, Effective_Date__c FROM Enrolment__c 
                                            WHERE Parent__c =: parentId AND Stage__c = :ConstantsClass.enroledStatus AND 
                                            Type__c = :ConstantsClass.enrolRegularStatus AND Package_Process_Type__c != :ConstantsClass.enrollmentProcessCancelType
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
        List<Invoice_Line_Item__c> invoiceLineItems = [SELECT Id, Invoice__r.Stripe_Charge_Id__c FROM Invoice_Line_Item__c WHERE Enrolment__c =: enrolId AND Is_Deposit__c = true];
        for(Invoice_Line_Item__c item : invoiceLineItems){
            if(String.isNotBlank(item.Invoice__r.Stripe_Charge_Id__c)){
                chargeId = item.Invoice__r.Stripe_Charge_Id__c;
                break;
            }
        }
        return chargeId;
    }
       
    public class WithdrawalSummary{
        public List<Lessons> lastLessons{get;set;}
        public List<Lessons> makeupLessons{get;set;}
        public List<Lessons> finalDeposits{get;set;}
        public String student{get;set;}
        public String packageName{get;set;}
        public String centre{get;set;}
        public String LessonDay{get;set;}
        public String lastDate{get;set;}
        public String noticeDate{get;set;}
        public Decimal gst{get;set;}
        public Decimal total{get;set;}
        public Decimal deposit{get;set;}
        public Decimal refund{get;set;}
    }
    public class Lessons{
        public String bookingId{get;set;}
        public String Lesson{get;set;}
        public String bookingDate{get;set;}
        public String bookingTime{get;set;}
        public Decimal duration{get;set;}
        public String status{get;set;}
        public String student{get;set;}
        public String cancelDate{get;set;}
        public String expiryDate{get;set;}
        public String nextExpiryDate{get;set;}
        public Decimal unitPrice{get;set;}
        public Decimal total{get;set;}
        public integer qty{get;set;}
    }  
}