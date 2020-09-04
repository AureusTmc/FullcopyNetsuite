/*
Name        :    CarryForwardLeaveBatchScheduler
Date        :    03 September 2019
Author      :
Description :    Schedule CarryForwardLeaveBatch to run daily at 12 AM.
*/


global class CarryForwardLeaveBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      CarryForwardLeaveBatch carryForwardLeaveBatchObj = new CarryForwardLeaveBatch(null);
      Database.executeBatch(carryForwardLeaveBatchObj);
   }   
}