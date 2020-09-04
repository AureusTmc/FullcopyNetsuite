public class EnrolmentProcessStep1Cntrl {
    public List<EnrolmentModel> enrModList{get;set;}    
    public String userEmail{get;set;}	
    
    public Boolean isError{get;set;}
    public String  isErrMsg{get;set;}
    public EnrolmentProcessStep1Cntrl(){
        enrModList = new List<EnrolmentModel>();
        isError    = false;
    }
    
    public void fetchEnrolments(){
        isError    = false;
        isErrMsg   = '';
        if(String.isNotBlank(userEmail)){
            String type = ConstantsClass.typeTrial;
            Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended};
            
            enrModList = new List<EnrolmentModel>();
            List<Enrolment__c> enrList = [SELECT Id, Name, Package__r.Name, Student__r.Name, Teacher__r.Name, Parent__r.Name, Parent__r.PersonEmail, Trial_Date__c 
                               			  FROM Enrolment__c 
                               			  WHERE Parent__r.PersonEmail =:userEmail AND Type__c =:type  AND Stage__c IN:stgList AND Package__r.Active__c = true];
            if(enrList.size() > 0){
            	for(Enrolment__c enr: enrList){
            		enrModList.add(new EnrolmentModel(enr.Id, enr.Name, enr.Student__r.Name, enr.Teacher__r.Name, enr.Package__r.Name, enr.Trial_Date__c));
        		}        
            }else{
                isError    = true;
        		isErrMsg   = 'No Enrolments found with this username.';
            }
        }else{
            isError    = true;
        	isErrMsg   = 'Please enter the useremail.';
        }
    }
    
    public PageReference completeEnrolments(){
        isError    = false;
        isErrMsg   = '';
        
        PageReference pageRef;
        
        String userName = UserInfo.getUserName();
        if(userName.contains('site')){
            pageRef = new PageReference('/enrolmentprocess');
        }else{
            pageRef = new PageReference('/apex/enrolmentprocess');
        } 
        pageRef.setRedirect(true);
        
        Integer counter = 1;
        for(EnrolmentModel enr: enrModList){
            if(enr.isCheck){
            	String enrlStr = 'enr'+counter;
        		pageRef.getParameters().put(enrlStr, enr.enrId);    
            
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
    
    public class EnrolmentModel{
        public Boolean isCheck{get;set;}
        public String  enrId{get;set;}
        public String  enrName{get;set;}
        public String  stuName{get;set;}
        public String  tchrName{get;set;}
        public String  pckgName{get;set;}
        public Date    pckgTrialDate{get;set;}
        
        public EnrolmentModel(String enrId, String enrName, String stuName, String tchrName, String pckgName, Date   pckgTrialDate){
        	this.isCheck       = false;
            this.enrId		   = enrId;
            this.enrName 	   = enrName;	
            this.stuName 	   = stuName;
            this.tchrName 	   = tchrName;
            this.pckgName      = pckgName;
            this.pckgTrialDate = pckgTrialDate;
        }
    }
}