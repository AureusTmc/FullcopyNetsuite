public without sharing class ChangeCenterEnrolmentProcessController implements IAdvanceAction{
    Private String enrolmentId;
    Private String teacherId;
    Private String centerId;
    Private String packageId;
    Private Date effectiveDate;
    Private Boolean isDifferEffectiveDate;
    
    Private Time timeslot;
    Private String myCaseId;
    Private String caseRedirect;
    Private String previousTime;
    Private String oldPackageName;
    Private String oldcenterId;
    Private String newPackageName;
    Private date nextBillDate;
     //Data Members for Additional Work
    Private Enrolment__c enrolmentObj;
    Private Organisation__c organisationObj;
    Private UpgradeCaseCreation upgradeDetails;
    public ChangeCenterEnrolmentProcessController(String enrolmentId, String teacherId, String centerId, String packageId, 
                                         String newEffectiveDateStr,  String timeStr, String myCaseId, 
                                         String caseRedirect, String previousTime, String oldPackageName, 
                                         String newPackageName,String oldcenterId) {
        this.enrolmentId =enrolmentId;
        this.teacherId = teacherId;
        this.centerId =centerId;
        this.packageId =packageId;
        this.isDifferEffectiveDate = true;
        this.effectiveDate =  AdvanceActionsHelper.convertToDateForUpgrade(newEffectiveDateStr);
        timeslot = AdvanceActionsHelper.getDateTimeFromString(timeStr).time();
        this.myCaseId =myCaseId;
        this.caseRedirect =caseRedirect;
        this.previousTime =previousTime;
        this.oldPackageName =oldPackageName;
        this.newPackageName =newPackageName;
        this.oldcenterId = oldcenterId;
        enrolmentObj = new Enrolment__c();
        organisationObj = new Organisation__c();
        upgradeDetails = new UpgradeCaseCreation();
    }
    //Init Method where all the process gets Start...
    Public String initProcess(){
        Boolean error = true;
        Boolean dayChange = false;
        Boolean centerisHome = false;
        string invoiceId;
        string caseReturn;
        string oldTeacher;
        string oldcenter;
        string oldPackage;
        Time oldTimeSlot;
        Integer duration=0;
        Set<String> centerIds = new Set<String>();
        if(String.isNotBlank(enrolmentId)){
            enrolmentObj = AdvanceActionsHelper.fetchEnrolment(enrolmentId);
            nextBillDate = AdvanceActionsHelper.fetchNextBillDateFromEnrolment(enrolmentObj);
            if(String.isNotBlank(enrolmentObj.Id) && String.isNotBlank(enrolmentObj.center__r.Organisation__c)){
                organisationObj = enrolmentObj.center__r.Organisation__r;
            }
            oldTeacher = enrolmentObj.Teacher__c;
            oldPackage = enrolmentObj.Package__c;
            oldcenter= enrolmentObj.center__c;
            oldTimeSlot = enrolmentObj.Lesson_Start_time__c;
            if(enrolmentObj.Package__r != null && enrolmentObj.Package__r.Duration__c != null ){
             duration = Integer.valueOf(enrolmentObj.Package__r.Duration__c);
            }
            List<String> athomeCenterIds = new  List<String>();
            List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
                                                Language, NamespacePrefix, Label, QualifiedApiName, Makeup_Expiry_Days__c,Ossia_at_Home_Id__c ,
                                                Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
                                                WHERE Label =:System.Label.Ossia_Organisation_Name];
            athomeCenterIds.add(Label.Aureus_at_Home_Id);   
            if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0 && string.isNotBlank(listOfOssia_Organisation_Settings[0].Ossia_at_Home_Id__c)){
                athomeCenterIds.add(listOfOssia_Organisation_Settings[0].Ossia_at_Home_Id__c);   
            }  

            if( string.isNotBlank(centerId) && athomeCenterIds.contains(centerId)){
                centerisHome = true; 
            }
        }
     
         enrolmentObj.Effective_Date__c = effectiveDate;
        Boolean isSameMonth = nextBillDate > effectiveDate ? true : false; // 1-Sep-2020 >  3-Sep-2020
        enrolmentObj.Package_Process_Status__c = isSameMonth ? ConstantsClass.enrollmentProcessCompletedStatus :  ConstantsClass.enrollmentProcessPendingStatus;             
        if(String.isNotBlank(centerId)){
            if(isSameMonth){
                enrolmentObj.Center__c = centerId;
            }
            enrolmentObj.New_Centre__c = centerId;
        }
        if(String.isNotBlank(teacherId)){
            if(isSameMonth){
                enrolmentObj.Teacher__c = teacherId;
            }
            enrolmentObj.New_Teacher__c = teacherId;
        }
        if(String.isNotBlank(packageId)){
            if(isSameMonth){
                enrolmentObj.Package__c = packageId;
            }
            enrolmentObj.new_package_Id__c = packageId;
        }
        
        if(timeslot != null){
            if(isSameMonth){
                enrolmentObj.Lesson_Start_time__c = timeslot;
            }
            enrolmentObj.Next_Lesson_Start_time__c = timeslot;
        }
         //11-Sep-2020: Nishi:user can change lesson day so we manage this new lesson
        Datetime effectiveDatetime = datetime.newInstance(effectiveDate,system.now().time());
        if(enrolmentObj.Lesson_Day__c != effectiveDatetime.format('EEEE')){
            enrolmentObj.New_Lesson_Day__c = effectiveDatetime.format('EEEE');
        
            if(isSameMonth){
                enrolmentObj.Lesson_Day__c = effectiveDatetime.format('EEEE');
            }
        }
        enrolmentObj.Package_Process_Type__c = ConstantsClass.enrollmentProcessChangedCenter;
        enrolmentObj.Package_Process_Request_Date__c = System.today();
        enrolmentObj.Advance_Action_Requested_By__c = UserInfo.getUserId();
         
        //4-sep-2020: center change then we create another subscription and related line item this start date is according to effective date
        // we deactivate Existing subscrition line item and remove nextbilling date or added subscrition end date  of current month last date
        if(String.isNotBlank(centerId) && String.isNotBlank(oldcenter) && !(centerId.equalsIgnoreCase(oldcenter))){
            createSubscriptionAndDeactiveOldlineItem(enrolmentObj);
        }
        //4-sep-2020: center change then we create another subscription and related line item this start date is according to effective date
        // we deactivate Existing subscrition line item and remove nextbilling date or added subscrition end date  of current month last date
        if(!isSameMonth && centerisHome){
            upgradeDetails = updatePackageEffectiveDateIsGreater(enrolmentObj, oldPackage, packageId, organisationObj, effectiveDate,teacherId,centerId);
            invoiceId =upgradeDetails.invoiceId;
            error = false;
        }
        //11-Sep-2020: Nishi:user can change lesson day so we manage this new lesson so we delete all future booking with the start of effective month
        Date newEffectiveDate = Date.newInstance(effectiveDate.year(),effectiveDate.month(),1);
        if(String.isNotBlank(enrolmentObj.Id)){
             Database.SaveResult saveResult = Database.update(enrolmentObj, false);
            if(saveResult.isSuccess()){
                RescheduleAllCenterBookings allReschedule = new RescheduleAllCenterBookings( enrolmentObj, effectiveDate);
            }
            error = false;
        }
       //system.debug('@@invoiceId'+invoiceId);
        if(caseRedirect == 'true' && error == false && enrolmentObj != NULL){
            caseReturn =    updateCase(myCaseId,enrolmentObj.id,oldPackageName,newPackageName,teacherId, oldTeacher,effectiveDate, 
                            timeslot,previousTime, invoiceId,centerId,oldcenter);
        }else if(error == false){
            caseReturn = '';
        }else{
            caseReturn = 'error';
        }
      //system.debug('@@@caseId'+caseReturn);                                    
        return caseReturn;
    }
    
    private void createSubscriptionAndDeactiveOldlineItem(Enrolment__c enr){
        map<id,Package__c> mapofpackage = new map<id,Package__c>([Select id,Package_Fee__c from Package__c where id=:enr.new_package_Id__c]); 
        Map<String, Subscription__c> activeSubMap = new Map<String, Subscription__c>();
        Map<String, Subscription_Line_Item__c> activeSubLineItemMap = new Map<String, Subscription_Line_Item__c>();
        List<Subscription_Line_Item__c> subLinItmList = new List<Subscription_Line_Item__c>();
        for(Subscription__c sub: [SELECT Id, Parent__c, Center__c FROM Subscription__c  
                                    WHERE Parent__c =: enr.Parent__c AND Center__c =:enr.New_Centre__c
                                    AND Status__c =: ConstantsClass.activeStatus]){
                activeSubMap.put(sub.Center__c, sub);
        }
        Subscription__c subs = new Subscription__c();
        if(activeSubMap.containsKey(enr.New_Centre__c)){
            subs = activeSubMap.get(enr.New_Centre__c);
        }else{
            //Filling subscription
            subs = BillingUtility.fillSubscription(enr.Parent__c, ConstantsClass.activeStatus, enr.Lessons_Start_Date__c);
            subs.Center__c = enr.New_Centre__c;
            subs.Next_Bill_Date__c   =  Date.newInstance(enr.Effective_Date__c.year(), enr.Effective_Date__c.month(), ConstantsClass.subNextBillingDay);
            Insert subs;
        }

        for(Subscription_Line_Item__c sublineItem: [Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                                    Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                                    Enrolment__r.Center__r.Organisation__r.Tax_Rate__c,Subscription_Expiry_Date__c,Status__c
                                                    FROM Subscription_Line_Item__c  
                                                    WHERE Enrolment__c=:enr.id
                                                    And Subscription__c =:subs.id]){
                    activeSubLineItemMap.put(sublineItem.Subscription__c, sublineItem);
        }
       //System.debug('subs'+subs);
        if(!activeSubLineItemMap.containsKey(subs.id)){
         
            //Filling subscription line item billing date for the enrolment
            Subscription_Line_Item__c subLItm = BillingUtility.fillSubscriptionLineItem(enr.Student__c, null, enr.new_package_Id__c, enr.Id, 
                                                mapofpackage.get(enr.new_package_Id__c).Package_Fee__c, ConstantsClass.activeStatus);
            subLItm.Subscription__c = subs.id;
            subLItm.Subscription_Start_Date__c = enr.Lessons_Start_Date__c;
            subLItm.Next_Bill_Date__c   =  Date.newInstance(enr.Effective_Date__c.year(), enr.Effective_Date__c.month(), ConstantsClass.subNextBillingDay);
            subLinItmList.add(subLItm);

            // deactivate existing subscription line item
            Subscription_Line_Item__c existingsubLItm =   enr.Subscription_Line_Items__r[0];
            existingsubLItm.Next_Bill_Date__c = null;
            date lastdateofCurrentMonth =Date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 1);
            existingsubLItm.Subscription_Expiry_Date__c = lastdateofCurrentMonth.addDays(-1);
            existingsubLItm.Status__c = ConstantsClass.statusInActive;
            subLinItmList.add(existingsubLItm);
           //System.debug('subLinItmList'+subLinItmList);
            upsert subLinItmList;
            //return fetchEnrolment(enrolmentObj.id);
        }
    }

    Public  static  List<Subscription_Line_Item__c>  fetchsublineItemList(String enrolmentId){
        List<Subscription_Line_Item__c> sublineItemList = [Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                            Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                            Enrolment__r.Center__r.Organisation__r.Tax_Rate__c,Subscription_Expiry_Date__c,Status__c
                                            FROM Subscription_Line_Item__c 
                                            Where Status__c =:ConstantsClass.activeStatus
                                            and Enrolment__c =: enrolmentId];
       
        return sublineItemList;                                          
    }

    //Hit API and create Invoice and Line Items and Payment Record if the Next Bill Date is less than Effective Date
    //// ex: 8-Sep-2020 effective date and next Billing date 1-Sep-2020
    public static UpgradeCaseCreation updatePackageEffectiveDateIsGreater(Enrolment__c enrolmentObj, String oldPackageId, String newPackageId, 
    Organisation__c  organisationObj, Date effectiveDate,string newTeacherId,string newCenterId){
        List<Subscription_Line_Item__c> sublineItemList = fetchsublineItemList(enrolmentObj.id);
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
       //System.debug('##summary'+summary);
       //System.debug('##enrolmentObj'+enrolmentObj);
        if(String.isNotBlank(enrolmentObj.Id)){
          
            currentPackageDeposit = AdvanceActionsHelper.getDepositFromFile(enrolmentObj.Id);
        }
       //System.debug('##currentPackageDeposit'+currentPackageDeposit);
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
       //System.debug('##newPackage.Deposit_Fee__c '+newPackage );
        Decimal depositeFee = 0;
        if(newPackage.Deposit_Fee__c != null && newPackage.Deposit_Fee__c> 0)
            depositeFee = BillingUtility.roundOffAmount((newPackage.Deposit_Fee__c - currentPackageDeposit)); 
        if(enrolmentObj != Null){
            stripeId = sublineItemList[0].Subscription__r.Parent__r.Stripe_Customer_Id__c;// enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__r.Stripe_Customer_Id__c;
            parentId =sublineItemList[0].Subscription__r.Parent__c;//enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.Parent__c;
        }
       //System.debug('##stripeId'+stripeId);
       //System.debug('##parentId'+parentId);
       //System.debug('##depositeFee'+depositeFee);
        //Summary details on upgrade package...
        upgradePackageCaseDetails.depositAmount = depositeFee;
       upgradePackageCaseDetails.total = depositeFee;
       upgradePackageCaseDetails.isSuccess = true;
        
        if(String.isNotBlank(stripeId) && depositeFee > 0 && String.isNotBlank(organisationObj.Id)){ //String.isNotBlank(centreCountry.Id)){commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
           
            Invoice_Line_Item__c inlineItemforChange = new Invoice_Line_Item__c();
           
            BillingUtility.StripeCharge chargeResponse = BillingUtility.createChargeForCustomer(stripeId, depositeFee, organisationObj.country__r.Currency_Code__c, 
                                                            organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c); 
            
           //System.debug('@@@chargeResponse'+chargeResponse);
            if(chargeResponse.statusCode == 200 && chargeResponse.paid){                
                isSuccess = true;
                //Invoice__c objInvoice = BillingUtility.fillInvoice(enrolmentObj.Subscription_Line_Items__r[0].Subscription__c, parentId, constantsClass.paidStatus);
                //objInvoice.Center__c = enrolmentObj.Subscription_Line_Items__r[0].Subscription__r.center__c;
                Invoice__c objInvoice = BillingUtility.fillInvoice(sublineItemList[0].Subscription__c, parentId, constantsClass.paidStatus);
                objInvoice.Center__c =sublineItemList[0].Subscription__r.center__c;
                insert objInvoice;
               //System.debug('@@@objInvoice'+objInvoice);
                if(String.isNotBlank(objInvoice.Id)){
                    upgradePackageCaseDetails.invoiceId = objInvoice.Id;
                }
                if(depositeFee > 0){
                    inlineItemforChange = PackageUpgradeController.createInvoiceLineItem(objInvoice.id, sublineItemList[0], depositeFee, newPackage.Id, true, '');
                    inlineItemforChange.Month__c = effectiveDate;
                    inlineItemforChange.Is_Deposit__c = True;
                    listOfInvoiceLineItems.add(inlineItemforChange);
                }
               
                if(listOfInvoiceLineItems.size() > 0){
                    INSERT listOfInvoiceLineItems;
                } 
               //System.debug('@@@listOfInvoiceLineItems'+listOfInvoiceLineItems);
                objInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c, status__c FROM Invoice__c WHERE Id =:objInvoice.Id];
                if(!Test.isRunningTest() && String.isNotBlank(organisationObj.Id)){
                    BillingUtility.updateCharge(chargeResponse.Id,objInvoice.Name, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
                }
                
                Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id, BillingUtility.roundOffAmount(objInvoice.Total_Amount__c), ConstantsClass.successStatus);
                objPayment.Transaction_ID__c = chargeResponse.Id;
                objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                INSERT objPayment; 
               //System.debug('@@@objPayment'+objPayment);
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

    
    Private Static String updateCase(String myCaseId,String enrolmentId,String oldPackageName,string newPackageName,string teacherId,String oldTeacher,
                                    date effectiveDate,time timeslot,string previousTime,string invoiceId,string centerId,String oldCenter){
        Case caseObj = AureusCalendarControllerHelper.createCaseForEnrolment(myCaseId, enrolmentId, 'changeCenter', false);
            if(String.isNotBlank(oldPackageName)){
                caseObj.Previous_Package__c = oldPackageName; 
            }
            if(String.isNotBlank(newPackageName)){
                caseObj.New_Package__c = newPackageName; 
            }
            if(String.isNotBlank(teacherId)){
                caseObj.New_Teacher__c =  teacherId;  
            }
            if(String.isNotBlank(oldTeacher)){ 
                caseObj.Previous_teacher__c = oldTeacher; 
            }
            if(String.isNotBlank(centerId)){
                caseObj.New_Center__c =  centerId;   
            }
            if(String.isNotBlank(oldCenter)){
                 caseObj.Previous_Center__c = oldCenter; 
            }
            if(effectiveDate != null){
                DateTime newformatTime = DateTime.newInstance(effectiveDate, timeslot);
                caseObj.New_Lesson_Day_Time__c = newformatTime.format('EEE @ h:mm a');
            }
            if(String.isNotBlank(previousTime)){
                caseObj.Previous_Lesson_Day_Time__c = previousTime;
            }
            if(String.isNotBlank(invoiceId)){
                 caseObj.Invoice__c = invoiceId;     
            }
           upsert caseObj; 
           return  caseObj.id;
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