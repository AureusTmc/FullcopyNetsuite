/*
Name        :    BookingTriggerHelper
Date        :    16 April 2019
Author      :

*/
public class BookingTriggerHelper{
    //@Jatin Commented as per new requirement of Fifth Lesson
    /*public static void processFifthBookingCancellation(Set<String> setOfFifthBookingIds){
        List<Invoice__c> listOfInvoices = new List<Invoice__c>();
        for(Invoice_Line_Item__c objLineItem : [SELECT Invoice__c, Invoice__r.Status__c FROM Invoice_Line_Item__c WHERE 
                                                Booking__c IN : setOfFifthBookingIds AND 
                                                Invoice__r.Status__c = :ConstantsClass.dueStatus]){
            Invoice__c objInv = new Invoice__c(Id = objLineItem.Invoice__c, Status__c = ConstantsClass.voidInvoiceStatus, Remarks__c = 'Adhoc/5th Booking Cancelled');
            listOfInvoices.add(objInv);
        }
        if(listOfInvoices.size() > 0){
            UPDATE listOfInvoices;
        }
    }*/
    
    public static void processTrialRescheduleBookings(List<Booking__c> listOfBookings){
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        for(Booking__c objBooking : listOfBookings){
            Enrolment__c objEnrol = new Enrolment__c(Id = objBooking.enrolment__c);
            objEnrol.Trial_Start_Time__c = objBooking.Start_time__c;
            objEnrol.Trial_Date__c = objBooking.Booking_Date__c;
            objEnrol.Teacher__c = objBooking.Teacher_Account__c;
            listOfEnrolment.add(objEnrol);
        }
        System.debug('listOfEnrolment '+listOfEnrolment);
        if(listOfEnrolment.size() > 0){
            UPDATE listOfEnrolment;
        }
    }
    
    public static void populatePrentInBooking(List<Booking__c> listOfBookings){
        List<Booking__c> filterBooking = new List<Booking__c>();
        Map<Id, Enrolment__c> enrMap = new Map<Id, Enrolment__c>();
        
        for(Booking__c book : listOfBookings){
            if(book.Enrolment__c != null && book.Parent__c == null){
                filterBooking.add(book);
                enrMap.put(book.Enrolment__c, null);
            }
        }
        
        if(filterBooking.size() > 0 && enrMap.size() > 0){
            enrMap = new Map<Id, Enrolment__c>([SELECT Id,Parent__c FROM Enrolment__c WHERE Id IN: enrMap.keySet()]);
            
            for(Booking__c book : filterBooking){
                if(enrMap.get(book.Enrolment__c).Parent__c != null)
                    book.Parent__c = enrMap.get(book.Enrolment__c).Parent__c;
            }
        }
    }

