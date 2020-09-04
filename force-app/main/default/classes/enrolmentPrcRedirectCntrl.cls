public class enrolmentPrcRedirectCntrl {
    
    public PageReference redirectToAntoher(){
        PageReference pageRef;
        String usrEmail = ApexPages.currentPage().getParameters().get('userEmail');
        
        if(String.isNotBlank(usrEmail)){
            String type = ConstantsClass.typeTrial;
            Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended, 'Pending Enrolment'};
                
            List<Enrolment__c> enrList = [SELECT Id, Name, Package__r.Name, Student__r.Name, Teacher__r.Name, Parent__r.Name, Parent__r.PersonEmail, Trial_Date__c, Stage__c 
                               			  FROM Enrolment__c 
                               			  WHERE Parent__r.PersonEmail =:usrEmail AND Type__c =:type  AND Stage__c IN:stgList AND Package__r.Active__c = true];
            
            Boolean isTrialAttend = false;
            for(Enrolment__c enr : enrList){
                if(enr.Stage__c == ConstantsClass.enrollStageAttended){
                    isTrialAttend = true;
                    break;
                }
            }
            
            String userName = UserInfo.getUserName();
            String pgName   = '';
            if(!userName.contains('site')){
                pgName = '/apex';
            } 
            
            if(isTrialAttend){
                pgName += '/enrolmentprocess_ipad';
            }else{
                pgName += '/EnrolmentProcessForClass'; 
            }
            pageRef = new PageReference(pgName);
            
			Integer counter = 1;
            for(Enrolment__c enr: enrList){
                String enrlStr = 'enr'+counter;
                pageRef.getParameters().put(enrlStr, enr.Id);    
                
                counter = counter+1;            
            }           
            
            if(counter > 1){
        		return pageRef;
            }else{
            	return null;                
            }
           
        }
        
        return null;
    }
}