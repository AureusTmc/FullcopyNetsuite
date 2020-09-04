/*
        Name        :    BusyBookingBatch
        Date        :    01/03/2019
        Author      :  
        Description :    This batch class is used for making Busy Booking of teacher for a center.
        
*/
global class BusyBookingBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    global DateTime startTime;
    global integer noOfRecords;
    global String typeBusy = ConstantsClass.typeBusy;
    global String scheduledStatus = ConstantsClass.scheduledStatus;
    global BusyBookingBatch (){
        noOfRecords  = 0;
        startTime = system.now();
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        /*return Database.getQueryLocator([Select Id,Name,
                                        (Select Id,Name,Active__c,Break_Time__c,Center_Name__c,Center_Name__r.Id,End_Time__c,
                                         Start_Time__c,Teacher_Name__c,Working_Day__c
                                         FROM Teacher_Working_Schedules__r
                                         WHERE Active__c=true AND Break_Time__c=true)
                                         From Account 
                                         WHERE RecordType.developerName='Teacher']);*/
        return Database.getQueryLocator([Select Id,Break_Time__c,Center_Name__c,End_Time__c,
                                         Start_Time__c,Teacher_Name__c,Working_Day__c
                                         FROM Teacher_Working_Hour__c
                                         WHERE Active__c=true AND Break_Time__c=true AND Working_Day__c != NULL AND Teacher_Name__c != NULL]);                                
    }
    
    global void execute(Database.BatchableContext BC, List<Teacher_Working_Hour__c> listOfTeacherWorkingHours){
        noOfRecords += listOfTeacherWorkingHours.size();
        
        List<Booking__c> bookingInserList = new List<Booking__c>();
        DateTime nextDate = system.today().addMonths(13);
        DateTime nextYearMonthStartDate= DateTime.newInstance(nextDate.year(),nextDate.month(),1,0,0,0);
        Integer days = date.daysInMonth(nextYearMonthStartDate.year(),nextYearMonthStartDate.month());
        DateTime nextYearMonthEndDate = DateTime.newInstance(nextYearMonthStartDate.year(),nextYearMonthStartDate.month(),days,0,0,0);
        
        Map<String,List<Date>> mapOfDaysWithDate = getDateMap(nextYearMonthStartDate,nextYearMonthEndDate ,'EEE');
        
        for(Teacher_Working_Hour__c objWorkingHour : listOfTeacherWorkingHours){
            if(mapOfDaysWithDate.containsKey(objWorkingHour.Working_Day__c)){
                List<Date> listOfDate = mapOfDaysWithDate.get(objWorkingHour.Working_Day__c);
                for(Date objDate : listOfDate){
                     Booking__c booking = new Booking__c();
                     booking.Center__c = objWorkingHour.Center_Name__c;
                     booking.Teacher_Account__c = objWorkingHour.Teacher_Name__c;
                     booking.Booking_Date__c = objDate;
                     booking.Start_Time__c = objWorkingHour.Start_Time__c;
                     booking.End_Time__c = objWorkingHour.End_Time__c;
                     booking.Type__c = typeBusy;
                     booking.Status__c = scheduledStatus;
                     booking.Category__c = ConstantsClass.categoryLunch;
                     bookingInserList.add(booking);
                } 
            }    
        }
        //system.debug('Bookings >>'+bookingInserList);
        //system.debug('Booking size >> '+bookingInserList.size());
        if(bookingInserList.size() > 0){
            insert bookingInserList;
        }
    }

    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Busy Booking Batch',startTime,system.now(),noOfRecords);
    }
    
    public static Map<String,List<Date>> getDateMap(DateTime firstDate,DateTime lastDate, String format ){
        Map<String,List<Date>> datesMap = new Map<String,List<Date>>();
        while(firstDate <= lastDate ){
            DateTime myDateTime =  firstDate;
            String day = myDateTime.format(format); //EEEE
            List<Date> dateList = new List<Date>();
            if(datesMap.containskey(day)){
                dateList = datesMap.get(day);
            }
            dateList.add(firstDate.date());
            firstDate = firstDate.addDays(1);
            datesMap.put(day,dateList);
        }
        system.debug(datesMap);
        return datesMap;
    }
}