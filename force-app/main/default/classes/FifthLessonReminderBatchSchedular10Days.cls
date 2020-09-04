/*
 *  Name         :  FifthLessonReminderBatchSchedular10Days        
 *  Created Date :  10/14/2019
 *  Description  :  This is a Schedular Class for Scheduling the FifthLessonReminderBatch Before 10 days
 */
global class FifthLessonReminderBatchSchedular10Days implements Schedulable{
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new FifthLessonReminderBatch(System.today(), 10), 100);
    }
}