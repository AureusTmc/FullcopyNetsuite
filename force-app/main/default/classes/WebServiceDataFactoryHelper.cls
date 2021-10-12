/*
Name        :    WebServiceDataFactoryHelper
Date        :    04/Jun/2019
Author      :  
Description :    This Helper class is used in all Api WebService controller.

*/
Public without sharing class WebServiceDataFactoryHelper{

public static string apikey;
public static string baseUrl;

static{
    List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
    if(stripeSettings!= null && stripeSettings.size()>0){
        baseUrl = stripeSettings[0].Stripe_Base_Url__c;
        apiKey = stripeSettings[0].Stripe_Secret_Key__c;
    }
}

// check login user is exist or not according to email and password FOR Homepage API
public static string fetchLoginAccount(String emailId, String password,string token,string DeviceType){
    password = EncodingUtil.convertToHex(Blob.valueOf(password));
    //system.debug(password);
    list<Account> accountList  = SOQLQueryHelper.getExistingParentAccount(emailId,password);
    
    system.debug('accountList'+accountList);
    if(accountList  != null && accountList.size() > 0 && accountList [0].Customer_Password__c.equals(password)){
        account actObj = accountList [0];
        system.debug(actObj.Available_Make_up_Units__c);
        //get enrollement and related 4 Bookings historical and upcomming 
        list<Enrolment__c> listOfEnrolmentwithUpcommingBooking = SOQLQueryHelper.getEnrolmentwithUpcommingBooking(actObj.id); 
        list<Enrolment__c> listOfEnrolmentwithHistoricalBooking = SOQLQueryHelper.getEnrolmentwithHistoricalBooking(actObj.id); 
        list<Home_Carousel__c> listOfHome_Carousel = new list<Home_Carousel__c>();//SOQLQueryHelper.getevent();
        List<Booking__c> listOfBookingWithoutEnrolment = SOQLQueryHelper.getBookingWithoutEnrolment(actObj.id);
        // 21-Nov-2019 : for add fifth lesson canceled bookings 
        List<Booking__c> listOfBookingFifthBookingPlaceholder = SOQLQueryHelper.getBookingFifthBookingPlaceholder(actObj.id);
        List<Fifth_Lesson__c> listOfFifthLesson = SOQLQueryHelper.getListOfFifthLesson(actObj.id);
        list<Account> listOfStudentAccount= SOQLQueryHelper.getStudentAccount(actObj.id);
        WebServiceModelHelper.HomePageModal mdlobj = new WebServiceModelHelper.HomePageModal();
        system.debug(listOfEnrolmentwithUpcommingBooking);
        system.debug(listOfEnrolmentwithHistoricalBooking);
        
        //@Sunny 25 Sep, 2019 Allow only if there is upcoming bookings
        boolean hasUpcomingBooking = false;
        if(listOfEnrolmentwithUpcommingBooking !=null){
            for(Enrolment__c enrol : listOfEnrolmentwithUpcommingBooking ) {
                if(enrol.bookings__r != null && enrol.bookings__r.size() >0){
                    for(Booking__c booking : enrol.bookings__r) {
                        if(booking.Status__c == 'Scheduled' || booking.Status__c == 'Pending'){
                            hasUpcomingBooking = true;
                        }
                    }
                }
            }
        }
        if(!hasUpcomingBooking) {
            RestContext.response.statusCode = 400;
            return '{"errorCode":"DATA_NOT_FOUND","message":"This email is not enroled with Aureus Academy. Please contact your Center Admin."}';
        }
        
        mdlobj.parentId = actObj.id;
        mdlobj.name= actObj.name;            
        mdlobj.firstName = actObj.firstName;
        mdlobj.lastName = actObj.lastName;
        mdlobj.email= actObj.PersonEmail;
        mdlobj.gender= actObj.Gender__c;
        mdlobj.phone= actObj.phone;
        mdlobj.profilePictureUrl= actObj.Profile_Pic_URL__c;
        // if get Subscription_Line_Items__r then add nextBillingDate 
        if(actObj.Subscription_Line_Items__r != null && actObj.Subscription_Line_Items__r.size() > 0) {
            mdlobj.nextBillingDate = actObj.Subscription_Line_Items__r[0].Next_Bill_Date__c ;
        }
        //System.debug('@@actObj.Invoices__r.size()'+actObj.Invoices__r);
        // if get Invoices__r then add isInvoiceDue value true other wise false
        if(actObj.Invoices__r != null && actObj.Invoices__r.size() > 0){
            mdlobj.isInvoiceDue = true;
        }else{
            mdlobj.isInvoiceDue = false;
        }
        if(actObj.Membership_Type__c =='American Club'){
            mdlobj.isAmericanClubMember= true;
        }else{
            mdlobj.isAmericanClubMember= false;
        }
        
        mdlobj.nationality= actObj.Nationality__c;
        mdlobj.cardNumber= actObj.Card_Number__c;
        mdlobj.cardType= actObj.Card_Type__c;
        mdlobj.expiration= actObj.Expiration__c;
        mdlobj.invoicePaidNotification= actObj.Invoice_Paid_Notification__c;
        mdlobj.bookingRemindedNotification =  actObj.Booking_Reminded_Notification__c ;
        mdlobj.street= actObj.BillingStreet;
        mdlobj.city = actObj.BillingCity;
        mdlobj.country=actObj.BillingCountry;
        mdlobj.postal_Code= actObj.BillingpostalCode;
        if(actObj.Centre_Name__r != null && actObj.Centre_Name__r.Country__r != null){
            system.debug('@@IF listOfHome_Carousel '+listOfHome_Carousel );
            mdlobj.centreCurrency = actObj.Centre_Name__r.Country__r.Currency_Code__c;
            listOfHome_Carousel = SOQLQueryHelper.getevent(actObj.Centre_Name__r.Country__r.name); 
        }else{
            system.debug('@@ELSE listOfHome_Carousel '+listOfHome_Carousel );
            mdlobj.centreCurrency= '';    
            listOfHome_Carousel = SOQLQueryHelper.getevent('SG');   
        }
        //mdlobj.centreCurrency= actObj.Centre_Name__r != null && actObj.Centre_Name__r.Country__r != null ? actObj.Centre_Name__r.Country__r.Currency_Code__c : '';
        
        
        mdlobj.availableMakeupUnits = actObj.Available_Make_up_Units__c == null ? String.valueOf(0) : String.valueOf(actObj.Available_Make_up_Units__c);
        map<String,WebServiceModelHelper.Enrollments> mapOfEnrollments = new Map<String,WebServiceModelHelper.Enrollments>();
        String enrollmentId = '';
        if( listOfEnrolmentwithUpcommingBooking != null && listOfEnrolmentwithUpcommingBooking.size() >0 ){
            // add enrollment and related upcomming bookings
            //commented by Rajesh on 20th July 2020, to solve make-up issue which were not showing on mobile home page after discussion with Sunny
            //enrollmentId = listOfEnrolmentwithUpcommingBooking[0].id;
            for(Enrolment__c enrolment :listOfEnrolmentwithUpcommingBooking ){
                WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
                objEnrollments.id = enrolment.id;
                objEnrollments.duration = enrolment.Package__r.Duration__c +' min';
                objEnrollments.studentName= enrolment.Student__r.Name;
                objEnrollments.studentId= enrolment.Student__c;
                objEnrollments.instrument = enrolment.instrument__c;
                
                objEnrollments.lessonDay = enrolment.Lesson_Day__c;
                objEnrollments.lessonType= enrolment.Package__r.program__r.Name;
                objEnrollments.regularTime= enrolment.Lesson_Start_time__c;
                objEnrollments.teacherName = enrolment.Teacher__r.name;
                objEnrollments.teacherId= enrolment.Teacher__c;
                objEnrollments.status = enrolment.Stage__c;
                objEnrollments.location = enrolment.center__r.location__c;
                objEnrollments.centerId = enrolment.center__c;
                objEnrollments.packageName = enrolment.Package__r.Name;
                objEnrollments.packageId= enrolment.Package__c;
                objEnrollments.programId= enrolment.Package__r.program__c;
                objEnrollments.packagePrice = ''+enrolment.Package__r.Package_Fee_with_GST__c;
                
                objEnrollments.packageType = enrolment.Package__r.type__c;
                if(enrolment.Subscription_Line_Items__r != null&& enrolment.Subscription_Line_Items__r.size() > 0){
                    objEnrollments.NextBillDate= enrolment.Subscription_Line_Items__r[0].Next_Bill_Date__c ;
                }
                List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
                List<Booking__c> upcomingBookings = new List<Booking__c>();
                if(enrolment.Bookings__r!= null && enrolment.Bookings__r.size() > 0){
                    for(Booking__c booking : enrolment.Bookings__r){
                        listOfBooking.add(addBookingvalue(booking));
                        if(booking.status__c == 'Scheduled' || booking.status__c == 'Pending') {
                            upcomingBookings.add(booking);
                        }
                    }
                }
                // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with bookings records
                if(enrolment.Fifth_Lessons__r!= null && enrolment.Fifth_Lessons__r.size() > 0){  
                    for(Fifth_Lesson__c objFifthLesson: enrolment.Fifth_Lessons__r){
                        listOfBooking.add(addFifthLessonRecords(objFifthLesson));
                    }     
                }
                // Oct-09-2019 :Nishi :  END : for add Fifth booking lesson list with bookings records
                system.debug('@@@listOfBooking'+listOfBooking);
                objEnrollments.bookings  = listOfBooking;
                
                if(enrolment.stage__c == 'Cancelled') {
                    if(upcomingBookings!= null && upcomingBookings.size() > 0) {
                        mapOfEnrollments.put( enrolment.id,objEnrollments); 
                    }
                } else { 
                    mapOfEnrollments.put( enrolment.id,objEnrollments); 
                }
                
                //Added by Rajesh on 20th July 2020, to solve make-up issue which were not showing on mobile home page after discussion with Sunny
                if(String.isBlank(enrollmentId) && mapOfEnrollments.size() > 0){
                    enrollmentId = mapOfEnrollments.values().get(0).id;
                }
            }
            
        }
        
        if(listOfEnrolmentwithHistoricalBooking != null && listOfEnrolmentwithHistoricalBooking.size() > 0 ){ 
            enrollmentId  = (enrollmentId != null )? enrollmentId :listOfEnrolmentwithHistoricalBooking[0].id;
            //add historical bookings according to enrollment id
            for(Enrolment__c enrolment :listOfEnrolmentwithHistoricalBooking ){
                List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
                WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
                if(enrolment.Bookings__r != null && enrolment.Bookings__r.size() > 0){
                    for(Booking__c booking : enrolment.Bookings__r){
                        if(mapOfEnrollments.containsKey(enrolment.id)){
                            listOfBooking = mapOfEnrollments.get(enrolment.id).bookings;
                            objEnrollments =  mapOfEnrollments.get(enrolment.id);
                            listOfBooking.add(addBookingvalue(booking ));
                            objEnrollments.bookings  = listOfBooking;
                            mapOfEnrollments.put( enrolment.id,objEnrollments); 
                        }
                    }
                }
                // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with bookings records
                if(enrolment.Fifth_Lessons__r!= null && enrolment.Fifth_Lessons__r.size() > 0){  
                    for(Fifth_Lesson__c objFifthLesson: enrolment.Fifth_Lessons__r){
                        if(mapOfEnrollments.containsKey(enrolment.id)){
                            listOfBooking = mapOfEnrollments.get(enrolment.id).bookings;
                            objEnrollments =  mapOfEnrollments.get(enrolment.id);
                            listOfBooking.add(addFifthLessonRecords(objFifthLesson));
                            objEnrollments.bookings  = listOfBooking;
                            mapOfEnrollments.put( enrolment.id,objEnrollments); 
                        } 
                        
                    }     
                }
                system.debug('@@@listOfBooking'+listOfBooking);
                // Oct-09-2019 :Nishi :  END : for add Fifth booking lesson list with bookings records
            }
            
        }
        
        if(listOfBookingWithoutEnrolment != null && listOfBookingWithoutEnrolment.size() >0){
            List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
            WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
            for(Booking__c booking : listOfBookingWithoutEnrolment ){
                if(mapOfEnrollments.containsKey(enrollmentId  )){
                    listOfBooking = mapOfEnrollments.get(enrollmentId).bookings;
                    objEnrollments =  mapOfEnrollments.get(enrollmentId);
                    listOfBooking.add(addBookingvalue(booking ));
                    objEnrollments.bookings  = listOfBooking;
                    mapOfEnrollments.put(enrollmentId ,objEnrollments); 
                }
            }
        }
        // add fifth lesson canceled booking 
        if(listOfBookingFifthBookingPlaceholder != null && listOfBookingFifthBookingPlaceholder.size() > 0){
            List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
            WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
            for(Booking__c booking : listOfBookingFifthBookingPlaceholder ){
                if(string.isnotBlank(booking.Enrolment__c)){
                    if(mapOfEnrollments.containsKey(booking.Enrolment__c  )){
                        listOfBooking = mapOfEnrollments.get(booking.Enrolment__c).bookings;
                        objEnrollments =  mapOfEnrollments.get(booking.Enrolment__c);
                        listOfBooking.add(addBookingvalue(booking ));
                        objEnrollments.bookings  = listOfBooking;
                        mapOfEnrollments.put(booking.Enrolment__c ,objEnrollments); 
                    }  
                }else{
                    if(mapOfEnrollments.containsKey(enrollmentId  )){
                        listOfBooking = mapOfEnrollments.get(enrollmentId).bookings;
                        objEnrollments =  mapOfEnrollments.get(enrollmentId);
                        listOfBooking.add(addBookingvalue(booking ));
                        objEnrollments.bookings  = listOfBooking;
                        mapOfEnrollments.put(enrollmentId ,objEnrollments); 
                    }
                }
            }   
        }
        // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with bookings records with out enrollement
        if(listOfFifthLesson != null && listOfFifthLesson.size() > 0){
            List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
            WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
            for(Fifth_Lesson__c objFifthLesson : listOfFifthLesson){
                if(mapOfEnrollments.containsKey(enrollmentId)){
                    listOfBooking = mapOfEnrollments.get(enrollmentId).bookings;
                    objEnrollments =  mapOfEnrollments.get(enrollmentId);
                    listOfBooking.add(addFifthLessonRecords(objFifthLesson));
                    objEnrollments.bookings  = listOfBooking;
                    mapOfEnrollments.put(enrollmentId ,objEnrollments); 
                    
                }
            }
            system.debug('@@@listOfBooking'+listOfBooking);
        }
        
        // Oct-09-2019 :Nishi :END: for add Fifth booking lesson list with bookings records
        
        mdlobj.enrolments.addAll(mapOfEnrollments.values());
        
        // add event records
        List<WebServiceModelHelper.event> listofevent = new List<WebServiceModelHelper.event>();
        if(listOfHome_Carousel != null && listOfHome_Carousel.size() > 0 ){
            for(Home_Carousel__c Home_Carouseobj : listOfHome_Carousel ){
                WebServiceModelHelper.event eventobj = new WebServiceModelHelper.event();     
                eventobj.description = Home_Carouseobj.Description__c;
                eventobj.sr_No=Home_Carouseobj.Sr_No__c;
                eventobj.imageURL=Home_Carouseobj.Image_URL__c;
                eventobj.title=Home_Carouseobj.Title__c;
                eventobj.webURL=Home_Carouseobj.Web_URL__c;
                listofevent.add(eventobj );
            }
        }
        mdlobj.events.addAll(listofevent);
        
        // added student records
        List<WebServiceModelHelper.student> listofstudent = new List<WebServiceModelHelper.student>();
        if( listOfStudentAccount != null && listOfStudentAccount.size() >0 ){
            for(Account accObj: listOfStudentAccount){
                WebServiceModelHelper.student studentobj = new WebServiceModelHelper.student();     
                studentobj .schoolName= accObj.School__r.Name;            
                studentobj.firstName = accObj.firstName;
                studentobj.lastName = accObj.lastName;
                studentobj.birthdate= accObj.PersonBirthdate;
                studentobj.gender= accObj.Gender__c;
                studentobj.learningStyle= accObj.Learning_Style__c;
                studentobj.studentId= accObj.Id;
                listofstudent .add(studentobj);
            }
        }
        
        mdlobj.students.addAll(listofstudent );
        // Start 21-nov-2019 for show fifth booking url
        List<faq_link_for_portal__c> ListOfFaqLinkForPortal = [Select Id,link_name__c  from faq_link_for_portal__c limit 1];
        if(ListOfFaqLinkForPortal != null && ListOfFaqLinkForPortal.size() > 0){
            mdlobj.fifthBookingFaqUrl = ListOfFaqLinkForPortal[0].link_name__c;
        }
        // End  21-nov-2019 for show fifth booking url
        // check token if token is exist then update parent account record
        if(String.IsnotBlank(token)){
            try{
                Account accobj = new Account(id = actObj.id,FCM_Token__c =token);
                update accobj;
            }catch(exception e){
                RestContext.response.statusCode = 500;
                system.debug('e.getMessage()'+e.getMessage());
                return '{"errorCode":"INTERNAL_ERROR","message":"'+e.getMessage()+'"}';
            }
        }
        // added By Ravi on 14 sept 2020...as require to store device type
        if(String.IsnotBlank(DeviceType)){
            try{
                Account accobj = new Account(id = actObj.id,DeviceType__c =DeviceType,Last_App_Login_Date__c=system.today());
                update accobj;
            }catch(exception e){
                RestContext.response.statusCode = 500;
                system.debug('e.getMessage()'+e.getMessage());
                return '{"errorCode":"INTERNAL_ERROR","message":"'+e.getMessage()+'"}';
            }
        }
        //End..added By Ravi on 14 sept 2020...as require to store device type 
        RestContext.response.statusCode = 200;
        return JSON.serialize(mdlobj).replaceAll('time_c','time').replaceAll('date_c','date').replaceAll('centreCurrency','currency');
    }else{
        //Added By Nitin 
        List<Account> accList = SOQLQueryHelper.getExistingTeacherAccount(emailId,password);
        if(accList.size()>0){
            Date startDt = System.Today().addDays(-7);
            Date endDt = System.Today().addDays(7);
            WebServiceModelHelper.teacherLogin teacher = new WebServiceModelHelper.teacherLogin(accList[0].Name, [SELECT id, Booking_Date__c,Teacher_Account__c,Center__c,Teacher_Account__r.name,Instrument__c , Student__r.Name, Enrolment__c,
                                                                                                                    Student__c,student_Name__c, Appointment_Day__c,Center_Location__c, Package__r.Name,Package__r.type__c, Duration__c, start_time__c, Center__r.Name,Status__c,Is_Reschedule_Booking__c,
                                                                                                                    type__c,Cancellation_Reason__c,Available_Make_up_Units__c,Make_up_Expiry_Date__c,Lesson_Type__c, Online_Lesson_Passcode__c, Online_Lesson_URL__c
                                                                                                                    FROM booking__c WHERE Teacher_Account__c=: accList[0].Id AND Booking_Date__c >=: startDt  AND Booking_Date__c <=: endDt AND (Type__c = 'Trial' OR Type__c = 'Regular' OR Type__c = 'Make-Up' OR Type__c = 'Ad-Hoc') ORDER BY Booking_Date__c,start_time__c    Limit 1000]);
            return JSON.Serialize(teacher);    
        }
        else{
            RestContext.response.statusCode = 400;
            return '{"errorCode":"DATA_NOT_FOUND","message":"Please Check your Email and Password."}';
        }
    }
}


//09-Oct-2019 add booking model class value according to given Fifth_lesson record
private static WebServiceModelHelper.Bookings addFifthLessonRecords(Fifth_Lesson__c objFifthLesson){
    WebServiceModelHelper.Bookings bookingObj = New WebServiceModelHelper.Bookings();
    bookingObj.bookingId = objFifthLesson.id;
    bookingObj.studentName= objFifthLesson.Student__r.Name;
    bookingObj.studentId= objFifthLesson.Student__c;
    bookingObj.date_c= objFifthLesson.Booking_Date__c ;
    //bookingObj.weekday= booking.Appointment_Day__c;
    bookingObj.packageName= objFifthLesson.Package__r.Name;
    bookingObj.packageType= objFifthLesson.Package__r.type__c;
    bookingObj.time_c= objFifthLesson.start_time__c ;
    bookingObj.instrument= objFifthLesson.Package__r.Instrument__c; //change in 14-Oct-2019: Nishi: '5th Lesson';
    bookingObj.center= objFifthLesson.Center__r.Name;
    bookingObj.teacherName= objFifthLesson.Teacher_Account__r.Name;
    bookingObj.teacherId= objFifthLesson.Teacher_Account__c;
    bookingObj.centerId= objFifthLesson.Center__c;
    bookingObj.enrollmentId = objFifthLesson.Enrolment__c;
    bookingObj.unitFee = objFifthLesson.Package__r.Unit_Fee__c;
    if(objFifthLesson.Package__r != null && objFifthLesson.Center__r.Country__r != null){ 
        bookingObj.gst = ((objFifthLesson.Package__r.Unit_Fee__c != null ? objFifthLesson.Package__r.Unit_Fee__c :1)*
                            ((objFifthLesson.Center__r.Country__r.Tax_rate__c != null ?objFifthLesson.Center__r.Country__r.Tax_rate__c :1)
                            /100)).setscale(2); ///Package__r.Package_Fee_with_GST__c; 
    }
    bookingObj.status = 'Scheduled';//(booking.Status__c=='Pending'?'Scheduled':booking.Status__c);
    //bookingObj.rescheduled =booking.Is_Reschedule_Booking__c;
    bookingObj.duration =  String.valueOf(objFifthLesson.Duration__c) + ' min';
    bookingObj.isFifthBooking = true;
    //bookingObj.type=booking.Type__c;
    //bookingObj.cancellationReason =booking.Cancellation_Reason__c;
    //bookingObj.expiryDate=booking.Make_up_Expiry_Date__c;
    
    /*bookingObj.availableMakeupMin =String.isNotBlank(String.valueOf(booking.Available_Make_up_Units__c)) ?
booking.Available_Make_up_Units__c +' min':
booking.Available_Make_up_Units__c +'' ;*/
    system.debug('@@@@ addFifthLessonRecords  bookingObj ---'+objFifthLesson);
    return bookingObj;
}

public  static string autoGenerateCode(){
    final integer STRING_LENGTH = 4;
    decimal  randomNumber =Math.Round(Math.Random() * ((Math.pow(10,STRING_LENGTH) - 1)-Math.pow(10,STRING_LENGTH -1)) + Math.pow(10,STRING_LENGTH -1));
    if(randomNumber <= 9999 && randomNumber > 999){
        if(String.valueOf(randomNumber).length() == 4){
            return String.valueOf(randomNumber);
        }else{
            return autoGenerateCode();
        }
    }else{
        return autoGenerateCode();
    }
}
// for signup send email with new random generated code 
public static string generateCode(String emailId, Boolean reset){
    list<Account> accountList  = SOQLQueryHelper.getAccountIsSignupOrReset(emailId,reset);   
    system.debug('@@accountList  '+accountList  );
    if(accountList!= null && accountList.size() > 0 ){
        account actObj =  accountList [0];
        list<Enrolment__c> listOfEnrolmentwithUpcommingBooking = SOQLQueryHelper.getEnrolmentwithUpcommingBooking(actObj.id); 
        List<OrgWideEmailAddress > orgWideIds = [select id, Address,displayname 
                                                    from OrgWideEmailAddress
                                                    where address= 'noreply@aureusacademy.com'];
        String orgWideId = '';
        if(orgWideIds != null && orgWideIds.size() > 0) {
            orgWideId = orgWideIds[0].id;
        }
        System.debug('@@listOfEnrolmentwithUpcommingBooking '+listOfEnrolmentwithUpcommingBooking );
        System.debug('@@orgWideId '+orgWideId );
        //@Sunny 25 Sep, 2019 Allow only if there is upcoming bookings
        boolean hasUpcomingBooking = false;
        if(listOfEnrolmentwithUpcommingBooking !=null){
            for(Enrolment__c enrol : listOfEnrolmentwithUpcommingBooking ) {
                for(Booking__c booking : enrol.bookings__r) {
                    if(booking.Status__c == 'Scheduled' || booking.Status__c == 'Pending'){
                        hasUpcomingBooking = true;
                    }
                }
            }
        }
        // if related enrollment upcomming booking is exist then user can sign up other wise not
        if(listOfEnrolmentwithUpcommingBooking != null && listOfEnrolmentwithUpcommingBooking.size() >0 && hasUpcomingBooking){ 
            string randomNumber = autoGenerateCode();
            // get Mobile_Api_Emails__c custom setting and set values for check random number and expire date in signup time
            Map<String,Mobile_Api_Emails__c> mapOfMobileApiEmail = Mobile_Api_Emails__c.getall();
            Mobile_Api_Emails__c Mobile_Api_Emailsobj = new  Mobile_Api_Emails__c();
            if(mapOfMobileApiEmail.containsKey(actObj.PersonEmail )){
                Mobile_Api_Emailsobj = new Mobile_Api_Emails__c(
                    Code_Expire_Date__c = DateTime.now().adddays(1),
                    Auto_Generate_Code__c =randomNumber,
                    id= mapOfMobileApiEmail.get(actObj.PersonEmail ).Id);
            }else{   
                Mobile_Api_Emailsobj = new Mobile_Api_Emails__c(name=actObj.PersonEmail ,
                                                                Email_Address__c = actObj.PersonEmail ,
                                                                Code_Expire_Date__c = DateTime.now().adddays(1),
                                                                Auto_Generate_Code__c = randomNumber);
            }
            system.debug('@@mapOfMobileApiEmail '+mapOfMobileApiEmail );
            System.debug('@@Mobile_Api_Emailsobj'+Mobile_Api_Emailsobj);
            Database.UpsertResult  saveResult = Database.upsert(Mobile_Api_Emailsobj, false);
            system.debug('@@saveResult.isSuccess()'+saveResult.isSuccess());
            if (saveResult.isSuccess()) { 
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                list<EmailTemplate> listOfEmailTemplate = [select Id,HtmlValue from EmailTemplate where DeveloperName='OTP_Email_Login_Confirmation'];
                mail.setTemplateId(listOfEmailTemplate[0].Id);
                mail.setToAddresses(New List<String>{emailId});
                mail.settreattargetobjectasrecipient(false);
                /*mail.setSubject('Finish setting your Aureus Account');
mail.setHTMLBody('<br/> Hi '+actObj.Name + '<br/> We recently received a request to set the password for the username '+ actObj.PersonEmail  +'. To finish setting your password.<br/>'+
' Your OTP code is : '+randomNumber+'<br/> go to the mobile app and use this code. This code expires in 24 hours.'+
'<br/><br/> <br/><br/>'+
'<h5>Aureus Group Pte Ltd</h5>'+
'<h5/>Headquarters: 12 Tai Seng Link, #04-02, Singapore 534233</h5>'
);
*/ // set email address
                mail.setTargetObjectId([select Id from User where id=:userInfo.getUserId()].Id);
                mail.setSaveAsActivity(false);
                mail.setWhatId([select Id from account where id=:actObj.Id].Id);
                //mail.setHtmlBody(listOfEmailTemplate[0].HtmlValue);
                if(String.isNotBlank(orgWideId))
                    mail.setOrgWideEmailAddressId(orgWideId);
                System.debug('@@listOfEmailTemplate '+listOfEmailTemplate );
                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                allmsg.add(mail);
                system.debug('@@mail'+mail);
                try {
                    Messaging.sendEmail(allmsg,false);
                    RestContext.response.statusCode = 200;
                    return '{"errorCode":"SUCCESS","message":"OTP sent to '+ actObj.PersonEmail  +'"}';
                }catch (Exception e) {
                    System.debug('error');
                    RestContext.response.statusCode = 500;
                    return '{"errorCode":"INTERNAL_ERROR","message":"'+e.getMessage()+'"}';
                }
            }else{
                RestContext.response.statusCode = 500;
                return '{"errorCode":"INTERNAL_ERROR","message":"Account Not updated"}';
            }
        }else{
            RestContext.response.statusCode = 400;
            if(reset){
                return '{"errorCode":"DATA_NOT_FOUND","message":"This email is not enroled with Aureus Academy. Please contact your Center Admin."}';
            }else{
                return '{"errorCode":"DATA_NOT_FOUND","message":"You don\'t have any enrollment"}';
            }
        }
    }else{
        RestContext.response.statusCode = 400;
        if(reset){
            return '{"errorCode":"INVALID_EMAIL","message":"This email is not enroled with Aureus Academy. Please contact your Center Admin."}';
        }else{
            return '{"errorCode":"INVALID_EMAIL","message":"This email is not enroled with Aureus Academy. Please contact your Center Admin."}';
        }
    }
}

// for signup parent account
public Static String signUpAccount(String emailId,String password,string code){
    list<Account> accountList  = SOQLQueryHelper.getNewEmailAccountId(emailId);
    if( accountList  != null && accountList .size() > 0){
        // get Mobile_Api_Emails__c custom setting 
        Map<String,Mobile_Api_Emails__c> mapOfMobileApiEmail = Mobile_Api_Emails__c.getall();
        // check email Id is exist or not
        if(mapOfMobileApiEmail != null && mapOfMobileApiEmail.size() > 0 && mapOfMobileApiEmail.containsKey(emailId)){
            System.debug(mapOfMobileApiEmail.get(emailId).Auto_Generate_Code__c);
            System.debug(code);
            // check random generated code is exist or not 
            if(mapOfMobileApiEmail.get(emailId).Auto_Generate_Code__c == code){
                DateTime currentDate = DateTime.now();
                DateTime previousDate = mapOfMobileApiEmail.get(emailId).Code_Expire_Date__c;
                Decimal Hours = decimal.valueOf((previousDate.getTime() - currentDate.getTime()));
                Decimal hoursnew = Hours/(1000*60*60);
                // check singup time is expire or not
                if(hoursnew  < 0){
                    RestContext.response.statusCode = 400; 
                    return '{"errorCode":"OTP_EXPIRE","message":"It\'s too late.Your OTP is expired now."}';
                }else{
                    try{
                        String pass = EncodingUtil.convertToHex(Blob.valueOf(password));
                        if(accountList[0].Customer_Password__c.equalsIgnoreCase(pass)){
                            RestContext.response.statusCode = 400; 
                            return '{"errorCode":"OLD_PASS","message":"You cannot use last password again"}';
                        }else{
                            if(string.isNotBlank(pass)){
                                Account acc= New account(Id = accountList [0].Id,Customer_Password__c = pass);
                                update acc;
                                RestContext.response.statusCode = 200;
                                return '{"errroCode":"SUCCESS","message":"Update Account Successfully"}';
                            }
                            RestContext.response.statusCode = 200;
                            return '{"errroCode":"SUCCESS","message":"Checked your OTP"}';
                        }
                    }catch(exception e){
                        RestContext.response.statusCode = 500;
                        return '{"errorCode":"INTERNAL_ERROR","message":"' + e +'"}';
                    }
                }
            }else{
                RestContext.response.statusCode = 400;
                return '{"errorCode":"INVALID_OTP","message":"Invalid OTP. Please check OTP again"}';
            }
        }else{
            RestContext.response.statusCode = 400;
            return '{"errorCode":"INVALID_EMAIL","message":"Please Sign up."}';
        }
    }else{
        RestContext.response.statusCode = 400;
        return '{"errorCode":"INVALID_EMAIL","message":"This email is not enroled with Aureus Academy. Please contact your Center Admin."}';
    } 
}


// for get all cancel bookings related parent account
Public Static String getCancelBookingSelection(String accountId){
List<Account> accountList  = SOQLQueryHelper.getAccount(accountId);
String response;
if(accountList  != null && accountList .size() > 0) { 
    list<Booking__c> bookings =  SOQLQueryHelper.getCancelBooking(accountId);
    List<Complementary_Credit__c> complimentaries = SOQLQueryHelper.getComplimentaryBooking(accountId); //11-10-2021 : nishi : To get complimentaries
    // 21-Nov-2019 : for add fifth lesson canceled bookings
    //list<Booking__c> listOfBookingFifthBookingPlaceholder =  SOQLQueryHelper.getBookingFifthBookingPlaceholder(accountId);
    //list<Fifth_Lesson__c> listOfFifthLesson =  SOQLQueryHelper.getCancelFifthLesson(accountId);
    WebServiceModelHelper.BookingResult BookingResultobj = new WebServiceModelHelper.BookingResult();
    // get all cancel bookings
    List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
    system.debug('@@@bookings '+bookings );
    if(bookings != null && bookings.size() >0){
        for(Booking__c bookingobj : bookings){
            if(bookingobj.Make_up_Expiry_Date__c !=null && bookingobj.Available_Make_up_Units__c!=null 
                && bookingobj.Available_Make_up_Units__c > 0)
                listOfBooking.add(addBookingvalue(bookingobj));
        }
    }
    // 21-Nov-2019 : for add fifth lesson canceled bookings
    /* if(listOfBookingFifthBookingPlaceholder != null && listOfBookingFifthBookingPlaceholder.size() >0 ){
    for(Booking__c bookingobj : listOfBookingFifthBookingPlaceholder){
    if(bookingobj.Make_up_Expiry_Date__c !=null && bookingobj.Available_Make_up_Units__c!=null && bookingobj.Available_Make_up_Units__c > 0)
    listOfBooking.add(addBookingvalue(bookingobj));
    } 
    } */
    //system.debug('@@@listOfBooking '+listOfBooking );
    // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with bookings records
    /* if(listOfFifthLesson != null && listOfFifthLesson.size() > 0){  
    for(Fifth_Lesson__c objFifthLesson: listOfFifthLesson ){
    listOfBooking.add(addFifthLessonRecords(objFifthLesson));
    }     
    } */
    //system.debug('@@@listOfBooking listOfFifthLesson '+listOfBooking );
    // Oct-09-2019 :Nishi :  END : for add Fifth booking lesson list with bookings records
    BookingResultobj.bookings = listOfBooking;    

    //Added by nishi : 11-10-2021 : To get complimentary bookings   : start    
    List<WebServiceModelHelper.Bookings> listOfComplimentary = New List<WebServiceModelHelper.Bookings>();
    system.debug('@@@complimentaries '+complimentaries);
    if(complimentaries != null && complimentaries.size() >0){
        for(Complementary_Credit__c objComp : complimentaries){
            if(objComp.Credit_Expiry_date__c !=null && objComp.Available_credit_Min__c != Null 
                && objComp.Available_credit_Min__c > 0)
                listOfComplimentary.add(addComplimentaryvalue(objComp));
        }
    }
    BookingResultobj.complimentaries = listOfComplimentary;
    //Added by nishi : 11-10-2021 : To get complimentary bookings   : end

    RestContext.response.statusCode = 200; 
    return JSON.Serialize(BookingResultobj).replaceAll('time_c','time').replaceAll('date_c','date');     
}else {
    RestContext.response.statusCode = 400; 
    return '{"errorCode":"DATA_NOT_FOUND","message":"Record Not Found"}';
}
}
// check  related invoice payment is paid or not 
public Static String fetchPayment(String InvoiceId){
    List<Invoice__c> invList = SOQLQueryHelper.getPaymentInvoice(InvoiceId);
    system.debug('@@invList '+invList );
    if(invList != null && invList.size() > 0){
        set<String> invListIds = MonthlyPaymentBatchHelper.getPaymentForInvoices(invList);
        system.debug('@@MonthlyPaymentBatchHelper.getPaymentForInvoices(invList)'+invListIds);
        if(invListIds != null && invListIds.size() > 0){
            RestContext.response.statusCode = 200; 
            return '{"errorCode": "SUCCESS","message":"Invoice paid successfully"}';
        }else{
            RestContext.response.statusCode = 400; 
            return '{"errorCode":"DATA_NOT_FOUND","message":"This Invoice is already Paid"}';
        } 
    }else{
        RestContext.response.statusCode = 400; 
        return '{"errorCode":"DATA_NOT_FOUND","message":"This Invoice is already Paid"}';
    }
}

// get all invoice 
public Static String fetchInvoice(String accountId){
    list<Account> accountList  = SOQLQueryHelper.getAccount(accountId);
    String response;
    if(accountList != null && accountList.size() > 0) { 
        list<Invoice__c> invoices=  SOQLQueryHelper.getInvoice(accountId);
        WebServiceModelHelper.InvoiceResult invoiceResultobj = new WebServiceModelHelper.InvoiceResult (); 
        if(Invoices!= null && Invoices.size() >0) {
            List<WebServiceModelHelper.invoice> listOfInvoices = New List<WebServiceModelHelper.invoice>();
            List<WebServiceModelHelper.payment> listOfPayments = New List<WebServiceModelHelper.payment>();
            // get all invoice with payment 
            for(Invoice__c invoice : invoices){
                listOfPayments = New List<WebServiceModelHelper.payment>();
                WebServiceModelHelper.invoice invoiceObj = new WebServiceModelHelper.invoice();
                invoiceObj.invoiceId = invoice.Id;
                invoiceObj.invoiceDate = invoice.Invoice_Date__c;
                invoiceObj.dueDate = invoice.Due_Date__c; 
                invoiceObj.balanceAmount = invoice.Total_Payable__c;
                invoiceObj.cardType = invoice.Card_Type__c;
                system.debug('@@invoice.Status__c '+invoice.Status__c );
                system.debug('@@invoice.Status__c '+invoice.Due_Date__c);
                
                if(!(invoice.Status__c.equalsIgnoreCase('Paid') || invoice.Status__c.equalsIgnoreCase('Cancelled') || invoice.Status__c.equalsIgnoreCase('Void')) && invoice.Due_Date__c < date.today()){
                    invoiceObj.status  = 'Overdue';// invoice.Status__c;
                }else{
                    invoiceObj.status  = invoice.Status__c;
                }
                system.debug('@@api invoice.Status__c ===> '+invoiceObj.status );
                invoiceObj.grossTotal = invoice.Gross_Total__c;
                invoiceObj.subTotal = invoice.Sub_Total__c;
                invoiceObj.gstTax = invoice.GST_Tax__c;
                invoiceObj.creditMemoAmount = invoice.Credit_Memo_Amount__c;
                invoiceObj.gstTaxAmount= invoice.GST_Tax_Amount__c;
                invoiceObj.discountAmount = invoice.Discount_Amount__c;
                invoiceObj.Deposit = invoice.Deposit__c;
                invoiceObj.invoiceNumber  = invoice.name;
                invoiceObj.totalAmount = invoice.Total_Amount__c;
                invoiceObj.cardNumber= invoice.Card_Number__c;
                invoiceObj.pdfDownloadUrl = Label.Mobile_API_URL+'apex/SubscriptionInvoicePdfClone?id=' + invoice.Id;
                invoiceObj.pdfUrl = Label.Mobile_API_URL+'apex/SubscriptionInvoiceHTML?id=' + invoice.Id;
                // add paymnet records 
                if(invoice.Payments__r != null && invoice.Payments__r.size() > 0){
                    for(payment__c payment: invoice.Payments__r){
                        WebServiceModelHelper.payment paymentObj = new WebServiceModelHelper.payment();
                        paymentObj.paymentDate =payment.Payment_Date__c;
                        paymentObj.amount  =payment.Payment_Amount__c;
                        paymentObj.method  =payment.Method_of_Payment__c ; 
                        listOfPayments.add(paymentObj);
                    }
                }
                invoiceObj.payments =listOfPayments; 
                listOfInvoices.add(invoiceObj);
            }
            invoiceResultobj.invoices=listOfInvoices ;
            RestContext.response.statusCode = 200;
            return JSON.Serialize(invoiceResultobj );
        }else{          
            RestContext.response.statusCode = 200; 
            invoiceResultobj .invoices= New List<WebServiceModelHelper.invoice>();
            return JSON.Serialize(invoiceResultobj );      
            
        }
    }else {
        RestContext.response.statusCode = 400;
        return '{"errorCode":"DATA_NOT_FOUND","message":"Record Not Found"}';
    }
}

//  get all Bookings according to enrollment id.
Public Static String getEnrollment( String enrollment,Integer recLimit,Integer recOffset,String type ){
    String response;
    WebServiceModelHelper.EnrollmentsResult enrollmentsResults = New WebServiceModelHelper.EnrollmentsResult();
    Map<Id, Enrolment__c > enrolments = SOQLQueryHelper.getEnrolments(enrollment);  
    // get Booking according to limit and offset and type
    list<Booking__c> bookings =  SOQLQueryHelper.getBookingUpcomingAndHistorical(enrollment,recLimit,recOffset,type);
    //21-NOv-2019 : get Fifthbooking placeholder Booking according to limit and offset and type
    list<Booking__c> bookingFifthBookingPlaceholder =  SOQLQueryHelper.getHistoricalBookingFifthBookingPlaceholder(enrollment,recLimit,recOffset,type);
    list<Fifth_Lesson__c> listOfFifthLesson =  SOQLQueryHelper.getFifthLessonUpcomingAndHistorical(enrollment,recLimit,recOffset,type);
    system.debug('@@@listOfFifthLesson  =='+listOfFifthLesson );
    List<Booking__c> listOfNewBooking = new List<Booking__c> ();
    List<Fifth_Lesson__c > listOfNewFifthLesson= new List<Fifth_Lesson__c > ();
    map<Id,List<Booking__c>> mapOfBooking = new map<Id,List<Booking__c>>();
    map<Id,List<Fifth_Lesson__c >> mapOfFifthLesson= new map<Id,List<Fifth_Lesson__c >>();
    // get all Booking 
    if(bookings != null && bookings.size() > 0){
        for(Booking__c booking :bookings){
            listOfNewBooking = new List<Booking__c> ();
            if(mapOfBooking.containsKey(booking.Enrolment__c)){
                listOfNewBooking = mapOfBooking.get(booking.Enrolment__c);
            }
            listOfNewBooking.add(booking);
            mapOfBooking.put(booking.Enrolment__c,listOfNewBooking);
        } 
    }
    //21-NOv-2019 : get Fifthbooking placeholder Booking according to limit and offset and type
    if(bookingFifthBookingPlaceholder != null && bookingFifthBookingPlaceholder.size () > 0){
        for(Booking__c booking :bookingFifthBookingPlaceholder){
            listOfNewBooking = new List<Booking__c> ();
            if(mapOfBooking.containsKey(booking.Enrolment__c)){
                listOfNewBooking = mapOfBooking.get(booking.Enrolment__c);
            }
            listOfNewBooking.add(booking);
            mapOfBooking.put(booking.Enrolment__c,listOfNewBooking);
        } 
    }
    system.debug('@@@listOfNewBooking=='+listOfNewBooking);
    system.debug('@@@mapOfBooking=='+mapOfBooking);
    // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with Enrollment records
    if(listOfFifthLesson  != null && listOfFifthLesson.size() > 0){
        system.debug('@@@listOfFifthLesson  =='+listOfFifthLesson );
        for(Fifth_Lesson__c objFifthLesson: listOfFifthLesson){
            listOfNewFifthLesson= new List<Fifth_Lesson__c > ();
            if(mapOfFifthLesson.containsKey(objFifthLesson.Enrolment__c)){
                listOfNewFifthLesson = mapOfFifthLesson.get(objFifthLesson.Enrolment__c);
            }
            listOfNewFifthLesson.add(objFifthLesson);
            mapOfFifthLesson.put(objFifthLesson.Enrolment__c,listOfNewFifthLesson);
        } 
    }
    system.debug('@@@listOfNewFifthLesson =='+listOfNewFifthLesson);
    system.debug('@@@mapOfFifthLesson=='+mapOfFifthLesson);
    
    // Oct-09-2019 :Nishi :  END: for add Fifth booking lesson list with Enrollment records
    // add all booking according to enrollment 
    if(enrolments != null && enrolments.size() >  0  ){                                    
        List<WebServiceModelHelper.Enrollments> listOfEnrollments = New List<WebServiceModelHelper.Enrollments>();
        for(Enrolment__c enrolment :enrolments.values()){
            WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
            objEnrollments.id = enrolment.id;
            objEnrollments.studentName = enrolment.Student__r.Name;
            objEnrollments.studentId= enrolment.Student__c;
            objEnrollments.instrument =enrolment.instrument__c;
            objEnrollments.duration = enrolment.Package__r.Duration__c == null ? '0 min' : enrolment.Package__r.Duration__c + ' min';
            objEnrollments.packageType = enrolment.Package__r.type__c;
            List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
            if(mapOfBooking !=null && mapOfBooking.size() >0 ){
                if(mapOfBooking.containsKey(enrolment.id)){
                    for(Booking__c booking : mapOfBooking.get(enrolment.id)){ 
                        listOfBooking.add(addBookingvalue(booking));
                    }    
                }
            }
            // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with bookings records
            if(mapOfFifthLesson != null && mapOfFifthLesson.size() >0){
                if(mapOfFifthLesson.containsKey(enrolment.id)){
                    for(Fifth_Lesson__c objFifthLesson: mapOfFifthLesson.get(enrolment.id)){ 
                        listOfBooking.add(addFifthLessonRecords(objFifthLesson));
                    }    
                }
            }
            system.debug('@@@listOfBooking addFifthLessonRecords'+listOfBooking);
            // Oct-09-2019 :Nishi :  END : for add Fifth booking lesson list with bookings records
            objEnrollments.bookings  = listOfBooking;
            listOfEnrollments.add(objEnrollments);
            /*if(enrolment.stage__c == 'Cancelled') {
if(listOfBooking.size() > 0) {
listOfEnrollments.add(objEnrollments);
}
} else { 
listOfEnrollments.add(objEnrollments);
}*/
        }
        enrollmentsResults.enrollments = listOfEnrollments;
        String enrolmentJsonResult = JSON.Serialize(enrollmentsResults).replaceAll('time_c','time').replaceAll('date_c','date');
        System.debug('enrolmentJsonResult '+enrolmentJsonResult );
        RestContext.response.statusCode = 200;
        return enrolmentJsonResult ;   
    }else{
        RestContext.response.statusCode = 200;
        enrollmentsResults.enrollments =  New List<WebServiceModelHelper.Enrollments>();
        String enrolmentJsonResult = JSON.Serialize(enrollmentsResults).replaceAll('time_c','time').replaceAll('date_c','date');
        return JSON.Serialize(enrolmentJsonResult ); 
        //return '{"errorCode":"DATA_NOT_FOUND","message":" Records Not Found"}';
    } 
    
}

//  get all lesson( enrollement and Booking ) according to parentId.
Public Static String getLesson( String parentId){
    List<Account> accountList  = SOQLQueryHelper.getAccount(parentId );
    map<String,WebServiceModelHelper.Enrollments> mapOfEnrollments = new Map<String,WebServiceModelHelper.Enrollments>();
    String response;
    if(accountList  != null && accountList .size() > 0 ) { 
        WebServiceModelHelper.EnrollmentsResult enrollmentsResults = New WebServiceModelHelper.EnrollmentsResult();
        List<Enrolment__c> listOfEnrolment =SOQLQueryHelper.getEnrolmentWithBooking(parentId); 
        List<Booking__c> listOfBookingFifthBookingPlaceholder = SOQLQueryHelper.getBookingFifthBookingPlaceholder(parentId);
        if( listOfEnrolment != null && listOfEnrolment.size() >  0){                                    
            List<WebServiceModelHelper.Enrollments> listOfEnrollments = New List<WebServiceModelHelper.Enrollments>();
            // get all enrollement with booking 
            System.debug('@@listOfEnrolment '+listOfEnrolment );
            for(Enrolment__c enrolment :listOfEnrolment){
                WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
                objEnrollments.id = enrolment.id;
                objEnrollments.studentName = enrolment.Student__r.Name;
                objEnrollments.studentId= enrolment.Student__c;
                objEnrollments.instrument =enrolment.instrument__c;
                objEnrollments.duration = enrolment.Package__r.Duration__c +' min';
                objEnrollments.packageType = enrolment.Package__r.type__c;
                List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
                System.debug('@@enrolment.Bookings__r'+enrolment.Bookings__r);
                if(enrolment.Bookings__r != null && enrolment.Bookings__r.size() > 0){
                    for(Booking__c booking : enrolment.Bookings__r){
                        listOfBooking.add(addBookingvalue(booking));
                    }
                }
                system.debug('@@@listOfBooking '+listOfBooking);
                // Oct-09-2019 :Nishi :  START : for add Fifth booking lesson list with bookings records
                if(enrolment.Fifth_Lessons__r!= null && enrolment.Fifth_Lessons__r.size() > 0){  
                    for(Fifth_Lesson__c objFifthLesson: enrolment.Fifth_Lessons__r){
                        listOfBooking.add(addFifthLessonRecords(objFifthLesson));
                    }     
                }
                system.debug('@@@listOfBooking '+listOfBooking);
                // Oct-09-2019 :Nishi :  END : for add Fifth booking lesson list with bookings records
                objEnrollments.bookings  = listOfBooking;
                listOfEnrollments.add(objEnrollments); 
                system.debug('@@@objEnrollments'+objEnrollments);
                mapOfEnrollments.put( enrolment.id,objEnrollments); 
            }
            // add fifth lesson canceled booking 
            if(listOfBookingFifthBookingPlaceholder != null && listOfBookingFifthBookingPlaceholder.size() > 0){
                List<WebServiceModelHelper.Bookings> listOfBooking = New List<WebServiceModelHelper.Bookings>();
                WebServiceModelHelper.Enrollments objEnrollments = New WebServiceModelHelper.Enrollments();
                for(Booking__c booking : listOfBookingFifthBookingPlaceholder ){
                    if(string.isnotBlank(booking.Enrolment__c)){
                        if(mapOfEnrollments.containsKey(booking.Enrolment__c)){
                            listOfBooking = mapOfEnrollments.get(booking.Enrolment__c).bookings;
                            objEnrollments =  mapOfEnrollments.get(booking.Enrolment__c);
                            listOfBooking.add(addBookingvalue(booking ));
                            objEnrollments.bookings  = listOfBooking;
                            mapOfEnrollments.put(booking.Enrolment__c ,objEnrollments); 
                        }  
                    }
                }   
            }
            enrollmentsResults.enrollments =mapOfEnrollments.values() ;
            String enrolmentJsonResult = JSON.Serialize(enrollmentsResults).replaceAll('time_c','time').replaceAll('date_c','date');
            System.debug('enrolmentJsonResult '+enrolmentJsonResult );
            RestContext.response.statusCode = 200;
            return enrolmentJsonResult ;   
        }else{
            enrollmentsResults.enrollments = New List<WebServiceModelHelper.Enrollments>();
            String enrolmentJsonResult = JSON.Serialize(enrollmentsResults).replaceAll('time_c','time').replaceAll('date_c','date');
            System.debug('enrolmentJsonResult '+enrolmentJsonResult );
            RestContext.response.statusCode = 200;
            return enrolmentJsonResult ;    
        } 
    }else { 
        return '{"errorCode":"DATA_NOT_FOUND","message":"Record Not Found"}';
    }
}

// get Case Upcoming And Historical List according to parent account
public static string getCaseData(string parentId,String type,Integer recLimit,Integer recOffset) {
    List<Account> accountlist =  SOQLQueryHelper.getAccount(parentId);
    system.debug('parentId'+parentId);
    system.debug('@@accountlist '+accountlist );
    if(accountlist!= null && accountlist.size() > 0){
        List<WebServiceModelHelper.Cases> listOfCases = new List<WebServiceModelHelper.Cases>();
        List<Case> CaseList =  SOQLQueryHelper.getCaseUpcomingAndHistoricalList(parentId,type,recLimit,recOffset);
        WebServiceModelHelper.CasesResult casesResult = new WebServiceModelHelper.CasesResult(); 
        If(CaseList!= null && CaseList.size() > 0 ){
            For(Case caseObj : CaseList ){
                List<WebServiceModelHelper.CaseComment> listOfCaseComments =  New List<WebServiceModelHelper.CaseComment>();
                WebServiceModelHelper.Cases cases = new WebServiceModelHelper.Cases();
                cases.caseId = caseObj.Id;
                cases.subject= caseObj.Subject;
                cases.Description= caseObj.Description;
                cases.studentId = caseObj.Student_Name__c;
                cases.studentName = caseObj.Student_Name__r.name;
                cases.type  = caseObj.Type ; 
                cases.parentId = caseObj.AccountId;
                cases.status= caseObj.status;
                cases.caseNumber= caseObj.caseNumber;
                cases.Createddate= caseObj.Createddate;
                // add CaseComment with created date
                if(caseObj.CaseComments != null && caseObj.CaseComments.size() > 0){
                    for(CaseComment caseCommentobj: caseObj.CaseComments){
                        WebServiceModelHelper.CaseComment caseComment = new WebServiceModelHelper.CaseComment();
                        caseComment.commentId = caseCommentobj.Id;
                        caseComment.caseId = caseCommentobj.ParentId ;
                        caseComment.commentDate = caseCommentobj.CreatedDate;
                        caseComment.owner= caseCommentobj.CreatedBy.Name == 'aureusacademy Site Guest User' ? 'You' : caseCommentobj.CreatedBy.Name;
                        caseComment.comment = caseCommentobj.CommentBody;
                        listOfCaseComments.add(caseComment);
                        
                    }
                }
                cases.caseComments = listOfCaseComments;
                listOfCases.add(cases);
            } 
            casesResult.cases = listOfCases;
            RestContext.response.statusCode = 200;
            return JSON.Serialize(casesResult);
        }else{ 
            RestContext.response.statusCode = 200;
            casesResult.cases = new List<WebServiceModelHelper.Cases>();
            return JSON.Serialize(casesResult);
            // return '{"errorCode":"DATA_NOT_FOUND","message":"Case Records Not Found"}';
        }
    }else {
        RestContext.response.statusCode = 400;
        return '{"errorCode":"DATA_NOT_FOUND","message":"Account Record Not Found"}';
    }
    
}

// Create Case Comment record 
public Static String createCaseComment(String caseId, String comment){
    try{
        CaseComment caseCommentObj = new CaseComment (
            ParentId = String.isNotBlank(caseId)?caseId :Null, CommentBody = String.isNotBlank(comment)?comment:'');
        Insert caseCommentObj;
        RestContext.response.statusCode = 200;
        return '{"errorCode": "SUCCESS","message":"Record save sucessfully."}';
    }catch(exception e){
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + e +'"}';
    }
}


// update Reschedule Booking records 
public Static String insertBookingReschedule(String bookingId, String teacherId,String oldteacherId, Time newTime,Date newDate, Time oldtime,Date olddate, Integer Duration, String lessonTypeNew){
    WebServiceModelHelper.mobileAppError mobileAppCode = WebServiceDataFactoryBookingHelper.createNewBookingReschedule(bookingId, teacherId, oldteacherId, newTime,newDate, oldtime, olddate, Duration, lessonTypeNew);                                 
    if(mobileAppCode.errorCode == 'SUCCESS'){  
        //string returnvalue =createNewBookingReschedule(bookingId, teacherId, oldteacherId, newTime,newDate, oldtime, olddate, Duration);
        list<Booking__c> listOfBooking =SOQLQueryHelper.getListOfBookingWithId(bookingId);
        string errormessage =insertApp_Feeds(listOfBooking , 'Reschedule');
        if(string.isNotBlank(errormessage)){
            RestContext.response.statusCode = 500;
            return '{"errorCode":"INTERNAL_ERROR","message":"' + errormessage + '"}';
        }
        RestContext.response.statusCode = 200;
        system.debug('##mobileAppCode'+JSON.Serialize(mobileAppCode));
        return  JSON.Serialize(mobileAppCode); 
    }else{
        if(mobileAppCode.errorCode == 'INTERNAL_ERROR'){ 
            RestContext.response.statusCode = 500;
        }else{
            RestContext.response.statusCode = 400;
        } 
        return  JSON.Serialize(mobileAppCode); 
    }                                              
}


private Static string insertApp_Feeds(List<Booking__c> listOfBooking,string bookingType){
    system.debug('@@ insertApp_Feeds listOfBooking'+listOfBooking);
    system.debug('@@ insertApp_Feeds bookingType'+bookingType);
    List<App_Feeds__c> listOfApp_Feeds = new  List<App_Feeds__c>();
    for(Booking__c objBooking: listOfBooking){
        listOfApp_Feeds.add(new App_Feeds__c(Parent__c =objBooking.Parent__c,
                                                Student__c = objBooking.Student__c,
                                                Teacher__c =objBooking.Teacher_Account__c, 
                                                Type__c = bookingType,
                                                Instrument__c = bookingType == 'Make-up' ? 'Make-up' : objBooking.Instrument__c, 
                                                Center__c = objBooking.Center__c,
                                                Booking_Id__c = objBooking.id, 
                                                Booking_Date__c = objBooking.Booking_Date__c, 
                                                Location__c = objBooking.Center__r.Location__c, 
                                                Booking_Time__c = objBooking.Start_Time__c));
    }
    Database.SaveResult[] saveApp_Feeds = Database.insert(listOfApp_Feeds, false);
    system.debug('@@@saveplaceholder '+saveApp_Feeds );
    for(Database.SaveResult sr : saveApp_Feeds){
        if (!sr.isSuccess()) {
            system.debug('saveResult.getErrors()'+sr.getErrors());
            return 'App Feeds Records Not Inserted';
        }
    }
    return null ;
    
}
// update Bookings if Booking is cancel  
public Static String updateBooking(String bookingIds, String cancellationReason,String makeUpReason, String makeupRemark){
    system.debug('@@@cancellationReason'+cancellationReason);
    Savepoint sp = Database.setSavepoint();  
    System.debug('save point = '+sp);
    try{
        list<Booking__c> listOfBooking =SOQLQueryHelper.getListOfBookingWithId(bookingIds);
        list<Fifth_Lesson__c> listOfFifthLesson =  SOQLQueryHelper.getListOfFifthLessonWithId(bookingIds);
        system.debug('@@listOfFifthLesson '+listOfFifthLesson );
        system.debug('@@@listOfBooking'+listOfBooking);
        if((listOfBooking!= null && listOfBooking.size() > 0 ) || (listOfFifthLesson != Null && listOfFifthLesson.size() > 0) ){ 
            system.debug('@@listOfFifthLesson '+listOfFifthLesson );
            system.debug('@@@listOfBooking'+listOfBooking);
            if(listOfBooking!= null && listOfBooking.size() > 0 ){ 
                WebServiceModelHelper.mobileAppError mobileAppCode = WebServiceDataFactoryBookingHelper.updateCancelBooking(bookingIds, cancellationReason, makeUpReason, makeupRemark); 
                                                                                                                                    
                System.debug('#mobileAppCode'+mobileAppCode);                                                                                                                                       
                if(mobileAppCode.errorCode == 'SUCCESS'){  
                    // insert App_Feeds__c records 
                    string errormessage =insertApp_Feeds(listOfBooking , 'Cancel');
                    System.debug('errormessage =insertApp_Feeds(listOfBooking , Cancel) = '+errormessage);
                    if(string.isNotBlank(errormessage)){
                        RestContext.response.statusCode = 500;
                        return '{"errorCode":"INTERNAL_ERROR","message":"' + errormessage + '"}';
                    }
                }else{
                    if(mobileAppCode.errorCode == 'INTERNAL_ERROR'){ 
                        RestContext.response.statusCode = 500;
                    }else{
                        RestContext.response.statusCode = 400;
                    } 
                    return  JSON.Serialize(mobileAppCode); 
                }
            }
            // Oct-09-2019 :Nishi :  Start : for update FifthBooking records
            if(listOfFifthLesson != Null && listOfFifthLesson.size() > 0){
                system.debug('@@listOfFifthLesson--- '+listOfFifthLesson );
                //return createFifthbookingRecords(listOfFifthLesson[0].Id ,'placeholder','5th Lesson - CX');
                WebServiceModelHelper.mobileAppError mobileAppCode = createFifthbookingRecords(listOfFifthLesson[0].id ,'placeholder','5th Lesson - CX'); 
                system.debug('@@@mobileAppCode '+mobileAppCode );
                if(mobileAppCode.errorCode == 'SUCCESS'){
                    RestContext.response.statusCode = 200;
                }else{
                    if(mobileAppCode.errorCode == 'INTERNAL_ERROR'){ 
                        RestContext.response.statusCode = 500;
                    }else{
                        RestContext.response.statusCode = 400;
                    } 
                    return  JSON.Serialize(mobileAppCode); 
                }
            }
            // Oct-09-2019 :Nishi :  End: for get FifthBooking records
            RestContext.response.statusCode = 200;
            return '{"errorCode":"SUCCESS","message":"Booking Cancelled Successfully"}';
        }else{
            RestContext.response.statusCode = 400;
            return '{"errorCode":"DATA_NOT_FOUND","message":"Booking Records Not Found"}';
        }
        
    }catch(Exception e){
        system.debug('@@@e.getMessage()'+e.getMessage());
        Database.rollback(sp);
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + e.getMessage()+'"}';
    }
}

//@Nishi : 10Oct :Created AdHoc Booking
public Static String updateAdHocBooking(String fifthBookingId){
    // Savepoint sp = Database.setSavepoint();  
    try{
        list<Fifth_Lesson__c> listOfFifthLesson =  SOQLQueryHelper.getListOfFifthLessonWithId(fifthBookingId);
        // Oct-10-2019 :Nishi :  Start : for update FifthBooking records
        if(listOfFifthLesson != Null && listOfFifthLesson.size() > 0){
            system.debug('@@listOfFifthLesson '+listOfFifthLesson );
            //return createFifthbookingRecords(listOfFifthLesson[0].id ,'adhoc','5th Lesson - AH');
            WebServiceModelHelper.mobileAppError mobileAppCode = createFifthbookingRecords(listOfFifthLesson[0].id ,'adhoc','5th Lesson - AH'); 
            system.debug('@@@mobileAppCode '+mobileAppCode );
            if(mobileAppCode.errorCode == 'SUCCESS'){
                RestContext.response.statusCode = 200;
                return '{"errorCode":"SUCCESS","message":"Ad-Hoc Booking is created Successfully"}'; 
            }else{
                if(mobileAppCode.errorCode == 'INTERNAL_ERROR'){ 
                    RestContext.response.statusCode = 500;
                }else{
                    RestContext.response.statusCode = 400;
                } 
                return  JSON.Serialize(mobileAppCode); 
            }
            
        }else{
            RestContext.response.statusCode = 400;
            return '{"errorCode":"DATA_NOT_FOUND","message":"Card details not found. Please contact the Centre Staff."}';
        }
    }catch(Exception e){
        system.debug('@@@e.getMessage()'+e.getMessage());
        //Database.rollback(sp);
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + e.getMessage()+'"}';
    }
}

// nishi: 10-oct-2019: update Fifth booking and create booking and app_feed records 

public static WebServiceModelHelper.mobileAppError  createFifthBookingRecords(string fifthBookingId,string bookingType,string lessonType ){
    string isLessonIdExist;
    // 25-Oct-2019 : for If Booking type makeup or adhoc then send true 
    if(bookingType == 'placeholder'){
        isLessonIdExist = FifthLessonController.bookingConvert(fifthBookingId,'',bookingType,false);
    }else if(bookingType == 'makeup'){
        isLessonIdExist = FifthLessonController.bookingConvert(fifthBookingId,'',bookingType,true);
    }else if(bookingType == 'adhoc'){
        isLessonIdExist = FifthLessonController.bookingConvert(fifthBookingId,'',bookingType,true);
    }
    // string isLessonIdExist = FifthLessonController.bookingConvert(fifthBookingId,'',bookingType);
    WebServiceModelHelper.mobileAppError mobileAppCode = new WebServiceModelHelper.mobileAppError();
    system.debug('@@@isLessonIdExist'+isLessonIdExist);
    if(String.isNotBlank(isLessonIdExist)){
        list<Fifth_Lesson__c> listOfFifthLesson =  SOQLQueryHelper.getListOfFifthLessonWithUpdatedId(fifthBookingId);
        system.debug('@@@listOfFifthLesson '+listOfFifthLesson );
        if(listOfFifthLesson != null && listOfFifthLesson.size() >0){
            system.debug('@@@listOfFifthLesson[0].Booking__c '+listOfFifthLesson[0].Booking__c );
            if(string.isNotBlank(listOfFifthLesson[0].Booking__c)){
                list<booking__c> listOfBooking =SOQLQueryHelper.getListOfBookingWithId(listOfFifthLesson[0].Booking__c);
                system.debug('@@@listOfBooking '+listOfBooking );
                if(string.isNotBlank(insertApp_Feeds(listOfBooking, lessonType ))){
                    mobileAppCode.errorCode = 'INTERNAL_ERROR';
                    mobileAppCode.message = 'App Feeds Record Not Inserted.';
                }else{
                    mobileAppCode.errorCode = 'SUCCESS';
                    mobileAppCode.message = 'App Feeds are Inserted.';
                }
            }else{
                mobileAppCode.errorCode = 'INTERNAL_ERROR';
                mobileAppCode.message = 'Booking Record Not Inserted.';
            }
        }else{
            mobileAppCode.errorCode = 'DATA_NOT_FOUND';
            mobileAppCode.message = 'Booking Record Not found.';
        }
    }else{
        mobileAppCode.errorCode = 'INTERNAL_ERROR';
        mobileAppCode.message = bookingType == 'adhoc' ? 'Card details not found. Please contact the Centre Staff. ' : 'Booking Record Not Updated.';
    }
    return mobileAppCode;
}

//@SUNNY Created Attachment for parent id with image base code
public Static String createAttachment(String parentId, String base64Data){
    system.debug('@@@parentId--'+parentId);
    system.debug('@@@base64Data--'+base64Data);
    List<Account> accountList  = SOQLQueryHelper.getAccount(parentId);   
    system.debug('@@@accountList--'+accountList);
    if(accountList  != null && accountList.size() > 0 ){
        try{
            List<ContentDocumentLink> files = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:parentId];
            system.debug('@@@files--'+files);
            set<String >setOfContentIds = new Set<String>();
            for(ContentDocumentLink contDocLink : files){
                setOfContentIds.add(contDocLink.ContentDocumentId);
                system.debug('@@@setOfContentIdsLoop--'+setOfContentIds);
            }
            system.debug('@@@setOfContentIds--'+setOfContentIds);
            if(setOfContentIds != null){ 
                delete [Select Id, Title, FileExtension, CreatedDate From ContentDocument USING SCOPE Team  WHERE id in: setOfContentIds];            
            }  
            //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.Title = 'profilePicture.jpg';
            cv.ContentDocumentId = null;
            cv.PathOnClient = 'profilePicture.jpg';
            insert cv;  
            system.debug('@@@cv--'+cv.id);
            system.debug('@@@filesafterInsert--'+files);
            if(!files.isEmpty()) {                                                          
                List<ContentDistribution> conDisList = [select ContentDocumentId, ContentVersionId, DistributionPublicUrl from ContentDistribution where ContentDocumentId =:files[0].ContentDocumentId];
                system.debug('@@@conDisList--'+conDisList);
                if(!conDisList.isEmpty()){
                    delete conDisList;   
                }
                system.debug('@@@deletefiles--'+files);
                // delete files ;   
            }
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = SOQLQueryHelper.getContentVersion(cv.id)[0].ContentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V';
            upsert cdl;
            system.debug('@@'+cdl);
            ContentDistribution newDistribution = new ContentDistribution(ContentVersionId  = cv.Id, 
                                                                            Name='External Link',
                                                                            PreferencesNotifyOnVisit = false);
            upsert newDistribution;
            system.debug('@@'+[SELECT Id, ContentDownloadUrl, ContentDocumentId 
                                FROM ContentDistribution 
                                where Id=:newDistribution.id].ContentDownloadUrl);
            Account acc = new Account(Profile_Pic_URL__c =   SOQLQueryHelper.getContentLink(newDistribution.id,cdl.id),
                                        Id= parentId);
            
            update acc;
            system.debug(acc);
            RestContext.response.statusCode = 200;
            return '{"errorCode":"SUCCESS","message":"Profile Picture uploaded successfully"}';
        }catch(exception e){
            RestContext.response.statusCode = 500;
            return '{"errorCode":"INTERNAL_ERROR","message":"' + e +'"}';
        }
    }else{
        RestContext.response.statusCode = 400;
        return  '{"errorCode":"DATA_NOT_FOUND","message":"Some error was found"}';
    }   
}
// Create case Record accroding to give api body 
public Static String createCase(String parentId,String studentId, String requestType,String subject,String details,
                                String invoiceId, String bookingId, String enrolmentId){
                                    try{
                                        string centerId = null;
                                        string location = null;
                                        // get Student id then add center id and location 
                                        if(String.isNotBlank(studentId)){
                                            List<Enrolment__c> listofEnrolment = SOQLQueryHelper.getCenterId(studentId);
                                            if(string.IsNotBlank(studentId)){
                                                if(listofEnrolment != null && listofEnrolment.size() > 0){
                                                    centerId= listofEnrolment[0].Center__c;
                                                    location = listofEnrolment[0].Center__r.location__c;
                                                }
                                            }
                                        }
                                        // get center id then add centerName and location 
                                        if(String.isBlank(centerId) && String.isNotBlank(parentId)) {
                                            List<Account> parentAccountList = SOQLQueryHelper.getAccount(parentId);
                                            if(parentAccountList != null && parentAccountList.size() >0 ){
                                                centerId= parentAccountList[0].Centre_Name__c;
                                                location = parentAccountList[0].Location__c;
                                            }
                                        }
                                        
                                        //Fetching the assignment rules on case
                                        AssignmentRule AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
                                        Case caseObj = new Case(
                                            Status = 'New',
                                            AccountId = (string.IsNotBlank(parentId)? parentId: null),
                                            Student_Name__c = (string.IsNotBlank(studentId)? studentId : null),
                                            Centre_Name__c = (string.IsNotBlank(centerId)? centerId: null),
                                            Type = requestType,
                                            recordTypeId =Schema.SObjectType.case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId(),
                                            Subject = subject,
                                            Enrolment__c = (string.IsNotBlank(enrolmentId)? enrolmentId: null),
                                            Location__c =  (string.IsNotBlank(location)? location: null),
                                            Description = details,
                                            Invoice__c = (string.IsNotBlank(invoiceId)? invoiceId: null),
                                            Booking__c = (string.IsNotBlank(bookingId)? bookingId : null),
                                            Origin = 'App');
                                        List<Case> insCaseList = new List<Case>{caseObj };
                                            if(insCaseList!= null && insCaseList.size() > 0){
                                                //Creating the DMLOptions for "Assign using active assignment rules" checkbox
                                                Database.DMLOptions dmo = new Database.DMLOptions();
                                                //dmo.assignmentRuleHeader.useDefaultRule = true;
                                                dmo.assignmentRuleHeader.assignmentRuleId=AR.id;
                                                Database.insert(insCaseList, dmo);
                                            }
                                        //Insert caseObj;
                                        RestContext.response.statusCode = 200;
                                        String message = 'Your request has been submitted! Please note it may take up to 2 minutes for your ticket to appear under new tickets';
                                        if(requestType == 'Refer a Friend') {
                                            string refferalName;
                                            if(string.isNotBlank(details)){
                                                refferalName= details.substring(details.indexOf(': ')+1,details.indexOf('Last Name:')-1);
                                            }
                                            message = 'Thank you for referring '+refferalName+' to Aureus Academy!';
                                        }else if(requestType.equalsIgnoreCase('Update Personal Details')){
                                            message = 'You request to change your details has been submitted successfully. We will review your request and get back to you as soon as possible!';
                                        }else if(requestType.equalsIgnoreCase('Update Student Details')){
                                            message = 'You request to change student details has been submitted successfully. We will review your request and get back to you as soon as possible!'; 
                                        }else if(subject.equalsIgnoreCase('Change Enrolment')){
                                            message = 'Your '+requestType+' request has been submitted! Please note it may take up to 2 minutes for your ticket to appear under new tickets.'; 
                                        }else if(subject.equalsIgnoreCase('Lesson Request')){
                                            message = 'You request has been submitted successfully.'; 
                                        }
                                        return '{"errorCode":"SUCCESS","message":"'+message+'"}';
                                    }catch(exception e){
                                        RestContext.response.statusCode = 500;
                                        return '{"errorCode":"INTERNAL_ERROR","message":"' + e +'"}';
                                    }
                                }
