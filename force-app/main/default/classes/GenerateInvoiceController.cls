/*
Name        :    GenerateInvoiceController
Date        :    18 April 2019
Author      :
Description :    This controller is used for the ad hoc inovice.
*/
public class GenerateInvoiceController{
    public List<SelectOption> listOfCenter{get;set;}
    public String selectedCenter{get;set;}
    public List<ItemWrapper> listOfItems{get;set;}
    private List<SelectOption> listOfStudents;
    public String index{get;set;}
    private Account objAcc;
    public Boolean isSummaryOpen{get;set;}
    Public Country__c centreCountry{get;set;}
    private Map<String,String> mapOfStuName;
    public GenerateInvoiceController(ApexPages.StandardController sc){
        centreCountry = new Country__c();
        isSummaryOpen = false;
        objAcc = (Account)sc.getRecord();
        objAcc = [SELECT Id,Parent__c,Stripe_Customer_Id__c FROM Account WHERE Id=: objAcc.id];
        listOfCenter = new List<SelectOption>();
        listOfStudents = new List<SelectOption>();
        listOfItems = new List<ItemWrapper>();
        mapOfStuName = new Map<String,String>();
        fillCenterList();
        fillStudentList(objAcc);  
        addRow();      
    }
    
    private void fillCenterList(){
        listOfCenter.add(new SelectOption('', ''));
        for(Account objAcc : [SELECT Id,Name FROM Account WHERE 
                              RecordType.name =: ConstantsClass.centerRecTypeName ORDER By Name]){
                                  listOfCenter.add(new SelectOption(objAcc.id, objAcc.Name));
                              } 
    }
    
    private void fillStudentList(Account objAcc){
        System.debug('objAcc'+objAcc);
        listOfStudents.add(new SelectOption('', ''));
        String parentId = String.isBlank(objAcc.parent__c) ? objAcc.id : objAcc.Parent__c;
        for(Account objStudent : [SELECT Id,Name FROM Account WHERE (Id =: parentId or Parent__c =: parentId) AND 
                                  RecordType.Name =: ConstantsClass.customerRecTypeName ORDER BY Name]){
                                      listOfStudents.add(new SelectOption(objStudent.Id,objStudent.Name));
                                      mapOfStuName.put(objStudent.Id,objStudent.Name);
                                  }        
    }
    
    public List<SelectOption> getCampPkgList(){
        List<SelectOption> campPckgList = new List<SelectOption>();
        campPckgList.add(new SelectOption('Other','Other'));
        
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        for(Package__c pkg : [SELECT Id,Name FROM Package__c 
                              WHERE Package_Fee__c != null AND Active__c = True AND (Type__c = 'Camp' OR Type__c = 'Contract') AND 
                              RecordtypeId =: pkgLessRecId AND Is_Promotion_Discount__c = False ORDER BY Name]){
                                  campPckgList.add(new SelectOption(pkg.Id,pkg.Name));                     
                              }
        
        return campPckgList;
    }
    
    public void fetchPkgAmount(){
        ItemWrapper itmWrap = listOfItems.get(Integer.valueOf(index)-1);
        itmWrap.isPkgSlcd = false;
        itmWrap.itemName  = '';
        
        if(String.isNotBlank(itmWrap.slctdPkg) && itmWrap.slctdPkg != 'Other'){
            List<Package__c> pckgList = [SELECT Id,Name,Package_Fee__c FROM Package__c WHERE Id =: itmWrap.slctdPkg];
            if(pckgList.size() > 0){
                itmWrap.price = pckgList.get(0).Package_Fee__c;
                itmWrap.isPkgSlcd = true;
                itmWrap.itemName = pckgList.get(0).Name;
            }
        }
        
        listOfItems[Integer.valueOf(index)-1] = itmWrap;
    }
    
    
    public void addRow(){
        listOfItems.add(new ItemWrapper(listOfStudents));
    }
    public void removeRow(){
        listOfItems.remove(Integer.valueOf(index)-1);
    }
    
