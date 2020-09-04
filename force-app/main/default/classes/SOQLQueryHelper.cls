/*
Name        :    SOQLQueryHelper
Date        :    04/03/2019
Author      :  
Description :    This Helper class is used in WebServiceDataFactoryHelper for query records.

*/
public class SOQLQueryHelper{
    /*--- Start Account query function  --- */
    // get account records related to id 
    public static List<Account> getAccount(string accountId){
        return [SELECT id, Name, Centre_Name__c,Location__c 
                FROM Account 
                WHERE id =: accountId];
    }
    // get account records related emailid and Password 
    public Static List<Account> getExistingParentAccount(String emailId,String password){
        return [SELECT id,Name,FirstName,LastName,PersonEmail,Phone,Nationality__c,BillingStreet, BillingCity,Customer_Password__c,
                BillingState, BillingCountry,BillingpostalCode,Gender__c,Available_Make_up_Units__c,Card_Number__c,Card_Type__c,Expiration__c,
                Profile_Pic_URL__c, Invoice_Paid_Notification__c,Booking_Reminded_Notification__c ,American_club__c,Membership_Type__c,Centre_Name__c, Centre_Name__r.Country__c,
                Centre_Name__r.Country__r.Currency_Code__c,Centre_Name__r.Country__r.name, 
                (SELECT Next_Bill_Date__c FROM Subscription_Line_Items__r
                 Where Next_Bill_Date__c != null  
                 Order by createdDate desc limit 1),
                (SELECT Parent_Account__c, Due_Date__c, Id, Status__c
                 FROM Invoices__r 
                 where Due_Date__c < today 
                 and Status__c NOT IN ('Paid','Cancelled','Void') ), 
                Country__r.name
                FROM Account 
                WHERE Customer_Password__c =:password
                AND PersonEmail =: emailId.tolowercase() 
                AND recordtype.name = 'Customer'];
    }
    
    // get account accrdingt to email address
    public Static List<Account> getNewEmailAccountId(String emailId){
        return [SELECT id,Name,PersonEmail,Customer_Password__c 
                FROM Account 
                where PersonEmail =: emailId.tolowercase() 
               ];
    }
    
    // check user is update or reset password
    public Static List<Account> getAccountIsSignupOrReset(String emailId,Boolean reset){
        if(reset){
            return [SELECT id,Name,PersonEmail 
                    FROM Account 
                    where PersonEmail =: emailId.tolowercase() 
                    AND Customer_Password__c != null 
                   ];
        }else{
            return [SELECT id,Name,PersonEmail 
                    FROM Account 
                    where PersonEmail =: emailId.tolowercase() 
                    AND Customer_Password__c = null 
                   ];
        }
    }
    //get account according to instrument list 
    public static List<Account> getAccountInstrumentsWithTeacher(Set<String> pickistValues){
        String pickistValue='';
        for(String pValue: pickistValues){
            pickistValue+='\''+pValue+'\''+',';
        }
        return  database.query('Select id, name, Major_Instruments_Disciplines__c'+ 
                               ' FROM Account '+ 
                               ' Where RecordType.Name = \'Teacher\''+
                               ' AND Major_Instruments_Disciplines__c != null'+
                               ' AND Major_Instruments_Disciplines__c includes ('+pickistValue.subString(0,pickistValue.length()-1)+')');        
    }
    
    //get account according to instrument list and center id
    public static List<Account> getAccountInstrumentsWithTeacher(Set<String> pickistValues,String CenterId){
        String pickistValue='';
        for(String pValue: pickistValues){
            pickistValue+='\''+pValue+'\''+',';
        }
        return  database.query('Select id, name, Major_Instruments_Disciplines__c'+ 
                               ' FROM Account '+ 
                               ' Where (RecordType.Name = \'Teacher\''+
                               ' AND (Major_Instruments_Disciplines__c != null'+
                               ' AND Major_Instruments_Disciplines__c includes ('+pickistValue.subString(0,pickistValue.length()-1)+'))) '+
                               ' Or (RecordType.Name = \'Customer\' '+
                               ' AND Centre_Name__c = \''+CenterId+'\')');        
    }
    public static List<Account> getBookingInstrumentsWithTeacher(Set<String> pickistValues){
        String pickistValue='';
        for(String pValue: pickistValues){
            pickistValue+='\''+pValue+'\''+',';
        }
        return  database.query('Select id, name, Major_Instruments_Disciplines__c,Status__c,Is_Reschedule_Booking__c'+ 
                               ' FROM Booking'+ 
                               ' Where RecordType.Name = \'Teacher\''+
                               ' AND Major_Instruments_Disciplines__c != null'+
                               ' AND Major_Instruments_Disciplines__c includes ('+pickistValue.subString(0,pickistValue.length()-1)+')');        
    }
    
    
    public static List<Account> getAccountTeachers(Set<String> Instruments){
        String pickistValue='';
        for(String pValue: Instruments){
            pickistValue+='\''+pValue+'\''+',';
        }
        return  database.query('Select id, name, Major_Instruments_Disciplines__c'+ 
                               ' FROM Account '+ 
                               ' Where RecordType.Name = \'Teacher\''+
                               ' AND Minor_Instruments_Disciplines__c includes ('+pickistValue.subString(0,pickistValue.length()-1)+')'+
                               ' OR Major_Instruments_Disciplines__c includes ('+pickistValue.subString(0,pickistValue.length()-1)+')');        
    }
    
