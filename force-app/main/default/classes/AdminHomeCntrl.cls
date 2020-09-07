public class AdminHomeCntrl {
    Public String countryName{get;set;}
    Public String countryCode{get;set;}
    public string org{get;set;}//Juneid 17 Aug 2020
    
    public AdminHomeCntrl(){
    	List<Centre_Users__c> cenUsrLst = [select Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.Organisation__r.name,Centre_Name__r.Country__c,Centre_Name__r.Country__r.Name, Centre_Name__r.Country__r.Country_Name__c
                               				from Centre_Users__c where User_Name__c=:UserInfo.getUserId()];
        system.debug('cenUsrLst.get(0).Centre_Name__r.Organisation__c-->'+cenUsrLst.get(0).Centre_Name__r.Organisation__c);
        if(cenUsrLst.size() > 0){
            countryCode= cenUsrLst.get(0).Centre_Name__r.Country__r.Name;
            countryName= cenUsrLst.get(0).Centre_Name__r.Country__r.Country_Name__c;
            org = cenUsrLst.get(0).Centre_Name__r.Organisation__r.name;
            system.debug('org--->'+org);
            //@Juneid 17 Aug,2020 current Logic for organization as per new logic
            if(String.isNotBlank(org)){
                if(org == Label.Ossia_Organisation_Name)
                    org='ossia';
                else
                    org='aureus';
                
                system.debug('org before send --->'+org);
            }
        }
        
        if(String.isBlank(countryCode)){
            countryCode = 'SG';
            countryName = 'Singapore';
        }
    }
}