    // start: Nishi- 4-Aug-2020: for if new booking created and resource id not found then we added resource Id using enrolment or teacher Working hrs.
    public static void populateResourceInBooking(List<Booking__c> listOfBookings){
        Set<string> bookingType = new Set<string>{ConstantsClass.bookTypeRegular,ConstantsClass.typeMakeup,ConstantsClass.typeAdhoc,ConstantsClass.typeTrial};
        
        List<Booking__c> filterEnrolmentBooking = new List<Booking__c>();
        Map<Id, Enrolment__c> enrMap = new Map<Id, Enrolment__c>();
        Map<string, List<Teacher_Working_Hour__c>> mapOfTeachWorkHrs = new Map<string, List<Teacher_Working_Hour__c>>();
        Set<String> teacherIds = new Set<String>();
        Set<String> centerIds = new Set<String>();
        Set<String> bookingDays = new  Set<String> ();
        List<Booking__c> filterTeacherBooking = new List<Booking__c>();
        for(Booking__c book : listOfBookings){
            system.debug('###book'+book);
            system.debug('###book.Lesson_Type__c'+book.Lesson_Type__c);
            if(string.IsNotBlank(book.Enrolment__c)){
                enrMap.put(book.Enrolment__c, null);
            }
            if(string.IsBlank(book.Resource__c)){
                if(string.IsNotBlank(book.Enrolment__c)){
                    filterEnrolmentBooking.add(book);
                    enrMap.put(book.Enrolment__c, null);
                }else if(string.IsNotBlank(book.Teacher_Account__c) && book.Booking_Date__c != null && book.Start_Time__c != null){
                    filterTeacherBooking.add(book);
                    teacherIds.add(book.Teacher_Account__c);
                    centerIds.add(book.Center__c);
                    bookingDays.add(DateTime.newInstance(book.Booking_Date__c, book.Start_Time__c).format('EEE'));
                }
            }
        }
        system.debug('enrMap'+enrMap);
        system.debug('filterEnrolmentBooking'+filterEnrolmentBooking);
        if(enrMap.size() > 0){
            enrMap = new Map<Id,Enrolment__c>([SELECT Id,Resource__c,Lesson_Mode__c,Online_Lesson_URL__c,Online_Lesson_Passcode__c FROM Enrolment__c WHERE Id IN: enrMap.keySet()]);
            //start-5-aug-2020: for we lessonmode is blank then we udpate Lesson mode and lesson url or passcode according to Enrolment 
            for(Booking__c book : listOfBookings){
                if(string.IsNotBlank(book.Enrolment__c)){
                    if(string.isBlank(book.Lesson_Type__c)){
                        string lessonMode =enrMap.get(book.Enrolment__c).Lesson_Mode__c;
                        book.Lesson_Type__c= string.isNotBlank(lessonMode)?lessonMode:ConstantsClass.InCentre;// nishi :4 -aug-2020:for set default Lesson type  is In center
                    }
                    if(string.isBlank(book.Online_Lesson_URL__c) && string.isBlank(book.Online_Lesson_Passcode__c)){
                        if(book.Lesson_Type__c == ConstantsClass.Online){
                            book.Online_Lesson_URL__c=enrMap.get(book.Enrolment__c).Online_Lesson_URL__c;
                            book.Online_Lesson_Passcode__c= enrMap.get(book.Enrolment__c).Online_Lesson_Passcode__c; 
                        }else if(book.Lesson_Type__c ==ConstantsClass.InCentre){
                            book.Online_Lesson_URL__c='';
                            book.Online_Lesson_Passcode__c='';
                        }
                    }
                }
                system.debug('book'+book);
            }
            //end-5-aug-2020: for we lessonmode is blank then we udpate Lesson mode and lesson url or passcode according to Enrolment 
            if(filterEnrolmentBooking.size() > 0){
                for(Booking__c book : filterEnrolmentBooking){
                    if(bookingType.contains(book.Type__c)){
                        if(string.IsNotBlank(enrMap.get(book.Enrolment__c).Resource__c)){
                            book.Resource__c = enrMap.get(book.Enrolment__c).Resource__c;
                        }else{
                            filterTeacherBooking.add(book);
                            teacherIds.add(book.Teacher_Account__c);
                            centerIds.add(book.Center__c);
                            bookingDays.add(DateTime.newInstance(book.Booking_Date__c, book.Start_Time__c).format('EEE'));
                        }
                    }
                }
            }
        }
        system.debug('centerIds'+centerIds);
        system.debug('teacherIds'+teacherIds);
        system.debug('bookingDays'+bookingDays);
        system.debug('filterTeacherBooking'+filterTeacherBooking);
        List<Teacher_Working_Hour__c> listOfTeacerWorkingHrs = new List<Teacher_Working_Hour__c>();
        if(filterTeacherBooking != null && filterTeacherBooking.size() > 0){
           
            for(Teacher_Working_Hour__c  objTeacerHrs :  [SELECT Active__c, Break_Time__c, Center_Name__c, End_Time__c, 
                                                        Remarks__c, Start_Time__c, 
                                                        Teacher_Name__c, Working_Day__c, Is_Booking_Booking_created__c, 
                                                        Centre__c, Resource__c, Name, Id FROM Teacher_Working_Hour__c
                                                        Where Active__c = true
                                                        And Break_Time__c = false
                                                        And Center_Name__c In:centerIds
                                                        And Teacher_Name__c in:teacherIds
                                                        And Working_Day__c in:bookingDays]){
                listOfTeacerWorkingHrs = new List<Teacher_Working_Hour__c>();
                if(mapOfTeachWorkHrs.containsKey(objTeacerHrs.Teacher_Name__c)){
                    listOfTeacerWorkingHrs =  mapOfTeachWorkHrs.get(objTeacerHrs.Teacher_Name__c);
                }
                listOfTeacerWorkingHrs.add(objTeacerHrs);
                mapOfTeachWorkHrs.put(objTeacerHrs.Teacher_Name__c,listOfTeacerWorkingHrs);
            }
            system.debug('mapOfTeachWorkHrs'+mapOfTeachWorkHrs);
            if(mapOfTeachWorkHrs != null && mapOfTeachWorkHrs.size() >0){
                for(Booking__c objBooking : filterTeacherBooking){
                    if(bookingType.contains(objBooking.Type__c)){
                        if(mapOfTeachWorkHrs.containsKey(objBooking.Teacher_Account__c)){
                            listOfTeacerWorkingHrs = mapOfTeachWorkHrs.get(objBooking.Teacher_Account__c);
                            for(Teacher_Working_Hour__c  objTeacerHrs :listOfTeacerWorkingHrs){
                                string bookingDay =DateTime.newInstance(objBooking.Booking_Date__c, objBooking.Start_Time__c).format('EEE');
                                if(bookingDay == objTeacerHrs.Working_Day__c &&
                                objBooking.Center__c == objTeacerHrs.Center_Name__c &&
                                objBooking.Start_Time__c >= objTeacerHrs.Start_Time__c
                                && objBooking.End_Time__c <= objTeacerHrs.End_Time__c){
                                    objBooking.Resource__c = objTeacerHrs.Resource__c;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // end: Nishi- 4-Aug-2020: for if new booking created and resource id not found then we added resource Id using enrolment or teacher Working hrs.
    
    //################### Added on 25 June 2019 By Karan Singh Soni ########################
    //#################### create a note for new Booking ###################################
    public static void createNoteForFreshBooking( map< Id, Booking__C> triggerNewMap ){
        
        Map< Id,ContentNote > mapNoteToAttch = new Map< Id,ContentNote >(); //map which include booking id and ContentNote object
        list< ContentDocumentLink > listContntDocLink = new list< ContentDocumentLink >(); 
        Map<contentDocumentLink,ContentNote> dataMap = new Map<contentDocumentLink,contentNote>();
        List<ContentNote> cnList = new List<ContentNote>();
        for( Booking__c objBook : [SELECT Id, Type__c, Student__r.Gender__c,Student__r.PersonBirthdate,Student__r.Learning_Style__C,Enrolment__r.Previous_Experience_if_any__c
                                   FROM Booking__c 
                                   WHERE Id IN :triggerNewMap.keySet() 
                                   AND Type__c = 'Trial'
                                   AND Enrolment__r.Type__c = 'Trial' 
                                   AND Enrolment__r.Stage__c = 'Requested']){
                                       ContentNote contntNoteObj = new ContentNote();
                                       contntNoteObj.Title = 'New Booking';
                                       String body = 'Gender : ' + objBook.Student__r.Gender__c + ',BirthDay : ' + objBook.Student__r.PersonBirthdate + ',Learning Style : ' + objBook.Student__r.Learning_Style__C + ',Previous experience if any : ' + objBook.Enrolment__r.Previous_Experience_if_any__c;
                                       contntNoteObj.Content = Blob.valueOf(body.escapeHTML4());
                                       //contntNoteObj.OwnerId = '0056F00000CWPTV';
                                       cnList.add(contntNoteObj);
                                       mapNoteToAttch.put(objBook.Id,contntNoteObj);
                                       /*
                                       ContentDocumentLink docLink = new ContentDocumentLink();
                                       docLink.LinkedEntityId = objBook.Id;
                                       docLink.ShareType = 'V';
                                       docLink.Visibility = 'AllUsers';
                                       dataMap.put(docLink,contntNoteObj);*/
                                   }
        system.debug('current user'+ userInfo.getUserId());
        system.debug('>>>>>>>>>>before>>>>>>>>>>>..'+cnList);
        /*if( cnList.size() > 0 ){
            database.saveResult[] ds =  database.insert(cnList);
            system.debug('cnList-->'+cnList[0].OwnerId);
            system.debug('current user-->'+userInfo.getUserId());
            for(Database.SaveResult sr : ds) {
                if (sr.isSuccess()) {
                    system.debug('>>>>>>>>>>success>>>>>>>>>>>..'+sr.getid());
                }
                else {               
                    for(Database.Error err : sr.getErrors()) {                    
                        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>error>>>>>>>>>>>>'+err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>' + err.getFields());
                    }
                }
            }/*
                system.debug('>>>>>>>>>>after>>>>>>>>>>>..'+cnList);
            /*
            for(contentDocumentLink cdl : dataMap.keyset()){
                system.debug('>>>>>>>>>>list of contentNote>>>>>>>>>>>..'+cdl);
                system.debug('>>>>>>>>>>dataMap.get(cdl)>>>>>>>>>>>..'+dataMap.get(cdl));
            }*/
            //system.debug('>>>>>>>>>>list of contentNote>>>>>>>>>>>..'+mapNoteToAttch.values());
            /*for( Id objBookId : mapNoteToAttch.keySet() ){
                ContentDocumentLink link2 = new ContentDocumentLink();
                link2.ContentDocumentId = mapNoteToAttch.get(objBookId).Id;
                link2.LinkedEntityId = objBookId;
                link2.ShareType = 'V';
                link2.Visibility = 'AllUsers';
                listContntDocLink.add( link2 );
            }
            system.debug('>>>>>>>>>>list of listContntDocLink>>>>>>>>>>>..'+listContntDocLink);
            if( listContntDocLink.size() > 0 )
                //insert listContntDocLink;

        }*/
    }
    //@Nishi (Date 22-7-2019), This process is used to Cancel Booking Notification.		
    public static void processCancelBooking(Map<String,String> mapOfCancelBookings){
        system.debug('@@@mapOfCancelBookings'+mapOfCancelBookings);
        List<MobileNotificationWrapper> notifications = new List<MobileNotificationWrapper>();		
        Map<String,String> parentTokens = new Map<String,String>();		
        For(Account acc: [SELECT id,FCM_Token__c from Account where Id in:mapOfCancelBookings.values() AND FCM_Token__c !=null]){		
            parentTokens.put(acc.id,acc.FCM_Token__c );		
        }		
        system.debug('@@parentTokens'+parentTokens);
        map<id,User> mapOfuser =new map<id,User>([select id,name ,profile.name from user where profile.name='aureusacademy Profile']);		
        for(Booking__c bookingObj : [ SELECT id,Enrolment__r.Stage__c, Booking_Date__c,Instrument__c, Student__r.Name,Cancellation_Reason__c,  start_time__c, Parent__c,		
                                     Teacher_Account__r.firstName		
                                     FROM booking__c		
                                     WHERE id IN: mapOfCancelBookings.keyset()		
                                     AND LastModifiedById NOT IN:mapOfuser.keyset()]){		
                                         try{		
                                             system.debug('@@bookingObj.Enrolment__r.Stage__c'+bookingObj .Enrolment__r.Stage__c);		
                                             Datetime StartTime = Datetime.newInstance(Date.today(), bookingObj.start_time__c);		
                                             DateTime BookingDate = DateTime.newInstance(bookingObj.Booking_Date__c.year(), bookingObj.Booking_Date__c.month(),bookingObj.Booking_Date__c.day());		
                                             String title ='';		
                                             String bodymsg ='';		
                                             String to = '';		
                                             //system.debug('@@bookingObj.Cancellation_Reason__c'+bookingObj.Cancellation_Reason__c);		
                                             if(bookingObj.Enrolment__r.Stage__c == ConstantsClass.enroledStatus){		
                                                 String instrument = String.IsNotBlank(bookingObj.instrument__c) ? bookingObj.instrument__c :'Make-up';		
                                                 if(String.isNotBlank(bookingObj.Cancellation_Reason__c) && bookingObj.Cancellation_Reason__c.equalsIgnoreCase('Teacher MC')){		
                                                     		
                                                     system.debug('@@bookingObj.Cancellation_Reason__c'+bookingObj.Cancellation_Reason__c);   		
                                                     title = bookingObj.Student__r.Name+'\'s Lesson Cancelled - Teacher Sick' ;		
                                                     bodymsg = bookingObj.Student__r.Name + '\'s '+instrument+' lesson on ' +		
                                                         + BookingDate.format('dd, MMM') +' ' +StartTime.format('h:mm a') +		
                                                         ' has been cancelled as teacher '+ bookingObj.Teacher_Account__r.firstName + 		
                                                         ' is sick. The make-up credit has been added your account and we apologise for any inconvenience caused! Please view the lesson details page for more details.';		
                                                     		
                                                 }else{		
                                                     		
                                                     system.debug('@@bookingObj.Cancellation_Reason__c'+bookingObj.Cancellation_Reason__c);		
                                                     title = instrument +' Lesson Cancelled';		
                                                     bodymsg = bookingObj.Student__r.Name + '\'s '+ instrument +' lesson has been cancelled on '		
                                                         +BookingDate.format('dd, MMM') +' '+		
                                                         StartTime.format('h:mm a')+'. Please view the lesson details page for more details.';		
                                                 }		
                                                 		
                                                 if(parentTokens.containsKey(bookingObj.Parent__c)){		
                                                     to = parentTokens.get(bookingObj.Parent__c);		
                                                     notifications.add(new MobileNotificationWrapper(bookingObj.Parent__c, to, title, bodymsg));		
                                                 }		
                                                 		
                                             }		
                                         }catch(Exception e){}		
                                     }	
        system.debug('@@@notifications'+notifications);
        system.debug('@@@notifications'+notifications.size());
        if(notifications.size() > 0 && !System.isBatch() && !System.isFuture()) {		
            Database.executeBatch(new SendMobileNotificationBatch(notifications),90);		
        }		
    }		
    		
    		
    //@Nishi (Date 25-7-2019), This process is used to scheduled booiking Notification.		
    public static void procesScheduledBooking(Map<String,String> mapOfscheduledBookings ){		
        List<MobileNotificationWrapper> notifications = new List<MobileNotificationWrapper>();		
        Map<String,String> parentTokens = new Map<String,String>();		
        For(Account acc: [SELECT id,FCM_Token__c from Account where Id in: mapOfscheduledBookings.values() AND FCM_Token__c !=null]){		
            parentTokens.put(acc.id,acc.FCM_Token__c );		
        }		
        		
        map<id,User> mapOfuser =new map<id,User>([select id,name ,profile.name from user where profile.name='aureusacademy Profile']);		
        for(Booking__c bookingObj : [ SELECT id,Enrolment__r.Stage__c, Booking_Date__c,Instrument__c, Student__r.Name,Cancellation_Reason__c,  start_time__c, Parent__c,		
                                     Teacher_Account__r.name,Prev_Booking_Date__c,Prev_Start_Time__c		
                                     FROM booking__c		
                                     WHERE id IN: mapOfscheduledBookings.keyset()		
                                     AND LastModifiedById NOT IN:mapOfuser.keyset()]){		
                                         try{		
                                             if(parentTokens.containsKey(bookingObj.Parent__c)){		
                                                 Datetime startTime = Datetime.newInstance(Date.today(), bookingObj.start_time__c);		
                                                 DateTime bookingDate = DateTime.newInstance(bookingObj.Booking_Date__c.year(), bookingObj.Booking_Date__c.month(),bookingObj.Booking_Date__c.day());		
                                                 Datetime preStartTime = Datetime.newInstance(Date.today(), bookingObj.Prev_Start_Time__c);		
                                                 DateTime preBookingDate = DateTime.newInstance(bookingObj.Prev_Booking_Date__c.year(), bookingObj.Prev_Booking_Date__c.month(),bookingObj.Prev_Booking_Date__c.day());		
                                                 		
                                                 String instrument = String.IsNotBlank(bookingObj.instrument__c) ? bookingObj.instrument__c :'Make-up';		
                                                 String title =  bookingObj.Student__r.Name  +' Lesson has been Rescheduled to ' + BookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a');		
                                                 String bodymsg =  bookingObj.Student__r.Name + '\'s '+ instrument + ' lesson has been rescheduled to '		
                                                     +bookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a')+		
                                                     '. This lesson was previously scheduled on '+ 		
                                                     prebookingDate.format('dd, MMM') +' '+ preStartTime.format('h:mm a')		
                                                     +'. Please view the lesson details page for more details.';		
                                                 String to = parentTokens.get(bookingObj.Parent__c);		
                                                 notifications.add(new MobileNotificationWrapper(bookingObj.Parent__c, to, title, bodymsg));		
                                             }		
                                         }catch(Exception e){}		
                                         		
                                     }		
        if(notifications.size() > 0 && !System.isBatch() && !System.isFuture()) {		
            Database.executeBatch(new SendMobileNotificationBatch(notifications),90);		
        }		
    }


     // added by Jatin:14-Feb-2020 :For calculate Camp type enrolment check Camp Id is exist or not
    // if find CampId and Camp Day id found then update 'No_of_Students_Enrolled__c' field in Camp days object
    public static void updateCampDayTotalStudent(map<String,String> mapOfCampClassAndCampDay){
        Map<String, Integer> mapOfBookingCount = new Map<String, Integer>();
        List<Camp_Days__c> campDaysList= new List<Camp_Days__c>();
        if(mapOfCampClassAndCampDay != null && mapOfCampClassAndCampDay.size() > 0){
            for(String campDaysId : mapOfCampClassAndCampDay.keySet()){
                mapOfBookingCount.put(campDaysId,0);
            }
            List<string>  bookingStatus   = new List<String>{ConstantsClass.pendingStatus,ConstantsClass.scheduledStatus};
                List<AggregateResult> AggregateResultList = [select Camp_Days__c  campDays, Count(Id) total 
                                                             FROM Booking__c  
                                                             WHERE  Camp_Id__c IN: mapOfCampClassAndCampDay.values()
                                                             And Camp_Days__c In:mapOfCampClassAndCampDay.keySet()
                                                             And Enrolment__c != null 
                                                             ANd Enrolment__r.Type__c =: ConstantsClass.enrollmentTypeCamp
                                                             AND Status__c IN:bookingStatus
                                                             GROUP BY Camp_Days__c ];
            for(AggregateResult result : AggregateResultList){
                mapOfBookingCount.put(String.valueOf(result.get('campDays')), (Integer)result.get('total'));
            }
            system.debug('@@@mapOfBookingCount'+mapOfBookingCount);
            if(mapOfBookingCount != null && mapOfBookingCount.size() > 0){
                for(String campId : mapOfBookingCount.keySet()){
                    campDaysList.add(new Camp_Days__c(Id = campId, No_of_Students_Enrolled__c = mapOfBookingCount.get(campId)));
                }
            }
            system.debug('@@@campDaysList'+campDaysList);
            
            if(campDaysList.size()>0){
                update campDaysList;
            }   
            
        }
        
    }
    
    // Added By Ravi on 29 june 2020
    public static void updateOnlineURL(List<Booking__c> bookList){
        // it basically update the Online url and Pass code value 
        List<Booking__c> updateBookingList = new List<Booking__c>();
        for(Booking__c bk:bookList){
            if(bk.Lesson_Type__c == ConstantsClass.Online || bk.Allow_Online_Guest_Joining__c==true){
                Booking__c book = new Booking__c();
                book.Id=bk.Id;
                book.Is_Lesson_Type_Change__c = False;
                book.Online_Lesson_URL__c=System.Label.Twilio_Meeting_URL+bk.Name;
                book.Online_Lesson_Passcode__c= AureusUtility.getRandomSixDigit(); 
                updateBookingList.add(book);
            }else if(bk.Lesson_Type__c ==ConstantsClass.InCentre){
                Booking__c book = new Booking__c();
                book.Id=bk.Id;
                book.Is_Lesson_Type_Change__c = False;
                book.Online_Lesson_URL__c='';
                book.Online_Lesson_Passcode__c='';
                updateBookingList.add(book);
            }
        }
        
        if(updateBookingList.size()>0 && updateBookingList != NULL){
            update updateBookingList;
        }
        
    }
    // Added By Ravi on 29 june 2020
}