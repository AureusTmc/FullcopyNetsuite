/**
 * Name: AllCampEnrolmentMultiStudentsCtrl
 * Author: jatin
 * Date : 29-Jan-2020
 * Description: this controller get all active camp according to center's
 */
public  class AllCampEnrolmentMultiStudentsCtrl {
    Public map<string,List<Camp__c>> mapOfCamp{get;set;}
    Public map<string,List<date>> mapOfCampDay{get;set;}
    //jatin: 19-feb-2020: for now we change requirement show all active camp according to center's
    //Public List<Camp__c> ListOfCamp{get;set;}  
    Public String centerId {get;set;} 
    Public String centerName {get;set;} 
    Public String enrolCampId {get;set;} 
    public Boolean showCampList{get;set;}
    public string countryCode{get;set;}
    public boolean isAureusAtHome{get;set;}
    public Integer trvlDuration{get;set;}
    Public String campId {get;set;} 
    Public String campName {get;set;}
    public boolean isOssia {get;set;}//Juneid 28 Aug 2020 for cheking org
    Public String currentCountry{get;set;}//Juneid 28 Aug 2020, Getting current country code
     Map<String, String> urlParamMetaMap;//Juneid 28 Aug 2020,store metadata value 
    string currentOrg;
    
    public AllCampEnrolmentMultiStudentsCtrl() {
        mapOfCampDay = new map<string,List<date>>();
        showCampList = false;
        isOssia = false;
        currentCountry = '';
           urlParamMetaMap = new Map<String, String>();
        currentOrg = '';
        //jatin: 18-feb-2020: for now we change requirement show all active camp according to center's
       /* centerId =    ApexPages.currentPage().getParameters().get('centerId');
        if(String.isNotBlank(centerId)){
        ListOfCamp = CampClassUtilityController.getCampList(centerId,'','',new set<string>());
            if(ListOfCamp != null && ListOfCamp.size() > 0){
                centerName = ListOfCamp[0].Centre__r.name;
                countryCode = ListOfCamp[0].Centre__r.Country__r.name;
            }   
            showCampList = true;  
            checkAtHome();            
        }*/ 
        
        //Juneid 28 Aug 2020, Getting metadata value of country and organization name
        for(URL_Parameters__mdt urlMdt : [SELECT Param_Name__c,Param_SF_Value__c FROM URL_Parameters__mdt]){
            urlParamMetaMap.put(urlMdt.Param_Name__c, urlMdt.Param_SF_Value__c);
        }
        system.debug('@@urlParamMetaMap'+urlParamMetaMap);
        //Juneid 28 Aug 2020 Orgnization wise logic as per new Requierment
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('org'))){
            isOssia = ApexPages.currentPage().getParameters().get('org').equalsIgnoreCase('ossia') ? true : false;
        }
         currentCountry = ApexPages.currentPage().getParameters().get('country');
        currentCountry = String.isNotBlank(currentCountry) ? currentCountry :  'SG';
        currentOrg = isOssia ? urlParamMetaMap.get('Ossia') : urlParamMetaMap.get(currentCountry.toUpperCase());
      
            
        mapOfCamp = new map<string,List<Camp__c>>();
        List<Camp__c> ListOfCamp = new List<Camp__c>();
        if(String.isNotBlank(currentOrg)){
            getActiveCamps(currentOrg);
        }
          
    }
    public void getActiveCamps(string currentOrg){
        mapOfCamp = new map<string,List<Camp__c>>();
        List<Camp__c> ListOfCamp = new List<Camp__c>();
        mapOfCampDay = new map<string,List<date>>();
        List<Camp__c> ListOfAllActiveCamp = CampClassUtilityController.getCampList('','','',new set<string>(),currentOrg);
        //List<Camp__c> ListOfAllActiveCamp =CampClassUtilityController.getCampList('','','',new set<string>());
        if(ListOfAllActiveCamp != null && ListOfAllActiveCamp.size() > 0 ){
            for(Camp__c objCamp : ListOfAllActiveCamp){
                ListOfCamp = new List<Camp__c>();
                if(string.isNotBlank(objCamp.Centre__r.name) && mapOfCamp.containsKey(objCamp.Centre__r.name)){
                    ListOfCamp = mapOfCamp.get(objCamp.Centre__r.name);
                }
                ListOfCamp.add(objCamp);
                mapOfCamp.put(objCamp.Centre__r.name,ListOfCamp);
                list<date> listOfCampDays= new list<date>();
                if(objCamp.Camp_Days__r != null && objCamp.Camp_Days__r.size() > 0){
                    listOfCampDays.add(objCamp.Camp_Days__r[0].Dates_Of_The_Camp__c);
                    listOfCampDays.add(objCamp.Camp_Days__r[objCamp.Camp_Days__r.size() - 1].Dates_Of_The_Camp__c);
                    mapOfCampDay.put(objCamp.id,listOfCampDays);
                }
            }
            showCampList = true;
        }
    }
    public void getCampId(){     
       // List<Camp__c>  ListOfCamp = CampClassUtilityController.getCampList('',enrolCampId,'',new set<string>());
        //if(ListOfCamp != null && ListOfCamp.size() > 0){
            //centerName = ListOfCamp[0].Centre__r.name;
            //countryCode = ListOfCamp[0].Centre__r.Country__r.name;
       // }
        system.debug('enrolCampId'+enrolCampId);
        // jatin : 18-Feb-2020: select any camp id  then we get centerid into page then we check centername is 'At-home'
        if(string.isNotBlank(centerId))
             checkAtHome(); 
    }


    // check center name in Aureus At Home then calculate travel duration 
      public void checkAtHome(){
        if(String.isNotBlank(centerId))
            isAureusAtHome = (centerId == Label.Aureus_at_Home_Id ? true : false);
        else
            isAureusAtHome = false;
        
        if(isAureusAtHome){
            for(Account acc: [SELECT Id,Name,CentreName_Cust__c,Travel_Time__c 
                              FROM Account 
                              WHERE Id =: centerId  LIMIT 1]){
                trvlDuration = acc.Travel_Time__c > 0 ? Integer.valueOf(acc.Travel_Time__c) : 30;
            }
        }
    }
    
}