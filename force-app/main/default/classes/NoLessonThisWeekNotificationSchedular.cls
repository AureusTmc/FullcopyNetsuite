/*
        Name        :    NoLessonThisWeekNotificationSchedular 
        Date        :    06/Aug/2019
        Author      :  
        Description :    This Schedular class is used to send reminder for No Lesson in this week.

      
*/
global class NoLessonThisWeekNotificationSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new NoLessonThisWeekNotificationBatch (),99);
    }
    
}