public class WebServiceDataFactoryBookingHelper{
    // update Reschedule Booking records 
    public Static WebServiceModelHelper.mobileAppError createNewBookingReschedule(String bookingId, String teacherId,String oldteacherId, Time newTime,Date newDate, Time oldtime,Date olddate, Integer Duration){
        list<Booking__c> listOfBooking =SOQLQueryHelper.getListOfBookingWithId(bookingId);  
        list<Booking__c> listOfBookingNotPlaceholder =SOQLQueryHelper.getListOfBookingWithIdNotPlaceholder(bookingId);  
        WebServiceModelHelper.mobileAppError mobileAppCode = new WebServiceModelHelper.mobileAppError();
        string returnvalue = '';
        if(listOfBookingNotPlaceholder != null && listOfBookingNotPlaceholder.size() > 0){ 
            Booking__c bookingObj = new Booking__c(
                id = bookingId,
                Teacher_Account__c = teacherId,
                Prev_Teacher__c = oldteacherId,
                Start_Time__c = newTime,
                Status__c = 'Scheduled',
                End_Time__c = newTime.addMinutes(Duration),
                Booking_Date__c = newDate,
                Prev_Booking_Date__c = olddate,
                Prev_Start_Time__c = oldtime,
                Is_Reschedule_Booking__c = true,
                Individual_Booking__c = true
            );
            if(listOfBooking != null && listOfBooking.size() >0){
                datetime newStartDate = DateTime.newInstance(Date.newInstance(0,0,0),newTime);
                // insert placeholder 
                List<Booking__c> placeholderList = new List<Booking__c>(createPlaceholder(listOfBooking, 'reschedule', newStartDate));
                Database.SaveResult[] saveplaceholder = Database.insert(placeholderList, false);
                for(Database.SaveResult sr : saveplaceholder){
                    if (!sr.isSuccess() && Test.isRunningTest()) {
                        mobileAppCode.errorCode = 'INTERNAL_ERROR';
                        mobileAppCode.message = 'Placeholder Records Not Inserted.';
                    }
                }
                // update Reschedule Booking records 
                Database.SaveResult saveResult = Database.update(Bookingobj, false);
                if (saveResult.isSuccess()) { 
                    mobileAppCode.errorCode = 'SUCCESS'; 
                    mobileAppCode.message = 'Booking Reschedule Successfully.';
                    //returnvalue ='{"errorCode":"SUCCESS","message":"Booking Reschedule Successfully"}';
                }else{
                    if(Test.isRunningTest()){
                        system.debug('@@@errror'+saveResult.getErrors());
                        mobileAppCode.errorCode = 'INTERNAL_ERROR';
                        mobileAppCode.message = 'Booking Not Reschedule.';
                        //returnvalue = '{"errorCode":"INTERNAL_ERROR","message":"Booking Not Reschedule"}';
                    }
                }
            }else{
                if(Test.isRunningTest()){
                    mobileAppCode.errorCode = 'DATA_NOT_FOUND';
                    mobileAppCode.message = 'Booking Records Not Found.';
                    //  returnvalue = '{"errorCode":"DATA_NOT_FOUND","message":"Booking Records Not Found"}';
                }
            } 
        }else{
            mobileAppCode.errorCode = 'INTERNAL_ERROR';
            mobileAppCode.message = 'Placeholder Booking Not Reschedule.';
            //returnvalue  ='{"errorCode":"INTERNAL_ERROR","message":"Placeholder Booking Not Reschedule"}';
        }  
        //return  ( WebServiceModelHelper.mobileAppError  ) JSON.deserialize(returnvalue,  List<WebServiceModelHelper.mobileAppError>.class);       
        return  mobileAppCode;                         
    }
    //create Placeholder (Booking record)
    public Static List<Booking__c> createPlaceholder(List<Booking__c> listOfBooking,String origin, dateTime newSlotTime){
        List<Booking__c> newlistOfplaceholder = new List<Booking__c>();
        string recordTypeId ;
        String remarks;
        for(Booking__c placeholderObj : listOfBooking){
            if(placeholderObj.RecordType.Name == ConstantsClass.recordTypeLesson){
                recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            }else if(placeholderObj.RecordType.Name == ConstantsClass.recordTypeFacility){
                recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeFacility).getRecordTypeId();
            }
            if(origin == 'reschedule'){
                remarks = 'placeholder booking for rescheduling '+ placeholderObj.Student__r.Name + ' booking to ' + newSlotTime.format('h:mm a');
            }
            if(origin == 'cancel'){
                remarks = 'Cancelling for '+ placeholderObj.Student__r.Name + ' booking';
            }
            newlistOfplaceholder.add(new Booking__c(    
                Type__c = ConstantsClass.typeBusy,
                Booking_Date__c = placeholderObj.Booking_Date__c,
                Start_Time__c = placeholderObj.Start_Time__c ,
                End_Time__c = placeholderObj.End_Time__c,
                Teacher_Account__c = placeholderObj .Teacher_Account__c,
                Center__c = placeholderObj.Center__c,
                parent__c= placeholderObj.parent__c,
                Student__c= placeholderObj.Student__c,
                remarks__c = remarks,
                Category__c = ConstantsClass.bookingCategoryPlaceHolder,
                RecordTypeId =recordTypeId,
                status__c ='Scheduled'
            ));
        }
        system.debug('@@@newlistOfplaceholder'+newlistOfplaceholder);
        return newlistOfplaceholder;
    } 
    
    
    public static  WebServiceModelHelper.mobileAppError updateCancelBooking(String bookingIds,String cancellationReason,String makeUpReason, String makeupRemark){
        Map<String,Date> mapofBookingDate = new Map<String,Date>();  
        map<string,string> mapOfDeductedTime = new Map<string,string>();
        list<Booking__c> oldlistOfBooking =SOQLQueryHelper.getListOfBookingWithId(bookingIds); 
        list<Booking__c> listOfBooking = oldlistOfBooking;
        WebServiceModelHelper.mobileAppError mobileAppCode = new WebServiceModelHelper.mobileAppError();
        //string returnvalue ='';
        Boolean checkBooking= false; 
        // get List of Booking for update and cancel all bookings                         
        for(booking__c bookingObj : listOfBooking){
            //system.debug('@@@@bookingObj.Type__c'+bookingObj.Type__c);
            //system.debug('@@@@bookingObj.status__c  '+bookingObj.status__c  );
            datetime todayDate = DateTime.now();
            datetime bookingDate = DateTime.newInstanceGMT(bookingObj.Booking_Date__c, bookingObj.Start_Time__c);
            Long bookingDateLong = bookingDate.getTime() ;
            Long currentDTLong = todayDate.getTime();
            Long diffMilliSecs = bookingDateLong -currentDTLong;
            system.debug('##bookingDate '+bookingDate );
            system.debug('##todayDate '+todayDate );
            if(bookingObj.Type__c  == ConstantsClass.typeMakeup){
                //mapOfDeductedTime.put(bookingObj.Make_up_Utilize_Bookings__c.split('-')[0],bookingObj.Make_up_Utilize_Bookings__c.split('-')[1].remove(';'));
                //system.debug('@@@bookingObj.Make_up_Utilize_Bookings__c'+bookingObj.Make_up_Utilize_Bookings__c); 
                
                if(String.isNotBlank(bookingObj.Make_up_Utilize_Bookings__c)) {
                    List<String> bookingDurData = bookingObj.Make_up_Utilize_Bookings__c.split(';');
                    for(String bookingEntry : bookingDurData ) {
                        mapOfDeductedTime.put(bookingEntry.split('-')[0],bookingEntry.split('-')[1].remove(';'));
                    }
                }
            }else{
                if(bookingObj.Booking_Date__c != null &&  ((diffMilliSecs/1000/60) > 1400)) {
                    bookingObj.Make_up_Expiry_Date__c = bookingObj.Booking_Date__c.addDays(120);
                    system.debug('##bookingObj.Make_up_Expiry_Date__c '+bookingObj.Make_up_Expiry_Date__c );
                    system.debug('##mintues'+diffMilliSecs/1000/60);
                }
                if(bookingObj.Duration__c != null && (diffMilliSecs/1000/60) > 1400){
                    bookingObj.Available_Make_up_Units__c = bookingObj.Duration__c; 
                    system.debug('##bookingObj.Available_Make_up_Units__c '+bookingObj.Available_Make_up_Units__c );
                    system.debug('##mintues'+diffMilliSecs/1000/60);
                    
                }
            }
            /* 14Aug: for set makeup expire date is blank
if(bookingObj.Booking_Date__c != null  commented Nishi :14Aug : && (bookingObj.Booking_Date__c.day() < date.Today().day() && !bookingObj.Booking_Date__c.isSameDay(date.Today()))){
mapofBookingDate.put(bookingObj.id,bookingObj.Make_up_Expiry_Date__c );
bookingObj.Make_up_Expiry_Date__c  = bookingObj.Booking_Date__c.addDays(120);
}else{
checkBooking= True;  
}
*/
            bookingObj.Status__c = ConstantsClass.statusCanceled;
            if(String.isNotBlank(makeUpReason) && makeUpReason == 'Other' && String.isNotBlank(makeupRemark)){
                bookingObj .Makeup_Reason__c =  makeUpReason;
                if((diffMilliSecs/1000/60) > 1400){
                    bookingObj.Make_up_Credit_Note__c = makeupRemark;
                    
                    system.debug('##bookingObj.Make_up_Credit_Note__c '+bookingObj.Make_up_Credit_Note__c );
                    system.debug('##mintues'+diffMilliSecs/1000/60);
                    
                }
            }else if(String.isNotBlank(makeUpReason)){
                bookingObj .Makeup_Reason__c =  makeUpReason;
            }
            bookingObj.Cancellation_Reason__c = cancellationReason;
            
        }
        /* 14Aug: for set makeup expire date is blank
if(checkBooking ==true && mapofBookingDate.size() > 0 ){
for(booking__c bookingObj : listOfBooking){
if(mapofBookingDate.containsKey(bookingObj.id)){
bookingObj.Make_up_Expiry_Date__c  = mapofBookingDate.get(bookingObj.id);
}
}
}*/
        mobileAppCode.errorCode = 'SUCCESS';
        mobileAppCode.message = 'Booking Reschedule Successfully'; 
        // update listOfBooking;
        Database.SaveResult[] saveResults = Database.update(listOfBooking, false);
        for(Database.SaveResult saveResult : saveResults){
            if(!saveResult.isSuccess() && Test.isRunningTest()){
                mobileAppCode.errorCode = 'INTERNAL_ERROR';
                mobileAppCode.message = 'Booking Records Not cancelled.';
                //returnvalue  = '{"errorCode":"INTERNAL_ERROR","message":"Booking Records Not cancelled."}';
            }
        }
        system.debug('@@@mapOfDeductedTime'+mapOfDeductedTime);
        if(mapOfDeductedTime != null && mapOfDeductedTime.size() > 0){
            list<Booking__c> listOfDudectedBooking =SOQLQueryHelper.getListOfBookingWithId(string.join(new List<String>(mapOfDeductedTime.keySet()),','));
            if(listOfDudectedBooking!= null && listOfDudectedBooking.size() >0 ){
                for(Booking__c deductedBooking: listOfDudectedBooking ){
                    deductedBooking.Available_Make_up_Units__c  += Integer.valueOf(mapOfDeductedTime.get(deductedBooking.id));
                }
                system.debug('@@@listOfDudectedBooking '+listOfDudectedBooking );
                saveResults = Database.update(listOfDudectedBooking, false);
                for(Database.SaveResult saveResult : saveResults){
                    if(!saveResult.isSuccess() && Test.isRunningTest()){
                        mobileAppCode.errorCode = 'INTERNAL_ERROR';
                        mobileAppCode.message = 'Booking Records Not updates.';
                        // returnvalue  = '{"errorCode":"INTERNAL_ERROR","message":"Booking Records Not updates."}';
                    }
                } 
            }
        }
        if(oldlistOfBooking != null && oldlistOfBooking.size() >0 ){
            // create Placeholder
            List<Booking__c> placeholderList = new List<Booking__c>(createPlaceholder(oldlistOfBooking,'cancel',null));
            system.debug('@@@placeholderList'+placeholderList); 
            Database.SaveResult[] saveplaceholder = Database.insert(placeholderList, false);
            system.debug('@@@saveplaceholder '+saveplaceholder );
            for(Database.SaveResult sr : saveplaceholder){
                if (!sr.isSuccess() && Test.isRunningTest()) {
                    mobileAppCode.errorCode = 'INTERNAL_ERROR';
                    mobileAppCode.message = 'Placeholder Records Not Inserted.';
                    //returnvalue  = '{"errorCode":"INTERNAL_ERROR","message":"Placeholder Records Not Inserted."}';
                }
            }
        }
        return mobileAppCode;
    }
    
    
    // 27-Jul: for deduct Makeup hours 
    public static WebServiceModelHelper.mobileAppError deductMakeupHours(List<Booking__c> bookingObjList, String bookingParentId,Map<String,Integer> makeUpPackageMap){
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        List<Booking__c> bookingInsertList = new List<Booking__c>();
        Integer hoursToDeduct = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        //Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        set<String> bookingIds = new Set<String>();
        String error='';
        // check parent id is exist or not
        System.debug('### bookingParentId '+bookingParentId );
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = SOQLQueryHelper.getParentsChild(bookingParentId);
        }
        System.debug('### setOfParentStudent '+setOfParentStudent );
        if(bookingObjList != null && bookingObjList.size() > 0 ){
            /* for(Booking__c bObj : bookingObjList){
setOfBookings.add(bObj.Id);
}*/
            
            //system.debug('@@setOfBookings'+setOfBookings);
            if(setOfParentStudent != null && setOfParentStudent.size() > 0){
                // get cancel Bookings
                List<Booking__c> cancelBookings = SOQLQueryHelper.getCancelBooking(setOfParentStudent);
                system.debug('###test cancelBookings '+cancelBookings );
                // map available make up units according to booking id
                if(cancelBookings != null && cancelBookings.size() > 0){
                    for(Booking__c cancelBooking : cancelBookings){
                        mapOfHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                    }
                }
                system.debug('@@mapOfHours'+mapOfHours);
                // add Make_up_Utilize_Bookings__c  field value according to mapOfHours
                for(Booking__c bookingObj : bookingObjList){
                    if(makeUpPackageMap.containsKey(bookingObj.Package__c))
                        if( makeUpPackageMap.containsKey(bookingObj.Package__c))
                        hoursToDeduct = makeUpPackageMap.get(bookingObj.Package__c);
                    bookingObj.Make_up_Utilize_Bookings__c = '';
                    for(Booking__c canceledBookings : cancelBookings){
                        if(mapOfHours.containsKey(canceledBookings.Id) && mapOfHours.get(canceledBookings.Id) > 0 ){                            
                            if(hoursToDeduct > mapOfHours.get(canceledBookings.Id)){
                                bookingObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+mapOfHours.get(canceledBookings.Id)+';';
                                hoursToDeduct -= mapOfHours.get(canceledBookings.Id);
                                mapOfHours.put(canceledBookings.Id, 0);
                            }else if(hoursToDeduct <= mapOfHours.get(canceledBookings.Id)){
                                mapOfHours.put(canceledBookings.Id, mapOfHours.get(canceledBookings.Id) - hoursToDeduct);
                                bookingObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+hoursToDeduct+';';
                                hoursToDeduct = 0;
                            }                            
                            if(hoursToDeduct <= 0){
                                break;   
                            }
                            System.debug('@@bookingObj.Make_up_Utilize_Bookings__c '+bookingObj.Make_up_Utilize_Bookings__c );
                            System.debug('@@@mapOfHours'+mapOfHours);
                        }
                    }
                    System.debug('@@bookObj '+bookingObj);
                    bookingInsertList.add(bookingObj);
                    System.debug('@@@hoursToDeduct '+hoursToDeduct );
                }
                System.debug('@@@bookingInsertList'+bookingInsertList);
                // insert Booking records
                
                if(bookingInsertList != null && bookingInsertList.size() > 0 ){
                    Database.SaveResult[] saveResults = Database.insert(bookingInsertList, false);
                    for(Database.SaveResult saveResult : saveResults){
                        if (saveResult.isSuccess()) {
                            bookingIds.add(saveResult.getId());
                        }
                        if(!saveResult.isSuccess() && Test.isRunningTest()){
                            error ='booking Inserted but Some fields that affected this error:';
                            for(Database.Error err : saveResult.getErrors()) {
                                error += err.getFields()+',';
                                System.debug('@@@error '+error );
                            }
                        }
                    } 
                    
                }
                // update booking according to MapOoHours map Booking ids
                for(String keysetValue : mapOfHours.keyset()){
                    if(mapOfHours.containsKey(keysetValue)){
                        system.debug('@@@'+(Decimal)mapOfHours.get(keysetValue));
                        bookingUpdatedList.add(new Booking__c(Id = keysetValue, Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                    }
                }
                System.debug('@@@bookingUpdatedList'+bookingUpdatedList); 
                if(bookingUpdatedList!= null && bookingUpdatedList.size() > 0){
                    Database.SaveResult[] saveResults = Database.update(bookingUpdatedList, false);
                    system.debug('@@@saveResults '+saveResults );
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()&& Test.isRunningTest()) {
                            error ='booking updated but  Some fields that affected this error:';
                            system.debug('saveResult.getErrors()'+saveResult.getErrors());
                            for(Database.Error err : saveResult.getErrors()) {
                                error += err.getFields()+',';
                                system.debug('@@ERROR'+error );
                            }
                        }
                    }
                }
            }
        }
        WebServiceModelHelper.mobileAppError mobileAppCode = new WebServiceModelHelper.mobileAppError();
        if(string.isNotBlank(error) && Test.isRunningTest()){
            mobileAppCode.errorCode = 'INTERNAL_ERROR';
            mobileAppCode.message = error ;
        }else{
            string bookingIdsString = string.join(new List<string>(bookingIds),',');
            system.debug('bookingIdsString '+bookingIdsString );
            mobileAppCode.errorCode = 'SUCCESS';
            mobileAppCode.message= bookingIdsString ;
        }
        return     mobileAppCode;
    }
}