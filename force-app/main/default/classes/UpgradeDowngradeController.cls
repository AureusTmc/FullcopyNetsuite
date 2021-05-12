/*
    Name            :     UpgradeDowngradeController
    Date            :     
    Author          :
    Description     :    This Controller is used for intrim invoice    
test class  :UpgradeDowngradeControllertest
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
    Time timeslot, String currencyCode, String baseUrl, String apiKey, Decimal taxRate,string newTeacherId,Boolean isPromotionalEnrolment){
        UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeEnrolmentProcessController.UpgradeCaseCreation();
        Boolean flag = false;
        String invoiceId;
        enrolment__c enrolmentObj = fetchEnrolment(enrollMentId);
        Map<String,Package__c> mapOfPackageFee = getPackage(oldPackage,PackageId);
        Package__c oldPackg = mapOfPackageFee.get(OldPackage);
        Package__c newPackg = mapOfPackageFee.get(PackageId);
       //system.debug('@@@oldPackg'+oldPackg);
       //system.debug('@@@newPackg'+newPackg);
        Subscription_Line_Item__c objSubLineItem = fetchSubsLineItem(enrollMentId);
        date nextBillDate = objSubLineItem.Next_Bill_Date__c;
        Integer countWithOldPackage = 0;
        Integer countWithNewPackage = 0;
        Integer minutesOfFifthBooking = 0;
        Decimal currentPackageDeposit = 0;
        
        //Create MAp for Create fifthBookings
        Map<String, Booking__c> mapOfFifthBookings = new Map<String, Booking__c>();
        Date effectiveDate = effectDate; //objSubLineItem.Enrolment__r.Effective_Date__c;
          // // added by Nishi: 11-aug-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
       //  // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 
        List<Booking__c> listOfBookings =  fetchListOfBookings(enrollmentId,effectDate);
       
        Decimal newPackageUnitPrice = 0;
        Decimal currentInvoiceAmount=0;
        //Decimal newPackageFacilityPrice = 0;
        //Decimal gstFacilityAmount = 0;
        Decimal newPackageNextMonthPrice = 0;
        Decimal nextmonthInvoiceAmount=0;
        Decimal gstNextMonthAmount = 0;
        Decimal depositeFee = 0;
        Decimal totalAmount = 0; Decimal gstAmount = 0; Decimal totalWithNoGST = 0;
        Decimal fifthBookingPrice = 0;
        Decimal newPackageAdvanceUnitPrice = 0;
        Boolean isOssiaOrganization = false;
        Map<string,Decimal> invoiceAdjustmentMap = new Map<string,Decimal>();
        Integer countWithNewPackageupgrade = 0;
        Integer countWithDiscountOldPackage = 0;
        Integer countNextMonthPackageupgrade = 0;
        Decimal discountamount =0;
        Decimal noOfMonths = isPromotionalEnrolment && String.isNotBlank(oldPackg.Promotion_period_In_months__c) ? Integer.valueOf(oldPackg.Promotion_period_In_months__c) : 1;
       
        if(string.isNotBlank(objSubLineItem.Enrolment__c) && string.isNotBlank(objSubLineItem.Enrolment__r.Center__c) && 
            string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__c) && string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name) &&
            objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssiaOrganization = true;
            }
        system.debug('@@listOfBookings'+listOfBookings);
        system.debug('@@listOfBookings'+listOfBookings.size());
        system.debug('@@@effectDate'+effectDate);
        decimal packageunitFee= isPromotionalEnrolment ? (oldPackg.Package_Fee__c/noOfMonths)/4 : oldPackg.Unit_Fee__c; 
            
        //@Jatin, 23 October 2019, Change due to populate the tax amount on invoice line item. 
        for(Booking__c objBooking : listOfBookings){
            if(objBooking.Booking_Date__c >= effectiveDate){
                //system.debug('@@effectiveDate'+effectiveDate);
                //system.debug('@@objBooking.Type__c'+objBooking.Type__c);
                if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){//||objBooking.Type__c == ConstantsClass.groupLessonTypeBooking
                    countWithNewPackageupgrade +=1;

                    newPackageUnitPrice +=newPackg.Unit_Fee__c - packageunitFee;
                    //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    // if(isOssiaOrganization){
                    //     newPackageFacilityPrice += (newPackg.facility_Fee__c - oldPackg.facility_Fee__c);
                    // }
                    //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    if(taxRate > 0){
                    gstAmount += ((newPackg.Unit_Fee__c - packageunitFee) * (taxRate/100));
                        //start: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    //    if(isOssiaOrganization && newPackageFacilityPrice > 0){
                    //         gstFacilityAmount += (newPackg.facility_Fee__c - oldPackg.facility_Fee__c) * taxRate/100;
                    //    }
                        //end: added by nishi:17-aug-2020: for if ossia Adhoc booking created then we added facility_Fee__c with unitfee
                    }
                }      
            }
        }
        system.debug('@@newPackageUnitPrice'+newPackageUnitPrice);
        system.debug('@@gstAmount'+gstAmount);
         // added by nishi: 23-oct-2020: now we create full lesson fees for the enhanced package for the remaining period in the current and next month invoice
         invoiceAdjustmentMap.put('positiveInvoiceAmount',(countWithNewPackageupgrade * newPackg.Unit_Fee__c));
         invoiceAdjustmentMap.put('negativeInvoiceAmount',(countWithNewPackageupgrade * packageunitFee));
         system.debug('countWithNewPackageupgrade'+countWithNewPackageupgrade);
          // added by nishi: 23-oct-2020:end: now we create full lesson fees for the enhanced package for the remaining period in the current and next month invoice
        if(isPromotionalEnrolment){
            date startDate = date.newInstance(effectiveDate.addMonths(1).year(), effectiveDate.addMonths(1).month(),1);
             listOfBookings =  fetchListOfBookings(enrollmentId,startDate,nextBillDate) ;
             system.debug('@@listOfBookings'+listOfBookings);
             system.debug('@@listOfBookings'+listOfBookings.size());
             if(listOfBookings != null && listOfBookings.size() > 0){
                for(Booking__c objBooking : listOfBookings){
                    if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){
                        countWithDiscountOldPackage+=1;
                        if(objBooking.Booking_Date__c >= startDate && objBooking.Booking_Date__c < nextBillDate){
                            newPackageUnitPrice +=newPackg.Unit_Fee__c - packageunitFee;//oldPackg.Unit_Fee__c;
                            if(taxRate > 0){
                                gstAmount += ((newPackg.Unit_Fee__c - packageunitFee/*oldPackg.Unit_Fee__c*/) * (taxRate/100));
                            }
                        }
                    }
                }
                system.debug('@@newPackageUnitPrice'+newPackageUnitPrice);
                system.debug('@@gstAmount'+gstAmount);
            }
        }
        // 21-Oct-2020 : @@nishi  :if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
        else{
            // check next month invoice billing already exist or not  
            date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
            if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month()){
                List<Booking__c> listOfNextMonthBookings = fetchListOfNextMonthBookings(enrollmentId);
                for(Booking__c objBooking : listOfNextMonthBookings){
                    if(objBooking.Booking_Date__c >= effectiveDate){
                        if(objBooking.Type__c == ConstantsClass.bookTypeRegular ){
                            countNextMonthPackageupgrade+=1;
                            newPackageNextMonthPrice += newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c;
                            if(taxRate > 0){
                                gstNextMonthAmount += ((newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)* (taxRate/100));
                            }
                        }      
                    }
                }
                 // added by nishi: 23-oct-2020: now we create full lesson fees for the enhanced package for the remaining period in the current and next month invoice
                invoiceAdjustmentMap.put('positiveNextMonthInvoiceAmount',(countNextMonthPackageupgrade * newPackg.Unit_Fee__c));
                invoiceAdjustmentMap.put('negativeNextMonthInvoiceAmount',(countNextMonthPackageupgrade * oldPackg.Unit_Fee__c));
                 // added by nishi: 23-oct-2020:end: now we create full lesson fees for the enhanced package for the remaining period in the current and next month invoice
            }// check next month invoice billing already exist or not 

        }// 21-Oct-2020 : @@nishi  :if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
        
        
        system.debug('@@@@@newPackageUnitPrice'+newPackageUnitPrice);
        system.debug('@@@@@gstAmount'+gstAmount);
        if(String.isNotBlank(enrollMentId)){
            currentPackageDeposit = AureusCalendarController.getDepositFromFile(enrollMentId);
        }
        
        depositeFee = (newPackg.Deposit_Fee__c - currentPackageDeposit);
      
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
        String stripeId = string.isNotBlank(objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c) ? objSubLineItem.Subscription__r.Parent__r.Stripe_Customer_Id__c:'';
      
        //Summary Details for case for upgrade package.....
        upgradePackageCaseDetails.depositAmount = BillingUtility.roundOffAmount(depositeFee);
        Decimal lessonCharge = newPackageUnitPrice + gstAmount;
        if(newPackageNextMonthPrice != 0){
            totalAmount += (newPackageNextMonthPrice + gstNextMonthAmount);
            totalWithNoGST += newPackageNextMonthPrice;
            lessonCharge += (newPackageNextMonthPrice + gstNextMonthAmount);
            gstNextMonthAmount = BillingUtility.roundOffAmount(gstNextMonthAmount);
        }
          //added by nishi: 24-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  
        
        if(isPromotionalEnrolment && oldPackg.Promotion_Discount__c != null){
            Decimal preUnitDiscountAmount = ((oldPackg.Promotion_Discount__c / noOfMonths)/4);
            invoiceAdjustmentMap.put('negativeInvoiceDiscountAmount',preUnitDiscountAmount*countWithNewPackageupgrade);
            countWithNewPackageupgrade += countWithDiscountOldPackage;
            decimal oldpackageDiscountAmount =  preUnitDiscountAmount*countWithNewPackageupgrade;
            decimal gstDiscountAmount =0;
            if(taxRate > 0){
                gstDiscountAmount = (oldpackageDiscountAmount* (taxRate/100));
            }
            system.debug('@@oldpackageDiscountAmount'+oldpackageDiscountAmount);
            system.debug('@@gstDiscountAmount'+gstDiscountAmount);
            totalAmount += (oldpackageDiscountAmount + gstDiscountAmount);
            totalWithNoGST += oldpackageDiscountAmount;
            lessonCharge += (oldpackageDiscountAmount + gstDiscountAmount);
           
        }
          //added by nishi: 24-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  
        
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
       */
        system.debug('invoiceAdjustmentMap'+invoiceAdjustmentMap);
        system.debug('totalAmount'+totalAmount);
        system.debug('depositeFee'+depositeFee);
        if(totalAmount != 0){
            /*if(isPromotionalEnrolment){
                upgradePackageCaseDetails = invoiceForupgradePromotionalPackages( upgradePackageCaseDetails, enrolmentObj,
                                                stripeId,   currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId,  invoiceAdjustmentMap,BillingUtility.roundOffAmount(totalAmount));
            }else{*/    
                    upgradePackageCaseDetails = invoiceForupgradePackages( upgradePackageCaseDetails, enrolmentObj,
                                                stripeId,   currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, invoiceAdjustmentMap,
                                                BillingUtility.roundOffAmount(totalAmount),isPromotionalEnrolment,isOssiaOrganization);
            //}
            if(upgradePackageCaseDetails.isSuccess){
                if(totalWithNoGST >0){
                    upgradePackageCaseDetails.total =BillingUtility.roundOffAmount(totalWithNoGST);
               }
            }
        }else{
            upgradePackageCaseDetails.isSuccess = false;
        }
       //system.debug('@@upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails ;
    }
    /*24-oct-2020:added by nishi:
    we worked on the following criteria:
      a). we create a credit memo for the previous package for the remaining period. This amount will be adjusted in subsequent invoices.
      b). We have created a new invoice for additional deposits and full lesson fees for the enhanced package for the remaining period in the current invoice. This invoice is adjusted with a credit memo. If a credit memo adjustment amount is less then the invoice amount then we charged via Stripe.
      c).  We change the nextbilling in the subscription and subscription line item on the first day of the next month.  
    */

    
    /*Private static UpgradeEnrolmentProcessController.UpgradeCaseCreation invoiceForupgradePromotionalPackages(UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,enrolment__c enrolmentObj,
                                                                            String stripeId,string currencyCode,string baseUrl,string apiKey,Subscription_Line_Item__c objSubLineItem ,Decimal depositeFee,
                                                                            Package__c oldPackg, Package__c newPackg, Date effectDate, Time timeslot, Decimal taxRate,string newTeacherId,
                                                                            Map<string,Decimal> invoiceAdjustmentMap,Decimal totalAmount){
            
            List<Invoice__c> listOfInvoice = getInvoiceDetails(enrolmentObj,effectDate.addmonths(1),objSubLineItem) ;
            Map<String,Decimal> parentCreditMemoTotal =  getCreditMemoForPrepaymentInvoiceAmount(listOfInvoice, enrolmentObj, effectDate);
            //Map<String,Decimal> parentCreditMemoTotal = BillingUtility.getParentCreditMemoMap(mapOfParentPrepaymentCreditMemo);
            Decimal accumulatedCreditMemoAmount =0;
            Decimal diffrenceAmount = 0;
            if(parentCreditMemoTotal.containsKey(enrolmentObj.parent__c)){
                accumulatedCreditMemoAmount = parentCreditMemoTotal.get(enrolmentObj.parent__c);
            }
            system.debug('accumulatedCreditMemoAmount'+accumulatedCreditMemoAmount);
            system.debug('totalAmount'+totalAmount);
            if(accumulatedCreditMemoAmount > 0){
                if(accumulatedCreditMemoAmount < totalAmount){ 
                    diffrenceAmount = totalAmount - accumulatedCreditMemoAmount ;
                }
                system.debug('diffrenceAmount'+diffrenceAmount);
                if(diffrenceAmount > 0){
                    upgradePackageCaseDetails = createChargeForCustomer( upgradePackageCaseDetails, enrolmentObj,
                                                    stripeId,   currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                    oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, invoiceAdjustmentMap,diffrenceAmount,true,listOfInvoice);
                    
                }else{
                    Map<String,List<Credit_Memo__c>>  mapOfParentCurrentMonthCreditMemo = createCreditMemoForCurrentMonthUpgradeProcess(listOfInvoice,invoiceAdjustmentMap,enrolmentObj,effectDate,objSubLineItem, taxRate, true,oldPackg.id);
                    //commented by nishi: 28-oct-2020:for change requirement now we create one credit memo and adjust into upgraded invoice
                    //map<string,List<Credit_Memo__c>> mapOfParentPrepaymentCreditMemo =createCreditMemoForPrepaymentInvoice(listOfInvoice,enrolmentObj, effectDate);
                    system.debug('mapOfParentCurrentMonthCreditMemo'+mapOfParentCurrentMonthCreditMemo);
                    //system.debug('mapOfParentPrepaymentCreditMemo'+mapOfParentPrepaymentCreditMemo);
                    upgradePackageCaseDetails =  createUpgradedAmountInvoice(listOfInvoice,objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, enrolmentObj,mapOfParentCurrentMonthCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,true);
                    if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        upgradePackageCaseDetails.isSuccess = true;
                         //This invoice should be adjusted with the prepayment next months created new credit memos
                        //commented by nishi: 28-oct-2020:for change requirement now we create one credit memo and adjust into upgraded invoice
                        // adjustPendingCreditMemoDeposit(enrolmentObj,effectDate,upgradePackageCaseDetails.invoiceId,mapOfParentPrepaymentCreditMemo,false);
                         if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                            BillingUtility.createAttachment(new Set<String>{upgradePackageCaseDetails.invoiceId});
                        }
                    }else{
                        upgradePackageCaseDetails.isSuccess = false;
                    } 
                }

                if(upgradePackageCaseDetails.isSuccess){
                    upgradePackageCaseDetails.enrolObj = updateEnrollment(enrolmentObj.id, newPackg.Id, timeslot, effectDate,newTeacherId);
                    upgradePackageCaseDetails.enrolObj = fetchEnrolment(enrolmentObj.id);
                } 
            }else{
                return invoiceForupgradePackages( upgradePackageCaseDetails, enrolmentObj,
                                                    stripeId,   currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                    oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, invoiceAdjustmentMap,totalAmount,true);
            }                                                          
        return upgradePackageCaseDetails;
    }*/

    public static UpgradeEnrolmentProcessController.UpgradeCaseCreation  createChargeForCustomer(UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,enrolment__c enrolmentObj,
                                                        String stripeId,string currencyCode,string baseUrl,string apiKey,Subscription_Line_Item__c objSubLineItem ,Decimal depositeFee,
                                                        Package__c oldPackg, Package__c newPackg, Date effectDate, Time timeslot, Decimal taxRate,string newTeacherId,
                                                        Map<string,Decimal> invoiceAdjustmentMap,Decimal totalAmount,Boolean isPromotionalEnrolment, List<Invoice__c> listOfInvoice,Boolean isossiaOrganisation){
            Payment__c objPayment = new Payment__c();
            Invoice__c objInvoice = new Invoice__c();
            system.debug('totalAmount'+totalAmount);
            if(totalAmount > 0){
                if(string.isNotBlank(stripeId)){
                    BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId,totalAmount, currencyCode, baseUrl, apiKey); 
                    if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                        Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = createCreditMemoForCurrentMonthUpgradeProcess(listOfInvoice,invoiceAdjustmentMap,enrolmentObj,effectDate,objSubLineItem, taxRate, isPromotionalEnrolment,oldPackg.id);
                        upgradePackageCaseDetails =  createUpgradedAmountInvoice(listOfInvoice,objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, enrolmentObj,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,isPromotionalEnrolment);
                        //commented by nishi: 28-oct-2020:for change requirement now we create one credit memo and adjust into upgraded invoice
                        /*if(isPromotionalEnrolment){
                            List<Credit_Memo__c> mapOfParentPrepaymentCreditMemo =createCreditMemoForPrepaymentInvoice(listOfInvoice,enrolmentObj, effectDate);
                            adjustPendingCreditMemoDeposit(enrolmentObj,effectDate,upgradePackageCaseDetails.invoiceId,mapOfParentPrepaymentCreditMemo,false);
                        }*/
                        if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                            objInvoice = [SELECT Id,Name,Total_Amount__c,Balance_Amount__c,Status__c, Parent_Account__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                            objInvoice.Status__c = constantsClass.paidStatus;
                            update objInvoice;
                        }
                        upgradePackageCaseDetails.isSuccess = true;
                        system.debug('@@@objInvoice '+objInvoice);
                        if(!Test.isRunningTest() && String.isNotBlank(baseUrl) && String.isNotBlank(apiKey)){
                            BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, baseUrl, apiKey);                    
                        }
                        objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,totalAmount,ConstantsClass.successStatus);
                        objPayment.Transaction_ID__c = chargeResponse.Id;
                        objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                        INSERT objPayment; 
                        system.debug('@@@objPayment '+objPayment);
                        if(objInvoice != NULL){
                            BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                        }
                        system.debug('@@@upgradePackageCaseDetails.enrolObj '+upgradePackageCaseDetails.enrolObj );
                        if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                            SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                        }
                    }else{
                        upgradePackageCaseDetails.isSuccess = false;
                        if(isossiaOrganisation){
                            Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = createCreditMemoForCurrentMonthUpgradeProcess(listOfInvoice,invoiceAdjustmentMap,enrolmentObj,effectDate,objSubLineItem, taxRate, isPromotionalEnrolment,oldPackg.id);
                            upgradePackageCaseDetails =  createUpgradedAmountInvoice(listOfInvoice,objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, enrolmentObj,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,isPromotionalEnrolment);
                            if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                                upgradePackageCaseDetails.isSuccess = true;
                            }
                            if(objInvoice != NULL){
                                BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                            }
                        }
                    } 
                }else{
                    upgradePackageCaseDetails.isSuccess = false;
                     //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                     if(isossiaOrganisation){
                        Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = createCreditMemoForCurrentMonthUpgradeProcess(listOfInvoice,invoiceAdjustmentMap,enrolmentObj,effectDate,objSubLineItem, taxRate, isPromotionalEnrolment,oldPackg.id);
                        upgradePackageCaseDetails =  createUpgradedAmountInvoice(listOfInvoice,objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, enrolmentObj,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,isPromotionalEnrolment);
                        if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                            upgradePackageCaseDetails.isSuccess = true;
                            BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{upgradePackageCaseDetails.invoiceId});
                        }
                    }
                     //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                } 
            }else{
                upgradePackageCaseDetails.isSuccess = false;
                system.debug('isPromotionalEnrolment'+isPromotionalEnrolment);
                if(isPromotionalEnrolment){
                    Map<String,List<Credit_Memo__c>>  mapOfParentCreditMemo = createCreditMemoForCurrentMonthUpgradeProcess(listOfInvoice,invoiceAdjustmentMap,enrolmentObj,effectDate,objSubLineItem, taxRate, isPromotionalEnrolment,oldPackg.id);
                    upgradePackageCaseDetails =  createUpgradedAmountInvoice(listOfInvoice,objSubLineItem, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId, enrolmentObj,mapOfParentCreditMemo,upgradePackageCaseDetails,invoiceAdjustmentMap,isPromotionalEnrolment);
                    if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        upgradePackageCaseDetails.isSuccess = true;
                    }
                    if(objInvoice != NULL){
                        BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                    }
                }
               
            } 
            system.debug('upgradePackageCaseDetails'+upgradePackageCaseDetails);
            return upgradePackageCaseDetails;
    }

    //We have created a new invoice for additional deposits and full lesson fees for the enhanced package for the remaining period in the current invoice. This invoice is adjusted with a credit memo
    public static UpgradeEnrolmentProcessController.UpgradeCaseCreation createUpgradedAmountInvoice(List<Invoice__c> listOfInvoice,Subscription_Line_Item__c objSubLineItem,Decimal depositeFee,
        Package__c oldPackg, Package__c newPackg, Date effectDate, Decimal taxRate,string newTeacherId,Enrolment__c enrolmentObj,
        Map<String,List<Credit_Memo__c>> mapOfParentCurrentCreditMemo, UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,
        Map<string,Decimal> invoiceAdjustmentMap,Boolean isPromotionalEnrolment){
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Decimal positiveInvoiceAmount  = invoiceAdjustmentMap.containsKey('positiveInvoiceAmount') && invoiceAdjustmentMap.get('positiveInvoiceAmount') != null ? (invoiceAdjustmentMap.get('positiveInvoiceAmount')) : 0;
        Decimal positiveNextMonthInvoiceAmount  = invoiceAdjustmentMap.containsKey('positiveNextMonthInvoiceAmount') && invoiceAdjustmentMap.get('positiveNextMonthInvoiceAmount') != null? (invoiceAdjustmentMap.get('positiveNextMonthInvoiceAmount')) : 0;
         
        Invoice__c objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objSubLineItem.Subscription__r.Parent__c,constantsClass.dueStatus);
        objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
        insert objInvoice;
        system.debug('objInvoice'+objInvoice);
        Invoice_Line_Item__c inlineItemForChange = new Invoice_Line_Item__c();
        if(String.isNotBlank(objInvoice.Id)){
            upgradePackageCaseDetails.invoiceId = objInvoice.Id;
            if(depositeFee > 0){
                inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,depositeFee, newPackg.Id,true, '');
                inlineItemForChange.Is_Deposit__c = True;
                inlineItemForChange.month__c = effectDate;
                listOfInvoiceLineItems.add(inlineItemForChange);
            }
            /*
            if(upgradePackageCaseDetails.lessonCharge > 0){
                inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageUnitPrice), newPackg.Id,FALSE, newTeacherId);
                inlineItemForChange.month__c = effectDate;
                listOfInvoiceLineItems.add(inlineItemForChange);
                if(newPackageNextMonthPrice != 0){
                    inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageNextMonthPrice), newPackg.Id,FALSE, newTeacherId);
                    inlineItemForChange.month__c = nextMonthDate.addMonths(-1);
                    listOfInvoiceLineItems.add(inlineItemForChange);
                }
            }*/
            // added by nishi: 23-oct-2020: now we create full lesson fees for the enhanced package for the remaining period in the current and next month invoice
            if(positiveInvoiceAmount > 0){
                inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,positiveInvoiceAmount, newPackg.Id,FALSE, newTeacherId);
                inlineItemForChange.month__c = effectDate;
                listOfInvoiceLineItems.add(inlineItemForChange);
                
            }
            if(positiveNextMonthInvoiceAmount != 0){
                date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
                inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,positiveNextMonthInvoiceAmount, newPackg.Id,FALSE, newTeacherId);
                inlineItemForChange.month__c = nextMonthDate.addMonths(-1);
                listOfInvoiceLineItems.add(inlineItemForChange);
            }
            if(isPromotionalEnrolment){
                List<Invoice_line_item__c> listOfInvoiceLineItemForPrepaymentInvoice = createInvoiceLineItemForPrepaymentInvoice(objInvoice.id,listOfInvoice, objSubLineItem,enrolmentObj,newTeacherId,newPackg);
                if(listOfInvoiceLineItemForPrepaymentInvoice != null && listOfInvoiceLineItemForPrepaymentInvoice.size() > 0){
                    listOfInvoiceLineItems.addAll(listOfInvoiceLineItemForPrepaymentInvoice);
                }
            }
            // added by nishi: 23-oct-2020:end: now we create full lesson fees for the enhanced package for the remaining period in the current and next month invoice
            /*if(fifthBookingPrice > 0){
                inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(fifthBookingPrice),newPackg.Id,FALSE, objSubLineItem.Enrolment__r.teacher__c);
                inlineItemForChange.month__c = effectDate;
                listOfInvoiceLineItems.add(inlineItemForChange);
            }*/
            system.debug('listOfInvoiceLineItems'+listOfInvoiceLineItems);
            if(listOfInvoiceLineItems.size() > 0){
                INSERT listOfInvoiceLineItems;
            } 
            

            adjustPendingCreditMemoDeposit(enrolmentObj,effectDate,objInvoice.id,mapOfParentCurrentCreditMemo,true);
        }
       return upgradePackageCaseDetails;
    }
    
    public static List<invoice_Line_item__c> createInvoiceLineItemForPrepaymentInvoice(string objectOfInvoiceId,List<Invoice__c> listOfInvoice, 
    Subscription_Line_Item__c objSubLineItem ,Enrolment__c objEnrol,string newTeacher,package__c newPackage){
        List<invoice_Line_item__c> newPackageinvoiceLineItemList = new List<invoice_Line_item__c>();
                            
        if(listOfInvoice != null && listOfInvoice.size() > 0){
            for(Invoice__c objInvoice : listOfInvoice){
                if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                    // if invoice line item month is greater then effective month then we create credit memo and added credit memo line item
                    for(invoice_Line_item__c objOldInvoiceLineItem : objInvoice.Invoice_Line_Items__r){

                        if(!objOldInvoiceLineItem.Is_discount__c && !objOldInvoiceLineItem.Is_deposit__c){
                            decimal newpackageamount = newPackage.unit_fee__c* 4;
                            Invoice_Line_Item__c inlineItemForupdate = PackageUpgradeController.createInvoiceLineItem(objectOfInvoiceId,objSubLineItem,newpackageamount, newPackage.id,false,newTeacher);
                            inlineItemForupdate.month__c = objOldInvoiceLineItem.month__c;
                            newPackageinvoiceLineItemList.add(inlineItemForupdate);
                        }
                    }
                }
            }
        }
        return newPackageinvoiceLineItemList;
    }
     
    //new invoice amount  adjusted with the credit memo
    public static void adjustPendingCreditMemoDeposit(enrolment__c enrolmentObj,Date effectDate,string invoiceId,Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo,Boolean getTotalAmount ){
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        Map<String, Date> mapOfParentEnrolmentLastDate = new Map<String, Date>();
        for(Invoice__c invoiceObj : [SELECT Id, Name,Parent_Account__c,Total_Amount__c, Remarks__c,Invoice_Date__c,Parent_Account__r.Centre_Name__c,
                                        Center__r.Country__r.Tax_Rate__c,Credit_Memo_Amount__c,Balance_Amount__c,
                                        Parent_Account__r.Total_Payment_Credit_Available__c,
                                        Total_Invoice_Amount__c,Status__c,Parent_Account__r.Total_Credit_Memo_Available__c,
                                        (SELECT Id, Enrolment__r.id,Enrolment__r.Package_Process_Type__c ,
                                            Enrolment__r.Effective_Date__c ,Package__c
                                            FROM Invoice_Line_Items__r) 
                                        FROM Invoice__c 
                                    WHERE Id =: invoiceId]){
                                        invoiceList.add(invoiceObj);
            for(Invoice_Line_Item__c  lineItemObj : invoiceObj.Invoice_Line_Items__r){
                if(mapOfParentEnrolmentLastDate.containsKey(invoiceObj.Parent_Account__c) && 
                    mapOfParentEnrolmentLastDate.get(invoiceObj.Parent_Account__c) < lineItemObj.Enrolment__r.Effective_Date__c){
                    mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                }else if(String.isNotBlank(lineItemObj.Enrolment__c) && lineItemObj.Enrolment__r.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType 
                        && lineItemObj.Enrolment__r.Effective_Date__c != NULL){
                    mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                }
            }
        }        
        BillingUtility.adjustPendingCreditMemoDeposit(invoiceList, new Set<String>{invoiceId}, new Set<String>{enrolmentObj.Parent__c},mapOfParentEnrolmentLastDate,getTotalAmount,mapOfParentCreditMemo,new Map<String, Boolean>{enrolmentObj.Parent__c=>true});
    }

     //added by nishi: 23-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  and create crdit memo  all prepayement effective months then adjusted into next monthbilling
     public static Map<String,decimal> getCreditMemoForPrepaymentInvoiceAmount(List<Invoice__c> listOfInvoice,enrolment__c enrolmentObj,Date effectDate){
        map<string,decimal> mapOfCreditMemosTotalamount = new map<string,decimal>();
       
        if(listOfInvoice != null && listOfInvoice.size() > 0){
            for(Invoice__c objInvoice : listOfInvoice){
                decimal totalRemainingAmount = mapOfCreditMemosTotalamount.containsKey(objInvoice.Parent_Account__c) ? mapOfCreditMemosTotalamount.get(objInvoice.Parent_Account__c):0;
                if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                    for(Invoice_Line_Item__c objInvLine : objInvoice.Invoice_Line_Items__r){
                        totalRemainingAmount +=(objInvLine.Amount__c + objInvLine.GST_Amount__c);
                    }
                }
                mapOfCreditMemosTotalamount.put(objInvoice.Parent_Account__c,totalRemainingAmount);
            }
            system.debug('mapOfCreditMemosTotalamount'+mapOfCreditMemosTotalamount);
        }
        
        return mapOfCreditMemosTotalamount;
   }

   
   public static List<Credit_memo_line_item__c>  createCreditMemoForPrepaymentInvoice(Subscription_Line_Item__c  objSubLineItem,enrolment__c enrolmentObj,Date effectDate){
    List<Invoice__c> listOfInvoice = UpgradeDowngradeController.getInvoiceDetails(enrolmentObj,effectDate.addmonths(1),objSubLineItem) ;
    List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
    List<Invoice_Line_Item__c> updateInvoiceLineItem = new List<Invoice_Line_Item__c>(); 
    system.debug('listOfInvoice'+listOfInvoice);
    set<string> creditmemoIds =new set<string>();
    if(listOfInvoice != null && listOfInvoice.size() > 0){
        for(Invoice__c objInvoice : listOfInvoice){
            if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                // if invoice line item month is greater then effective month then we create credit memo and added credit memo line item
                for(Invoice_Line_Item__c objInvLine : objInvoice.Invoice_Line_Items__r){
                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(objInvLine.Amount__c,
                                        objInvLine.GST_Amount__c,objInvLine.Package__c,
                                        objInvLine.Enrolment__c,objInvLine.id,objInvLine.Remarks__c,objInvLine.Month__c);
                    objCreditLineItem.Is_Deposit__c=objInvLine.Is_Deposit__c;
                    objCreditLineItem.Is_Discount__c=objInvLine.Is_Discount__c;
                    listOfCreditmemolineitem.add(objCreditLineItem);                                      
                    //Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                    Invoice_Line_Item__c objupdateInvLine = new Invoice_Line_Item__c(id=objInvLine.id,Credit_Memo_Amount__c = objInvLine.Amount__c);
                    if(objInvLine.GST_Amount__c != Null ){
                        objupdateInvLine.Credit_Memo_Tax__c = objInvLine.GST_Amount__c;
                    }
                    updateInvoiceLineItem.add(objupdateInvLine);
                }
            }
        }
        if(updateInvoiceLineItem != null && updateInvoiceLineItem.size() > 0){
            update updateInvoiceLineItem;
        }
    }
    
    return listOfCreditmemolineitem;
}
  
