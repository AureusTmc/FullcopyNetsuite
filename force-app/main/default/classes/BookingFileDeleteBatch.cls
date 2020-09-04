global class BookingFileDeleteBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Booking_Date__c FROM Booking__c WHERE Booking_Date__c <= TODAY';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Booking__c> scope){
        Set<Id> bookingIds = new Set<Id>();
        for(Booking__c obj : scope){
            if(((Date.valueOf(obj.Booking_Date__c)).daysBetween(system.today())) >= Integer.valueOf(System.Label.Max_Days_for_Booking_expire)){
                bookingIds.add(obj.Id);
            }
        }
        if(bookingIds.size() > 0){
            List<Attachment> attachList = [SELECT Id, Parent.Name, Parent.Type FROM Attachment WHERE ParentId IN :bookingIds];
        	delete attachList;
        }
    }    
    global void finish(Database.BatchableContext bc){
    
    }    
}