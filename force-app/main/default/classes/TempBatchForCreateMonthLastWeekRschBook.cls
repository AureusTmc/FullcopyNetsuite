/*
Name        :    TempBatchForCreateMonthLastWeekRschBook
Date        :    07/20/2019
Author      :    Rajesh
Description :    This is temprary batch class, and its created for Insert missing 5th placholder booking.
We will deactivate after correct reschedule bookings.
*/
global class TempBatchForCreateMonthLastWeekRschBook implements Database.Batchable<sObject>,database.stateful{     
    global TempBatchForCreateMonthLastWeekRschBook(){}
    
    global Database.QueryLocator start(Database.BatchableContext BC){
       
        return Database.getQueryLocator([SELECT Id,Name,Center__c,(SELECT Id,Name,RecordTypeId,Student__c,Teacher_Account__c,
                                                         Enrolment__c,Package__c,Center__c,Type__c,Status__c,Start_Time__c,Category__c,
                                                         End_Time__c,Booking_Date__c 
                                                         FROM Bookings__r 
                                                         WHERE (Type__c = 'Regular' OR Type__c = 'Make-up' OR Category__c  = 'Placeholder')  order by Booking_Date__c)
                                         FROM Enrolment__c WHERE Stage__C ='Enrolled']);
    }
    
    global void execute(Database.BatchableContext BC, List<Enrolment__c> enrList){
        Map<Id,List<Booking__c>> regularBookMap = new Map<Id,List<Booking__c>>();
        Set<String> makePlaceHoldBookSet = new Set<String>();
        
        for(Enrolment__c enr : enrList){
            for(Booking__c b: enr.Bookings__r){
                if(b.Type__c == 'Regular'){
                    List<Booking__c> tempLst = new List<Booking__c>();
                    if(regularBookMap.containsKey(enr.Id)){
                        tempLst = regularBookMap.get(enr.Id);                        
                    }
                    tempLst.add(b);
                    regularBookMap.put(enr.Id, tempLst);
                }else{
                    makePlaceHoldBookSet.add(enr.Id+'#'+b.Booking_Date__c+'#'+b.Start_Time__c);
                }
            }
        }
        
        
        List<Booking__c> insMissBookList = new List<Booking__c>();
        
        for(Enrolment__c enr : enrList){
        
            List<Booking__c> tempLst = regularBookMap.get(enr.Id);
            
            if(tempLst != null && tempLst.size() > 0){
                Booking__c preBook = tempLst.get(0);
                
                Integer count = 0;
                for(Booking__c b: tempLst){
                    
                    if(count>0)
                        preBook = tempLst.get(count-1);
                    count = count+1; 
                    
                    Date tempDt = preBook.Booking_Date__c.addDays(7);
                   
                    if(preBook != null && preBook.Booking_Date__c.daysBetween(b.Booking_Date__c) >=14){
                        String plcMapKey = enr.Id+'#'+tempDt+'#'+b.Start_Time__c;
                        if(!(makePlaceHoldBookSet.contains(plcMapKey)) && tempDt > System.today() && tempDt.day() >= 29 && tempDt.day() <=31){
                            Booking__c book   = new Booking__c();
                            book.RecordTypeId = b.RecordTypeId;
                            book.Student__c   = b.Student__c;
                            book.Teacher_Account__c = b.Teacher_Account__c; 
                            book.Enrolment__c = b.Enrolment__c;
                            book.Package__c   = b.Package__c;
                            book.Center__c    = b.Center__c;
                            book.Type__c      = ConstantsClass.busyBookingType;
                            book.Status__c    = ConstantsClass.scheduledStatus;
                            book.Category__c  = 'Placeholder';       
                            book.Booking_Date__c = preBook.Booking_Date__c.addDays(7);
                            book.Start_Time__c= b.Start_Time__c;
                            book.End_Time__c  = b.End_Time__c;
                            book.Field_1__c   = 'Missing 5th placeholder booking created '+System.today();
                            insMissBookList.add(book);
                            
                            
                            //Filling booking for the Before travel  
                            Booking__c befBook = new Booking__c();
                            befBook.RecordTypeId = b.RecordTypeId;
                            befBook.Student__c   = b.Student__c;
                            befBook.Teacher_Account__c = b.Teacher_Account__c; 
                            befBook.Enrolment__c = b.Enrolment__c;
                            befBook.Package__c   = b.Package__c;
                            befBook.Center__c    = b.Center__c;
                            
                            Boolean isAureusAtHome = (enr.Center__c == Label.Aureus_at_Home_Id ? true : false);
                            if(isAureusAtHome){
                                befBook.Type__c      = ConstantsClass.busyBookingType;
                                befBook.Status__c    = ConstantsClass.scheduledStatus;
                                befBook.Category__c  = 'Placeholder';       
                                befBook.Booking_Date__c = preBook.Booking_Date__c.addDays(7);
                                befBook.End_Time__c  = book.Start_Time__c;
                                befBook.Start_Time__c = book.Start_Time__c.addMinutes(-30);
                                befBook.Field_1__c   = 'Missing 5th Travel placeholder booking created '+System.today();
                                
                                
                                insMissBookList.add(befBook); 
                            }   
                        }   
                    }
                }
            }
        }
        
       // SavePoint sp = Database.setSavepoint();
        //try{            
            if(insMissBookList.size() > 0)
                insert insMissBookList;
        //}catch(Exception e){
          //  Database.rollback(sp);
        //}
    }
    
    global void finish(Database.BatchableContext BC){
    }
}