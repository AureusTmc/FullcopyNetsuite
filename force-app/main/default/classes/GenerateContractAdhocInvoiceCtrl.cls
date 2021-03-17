/*
Name        :    GenerateContractAdhocInvoiceCtrl
Date        :    23 Feb 2021
Author      :
Description :    This controller is used for the Contract ad hoc invoice.
test class:GenerateContractAdhocInvoiceCtrlTest
page		:	GenerateContractAdhocInvoicePage
*/
public with Sharing class GenerateContractAdhocInvoiceCtrl{
    public List<SelectOption> listOfCenter{get;set;}
    public String selectedCenter{get;set;}
    public String centerName{get;set;}
    public List<ItemWrapper> listOfItems{get;set;}
    private List<SelectOption> listOfTeacher{get;set;}
    public String index{get;set;}
    public String teacherName{get;set;}
    public String teacherId{get;set;}
    public String startDate{get;set;}
    public String enddate{get;set;}
    public String invoiceDate{get;set;}
    public Boolean isInvoiceDate{get;set;}
    public String totalLesson{get;set;}
    private Account objAcc;
    public Boolean isSummaryOpen{get;set;}
    Public Country__c centreCountry{get;set;}
    private Map<String,String> mapOfStuName;
    public Boolean isError{get;set;}
    public Boolean isSucess{get;set;}
    public string errormessage{get;set;}
    public string selectedMethod{get;set;}
    public string invoiceId{get;set;}
    Invoice__c objInvoice = new Invoice__c ();
    public Boolean isAllowedPermissionToThisUser{get;set;}
    public GenerateContractAdhocInvoiceCtrl(ApexPages.StandardController sc){
        isAllowedPermissionToThisUser = FeatureManagement.checkPermission('Add_Contract_Invoice') ? true : false;
      
        centreCountry = new Country__c();
        isSummaryOpen = false;
        objAcc = (Account)sc.getRecord();
        objAcc = [SELECT Id,Parent__c,Centre_Name__c,Stripe_Customer_Id__c,person_email__c FROM Account WHERE Id=: objAcc.id];
        listOfCenter = new List<SelectOption>();
        listOfTeacher = new List<SelectOption>();
        listOfItems = new List<ItemWrapper>();
        mapOfStuName = new Map<String,String>();
        fillCenterList();
        //selectedCenter = String.isnotBlank(objAcc.Centre_Name__c) ? objAcc.Centre_Name__c : '';
        if(string.isNotBlank(selectedCenter)){
            fetchCentreCountry();
        }
        objInvoice = new Invoice__c(Status__c=ConstantsClass.dueStatus,
                                         Due_Date__c = system.today(),
                                        Invoice_Date__c =system.today(), 
                                        Parent_Account__c = objAcc.Id,
                                        Invoice_Type__c ='Contract');
        //fillStudentList(objAcc);  
        addRow();      
    }
    
    private void fillCenterList(){
        List<Centre_Users__c> cenUsrLst = [select Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.Country__c,Centre_Name__r.Country__r.Name, Centre_Name__r.Country__r.Country_Name__c
        from Centre_Users__c where User_Name__c=:UserInfo.getUserId()];
        if(cenUsrLst.size() > 0){
            selectedCenter= cenUsrLst.get(0).Centre_Name__c;
            centerName = cenUsrLst.get(0).Centre_Name__r.Name;
        }
        // listOfCenter.add(new SelectOption('', ''));
        // for(Account objAcc : [SELECT Id,Name FROM Account WHERE 
        //                       RecordType.name =: ConstantsClass.centerRecTypeName ORDER By Name]){
        //                           listOfCenter.add(new SelectOption(objAcc.id, objAcc.Name));
        //                       } 
    }

    @RemoteAction
    public static String getStudents(String str,String centreCountryId){
        TeacherDetails objTeacherDetails = new TeacherDetails();
        system.debug('str'+str);
        system.debug('centreCountryId'+centreCountryId);
        list<TeacherDetail> listOfTeacherDetails = new list<TeacherDetail>();
       // listOfTeacher = new List<SelectOption>();
        //listOfTeacher.add(new SelectOption('', ''));
        //String selCenter = String.isBlank(selectedCenter) ? objAcc.Centre_Name__c : selectedCenter;
        Set<String> teachersIdSet = new Set<String>();
        if(String.isNotBlank(centreCountryId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__r.Country__c =: centreCountryId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        system.debug('teachersIdSet'+teachersIdSet);
        String query = '';    
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;         
        if(teachersIdSet.size() > 0){
            string searchstring = String.isNotBlank(str)  ?'%'+str+'%':'';
            List<account> listOfTeachers = [SELECT Id, Name FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus
                                             AND id IN : teachersIdSet
                                             And (Name LIKE :searchstring)
                                             ORDER BY Name
                                             Limit 5];
                                             system.debug('listOfTeachers'+listOfTeachers);                                 
            for(account objStudent:  listOfTeachers){
                TeacherDetail objTeacherDetail = new TeacherDetail();
                objTeacherDetail.teacherid = objStudent.Id;
                objTeacherDetail.teachername = objStudent.Name;
                //listOfTeacher.add(new SelectOption(objStudent.Id,objStudent.Name));
                //mapOfStuName.put(objStudent.Id,objStudent.Name);
                listOfTeacherDetails.add(objTeacherDetail);
            }  
        }  
        system.debug('listOfTeacherDetails'+listOfTeacherDetails); 
        objTeacherDetails.listOfTeacherDetails = listOfTeacherDetails;
        return JSON.serialize(objTeacherDetails);
    }
    public class TeacherDetails{
        public list<TeacherDetail> listOfTeacherDetails;
    }
    public class TeacherDetail{
        public String teacherid;
        public String teachername;
    }
    
    /*public List<SelectOption> getCampPkgList(){
        List<SelectOption> campPckgList = new List<SelectOption>();
        campPckgList.add(new SelectOption('Other','Other'));
        
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        for(Package__c pkg : [SELECT Id,Name FROM Package__c 
                              WHERE Package_Fee__c != null AND Active__c = True AND (Type__c = 'Contract') AND 
                              RecordtypeId =: pkgLessRecId AND Is_Promotion_Discount__c = False ORDER BY Name]){
                                  campPckgList.add(new SelectOption(pkg.Id,pkg.Name));                     
                              }
        
        return campPckgList;
    }*/
    
    /*public void fetchPkgAmount(){
        ItemWrapper itmWrap = listOfItems.get(Integer.valueOf(index)-1);
        itmWrap.isPkgSlcd = false;
        itmWrap.itemName  = '';
        
        if(String.isNotBlank(itmWrap.slctdPkg) && itmWrap.slctdPkg != 'Other'){
            List<Package__c> pckgList = [SELECT Id,Name,Package_Fee__c FROM Package__c WHERE Id =: itmWrap.slctdPkg];
            if(pckgList.size() > 0){
                itmWrap.price = pckgList.get(0).Package_Fee__c * integer.valueOf(string.isNotBlank(itmWrap.noOflesson)? itmWrap.noOflesson:'1');
                itmWrap.isPkgSlcd = true;
                itmWrap.itemName = pckgList.get(0).Name;
            }
        }
        
        listOfItems[Integer.valueOf(index)-1] = itmWrap;
    }*/
    
    
    public void addRow(){
        listOfItems.add(new ItemWrapper(listOfTeacher));
    }
    public void removeRow(){
        listOfItems.remove(Integer.valueOf(index)-1);
    }
    
    public void payAndRedirect(){
        isError = false;
        isSucess = false;
        errormessage ='';
        invoiceId ='';
        try{
            System.debug('objAcc'+objAcc);
            
            List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
            Decimal totalAmount = 0;
            if(listOfItems != null && listOfItems.size()> 0 ){
                objInvoice.Center__c=selectedCenter;
                                        
                for(ItemWrapper objItem : listOfItems){
                    date startDateterm= string.isNotBlank(objItem.startDateterm) ?  date.newInstance(integer.valueOf(objItem.startDateterm.split('/')[2]), integer.valueOf(objItem.startDateterm.split('/')[0]), integer.valueOf(objItem.startDateterm.split('/')[1])) : System.today();//02/01/2021 
                    date endDateterm= string.isNotBlank(objItem.endDateterm) ?  date.newInstance(integer.valueOf(objItem.endDateterm.split('/')[2]), integer.valueOf(objItem.endDateterm.split('/')[0]), integer.valueOf(objItem.endDateterm.split('/')[1])) : System.today();//02/01/2021 
                    decimal reduceAmount =objItem.price;//reduceGSTFromAmount(centreCountry.Tax_Rate__c, objItem.price);
                    Invoice_Line_Item__c invItm = new Invoice_Line_Item__c(Amount__c= BillingUtility.roundOffAmount(reduceAmount),Student_Name__c= objItem.selectedStudent,
                                                                            Remarks__c = objItem.itemName, month__c = System.today(),
                                                                            Number_of_Lesson__c=objItem.noOflesson, Teacher_Id__c=objItem.slctdteacher,
                                                                            Term_Start_Date__c = startDateterm,
                                                                            Term_End_Date__c= endDateterm);

                    // if(objItem.isPkgSlcd == true && String.isNotBlank(objItem.slctdPkg))
                    //     invItm.Package__c = objItem.slctdPkg;
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
                insert objInvoice;
                objInvoice = [SELECT Id,Name,Parent_Account__c FROM Invoice__c WHERE Id=: objInvoice.Id];
                for(Invoice_Line_Item__c objItem : listOfLineItems){
                    objItem.Invoice__c = objInvoice.id;
                }
                
                INSERT listOfLineItems;
                system.debug('@@listOfLineItems'+listOfLineItems);
                isSucess = true;
                errormessage ='Invoice Created Sucessfully..';
                createPayment(selectedMethod,objInvoice.id,totalAmount);
                if(isSucess){
                    invoiceId = objInvoice.id;
                }
            }
        }catch(Exception e){
            system.debug('error'+e.getStackTraceString()+'-'+e.getMessage());
            isError = true;
            errormessage = e.getStackTraceString()+'-'+e.getMessage();
        }
       
    }

    // this method is used for adjusting credit notes on the parent.
    private static void adjustDiscounts(Set<String> setOfInvIds,Date invDate){
        Map<String,Invoice__c> mapOfParentInv = new Map<String,Invoice__c>();
        Map<String,Customer_Adhoc_Discount__c> customerDiscountsMap = new Map<String,Customer_Adhoc_Discount__c>();
        List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
        List<Customer_Adhoc_Discount__c> listOfDiscounts = new List<Customer_Adhoc_Discount__c>();
        //to apply tax on discount...
        Map<String, Account> mapOfParent = new Map<String, Account>();
        for(Invoice__c objInv : [SELECT Id,Parent_Account__c, Parent_Account__r.Centre_Name__r.Country__r.Tax_Rate__c, 
                                Total_Amount__c,Parent_Account__r.Centre_Name__r.Organisation__r.Tax_Rate__c
                                FROM Invoice__c WHERE Id IN : setOfInvIds]){
            mapOfParentInv.put(objInv.parent_Account__c, objInv);
            mapOfParent.put(objInv.parent_Account__c, objInv.parent_Account__r);
        }
        // filling map of 1 pending discont for each parent if it has any.
        for(Customer_Adhoc_Discount__c discount : [SELECT Id,Discount_Amount__c,Parent__c,Status__c,Reason__c,Remark__c 
                                                FROM Customer_Adhoc_Discount__c 
                                                WHERE Parent__c IN :mapOfParentInv.keySet() AND
                                                Status__c =: constantsClass.paymentPendingStatus 
                                                AND Discount_Amount__c != NULL 
                                                AND Discount_Date__c <=: invDate
                                                order by Discount_Amount__c Desc]){
        
            if(!customerDiscountsMap.containsKey(discount.Parent__c)){
                customerDiscountsMap.put(discount.Parent__c,discount);
            }
        }
        // Adjusting discount
        for(String parentId : customerDiscountsMap.keySet()){
            Customer_Adhoc_Discount__c discount = customerDiscountsMap.get(parentId);
            if(mapOfParentInv.containsKey(parentId) && mapOfParentInv.get(parentId).Total_Amount__c >= discount.Discount_Amount__c){
                String invId = mapOfParentInv.get(parentId).Id;
                String remarks='';
                if(String.isNotBlank(discount.Reason__c)){
                    if(discount.Reason__c == 'Admin Error'){
                        remarks = 'Referral';    
                    }else if(discount.Reason__c == 'Others'){
                        remarks = discount.Remark__c;  
                    }else{
                        remarks = discount.Reason__c;
                    }
                }

                Decimal taxAmount  = 0;
                if(mapOfParent.containsKey(parentId) && String.isNotBlank(mapOfParent.get(parentId).Centre_Name__r.Country__c) && 
                    mapOfParent.get(parentId).Centre_Name__r.Country__r.Tax_Rate__c != NULL && 
                    mapOfParent.get(parentId).Centre_Name__r.Country__r.Tax_Rate__c > 0){
                        taxAmount = (BillingUtility.roundOffAmount((-1*discount.Discount_Amount__c)) * mapOfParent.get(parentId).Centre_Name__r.Country__r.Tax_Rate__c) / 100;
                }
               
                Invoice_Line_Item__c discountItem = BillingUtility.fillInvLnItm(invId,null,null, BillingUtility.roundOffAmount(-1*discount.Discount_Amount__c), remarks,'');
                discountItem.Month__c = invDate;
                discountItem.is_Discount__c = true;   
                discountItem.GST_Amount__c = BillingUtility.roundOffAmount(taxAmount);

                listOfLineItems.add(discountItem);
                discount.Status__c = ConstantsClass.paymentSuccessStatus;
                discount.invoice__c = invId;
                listOfDiscounts.add(discount); 
            }
        }
        
        if(listOfLineItems.size() > 0){
            INSERT listOfLineItems;
        }
        if(listOfDiscounts.size() > 0){
            UPDATE listOfDiscounts;
        }
      
    }
    public void createPayment( String selectedMethod, String recordId,  Decimal currentCreditAmounts){
        system.debug('method call-->'+selectedMethod+ recordId+currentCreditAmounts);
        if( String.isNotBlank(recordId) && String.isNotBlank(selectedMethod)){
            try{  
                List<Payment__c> paymentsToUpsert  = new List<Payment__c>();//To update and create paymet of crdit
                //Getting recordtype Id
                String payCredRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
                String paySuccesRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
                //Fetching current invoice Values
                List<Invoice__c> invoiceList = new List<Invoice__c>();
                Map<String, Date> mapOfParentEnrolmentLastDate = new Map<String, Date>();
                for(Invoice__c invoiceObj : [SELECT Id, Name,Parent_Account__c,Total_Amount__c, Remarks__c,Invoice_Date__c,Parent_Account__r.Centre_Name__c,
                                                Center__r.Country__r.Tax_Rate__c,Credit_Memo_Amount__c,Balance_Amount__c,
                                                Parent_Account__r.Total_Payment_Credit_Available__c,
                                                Center__r.Organisation__r.Name,Parent_Account__r.Centre_Name__r.Location__c,Parent_Account__r.PersonContactId, // added by nishi: 13-nov-2020: for send Payment confiramtion email 
                                                Total_Invoice_Amount__c,Status__c,Parent_Account__r.Total_Credit_Memo_Available__c,
                                                (SELECT Id, Enrolment__r.id,Enrolment__r.Package_Process_Type__c ,Term_End_Date__c,
                                                    Enrolment__r.Effective_Date__c ,Package__c
                                                    FROM Invoice_Line_Items__r) 
                                                FROM Invoice__c 
                                            WHERE Id =: recordId]){
                                                invoiceList.add(invoiceObj);
                    for(Invoice_Line_Item__c  lineItemObj : invoiceObj.Invoice_Line_Items__r){
                        if(mapOfParentEnrolmentLastDate.containsKey(invoiceObj.Parent_Account__c) && 
                            mapOfParentEnrolmentLastDate.get(invoiceObj.Parent_Account__c) < lineItemObj.Term_End_Date__c){
                            mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Term_End_Date__c);
                        }else if(lineItemObj.Term_End_Date__c != NULL){
                            mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Term_End_Date__c);
                        }
                    }
                }           
                adjustDiscounts(new Set<String>{recordId},system.today());                                 
                system.debug('invoiceList--->'+invoiceList);
                /*if(invoiceList.size() > 0 ){
                    payment__c objpayment = new payment__c();
                    Invoice__c invoice = invoiceList[0];
                    boolean isOssia = false;
                    if(string.isNotBlank(invoiceList[0].Center__c) && string.isNotBlank(invoiceList[0].Center__r.Organisation__c)&&
                        string.isNotBlank(invoiceList[0].Center__r.Organisation__r.Name) 
                        && invoiceList[0].Center__r.Organisation__r.Name ==System.Label.Ossia_Organisation_Name ){
                        isOssia=true;
                    }
                    //List<Credit_Memo__c> creditMemosToUpsert  = new List<Credit_Memo__c>();//To update and create paymet of crdit
                    Map<String, Credit_Memo__c> mapOfCreditMemos = new Map<String, Credit_Memo__c>();
                    Decimal accumulatedCreditMemoAmount = invoice.Parent_Account__r.Total_Credit_Memo_Available__c != null ?invoice.Parent_Account__r.Total_Credit_Memo_Available__c : 0;
                            
                    if(accumulatedCreditMemoAmount != null && accumulatedCreditMemoAmount > 0){
                        Decimal invoiceTotalAmount = invoice.Balance_Amount__c; 
                        Decimal diffrenceAmount = 0;
                       
                        List<Credit_Memo__c> listOfCreditMemos  =PaymentComponentController.generateCreditMemoQuery( new Set<String>{invoice.Parent_Account__c});
                        if(listOfCreditMemos != null && listOfCreditMemos.size()>0){
                            Date lastDate = listOfCreditMemos[0].Credit_Memo_Date__c;
                            Map<String, Boolean> mapOfActiveParent = BillingUtility.checkParentHasMultipleEnrolments( new Set<String>{invoice.Parent_Account__c}, lastDate);
                            Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo = BillingUtility.getParentCreditMemo(new Set<String>{invoice.Parent_Account__c},lastDate);
                            BillingUtility.adjustPendingCreditMemoDeposit(invoiceList, new Set<String>{invoice.id}, new Set<String>{invoice.Parent_Account__c},mapOfParentEnrolmentLastDate,false,mapOfParentCreditMemo,mapOfActiveParent );
                            if(accumulatedCreditMemoAmount<invoiceTotalAmount){
                                diffrenceAmount =  invoiceList[0].Balance_Amount__c - accumulatedCreditMemoAmount;
                            }
                            if(diffrenceAmount >0){// for  if user use only credit memo amount not use other options
                                //Create new payment credit for remaning amount
                                objpayment = PaymentComponentController.createpaymentrecord(diffrenceAmount,selectedMethod,invoiceList[0].Id,'',paySuccesRecId,invoiceList[0].Parent_Account__c);
                                paymentsToUpsert.add(objpayment); 
                                invoiceList[0].Status__c ='Paid'; 
                                isSucess = true;
                                errormessage ='Paid Invoice Amount Sucessfully';
                            }else{
                                isSucess = true;
                                errormessage = 'Credit Memo Amount Used Sucessfully';
                            }
                            
                        }else{
                            isError = true;
                            errormessage ='Credit memo Amount not found. ';
                        }
                    }
                    // for if payment is credit record not found then we insert new payment record with full amount
                    else{
                        objpayment = PaymentComponentController.createpaymentrecord(invoiceList[0].Balance_Amount__c,selectedMethod,invoiceList[0].Id,'',paySuccesRecId,invoiceList[0].Parent_Account__c);
                        paymentsToUpsert.add(objpayment);
                        invoiceList[0].Status__c ='Paid';
                        isSucess = true;
                        errormessage ='Paid Invoice Amount Sucessfully';
                    }

                    system.debug('paymentsToUpsert-->'+paymentsToUpsert);
                    if(paymentsToUpsert.size() > 0)
                        UPSERT paymentsToUpsert;
                    if(invoiceList.size() > 0)
                        update  invoiceList[0];
                }*/
            }catch(Exception e){
                system.debug('error'+e.getStackTraceString()+'-'+e.getMessage());
                isError = true;
                errormessage = e.getStackTraceString()+'-'+e.getMessage();
            }
           
        }
    }/*
    private Double reduceGSTFromAmount(Decimal taxRate, Decimal amount){
        double gstAmount = 0.0;
        
        if(taxRate != NULL  && taxRate > 0){
            gstAmount = amount * (taxRate / 107);  // beacuse 7% was already included in amount
        } 
        system.debug('gstAmount'+gstAmount);
        system.debug('amount - gstAmount'+(amount - gstAmount));
        return (amount - gstAmount);
    }*/
    public void toggaleSummary(){
        isSummaryOpen = isSummaryOpen ? false : true;
    }
    public void udpateTeacherDetails(){
        ItemWrapper itmWrap = listOfItems.get(Integer.valueOf(index)-1);
        itmWrap.slctdteacherName = teacherName;
        itmWrap.slctdteacher  = teacherId;
        listOfItems[Integer.valueOf(index)-1] = itmWrap;
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
            //fillStudentList(objAcc);
        }else{
            centreCountry = new Country__c();
        }
        
    }
    public void udpateTermDateRange(){
        ItemWrapper itmWrap = listOfItems.get(Integer.valueOf(index)-1);
        itmWrap.startDateterm = startDate;
        itmWrap.endDateterm  = enddate;
        //itmWrap.noOflesson = totalLesson;
        listOfItems[Integer.valueOf(index)-1] = itmWrap;
        //fetchPkgAmount();
    }
    public void setInvoiceDate(){
        if(isInvoiceDate){
            objInvoice.Invoice_Date__c =  string.isNotBlank(invoiceDate) ?  date.newInstance(integer.valueOf(invoiceDate.split('/')[2]), integer.valueOf(invoiceDate.split('/')[0]), integer.valueOf(invoiceDate.split('/')[1])) : System.today();//02/01/2021 
        }else{
            objInvoice.Due_Date__c =  string.isNotBlank(invoiceDate) ?  date.newInstance(integer.valueOf(invoiceDate.split('/')[2]), integer.valueOf(invoiceDate.split('/')[0]), integer.valueOf(invoiceDate.split('/')[1])) : System.today();//02/01/2021 
        }
    }
    public class ItemWrapper{
        public String itemName{get;set;}
        public List<SelectOption> listOfTeacher{get;set;}
        public String selectedStudent{get;set;}
        public Decimal price{get;set;}
        public String slctdPkg{get;set;}
        public String slctdPkgName{get;set;}
        public String slctdteacher{get;set;}
        public String slctdteacherName{get;set;}
        public String noOflesson{get;set;}
        public String startDateterm{get;set;}
        public String endDateterm{get;set;}
        public Boolean isPkgSlcd{get;set;}
        
        public ItemWrapper(){
            startDateterm = Datetime.newInstance(date.newInstance(System.now().year(),System.now().month(),1),System.now().time()).format('MM/dd/YYYY');
            endDateterm =  Datetime.newInstance(date.newInstance(System.now().year(),System.now().month(),date.daysInMonth(System.now().year(),System.now().month())), System.now().time()).format('MM/dd/YYYY');
            noOflesson = '10';
            slctdteacherName='';
        }
        public ItemWrapper(List<SelectOption> listOfTeacher){
            this.listOfTeacher = listOfTeacher;
            startDateterm = Datetime.newInstance(date.newInstance(System.now().year(),System.now().month(),1),System.now().time()).format('MM/dd/YYYY');
            endDateterm =  Datetime.newInstance(date.newInstance(System.now().year(),System.now().month(),date.daysInMonth(System.now().year(),System.now().month())), System.now().time()).format('MM/dd/YYYY');
            noOflesson = '10';
            slctdteacherName='';
        }
    }        
}