    public PageReference payAndRedirect(){
        System.debug('objAcc'+objAcc);
        Invoice__c objInvoice;
        System.debug('objAcc'+objAcc.Stripe_Customer_Id__c);
        if(String.isNotBlank(objAcc.Stripe_Customer_Id__c)){
            List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
            objInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                        Invoice_Date__c =system.today(), Parent_Account__c = objAcc.Id,Center__c=selectedCenter);
            
            Decimal totalAmount = 0;
            for(ItemWrapper objItem : listOfItems){
                decimal reduceAmount =reduceGSTFromAmount(centreCountry.Tax_Rate__c, objItem.price);
                Invoice_Line_Item__c invItm = new Invoice_Line_Item__c(Amount__c= BillingUtility.roundOffAmount(reduceAmount)/*,Student__c= objItem.selectedStudent*/,
                                                                       Remarks__c = objItem.itemName, month__c = System.today());
                if(objItem.isPkgSlcd == true && String.isNotBlank(objItem.slctdPkg))
                    invItm.Package__c = objItem.slctdPkg;
                if(reduceAmount > 0 && centreCountry.Tax_Rate__c > 0)
                    invItm.GST_Amount__c = BillingUtility.roundOffAmount(reduceAmount * (centreCountry.Tax_Rate__c / 100));
                system.debug('@@objItem.price'+objItem.price);
                system.debug('@@@reduceAmount'+reduceAmount);
                system.debug('@@@invItm.GST_Amount__c'+invItm.GST_Amount__c);    
                listOfLineItems.add(invItm);
                decimal gstAmount = invItm.GST_Amount__c != null ? invItm.GST_Amount__c : 0;
                system.debug('@@@invItm.gstAmount'+gstAmount);
                totalAmount+= BillingUtility.roundOffAmount((reduceAmount != null ? BillingUtility.roundOffAmount(reduceAmount) : 0) + gstAmount );    
            }
            system.debug('@@totalAmount'+totalAmount);
            //double gstAdded = totalAmount * (Double.valueOf(System.Label.GST_Tax_Rate) / 100);
            //totalAmount+= gstAdded;
            if(String.isNotBlank(centreCountry.Currency_Code__c) && String.isNotBlank(centreCountry.Stripe_Base_Url__c) && String.isNotBlank(centreCountry.Stripe_Secret_Key__c)){
                BillingUtility.StripeCharge objStripeCharge = BillingUtility.createChargeForCustomer(objAcc.Stripe_Customer_Id__c, totalAmount, centreCountry.Currency_Code__c, centreCountry.Stripe_Base_Url__c,  centreCountry.Stripe_Secret_Key__c);    
                System.debug('@@@objStripeCharge'+objStripeCharge);
                
                if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                    insert objInvoice;
                    objInvoice = [SELECT Id,Name,Parent_Account__c FROM Invoice__c WHERE Id=: objInvoice.Id];
                    for(Invoice_Line_Item__c objItem : listOfLineItems){
                        objItem.Invoice__c = objInvoice.id;
                    }
                    
                    INSERT listOfLineItems;
                    system.debug('@@listOfLineItems'+listOfLineItems);
                    
                    Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,totalAmount,ConstantsClass.successStatus); 
                    objPayment.Transaction_ID__c = objStripeCharge.Id;
                    objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                    insert objPayment;
                    system.debug('@@@objPayment'+objPayment);
                    BillingUtility.updateCharge(objStripeCharge.Id,objInvoice.Name, centreCountry.Stripe_Base_Url__c,  centreCountry.Stripe_Secret_Key__c);
                    
                }
            }
        }
        System.debug('@@@objInvoice'+objInvoice.Id);
        return new PageReference('/'+objInvoice.id);
    }
    private Double reduceGSTFromAmount(Decimal taxRate, Decimal amount){
        double gstAmount = 0.0;
        
        if(taxRate != NULL  && taxRate > 0){
            gstAmount = amount * (taxRate / 107);  // beacuse 7% was already included in amount
        } 
        system.debug('gstAmount'+gstAmount);
        system.debug('amount - gstAmount'+(amount - gstAmount));
        return (amount - gstAmount);
    }
    public void toggaleSummary(){
        //system.debug('toggleSummary called');
        for(ItemWrapper objItem : listOfItems){
            objItem.studName  = mapOfStuName.containsKey(objItem.selectedStudent) ?mapOfStuName.get(objItem.selectedStudent) : '';
        }
        isSummaryOpen = isSummaryOpen ? false : true;
        //system.debug('toggleSummary called'+isSummaryOpen);
        
    }
    
    Public void fetchCentreCountry(){
        List<Account> accList = new List<Account>();
        System.debug('@@@selectedCenter'+selectedCenter);
        if(String.isNotBlank(selectedCenter)){
            accList = [SELECT Id, Country__r.Id, Country__r.Currency_Code__c, Country__r.Stripe_Base_Url__c, 
                       Country__r.Stripe_Secret_Key__c, Country__r.Tax_Rate__c  FROM Account WHERE Id =: selectedCenter];
            if(accList.size() > 0){
                centreCountry = accList[0].Country__r;
                System.debug('@@@centreCountry'+centreCountry);
            }
            //centreCountry = 
        }else{
            centreCountry = new Country__c();
        }
    }
    
    public class ItemWrapper{
        public String itemName{get;set;}
        public List<SelectOption> listOfStudents{get;set;}
        public String selectedStudent{get;set;}
        public Decimal price{get;set;}
        public String studName{get;set;}
        public String slctdPkg{get;set;}
        public String slctdPkgName{get;set;}
        public Boolean isPkgSlcd{get;set;}
        
        public ItemWrapper(){}
        public ItemWrapper(List<SelectOption> listOfStudents){
            this.listOfStudents = listOfStudents;
        }
    }        
}