global class ExpireEnrolmentBooking implements  Database.Batchable<sObject>{
	Private String PendingEnrolment= ConstantsClass.PendingEnrolment;
    
    global Database.QueryLocator start(Database.BatchableContext bc){ 
       integer noOfDay = (integer.valueOf(System.Label.Enrolment_expiry_period)/24);
        DateTime myDateTime = system.Now().addDays(-noOfDay);
        String query = 'Select Id,Status__c,Enrolment__r.Stage__c,Enrolment__c From Booking__c Where Enrolment__r.Stage__c =:PendingEnrolment AND Enrolment__r.Enrolment_Email_Date__c <=:myDateTime';
		      
        return Database.getQueryLocator(query); 
    }
    global void execute (Database.BatchableContext bc ,List<sObject> recordsList){
        System.debug('Execute-------'+recordsList.size());
        List<Booking__c> bookList = new List<Booking__c>();
        List<Enrolment__c> enrList = new List<Enrolment__c>();
        set<Id> bkgId = new set<Id>();
        set<Id> enrId = new set<Id>();
        List<Booking__C> records = (List<Booking__c>)recordsList;
        system.debug('records'+records);
        for(Booking__C bkg:records ){
            if(bkg.Status__c =='Blocked'){
                bkgId.add(bkg.Id);
            }
            enrId.add(bkg.Enrolment__c);
        }
        for(Enrolment__c enrLst :[select Id,Stage__c from Enrolment__c where Id in:enrId]){
            enrLst.stage__c='Attended';
            enrList.add(enrLst);
        }
        bookList=[Select Id from Booking__c where Id in:bkgId];
        system.debug('bookList'+bookList);
        if(bookList.size()>0){
            delete bookList; 
        }
        system.debug('enrList'+enrList);
        if(enrList.size()>0)
            update enrList;
        
        }
    global void finish(Database.BatchableContext bc){
        System.debug('----Finish');
    }
}