// get picklist according to object name and field name
public static String getPickListValues(String objName, String fieldName){
    List<WebServiceModelHelper.PickListOption> listOptions = new List<WebServiceModelHelper.PickListOption>();
    String response = validateObjectNameAndFieldName(objName, fieldName);
    // check response give error or not 
    if(String.isNotBlank(response)){
        RestContext.response.statusCode = 400;
        return response;
    }
    else{
        list<Schema.PicklistEntry> currentPicklist =  getPicklist(objName,fieldName);
        list<String> picklistValues =  new list<String>();
        List<String> optionToExclude = new List<String>();
        if( fieldName == 'Location__c') {
            optionToExclude = new List<String>{'XXXX','Aureus @ Home'};
                } else if(fieldName == 'Major_Instruments_Disciplines__c') {
                    optionToExclude = new List<String>{'Voice','Piano Rental','Piano Sales'};
                        } else if( fieldName == 'Cancellation_Reason__c') {
                            optionToExclude = new List<String>{'Teacher MC','Teacher Holiday'};
                                }
        for(Schema.PicklistEntry currentEntry : currentPicklist){
            //WebServiceModelHelper.PickListOption pLO = New WebServiceModelHelper.PickListOption();
            //pLO.apiName = currentEntry.getValue();
            //pLO.label = currentEntry.getLabel();
            //listOptions.add(pLO);
            if(!optionToExclude.contains(currentEntry.getLabel()))
                picklistValues.add(currentEntry.getLabel());
        }
        
        if(fieldName == 'School__c'){
            for(School__c school : [SELECT name from School__c]) {
                picklistValues.add(school.Name);
            }
        }
        picklistValues.sort();
        for(String value : picklistValues){
            WebServiceModelHelper.PickListOption pLO = New WebServiceModelHelper.PickListOption();
            pLO.apiName = value ;
            pLO.label = value ;
            listOptions.add(pLO);
        }
        RestContext.response.statusCode = 200;
        return  JSON.Serialize(listOptions);
    }
}