    public Static List<Account> getAccount(String lessonName,Set<id> teacherids){
        id techerRecordtypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.teacherRecTypeName).getRecordTypeId();
        return [select id,name,RecordType.ID,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c
                from account 
                where RecordType.ID =: techerRecordtypeId 
                AND (Major_Instruments_Disciplines__c INCLUDES (:lessonName) 
                     OR Minor_Instruments_Disciplines__c INCLUDES (:lessonName)) 
                AND Major_Instruments_Disciplines__c != NULL 
                AND id IN : teacherids];
    }
    // get student records of existing parentId
    public Static List<Account> getStudentAccount(String parentId){
        return [SELECT id,Name,FirstName,LastName,Gender__c,PersonBirthdate,Learning_Style__c,School__r.Name,Parent__c
                FROM Account 
                WHERE Parent__c =: parentId
                And RecordType.Name='Customer'];
    }
    
    public static List<Account> getAccountStripeCustomerId(String tempCstmr ){
        return [SELECT Id, Name, Card_Number__c, Card_Type__c, 
                Card_Image__c, Stripe_Customer_Id__c 
                FROM Account WHERE Id =: tempCstmr AND Stripe_Customer_Id__c != null];
    }
    
    // 27-Jul : for get all set of account ids check parent ids or account id
    public static Set<String> getParentsChild(String parentId){
        Set<String> setOfAccId = new Set<String>();
        List<Account> accList = [SELECT Id FROM Account WHERE (Id =: parentId OR Parent__c =: parentId)];
        for(Account acc : accList){
            setOfAccId.add(acc.Id);
        }
        return setOfAccId;
    }
    /*---  end  Account query function */
    
    /*---  Start  Home_Carousel__cquery function */
    
    public static list<Home_Carousel__c> getevent(string countryCode){
        return [SELECT Description__c,Image_URL__c, Sr_No__c,Title__c,Web_URL__c,Country__r.Name
                FROM Home_Carousel__c 
                Where Web_URL__c!=null AND Description__c!=null AND Title__c!=null 
                AND Sr_No__c in ('1','2','3','4','5','6','7','8','9','10')
                AND Country__r.Name=: countryCode
                order by  Sr_No__c Asc
               ];
    }
    /*---  end Home_Carousel__cquery function */
    
    
    /*---  Start  Booking__c query function */
    public static List<Booking__c> getCancelBooking(String actObjId){
        return [SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
                Student__c,Appointment_Day__c, Package__r.Name,Package__r.type__c, Duration__c, start_time__c, Center__r.Name,Status__c,Is_Reschedule_Booking__c,
                type__c,Cancellation_Reason__c,Available_Make_up_Units__c,Make_up_Expiry_Date__c,Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                FROM booking__c 
                WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson 
                AND type__c != :ConstantsClass.typeBusy 
                AND parent__c=: actObjId 
                //AND Booking_Date__c >= TODAY
                AND Status__c ='Canceled'
                AND Duration__c != null 
                And Make_up_Expiry_Date__c >= Today
                Order By Booking_Date__c ASC
               ];
    }
    
    public Static List<Booking__c> getBooking(list<Date>  dateList,Set<string> bookingStatus, Set<String> bookTypeSet, String regularType,
                                              String busyType,String centerId, String teacherId ){
                                                  String recordTypeLesson = ConstantsClass.recordTypeLesson;
                                                  return [SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, 
                                                          Center__c, Teacher_Account__c, Booking_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c FROM Booking__c 
                                                          WHERE RecordType.Name =: ConstantsClass.recordTypeLesson AND Center__c =:centerId AND Teacher_Account__c =: teacherId 
                                                          AND Booking_Date__c In: dateList 
                                                           AND type__c != :ConstantsClass.typeBusy 
                                                          AND Start_Time__c != NULL 
                                                          AND End_Time__c != NULL
                                                          AND ((status__c IN: bookingStatus AND type__c IN: bookTypeSet)
                                                               OR (type__c =: busyType AND Category__c != 'Placeholder')) 
                                                          order by Booking_Date__c];
                                              }
    public Static List<Booking__c> getMultipleTeacherBooking(list<Date>  dateList,Set<string> bookingStatus, Set<String> bookTypeSet, String regularType,
                                                             String busyType,String centerId, List<String> teacherIds ){
                                                                 String recordTypeLesson = ConstantsClass.recordTypeLesson;
                                                                 return [SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, 
                                                                         Center__c, Teacher_Account__c, Booking_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c FROM Booking__c 
                                                                         WHERE RecordType.Name =: recordTypeLesson AND Center__c =:centerId AND Teacher_Account__c In: teacherIds 
                                                                         AND Booking_Date__c In: dateList
                                                                         AND Start_Time__c != NULL 
                                                                         AND End_Time__c != NULL 
                                                                          AND type__c != :ConstantsClass.typeBusy 
                                                                         AND ((status__c IN: bookingStatus AND type__c IN: bookTypeSet)
                                                                              OR (type__c =: busyType AND Category__c != 'Placeholder')) 
                                                                         order by Booking_Date__c];
                                                             }
    
    // get Booking records with Instrument__c
    public static List<Booking__c> getBookingInstruments(String bookingId){
        return [SELECT id,Instrument__c,Is_Reschedule_Booking__c,Center__c
                FROM Booking__c
                WHERE RecordType.Name =: ConstantsClass.recordTypeLesson AND Id=: bookingId AND type__c != :ConstantsClass.typeBusy];
    }
    // get Booking according to limit and offset and type
    public static List<Booking__c> getBookingUpcomingAndHistorical(String enrollmentId,Integer recLimit,Integer recOffset,String type){
        if(type.equalsIgnoreCase('upcoming')){
            return  [SELECT ID, Teacher_Account__c,Center__c,Name,Enrolment__c, Instrument__c, Student__c,Teacher_Account__r.Name, Student__r.Name, Booking_Date__c,Appointment_Day__c,
                     Package__r.Name, Package__r.Type__c,Duration__c, Center__r.Name, Center_Name__c,start_time__c ,Status__c,Is_Reschedule_Booking__c,type__c
                     ,Cancellation_Reason__c,Available_Make_up_Units__c, Make_up_Expiry_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                     FROM booking__c 
                     WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson 
                     AND Enrolment__c =: enrollmentId 
                     AND type__c != :ConstantsClass.typeBusy 
                     AND Booking_Date__c >= TODAY
                     AND Status__c in ('Scheduled','Pending') 
                     Order By Booking_Date__c DESC
                     LIMIT :recLimit
                     OFFSET :recOffset
                    ];
        }else if(type.equalsIgnoreCase('historical')){
            return  [SELECT ID, Teacher_Account__c,Center__c,Name, Enrolment__c,Instrument__c, Student__c,Teacher_Account__r.Name, Student__r.Name,Booking_Date__c,Appointment_Day__c,
                     Package__r.Name, Package__r.Type__c,Duration__c, Center__r.Name, Center_Name__c,start_time__c,Status__c ,Is_Reschedule_Booking__c,Createddate,type__c
                     ,Cancellation_Reason__c,Available_Make_up_Units__c , Make_up_Expiry_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                     FROM booking__c 
                     WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson 
                     AND Enrolment__c =: enrollmentId
                     AND Booking_Date__c < TODAY 
                     AND type__c != :ConstantsClass.typeBusy 
                     AND Status__c in('No-show','Completed','Canceled','Pending')
                     Order By Booking_Date__c DESC
                     LIMIT :recLimit
                     OFFSET :recOffset
                    ];
        }else{
            return  [SELECT ID, Teacher_Account__c,Center__c,Name, Enrolment__c,Instrument__c, Student__c,Teacher_Account__r.Name, Student__r.Name,Booking_Date__c,Appointment_Day__c,
                     Package__r.Name, Duration__c,Package__r.Type__c, Center__r.Name, Center_Name__c,start_time__c,Status__c ,Is_Reschedule_Booking__c,Createddate,type__c
                     ,Cancellation_Reason__c,Available_Make_up_Units__c , Make_up_Expiry_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                     FROM booking__c 
                     WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson 
                     AND Enrolment__c =: enrollmentId
                     AND type__c != :ConstantsClass.typeBusy 
                     Order By Booking_Date__c DESC
                     LIMIT :recLimit
                     OFFSET :recOffset
                    ];
        }
    }

