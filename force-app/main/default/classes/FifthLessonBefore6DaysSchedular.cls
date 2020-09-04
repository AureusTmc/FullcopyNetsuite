/*
 *  Name         :  FifthLessonBefore6DaysSchedular        
 *  Created Date :  10/14/2019
 *  Description  :  This is a Schedular Class for Scheduling the FifthLessonBefore6DaysBatch Before 6 days
 */
global with sharing class FifthLessonBefore6DaysSchedular implements Schedulable{
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new FifthLessonBefore6DaysBatch(System.today()), 200);
    }
}