// get picklist value accroding to object and fieldname
private static List<Schema.PicklistEntry>  getPicklist(String objName, String fieldName){
    Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{objName});
    Schema.DescribeFieldResult dfrList = results[0].fields.getMap().get(fieldName).getDescribe();
    String type = String.valueOf(dfrList.getType());
    if(type.equalsIgnoreCase('PICKLIST') || type.equalsIgnoreCase('MULTIPICKLIST')){
        return dfrList.getPicklistValues();
    }
    return new list<Schema.PicklistEntry>();
    
}
// validate object or field is exist or not
private static String validateObjectNameAndFieldName(String objName, String fieldName){
    String error = '';
    Map<String, Schema.SObjectType> objResultMap = Schema.getGlobalDescribe();
    if(!objResultMap.containsKey(objName)){
        error += '{"errorCode": "INCORRECT_API","message":"Please Insert Correct Object API Name!"}';
    }
    if(String.isBlank(error)){
        Map<String, Schema.SObjectField> fieldDetails = objResultMap.get(objName).getDescribe().fields.getMap();
        if(!fieldDetails.containsKey(fieldName)){
            error += '{"errorCode":"INCORRECT_API", "message":"Please Correct the Object Field API Name!"}';
            system.debug('!!error '+error );
        }
    }    
    return error ;
}

