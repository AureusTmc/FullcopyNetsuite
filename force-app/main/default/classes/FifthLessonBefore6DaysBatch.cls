/*
        Name        :    FifthLessonBefore6DaysBatch
        Date        :    09/23/2019
        Author      :  
        Description :    This batch class is used for the creating 
                         bookings in the place of 5th lessons.                          
        
*/
global class FifthLessonBefore6DaysBatch implements Database.Batchable<sObject>, database.stateful{ 
    global DateTime startTime;
    global integer noOfRecords;
    global Date fifthLessonDate;
    global FifthLessonBefore6DaysBatch(Date dateForProcess) {
        noOfRecords  = 0;
        startTime = system.now();
        if(dateForProcess != NULL){
            fifthLessonDate = dateForProcess.addDays(6);
        }
        System.debug('@@@dateForProcess'+fifthLessonDate);
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, center__c, Center__r.Name, Parent__c, Parent__r.Available_Make_up_Units__c, 
                                             Enrolment__r.Id, Enrolment__r.Student__c, Enrolment__r.Parent__c, 
                                            Enrolment__r.Parent__r.Available_Make_up_Units__c, Enrolment__r.Center__r.Country__r.Id,
                                            Enrolment__r.Center__r.Country__r.Country_Name__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                            Parent__r.Stripe_Customer_Id__c, 
                                            Package__r.Duration__c, Enrolment__r.Center__r.Name, Enrolment__r.package__r.Duration__c, Enrolment__r.Center__c, 
                                            Enrolment__r.Lesson_Start_time__c, isActive__c, Duration__c, Booking_Date__c, Enrolment__r.Teacher__c 
                                            FROM Fifth_Lesson__c 
                                            WHERE IsActive__c = TRUE 
                                            AND (Booking_date__c = : fifthLessonDate 
                                            AND DAY_IN_MONTH(Booking_date__c) > 28 ) 
                                            AND Booking__c = NULL]);
    }
    global void execute(Database.BatchableContext BC, List<Fifth_Lesson__c> fifthLessonsList){
        System.debug('@@@@@fifthLessonsList'+fifthLessonsList.size());
        if(fifthLessonsList.size() > 0){
            noOfRecords  += fifthLessonsList.size();
            AureusUtility.createFifthBookingBefore6Days(fifthLessonsList);
        }
        
    }
    global void finish(Database.BatchableContext BC){
        system.debug('complete');
        BillingUtility.createBatchLog('Fifth Lessons Batch Before 6 days',startTime,system.now(),noOfRecords);
        if(noOfRecords > 0){
            Database.executeBatch(new MonthlyPaymentBatch(), 50);
        }
    }
}