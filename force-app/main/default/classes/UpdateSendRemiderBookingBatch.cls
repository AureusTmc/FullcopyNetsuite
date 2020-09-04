// Added By Ravi on 20 june 2020 ...it basically update Send Reminder checkbox on basis of booking date value defined in Custom label
// When this batch upate Is Resc
global class UpdateSendRemiderBookingBatch implements Database.Batchable<sObject>,Database.stateful {
    public Integer totalNoOfRecords = 0;
    public DateTime startTime;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    // collect the batches of records or objects to be passed to execute
        totalNoOfRecords  = 0;
        startTime = system.now();
        Set<String> typeStr= new Set<String>{'Regular','Make-up','Ad-hoc'};
        Set<String> statusStr= new Set<String>{'Scheduled'};
        Date filterDat=System.today().addDays(Integer.valueOf(System.Label.filterDate));  
        String query = 'SELECT Id,Is_Send_Reminder__c from Booking__c where Type__c in:typeStr and Status__c in:statusStr and Is_Send_Reminder__c=false and  Booking_Date__c=:filterDat';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Booking__c> bookList) {
        totalNoOfRecords += bookList.size();
        List<Booking__c> bookingList = new List<Booking__c>();
        for(Booking__c bk : bookList) {
            Booking__c book = new Booking__c();
            book.Id=bk.Id;
            book.Is_Send_Reminder__c=True;
            bookingList.add(book);
        }
        try {
            if(bookingList.size()>0){
                update bookingList;    
            }
        } catch(Exception e) {
            System.debug('Line No'+e.getLineNumber() +'MSG'+e.getMessage());
        }
    
    }
    
    global void finish(Database.BatchableContext BC) {
        system.debug('-->>>'+ totalNoOfRecords +' startTime'+ startTime +'===='+System.Now()) ;
        Batch_Job_Log__c blog = new Batch_Job_Log__c();
        blog.Name = 'UpdateSendRemiderBookingBatch';
        blog.Start_Time__c = startTime;
        blog.End_Time__c = System.Now();
        blog.No_of_records_proceeds__c = totalNoOfRecords;
        insert blog;
    }
}