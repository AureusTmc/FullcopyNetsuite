/** Name        :    PreviousMonthRecordLockingSchedular
    Date        :    24-Sep-2020
    Author      :   nishi jain 
 * 
 * Description: A scheduled process will be developed to mark all those records as locked that belongs to the previous calendar month as below:
                1) All Paid and Void invoices whose invoice date is the previous calendar month  and its line items
                2) All Credit memo with (Status = Success, Customer No Response) with credit memo date in the previous calendar month and its line items.
                3) All payments with payment date in the previous calendar month

 */
global class PreviousMonthRecordLockingSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Date startDate = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 1);
        Integer daysInMonth = Date.daysInMonth(startDate.year(), startDate.month());
        Date endDate = Date.newInstance(startDate.year(), startDate.month(), daysInMonth);
        Database.executeBatch(new RecordLockingPaymentBatch(startDate,endDate),99);
        Database.executeBatch(new RecordLockingCreditMemoBatch(startDate,endDate),99);
       // Database.executeBatch(new RecordLockingInvoiceBatch(startDate,endDate),99); commented by nishi:25-sep-2020:any invoice run before payment then payment batch not worked so we run this batch after payment locking work completed 
     
    }
}