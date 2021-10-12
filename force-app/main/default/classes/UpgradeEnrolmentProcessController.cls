/*
Name        :        UpgradeEnrolmentProcessController
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        This Controller help for AureusCalendarController.
test class 	:		UpgradeEnrolmentProcessControllertest
*/
public without sharing class UpgradeEnrolmentProcessController implements IAdvanceAction{

    //Data Members for the Upgrade Package of the Customer
    Private String booking;
    Private Date effectiveDate;
    Private String oldPackage;
    Private String newPackage;
    Private String oldTeacherId;
    Private String newTeacherId;
    Private Time timeslot;
    Private String caseId;
    Private String caseRedirect;
    Private Map<String, String> mapOfCase;
    
    //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    Private Date nextBillDate;
    //Private Country__c countryObj;commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
    Private Organisation__c organisationObj;
    Private UpgradeCaseCreation upgradeDetails;

    //Constructor to Initialize all the data members
    public UpgradeEnrolmentProcessController(String booking, String effectiveDateStr, String newPackage, 
                                             String oldPackage, String timeSlot, String caseId, String caseRedirect, 
                                             Map<String, String> caseValuesOfMap,
                                             // added by nishi:11-Aug-2020: for manage ossia organisation new teacher
                                             String oldTeacherId,String newTeacherId) {
        this.booking = booking;
        effectiveDate = AdvanceActionsHelper.convertToDateForUpgrade(effectiveDateStr);
        this.newPackage = newPackage;
        this.oldPackage = oldPackage;
        // added by nishi:start-11-Aug-2020: for manage ossia organisation new teacher
        this.newTeacherId = newTeacherId;
        this.oldTeacherId = oldTeacherId;
        // added by nishi:End-11-Aug-2020: for manage ossia organisation new teacher
        this.timeslot = AdvanceActionsHelper.getDateTimeFromString(timeSlot).time();
        this.caseId = caseId;
        this.caseRedirect = caseRedirect;

        mapOfCase = new Map<String, String>();
        mapOfCase = caseValuesOfMap;

        enrolmentObj = new Enrolment__c();
        
        //countryObj = new Country__c();commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
        organisationObj = new Organisation__c();
        upgradeDetails = new UpgradeCaseCreation();

    }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        Savepoint downgradeSavePoint;
        String caseIdToReturn;
        try{
            
            enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
            
            Boolean isSuccess = FALSE;
            Set<String> setOfBookings = new Set<String>();
            Map<String, Booking__c> mapOfMakeupBooking = new Map<String, Booking__c>();
            Boolean isPromotionalEnrolment=false;
            Boolean isPromoPackageEnrolment=false;
            if( String.isNotBlank(enrolmentObj.Type_of_Package__c) && (enrolmentObj.Type_of_Package__c == ConstantsClass.prePaymentType || enrolmentObj.Type_of_Package__c == ConstantsClass.PromoTypePayment)){
                isPromotionalEnrolment= true;
                if(enrolmentObj.Type_of_Package__c == ConstantsClass.PromoTypePayment){
                    isPromoPackageEnrolment= true;
                    
                }
            }
            //Fetch Next Bill Date From Enrolment
            nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
            
            //Fetch the Country Object From Enrolment
            //countryObj = AdvanceActionsHelper.fetchCountryFromEnrolment(enrolmentObj);
            if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.center__r.Organisation__c)){
                organisationObj = enrolmentObj.center__r.Organisation__r;
            }
            // New Effective date   is less then next Billing date
            // ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020  (If next month biiling Advance created Paid September payment) 
            // ex: 12-Aug-2020 effective date and next Billing date 1-sep-2020  (If current month biiling created Paid Augest payment) 
            //Start:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
            /*if(effectiveDate <= nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(countryObj.Id)){
upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, nextBillDate, newPackage, oldPackage, timeslot, countryObj,newTeacherId);
enrolmentObj = upgradeDetails.enrolObj;
}*/
            //end:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
            if(effectiveDate < nextBillDate && String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(organisationObj.Id)){
                date updatednextBillDate= isPromoPackageEnrolment &&  enrolmentObj.Promotional_Period_End_Date__c != null && enrolmentObj.Promotional_Period_End_Date__c >= nextBillDate ? enrolmentObj.Promotional_Period_End_Date__c : nextBillDate;
                upgradeDetails = updatePackageNextDateIsGreater(enrolmentObj.Id, effectiveDate, updatednextBillDate, newPackage, oldPackage, timeslot, organisationObj,newTeacherId,isPromotionalEnrolment);
                enrolmentObj = upgradeDetails.enrolObj;
            }
            // New Effective date   is greated then next Billing date
            // ex: 8-Sep-2020 effective date and next Billing date 1-sep-2020(If current month biiling created Paid Augest payment) 
            else if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(organisationObj.Id)){
                // upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, countryObj, effectiveDate,newTeacherId);
                upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, newPackage, organisationObj, effectiveDate,newTeacherId);
             
                if(upgradeDetails.isSuccess){
                     // added by nishi: 10-May-2021:start: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
                    //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
                    if(isPromotionalEnrolment){
                        if(isPromoPackageEnrolment && effectiveDate >= nextBillDate  && enrolmentObj.Promotional_Period_End_Date__c >= nextBillDate){
                            map<string,Credit_Memo__c> newPendingCreditMemos = upgradeDowngradeController.createCreditMemoNextBillingDateForPromoPackage(enrolmentObj.Id,oldPackage, effectiveDate,'Upgrade Enrolment Adjustment');
                        }
                        AdvanceActionsHelper.updatePromotionalEnrolment(enrolmentObj,effectiveDate,nextBillDate);
                    }
                    // added by nishi: 10-May-2021:end: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
                    //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
                
                    // added by nishi:start-11-Aug-2020: for manage ossia organisation new teacher
                    if(string.isNotBlank(newTeacherId)){
                        enrolmentObj.New_Teacher__c = newTeacherId;
                    }
                    // added by nishi:end-11-Aug-2020: for manage ossia organisation new teacher
                    enrolmentObj.New_Package_Id__c = newPackage;
                    enrolmentObj.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
                    enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
                    enrolmentObj.Effective_Date__c = effectiveDate;
                    enrolmentObj.Package_Process_Request_Date__c = System.today();
                    enrolmentObj.Advance_Action_Requested_By__c = Userinfo.getUserId();
                    enrolmentObj.Next_Lesson_Start_time__c = timeslot;
                    
                    if(String.isNotBlank(enrolmentObj.Id)){
                        Database.SaveResult saveResult = Database.Update(enrolmentObj, false);
                        //System.debug('saveResult'+saveResult);
                        if(!saveResult.isSuccess()){
                            isSuccess = false;
                        }
                    }
                }
            }
            downgradeSavePoint = Database.setSavepoint();
            // 21-Oct-2020 : @@nishi  :if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
           /* if(isPromotionalEnrolment){
                enrolmentObj =AdvanceActionsHelper.updateSubscriptionNextBillDate(enrolmentObj,effectiveDate,nextBillDate);
            }*/
            // 21-Oct-2020 : @@nishi  End::if Enrolment package type is Prepayemnt or promo thenChange the next bill dates in Subs line items and Subscription to the first day of the next month
            
            enrolmentObj = AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(this.booking);
            if(String.isNotBlank(enrolmentObj.Id) && upgradeDetails.isSuccess){
                AdvanceActionsHelper.processFutureBookings(enrolmentObj, 'upgrade');
                setOfBookings = AdvanceActionsHelper.processFutureFifthLessons(enrolmentObj, 'upgrade');
                //System.debug('setOfBookings'+setOfBookings);
                for(Booking__c bookingObj : AdvanceActionsHelper.fetchAllBooking(setOfBookings)){
                    mapOfMakeupBooking.put(bookingObj.Id, bookingObj);
                }
                //System.debug('mapOfMakeupBooking'+mapOfMakeupBooking);
            }
            
            Integer timeDiff = 0;
            if(String.isNotBlank(enrolmentObj.Id) && mapOfMakeupBooking.size() > 0){
                if(String.isNotBlank(oldPackage) && String.isNotBlank(newPackage)){
                    AdvanceActionsHelper.UpgradeDowngradePackageSummary summary = AdvanceActionsHelper.getPackageDetailsUpgradeDowngrade(oldPackage, newPackage);
                    timeDiff = Integer.valueOf(summary.newDuration) - Integer.valueOf(summary.oldDuration);   
                    //System.debug('enrolmentObj.Center__r.Organisation__r.Name'+enrolmentObj.Center__r.Organisation__r.Name);
                    //Start-added by nishi: 12-aug-2020: for if enrolment center is ossia then we get makeup mins  to enolment other wise parent makeup min we get
                    if(String.isNotBlank(enrolmentObj.Center__c) && String.isNotBlank(enrolmentObj.Center__r.Organisation__c) && String.isNotBlank(enrolmentObj.Center__r.Organisation__r.Name) && 
                       enrolmentObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                           OssiaCenterCalendarController.createOssiaFifthBookingOnUpgrade(enrolmentObj, mapOfMakeupBooking, timeDiff, timeSlot, Integer.valueOf(summary.oldDuration));
                       }else{
                           AureusCalendarControllerHelper.createFifthBookingOnUpgrade(enrolmentObj, mapOfMakeupBooking, timeDiff, timeSlot, Integer.valueOf(summary.oldDuration));
                       }  
                    //End-added by nishi: 12-aug-2020: for if enrolment center is ossia then we get makeup mins  to enolment other wise parent makeup min we get  
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
                // added by nishi:start-11-Aug-2020: for manage ossia organisation new teacher
                if(string.isNotBlank(oldTeacherId)){
                    objCase.Previous_teacher__c = oldTeacherId;    
                }
                if(string.isNotBlank(newTeacherId)){
                    objCase.New_Teacher__c = newTeacherId;    
                }
                // added by nishi:end-11-Aug-2020: for manage ossia organisation new teacher
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
            //System.debug('upgradeDetails'+upgradeDetails);
            if(!upgradeDetails.isSuccess)
                caseIdToReturn = 'error';
        }catch (Exception e){
            caseIdToReturn = 'error';
            System.debug('@@caseIdToReturn'+e.getStackTraceString()+'-'+e.getMessage() +';');
            //On 14-Oct-2020: Nishi to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(downgradeSavePoint);
        }
        return caseIdToReturn;
    }

    

    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is Greater than Effective Date
    //  // ex: 12-Aug-2020 effective date and next Billing date 1-Sep-2020
    Private UpgradeCaseCreation updatePackageNextDateIsGreater(String enrolmentId, Date effectiveDate, Date nextBillDate, String newPackageId, String oldPackageId, 
    Time newTimeSlot, Organisation__c  organisationObj,/*Country__c countryObj,*/string newTeacherId,Boolean isPromotionalEnrolment){
        UpgradeCaseCreation upgradeCaseDetails = new UpgradeCaseCreation();
        Boolean isSuccess = false;
        String invoiceId;
        if(String.isNotBlank(enrolmentId) && nextBillDate != Null && effectiveDate != Null &&
           String.isNotBlank(newPackageId) && String.isNotBlank(oldPackageId) && newTimeSlot != Null && String.isNotBlank(organisationObj.Id)){ //String.isNotBlank(countryObj.Id)){
            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
            //    upgradeCaseDetails = upgradeDowngradeController.upgradePackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, 
            //    countryObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c, countryObj.Tax_Rate__c,newTeacherId);
            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
                 upgradeCaseDetails = upgradeDowngradeController.upgradePackage(enrolmentId, effectiveDate, newPackageId, oldPackageId, newTimeSlot, 
                organisationObj.country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c, organisationObj.Tax_Rate__c,newTeacherId,
                isPromotionalEnrolment);
           }
        return upgradeCaseDetails;
    }
    

    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is less than Effective Date
    //// ex: 8-Sep-2020 effective date and next Billing date 1-Sep-2020
    Private UpgradeCaseCreation updatePackageEffectiveDateIsGreater(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId, 
    Organisation__c  organisationObj,/*Country__c centreCountry,*/ Date effectiveDate,string newTeacherId){
        Boolean isSuccess = false;
        Boolean isOssiaOrganization = false;
        if(string.isNotBlank(enrolmentObj.Center__c) && 
            string.isNotBlank(enrolmentObj.Center__r.Organisation__c) && string.isNotBlank(enrolmentObj.Center__r.Organisation__r.Name) &&
            enrolmentObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssiaOrganization = true;
            }
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
           //System.debug('##currentPackageDeposit'+currentPackageDeposit);
            currentPackageDeposit = AdvanceActionsHelper.getDepositFromFile(enrolmentObj.Id);
        }
        
       
        Decimal depositeFee = BillingUtility.roundOffAmount((newPackage.Deposit_Fee__c - currentPackageDeposit)); 
        if(enrolmentObj != Null){
            stripeId = string.isNotBlank(enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c) ? enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c :'';
            parentId = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
        
       
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
       upgradePackageCaseDetails.total = depositeFee;
       upgradePackageCaseDetails.isSuccess = true;
        
        if(depositeFee > 0 && String.isNotBlank(organisationObj.Id)){ //String.isNotBlank(centreCountry.Id)){commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
           if(String.isNotBlank(stripeId) ){
            
            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
                //BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c); 
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, organisationObj.country__r.Currency_Code__c, 
                                                                organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c); 
                
            //System.debug('@@@chargeResponse'+chargeResponse);
                if(chargeResponse.statusCode == 200 && chargeResponse.paid){                
                    isSuccess = true;
                    upgradePackageCaseDetails = createDueInvoiceWithLineItem(enrolmentObj,parentId,upgradePackageCaseDetails,depositeFee,newPackage,effectiveDate);
                    if(String.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                        objInvoice.status__c = constantsClass.paidStatus;
                        update objInvoice;
                        //start:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
                        // if(!Test.isRunningTest() && String.isNotBlank(centreCountry.Id)){
                        //     BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                        // }
                        //End:commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
                        if(!Test.isRunningTest() && String.isNotBlank(organisationObj.Id)){
                            BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
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
                    }
                }else{
                    isSuccess = false;
                    upgradePackageCaseDetails.isSuccess = false;
                    //upgrade should be allowed and invoice should be still generated even if the card is failed
                    if(isOssiaOrganization){
                        upgradePackageCaseDetails = createDueInvoiceWithLineItem(enrolmentObj,parentId,upgradePackageCaseDetails,depositeFee,newPackage,effectiveDate);
                        if(String.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                            Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                            if(objInvoice != NULL){
                                invoiceIds.add(objInvoice.Id);
                                BillingUtility.createAttachment(invoiceIds);
                            }
                            upgradePackageCaseDetails.isSuccess = true;
                        }
                    }
                }
            }else{
                upgradePackageCaseDetails.isSuccess = false;
                //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                if(isOssiaOrganization){
                    upgradePackageCaseDetails = createDueInvoiceWithLineItem(enrolmentObj,parentId,upgradePackageCaseDetails,depositeFee,newPackage,effectiveDate);
                    if(String.isNotBlank(upgradePackageCaseDetails.invoiceId)){
                        Invoice__c objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:upgradePackageCaseDetails.invoiceId];
                        if(objInvoice != NULL){
                            BillingUtility.createAttachment(new Set<String>{objInvoice.Id});
                        }
                        BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{objInvoice.Id});
                        upgradePackageCaseDetails.isSuccess = true;
                    }
                }
                 //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
            }
        }else{
            isSuccess = false;
            upgradePackageCaseDetails.isSuccess = false;
        }
        return upgradePackageCaseDetails;
    }

    private static UpgradeCaseCreation createDueInvoiceWithLineItem(Enrolment__c enrolmentObj,string parentId,UpgradeCaseCreation upgradePackageCaseDetails,
                                                                        Decimal depositeFee, package__c newPackage, date effectiveDate){
        //constantsClass.paidStatus
        Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.dueStatus);
        objInvoice.Center__c = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.center__c;
        
        insert objInvoice;
        
        if(String.isNotBlank(objInvoice.Id)){
            upgradePackageCaseDetails.invoiceId = objInvoice.Id;
        }
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        if(depositeFee > 0){
            Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
            inlineItemforChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, enrolmentObj.Subscription_Line_Items__r[0], depositeFee, newPackage.Id, true, '');
            inlineItemforChange.Month__c = effectiveDate;
            inlineItemforChange.Is_Deposit__c = True;
            listOfInvoiceLineItems.add(inlineItemforChange);
        }
        
        if(listOfInvoiceLineItems.size() > 0){
            INSERT listOfInvoiceLineItems;
        }
        return upgradePackageCaseDetails; 
    }

    //Wrapper Class For Upgrade Enrolment Callout
    public class UpgradeCaseCreation{
        public String invoiceId{get;set;}
        public Decimal depositAmount{get;set;}
        public Decimal lessonCharge{get;set;}
        public Decimal total{get;set;}
        public Enrolment__c enrolObj{get;set;}
        public Boolean isSuccess{get;set;}
        public UpgradeCaseCreation(){
            isSuccess = false;
        }
    }
}