/*
Name		:	PostInvoiceBatchSchedular	
Date		:	30th July 2019			
Author		:	Arpit vijayvergiya
Description :	This class is being used for scheduling PostInvoiceBatch.
*/

global class PostInvoiceBatchSchedular implements Schedulable{
	global void execute (SchedulableContext ctx) {
        Database.executeBatch(new PostInvoiceBatch());
    }
}