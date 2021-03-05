public class enrolmentPrcRedirectCntrl {
    
    public PageReference redirectToAntoher(){
        PageReference pageRef;
        String usrEmail = ApexPages.currentPage().getParameters().get('userEmail');
        
        if(String.isNotBlank(usrEmail)){
            list<String> type = new list<String>{ConstantsClass.typeTrial,ConstantsClass.enrolGroupType};  //20-11-2020 Zakir Added Type Group in the List . 
             
            Set<String> stgList = new Set<String>{ConstantsClass.enrollStageAttended, 'Pending Enrolment'};
                
            List<Enrolment__c> enrList = [SELECT Id, Name, Package__r.Name, Student__r.Name, Teacher__r.Name, Parent__r.Name, Parent__r.PersonEmail, Trial_Date__c, Stage__c,
                                          Parent__r.Organisation__c,Parent__r.Organisation__r.Name,
                                          Center__r.Organisation__c,Center__r.Organisation__r.Name,Trial_Start_Time__c
                                           FROM Enrolment__c 
                                             WHERE  Parent__r.PersonEmail =:usrEmail //commented by nishi: 30-nov-2020: for  Change customer key from email address to email address+Organisation name   
                                             //Parent__r.User_Email__c =:usrEmail 
                                             AND Type__c IN: type  AND Stage__c IN:stgList ];//AND Package__r.Active__c = true
            
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
                string orgName;
                 //20-11-2020 Zakir Added Organisation parameter . 
                pageRef.getParameters().put(enrlStr, enr.Id);
                if(enr.Trial_Date__c != null && enr.Trial_Start_Time__c != null){
                    pageRef.getParameters().put('currentOrg',enr.Parent__r.Organisation__c);
                    if(enr.Parent__r.Organisation__r.Name == Label.Ossia_Organisation_Name){
                        orgName = 'ossia'; 
                    }else{
                        orgName = 'aureus'; 
                    }
                    pageRef.getParameters().put('orgType',orgName);
                }else{
                    pageRef.getParameters().put('currentOrg',enr.Center__r.Organisation__c);
                    if(enr.Center__r.Organisation__r.Name == Label.Ossia_Organisation_Name){
                        orgName = 'ossia'; 
                    }else{
                        orgName = 'aureus'; 
                    }
                    pageRef.getParameters().put('orgType',orgName);
                    pageRef.getParameters().put('pagetype','directEnrolment');
                  
                }
                 //20-11-2020 Zakir Added Added Organisation parameter . 
                system.debug('pegeRef-->'+pageRef.getParameters());
                
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