// get All Teacher list according to booking instrument
public Static String getAllRelatedTeacher(String bookingId){
    List<Booking__c> listOfBooking = SOQLQueryHelper.getBookingInstruments(bookingId); 
    if(listOfBooking  != null && listOfBooking .size() >  0 ){
        List<WebServiceModelHelper.instrument> ListOfInstrument = New List<WebServiceModelHelper.instrument>();
        // get account teacher records accroding to booking instrument 
        for(Account accountObj : SOQLQueryHelper.getAccountInstrumentsWithTeacher(New Set<String>{listOfBooking[0].Instrument__c}, listOfBooking[0].Center__c)){
            WebServiceModelHelper.instrument objInstrument = new WebServiceModelHelper.instrument();
            objInstrument.teachername = accountObj.Name;
            objInstrument.teacherId = accountObj.Id;
            ListOfInstrument.add(objInstrument);
        } 
        RestContext.response.statusCode = 200;
        return JSON.Serialize(ListOfInstrument);
    }else{
        RestContext.response.statusCode = 400;
        return  '{"errorCode":"DATA_NOT_FOUND","message":"Some error was found"}';
    }
}

// get package according to program and location
public static String getPackages(String program,String location){
    list<Package__c> listOfPackage =  SOQLQueryHelper.getListOfPackage(program,location); 
    WebServiceModelHelper.MakeupPackageSelection objMakeupPackageSelection = new WebServiceModelHelper.MakeupPackageSelection();
    List<WebServiceModelHelper.packages> listOfpackages = New List<WebServiceModelHelper.packages>(); 
    if(listOfPackage != null && listOfPackage.size() >0 ){
        for(Package__c objPackage : listOfPackage ){
            WebServiceModelHelper.packages packageobj = New WebServiceModelHelper.packages();
            packageobj.packageId = objPackage.Id;
            packageobj.packageName = objPackage.Name;
            packageobj.duration = Integer.valueOf(objPackage.duration__c);  
            listOfpackages.add(packageobj);    
        }
    }
    RestContext.response.statusCode = 200;
    return JSON.Serialize(listOfpackages);
}

// get Package makeup accroding to center Id
public Static String getMakeupPackageSelection(String centerId){
    // get Package list
    WebServiceModelHelper.MakeupPackageSelection objMakeupPackageSelection = new WebServiceModelHelper.MakeupPackageSelection();
    list<Package__c> listOfPackage =  SOQLQueryHelper.getListOfPackage(centerId);  
    List<WebServiceModelHelper.packages> listOfpackages = New List<WebServiceModelHelper.packages>(); 
    // add package List with duration
    if(listOfPackage != null && listOfPackage.size() >0){
        for(Package__c objPackage : listOfPackage ){
            WebServiceModelHelper.packages packageobj = New WebServiceModelHelper.packages();
            packageobj.packageId = objPackage.Id;
            packageobj.packageName = objPackage.Name;
            packageobj.duration = Integer.valueOf(objPackage.duration__c);  
            listOfpackages.add(packageobj);    
        }
        objMakeupPackageSelection.packages = listOfpackages;
    }
    // get  Account Instruments if record Type is 'Teacher'
    Map<String,List<WebServiceModelHelper.instrument>> mapOfInstrumentsWithTeacher = New Map<String,List<WebServiceModelHelper.instrument>>();
    List<Schema.PicklistEntry> currentPicklist =  getPicklist('Account', 'Major_Instruments_Disciplines__c');
    if(currentPicklist != null&& currentPicklist.size() > 0){
        // add all instrument list with 
        for(Schema.PicklistEntry currentEntry : currentPicklist){
            mapOfInstrumentsWithTeacher.put(currentEntry.getValue(),new List<WebServiceModelHelper.instrument>());
        }
        //get account according to instrument list 
        for(Account accountObj : SOQLQueryHelper.getAccountInstrumentsWithTeacher(mapOfInstrumentsWithTeacher.keySet())){
            for(String instrument:accountObj.Major_Instruments_Disciplines__c.split(';')){
                List<WebServiceModelHelper.instrument> ListOfInstrument = New List<WebServiceModelHelper.instrument>();
                If(mapOfInstrumentsWithTeacher.containsKey(instrument)){
                    ListOfInstrument  = mapOfInstrumentsWithTeacher.get(instrument);
                }
                WebServiceModelHelper.instrument objInstrument = new WebServiceModelHelper.instrument();
                objInstrument.teachername = accountObj.Id;
                objInstrument.teacherId = accountObj.Name;
                ListOfInstrument.add(objInstrument);
                System.debug(accountObj);
                mapOfInstrumentsWithTeacher.put(instrument,ListOfInstrument);
            }
        }
        objMakeupPackageSelection.instrumentsWithTeacher = mapOfInstrumentsWithTeacher;
        RestContext.response.statusCode = 200;
        return JSON.Serialize(objMakeupPackageSelection);
    }else{
        RestContext.response.statusCode = 400;
        return  '{"errorCode":"DATA_NOT_FOUND","message":"Some error was found"}';
    }
}

// add booking model class value according to given booking record
private static WebServiceModelHelper.Bookings addBookingvalue(booking__c booking){
    WebServiceModelHelper.Bookings bookingObj = New WebServiceModelHelper.Bookings();
    bookingObj.bookingId = booking.id;
    bookingObj.studentName= booking.Student__r.Name;
    bookingObj.studentId= booking.Student__c;
    bookingObj.date_c= booking.Booking_Date__c ;
    bookingObj.weekday= booking.Appointment_Day__c;
    bookingObj.packageName= booking.Package__r.Name;
    bookingObj.packageType= booking.Package__r.type__c;
    bookingObj.time_c= booking.start_time__c ;
    bookingObj.instrument= (booking.type__c =='Make-up'?'Make-up':(booking.type__c =='Ad-hoc'?'Ad-hoc':booking.instrument__c ) );
    bookingObj.center= booking.Center__r.Name;
    bookingObj.teacherName= booking.Teacher_Account__r.Name;
    bookingObj.teacherId= booking.Teacher_Account__c;
    bookingObj.centerId= booking.Center__c;
    bookingObj.enrollmentId = booking.Enrolment__c;
    bookingObj.status = (booking.Status__c == 'Pending'?'Scheduled': 
                            (booking.Type__c =='Busy' ? 'Canceled': booking.Status__c));
    bookingObj.rescheduled =booking.Is_Reschedule_Booking__c;
    bookingObj.duration =  String.valueOf(booking.Duration__c) + ' min';
    bookingObj.type=booking.Type__c ;///(booking.Type__c =='Busy' ? 'Regular': booking.Type__c);
    bookingObj.cancellationReason =booking.Cancellation_Reason__c;
    bookingObj.lessonTypeNew =booking.Lesson_Type__c;
    bookingObj.lessonPasscode = booking.Online_Lesson_Passcode__c;
    bookingObj.lessonOnlineURL = booking.Online_Lesson_URL__c;
    bookingObj.expiryDate=booking.Make_up_Expiry_Date__c;
    bookingObj.isFifthBooking = false;
    bookingObj.availableMakeupMin =String.isNotBlank(String.valueOf(booking.Available_Make_up_Units__c)) ?
        booking.Available_Make_up_Units__c +' min':
    booking.Available_Make_up_Units__c +'' ;
    /*Added By : Nishi : 04-10-2021 : To get complimentry minutes : start
    
        bookingObj.availableComplimentryMin = (String.isNotBlank(booking.Parent__c)&&
            String.isNotBlank(String.valueOf(booking.Parent__r.Available_Complementary_Credit_mins__c))) ?
        booking.Parent__r.Available_Complementary_Credit_mins__c +' min':
        booking.Parent__r.Available_Complementary_Credit_mins__c +'' ;
            bookingObj.isComplimentry =booking.Is_Complimentary_Credit__c;   
    //Added By : Nishi : 04-10-2021 : To get complimentry minutes : end */
    
    return bookingObj;
}

//Added by nishi : 11-10-2021 
// add booking model class value according to given complimentry record
private static WebServiceModelHelper.Bookings addComplimentaryvalue(Complementary_Credit__c objComplimentary){
    WebServiceModelHelper.Bookings complimentaryObj = New WebServiceModelHelper.Bookings();
    complimentaryObj.bookingId = objComplimentary.id;
    complimentaryObj.studentName = (String.isnotBlank(objComplimentary.enrolment__c) && String.isnotBlank(objComplimentary.enrolment__r.Student__c)) ? 
                                objComplimentary.enrolment__r.Student__r.Name : Null;
    complimentaryObj.studentId = (String.isnotBlank(objComplimentary.enrolment__c) && String.isnotBlank(objComplimentary.enrolment__r.Student__c)) ? 
                                objComplimentary.enrolment__r.Student__c : Null;
    complimentaryObj.date_c = objComplimentary.Credit_Apply_date__c ;
    complimentaryObj.weekday = String.isnotBlank(objComplimentary.enrolment__c) ?
                            objComplimentary.enrolment__r.Lesson_Day__c : Null;
    complimentaryObj.packageName = String.isnotBlank(objComplimentary.Package_Name__c) ?
                                objComplimentary.Package_Name__r.Name : Null;
    complimentaryObj.packageType = String.isnotBlank(objComplimentary.Package_Name__c) ?
                                objComplimentary.Package_Name__r.type__c : Null;
    complimentaryObj.time_c = String.isnotBlank(objComplimentary.enrolment__c) ?
                                objComplimentary.enrolment__r.Lesson_Start_time__c : Null;
    complimentaryObj.instrument =  String.isnotBlank(objComplimentary.enrolment__c) ?
                                objComplimentary.enrolment__r.Instrument__c : Null;
    complimentaryObj.center =  (String.isnotBlank(objComplimentary.enrolment__c) && String.isnotBlank(objComplimentary.enrolment__r.Center__c)) ?
                                objComplimentary.enrolment__r.Center__r.Name : Null;
    complimentaryObj.teacherName = String.isnotBlank(objComplimentary.Teacher_Name__c) ? 
                                objComplimentary.Teacher_Name__r.Name : Null;
    complimentaryObj.teacherId = String.isnotBlank(objComplimentary.Teacher_Name__c) ?
                                objComplimentary.Teacher_Name__c : Null;
    complimentaryObj.centerId = (String.isnotBlank(objComplimentary.enrolment__c) && String.isnotBlank(objComplimentary.enrolment__r.Center__c)) ?
                                objComplimentary.enrolment__r.Center__c : Null;
    complimentaryObj.enrollmentId = String.isnotBlank(objComplimentary.enrolment__c) ? 
                                objComplimentary.Enrolment__c : Null;
    complimentaryObj.status = (objComplimentary.Is_Active__c == True) ? 'Active' : 'InActive';                            
    complimentaryObj.rescheduled = false;
    complimentaryObj.duration =  String.isnotBlank(objComplimentary.enrolment__c) ? 
                                objComplimentary.enrolment__r.Duration__c + ' min' : Null;
    complimentaryObj.type = String.isnotBlank(objComplimentary.enrolment__c) ?
                                objComplimentary.enrolment__r.Type__c : Null;
    complimentaryObj.cancellationReason = objComplimentary.Credit_Reason__c;
    complimentaryObj.lessonTypeNew = String.isnotBlank(objComplimentary.enrolment__c) ?
                                objComplimentary.enrolment__r.Lesson_Mode__c : Null;
    complimentaryObj.lessonPasscode = String.isnotBlank(objComplimentary.enrolment__c) ?
                                objComplimentary.enrolment__r.Online_Lesson_Passcode__c : Null;
    complimentaryObj.lessonOnlineURL = String.isnotBlank(objComplimentary.enrolment__c) ? 
                                objComplimentary.enrolment__r.Online_Lesson_URL__c : Null;
    complimentaryObj.expiryDate = objComplimentary.Credit_Expiry_date__c;
    complimentaryObj.isFifthBooking = false;
    complimentaryObj.availableMakeupMin = String.isNotBlank(String.valueOf(objComplimentary.Available_credit_Min__c)) ?
        objComplimentary.Available_credit_Min__c +' min':
        objComplimentary.Available_credit_Min__c +'' ;
    
    return complimentaryObj;
} 

//@jatin : Get Time Slots According to the centre, Single/Multiple Teachers and week day
public static WebServiceModelHelper.WorkingHours getTeachersWorkingHourTimeSlotList(Set<String> teacherIds, String centreId, String weekDay){
    WebServiceModelHelper.WorkingHours workingHours = new WebServiceModelHelper.WorkingHours();
    Map<String, Teacher_Working_Hour__c> workingHoursMap = new Map<String, Teacher_Working_Hour__c>();
    DateTime startTime, endTime;
    WebServiceModelHelper.TeacherSlot teacherSlots = new WebServiceModelHelper.TeacherSlot();
    if(teacherIds != null && teacherIds.size() > 0 && String.isNotBlank(centreId) && String.isNotBlank(weekDay)){
        workingHours.weekDay = weekDay;
        workingHours.centre = centreId;
        workingHoursMap = SOQLQueryHelper.getTeachersWorkingHours(teacherIds, centreId, weekDay);
    }
    workingHours.timeSlots = new List<WebServiceModelHelper.TeacherSlot>();
    for(String teacherId : workingHoursMap.keyset()){
        startTime = DateTime.newInstance(Date.today(), workingHoursMap.get(teacherId).Start_Time__c);
        endTime = DateTime.newInstance(Date.today(), workingHoursMap.get(teacherId).End_Time__c );
        if(startTime != NULL && endTime != NULL){
            teacherSlots = new WebServiceModelHelper.TeacherSlot();
            teacherSlots.teacherId = teacherId;
            teacherSlots.teacherName = workingHoursMap.get(teacherId).Teacher_Name__r.Name;
            teacherSlots.timeslots = getFormatedTimeSlotList(startTime, endTime);
            workingHours.timeSlots.add(teacherSlots);
        } 
    }
    
    return workingHours;
}
private static List<String> getFormatedTimeSlotList(DateTime startTime, DateTime endTime){
    List<String> timeSlots = new List<String>();
    if(startTime < endTime){
        while(startTime <= endTime){
            timeSlots.add(startTime.format('h:mm a'));
            //nishi
            startTime = startTime.addMinutes(15);
        }
    }
    return timeSlots;
}

