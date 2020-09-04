global class PackageUpdateEnrolmentSchedular implements Schedulable{
    global void execute(SchedulableContext ctx){
        Database.executeBatch(new PackageUpdateEnrolmentBatch());
    }
}