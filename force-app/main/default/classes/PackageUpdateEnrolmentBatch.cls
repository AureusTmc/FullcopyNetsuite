/*
        Name        :    PackageUpdateEnrolmentBatch
        Date        :    02/04/2019
        Description :    This batch class is Update regular package on the Enrolments which are linked with the discounted package
*/
global class PackageUpdateEnrolmentBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
	
    global Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator([SELECT Id, Name, Package__c, Package_To_Be_Change__c, Promotional_Period_End_Date__c
                                         FROM Enrolment__c 
                                         WHERE Promotional_Period_End_Date__c <= TODAY AND Package_To_Be_Change__c != null 
                                         	   AND Package__r.Type_Of_Package__c IN ('Promo','Prepayment')]);
    }
    
    global void execute(Database.BatchableContext BC, List<Enrolment__c> enrList){
        
        if(enrList.size() > 0){
           
        	//Added by Rajesh: 25th June 2019, Updating promotional package with the regular package in the bookings
            List<Booking__c> bookUpdList = new List<Booking__c>();
            for(Booking__c objBooking : [SELECT Id,End_Time__c,Start_Time__c, Package__c, Enrolment__c, Enrolment__r.Package__c, Enrolment__r.Package_To_Be_Change__c, 
                                         		Enrolment__r.Promotional_Period_End_Date__c, Booking_Date__c 
                                         FROM Booking__c 
                                         WHERE RecordType.Name =: ConstantsClass.recordTypeLesson AND Booking_Date__c > TODAY AND Enrolment__c IN :enrList]){
                                              
                if(objBooking.Booking_Date__c > objBooking.Enrolment__r.Promotional_Period_End_Date__c && objBooking.Package__c == objBooking.Enrolment__r.Package__c){      
                    objBooking.Package__c = objBooking.Enrolment__r.Package_To_Be_Change__c;
                    bookUpdList.add(objBooking);
                }
            }
            
            if(bookUpdList.size() > 0)
                update bookUpdList;
            
            for(Enrolment__c enr : enrList){
            	enr.Package__c = enr.Package_To_Be_Change__c;       
                enr.Promotional_Period_End_Date__c = null;
            }
            update enrList;
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
    
    /* 
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Added by rajesh, 25th June 2019- Added some promotinal package related fields for update enrolment and bookings with the new package
    	return Database.getQueryLocator([SELECT Id, Name, Next_Bill_Date__c, Enrolment__c, Enrolment__r.Package__c, Enrolment__r.Package__r.Promotion_period_In_months__c, Enrolment__r.Package_To_Be_Change__c, Enrolment__r.Promotional_Period_End_Date__c,
                                         Enrolment__r.Package__r.Promotion_Discount__c, Enrolment__r.Package__r.Package_after_Promotion__c, Enrolment__r.Package__r.Is_Promotion_Discount__c 
                                         FROM Subscription_Line_Item__c 
                                         WHERE Next_Bill_Date__c = NEXT_MONTH AND Enrolment__r.Package__r.Promotion_period_In_months__c != null
                                         	   AND Enrolment__r.Package__r.Promotion_Discount__c != null AND Enrolment__r.Package_To_Be_Change__c != null AND 
                                         	   Enrolment__r.Promotional_Period_End_Date__c != null AND Enrolment__r.Package__r.Is_Promotion_Discount__c = True]);
    }
    
    global void execute(Database.BatchableContext BC, List<Subscription_Line_Item__c> subLineItemList){
        List<Enrolment__c> updEnrList = new List<Enrolment__c>();
        
        //Added by Rajesh: 24th June 2019, processing subscription line items with the enrolment and populating regular package in the enrolment
        for(Subscription_Line_Item__c subLnItm : subLineItemList){
            updEnrList.add(new Enrolment__c(Id = subLnItm.Enrolment__c, 
                                            Package__c = subLnItm.Enrolment__r.Package_To_Be_Change__c));
        }
		
		        
        if(updEnrList.size() > 0){
            update updEnrList;
        	
            //Added by Rajesh: 25th June 2019, Updating promotional package with the regular package in the bookings
            List<Booking__c> bookUpdList = new List<Booking__c>();
            for(Booking__c objBooking : [SELECT Id,End_Time__c,Start_Time__c, Package__c, Package__r.Duration__c, Enrolment__c, Enrolment__r.Package__c, Enrolment__r.Promotional_Period_End_Date__c, Booking_Date__c FROM Booking__c WHERE RecordType.Name =: ConstantsClass.recordTypeLesson
                                            AND Enrolment__c IN :updEnrList AND Booking_Date__c >= today AND (Type__c =: ConstantsClass.typeRegular OR IS_Fifth_Booking__c = TRUE)
                                          AND Status__c !=: ConstantsClass.statusCanceled]){
                                              
                if(objBooking.Booking_Date__c > objBooking.Enrolment__r.Promotional_Period_End_Date__c){      
                    objBooking.Package__c = objBooking.Enrolment__r.Package__c;
                    bookUpdList.add(objBooking);
                }
            }
            
            if(bookUpdList.size() > 0)
                update bookUpdList;
        }
    }
    
    global void finish(Database.BatchableContext BC){
    } */   
}