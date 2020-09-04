/*
Name        :    specialReferralDiscountBatchSheduler
Date        :    08 Aug 2020
Author      :  
Description :    This batch class is used to shedule the specialReferralDiscountBatch
*/

    global class specialReferralDiscountBatchSheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        specialReferralDiscountBatch spclRefrelDiscBatch = new specialReferralDiscountBatch();//Creating Batch Object
        database.executebatch(spclRefrelDiscBatch);//Executing batch 
    }
}