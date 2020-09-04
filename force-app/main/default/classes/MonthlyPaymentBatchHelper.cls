/*
    Name        :    MonthlyPaymentBatchHelper
    Date        :    02/27/2019
    Author      :    
    Description :    
    
*/

public class MonthlyPaymentBatchHelper{

    public static Set<String> getPaymentForInvoices(List<Invoice__c> listOfInvoice){
        Set<String> successinvoiceIdSet = new Set<String>();
        List<Invoice__c> listOfInvoicesTOUpdate = new List<Invoice__c>();
        List<Invoice__c> DeclinedInvoiceList = new List<Invoice__c>();
        //List<Invoice__c> listOfInvoiceToRefund = new List<Invoice__c>();
        Set<Id> fifthBookingIdSet = new Set<Id>();
        List<Payment__c> listOfPayment = new List<Payment__c>();
        List<Stripe_Payment_Log__c> invoiceLogList = new List<Stripe_Payment_Log__c>();
        Set<String> declinedSet = new Set<String>();
        
        String paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        String payCreditRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId();    
        
        //Map Of Countries of the centre's
        Map<String, Country__c> mapOfCountries = BillingUtility.getCountryMap('');
        
        for(Stripe_Declined_Code__mdt decMdt : [Select Label From Stripe_Declined_Code__mdt]){
            declinedSet.add(decMdt.Label);
        } 
        //26-Nov-2019:jatin Send Email to the Customer if its charge gives error and the payment is not collected from his account
        list<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name 
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName ='Payment_Collection_Failed'];
        system.debug('@@listOfEmailTemplate'+listOfEmailTemplate);
        system.debug(listOfInvoice);
        List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
        for(Invoice__c objInvoice : listOfInvoice){
            Stripe_Payment_Log__c iLog = new Stripe_Payment_Log__c();
            system.debug('In loop 1');
            try{
                //Country Object to store the country object for the perticular Invoice...
                Country__c countryObj = new Country__c();
                if(mapOfCountries.containsKey(objInvoice.Center__r.Country__c)){
                    countryObj = mapOfCountries.get(objInvoice.Center__r.Country__c);
                }
                System.debug('In Loop');
                if(objInvoice.Balance_Amount__c >= 0.30 && String.isNotBlank(countryObj.Id) && String.isNotBlank(countryObj.Currency_Code__c) 
                    && String.isNotBlank(countryObj.Stripe_Base_Url__c) && String.isNotBlank(countryObj.Stripe_Secret_Key__c)){
                    BillingUtility.StripeCharge objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(
                                                                    objInvoice.Parent_Account__r.Stripe_Customer_Id__c,
                                                                    objInvoice.Balance_Amount__c, countryObj.Currency_Code__c,
                                                                    objInvoice.Name, countryObj.Stripe_Base_Url__c, 
                                                                    countryObj.Stripe_Secret_Key__c);
                    System.debug('@@@objStripeCharge'+objStripeCharge);
                    if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                        objInvoice.status__c = ConstantsClass.paidStatus;
                        listOfInvoicesTOUpdate.add(objInvoice);
                        successinvoiceIdSet.add(objInvoice.Id);
                        
                        if(objInvoice.Subscription__c == null){
                            fifthBookingIdSet.add(objInvoice.Id);
                        }
                        
                        Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, objInvoice.Balance_Amount__c,
                                                                        ConstantsClass.successStatus); 
                        objPayment.Transaction_ID__c = objStripeCharge.Id;
                        objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;               
                        objPayment.recordTypeId = paymentRecType;                
                        listOfPayment.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                    }else{
                        if(objStripeCharge.error != null){
                            iLog.Status__c = 'Failure';
                            iLog.Invoice__c = objInvoice.Id;
                            
                            iLog.Message__c = objStripeCharge.error.message;
                            iLog.Type__c = objStripeCharge.error.stripeType;
                            
                            if(String.isNotBlank(objStripeCharge.error.charge)){
                                iLog.ChargeId__c = objStripeCharge.error.charge;
                            }
                            if(String.isNotBlank(objStripeCharge.error.decline_code)){
                                iLog.Code__c = objStripeCharge.error.decline_code;
                            }
                            if(declinedSet.size()>0 && declinedSet.contains(objStripeCharge.error.decline_code)){
                                DeclinedInvoiceList.add(objInvoice);
                            }
                        }
                        invoiceLogList.add(iLog); 
                        //26-Nov-2019:jatin Send Email to the Customer if its charge gives error and the payment is not collected from his account
                        if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 ){
                            string centerId,personContactId;
                            if(objInvoice.Parent_Account__r != null && objInvoice.Parent_Account__r.Centre_Name__r != null &&
                                string.isNotBlank(objInvoice.Parent_Account__r.Centre_Name__r.Location__c) ){
                                centerId = objInvoice.Parent_Account__r.Centre_Name__r.Location__c;
                            }
                            if(objInvoice.Parent_Account__r != null && string.isNotBlank(objInvoice.Parent_Account__r.PersonContactId)){
                                personContactId = objInvoice.Parent_Account__r.PersonContactId;
                            }
                            sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,objInvoice.id,centerId));
                        }
                    }        
                } //commmented by jatin: 15-jan-2020:Payment should not be created if zero amount is due
                //else if(objInvoice.Balance_Amount__c <= 0.30 && objInvoice.Balance_Amount__c >= 0){
                else if(objInvoice.Balance_Amount__c <= 0.30 && objInvoice.Balance_Amount__c > 0){
                        objInvoice.status__c = ConstantsClass.paidStatus;
                        listOfInvoicesTOUpdate.add(objInvoice);
                        successinvoiceIdSet.add(objInvoice.Id);
                    
                        Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, objInvoice.Balance_Amount__c,
                                                                        ConstantsClass.successStatus); 
                        objPayment.recordTypeId = payCreditRecType;
                        objPayment.remarks__c = 'Rounding Down';
                        listOfPayment.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                }   
            }catch(Exception ex){
                System.debug('@@@@Exception '+ex.getMessage());
                iLog.Status__c = 'Failure';
                iLog.Invoice__c = objInvoice.Id;
                iLog.Message__c =   ex.getMessage(); //objStripeCharge.error.message;
                iLog.Type__c =     ex.getTypeName();  //objStripeCharge.error.stripeType;
                invoiceLogList.add(iLog);  
                //26-Nov-2019:jatin Send Email to the Customer if its charge gives error and the payment is not collected from his account
                if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 ){
                    string centerId,personContactId;
                    if(objInvoice.Parent_Account__r != null && objInvoice.Parent_Account__r.Centre_Name__r != null &&
                        string.isNotBlank(objInvoice.Parent_Account__r.Centre_Name__r.Location__c) ){
                        centerId = objInvoice.Parent_Account__r.Centre_Name__r.Location__c;
                    }
                    if(objInvoice.Parent_Account__r != null && string.isNotBlank(objInvoice.Parent_Account__r.PersonContactId)){
                        personContactId = objInvoice.Parent_Account__r.PersonContactId;
                    }
                    sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,objInvoice.id,centerId));
                }
            }
           
        }
        if(invoiceLogList.size()>0){
                Database.insert(invoiceLogList,false);
            }
        if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
            Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
        }
        system.debug('@@@listOfInvoicesTOUpdate'+listOfInvoicesTOUpdate);
        system.debug('@@@invoiceLogList'+invoiceLogList);
        system.debug('@@@sendSingleEmailMessage'+sendSingleEmailMessage);
        if(listOfInvoicesTOUpdate.size()>0){
            Database.Update(listOfInvoicesTOUpdate,false);
            
            
            if(listOfPayment.size() > 0){
                Database.insert(listOfPayment,false);
            }
            
            /*List<Enrolment__c> listOfEnrolment = getListOfEnrollments(successinvoiceIdSet);    //getListOfEnrollments(listOfInvoicesTOUpdate);
            List<Enrolment__c> listOfEnrolmentToProcess = getEnrolmentsToProccess(listOfEnrolment);
            if(listOfEnrolmentToProcess.size()>0){
                update listOfEnrolmentToProcess;
            }
            listOfEnrolment = getUpdatedEnrolment(listOfEnrolment);
            changeThisMonthBookingStatus(listOfEnrolment);
            createNextAppointments(listOfEnrolment);*/
        }  
        
        /*if(DeclinedInvoiceList.size()>0){
            BillingUtility.sendDeclinedMail(DeclinedInvoiceList,'Declined');
        }*/
        if(fifthBookingIdSet.size()>0){
            updateFifthBookingStatus(fifthBookingIdSet);
        }
        
        return successinvoiceIdSet;
    }

    
    
    //12-03-2019 This method update the fifth bookings status By Sanjay Bhati
    public static void updateFifthBookingStatus(Set<Id> invoiceIdSet){
        Set<Id> bookingIdSet = new Set<Id>();
        List<Booking__c> bookingList = new List<Booking__c>();
        if(invoiceIdSet.size()>0){
            for(Invoice_Line_Item__c invoiceLine : [Select Id,Name,Booking__c,Booking__r.Is_fifth_booking__c From Invoice_Line_Item__c WHERE Invoice__c IN : invoiceIdSet]){
                if(invoiceLine.Booking__c != null && invoiceLine.Booking__r.Is_fifth_booking__c){
                    bookingIdSet.add(invoiceLine.Booking__c);
                }
            }
            if(bookingIdSet.size()>0){
                for(Id bid : bookingIdSet){
                    Booking__c book = new Booking__c();
                    book.Id = bid;
                    book.Status__c = 'Scheduled';
                    bookingList.add(book);
                }
            }
        }
        if(bookingList.size()>0){
            update bookingList;
        }
    }
    
    // this method change the status from pending to reschedule for this month booking.
   /* public static void changeThisMonthBookingStatus(List<Enrolment__c> listOfEnrolment){
        //System.debug('@@ changeThisMonthBookingStatus listOfEnrolment'+listOfEnrolment.size());
        Date selectedDate =  system.today();
        Date firstDate = selectedDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(selectedDate.year() , selectedDate.month())  - 1);
        Map<String,List<Date>> datesMap = getDateMap(firstDate,lastDate );
        Map<Enrolment__c,Date> fifthBookingMap = new Map<Enrolment__c,Date>();
        
        
        if(listOfEnrolment.size() >0){
            Set<String> setOfEnrolmentIds  = new Set<String>();
            
            List<Booking__c> listOfBookings = new List<Booking__c>();
             
            for(Enrolment__c objEnrol : listOfEnrolment){
                setOfEnrolmentIds.add(objEnrol.Id);
                System.debug('datesMap.get(objEnrol.Lesson_Day__c).size()'+datesMap.get(objEnrol.Lesson_Day__c).size());
                if(datesMap.containskey(objEnrol.Lesson_Day__c) && datesMap.get(objEnrol.Lesson_Day__c).size() == 5){
                    fifthBookingMap.put(objEnrol,datesMap.get(objEnrol.Lesson_Day__c)[4]);
                }
            }
            for(Booking__c objBooking : [SELECT Id, Status__c FROM Booking__c WHERE Enrolment__c IN :setOfEnrolmentIds AND Status__c = 'Pending' AND 
                                        Booking_Date__c = THIS_MONTH And Type__c =: ConstantsClass.typeRegular  ]){
                                        ///AND Individual_Booking__c = FALSE
                                        objBooking.Status__c = 'Scheduled';
                                        listOfBookings.add(objBooking);
            }
            
            if(listOfBookings.size() > 0){
                update listOfBookings;
            }
            
            if(fifthBookingMap.size()>0){
                createFifthBooking(fifthBookingMap);
            }
        } 
    }
    */
    public static Map<String,List<Date>> getDateMap(Date firstDate,Date lastDate ){
        Map<String,List<Date>> datesMap = new Map<String,List<Date>>();
        while(firstDate <= lastDate ){
            DateTime myDateTime = (DateTime) firstDate;
            String day = myDateTime.format('EEEE');
            List<Date> dateList = new List<Date>();
            if(datesMap.containskey(day)){
                dateList = datesMap.get(day);
            }
            dateList.add(firstDate);
            firstDate = firstDate.addDays(1);
            datesMap.put(day,dateList);
        }
        //system.debug(datesMap);
        return datesMap;
    }
    /*
    // this method create next 4 appointment for that enrolment.
    public static void createNextAppointments(List<Enrolment__c> listOfEnrolment){
        String lessonRecorType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        List<Booking__c> listOfBookings = new List<Booking__c>();
        //Map<String, Enrolment__c> mapOfEnrolments = new Map<String, Enrolment__c>();
        //Map<String, Date> mapOfEnrolmentAndBookingDate = new Map<String , Date>();
        
        if(listOfEnrolment.size() > 0){
            Date current = System.today().addMonths(13);
            Date firstDate = Date.newInstance(current.year(),current.month(),01);
            Date lastDate = Date.newInstance(current.year(),current.month(),Date.daysInMonth(current.month(),current.year()));
            
            Map<String, List<Date>> mapOfDates = getDateMap(firstDate,lastDate);
                     
            
            for(Enrolment__c objEnrol : listOfEnrolment){
                List<Date> listOfDates = mapOfDates.get(objEnrol.Lesson_Day__c);
                if(listOfDates.size() > 4){
                    listOfDates.remove(4);
                }
                for(Date objDate : listOfDates){
                    Booking__c objBooking = new Booking__c();
                    objBooking.Student__c = objEnrol.Student__c;
                    objBooking.Center__c = objEnrol.Center__c;
                    objBooking.Teacher_Account__c = objEnrol.Teacher__c;
                    objBooking.Enrolment__c = objEnrol.Id; 
                    objBooking.Package__c = objEnrol.Package__c;
                    objBooking.start_time__c = objEnrol.Lesson_Start_time__c;
                    objBooking.End_time__c = objBooking.start_time__c.addMinutes(Integer.valueOf(objEnrol.Package__r.Duration__c));
                    objBooking.Booking_Date__c = objDate;//maxDate.addDays(7*i);
                    objBooking.recordTypeId = lessonRecorType;
                    objBooking.type__c = 'Regular';
                    objBooking.Status__c = 'Pending';
                    listOfBookings.add(objBooking);
                }
            }
            //System.debug('listOfBookings'+listOfBookings);
            if(listOfBookings.size() > 0){
                insert listOfBookings;
            }
        }        
    }
    
    // this method return the list of cancelled booking of all students including parent itself, within 120 days
    public static Map<String,List<Booking__c>> getParentBookingMap(Map<Enrolment__c,Date> enrollmentMap){
        Map<String,List<Booking__c>> parentBookingMap = new Map<String,List<Booking__c>>();
        Set<String> setOfParentIds = new Set<String>(); // hold ids of parent which has available makeup minutes
        Set<String> setOfStuParentIds = new Set<String>(); // hold id of student and parent to fetch cancelled bookings.
        
        // fill set of parentIds from enrollment which has available makeup credits.
        for(Enrolment__c enroll : enrollmentMap.keyset()){
            if(String.isNotBlank(enroll.Student__c) && String.isNotBlank(enroll.Parent__c) && enroll.Parent__r.Available_Make_up_Units__c > 0){
                setOfParentIds.add(enroll.Parent__c); 
            }
        }
        
        // fill the set of student and parent for which we fetch bookings.
        if(setOfParentIds.size() > 0){
            for( Account objAcc : [SELECT Id, also_A_Student__c FROM Account WHERE Id IN: setOfParentIds OR Parent__c IN: setOfParentIds]){
                setOfStuParentIds.add(objAcc.Id);
            }
        }
        
        // fill bookings of parent o
        if(setOfStuParentIds.size() > 0){
            for(Booking__c booking : [SELECT  Id,Student__c,Parent__c,Available_Make_up_Units__c,Enrolment__c,Enrolment__r.Package__r.Duration__c FROM Booking__c 
                                      WHERE status__c =: ConstantsClass.statusCanceled  AND Student__c IN :setOfStuParentIds AND Make_up_Expiry_Date__c > today
                                              AND Available_Make_up_Units__c != Null
                                              ORDER BY Make_up_Expiry_Date__c asc  ] ){
                                              
                String parentId = String.isNotBlank(booking.Parent__c) ?booking.Parent__c : booking.Student__c;
                if(String.isNotBlank(parentId)){
                    List<Booking__c> bookingList = parentBookingMap.containsKey(parentId) ?parentBookingMap.get(parentId) : new List<Booking__c>();
                    bookingList.add(booking);
                    parentBookingMap.put(parentId, bookingList);
                }
            }
        } 
        return parentBookingMap;
    }
    public static void createFifthBooking(Map<Enrolment__c,Date> enrollmentMap){
        
        Map<String,List<Booking__c>> parentBookingMap = getParentBookingMap(enrollmentMap);
        Map<String,Id> packageMap = getPackageMap(); // map of package key==> Duration+'-'+centerName
        //List<Booking__c> bookingsToUpsert = new List<Booking__c>();
        Map<String,Booking__c> bookingsToUpsert = new Map<String,Booking__c>();
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        List<Invoice__c> listOfInv = new List<Invoice__c>();
        List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
        
        for(Enrolment__c enrol : enrollmentMap.keySet()){
            String type='';
            String status ='';
            String packageId = '';
            String utilizedBookings ='';
            Date bookingDate = enrollmentMap.get(enrol);
            // check is parent has make up , then cretae make up booking
            if(enrol.Parent__r.Available_Make_up_Units__c != NULL && 
                enrol.Parent__r.Available_Make_up_Units__c >= Decimal.valueOf(enrol.package__r.Duration__c) 
                && parentBookingMap.containsKey(enrol.Parent__c) ){
                type = ConstantsClass.typeMakeup;
                status = ConstantsClass.statusScheduled;
                if(packageMap.containsKey(enrol.package__r.Duration__c+'-'+enrol.Center__r.Name)){
                    packageId =packageMap.get(enrol.package__r.Duration__c+'-'+enrol.Center__r.Name);
                }
                Integer hoursToDeduct = Integer.valueOf(enrol.package__r.Duration__c);
                for(Booking__c objBook : parentBookingMap.get(enrol.Parent__c)){
                    if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                        objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                        utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                        hoursToDeduct = 0;
                    }else{
                        utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                        hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                        objBook.Available_Make_up_Units__c = 0;
                         
                    }
                    //bookingsToUpsert.add(objBook); // add cancelled booking to reset credits.
                    bookingsToUpsert.put(objBook.id,objBook);
                    
                    if(hoursToDeduct == 0){
                        break;
                    }    
                }
            }else{
                type = ConstantsClass.typeAdhoc;
                status = ConstantsClass.statusPending;
                packageId = enrol.package__c;
            }
            
            Booking__c objBook = addBooking(enrol,type,status,bookingDate,TRUE,packageId,utilizedBookings);
            bookingsToInsert.add(objBook);
            if(type == ConstantsClass.typeAdhoc){
                Invoice__c objInv = BillingUtility.fillInvoice('', enrol.Parent__c, ConstantsClass.dueStatus);
                objInv.due_Date__c =  bookingDate.addDays(-7);
                listOfInv.add(objInv);
                listOfLineItems.add(addInvoiceLineItem(enrol,objInv ,objBook));
            }
        }
        if(bookingsToUpsert.size() > 0){
            //UPSERT bookingsToUpsert;     
            Database.Upsert(bookingsToUpsert.values(),false);
        }
        if(bookingsToInsert.size() > 0){
            Database.Insert(bookingsToInsert,false);
        }
        if(listOfInv.size() > 0){
            Database.Insert(listOfInv,FALSE);
            //INSERT listOfInv;
        }
        if(listOfLineItems.size()>0){
            for(Invoice_Line_Item__c invoiceLine : listOfLineItems){
                invoiceLine.Invoice__c = invoiceLine.Invoice__r.Id;
                invoiceLine.Booking__c = invoiceLine.Booking__r.Id;
            }
            Database.insert(listOfLineItems,FALSE);
            //insert listOfLineItems;
        }
    }
    public static Map<String,Id> getPackageMap(){
        Map<String,Id> packageMap = new Map<String,Id>();
        for(Package__c packg : [Select Id,type__c,Duration__c,Location__r.Name From Package__c where type__c='Makeup']){
            packageMap.put(packg.Duration__c+'-'+packg.Location__r.Name,packg.Id); 
        }
        return packageMap;
    }
    public static Invoice_Line_Item__c addInvoiceLineItem(Enrolment__c objEnrol,Invoice__c invoice,Booking__c booking){
        Invoice_Line_Item__c invoiceLine = new Invoice_Line_Item__c();
        invoiceLine.Enrolment__c = objEnrol.Id;
        invoiceLine.Invoice__r = invoice;
        invoiceLine.Amount__c = objEnrol.Package__r.Unit_Fee__c;
        invoiceLine.Package__c = objEnrol.Package__c;
        invoiceLine.Booking__r = booking;
        invoiceLine.Teacher_Id__c = booking.Teacher_Account__c;
        return invoiceLine;
    }
    Public static Booking__c addBooking(Enrolment__c objEnrol,String type,String status,date bookDate , Boolean isFifthBooking,
                                        String packageId,String utilizedBookings){
        Booking__c objBooking = new Booking__c();
        objBooking.Student__c = objEnrol.Student__c;
        objBooking.Center__c = objEnrol.Center__c;
        objBooking.Teacher_Account__c = objEnrol.Teacher__c;
        objBooking.Enrolment__c = objEnrol.Id;
        objBooking.start_time__c = objEnrol.Lesson_Start_time__c;
        objBooking.End_time__c = objBooking.start_time__c.addMinutes(Integer.valueOf(objEnrol.Package__r.Duration__c));
        objBooking.Booking_Date__c = bookDate;
        objBooking.type__c = type;
        objBooking.Status__c = status;
        objBooking.Package__c = packageId;
        objBooking.is_Fifth_Booking__c = isFifthBooking;
        if(String.isNotBlank(utilizedBookings)){
            objBooking.Make_up_Utilize_Bookings__c = utilizedBookings;
        }
        return objBooking;
    }
    
    
    // this method return list of enrollments for which we created 
    public static List<Enrolment__c> getListOfEnrollments(Set<String> setOfInvoiceIds){
        Set<String> setOfEnrolmentIds = new Set<String>();
        //Set<String> setOfInvoiceIds = new Set<String>();
        List<Enrolment__c> listOfEnrolments = new List<Enrolment__c>();
        //System.debug('@@ listOfInvoice '+listOfInvoice);
        if(setOfInvoiceIds.size() > 0){
            for(Invoice_Line_Item__c objLineItems : [SELECT Enrolment__c FROM Invoice_Line_Item__c 
                                                    WHERE Invoice__c IN:setOfInvoiceIds AND Enrolment__c != NULL AND Enrolment__r.Lesson_day__c != NULL]){
                setOfEnrolmentIds.add(objLineItems.Enrolment__c);
            }
            
            if(setOfEnrolmentIds.size() > 0){
                listOfEnrolments = fetchEnrolments(setOfEnrolmentIds);
            }
        }
        return listOfEnrolments;
    }
    
    public static List<Enrolment__c> getUpdatedEnrolment(List<Enrolment__c> listOfEnrolment){
        Set<String> setOfEnrolIds = new Set<String>();
        for(Enrolment__c objEnrol : listOfEnrolment){
            setOfEnrolIds.add(objEnrol.Id);    
        }
        return fetchEnrolments(setOfEnrolIds);
    }
    
    public static List<Enrolment__c> getEnrolmentsToProccess(List<Enrolment__c> listOfEnrolment){
        List<Enrolment__c> listOfEnrolmentToProcess = new List<Enrolment__c>();
        Date currentDate = System.today();
        Date firstDate = Date.newInstance(currentDate.year(),currentDate.month(), 01);
        Date lastDate =  Date.newInstance(currentDate.year(),currentDate.month(), Date.daysInMonth(currentDate.year(),currentDate.month()));
        for(Enrolment__c objEnrolment : listOfEnrolment ){
            if(String.isNotBlank(objEnrolment.Package_Process_Type__c) && String.isNotBlank(objEnrolment.Package_Process_Status__c)
                && objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessPendingStatus && 
                (objEnrolment.effective_Date__c >= firstDate && objEnrolment.effective_Date__c <= lastDate) ){
                if(objEnrolment.Package_Process_Type__c == 'Upgrade' || objEnrolment.Package_Process_Type__c == 'Downgrade'){
                        objEnrolment.package__c = objEnrolment.New_Package_Id__c;
                        if(objEnrolment.Next_Lesson_Start_time__c != NULL){
                            objEnrolment.Lesson_Start_Time__c = objEnrolment.Next_Lesson_Start_time__c;
                        }
                        objEnrolment.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
                }else if(objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType){
                    objEnrolment.Stage__c= ConstantsClass.enrollmentStageCancelled;
                    objEnrolment.Package_Process_Status__c =  ConstantsClass.enrollmentProcessCompletedStatus; //'Completed';
                }else if(objEnrolment.Package_Process_Type__c == ConstantsClass.enrollmentProcessChanged){
                    if(String.isNotBlank(objEnrolment.New_Package_Id__c)){
                        objEnrolment.package__c = objEnrolment.New_Package_Id__c;
                    }
                    if(objEnrolment.Next_Lesson_Start_time__c != NULL){
                        objEnrolment.Lesson_Start_Time__c = objEnrolment.Next_Lesson_Start_time__c;
                    }
                    if(String.isNotBlank(objEnrolment.New_Teacher__c)){
                        objEnrolment.teacher__c = objEnrolment.New_Teacher__c;
                    }
                    if(String.isNotBlank(objEnrolment.New_Lesson_Day__c)){
                        objEnrolment.Lesson_Day__c = objEnrolment.New_Lesson_Day__c;
                    }
                    objEnrolment.Package_Process_Status__c =  ConstantsClass.enrollmentProcessCompletedStatus; //'Completed';
                }
                listOfEnrolmentToProcess.add(objEnrolment); 
            }
        }
        return listOfEnrolmentToProcess;
    }
    
    private static List<Enrolment__c> fetchEnrolments(Set<String> setOfEnrolIds){
        return [SELECT Id,Student__r.Parent__c, Student__c, Parent__c, Package__c,Package__r.Unit_Fee__c,Package__r.Duration__c, 
                                    Center__c,Center__r.Name, Teacher__c, Lesson_Start_time__c, Lesson_Day__c,Next_Lesson_Start_time__c,
                                    Package_Process_Type__c,Package_Process_Status__c,Effective_Date__c,New_Package_Id__c,
                                    Student__r.Available_Make_up_Units__c,Student__r.Parent__r.Available_Make_up_Units__c,
                                    Package__r.Program__r.Instrument__c,Package__r.Location__c,Package__r.Type__c,
                                    New_Lesson_Day__c,New_Teacher__c,Parent__r.Available_Make_up_Units__c
                                    FROM Enrolment__c WHERE Id IN:setOfEnrolIds AND Stage__c !=: ConstantsClass.enrollmentStageCancelled];
    
    }*/
}