global class TempCreateFifthLessonRecords implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc){ 
       
        String query = 'SELECT Id, Name, Status__c, Type__c, Center__c, Package__c, Parent__c, '+
									   'Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, Teacher_Account__r.Employee_Duty_Type__c, '+
									   'Start_Time__c, Duration__c, Student__c, Student__r.Name, Student__r.Parent__c,Student__r.PersonContactId, '+
									   'Student__r.Parent__r.PersonContactId, End_Time__c, Enrolment__c, Center__r.Location__c, '+ 
									   'RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c '+ 
								'FROM Booking__c '+
								'WHERE Type__c=\'Busy\' and Category__c = \'Placeholder\' and Booking_Date__c != null and Enrolment__c != null AND Status__c = \'Scheduled\' and Booking_Date__c > today';
        return Database.getQueryLocator(query); 
    }
    global void execute (Database.BatchableContext bc ,List<Booking__c> bookingList){
       //Create fifth lesson record for existing placholder bookings
        List<Fifth_Lesson__c> fifthLessonList = new List<Fifth_Lesson__c>();
        List<Booking__c> updBookingList = new List<Booking__c>();
       
        for(Booking__c book : bookingList){
            if(book.Booking_Date__c.day() >= 29 && book.Booking_Date__c.day() <= 31){
                Fifth_Lesson__c fifthLesn   = new Fifth_Lesson__c();
                fifthLesn.Enrolment__c = book.Enrolment__c;
                fifthLesn.Student__c   = book.Student__c;
                fifthLesn.Teacher_Account__c = book.Teacher_Account__c; 
                fifthLesn.Package__c      = book.Package__c;
                fifthLesn.Center__c    	  = book.Center__c;
                fifthLesn.Parent__c       = book.Parent__c;
                fifthLesn.Booking_Date__c = book.Booking_Date__c;
                fifthLesn.Start_Time__c	  = book.Start_Time__c;
                fifthLesn.End_Time__c  	  = book.End_Time__c;
                fifthLesn.Remarks__c      = 'Created fifth lesson record 11th Oct 2019.';
                fifthLessonList.add(fifthLesn);
                
                book.Status__c = ConstantsClass.statusCanceled;
                book.Field_1__c = 'Created fifth lesson record 11th Oct 2019.';
                updBookingList.add(book);
            }
        }			
        
        System.debug('@@@@-->'+fifthLessonList.size());
        System.debug('@@@@-->'+updBookingList.size());
        if(fifthLessonList.size() > 0){	
            update updBookingList;
            insert fifthLessonList;
        }
    }
    global void finish(Database.BatchableContext bc){
        System.debug('----Finish');
    }
}