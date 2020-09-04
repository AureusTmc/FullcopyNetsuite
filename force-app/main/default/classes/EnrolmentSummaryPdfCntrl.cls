public class EnrolmentSummaryPdfCntrl {
    public Account parAcc{get;set;}
    public List<LessonWrapper> stuWrapList{get;set;}
    public Invoice__c inv{get;set;}
    public GrandTotalWrapper grndTotModel{get;set;}
    
    //Cancellation policy form variables
    public Date dt{get;set;}
    public String parName{get;set;}
    public String attId{get;set;}
    
    //Added by Rajesh, 14th july 2019, for check that parent is American club member of not
    public Boolean isAmcClubMember{get;set;}
    public EnrolmentSummaryPdfCntrl(){
        parAcc = new Account();
        stuWrapList = new List<LessonWrapper>();
        inv     	 = new Invoice__c();
        grndTotModel = new GrandTotalWrapper();
        dt = System.today();
        
        //Added by Rajesh, 14th July 2019, set defaut value as false
        isAmcClubMember  = false;
        
        string invId = Apexpages.currentPage().getParameters().get('Id');
        if(String.isNotBlank(invId))
            fillData(invId);
    }
    
    public void fillData(String invId){
        List<Invoice__c> invList = [Select Id,Name,Due_Date__c,GST_Tax__c,GST_Tax_Amount__c,Invoice_Date__c,Parent_Account__c, Parent_Account__r.Name, 
                                    		Status__c,Sub_Total__c,Subscription__c,Total_Amount__c,
                                            (Select Id, Amount__c, Subscription_Line_Item__c, Package_Name__c, Remarks__c, Opportunity__c, Student__c, 
                                             Enrolment__c, Subscription_Line_Item__r.Enrolment__c, Discount_Amount__c
                                             from Invoice_Line_Items__r) 
                                    FROM Invoice__c 
                                    WHERE Id=:invId LIMIT 1]; 
        if(invList.size() > 0){
            inv = invList.get(0);
            
            if(inv.Parent_Account__c != null){
                parAcc = [SELECT Id, Name, personMobilePhone, BillingPostalcode, personEmail, Billingstreet, BillingCity , BillingCountry, Is_Club_Member__c, Membership_Type__c 
                          FROM Account WHERE Id =: inv.Parent_Account__c LIMIT 1];
      			
                //Added by Rajesh, 11th July 2019, for check that parent is American club member of not
                if(parAcc.Is_Club_Member__c && parAcc.Membership_Type__c == ConstantsClass.amcClubMember)
                    isAmcClubMember = true;
                
                Set<String> enrIds = new Set<String>();
                Map<String, Decimal> enrFeeMap = new Map<String, Decimal>();
                Map<String, Decimal> enrFeeDisMap = new Map<String, Decimal>();
                for(Invoice_Line_Item__c inLine: inv.Invoice_Line_Items__r){
                    String enrId = inLine.Enrolment__c != null ? inLine.Enrolment__c : inLine.Subscription_Line_Item__r.Enrolment__c; 
                    enrIds.add(enrId);
                    
					String key = inLine.Enrolment__c+'#'+inLine.Remarks__c; 
                    
                    //Fee Amount 
                    if(inLine.Amount__c  > 0){
                        Decimal tmpAmt = enrFeeMap.containsKey(key) ? enrFeeMap.get(key) : 0;
                        tmpAmt += inLine.Amount__c;
                        enrFeeMap.put(key, tmpAmt);
                    }
                    //Fee Discount Amount 
                    if(inLine.Discount_Amount__c  > 0){
                        Decimal tmpDisAmt = enrFeeDisMap.containsKey(key) ? enrFeeDisMap.get(key) : 0;
                        tmpDisAmt += inLine.Discount_Amount__c;
                        enrFeeDisMap.put(key, tmpDisAmt);
                    }
                }
                
                if(enrIds.size() > 0){
                    for(Enrolment__c enr  : [SELECT Id, Student__c, Student__r.Name, Center__r.Name, Teacher__r.Name, Package__c, 
                                             		Package__r.Name, Lessons_Start_Date__c, Lesson_Start_Time__c
                                             FROM Enrolment__c
                                             WHERE Id IN: enrIds]){
                                                 
                    	LessonWrapper stuWrap = new LessonWrapper();                
                        stuWrap.stuEnrDetail  = enr;
                        stuWrap.lessonSlctSlotT = DateTime.newInstance(enr.Lessons_Start_Date__c, enr.Lesson_Start_Time__c).format('hh:mm a');    
                        
                        String key = enr.Id+'#'+ConstantsClass.pkgPrgFeesDes;                      
                        if(enrFeeMap.containsKey(key)){
                        	//Invoice_Line_Item__c invLn = enrFeeMap.get(key);    
                            stuWrap.selPckMonthFees= enrFeeMap.get(key);
                            if(enrFeeDisMap.get(key) > 0)
                                stuWrap.pkgFeesPromtnalDis = enrFeeDisMap.get(key);
                        }
                        
                        key = enr.Id+'#'+ConstantsClass.pkgRegFeesDes;                          
                        if(enrFeeMap.containsKey(key)){
                        	//Invoice_Line_Item__c invLn = enrFeeMap.get(key);    
                            stuWrap.regiFees = enrFeeMap.get(key);
                            if(enrFeeDisMap.get(key) > 0)
                                stuWrap.regiFeesDis = enrFeeDisMap.get(key);
                        }
                        
                        key = enr.Id+'#'+ConstantsClass.pkgDepFeesDes;                          
                        if(enrFeeMap.containsKey(key)){
                        	//Invoice_Line_Item__c invLn = enrFeeMap.get(key);    
                            stuWrap.depFees        = enrFeeMap.get(key);
                        }   
                                                 
                        stuWrapList.add(stuWrap);
                        
                        Decimal totTemp = stuWrap.regiFees + stuWrap.selPckMonthFees;                         
                        //Grand Total calcuation
                        grndTotModel.feesTot += totTemp;
                        grndTotModel.disTot  += (stuWrap.pkgFeesPromtnalDis + stuWrap.regiFeesDis);
                        grndTotModel.depositTot += stuWrap.depFees;
                                                 
                        //Gst calculation
                        Integer gstTaxPer = ConstantsClass.defGST;
                        try{
                            gstTaxPer = Integer.valueOf(Label.GST_Tax_Rate);
                        }catch(Exception e){}     
                                                 
                        Decimal tempTot = grndTotModel.feesTot - grndTotModel.disTot;
                        grndTotModel.gstTot = tempTot > 0 ? ((tempTot * gstTaxPer) / 100):0;        
                        
                        grndTotModel.disTot   = grndTotModel.disTot.setScale(2);
                        grndTotModel.feesTot  = grndTotModel.feesTot.setScale(2);
                        grndTotModel.gstTot   = grndTotModel.gstTot.setScale(2);
                        grndTotModel.depositTot = grndTotModel.depositTot.setScale(2);
                        grndTotModel.subsTot  = (grndTotModel.feesTot + grndTotModel.gstTot -(grndTotModel.disTot)).setScale(2);
                        grndTotModel.grandTot = (grndTotModel.subsTot + grndTotModel.depositTot).setScale(2);                         
                    }
                }
                
                //Filling cancellation policy form data
                parName = inv.Parent_Account__r.Name;
                if(inv.Invoice_Line_Items__r.size() > 0){
                    Invoice_Line_Item__c invLItem = inv.Invoice_Line_Items__r.get(0);
                    
                    String enrId = invLItem.Enrolment__c != null ? invLItem.Enrolment__c :  invLItem.Subscription_Line_Item__r.Enrolment__c;
                    
                    String parSignAttName = '%'+ConstantsClass.defAttSignName+'%';
                    List<Attachment> attList = [SELECT Id,Name FROM Attachment WHERE ParentId =: enrId AND Name LIKE:parSignAttName LIMIT 1];
                    if(attList.size() > 0)
                        attId = attList.get(0).Id;
                }
            }       
        }
    }
    
    

    
    public class LessonWrapper{
        public Enrolment__c stuEnrDetail{get;set;}
        public String lessonSlctSlotT{get;set;}
        
        //Fee calculation variables
        public Decimal selPckMonthFees{get;set;}
        public Decimal regiFees{get;set;}
        public Decimal depFees{get;set;}
        
        Decimal pkgFeesPromtnalDis;
        Decimal regiFeesDis;        
        public LessonWrapper(){
            stuEnrDetail = new Enrolment__C();
            
            //---------Fee intialisation
            selPckMonthFees = depFees = regiFees = regiFeesDis = pkgFeesPromtnalDis =  0;
        }
    }
    
    public class GrandTotalWrapper{
        public Decimal disTot{get;set;}
        public Decimal feesTot{get;set;}
        public Decimal gstTot{get;set;}
        public Decimal subsTot{get;set;}
        public Decimal depositTot{get;set;}
        public Decimal grandTot{get;set;}
        
        public GrandTotalWrapper(){
            disTot = feesTot = gstTot = subsTot =depositTot = grandTot = 0;
        }
    }
}