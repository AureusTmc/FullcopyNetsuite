/*
Name		:	PreInvoiceBatchSchedular	
Date		:	30th July 2019			
Author		:	Arpit vijayvergiya
Description :	This class is being used for scheduling PreInvoiceBatch.
*/

global class PreInvoiceBatchSchedular implements Schedulable{
	global void execute (SchedulableContext ctx) {
        Database.executeBatch(new PreInvoiceBatch());
    }
}