// give time slots accordingly teachers center , duration AND  date
public static List<String> getTimeSlotsAccordingly(String centerId, String teacherId, String duration, String effectiveDateStr){
    List<String> availTimeSlots = new List<String>();
    List<String> durations = new List<String>();
    DateTime effectiveDate;
    List<Package__c> newPackageList = new List<Package__c>();
    if(String.isNotBlank(Duration)){
        // system.debug('@@Duration'+Duration);
        durations  = duration.contains(',') ? duration.split(',') : new List<String>{duration};
            newPackageList = [SELECT Id, Duration__c FROM Package__c WHERE Duration__c  In:durations AND Location__c =:centerId];
    }
    system.debug('@@newPackageList '+newPackageList );
    if(String.isNotBlank(effectiveDateStr)){
        effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
    }
    system.debug('^^teacherId'+teacherId);
    system.debug('^^Duration'+Duration);
    // If date not exist then get Date slots
    if(String.isNotBlank(teacherId) && String.isNotBlank(centerId) && effectiveDate == NULL){
        // check teacher id is multiple or one then according to id call functions
        availTimeSlots  = teacherId.contains(',') ? 
            getmultipleTeacherWorkingDateSlotList( 
                centerId,
                teacherId.split(','),
                durations,
                newPackageList ) : 
        getTeacherWorkingDateSlotList( 
            centerId,
            teacherId,
            Duration,
            newPackageList);
    }else{// If date is exist then get time slots
        if(String.isNotBlank(teacherId) && String.isNotBlank(centerId) && effectiveDate != NULL){
            // check teacher id is multiple or one then according to id call functions    
            availTimeSlots = teacherId.contains(',') ? 
                getMultipleTeacherWorkingHourTimeSlotList(
                    teacherId.split(','),
                    centerId,
                    effectiveDate.format('EEE'),
                    effectiveDate.date(),
                    newPackageList,
                    durations):
            getTeacherWorkingHourTimeSlotList(
                teacherId, 
                centerId, 
                effectiveDate.format('EEE'),
                effectiveDate.date(),
                newPackageList,
                Duration);
        }
    }
    
    return availTimeSlots;
}
// get multiple Teachers common hours slots 
public static List<String> getmultipleTeacherWorkingDateSlotList(String centerId, list<String> teacherIds, List<String> duration,List<Package__c> newPackageList){
    // 7-Aug-2019 : Nishi:for Manage first teacher get first duation and second get Second Duration
    Map<String,String> mapOfTeacherDuration = new Map<String,String>();
    if(( teacherIds != null && teacherIds.size() > 0)  && (duration!= null && duration.size() > 0) && teacherIds.size() == duration.size()){
        for(Integer teacherNo=0;teacherNo <    teacherIds.size() ;teacherNo++){
            mapOfTeacherDuration.put(teacherIds[teacherNo],duration[teacherNo]);
        }
    }
    // get this map<teacher,map<date,list<timeslots>>>  
    Map<string,Map<String,Set<String>>>  mapOfTeacher_Working_Hours = new Map<string,Map<String,Set<String>>> ();
    List<String> delDates = new list<String>();
    Date currentDate= date.today();
    Set<Date> bookingAvailableDates= new Set<date>();
    List<Teacher_Working_Hour__c> teachersHours = SOQLQueryHelper.getmultipleTeachersWorkingHours(teacherIds, centerId);
    set<String> weekDay = new  set<String> ();
    List<String> delWeekDays = new  List<String> ();
    // if any one teacher is not available in given duration then remove this week day
    
    //for get teacher working hours accrding to common week days
    if(teachersHours != null && mapOfTeacherDuration != null && mapOfTeacherDuration.size() > 0 &&  teachersHours.size() > 0 ){
        for(Teacher_Working_Hour__c teachersHour : teachersHours ){
            Long timeAvailable = gettimeAvailable(teachersHour.Start_Time__c, teachersHour.End_Time__c);
            //7-aug:2019:  for check related teacher duration
            if(mapOfTeacherDuration.containsKey(teachersHour.Teacher_Name__c)){
                // check Available time but is not common then we remove this days
                if(timeAvailable >= Integer.valueOf(mapOfTeacherDuration.get(teachersHour.Teacher_Name__c)) ){
                    weekDay.add(teachersHour.Working_Day__c);
                    
                    map<String,set<string>> mapOfTeacherWorkingDates =new map<String,set<string>>();
                    if(mapOfTeacher_Working_Hours.containsKey(teachersHour.Teacher_Name__c)){
                        mapOfTeacherWorkingDates = mapOfTeacher_Working_Hours.get(teachersHour.Teacher_Name__c);
                    }
                    mapOfTeacherWorkingDates.put(teachersHour.Working_Day__c,new Set<string>(getFormatedTimeSlotListForBooking( 
                        DateTime.newInstance(Date.today(), teachersHour.Start_Time__c),
                        DateTime.newInstance(Date.today(), teachersHour.End_Time__c ))));
                    mapOfTeacher_Working_Hours.put(teachersHour.Teacher_Name__c,mapOfTeacherWorkingDates);                               
                }else{
                    if(weekDay.contains(teachersHour.Working_Day__c))
                        delWeekDays.add(teachersHour.Working_Day__c);
                    //system.debug('@@CANCEL'+teachersHour.Working_Day__c);
                }
            }
        }
    }
    System.debug('@@@weekDay'+weekDay);
    System.debug('@@@delWeekDays'+delWeekDays);
    system.debug('@@mapOfTeacher_Working_Hours'+mapOfTeacher_Working_Hours);
    // If not common weekdays then remove in week day set 
    if(delWeekDays!= null && delWeekDays.size() > 0){
        weekDay.removeAll(delWeekDays);
    }// Map<string,Map<String,Set<String>>>
    if( weekDay!= null && mapOfTeacher_Working_Hours != null && weekDay.size() >0 && mapOfTeacher_Working_Hours.size() >0 ){
        System.debug('@@@weekDay'+weekDay);
        
        //currentDate =currentDate.addMonths(1);
        // get all next 30 days AvailTime date slots according to weekdays of teacher
        Map<string,Map<String,Set<String>>>  mapOfTeacherAvailTimeslots = new Map<string,Map<String,Set<String>>> ();
        Map<String,Set<String>>  mapOfAvailTimeslots = new Map<String,Set<String>> ();
        for(string teacherId: mapOfTeacher_Working_Hours.keySet()){
            mapOfAvailTimeslots =  new Map<String,Set<String>> ();
            for(Integer i= 1; i< 30;i++){
                DateTime  newDate = currentDate.addDays(i); 
                if(weekDay.contains(newDate.format('EEE')) && mapOfTeacher_Working_Hours.containsKey(teacherId)){
                    bookingAvailableDates.add(currentDate.addDays(i));
                    Set<String> weekTimeSlots= new Set<String>(mapOfTeacher_Working_Hours.get(teacherId).get(newDate.format('EEE')));
                    mapOfavailTimeslots.put(String.valueOf(currentDate.addDays(i)), weekTimeSlots);
                }
            }
            mapOfTeacherAvailTimeslots.put(teacherid,mapOfavailTimeslots);
        }
        system.debug('@@mapOfavailTimeslots'+mapOfavailTimeslots);
        // get available Date Slot and remove Schedule and unOrdered slots 
        return getDateSlotsList(mapOfTeacherAvailTimeslots ,bookingAvailableDates,centerId,teacherIds,mapOfTeacherDuration,newPackageList);
    }
    return New List<String>();
}

// get teacher working avaliable dates 
public static List<String> getTeacherWorkingDateSlotList(String centerId, String teacherId, string duration,List<Package__c> newPackageList){
    Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted};
        Set<String> bookTypeSet    = new Set<String>{ConstantsClass.typeTrial, ConstantsClass.typeRegular, ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc, ConstantsClass.typeBusy};
            String regularType = ConstantsClass.typeRegular;
    String busyType = ConstantsClass.typeBusy;
    Set<Date> bookingAvailableDates = new Set<Date>();
    Date currentDate= date.today();
    Map<String,Set<String>>  mapOfavailTimeslots = new Map<String,Set<String>> ();
    List<Teacher_Working_Hour__c> teachersHours =  SOQLQueryHelper.getTeachersWorkingHours(teacherId, centerId);
    Set<String> weekDay = new  Set<String> ();
    Map<String,Set<String>>  mapOfTeacher_Working_Hours = new Map<String,Set<String>> ();
    
    //check teacher working hours accorgint to week day
    if(teachersHours != null && teachersHours.size() >0 && duration != null){
        for(Teacher_Working_Hour__c teachersHour : teachersHours ){
            // check avaliable time is greater then given duration or not 
            // if greater then given duration then add this weed day
            Long timeAvailable = gettimeAvailable(teachersHour.Start_Time__c, teachersHour.End_Time__c);
            //system.debug('gettimeAvailable-->'+timeAvailable );
            if(timeAvailable >= Integer.valueOf(duration) ){
                weekDay.add(teachersHour.Working_Day__c);
                // get working day and related time slotes 
                mapOfTeacher_Working_Hours.put(teachersHour.Working_Day__c,
                                                new Set<string>(getFormatedTimeSlotListForBooking( 
                                                    DateTime.newInstance(Date.today(), teachersHour.Start_Time__c),
                                                    DateTime.newInstance(Date.today(), teachersHour.End_Time__c ))));
            }
        }
    }
    
    if(weekDay != null &&  mapOfTeacher_Working_Hours!= null && weekDay.size() > 0 && mapOfTeacher_Working_Hours.size() >0 ){
        system.debug('@@weekDay'+weekDay);
        // get 30 days date if is exist in week day
        for(Integer i= 1; i < 30;i++){
            DateTime  newDate = currentDate.addDays(i); 
            if(weekDay.contains(newDate.format('EEE')) && mapOfTeacher_Working_Hours.containsKey(newDate.format('EEE'))){
                Set<String> weekTimeSlots= new Set<String>(mapOfTeacher_Working_Hours.get(newDate.format('EEE')));
                // add dates and timeslots according to week days
                mapOfavailTimeslots.put(String.valueOf(currentDate.addDays(i)), weekTimeSlots);
                bookingAvailableDates.add(currentDate.addDays(i)); 
            }
        }
        system.debug('@duration'+duration);
        // get available Date Slot and remove Schedule and unOrdered slots
        return getDateSlotsList(new map<String,Map<String,Set<String>>> {teacherId=>mapOfavailTimeslots},bookingAvailableDates,centerId,new list<String>{teacherId},new map<string,String>{teacherId=>duration},newPackageList); 
    }
    return new List<String>(); 
}
private static map<String,Map<String,Set<String>>> getDateSlotsListRemoval(map<String,Map<String,Set<String>>>  mapOfteacherAvailTimeslots,map<String,Map<String,Set<String>>>  mapOfteacherRemoveTimeslots){
    for(string teacherId : mapOfteacherRemoveTimeslots.keySet()){
        if(mapOfteacherRemoveTimeslots.containsKey(teacherId)){
            // get date slots according to teacher Id
            Map<String,Set<String>> mapOfRemoveBookingTimeSlots = mapOfteacherRemoveTimeslots.get(teacherId);
            if(mapOfRemoveBookingTimeSlots != null && mapOfRemoveBookingTimeSlots.size() >0){ 
                for(string bookingDates: mapOfRemoveBookingTimeSlots.keySet()){
                    if(mapOfteacherAvailTimeslots.containsKey(teacherId)){
                        Map<String,Set<String>> mapOfavailTimeslots = mapOfteacherAvailTimeslots.get(teacherId);
                        // get Time slots or related date 
                        if(mapOfavailTimeslots != null && mapOfavailTimeslots.size() > 0){
                            if(mapOfavailTimeslots.containsKey(bookingDates)){
                                Set<String> bookSet = mapOfavailTimeslots.get(bookingDates);
                                // remove schedule time slots in availble time slots
                                if(bookSet != null && bookSet.size() >0 ){ 
                                    bookSet.removeAll(mapOfRemoveBookingTimeSlots.get(bookingDates));
                                    mapOfavailTimeslots.put(bookingDates, bookSet);
                                    mapOfteacherAvailTimeslots.put(teacherId,mapOfavailTimeslots);
                                }
                            }
                        }
                    }
                }
            }
        }                    
    }
    return  mapOfteacherAvailTimeslots;
}
// get unselected slots
private static map<String,Map<string ,Set<string>>> getUnorderedBookingDateSlots(map<String,Map<String,Set<String>>>  mapOfteacherAvailTimeslots,map<string,String> mapOfTeacherWithDuration){
    map<String ,Set<String>> mapOfUnOrderedTimeSlots  = new   map<String ,Set<String>>();
    map<String,Map<string ,Set<string>>> mapOfUnOrderedTeacherTimeSlots  = new map<String,Map<string ,Set<string>>>();
    for(string teacherId : mapOfteacherAvailTimeslots.keySet()){
        mapOfUnOrderedTimeSlots  = new   map<String ,Set<String>>();
        if(mapOfteacherAvailTimeslots.containsKey(teacherId)){
            Map<String,Set<String>> mapOfavailTimeslots= mapOfteacherAvailTimeslots.get(teacherId); 
            // get dateslots according to related teacher Id
            if(mapOfavailTimeslots != null && mapOfavailTimeslots.size() >0){
                for(string bookingDates: mapOfavailTimeslots.keyset()){
                    if(mapOfavailTimeslots.containsKey(bookingDates)){
                        // system.debug('@@bookingDates'+bookingDates);
                        // get timeslots according to related Date
                        if(mapOfavailTimeslots.get(bookingDates) != null && mapOfavailTimeslots.get(bookingDates).size() > 0 ){ 
                            // system.debug('@@mapOfavailTimeslots.get(bookingDates)'+mapOfavailTimeslots.get(bookingDates));
                            mapOfUnOrderedTimeSlots.put(bookingDates, 
                                                        removeUnselectableSlots(mapOfavailTimeslots.get(bookingDates), 
                                                                                mapOfTeacherWithDuration.get(teacherId)));
                            mapOfUnOrderedTeacherTimeSlots.put(teacherId,mapOfUnOrderedTimeSlots);          
                        }
                    }
                }
            }
        }
    }
    return mapOfUnOrderedTeacherTimeSlots  ;
}
// get available Date Slots and remove Schedule and unOrdered slots
private static List<String> getDateSlotsList (map<String,Map<String,Set<String>>>  mapOfteacherAvailTimeslots, 
                                                Set<Date> bookingAvailableDates,String centerId,List<String> teacherIds,
                                                map<string,String> mapOfTeacherWithDuration,List<Package__c> newPackageList){
                                                    // system.debug('@@mapOfTeacherWithDuration'+mapOfTeacherWithDuration);
                                                    map<String,Map<string ,Set<string>>>  mapOfScheduledTeacherBookingTimeSlots = getScheduledBookingDateSlots(bookingAvailableDates,centerId, teacherIds);
                                                    Map<string ,List<String>>  mapOfavailTimeslotsNew = new Map<string ,List<String>>();
                                                    // get Scheduled Teacher Booking TimeSlots for remove available teacher time slots 
                                                    if(mapOfScheduledTeacherBookingTimeSlots != null && mapOfScheduledTeacherBookingTimeSlots .size() >0){
                                                        mapOfteacherAvailTimeslots = getDateSlotsListRemoval(mapOfteacherAvailTimeslots,mapOfScheduledTeacherBookingTimeSlots );
                                                    }
                                                    
                                                    if(mapOfteacherAvailTimeslots!= null && mapOfteacherAvailTimeslots.size() > 0){
                                                        // 14-Oct-2019: Nishi:Start: -- remove Fifth booking records
                                                        map<String,Map<string ,Set<string>>>  mapOfFifthTeacherBookingTimeSlots = getFifthBookingDateSlots(bookingAvailableDates,centerId, teacherIds);
                                                        system.debug('@@@mapOfFifthTeacherBookingTimeSlots '+mapOfFifthTeacherBookingTimeSlots );
                                                        // get Fifth Teacher Booking TimeSlots for remove available teacher time slots 
                                                        if(mapOfFifthTeacherBookingTimeSlots != null && mapOfFifthTeacherBookingTimeSlots.size() >0){
                                                            mapOfteacherAvailTimeslots = getDateSlotsListRemoval(mapOfteacherAvailTimeslots,mapOfFifthTeacherBookingTimeSlots );
                                                        }
                                                        // 14-Oct-2019: Nishi : End : -- remove Fifth booking records
                                                    }
                                                    // system.debug('!!mapOfteacherAvailTimeslots'+mapOfteacherAvailTimeslots);
                                                    // system.debug('!!newPackageList '+newPackageList );
                                                    map<String ,Set<String>> mapOfUnOrderedTimeSlots  = new   map<String ,Set<String>>();
                                                    map<String,Map<string ,Set<string>>> mapOfUnOrderedTeacherTimeSlots  = new map<String,Map<string ,Set<string>>>();
                                                    // get unselected slots
                                                    if(mapOfteacherAvailTimeslots!= null && newPackageList != null && mapOfteacherAvailTimeslots.size() > 0 && newPackageList.size() > 0 ){
                                                        mapOfUnOrderedTeacherTimeSlots  = getUnorderedBookingDateSlots(mapOfteacherAvailTimeslots,mapOfTeacherWithDuration);
                                                    }
                                                    
                                                    // system.debug('!!!mapOfUnOrderedTimeSlots---------------------------------->'+mapOfUnOrderedTeacherTimeSlots);
                                                    // remove unordered time slots
                                                    if(mapOfUnOrderedTeacherTimeSlots!= Null && mapOfUnOrderedTeacherTimeSlots.size() > 0){
                                                        mapOfteacherAvailTimeslots = getDateSlotsListRemoval(mapOfteacherAvailTimeslots,mapOfUnOrderedTeacherTimeSlots);
                                                    }
                                                    
                                                    
                                                    List<string> teachers = New List<String>(mapOfTeacherWithDuration.keySet()); 
                                                    List<String> listOfDateSlots = new List<String>(getListOfAvailabelDates(
                                                        New List<String>(mapOfTeacherWithDuration.keySet()),
                                                        mapOfteacherAvailTimeslots));
                                                    // get common date and sort
                                                    if(listOfDateSlots != null && listOfDateSlots.size() >0){
                                                        listOfDateSlots.sort();
                                                        return  listOfDateSlots;
                                                    }else{
                                                        return new list<String>();
                                                    }
                                                }
