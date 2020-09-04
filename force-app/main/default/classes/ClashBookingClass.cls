public class ClashBookingClass {
	
    @AuraEnabled
    public static list<wrappBooking> getBooking(string center){
        system.debug('center test'+center);
        set<string> status = new set<string>{'Pending','Scheduled','Completed'};
        set<string> Types = new set<string>{'Trial','Regular','Make-up','Ad-hoc'};
         string dateFilter='NEXT_N_DAYS:15';
        //list<wrappBooking> wrapList = new list<wrappBooking>();
        string str='SELECT Id,Name,Status__c,Type__c,Center__r.Name,Center__c,Teacher_Account__c,Student__r.Name,Parent__r.Name,Parent__c,CreatedDate,Teacher_Account__r.Name,Package__r.Name,Booking_Date__c,Start_Time__c,Duration__c FROM Booking__c WHERE Center__c=:center And  Status__c in :status and Booking_Date__c='+ dateFilter +' and Type__c in:Types AND Package__r.Type__c !=\'Group\' ORDER BY Center__r.Name ASC, Teacher_Account__r.Name ASC';
       map<string,list<Booking__c>> maptoString = new map<string,list<Booking__c>>();
       
        list<Booking__c> clashBookList = Database.query(str);
        system.debug('---test'+clashBookList);
        for(Booking__c bookListnew:clashBookList){
            string key =string.valueOf(bookListnew.Teacher_Account__c)+''+string.valueOf(bookListnew.Booking_Date__c) +''+ string.valueOf(bookListnew.Start_Time__c);
            List<Booking__c> tmp = new List<Booking__c>();
            if(maptoString.containsKey(key))
              tmp = maptoString.get(key);
            tmp.add(bookListnew);
            maptoString.put(key,tmp);
        }
       list<wrappBooking> wrap = new List<wrappBooking>();
       for(string ky :maptoString.keySet()) {
        wrappBooking wr = new wrappBooking();
        wr.Key = ky;
        wr.bookListing= maptoString.get(ky);
        wr.NumberRecord=wr.bookListing.size();
           if(wr.NumberRecord>1)
                wrap.add(wr);
       }

       return wrap;
    }
    Public class wrappBooking {
        @AuraEnabled
        public string Key {get;set;}
        @AuraEnabled
        public list<Booking__c> bookListing {get;set;}
        /* @AuraEnabled
public string Student {get;set;}
@AuraEnabled
public string Parent {get;set;}
@AuraEnabled
public string Teacher {get;set;}
@AuraEnabled
public string Name {get;set;}
@AuraEnabled
public string BookingDate {get;set;}
@AuraEnabled
public string BookingTime {get;set;}
@AuraEnabled
public string Status {get;set;}
@AuraEnabled
public string TypeRecord {get;set;}
@AuraEnabled
public string PackageRecord {get;set;}*/
        @AuraEnabled
        public Integer NumberRecord {get;set;}
    }
    
    @AuraEnabled
    public static list<Date> getDate(){
        Date todayDate = System.today();
        Date next=todayDate.addDays(15);
        list<Date> dateList = new List<Date>();
        dateList.add(todayDate);
        dateList.add(next);
        return dateList;
    }
}