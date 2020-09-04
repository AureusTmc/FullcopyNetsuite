public class BookingCancellationClass {
    
    /*
    Name        :        BookingCancellationClass
    Author      :        Ravi Gupta
    Description :        It is the  class of Booking Cancellation Form.
    */
    @AuraEnabled
    public static list<Enrolment__c> getEnrolment(string enrolId){
        
       List<Enrolment__c> enrolList =[select Student__r.Name,Student__c,Parent__r.Name,Parent__c,Center__r.Name,Center__c from Enrolment__c where Id=:enrolId];
        //system.debug('enrolList'+enrolList);
        if(enrolList.size()>0){
            return enrolList;
        }
        return enrolList;
    }
    @AuraEnabled
    public static void SaveBooking(string BookingTypeList){
        System.debug('BookingTypeList' + BookingTypeList);
        List<Booking__c> BookList=new List<Booking__c>();
        List<Wrapperclass> wraplist  = new List<Wrapperclass>();
        Id LessonType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        
        wraplist =   (List<Wrapperclass>)System.JSON.deserialize(BookingTypeList, List<Wrapperclass>.class);
        
        system.debug('wraplist'+wraplist);
        integer size=wraplist.size();
        system.debug('====>');
        system.debug('size====>'+size);
        if(BookingTypeList!=null){
             for(Wrapperclass wr : wraplist){
                 List<String> endT = wr.End_Time.split(':');
                Time EndTime = Time.newInstance(Integer.valueOf(endT[0]), Integer.valueOf(endT[1]),0,0);
                List<String> startT = wr.Start_Time.split(':');
                Time StartTime = Time.newInstance(Integer.valueOf(startT[0]), Integer.valueOf(startT[1]),0,0);
                List<string> BkDate =wr.Booking_Date.split('-');
                Date BookingDate = Date.newInstance(Integer.valueOf(BkDate[0]),Integer.valueOf(BkDate[1]),Integer.valueOf(BkDate[2]));
                Date ExpiryDate=BookingDate.addDays(120);
                Booking__c bkgObj = new Booking__c(Student__c=wr.Student,Parent__c=wr.Parent,Center__c=wr.Center,
                                                    Booking_Date__c=BookingDate,Start_Time__c=StartTime,End_Time__c=EndTime,
                                                    Available_Make_up_Units__c=Decimal.valueOf(wr.Available_Make_up_Units)-1,
                                                    recordTypeId = LessonType,Type__c='Regular',Status__c='Canceled',Make_up_Expiry_Date__c=ExpiryDate);
                BookList.add(bkgObj);
            }
            if(BookList.size()>0){
                    insert BookList;
                }
            list<Booking__c> BookingList = new list<Booking__c>();
            for(Booking__c bookingObj :BookList){
                bookingObj.Available_Make_up_Units__c=bookingObj.Available_Make_up_Units__c+1;
                BookingList.add(bookingObj);
            }
            if(BookingList.size()>0){
                update BookingList;
            }
            system.debug('--Id' + BookList);
        }
    }
     public class Wrapperclass{
        @auraenabled
        public String Student{get;set;}
        @auraenabled
        public string Parent{get;set;}
         @auraenabled
        public String Center{get;set;}
        @auraenabled
        public string Booking_Date{get;set;}
         @auraenabled
        public String Start_Time{get;set;}
         @auraenabled
        public String Duration{get;set;}
        @auraenabled
        public string End_Time{get;set;}
         @auraenabled
        public String Available_Make_up_Units{get;set;}
        
        public Wrapperclass(){
            
        }
        
    }
    
}