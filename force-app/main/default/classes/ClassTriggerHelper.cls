/*
        Name            :    ClassTriggerHelper
        Date            :    16 August 2019
        Author          :    
        Description     :    Helper class for Class Trigger

*/
public class ClassTriggerHelper{
    
    /*
     * This method will create the class bookings for 12 months 
     * After the Class is created for the centre and teacher.
    */
    
    public static void createOneYearBookings(List<Class__c> classList){
        
        List<Booking__c> bookingListForClass = new List<Booking__c>();
         List<Class__c> listOfClass = new List<Class__c>();
        for(Class__c objClass : classList){
            if(objClass.Start_Time__c != null && objClass.Class_Date__c != null){    
                DateTime startTime = DateTime.newInstance(objClass.Class_Date__c, objClass.Start_Time__c);
                if(objClass.Class_End_Date__c != null){
                    DateTime endTime = DateTime.newInstance(objClass.Class_End_Date__c, objClass.Start_Time__c);
                    bookingListForClass.addAll(createBookingsForClass(objClass, startTime, endTime));
                } else{
                    DateTime endTime = DateTime.newInstance(objClass.Class_Date__c, objClass.Start_Time__c).addMonths(ConstantsClass.periodOfClassesInMonths + 1);
                    endTime = DateTime.newInstance(Date.newInstance(endTime.year(), endTime.month(), 1), objClass.Start_Time__c);
                    bookingListForClass.addAll(createBookingsForClass(objClass, startTime, endTime));
                    //commented by jatin: 17-Mar-2020: according to new requirement  Class_End_Date__c field  is only update manually 
                    //listOfClass.add(new Class__c (id=objClass.id,Class_End_Date__c = endTime.date()));
                }
            }
        }
        System.debug('@@@@bookingListForClass'+bookingListForClass);
        if(bookingListForClass != null && bookingListForClass.size() > 0){
            insert	bookingListForClass;     
        }
        /*if(listOfClass != null && listOfClass.size() > 0){
            update	listOfClass;     
        }*/
    }
    
    //This method will create 12 Months booking for per class.
    Public static List<Booking__c> createBookingsForClass(Class__c classObj,DateTime startTime,datetime endTime){
    	List<Booking__c> bookingListForClass = new List<Booking__c>();
        String groupClassBookingType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupBookingRecordType).getRecordTypeId();
        // 7-jan-2020:Change the Record Type of the placeholder in the class creation process to "Lesson"
        String lessonBookingType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        
        package__c packageObj = new package__c();
        if(classObj.Package__c != null){
            packageObj = [select id,name from package__c where id=:classObj.Package__c];
        }
        //DateTime startTime;
        //DateTime endTime;
        if(String.isNotBlank(classObj.Id)){
           // startTime = DateTime.newInstance(classObj.Class_Date__c, classObj.Start_Time__c);
           /* endTime = startTime.addMonths(ConstantsClass.periodOfClassesInMonths + 1);
            endTime = DateTime.newInstance(Date.newInstance(endTime.year(), endTime.month(), 1), classObj.Start_Time__c);
            */endTime = endTime.addDays(-1);
            //Create Bookings for 12 Months
            while(startTime <= endTime){
                //system.debug('startTime.day()'+startTime.day());
                if(startTime.day() <= 28){
                   //Create Group Class Type bookings
                   Booking__c regularGroupClassObj = new Booking__c(Class__c = classObj.Id, Booking_Date__c = startTime.date(), 
                                                         Start_Time__c = classObj.Start_Time__c, End_Time__c = classObj.End_Time__c,
                                                         Teacher_Account__c = classObj.Teacher__c, Center__c = classObj.Centre_Name__c, 
                                                         Type__c = ConstantsClass.groupTypeBooking, Status__c = ConstantsClass.scheduledStatus,
                                                         Package__c = classObj.Package__c, RecordTypeId = groupClassBookingType);
                   bookingListForClass.add(regularGroupClassObj);
               }
               // @jatin: 2Jan-2020 : for add plachoder for 5th lesson group class
                if(startTime.day() > 28){
                    Booking__c placeholderObj = new Booking__c();
                    placeholderObj.Type__c = ConstantsClass.typeBusy;
                    placeholderObj.Booking_Date__c = startTime.date();
                    placeholderObj.Start_Time__c = classObj.Start_Time__c;
                    placeholderObj.End_Time__c = classObj.End_Time__c;
                    placeholderObj.status__c = ConstantsClass.scheduledStatus;
                    placeholderObj.Teacher_Account__c = classObj.Teacher__c;
                    placeholderObj.Center__c = classObj.Centre_Name__c;
                    placeholderObj.remarks__c = 'placeholder booking for Group Class - '+ classObj.name;
                    placeholderObj.recordTypeId = lessonBookingType;
                    placeholderObj.Category__c = ConstantsClass.bookingCategoryPlaceHolder;
                    placeholderObj.Class__c = classObj.Id;
                    bookingListForClass.add(placeholderObj);
                }
                
                startTime = startTime.addDays(7);
            }
        }
       // system.debug('bookingListForClass'+bookingListForClass);
        return bookingListForClass;
    } 
}