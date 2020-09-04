public class EnrolmentEmailProcessCntrl {
	
    public PageReference redirectToEnrolment(){
        String userEmail = ApexPages.currentPage().getParameters().get('email');
        String enrolmentSource = ApexPages.currentPage().getParameters().get('es');
        String countryCode = ApexPages.currentPage().getParameters().get('country');
        
        PageReference pageRef;
            
        String userName = UserInfo.getUserName();
        if(userName.contains('site')){
            //Updated by Rajesh: 16th Sep 2019: to redirect on new enrolmentprocess
            //pageRef = new PageReference('/enrolmentprocess');
            pageRef = new PageReference('/enrolmentprocess_ipad');
        }else{
            //Updated by Rajesh: 16th Sep 2019: to redirect on new enrolmentprocess
            //pageRef = new PageReference('/apex/enrolmentprocess');
            pageRef = new PageReference('/apex/enrolmentprocess_ipad');
        } 
        
        if(String.isNotBlank(userEmail)){
            pageRef.setRedirect(true);
            
            String type = ConstantsClass.typeTrial;
            //Updated by Rajesh 12th Nov 2019, Added Lost stage for Trial lost enrolment
            //Updated by Rajesh 12th Dec 2019, Added Lost stage for Pending enrolment 
            Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended, ConstantsClass.enrollStageLost, ConstantsClass.PendingEnrolment};
                
            List<Enrolment__c> enrList = [SELECT Id, Name, Package__r.Name, Student__r.Name, Teacher__r.Name, Parent__r.Name, Parent__r.PersonEmail, Trial_Date__c 
                                          FROM Enrolment__c 
                                          WHERE Parent__r.PersonEmail =:userEmail AND Type__c =:type  AND Stage__c IN:stgList AND Package__r.Active__c = true];
            if(enrList.size() > 0){
                Integer counter = 1;
                for(Enrolment__c enr: enrList){
                    String enrlStr = 'enr'+counter;
                    pageRef.getParameters().put(enrlStr, enr.Id);    
                
                    counter = counter+1;
                }   
            }     
        }
        
        if(String.isNotBlank(enrolmentSource))
            pageRef.getParameters().put('es', enrolmentSource);   
        
       	if(String.isNotBlank(countryCode))
            pageRef.getParameters().put('country', countryCode);   
        
        return pageRef;
    }
}