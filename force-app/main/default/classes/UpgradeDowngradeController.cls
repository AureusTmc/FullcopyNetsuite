/*
    Name            :     UpgradeDowngradeController
    Date            :     
    Author          :
    Description     :    This Controller is used for intrim invoice    

*/
public class UpgradeDowngradeController{
    
    public static String getEnrolmentId(Id bookingId){
        Booking__c booking = new Booking__c();
        List<Subscription_Line_Item__c> subscriptionList = new List<Subscription_Line_Item__c>();
        if(!String.isBlank(bookingId)){
            booking = [Select Id,Enrolment__c From Booking__c Where Id=:bookingId Limit 1];
            if(booking != null){
                return booking.Enrolment__c ;  
            }
        }
        return null;
    }
    public static Enrolment__c  getEnrolment(Id subscriptionId){
        
        List<Subscription_Line_Item__c> subLineList = new List<Subscription_Line_Item__c>();
        Enrolment__c  enrolment = new Enrolment__c ();
        subLineList = [Select Id,Name,Enrolment__c   From Subscription_Line_Item__c Where Subscription__c=:subscriptionId];
        if(subLineList.size()>0){
            enrolment = [Select Id,Name,Student__c,Student__r.Parent__c,Student__r.Parent__r.Available_Make_up_Units__c,Package__c,
                              Package__r.Unit_Fee__c,
                              Student__r.Available_Make_up_Units__c,Student__r.Stripe_Customer_Id__c,Student__r.Parent__r.Stripe_Customer_Id__c
                              From Enrolment__c Where Id=:subLineList[0].Enrolment__c ];
            if(enrolment != null){
                return enrolment;
            }
        }
        return null;
    }
    public static UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackage(Id enrollMentId,Date effectDate,Id PackageId,Id OldPackage, 
    Time timeslot, String currencyCode, String baseUrl, String apiKey, Decimal taxRate,string newTeacherId){
        UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
        Boolean flag = false;
        String invoiceId;
        Map<String,Package__c> mapOfPackageFee = getPackage(oldPackage,PackageId);
        Package__c oldPackg = mapOfPackageFee.get(OldPackage);
        Package__c newPackg = mapOfPackageFee.get(PackageId);
       //system.debug('@@@oldPackg'+oldPackg);
       //system.debug('@@@newPackg'+newPackg);
        Subscription_Line_Item__c objSubLineItem = fetchSubsLineItem(enrollmentId);
        Integer countWithOldPackage = 0;
        Integer countWithNewPackage = 0;
        Integer minutesOfFifthBooking = 0;
        Decimal currentPackageDeposit = 0;
        
        //Create MAp for Create fifthBookings
        Map<String, Booking__c> mapOfFifthBookings = new Map<String, Booking__c>();
        Date effectiveDate = effectDate; //objSubLineItem.Enrolment__r.Effective_Date__c;
          // // added by Nishi: 11-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
       //  // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 
        List<Booking__c> listOfBookings = fetchListOfBookings(enrollmentId);
       
        Decimal newPackageUnitPrice = 0;
        //Decimal newPackageFacilityPrice = 0;
        //Decimal gstFacilityAmount = 0;
        Decimal newPackageNextMonthPrice = 0;
        Decimal gstNextMonthAmount = 0;
        Decimal depositeFee = 0;
        Decimal totalAmount = 0; Decimal gstAmount = 0; Decimal totalWithNoGST = 0;
        Decimal fifthBookingPrice = 0;
        Decimal newPackageAdvanceUnitPrice = 0;
        Boolean isOssiaOrganization = false;
        
        if(string.isNotBlank(objSubLineItem.Enrolment__c) && string.isNotBlank(objSubLineItem.Enrolment__r.Center__c) && 
            string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__c) && string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name) &&
            objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssiaOrganization = true;
            }
        ////system.debug('@@listOfBookings'+listOfBookings);
        ////system.debug('@@@effectDate'+effectDate);
        //@Jatin, 23 October 2019, Change due to populate the tax amount on invoice line item. 
        for(Booking__c objBooking : listOfBookings){
            if(objBooking.Booking_Date__c >= effectiveDate){
                //system.debug('@@effectiveDate'+effectiveDate);
                //system.debug('@@objBooking.Type__c'+objBooking.Type__c);
                if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){//||objBooking.Type__c == ConstantsClass.groupLessonTypeBooking
                    newPackageUnitPrice += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                    //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    // if(isOssiaOrganization){
                    //     newPackageFacilityPrice += (newPackg.facility_Fee__c - oldPackg.facility_Fee__c);
                    // }
                    //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    if(taxRate > 0){
                    gstAmount += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c) * taxRate/100;
                        //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    //    if(isOssiaOrganization && newPackageFacilityPrice > 0){
                    //         gstFacilityAmount += (newPackg.facility_Fee__c - oldPackg.facility_Fee__c) * taxRate/100;
                    //    }
                        //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    }
                }      
            }
        }
        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        date nextBillDate = objSubLineItem.Next_Bill_Date__c;
        if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month()){
            List<Booking__c> listOfNextMonthBookings = fetchListOfNextMonthBookings(enrollmentId);
            for(Booking__c objBooking : listOfNextMonthBookings){
                if(objBooking.Booking_Date__c >= effectiveDate){
                    if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){//||objBooking.Type__c == ConstantsClass.groupLessonTypeBooking
                        newPackageNextMonthPrice += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c);
                        if(taxRate > 0){
                            gstNextMonthAmount += (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c) * taxRate/100;
                        }
                    }      
                }
            }
        }
        
        ////system.debug('@@@@@newPackageUnitPrice'+newPackageUnitPrice);
        ////system.debug('@@@@@gstAmount'+gstAmount);
        if(String.isNotBlank(enrollMentId)){
            currentPackageDeposit = AureusCalendarController.getDepositFromFile(enrollMentId);
        }
        
        depositeFee = newPackg.Deposit_Fee__c - currentPackageDeposit;
      
       totalAmount = (newPackageUnitPrice + gstAmount) + depositeFee;
       totalWithNoGST = newPackageUnitPrice + depositeFee;
         //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
        //  if(isOssiaOrganization && newPackageFacilityPrice > 0){
        //     totalAmount+=BillingUtility.roundOffAmount(newPackageFacilityPrice);
        //     totalWithNoGST+=BillingUtility.roundOffAmount(newPackageFacilityPrice);
        //     if(gstFacilityAmount > 0){
        //        totalAmount+=BillingUtility.roundOffAmount(gstFacilityAmount);
        //     }
        // }
      
        //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
        String stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c;
      
        //Summary Details for case for upgrade package.....
        upgradePackageCaseDetails.depositAmount = BillingUtility.roundOffAmount(depositeFee);
        Decimal lessonCharge = newPackageUnitPrice + gstAmount;
        if(newPackageNextMonthPrice != 0){
            totalAmount += (newPackageNextMonthPrice + gstNextMonthAmount);
            totalWithNoGST += newPackageNextMonthPrice;
            lessonCharge += (newPackageNextMonthPrice + gstNextMonthAmount);
            gstNextMonthAmount = BillingUtility.roundOffAmount(gstNextMonthAmount);
        }
        upgradePackageCaseDetails.lessonCharge = BillingUtility.roundOffAmount(lessonCharge);

          //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
        // if(isOssiaOrganization && newPackageFacilityPrice > 0){
        //     upgradePackageCaseDetails.lessonCharge+=BillingUtility.roundOffAmount(newPackageFacilityPrice);
        //     if(gstFacilityAmount > 0){
        //         upgradePackageCaseDetails.lessonCharge+=BillingUtility.roundOffAmount(gstFacilityAmount);
        //     }
        // }
        //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
        upgradePackageCaseDetails.isSuccess = true;
       //system.debug('@@@@@totalAmount'+totalAmount);
       //system.debug('@@@@@depositeFee'+depositeFee);
       //system.debug('@@@@@totalWithNoGST'+totalWithNoGST);
       totalAmount = BillingUtility.roundOffAmount(totalAmount);
       totalWithNoGST = BillingUtility.roundOffAmount(totalWithNoGST);
       totalAmount = BillingUtility.roundOffAmount(totalAmount);
       gstAmount = BillingUtility.roundOffAmount(gstAmount);
       
       
       // added by Nishi: 11-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
       
        //@Jatin, 23 October 2019, Commented due to populate the tax amount on invoice line item. 
        /*for(Booking__c objBooking : listOfBookings){
            if(objBooking.Booking_Date__c >= effectiveDate){
                if(objBooking.Type__c == ConstantsClass.bookTypeRegular){
                    countWithNewPackage +=1;
                }
            }
        }
        if(String.isNotBlank(enrollMentId)){
            currentPackageDeposit = AureusCalendarController.getDepositFromFile(enrollMentId);
        }
        Decimal depositeFee = (newPackg.Deposit_Fee__c - currentPackageDeposit);
        Decimal newPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNewPackage ;
        newPackageUnitPrice = BillingUtility.roundOffAmount(newPackageUnitPrice);
        Decimal fifthBookingPrice = (newPackg.Unit_Fee__c /Integer.valueOf(newPackg.duration__c))*minutesOfFifthBooking; 
        Decimal totalAmount = newPackageUnitPrice + fifthBookingPrice; //+ oldPackageUnitPrice 
        Decimal totalWithNoGST = 0;
        if(taxRate > 0){
            totalAmount += totalAmount*(taxRate/100);    
        }
        totalAmount +=   depositeFee ;
        totalWithNoGST += depositeFee;
        
        totalAmount = BillingUtility.roundOffAmount(totalAmount);        
        String stripeId = objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c;   
        
        //Summary Details for case for upgrade package.....
        upgradePackageCaseDetails.depositAmount = depositeFee;
        upgradePackageCaseDetails.lessonCharge = newPackageUnitPrice;            
        upgradePackageCaseDetails.lessonCharge += upgradePackageCaseDetails.lessonCharge*(taxRate/100);
        upgradePackageCaseDetails.isSuccess = true;*/
            
        if(String.isNotBlank(stripeId) && totalAmount > 0){
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId,totalAmount, currencyCode, baseUrl, apiKey); 
           //system.debug('@@chargeResponse'+chargeResponse);
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                flag = true;
                Invoice__c objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objSubLineItem.Subscription__r.Parent__c,constantsClass.paidStatus);
                objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
                Invoice_Line_Item__c inlineItemForChange = new Invoice_Line_Item__c();
                List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
                insert objInvoice;
               //system.debug('@@objInvoice'+objInvoice);
                if(String.isNotBlank(objInvoice.Id)){
                    upgradePackageCaseDetails.invoiceId = objInvoice.Id;
                }
                if(depositeFee > 0){
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(depositeFee), newPackg.Id,true, '');
                    inlineItemForChange.Is_Deposit__c = True;
                    inlineItemForChange.month__c = effectiveDate;
                    listOfInvoiceLineItems.add(inlineItemForChange);
                    
                }
                if(upgradePackageCaseDetails.lessonCharge > 0){
                  //system.debug('newPackageUnitPrice'+newPackageUnitPrice);
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageUnitPrice), newPackg.Id,FALSE, newTeacherId);
                    inlineItemForChange.month__c = effectiveDate;
                    listOfInvoiceLineItems.add(inlineItemForChange);
                    if(newPackageNextMonthPrice != 0){
                        inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageNextMonthPrice), newPackg.Id,FALSE, newTeacherId);
                        inlineItemForChange.month__c = nextMonthDate.addMonths(-1);
                        listOfInvoiceLineItems.add(inlineItemForChange);
                    }
                }
                 //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                // if(isOssiaOrganization && newPackageFacilityPrice > 0){
                //     //  for if Next Month billing invoice already created then we create 1 more invoice line item for adjuct next month intrim invoice
                //     if(nextMonthPackagefacilityPrice>0){
                //         newPackageFacilityPrice+=nextMonthPackagefacilityPrice;
                //        //system.debug('nextMonthPackageUnitPrice'+nextMonthPackagefacilityPrice);
                //     }
                //     // for if Next Month billing invoice already created then we create 1 more invoice line item for adjuct next month intrim invoice
                   
                //     inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageFacilityPrice), newPackg.Id,FALSE, newTeacherId);
                //     inlineItemForChange.month__c = effectiveDate;
                //     inlineItemForChange.Remarks__c = 'Facility Fee';
                //     listOfInvoiceLineItems.add(inlineItemForChange);
                // }
                 //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                
                if(totalWithNoGST > 0){
                    upgradePackageCaseDetails.total = totalWithNoGST;
                }
                if(fifthBookingPrice > 0){
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(fifthBookingPrice),newPackg.Id,FALSE, objSubLineItem.Enrolment__r.teacher__c);
                    inlineItemForChange.month__c = effectiveDate;
                    listOfInvoiceLineItems.add(inlineItemForChange);
                }
                if(listOfInvoiceLineItems.size() > 0){
                    INSERT listOfInvoiceLineItems;
                } 
               //system.debug('@@listOfInvoiceLineItems'+listOfInvoiceLineItems);
                objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                
                if(String.isNotBlank(baseUrl) && String.isNotBlank(apiKey)){
                    BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, baseUrl, apiKey);                    
                }

                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,totalAmount,ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = chargeResponse.Id;
                objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                INSERT objPayment; 
               //system.debug('objInvoice.Id'+objInvoice.Id);
               //system.debug('@@objPayment'+objPayment);
                if(objInvoice != NULL){
                    BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                }
                upgradePackageCaseDetails.enrolObj = updateEnrollment(enrollMentId,PackageId, timeslot, effectDate,newTeacherId);
                upgradePackageCaseDetails.enrolObj = fetchEnrolment(enrollMentId);
               //system.debug('@@@upgradePackageCaseDetails.enrolObj '+upgradePackageCaseDetails.enrolObj );
                if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                    SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                }
                
            }else{
               flag = false;
               upgradePackageCaseDetails.isSuccess = false;
            }    
        }else{
            flag = false;
        }
       //system.debug('@@upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails ;
    }
  
    Public static Subscription_Line_Item__c fetchSubsLineItem(String enrolId){
        return [SELECT Id,Subscription__c,Subscription__r.Parent__c,Subscription__r.Center__c,Subscription__r.Parent__r.Stripe_Customer_Id__c, 
                Enrolment__r.Lesson_Day__c,Enrolment__c, Enrolment__r.Effective_Date__c, Enrolment__r.teacher__c, Enrolment__r.Center__r.Country__c,
                Next_Bill_Date__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                Enrolment__r.Center__r.Organisation__r.Name
                 FROM Subscription_Line_Item__c WHERE Enrolment__c =: enrolId LIMIT 1];
    }
    
    public static Map<String,Package__c> getPackage(String oldPackageId,String newPackageId){
        return new Map<String,Package__c>([Select Id,Name,Unit_Fee__c,Deposit_Fee__c,Duration__c
                                            //,facility_Fee__c // added by nishi:17-Aug-2020: for manage Ossia center facility fees
                                             From Package__c WHERE 
                                            Id =:oldPackageId OR Id=: newPackageId ]);
    }
    
    public static Enrolment__c updateEnrollment(Id enrolMentId,Id packageId, Time newTimeSlot, Date effectiveDate,string newTeacherId){
        Enrolment__c enrol = new Enrolment__c();
        enrol.Id = enrolMentId;
          // added by nishi:start-11-Aug-2020: for manage ossia organisation new teacher
          if(string.isNotBlank(newTeacherId)){
            enrol.Teacher__c = newTeacherId;
            enrol.New_Teacher__c = newTeacherId;
        }
        // added by nishi:end-11-Aug-2020: for manage ossia organisation new teacher
        enrol.Package__c = packageId;
        enrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessCompletedStatus;
        enrol.Lesson_Start_time__c = newTimeSlot;
        enrol.Effective_Date__c = effectiveDate;
        enrol.New_Package_Id__c = packageId;
        enrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        enrol.Package_Process_Request_Date__c = System.today();
        enrol.Advance_Action_Requested_By__c = Userinfo.getUserId();
        enrol.Next_Lesson_Start_time__c = newTimeSlot;
        
        update enrol;
        return enrol;
    }
    public static List<Booking__c> fetchListOfBookings(String enrolmentId){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c, Status__c FROM Booking__c 
                WHERE Enrolment__c=:enrolmentId AND Booking_Date__c = THIS_MONTH
                 //jatin:7-jan-2020 : for now we calculate all booking Status__c !=: ConstantsClass.statusCanceled 
                //AND Status__c !=: ConstantsClass.statusCanceled
                ];
    }
    public static List<Booking__c> fetchListOfBookings(String enrolmentId,date effectiveDate,Date nextBillingDate){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c, Status__c FROM Booking__c 
                WHERE Enrolment__c=:enrolmentId AND 
                 Booking_Date__c >= :effectiveDate AND 
                Booking_Date__c < :nextBillingDate
                 //jatin:7-jan-2020 : for now we calculate all booking Status__c !=: ConstantsClass.statusCanceled 
                //AND Status__c !=: ConstantsClass.statusCanceled
                ];
    }
     // added by nishi: 12-Aug-2020: for get Next Billing Month Booking 
     public static List<Booking__c> fetchListOfNextMonthBookings(String enrolmentId){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c, Status__c FROM Booking__c 
                WHERE Enrolment__c=:enrolmentId 
                AND Booking_Date__c = Next_MONTH 
                ];
    }
    public static Enrolment__c fetchEnrolment(String enrolId){
        List<Enrolment__c> enrolList = [SELECT Id, effective_Date__c, Center__c, Parent__c, Package__c, Package_Process_Status__c,Lesson_Start_time__c,
                                        New_Package_Id__c, Package_Process_Type__c, Next_Lesson_Start_time__c FROM Enrolment__c WHERE Id =: enrolId];
        Enrolment__c enrolObj = new Enrolment__c();
        if(enrolList.size() > 0){
            enrolObj = enrolList[0];
        }
        
        return  enrolObj;
    }
    
}