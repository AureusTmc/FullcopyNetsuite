/*
 *  Name         :  FifthLessonReminderBatchSchedular15Days        
 *  Created Date :  10/14/2019
 *  Description  :  This is a Schedular Class for Scheduling the FifthLessonReminderBatch Before 15 days
 */
global class FifthLessonReminderBatchSchedular15Days implements Schedulable{
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new FifthLessonReminderBatch(System.today(), 15), 100);
    }
}