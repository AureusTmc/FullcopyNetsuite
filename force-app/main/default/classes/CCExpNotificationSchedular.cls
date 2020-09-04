/*
        Name        :    ccExpNotificationSchedular 
        Date        :    05/Aug/2019
        Author      :  
        Description :    This Schedular class is used to send reminder in before expire 1st,2ed,3rd months
      
*/
global class CCExpNotificationSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new CCExpirationNotificationBatch(90),99);
        Database.executeBatch(new CCExpirationNotificationBatch(60),99);
        Database.executeBatch(new CCExpirationNotificationBatch(30),99);
        Database.executeBatch(new CCExpirationNotificationBatch(15),99);
    }
}