private static Set<String> getListOfAvailabelDates(List<string> teachers,map<String,Map<String,Set<String>>>  mapOfteacherAvailTimeslots){
    Set<String> listOfAvailableDate = new Set<String>();
    if(mapOfteacherAvailTimeslots != null && mapOfteacherAvailTimeslots.size() >0){
        if(teachers!= null && teachers.size() > 1){
            // get all common slots  
            mapOfteacherAvailTimeslots = getMultipleTeacherTimeSlots(teachers ,mapOfteacherAvailTimeslots);
            Integer mapOfAvailableTeacherTimeSlotsSize = mapOfteacherAvailTimeslots.size();
            Map<string,set<string>> mapOfavailTimeslots = mapOfteacherAvailTimeslots.get(teachers[mapOfAvailableTeacherTimeSlotsSize]);
            // last slot is common slots and remove date if time slots size is 0
            if(mapOfavailTimeslots  != null && mapOfavailTimeslots.size() >0){
                system.debug('@@@mapOfavailTimeslots '+mapOfavailTimeslots );
                for(String dates: mapOfavailTimeslots.keySet()){
                    if(mapOfavailTimeslots.get(dates) != null && mapOfavailTimeslots.get(dates).size() >0)
                        listOfAvailableDate.add(string.valueOf(dates));
                }
            }
        }
        else{
            for(string teacherId : mapOfteacherAvailTimeslots.keySet()){
                Map<string,set<string>> mapOfavailTimeslots = mapOfteacherAvailTimeslots.get(teacherId);
                for(String dates: mapOfavailTimeslots.keySet()){
                    if(mapOfavailTimeslots.get(dates) != null && mapOfavailTimeslots.get(dates).size() >0)
                        listOfAvailableDate.add(string.valueOf(dates));
                }
            }
        }
    }
    return listOfAvailableDate;
}
// for return multiple teachers common date and common time slot
private Static map<String,Map<string ,Set<string>>>  getMultipleTeacherTimeSlots(List<string> teachers,Map<string,Map<String,Set<String>>>  mapOfTeacherAvailTimeslots){
    Set<String> listOfAvailableDate = new Set<String>();
    Set<String> listOfAvailDates = new Set<String>();
    map<String,Map<string ,Set<string>>> mapOfAvailableTeacherTimeSlots  = new map<String,Map<string ,Set<string>>>();
    Map<string,set<string>> mapOfDateSlotsCheck= new  Map<string,set<string>>();
    // get first teacher date slots for check common slots
    Map<string,set<string>> mapOfDateSlots = mapOfteacherAvailTimeslots.get(teachers[0]);
    
    For(Integer j = 1; j < teachers.size(); j++){
        Map<string,set<string>> mapOfDateSlots2=  new Map<string,set<string>>();
        // for if third teacher is exist then  set this mapOfDateSlots  map common slots of first and second user slots  
        if(j > 1 && mapOfAvailableTeacherTimeSlots != null && mapOfAvailableTeacherTimeSlots.size() > 0){
            if(mapOfAvailableTeacherTimeSlots.containsKey(teachers[j-1])){
                mapOfDateSlots = mapOfAvailableTeacherTimeSlots.get(teachers[j-1]);
            }
        }
        // get next teacher date slots for check common slots
        mapOfDateSlots2 = mapOfteacherAvailTimeslots.get(teachers[j]);
        //system.debug('!!!mapOfDateSlots '+mapOfDateSlots );
        // system.debug('!!!mapOfDateSlots2 '+mapOfDateSlots2 );
        if(mapOfDateSlots != null && mapOfDateSlots2 != null && mapOfDateSlots.size() > 0 && mapOfDateSlots2.size() > 0){
            // for check if not common date slots in first time then not check next teacher slots
            if((j > 1 && mapOfAvailableTeacherTimeSlots != null && mapOfAvailableTeacherTimeSlots.size() > 0) || j==1 ){
                for(string dateSlots1 :  mapOfDateSlots.keySet() ){
                    for(string dateSlots2 :  mapOfDateSlots2.keySet()){
                        // check common date slots in multiple teachers
                        if(dateSlots2.equalsIgnoreCase(dateSlots1)){
                            //system.debug('dateSlots2 '+dateSlots2 );
                            // get time slots for both teachers
                            set<string> listTimeSlots1=  mapOfDateSlots.get(dateSlots1);
                            set<string> listTimeSlots2=  mapOfDateSlots2.get(dateSlots2);
                            if(listTimeSlots1 != null && listTimeSlots2 != null && listTimeSlots2.size() >0 && listTimeSlots1.size() > 0){
                                //system.debug('!!listTimeSlots1'+listTimeSlots1);
                                //system.debug('!!listTimeSlots2'+listTimeSlots2);
                                for(string timeSlots1 :  listTimeSlots1){
                                    for(string timeSlots2 :  listTimeSlots2){
                                        // check common time slots in multiple teachers
                                        if(listTimeSlots2.contains(timeSlots1)){
                                            // system.debug('$$$Added date'+dateSlots1+' ---timeSlots2 --'+timeSlots2 );
                                            listOfAvailableDate.add(dateSlots1);
                                            mapOfDateSlotsCheck = new Map<string,set<string>>();
                                            listOfAvailDates = new Set<string>();
                                            if(mapOfAvailableTeacherTimeSlots.containskey(teachers[j])){
                                                mapOfDateSlotsCheck= mapOfAvailableTeacherTimeSlots.get(teachers[j]);
                                                if(mapOfDateSlotsCheck.containskey(dateSlots1)){
                                                    listOfAvailDates = mapOfDateSlotsCheck.get(dateSlots1);
                                                }
                                            }
                                            listOfAvailDates.add(timeSlots1);
                                            mapOfDateSlotsCheck.put(dateSlots1,listOfAvailDates);
                                            // only common slots are added in this map
                                            mapOfAvailableTeacherTimeSlots.put(teachers[j],mapOfDateSlotsCheck);  
                                            //system.debug('$$/////////////////   IF  ///////////////////// ------');
                                            
                                            //system.debug('%%%mapOfAvailableTeacherTimeSlots '+mapOfAvailableTeacherTimeSlots );
                                            // system.debug('%%%mapOfDateSlotsCheck'+mapOfDateSlotsCheck);
                                            //system.debug('%%%listOfAvailableDate'+listOfAvailableDate);
                                            //
                                            // system.debug('$$/////////////////   IF END ///////////////////// ------');
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }else{
            mapOfAvailableTeacherTimeSlots = new map<String,Map<string ,Set<string>>> ();
        }
    }
    //system.debug('%%%mapOfAvailableTeacherTimeSlots '+mapOfAvailableTeacherTimeSlots );
    //system.debug('%%%mapOfDateSlotsCheck'+mapOfDateSlotsCheck);
    //system.debug('%%%listOfAvailableDate'+listOfAvailableDate);
    if(mapOfAvailableTeacherTimeSlots != null && mapOfAvailableTeacherTimeSlots .size() >0){
        return mapOfAvailableTeacherTimeSlots ;
    }else{
        return new map<String,Map<string ,Set<string>>> ();
    }
}
// get Scheduled Booking teacher Date Slots for remove this in available slots
private static map<String,Map<string ,Set<string>>> getScheduledBookingDateSlots( Set<Date> bookingAvailableDates, String centerId, list<String> teacherIds){
    List<Booking__c> bookingList = getBookingsOnSelectedDates(centerId, teacherIds,bookingAvailableDates, false);
    System.debug('!!!bookingList '+bookingList);
    Map<String ,Set<string>> mapOfScheduledBookingTimeSlots= new Map<string ,Set<string>>();
    map<String,Map<string ,Set<string>>> mapOfScheduledTeacherBookingTimeSlots= new map<String,Map<string ,Set<string>>>();
    if(bookingList != null && bookingList.size() > 0){
        //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
        for(Booking__c currentBook : bookingList){
            Set<string> scheduledBookingTimeSlots = new Set<String>();
            mapOfScheduledBookingTimeSlots= new Map<string ,Set<string>>();
            if(mapOfScheduledTeacherBookingTimeSlots.containsKey(currentBook.Teacher_Account__c)){
                mapOfScheduledBookingTimeSlots = mapOfScheduledTeacherBookingTimeSlots.get(currentBook.Teacher_Account__c);
                if(mapOfScheduledBookingTimeSlots != null && mapOfScheduledBookingTimeSlots.size() >0){
                    if(mapOfScheduledBookingTimeSlots.containsKey(string.valueOf(currentBook.Booking_Date__c))){
                        scheduledBookingTimeSlots  = new Set<string>(mapOfScheduledBookingTimeSlots.get(string.valueOf(currentBook.Booking_Date__c)));
                    }
                }
            }
            scheduledBookingTimeSlots.AddAll(getFormatedTimeSlotListForBooking(
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c),
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c)));
            mapOfScheduledBookingTimeSlots.put(string.valueOf(currentBook.Booking_Date__c),
                                                scheduledBookingTimeSlots);
            mapOfScheduledTeacherBookingTimeSlots.put(currentBook.Teacher_Account__c,mapOfScheduledBookingTimeSlots);
            //system.debug('!!CONtains String.valueOf(currentBook.Booking_Date__c)'+mapOfScheduledBookingTimeSlots.get('2019-09-15'));
        }
    }
    /// system.debug('!!!mapOfScheduledBookingTimeSlots--'+mapOfScheduledTeacherBookingTimeSlots);
    if(mapOfScheduledTeacherBookingTimeSlots!= null && mapOfScheduledTeacherBookingTimeSlots.size() >0)
        return mapOfScheduledTeacherBookingTimeSlots;
    else
        return  new map<String,Map<string ,Set<string>>>();    
}

// get Fifth Booking teacher Date Slots for remove this in available slots
private static map<String,Map<string ,Set<string>>> getFifthBookingDateSlots( Set<Date> bookingAvailableDates, String centerId, list<String> teacherIds){
    List<Fifth_Lesson__c> bookingList = SOQLQueryHelper.getBookingsOnFifthDates(centerId, teacherIds,bookingAvailableDates);
    System.debug('!!!bookingList '+bookingList);
    Map<String ,Set<string>> mapOfFifthBookingTimeSlots= new Map<string ,Set<string>>();
    map<String,Map<string ,Set<string>>> mapOfFifthTeacherBookingTimeSlots= new map<String,Map<string ,Set<string>>>();
    if(bookingList != null && bookingList.size() > 0){
        //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
        for(Fifth_Lesson__c currentBook : bookingList){
            Set<string> fifthBookingTimeSlots = new Set<String>();
            mapOfFifthBookingTimeSlots= new Map<string ,Set<string>>();
            if(mapOfFifthTeacherBookingTimeSlots.containsKey(currentBook.Teacher_Account__c)){
                mapOfFifthBookingTimeSlots = mapOfFifthTeacherBookingTimeSlots.get(currentBook.Teacher_Account__c);
                if(mapOfFifthBookingTimeSlots != null && mapOfFifthBookingTimeSlots.size() >0){
                    if(mapOfFifthBookingTimeSlots.containsKey(string.valueOf(currentBook.Booking_Date__c))){
                        fifthBookingTimeSlots  = new Set<string>(mapOfFifthBookingTimeSlots.get(string.valueOf(currentBook.Booking_Date__c)));
                    }
                }
            }
            fifthBookingTimeSlots.AddAll(getFormatedTimeSlotListForBooking(
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c),
                DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c)));
            mapOfFifthBookingTimeSlots.put(string.valueOf(currentBook.Booking_Date__c),
                                            fifthBookingTimeSlots);
            mapOfFifthTeacherBookingTimeSlots.put(currentBook.Teacher_Account__c,mapOfFifthBookingTimeSlots);
            //system.debug('!!CONtains String.valueOf(currentBook.Booking_Date__c)'+mapOfFifthBookingTimeSlots.get('2019-09-15'));
        }
    }
    /// system.debug('!!!mapOfFifthBookingTimeSlots--'+mapOfFifthTeacherBookingTimeSlots);
    if(mapOfFifthTeacherBookingTimeSlots!= null && mapOfFifthTeacherBookingTimeSlots.size() >0)
        return mapOfFifthTeacherBookingTimeSlots;
    else
        return  new map<String,Map<string ,Set<string>>>();    
}

// for reutrn available minutes according to starttime  and endtime
public static long gettimeAvailable(Time Start_Time, Time End_Time){
    dateTime curst = DateTime.newInstance(Date.today(), Start_Time );
    dateTime endst = DateTime.newInstance(Date.today(),End_Time);
    Long timeAvailable = endst.getTime() - curst.getTime();
    timeAvailable /= 60000;
    return timeAvailable;
}

//Get Time Slots According to the centre, Teacher and week day
private static List<String> getTeacherWorkingHourTimeSlotList(String teacherId, String centreId, String weekDay,
                                                                Date effectiveDate,List<Package__c> newPackageList,string duration){
                                                                    Set<String> availTimeSlots = new Set<String>();
                                                                    DateTime startTime, endTime;
                                                                    List<Teacher_Working_Hour__c> teachersHours = SOQLQueryHelper.getTeachersWorkingHours(teacherId, centreId, weekDay);
                                                                    system.debug('@@@teachersHours '+teachersHours );
                                                                    system.debug('@@weekDay'+weekDay);
                                                                    // for get start time to end time working hours time slots
                                                                    if( teachersHours != null && teachersHours.size() > 0 && duration != null){
                                                                        startTime = DateTime.newInstance(Date.today(), teachersHours[0].Start_Time__c);
                                                                        endTime = DateTime.newInstance(Date.today(), teachersHours[0].End_Time__c );
                                                                        if(startTime != NULL && endTime != NULL){
                                                                            //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
                                                                            availTimeSlots = new Set<String>(getFormatedTimeSlotListForBooking(startTime, endTime));
                                                                        }
                                                                        system.debug('@@availTimeSlots '+availTimeSlots );
                                                                        if((availTimeSlots != null && availTimeSlots.size() > 0) && duration != null){
                                                                            Set<String> bookingAvailableDates = new Set<String>();
                                                                            for(Integer i= 1; i < 30;i++){
                                                                                bookingAvailableDates.add(string.valueOf(date.today().addDays(i))); 
                                                                            }
                                                                            if(bookingAvailableDates.contains(string.valueOf(effectiveDate))){
                                                                                return getTimeSlots(new map<string,Set<string>>{teacherId=>availTimeSlots},centreId,effectiveDate,newPackageList ,new map<string,string>{teacherId=>duration});
                                                                            }
                                                                            return new List<String>(); 
                                                                        }else
                                                                            return new List<String>();  
                                                                    }
                                                                    return new List<String>();        
                                                                }

//Get working hours According to the centre, multiple  Teacher and week day
private static List<String> getMultipleTeacherWorkingHourTimeSlotList(list<String> teacherIds, String centreId, String weekDay,
                                                                        Date effectiveDate,List<Package__c> newPackageList ,List<String> durations){
                                                                            Map<String,Set<String>> mapOfavailTimeslots = new Map<String,Set<String>>();
                                                                            Time startTime, endTime;
                                                                            long startDuration,endDuration;
                                                                            Map<String,String> mapOfTeacherDuration = new Map<String,String>();
                                                                            if(( teacherIds != null && teacherIds.size() > 0)  && (durations!= null && durations.size() > 0) && teacherIds.size() == durations.size()){
                                                                                for(Integer teacherNo=0;teacherNo < teacherIds.size() ;teacherNo++){
                                                                                    mapOfTeacherDuration.put(teacherIds[teacherNo],durations[teacherNo]);
                                                                                }
                                                                            }
                                                                            List<Teacher_Working_Hour__c> teachersHours = SOQLQueryHelper.getMultipleTeachersWorkingHours(teacherIds, centreId, weekDay);
                                                                            list<string> existingTeachers = new List<String>();
                                                                            // get greater start time and lowest end time for get minimum and common time slots
                                                                            if( mapOfTeacherDuration!= null&&  teachersHours != null && teachersHours.size() > 0 && mapOfTeacherDuration.size() > 0){
                                                                                for(Teacher_Working_Hour__c teachersHour :teachersHours){
                                                                                    if(mapOfTeacherDuration.containsKey(teachersHour.Teacher_Name__c)){
                                                                                        Long timeAvailable = gettimeAvailable(teachersHour.Start_Time__c, teachersHour.End_Time__c);
                                                                                        // check Available time but is not common then we remove this days
                                                                                        if(timeAvailable >= Integer.valueOf(mapOfTeacherDuration.get(teachersHour.Teacher_Name__c)) ){
                                                                                            Set<String> availTimeSlots = new Set<String>();
                                                                                            if(mapOfavailTimeslots.containsKey(teachersHour.Teacher_Name__c)){
                                                                                                availTimeSlots = mapOfavailTimeslots.get(teachersHour.Teacher_Name__c);
                                                                                            }
                                                                                            availTimeSlots.addAll(New Set<string>(getFormatedTimeSlotListForBooking( 
                                                                                                DateTime.newInstance(Date.today(), teachersHour.Start_Time__c),
                                                                                                DateTime.newInstance(Date.today(), teachersHour.End_Time__c ))));
                                                                                            mapOfavailTimeslots.put(teachersHour.Teacher_Name__c,availTimeSlots);
                                                                                            
                                                                                        }
                                                                                    } 
                                                                                }
                                                                                system.debug('@@mapOfavailTimeslots --'+mapOfavailTimeslots);
                                                                                system.debug('@@centreId --'+centreId);
                                                                                system.debug('@@effectiveDate --'+effectiveDate);
                                                                                system.debug('@@newPackageList --'+newPackageList);
                                                                                system.debug('@@mapOfTeacherDuration --'+mapOfTeacherDuration);
                                                                                Set<String> bookingAvailableDates = new Set<String>();
                                                                                for(Integer i= 1; i < 30;i++){
                                                                                    bookingAvailableDates.add(string.valueOf(date.today().addDays(i))); 
                                                                                }
                                                                                if(bookingAvailableDates.contains(string.valueOf(effectiveDate))){
                                                                                    return getTimeSlots(mapOfavailTimeslots,centreId,effectiveDate,newPackageList ,mapOfTeacherDuration);
                                                                                }
                                                                                return New list<String>();
                                                                                
                                                                            }
                                                                            return New list<String>();
                                                                        }

private static Map<String,Set<String>> getTimeSlotsListRemoval(Map<String,Set<String>> mapOfavailTimeslots, Map<String,Set<String>> mapOfRemovalTimeslots){
    for(string teacherId: mapOfRemovalTimeslots.keySet()){
        Set<String> teacherIdSet = mapOfavailTimeslots.get(teacherId);
        if(teacherIdSet != null && teacherIdSet.size() >0){
            teacherIdSet.removeAll(mapOfRemovalTimeslots.get(teacherId));
            mapOfavailTimeslots.put(teacherId, teacherIdSet);
        }
    } 
    return mapOfavailTimeslots;
}
public Static List<string> getTimeSlots(Map<String,Set<String>> mapOfavailTimeslots,string centerId,Date effectiveDate,
                                        List<Package__c> newPackageList ,map<string,String> teacherWithDurations){
                                            Map<String,Set<String>> mapOfScheduledBookingTimeSlots ,mapOfFifthBookingTimeSlots , mapOfUnOrderedTimeSlots= new Map<String,Set<String>>();
                                            if(mapOfavailTimeslots!= null && mapOfavailTimeslots.size() > 0 ){
                                                // get Bookings according to selected date 
                                                //list<string> teacherIds = teacherId.contains(',') ? teacherId.split(',') : new List<string>{teacherId}; 
                                                mapOfScheduledBookingTimeSlots = getScheduledBookingSlots(effectiveDate, centerId, mapOfavailTimeslots.keySet());
                                            }
                                            
                                            System.debug('@@@getScheduledBookingSlots-->'+mapOfScheduledBookingTimeSlots );
                                            
                                            if(mapOfScheduledBookingTimeSlots != null && mapOfScheduledBookingTimeSlots.size() >0){
                                                mapOfavailTimeslots = getTimeSlotsListRemoval(mapOfavailTimeslots ,mapOfScheduledBookingTimeSlots);
                                            }
                                            
                                            // 14-Oct-2019: Nishi:Start: -- remove Fifth booking records
                                            system.debug('@@@availTimeslots after remove slots --'+mapOfavailTimeslots);
                                            if(mapOfavailTimeslots != null  && mapOfavailTimeslots.size() > 0  ){
                                                mapOfFifthBookingTimeSlots = getFifthBookingSlots(effectiveDate, centerId, mapOfavailTimeslots.keySet());
                                            }
                                            system.debug('mapOfFifthBookingTimeSlots '+mapOfFifthBookingTimeSlots );
                                            if(mapOfFifthBookingTimeSlots != null && mapOfFifthBookingTimeSlots.size() > 0){
                                                mapOfavailTimeslots = getTimeSlotsListRemoval(mapOfavailTimeslots ,mapOfFifthBookingTimeSlots );
                                            }
                                            // 14-Oct-2019: Nishi:end : -- remove Fifth booking records
                                            // get unselected slots
                                            if(mapOfavailTimeslots != null && newPackageList != null && mapOfavailTimeslots.size() > 0  && newPackageList.size() > 0 ){
                                                for(string teacherId : mapOfavailTimeslots.keySet()){  
                                                    if(mapOfavailTimeslots.containsKey(teacherId) && teacherWithDurations.containsKey(teacherId )){
                                                        mapOfUnOrderedTimeSlots.put(teacherId, 
                                                                                    removeUnselectableSlots(mapOfavailTimeslots.get(teacherId), 
                                                                                                            teacherWithDurations.get(teacherId)));
                                                    }
                                                }
                                            }
                                            
                                            system.debug('!!!mapOfUnOrderedTimeSlots---------------------------------->'+mapOfUnOrderedTimeSlots);
                                            // remove unordered time slots
                                            if(mapOfUnOrderedTimeSlots!= Null && mapOfUnOrderedTimeSlots.size() > 0){
                                                mapOfavailTimeslots = getTimeSlotsListRemoval(mapOfavailTimeslots ,mapOfUnOrderedTimeSlots);
                                            }
                                            List<String> listOfAvailableTimeSlots = new List<string>(getlistOfAvailableTimeSlots(
                                                New List<String>(teacherWithDurations.keySet()),
                                                mapOfavailTimeslots,effectiveDate));
                                            system.debug('!!dates'+listOfAvailableTimeSlots);
                                            if(listOfAvailableTimeSlots != null && listOfAvailableTimeSlots.size() >0)
                                                return listOfAvailableTimeSlots;
                                            else
                                                return new List<string>();
                                        }

private static  Set<String>  getlistOfAvailableTimeSlots(List<string> teachers,Map<String,Set<String>> mapOfavailTimeslots,date effectiveDate){
    Set<String> listOfAvailableTimeSlots= new Set<String>();
    // check slots size if less then 0 then remove this date
    if(mapOfavailTimeslots != null && mapOfavailTimeslots.size() >0){
        if(teachers != null && teachers.size() > 1){
            Map<string,Map<String,Set<String>>>  mapOfTeacherAvailTimeslots = new Map<string,Map<String,Set<String>>> ();
            string availDate = string.valueOf(effectiveDate); 
            for(String teacher : teachers){
                
                mapOfTeacherAvailTimeslots.put(teacher,New Map<String,Set<String>>{availDate=>mapOfavailTimeslots.get(teacher)});
            } 
            mapOfteacherAvailTimeslots = getMultipleTeacherTimeSlots(teachers ,mapOfteacherAvailTimeslots);
            if(mapOfteacherAvailTimeslots != null && mapOfteacherAvailTimeslots.size()>0){
                Integer mapOfAvailableTeacherTimeSlotsSize = mapOfteacherAvailTimeslots.size();
                if(mapOfteacherAvailTimeslots.containsKey(teachers[mapOfAvailableTeacherTimeSlotsSize])){
                    mapOfavailTimeslots = mapOfteacherAvailTimeslots.get(teachers[mapOfAvailableTeacherTimeSlotsSize]);
                    system.debug('@@@mapOfavailTimeslots '+mapOfavailTimeslots );
                    if(mapOfavailTimeslots != null && mapOfavailTimeslots.size() > 0){
                        for(String dates: mapOfavailTimeslots.keySet()){
                            if(mapOfavailTimeslots.get(dates) != null && mapOfavailTimeslots.get(dates).size() >0)
                                listOfAvailableTimeSlots.addAll(mapOfavailTimeslots.get(dates));
                        }
                    }
                }
            }
        }else{
            for(String teacherId: mapOfavailTimeslots.keySet()){
                listOfAvailableTimeSlots.addAll(mapOfavailTimeslots.get(teacherId));
            }
        }
    }
    return listOfAvailableTimeSlots;  
}
// add schaduled booking time slots
private static Map<String,Set<String>> getScheduledBookingSlots( Date bookingsDate, String centerId, set<String> teacherIds){
    Set<Date> dt = new Set<Date>();
    dt.add(bookingsDate);
    List<Booking__c> bookingList = getBookingsOnSelectedDates(centerId, new List<string>(teacherIds), dt, false);
    System.debug('@@@getScheduledBookingSlots bookingList--> '+bookingList);
    System.debug('@@@getScheduledBookingSlots bookingList--> '+bookingList.size());
    Set<String> bookingSlots = new Set<String>();
    Map<String,Set<String>> mapOfBookingSlots = new  Map<String,Set<String>>();
    if(bookingList != null && bookingList.size() > 0 ){
        //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
        for(Booking__c currentBook : bookingList){
            bookingSlots = new Set<String>();
            if(mapOfBookingSlots.ContainsKey(currentBook.Teacher_Account__c )){
                bookingSlots  = mapOfBookingSlots.get(currentBook.Teacher_Account__c );
            }
            bookingSlots.addAll(getFormatedTimeSlotListForBooking(DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c)));
            mapOfBookingSlots.put(currentBook.Teacher_Account__c,bookingSlots);
        }
    }
    system.debug('@@bookingSlots --'+mapOfBookingSlots);
    return mapOfBookingSlots;
}

// 14-Oct-2019: Nishi : for add Fifthbooking time slots
private static Map<String,Set<String>> getFifthBookingSlots( Date bookingsDate, String centerId, set<String> teacherIds){
    Set<Date> dt = new Set<Date>();
    dt.add(bookingsDate);
    List<Fifth_Lesson__c> bookingList = SOQLQueryHelper.getBookingsOnFifthDates(centerId, new List<string>(teacherIds), dt);
    System.debug('@@@getFifthBookingSlots bookingList--> '+bookingList);
    Set<String> bookingSlots = new Set<String>();
    Map<String,Set<String>> mapOfBookingSlots = new  Map<String,Set<String>>();
    if(bookingList != null && bookingList.size() > 0 ){
        //Returns the timeslots in formated form(10:00 AM) with 15 mins gap 
        for(Fifth_Lesson__c currentBook : bookingList){
            bookingSlots = new Set<String>();
            if(mapOfBookingSlots.ContainsKey(currentBook.Teacher_Account__c )){
                bookingSlots  = mapOfBookingSlots.get(currentBook.Teacher_Account__c );
            }
            bookingSlots.addAll(getFormatedTimeSlotListForBooking(DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c), DateTime.newInstance(currentBook.Booking_Date__c, currentBook.end_Time__c)));
            mapOfBookingSlots.put(currentBook.Teacher_Account__c,bookingSlots);
        }
    }
    system.debug('@@fifthbookingSlots --'+mapOfBookingSlots);
    return mapOfBookingSlots;
}


private static List<String> getFormatedTimeSlotListForBooking(DateTime startTime, DateTime endTime){
    List<String> timeSlots = new List<String>();
    if(startTime < endTime){
        while(startTime < endTime){
            timeSlots.add(startTime.format('h:mm a'));
            startTime = startTime.addMinutes(15);
        }
    }
    return timeSlots;
}

//@jatin: remove Unselectable time Slots
private static Set<String> removeUnselectableSlots(Set<String> setOfTimeSlot, String timeSlotDuration){
    Set<String> elementsToRemove = new Set<String>();
    DateTime currentDT;
    Boolean innerLoop = false;
    //System.debug('@@durations'+timeSlotDuration);
    //   System.debug('@@timeSlots'+setOfTimeSlot);
    if(setOfTimeSlot != null && setOfTimeSlot.size() >0){
        List<string> timeSlots= new list<String>(setOfTimeSlot);
        integer duration = integer.valueOf(timeSlotDuration);
        // System.debug('@@durations'+duration);
        // System.debug('@@timeSlots'+timeSlots);
        
        
        for(integer i = 0; i< timeSlots.size(); i++){
            currentDT = getDateTimeFromString(timeSlots[i]);
            innerLoop = (i + duration / 15) > timeSlots.size() ? false : true;
            if(innerLoop){
                for(integer j = i ; j < i + duration / 15; j++){
                    if(currentDT.format('h:mm a') != timeSlots[j]){
                        elementsToRemove.add(timeSlots[i]);
                    }
                    currentDT = currentDT.addMinutes(15);
                }
            }else{
                elementsToRemove.add(timeSlots[i]);
            }
        }
    }
    return elementsToRemove;
}

//@jatin: this function return Date time according to given AM PM formated Time
private static DateTime getDateTimeFromString(String currentTime){
    DateTime dt;
    Time currentTimeObj;
    Integer hours, minutes;
    if(String.isNotBlank(currentTime)){
        if(currentTime.contains('AM')){
            hours = Integer.valueOf(currentTime.split(':')[0]); 
        }else if(currentTime.contains('PM') && !currentTime.contains('12')){
            hours = Integer.valueOf(currentTime.split(':')[0]) + 12; 
        }else if(currentTime.contains('PM') && currentTime.contains('12')){
            hours = Integer.valueOf(currentTime.split(':')[0]); 
        } 
        minutes = Integer.valueOf(currentTime.split(':')[1].split(' ')[0]);
        currentTimeObj = Time.newInstance(hours, minutes, 0, 0);
    }
    if(currentTimeObj != NULL){
        dt = DateTime.newInstance(Date.today(), currentTimeObj);
    }
    return dt;
}

private static List<Booking__c> getBookingsOnSelectedDates(String centerId, List<String> teacherIds, Set<Date> dates, Boolean enrolBool){
    String recordTypeLesson = ConstantsClass.recordTypeLesson;
    // 18-oct-2019 : Nishi: start :for change requirement
    //Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted};
    Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.typeTrial, ConstantsClass.typeRegular, ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc};
            
            //Set<String> bookTypeSet = new Set<String>{ConstantsClass.typeTrial, ConstantsClass.typeRegular, ConstantsClass.typeMakeup, ConstantsClass.typeAdhoc,ConstantsClass.typeBusy};
            // 18-oct-2019 : Nishi: End:for change  requirement 
            Date dt, endDt;
    String regularType = ConstantsClass.typeRegular;
    String busyType = ConstantsClass.typeBusy;
    
    String weekDay;
    // 14-oct-2019 : Nishi: start :for fifthlesson records requirement
    // 17-Feb-2020: nishi: fo add place holder category for show in time slots.
    Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};
        //24-Feb-2020://commented by nishi 24-Feb-2020: for manage placeholder type booking,ConstantsClass.bookingCategoryPlaceHolder
        string placeholderCategory= ConstantsClass.bookingCategoryPlaceHolder;
    // 14-oct-2019 : Nishi: end: for fifthlesson records requirement
    
    String queryStr = 'SELECT Id, Name, start_Time__c, Lesson_Type__c, Duration__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
    if(String.isNotBlank(centerId)){
        queryStr += ' AND Center__c =: centerId';
    }
    if(teacherIds!= null && teacherIds.size() > 0){
        queryStr += ' AND Teacher_Account__c in: teacherIds';
    }
    
    if(dates!= null && dates.size() > 0 ){
        // 14-oct-2019 : Nishi: start :for fifthlesson records requirement
        //queryStr += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND type__c IN: bookTypeSet AND Category__c !=: placeholderCategory';
        // commented by nishi:24-Feb-2020:manage placeholder type added in time slots and leave or holiday type booking remove
        //queryStr += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet ) OR (Type__c =: busyType AND Category__c NOT IN: busyStatusSet))';
        
        queryStr += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType  AND Category__c !=: placeholderCategory))';
        // 14-oct-2019 : Nishi: start :for fifthlesson records requirement
    }
    system.debug('!!!queryStr'+queryStr);
    return Database.query(queryStr);
}


