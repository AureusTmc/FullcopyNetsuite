public without sharing class UpgradeEnrolmentProcessController implements IAdvanceAction{

    //Data Members for the Upgrade Package of the Customer
    Private String booking;
    Private Date effectiveDate;
    Private String oldPackage;
    Private String newPackage;
    Private Time timeslot;
    Private String caseId;
    Private String caseRedirect;
    Private Map<String, String> mapOfCase;
    
    //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    Private Date nextBillDate;
    Private Country__c countryObj;
    Private UpgradeCaseCreation upgradeDetails;

    //Constructor to Initialize all the data members
    public UpgradeEnrolmentProcessController(String booking, String effectiveDateStr, String newPackage, 
                                             String oldPackage, String timeSlot, String caseId, String caseRedirect, 
                                             Map<String, String> caseValuesOfMap) {
        this.booking = booking;
        effectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(effectiveDateStr);
        this.newPackage = newPackage;
        this.oldPackage = oldPackage;
        this.timeslot = AdvanceActionsHelper.getDateTimeFromString(timeSlot).time();
        this.caseId = caseId;
        this.caseRedirect = caseRedirect;

        mapOfCase = new Map<String, String>();
        mapOfCase = caseValuesOfMap;

        enrolmentObj = new Enrolment__c();
        
        countryObj = new Country__c();
        upgradeDetails = new UpgradeCaseCreation();

    }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
        String caseIdToReturn;
        Boolean isSuccess = FALSE;
        Set<String> setOfBookings = new Set<String>();
        Map<String, Booking__c> mapOfMakeupBooking = new Map<String, Booking__c>();

        //Fetch Next Bill Date From Enrolment
        nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
        
        //Fetch the Country Object From Enrolment
        countryObj = AdvanceActionsHelper.fetchCountryFromEnrolment(enrolmentObj);

        if(effectiveDate <= nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
            upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, nextBillDate, newPackage, oldPackage, timeslot, countryObj);
            enrolmentObj = upgradeDetails.enrolObj;
        }else if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
            upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, countryObj, effectiveDate);
            if(upgradeDetails.isSuccess){
                enrolmentObj.New_Package_Id__c = newPackage;
                enrolmentObj.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
                enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
                enrolmentObj.Effective_Date__c = effectiveDate;
                enrolmentObj.Package_Process_Request_Date__c = System.today();
                enrolmentObj.Advance_Action_Requested_By__c = Userinfo.getUserId();
                enrolmentObj.Next_Lesson_Start_time__c = timeslot;
                
                if(String.isNotBlank(enrolmentObj.Id)){
                    Database.SaveResult saveResult = Database.Update(enrolmentObj, false);
                    if(!saveResult.isSuccess()){
                        isSuccess = false;
                    }
                }
            }
        }
        enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
        if(String.isNotBlank(enrolmentObj.Id) && upgradeDetails.isSuccess){
            AdvanceActionsHelper.processFutureBookings(enrolmentObj, 'upgrade');
            setOfBookings = AdvanceActionsHelper.processFutureFifthLessons(enrolmentObj, 'upgrade');
            for(Booking__c bookingObj : AdvanceActionsHelper.fetchAllBooking(setOfBookings)){
                mapOfMakeupBooking.put(bookingObj.Id, bookingObj);
            }
        }
        
        Integer timeDiff = 0;
        if(String.isNotBlank(enrolmentObj.Id) && mapOfMakeupBooking.size() > 0){
            if(String.isNotBlank(oldPackage) && String.isNotBlank(newPackage)){
                AdvanceActionsHelper.UpgradeDowngradePackageSummary summary = AdvanceActionsHelper.getPackageDetailsUpgradeDowngrade(oldPackage, newPackage);
                
                timeDiff = Integer.valueOf(summary.newDuration) - Integer.valueOf(summary.oldDuration);   
                
                AureusCalendarControllerHelper.createFifthBookingOnUpgrade(enrolmentObj, mapOfMakeupBooking, timeDiff, timeSlot, Integer.valueOf(summary.oldDuration));
            }
        }
        if(caseRedirect == 'true'){
            Case objCase =  AureusCalendarControllerHelper.createCaseForEnrolment(caseId, enrolmentObj.Id, 'upgrade', false);
            if(String.isNotBlank(upgradeDetails.invoiceId)){
                objCase.Invoice__c = upgradeDetails.invoiceId;
            }
            objCase.deposit_Topup__c = upgradeDetails.depositAmount;
            objCase.Lesson_Charge_Topup__c = upgradeDetails.lessonCharge;
            objCase.Total_Invoice_topup__c  = upgradeDetails.total;
            if(mapOfCase.containsKey('previousPackage')){
                objCase.Previous_Package__c = mapOfCase.get('previousPackage');    
            }
            if(mapOfCase.containsKey('newPackage')){
                objCase.New_Package__c = mapOfCase.get('newPackage');    
            }
            if(mapOfCase.containsKey('previousLessonDayTime')){
                objCase.Previous_Lesson_Day_Time__c = mapOfCase.get('previousLessonDayTime');    
            }
            if(mapOfCase.containsKey('newLessonDayTime')){
                objCase.New_Lesson_Day_Time__c = mapOfCase.get('newLessonDayTime');    
            }
            if(mapOfCase.containsKey('currentDepositonFile')){
                objCase.Current_Deposit_on_File__c = Decimal.valueOf(mapOfCase.get('currentDepositonFile'));    
            }
            if(mapOfCase.containsKey('newPackageDeposit')){
                objCase.New_Package_Deposit__c = Decimal.valueOf(mapOfCase.get('newPackageDeposit'));    
            }
            if(mapOfCase.containsKey('invoiceForCurrentMonth')){
                objCase.Invoice_for_Current_Month__c = Decimal.valueOf(mapOfCase.get('invoiceForCurrentMonth'));    
            }
            
            upsert objCase;
            caseIdToReturn = objCase.Id;
        }
        if(!upgradeDetails.isSuccess)
            caseIdToReturn = 'error';
        return caseIdToReturn;
    }

    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
    Private UpgradeCaseCreation updatePackageNextDateIsGreater(String enrolmentId, Date effectiveDate, Date nextBillDate, String newPackageId, String oldPackageId, Time newTimeSlot, Country__c countryObj){
        UpgradeCaseCreation upgradeCaseDetails = new UpgradeCaseCreation();
        Boolean isSuccess = false;
        String invoiceId;
        if(String.isNotBlank(enrolmentId) && nextBillDate != Null && effectiveDate != Null &&
           String.isNotBlank(newPackageId) && String.isNotBlank(oldPackageId) && newTimeSlot != Null && String.isNotBlank(countryObj.Id)){
               upgradeCaseDetails = upgradeDowngradeController.upgradePackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, countryObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c, countryObj.Tax_Rate__c);
           }
        return upgradeCaseDetails;
    }

    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
    Private UpgradeCaseCreation updatePackageEffectiveDateIsGreater(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId, Country__c centreCountry, Date effectiveDate){
        Boolean isSuccess = false;
        UpgradeCaseCreation upgradePackageCaseDetails = new UpgradeCaseCreation();
        String invoiceId = '';
        String stripeId = '', parentId = '';
        Decimal currentPackageDeposit = 0;
        Package__c newPackage, oldPackage = new Package__c();
        Set<String> invoiceIds = new Set<String>();
        AdvanceActionsHelper.UpgradeDowngradePackageSummary summary = AdvanceActionsHelper.getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
        newPackage = summary.newPackage;
        oldPackage = summary.oldPackage; 
        
        if(String.isNotBlank(enrolmentObj.Id)){
            system.debug('##currentPackageDeposit'+currentPackageDeposit);
            currentPackageDeposit = AdvanceActionsHelper.getDepositFromFile(enrolmentObj.Id);
        }
        
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Decimal depositeFee = BillingUtility.roundOffAmount((newPackage.Deposit_Fee__c - currentPackageDeposit)); 
        if(enrolmentObj != Null){
            stripeId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c;
            parentId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
        
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
        upgradePackageCaseDetails.total = depositeFee;
        upgradePackageCaseDetails.isSuccess = true;
        
        if(String.isNotBlank(stripeId) && depositeFee > 0 && String.isNotBlank(centreCountry.Id)){
           
            Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c); 
            
            System.debug('@@@chargeResponse'+chargeResponse);
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){                
                isSuccess = true;
                Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.paidStatus);
                objInvoice.Center__c = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.center__c;
                
                insert objInvoice;
                
                if(String.isNotBlank(objInvoice.Id)){
                    upgradePackageCaseDetails.invoiceId = objInvoice.Id;
                }
                if(depositeFee > 0){
                    inlineItemforChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolmentObj.Subscription_Line_Items__r[0], depositeFee, newPackage.Id, true, '');
                    inlineItemforChange.Month__c = effectiveDate;
                    inlineItemforChange.Is_Deposit__c = True;
                    listOfInvoiceLineItems.add(inlineItemforChange);
                }
                
                if(listOfInvoiceLineItems.size() > 0){
                    INSERT listOfInvoiceLineItems;
                } 
                
                objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                if(!Test.isRunningTest() && String.isNotBlank(centreCountry.Id)){
                    BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                }
                
                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, BillingUtility.roundOffAmount(objInvoice.Total_Amount__c), ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = chargeResponse.Id;
                objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                INSERT objPayment; 
                
                if(String.isNotBlank(objPayment.id) && String.isNotBlank(objInvoice.id)){
                    SageIntacctIntegrationUtility.packageUpgrade(objInvoice.Id, objPayment.Id);
                }
                
                if(objInvoice != NULL){
                    invoiceIds.add(objInvoice.Id);
                    BillingUtility.createAttachment(invoiceIds);
                }
            }else{
                isSuccess = false;
                upgradePackageCaseDetails.isSuccess = false;
            }
        }else{
            isSuccess = false;
        }
        return upgradePackageCaseDetails;
    }

    //Wrapper Class For Upgrade Enrolment Callout
    public class UpgradeCaseCreation{
        public String invoiceId;
        public Decimal depositAmount;
        public Decimal lessonCharge;
        public Decimal total;
        public Enrolment__c enrolObj;
        public Boolean isSuccess = false;
    }
}