//  21-Nov-2019 : get Booking according to limit and offset and type
    public static List<Booking__c> getHistoricalBookingFifthBookingPlaceholder(String enrollmentId,Integer recLimit,Integer recOffset,String type){
        LIst<Fifth_Lesson__c> listOfFifth_Lesson = new LIst<Fifth_Lesson__c>();
        if(type.equalsIgnoreCase('upcoming')){}
        else if(type.equalsIgnoreCase('historical')){
            listOfFifth_Lesson =   [SELECT id,Booking__c,Booking__r.Booking_Date__c,Booking__r.Teacher_Account__c,Booking__r.Center__c,Booking__r.Teacher_Account__r.name,Booking__r.Instrument__c , Booking__r.Student__r.Name, Booking__r.Enrolment__c,
                                Booking__r.Student__c,Booking__r.Appointment_Day__c, Booking__r.Package__r.Name, Booking__r.Package__r.Type__c,Booking__r.Duration__c, Booking__r.start_time__c, Booking__r.Center__r.Name,Booking__r.Status__c,Booking__r.Is_Reschedule_Booking__c, 
                                Booking__r.type__c,Booking__r.Cancellation_Reason__c,Booking__r.Available_Make_up_Units__c, Booking__r.Make_up_Expiry_Date__c  
                                FROM Fifth_Lesson__c 
                                WHERE Duration__c != null 
                                AND Booking__c != NULL
                                AND IsActive__c = false 
                                AND Booking__r.RecordType.Name =: ConstantsClass.recordTypeLesson 
                                AND Booking__r.Enrolment__c =: enrollmentId
                                AND Booking__r.Booking_Date__c < TODAY 
                                AND Booking__r.type__c = 'Busy' 
                                and Booking__r.Status__c ='Scheduled'
                                and Booking__r.Category__c = 'Placeholder'
                                Order By Booking__r.Booking_Date__c DESC
                                LIMIT :recLimit
                                OFFSET :recOffset
                    ];
        }else{
                listOfFifth_Lesson =   [SELECT id,Booking__c,Booking__r.Booking_Date__c,Booking__r.Teacher_Account__c,Booking__r.Center__c,Booking__r.Teacher_Account__r.name,Booking__r.Instrument__c , Booking__r.Student__r.Name, Booking__r.Enrolment__c,
                                    Booking__r.Student__c,Booking__r.Appointment_Day__c, Booking__r.Package__r.Name, Booking__r.Package__r.Type__c,Booking__r.Duration__c, Booking__r.start_time__c, Booking__r.Center__r.Name,Booking__r.Status__c,Booking__r.Is_Reschedule_Booking__c, 
                                    Booking__r.type__c,Booking__r.Cancellation_Reason__c,Booking__r.Available_Make_up_Units__c, Booking__r.Make_up_Expiry_Date__c  
                                    FROM Fifth_Lesson__c
                                    WHERE  Duration__c != null 
                                    AND Booking__c != NULL
                                    AND IsActive__c = false
                                    AND Booking__r.RecordType.Name =: ConstantsClass.recordTypeLesson 
                                    AND Booking__r.Enrolment__c =: enrollmentId
                                    AND Booking__r.type__c = 'Busy' 
                                    and Booking__r.Status__c ='Scheduled'
                                    and Booking__r.Category__c = 'Placeholder'
                                    Order By Booking__r.Booking_Date__c DESC
                                    LIMIT :recLimit
                                    OFFSET :recOffset
                    ];
        }
        List<Booking__c> listOfBookingFifthBookingPlaceholder  = getonlyFifthLessonBookings(listOfFifth_Lesson);
        return listOfBookingFifthBookingPlaceholder;
    }
    /*public static List<Booking__c> getHistoricalBooking(String actObjId){
return [SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
Student__c,Appointment_Day__c, Package__r.Name, Duration__c, start_time__c, Center__r.Name,Status__c 
FROM booking__c 
WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson 
AND parent__c=: actObjId 
AND Booking_Date__c < TODAY
 AND type__c != :ConstantsClass.typeBusy 
ANd Status__c !='Canceled'
];
}
public static List<Booking__c> getUpcommingBooking(String actObjId){
return [SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
Student__c,Appointment_Day__c, Package__r.Name, Duration__c, start_time__c, Center__r.Name,Status__c 
FROM booking__c 
WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson 
AND parent__c=: actObjId 
AND Booking_Date__c >= TODAY
AND type__c != :ConstantsClass.typeBusy 
ANd Status__c !='Canceled'
];
}*/
    // get Bookings records according to ids 
    public Static list<booking__c> getListOfBookingWithIdNotPlaceholder(String bookingId){
        return [SELECT Id, Name, Status__c, Type__c, Make_up_Utilize_Bookings__c, Center__c,Enrolment__c,
                Make_up_Expiry_Date__c, Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, parent__c,parent__r.name,
                Make_up_Credit_Note__c, Start_Time__c, Duration__c, Student__c, Student__r.Name, 
                Student__r.Parent__c, End_Time__c, Available_Make_up_Units__c, Cancellation_Reason__c,  
                RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c,Is_Reschedule_Booking__c,
                Instrument__c,Center__r.Location__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                FROM Booking__c 
                WHERE Id in: bookingId.split(',')
                And type__c !=: ConstantsClass.typeBusy AND Category__c != 'Placeholder'
                Order By Booking_Date__c DESC];
    }
    // get Bookings records according to ids 
    public Static list<booking__c> getListOfBookingWithId(String bookingId){
        return [SELECT Id, Name, Status__c, Type__c, Make_up_Utilize_Bookings__c, Center__c,Enrolment__c,
                Make_up_Expiry_Date__c, Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, parent__c,parent__r.name,
                Make_up_Credit_Note__c, Start_Time__c, Duration__c, Student__c, Student__r.Name, 
                Student__r.Parent__c, End_Time__c, Available_Make_up_Units__c, Cancellation_Reason__c,  
                RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c,Is_Reschedule_Booking__c,
                Instrument__c,Center__r.Location__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                FROM Booking__c 
                WHERE Id in: bookingId.split(',')
                Order By Booking_Date__c DESC];
    }
    public static List<Booking__c> getBookingsOnSelectedDates(String centerId, List<String> teacherIds, Set<Date> dates){
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        system.debug(dates);
        List<Booking__c> bookingList = new List<Booking__c>();
        bookingList = [SELECT Id, Name, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, 
                       Center__c, Teacher_Account__c, Booking_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c 
                       FROM Booking__c WHERE RecordType.Name =: recordTypeLesson 
                       AND Center__c =: centerId 
                       AND type__c != :ConstantsClass.typeBusy 
                       AND Teacher_Account__c in: teacherIds 
                       AND Booking_Date__c IN: dates 
                       AND Start_Time__c != NULL 
                       AND End_Time__c != NULL ];
        return bookingList;
    }
    
    // 27-JUL : for get cancel Booking records used in deductMakeupHours function 
    public static  List<Booking__c> getCancelBooking(Set<string> setOfParentStudent ){
        return [SELECT Id, Student__r.Name,Parent__r.Name,Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c, 
                Student__c, Type__c, Duration__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                FROM Booking__c 
                WHERE  RecordType.Name =: ConstantsClass.recordTypeLesson AND 
                Status__c =: ConstantsClass.statusCanceled
                 AND Student__c IN : setOfParentStudent 
                 AND type__c != :ConstantsClass.typeBusy AND 
                Make_up_Expiry_Date__c >= TODAY 
                AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                ORDER BY Make_up_Expiry_Date__c];
    }
    /*---  end Booking__c query function */
    
    /*--Booking History query function*/
    public static  List<Booking__History> getBookingHistory(String bookingId ){
        return [SELECT Id, IsDeleted, Parent.name, CreatedById, CreatedBy.name,CreatedDate, Field, OldValue, NewValue 
                FROM Booking__History
                WHERE ParentId =: bookingId
               ORDER BY CreatedDate desc];
    }
    
    /*-- Booking Historyquery function*/
    
    /**---9:Oct:2019 : start :FIfth lesson Function -----*/
    
     //get enrollement and related 4 Bookings historical 
    public static List<Fifth_Lesson__c> getListOfFifthLesson(String actObjId){
        return [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c 
                FROM Fifth_Lesson__c
                    WHERE parent__c=: actObjId 
                    AND Enrolment__c = NULL
                    AND Booking__c = NULL
                    AND IsActive__c = true
                    Order By Booking_Date__c DESC 
                ];
    }
    
    
     public static List<Fifth_Lesson__c> getCancelFifthLesson(String actObjId){
        return [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                FROM Fifth_Lesson__c
                WHERE parent__c=: actObjId 
                AND Duration__c != null
                AND Booking__c = NULL
                AND IsActive__c = true 
                Order By Booking_Date__c ASC
               ];
    }
    
    public static   List<Fifth_Lesson__c> getBookingsOnFifthDates(String centerId, List<String> teacherIds, Set<Date> dates){
         return  [SELECT Id, Start_Time__c, End_Time__c, Teacher_Account__c, Booking_Date__c FROM Fifth_Lesson__c WHERE IsActive__c = TRUE 
                                                      AND Teacher_Account__c =: teacherIds AND Center__c =: centerId AND 
                                                      Booking_Date__c In :dates ];
    }
    
    // get Booking according to limit and offset and type
    public static List<Fifth_Lesson__c> getFifthLessonUpcomingAndHistorical(String enrollmentId,Integer recLimit,Integer recOffset,String type){
        if(type.equalsIgnoreCase('upcoming')){
            return  [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                    FROM Fifth_Lesson__c
                     WHERE Enrolment__c =: enrollmentId 
                     AND Booking__c = NULL
                     AND IsActive__c = true
                     AND Booking_Date__c >= TODAY
                     Order By Booking_Date__c DESC
                     LIMIT :recLimit
                     OFFSET :recOffset
                    ];
        }else if(type.equalsIgnoreCase('historical')){
            return  [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                    FROM Fifth_Lesson__c
                     WHERE Enrolment__c =: enrollmentId 
                     AND Booking__c = NULL
                     AND IsActive__c = true
                     AND Booking_Date__c < TODAY
                     Order By Booking_Date__c DESC
                     LIMIT :recLimit
                     OFFSET :recOffset
                    ];
        }else{
            return  [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                     FROM Fifth_Lesson__c
                     WHERE Enrolment__c =: enrollmentId 
                     AND Booking__c = NULL
                     AND  IsActive__c = true
                     Order By Booking_Date__c DESC
                     LIMIT :recLimit
                     OFFSET :recOffset
                    ];
        }
    }
    
    
    // get Bookings records according to ids 
    public Static list<Fifth_Lesson__c> getListOfFifthLessonWithId(String lessonIds){
        return [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                     FROM Fifth_Lesson__c
                WHERE Id in: lessonIds.split(',')
                AND Booking__c = NULL
                AND IsActive__c = true
                Order By Booking_Date__c DESC];
    }
     // get Bookings records according to ids 
    public Static list<Fifth_Lesson__c> getListOfFifthLessonWithUpdatedId(String lessonIds){
        return [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                     FROM Fifth_Lesson__c
                WHERE Id in: lessonIds.split(',')
                AND Booking__c != NULL
                AND IsActive__c = false
                Order By Booking_Date__c DESC];
    }
    
   /**---9:Oct:2019 : start : FIfth lesson Function -----*/ 
    
    /*---  Start  enrolment__c query function */
    public Static List<Enrolment__c> getCenterId(string studentId){
        return [SELECT Center__c, Center__r.Location__c from Enrolment__c
                where Student__c =:studentId Order By createdDate ASC
               ];
    }
    //get enrollement and related 4 Upcomming Bookings 
    public static List<enrolment__c > getEnrolmentwithUpcommingBooking(String actObjId){
        
        return [SELECT id, Package__r.Name ,Package__r.Type__c,Student__r.Name, Student__c,  Instrument__c,Package__r.Duration__c,Lesson_Day__c,Package__r.program__r.Name,
                Package__r.program__c,Lesson_Start_time__c,Teacher__c,Teacher__r.name,Stage__c,center__c,center__r.location__C,Package__r.Package_Fee__c,Package__c,Package__r.Package_Fee_with_GST__c, 
                (SELECT  Next_Bill_Date__c From Subscription_Line_Items__r),
                (
                    SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
                    Student__c,Appointment_Day__c, Package__r.Name, Package__r.Type__c, Duration__c, start_time__c, Center__r.Name,Status__c,Is_Reschedule_Booking__c, 
                    type__c,Cancellation_Reason__c,Available_Make_up_Units__c, Make_up_Expiry_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c 
                    FROM Bookings__r
                    WHERE parent__c=: actObjId 
                    AND Booking_Date__c >= TODAY 
                    AND type__c != :ConstantsClass.typeBusy 
                    //AND Status__c in ('Scheduled', 'Pending') 
                    Order By Booking_Date__c ASC
                    //LIMIT 4 
                ),
                // Oct-09-2019 :Nishi :  Start : for get FifthBooking records
                (SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                FROM Fifth_Lessons__r
                 WHERE parent__c=: actObjId 
                    AND Booking_Date__c >= TODAY  
                    AND Booking__c = NULL
                    and IsActive__c = true
                 Order By Booking_Date__c ASC)
                 // Oct-09-2019 :Nishi :  END :  for get FifthBooking records
                FROM enrolment__c
                WHERE parent__c=: actObjId
                AND Type__c != 'Trial'
                //AND Stage__c = 'Enrolled'
                Order by createdDate Desc];
    }
    //get enrollement and related 4 Bookings historical 
    public static List<enrolment__c > getEnrolmentwithHistoricalBooking(String actObjId){
        return [SELECT id, Package__r.Name ,Package__r.Type__c,Student__r.Name, Student__c,  Instrument__c,Package__r.Duration__c,Lesson_Day__c,Package__r.program__r.Name,
                center__c,Package__r.program__c,Lesson_Start_time__c,Teacher__c,Teacher__r.name,Stage__c,center__r.location__C,Package__r.Package_Fee__c,Package__c,Package__r.Package_Fee_with_GST__c, 
                (SELECT  Next_Bill_Date__c From Subscription_Line_Items__r),
                (
                    SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
                    Student__c,Appointment_Day__c, Package__r.Name, Package__r.Type__c,Duration__c, start_time__c, Center__r.Name,Status__c,Is_Reschedule_Booking__c, 
                    type__c,Cancellation_Reason__c,Available_Make_up_Units__c, Make_up_Expiry_Date__c,Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c 
                    FROM Bookings__r
                    WHERE parent__c=: actObjId 
                    AND Booking_Date__c < TODAY 
                    AND type__c != :ConstantsClass.typeBusy
                    //ANd Status__c not IN('Canceled','Scheduled','Pending')
                    Order By Booking_Date__c DESC 
                    //LIMIT 4
                ),
                // Oct-09-2019 :Nishi :  Start : for get FifthBooking records
                (SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name ,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                FROM Fifth_Lessons__r
                 WHERE parent__c=: actObjId 
                 AND Booking__c = NULL
                 and IsActive__c = true
                 AND Booking_Date__c < TODAY  
                 Order By Booking_Date__c DESC )
                 // Oct-09-2019 :Nishi :  END :  for get FifthBooking records
                FROM enrolment__c
                WHERE parent__c=: actObjId 
                AND Type__c != 'Trial'
                //AND Stage__c = 'Enrolled'
                Order by createdDate Desc];
    }
    
    //get enrollement and related 4 Bookings historical 
    public static List<Booking__c> getBookingWithoutEnrolment(String actObjId){
        return [SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
                    Student__c,Appointment_Day__c, Package__r.Name, Package__r.Type__c,Duration__c, start_time__c, Center__r.Name,Status__c,Is_Reschedule_Booking__c, 
                    type__c,Cancellation_Reason__c,Available_Make_up_Units__c, Make_up_Expiry_Date__c,Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c 
                    FROM Booking__c
                    WHERE parent__c=: actObjId 
                    AND type__c != :ConstantsClass.typeBusy
                    AND Enrolment__c = NULL
                    Order By Booking_Date__c DESC 
                ];
    }
    //21-NOv-2019 : get Fifthbooking placeholder Booking  
    public static List<Booking__c> getBookingFifthBookingPlaceholder(String actObjId){
        List<Fifth_Lesson__c> listOfFifthLesson = [SELECT id,Booking__c,Booking__r.Booking_Date__c,Booking__r.Teacher_Account__c,Booking__r.Center__c,Booking__r.Teacher_Account__r.name,Booking__r.Instrument__c , Booking__r.Student__r.Name, Booking__r.Enrolment__c,
                                            Booking__r.Student__c,Booking__r.Appointment_Day__c, Booking__r.Package__r.Name, Booking__r.Package__r.Type__c,Booking__r.Duration__c, Booking__r.start_time__c, Booking__r.Center__r.Name,Booking__r.Status__c,Booking__r.Is_Reschedule_Booking__c, 
                                            Booking__r.type__c,Booking__r.Cancellation_Reason__c,Booking__r.Available_Make_up_Units__c, Booking__r.Make_up_Expiry_Date__c,Booking__r.Lesson_Type__c,Booking__r.Online_Lesson_Passcode__c, Booking__r.Online_Lesson_URL__c
                                            FROM Fifth_Lesson__c 
                                            WHERE Booking__r.parent__c=:actObjId
                                            AND Duration__c != null 
                                            AND Booking__c != NULL 
                                            AND IsActive__c = false 
                                            AND Booking__r.type__c = 'Busy' 
                                            AND Booking__r.Status__c ='Scheduled' 
                                            AND Booking__r.Category__c = 'Placeholder'
                                            Order By Booking__r.Booking_Date__c ASC ];
        List<Booking__c> listOfBookingFifthBookingPlaceholder  = getonlyFifthLessonBookings(listOfFifthLesson);
        return listOfBookingFifthBookingPlaceholder;
    }
    // 21-Nov-2019 : for get bookings
    private static List<Booking__c> getonlyFifthLessonBookings(List<Fifth_Lesson__c> listOfFifthLesson){
         List<Booking__c> listOfBookingFifthBookingPlaceholder = new List<Booking__c>();
        if(listOfFifthLesson != null && listOfFifthLesson.size() > 0){
            for(Fifth_Lesson__c objFifthLesson : listOfFifthLesson){
               listOfBookingFifthBookingPlaceholder.add(objFifthLesson.Booking__r); 
            }
        }
         return listOfBookingFifthBookingPlaceholder;
    }
   
    public static List<enrolment__c > getEnrolment(String actObjId){
        return [SELECT id, Package__r.Name ,Student__r.Name, Student__c 
                FROM enrolment__c 
                WHERE parent__c=: actObjId];
    }
    public static map<Id,enrolment__c > getEnrolments(String enrollmentId){
        return new Map<Id, enrolment__c >([SELECT id,Instrument__c, Package__r.Name ,Package__r.Type__c,Student__r.Name, Student__c ,Package__r.Duration__c,teacher__c
                                           FROM enrolment__c 
                                           WHERE Id=: enrollmentId]);
    }
    
    // get enrollment with booking according to Parent id
    public static List<Enrolment__c> getEnrolmentWithBooking(String parentId){
        return [SELECT Id,Student__r.Name, Student__c,Instrument__c,Package__r.Duration__c,Package__r.Type__c,
                (SELECT ID, Teacher_Account__c,Center__c,Name, Instrument__c, Student__c,Teacher_Account__r.Name, Student__r.Name,Enrolment__c, Booking_Date__c,Appointment_Day__c,
                 Package__r.Name,Package__r.Type__c, Duration__c, Center__r.Name, Center_Name__c,start_time__c,Status__c ,Is_Reschedule_Booking__c,
                 type__C,Cancellation_Reason__c,Available_Make_up_Units__c, Make_up_Expiry_Date__c, Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                 FROM Bookings__r 
                 WHERE Booking_Date__c =NEXT_90_DAYS 
                 AND type__c != :ConstantsClass.typeBusy
                 Order By Booking_Date__c DESC
                ),// Oct-09-2019 :Nishi :  Start : for get FifthBooking records
                (SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Package__r.Instrument__c,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c,Center__r.COuntry__r.Tax_rate__c
                FROM Fifth_Lessons__r
                 WHERE Booking_Date__c =NEXT_90_DAYS 
                 AND Booking__c = NULL
                 and IsActive__c = true
                 Order By Booking_Date__c DESC)
                 // Oct-09-2019 :Nishi :  END :  for get FifthBooking records
                FROM Enrolment__c 
                WHERE Parent__c =: parentId
               ];
        
    }
    /*---  end enrolment__c query function */ 
    
    
    /*---  start case query function */ 
    // get Booking according to limit and offset and type
    public Static List<Case> getCaseUpcomingAndHistoricalList(String parentId,String type,Integer recLimit,Integer recOffset){
        if(type == 'upcoming'){
            return [SELECT Id, Subject, AccountId, Status, caseNumber,Description, Student_Name__c, Student_Name__r.name, Type,Createddate,
                    (SELECT Id,ParentId ,CommentBody,CreatedDate,CreatedBy.Name 
                     FROM CaseComments 
                     Order By createddate DESC
                    ) 
                    FROM Case 
                    Where AccountId=:parentId  
                    AND Origin = 'App' 
                    AND status in('Open','New')
                    Order By Createddate DESC
                    LIMIT :recLimit
                    OFFSET :recOffset];
        }else if(type == 'historical'){
            return [SELECT Id, Subject, AccountId, Status,caseNumber,Description, Student_Name__c, Student_Name__r.name, Type,Createddate ,
                    (SELECT Id,ParentId ,CommentBody,CreatedDate,CreatedBy.Name 
                     FROM CaseComments
                     Order By createddate DESC) 
                    FROM Case 
                    Where AccountId=:parentId 
                    AND Origin = 'App' 
                    AND status ='Closed'
                    Order By Createddate DESC
                    LIMIT :recLimit
                    OFFSET :recOffset];
        }else{
            return [SELECT Id, Subject, AccountId, Status, caseNumber,Description, Student_Name__c, Student_Name__r.name, Type,Createddate,
                    (SELECT Id,ParentId ,CommentBody,CreatedDate,CreatedBy.Name 
                     FROM CaseComments 
                     Order By createddate DESC) 
                    FROM Case 
                    Where AccountId=:parentId 
                    AND Origin = 'App' 
                    Order By Createddate DESC
                    LIMIT :recLimit
                    OFFSET :recOffset];
        }
        
    }
    /*---  end case query function  --- */ 
    
    
    /*---  start Program__c query function  --- */ 
    public Static List<Program__c> getAllProgram(){
        return [SELECT Status__c, Name, Id FROM Program__c where Status__c='Active' and Instrument__c != null];
        
    }
    /*---  end case query function  --- */ 
    
    
    /*---  start Teacher_Working_Hour__c query function  --- */ 
    public static List<Teacher_Working_Hour__c> getTeachersWorkingHours(String teacherId, String centreId, String weekDay){
        system.debug('@@teacherId'+teacherId);
        system.debug('@@centreId'+centreId);
        system.debug('@@weekDay'+weekDay);
        return [SELECT Id, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c 
                WHERE Center_Name__c =: centreId AND Teacher_Name__c =: teacherId 
                AND Working_Day__c =: weekDay AND Active__c = True AND Break_Time__c = False];
    }
    public static List<Teacher_Working_Hour__c> getMultipleTeachersWorkingHours(list<String> teacherIds, String centreId, String weekDay){
        system.debug('@@teacherId'+teacherIds);
        system.debug('@@centreId'+centreId);
        system.debug('@@weekDay'+weekDay);
        return [SELECT Id, Start_Time__c, End_Time__c,Teacher_Name__c FROM Teacher_Working_Hour__c 
                WHERE Center_Name__c =: centreId AND Teacher_Name__c in: teacherIds
                AND Working_Day__c =: weekDay AND Active__c = True AND Break_Time__c = False];
    }
    
    
    
    
    public static List<Teacher_Working_Hour__c> getTeachersWorkingHours(String teacherId, String centreId){
        return [SELECT  Id, Start_Time__c, End_Time__c, Working_Day__c  FROM Teacher_Working_Hour__c 
                WHERE Center_Name__c =: centreId AND Teacher_Name__c =: teacherId 
                AND Active__c = True AND Break_Time__c = False];
    }
    
    public static List<Teacher_Working_Hour__c> getmultipleTeachersWorkingHours(List<String> teacherIds, String centreId){
        Set<String> workingDays = new Set<String>();
        //set<String> teacherIds = new Set<string>(teacherIdList);
        for(AggregateResult objAggregateResult : [SELECT  Working_Day__c FROM Teacher_Working_Hour__c 
                                                  WHERE  Center_Name__c =: centreId
                                                  AND Teacher_Name__c IN: teacherIds
                                                  AND Active__c = True 
                                                  AND Break_Time__c = False 
                                                  GROUP BY Working_Day__c 
                                                  having count(Working_Day__c ) >: teacherIds.size() - 1]){
                                                      workingDays.add(String.valueOf(objAggregateResult.get('Working_Day__c')));
                                                  }
        
        return [SELECT  Id, Start_Time__c, End_Time__c, Working_Day__c,Teacher_Name__c  FROM Teacher_Working_Hour__c 
                WHERE Center_Name__c =: centreId AND Teacher_Name__c In: teacherIds AND Working_Day__c in:workingDays
                AND Active__c = True AND Break_Time__c = False];
    }
    
    public static Map<String, Teacher_Working_Hour__c> getTeachersWorkingHours(Set<String> teacherIds, String centreId, String weekDay){
        Map<String, Teacher_Working_Hour__c> mapOfTeachersWorkingHours = new Map<String, Teacher_Working_Hour__c>();
        for(Teacher_Working_Hour__c workingHour : [SELECT Id, Start_Time__c, End_Time__c, Teacher_Name__c, Teacher_Name__r.Name FROM Teacher_Working_Hour__c 
                                                   WHERE Center_Name__c =: centreId AND Teacher_Name__c IN: teacherIds
                                                   AND Working_Day__c =: weekDay AND Active__c = True AND Break_Time__c = False]){
                                                       mapOfTeachersWorkingHours.put(workingHour.Teacher_Name__c, workingHour);
                                                   }
        return mapOfTeachersWorkingHours;
    }
    
    
    public Static List<teacher_working_hour__c > getTeacherWorkingHours(string centerId){
        return [select id,teacher_name__c,center_name__c 
                from teacher_working_hour__c 
                where center_name__c =: centerId 
                AND Active__c = true 
                AND Working_Day__c != null 
                AND Break_Time__c = False
                ORDER BY Teacher_Name__r.Name];
    }
    
    /*---  end Teacher_Working_Hour__c query function  --- */ 
    
    
    /*---  start Invoice__c query function  --- */ 
    // get invoice and related child 'Success' payment records 
    public static List<Invoice__c> getInvoice(String accountId){
        return [SELECT Id, Invoice_Date__c, Due_Date__c, Balance_Amount__c, Status__c, Gross_Total__c, Sub_Total__c, GST_Tax__c,
                GST_Tax_Amount__c, Discount_Amount__c, Deposit__c, Total_Amount__c,name,Card_Number__c,Card_Type__c,
                (SELECT Id, Payment_Date__c, Payment_Amount__c, Method_of_Payment__c
                 FROM Payments__r 
                 WHERE   Payment_Status__c= 'Success' )
                FROM Invoice__c
                WHERE Parent_Account__c=: accountId 
                AND Status__c != 'Void' 
                AND Invoice_Date__c >= 2019-06-01
                ORDER BY createddate DESC
               ];
    }
    
    // get invoice records
    public static List<Invoice__c> getPaymentInvoice(String InvoiceId){
        return [Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId,Parent_Account__r.Stripe_Customer_Id__c, 
                Total_Amount__c,subscription__c,Balance_Amount__c,Center__c,Center__r.Country__c FROM Invoice__c WHERE 
                Parent_Account__r.Stripe_Customer_Id__c != NULL AND Id= :InvoiceId
                AND Status__c=:ConstantsClass.dueStatus];
    }
    /*---  end Invoice__c query function  --- */ 
    
    
    /*---  start ContentVersion query function  --- */    
    public static List<ContentVersion > getContentVersion (String contentVersionId ){
        return [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId];
    }
    public static List<ContentDocumentLink> getContentDocumentLink (String parentId){
        return [SELECT  ContentDocumentId, Id, LinkedEntityId, IsDeleted, SystemModstamp, ShareType, Visibility, ContentDocument.LatestPublishedVersionId 
                FROM ContentDocumentLink 
                where LinkedEntityId =:parentId];
    }
   
    
    public static List<ContentDistribution > getContentDistribution(String contentVersionId ){
        return [SELECT id,ContentDocumentId
                FROM ContentDistribution 
                where ContentVersionId  =:contentVersionId 
               ];
    }
   
    public static string getContentLink(String distributionId, String docLinkId){
        //@Sunny 16 July, 2019
        ContentDistribution contentDis = [SELECT DistributionPublicUrl,ContentVersionId,ContentDocumentId FROM ContentDistribution WHERE Id=:distributionId];
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String orgId = '';
        List<Organization> orgList = Database.Query('select isSandbox, Id from organization');
        if(!orgList.isEmpty()){
            orgId = orgList[0].Id;
        } 
        ContentDocumentlink ContentDocumentlinkRec = [select id,LinkedEntityId,ContentDocumentId,ContentDocument.FileExtension from ContentDocumentlink 
                                                      where id = :docLinkId];
        String publicUrl = '';
        string versionId = contentDis.ContentVersionId;
        String urlToParse = contentDis.DistributionPublicUrl;                                                     
        String preUrl = baseUrl+'/sfc/dist/version/renditionDownload?rendition=';
        if(ContentDocumentlinkRec.ContentDocument.FileExtension == 'jpg' || ContentDocumentlinkRec.ContentDocument.FileExtension == 'jpeg'){
            preUrl  += 'ORIGINAL_Jpg';
        }else if(ContentDocumentlinkRec.ContentDocument.FileExtension == 'png'){
            preUrl  += 'ORIGINAL_Png';
        }  
        preUrl  += '&contentId='+contentDis.ContentDocumentId+'&operationContext=DELIVERY&page=0&oid='+orgId+'&dpt=null&viewId=';
        list<String> imageIdList = urlToParse.split('/a/');
        publicUrl = preUrl+'&versionId='+versionId+'&d=/a/'+imageIdList[1];
        return publicUrl;
    }
    
    /*---  end ContentVersion query function  --- */ 
    
    
    
    /*---  Package__c query function */
    // get makup type booking records
    public Static List<Package__c> getAvailableMakups (string centerId){
        return [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, 
                Unit_Fee__c, Active__c FROM Package__c 
                WHERE Location__c =: centerId 
                AND Active__c = true 
                AND Type__c = 'Makeup' 
                AND Duration__c != null
                AND Duration__c != '15' 
                ORDER BY Duration__c];
    }
    // get Package list according to center id
    public Static List<Package__c> getListOfPackage(string centerId){
        return [SELECT Id, Duration__c, Name, Location__c, Type__c 
                FROM Package__c 
                WHERE Location__c=:centerId
                AND Type__c='Makeup'];
        
    }
    // get Package list according to program and location id
    public Static List<Package__c> getListOfPackage(String program,String location){
        return [SELECT Id, Duration__c, Name, Location__c, Type__c 
                FROM Package__c 
                WHERE Location__c=:location
                AND program__c=:program
                ANd Package_Fee__c > 0];
        
    }
    
    public Static List<Package__c> getListOfMakeupPackage(){
        return [SELECT Id, Name, Location__c, Duration__c, of_Units__c, Type__c, Package_Fee__c, Registration_Fee__c, 
                Unit_Fee__c, Active__c FROM Package__c 
                WHERE Active__c = true AND Type__c = 'Makeup' AND Duration__c != null ORDER BY Duration__c];
    }
    /*---  Package__c query function */
    
    /*-- Mobile Notification query function*/
    public Static List<Mobile_Notification__c > getListOfParentMobileNotification(String parentId){
        return [SELECT Id, Customer_Name__c, Body__c, Title__c, Status__c, Deleted_by_user__c, createddate 
                FROM Mobile_Notification__c 
                where Customer_Name__c =: parentId 
                AND Deleted_by_user__c =False 
                ORDER BY createddate desc];
    }
    public Static List<Mobile_Notification__c > getListOfMobileNotification(String notificationId){
        return [SELECT Id, Customer_Name__c, Body__c, Title__c, Status__c, Deleted_by_user__c
                FROM Mobile_Notification__c 
                where id =: notificationId
               ];
    }
    /*-- Mobile Notification query function*/
    
    
        
}