// Get all lesson Name and id if not found then return  error
Public Static List<WebServiceModelHelper.lesson> getAllLesson(){
    List<Program__c> listOfPackage = SOQLQueryHelper.getAllProgram();
    WebServiceModelHelper.LessonResult LessonResultobj = new WebServiceModelHelper.LessonResult();
    List<WebServiceModelHelper.lesson> listOfLesson= new List<WebServiceModelHelper.lesson>();
    
    if(listOfPackage != null && listOfPackage.size() > 0){
        for(Program__c Programobj: listOfPackage ){
            WebServiceModelHelper.lesson lessonObj = new WebServiceModelHelper.lesson();
            lessonObj.lessonName=Programobj.name;
            lessonObj.lessonId=Programobj.Id;
            listOfLesson.add(lessonObj);
        }
        RestContext.response.statusCode = 200;
        return listOfLesson;
    }else{
        RestContext.response.statusCode = 400;
        return listOfLesson;
        //return  '{"errorCode":"DATA_NOT_FOUND","message":"Some error was found"}';
    }
}

// @nishi : for update any fields value according to record Id and  field type
public static String updateRecords(Id recordId,String fieldApi,string newValue){
    
    String  objectName = ''+recordId.getsobjecttype();
    string response = validateObjectNameAndFieldName(objectName.trim(), fieldApi);
    if(String.isNotBlank(response)){
        RestContext.response.statusCode = 400;
        return response;
    }
    else{
        try{ 
            Sobject sobj =  Schema.getGlobalDescribe().get(objectName.trim()).newSObject();
            system.debug('@@'+fieldApi);
            system.debug('@@'+newValue);
            String objectDataType = String.valueOf(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldApi).getDescribe().getType());
            if(objectDataType  == 'BOOLEAN'){
                sobj.put(fieldApi,Boolean.valueOf(newValue));
            }else if(objectDataType  == 'DATE' ){
                sobj.put(fieldApi,date.valueOf(newValue));
            }else if(objectDataType  == 'DATETIME' ){
                DateTime todayDateTime = date.valueOf(newValue).addDays(1);
                sobj.put(fieldApi,todayDateTime );
            }else if(objectDataType  == 'DOUBLE'){
                sobj.put(fieldApi,decimal.valueOf(newValue));
            }else{
                sobj.put(fieldApi,newValue);
            } 
            system.debug('@@'+sobj );
            sobj.put('Id',recordId);
            system.debug('@@'+sobj );
            update sobj ;
            RestContext.response.statusCode = 200;
            return '{"errorCode":"SUCCESS","message":"Record update sucessfully."}';
        }catch(exception e){
            RestContext.response.statusCode = 500;
            return '{"errorCode":"INTERNAL_ERROR","message":"' + e +'"}';
        }
    }
}

//@jatin: for check customer card details and update details then update in account records
public Static String updateCustomerCard(String tempCstmr ,String selMonth,String selYear){
    String errorMessage = '';
    WebServiceModelHelper.cardDetail cardDetails = new WebServiceModelHelper.cardDetail();
    List<Account> cstmrAccList = SOQLQueryHelper.getAccountStripeCustomerId(tempCstmr );
    try{ 
        if(cstmrAccList != null && cstmrAccList.size()>0 ){
            String stCstmrId  = cstmrAccList.get(0).Stripe_Customer_Id__c;
            system.debug('@@stCstmrId  '+stCstmrId  );
            system.debug('@@selMonth'+selMonth);
            system.debug('@@selYear'+selYear);
            if(String.isNotBlank(selMonth) && String.isNotBlank(selYear)){
                system.debug('@@@stCstmrId'+stCstmrId);
                WebServiceModelHelper.StripeCustomer sc = getCustomerWithCard(stCstmrId);
                System.debug('@@@@   '+sc.default_source);
                system.debug('@@@ sc'+sc);
                if(sc.error != null){
                    errorMessage = sc.error.message;
                    system.debug('@@@errorMessage '+errorMessage );
                }else if(sc.statusCode == 200 && String.isNotBlank(sc.default_source)){
                    WebServiceModelHelper.StripeCard scard = updateCard(stCstmrId, sc.default_source, selMonth, selYear);
                    if(scard.statusCode == 200){ 
                        system.debug('@@@scard '+scard );
                        system.debug('scard.exp_year'+scard.exp_year);
                        date newExpireDate;
                        if(scard.exp_year != null && scard.exp_month != null)
                            newExpireDate= date.newinstance(scard.exp_year, scard.exp_month, date.today().day());
                        Account objAcc = new Account(Id = tempCstmr,
                                                        //Expiry_Date__c = newExpireDate,
                                                        Expiry_Month__c= scard.exp_month,
                                                        Expiry_Year__c =scard.exp_year,
                                                        Card_Number__c=scard.last4, Card_Type__c=(scard.brand== 'American Express' ? 'amex' : scard.brand));
                        update objAcc;
                        Account acc=[Select Expiration__c from Account where Id=:tempCstmr]; //updated-02092020
                        cardDetails.exp_month = scard.exp_month;
                        cardDetails.exp_year = scard.exp_year ;
                        cardDetails.expiration = acc.Expiration__c; //updated-02092020
                        cardDetails.last4digits  = scard .last4;
                        cardDetails.brand = (scard.brand== 'American Express' ? 'amex' : scard.brand);
                    }
                    if(scard.error != null){
                        errorMessage = scard.error.message;
                        system.debug('@@@errorMessage '+errorMessage );
                    }
                }
            }else{
                errorMessage = 'Month and Year is required for the the card update';
            }
            
            if(String.isNotBlank(errorMessage)){
                RestContext.response.statusCode = 500;
                return '{"errorCode":"INTERNAL_ERROR","message":"' + errorMessage +'"}';
            }else{
                RestContext.response.statusCode = 200;
                return '{"errorCode":"SUCCESS","message":"Card update Successfully.","cardDetails":'+JSON.Serialize(cardDetails)+'}';
            }
        }else{
            RestContext.response.statusCode = 400;
            return  '{"errorCode":"DATA_NOT_FOUND","message":"Record not found"}';
        } 
    }catch(Exception e){
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + errorMessage +'"}';  
    }   
}

public static WebServiceModelHelper.StripeCard updateCard(String customerId, String cardId, String expMonth, String expYear){
    string chargeUrl = baseurl+'/v1/customers/'+customerId+'/sources/'+cardId;
    
    HttpRequest http = new HttpRequest();
    http.setEndpoint(chargeUrl);
    http.setMethod('POST');
    Blob headerValue = Blob.valueOf(apikey+':');
    String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    http.setHeader('Authorization', authorizationHeader);
    
    string url = '&' + EncodingUtil.urlEncode('exp_month', 'UTF-8') + '=' + EncodingUtil.urlEncode(expMonth, 'UTF-8') + '&';
    url += EncodingUtil.urlEncode('exp_year', 'UTF-8') + '=' + EncodingUtil.urlEncode(expYear, 'UTF-8') ;
    
    http.setBody(url);
    
    Integer statusCode;
    Http con = new Http();
    HttpResponse hs = new HttpResponse();
    
    hs = con.send(http);
    
    statusCode = hs.getStatusCode();
    
    system.debug('Carrd Response===='+hs.getBody());
    string response = hs.getBody();
    response = cleanJson(response);
    
    WebServiceModelHelper.StripeCard sc = (WebServiceModelHelper.StripeCard) System.JSON.deserialize(response, WebServiceModelHelper.StripeCard.class);
    
    sc.statusCode = statusCode;
    System.debug('Stripe Card '+sc);
    return sc;
}

//@jatin: for check customer card details and add in account records
public Static String addCustomerCard(String cstmrId,String token){
    List<Account> cstmrAccList = [SELECT Id,Name,PersonEmail,Stripe_Customer_Id__c FROM Account WHERE Id =: cstmrId];
    WebServiceModelHelper.cardDetail cardDetails = new WebServiceModelHelper.cardDetail();
    string errorMessage ='';
    try{
        if(cstmrAccList!= null && cstmrAccList.size()>0){
            Account csmtr = cstmrAccList[0];
            system.debug('csmtr '+csmtr );
            String customerId = csmtr.Stripe_Customer_Id__c;
            system.debug('@@customerId '+customerId );
            if(String.isBlank(customerId)){
                WebServiceModelHelper.StripeCharge sCstmr = New WebServiceModelHelper.StripeCharge();
                sCstmr = createStripeCustomer(token, csmtr.Name, csmtr.PersonEmail, 'Add customer from update card page');    
                System.debug(JSON.serialize(sCstmr));
                if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){ 
                    if(sCstmr.sources.total_count > 0 && sCstmr.sources.data != null && sCstmr.sources.data.size() > 0 ){
                        String last4 = sCstmr.sources.data[0].card != null ? sCstmr.sources.data[0].card.last4 : '';
                        String brand = sCstmr.sources.data[0].card != null ? sCstmr.sources.data[0].card.brand : '';
                        system.debug('@@@last4 '+last4 );
                        system.debug('@@@brand '+brand );
                        if(!String.isBlank(last4) && !String.isBlank(brand)){
                            date newExpireDate= date.newinstance(sCstmr.sources.data[0].card.exp_year, sCstmr.sources.data[0].card.exp_month, date.today().day());
                            Account objAcc = new Account(Id = cstmrId,
                                                            //Expiry_Date__c = newExpireDate, 
                                                            Expiry_Month__c= sCstmr.sources.data[0].card.exp_month,
                                                            Expiry_Year__c =sCstmr.sources.data[0].card.exp_year,
                                                            Stripe_Customer_Id__c = sCstmr.id, Card_Number__c=last4, Card_Type__c=(sCstmr.sources.data[0].card.brand== 'American Express' ? 'amex' : sCstmr.sources.data[0].card.brand));
                            update objAcc;
                            cardDetails.exp_month = sCstmr.sources.data[0].card.exp_month;
                            cardDetails.exp_year = sCstmr.sources.data[0].card.exp_year ;
                            cardDetails.last4digits  = sCstmr.sources.data[0].card.last4;
                            cardDetails.brand = (sCstmr.sources.data[0].card.brand== 'American Express' ? 'amex' : sCstmr.sources.data[0].card.brand);
                            
                        } else if(String.isNotBlank(sCstmr.sources.data[0].last4) && String.isNotBlank(sCstmr.sources.data[0].brand)  ){
                            date newExpireDate= date.newinstance(sCstmr.sources.data[0].exp_year, sCstmr.sources.data[0].exp_month, date.today().day());
                            Account objAcc = new Account(Id = cstmrId,
                                                            //Expiry_Date__c = newExpireDate, 
                                                            Expiry_Month__c= sCstmr.sources.data[0].exp_month,
                                                            Expiry_Year__c =sCstmr.sources.data[0].exp_year,
                                                            Stripe_Customer_Id__c = sCstmr.id, Card_Number__c=sCstmr.sources.data[0].last4, Card_Type__c=(sCstmr.sources.data[0].brand == 'American Express' ? 'amex' : sCstmr.sources.data[0].brand));
                            update objAcc;
                            cardDetails.exp_month = sCstmr.sources.data[0].exp_month;
                            cardDetails.exp_year = sCstmr.sources.data[0].exp_year ;
                            cardDetails.last4digits  = sCstmr.sources.data[0].last4;
                            cardDetails.brand = (sCstmr.sources.data[0].brand== 'American Express' ? 'amex' : sCstmr.sources.data[0].brand);
                            
                        }
                        else{
                            errorMessage  = 'last4  and brand not found';
                        }
                    }else{
                        errorMessage = 'Stripe data not found..';
                    }
                }else{
                    errorMessage  = ''+sCstmr.error.message;
                }
            }else{
                WebServiceModelHelper.StripeCard addCard = AddCardWithCustomer(customerId,token);
                system.debug('@@@addCard '+addCard );
                if(addCard.error != null){
                    errorMessage = ''+addCard.error.message;
                }else if(addCard.statusCode == 200 && addCard.id != null && !String.isBlank(addCard.id)){
                    WebServiceModelHelper.StripeCharge setDefault = setDefaultCard(customerId,addCard.id);
                    system.debug('@@@setDefault '+JSON.serialize(setDefault) );
                    system.debug('@@@setDefault.sources.total_count'+setDefault.sources.total_count);
                    system.debug('@@@setDefault.sources.data.size()'+setDefault.sources.data.size());
                    system.debug('@@@setDefault.sources.data'+setDefault.sources.data);
                    String last4='';
                    String brand = '';
                    if(setDefault.sources.total_count > 0  && setDefault.sources.data != null && setDefault.sources.data.size() > 0){    
                        if(setDefault.sources.data[0].card != null){
                            WebServiceModelHelper.Data dateCstmr = New WebServiceModelHelper.Data();
                            dateCstmr = setDefault.sources.data[0];
                            system.debug(''+dateCstmr.card.brand);
                            system.debug(''+dateCstmr.card.last4);
                            
                            last4 = dateCstmr.card.last4;
                            brand = dateCstmr.card.brand;
                            system.debug('@@@last4 '+last4 );
                            system.debug('@@@brand '+brand );
                        }
                    }
                    if(setDefault.error != null){
                        errorMessage  = ''+setDefault .error.message;
                    }
                    if(setDefault.statusCode == 200 && setDefault.Id != null && !String.isBlank(setDefault.id) && 
                        !String.isBlank(last4) && !String.isBlank(brand)){
                            date newExpireDate;
                            if(setDefault.sources.data[0].card.exp_year != null && setDefault.sources.data[0].card.exp_month != null) 
                                newExpireDate= date.newinstance(setDefault.sources.data[0].card.exp_year, setDefault.sources.data[0].card.exp_month, date.today().day());
                            Account objAcc = new Account(Id = cstmrId,
                                                        //Expiry_Date__c = newExpireDate,
                                                        Expiry_Month__c= setDefault.sources.data[0].card.exp_month,
                                                        Expiry_Year__c =setDefault.sources.data[0].card.exp_year,
                                                        Card_Number__c=last4,
                                                        Card_Type__c=(brand == 'American Express' ? 'amex' : brand));
                            UPDATE objAcc;
                            cardDetails.exp_month = setDefault.sources.data[0].card.exp_month;
                            cardDetails.exp_year = setDefault.sources.data[0].card.exp_year ;
                            cardDetails.last4digits  = setDefault.sources.data[0].card.last4;
                            cardDetails.brand = setDefault.sources.data[0].card.brand == 'American Express' ? 'amex' : setDefault.sources.data[0].card.brand ; 
                            system.debug('@@@objAcc'+objAcc);
                        } else if(setDefault.statusCode == 200 && setDefault.Id != null && !String.isBlank(setDefault.id) && setDefault.sources.total_count > 0 && !String.isBlank(setDefault.sources.data[0].brand) && !String.isBlank(setDefault.sources.data[0].last4)){
                            date newExpireDate;
                            if(setDefault.sources.data[0].exp_year != null && setDefault.sources.data[0].exp_month != null) 
                                newExpireDate= date.newinstance(setDefault.sources.data[0].exp_year, setDefault.sources.data[0].exp_month, date.today().day());
                            Account objAcc = new Account(Id = cstmrId,
                                                        //Expiry_Date__c = newExpireDate,
                                                        Expiry_Month__c= setDefault.sources.data[0].exp_month,
                                                        Expiry_Year__c =setDefault.sources.data[0].exp_year,
                                                        Card_Number__c=setDefault.sources.data[0].last4,
                                                        Card_Type__c=(setDefault.sources.data[0].brand == 'American Express' ? 'amex' : setDefault.sources.data[0].brand));
                            UPDATE objAcc;
                            cardDetails.exp_month = setDefault.sources.data[0].exp_month;
                            cardDetails.exp_year = setDefault.sources.data[0].exp_year ;
                            cardDetails.last4digits  = setDefault.sources.data[0].last4;
                            cardDetails.brand = setDefault.sources.data[0].brand == 'American Express' ? 'amex' : setDefault.sources.data[0].brand ; 
                            system.debug('@@@objAccElse'+objAcc);
                            
                        } else{
                            errorMessage  = 'last4  and brand not found';
                        }
                }
            }
            if(String.isNotBlank(errorMessage)){
                RestContext.response.statusCode = 500;
                return '{"errorCode":"INTERNAL_ERROR","message":"' + errorMessage +'"}';
            }else{
                RestContext.response.statusCode = 200;
                return '{"errorCode":"SUCCESS","message":"Customer created Successfully","cardDetails":'+JSON.Serialize(cardDetails)+'}';
            }
        }else{
            RestContext.response.statusCode = 400;
            return  '{"errorCode":"DATA_NOT_FOUND","message":"Record not found"}';
        }  
    }catch(Exception e){
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + errorMessage +'"}';  
    }
}

public static WebServiceModelHelper.StripeCard AddCardWithCustomer(String customerId,String token){
    string chargeUrl = baseurl+'/v1/customers/'+customerId+'/sources';
    
    HttpRequest http = new HttpRequest();
    http.setEndpoint(chargeUrl);
    http.setMethod('POST');
    Blob headerValue = Blob.valueOf(apikey+':');
    String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    http.setHeader('Authorization', authorizationHeader);
    
    string url = '&' + EncodingUtil.urlEncode('source', 'UTF-8') + '=' + 
        EncodingUtil.urlEncode(token, 'UTF-8') + '&';
    
    http.setBody(url);
    
    Integer statusCode;
    Http con = new Http();
    HttpResponse hs = new HttpResponse();
    
    hs = con.send(http);
    
    statusCode = hs.getStatusCode();
    
    //system.debug('Carrd Response===='+hs.getBody());
    string response = hs.getBody();
    response = cleanJson(response);
    
    WebServiceModelHelper.StripeCard sc = (WebServiceModelHelper.StripeCard) System.JSON.deserialize(response, WebServiceModelHelper.StripeCard.class);
    
    sc.statusCode = statusCode;
    System.debug('Stripe Card '+sc);
    return sc;
}    

// @jatin: for check card Details like :cvv,expire date then return last 4 digit and expire date in model class
public static WebServiceModelHelper.StripeCharge setDefaultCard(String customerId,String cardId){
    String baseurl;
    String apikey;
    List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
    if(stripeSettings!= null && stripeSettings.size()>0){
        baseUrl = stripeSettings[0].Stripe_Base_Url__c;
        apiKey = stripeSettings[0].Stripe_Secret_Key__c;
    }
    string chargeUrl = baseurl+'/v1/customers/'+customerId;
    HttpRequest http = new HttpRequest();
    http.setEndpoint(chargeUrl);
    http.setMethod('POST');
    Blob headerValue = Blob.valueOf(apikey+':');
    String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    http.setHeader('Authorization', authorizationHeader);
    string url = '&' + EncodingUtil.urlEncode('default_source', 'UTF-8') + '=' + EncodingUtil.urlEncode(cardId, 'UTF-8') + '&';
    http.setBody(url);
    Integer statusCode;
    Http con = new Http();
    HttpResponse hs = new HttpResponse();
    hs = con.send(http);
    statusCode = hs.getStatusCode();
    system.debug('Response===='+hs.getBody());
    string response = hs.getBody();
    WebServiceModelHelper.StripeCharge sc = (WebServiceModelHelper.StripeCharge ) System.JSON.deserialize(response.replaceAll('object','object_z').replaceAll('currency','currency_z'), WebServiceModelHelper.StripeCharge.class);
    
    sc.statusCode = statusCode;
    system.debug('@@@sc'+sc);
    return sc;
}

public static WebServiceModelHelper.StripeCustomer getCustomerWithCard(String customerId){
    String baseurl;
    String apikey;
    List<Stripe_Settings__mdt> stripeSettings = [Select Id,Stripe_Base_Url__c,Stripe_Secret_Key__c from Stripe_Settings__mdt where DeveloperName='Stripe' limit 1];
    if(stripeSettings!= null && stripeSettings.size()>0){
        baseUrl = stripeSettings[0].Stripe_Base_Url__c;
        apiKey = stripeSettings[0].Stripe_Secret_Key__c;
    }
    
    string chargeUrl = baseurl+'/v1/customers/'+customerId;
    
    HttpRequest http = new HttpRequest();
    http.setEndpoint(chargeUrl);
    http.setMethod('GET');
    Blob headerValue = Blob.valueOf(apikey+':');
    String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    http.setHeader('Authorization', authorizationHeader);
    
    Integer statusCode;
    Http con = new Http();
    HttpResponse hs = new HttpResponse();
    
    hs = con.send(http);
    
    statusCode = hs.getStatusCode();
    
    system.debug('Carrd Response===='+hs.getBody());
    string response = hs.getBody();
    response = cleanJson(response);
    
    WebServiceModelHelper.StripeCustomer sc = (WebServiceModelHelper.StripeCustomer) System.JSON.deserialize(response, WebServiceModelHelper.StripeCustomer.class);
    
    sc.statusCode = statusCode;
    System.debug('Stripe Card '+sc);
    return sc;
}

