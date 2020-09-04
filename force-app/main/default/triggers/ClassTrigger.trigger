/*
 * Class Name		:		ClassTrigger
 * Creation Date    :		2019/08/22
 * Description		:		This Trigger will create the booking for that class for 12 months in case of inserting the class
*/ 
trigger ClassTrigger on Class__c (after insert, after update) {
    // it will create Bookings for 12 month for that class
    if(trigger.isInsert && trigger.isAfter){
        ClassTriggerHelper.createOneYearBookings(Trigger.new);
    }
    
  }