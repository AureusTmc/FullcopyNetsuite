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
        // 21-Oct-2020 : @@nishi  :if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
        if(isPromotionalEnrolment){
            // check next month invoice billing already exist or not  
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
            }// check next month invoice billing already exist or not 

        }// 21-Oct-2020 : @@nishi  :if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
        
        
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
            if(isPromotionalEnrolment){
                upgradePackageCaseDetails = invoiceForupgradePromotionalPackages( upgradePackageCaseDetails, enrolmentObj,
                                                stripeId, totalAmount,  currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, 
                                                newPackageUnitPrice,  fifthBookingPrice, totalWithNoGST);
            }else{    
                    upgradePackageCaseDetails = invoiceForupgradePackages( upgradePackageCaseDetails, enrollMentId,
                                                stripeId, totalAmount,  currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                                oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, newPackageNextMonthPrice,
                                                newPackageUnitPrice,  fifthBookingPrice, totalWithNoGST);
            }
        }else{
            flag = false;
        }
       //system.debug('@@upgradePackageCaseDetails'+upgradePackageCaseDetails);
        return upgradePackageCaseDetails ;
    }

    Private static UpgradeEnrolmentProcessController.UpgradeCaseCreation invoiceForupgradePromotionalPackages(UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,enrolment__c enrolmentObj,
                                                                            String stripeId,decimal totalAmount, string currencyCode,string baseUrl,string apiKey,Subscription_Line_Item__c objSubLineItem ,Decimal depositeFee,
                                                                            Package__c oldPackg, Package__c newPackg, Date effectDate, Time timeslot, Decimal taxRate,string newTeacherId,
                                                                            Decimal newPackageUnitPrice, decimal fifthBookingPrice,Decimal totalWithNoGST){
            
            List<Invoice__c> listOfInvoice = getInvoiceDetails(enrolmentObj,effectDate,objSubLineItem) ;
            Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo =createNextMonthsCreditMemo(listOfInvoice,enrolmentObj, effectDate);
            system.debug('mapOfParentCreditMemo'+mapOfParentCreditMemo);
            Map<String,Decimal> parentCreditMemoTotal = BillingUtility.getParentCreditMemoMap(mapOfParentCreditMemo);
            Decimal accumulatedCreditMemoAmount =0;
            Decimal diffrenceAmount = 0;
            if(parentCreditMemoTotal.containsKey(enrolmentObj.parent__c)){
                accumulatedCreditMemoAmount = parentCreditMemoTotal.get(enrolmentObj.parent__c);
            }
            system.debug('accumulatedCreditMemoAmount'+accumulatedCreditMemoAmount);
            system.debug('totalAmount'+totalAmount);
            if(accumulatedCreditMemoAmount > 0){
                Decimal creditmemoPaidAmount =totalAmount;
                if(accumulatedCreditMemoAmount < totalAmount){ 
                    diffrenceAmount = totalAmount - accumulatedCreditMemoAmount ;
                    creditmemoPaidAmount = accumulatedCreditMemoAmount;
                }
                upgradePackageCaseDetails =  createUpgradedAmountInvoice( objSubLineItem, totalAmount, depositeFee,oldPackg,  newPackg,  effectDate,  taxRate, newTeacherId,
                                            newPackageUnitPrice,  fifthBookingPrice, totalWithNoGST, enrolmentObj,mapOfParentCreditMemo,upgradePackageCaseDetails);
                if(string.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                    Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Status__c, Parent_Account__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                    system.debug('@@@objInvoice '+objInvoice);
                    Payment__c objPayment = new Payment__c();
                    system.debug('diffrenceAmount'+diffrenceAmount);
                    if(diffrenceAmount > 0){
                        BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId,diffrenceAmount, currencyCode, baseUrl, apiKey); 
                        if(chargeResponse.statusCode == 200 && chargeResponse.paid){
                            objInvoice.Status__c = constantsClass.paidStatus;
                            update objInvoice;
                            system.debug('@@@objInvoice '+objInvoice);
                            if(String.isNotBlank(baseUrl) && String.isNotBlank(apiKey)){
                                BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, baseUrl, apiKey);                    
                            }
        
                            
                            objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,diffrenceAmount,ConstantsClass.successStatus);
                            objPayment.Transaction_ID__c = chargeResponse.Id;
                            objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                            INSERT objPayment; 
                            system.debug('@@@objPayment '+objPayment);
                        }else{
                            upgradePackageCaseDetails.isSuccess = false;
                        } 
                    }
                    if(objInvoice != NULL){
                        BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                    }
                    upgradePackageCaseDetails.enrolObj = updateEnrollment(enrolmentObj.id, newPackg.Id, timeslot, effectDate,newTeacherId);
                    upgradePackageCaseDetails.enrolObj = fetchEnrolment(enrolmentObj.id);
                    system.debug('@@@upgradePackageCaseDetails.enrolObj '+upgradePackageCaseDetails.enrolObj );
                    if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                        SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                    }
                }
            }else{
                return invoiceForupgradePackages( upgradePackageCaseDetails, enrolmentObj.id,
                                            stripeId, totalAmount,  currencyCode, baseUrl, apiKey, objSubLineItem , depositeFee,
                                            oldPackg,  newPackg,  effectDate,  timeslot,  taxRate, newTeacherId, 0,
                                            newPackageUnitPrice,  fifthBookingPrice, totalWithNoGST);
            }                                                          
        return upgradePackageCaseDetails;
    }

    //Generate and invoice for the additional Deposit and full lesson fee for the upgraded package for the leftover period in the current billing cycle
    private static UpgradeEnrolmentProcessController.UpgradeCaseCreation createUpgradedAmountInvoice(Subscription_Line_Item__c objSubLineItem,Decimal totalAmount,Decimal depositeFee,
        Package__c oldPackg, Package__c newPackg, Date effectDate, Decimal taxRate,string newTeacherId,
        Decimal newPackageUnitPrice, decimal fifthBookingPrice,Decimal totalWithNoGST,Enrolment__c enrolmentObj,Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo,
        UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails){
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Invoice__c objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objSubLineItem.Subscription__r.Parent__c,constantsClass.dueStatus);
        objInvoice.Center__c = objSubLineItem.Subscription__r.Center__c;
        insert objInvoice;
        system.debug('objInvoice'+objInvoice);
        Invoice_Line_Item__c inlineItemForChange = new Invoice_Line_Item__c();
        if(String.isNotBlank(objInvoice.Id)){
            upgradePackageCaseDetails.invoiceId = objInvoice.Id;
        }
        if(depositeFee > 0){
            inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(depositeFee), newPackg.Id,true, '');
            inlineItemForChange.Is_Deposit__c = True;
            inlineItemForChange.month__c = effectDate;
            listOfInvoiceLineItems.add(inlineItemForChange);
        }
        if(upgradePackageCaseDetails.lessonCharge > 0){
            inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageUnitPrice), newPackg.Id,FALSE, newTeacherId);
            inlineItemForChange.month__c = effectDate;
            listOfInvoiceLineItems.add(inlineItemForChange);
        }
        
        if(totalWithNoGST > 0){
            upgradePackageCaseDetails.total = totalWithNoGST;
        }
        if(fifthBookingPrice > 0){
            inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(fifthBookingPrice),newPackg.Id,FALSE, objSubLineItem.Enrolment__r.teacher__c);
            inlineItemForChange.month__c = effectDate;
            listOfInvoiceLineItems.add(inlineItemForChange);
        }
        if(listOfInvoiceLineItems.size() > 0){
            INSERT listOfInvoiceLineItems;
        } 
        adjustPendingCreditMemoDeposit(enrolmentObj,effectDate,objInvoice.id,mapOfParentCreditMemo);
       return upgradePackageCaseDetails;
    }
    //new invoice amount  adjusted with the credit memo
    private static void adjustPendingCreditMemoDeposit(enrolment__c enrolmentObj,Date effectDate,string invoiceId,Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo ){
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
        BillingUtility.adjustPendingCreditMemoDeposit(invoiceList, new Set<String>{invoiceId}, new Set<String>{enrolmentObj.Parent__c},mapOfParentEnrolmentLastDate,true,mapOfParentCreditMemo);
    }

    private static Map<String,List<Credit_Memo__c>> createNextMonthsCreditMemo(List<Invoice__c> listOfInvoice,enrolment__c enrolmentObj,Date effectDate){
            map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
            map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
            List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
            List<Invoice_Line_Item__c> updateInvoiceLineItem = new List<Invoice_Line_Item__c>(); 
            system.debug('listOfInvoice'+listOfInvoice);
            if(listOfInvoice != null && listOfInvoice.size() > 0){
                for(Invoice__c objInvoice : listOfInvoice){
                    listOfCreditmemolineitem = new List<Credit_memo_line_item__c>(); 
                    if(objInvoice.Invoice_Line_Items__r != null && objInvoice.Invoice_Line_Items__r.size() > 0 && objInvoice.Payments__r != null && objInvoice.Payments__r.size() >0){
                        // if invoice line item month is greater then effective month then we create credit memo and added credit memo line item
                        Credit_Memo__c objCreditMemo = BillingUtility.createCreditMemoRec(objInvoice.Parent_Account__c,objInvoice.Center__c,objInvoice.Id, effectDate,'');
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
                            objInvLine.Credit_Memo_Amount__c = objInvLine.Amount__c;
                            if( objInvLine.GST_Amount__c != Null ){
                                objInvLine.Credit_Memo_Tax__c = objInvLine.GST_Amount__c;
                            }
                            updateInvoiceLineItem.add(objInvLine);
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
            return getParentCreditMemo(new set<string>{enrolmentObj.parent__c},effectDate);
       }
    // get if there is any pending credit memo available with the customer account
    public static Map<String,List<Credit_Memo__c>> getParentCreditMemo(Set<String> setOfParentIds, Date lastDate){
        Map<String,List<Credit_Memo__c>>  parentCreditMemos = new Map<String,List<Credit_Memo__c>>();
        String query = generateCreditMemoQuery(setOfParentIds,lastDate);
        for(Credit_Memo__c objPay : Database.query(query)){
            List<Credit_Memo__c> listOfCreditMemos = parentCreditMemos.containsKey(objPay.Parent_Account__c) ? 
                                                    parentCreditMemos.get(objPay.Parent_Account__c) : new List<Credit_Memo__c>();
            listOfCreditMemos.add(objPay);
            parentCreditMemos.put(objPay.Parent_Account__c,listOfCreditMemos);
        }
        return parentCreditMemos;
    }

    // get  pending credit memo available with the customer account
    private static string generateCreditMemoQuery(Set<String> setOfParentIds, Date lastDate){
        String pendingStatus = ConstantsClass.creditMemoPendingStatus;
        String query = 'SELECT From_Invoice__c, Parent_Account__c, Organisations_Name__c, Comments__c, Currency_Code__c, Total_Amount__c, Payment_Method__c, Invoice_Number__c, ';
        query+= ' Credit_Memo_Date__c, Status__c, Refund_ID__c, Stripe_Payout_Id__c, Stripe_Fee__c, Cheque_Date__c, Cheque_No__c, Bank_Name__c, NETS_Code__c, Amount_Exl_tax_Rollup__c, ';
        query+= ' (SELECT Transaction_ID__c, Credit_Memo_Number__c, Enrolment__c, Amount__c, Netsuite_GST_Code__c, Tax_Amount__c, Month__c, Remarks__c, Package__c, Is_Deposit__c, Is_Discount__c, ';
        query+= '  Invoice_Line_Item__c, Package_Name__c, Netsuite_Product_Name__c, Name, Id FROM Credit_memo_line_items__r order by Amount__c Desc),';
        query+= ' Tax_Amount_Rollup__c, Center__c, Netsuite_Payment_Method__c, Id, Name FROM Credit_Memo__c ';
        query+= ' WHERE Status__c =\''+pendingStatus +'\'';
        query+= ' AND Credit_Memo_Date__c =:lastDate';
        query+= ' AND Parent_Account__c IN :setOfParentIds';
        query+= '  order by Total_Amount__c Desc';
    //system.debug('Query '+query);
        return query;
    }
    private static List<Invoice__c> getInvoiceDetails(enrolment__c enrolmentObj, Date effectDate,Subscription_Line_Item__c objSubLineItem){
        date effectiveDate = date.newInstance(effectDate.addmonths(1).year(), effectDate.addmonths(1).month(),1);
        Set<string> invoiceIds = new Set<string> ();
        for(Invoice_Line_Item__c objInvLine : [SELECT ID,Invoice__c FROM Invoice_Line_Item__c
                                    where Enrolment__C =:enrolmentObj.id
                                    And Month__c >=: effectiveDate 
                                    and Month__c <=:objSubLineItem.Next_Bill_Date__c
                                    And Subscription_Line_Item__c=: objSubLineItem.id]){
                                        invoiceIds.add(objInvLine.Invoice__c);
                                    }
        return [Select id,Invoice_Date__c,Status__c,Currency_Code__c,Name,Parent_Account__c,Center__c,                                   
                    (SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c,
                        Credit_Memo_Amount__c,Credit_Memo_tax__c,Remarks__c
                        FROM Invoice_Line_Items__r
                        where Enrolment__C =:enrolmentObj.id
                            And Month__c >=: effectiveDate and Month__c <=:objSubLineItem.Next_Bill_Date__c
                            And Subscription_Line_Item__c=: objSubLineItem.id),
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
                    AND Id In:invoiceIds];
    }
    

    Private static UpgradeEnrolmentProcessController.UpgradeCaseCreation invoiceForupgradePackages(UpgradeEnrolmentProcessController.UpgradeCaseCreation upgradePackageCaseDetails,Id enrollMentId,
                                                                        String stripeId,decimal totalAmount, string currencyCode,string baseUrl,string apiKey,Subscription_Line_Item__c objSubLineItem ,Decimal depositeFee,
                                                                        Package__c oldPackg, Package__c newPackg, Date effectDate, Time timeslot, Decimal taxRate,string newTeacherId,Decimal newPackageNextMonthPrice,
                                                                        Decimal newPackageUnitPrice, decimal fifthBookingPrice,Decimal totalWithNoGST){
        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId,totalAmount, currencyCode, baseUrl, apiKey); 
            //system.debug('@@chargeResponse'+chargeResponse);
                if(chargeResponse.statusCode == 200 && chargeResponse.paid){
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
                        inlineItemForChange.month__c = effectDate;
                        listOfInvoiceLineItems.add(inlineItemForChange);
                        
                    }
                    if(upgradePackageCaseDetails.lessonCharge > 0){
                    //system.debug('newPackageUnitPrice'+newPackageUnitPrice);
                        inlineItemForChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,BillingUtility.roundOffAmount(newPackageUnitPrice), newPackg.Id,FALSE, newTeacherId);
                        inlineItemForChange.month__c = effectDate;
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
                        inlineItemForChange.month__c = effectDate;
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
                    upgradePackageCaseDetails.enrolObj = updateEnrollment(enrollMentId, newPackg.Id, timeslot, effectDate,newTeacherId);
                    upgradePackageCaseDetails.enrolObj = fetchEnrolment(enrollMentId);
                //system.debug('@@@upgradePackageCaseDetails.enrolObj '+upgradePackageCaseDetails.enrolObj );
                    if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                        SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                    }
                    
                }else{
                    upgradePackageCaseDetails.isSuccess = false;
                }   
                return  upgradePackageCaseDetails;
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
        List<Enrolment__c> enrolList = [SELECT Id, effective_Date__c, Center__c, Parent__c, Package__c, Package_Process_Status__c,Lesson_Start_time__c,Type_of_Package__c,
                                        New_Package_Id__c, Package_Process_Type__c, Next_Lesson_Start_time__c FROM Enrolment__c WHERE Id =: enrolId];
        Enrolment__c enrolObj = new Enrolment__c();
        if(enrolList.size() > 0){
            enrolObj = enrolList[0];
        }
        
        return  enrolObj;
    }
    
}