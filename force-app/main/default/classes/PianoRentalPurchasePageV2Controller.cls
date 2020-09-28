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
                Parent__r.BillingCity, Parent__r.BillingCountry,Parent__r.Phone,Parent__r.id,Parent_Email__c,
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
        
        //deduct Delievery  charges
        if(objEnrolment.Delivery_Charges__c != null && objEnrolment.Delivery_Charges__c >0){
            listOfBillSummary.add(new BillingSummary(-(objEnrolment.Delivery_Charges__c/2),'Deduct (One Way) Delivery Charges'));
        }
        //deduct stairs charges
        if(objEnrolment.Stair_Charges__c != null && objEnrolment.Stair_Charges__c >0){
            listOfBillSummary.add(new BillingSummary(-(objEnrolment.Stair_Charges__c/2),'Deduct (One Way) Stair Charges'));
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
            
            //only work if successfule email is send
            if( Test.isRunningTest() || sendEmailResults[0].isSuccess() ){
                
                enrolment.Stage__c = ConstantsClass.enrollmentPianoSoldStage; 
                enrolment.Rental_Termination_Date__c = Date.today();
                update enrolment; 
                
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