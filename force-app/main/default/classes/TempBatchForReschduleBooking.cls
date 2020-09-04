/*
Name        :    TempBatchForReschduleBooking
Date        :    07/15/2019
Author      :    Rajesh
Description :    This is temprary batch class, for correct reschedule bookings
We will deactivate after correct reschedule bookings.
*/
global class TempBatchForReschduleBooking implements Database.Batchable<sObject>,database.stateful{    
    
    global TempBatchForReschduleBooking(){
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id,Name,(SELECT Id,Name,RecordTypeId,Student__c,Teacher_Account__c,
                                                         Enrolment__c,Package__c,Center__c,Type__c,Status__c,Start_Time__c,
                                                         End_Time__c,Booking_Date__c 
                                                         FROM Bookings__r 
                                                         WHERE Type__c = 'Regular' order by Booking_Date__c)
                                         FROM Enrolment__c WHERE Last_Reschedule_Date__c = null AND Stage__C ='Enrolled']);
    }
    
    global void execute(Database.BatchableContext BC, List<Enrolment__c> enrList){
        
        List<Booking__c> insMissBookList = new List<Booking__c>();
        List<Enrolment__c> updEnrlList = new List<Enrolment__c>();
        
        for(Enrolment__c enr : enrList){
            
            enr.Last_Reschedule_Date__c = system.today();
            updEnrlList.add(enr);
            
            if(enr.Bookings__r.size() > 0){
                Booking__c preBook = enr.Bookings__r.get(0);
                
                Integer count = 0;
                for(Booking__c b: enr.Bookings__r){
                    
                    if(count>0)
                        preBook = enr.Bookings__r.get(count-1);
                    count = count+1; 
                    
                    Date tempDt = preBook.Booking_Date__c.addDays(7);
                   
                    if(preBook != null && preBook.Booking_Date__c.daysBetween(b.Booking_Date__c) >=14){
                        if(tempDt.day() >= 1 && tempDt.day() <=7){
                            Booking__c book   = new Booking__c();
                            book.RecordTypeId = b.RecordTypeId;
                            book.Student__c = b.Student__c;
                            book.Teacher_Account__c = b.Teacher_Account__c; 
                            book.Enrolment__c = b.Enrolment__c;
                            book.Package__c   = b.Package__c;
                            book.Center__c    = b.Center__c;
                            book.Type__c      = b.Type__c;
                            book.Status__c    = b.Status__c;     
                            book.Booking_Date__c = preBook.Booking_Date__c.addDays(7);
                            book.Start_Time__c = b.Start_Time__c;
                            book.End_Time__c = b.End_Time__c;
                            book.Field_1__c = 'Missing booking created '+System.today();
                            insMissBookList.add(book);
                        }	
                    }
                }
            }
        }
        
        SavePoint sp = Database.setSavepoint();
        try{
            if(updEnrlList.size() > 0)
                update updEnrlList;
            
            if(insMissBookList.size() > 0)
                insert insMissBookList;
        }catch(Exception e){
            Database.rollback(sp);
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}