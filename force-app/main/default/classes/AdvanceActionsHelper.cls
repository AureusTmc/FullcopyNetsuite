public without sharing class AdvanceActionsHelper {
    
    /*
* This Method will return the Date from the date string.
*/
    Public Static Date convertToDate(String dateStr){
        Date dateToReturn;
        if(String.isBlank(dateStr)){
            return dateToReturn;
        }
        dateToReturn =  Date.valueOf(dateStr);
        return dateToReturn;
    }
    
    /*
* This Method will return the Date from the date string.
*/
    Public Static Date convertToDateForUpgrade(String dateStr){
        Date dateToReturn;
        if(String.isBlank(dateStr)){
            return dateToReturn;
        }
        List<String> dtStr = dateStr.split('/');
        if(dtStr.size() > 1){
            dateToReturn = Date.valueOf(dtStr[2]+'-'+dtStr[0]+'-'+dtStr[1]);
        }
        return dateToReturn;
    }
    
    /*
* Fetch Enrolment, Country, Subscription, Subscription Line Item From Booking
*/
    Public Static Enrolment__c fetchEnrolmentDetailsFromBooking(String bookingId){
        String enrolmentId;
        enrolmentId = upgradeDowngradeController.getEnrolmentId(bookingId);
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
        Enrolment__c enrolmentObj = new Enrolment__c();
        if(String.isNotBlank(enrolmentId)){
            enrolmentList = [SELECT Id,name, Effective_Date__c,class__C, New_class__C,Lesson_Day__c, Teacher__r.Employee_Duty_Type__c, package__r.unit_fee__c,
                            Lessons_Start_Date__c, Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, Center__r.Country__c,Next_Lesson_Start_time__c,
                             Package__c, Package__r.Duration__c,Parent__c, Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, 
                             Center__r.Country__r.Stripe_Secret_Key__c, Center__r.Country__r.Stripe_Base_Url__c,Center__r.Country__r.Id, 
                             // added by nishi for update new Teacher Id for ossia organization
                             New_Teacher__c,Teacher__c,Center__r.Organisation__r.Name,Available_Make_up_mins__c,
                             //start:added by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
                             Center__r.Organisation__r.Tax_Rate__c, Center__r.Organisation__r.Country__r.Currency_Code__c, 
                             Center__r.Organisation__r.Stripe_Secret_Key__c, Center__r.Organisation__r.Stripe_Base_Url__c,Center__r.Organisation__r.Id, 
                             //end:added by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
                             Center__r.Organisation__c, (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                                         Subscription__c, Subscription__r.Center__c, Enrolment__c, 
                                                         Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                                         Enrolment__r.Center__r.Organisation__r.Tax_Rate__c FROM Subscription_Line_Items__r
                                                         Where Status__c =:ConstantsClass.activeStatus //4-sep-2020: added by nishi for new requirement one enrolment have two subscrition so we get active line item
                                                         And Next_Bill_Date__c != null)
                             FROM Enrolment__c WHERE Id =: enrolmentId];
            if(enrolmentList.size() > 0){
                enrolmentObj = enrolmentList[0];
            }
        }
        return enrolmentObj;
    }
       /*
*  This method is use for Cancel the future makeup bookings of the enrolment and delete the busy placeholder.
*/
    public static void processFutureMakeupAndBusyBookingsForWithdrawal(Enrolment__c enrolObj, List<Booking__c> bookingListToDelete, Set<String> setOfMakeupBookings){
        List<Booking__c> bookingListToUpdate = new List<Booking__c>();
        
        if(String.isNotBlank(enrolObj.Student__c) && String.isNotBlank(enrolObj.Teacher__c) && 
           Integer.valueOf(enrolObj.Package__r.Duration__c) > 0 && enrolObj.Lesson_Start_time__c != NULL && 
           enrolObj.Effective_Date__c != NULL && String.isNotBlank(enrolObj.Lesson_Day__c)){
               
               for(Booking__c bookingObj : AureusCalendarControllerHelper.processMakeupBooking(enrolObj.Student__c, enrolObj.Teacher__c,Integer.valueOf(enrolObj.Package__r.Duration__c), enrolObj.Lesson_Start_time__c, enrolObj.Effective_Date__c, enrolObj.Lesson_Day__c)){
                   
                   if(bookingObj.Type__c == ConstantsClass.busyBookingType && bookingObj.Category__c == ConstantsClass.bookingCategoryPlaceHolder){
                       bookingListToDelete.add(bookingObj);            
                   }else if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                       bookingListToUpdate.add(bookingObj);
                   }
                   
               }
               
               if(bookingListToDelete.size() > 0){
                   DELETE bookingListToDelete;
               }
               
               if(bookingListToUpdate.size() > 0){
                   AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(bookingListToUpdate);  
               }
           }      
    }
    /*
* Fetch Subscription Line Item's Next Bill Date From Enrolment
*/
    Public Static Date fetchNextBillDateFromEnrolment(Enrolment__c enrolmentObj){
        Date nextBillDate;
        system.debug('###enrolmentObj.I'+enrolmentObj.Id);
        system.debug('###enrolmentObj.I'+enrolmentObj.Subscription_Line_Items__r.size());
        if(String.isNotBlank(enrolmentObj.Id) && enrolmentObj.Subscription_Line_Items__r.size() > 0 && enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c != NULL){
            nextBillDate = enrolmentObj.Subscription_Line_Items__r[0].Next_Bill_Date__c;
        }
        return nextBillDate;
    }
    
    /*
* Fetch Country From Enrolment
*/
    Public Static Country__c fetchCountryFromEnrolment(Enrolment__c enrolmentObj){
        Country__c countryObj = new Country__c();
        if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.center__r.country__c)){
            countryObj = enrolmentObj.center__r.country__r;
        }
        return countryObj;
    }
    
    /*
*  This Method will return the Date Time from the timeslot from the calendar.
*/
    Public Static DateTime getDateTimeFromString(String currentTime){
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
    


    Public  static Enrolment__c fetchEnrolment(String enrolmentId){
        Enrolment__c enrolmentObj = new Enrolment__c();
        List<Enrolment__c> enrolmentList = [SELECT Id,name, Effective_Date__c, Lesson_Day__c, Teacher__c, Teacher__r.Employee_Duty_Type__c, 
                                            class__C,New_Class__c,Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, package__r.unit_fee__c,
                                            Next_Lesson_Start_time__c,new_package_Id__c,New_Teacher__c,new_package_Id__r.Duration__c,Lessons_Start_Date__c,
                                            New_Teacher__r.id,New_Teacher__r.Employee_Duty_Type__c,Package__c, Package__r.Duration__c,Parent__c,
                                            Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, 
                                            Center__r.Country__r.Stripe_Secret_Key__c, Center__r.Country__r.Stripe_Base_Url__c,Center__r.Country__r.Id, 
                                            //Start: added by nishi: 24-Aug-2020: for manage tax according to organisation
                                            Center__r.Organisation__r.Tax_Rate__c, Center__r.Organisation__r.Country__r.Currency_Code__c, 
                                            Center__r.Organisation__r.Stripe_Secret_Key__c, Center__r.Organisation__r.Stripe_Base_Url__c,Center__r.Organisation__r.Id, 
                                            Center__r.Organisation__c,Center__r.Organisation__r.name, New_Centre__c,
                                            //End: added by nishi: 24-Aug-2020: for manage tax according to organisation
                                            (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                            Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                            Enrolment__r.Center__r.Organisation__r.Tax_Rate__c,Subscription_Expiry_Date__c,Status__c
                                            FROM Subscription_Line_Items__r
                                            where Status__c =:ConstantsClass.activeStatus //4-sep-2020: added by nishi for new requirement one enrolment have two subscrition so we get active line item
                                            And Next_Bill_Date__c != null)  
                                            FROM Enrolment__c WHERE Id =: enrolmentId];
        if(enrolmentList.size() > 0){
            enrolmentObj = enrolmentList[0];
        } 
        return enrolmentObj;                                          
    }


    /*
* return sum of all deposit amount for enrolment
*/
    
    Public Static Decimal getDepositFromFile(String enrolId){
        Decimal invoiceDeposit = 0;
        Decimal paymentDeposit = 0;
        Decimal depositToReturn = 0;
        Set<String> statusSet = new Set<String>{ConstantsClass.voidInvoiceStatus, ConstantsClass.cancelledInvoiceStatus};
            for(Invoice_Line_Item__c objLineItem : [SELECT Id,Amount__c FROM Invoice_Line_Item__c WHERE IS_Deposit__c = TRUE AND Enrolment__c =:enrolId AND Invoice__r.Status__c NOT IN :statusSet]){
                invoiceDeposit += objLineItem.amount__c;
            }
        for(Payment__c payment : [SELECT Id, Payment_Amount__c FROM Payment__c WHERE Enrolment__c =: enrolId AND RecordType.Name =: ConstantsClass.paymentAsDepositRecordType]){
            paymentDeposit += payment.Payment_Amount__c;
        }
        system.debug('!!invoiceDeposit'+invoiceDeposit);
         system.debug('!!paymentDeposit'+paymentDeposit);
        depositToReturn = invoiceDeposit - paymentDeposit;
         system.debug('!!depositToReturn'+paymentDeposit);
        return depositToReturn;
    }
    
    /*
* This Method will Return the Package Details. 
*/
    Public Static UpgradeDowngradePackageSummary  getPackageDetailsUpgradeDowngrade(String oldPackageId, String newPackageId){
        UpgradeDowngradePackageSummary summary = new UpgradeDowngradePackageSummary();
        Set<String> packageIds = new Set<String>();
        List<Package__c> packageList = new List<Package__c>();
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            packageIds.add(oldPackageId);
            packageIds.add(newPackageId);
        }
        if(packageIds.size() > 0){
            packageList = [SELECT Id, Name, Deposit_Fee__c, duration__c, Unit_Fee__c  FROM Package__c WHERE Id IN: packageIds];
            if(packageList.size() == 2){
                for(Package__c packageObj : packageList){
                    if(packageObj.Id == oldPackageId){
                        summary.oldPackage = packageObj;
                        summary.oldPackageName = packageObj.Name; 
                        summary.oldPackageId = packageObj.Id;
                        summary.oldDuration = packageObj.duration__c;
                        summary.currentPackageDeposit = packageObj.Deposit_Fee__c;
                    }else if(packageObj.Id == newPackageId){
                        summary.newPackage = packageObj;
                        summary.newPackageName = packageObj.Name; 
                        summary.newPackageId = packageObj.Id;
                        summary.newDuration = packageObj.Duration__c;
                        summary.newPackageDeposit = packageObj.Deposit_Fee__c;
                    }
                }
            }
        }
        return summary;
    }
    
    /*
*  This Method will fetch all regular Bookings and process them according to the type.
*/
    
    Public Static void processFutureBookings(Enrolment__c enrolmentObj, String type){
        
        Integer timeDuration = 0;
        List<Booking__c> bookingList = new List<Booking__c>();
        
        for(Booking__c objBook : [SELECT Id, Start_Time__c, end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                  Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                  Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c 
                                  FROM Booking__c WHERE Enrolment__c = :enrolmentObj.Id AND Booking_Date__c >= :enrolmentObj.effective_Date__c
                                  AND Type__c = :ConstantsClass.typeRegular AND Status__c != :ConstantsClass.statusCanceled]){
                                      System.debug('@@@@objBook'+objBook);
                                      if(objBook.Enrolment__r.Next_Lesson_Start_time__c != NULL && (type == 'downgrade' || type == 'upgrade' || type == 'change')){
                                          //Arpit commented this
                                          objBook.start_time__c = objBook.Enrolment__r.Next_Lesson_Start_time__c;
                                      }else if(objBook.Enrolment__r.Lesson_Start_time__c != NULL){
                                          //Arpit commented this
                                          objBook.start_time__c = objBook.Enrolment__r.Lesson_Start_time__c;
                                      }
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__r.Duration__c) && String.isNotBlank(objBook.package__r.Duration__c)){
                                          timeDuration =  Integer.valueOf(objBook.Enrolment__r.new_package_Id__r.Duration__c) - Integer.valueOf(objBook.package__r.Duration__c);                      
                                      }
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.New_Teacher__c)){
                                          objBook.teacher_Account__c = objBook.Enrolment__r.New_Teacher__c;
                                      }   
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__c)){
                                          objBook.package__c = objBook.Enrolment__r.new_package_Id__c; 
                                      }
                                      
                                      if(String.isNotBlank(objBook.Enrolment__r.new_package_Id__c)){
                                          objBook.end_time__c = objBook.start_Time__c.addMinutes(Integer.valueOf(objBook.Enrolment__r.new_package_Id__r.Duration__c));
                                      }else{
                                          objBook.end_time__c = objBook.start_Time__c.addMinutes(Integer.valueof(objBook.package__r.Duration__c));
                                      }
                                      
                                      bookingList.add(objBook);
                                  }
        if(bookingList.size() > 0){
            System.debug('@@@@bookingList'+bookingList);
            UPSERT bookingList;
        }
    }
    
    /*
* This Method will Process the Future Fifth Lessons 
*/
    Public Static Set<String> processFutureFifthLessons(Enrolment__c enrolmentObj, String type){
        
        Integer timeDuration = 0;
        Set<String> makeupBookingsSet = new Set<String>();
        
        List<Fifth_Lesson__c> fifthLessonList = new List<Fifth_Lesson__c>();
        for(Fifth_Lesson__c fifthLesson : [SELECT Id, Start_Time__c, end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                           Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                           Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c,
                                           Booking__r.Package__r.Type__c, IsActive__c FROM Fifth_Lesson__c 
                                           WHERE Enrolment__c = :enrolmentObj.Id AND Booking_Date__c >= :enrolmentObj.effective_Date__c]){
                                               system.debug('##fifthLesson.Booking__c'+fifthLesson.Booking__c);
                                               system.debug('##fifthLesson.Booking__c'+fifthLesson.id);
                                               system.debug('##fifthLesson.IsActive__c'+fifthLesson.IsActive__c);
                                               system.debug('##fifthLesson.IsActive__c'+fifthLesson.Booking__r.Package__r.Type__c);
                                               if(String.isNotBlank(fifthLesson.Booking__c) && !fifthLesson.IsActive__c && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.pakageTypeMakeup){
                                                   makeupBookingsSet.add(fifthLesson.Booking__c);
                                               }
                                               
                                               
                                               if(fifthLesson.Enrolment__r.Next_Lesson_Start_time__c != NULL && (type == 'downgrade' || type == 'upgrade' || type == 'change')){                                         
                                                   fifthLesson.start_time__c = fifthLesson.Enrolment__r.Next_Lesson_Start_time__c;
                                               }else if(fifthLesson.Enrolment__r.Lesson_Start_time__c != NULL){
                                                   fifthLesson.start_time__c = fifthLesson.Enrolment__r.Lesson_Start_time__c;
                                               }
                                               
                                               
                                               if(String.isNotBlank(fifthLesson.Enrolment__r.new_package_Id__r.Duration__c) && String.isNotBlank(fifthLesson.package__r.Duration__c)){
                                                   timeDuration =  Integer.valueOf(fifthLesson.Enrolment__r.new_package_Id__r.Duration__c) - Integer.valueOf(fifthLesson.package__r.Duration__c);                      
                                               }
                                               
                                               if(String.isNotBlank(fifthLesson.Enrolment__r.New_Teacher__c)){
                                                   fifthLesson.teacher_Account__c = fifthLesson.Enrolment__r.New_Teacher__c;
                                               }
                                               
                                               if(String.isNotBlank(fifthLesson.Enrolment__r.new_package_Id__c)){
                                                   fifthLesson.package__c = fifthLesson.Enrolment__r.new_package_Id__c; 
                                               }
                                               
                                               if(String.isNotBlank(fifthLesson.Enrolment__r.new_package_Id__c)){
                                                   fifthLesson.end_time__c = fifthLesson.start_Time__c.addMinutes(Integer.valueOf(fifthLesson.Enrolment__r.new_package_Id__r.Duration__c));
                                               }else{
                                                   fifthLesson.end_time__c = fifthLesson.start_Time__c.addMinutes(Integer.valueof(fifthLesson.package__r.Duration__c));
                                               }
                                               
                                               fifthLessonList.add(fifthLesson);
                                           }
        if(fifthLessonList.size() >0){
            UPSERT fifthLessonList;
        }
        system.debug('fifthLessonList'+fifthLessonList);
        system.debug('makeupBookingsSet'+makeupBookingsSet);
        return makeupBookingsSet;
    }
    
    /*
*  This Method will fetch the bookings 
*/
    Public Static List<Booking__c> fetchAllBooking(Set<String> setOfBookings){
        List<Booking__c> listOfBookings = new List<Booking__c>();
        if(setOfBookings.size() > 0){
            listOfBookings = [SELECT Id, Start_time__c, End_time__c, Booking_Date__c, Available_Make_up_Units__c, Student__r.Name, 
                              Center__c, Teacher_Account__c, Make_up_Utilize_Bookings__c, Duration__c, Type__c, Category__c FROM Booking__c 
                              WHERE Id IN :setOfBookings];
        }
        return listOfBookings;
    }
    
    /*
*  This Method will return the old and new Package.
*/
    Public Static UpDownSummary getOldNewPackage(String oldPackage, String newPackage){
        UpDownSummary objSummary = new UpDownSummary();
        for(Package__c objPack : [SELECT Id,Name, Duration__c FROM Package__c WHERE Id = :oldPackage OR Id = :newPackage]){
            if(objPack.Id == oldPackage){
                objSummary.oldPack = objPack;
            }else if(objPack.Id == newPackage){
                objSummary.newPack = objPack;
            }
        }
        return objSummary;
    }
    
    /*
* This Method will Add Makeup Minutes to the Parent
*/
    Public Static void AddFifthMakeupMinutesToParent(String centreId, Integer newPackageDuration, Integer timediff, Time startTime, Time newStartTime, Set<String> setOfBookings){
        List<Booking__c> bookingListToUpsert = new List<Booking__c>();
        Map<String, Integer> makeupReferencMap = new Map<String, Integer>();
        String utilizeBookings = '';
        Package__c makeupPackage = AureusCalendarControllerHelper.fetchDesiredPackage(centreId, String.valueOf(newPackageDuration));
        Boolean flag = false;
        for(Booking__c bookingObj : fetchAllBooking(setOfBookings)){
            Booking__c newBookObj = new Booking__c();
            flag = false;
            if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                if(String.isNotBlank(bookingObj.Make_up_Utilize_Bookings__c)){
                    utilizeBookings = '';
                    if(bookingObj.Make_up_Utilize_Bookings__c.split(';').size() > 0){
                        for(String makeup : bookingObj.Make_up_Utilize_Bookings__c.split(';')){
                            if(Integer.valueOf(makeup.split('-')[1]) >= timediff && !flag){
                                if(Integer.valueOf(makeup.split('-')[1]) - timediff > 0){
                                    utilizeBookings += makeup.split('-')[0]+'-'+String.valueOf(Integer.valueOf(makeup.split('-')[1]) - timediff)+';';
                                    makeupReferencMap.put(makeup.split('-')[0], timediff);
                                }
                                flag = true;
                            }else{
                                utilizeBookings += makeup+';';
                            }
                        }
                    }
                }
                
                newBookObj.Id = bookingObj.Id;
                newBookObj.Make_up_Utilize_Bookings__c  = utilizeBookings;
                if(newStartTime != NULL && newPackageDuration > 0 && String.isNotBlank(makeupPackage.Id)){
                    newBookObj.start_Time__c = newStartTime;
                    newBookObj.end_Time__c = newBookObj.start_Time__c.addMinutes(newPackageDuration);
                    newBookObj.Package__c = makeupPackage.Id;
                }
                utilizeBookings = '';
                for(Booking__c bookobj : fetchAllBooking(makeupReferencMap.keySet())){
                    bookingListToUpsert.add(new Booking__c(Id = bookobj.Id, Available_Make_up_Units__c =  bookobj.Available_Make_up_Units__c + makeupReferencMap.get(bookobj.Id)));
                }
                bookingListToUpsert.add(newBookObj);                                                                         
            }else if(bookingObj.Type__c == ConstantsClass.typeBusy){
                bookingObj.start_Time__c = newStartTime;
                bookingObj.End_Time__c = bookingObj.start_Time__c.addMinutes(newPackageDuration);
                bookingListToUpsert.add(bookingObj);
            }            
        }
        
        if(bookingListToUpsert.size() > 0){
            update bookingListToUpsert;
        }
    }
    
    /*
* This Method will Delete future Fifth Lessons...
*/
    Public static Set<String> deleteFutureFifthLessons(Enrolment__c enrolmentObj){
        Set<String> setofMakeupBookings = new Set<String>();
        List<Fifth_Lesson__c> fifthLessonsToDelete = new List<Fifth_Lesson__c>();
        for(Fifth_Lesson__c fifthLesson : [SELECT Id, Start_Time__c, end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                           Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                           Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c,
                                           Booking__r.Package__r.Type__c, IsActive__c FROM Fifth_Lesson__c 
                                           WHERE Enrolment__c = :enrolmentObj.Id AND Booking_Date__c >= :enrolmentObj.effective_Date__c]){
                                               if(String.isNotBlank(fifthLesson.Booking__c) && !fifthLesson.IsActive__c && fifthLesson.Booking__r.Package__r.Type__c == ConstantsClass.pakageTypeMakeup){
                                                   setofMakeupBookings.add(fifthLesson.Booking__c);
                                               }
                                               fifthLessonsToDelete.add(fifthLesson);
                                           }
        if(fifthLessonsToDelete.size() > 0){
            DELETE fifthLessonsToDelete;
        }
        return setofMakeupBookings;
    }
    public static List<Enrolment__c> getNextBillingDateSubscription(String enrollmentId){
        return [SELECT Id, Name, Parent__c, Parent__r.Name, effective_Date__c, Lesson_Day__c, New_Package_Id__r.Unit_Fee__c, 
                Package__r.Unit_Fee__c, Center__c, Teacher__c, package__r.Duration__c, new_package_Id__r.Duration__c, (SELECT Id, Subscription__c, Subscription__r.Center__c, Enrolment__c, Next_Bill_Date__c , Subscription__r.Parent__c, 
                                                                                                                       Subscription__r.Parent__r.Stripe_Customer_Id__c FROM Subscription_Line_Items__r WHERE Subscription__c != NULL) 
                FROM Enrolment__c WHERE Id =: enrollmentId];
    }
    Public  static Enrolment__c initEnroll(Enrolment__c enroll){
        enroll.Package_Process_Type__c = '';
        enroll.Package_Process_Request_Date__c = Null;
        enroll.Notice_Period_Start_Date__c = Null;
        enroll.Reason_of_Withdraw__c  = ''; 
        enroll.Feedback_Comments__c = '';
        enroll.New_Package_Id__c = Null;
        enroll.Package_Process_Status__c = '';  
        enroll.Notice_Period_End_Date__c = Null;
        enroll.Refund_Method__c = '';
        
        return enroll;
    }
   /* Public  static Enrolment__c getUpdatedEnrollmentFields(string enrolmentId,string ProcessType,
        date NoticePeriodStartDate,Date EffectiveDate,string packageId,Time timeSlot){
        Enrolment__c enroll = new Enrolment__c();
        enroll.Id = enrolmentId;
        enroll = initEnroll(enroll);
        
        Date nextBillDate = getNextBillingDate(enrolmentId);
        enroll.Package_Process_Type__c = ProcessType;
        system.debug('@@@ProcessType'+ProcessType);
        if(ProcessType.equalsIgnoreCase(ConstantsClass.enrollmentProcessChanged)){
             Boolean isSameMonth = nextBillDate > effectiveDate ? true : false;
             enroll.Package_Process_Status__c = isSameMonth ? ConstantsClass.enrollmentProcessCompletedStatus : ConstantsClass.enrollmentProcessPendingStatus;      
            if(String.isNotBlank(packageId)){
                if(isSameMonth){
                    enroll.Package__c = packageId;
                }
                enroll.new_package_Id__c = packageId;
            }
            if(timeslot != null){
                if(isSameMonth){
                    enroll.Lesson_Start_time__c = timeslot;
                }
                enroll.Next_Lesson_Start_time__c = timeslot;
            }
                
                
            if(effectiveDate != NULL){
                enroll.Effective_Date__c = effectiveDate;
            }
            
        }else{
            Boolean  isSameMonth = (effectiveDate >= nextBillDate) ? true :false;
            enroll.Package_Process_Status__c = isSameMonth ? ConstantsClass.enrollmentProcessPendingStatus : ConstantsClass.enrollmentProcessCompletedStatus;      
            
            if(ProcessType.equalsIgnoreCase(ConstantsClass.enrollmentProcessDowngradeType)){
                if(!isSameMonth){
                    enroll.Package__c = packageId;
                }
                enroll.New_Package_Id__c = packageId;
                enroll.Next_Lesson_Start_time__c = timeSlot;
            }else if(ProcessType.equalsIgnoreCase(ConstantsClass.enrollmentProcessCancelType)){
                if(!isSameMonth){
                    enroll.Stage__c = 'Cancelled';
                }
            }
            if(effectiveDate != NULL){
                enroll.Effective_Date__c = effectiveDate;
            }
           
            if(enroll.Effective_Date__c != NULL){
                enroll.Notice_Period_End_Date__c = effectiveDate;
                enroll.Notice_Period_Start_Date__c = NoticePeriodStartDate;
            }
        }
         system.debug('@@@effectiveDate'+effectiveDate);
        enroll.Advance_Action_Requested_By__c = Userinfo.getUserId();
        enroll.Package_Process_Request_Date__c = System.today();
        return enroll;
    }
*/
    private static Date getNextBillingDate(String enrolId){
        Date nextBillingDate;
        List<Subscription_Line_Item__c> subscriptionLineItemList = [SELECT Id, Next_Bill_Date__c FROM Subscription_Line_Item__c WHERE Enrolment__c =: enrolId];
        if(subscriptionLineItemList.size() > 0){
            nextBillingDate = subscriptionLineItemList[0].Next_Bill_Date__c;
        }
        return nextBillingDate;
    }
        
    Public class UpgradeDowngradePackageSummary{
        public String oldPackageId;
        public String newPackageId;
        public String oldPackageName;
        public String newduration;
        public String oldduration;
        public String newPackageName;
        public Decimal currentPackageDeposit;
        public Decimal newPackageDeposit;
        public String currentDayAndTime;
        public String effectiveDate; 
        public Decimal invoiceForCurrentMonth;
        public String newDayAndTime;
        public Package__c oldPackage;
        public Package__c newPackage;
        public Decimal invoiceTopup;
        public Decimal invoiceDepositTopup;
        public Decimal invoiceDepositLessonTopup;
        public Decimal positiveInvoiceAmount;
        public Decimal negativeInvoiceAmount;
    }
    
    public class UpDownSummary{
        public Package__c oldPack;
        public Package__c newPack;
        public Integer noOfBookingWithNewPack;
        public Integer noOfBookingWithOldPack;
    }
}