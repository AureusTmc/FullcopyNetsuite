public class BookingCancellationClass {
    
    /*
    Name        :        BookingCancellationClass
    Author      :        Ravi Gupta
    Description :        It is the  class of Booking Cancellation Form.
    */
    @AuraEnabled
    public static list<Enrolment__c> getEnrolment(string enrolId){
        
       List<Enrolment__c> enrolList =[select Student__r.Name,Student__c,Parent__r.Name,Parent__c,Center__r.Name,Center__c ,
                                        Center__r.Organisation__r.Name // added by nishi: 5-Oct-2020: for manage ossia organisation makeup mins
                                        from Enrolment__c where Id=:enrolId];
        //system.debug('enrolList'+enrolList);
        if(enrolList.size()>0){
            return enrolList;
        }
        return enrolList;
    }
    @AuraEnabled
    public static void SaveBooking(string BookingTypeList,string enrolmentId){
        System.debug('BookingTypeList' + BookingTypeList);
        List<Booking__c> BookList=new List<Booking__c>();
        List<Wrapperclass> wraplist  = new List<Wrapperclass>();
        Id LessonType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        // added by nishi: 29-Jul-2020: for manage ossia organization student we added Makeup expiry days will be 180 days.
        list<Enrolment__c> enrolList = getEnrolment(enrolmentId); 
        List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings = [SELECT Id, 
        Label,  Makeup_Expiry_Days__c,Makeup_Expiry_Days_For_Public_Holiday__c,
        Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
        WHERE Label =:System.Label.Ossia_Organisation_Name];
        Enrolment__c objEnrol= enrolList[0];
        Boolean isOssia = false;
        if(string.isNotBlank(objEnrol.Center__c) && string.isNotBlank(objEnrol.Center__r.Organisation__c) &&
        string.isNotBlank(objEnrol.Center__r.Organisation__r.Name) && 
        objEnrol.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
            isOssia = true;
            
        }
        // added by nishi: 29-Jul-2020: for manage ossia organization student  we added Makeup expiry days will be 180 days.
 
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
                                                    recordTypeId = LessonType,Type__c='Regular',Status__c='Canceled',
                                                    Make_up_Expiry_Date__c=ExpiryDate);
                // added by nishi: 5-Oct-2020:Start: for if enrolment is belogs to ossia then we added makup min 180 other wise we addded 120 days 
                if(isOssia){
                    bkgObj.enrolment__c = enrolmentId;
                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                        bkgObj.Make_up_Expiry_Date__c = BookingDate.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days__c));
                    }
                }                                    
                // added by nishi: 5-Oct-2020:End: for if enrolment is belogs to ossia then we added makup min 180 other wise we addded 120 days 
              
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