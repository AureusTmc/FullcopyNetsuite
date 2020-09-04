global class BookingNotesBatch implements Database.Batchable<sObject>{
    /*This class  creates notes   for all the Bookings with Type 'Trial' ANd Enrolment Type is Trial and enrolment Stage Booked And Requested */
 global Database.QueryLocator start(Database.BatchableContext bc){ 
     set<String> stage = new set<String>{'Requested','Booked'};
        String query = 'select Id,Student__r.PersonBirthdate,Booking_Date__c,Parent__r.Owner.Name,(select Id from ContentDocumentLinks ),(select Id from Booking_Notes__r ),Student__r.Gender__c,Enrolment__r.Previous_Experience_if_any__c,Student__r.Description,Enrolment__r.Learning_Style__c from Booking__c where Type__c=\'Trial\' And  Enrolment__r.Type__c = \'Trial\' And Enrolment__r.Stage__c in:stage limit 10';
        return Database.getQueryLocator(query); 
    }
    global void execute (Database.BatchableContext bc ,List<Booking__c> bookList){
        //system.debug('----'+bookList);
        //system.debug('----'+bookList[0].Booking_Notes__r);
        list<Booking__c> UpdateBookList = new list<Booking__c>();
        List<ContentDocumentLink> noteList = new list<ContentDocumentLink>();
        // For Portal: Booking Note Create List
        List<Booking_Note__c> BookingNoteList = new List<Booking_Note__c>();
        
        Map<Id,ContentNote> contentnote2insertmap = new Map<Id,ContentNote>();
        for(Booking__c bkObj :bookList){
            if(bkObj.ContentDocumentLinks.size() < 1){
                ContentNote cnt = new ContentNote();
                cnt.Content = Blob.valueof('Gender: '+ string.valueOf(bkObj.Student__r.Gender__c) +'<br>Birthday: '+ string.valueOf(bkObj.Student__r.PersonBirthdate) + '<br>Comments:' +string.valueOf(bkObj.Student__r.Description) +'<br>Previous Experience: '+ string.valueOf(bkObj.Enrolment__r.Previous_Experience_if_any__c)+ '<br>Learning Style: '+ string.valueOf(bkObj.Enrolment__r.Learning_Style__c) );
                cnt.Title = 'Initial Student Notes';
                contentnote2insertmap.put(bkObj.id,cnt);
            }
            if(bkObj.Booking_Notes__r.size() < 1){
                Booking_Note__c bkgObj = new Booking_Note__c(Booking__c=bkObj.Id,Note_Created_Date__c=bkObj.Booking_Date__c,Title__c='Initial Student Notes', Note_Created_By__c=bkObj.Parent__r.Owner.Name,
                                                             Description__c='Gender: '+ string.valueOf(bkObj.Student__r.Gender__c) +'<br>Birthday: '+ string.valueOf(bkObj.Student__r.PersonBirthdate) + '<br>Comments:' +string.valueOf(bkObj.Student__r.Description) +'<br>Previous Experience: '+ string.valueOf(bkObj.Enrolment__r.Previous_Experience_if_any__c)+ '<br>Learning Style: '+ string.valueOf(bkObj.Enrolment__r.Learning_Style__c)
                                                             );
				BookingNoteList.add(bkgObj);              
            }
        }
        
        if(contentnote2insertmap.values().size()>0)
            insert contentnote2insertmap.values();
        
        
       // system.debug('BookingNoteList'+BookingNoteList);
        for(Booking__c bkobj :bookList){
            //system.debug('bkobj.Id'+bkobj.Id);
            if(contentnote2insertmap.containskey(bkobj.id)){
                system.debug('----'+bkobj.id);
                ContentDocumentLink  clnk = new ContentDocumentLink();
                clnk.LinkedEntityId = bkobj.Id;
                clnk.ContentDocumentId = contentnote2insertmap.get(bkobj.id).Id;
                clnk.ShareType = 'I';
                noteList.add(clnk);
                bkobj.Field_1__c='Note Created on Trial Booking';
                UpdateBookList.add(bkobj);
            }
    }
        if(BookingNoteList.size()>0)
            insert BookingNoteList;
        //system.debug('BookingNoteList'+BookingNoteList[0].Id);
        if(noteList.size()>0){
            insert noteList;
            update UpdateBookList;
        }
    
}
    global void finish(Database.BatchableContext bc){
        System.debug('----Finish');
    }
}