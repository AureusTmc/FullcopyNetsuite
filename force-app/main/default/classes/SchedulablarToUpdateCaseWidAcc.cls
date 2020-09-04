global class SchedulablarToUpdateCaseWidAcc implements Schedulable {
    global void execute(SchedulableContext SC) {
        BatchClsToUpdateAccConOnChatCase batchApex1 = new BatchClsToUpdateAccConOnChatCase();
        ID batchprocessid1 = Database.executeBatch(batchApex1,integer.valueof(label.BatchSizeForSchedulablarToUpdateCaseWidAcccls)); 
        datetime schduledate = system.now().addminutes(2);
        String day = string.valueOf(schduledate.day());
        String month = string.valueOf(schduledate.month());
        String hour = string.valueOf(schduledate.hour()); 
        String minute = string.valueOf(schduledate.minute());
        
        String second = string.valueOf(schduledate.second());
        String year = string.valueOf(schduledate.year());
        String strJobName = 'Job-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new SchedulablarToUpdateCaseWidAcc());   
    }
   
    
}