//added by nishi: 23-oct-2020: if enrolment package type is prepayament and promo and Promotion_Discount__c found then we calculate discount amount for regular booking  and create crdit memo  all prepayement effective months then adjusted into next monthbilling
public static Map<String,List<Credit_Memo__c>> createCreditMemoForPrepaymentInvoice(List<Invoice__c> listOfInvoice,enrolment__c enrolmentObj,Date effectDate,string remark){
    map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
    map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
    List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
    List<Invoice_Line_Item__c> updateInvoiceLineItem = new List<Invoice_Line_Item__c>(); 
    system.debug('listOfInvoice'+listOfInvoice);
    set<string> creditmemoIds =new set<string>();
    if(listOfInvoice != null && listOfInvoice.size() > 0){
        for(Invoice__c objInvoice : listOfInvoice){
            listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
            if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                // if invoice line item month is greater then effective month then we create credit memo and added credit memo line item
                Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objInvoice.Parent_Account__c,objInvoice.Center__c,objInvoice.Id, effectDate,remark);
                objCreditMemo.Payment_Method__c =  objInvoice.Payments__r[0].Method_of_Payment__c;
                system.debug('objInvoice.Invoice_Line_Items__r'+objInvoice.Invoice_Line_Items__r);
                for(Invoice_Line_Item__c objInvLine : objInvoice.Invoice_Line_Items__r){
                    if(mapOfCreditmemolineitem.containskey(objInvoice.id)){
                        listOfCreditmemolineitem = mapOfCreditmemolineitem.get(objInvoice.id);
                    }
                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(objInvLine.Amount__c,
                                        objInvLine.GST_Amount__c,objInvLine.Package__c,
                                        objInvLine.Enrolment__c,objInvLine.id,objInvLine.Remarks__c,objInvLine.Month__c);
                    objCreditLineItem.Is_Deposit__c=objInvLine.Is_Deposit__c;
                    objCreditLineItem.Is_Discount__c=objInvLine.Is_Discount__c;
                    listOfCreditmemolineitem.add(objCreditLineItem);                                      
                    mapOfCreditmemolineitem.put(objInvoice.id,listOfCreditmemolineitem);
                
                    //Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                    Invoice_Line_Item__c objupdateInvLine = new Invoice_Line_Item__c(id=objInvLine.id,Credit_Memo_Amount__c = objInvLine.Amount__c);
                    if( objInvLine.GST_Amount__c != Null ){
                        objupdateInvLine.Credit_Memo_Tax__c = objInvLine.GST_Amount__c;
                    }
                    updateInvoiceLineItem.add(objupdateInvLine);
                }
                newPendingCreditMemos.put(objInvoice.id,objCreditMemo);
            }
        }
        system.debug('updateInvoiceLineItem'+updateInvoiceLineItem);
        
        if(newPendingCreditMemos.size() > 0){
            Insert newPendingCreditMemos.values();  
            system.debug('newPendingCreditMemos'+newPendingCreditMemos);
            system.debug('mapOfCreditmemolineitem'+mapOfCreditmemolineitem);
            List<Credit_memo_line_item__c> listOfnewCreditmemolineitem = new list<Credit_memo_line_item__c>();
            for(string creditMemoRemark : newPendingCreditMemos.keyset()){
                if(mapOfCreditmemolineitem.containskey(creditMemoRemark)){
                    for(Credit_memo_line_item__c creditLineItemobj: mapOfCreditmemolineitem.get(creditMemoRemark)){
                        creditmemoIds.add(newPendingCreditMemos.get(creditMemoRemark).id);
                        creditLineItemobj.Credit_Memo_Number__c = newPendingCreditMemos.get(creditMemoRemark).id;
                        listOfnewCreditmemolineitem.add(creditLineItemobj);
                    }
                }
            } 
            if(listOfnewCreditmemolineitem != null && listOfnewCreditmemolineitem.size() > 0){
                insert listOfnewCreditmemolineitem;
            }
                                    
        }
        //added by nishi: 6-Oct-2020 : end:for new requirement Create a Credit Memo record with the status pending instead of the Payment as Deposit record.
    
        if(updateInvoiceLineItem != null && updateInvoiceLineItem.size() > 0){
            update updateInvoiceLineItem;
        }
    }
    
    return getParentCreditMemo(new set<string>{enrolmentObj.parent__c},effectDate,creditmemoIds);
}
    
    // get if there is any pending credit memo available with the customer account
    public static Map<String,List<Credit_Memo__c>> getParentCreditMemo(Set<String> setOfParentIds, Date lastDate,set<string> creditmemoIds){
        Map<String,List<Credit_Memo__c>>  parentCreditMemos = new Map<String,List<Credit_Memo__c>>();
        String query = generateCreditMemoQuery(setOfParentIds,lastDate,creditmemoIds);
        for(Credit_Memo__c objPay : Database.query(query)){
            List<Credit_Memo__c> listOfCreditMemos = parentCreditMemos.containsKey(objPay.Parent_Account__c) ? 
                                                    parentCreditMemos.get(objPay.Parent_Account__c) : new List<Credit_Memo__c>();
            listOfCreditMemos.add(objPay);
            parentCreditMemos.put(objPay.Parent_Account__c,listOfCreditMemos);
        }
        return parentCreditMemos;
    }

    // get  pending credit memo available with the customer account
    private static string generateCreditMemoQuery(Set<String> setOfParentIds, Date lastDate,set<string> creditmemoIds){
        String pendingStatus = ConstantsClass.creditMemoPendingStatus;
        String query = 'SELECT From_Invoice__c, Parent_Account__c, Organisations_Name__c, Comments__c, Currency_Code__c, Total_Amount__c, Payment_Method__c, Invoice_Number__c, ';
        query+= ' Credit_Memo_Date__c, Status__c, Refund_ID__c, Stripe_Payout_Id__c, Stripe_Fee__c, Cheque_Date__c, Cheque_No__c, Bank_Name__c, NETS_Code__c, Amount_Exl_tax_Rollup__c, ';
        query+= ' (SELECT Transaction_ID__c, Credit_Memo_Number__c, Enrolment__c, Amount__c, Netsuite_GST_Code__c, Tax_Amount__c, Month__c, Remarks__c, Package__c, Is_Deposit__c, Is_Discount__c, ';
        query+= '  Invoice_Line_Item__c, Package_Name__c, Netsuite_Product_Name__c, Name, Id FROM Credit_memo_line_items__r order by Amount__c Desc),';
        query+= ' Tax_Amount_Rollup__c, Center__c, Netsuite_Payment_Method__c, Id, Name FROM Credit_Memo__c ';
        query+= ' WHERE Status__c =\''+pendingStatus +'\'';
        query+= ' AND Credit_Memo_Date__c =:lastDate';
        query+= ' AND Parent_Account__c IN :setOfParentIds';
        query+= ' AND Id IN :creditmemoIds';
        query+= '  order by Total_Amount__c Desc';
    //system.debug('Query '+query);
        return query;
    }
    public static List<Invoice__c> getInvoiceDetails(enrolment__c enrolmentObj, Date effectDate,Subscription_Line_Item__c objSubLineItem){
        date effectiveDate = date.newInstance(effectDate.year(), effectDate.month(),1);
        system.debug('@@effectiveDate'+effectiveDate);
            system.debug('@@objSubLineItem.Next_Bill_Date__c'+objSubLineItem.Next_Bill_Date__c);
        system.debug('@@objSubLineItem.id'+objSubLineItem.id);
        map<string,string> invoiceIdsmap = new map<string,string> ();
        for(Invoice_Line_Item__c objInvLine : [SELECT ID,Invoice__c FROM Invoice_Line_Item__c
                                    where Enrolment__C =:enrolmentObj.id
                                    And Month__c >=: effectiveDate 
                                    //and Month__c <=:objSubLineItem.Next_Bill_Date__c
                                    And Subscription_Line_Item__c=: objSubLineItem.id
                                    And Is_Deposit__c = false
                                    And package__r.type__c != 'Adhoc']){
                                        invoiceIdsmap.put(objInvLine.id,objInvLine.Invoice__c);
                                    }
                                    system.debug('!!invoiceIdsmap'+invoiceIdsmap.size());
        return [Select id,Invoice_Date__c,Status__c,Currency_Code__c,Name,Parent_Account__c,Center__c,  invoice_type__c,                                  
                    (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c,
                        Credit_Memo_Amount__c,Credit_Memo_tax__c,Remarks__c
                        FROM Invoice_Line_Items__r
                        where id in:invoiceIdsmap.keySet()),
                    (SELECT Id, Payment_Amount__c, Transaction_Id__c, remarks__c, Invoice__c, Parent_Account__c, 
                        Invoice__r.Center__r.Organisation__r.name,Payment_Date__c,method_of_payment__c,
                        Invoice__r.Center__r.Organisation__r.Stripe_Base_Url__c, Invoice__r.Center__r.Organisation__r.Stripe_Secret_Key__c
                        FROM Payments__r 
                        Where RecordType.Name =:ConstantsClass.paymentTransactionRecType)
                    From Invoice__C 
                    Where  Parent_Account__c =: enrolmentObj.Parent__c
                    //And invoice_type__c = 'Recurring'
                    And Status__c =: constantsClass.paidStatus
                    And Subscription__c =:objSubLineItem.Subscription__c
                    AND Id In:invoiceIdsmap.values()];
    }
    

    public static UpgradeEnrolmentProcessController.UpgradeCaseCreation invoiceForupgradePackages(UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,enrolment__c objEnrol,
                                                                        String stripeId, string currencyCode,string baseUrl,string apiKey,Subscription_Line_Item__c objSubLineItem ,Decimal depositeFee,
                                                                        Package__c oldPackg, Package__c newPackg, Date effectDate, Time timeslot, Decimal taxRate,string newTeacherId,
                                                                        Map<string,Decimal> invoiceAdjustmentMap,Decimal totalAmount,boolean isPromotionalEnrolment, boolean isOssiaOrganization){
         // added by nishi: 24-oct-2020:  We have created a new invoice for additional deposits and full lesson fees for the enhanced package for the remaining period in the current invoice. we create a credit memo for  the previous package for the remaining period
        // and then adjust this credit memo to the newly upgraded package invoice And the remaining invoice amount we charged via Stripe.                                                                
            List<Invoice__c> listOfInvoice = isPromotionalEnrolment ? getInvoiceDetails(objEnrol,effectDate.addmonths(1),objSubLineItem) : new  List<Invoice__c>();
            upgradePackageCaseDetails.isSuccess = true;                                                     
            if(totalAmount != 0){
                upgradePackageCaseDetails= createChargeForCustomer(upgradePackageCaseDetails, objEnrol,
                                        stripeId,   currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                        oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, invoiceAdjustmentMap,totalAmount,isPromotionalEnrolment,listOfInvoice,isOssiaOrganization);
                if(upgradePackageCaseDetails.isSuccess){
                    upgradePackageCaseDetails.enrolObj = updateEnrollment(objEnrol.id, newPackg.Id, timeslot, effectDate,newTeacherId);
                    upgradePackageCaseDetails.enrolObj = fetchEnrolment(objEnrol.id);
                }                                        
            }else{
                upgradePackageCaseDetails.isSuccess = false;
            }
        return upgradePackageCaseDetails;
    }

    // added by nishi: 10-May-2021: If the next billing date is less than the effective date and the package is the promo package then
    // we will check that the invoice line item month matches the month of the next billing date, 
    //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record.
    // the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
    public static map<string,Credit_Memo__c> createCreditMemoNextBillingDateForPromoPackage(String enrolmentId,string oldPackage, Date effectiveDate,string creditMemoRemarks ){
        enrolment__c objEnrol = fetchEnrolment(enrolmentId);
        Subscription_Line_Item__c objSubLineItem = fetchSubsLineItem(enrolmentId);
        List<Invoice__c> listOfInvoice = getInvoiceDetails(objEnrol,effectiveDate,objSubLineItem);
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
        //Credit_memo_line_item__c objCreditLineItem = new  Credit_memo_line_item__c();    
        list<Invoice_Line_Item__c> updateInvoiceLineItem = new list<Invoice_Line_Item__c>();
        List<Booking__c> bookingList = [SELECT Id, Package__c, center__c, Teacher_Account__c, Package__r.Unit_Fee__c, Student__c, Student__r.Parent__c,Booking_date__c FROM Booking__c WHERE 
                                        Enrolment__c =: objEnrol.id AND Booking_Date__c >= :effectiveDate AND 
                                        Booking_Date__c <= :objEnrol.Promotional_Period_End_Date__c
                                        AND Type__c =: ConstantsClass.typeRegular 
                                        ORDER BY Booking_Date__c ];
        
        system.debug('bookingList'+bookingList);
        if(bookingList != null && bookingList.size() > 0){
            Map<Id,Package__c> mapOfPackages =New Map<Id,Package__c>([Select Id,Unit_Fee__c,Is_Promotion_Discount__c,type_of_package__C,
                                            Package_after_Promotion__c,Package_Fee__c, Promotion_period_In_months__c, 
                                            Promotion_Discount__c from Package__c where Id =:oldPackage]);
            map<id,String> packageInvoiceAmount = new Map<Id,String>();
            map<id,String> packageInvoiceDiscountAmount = new Map<Id,String>();
            for(Booking__c booking : bookingList){
                packageInvoiceAmount.put(oldPackage,getPrepaymentPackageInvoiceAmount(objEnrol,mapOfPackages,packageInvoiceAmount,oldPackage,false));    
                packageInvoiceDiscountAmount.put(oldPackage,getPrepaymentPackageInvoiceAmount(objEnrol,mapOfPackages,
                                                                                                            packageInvoiceDiscountAmount,oldPackage,true)); 
            }
            map<String,Invoice_Line_Item__c> updateCreditMemoInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
            Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
            Map<String,Invoice_line_item__c> mapofinvoicelineitem = new Map<String,Invoice_line_item__c>();
            for(Invoice__c invoiceobj : listOfInvoice){
                for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                    if(objlineitem.month__c.month() >= effectiveDate.month()){
                        mapofinvoice.put('Current',invoiceobj);
                            if(!objlineitem.Is_Discount__c)
                                mapofinvoicelineitem.put('Current',objlineitem);
                            else if(objlineitem.Is_Discount__c)
                                mapofinvoicelineitem.put('DiscountInvoice',objlineitem);
                    }
                }
            }
            if((packageInvoiceAmount.containskey(oldPackage) && decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[0]) > 0) && 
                ((packageInvoiceDiscountAmount.containskey(oldPackage) && decimal.valueOf(packageInvoiceDiscountAmount.get(oldPackage).split(';')[0]) > 0))){

                String invoiceId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                    if(mapofinvoice.containskey('Current')){
                        invoiceId = mapofinvoice.get('Current').id;
                    }
                
                    Credit_Memo__c  objCreditMemo = new     Credit_Memo__c();
                    objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId, effectiveDate,creditMemoRemarks);
                    newPendingCreditMemos.put(creditMemoRemarks,objCreditMemo);  
                    
                    if(packageInvoiceAmount.containsKey(oldPackage)){
                        if(packageInvoiceAmount.get(oldPackage).split(';') != null && 
                        packageInvoiceAmount.get(oldPackage).split(';').size() >0){
                        decimal oldPackageTotalAmount = decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[0]);
                            decimal gstAmount = decimal.valueOf(packageInvoiceAmount.get(oldPackage).split(';')[1]);
                            if(oldPackageTotalAmount != 0){
                                oldPackageTotalAmount = BillingUtility.roundOffAmount(oldPackageTotalAmount);
                            }
                            if(gstAmount != 0){
                                gstAmount = BillingUtility.roundOffAmount(gstAmount);
                            }
                            String invoicelineitemId = null;
                            if(mapofinvoicelineitem.containskey('Current')){
                                invoicelineitemId =mapofinvoicelineitem.get('Current').id; 
                            }
                            
                            Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(oldPackageTotalAmount,gstAmount,oldPackage,
                            objEnrol.id,invoicelineitemId,'',effectiveDate);
                            listOfCreditmemolineitem.add(objCreditLineItem);                                                  
                            if(string.isNotBlank(invoicelineitemId)){
                                updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( mapofinvoicelineitem,oldPackageTotalAmount,gstAmount,invoicelineitemId));
                            }
                        }                 
                    }
                    if(packageInvoiceDiscountAmount.containsKey(oldPackage)){
                        if(packageInvoiceDiscountAmount.get(oldPackage).split(';') != null && 
                            packageInvoiceDiscountAmount.get(oldPackage).split(';').size() >0){
                            decimal oldPackageTotalDiscountAmount = -BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceDiscountAmount.get(oldPackage).split(';')[0]));
                            decimal gstAmount = -BillingUtility.roundOffAmount(decimal.valueOf(packageInvoiceDiscountAmount.get(oldPackage).split(';')[1]));
                            String invoicelineitemId = null;
                            if(mapofinvoicelineitem.containskey('DiscountInvoice')){
                                invoicelineitemId =mapofinvoicelineitem.get('DiscountInvoice').id; 
                            }
                            Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(oldPackageTotalDiscountAmount,gstAmount,oldPackage,
                            objEnrol.id,invoicelineitemId,'',effectiveDate);
                            objCreditLineItem.Is_Discount__c = true; 
                            listOfCreditmemolineitem.add(objCreditLineItem);                                                  
                        if(string.isNotBlank(invoicelineitemId)){
                                updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( mapofinvoicelineitem,oldPackageTotalDiscountAmount,gstAmount,invoicelineitemId));
                            }
                        }                 
                    }
                
                    mapOfCreditmemolineitem.put(creditMemoRemarks,listOfCreditmemolineitem);
                    set<string> creditmemoIds = new set<string>();
                    if(newPendingCreditMemos.size() > 0){
                    Insert newPendingCreditMemos.values();  
                    system.debug('newPendingCreditMemos'+newPendingCreditMemos);
                    system.debug('mapOfCreditmemolineitem'+mapOfCreditmemolineitem);
                    List<Credit_memo_line_item__c> listOfnewCreditmemolineitem = new list<Credit_memo_line_item__c>();
                        for(string creditMemoRemark : newPendingCreditMemos.keyset()){
                            if(mapOfCreditmemolineitem.containskey(creditMemoRemark)){
                                for(Credit_memo_line_item__c creditLineItemobj: mapOfCreditmemolineitem.get(creditMemoRemark)){
                                    creditmemoIds.add(newPendingCreditMemos.get(creditMemoRemark).id);
                                    creditLineItemobj.Credit_Memo_Number__c = newPendingCreditMemos.get(creditMemoRemark).id;
                                    listOfnewCreditmemolineitem.add(creditLineItemobj);
                                }
                            }
                        } 
                        if(listOfnewCreditmemolineitem != null && listOfnewCreditmemolineitem.size() > 0){
                            insert listOfnewCreditmemolineitem;
                        }
                                                
                    }
                    if(updateCreditMemoInvoiceLineItem != null && updateCreditMemoInvoiceLineItem.size() > 0){
                        update updateCreditMemoInvoiceLineItem.values();
                    }
                }
            }
        }
        return newPendingCreditMemos;
    } 

    // may-11-20201: nishi: get paid invoice amount and tax according to enrolment promotional packages end date
    private static String getPrepaymentPackageInvoiceAmount(Enrolment__c objEnrol,Map<Id,Package__c> mapOfPackages,
        map<id,String> packageInvoiceAmount,string packageId,boolean isDiscount){
        decimal totalAmount = 0;
        decimal gstAmount = 0;
        Decimal noOfMonths = String.isNotBlank(mapOfPackages.get(packageId).Promotion_period_In_months__c) ? Integer.valueOf(mapOfPackages.get(packageId).Promotion_period_In_months__c) : 1;
        Decimal preUnitDiscountAmount = 0;    
        if(packageInvoiceAmount.containsKey(packageId)){
            totalAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[0]);
        }
        Integer lessondays = 4;
        if(isDiscount){
            if(mapOfPackages.get(packageId).Promotion_Discount__c != null){
                preUnitDiscountAmount = ((mapOfPackages.get(packageId).Promotion_Discount__c / noOfMonths)/lessondays);
            }
        }else{
            if(mapOfPackages.get(packageId).Package_Fee__c != null){
                 preUnitDiscountAmount = ((mapOfPackages.get(packageId).Package_Fee__c / noOfMonths)/lessondays);
            }
        }
        totalAmount += preUnitDiscountAmount;
        if(String.isNotBlank(objEnrol.Id) &&  String.isNotBlank(objEnrol.Center__c)
        && String.isNotBlank(objEnrol.Center__r.Country__c) && objEnrol.Center__r.Country__r.Tax_Rate__c > 0
        && preUnitDiscountAmount  > 0 ){
            if(packageInvoiceAmount.containsKey(packageId)){
                gstAmount = decimal.valueOf(packageInvoiceAmount.get(packageId).split(';')[1]);
            }
            gstAmount += (preUnitDiscountAmount * objEnrol.Center__r.Country__r.Tax_Rate__c)/100;
        }
        return totalAmount+';'+gstAmount;
    }

    // 23-Oct-2020:nishi: We have created a new invoice for additional deposits and full lesson fees for the enhanced package for the remaining period in the current invoice. we create a credit memo for  the previous package for the remaining period and then adjust this credit memo to the newly upgraded package invoice
    public static Map<String,List<Credit_Memo__c>> createCreditMemoForCurrentMonthUpgradeProcess(List<Invoice__c> listOfInvoice,Map<string,Decimal> invoiceAdjustmentMap,Enrolment__c objEnrol,date effectiveDate,Subscription_Line_Item__c objSubLineItem,
     decimal taxRate,Boolean isPromotionalEnrolment,string oldPackId){
        Decimal negativeInvoiceAmount =  invoiceAdjustmentMap.containsKey('negativeInvoiceAmount') && invoiceAdjustmentMap.get('negativeInvoiceAmount') != null ? (invoiceAdjustmentMap.get('negativeInvoiceAmount')) : 0;
        Decimal negativeNextMonthInvoiceAmount =  invoiceAdjustmentMap.containsKey('negativeNextMonthInvoiceAmount') && invoiceAdjustmentMap.get('negativeNextMonthInvoiceAmount') != null?(invoiceAdjustmentMap.get('negativeNextMonthInvoiceAmount')) : 0;
        Decimal negativeInvoiceDiscountAmount =  invoiceAdjustmentMap.containsKey('negativeInvoiceDiscountAmount') && invoiceAdjustmentMap.get('negativeInvoiceDiscountAmount') != null ? (invoiceAdjustmentMap.get('negativeInvoiceDiscountAmount')) : 0;
        system.debug('negativeInvoiceAmount'+negativeInvoiceAmount);    
        system.debug('negativeNextMonthInvoiceAmount'+negativeNextMonthInvoiceAmount);    
        system.debug('negativeInvoiceDiscountAmount'+negativeInvoiceDiscountAmount);    
        system.debug('isPromotionalEnrolment'+isPromotionalEnrolment);    
        List<Credit_Memo__c>  listOfParentCreditMemo = new List<Credit_Memo__c> ();
        date nextBillDate = objSubLineItem.Next_Bill_Date__c;
        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
        Credit_memo_line_item__c objCreditLineItem = new  Credit_memo_line_item__c();    
        map<String,Invoice_Line_Item__c> updateInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        map<String,Invoice_Line_Item__c>  updateCreditMemoInvoiceLineItem = new map<String,Invoice_Line_Item__c> (); 
  
        Credit_Memo__c  objCreditMemo = new     Credit_Memo__c();
         //for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.
         Map<String,Invoice__c> mapofinvoice = new Map<String,Invoice__c>();
         Map<String,Invoice_line_item__c> mapofinvoicelineitem = new Map<String,Invoice_line_item__c>();
         for(Invoice__c invoiceobj : getInvoiceDetails(objEnrol,effectiveDate,objSubLineItem)){
            if(isPromotionalEnrolment){
                for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                    if(objlineitem.month__c.month() == effectiveDate.month()){
                        mapofinvoice.put('Current',invoiceobj);
                        if(!objlineitem.Is_Discount__c)
                            mapofinvoicelineitem.put('Current',objlineitem);
                        else if(objlineitem.Is_Discount__c)
                            mapofinvoicelineitem.put('DiscountInvoice',objlineitem);
                    }
                    updateInvoiceLineItem.put(objlineitem.id,objlineitem);
                }
            }else{
                if(invoiceobj.invoice_type__c == 'Recurring'){
                    //string invoiceMonth ='';
                    // if(invoiceobj.Invoice_Date__c.month() == effectiveDate.month())
                    //     invoiceMonth = 'Current';
                    // if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && invoiceobj.Invoice_Date__c.month() == nextMonthDate.addMonths(-1).month() )
                    //     invoiceMonth = 'Next Month';
                    // system.debug('invoiceMonth'+invoiceMonth);
                    // if(string.isnotBlank(invoiceMonth)){
                    //     mapofinvoice.put(invoiceMonth,invoiceobj);
                        for(Invoice_line_item__c objlineitem: invoiceobj.Invoice_line_items__r){
                            string invoiceMonth ='';
                            if(objlineitem.month__c.month() == effectiveDate.month())
                             invoiceMonth = 'Current';
                            if(nextBillDate >= nextMonthDate && effectiveDate.month() < nextMonthDate.addMonths(-1).month() && objlineitem.month__c.month() == nextMonthDate.addMonths(-1).month() )
                                invoiceMonth = 'Next Month';
                            if(string.isnotBlank(invoiceMonth)){
                                mapofinvoice.put(invoiceMonth,invoiceobj);
                                updateInvoiceLineItem.put(objlineitem.id,objlineitem);
                                system.debug('objlineitem'+objlineitem);
                                if(!objlineitem.Is_Discount__c)
                                    mapofinvoicelineitem.put(invoiceMonth,objlineitem);
                            }
                            
                        }
                    //}
                }
            }
            
            
         }
         system.debug('mapofinvoicelineitem'+mapofinvoicelineitem);    
         String invoiceId = null;
         if(mapofinvoice != null && mapofinvoice.size() > 0 ){
             if(mapofinvoice.containskey('Current')){
                 invoiceId = mapofinvoice.get('Current').id;
             }
         }
        objCreditMemo = BillingUtility.createCreditMemoRec(objEnrol.Parent__c,objEnrol.center__c, invoiceId, effectiveDate,'Upgrade Enrolment Adjustment');
         newPendingCreditMemos.put('Upgrade Enrolment Adjustment',objCreditMemo);
         system.debug('objCreditMemo'+objCreditMemo);    
         listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
        
         //added by nishi: 7-Oct-2020 : end:for new requirement Create a Credit Memo record with the status Sucess instead of the Negative invoice line item record.

         decimal negativeInvoiceDiscountAmountGST =0;
         decimal negativeInvoiceAmountGST =0;
         decimal negativeNextMonthInvoiceAmountGST =0;
         // create credit memo line item for current month old package negative invoice amount 
         if(negativeInvoiceAmount != NULL && negativeInvoiceAmount!= 0){
            if(negativeInvoiceAmount != NULL  && taxRate > 0){
                 negativeInvoiceAmountGST  = BillingUtility.roundOffAmount(negativeInvoiceAmount * (taxRate /100));
            }
            String invoicelineitemId = null;
            if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                if(mapofinvoice.containskey('Current')){
                    if(mapofinvoicelineitem.containskey('Current')){
                        invoicelineitemId =mapofinvoicelineitem.get('Current').id; 
                    }
                    
                }
            }
            objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(negativeInvoiceAmount),
                                            negativeInvoiceAmountGST,oldPackId,
                                            objEnrol.id,invoicelineitemId,'',effectiveDate);
            listOfCreditmemolineitem.add(objCreditLineItem);     
            system.debug('objCreditLineItem'+objCreditLineItem);                                        
            if(string.isNotBlank(invoicelineitemId) ){
                updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,BillingUtility.roundOffAmount(negativeInvoiceAmount),negativeInvoiceAmountGST,invoicelineitemId));
            }
        }

        // create credit memo line item for current month old package negative discount invoice amount 
        if(isPromotionalEnrolment ){
            List<Credit_memo_line_item__c> listOfCreditMemoForPrepaymentInvoice = createCreditMemoForPrepaymentInvoice( objSubLineItem,objEnrol,effectiveDate);
            if(listOfCreditMemoForPrepaymentInvoice != null && listOfCreditMemoForPrepaymentInvoice.size() > 0){
                listOfCreditmemolineitem.addAll(listOfCreditMemoForPrepaymentInvoice);                                                  
            }
            if( negativeInvoiceDiscountAmount != NULL && negativeInvoiceDiscountAmount != 0){
                if(negativeInvoiceDiscountAmount != NULL  && taxRate > 0){
                    negativeInvoiceDiscountAmountGST  = BillingUtility.roundOffAmount(negativeInvoiceDiscountAmount * (taxRate /100));
                }
                String invoicelineitemId = null;
                if(isPromotionalEnrolment && mapofinvoicelineitem.containskey('DiscountInvoice')){
                    invoicelineitemId =mapofinvoicelineitem.get('DiscountInvoice').id; 
                }
                objCreditLineItem = BillingUtility.createCreditMemoLineRec(-BillingUtility.roundOffAmount(negativeInvoiceDiscountAmount),
                                                -(negativeInvoiceDiscountAmountGST),oldPackId,
                                                objEnrol.id,invoicelineitemId,'',effectiveDate);
                                                objCreditLineItem.Is_Discount__c = true;   
                listOfCreditmemolineitem.add(objCreditLineItem);     
                system.debug('objCreditLineItem'+objCreditLineItem);                                        
                if(string.isNotBlank(invoicelineitemId) ){
                    updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,-BillingUtility.roundOffAmount(negativeInvoiceDiscountAmount),-BillingUtility.roundOffAmount(negativeInvoiceDiscountAmountGST),invoicelineitemId));
                }
            }
        }

        // create credit memo line item for next month old package negative invoice amount 
        if(!isPromotionalEnrolment){
            if(negativeNextMonthInvoiceAmount != NULL && negativeNextMonthInvoiceAmount != 0){
                if(negativeNextMonthInvoiceAmount != NULL  && taxRate > 0){
                    negativeNextMonthInvoiceAmountGST  = BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount * (taxRate /100));
                }
                String invoicelineitemId = null;
                if(mapofinvoice != null && mapofinvoice.size() > 0 ){
                    if(mapofinvoice.containskey('Next Month')){
                        if(mapofinvoicelineitem.containskey('Next Month')){
                            invoicelineitemId =mapofinvoicelineitem.get('Next Month').id; 
                        }
                    }
                }
                objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount),
                negativeNextMonthInvoiceAmountGST,oldPackId,
                objEnrol.id,invoicelineitemId,'');
                objCreditLineItem.Month__c = nextMonthDate.addMonths(-1);
                listOfCreditmemolineitem.add(objCreditLineItem);                                      
                system.debug('listOfCreditmemolineitem'+listOfCreditmemolineitem);      
                if(string.isNotBlank(invoicelineitemId) ){
                    updateCreditMemoInvoiceLineItem.put(invoicelineitemId,updateInvoiceLineItemMap( updateInvoiceLineItem,BillingUtility.roundOffAmount(negativeNextMonthInvoiceAmount),negativeNextMonthInvoiceAmountGST,invoicelineitemId));
                }
            }
        }
        mapOfCreditmemolineitem.put('Upgrade Enrolment Adjustment',listOfCreditmemolineitem);
        set<string> creditmemoIds = new set<string>();
        if(newPendingCreditMemos.size() > 0){
           Insert newPendingCreditMemos.values();  
           system.debug('newPendingCreditMemos'+newPendingCreditMemos);
           system.debug('mapOfCreditmemolineitem'+mapOfCreditmemolineitem);
           List<Credit_memo_line_item__c> listOfnewCreditmemolineitem = new list<Credit_memo_line_item__c>();
            for(string creditMemoRemark : newPendingCreditMemos.keyset()){
                if(mapOfCreditmemolineitem.containskey(creditMemoRemark)){
                    for(Credit_memo_line_item__c creditLineItemobj: mapOfCreditmemolineitem.get(creditMemoRemark)){
                        creditmemoIds.add(newPendingCreditMemos.get(creditMemoRemark).id);
                        creditLineItemobj.Credit_Memo_Number__c = newPendingCreditMemos.get(creditMemoRemark).id;
                        listOfnewCreditmemolineitem.add(creditLineItemobj);
                    }
                }
            } 
            if(listOfnewCreditmemolineitem != null && listOfnewCreditmemolineitem.size() > 0){
                insert listOfnewCreditmemolineitem;
            }
                                       
        }
        system.debug('updateCreditMemoInvoiceLineItem'+updateCreditMemoInvoiceLineItem);
         if(updateCreditMemoInvoiceLineItem != null && updateCreditMemoInvoiceLineItem.size() > 0){
            update updateCreditMemoInvoiceLineItem.values();
        }
        return getParentCreditMemo(new set<string>{objEnrol.parent__c},effectiveDate,creditmemoIds);
    }

    

    public  static  Invoice_Line_Item__c updateInvoiceLineItemMap(Map<string,Invoice_Line_Item__c> updateInvoiceLineItem,decimal amount,decimal tax,string invoicelineitemId){
        decimal invoicelineItemCreditAmount=0;
        decimal invoicelineItemCreditGst=0;
        
        if(updateInvoiceLineItem.containskey(invoicelineitemId)){
            invoicelineItemCreditAmount = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c :0;
            invoicelineItemCreditGst = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c :0;
        }

        return new Invoice_Line_Item__c(id=invoicelineitemId,
                                    Credit_Memo_Amount__c =invoicelineItemCreditAmount+(amount),
                                    Credit_Memo_tax__c=invoicelineItemCreditGst+tax);
    }
   
    Public static Subscription_Line_Item__c fetchSubsLineItem(String enrolId){
        return [SELECT Id,Subscription__c,Subscription__r.Parent__c,Subscription__r.Center__c,Subscription__r.Parent__r.Stripe_Customer_Id__c, 
                Enrolment__r.Lesson_Day__c,Enrolment__c, Enrolment__r.Effective_Date__c, Enrolment__r.teacher__c, Enrolment__r.Center__r.Country__c,
                Next_Bill_Date__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                Enrolment__r.Center__r.Organisation__r.Name
                 FROM Subscription_Line_Item__c 
                 WHERE Enrolment__c =: enrolId 
                 And Status__c =: ConstantsClass.activeStatus
                 And Next_Bill_Date__c != null LIMIT 1];
    }
    Public static List<Subscription_Line_Item__c> fetchSubsLineItems(String subscription_Line_Itemid){
        return [SELECT Id,Subscription__c,Subscription__r.Parent__c,Subscription__r.Center__c,Subscription__r.Parent__r.Stripe_Customer_Id__c, 
                Enrolment__r.Lesson_Day__c,Enrolment__c, Enrolment__r.Effective_Date__c, Enrolment__r.teacher__c, Enrolment__r.Center__r.Country__c,
                Next_Bill_Date__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                Enrolment__r.Center__r.Organisation__r.Name
                 FROM Subscription_Line_Item__c WHERE id =: subscription_Line_Itemid 
                 ];
    }
    
    public static Map<String,Package__c> getPackage(String oldPackageId,String newPackageId){
        return new Map<String,Package__c>([Select Id,Name,Unit_Fee__c,Deposit_Fee__c,Duration__c, Package_Fee__c,
                                            Is_Promotion_Discount__c,type_of_package__C, Package_after_Promotion__c, Promotion_period_In_months__c, Promotion_Discount__c // added by nishi: 22-Oct-2020: for manage Promotional Package
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
    public static List<Booking__c> fetchListOfBookings(String enrolmentId,Date effectivedate){
        date firstdate = date.newinstance(effectivedate.year(),effectivedate.month(),1);
        date lastDate = firstDate.addMonths(1).addDays(-1);
        
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c, Status__c FROM Booking__c 
                WHERE Enrolment__c=:enrolmentId 
                and Booking_Date__c >=: firstdate and Booking_Date__c<=:lastDate
                //commented by nishi:22-Oct-2020: AND Booking_Date__c = THIS_MONTH
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
        List<Enrolment__c> enrolList = [SELECT Id, effective_Date__c, Center__c, Parent__c, Package__c, Package_Process_Status__c,Lesson_Start_time__c,Type_of_Package__c,
                                        Promotional_Period_End_Date__c,Center__r.Country__r.Tax_Rate__c,Lesson_Day__c,
                                        New_Package_Id__c, Package_Process_Type__c, Next_Lesson_Start_time__c FROM Enrolment__c WHERE Id =: enrolId];
        Enrolment__c enrolObj = new Enrolment__c();
        if(enrolList.size() > 0){
            enrolObj = enrolList[0];
        }
        
        return  enrolObj;
    }
    
}