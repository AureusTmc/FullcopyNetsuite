/**
* @File Name : PianoRentalPurchasePageV2Controller.cls
* @Vf Page : PianoRentalPurchasePageV2.vfp
* @Test Class Name : - PianoRentalPurchasePageV2ControllerTest
* @Description : This page is modified version of the page PianoRentalPurchasePage for the netsuite integeration.
* @Author : TMC
* @Last Modified By : Karan Singh Soni 
* @Last Modified On : 3 Sep 2020
* @Modification Log : Inital version
*==============================================================================
* Ver Date Author Modification
*==============================================================================
* 1.0 31 Aug 2020 Karan Singh Soni ( Inital version )
**/
//CH01 13 Oct 2020 : In case if the Enrolment Cneter Name is "Aureus HQ" , then it will use the "Aureus Admin" OWA.
// CH02 17-Nov 2020: Nishi: to create a credit memo for 4 months rental return and deposit return. This should be created as Success and should not be sent to Netsuite.
public class PianoRentalPurchasePageV2Controller {
    
    Public Enrolment__c enrolment{get;set;}
    Public string  errorMessage{get;set;} 
    Public Boolean isErrorOnSave {get;set;}
    public Boolean isAlreadySold {get;set;}
    public List<BillingSummary> listOfSummary{get;set;}
    public Decimal amountAfterDiscount{get;set;}
    Public Decimal totalRentalDepositAmount{get;set;}
    public Boolean isEmailSent {get;set;}
    public String posUserName {get;set;}
    
    //_________________________________________________________  Constructor  ________________________________________________________________________________
    public PianoRentalPurchasePageV2Controller(ApexPages.StandardController st) {
        
        enrolment = (Enrolment__c)st.getRecord();
        errorMessage = '';
        isErrorOnSave = false;
        amountAfterDiscount = 0;
        totalRentalDepositAmount = 0;
        isEmailSent = false;
        posUserName ='';
        
        if(string.isNotBlank(enrolment.Id)){
            List<Enrolment__c> listOfenrolment  = getRentalEnrolmentList(new Set<string> {enrolment.Id});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                enrolment = listOfenrolment[0];
            }
        }
        if( String.isNotBlank( enrolment.Teacher__r.name ))
            posUserName = enrolment.Teacher__r.name;
        
