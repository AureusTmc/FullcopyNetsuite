global class PackageUpdateEnrolmentSchedular implements Schedulable{
    global void execute(SchedulableContext ctx){
        //Database.executeBatch(new PackageUpdateEnrolmentBatch());// commented by nishi:5-Jan-2021:  to solve  Too many DML rows: 10001 error
        Database.executeBatch(new PackageUpdateEnrolmentBatch(),50);
    }
}