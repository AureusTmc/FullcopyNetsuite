global class LeaveRequestHelperBatch implements Database.Batchable<sObject> {
	 // fetching teacher name from the constant class
    private static string Teacher = ConstantsClass.teacherRecTypeName;
        // defined to store the teacher record Type
    private static Id TeacherRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Teacher).getRecordTypeId();
    // defined to map to working hour
    global map<string,string> mapToworkinghourBatch = new map<string,string>();
    // defining the sick leave record type
    private Id sickRecordType= Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByDeveloperName().get('Sick_Leave').getRecordTypeId();
    // defined to map the teacher with the leave request object
    global  map<Id,Leave_Request__c> mapToTeacherDateBatch=new map<Id,Leave_Request__c>();
    global Database.QueryLocator start(Database.BatchableContext BC){
        // fetch the record of teacher who is on leave
        SET<ID> keys = mapToTeacherDateBatch.keyset();
        string query='select Id,Name,Organisation__c,Employee_Duty_Type__c from Account where Id in :keys AND RecordTypeId=:TeacherRecordTypeId';
        system.debug('== batch size '+ ((List<Account> )database.query(query)).size());
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> techrList){
        // for creating Full day busy booking 
        list<Booking__c> BookingLeaveList = new list<Booking__c>();
        Time StartTime =Time.newInstance(08, 00, 00, 00);
        Time EndTime=Time.newInstance(20, 00, 00, 00);
        system.debug('mapToworkinghourBatch' + mapToworkinghourBatch);
        for(Account thrAcc:techrList){
            system.debug('== mapToTeacherDateBatch '+mapToTeacherDateBatch);
            if(mapToTeacherDateBatch.containsKey(thrAcc.Id)){
                Leave_Request__c lr = mapToTeacherDateBatch.get(thrAcc.Id);
                Integer totalDays = lr.Leave_Start_Date__c.daysBetween(lr.Leave_End_Date__c);
                Date startDate = lr.Leave_Start_Date__c;
				system.debug('totalDays'+totalDays);                
                for(integer i = 0; i<= totalDays; i++){
                    system.debug('startDate'+startDate);
                    Datetime dt = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
                    String dayOfWeek=dt.format('E');
                    string teacherId =string.valueOf(thrAcc.Id);
                    string KeyId=teacherId+'/'+dayOfWeek;
                    if(mapToworkinghourBatch.containsKey(KeyId) && mapToworkinghourBatch.get(KeyId).split('/')[2]==dayOfWeek ){
                        //system.debug('mapToTeacherDateBatch'+mapToTeacherDateBatch.get(teacherId).Sick_leave_start_Time__c +'--->'+startDate );
                        string CenterId =string.valueOf(mapToworkinghourBatch.get(KeyId).split('/')[3]); 
                        integer hr=integer.valueOf(mapToworkinghourBatch.get(KeyId).split('/')[0].split(':')[0]);
                        integer min=integer.valueOf(mapToworkinghourBatch.get(KeyId).split('/')[0].split(':')[1]);
                        StartTime=Time.newInstance(hr,min,00,00);
                        integer Ehr=integer.valueOf(mapToworkinghourBatch.get(KeyId).split('/')[1].split(':')[0]);
                        integer Emin=integer.valueOf(mapToworkinghourBatch.get(KeyId).split('/')[1].split(':')[1]);
                        EndTime=Time.newInstance(Ehr,Emin,00,00);
                        system.debug('--->'+EndTime);
                        string TeacherLeaveRemark=mapToTeacherDateBatch.get(teacherId).RecordTypeId==sickRecordType?'Sick Leave':'Teacher Leave';
                        Booking__c bkgLeaveObj = new Booking__c(End_Time__c=EndTime,Start_Time__c=StartTime,Status__c='Scheduled',Type__c='Busy',Category__c='Leave',Center__c=CenterId,Teacher_Account__c=teacherId,Booking_Date__c=startDate,Remarks__c=TeacherLeaveRemark);
                        BookingLeaveList.add(bkgLeaveObj); 
                    }
                    startDate=startDate.addDays(1);
                    
                }
                
            }  
        }
        system.debug('BookingLeaveList'+BookingLeaveList.size());
        if(BookingLeaveList.size()>0){
            insert BookingLeaveList;
        } 
    }
    
    global void finish(Database.BatchableContext BC){
    }
 
}