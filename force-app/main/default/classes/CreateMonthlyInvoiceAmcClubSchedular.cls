/*
        Name        :    CreateMonthlyInvoiceAmcClubSchedular
        Date        :    06/30/2019
        Author      :    Rajesh
        Description :    This Schedular class is used for CreateMonthlyInvoiceAmcClubBatch class
*/
global class CreateMonthlyInvoiceAmcClubSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new CreateMonthlyInvoiceAmcClubBatch(system.today().year(),system.today().month()));// Zakir 2-12-2020 :added 2 parameter in batch class   
        // Database.executeBatch(new CreateMonthlyInvoiceAmcClubBatch());
    }
}