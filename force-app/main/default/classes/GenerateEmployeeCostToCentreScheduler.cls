global class GenerateEmployeeCostToCentreScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
		Database.executeBatch(new GenerateEmployeeCostToCentreBatch(),100);      
   }
}