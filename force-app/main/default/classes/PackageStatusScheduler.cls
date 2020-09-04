/*
Name		:	PackageStatusScheduler
Date		:	23 Jul 2019
Author		:	Arpit vijayvergiya
Description :	This class is being used for scheduling PackageStatusBatch.
*/

global class PackageStatusScheduler implements Schedulable{
	global void execute (SchedulableContext ctx) {
        Database.executeBatch(new PackageStatusBatch());
    }
}