        if(enrolment.Stage__c != ConstantsClass.enrollmentPianoSoldStage){
            isAlreadySold = false;
            listOfSummary = fillBillSummary(enrolment);
            for(BillingSummary summary : listOfSummary){
                amountAfterDiscount += summary.amount;
            }
            
            if(amountAfterDiscount > 0){
                amountAfterDiscount = (amountAfterDiscount != NULL) ? BillingUtility.roundOffAmount(amountAfterDiscount): 0;
            }
            
            Map<string,Decimal> mapOfTotalRentalDepositAmount  = PianoRentalHelperController.getTotalRentalDepositAmount(new Set<String>{enrolment.id});
            if(mapOfTotalRentalDepositAmount != null && mapOfTotalRentalDepositAmount.size() > 0 && mapOfTotalRentalDepositAmount.containsKey(enrolment.id)){
                if(mapOfTotalRentalDepositAmount.get(enrolment.id) !=  null && mapOfTotalRentalDepositAmount.get(enrolment.id) > 0)  
                    totalRentalDepositAmount =-(mapOfTotalRentalDepositAmount.get(enrolment.id));
            }
        }else{
            isAlreadySold = true;
        }
    }//end of Constructors 
    
    //_____________________________________________________________________________  fetch the current enrolment record ___________________________________________________________________________
    public static List<Enrolment__c> getRentalEnrolmentList(Set<String> enrolmentIds){
        return [SELECT Id,Teacher__r.name,Teacher__r.Personal_Email__c,Rental_Termination_Date__c,Product_Id__c,Brand__c ,Name, center__r.country__r.Tax_Rate__c,
                center__r.country__r.Stripe_Base_Url__c,Extra_Stairs__c,Actual_Delivery_Date_Time__c,Aggrement_Id__c,
                Package__c,teacher__c,center__c,Stage__c,Parent__r.PersonContactId,Center__r.Location__c,
                Termination_Reason__c,Termination_Reason_others__c,Termination_request_date__c,Piano_Pickup_date__c,
                center__r.country__r.Currency_Code__c,center__r.country__r.Stripe_Secret_Key__c,Teacher__r.OwnerId,
                Parent__c, Parent__r.Name, effective_Date__c, Rental_price_per_month__c,Stair_Charges__c,
                Final_Delivery_date__c,Rental_Start_date__c,Rental_End_date__c,Minimum_Rental_Commitment_Period__c,
                Student__r.Name, Package__r.Name, Package__r.Deposit_Fee__c, Package__r.Unit_Fee__c,
                House_type__c,Building_name__c,Block__c,Unit_and_Level__c,PIN_code__c,Serial_Number__c,Model__c,Standard_Accessories__c,
                Center__r.Name, Lessons_Start_Date__c, Lesson_Start_time__c, Notice_Period_End_Date__c,  
                Center__r.country__r.Id, No_of_Stairs__c,Termination_Inspection_Completed__c,Parent__r.Card_Image__c,Parent__r.Card_Number__c,
                Selling_price__c,Delivery_Charges__c,Parent__r.PersonMobilePhone,Parent__r.PersonEmail,
                Final_Delivery_Timeslot__c,Parent__r.FirstName, Parent__r.LastName,Parent__r.BillingStreet,
                Parent__r.BillingCity, Parent__r.BillingCountry,Parent__r.Phone,Parent__r.id,Parent_Email__c,Related_Lesson_Enrolment__c,
                (SELECT Id,Subscription__c,Status__c,Subscription__r.Next_Bill_Date__c,Subscription__r.Subscription_Start_Date__c,Subscription__r.Parent__c,Subscription__r.Center__c,
                 Subscription_Expiry_Date__c,Subscription__r.Parent__r.Stripe_Customer_Id__c, Amount__c,Next_Bill_Date__c,Subscription_Start_Date__c,Subscription__r.Subscription_End_Date__c
                 FROM Subscription_Line_Items__r 
                 WHERE Subscription__c != NULL) 
                FROM Enrolment__c 
                WHERE Id =: enrolmentIds];
    }
    
    
    
    /* fill invoice billing summary for customer confirmation
a.	Original piano price (excluding promotion, if any)
b.	Apply the following deductions()
i.	 Maximum 4 month rent paid(credit)
ii.	 Apply Rental Deposit (as applicable)(payment as deposit)
iii. Apply 1 way paid delivery charges (as applicable)(balance Credit)

Note : 3 Sep 2020 This method was taken from another class -> PianoRentalPurchaseController and modified as per need.
*/
    private List<BillingSummary> fillBillSummary(Enrolment__c objEnrolment){
        List<BillingSummary> listOfBillSummary = new List<BillingSummary>();
        //SELECT Id,Name,parent__r.NAme, ( SELECT Id FROM Invoice_Line_Items__r )  FROM Enrolment__c WHERE RecordType.Name ='Instrument Rental'
        Map<String,List<Invoice__c>> mapOfEnrolmentInvoice = PianoRentalHelperController.get4MonthPaidInvoiceAmountWithDate(new Set<String>{objEnrolment.id});
        
        Map<string,Decimal> mapOfTotalcurrentMonthPaidInvoiceAmount =PianoRentalHelperController.getCurrentMonthInvoiceAmount(new Set<String>{objEnrolment.id},ConstantsClass.paidStatus);
        Map<string,Decimal> mapOfTotalRentalDepositAmount  = PianoRentalHelperController.getTotalRentalDepositAmount(new Set<String>{objEnrolment.id});
        
        //If Existing Aureus student then inbound delivery charges and stair case charges will not be applied in credit memo. This is because for Aureus students these are charged at the time of rental termination.
        if(string.isBlank(objEnrolment.Related_Lesson_Enrolment__c)){
            //deduct Delievery  charges
            if(objEnrolment.Delivery_Charges__c != null && objEnrolment.Delivery_Charges__c >0){
                listOfBillSummary.add(new BillingSummary(-(objEnrolment.Delivery_Charges__c/2),'Deduct (One Way) Delivery Charges'));
            }
            //deduct stairs charges
            if(objEnrolment.Stair_Charges__c != null && objEnrolment.Stair_Charges__c >0){
                listOfBillSummary.add(new BillingSummary(-(objEnrolment.Stair_Charges__c/2),'Deduct (One Way) Stair Charges'));
            }
        }
        
        //show paid invoice summary last 4 month with due date and amount
        if(mapOfEnrolmentInvoice != null && mapOfEnrolmentInvoice.size() > 0){
            List<Invoice__c> listofInvoice = mapOfEnrolmentInvoice.get(objEnrolment.id);
            for(Invoice__c objInvoice : listofInvoice){
                datetime dueDate = datetime.newInstance(objInvoice.Due_Date__c, Time.newInstance(0,0,0,0));
                listOfBillSummary.add(new BillingSummary(-(objInvoice.Sub_Total__c),'Deduct Paid Rent - '+ dueDate.format('dd MMM, yyyy'))); 
            }
        }
        
        //show current month paid Invoice amount
        if(mapOfTotalcurrentMonthPaidInvoiceAmount != null && mapOfTotalcurrentMonthPaidInvoiceAmount.size() > 0 && mapOfTotalcurrentMonthPaidInvoiceAmount.containsKey(objEnrolment.id)){
            if(mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id) !=  null && mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id) > 0) 
                listOfBillSummary.add(new BillingSummary(-(mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id)),'Deduct Current Month Rental')); 
        }
        
        return listOfBillSummary;
    }
    
    //This will send the email message to the POS team -> enrolment's teachers email and update enrolment and subscriptions.
    public void sendEmailToPOS(){
        
        Messaging.SendEmailResult[] sendEmailResults;
        list< Subscription__c > listSubscriptions = new list< Subscription__c >();
        set< Id > setSubsIds = new set< Id >();
        Savepoint sp = Database.setSavepoint();
        
        try{
            if( String.isNotBlank( enrolment.Center__r.Name ) && String.isNotBlank( enrolment.Teacher__r.Personal_Email__c ) ){
                
                List< OrgWideEmailAddress > listOWA = [ SELECT Id, Address, DisplayName 
                                                       FROM OrgWideEmailAddress 
                                                       WHERE displayName =: enrolment.Center__r.Name LIMIT 1 ];
                
                List< EmailTemplate > listEmailTemplate = [ SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                                           FROM EmailTemplate 
                                                           WHERE DeveloperName = 'Piano_Rental_to_Purchase_Process' LIMIT 1 ];                
                
                //CH01
                if(listOWA.size() == 0  && enrolment.Center__r.Name == 'Aureus HQ' ){
                    
                    listOWA = [SELECT Id, Address, DisplayName 
                               FROM OrgWideEmailAddress 
                               WHERE displayName = 'Aureus Admin' LIMIT 1 ];
                }
                //CH01 END
                
                if( listOWA.size() > 0  && listEmailTemplate.size() > 0 ){
                    
                    //https://hub.appirio.com/cloud-powered-blog/simplify-sending-email-to-non-contacts-with-renderstoredemailtemplate
                    Messaging.SingleEmailMessage objOutGoingEmail =  Messaging.renderStoredEmailTemplate(listEmailTemplate[0].Id, null, enrolment.Id);
                    objOutGoingEmail.setToAddresses(new list< String >{enrolment.Teacher__r.Personal_Email__c});
                    objOutGoingEmail.setSubject('Process-to-rental');
                    objOutGoingEmail.setOrgWideEmailAddressId( listOWA[0].Id );
                    
                    /*10 SEP 2020 Karan : will use the email template instead
* string emailHtmlBody = 'Dear Karan <br/>' ;
emailHtmlBody += 'Customer ' + enrolment.Parent__r.Name + '  has opted for the Rent-to-purchase option for their ongoing piano rental subscription. <br/>';
emailHtmlBody += 'Please see the credit statement that needs to be applied at the time of purchase. <br/>';
objOutGoingEmail.setHtmlBody(emailHtmlBody); */
                    
                    //3 Sep 2020 Karan: will use OWA instead  objOutGoingEmail.setTargetObjectId( UserInfo.getUserId()); //need to to this as as validation rule written on Email message ->Check_if_From_Email_is_same_as_User
                    //3 Sep 2020 Karan: will use OWA instead  objOutGoingEmail.saveAsActivity = false;					//need to to this as as validation rule written on Email message ->Check_if_From_Email_is_same_as_User
                    
                    //_________________________________________________________________  Attaching pdf to the email  ________________________________________________-
                    Messaging.EmailFileAttachment objEmailAttchmt = new Messaging.EmailFileAttachment();
                    objEmailAttchmt.setFileName('Reciept.pdf');
                    
                    If(!Test.isRunningTest()){ //28 Sep 2020 Methods defined as TestMethod do not support getContent 
                        objEmailAttchmt.setBody(new PageReference('/apex/PianoRentalPurchasePageV2?Id=' + enrolment.Id).getContentAsPDF());     
                    }
                    objOutGoingEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {objEmailAttchmt});
                    
                    if(!Test.isRunningTest()){
                        
                        sendEmailResults =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] {objOutGoingEmail});
                        
                    }
                }else{ //__________________________________________________  incase if any enrolment's centre doesnot have any address in OWA or Email Template not found
                    
                    isErrorOnSave = true;
                    errorMessage='We have encountered a problem while sending the email : Current enrolment Center does not have valid email address associated with it or Email Template is not defined.Please check with System Admin for this.'; 
                }
            }else{  //_______________________________________________  incase if any enrolment doesnot have any center assiociated to it as we need this for fetch center email address from OWA
                
                isErrorOnSave = true;
                errorMessage='We have encountered a problem while sending the email : Current enrolment is not associated to any centre or Teacher email is not populated.Please check with System Admin for this.'; 
            }
            if( sendEmailResults != Null && sendEmailResults.size() > 0){
                system.debug('sendEmailResults -->  ' + sendEmailResults[0].isSuccess() );
            } 
            
             system.debug('sendEmailResults --> ' + sendEmailResults);
            //only work if successfule email is send
            if( Test.isRunningTest() || ( sendEmailResults != Null && sendEmailResults.size() > 0 && sendEmailResults[0].isSuccess() )){
                
                enrolment.Stage__c = ConstantsClass.enrollmentPianoSoldStage; 
                enrolment.Rental_Termination_Date__c = Date.today();
                update enrolment; 
                
                // CH02 17-Nov 2020: Nishi: to create a credit memo for 4 months rental return and deposit return. This should be created as Success and should not be sent to Netsuite.
                createCreditMemoForPianoRentalPurchase(enrolment.id);

                //currently marking the enrolement subs line item ( it will be only one ) to inactive.
                if( enrolment.Subscription_Line_Items__r != null & enrolment.Subscription_Line_Items__r.size() > 0  ){
                    
                    for( Subscription_Line_Item__c objSubsLine : enrolment.Subscription_Line_Items__r ){
                        
                        objSubsLine.Subscription_Expiry_Date__c = Date.today();
                        objSubsLine.Next_Bill_Date__c = null;
                        objSubsLine.Status__c = 'In Active';
                        
                        setSubsIds.add( objSubsLine.Subscription__c );
                    }//end of for loop
                    
                    update enrolment.Subscription_Line_Items__r;
                    
                    //incase if the subscription linked with above subs line item, does not have any other active line item, will also mark it as inactive etc
                    if( setSubsIds.size() > 0 ){
                        
                        for( Subscription__c objSub : [ SELECT Id,Status__c,Next_Bill_Date__c,Subscription_End_Date__c,
                                                       ( SELECT ID FROM Subscription_Line_Items__r WHERE Status__c = 'Active' LIMIT 1 ) 
                                                       FROM Subscription__c  
                                                       WHERE ID IN : setSubsIds ] ){
                                                           
                                                           system.debug(' objSub --> ' + objSub );
                                                           
                                                           if( objSub.Subscription_Line_Items__r != null && objSub.Subscription_Line_Items__r.size() == 0 ){
                                                               
                                                               objSub.Status__c = 'In Active';
                                                               objSub.Next_Bill_Date__c = null;
                                                               objSub.Subscription_End_Date__c = Date.today();
                                                               listSubscriptions.add( objSub );
                                                           }
                                                       }
                        
                        if( listSubscriptions.size() > 0 ){
                            system.debug(' listSubscriptions --> ' + listSubscriptions );
                            update listSubscriptions;
                        }
                    }//end of update subscription
                }//end of update subscription line items
                
            }else{ //_______________________________________________________ Incase email sent was not successfull
                
                isErrorOnSave = true;
                errorMessage='We have encountered a problem while sending the email as it was unsuccessful.Please check with System Admin for this.';
            }
            
        }catch( Exception objExp ){
            Database.rollback( sp );
            isErrorOnSave = true;
            system.debug(' ---> '+ objExp.getMessage() + '  ---> ' + objExp.getLineNumber());
            errorMessage='We have encountered a problem while sending the email : ' + objExp.getMessage() + ' Line Number : '+ objExp.getLineNumber() + '.Please check with System Admin for this.' ;
        }finally{
            isEmailSent = true;
        }
    } 

     // CH02 17-Nov 2020: Nishi: to create a credit memo for 4 months rental return and deposit return. This should be created as Success and should not be sent to Netsuite.
    public void createCreditMemoForPianoRentalPurchase(string enrolmentid){
        Credit_Memo__c  objCreditMemo = new     Credit_Memo__c();
        map<string,Credit_Memo__c> newPendingCreditMemos = new map<string,Credit_Memo__c>();
        map<string,List<Credit_memo_line_item__c>> mapOfCreditmemolineitem = new map<string,List<Credit_memo_line_item__c>>();
        //Credit_memo_line_item__c objCreditLineItem = new  Credit_memo_line_item__c();    
        map<String,Invoice_Line_Item__c> updateInvoiceLineItem = new map<String,Invoice_Line_Item__c>();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();
        List<Enrolment__c> listOfenrolment  = getRentalEnrolmentList(new Set<string> {enrolmentid});
        if(listOfenrolment != null && listOfenrolment.size() > 0){
            Enrolment__c  objEnrolment = listOfenrolment[0];
            Map<String,List<Invoice_Line_Item__c>> mapOfInvoiceLineItems = get4MonthPaidInvoiceAmountWithDate(new Set<String>{objEnrolment.id});
            Map<String,List<Invoice_Line_Item__c>> mapOfStairCaseandDeliveryChargesInvoice = getStairCaseandDeliveryChargesinvoice(new Set<String>{objEnrolment.id});
            objCreditMemo = BillingUtility.createCreditMemoRec(objEnrolment.Parent__c,objEnrolment.center__c, null,  system.today(),'Rent to purchase executed via POS Zoku.');
            objCreditMemo.Status__c = ConstantsClass.creditMemoSuccessStatus;
            objCreditMemo.Dont_send_to_Netsuite__c = true;
            listOfCreditmemolineitem = new List<Credit_memo_line_item__c>();

            // create credit memo for Deposit Line item and 4 month invoice line item and current month included
            if(mapOfInvoiceLineItems != null && mapOfInvoiceLineItems.size() > 0 && mapOfInvoiceLineItems.containsKey(objEnrolment.id)){
                for(Invoice_Line_Item__c objInvLine  : mapOfInvoiceLineItems.get(objEnrolment.id)){
                    datetime dueDate = datetime.newInstance(objInvLine.Invoice__r.Due_Date__c, Time.newInstance(0,0,0,0));
                    string remarks = objInvLine.Is_Deposit__c?'Deposit Refund':'Deduct Paid Rent - '+ dueDate.format('dd MMM, yyyy');
                    Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(objInvLine.Amount__c,
                    objInvLine.GST_Amount__c,objInvLine.Package__c,
                    objInvLine.Enrolment__c,objInvLine.id,remarks,objInvLine.Month__c);
                    objCreditLineItem.Is_Deposit__c=objInvLine.Is_Deposit__c;
                    listOfCreditmemolineitem.add(objCreditLineItem);                                      
                    //Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                    if(string.isNotBlank(objInvLine.id) ){
                        updateInvoiceLineItem.put(objInvLine.id,updateInvoiceLineItemMap( updateInvoiceLineItem,objInvLine.Amount__c,objInvLine.GST_Amount__c,objInvLine.id));
                    }
                }
            }
            // If Existing Aureus student then inbound delivery charges and stair case charges will not be applied in credit memo. This is because for Aureus students these are charged at the time of rental termination.
            if(string.isBlank(objEnrolment.Related_Lesson_Enrolment__c)){
                // create credit memo line items for stair Case and Delivery charges one way amount refunded
                if(mapOfStairCaseandDeliveryChargesInvoice != null && mapOfStairCaseandDeliveryChargesInvoice.size() > 0 && mapOfStairCaseandDeliveryChargesInvoice.containsKey(objEnrolment.id)){
                    decimal taxrate = 0;
                    if(string.isnotBlank(objEnrolment.center__c) && string.isnotBlank(objEnrolment.center__r.country__c) &&  objEnrolment.center__r.country__r.Tax_Rate__c >0 ){
                        taxrate = objEnrolment.center__r.country__r.Tax_Rate__c;
                    }
                    for(Invoice_Line_Item__c objInvLine  : mapOfStairCaseandDeliveryChargesInvoice.get(objEnrolment.id)){
                        decimal chargeAmount =objInvLine.Amount__c/2;
                        string remarks ='';
                        datetime dueDate = datetime.newInstance(objInvLine.Invoice__r.Due_Date__c, Time.newInstance(0,0,0,0));
                        if(objInvLine.Remarks__c.containsIgnoreCase('Delivery')){
                            remarks ='Deduct (One Way) Delivery Charges';
                        }else if(objInvLine.Remarks__c.containsIgnoreCase('Stair')){  
                            remarks ='Deduct (One Way) Stair Charges - '+ dueDate.format('dd MMM, yyyy');
                        }
                        decimal gstAmount= 0;
                        if(taxrate >  0 && chargeAmount != 0 ){
                            gstAmount = BillingUtility.roundOffAmount(chargeAmount * (taxrate / 100));
                        } 
                        Credit_memo_line_item__c objCreditLineItem = BillingUtility.createCreditMemoLineRec(BillingUtility.roundOffAmount(chargeAmount),
                        gstAmount,objInvLine.Package__c,objInvLine.Enrolment__c,objInvLine.id,remarks,objInvLine.Month__c);
                        listOfCreditmemolineitem.add(objCreditLineItem);                                      
                        //Credit amount amount field should be populated without GST amount and applicable GST should be stored in Credit Memo Tax field
                        if(string.isNotBlank(objInvLine.id) ){
                            updateInvoiceLineItem.put(objInvLine.id,updateInvoiceLineItemMap( updateInvoiceLineItem,BillingUtility.roundOffAmount(chargeAmount),gstAmount,objInvLine.id));
                        }
                    }
                }
            }
            mapOfCreditmemolineitem.put('PianoRentalPurchase',listOfCreditmemolineitem);
            system.debug('objCreditMemo'+objCreditMemo);  
            newPendingCreditMemos.put('PianoRentalPurchase',objCreditMemo);
           
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
            if(updateInvoiceLineItem != null && updateInvoiceLineItem.size() > 0){
                update updateInvoiceLineItem.values();
            }
        }
        //added by nishi: 17-Nov-2020 : start:for new requirement Create a Credit Memo record with the status pending instead of the refund record.
       
    }

    public  static  Invoice_Line_Item__c updateInvoiceLineItemMap(Map<string,Invoice_Line_Item__c> updateInvoiceLineItem,decimal amount,decimal tax,string invoicelineitemId){
        decimal invoicelineItemCreditAmount=0;
        decimal invoicelineItemCreditGst=0;
        
        if(updateInvoiceLineItem.containskey(invoicelineitemId)){
            invoicelineItemCreditAmount = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_Amount__c :0;
            invoicelineItemCreditGst = updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c != null ?updateInvoiceLineItem.get(invoicelineitemId).Credit_Memo_tax__c :0;
        }
        decimal taxAmount =  tax != null && tax > 0 ? tax :0;
        decimal creditMemoAmount =  amount != null && amount > 0 ? amount :0;
        return new Invoice_Line_Item__c(id=invoicelineitemId,
                                    Credit_Memo_Amount__c =invoicelineItemCreditAmount+creditMemoAmount,
                                    Credit_Memo_tax__c=invoicelineItemCreditGst+taxAmount);
    }
   

    // 13-Feb-2020: Jatin: this function get enrolement and parent id then get related 4 month paid invoice amount with due date for show summary in termination page
    public static  Map<String,List<Invoice_Line_Item__c>> get4MonthPaidInvoiceAmountWithDate(Set<string> enrolmentIds){
        Date last4thMonthStartdate = date.newInstance(System.today().addMonths(-4).year(), System.today().addMonths(-4).Month(), 1);
        Date last4thMonthEnddate = System.today();
        Map<String,List<Invoice_Line_Item__c>> mapOfInvoiceEnrolmentIds = getTotalRentalDepositAmount(enrolmentIds);
        List<Invoice__c> listofInvoice = new List<Invoice__c>();
        Set<String> statusSet = new Set<String>{ConstantsClass.voidInvoiceStatus, ConstantsClass.cancelledInvoiceStatus};
        // get invoice line item for get enrolmentIds related to invoiceid
        for(Invoice_Line_Item__c objlineItem : [SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c,
                                    Credit_Memo_Amount__c,Credit_Memo_tax__c,Remarks__c,Invoice__r.Due_Date__c
                                    from Invoice_Line_Item__c
                                    Where Enrolment__c In:enrolmentIds
                                    AND (Invoice__r.Due_Date__c  >=: last4thMonthStartdate And Invoice__r.Due_Date__c <=: last4thMonthEnddate)
                                    AND Invoice__r.Status__c = 'Paid'
                                    AND Is_Deposit__c = false
                                    AND Invoice__r.Invoice_Type__c =:ConstantsClass.recurringInvoiceType
                                    And Invoice__r.Status__c NOT IN :statusSet]){
            List<Invoice_Line_Item__c> listofInvoiceLineItem = new List<Invoice_Line_Item__c>();
            if(mapOfInvoiceEnrolmentIds.containsKey(objlineItem.Enrolment__c)){
                listofInvoiceLineItem =mapOfInvoiceEnrolmentIds.get(objlineItem.Enrolment__c);
            }        
            listofInvoiceLineItem.add(objlineItem);
            mapOfInvoiceEnrolmentIds.put(objlineItem.Enrolment__c,listofInvoiceLineItem);    
        }
       
        return mapOfInvoiceEnrolmentIds;
    }

     // get depoist  invoice amount with gst
     public static Map<String,List<Invoice_Line_Item__c>>  getTotalRentalDepositAmount(Set<string> objEnrolmentIds){
        Map<string,list<Invoice_Line_Item__c>> mapOfTotalRentalDeposit = new Map<string,list<Invoice_Line_Item__c>>();
        Set<String> statusSet = new Set<String>{ConstantsClass.voidInvoiceStatus, ConstantsClass.cancelledInvoiceStatus};
       
        for( Invoice_Line_Item__c objInvoiceLineItem : [SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c,
                                                        Credit_Memo_Amount__c,Credit_Memo_tax__c,Remarks__c,Invoice__r.Due_Date__c
                                                        FROM Invoice_Line_Item__c 
                                                        WHERE Enrolment__c IN: objEnrolmentIds
                                                        AND Is_Deposit__c = true
                                                        AND Invoice__r.Due_Date__c <= Today
                                                        And Invoice__r.Status__c NOT IN :statusSet]){
            List<Invoice_Line_Item__c> listofInvoiceLineItem = new List<Invoice_Line_Item__c>();
            if(mapOfTotalRentalDeposit.containsKey(objInvoiceLineItem.Enrolment__c)){
                listofInvoiceLineItem =mapOfTotalRentalDeposit.get(objInvoiceLineItem.Enrolment__c);
            }        
            listofInvoiceLineItem.add(objInvoiceLineItem);                                               
            mapOfTotalRentalDeposit.put(objInvoiceLineItem.Enrolment__c,listofInvoiceLineItem);
        }
        return mapOfTotalRentalDeposit;
    }
     // get staircase and Delivery charge invoice amount with gst
     public static  Map<String,List<Invoice_Line_Item__c>>  getStairCaseandDeliveryChargesinvoice(Set<string> objEnrolmentIds){
        Date last4thMonthStartdate = date.newInstance(System.today().addMonths(-4).year(), System.today().addMonths(-4).Month(), 1);
        Date last4thMonthEnddate = System.today();
        Map<String,List<Invoice_Line_Item__c>> mapOfInvoiceEnrolmentIds = new Map<String,List<Invoice_Line_Item__c>>();
        List<Invoice__c> listofInvoice = new List<Invoice__c>();
        // get invoice line item for get enrolmentIds related to invoiceid
        for(Invoice_Line_Item__c objlineItem : [SELECT ID, Amount__c, GST_Amount__c,Package__c,Enrolment__c,Is_Deposit__c,Is_Discount__c,Month__c,
                                    Credit_Memo_Amount__c,Credit_Memo_tax__c,Remarks__c,Invoice__r.Due_Date__c
                                    from Invoice_Line_Item__c
                                    Where Enrolment__c In:objEnrolmentIds
                                    AND Invoice__r.Status__c = 'Paid'
                                    AND Is_Deposit__c = false]){
            List<Invoice_Line_Item__c> listofInvoiceLineItem = new List<Invoice_Line_Item__c>();
            if(objlineItem.Remarks__c.containsIgnoreCase('Delivery') || objlineItem.Remarks__c.containsIgnoreCase('Stair')){  
                if(mapOfInvoiceEnrolmentIds.containsKey(objlineItem.Enrolment__c)){
                    listofInvoiceLineItem =mapOfInvoiceEnrolmentIds.get(objlineItem.Enrolment__c);
                }      
                listofInvoiceLineItem.add(objlineItem);
                mapOfInvoiceEnrolmentIds.put(objlineItem.Enrolment__c,listofInvoiceLineItem);   
            }
            
        }
       
        return mapOfInvoiceEnrolmentIds;
    }
    //__________________________________________________________________________  Inner Classes _____________________________________________________________________________________________
    public class BillingSummary{
        public Decimal amount{get;set;}
        public String packageName{get;set;}
        public Decimal netAmount{get;set;}
        public BillingSummary(Decimal amount,String packageName){
            this.amount = amount;
            this.packageName = packageName;
            this.netAmount = (amount).setScale(2);
        }
    }
}