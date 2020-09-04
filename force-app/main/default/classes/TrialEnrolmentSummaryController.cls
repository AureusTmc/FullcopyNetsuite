public class TrialEnrolmentSummaryController{
    public Account parentAcc{get;set;}
    public Account student{get;set;}
    public Enrolment__c freeTrailEnr{get;set;}
    public String lessTime{get;set;}
    
    public Decimal pkgFeesPromtnalDis{get;set;}
    public Decimal regiFees{get;set;}
    public Decimal regiFeesDis{get;set;}
    public Decimal prgRegFees{get;set;}
    public Decimal depFees{get;set;}
    public Decimal prgFees{get;set;}
    public Decimal gstAmt{get;set;}
    public Decimal totAmt{get;set;}
    public Decimal disTot{get;set;}
    public Decimal subsTot{get;set;}
    public Decimal grandTot{get;set;}
    
    public string base64SignImg{get;set;}
    public string stripeToken{get;set;}
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    public Boolean isErrorOnLoad{get;set;}
    
    public String apiKey {get;set;}
    Decimal packFees;
    Integer pkgDuration;
    Integer  prmtnalPkgInMonth;
    public TrialEnrolmentSummaryController(){
        parentAcc    = new Account();
        student      = new Account();
        freeTrailEnr = new Enrolment__c();
        
        String enrolId = ApexPages.currentPage().getParameters().get('id'); 
        packFees = regiFees = prgRegFees = depFees = prgFees = gstAmt = totAmt = pkgFeesPromtnalDis = regiFeesDis = disTot = grandTot = subsTot = 0;
        
        //Get Api key for the Stripe
        List<Stripe_Settings__mdt> stripeSettings = [SELECT Id,Stripe_Base_Url__c,Stripe_Secret_Key__c,Stripe_Publishable_Key__c 
                                                     FROM Stripe_Settings__mdt 
                                                     WHERE DeveloperName =: ConstantsClass.cstmMetaDataStripe LIMIT 1];
        if(stripeSettings.size()>0){
           apiKey = stripeSettings[0].Stripe_Publishable_Key__c;
        }
        
        try{
            if(String.isNotBlank(enrolId)){  
               
                List<Enrolment__c> enrList = [SELECT Id, Center__c, Center__r.name, Center__r.CentreName_Cust__c, Teacher__c, Teacher__r.name, Package__c, 
                                              		 Package__r.Name, Package__r.Program__r.Instrument__c, Parent__r.Also_a_Student__c, Student__c, Parent__c, 
                                                     Trial_Date__c, Trial_Start_Time__c, Center__r.Travel_Time__c, Lessons_Start_Date__c, Lesson_Start_time__c
                                              FROM Enrolment__c
                                              WHERE Id =: enrolId AND Student__c != null AND Parent__c != null AND Type__c = 'Trial'
                                              		AND Center__c != null AND Teacher__c != null AND Package__c != null Limit 1];
                if(enrList.size() > 0){
                    freeTrailEnr      = enrList.get(0);
                    
                  //  String lesHour  = ''+ freeTrailEnr.Lesson_Start_time__c.hour();
                    //String lesMints = ''+ freeTrailEnr.Lesson_Start_time__c.minute();
                  //  lessTime = lesHour.length() > 1 ? lesHour : '0'+lesHour ;
                    lessTime = DateTime.newInstance(freeTrailEnr.Lessons_Start_Date__c, freeTrailEnr.Lesson_Start_time__c).format('hh:mm a');
                    
                    
                    fetchCstmrAndLessonInfo();
                }else{
                    errorMsg = 'Enrolment is not correct, Please contact our center admin.';
                    isErrorOnLoad = true;
                }
            }else{
                //Please check booking error
                //Need to show error
                errorMsg = 'Enrolment is not available.';
                isErrorOnLoad = true;
            }
        }catch(Exception e){
            errorMsg = 'Enrolment is not correct,  Please contact our center admin.';
            isErrorOnLoad = true;
        }
    }  
    
    private void fetchCstmrAndLessonInfo(){
        if(freeTrailEnr.Id != null){
           
            //Fetching Parent Account
            List<Account> accList = [SELECT Id, FirstName, LastName, PersonMobilePhone, PersonOtherPhone, PersonEmail, 
                                     		BillingCountryCode, Gender__c, Nationality__c, Phone, Occupation__c, BillingStreet, 
                                     		BillingCity, BillingPostalCode, BillingCountry
                                     FROM Account WHERE Id =: freeTrailEnr.Parent__c];
            if(accList.size() > 0)
                parentAcc = accList.get(0);
            
             //Fetching Student Account
            accList = [SELECT Id, FirstName, LastName, PersonBirthdate, Learning_Style__c, Description, Gender__c, Nationality__c
                       FROM Account WHERE Id =: freeTrailEnr.Student__c];
            if(accList.size() > 0)
                student = accList.get(0);  
            
            List<Package__c> packList = [SELECT Id, Name, Program__c, Deposit_Fee__c, Registration_Fee__c, Package_Fee__c,
                                         		Unit_Fee__c, Duration__c, Program__r.Billing__c, Program__r.Scheduling__c,
                                         		Promotion_period_In_months__c, Promotion_Discount__c, Package_after_Promotion__c, Package_after_Promotion__r.Unit_Fee__c,
                                                Is_Promotion_Discount__c, Registration_Discount_Active__c, Registration_Discount_Value__c  
                                         FROM Package__c WHERE Id =: freeTrailEnr.Package__c];
            
            if(packList.size() > 0){
                Package__c pack = packList.get(0);
                packFees = pack.Package_Fee__c;
                depFees  = pack.Deposit_Fee__c != null ? pack.Deposit_Fee__c.setScale(2) : 0 ;
                regiFees = pack.Registration_Fee__c;
                
                Decimal tempUnitFee = pack.Unit_Fee__c;
                Integer prmtnalPkgInMonth = 0;
                //Promotional fees discount calcuation
                if(pack.Is_Promotion_Discount__c && String.isNotBlank(pack.Promotion_period_In_months__c)){ 
                    tempUnitFee         = pack.Package_after_Promotion__r.Unit_Fee__c;
                    pkgFeesPromtnalDis  = pack.Promotion_Discount__c;
                    prmtnalPkgInMonth   = 0;
                    
                    try{
                        prmtnalPkgInMonth   = Integer.valueOf(pack.Promotion_period_In_months__c);
                    }catch(Exception e){}
                }
                 //Registration fees calcuation
                regiFeesDis = (pack.Registration_Discount_Active__c && pack.Registration_Discount_Value__c > 0) ? pack.Registration_Discount_Value__c : 0;
				
                prgFees  = BillingUtility.calculateCurrentMonthPckFees(freeTrailEnr.Lessons_Start_Date__c, tempUnitFee);
                //Promotional fees discount calcuation
                if(pack.Is_Promotion_Discount__c && prmtnalPkgInMonth > 0){
                    prgFees = pack.Package_Fee__c + prgFees;
                }
                
                 //Gst calculation
                Integer gstTaxPer = ConstantsClass.defGST;
                try{
                    gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                }catch(Exception e){}
                
                totAmt = regiFees + prgFees;
                disTot  =  (regiFeesDis + pkgFeesPromtnalDis);
                
                Decimal tempTot = totAmt - disTot;
                gstAmt = (tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0).setScale(2);
                subsTot= (tempTot + gstAmt).setScale(2);
                grandTot = (subsTot + depFees).setScale(2);
                
                
               /* Decimal tempUnitFee = pack.Unit_Fee__c;
                //Promotional fees discount calcuation
                if(pack.Is_Promotion_Discount__c && String.isNotBlank(pack.Promotion_period_In_months__c)){ 
                    tempUnitFee         = pack.Package_after_Promotion__r.Unit_Fee__c;
                    pkgFeesPromtnalDis  = pack.Promotion_Discount__c;
                    prmtnalPkgInMonth   = 0;
                    
                    try{
                        prmtnalPkgInMonth   = Integer.valueOf(pack.Promotion_period_In_months__c);
                    }catch(Exception e){}
                }
                
                regiFees = pack.Registration_Fee__c;
                 //Registration fees calcuation
                regiFeesDis = (pack.Registration_Discount_Active__c && pack.Registration_Discount_Value__c > 0) ? pack.Registration_Discount_Value__c : 0;
                
                
                pkgDuration = pack.Duration__c != null ? Integer.valueOf(pack.Duration__c) : 0;
                prgFees  = BillingUtility.calculateCurrentMonthPckFees(freeTrailEnr.Lessons_Start_Date__c, pack.Unit_Fee__c);  
                
                prgRegFees = regiFees + prgFees;
                //Deducting registration fees
                if(regiFeesDis > 0)
                    prgRegFees = (prgRegFees - regiFeesDis);
                
                //Deducting promotional fees
                if(pkgFeesPromtnalDis > 0)
                    prgRegFees = (prgRegFees - pkgFeesPromtnalDis);
                
                Integer gstTaxPer = ConstantsClass.defGST;
                try{
                    gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                }catch(Exception e){}
                
                gstAmt = prgRegFees > 0 ? ((prgRegFees * gstTaxPer) / 100):0;
                totAmt = prgRegFees + gstAmt + depFees;
                
                prgRegFees = prgRegFees != null ? prgRegFees.setScale(2) : 0;
                depFees = depFees != null? depFees.setScale(2) : 0;
                gstAmt  = gstAmt != null ? gstAmt.setScale(2) : 0;
                totAmt  = totAmt != null ? totAmt.setScale(2) : 0;
				*/
            }
        }
    }
    
    public PageReference completeEnrolment(){
        Savepoint sp;
        isError = false;
        errorMsg = '';
        
        if(stripeToken!=null && stripeToken.trim().length()>0){
            try{
                String cusName = String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName : ' ';
                cusName += parentAcc.LastName;
                BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(stripeToken, cusName, parentAcc.PersonEmail, 'Parent customer');
                
                if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){                    
                    Decimal amountInSmallUnit = grandTot;
                    BillingUtility.stripeCharge sc = BillingUtility.createChargeForCustomer(sCstmr.id,amountInSmallUnit,'sgd');
                    
                    if(sc.statusCode==200){
                        sp = Database.setSavepoint();
                        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();    
                        
                        //Check that customer is already exist or not on the bases of email
                        parentAcc.Stripe_Customer_Id__c = sCstmr.id;
                        update parentAcc;
                        
                        student.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                        update student;
                        
                        freeTrailEnr.Type__c  = 'Regular';
                        freeTrailEnr.Stage__c = ConstantsClass.enroledStatus;
                        update freeTrailEnr;
                        
                        //Inserting subscription
                        Date subTempDt       = System.today().addMonths(1);
                      
                        Subscription__c subs = new Subscription__c();
                        List<Subscription__c> subList = [SELECT Id,Center__c  FROM Subscription__c  
                                                         WHERE Parent__c =:parentAcc.Id AND Center__c =:freeTrailEnr.Center__c 
                                                         AND Status__c =: ConstantsClass.activeStatus];
                        if(subList.size() > 0){
                            subs = subList.get(0);
                        }else{
                            Date subsDt = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                            subs = BillingUtility.fillSubscription(parentAcc.Id, ConstantsClass.activeStatus, subsDt);
                            if(freeTrailEnr.Center__c != null){
                                subs.Center__c = freeTrailEnr.Center__c;
                            }
                            
                            Date subsNextBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);
                            subs.Next_Bill_Date__c  = subsNextBillingDate;
                            
                            if(pkgFeesPromtnalDis > 0 && prmtnalPkgInMonth > 0){
                                 subs.Next_Bill_Date__c = subs.Next_Bill_Date__c.addMonths(prmtnalPkgInMonth); 
                            }
                            
                            insert subs;
                        }
                        
                        //Filling Invoice
                        Invoice__c inv        = BillingUtility.fillInvoice(subs.Id, parentAcc.Id, ConstantsClass.paidStatus);
                        insert inv;
                        
                        //Filling Payment
                        Payment__c pay        = BillingUtility.fillPayment(parentAcc.Id, null, grandTot, ConstantsClass.successStatus);
                        pay.Transaction_ID__c = sc.id; 
                        pay.Invoice__c        = inv.Id;
                        insert pay;
                        
                        Subscription_Line_Item__c subLItm = BillingUtility.fillSubscriptionLineItem(null, subs.Id, freeTrailEnr.Package__c, null, packFees, ConstantsClass.activeStatus);
                        subLItm.Student__c   = student.Id;
                        subLItm.Enrolment__c = freeTrailEnr.Id;
                         //Filling subscription line item billing date for the enrolment
                        Date subsDt = Date.newInstance(subTempDt.year(), subTempDt.month(), 1);
                        
                        Date subsNextBillingDate = Date.newInstance(subTempDt.year(), subTempDt.month(), ConstantsClass.subNextBillingDay);
                        subLItm.Next_Bill_Date__c   = subsNextBillingDate;
                        if(pkgFeesPromtnalDis > 0 && prmtnalPkgInMonth > 0){
                            subLItm.Next_Bill_Date__c = subLItm.Next_Bill_Date__c.addMonths(prmtnalPkgInMonth); 
                        }
                        
                        insert subLItm;
                        //subLinItmList.add(subLItm);
                        
                        List<Invoice_Line_Item__c> invLineItmList     = new List<Invoice_Line_Item__c>();
                        //Filling Invoice Line items
                        if(prgRegFees> 0){
                            String remStr = ConstantsClass.pkgPrgFeesDes;
                            
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, prgRegFees, remStr);
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = freeTrailEnr.Id;
                            invLnItm.Subscription_Line_Item__c = subLItm.Id;
                            invLnItm.Package__c   = freeTrailEnr.Package__c;
                            if(pkgFeesPromtnalDis > 0)
                                invLnItm.Discount_Amount__c = pkgFeesPromtnalDis; 
                            invLineItmList.add(invLnItm);
                        }
                        if(regiFees> 0){
                            String remStr = ConstantsClass.pkgRegFeesDes;
                            
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, regiFees, remStr);
                            invLnItm.Invoice__c   = inv.Id;
                            invLnItm.Enrolment__c = freeTrailEnr.Id;
                            invLnItm.Package__c   = freeTrailEnr.Package__c;
                            invLnItm.Subscription_Line_Item__c = subLItm.Id;
                            if(regiFeesDis> 0)
                                invLnItm.Discount_Amount__c = regiFeesDis; 
                            invLineItmList.add(invLnItm);
                        }
                        if(depFees > 0){
                            String remStr = ConstantsClass.pkgDepFeesDes;
                            
                            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, depFees, remStr);
                            invLnItm.Invoice__c    = inv.Id;
                            invLnItm.Enrolment__c  = freeTrailEnr.Id;
                            invLnItm.Subscription_Line_Item__c = subLItm.Id;
                            invLnItm.Package__c    = freeTrailEnr.Package__c;
                            invLnItm.Is_Deposit__c = true;
                            invLineItmList.add(invLnItm);
                        }
                        
                        if(invLineItmList.size() > 0)
                            insert invLineItmList;
                        
                        Date lsStDate = freeTrailEnr.Lessons_Start_Date__c;
                        Integer numberOfDays = Date.daysInMonth(lsStDate.year(), lsStDate.month());
                        Date  lastDayOfEndDateMonth = Date.newInstance(lsStDate.year(), lsStDate.month(), numberOfDays);
                        
                        List<Booking__c> bookList = [SELECT Id, Type__c, Status__c, Booking_Date__c 
                                                     FROM Booking__c WHERE Enrolment__c =: freeTrailEnr.Id AND  
                                                     	  Booking_Date__c <=: subLItm.Next_Bill_Date__c AND  Type__c !=: ConstantsClass.typeTrial];
                        for(Booking__c book : bookList)
                            book.Status__c = ConstantsClass.scheduledStatus;
                        
                        update bookList;
                        
                        if(base64SignImg !=null && base64SignImg.trim().length() > 0){
                            List<Attachment> attListForSign = new List<Attachment>();
                            base64SignImg = base64SignImg.replace('data:image/png;base64,','');

                            Attachment att = new Attachment();
                            att.Name       = ConstantsClass.defAttSignName;
                            att.parentId   = freeTrailEnr.Id;
                            att.body       = EncodingUtil.base64Decode(base64SignImg);
                            attListForSign.add(att);
                          
                            if(attListForSign.size() > 0)
                                insert attListForSign;
                        }
                        
                        //Update invoice number on Stripe
                        /*List<Invoice__c> invList = [SELECT Id,Name FROM Invoice__c WHERE Id =: inv.Id];
                        if(invList.size() > 0)
                            BillingUtility.updateCharge(sc.id, invList.get(0).Name);
                        */
                        return new pagereference('/apex/Thankyoupage?type=Enrolment&invId='+inv.Id+'&scId='+sc.id).setRedirect(true);    
                    }else{
                        errorMsg = sc.error.message;
                        isError = true;
                    }
                }else{
                    errorMsg = sCstmr.error.message;
                    isError = true;
                }
            }catch(Exception e){
                Database.rollback(sp);
                
                System.debug('Error:  '+e.getMessage());
                errorMsg = e.getMessage();
                isError  = true;
                return null;
            }
        }else{
             errorMsg = 'Some problem with your card. Please try again.';
             isError = true;
        }
        
        return null;
    }
    
    private Static Booking__c fillBook(Id stdntId, Id cenId, Id techId, Id pckgId, String recTypeId, Id enrlId, String status, Date bookDate, Time bookTime, Integer pkgDuration){
        Booking__c book   = new Booking__c(Student__c = stdntId, Teacher_Account__c = techId, Enrolment__c = enrlId);
        book.RecordTypeId = recTypeId;
        book.Package__c   = pckgId;
        book.Center__c    = cenId;
        book.Type__c      = ConstantsClass.bookTypeRegular;
        book.Status__c    = status;     
        book.Booking_Date__c = bookDate;
        
        if(bookTime != null && pkgDuration > 0){
            book.Start_Time__c = bookTime;
            book.End_Time__c = book.Start_Time__c.addMinutes(pkgDuration);
        }
        return book;
    }
    
}