Public static String cleanJson(String json) {
    json = json.replaceAll('"object":', '"stripeObject":');
    json = json.replaceAll('"date":', '"stripeDate":');
    json = json.replaceAll('"end":', '"endDate":');
    json = json.replaceAll('"data":', '"stripeData":');
    json = json.replaceAll('"currency":', '"stripeCurrency":');
    json = json.replaceAll('"type":', '"stripeType":');
    
    json = json.replaceAll('"customer":\\s?"cus_', '"customer_id": "cus_');
    json = json.replaceAll('"invoice":\\s?"in_', '"invoice_id": "in_');
    
    return json;
}

// @jatin: for add card Details
private static WebServiceModelHelper.StripeCharge createStripeCustomer(string token,string name,string email, string description){
    string customerUrl = baseurl + '/v1/customers';
    
    HttpRequest http = new HttpRequest();
    http.setEndpoint(customerUrl);
    http.setMethod('POST');
    Blob headerValue = Blob.valueOf(apiKey + ':');
    String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    http.setHeader('Authorization', authorizationHeader);
    
    string url = '&' + EncodingUtil.urlEncode('source', 'UTF-8') + '=' + EncodingUtil.urlEncode(token, 'UTF-8') + '&';
    url += EncodingUtil.urlEncode('metadata[Name]', 'UTF-8') + '=' + EncodingUtil.urlEncode(name, 'UTF-8') + '&';
    url += EncodingUtil.urlEncode('email', 'UTF-8') + '=' + EncodingUtil.urlEncode(email, 'UTF-8') + '&';
    url += EncodingUtil.urlEncode('description', 'UTF-8') + '=' + EncodingUtil.urlEncode(description, 'UTF-8') + '&';
    
    http.setBody(url);
    
    Integer statusCode;
    Http con = new Http();
    HttpResponse hs = new HttpResponse();
    
    hs = con.send(http);
    
    statusCode = hs.getStatusCode();
    
    system.debug('Response===='+hs.getBody());
    string response = hs.getBody();
    
    WebServiceModelHelper.StripeCharge sc = (WebServiceModelHelper.StripeCharge ) System.JSON.deserialize(response.replaceAll('object','object_z').replaceAll('currency','currency_z'), WebServiceModelHelper.StripeCharge.class);
    
    sc.statusCode = statusCode;
    return sc;
}

// get all teacher according to center id and account name
public Static String  getAllTeacher(String centerId,String lessonName){
    Set<id> teacherids = new Set<id>();
    WebServiceModelHelper.TeacherDetails objTeacherDetails = new WebServiceModelHelper.TeacherDetails();
    List<WebServiceModelHelper.instrument> listOfInstrument  = new List<WebServiceModelHelper.instrument>();
    List<teacher_working_hour__c> listOfteacher_working_hours =SOQLQueryHelper.getTeacherWorkingHours(centerId);
    if(listOfteacher_working_hours != null&& listOfteacher_working_hours.size() > 0 ){
        for(teacher_working_hour__c twhObj : listOfteacher_working_hours){
            teacherids.add(twhObj.teacher_name__c);
        }
        System.debug('teacherids = '+teacherids);
        if( teacherids != null && teacherids.size() > 0){
            List<Account> listOfAccount =SOQLQueryHelper.getAccount(lessonName,teacherids);         
            if( listOfAccount != null && listOfAccount.size() > 0){
                for(Account accObj : listOfAccount ){
                    WebServiceModelHelper.instrument objinstrument  = new WebServiceModelHelper.instrument();
                    objinstrument.teachername   = accObj.Name;
                    objinstrument.teacherId= accObj.id;
                    listOfInstrument.add(objinstrument);
                }
            }
        }
    }
    RestContext.response.statusCode = 200;
    objTeacherDetails.teachers = listOfInstrument;
    return JSON.Serialize(objTeacherDetails);
}

// get center id then response package records
public static String getPackages(String centerId){
    List<Package__c > listOfpackage = SOQLQueryHelper.getAvailableMakups(centerId);
    List<WebServiceModelHelper.packages> listOfpackages  = new List<WebServiceModelHelper.packages>();
    if(listOfpackage != null && listOfpackage.size() > 0){
        for(Package__c pkg : listOfpackage ){
            WebServiceModelHelper.packages objpackages = New WebServiceModelHelper.packages();
            objpackages.packageId = pkg.Id;
            objpackages.packageName= pkg.Name;
            objpackages.duration= Integer.valueOf(pkg.Duration__c);
            listOfpackages.add(objpackages);
        }                       
    }
    RestContext.response.statusCode = 200;
    return JSON.Serialize(listOfpackages);
}

//25-Jul-2019 :  insert multiple makeup Bookings  
public static String inserMakeupBooking(List<WebServiceModelHelper.MakeAppointmentForPortalModalClass> newModelList){
    Savepoint sp = Database.setSavepoint();  
    Map<String,Integer> makeUpPackageMap = new Map<String,Integer>();
    List<Package__c > listOfPackage = SOQLQueryHelper.getListOfMakeupPackage();
    List<string> lessonIds = new List<string>();
    //String errorMessage ='';
    // map package id and duration 
    if(listOfPackage != null && listOfPackage.size() >0){
        for(Package__c pkg : listOfPackage ){
            makeUpPackageMap.put(pkg.id,Integer.valueOf(pkg.Duration__c));    
        } 
    }
    system.debug('@@makeUpPackageMap'+makeUpPackageMap);               
    //String errorMsg = '';
    List<Booking__c> bookingListForInsert = new List<Booking__c>();
    try{
        system.debug('@@@newModelList'+newModelList);
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        Integer hoursToDeduct = 0;
        if(newModelList != null && newModelList.size() >0){
            // insert Booking records into Model class
            for(WebServiceModelHelper.MakeAppointmentForPortalModalClass mObj : newModelList){
                if(string.isNotBlank(mObj.bookingId)){
                    lessonIds.add(mObj.bookingId);
                }else{
                    List<String> timeList = mObj.startTime.split(':');
                    Time tempstartTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);    
                    Booking__c bookingObj = new Booking__c(RecordtypeId = bookLessRecId);
                    bookingObj.Center__c  = (String.isNotBlank(mObj.CenterId)?mObj.CenterId:Null);
                    bookingObj.Teacher_Account__c = (String.isNotBlank(mObj.teacherId)?mObj.teacherId:Null);
                    bookingObj.Enrolment__c = (String.isNotBlank(mObj.enrolmentId)?mObj.enrolmentId:Null);
                    bookingObj.Student__c = (String.isNotBlank(mObj.studentId)?mObj.studentId:Null);
                    bookingObj.Package__c = (String.isNotBlank(mObj.packageId)?mObj.packageId:Null);
                    bookingObj.Type__c    = ConstantsClass.typeMakeup;
                    bookingObj.Lesson_Type__c = (String.isNotBlank(mObj.lessonTypeNew)?mObj.lessonTypeNew:Null);
                    bookingObj.Is_Lesson_Type_Change__c = true;
                    bookingObj.status__c  = ConstantsClass.statusScheduled;
                    bookingObj.Booking_Date__c = (String.isNotBlank(mObj.bookingdate)?date.parse(mObj.bookingdate):date.today()); 
                    bookingObj.Start_Time__c = tempstartTime;
                    
                    if(mObj.duration > 0 && (makeUpPackageMap != null && makeUpPackageMap.size() > 0 && makeUpPackageMap.containsKey(mObj.packageId))){                        
                        bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(makeUpPackageMap.get(mObj.packageId));                    
                    }
                    bookingListForInsert.add(bookingObj);  
                }           
            } 
            system.debug('@@bookingListForInsert'+bookingListForInsert); 
            System.debug('@@@makeUpPackageMap'+makeUpPackageMap);  
            if((bookingListForInsert != null && bookingListForInsert.size() > 0) || (lessonIds!= null && lessonIds.size() > 0)){
                // insert Bookings records and deduct makeup hours
                if(bookingListForInsert != null && bookingListForInsert.size() > 0){
                    WebServiceModelHelper.mobileAppError mobileAppCode = WebServiceDataFactoryBookingHelper.deductMakeupHours(bookingListForInsert, newModelList[0].parentId,makeUpPackageMap); 
                    system.debug('@@@mobileAppCode '+mobileAppCode );
                    if(mobileAppCode.errorCode == 'SUCCESS'){
                        system.debug('@@@mobileAppCode.message'+mobileAppCode.message);  
                        // insert App_Feeds__c records 
                        list<Booking__c> listOfBooking =SOQLQueryHelper.getListOfBookingWithId(mobileAppCode.message); 
                        String  errorMessage = insertApp_Feeds(listOfBooking, 'Make-Up');
                        if(string.isNotBlank(errorMessage )){
                            RestContext.response.statusCode = 500;
                            return '{"errorCode":"INTERNAL_ERROR","message":"'+ errorMessage  +'"}';
                        }
                    }else{
                        if(mobileAppCode.errorCode == 'INTERNAL_ERROR'){ 
                            RestContext.response.statusCode = 500;
                        }else{
                            RestContext.response.statusCode = 400;
                        } 
                        return  JSON.Serialize(mobileAppCode); 
                    } 
                }
                if(lessonIds!= null && lessonIds.size() > 0){
                    system.debug('@@lessonIds'+lessonIds);
                    list<Fifth_Lesson__c> listOfFifthLesson =  SOQLQueryHelper.getListOfFifthLessonWithId(string.join(lessonIds,','));
                    if(listOfFifthLesson != Null && listOfFifthLesson.size() > 0){
                        system.debug('@@listOfFifthLesson '+listOfFifthLesson );
                        // nishi: 10-oct-2019: update Fifth booking and create booking and app_feed records 
                        //return createFifthbookingRecords(listOfFifthLesson[0].id ,'makeup','5th Lesson - MU');
                        // nishi: 11-oct-2019: update Fifth booking and create booking and app_feed records  
                        system.debug('@@@listOfFifthLesson[0].id'+listOfFifthLesson[0].id);
                        WebServiceModelHelper.mobileAppError mobileAppCode = createFifthbookingRecords(listOfFifthLesson[0].id ,'makeup','5th Lesson - MU'); 
                        system.debug('@@@mobileAppCode '+mobileAppCode );
                        if(mobileAppCode.errorCode == 'SUCCESS'){
                            RestContext.response.statusCode = 200;
                        }else{
                            if(mobileAppCode.errorCode == 'INTERNAL_ERROR'){ 
                                RestContext.response.statusCode = 500;
                            }else{
                                RestContext.response.statusCode = 400;
                            } 
                            return  JSON.Serialize(mobileAppCode); 
                        }
                        
                    }else{
                        RestContext.response.statusCode = 400;
                        return  '{"errorCode":"DATA_NOT_FOUND","message":"Makeup Records not found"}';
                    }
                }  
                // Oct-09-2019 :Nishi :  End: for get FifthBooking records
                RestContext.response.statusCode = 200;
                return '{"errorCode":"SUCCESS","message":"MakeUp created Successfully"}';          
            }else{
                RestContext.response.statusCode = 400;
                return  '{"errorCode":"DATA_NOT_FOUND","message":"Makeup Records not found"}';
            }                  
        }else{
            RestContext.response.statusCode = 400;
            return  '{"errorCode":"DATA_NOT_FOUND","message":"Makeup Records not found"}';
        }
    }catch(Exception e){
        system.debug('@@@e.getMessage()'+e.getMessage());
        Database.rollback(sp);
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + e.getMessage()+'"}';
    }
}


// 7Aug: For get all Mobile notification response
public Static String getMobileNotfication(String parentId){
    List<WebServiceModelHelper.Notification> listOfNotification = new List<WebServiceModelHelper.Notification>();
    WebServiceModelHelper.NotificationResult objNotificationResult = new WebServiceModelHelper.NotificationResult();
    if(String.isNotBlank(parentId)){
        List<Mobile_Notification__c > listOfMobileNotification = SOQLQueryHelper.getListOfParentMobileNotification(parentId);
        if( listOfMobileNotification != null && listOfMobileNotification.size() > 0){
            for(Mobile_Notification__c objMobileNotification : listOfMobileNotification){
                // added on 16 sept 2020 objMobileNotification.Is_Read__c as per discussion with nitin by ravi in order to pass is read value
                listOfNotification.add(new WebServiceModelHelper.Notification(objMobileNotification.Id,objMobileNotification.Title__c,objMobileNotification.Body__c,objMobileNotification.createddate,objMobileNotification.Is_Read__c,objMobileNotification.Isimportant__c, objMobileNotification.Image_Url__c,  objMobileNotification.Button_URL__c));
            }
        }
        objNotificationResult.notifications = listOfNotification;
        RestContext.response.statusCode = 200;
        return JSON.Serialize(objNotificationResult );
    }else{
        RestContext.response.statusCode = 400;
        return  '{"errorCode":"DATA_IS_NULL","message":"Parent id Is null"}';
    }    
}

// 7Aug: for update Notfication if we get parentid then delete related all Notification otherwise realted id record delete

public static string updateNotfication(String notificationId,string parentId){
    Savepoint sp = Database.setSavepoint();  
    try{
        if(String.isNotBlank(notificationId)){
            List<Mobile_Notification__c > listOfMobileNotification = SOQLQueryHelper.getListOfMobileNotification(notificationId);
            if(listOfMobileNotification != null && listOfMobileNotification.size() > 0 ){
                Mobile_Notification__c objMobileNotification  = new Mobile_Notification__c(Deleted_by_user__c = true,id = listOfMobileNotification[0].Id); 
                update objMobileNotification ; 
                RestContext.response.statusCode = 200;
                return '{"errorCode":"SUCCESS","message":"Mobile Notifications is Deleted Successfully"}';
            }else{
                RestContext.response.statusCode = 400;
                return  '{"errorCode":"DATA_NOT_FOUND","message":"Notification Records not found"}';
            }
        }else If(String.isNotBlank(parentId)){
            List<Mobile_Notification__c > listOfMobileNotification = SOQLQueryHelper.getListOfParentMobileNotification(parentId);
            if(listOfMobileNotification != null && listOfMobileNotification.size() > 0){
                for(Mobile_Notification__c objMobileNotification : listOfMobileNotification){
                    objMobileNotification.Deleted_by_user__c = true;
                }
                update listOfMobileNotification;
                RestContext.response.statusCode = 200;
                return '{"errorCode":"SUCCESS","message":"All Mobile Notifications are  Deleted Successfully"}';
            }else{
                RestContext.response.statusCode = 400;
                return  '{"errorCode":"DATA_NOT_FOUND","message":"Notification Records not found"}';
            }
        }else{
            RestContext.response.statusCode = 400;
            return  '{"errorCode":"DATA_IS_NULL","message":"Id parameter are null"}';
        }
    }catch(Exception e){
        system.debug('@@@e.getMessage()'+e.getMessage());
        Database.rollback(sp);
        RestContext.response.statusCode = 500;
        return '{"errorCode":"INTERNAL_ERROR","message":"' + e.getMessage()+'"}';
    }
}

public account accountobj{get;set;}
public Account getobjAccount() {
    list<Account> listOfaccount =[Select Centre_Phone_Formula__c,Centre_Address_Formula__c,Centre_Email_Formula__c from Account Where Id =: accountobj.Id];
    if(listOfaccount != null && listOfaccount.size() >0 )
        return listOfaccount[0];
    return new Account();
}

public String getAutoGeneratedCode(){
    
    list<Account> accountList  =  [SELECT id,Name,PersonEmail 
                                    FROM Account 
                                    WHERE Id =: accountobj.Id];
    if(accountList.size() > 0 && accountList  != null){
        // get Mobile_Api_Emails__c custom setting 
        Map<String,Mobile_Api_Emails__c> mapOfMobileApiEmail = Mobile_Api_Emails__c.getall();
        // check email Id is exist or not
        if(mapOfMobileApiEmail != null
            &&  mapOfMobileApiEmail.size() > 0 
            && mapOfMobileApiEmail.containsKey(accountList[0].PersonEmail)){
                System.debug(mapOfMobileApiEmail.get(accountList[0].PersonEmail).Auto_Generate_Code__c);
                return mapOfMobileApiEmail.get(accountList[0].PersonEmail).Auto_Generate_Code__c;
            }
    }
    
    return '';
}

// get Booking History
public static String getBookingHistory(String bookingId){
    Map<id,Booking__c> mapOfBooking = new Map<id,Booking__c>(SOQLQueryHelper.getListOfBookingWithId(bookingId));
    List<Booking__History> listOfBookingHistory = SOQLQueryHelper.getBookingHistory(bookingId);
    List<String> listOfHistory = new List<String>();
    //Map<String,portal_settings__c> mapOfPortalSettings = portal_settings__c.getall();
    List<Id> appUserIds = new List<Id>();
    For(portal_settings__c setting : [select id,name,User_Id__c from portal_settings__c]) {
        appUserIds.add(setting.User_Id__c);
    }
    WebServiceModelHelper.bookingHistoryResult bookingHistoryResult = new WebServiceModelHelper.bookingHistoryResult();
    system.debug('@@listOfBookingHistory'+listOfBookingHistory);
    for(Booking__History objBookingHistory : listOfBookingHistory){
        String bookingDetail ='';
        String fieldLabel  ='';
        Boolean isShowHistory = false; 
        boolean checkIsMakeup= false;
        String objectDataType ='';
        if(String.isNotBlank(String.valueOf(objBookingHistory.OldValue))){
            isShowHistory = validateId(String.valueOf(objBookingHistory.OldValue));
            objectDataType = String.valueOf(Schema.getGlobalDescribe().get('Booking__c').getDescribe().fields.getMap().get(objBookingHistory.Field).getDescribe().getType());
            fieldLabel =Schema.getGlobalDescribe().get('Booking__c').getDescribe().fields.getMap().get(objBookingHistory.Field).getDescribe().getLabel();
            
            // set text in history detail according to old value, new value and fiels type 
            if(String.isNotBlank(String.valueOf(objBookingHistory.NewValue))){
                bookingDetail = objBookingHistory.CreatedDate.format('dd MMM,YYYY') + ' '+ fieldLabel +' Changed from ';
                if(objectDataType.equalsIgnoreCase('DATETIME') ||objectDataType.equalsIgnoreCase('DATE')){ 
                    DateTime datevalue = DateTime.newInstance(Date.valueOf(objBookingHistory.OldValue).year(), Date.valueOf(objBookingHistory.OldValue).month(),Date.valueOf(objBookingHistory.OldValue).day());
                    bookingDetail += datevalue.format('EEE dd MMM,YYYY');
                }  else{
                    bookingDetail += String.valueOf(objBookingHistory.OldValue);
                }
                bookingDetail +=  ' to ';
                if(objectDataType.equalsIgnoreCase('DATETIME') ||objectDataType.equalsIgnoreCase('DATE')){ 
                    DateTime datevalue = DateTime.newInstance(Date.valueOf(objBookingHistory.NewValue).year(), Date.valueOf(objBookingHistory.NewValue).month(),Date.valueOf(objBookingHistory.NewValue).day());
                    bookingDetail += datevalue.format('EEE dd MMM,YYYY');
                }  else{
                    bookingDetail += String.valueOf(objBookingHistory.NewValue);
                }
                bookingDetail += (fieldLabel.equalsIgnoreCase('Available Make-up mins.') ? ' mins.':'.'); 
            }else{
                bookingDetail = objBookingHistory.CreatedDate.format('dd MMM,YYYY') + ' Deleted ';
                if(objectDataType.equalsIgnoreCase('DATETIME') ||objectDataType.equalsIgnoreCase('DATE')){ 
                    DateTime datevalue = DateTime.newInstance(Date.valueOf(objBookingHistory.OldValue).year(), Date.valueOf(objBookingHistory.OldValue).month(),Date.valueOf(objBookingHistory.OldValue).day());
                    bookingDetail += datevalue.format('EEE dd MMM,YYYY');
                }  else{
                    bookingDetail += String.valueOf(objBookingHistory.OldValue);
                }
                bookingDetail += (fieldLabel.equalsIgnoreCase('Available Make-up mins.') ? ' mins ':' ')+'in '+fieldLabel;
            }
            if(fieldLabel.equalsIgnoreCase('Cancellation Reason')){
                isShowHistory = true;
            }
        }else if(String.isNotBlank(String.valueOf(objBookingHistory.NewValue))){
            isShowHistory = validateId(String.valueOf(objBookingHistory.NewValue));
            objectDataType = String.valueOf(Schema.getGlobalDescribe().get('Booking__c').getDescribe().fields.getMap().get(objBookingHistory.Field).getDescribe().getType());
            fieldLabel =Schema.getGlobalDescribe().get('Booking__c').getDescribe().fields.getMap().get(objBookingHistory.Field).getDescribe().getLabel();
            bookingDetail = objBookingHistory.CreatedDate.format('dd MMM,YYYY') + ' Changed '+ fieldLabel +' to ';
            system.debug('@@objectDataType'+objectDataType);
            if(objectDataType.equalsIgnoreCase('DATETIME') ||objectDataType.equalsIgnoreCase('DATE')){ 
                system.debug('@@objectDataType'+objectDataType);
                DateTime datevalue = DateTime.newInstance(Date.valueOf(objBookingHistory.NewValue).year(), Date.valueOf(objBookingHistory.NewValue).month(),Date.valueOf(objBookingHistory.NewValue).day());
                bookingDetail += datevalue.format('EEE dd MMM,YYYY');
            }else{
                bookingDetail += String.valueOf(objBookingHistory.NewValue);
            }
            bookingDetail += ' ' + (fieldLabel.equalsIgnoreCase('Available Make-up mins.') ? ' mins.':'.'); 
            system.debug('@@bookingDetail'+bookingDetail);
            if(fieldLabel.equalsIgnoreCase('Cancellation Reason')){
                isShowHistory = true;
            }
        }
        
        if(string.isBlank(fieldLabel )){
            if(mapOfBooking.containskey(objBookingHistory.ParentId)){
                if(mapOfBooking.get(objBookingHistory.ParentId).Type__c =='Make-up'){
                    System.debug('appUserIds'+appUserIds);
                    System.debug('objBookingHistory.CreatedBy.id'+objBookingHistory.CreatedBy.id);
                    if(appUserIds.contains(objBookingHistory.CreatedBy.id)){
                        bookingDetail = objBookingHistory.CreatedDate.format('dd MMM,YYYY') +' Make-up lesson was created by '+ mapOfBooking.get(objBookingHistory.ParentId).Parent__r.Name;
                    }else{
                        bookingDetail = objBookingHistory.CreatedDate.format('dd MMM,YYYY') +' Make-up lesson was created by Aureus Team';
                    }
                }
            }
        }
        if((!isShowHistory) && string.isNotBlank(bookingDetail)){
            listOfHistory.add(bookingDetail);
        }
    }
    if(listOfHistory != null && listOfHistory.size() > 0){
        bookingHistoryResult.bookingHistory =  listOfHistory;
    }
    RestContext.response.statusCode = 200;
    return JSON.Serialize(bookingHistoryResult);
}
// check paramenter is Id or not
private  static  Boolean validateId(String Idparam) {
    String id = String.escapeSingleQuotes(Idparam);
    if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)){
        return true;
    }
    return false;
}

}