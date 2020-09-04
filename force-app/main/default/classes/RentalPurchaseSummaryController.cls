/*
    Name        :   RentalPurchaseSummaryController
    Date        :   01/21/2020
    Author      :   Jatin
    Description :   This controller is used to display summary for Rental Purchase Summary page
*/
public  class RentalPurchaseSummaryController {
    public String enrolId{get;set;}
    public Enrolment__c enrolment{get;set;}
    public List<BillingSummary> listOfSummary{get;set;}
    public Decimal gstAmount{get;set;}
     public Decimal amountAfterDiscount{get;set;}
    public Decimal finalAmount{get;set;}
    public Boolean errorMessage{get;set;}
    Public Decimal totalRentalDepositAmount{get;set;}
    Public Country__c centreCountry;
   
    public RentalPurchaseSummaryController(){
        gstAmount =0;
        amountAfterDiscount  = 0;
        totalRentalDepositAmount =0;
        errorMessage = false;
        finalAmount  = 0;
        enrolment  = new enrolment__C();
    }

    // get Billing summary 
    public void getPurchaseBillingSummary(){
        gstAmount = 0;
        centreCountry = new Country__c();
        errorMessage = false;
        amountAfterDiscount  = 0;
        finalAmount  = 0;
        system.debug('@@@enrolId'+enrolId);
        if(string.isNotBlank(enrolId)){
            errorMessage = true;
            List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolId});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                enrolment = listOfenrolment[0];
            }
            if(String.isNotBlank(enrolment.Id) && String.isNotBlank(enrolment.Center__r.Country__r.Id)){
                centreCountry = enrolment.Center__r.Country__r; 
            }
             listOfSummary = fillBillSummary(enrolment);
            for(BillingSummary summary : listOfSummary){
                amountAfterDiscount += summary.amount;
                if(String.isNotBlank(enrolment.Center__r.Country__r.Id) && enrolment.Center__r.Country__r.Tax_Rate__c > 0){
                    gstAmount += BillingUtility.roundOffAmount((summary.amount) * (enrolment.Center__r.Country__r.Tax_Rate__c / 100));    
                }
            }
            finalAmount = amountAfterDiscount + gstAmount;
            
            
            if(amountAfterDiscount > 0 || gstAmount > 0 || finalAmount > 0){
                amountAfterDiscount = (amountAfterDiscount != NULL) ? BillingUtility.roundOffAmount(amountAfterDiscount): 0;
                gstAmount = (gstAmount != NULL) ?BillingUtility.roundOffAmount(gstAmount) : 0;   
                finalAmount = (finalAmount != NULL) ? BillingUtility.roundOffAmount(finalAmount) :0;
            }
            Map<string,Decimal> mapOfTotalRentalDepositAmount  = PianoRentalHelperController.getTotalRentalDepositAmount(new Set<String>{enrolment.id});
            if(mapOfTotalRentalDepositAmount != null && mapOfTotalRentalDepositAmount.size() > 0 && mapOfTotalRentalDepositAmount.containsKey(enrolment.id)){
                if(mapOfTotalRentalDepositAmount.get(enrolment.id) !=  null && mapOfTotalRentalDepositAmount.get(enrolment.id) > 0)  
                    totalRentalDepositAmount =-(mapOfTotalRentalDepositAmount.get(enrolment.id));
            }
        }
    }
    
    
    /* fill invoice billing summary for customer confirmation
        a.	Original piano price (excluding promotion, if any)
        b.	Apply the following deductions()
            i.	Maximum 4 month rent paid(credit)
            ii.	Apply Rental Deposit (as applicable)(payment as deposit)
            iii.	Apply 1 way paid delivery charges (as applicable)(balance Credit)

    */
    private List<BillingSummary> fillBillSummary(Enrolment__c objEnrolment){
        List<BillingSummary> listOfBillSummary = new List<BillingSummary>();
        //commented by jatin: 13-feb-2020 for show all due invoice in summary 
        //Map<string,Decimal> mapOfTotalInvoicePaidAmount = PianoRentalHelperController.get4MonthPaidInvoiceAmount(new Set<String>{objEnrolment.id});
        Map<String,List<Invoice__c>> mapOfEnrolmentInvoice = PianoRentalHelperController.get4MonthPaidInvoiceAmountWithDate(new Set<String>{objEnrolment.id});
       
        Map<string,Decimal> mapOfTotalcurrentMonthPaidInvoiceAmount =PianoRentalHelperController.getCurrentMonthInvoiceAmount(new Set<String>{objEnrolment.id},ConstantsClass.paidStatus);
        Map<string,Decimal> mapOfTotalRentalDepositAmount  = PianoRentalHelperController.getTotalRentalDepositAmount(new Set<String>{objEnrolment.id});
        if(objEnrolment.Selling_price__c  != null && objEnrolment.Selling_price__c > 0){
            listOfBillSummary.add(new BillingSummary(objEnrolment.Selling_price__c,'Original piano price'));
        }
        
        if(objEnrolment.Delivery_Charges__c != null && objEnrolment.Delivery_Charges__c >0){
            listOfBillSummary.add(new BillingSummary(-(objEnrolment.Delivery_Charges__c/2),'Deduct (One Way) Delivery Charges'));
        }
        // 10-Feb-2020: deduct stairs charges
        if(objEnrolment.Stair_Charges__c != null && objEnrolment.Stair_Charges__c >0){
            listOfBillSummary.add(new BillingSummary(-(objEnrolment.Stair_Charges__c/2),'Deduct (One Way) Stair Charges'));
        }

        /*commented by jatin: 13-feb-2020 for show all due invoice in summary 
        if(mapOfTotalInvoicePaidAmount != null && mapOfTotalInvoicePaidAmount.size() > 0 && mapOfTotalInvoicePaidAmount.containsKey(objEnrolment.id)){
            
            /*if(mapOfTotalInvoicePaidAmount.get(objEnrolment.id) !=  null && mapOfTotalInvoicePaidAmount.get(objEnrolment.id) > 0) 
                listOfBillSummary.add(new BillingSummary(-(mapOfTotalInvoicePaidAmount.get(objEnrolment.id)),'Deduct Maximum 4 month paid rent')); 
        }*/

        // 13-Feb-2020: show paid invoice summary last 4 month with due date and amount
        if(mapOfEnrolmentInvoice != null && mapOfEnrolmentInvoice.size() > 0){
            List<Invoice__c> listofInvoice = mapOfEnrolmentInvoice.get(objEnrolment.id);
            for(Invoice__c objInvoice : listofInvoice){
                datetime dueDate = datetime.newInstance(objInvoice.Due_Date__c, Time.newInstance(0,0,0,0));
                listOfBillSummary.add(new BillingSummary(-(objInvoice.Sub_Total__c),'Deduct Paid Rent - '+ dueDate.format('dd MMM, yyyy'))); 
            }
        }

        /* commented by jatin: for this summary deduct in total amount
        if(mapOfTotalRentalDepositAmount != null && mapOfTotalRentalDepositAmount.size() > 0 && mapOfTotalRentalDepositAmount.containsKey(objEnrolment.id)){
            if(mapOfTotalRentalDepositAmount.get(objEnrolment.id) !=  null && mapOfTotalRentalDepositAmount.get(objEnrolment.id) > 0)  
                listOfBillSummary.add(new BillingSummary(-(mapOfTotalRentalDepositAmount.get(objEnrolment.id)),'Deduct Rental Deposit')); 
        }
        */

        // 5-FEB-2020: show current month paid Invoice amount
        if(mapOfTotalcurrentMonthPaidInvoiceAmount != null && mapOfTotalcurrentMonthPaidInvoiceAmount.size() > 0 && mapOfTotalcurrentMonthPaidInvoiceAmount.containsKey(objEnrolment.id)){
            if(mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id) !=  null && mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id) > 0) 
                listOfBillSummary.add(new BillingSummary(-(mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id)),'Deduct Current Month Rental')); 
        }

        return listOfBillSummary;
    }
    
    
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