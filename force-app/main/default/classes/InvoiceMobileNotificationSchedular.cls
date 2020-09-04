/*
        Name        :    InvoiceMobileNotificationSchedular 
        Date        :    02/Aug/2019
        Author      :    Nishi
        Description :    This batch class is used to send reminder  notification after  3, 5 and 7 days.
        
*/
global class InvoiceMobileNotificationSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new InvoiceMobileNotificationBatch(3),99);
        Database.executeBatch(new InvoiceMobileNotificationBatch(5),99);
        Database.executeBatch(new InvoiceMobileNotificationBatch(7),99);
    }
}