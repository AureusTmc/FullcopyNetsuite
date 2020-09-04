/*
        Name        :    CreateMonthlyInvoiceAmcClubSchedular
        Date        :    06/30/2019
        Author      :    Rajesh
        Description :    This Schedular class is used for CreateMonthlyInvoiceAmcClubBatch class
*/
global class CreateMonthlyInvoiceAmcClubSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new CreateMonthlyInvoiceAmcClubBatch());
    }
}