/*
        Name        :    MonthlyPaymentSchedular
        Date        :    09/02/2019
        Author      :  
        Description :    This Schedular class is used for Scheduling the payment collection batch called MonthlyPaymentBatch
        
*/
global class MonthlyPaymentSchedular implements Schedulable{
	global void execute(SchedulableContext sc) {
        MonthlyPaymentBatch batch = new MonthlyPaymentBatch();
        Database.executeBatch(batch, 50);  
    }
}