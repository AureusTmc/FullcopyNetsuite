public class searchTrialIpadCntrl {
    public String slcdCenter{get;set;}
    public String slcdEnrIds{get;set;}
    Public Date GetToday{get;set;}
    
    public list<Centre_Users__c> centerName {get;set;}
    
    public Boolean isError{get;set;}
    public String  isErrMsg{get;set;}
        
    public String countryCode{get;set;}
    string enrolmentOrg;//@Juneid 18 Aug 2020, This is use for store enrolment organization
    public String orgType{get;set;}//@Juneid 19 Aug 2020, Storing currebt org name
    //public static
    public searchTrialIpadCntrl(){
        //system.debug('slcdCenter'+slcdCenter);
        centerName= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.Organisation__c,Centre_Name__r.Organisation__r.name from Centre_Users__c where User_Name__c=:UserInfo.getUserId()]);
        slcdCenter=centerName[0].Centre_Name__c;
        enrolmentOrg = centerName[0].Centre_Name__r.Organisation__c;//@Juneid 18 Aug,2020, Getting currentv user's Organization
        system.debug('organization--->'+enrolmentOrg);
        //@Juneid 19 Aug,2020 Checking Organization for Ossia and Aureus
        if(String.isNotBlank(centerName[0].Centre_Name__r.Organisation__r.name))
            if(centerName[0].Centre_Name__r.Organisation__r.name == Label.Ossia_Organisation_Name)
            orgType = 'ossia';
        else 
            orgType ='aureus';
        
        GetToday=system.today();
        countryCode	 = ApexPages.currentPage().getParameters().get('country');
        slcdEnrIds   = '';
        if(String.isBlank(countryCode))
            countryCode = 'SG';
    }	
    
    public list<SelectOption> getCenters(){
        system.debug('enrId--->'+slcdEnrIds.split(','));
        list<SelectOption> options = new list<SelectOption>();
                
        String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        options.add(new SelectOption('','Please select')); 
        system.debug('cenRecId--->'+cenRecId);
        system.debug('countryCode--->'+countryCode);
        system.debug('enrolmentOrg--->'+enrolmentOrg);
        //@Juneid 18 Aug 2020, Added centre filter logic for Orgnaization wise
        for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                          WHERE (RecordtypeId =: cenRecId AND CentreName_Cust__c != null) AND (Country__r.Name =:countryCode AND Organisation__c =:enrolmentOrg) ORDER BY CentreName_Cust__c]){
                              system.debug('----'+acc);
            options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
        }
        
        return options;
    }
    
    public list <EnrolmentModel> getEnrolments() {
        List<EnrolmentModel> enrList = new List<EnrolmentModel>(); 
        //String type = ConstantsClass.typeTrial;
        Set<String> typeSet = new Set<String>{ConstantsClass.typeTrial, 'Group'};
        Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment};
        if(String.isNotBlank(slcdCenter)){
            for(Enrolment__c enr: [SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Student__r.Name,
                                      		 Teacher__c, Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c,
                                      		 Center__c, Center__r.Name 
                                      FROM Enrolment__c 
                                      WHERE Parent__r.Personemail != null AND Type__c IN:typeSet  AND Stage__c IN:stgList 
                                   	  AND Center__c=:slcdCenter and Trial_Date__c=:GetToday]){
                                        system.debug('----'+enr);  
                String tempTSlot = DateTime.newInstance(enr.Trial_Date__c, enr.Trial_Start_Time__c).format('hh:mm a');                          
             	enrList.add(new EnrolmentModel(enr, tempTSlot));
             }
        }
        
        return enrList;
    }
    
    @RemoteAction
    public static list <EnrolmentModel> fetchEnrolments(String srchKey, String cntryCode) {
        
        List<EnrolmentModel> enrList = new List<EnrolmentModel>(); 
        //String type = ConstantsClass.typeTrial;
        Set<String> typeSet = new Set<String>{ConstantsClass.typeTrial, 'Group'};
        Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment};
        system.debug('======------>'+srchKey);
        if(String.isNotBlank(srchKey)){
            String tempSerch = srchKey + '%';
            system.debug('=====>'+tempSerch);
            String str = 'SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c, Student__r.Name,Teacher__c, '+
                				 'Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, Trial_Start_Time__c,Center__c, Center__r.Name  '+
                		 'FROM Enrolment__c WHERE Center__r.Country__r.Name =:cntryCode AND Parent__r.Personemail != null AND Student__c != null AND '+
                		 	  'Student__r.Name != null AND Stage__c IN:stgList AND Type__c IN:typeSet AND (Name like: tempSerch OR Parent__r.Name like: tempSerch OR '+
                		 	  'Student__r.Name like: tempSerch OR Parent__r.PersonEmail like: tempSerch OR Parent__r.Phone like: tempSerch )';  
            System.debug('@str@@@'+str);
            List<Enrolment__c> enrListing= database.query(str);
            
            //System.debug('@str@@@'+enrListing.size());
            for(Enrolment__c enr:enrListing){
                String tempTSlot;
                system.debug('---->'+enr);
                if(enr.Trial_Date__c != null){
                   tempTSlot = DateTime.newInstance(enr.Trial_Date__c, enr.Trial_Start_Time__c).format('hh:mm a');   
                } 
                enr.Parent_Email__c = enr.Parent__r.Personemail;
                enrList.add(new EnrolmentModel(enr, tempTSlot));  
            }
        }
        system.debug('enrList---'+enrList.size());
        return enrList;
    }
    /* Nishi: 5-Feb-2021:Start: Aureus Q1 2021: Clicking on New customer  button then we open a new page to capture the Parent and Student details.*/
	public PageReference directCreateNewEnrolment(){
        return new PageReference('/apex/createDirectEnrolmentPage?'+'currentOrg='+enrolmentOrg+'&'+'orgType='+orgType+'&'+'slcdCenter='+slcdCenter+'&'+'countryCode='+countryCode);
    }
     /* Nishi: 5-Feb-2021:end: Aureus Q1 2021: Clicking on New customer  button then we open a new page to capture the Parent and Student details.*/
	
    public PageReference redirectToEnrolment(){
        isError    = false;
        isErrMsg   = '';
        
        PageReference pageRef;
        
        String userName = UserInfo.getUserName();
        if(userName.contains('site')){
            pageRef = new PageReference('/enrolmentprocess_ipad');
        }else{
            pageRef = new PageReference('/apex/enrolmentprocess_ipad?'+'currentOrg='+enrolmentOrg+'&'+'orgType='+orgType);
        } 
        pageRef.setRedirect(true);
        
        Integer counter = 1;
        for(String enrId: slcdEnrIds.split(',')){
            if(String.isNotBlank(enrId)){
            	String enrlStr = 'enr'+counter;
        		pageRef.getParameters().put(enrlStr, enrId);    
            
                counter = counter+1;
            }
        }
        if(counter > 1){
        	 return pageRef;
        }else{
            isError    = true;
        	isErrMsg   = 'Please select atleast 1 enrolment.';
        }
        return null;
    }
    
    public void addDate(){
       GetToday= GetToday.addDays(1);
        getEnrolments();
       // return GetToday;
    }
    public void subDate(){
       GetToday= GetToday.addDays(-1);
        getEnrolments();
       // return GetToday;
    }
    
    public class EnrolmentModel{
        public Enrolment__c enr{get;set;}
        public String enrTrialSlot{get;set;}
        
        public EnrolmentModel(Enrolment__c enr, String enrTrialSlot){
            this.enr = enr;
            this.enrTrialSlot = enrTrialSlot;
        }
    }
}