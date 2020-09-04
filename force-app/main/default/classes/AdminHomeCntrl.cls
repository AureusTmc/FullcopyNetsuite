public class AdminHomeCntrl {
    Public String countryName{get;set;}
    Public String countryCode{get;set;}
    
    public AdminHomeCntrl(){
    	List<Centre_Users__c> cenUsrLst = [select Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.Country__c,Centre_Name__r.Country__r.Name, Centre_Name__r.Country__r.Country_Name__c
                               				from Centre_Users__c where User_Name__c=:UserInfo.getUserId()];
        if(cenUsrLst.size() > 0){
            countryCode= cenUsrLst.get(0).Centre_Name__r.Country__r.Name;
            countryName= cenUsrLst.get(0).Centre_Name__r.Country__r.Country_Name__c;
        }
        
        if(String.isBlank(countryCode)){
            countryCode = 'SG';
            countryName = 'Singapore';
        }
    }
}