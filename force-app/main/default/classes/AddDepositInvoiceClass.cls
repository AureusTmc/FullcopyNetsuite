public class AddDepositInvoiceClass {
	 
    /*
    Name        :        AddDepositInvoiceClass
    Author      :        Ravi Gupta
    Description :        It is the  class of Add Deposit Invoices.
    */
    @AuraEnabled
    public static list<Enrolment__c> getEnrolment(string enrolId){
        
       List<Enrolment__c> enrolList =[select Id,Name,Student__r.Name,Student__c,Parent__r.Name,Parent__c,Center__r.Name,Center__c,Package__r.Deposit_Fee__c,Teacher__c,Package__r.Name,Package__c ,(select Id,Subscription__c from Subscription_Line_Items__r Limit 1) from Enrolment__c where Id=:enrolId];
       
        if(enrolList.size()>0){
            return enrolList;
        }
        return enrolList;
    }
    @AuraEnabled
    public static list<Enrolment__c> getType(string enrolId){
        list<Enrolment__c> enrList= [select Id,Type__c From Enrolment__c where Id=:enrolId];
        return enrList;
    }
    @AuraEnabled
    public static void SaveInvoice(string EnrolList,string Subscriptions,string EnrolmentId,string PackageId,string TeacherId,string SubscriptionLine){
        Id paymentTransRecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
        List<Invoice__c> InvList=new List<Invoice__c>();
        list<Invoice_Line_Item__c> InvLineList = new list<Invoice_Line_Item__c>();
        list<Payment__c> paymentList = new List<Payment__c>();
        List<Wrapperclass> wraplist  = new List<Wrapperclass>();
        Id LessonType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        
        wraplist =   (List<Wrapperclass>)System.JSON.deserialize(EnrolList, List<Wrapperclass>.class);
        //integer size=wraplist.size();
        if(EnrolList!=null){
             for(Wrapperclass wr : wraplist){
                List<string> BkDate =wr.Invoice_Date.split('-');
                 system.debug('BkDate'+BkDate);
                Date InvoiceDate = Date.newInstance(Integer.valueOf(BkDate[0]),Integer.valueOf(BkDate[1]),Integer.valueOf(BkDate[2]));
                Invoice__c bkgObj = new Invoice__c(Customer_Name__c=wr.Student,Parent_Account__c=wr.Parent,Center__c=wr.Center,
                                                    Invoice_Date__c=InvoiceDate,Due_Date__c=InvoiceDate,Status__c='Paid',Subscription__c=Subscriptions,Field_1__c='Initial Deposit Invoices Created');
                InvList.add(bkgObj);
            }
            
            system.debug('InvList'+InvList);
            if(InvList.size()>0){
                insert InvList;
                integer j=0;
                for(Invoice__c InvObj:InvList){
                    Invoice_Line_Item__c invObject = new Invoice_Line_Item__c(Invoice__c=InvObj.Id,Remarks__c='Deposit',Enrolment__c=EnrolmentId,Package__c=PackageId,Teacher_Id__c=TeacherId,Subscription_Line_Item__c=SubscriptionLine,Field_1__c='Initial Deposit Invoices Created',Is_Deposit__c=true,Amount__c=decimal.valueOf(wraplist[j].DepositAmt));
                    InvLineList.add(invObject);
                    j++;
                }
                system.debug('InvLineList'+InvLineList);
                if(InvLineList.size()>0){
                    insert InvLineList;
                }
                integer i=0;
                for(Invoice__c InvObj:InvList){
                    Payment__c payObj = new Payment__c(Invoice__c=InvObj.Id,Payment_Date__c=InvObj.Invoice_Date__c,Parent_Account__c=InvObj.Parent_Account__c,Payment_Amount__c=decimal.valueOf(wraplist[i].DepositAmt),Remarks__c='Deposit',RecordTypeId=paymentTransRecordTypeId,Field_1__c='Initial Deposit Invoices Created',Transaction_ID__c=wraplist[i].Stripe,Method_of_Payment__c=wraplist[i].PaymentMethod,Payment_Status__c='Success');
                	paymentList.add(payObj);
                    i++;
                }
                system.debug('paymentList'+paymentList);
                if(paymentList.size()>0){
                    insert paymentList;
                }
            }
        } 
    }
        public class Wrapperclass{
            @auraenabled
            public String Student{get;set;}
            @auraenabled
            public string Parent{get;set;}
            @auraenabled
            public String Center{get;set;}
            @auraenabled
            public string Invoice_Date{get;set;}
            @auraenabled
            public String DepositAmt{get;set;}
            @auraenabled
            public String Packages{get;set;}
            @auraenabled
            public string Stripe{get;set;}
            @auraenabled
            public String CoInv{get;set;}
            @auraenabled
            public String PaymentMethod{get;set;}
            
            public Wrapperclass(){
                
            }
            
        }
}