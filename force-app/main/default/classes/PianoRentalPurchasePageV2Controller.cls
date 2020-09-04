/**
* @File Name : PianoRentalPurchasePageV2Controller.cls
* @Vf Page : PianoRentalPurchasePageV2.vfp
* @Test Class Name : - 
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
    
    //_________________________________________________________  Constructor  ________________________________________________________________________________
    public PianoRentalPurchasePageV2Controller(ApexPages.StandardController st) {
        
        enrolment = (Enrolment__c)st.getRecord();
        errorMessage = '';
        isErrorOnSave = false;
        amountAfterDiscount = 0;
        totalRentalDepositAmount = 0;
        isEmailSent = false;
        
        
        if(string.isNotBlank(enrolment.Id)){
            List<Enrolment__c> listOfenrolment  = getRentalEnrolmentList(new Set<string> {enrolment.Id});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                enrolment = listOfenrolment[0];
            }
        }
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
        return [SELECT Id,Product_Id__c,Brand__c ,Name, center__r.country__r.Tax_Rate__c,center__r.country__r.Stripe_Base_Url__c,
                Extra_Stairs__c,Actual_Delivery_Date_Time__c,Aggrement_Id__c,
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
    
    //This will send the email message to the POS team.
    public void sendEmailToPOS(){
        
        try{
            if( String.isNotBlank( enrolment.Center__r.Name ) ){
                
                List< OrgWideEmailAddress > listOWA = [ select id, Address, DisplayName from OrgWideEmailAddress WHERE displayName =: enrolment.Center__r.Name Limit 1 ];
                
                if( listOWA.size() > 0 && String.isNotBlank( listOWA[0].Address ) ){
                    
                    string emailHtmlBody = 'Dear Karan <br/>' ;
                    emailHtmlBody += 'Customer ' + enrolment.Parent__r.Name + '  has opted for the Rent-to-purchase option for their ongoing piano rental subscription. <br/>';
                    emailHtmlBody += 'Please see the credit statement that needs to be applied at the time of purchase. <br/>';
                    
                    Messaging.SingleEmailMessage objOutGoingEmail = new Messaging.SingleEmailMessage();
                    objOutGoingEmail.setToAddresses(new list< String >{'karan.singh@techmatrixconsulting.com'});
                    objOutGoingEmail.setSubject('Process-to-rental');
                    objOutGoingEmail.setHtmlBody(emailHtmlBody); 
                    objOutGoingEmail.setOrgWideEmailAddressId( listOWA[0].Id );
                    
                    //3 Sep 2020 Karan: will use OWA instead  objOutGoingEmail.setTargetObjectId( UserInfo.getUserId()); //need to to this as as validation rule written on Email message ->Check_if_From_Email_is_same_as_User
                    //3 Sep 2020 Karan: will use OWA instead  objOutGoingEmail.saveAsActivity = false;					//need to to this as as validation rule written on Email message ->Check_if_From_Email_is_same_as_User
                    
                    //_________________________________________________________________  Attaching pdf to the email  ________________________________________________-
                    Messaging.EmailFileAttachment objEmailAttchmt = new Messaging.EmailFileAttachment();
                    objEmailAttchmt.setFileName('Reciept.pdf');
                    objEmailAttchmt.setBody(new PageReference('/apex/PianoRentalPurchasePageV2?Id=' + enrolment.Id).getContentAsPDF()); 
                    objOutGoingEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {objEmailAttchmt});
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {objOutGoingEmail});
                
                }else{ //__________________________________________________  incase if any enrolment's centre doesnot have any address in OWA
                    
                    isErrorOnSave = true;
                    errorMessage='We have encountered a problem while sending the email : Current enrolment Center does not have valid email address associated with it. Please check the address of associated centre in the OWA.'; 
                }
            }else{  //_______________________________________________  incase if any enrolment doesnot have any center assiociated to it as we need this for fetch center email address from OWA
           
                isErrorOnSave = true;
                errorMessage='We have encountered a problem while sending the email : Current enrolment is not associated to any centre.'; 
            }
            
        }catch( Exception objExp ){
            
            isErrorOnSave = true;
            errorMessage='We have encountered a problem while sending the email : ' + objExp.getMessage() + ' Line Number : '+ objExp.getLineNumber() ;
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