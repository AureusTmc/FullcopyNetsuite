public with sharing class createDirectEnrolmentCtrl {
    public String slcdCenter{get;set;}
    public String slcdCentrName{get;set;}
    public String slcdNoOfStudent{get;set;}
    //Variables according to ipad page
    public List<TrialEnrModel> enrModelList{get;set;}
    public String countryCode{get;set;}
    
    public Integer slcdStuIndex{get;set;}
    public Account parentAcc{get;set;}
    public Boolean isParAlsoAStudent{get;set;}
  
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    public Boolean iWantReceivedLatestNew{get;set;}
    public String  slcdExistingStu{get;set;}
    public Boolean isSiteGuestUser{get;set;}
    public string PersonMobilePhoneCustom{get;set;}  
    public Boolean isPageInMobile{get;set;}
    public String  orgType{get;set;}
    public String org{get;set;}// this variable is used to store organization type 
    
    string organization;    
    //To store trial source on case object and country for filtercentre
    String trialSource;
    public createDirectEnrolmentCtrl(){
        enrModelList = new List<TrialEnrModel>(); 
        parentAcc = new Account();
        isParAlsoAStudent = false;
        iWantReceivedLatestNew = false;
        isSiteGuestUser = (UserInfo.getName()).contains('Site');
        PersonMobilePhoneCustom = '';
        org = ApexPages.currentPage().getParameters().get('currentOrg');   
        countryCode = ApexPages.currentPage().getParameters().get('countryCode');   
        orgType = ApexPages.currentPage().getParameters().get('orgType');  
        slcdCenter = ApexPages.currentPage().getParameters().get('slcdCenter');   
        if(string.isNotBlank(slcdCenter)){
            slcdCentrName = [select name from account where id=:slcdCenter].name;
        }
        enrModelList.add(new TrialEnrModel()); 
    }

    public PageReference backBtnCmp4(){
        return new PageReference('/apex/searchtrial_ipad?country='+countryCode);
    }

    public PageReference nextBtnCmp4(){
        //return page.freetrial_ipad5;
        //existingStuMap
        System.debug('@@@@'+PersonMobilePhoneCustom);
        parentAcc.phone = PersonMobilePhoneCustom;
        Set<String> genderSet = new Set<String>();
        Set<Date>   dobSet    = new Set<Date>();
        for(TrialEnrModel trMd : enrModelList){
            trMd.existingStuOpt = new Map<String,String>();
            trMd.slcdExistingStu = '';
            //Fill Student Details
            Account studentAcc = trMd.studentAcc; 
            if(studentAcc.Gender__c != null)
                genderSet.add(studentAcc.Gender__c);
            if(studentAcc.PersonBirthdate != null)
                dobSet.add(studentAcc.PersonBirthdate);
        }
        
        if(isParAlsoAStudent && enrModelList.size()>0){
            enrModelList.get(0).isParAlsoAStudent =isParAlsoAStudent;
            enrModelList.get(0).studentAcc.FirstName = parentAcc.FirstName;
            enrModelList.get(0).studentAcc.LastName  = parentAcc.LastName;            
        }
        
        if(enrModelList.size()>1 && enrModelList.get(1).stuSameAsChild1){
            enrModelList.get(1).studentAcc = enrModelList.get(0).studentAcc;
            enrModelList.get(1).stuPreExperience = enrModelList.get(0).stuPreExperience;
        }
        
        Boolean skipExistingStuPage = true;
        if(genderSet.size() > 0 && dobSet.size() > 0){
            Map<String, List<Account>> stuMap = new Map<String, List<Account>>();
            for(Account ac: [SELECT Id,Name,Parent__r.PersonEmail,PersonBirthdate,Gender__c FROM Account WHERE Gender__c IN:genderSet AND  
                             PersonBirthdate IN: dobSet AND
                             Parent__r.PersonEmail =: parentAcc.PersonEmail]){
                                 
                                 String key = ac.PersonBirthdate+':'+ac.Gender__c;  
                                 List<Account>  tList = stuMap.containsKey(key) ? stuMap.get(key) : new List<Account>();    
                                 tList.add(ac);                     
                                 stuMap.put(key, tList);                     
                             }
            if(stuMap.size() > 0){
                for(TrialEnrModel trMd : enrModelList){
                    Account studentAcc = trMd.studentAcc; 
                    String key = studentAcc.PersonBirthdate+':'+studentAcc.Gender__c;  
                    if(stuMap.containsKey(key)){
                        for(Account ac : stuMap.get(key)){
                            trMd.existingStuOpt.put(ac.Id,ac.Name);
                            System.debug('@@@'+ac);
                        }
                        
                        trMd.existingStuOpt.put('new','Create new student');
                        skipExistingStuPage = false;
                        
                    }
                }
            }
        }
        return saveTrialData();
    }

    public Pagereference saveTrialData(){
        PageReference pageRef;
        Savepoint sp = Database.setSavepoint();
        List<Account> refRelAccount = new List<Account>();
        Boolean isExisting = true;
        isError = false;
        errorMsg = '';
        try{
            String csmrRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(); 
        //Fill Parent and Upasert parent record
        parentAcc.RecordTypeId   = csmrRecId;
        // added by nishi: 28-Sep-2020: for stop active process builer validations 
        if(!test.isRunningTest()){
            parentAcc.Centre_Name__c = slcdCenter;
        }
         // added by nishi: 28-Sep-2020: for stop process builer 
        List<Account> centrList  = [SELECT Id, Name, Location__c,Organisation__c, Country__r.name,Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
        if(centrList.size() > 0){
                parentAcc.Location__c = centrList.get(0).Location__c;
                //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                if(centrList.get(0).Country__r.Country_Name__c != null)
                    parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
            }
            //Check that customer is already exist or not on the bases of email
            if(parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name FROM Account
                                         WHERE PersonEmail =: parentAcc.PersonEmail 
                                        //And Centre_Name__r.Organisation__c =: centrList.get(0).Organisation__c // Added by nishi: 30-nov-2020: for Change customer key from email address to email address+Organisation name
                                        ]; 
                if(accList.size() > 0){
                    parentAcc.Id = accList.get(0).Id;
                }
            }
            if(isParAlsoAStudent){
                Account stuAcc = enrModelList.get(0).studentAcc;
                parentAcc.Also_a_Student__c = true;
                parentAcc.PersonBirthdate   = stuAcc.PersonBirthdate;
                parentAcc.Learning_Style__c = stuAcc.Learning_Style__c;
                parentAcc.Description       = stuAcc.Description;
                parentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                parentAcc.Gender__c = stuAcc.Gender__c;
            }
            parentAcc.PersonMobilePhone = parentAcc.Phone;
            upsert parentAcc;
            List<Account> stuList = new List<Account>();
            List<Enrolment__c> enrList = new List<Enrolment__c>();
            for(TrialEnrModel trMd : enrModelList){
                //Fill Student Details
                Account studentAcc = trMd.studentAcc;  
                system.debug('studentAcc'+studentAcc);
                studentAcc.RecordTypeId   = csmrRecId;
                system.debug('trMd.isParAlsoAStudent'+trMd.isParAlsoAStudent);  
                If(trMd.stuSameAsChild1){
                    studentAcc = stuList.get(0);
                }else{
                    if(!trMd.isParAlsoAStudent){
                        //To find existing student for the sepecific parent
                        if(String.isNotBlank(trMd.slcdExistingStu) && !trMd.slcdExistingStu.equalsIgnoreCase('new'))
                            studentAcc.Id = trMd.slcdExistingStu;                        
                            studentAcc.Parent__c = parentAcc.Id;
                            studentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;   
                            if(!test.isRunningTest()){
                                studentAcc.Centre_Name__c = slcdCenter;
                            }
                            if(centrList.size() > 0){
                                studentAcc.Location__c = centrList.get(0).Location__c;
                                if(centrList.get(0).Country__r.Country_Name__c != null)
                                    studentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                            }   
                        stuList.add(studentAcc);  
                    }else{
                        studentAcc = parentAcc;
                    }   
                } 
                //Fill Enrolment details
                Enrolment__c enrl  = new Enrolment__c();
                enrl.Parent__c     = parentAcc.Id;
                enrl.Learning_Style__c = studentAcc.Learning_Style__c;
                enrl.Student__r    = studentAcc;
                enrl.Type__c       = ConstantsClass.typeTrial;
                enrl.Stage__c      = ConstantsClass.enrollStageAttended;
                //enrl.Trial_Date__c = system.today();                    
                //Filling start time
                //enrl.Trial_Start_Time__c = system.now().time();
                
                 // added by nishi: 28-Sep-2020: for stop active process builer validations
                if(!test.isRunningTest()){
                    enrl.Center__c     = slcdCenter;
                }
                enrl.Previous_Experience_if_any__c  = trMd.stuPreExperience;
                enrl.Cancellation_Policy_Agreed__c  = true;
                enrl.I_want_to_receive_latest_newsletter__c = iWantReceivedLatestNew;
                enrList.add(enrl);
            }
            
            if(stuList.size() > 0){
                system.debug('stuList'+stuList);
                upsert stuList;
            }
            system.debug('enrList'+enrList);
            for(Enrolment__c enrl: enrList)
                enrl.Student__c = enrl.Student__r.Id;
            
            insert enrList;
            String userName = UserInfo.getUserName();
            if(userName.contains('site')){
                pageRef = new PageReference('/enrolmentprocess_ipad');
            }else{
                pageRef = new PageReference('/apex/enrolmentprocess_ipad?'+'currentOrg='+org+'&'+'orgType='+orgType+'&'+'pagetype=directEnrolment');
            } 
            pageRef.setRedirect(true);
            
            Integer counter = 1;
            for(Enrolment__c objenr: enrList){
                if(String.isNotBlank(objenr.id)){
                    String enrlStr = 'enr'+counter;
                    pageRef.getParameters().put(enrlStr, objenr.id);    
                
                    counter = counter+1;
                }
            }
            if(counter > 1){
                return pageRef;
            }else{
                isError    = true;
                errorMsg   = 'Please select atleast 1 enrolment.';
            } 
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            System.debug('Error:  '+e.getStackTraceString() +e.getLineNumber());
            errorMsg = e.getMessage();
            isError = true;
        }
        return pageRef;
    }
    public Class TrialEnrModel{
        public Integer slcdDuration{get;set;}
        public Date    calStartDate{get;set;}
        public Date    calEndDate{get;set;}
        public Account studentAcc{get;set;}
        public String  stuPreExperience{get;set;}
        public String slcdExistingStu{get;set;}
        public Map<String,String> existingStuOpt{get;set;}
        public Boolean stuSameAsChild1{get;set;}
        public Boolean isParAlsoAStudent{get;set;}
        public String  slcdLsnType{get;set;}
        public TrialEnrModel(){
            this.slcdDuration   = 30;
            this.calStartDate   = System.today();
            this.calEndDate     = calStartDate.addDays(6);
            this.existingStuOpt = new Map<String,String>();
            this.studentAcc     = new Account();
            this.stuSameAsChild1= false;
            this.isParAlsoAStudent= false;
            this.slcdLsnType    = 'Individual';
        }
    }
}
