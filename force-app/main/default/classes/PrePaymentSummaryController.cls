/*
    Name        :   PrePaymentSummaryController
    Date        :   06/21/2019
    Author      :   Arpit Vijayvergiya
    Description :   This controller is used to display summary for prepayment page
*/
public without sharing class PrePaymentSummaryController {
    private String packageId;
    private String enrolId;
    private Integer noOfMonths;
    public Enrolment__c enrolment{get;set;}
    public Package__c prepayPackage{get;set;}
    public Boolean isAlreadyStripCstmr{get;set;}
    public List<BillingSummary> listOfSummary{get;set;}
    public Date firstDate{get;set;}
    public Date lastDate{get;set;}
    public Date nextBillDate{get;set;}
    public Decimal gstAmount{get;set;}
    public Decimal finalAmount{get;set;}
    public String base64SignImg{get;set;}
    public Boolean isErrorOnSave{get;set;}
    public String errorMessage{get;set;}
    public string attId{get;set;}
    public Decimal amountAfterDiscount{get;set;}
    public String cardNumber{get;set;}
    public String cardImage{get;set;}
    private Subscription_Line_Item__c objLineItem;
    public boolean isExpired{get;set;}
    Public boolean isOssia{get;set;}
    Public Decimal totalPackageAmount{get;set;}
    //Public Country__c centreCountry;
    Public Organisation__c organisationOfCentre;
    public PrePaymentSummaryController(){
        gstAmount = 0;
        isOssia = false;
        amountAfterDiscount = 0;
        //centreCountry = new Country__c();
        organisationOfCentre = new Organisation__c();
        isExpired = false;
        enrolId = ApexPages.currentPage().getParameters().get('enrolId');
        system.debug('@@@PrePaymentSummaryController -enrolId'+enrolId);
        packageId = ApexPages.currentPage().getParameters().get('packageId');
        system.debug('@@@PrePaymentSummaryController -packageId'+packageId);
        enrolment = fetchEnrol(enrolId);
        system.debug('@@@PrePaymentSummaryController -enrolment'+enrolment);
        prepayPackage = fetchPackage(packageId);
        //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
        // if(String.isNotBlank(enrolment.Id) && String.isNotBlank(enrolment.Center__r.Country__r.Id)){
        //     centreCountry = enrolment.Center__r.Country__r; 
        // }
        totalPackageAmount =0;
        if(prepayPackage.Package_Fee__c != null && prepayPackage.Package_Fee__c > 0){
            totalPackageAmount = prepayPackage.Package_Fee__c;
        }
        if(String.isNotBlank(enrolment.Id) && String.isNotBlank(enrolment.Center__r.Organisation__r.Id)){
            organisationOfCentre = enrolment.Center__r.Organisation__r; 
            if(organisationOfCentre.name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssia = true;
                // if(prepayPackage.facility_Fee__c != null && prepayPackage.facility_Fee__c> 0)
                // totalPackageAmount += prepayPackage.facility_Fee__c;
            }
        }
        attId = fetchAttachment(enrolment);
        system.debug('@@@PrePaymentSummaryController -attId'+attId);
        cardNumber = enrolment.Parent__r.Card_Number__c;
        cardImage = enrolment.Parent__r.Card_Image__c;
        system.debug('@@@PrePaymentSummaryController -cardNumber'+cardNumber);
        system.debug('@@@PrePaymentSummaryController -cardImage'+cardImage);

        objLineItem = fetchSubsLineItem(enrolment.id);
        Date nextMonthDate = System.today().addMonths(1);
        system.debug('@@@PrePaymentSummaryController -nextMonthDate'+nextMonthDate);
        firstDate = objLineItem.Next_Bill_Date__c;
        system.debug('@@@PrePaymentSummaryController -firstDate'+firstDate);
        isExpired = checkLinkExpiry(enrolment,prepayPackage,firstDate);
        system.debug('@@@PrePaymentSummaryController -prepayPackage.Promotion_period_In_months__c'+prepayPackage.Promotion_period_In_months__c);
        noOfMonths = String.isNotBlank(prepayPackage.Promotion_period_In_months__c) ? Integer.valueOf(prepayPackage.Promotion_period_In_months__c) : 0;
        system.debug('@@@PrePaymentSummaryController -noOfMonths'+noOfMonths);
        lastDate = firstDate.addMonths(noOfMonths);
        system.debug('@@@PrePaymentSummaryController -firstDate.addMonths(noOfMonths) --lastDate :'+lastDate);
        nextBillDate = lastDate;
        system.debug('@@@PrePaymentSummaryController -nextBillDate :'+nextBillDate);
        lastDate = lastDate.addDays(-1);
        system.debug('@@@PrePaymentSummaryController -lastDate :'+lastDate);
        system.debug('@@PrePaymentSummaryController -prepayPackage'+prepayPackage);
        listOfSummary = fillBillSummary(prepayPackage,firstDate,noOfMonths);
        system.debug('@@PrePaymentSummaryController -listOfSummary'+listOfSummary);
        system.debug('@@PrePaymentSummaryController -prepayPackage.Package_Fee__c'+prepayPackage.Package_Fee__c);
        
        if(prepayPackage.Package_Fee__c <> NULL){
            //amountAfterDiscount = prepayPackage.Package_Fee__c-prepayPackage.Promotion_Discount__c;
            for(BillingSummary summary : listOfSummary){
                system.debug('@@summary --prepayPackage.Promotion_Discount__c'+prepayPackage.Promotion_Discount__c);
                system.debug('@@summary --summary'+summary);
                if(prepayPackage.Promotion_Discount__c <> NULL){
                    amountAfterDiscount += summary.amount - summary.discount;
                }
                //   //added by nishi:27-aug-2020:if ossia organisation and Facility fee is exist  so we added  Facility fees
                // if(isOssia && summary.faclityFee != null && summary.faclityFee > 0){
                //     amountAfterDiscount+=summary.faclityFee;
                // }   
                //   //added by nishi:27-aug-2020:if ossia organisation and Facility fee is exist  so we added  Facility fees
                if(String.isNotBlank(enrolment.Center__r.Country__r.Id) && enrolment.Center__r.Country__r.Tax_Rate__c > 0){
                    //    gstAmount += ((summary.amount - summary.discount) + (isOssia ? summary.faclityFee :0)) * (enrolment.Center__r.Country__r.Tax_Rate__c / 100);    
                
                    gstAmount += ((summary.amount - summary.discount) * (enrolment.Center__r.Country__r.Tax_Rate__c / 100));    
                }
            }
            system.debug('@@PrePaymentSummaryController -amountAfterDiscount'+amountAfterDiscount);
            system.debug('@@PrePaymentSummaryController -gstAmount'+gstAmount);
            finalAmount = amountAfterDiscount + gstAmount;
            system.debug('@@@PrePaymentSummaryController -finalAmount'+finalAmount);
        }
        
        if(amountAfterDiscount > 0 || gstAmount > 0 || finalAmount > 0){
            amountAfterDiscount = (amountAfterDiscount != NULL) ? BillingUtility.roundOffAmount(amountAfterDiscount): 0;
            gstAmount = BillingUtility.roundOffAmount(gstAmount);   
            system.debug('@@PrePaymentSummaryController -amountAfterDiscount'+amountAfterDiscount);
            system.debug('@@PrePaymentSummaryController -gstAmount'+gstAmount);
			finalAmount = BillingUtility.roundOffAmount(finalAmount);
            System.debug('@@@PrePaymentSummaryController -finalAmount'+finalAmount);
        }
    }
    
    public PageReference completePrepayment(){
        PageReference page = NULL;
        system.debug('@@completePrepayment- enrolment.Parent__r.stripe_customer_id__c'+enrolment.Parent__r.stripe_customer_id__c);
        system.debug('@@completePrepayment-organisationOfCentre'+organisationOfCentre.Id);
         system.debug('@@completePrepayment-finalAmount'+finalAmount);
        system.debug('@@completePrepayment-enrolment.Parent__r.Stripe_Base_Url__c'+organisationOfCentre.Stripe_Base_Url__c);
        system.debug('@@completePrepayment-centreCountry.Stripe_Secret_Key__c'+organisationOfCentre.Stripe_Secret_Key__c);
        
        if(String.isNotBlank(enrolment.Parent__r.stripe_customer_id__c) && finalAmount > 0 
            && String.isNotBlank(organisationOfCentre.Id)
             && String.isNotBlank(organisationOfCentre.Stripe_Base_Url__c)
              && String.isNotBlank(organisationOfCentre.Stripe_Secret_Key__c)){
                  /**commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                   *  BillingUtility.StripeCharge objStripeCharge = BillingUtility.createChargeForCustomer(
                                enrolment.Parent__r.Stripe_Customer_Id__c,BillingUtility.roundOffAmount(finalAmount) ,centreCountry.Currency_Code__c,
                                 centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);
                                */
            BillingUtility.StripeCharge objStripeCharge = BillingUtility.createChargeForCustomer(
                                enrolment.Parent__r.Stripe_Customer_Id__c,BillingUtility.roundOffAmount(finalAmount) ,organisationOfCentre.country__r.Currency_Code__c, organisationOfCentre.Stripe_Base_Url__c, organisationOfCentre.Stripe_Secret_Key__c);
                                system.debug('@@@completePrepayment- objStripeCharge'+objStripeCharge);
                                if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                                    //System.debug('@@@objStripeCharge'+objStripeCharge);
                                    processPrepay(objStripeCharge.id);
                                }else{
                                    isErrorOnSave = true;
                                    if(objStripeCharge.error != NULL){
                                        errorMessage = objStripeCharge.error.message;
                                        system.debug('@@@completePrepayment- objStripeCharge.error.message'+objStripeCharge.error.message);
                                    }
                                }    
        }else{
            isErrorOnSave = true;
            errorMessage = 'Customer does not have a valid stripe customer id.';
        }
        system.debug('@@@completePrepayment isErrorOnSave '+isErrorOnSave);
        system.debug('@@@ completePrepayment errorMessage '+errorMessage);
        return page;
    }
    
    private void processPrepay(String chargeId){
        updateEnrolment();
        system.debug('@@processPrepay- chargeId'+chargeId);
        system.debug('@@processPrepay- base64SignImg'+base64SignImg);
        insertSignature(base64SignImg, enrolment, prepayPackage.Id);
        Invoice__c inv = insertInvoice(objLineItem);
        system.debug('@@@processPrepay inv'+inv);
        if(!Test.isRunningTest()){
            BillingUtility.updateCharge(chargeId,inv.Name, organisationOfCentre.Stripe_Base_Url__c, organisationOfCentre.Stripe_Secret_Key__c);  	
            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic*/
            //BillingUtility.updateCharge(chargeId,inv.Name, centreCountry.Stripe_Base_Url__c, centreCountry.Stripe_Secret_Key__c);  	  
        }
        
        Payment__c objPay = insertPayment(chargeId,inv.id);
        insertInvoiceLineItems(inv,objLineItem);
        SageIntacctIntegrationUtility.existingCustomerPrepayment(inv.id,objPay.id);
        updateFutureBookings(enrolment.Id, enrolment.Package__c, enrolment.prepayment_period_start_date__c, enrolment.prepayment_period_end_date__c);  
    }
    
    private static Subscription_line_Item__c fetchSubsLineItem(String enrolId){
        List<Subscription_Line_Item__c> lineItems = [SELECT Id,Next_Bill_Date__c,Subscription__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c  FROM Subscription_Line_Item__c WHERE
                                                    Enrolment__c=: enrolId LIMIT 1];
                                                    system.debug('@@@fetchSubsLineItem -lineItems'+lineItems);
                                                    
        if(lineItems.size()>0){
            return lineItems[0];
        }else{
            return null;
        }
    }
    
    private static Subscription_line_item__c  updateNextBillDate(Enrolment__c objEnrol){
        Subscription_line_item__c objLineItem= fetchSubsLineItem(objEnrol.id);
        system.debug('@@@updateNextBillDate - objLineItem'+objLineItem);
        String subscriptionId = objLineItem.Subscription__c;
        objLineItem.Next_Bill_Date__c = objEnrol.Next_Bill_Date__c;
        update objLineItem;
        system.debug('@@@updateNextBillDate - updated  objLineItem' + objLineItem);
        system.debug('@@@updateNextBillDate - subscriptionId' + subscriptionId);
        //Update Subscription next bill date with minimum date of its line item
        if(String.isNotBlank(subscriptionId)){
            Date minDate;
            Subscription__c subsciptionObj = new Subscription__c();
            subsciptionObj.Id = subscriptionId;
            List<AggregateResult> AggregateResultList = [select MIN(Next_Bill_Date__c) mindate from Subscription_line_item__c 
                                                         WHERE Subscription__c =: subscriptionId AND 
                                                         Status__c =: ConstantsClass.activeStatus]; 
            for(AggregateResult aggResult : AggregateResultList){
                subsciptionObj.Next_Bill_Date__c = Date.valueOf(aggResult.get('mindate'));
            }
            system.debug('@@@updateNextBillDate - AggregateResultList' + AggregateResultList);
            system.debug('@@@updateNextBillDate -  subsciptionObj' + subsciptionObj);
            if(String.isNotBlank(subsciptionObj.Id)){
                update subsciptionObj;
            }
            system.debug('@@@updateNextBillDate - updated subsciptionObj' + subsciptionObj);
        }
        return objLineItem;                                            
    }
    
    private Invoice__c insertInvoice(Subscription_Line_Item__c subslineItem){
        system.debug('@@@@ insertInvoice -- '+subslineItem);
        Invoice__c inv = BillingUtility.fillInvoice(subslineItem.Subscription__c, enrolment.Parent__c, ConstantsClass.paidStatus);
        inv.Invoice_Date__c = System.today();
        inv.Due_Date__c = inv.Invoice_Date__c.addDays(ConstantsClass.addInvoiceDueDays);
        inv.Center__c = enrolment.Center__c;
        inv.Invoice_Type__c = ConstantsClass.recurringInvoiceType;
        insert inv;
        system.debug('@@@@ insertInvoice -- insert new invoice'+inv);
        //return inv;
        return [SELECT Id,Subscription__c,Parent_Account__c,Invoice_Date__c,Due_Date__c,Center__c,Name FROM Invoice__c WHERE Id=: inv.id];
    }
    
    private void insertInvoiceLineItems(Invoice__c inv,Subscription_Line_Item__c subLineItem){
        List<Invoice_Line_Item__c> invLineItems = new List<Invoice_Line_Item__c>();
        system.debug('@@@insertInvoiceLineItems inv'+inv);
        system.debug('@@@insertInvoiceLineItems subLineItem'+subLineItem);
        system.debug('@@@insertInvoiceLineItems prepayPackage'+prepayPackage.Package_Fee__c);
        system.debug('@@@insertInvoiceLineItems Promotion_Discount__c'+prepayPackage.Promotion_Discount__c);
        if(prepayPackage.Package_Fee__c != NULL && prepayPackage.Promotion_Discount__c != NULL){
            Decimal amount = prepayPackage.Package_Fee__c / noOfMonths;
            //Decimal facilityFee = prepayPackage.facility_Fee__c / noOfMonths;
            Decimal taxRate = subLineItem.Enrolment__r.Center__r.Country__r.Tax_Rate__c; 
            system.debug('@@@insertInvoiceLineItems amount'+amount);
            Decimal discount = prepayPackage.Promotion_Discount__c / noOfMonths;
            system.debug('@@@insertInvoiceLineItems discount'+amount);
            system.debug('@@@insertInvoiceLineItems noOfMonths'+noOfMonths);
            for(Integer i=0;i<noOfMonths; i++){
                Invoice_Line_Item__c invLineItem = BillingUtility.fillInvLnItm(inv.id, enrolment.id, subLineItem.id, BillingUtility.roundOffAmount(amount),'',Enrolment.Teacher__c);
                invLineItem.Discount_Amount__c = BillingUtility.roundOffAmount(discount);
                invLineItem.Month__c = firstDate.addMonths(i);
                // if(gstAmount != NULL && gstAmount > 0){
                //     invLineItem.Gst_Amount__c = BillingUtility.roundOffAmount(gstAmount/noOfMonths);
                // }else{
                //     invLineItem.Gst_Amount__c = 0;
                // }
                if(taxRate != NULL && taxRate > 0){
                    invLineItem.Gst_Amount__c = BillingUtility.roundOffAmount(((amount-discount)*taxRate) /100);
                }else{
                    invLineItem.Gst_Amount__c = 0;
                }
                invLineItem.Package__c = prepayPackage.id;
                system.debug('@@@insertInvoiceLineItems invLineItem'+invLineItem);
                invLineItems.add(invLineItem);
                //added by nishi:27-aug-2020:if ossia organisation and Facility fee is exist  so we added  Facility fees
               /* if(String.isNotBlank(prepayPackage.Location__c) && String.isNotBlank(prepayPackage.Location__r.Organisation__c) &&
                    String.isNotBlank(prepayPackage.Location__r.Organisation__r.Name) && 
                    prepayPackage.Location__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name) 
                    && prepayPackage.facility_Fee__c != null){
                    invLineItem = BillingUtility.fillInvLnItm(inv.id, enrolment.id, subLineItem.id, BillingUtility.roundOffAmount(facilityFee),prepayPackage.name+ ' (Facility Fees)',Enrolment.Teacher__c);
                    invLineItem.Month__c = firstDate.addMonths(i);
                    if(taxRate != NULL && taxRate > 0){
                        invLineItem.Gst_Amount__c = BillingUtility.roundOffAmount((facilityFee*taxRate) /100);
                    }else{
                        invLineItem.Gst_Amount__c = 0;
                    }
                    invLineItem.Package__c = prepayPackage.id;
                    system.debug('@@@insertInvoiceLineItems invLineItem'+invLineItem);
                    invLineItems.add(invLineItem);
                }*/
                //added by nishi:27-aug-2020:if ossia organisation and Facility fee is exist  so we added  Facility fees
            }
            system.debug('@@@insertInvoiceLineItems all  invLineItems'+invLineItems);
            insert invLineItems;
            if(String.isNotBlank(inv.Id)){
                createInvoiceAttachment(inv.Id);                   
            }
            
        }
    }
    
    private Payment__c insertPayment(String chargeId,String invId){
        system.debug('@@@insertPayment  -chargeId'+chargeId);
        system.debug('@@@insertPayment  -invId'+invId);
        String paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        
        Payment__c objPayment = BillingUtility.fillPayment(enrolment.Parent__c,invId, finalAmount,ConstantsClass.successStatus);
        objPayment.recordTypeId = paymentRecType; 
        objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
        objPayment.Transaction_ID__c = chargeId;    
        insert objPayment;
        system.debug('@@@insertPayment  -inserted Payment'+objPayment);
        return objPayment;
    }
    
    private void updateEnrolment(){
        
        enrolment.Package_To_Be_Change__c = enrolment.Package__c;
        enrolment.Package__c = prepayPackage.Id;
        enrolment.prepayment_period_start_date__c = firstDate;
        enrolment.prepayment_period_end_date__c = lastDate;
        enrolment.Prepayment_Request_Date__c = System.today();
        enrolment.Promotional_Period_End_Date__c = lastDate;
        update enrolment;
        system.debug('@@@updateEnrolment - updated enrolment -- '+enrolment);
    }
    
    public static void insertSignature(String base64SignImgStr, Enrolment__c objEnrol, String prePackage){
        DateTime now = DateTime.now();
        if(base64SignImgStr!=null && base64SignImgStr.trim().length()>0 ){
            base64SignImgStr = base64SignImgStr.replace('data:image/png;base64,','');
            Attachment att = new Attachment();
            att.Name     = objEnrol.name+'- Prepayment- '+now.format('dd/MM/yyyy')+'.png';
            att.parentId =  objEnrol.Parent__c;
            att.body     = EncodingUtil.base64Decode(base64SignImgStr);
            insert att;
            system.debug('@@@insertSignature - insert Attachment'+ att);
        }
        
        insertPdfAndSendEmail(objEnrol.id,prepackage);
    }
    public PageReference newAttachInsert(){
        Enrolment__c enrolObj = [SELECT Id, Parent__r.personContactId, Center__r.Location__c FROM Enrolment__c WHERE Id =:enrolId];
        Attachment attach = new Attachment();
        Blob body = Blob.valueOf('Some Text');
        try {
            PageReference pdf = new PageReference('/apex/PrePaySummarypdf?enrolId='+enrolObj.Id+'&packageId='+packageId);
            body =  pdf.getContent();
        }catch (Exception e) {
          body = Blob.valueOf('Some Text');
        }
        attach.Body = body;
        attach.Name = 'PrepaymentSummary.pdf';
        attach.ParentId =  enrolObj.Parent__c;
        system.debug('@@@newAttachInsert - attach'+attach);
        return new PageReference('/apex/thankyoupage');
}
    
    @future(callout=true)
    public static void insertPdfAndSendEmail(String enrolmentId, String packageId){
        system.debug('@@@insertPdfAndSendEmail - enrolmentId'+enrolmentId);
        system.debug('@@@insertPdfAndSendEmail - packageId'+packageId);
        DateTime now = DateTime.now();
        Enrolment__c enrolObj = [SELECT Id, Name,Parent__r.personContactId, Center__r.Location__c,next_bill_Date__c FROM Enrolment__c WHERE Id =:enrolmentId];
        String pdfName = enrolObj.name+'- Prepayment Summary- '+now.format('dd/MM/yyyy')+'.pdf';
        Attachment attach = new Attachment();
        Blob body = Blob.valueOf('Some Text');
        try {
            String siteUrl = System.Label.Aureus_Site;
            PageReference pdf = new PageReference(siteUrl+'/apex/PrePaySummarypdf?enrolId='+enrolObj.Id+'&packageId='+packageId);
            body =  pdf.getContentAsPdf();
        } catch (Exception e) {
            body = Blob.valueOf('Some Text');
        }
        attach.Body = body;
        attach.Name = pdfName;
        attach.ParentId = enrolObj.Parent__c;
        insert attach;
        system.debug('@@@insertPdfAndSendEmail -  attach :' +attach);
        sendEmail(body, enrolObj,pdfName);
    }
    
    @future(callout=true)
    private static void createInvoiceAttachment(String invoiceId){
        system.debug('@@@createInvoiceAttachment -invoiceId'+invoiceId);
        if(String.isNotBlank(invoiceId)){
            Invoice__c invoiceObj = [SELECT Id, Name, Parent_Account__c FROM Invoice__c WHERE Id =:invoiceId LIMIT 1];
            String pdfName = invoiceObj.name+'.pdf';
            Attachment attach = new Attachment();
            Blob body = Blob.valueOf('Some Text');
            try {
                String siteUrl = System.Label.Aureus_Site;
                PageReference pdf = new PageReference(siteUrl+'/apex/SubscriptionInvoicePdfClone?id='+invoiceObj.Id);
                body =  pdf.getContentAsPdf();
            } catch (Exception e) {
                body = Blob.valueOf('Some Text');
            }
            attach.Body = body;
            attach.Name = pdfName;
            attach.ParentId = invoiceObj.Id;
            insert attach;
            system.debug('@@@createInvoiceAttachment -attach'+attach);
        }
    }        
    
    
    private static void sendEmail(Blob body, Enrolment__c enrolment,String pdfName){
        system.debug('@@sendEmail - body'+body);
        system.debug('@@sendEmail - enrolment'+enrolment);
        system.debug('@@sendEmail - pdfName'+pdfName);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>(); 
        for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
            mapOfOrgWide.put(objAddress.DisplayName,objAddress);
        }
        system.debug('@@sendEmail - mapOfOrgWide'+mapOfOrgWide);
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Developername ='Prepayment_Summary' LIMIT 1];
        system.debug('@@sendEmail - template'+template);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(enrolment.Parent__r.personContactId);
        mail.setWhatId(enrolment.Id);
        mail.setTemplateId(template.id);
        mail.saveAsActivity = true;
        String location = enrolment.Center__r.Location__c;
        system.debug('@@sendEmail - location'+location);
        if(String.isNotBlank(location) && mapOfOrgWide.containsKey(location)){
             mail.setOrgWideEmailAddressId(mapOfOrgWide.get(location).Id);
        }
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
        efa.setFileName(pdfName);
        efa.setBody(body);
        fileAttachments.add(efa);
        system.debug('@@@@sendEmail  - Emailfileattachment - '+efa);
        mail.setFileAttachments(fileAttachments);
        system.debug('@@@@sendEmail  - SingleEmailMessage - '+mail);
        emailList.add(mail);
        Messaging.sendEmail(emailList);
        system.debug('@@@@sendEmail  - SingleEmailMessageList - '+emailList);
        updateNextBillDate(enrolment);
    }
    
    private Enrolment__c fetchEnrol(String enrolId){
        Enrolment__c enrolment = new Enrolment__c();
        List<Enrolment__c> enrolmentList = [SELECT Id,Name,Center__c,Center__r.Location__c,Student__c,Student__r.lastName,Student__r.Name,
                                            Center__r.Name,Teacher__c,Parent__r.Stripe_customer_id__c,Parent__r.Card_Image__c, 
                                            Parent__r.Card_Number__c,Parent__r.personContactId,Package__c,Parent__r.personEmail,Parent__r.Name,
                                            Parent__r.PersonMobilePhone,prepayment_period_start_date__c,prepayment_period_end_date__c,
                                            Package__r.type_of_package__c, Link_Creation_Date__c, 
                                            Center__r.Country__r.Id, Center__r.Country__r.Tax_Rate__c, 
                                            Center__r.Country__r.Stripe_Base_Url__c, Center__r.Country__r.Stripe_Secret_Key__c,	Center__r.Country__r.Currency_Code__c ,
                                            // added by nishi: 26-Aug-2020: for manage Stripe Details
                                            Center__r.Organisation__r.Id, Center__r.Organisation__r.Tax_Rate__c, Center__r.Organisation__r.Name,
                                            Center__r.Organisation__r.Stripe_Base_Url__c, Center__r.Organisation__r.Stripe_Secret_Key__c,	Center__r.Organisation__r.Country__r.Currency_Code__c 
                                            // added by nishi: 26-Aug-2020: for manage Stripe Details
                                            FROM Enrolment__c WHERE id=: enrolId];
        //Parent__r.personEmail,Parent__r.Name,
        if(enrolmentList.size() > 0){
            enrolment = enrolmentList[0];
        }
        system.debug('@@@fetchEnrol enrolment :'+enrolment);
        return enrolment;
    }
    
    private String fetchAttachment(Enrolment__c enrolment){
        String attachId = '';
        Datetime now = Datetime.now();
        String attachName =  enrolment.name+'- Prepayment- '+now.format('dd/MM/yyyy')+'.png';
        system.debug('@@@fetchAttachment enrolment.Parent__c'+enrolment.Parent__c);
        system.debug('@@@fetchAttachment attachName'+attachName);
        List<Attachment> listOfAttach = [SELECT Id FROM Attachment WHERE ParentId =:enrolment.Parent__c AND Name =:attachName];
        system.debug('@@@fetchAttachment listOfAttach'+listOfAttach);
        if(listOfAttach.size() > 0){
            attachId = listOfAttach[0].id;
        }
        return attachId;
    }
    
    private Package__c fetchPackage(String packageId){
        system.debug('@@fetchPackage --packageId : '+packageId);
        Package__c prepayPackage = new Package__c();
        List<Package__c> listOfPackage = [SELECT Id,Name,Promotion_period_In_months__c,package_fee__c,Promotion_Discount__c,Offer_End_Date__c,
                                          Active__c,Location__r.Organisation__r.Name
                                          //facility_Fee__c
                                          FROM Package__c WHERE Id=: packageId];
        if(listOfPackage.size() > 0){
            prepayPackage = listOfPackage[0];
        }
        system.debug('@@fetchPackage --prepayPackage : '+prepayPackage);
        return prepayPackage;
    }
    
    
    private List<BillingSummary> fillBillSummary(Package__c objPack,Date firstDate,Integer noOfMonth){
        List<BillingSummary> listOfBillSummary = new List<BillingSummary>();
        system.debug('@@ fillBillSummary - objPack'+objPack );
        system.debug('@@fillBillSummary - noOfMonth '+noOfMonth );
        system.debug('@@fillBillSummary - firstDate '+firstDate );
        if(objPack.Package_Fee__c != NULL){
            Decimal amount =  0;
            //Decimal facilityamount =  0;
            Decimal discount = 0;
            if(objPack.Package_Fee__c != NULL && noOfMonth != NUll)
                amount = BillingUtility.roundOffAmount(objPack.Package_Fee__c /noOfMonth);
                // if(String.isNotBlank(objPack.Location__c) && String.isNotBlank(objPack.Location__r.Organisation__c) &&
                //  String.isNotBlank(objPack.Location__r.Organisation__r.Name) && 
                //  objPack.Location__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name) 
                //  && objPack.facility_Fee__c != null){
                //     facilityamount += BillingUtility.roundOffAmount(objPack.facility_Fee__c /noOfMonth);
                // }   
            if(objPack.Promotion_Discount__c != NULL && noOfMonth != NUll)
                discount = BillingUtility.roundOffAmount(objPack.Promotion_Discount__c / noOfMonth);
            system.debug('@@@fillBillSummaryamount'+amount);
            system.debug('@@@fillBillSummary discount'+discount);
            for(Integer i=0;i<noOfMonth; i++){
                listOfBillSummary.add(new BillingSummary(firstDate.addMonths(i),amount,/*facilityamount,*/objPack.Name,discount));               
            }
        }
        system.debug('@@@fillBillSummary listOfBillSummary'+listOfBillSummary);
        return listOfBillSummary;
    }
    
    private void updateFutureBookings(String enrolmentId, String packageId, Date periodStartDate, Date periodEndDate){
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessonList = new List<Fifth_Lesson__c>();
        system.debug('@@@updateFutureBookings enrolmentId'+enrolmentId);
        system.debug('@@@updateFutureBookings packageId'+packageId);
        system.debug('@@@updateFutureBookings periodStartDate'+periodStartDate);
        system.debug('@@@updateFutureBookings periodEndDate'+periodEndDate);
        if(String.isNotBlank(enrolmentId) && String.isNotBlank(packageId) && periodStartDate != NULL && periodEndDate != NULL){
            for(Booking__c bookObj : [SELECT Id, Package__c FROM Booking__c WHERE Enrolment__c =: enrolmentId 
                                      AND Type__c =: ConstantsClass.typeRegular AND Booking_Date__c >= :periodStartDate AND Booking_Date__c <= :periodEndDate]){
                bookObj.Package__c = packageId;
                bookingList.add(bookObj);
            }
            system.debug('@@@updateFutureBookings bookingList'+bookingList);
            for(Fifth_Lesson__c lessonObj : [SELECT Id, Package__c FROM Fifth_Lesson__c WHERE Enrolment__c =: enrolmentId 
                                      AND Booking_Date__c >= :periodStartDate AND Booking_Date__c <= :periodEndDate]){
                 lessonObj.Package__c = packageId;
                 fifthLessonList.add(lessonObj);
            }
            system.debug('@@@updateFutureBookings fifthLessonList'+fifthLessonList);
            if(fifthLessonList.size() > 0){
                UPDATE fifthLessonList;
            }
            if(bookingList.size() > 0){
                UPDATE bookingList;
            }
            system.debug('@@@updateFutureBookings updated bookingList'+bookingList);
            system.debug('@@@updateFutureBookings updated fifthLessonList'+fifthLessonList);
        }
    }
    
    private boolean checkLinkExpiry(Enrolment__c objEnrol, Package__c objPackage, Date nextBillDate){
    	Boolean isExpired = false;
        Date currentDate = System.today();
        Integer months = Integer.valueOf(Label.Prepayment_Expiry);
        Date maxDate = currentDate.addMonths(months); 
        isExpired = objPackage.Active__c  ? false : true;
        system.debug('@@@checkLink- ExpiryisExpired'+isExpired);
        if(!isExpired){
            system.debug('@@@checkLink- objEnrol.package__r.type_of_package__c'+objEnrol.package__r.type_of_package__c);
            system.debug('@@@checkLink- nextBillDate'+nextBillDate);
            system.debug('@@@checkLink- maxDate'+maxDate);
            system.debug('@@@checkLink- nextBillDate >= maxDate'+(nextBillDate >= maxDate));
        	isExpired = objEnrol.package__r.type_of_package__c == 'Prepayment' || nextBillDate >= maxDate ? true : false;
        }
        system.debug('@@@checkLink- objEnrol.Link_Creation_Date__c'+objEnrol.Link_Creation_Date__c);
        if(!isExpired && objEnrol.Link_Creation_Date__c != NULL){
            system.debug('@@@checkLink- Label.Link_Expiry_Duration'+Label.Link_Expiry_Duration);
            isExpired = getTimeDiff(objEnrol.Link_Creation_Date__c) > Double.valueOf(Label.Link_Expiry_Duration) ? true : false;
        }
        system.debug('@@@checkLink- isExpired'+isExpired);
        return isExpired;
    }
    public class BillingSummary{
        Public Date invoiceDate{get;set;}
        public Decimal amount{get;set;}
        public Decimal totalAmount{get;set;}
        //public Decimal faclityFee{get;set;}
        public String packageName{get;set;}
        Public Decimal discount{get;set;}
        public Decimal netAmount{get;set;}
        public BillingSummary(Date invDate,Decimal amount,/*Decimal faclityFee,*/String packageName,Decimal discount){
            this.invoiceDate = invDate;
            //this.faclityFee = faclityFee; //added by nishi jain: 27_aug-2020: for manage Facility Fee
            this.amount = amount;
            this.packageName = packageName;
            this.discount = discount;
            this.totalAmount = amount;//+ (faclityFee > 0 ?faclityFee :0);
            this.netAmount = ((amount - discount) /*+ (faclityFee > 0 ?faclityFee :0)*/ ).setScale(2);
        }
    }
    
    private static Double getTimeDiff(DateTime linkDateTime){
        Long pastMilli = linkDateTime.getTime();
        Long current = DateTime.now().getTime();
        Double difference = (((current - pastMilli) / 1000) / 60) / 60;
        system.debug('@@@getTimeDiff - difference: '+difference);
        return difference;
    } 
}