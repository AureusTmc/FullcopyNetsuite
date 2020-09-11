public class FreeTrial_IpadCntrl {
    public String slcdLsnType{get;set;}
    public String slcdCenter{get;set;}
    public String slcdCentrName{get;set;}
    public String slcdNoOfStudent{get;set;}
    Map<String,String> disabledInstrument;
    /*
public Account      parentAcc{get;set;}
public Account      studentAcc{get;set;}
*/
    //public Boolean isNextWithoutError{get;set;}
    
    //Variables according to ipad page
    List<String> instrumentList;
    public List<TrialEnrModel> enrModelList{get;set;}
    public String countryCode{get;set;}
    
    public Integer slcdStuIndex{get;set;}
    public String  slcdInstrument{get;set;}
    public Integer slcdDuration{get;set;}
    public String  slcdDate{get;set;}
    public String  slcdSlot{get;set;}
    public String  slcdTchrId{get;set;}
    
    public Account parentAcc{get;set;}
    public Boolean isParAlsoAStudent{get;set;}
    
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    public Boolean iWantReceivedLatestNew{get;set;}
    public String  slcdExistingStu{get;set;}
    public Boolean isSiteGuestUser{get;set;}
    public string PersonMobilePhoneCustom{get;set;}  
    public Boolean isPageInMobile{get;set;}
    public String  srcType{get;set;}
    public String org{get;set;}// @Juneid 14 Aug 2020, this variable is used to store organization type 
    Boolean isAureusAtHome;
    Integer trvlDuration;
    String formName;             
 public String uniqueRefCode{get;set;}//@Juneid ,04-Aug-2020,This variable is used to store Unique refrel code
    Boolean isOsiaApply; //@Juneid 05 Aug,2020, This Varibale is used to check Osia or not
    String centerCountry;//@Juneid 07 Aug 2020, This variable is used to store Center country name
    Id prsonContactId;
    public Boolean isOsiaEnable{get;set;}//Juneid 14 Aug 2020
    string currentOrg;//Juneid 17 Aug 2020, store the current organization
    Map<String, String> urlParamMetaMap;//Juneid 17 Aug 2020,store metadata value 
    
    string organization;    
    //Added by Rajesh, 6th Aug 2019. To store trial source on case object and country for filtercentre
    String trialSource;
    public FreeTrial_IpadCntrl(){
        enrModelList = new List<TrialEnrModel>(); 
        parentAcc = new Account();
        isAureusAtHome = false;
        isParAlsoAStudent = false;
        iWantReceivedLatestNew = false;
        isSiteGuestUser = (UserInfo.getName()).contains('Site');
        PersonMobilePhoneCustom = '';
        slcdLsnType = 'Individual';   
 uniqueRefCode =   ApexPages.currentPage().getParameters().get('refcode');
        system.debug('uniqueRefCode--->'+uniqueRefCode);
        isOsiaApply =  false;

        currentOrg= '';
        org ='';
        urlParamMetaMap = new Map<String, String>();
        
        //isNextWithoutError = false;
        
        /* countryCode   = ApexPages.currentPage().getParameters().get('country');
if(String.isBlank(countryCode))
countryCode = 'SG';
*/
        
        //Juneid 17 Aug 2020, Getting metadata value of country and organization name
        for(URL_Parameters__mdt urlMdt : [SELECT Param_Name__c,Param_SF_Value__c FROM URL_Parameters__mdt]){
            urlParamMetaMap.put(urlMdt.Param_Name__c, urlMdt.Param_SF_Value__c);
        }
        system.debug('urlParam--->'+urlParamMetaMap);
        
        
        List<Centre_Users__c> cenUsrLst = [select Id,Centre_Name__c,Centre_Name__r.Name,Centre_Name__r.Country__c,Centre_Name__r.Country__r.Name, Centre_Name__r.Country__r.Country_Name__c
                                           from Centre_Users__c where User_Name__c=:UserInfo.getUserId()];
        if(cenUsrLst.size() > 0){
            slcdCenter= cenUsrLst.get(0).Centre_Name__c;
            countryCode = cenUsrLst.get(0).Centre_Name__r.Country__r.Name;
        }
        
        if(String.isBlank(countryCode))
            countryCode = 'SG';
        
        String cntryCodeForSiteUser = ApexPages.currentPage().getParameters().get('country');   
        if(isSiteGuestUser && String.isNotBlank(cntryCodeForSiteUser))
            countryCode  = cntryCodeForSiteUser;    
        
        system.debug('countryCode--->'+countryCode);
        org =  ApexPages.currentPage().getParameters().get('org');
        system.debug('org-->'+org);
        
        if(String.isNotBlank(org)){
            if(org.equalsIgnoreCase('ossia')){
                org ='osia'; 
                currentOrg = urlParamMetaMap.get('Ossia');
            }else{
                currentOrg = urlParamMetaMap.get(countryCode.toUpperCase());
                org = 'aureus';
            }
        }else{
            currentOrg = urlParamMetaMap.get(countryCode.toUpperCase());
            org = 'aureus';
        }
        system.debug('currentOrg--->'+currentOrg);
        
        
        formName = ApexPages.currentPage().getParameters().get('Formname');        
        //Added by Rajesh, 6th Aug 2019. To store trial source on case object and country for filtercentre
        trialSource  = ApexPages.currentPage().getParameters().get('ts');
        
        fetchInstrument();
    }
    public list<SelectOption> getCenters(){
        list<SelectOption> options = new list<SelectOption>();
        String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        options.add(new SelectOption('','Select Centre')); 
        
        //@Juneid 14 Aug 2020 , Logic for Specific organisation centres
        //updated by Rajesh, 7th Aug 2019. updated soql To package centre bases of the country
        //Updated by Rajesh, 13th Aug 2019. Updated soql to remove hardcoded centre and filter centres on the bases of centre status
        for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                          WHERE RecordtypeId =: cenRecId AND Centre_Status__c =:ConstantsClass.activeStatus AND Organisation__c =:currentOrg ORDER BY CentreName_Cust__c]){
                              options.add(new SelectOption(acc.Id,acc.CentreName_Cust__c)); 
                          }
        
        return options;
    }
    
    public void slcdLessonType(){
        // slcdLsnType
        /*list<SelectOption> centOpt = getCenters();

for(StudentWrapper st : studentWrapList){            
LessonWrapper lsn = new LessonWrapper();
lsn.centerOptions = centOpt;

st.lesson = lsn;
}
if(slcdStuIndex > 0){
Integer selectedInd = slcdStuIndex-1;
if(String.isNotBlank(slcdLsnType)){
/*StudentWrapper stuWrap = studentWrapList.get(selectedInd);

LessonWrapper lsn = new LessonWrapper();
lsn.centerOptions = getCenters();
lsn.selectedLsnType= slcdLsnType;

stuWrap.lesson = lsn;
}
}*/
        
        System.debug('@@@@@'+slcdStuIndex);
        System.debug('@@@@@'+slcdLsnType);
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            if(String.isNotBlank(slcdLsnType)){
                TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
                trialEnrMod.slcdLsnType = slcdLsnType;
                if(slcdLsnType.equalsIgnoreCase('Individual')){
                    fetchInstrument();
                    trialEnrMod.instrumentList = instrumentList;
                    trialEnrMod.disabledInstrument = disabledInstrument;
                }else{
                    fetchInstrumentForGrpLsn();
                    trialEnrMod.instrumentList = instrumentList;
                    trialEnrMod.disabledInstrument = disabledInstrument;
                }
                enrModelList[slcdStuIndex-1] = trialEnrMod;
            }
        }
    }
    
    public void fetchInstrument(){
        instrumentList = new List<String>();
        disabledInstrument = new Map<String,String>();
        
        Set<String> instrumentTempSet = new Set<String>();
        if(String.isNotBlank(slcdCenter)){  
            checkAtHome();
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Name,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,
                                                             End_Time__c,Active__c,Center_Name__c,Center_Name__r.Name,Teacher_Name__r.Major_Instruments_Disciplines__c 
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Active__c = true AND Working_Day__c != null AND Break_Time__c = False AND
                                                             Teacher_Name__r.Major_Instruments_Disciplines__c != null AND Center_Name__r.Country__r.Name =:countryCode AND 
                                                             Teacher_Name__r.Enable_Trial_Bookings__c = true];
            //Filling active Instruments for the selected Center
            for(Teacher_Working_Hour__c teachTemp: techWorkSchList){
                if(teachTemp.Center_Name__c == slcdCenter) {
                    slcdCentrName = teachTemp.Center_Name__r.Name;
                    for(String strIns : teachTemp.Teacher_Name__r.Major_Instruments_Disciplines__c.split(';'))
                        instrumentTempSet.add(strIns); 
                }
            }
            
            if(!isAureusAtHome){
                //Filling disabled Instruments for the selected Center
                for(Teacher_Working_Hour__c teachTemp: techWorkSchList){
                    system.debug('teachTemp--->'+teachTemp);
                    system.debug('instrumentTempSet-->'+instrumentTempSet);
                    if(teachTemp.Center_Name__c != slcdCenter){
                        for(String strIns : teachTemp.Teacher_Name__r.Major_Instruments_Disciplines__c.split(';')){
                            system.debug('strIns--->'+strIns);
                            if(!instrumentTempSet.contains(strIns)){
                                String centNames =  disabledInstrument.containsKey(strIns) ? disabledInstrument.get(strIns) : teachTemp.Center_Name__r.Name;
                                
                                if(!(centNames.contains(teachTemp.Center_Name__r.Name)))
                                    centNames += ', '+teachTemp.Center_Name__r.Name;
                                
                                disabledInstrument.put(strIns, centNames);  
                            }   
                        }   
                    }
                }
            }
        }
        
        instrumentList.addAll(instrumentTempSet);
        instrumentList.sort();
    }
    
    public void fetchInstrumentForGrpLsn(){
        instrumentList = new List<String>();
        disabledInstrument = new Map<String,String>();
        
        Set<String> instrumentTempSet = new Set<String>();
        if(String.isNotBlank(slcdCenter)){  
            checkAtHome();
             //Start:Added by nishi:3-Sep-2020: for show ossia group class time slot we get instrument to Ossia_Group_Grade_Package__c object
            if(org == 'osia'){
                List<Ossia_Group_Grade_Package__c> gradePackageList = [SELECT Class_Name__c, Package__c,  Name, Id ,Class_Name__r.Centre_Name__r.Name,
                                                                        Package__r.Program__r.Instrument__c
                                                                        FROM Ossia_Group_Grade_Package__c
                                                                        Where Package__r.Program__r.Instrument__c != null and
                                                                        Class_Name__r.Centre_Name__r.Country__r.Name =:countryCode
                                                                        and Class_Name__r.Active__c = true 
                                                                        // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                                                        And Class_Name__r.Is_Makeup_Class__c = false];
                
                for(Ossia_Group_Grade_Package__c objGradePackage: gradePackageList){
                    if(objGradePackage.Class_Name__r.Centre_Name__c == slcdCenter) {
                        slcdCentrName = objGradePackage.Class_Name__r.Centre_Name__r.Name;
                        instrumentTempSet.add(objGradePackage.Package__r.Program__r.Instrument__c); 
                    } 
                }

                if(!isAureusAtHome){
                    //Filling disabled Instruments for the selected Center
                    for(Ossia_Group_Grade_Package__c objGradePackage: gradePackageList){
                        if(objGradePackage.Class_Name__r.Centre_Name__c != slcdCenter) {
                            if(!instrumentTempSet.contains(objGradePackage.Package__r.Program__r.Instrument__c)){
                                String centNames =  disabledInstrument.containsKey(objGradePackage.Package__r.Program__r.Instrument__c) ? disabledInstrument.get(objGradePackage.Package__r.Program__r.Instrument__c) : objGradePackage.Class_Name__r.Centre_Name__r.Name;
                                
                                if(!(centNames.contains(objGradePackage.Class_Name__r.Centre_Name__r.Name)))
                                    centNames += ', '+objGradePackage.Class_Name__r.Centre_Name__r.Name;
                                
                                disabledInstrument.put(objGradePackage.Package__r.Program__r.Instrument__c, centNames);  
                            }   
                              
                        }
                    }
                }
               
            }else{
                 //end:Added by nishi:3-Sep-2020: for show ossia group class time slot we get instrument to Ossia_Group_Grade_Package__c object
                List<Class__c> clssList = [SELECT Id,Teacher__c,Teacher__r.Name,Teacher__r.Teacher_Bio__c,Active__c,Centre_Name__c,Centre_Name__r.Name,Teacher__r.Major_Instruments_Disciplines__c,Instrument__c
                                        FROM Class__c 
                                        WHERE Active__c = true 
                                        AND Instrument__c != null AND Centre_Name__r.Country__r.Name =:countryCode
                                        // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                        And Is_Makeup_Class__c = false];
                for(Class__c cls : clssList){
                    if(cls.Centre_Name__c == slcdCenter) {
                        slcdCentrName = cls.Centre_Name__r.Name;
                        for(String strIns : cls.Instrument__c.split(';'))
                            instrumentTempSet.add(strIns); 
                    }                   
                }
                if(!isAureusAtHome){
                    //Filling disabled Instruments for the selected Center
                    for(Class__c cls : clssList){
                        if(cls.Centre_Name__c != slcdCenter) {
                            for(String strIns : cls.Instrument__c.split(';')){
                                
                                if(!instrumentTempSet.contains(strIns)){
                                    String centNames =  disabledInstrument.containsKey(strIns) ? disabledInstrument.get(strIns) : cls.Centre_Name__r.Name;
                                    
                                    if(!(centNames.contains(cls.Centre_Name__r.Name)))
                                        centNames += ', '+cls.Centre_Name__r.Name;
                                    
                                    disabledInstrument.put(strIns, centNames);  
                                }   
                            }   
                        }
                    }
                }
            }
            
            
            
        }
        
        instrumentList.addAll(instrumentTempSet);
        instrumentList.sort();
    }
    
    public void checkAtHome(){
        if(String.isNotBlank(slcdCenter))
            isAureusAtHome = (slcdCenter == Label.Aureus_at_Home_Id ? true : false);
        else
            isAureusAtHome = false;
        
        if(isAureusAtHome){
            for(Account acc: [SELECT Id,Name,CentreName_Cust__c,Travel_Time__c 
                              FROM Account 
                              WHERE Id =: slcdCenter  LIMIT 1]){
                                  trvlDuration = acc.Travel_Time__c > 0 ? Integer.valueOf(acc.Travel_Time__c) : 30;
                              }
        }
    }
    
    public void getNoOfStudent(){
        enrModelList = new List<TrialEnrModel>();     
        
        if(String.isNotBlank(slcdNoOfStudent)){  
            for(Integer i=0; i<Integer.valueOf(slcdNoOfStudent); i++){
                TrialEnrModel tm = new TrialEnrModel();
                tm.instrumentList = instrumentList;
                tm.disabledInstrument = disabledInstrument;
                enrModelList.add(tm);    
            }               
        }
    }
    
    public void setTrialInsetrument(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdInstrument = slcdInstrument;
            trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
            trialEnrMod.timeSlotStrMap = new Map<Date, String>();
            fetchTimeSlot(trialEnrMod);
        }
    }
    
    public PageReference backBtnCmp1(){
        system.debug('isOsiaEnable in  1st next-->'+isOsiaEnable);
        isOsiaEnable = isOsiaEnable;
        return null;
    }
    public PageReference nextBtnCmp1(){
        system.debug('isOsiaEnable in freetrial_ipad2-->'+isOsiaEnable);
        return page.freetrial_ipad2;
    }
    
    public PageReference backBtnCmp2(){
        return page.freetrial_ipad1;
    }
    public PageReference nextBtnCmp2(){
        return page.freetrial_ipad3;
    }
    
    public PageReference backBtnCmp3(){
        return page.freetrial_ipad2;
    }
    public PageReference nextBtnCmp3(){
        return page.freetrial_ipad4;
    }
    public PageReference backBtnCmp4(){
        return page.freetrial_ipad3;
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
        
        if(skipExistingStuPage)
            return page.freetrial_ipad5;
        else
            return page.freetrial_ipad6;
    }
    public PageReference backBtnCmp5(){
        Boolean isSkipExistingStuPage = false;
        for(TrialEnrModel trMd : enrModelList){
            if(String.isNotBlank(trMd.slcdExistingStu)){
                isSkipExistingStuPage = true;
                break;
            }
        }
        if(isSkipExistingStuPage)
            return page.freetrial_ipad6;
        else
            return page.freetrial_ipad4;
    }
    public PageReference backBtnCmp6(){
        return page.freetrial_ipad4;
    }
    public PageReference nextBtnCmp6(){
        return page.freetrial_ipad5;
    }
    
    //Page2 functions        
    public void fetchPreWeekSlot(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            if(isPageInMobile){
                trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(-3);
                trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(-3);
            }else{
                trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(-7);
                trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(-7);
            }            
            //trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(-7);
            // trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(-7);
            trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
            trialEnrMod.timeSlotStrMap = new Map<Date, String>();
            fetchTimeSlot(trialEnrMod); 
        }
    }
    public void fetchNextWeekSlot(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            if(isPageInMobile){
                trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(3);
                trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(3);
            }else{
                trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(7);
                trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(7);
            }  
            //trialEnrMod.calStartDate = trialEnrMod.calStartDate.addDays(7);
            //trialEnrMod.calEndDate   = trialEnrMod.calEndDate.addDays(7);
            trialEnrMod.timeSlotMap = new Map<Date, List<String>>();
            trialEnrMod.timeSlotStrMap = new Map<Date, String>();
            fetchTimeSlot(trialEnrMod);
        }
    }
    
    public void processDuration(){
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdDuration = slcdDuration;
            fetchTimeSlot(trialEnrMod);
        }
    }
    
    public void slcdTeacher(){ 
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdTchrId = slcdTchrId;    
            trialEnrMod.slcdTchrName = '';
            
            List<Account> tchrlist = [SELECT Id,Name FROM Account WHERE Id =: slcdTchrId];
            if(tchrlist.size() > 0)
                trialEnrMod.slcdTchrName = tchrlist.get(0).Name;
            
            if(String.isNotBlank(trialEnrMod.slcdLsnType) && trialEnrMod.slcdLsnType.equalsIgnoreCase('Group')){
                String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();   
                Map<String, Booking__c> grpLsnBookMap = new Map<String, Booking__c>(); 
                
                for(Booking__c book: [SELECT Id, Class__c, Booking_Date__c, Class__r.Teacher__c, Class__r.Start_Time__c, Class__r.Package__c, Class__r.Minimum_age__c, Class__r.Maximum_age__c  
                                      FROM Booking__c
                                      WHERE RecordTypeId =: bookGrpClsRecId AND Class__r.Centre_Name__c =: slcdCenter AND Class__r.Active__c = True AND Class__r.Available_Capacity__c > 0 
                                      AND Class__c != null AND Booking_Date__c =: trialEnrMod.slcdDateDt AND  Class__r.Teacher__c =:slcdTchrId
                                      // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                      And Class__r.Is_Makeup_Class__c = false]){
                                          
                                          String key = book.Class__r.Teacher__c +'#'+ trialEnrMod.slcdDateDt+'#'+book.Class__r.Start_Time__c;                      
                                          grpLsnBookMap.put(key, book);
                                      }
                
                List<String> timeList = trialEnrMod.slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                
                String key = slcdTchrId +'#'+ trialEnrMod.slcdDateDt+'#'+startTime;  
                if(grpLsnBookMap.containsKey(key)){
                    trialEnrMod.classMinAge = grpLsnBookMap.get(key).Class__r.Minimum_age__c != null ? Integer.valueOf(grpLsnBookMap.get(key).Class__r.Minimum_age__c) : 0;
                    trialEnrMod.classMaxAge = grpLsnBookMap.get(key).Class__r.Maximum_age__c != null ? Integer.valueOf(grpLsnBookMap.get(key).Class__r.Maximum_age__c) : 0;
                }                
            }
        }    
    }
    
    public void processExistingStu(){ 
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdExistingStu = slcdExistingStu;
            System.debug('@@@@'+slcdExistingStu);
        }    
    }
    
    public void fetchTimeSlot(TrialEnrModel trialEnrMod){
        system.debug('trialEnrMod--->'+trialEnrMod);
        trialEnrMod.teachModSlotMap = new Map<String,Map<String, List<TeacherModel>>>();
        /* validation
if(String.isNotBlank(slcdCenter)){
isError = true;
ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'Please select atleast one location.'));
}else if(String.isNotBlank(slcdInstrument)){
isError = true;
ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'Please select atleast one instrument.'));
}*/
        
        Map<String,List<Teacher_Working_Hour__c>> teachWorkSchMap = new Map<String,List<Teacher_Working_Hour__c>>();
        Map<String,String> teachAttaImageMap = new Map<String,String>();
        Set<String> tchrSet = new Set<String>();
        Map<Id,List<String>> tcrQualMap = new Map<Id,List<String>>();
        
        if(trialEnrMod.slcdLsnType.equalsIgnoreCase('Individual')){
            List<Teacher_Working_Hour__c> techWorkSchList = [SELECT Id,Name,Teacher_Name__c,Teacher_Name__r.Engagement_Type__c,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,
                                                             Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c
                                                             FROM  Teacher_Working_Hour__c 
                                                             WHERE Center_Name__c =: slcdCenter AND Active__c = true AND Working_Day__c != null AND Break_Time__c = False 
                                                             AND Teacher_Name__r.Status__c =: ConstantsClass.teacherWorkingStatus AND Start_Time__c != null AND End_Time__c != null AND
                                                             Teacher_Name__r.Major_Instruments_Disciplines__c includes(:trialEnrMod.slcdInstrument) AND Teacher_Name__r.Enable_Trial_Bookings__c = true];
            system.debug('techwork'+techWorkSchList);
            for(Teacher_Working_Hour__c tchWrkSch: techWorkSchList){                                                               
                List<Teacher_Working_Hour__c> tchList = teachWorkSchMap.get(tchWrkSch.Working_Day__c);
                if(tchList == null)
                    tchList = new List<Teacher_Working_Hour__c>();
                system.debug('tchWrkSch---->'+tchWrkSch);
                tchList.add(tchWrkSch);                                                  
                teachWorkSchMap.put(tchWrkSch.Working_Day__c, tchList);  
                system.debug('teachWorkSchMap--->'+teachWorkSchMap);
                
                teachAttaImageMap.put(tchWrkSch.Teacher_Name__c,null);    
                system.debug('teachAttaImageMap---->'+teachAttaImageMap);
                
                tcrQualMap.put(tchWrkSch.Teacher_Name__c, null);
                system.debug('tcrQualMap--->'+tcrQualMap);
            }
            
            if(teachAttaImageMap.size() > 0){
                for(Account acc : [SELECT Id, (SELECT Id FROM Attachments WHERE Name Like '%Profile Image%' AND ContentType IN ('image/png', 'image/jpeg', 'image/gif') 
                                               ORDER BY LastModifiedDate DESC LIMIT 1) 
                                   FROM Account WHERE Id IN : teachAttaImageMap.keySet()]){
                                       
                                       if(acc.Attachments != null && acc.Attachments.size()>0)
                                           teachAttaImageMap.put(acc.Id, acc.Attachments.get(0).Id);
                                   }
            }
            
            Map<String,Fifth_Lesson__c> fifthLsnMap = new Map<String,Fifth_Lesson__c>();
            Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
            
            if(isPageInMobile)
                trialEnrMod.calEndDate = trialEnrMod.calStartDate.addDays(2);
            Date startDt = trialEnrMod.calStartDate;
            Date endDt   = trialEnrMod.calEndDate;
            
            //Update by-: Nishant | Date-: 18/06/2019
            //Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up'};
            //Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled'};
            Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc', 'Group Class'};
                Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed','Blocked'};
                    String bookLessRecId   =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
            String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();
            
            Set<String> bookSet       = new Set<String>();
            for(Booking__c book : [SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c 
                                   FROM Booking__c 
                                   WHERE Teacher_Account__c IN:teachAttaImageMap.keySet() AND (RecordTypeId =: bookLessRecId OR RecordTypeId =: bookGrpClsRecId) AND Start_Time__c != null AND End_Time__c != null
                                   AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)  AND Status__c IN: bookStatusSet
                                   AND ((Type__c IN: bookTypeSet) OR (Type__c = 'Busy' AND Category__c != 'Placeholder'))]){
                                       if(book.End_Time__c > book.Start_Time__c){
                                           String key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ book.Start_Time__c;
                                           bookMap.put(key, book); 
                                           
                                           if(trialEnrMod.slcdDuration == 0 || trialEnrMod.slcdDuration == 0)
                                               trialEnrMod.slcdDuration = 30;
                                           
                                           //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                                           String currDay =  DateTime.newInstance(book.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                                           Time temStartTime = book.Start_Time__c.addMinutes(-(trialEnrMod.slcdDuration-15)); 
                                           Time endTempT     = book.End_Time__c;
                                           while(temStartTime < endTempT){
                                               key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ temStartTime;
                                               bookSet.add(key);
                                               
                                               temStartTime = temStartTime.addMinutes(15);
                                           }
                                       }
                                   }
            
            for(Fifth_Lesson__c fifthLsn : [SELECT Id, Name, Booking_Date__c, Start_Time__c, End_Time__c, Teacher_Account__c  
                                            FROM Fifth_Lesson__c 
                                            WHERE Teacher_Account__c IN:teachAttaImageMap.keySet() AND IsActive__c = True AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt)]){
                                                /*if(fifthLsn.End_Time__c > fifthLsn.Start_Time__c){   
String key = fifthLsn.Teacher_Account__c +':'+ fifthLsn.Booking_Date__c +':'+ fifthLsn.Start_Time__c;
fifthLsnMap.put(key, fifthLsn);  
}*/
                                                if(fifthLsn.End_Time__c > fifthLsn.Start_Time__c){
                                                    String key = fifthLsn.Teacher_Account__c +':'+ fifthLsn.Booking_Date__c +':'+ fifthLsn.Start_Time__c;
                                                    fifthLsnMap.put(key, fifthLsn); 
                                                    
                                                    if(trialEnrMod.slcdDuration == 0 || trialEnrMod.slcdDuration == 0)
                                                        trialEnrMod.slcdDuration = 30;
                                                    
                                                    //Added by Rajesh, 21st Aug 2019, to solve time slot issue
                                                    String currDay =  DateTime.newInstance(fifthLsn.Booking_Date__c, Time.newInstance(0, 0, 0, 0)).format('E');
                                                    Time temStartTime = fifthLsn.Start_Time__c.addMinutes(-(trialEnrMod.slcdDuration-15)); 
                                                    Time endTempT     = fifthLsn.End_Time__c;
                                                    while(temStartTime < endTempT){
                                                        key = fifthLsn.Teacher_Account__c +':'+ fifthLsn.Booking_Date__c +':'+ temStartTime;
                                                        bookSet.add(key);
                                                        
                                                        temStartTime = temStartTime.addMinutes(15);
                                                    }
                                                }                                 
                                            }
            
            System.debug('@@@'+bookSet);
            //Fetching teacher highest qualification
            /* Map<Id,List<String>> tcrQualMap = new Map<Id,List<String>>();
for(Teacher_Working_Hour__c teachWorkSch: techWorkSchList)
tcrQualMap.put(teachWorkSch.Teacher_Name__c, null);
*/
            if(tcrQualMap.size() > 0){
                for(Qualification__c qu : [SELECT Id,Name,Teacher__c,Programme_Name__c FROM Qualification__c 
                                           WHERE Teacher__c IN:tcrQualMap.keySet() ORDER BY Year_of_Graduation__c]){
                                               
                                               List<String> tchrQual = new List<String>();
                                               if(tcrQualMap.get(qu.Teacher__c) != null)
                                                   tchrQual = tcrQualMap.get(qu.Teacher__c);
                                               
                                               tchrQual.add(qu.Programme_Name__c);                          
                                               tcrQualMap.put(qu.Teacher__c, tchrQual);                          
                                               // if(tcrQualMap.get(qu.Teacher__c) == null)
                                               // tcrQualMap.put(qu.Teacher__c, qu);
                                           }
            }
            
            
            for(Date st=startDt; st<=endDt; st=st.addDays(1)){
                Map<String, List<TeacherModel>> tempSlotMap = new Map<String, List<TeacherModel>>();
                /*TimeSlotModelCntrl tSlotMapTemp = new TimeSlotModelCntrl();

Set<Time> morningTimesTemp      = new Set<Time>();
Set<Time> afternoonTimesTemp    = new Set<Time>();*/
                //   Map<Id,TeacherModel> accTcrMap  = new Map<Id,TeacherModel>();
                
                Set<Time> timeSlotTemp      = new Set<Time>();
                String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
                system.debug('@@@currDay'+currDay);
                if(teachWorkSchMap.containsKey(currDay)){
                    List<Teacher_Working_Hour__c> tchWorSchLst = teachWorkSchMap.get(currDay);
                    
                    for(Teacher_Working_Hour__c teachWorkSch: tchWorSchLst){
                       // start:nishi: 4-Sep-2020: for check teacher engagement type is part-time and is day is greater then 28 mean (5th lesson booking) so we not consider this teacher
                       //remove any timeslot for 5th days for part-time teachers.
                        Boolean isPartTimeTeacher = false; 
                        if(teachWorkSch.Teacher_Name__r.Engagement_Type__c =='Part-Time' && st.day() > 28 && org == 'osia'){
                            isPartTimeTeacher = true;
                        }
                        system.debug('%%%%isPartTimeTeacher'+isPartTimeTeacher +'  '+st); 
                        if(!isPartTimeTeacher){
                        //end: nishi: 4-Sep-2020: for check teacher engagement type is part-time and is day is greater then 28 mean (5th lesson booking) so we not consider this teacher
                       //remove any timeslot for 5th days for part-time teachers.

                            /* if(!(accTcrMap.containsKey(teachWorkSch.Teacher_Name__c))){
    List<String> tchrQual =  new List<String>();
    if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
    tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
    TeacherModel acc  = new TeacherModel(teachWorkSch.Teacher_Name__c, teachWorkSch.Teacher_Name__r.Name,
    teachWorkSch.Teacher_Name__r.Teacher_Bio__c, '', tchrQual);

    if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
    acc.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
    accTcrMap.put(teachWorkSch.Teacher_Name__c, acc);
    }*/
                            
                            Time stTime = teachWorkSch.Start_Time__c;
                            /* if(st == System.today() && System.now().time() > stTime){
    stTime = System.now().time();
    }*/
                            
                            Integer endTimeDef = trialEnrMod.slcdDuration  > 0 ? trialEnrMod.slcdDuration : 30;
                            
                            while(stTime <= teachWorkSch.End_Time__c.addMinutes(-endTimeDef)){
                                /*if(st != date.Parse(slcdDate) && (morningTimesTemp.size() > 0 && afternoonTimesTemp.size() > 0)){
    break;
    } */            
                                
                                String key = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime;
                                if(bookMap.containsKey(key)){
                                    Booking__c bookTmp = bookMap.get(key);
                                    stTime = bookTmp.End_Time__c;
                                }else if(fifthLsnMap.containsKey(key)){
                                    Fifth_Lesson__c fifthTmp = fifthLsnMap.get(key);
                                    stTime = fifthTmp.End_Time__c;
                                }else{
                                    string key2 = teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime.addMinutes(15);
                                    
                                    if(bookMap.containsKey(key2)){
                                        Booking__c bookTmp = bookMap.get(key2);
                                        stTime = bookTmp.End_Time__c;
                                    }else if(fifthLsnMap.containsKey(key2)){
                                        Fifth_Lesson__c fifthTmp = fifthLsnMap.get(key2);
                                        stTime = fifthTmp.End_Time__c;
                                    }else{
                                        //if(stTime.hour() < 12){
                                        String tempKey =  teachWorkSch.Teacher_Name__c + ':'+ st + ':'+ stTime;
                                        //if(!(bookSet.contains(tempKey)) && stTime.addMinutes(ConstantsClass.defMinutes) < teachWorkSch.End_Time__c){
                                        if(stTime.addMinutes(ConstantsClass.defMinutes) < teachWorkSch.End_Time__c){
                                            // Time currTime = Time.newInstance(System.now().hour(), System.now().minute(), System.now().second(), System.now().millisecond());
                                            //currTime = currTime.addHours(4);
                                            
                                            //DateTime tempTodayTime = System.now().addHours(4);
                                            //Updated by Rajesh 13th Aug 2019, Add 2 hours window for today
                                            DateTime tempTodayTime = System.now().addHours(4);
                                            if(!isSiteGuestUser)
                                                tempTodayTime = System.now().addMinutes(15);
                                            
                                            //DateTime tempTodayTime = System.now();
                                            DateTime tempStDtTime  = Datetime.newInstance(st, stTime);
                                            
                                            //if(st > System.today() || (st == System.today() &&  stTime > currTime)){
                                            if(tempStDtTime > tempTodayTime){
                                                timeSlotTemp.add(stTime);
                                                
                                                //Filling teacher according to time slot
                                                List<TeacherModel> tchTempList = new List<TeacherModel>();
                                                String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                                                
                                                // if(trialEnrMod.teachModSlotMap.get(timeStr) != null)
                                                //   tchTempList = trialEnrMod.teachModSlotMap.get(timeStr);
                                                if(tempSlotMap.get(timeStr) != null)
                                                    tchTempList = tempSlotMap.get(timeStr);
                                                
                                                List<String> tchrQual =  new List<String>();
                                                if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
                                                    tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);
                                                
                                                TeacherModel tMod = new TeacherModel(teachWorkSch.Teacher_Name__c,teachWorkSch.Teacher_Name__r.FirstName,
                                                                                    teachWorkSch.Teacher_Name__r.Teacher_Bio__c,'',tchrQual);
                                                if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
                                                    tMod.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
                                                tchTempList.add(tMod);
                                                
                                                tempSlotMap.put(timeStr, tchTempList);
                                                // Map<String, List<TeacherModel>> tempSlotMap = Map<String, List<TeacherModel>>();
                                                
                                                //Filling teacher according to time slot
                                                /*List<TeacherModel> tchTempList = new List<TeacherModel>();
    String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');

    if(trialEnrMod.teachModSlotMap.get(timeStr) != null)
    tchTempList = trialEnrMod.teachModSlotMap.get(timeStr);

    List<String> tchrQual =  new List<String>();
    if(tcrQualMap.get(teachWorkSch.Teacher_Name__c) != null)
    tchrQual = tcrQualMap.get(teachWorkSch.Teacher_Name__c);

    TeacherModel tMod = new TeacherModel(teachWorkSch.Teacher_Name__c,teachWorkSch.Teacher_Name__r.Name,
    teachWorkSch.Teacher_Name__r.Teacher_Bio__c,'',tchrQual);
    if(teachAttaImageMap.get(teachWorkSch.Teacher_Name__c) != null)
    tMod.attachmentId = teachAttaImageMap.get(teachWorkSch.Teacher_Name__c);
    tchTempList.add(tMod);

    trialEnrMod.teachModSlotMap.put(timeStr,tchTempList);*/
                                                // stTime = stTime.addMinutes(15);
                                            }
                                        }
                                        stTime = stTime.addMinutes(ConstantsClass.defMinutes);
                                        //  }
                                    }
                                }
                            }
                        }
                    }
                }
                /*
List<String> mrgSlotList = new List<String>();
List<Time> tmpLst        = new List<Time>();
tmpLst.addAll(morningTimesTemp);tmpLst.sort();
for(Time t : tmpLst){
String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
mrgSlotList.add(t.hour() + ':' + minTmp);
}

List<String> aftSlotList = new List<String>();
tmpLst                   = new List<Time>();
tmpLst.addAll(afternoonTimesTemp);tmpLst.sort();
for(Time t : tmpLst){
String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
aftSlotList.add(t.hour() + ':' + minTmp);
}

TimeSlotModelCntrl tSlotMapTemp2 = new TimeSlotModelCntrl();
if(slcdDate != null){
if(st == date.Parse(slcdDate)){
tSlotMapTemp.morningSlot = mrgSlotList;
tSlotMapTemp.afternoonSlot = aftSlotList;
if(mrgSlotList.size() > 0 && aftSlotList.size() > 0)
tSlotMapTemp.teachModList = accTcrMap.values();  

tSlotMapTemp2 = tSlotMapTemp;
}
}

if(mrgSlotList.size() > 0)
tSlotMapTemp2.isAvlMrgSlot = true;
if(aftSlotList.size() > 0)
tSlotMapTemp2.isAvlAfternoonSlot = true;

tSlotDateMap.put(st.day()+'/'+st.month()+'/'+st.year() , tSlotMapTemp2);*/
                system.debug('st'+st.format());
                system.debug('tempSlotMap'+tempSlotMap);
                trialEnrMod.teachModSlotMap.put(st.format(),tempSlotMap);
                system.debug('timeSlotTemp------> '+timeSlotTemp);
                List<String> slotList = new List<String>();
                List<Time> tmpLst        = new List<Time>();
                tmpLst.addAll(timeSlotTemp);tmpLst.sort();
                
                String dayOfWeek  = ((DateTime)st).format('E');
                for(Time t : tmpLst){
                    String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                    slotList.add(dayOfWeek+'-'+t.hour() + ':' + minTmp);
                }
                system.debug('st'+st);
                system.debug('slotList'+slotList);
                system.debug('st.format()'+st.format());
                trialEnrMod.timeSlotMap.put(st, slotList);
                trialEnrMod.timeSlotStrMap.put(st, st.format());
            }
        }else if(trialEnrMod.slcdLsnType.equalsIgnoreCase('Group')){
            Map<String,List<Class__c>> clsSchMap = new Map<String,List<Class__c>>();
            Map<String,Booking__c> bookMap = new Map<String,Booking__c>();
            
            if(trialEnrMod.slcdDuration == 0 || trialEnrMod.slcdDuration == 0)
                trialEnrMod.slcdDuration = 30;               
            
            if(isPageInMobile)
                trialEnrMod.calEndDate = trialEnrMod.calStartDate.addDays(2);
            Date startDt = trialEnrMod.calStartDate;
            Date endDt   = trialEnrMod.calEndDate;
            system.debug('@@trialEnrMod.slcdInstrument'+trialEnrMod.slcdInstrument);
            system.debug('@@slcdCenter'+slcdCenter);
            system.debug('@@trialEnrMod.slcdDuration'+trialEnrMod.slcdDuration);
            String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId(); 
            //Start:Added by nishi:3-Sep-2020: for show ossia group class time slot we get instrument to Ossia_Group_Grade_Package__c object
            if(org == 'osia'){
                set<String> listOfGradePackageClass= new set<String>();
                for(Ossia_Group_Grade_Package__c objGradePackage: [SELECT Class_Name__c, Package__c,  Name, Id 
                                                                        FROM Ossia_Group_Grade_Package__c
                                                                        Where Package__r.Program__r.Instrument__c =: trialEnrMod.slcdInstrument
                                                                       ]){
                    listOfGradePackageClass.add(objGradePackage.Class_Name__c);
                }
                for(Class__c cls: [SELECT Id, Name, Package__c, Package__r.Name, Teacher__c, Teacher__r.FirstName, Teacher__r.Teacher_Bio__c, Class_Day__c, Start_Time__c,End_Time__c,
                                    (SELECT Id, Booking_Date__c FROM Bookings__r WHERE RecordTypeId =: bookGrpClsRecId AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt))
                                    FROM Class__c WHERE 
                                    ID In: listOfGradePackageClass
                                    and Centre_Name__c =:  slcdCenter 
                                    AND Active__c = True 
                                    AND Available_Capacity__c > 0 
                                    AND Duration__c =: trialEnrMod.slcdDuration
                                    // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                    And Is_Makeup_Class__c = false]){ 
                    
                    if(cls.End_Time__c > cls.Start_Time__c){
                        teachAttaImageMap.put(cls.Teacher__c,null); 
                        tcrQualMap.put(cls.Teacher__c, null);
                        system.debug('@@cls.Class_Day__c'+cls.Class_Day__c);
                        List<Class__c> clsList = clsSchMap.get(cls.Class_Day__c);
                        if(clsList == null)
                            clsList = new List<Class__c>();                    
                        clsList.add(cls);                                                  
                        clsSchMap.put(cls.Class_Day__c, clsList);                       
                        for(Booking__c book: cls.Bookings__r)
                            bookMap.put(cls.Id+'#'+book.Booking_Date__c, book);    
                    }
                }
            }else{
                 //end: Added by nishi:3-Sep-2020: for show ossia group class time slot we get instrument to Ossia_Group_Grade_Package__c object
                for(Class__c cls: [SELECT Id, Name, Package__c, Package__r.Name, Teacher__c, Teacher__r.FirstName, Teacher__r.Teacher_Bio__c, Class_Day__c, Start_Time__c,End_Time__c,
                                    (SELECT Id, Booking_Date__c FROM Bookings__r WHERE RecordTypeId =: bookGrpClsRecId AND (Booking_Date__c >=: startDt AND Booking_Date__c <=: endDt))
                                    FROM Class__c WHERE Instrument__c =:trialEnrMod.slcdInstrument 
                                    AND Centre_Name__c =:  slcdCenter 
                                    AND Active__c = True 
                                    AND Available_Capacity__c > 0 
                                    AND Duration__c =: trialEnrMod.slcdDuration
                                    // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                    And Is_Makeup_Class__c = false]){ 
                    
                    if(cls.End_Time__c > cls.Start_Time__c){
                        teachAttaImageMap.put(cls.Teacher__c,null); 
                        tcrQualMap.put(cls.Teacher__c, null);
                        system.debug('@@cls.Class_Day__c'+cls.Class_Day__c);
                        List<Class__c> clsList = clsSchMap.get(cls.Class_Day__c);
                        if(clsList == null)
                            clsList = new List<Class__c>();                    
                        clsList.add(cls);                                                  
                        clsSchMap.put(cls.Class_Day__c, clsList);                       
                        for(Booking__c book: cls.Bookings__r)
                            bookMap.put(cls.Id+'#'+book.Booking_Date__c, book);    
                    }
                }
            }
           

            system.debug('@@clsSchMap'+clsSchMap);
            if(teachAttaImageMap.size() > 0){
                for(Account acc : [SELECT Id, (SELECT Id FROM Attachments WHERE Name Like '%Profile Image%' AND ContentType IN ('image/png', 'image/jpeg', 'image/gif') 
                                               ORDER BY LastModifiedDate DESC LIMIT 1) 
                                   FROM Account WHERE Id IN : teachAttaImageMap.keySet()]){
                                       
                                       if(acc.Attachments != null && acc.Attachments.size()>0)
                                           teachAttaImageMap.put(acc.Id, acc.Attachments.get(0).Id);
                                   }
            }
            if(tcrQualMap.size() > 0){
                for(Qualification__c qu : [SELECT Id,Name,Teacher__c,Programme_Name__c FROM Qualification__c 
                                           WHERE Teacher__c IN:tcrQualMap.keySet() ORDER BY Year_of_Graduation__c]){
                                               
                                               List<String> tchrQual = new List<String>();
                                               if(tcrQualMap.get(qu.Teacher__c) != null)
                                                   tchrQual = tcrQualMap.get(qu.Teacher__c);
                                               
                                               tchrQual.add(qu.Programme_Name__c);                          
                                               tcrQualMap.put(qu.Teacher__c, tchrQual);  
                                           }
            }
            system.debug('@@startDt'+startDt);
            system.debug('@@endDt'+endDt);
            
            for(Date st=startDt; st<=endDt; st=st.addDays(1)){
                //    if(st >= System.today()){
                Map<String, List<TeacherModel>> tempSlotMap = new Map<String, List<TeacherModel>>();
                Set<Time> timeSlotTemp      = new Set<Time>();                
                String currDay =  DateTime.newInstance(st, Time.newInstance(0, 0, 0, 0)).format('E');
                
                if(clsSchMap.containsKey(currDay) && st >= System.today()){
                    List<Class__c> clsSchLst = clsSchMap.get(currDay);
                    
                    for(Class__c clsSch: clsSchLst){    
                        if(bookMap.containsKey(clsSch.Id+'#'+st)){
                            Time stTime = clsSch.Start_Time__c;
                            timeSlotTemp.add(stTime);       
                            
                            //Filling teacher according to time slot
                            List<TeacherModel> tchTempList = new List<TeacherModel>();
                            String timeStr = stTime.hour() + ':' + (stTime.minute() != 0 ?  (stTime.minute() +'') : '00');
                            
                            if(tempSlotMap.get(timeStr) != null)
                                tchTempList = tempSlotMap.get(timeStr);
                            
                            List<String> tchrQual =  new List<String>();
                            if(tcrQualMap.get(clsSch.Teacher__c) != null)
                                tchrQual = tcrQualMap.get(clsSch.Teacher__c);
                            
                            TeacherModel tMod = new TeacherModel(clsSch.Teacher__c,clsSch.Teacher__r.FirstName,
                                                                 clsSch.Teacher__r.Teacher_Bio__c,'',tchrQual);
                            if(teachAttaImageMap.get(clsSch.Teacher__c) != null)
                                tMod.attachmentId = teachAttaImageMap.get(clsSch.Teacher__c);
                            tchTempList.add(tMod);
                            
                            tempSlotMap.put(timeStr, tchTempList);
                        }
                    }
                }
                trialEnrMod.teachModSlotMap.put(st.format(),tempSlotMap);
                system.debug('timeSlotTemp------> '+timeSlotTemp);
                List<String> slotList = new List<String>();
                List<Time> tmpLst        = new List<Time>();
                tmpLst.addAll(timeSlotTemp);tmpLst.sort();
                
                String dayOfWeek  = ((DateTime)st).format('E');
                for(Time t : tmpLst){
                    String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                    slotList.add(dayOfWeek+'-'+t.hour() + ':' + minTmp);
                }
                trialEnrMod.timeSlotMap.put(st, slotList);
                trialEnrMod.timeSlotStrMap.put(st, st.format());
            }
            // }
        }
    }
    
    public void fetchTeacherDetails(){        
        if(slcdStuIndex != null && slcdStuIndex >= 1){
            TrialEnrModel trialEnrMod = enrModelList.get(slcdStuIndex-1);
            trialEnrMod.slcdDate    = slcdDate;
            trialEnrMod.slcdDateDt  = date.parse(slcdDate);
            trialEnrMod.slcdFullSlot= slcdSlot;
            trialEnrMod.slcdSlot = trialEnrMod.slcdFullSlot.substring(4, trialEnrMod.slcdFullSlot.length());
            trialEnrMod.slcdSlotTchrs = new List<TeacherModel>();
            System.debug('@@@@trialEnrMod.teachModSlotMap'+trialEnrMod.teachModSlotMap);
            System.debug('@@@@slcdDate'+slcdDate);
            System.debug('@@@@trialEnrMod.slcdSlot'+trialEnrMod.slcdSlot);
            System.debug('@@@@trialEnrMod.teachModSlotMap.get(slcdDate)'+trialEnrMod.teachModSlotMap.get(slcdDate));
            System.debug('@@@@trialEnrMod.teachModSlotMap.get(slcdDate).get(trialEnrMod.slcdSlot)'+trialEnrMod.teachModSlotMap.get(slcdDate).get(trialEnrMod.slcdSlot));
            if(trialEnrMod.teachModSlotMap.get(slcdDate) != null && trialEnrMod.teachModSlotMap.get(slcdDate).get(trialEnrMod.slcdSlot) != null)
                trialEnrMod.slcdSlotTchrs = trialEnrMod.teachModSlotMap.get(slcdDate).get(trialEnrMod.slcdSlot);
            
            System.debug('@@@@'+trialEnrMod.slcdSlotTchrs);
            System.debug('@@@@'+trialEnrMod.slcdSlot);
            /*System.debug('@@@@'+slcdStuIndex);
System.debug('@@@@'+enrModelList.size());
System.debug('@@@@'+trialEnrMod.slcdInstrument);
System.debug('@@@@'+enrModelList.get(1).slcdInstrument);
System.debug('@@@@'+trialEnrMod.slcdSlotTchrs.size());
*/
            if(slcdStuIndex == 1 && enrModelList.size() > 1){
                TrialEnrModel trialEnrMod2nd = enrModelList.get(1);
                trialEnrMod2nd.timeSlotMap = new Map<Date, List<String>>();
                trialEnrMod2nd.timeSlotStrMap = new Map<Date, String>();
                trialEnrMod2nd.slcdFullSlot = '';
                trialEnrMod2nd.slcdSlot     = '';
                fetchTimeSlot(trialEnrMod2nd);
            }
            
            if(slcdStuIndex == 1 && enrModelList.size() > 1 && trialEnrMod.slcdInstrument == enrModelList.get(1).slcdInstrument && trialEnrMod.slcdSlotTchrs.size()==1){
                
                List<String> slotList = enrModelList.get(1).timeSlotMap.get(trialEnrMod.slcdDateDt);    
                
                
                //Filling start time
                List<String> timeList = trialEnrMod.slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);
                Time tempStTime = startTime.addMinutes(-(trialEnrMod.slcdDuration-15));
                Time tempEndTime = startTime.addMinutes(trialEnrMod.slcdDuration-15);
                
                String dayOfWeek  = ((DateTime)trialEnrMod.slcdDateDt).format('E');
                Set<String> tSet = new Set<String>();
                for(Time t = tempStTime; t <= tempEndTime; t=t.addMinutes(15)){
                    String minTmp = t.minute() != 0 ?  (t.minute() +'') : '00';
                    tSet.add(dayOfWeek+'-'+t.hour() + ':' + minTmp);
                }
                System.debug('@@@tSet'+tSet);
                
                Integer j = 0;
                while (j < slotList.size()){
                    // if(slotList.get(j).equalsIgnoreCase(trialEnrMod.slcdFullSlot)){
                    if(tSet.contains(slotList.get(j))){
                        slotList.remove(j);
                        enrModelList.get(1).slcdFullSlot= '';
                        enrModelList.get(1).slcdSlot = '';
                    }else{
                        j++;
                    }
                }
                
                enrModelList.get(1).timeSlotMap.put(trialEnrMod.slcdDateDt, slotList);
            }
        }
    }
    
    public Pagereference saveTrialData(){
        Savepoint sp = Database.setSavepoint();
        List<Account> refRelAccount = new List<Account>();
        Boolean isExisting = true;
        isError = false;
        errorMsg = '';
        try{
            String csmrRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(); 
            
            Map<String, Package__c> packMap = new Map<String, Package__c>();
            map<string,string> listOfGradePackageClass = new   map<string,string>(); //added by nishi: 3-sep-2020: for manage ossia packages
            Set<String> scldInst = new Set<String>();
            Set<String> scldTchr = new Set<String>();
            Set<Date>   scldDate = new Set<Date>();
            for(TrialEnrModel trMd : enrModelList){
                scldInst.add(trMd.slcdInstrument);
                
                if(trMd.slcdLsnType.equalsIgnoreCase('Group')){
                    scldTchr.add(trMd.slcdTchrId);
                    scldDate.add(trMd.slcdDateDt);
                }
            }
            
            List<Package__c> packLst = [SELECT Id,Name,Program__r.Instrument__c,Program__c,Program__r.Name, Location__r.Name 
                                        FROM Package__c 
                                        WHERE Location__c =: slcdCenter  AND Program__r.Status__c = 'Active' AND Active__c = True AND
                                        Program__r.Instrument__c IN: scldInst AND Type__c = 'Trial' AND Duration__c = '30'];
            
            if(packLst.size() == 0){
                errorMsg = 'Trial Package is not configured for this '+slcdInstrument+', Please contact to center admin.';
                isError = true;
                return null;
            }
            
            Map<String, Booking__c> grpLsnBookMap = new Map<String, Booking__c>(); 
            if(scldTchr.size() > 0 && scldDate.size() > 0){
                String bookGrpClsRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId();   
                for(Booking__c book: [SELECT Id, Class__c, Booking_Date__c, Class__r.Teacher__c, Class__r.Start_Time__c, Class__r.Package__c 
                                      FROM Booking__c
                                      WHERE RecordTypeId =: bookGrpClsRecId AND Class__r.Centre_Name__c =: slcdCenter AND Class__r.Active__c = True AND Class__r.Available_Capacity__c > 0 
                                      AND Class__c != null AND Booking_Date__c IN: scldDate AND  Class__r.Teacher__c IN:scldTchr
                                      // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                      And Class__r.Is_Makeup_Class__c = false]){
                                          String key = book.Class__r.Teacher__c +'#'+ book.Booking_Date__c+'#'+book.Class__r.Start_Time__c;                      
                                          grpLsnBookMap.put(key, book);
                                      }
                //added by nishi: 3-sep-2020: for manage ossia packages                      
                if(org == 'osia'){
                    for(Ossia_Group_Grade_Package__c objGradePackage: [SELECT Class_Name__c, Package__c,  Name, Id ,Package__r.Program__r.Instrument__c
                                                                        FROM Ossia_Group_Grade_Package__c
                                                                        Where Package__r.Program__r.Instrument__c In:scldInst
                                                                        // added by nishi : 11-Sep-2020: for We restrict those group classes for the trial enrolment process
                                                                        And Class_Name__r.Is_Makeup_Class__c = false]){
                        if(!listOfGradePackageClass.containsKey(objGradePackage.Class_Name__c)) {                       
                            listOfGradePackageClass.put(objGradePackage.Class_Name__c+'-'+objGradePackage.Package__r.Program__r.Instrument__c,objGradePackage.Package__c);
                        }
                    }
                }   
                //added by nishi: 3-sep-2020: for manage ossia packages                   
            }
            system.debug('listOfGradePackageClass'+listOfGradePackageClass);
            system.debug('grpLsnBookMap'+grpLsnBookMap);
            if(validateSlcdSlot()){
                errorMsg = 'Timeslot not available.';
                isError = true;
                return null;
            }
            
            for(Package__c pkg : packLst)
                packMap.put(pkg.Program__r.Instrument__c, pkg);
            
            //Fill Parent and Upasert parent record
            parentAcc.RecordTypeId   = csmrRecId;
            parentAcc.Centre_Name__c = slcdCenter;
            parentAcc.Instrument__c  = (new list<string>(scldInst) )[0] ;
            List<Account> centrList  = [SELECT Id, Name, Location__c, Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
            if(centrList.size() > 0){
                parentAcc.Location__c = centrList.get(0).Location__c;
                //Added by rajesh, 10th sep 2019. To do some sharing seeting stuff as per Ashish ji discussion
                if(centrList.get(0).Country__r.Country_Name__c != null)
                    parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
            }
            //Check that customer is already exist or not on the bases of email
            if(parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
              
                if(accList.size() > 0){
                    //Integer count = 0;
                    parentAcc.Id = accList.get(0).Id;
                }else{
                    system.debug('in else of refrel -->'+isOsiaApply);
                    //@Juneid 04-Aug 2020, Filling refrence code of rferree
                    if(String.isNotBlank(uniqueRefCode) && isOsiaApply == true){
                        refRelAccount = [SELECT Id,personContactId,billingcountry,Unique_Referral_Code__c FROM Account WHERE Unique_Referral_Code__c =:uniqueRefCode];
                        system.debug('refRelAccount-->'+refRelAccount);
                        if(refRelAccount.size() > 0){
                            if(refRelAccount[0].billingcountry ==centerCountry)
                                parentAcc.Referred_by__c =  refRelAccount[0].Id;
                        }
                        isExisting = false;
                    }
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
            
            //system.debug('PersonMobilePhoneCustom---> '+PersonMobilePhoneCustom);
            parentAcc.PersonMobilePhone = parentAcc.Phone;
            //parentAcc.Phone = PersonMobilePhoneCustom;
            system.debug('parentAcc'+parentAcc);
            upsert parentAcc;
            
            List<Account> stuList = new List<Account>();
            List<Enrolment__c> enrList = new List<Enrolment__c>();
            List<Booking__c> bookList = new List<Booking__c>();
            
            String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();    
            for(TrialEnrModel trMd : enrModelList){
                //Fill Student Details
                Account studentAcc = trMd.studentAcc;  
                studentAcc.RecordTypeId   = csmrRecId;
                if(!isParAlsoAStudent){
                    //To find existing student for the sepecific parent
                    if(String.isNotBlank(trMd.slcdExistingStu) && !trMd.slcdExistingStu.equalsIgnoreCase('new'))
                        studentAcc.Id = trMd.slcdExistingStu;                        
                    studentAcc.Parent__c = parentAcc.Id;
                    studentAcc.Current_Engagement_Status__c = ConstantsClass.activeStatus;                    
                    studentAcc.Centre_Name__c = slcdCenter;
                    if(centrList.size() > 0){
                        studentAcc.Location__c = centrList.get(0).Location__c;
                        if(centrList.get(0).Country__r.Country_Name__c != null)
                            studentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                    }     
                }else{
                    studentAcc = parentAcc;
                }   
                If(trMd.stuSameAsChild1){
                    studentAcc = stuList.get(0);
                }else{
                    stuList.add(studentAcc);
                }
                
                //Fill Enrolment details
                Enrolment__c enrl  = new Enrolment__c();
                enrl.Parent__c     = parentAcc.Id;
                enrl.Learning_Style__c = studentAcc.Learning_Style__c;
                enrl.Student__r    = studentAcc;
                enrl.Type__c       = ConstantsClass.typeTrial;
                enrl.Stage__c      = ConstantsClass.requestedSubStatus;
                enrl.Center__c     = slcdCenter;
                enrl.Teacher__c    = trMd.slcdTchrId;
                enrl.Previous_Experience_if_any__c  = trMd.stuPreExperience;
                enrl.Cancellation_Policy_Agreed__c  = true;
                enrl.I_want_to_receive_latest_newsletter__c = iWantReceivedLatestNew;
                //@Juneid 07 Aug 2020
                if(String.isNotBlank(uniqueRefCode) && isExisting == false && isOsiaApply == true && refRelAccount[0].billingcountry ==centerCountry){
                    enrl.Referred_by__c = refRelAccount[0].id;
                    prsonContactId = refRelAccount[0].personContactId;
                    enrl.Referral_code_used__c = uniqueRefCode;
                }
                if(packMap.containskey(trMd.slcdInstrument))
                    enrl.Package__c = packMap.get(trMd.slcdInstrument).Id;
                
                enrl.Trial_Date__c = trMd.slcdDateDt;                    
                //Filling start time
                List<String> timeList = trMd.slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                enrl.Trial_Start_Time__c = startTime;
                
                
                if(String.isNotBlank(formName))
                    enrl.Form_Name__c = formName;
                
                //Added by Rajesh, 6th Aug 2019. To store trial source on enrolment/case object 
                if(String.isNotBlank(trialSource))
                    enrl.Trial_Source__c = trialSource;
                
                if(String.isNotBlank(srcType))
                    enrl.Source_Type__c = srcType;
                if(isSiteGuestUser)
                    enrl.Source_Type__c = 'Web';
                
                if(trMd.slcdLsnType.equalsIgnoreCase('Group')){
                    String key = enrl.Teacher__c +'#'+ enrl.Trial_Date__c+'#'+enrl.Trial_Start_Time__c;    
                    system.debug('key'+key);                  
                    if(grpLsnBookMap.containsKey(key)){
                        enrl.Class__c   = grpLsnBookMap.get(key).Class__c;
                        //start: added by nishi: 3-Sep-2020: for manage Ossia group grade Packages
                        if(org == 'osia'){
                            system.debug('check package' + (listOfGradePackageClass.containsKey(grpLsnBookMap.get(key).Class__c+'-'+trMd.slcdInstrument)));
                            if(listOfGradePackageClass.containsKey(grpLsnBookMap.get(key).Class__c+'-'+trMd.slcdInstrument)){
                                enrl.Package__c =listOfGradePackageClass.get(grpLsnBookMap.get(key).Class__c+'-'+trMd.slcdInstrument);
                            }
                        }else{
                            enrl.Package__c = grpLsnBookMap.get(key).Class__r.Package__c;
                        }
                         // end: added by nishi: 3-Sep-2020: for manage Ossia group grade Packages
                        enrl.Type__c    = 'Group';
                    }
                }
                enrList.add(enrl);
                
                //Fill Bookings
                Booking__c book = new Booking__c(Student__r = studentAcc, Teacher_Account__c = trMd.slcdTchrId, Enrolment__r = enrl);
                book.Center__c =  slcdCenter;
                book.Type__c   = ConstantsClass.typeTrial;
                book.Allow_Online_Guest_Joining__c=true;// added by Ravi on 7 sept 2020 for trial booking.
                book.Status__c = ConstantsClass.statusPending;
                book.RecordTypeId = bookLessRecId;
                book.Package__c = enrl.Package__c;
                book.Booking_Date__c = enrl.Trial_Date__c;
                book.Start_Time__c = enrl.Trial_Start_Time__c;
                book.End_Time__c = book.Start_Time__c.addMinutes(trMd.slcdDuration);
                if(trMd.slcdLsnType.equalsIgnoreCase('Group')){
                    String key = enrl.Teacher__c +'#'+ enrl.Trial_Date__c+'#'+enrl.Trial_Start_Time__c;                      
                    if(grpLsnBookMap.containsKey(key)){
                        book.RecordTypeId   =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Lesson').getRecordTypeId();
                        //book.Type__c      = 'Group Lesson';
                        book.Group_Class__c =  grpLsnBookMap.get(key).Id;
                        //start: added by nishi: 3-Sep-2020: for manage Ossia group grade Packages
                        if(org != 'osia'){
                            book.Package__c = grpLsnBookMap.get(key).Class__r.Package__c;
                        }
                        //end: added by nishi: 3-Sep-2020: for manage Ossia group grade Packages
                    }
                }
                bookList.add(book);
                
                if(isAureusAtHome){
                    Booking__c befBook = new Booking__c(Student__r = studentAcc, Teacher_Account__c = trMd.slcdTchrId, Enrolment__r = enrl);
                    befBook.RecordTypeId  = bookLessRecId;
                    befBook.Center__c =  slcdCenter;
                    befBook.Type__c    = ConstantsClass.busyBookingType;
                    book.Status__c     = ConstantsClass.scheduledStatus;
                    befBook.Category__c= 'Travel';
                    befBook.Remarks__c = 'Travel time slot for home trial booking';
                    book.Package__c = enrl.Package__c;
                    befBook.Start_Time__c = book.Start_Time__c.addMinutes(-trvlDuration);
                    befBook.End_Time__c   = book.Start_Time__c;
                    befBook.Booking_Date__c = book.Booking_Date__c;
                    if(trMd.slcdLsnType.equalsIgnoreCase('Group')){
                        String key = enrl.Teacher__c +'#'+ enrl.Trial_Date__c+'#'+enrl.Trial_Start_Time__c;                      
                        if(grpLsnBookMap.containsKey(key)){
                            book.RecordTypeId   =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Lesson').getRecordTypeId();
                            //book.Type__c      = 'Group Lesson';
                            book.Group_Class__c =  grpLsnBookMap.get(key).Id;
                            //start: added by nishi: 3-Sep-2020: for manage Ossia group grade Packages
                            if(org != 'osia'){
                                book.Package__c = grpLsnBookMap.get(key).Class__r.Package__c;
                            }
                            //end: added by nishi: 3-Sep-2020: for manage Ossia group grade Packages
                        }
                    }
                    bookList.add(befBook);    
                }
            }
            
            if(stuList.size() > 0){
                system.debug('stuList'+stuList);
                upsert stuList;
                system.debug('enrList'+enrList);
                for(Enrolment__c enrl: enrList)
                    enrl.Student__c = enrl.Student__r.Id;
                
                    insert enrList;
                    system.debug('bookList'+bookList);
                for(Booking__c book : bookList){
                    book.Student__c = book.Student__r.Id;
                    book.Enrolment__c = book.Enrolment__r.Id;
                }
                insert bookList;    
                if(enrList != null && enrList.size() > 0){
                    sendMailToReffrel(enrList[0]);
                }
                
                if(!isSiteGuestUser){
                    for(Enrolment__c enrl: enrList)
                        enrl.Stage__c = 'Booked';
                    update enrList;
                    
                    for(Booking__c book : bookList)
                        book.Status__c = ConstantsClass.scheduledStatus;
                    update bookList;
                }                
            }
            if(isSiteGuestUser){
                if(org=='osia')
                    return new Pagereference(Label.Trial_booking_confirmation_url_for_Ossia);  
                else
                    return new Pagereference(Label.Trial_booking_confirmation_url); 
            }
            else
                return new Pagereference('/apex/freetrial_thankIpad?org='+org);  
            
            //Pagereference pg = new Pagereference('https://aureusacademy.com/trial-booking-confirmation'); 
            // errorMsg = 'success';
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            System.debug('Error:  '+e.getStackTraceString() +e.getLineNumber());
            errorMsg = e.getMessage();
            isError = true;
            return null;
        }
        
    }
    @TestVisible
    private Boolean validateSlcdSlot(){
        Boolean isValidateFuture = false; 
        
        if(enrModelList.size() > 0){
            Set<String> bookTypeSet    = new Set<String>{'Trial', 'Regular', 'Make-Up', 'Ad-hoc'};
                Set<String> bookStatusSet  = new Set<String>{'Pending', 'Scheduled', 'Re-scheduled', 'Completed','Blocked'};
                    String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); 
            
            String soqlStr = 'SELECT Id,Name,Booking_Date__c,Duration__c,Start_Time__c,End_Time__c,Type__c,Teacher_Account__c FROM Booking__c ';
            soqlStr += ' WHERE RecordTypeId =: bookLessRecId AND Start_Time__c != null AND End_Time__c != null AND Status__c IN: bookStatusSet AND';
            soqlStr += ' ((Type__c IN: bookTypeSet) OR (Type__c = \'Busy\' AND Category__c != \'Placeholder\')) ';
            
            Map<String, TrialEnrModel> trialEnrMap = new Map<String, TrialEnrModel>();
            for(TrialEnrModel trMd : enrModelList){
                String tchrId = trMd.slcdTchrId;
                Date   slcdDt = trMd.slcdDateDt;
                soqlStr += ' AND (Teacher_Account__c =: tchrId AND (Booking_Date__c >=: slcdDt AND Booking_Date__c <=: slcdDt)) ';
                
                List<String> timeList = trMd.slcdSlot.split(':');
                Time startTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0);                 
                String key = trMd.slcdTchrId+':'+trMd.slcdDateDt+':'+startTime;
                trialEnrMap.put(key,trMd);
            }
            System.debug('query -->'+soqlStr);
            for(Booking__c book : Database.query(soqlStr)){    
                String key = book.Teacher_Account__c +':'+ book.Booking_Date__c +':'+ book.Start_Time__c;
                if(trialEnrMap.containsKey(key)){
                    TrialEnrModel trMd = trialEnrMap.get(key);
                    List<String> timeList = trMd.slcdSlot.split(':');            
                    Time sltdStartTime = Time.newInstance(Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]) , 0, 0); 
                    Time sltdEndTime   = sltdStartTime.addMinutes(trMd.slcdDuration); 
                    
                    if((sltdStartTime >= book.Start_Time__c && sltdEndTime <= book.End_Time__c) && (sltdEndTime >= book.Start_Time__c && sltdEndTime <= book.End_Time__c)){
                        isValidateFuture = true;
                        break;          
                    }
                }
            }
        }
        return isValidateFuture;
    }
    //@Juneid, 05 Aug 2020, This methos is check customer is exist of not and apply refrel code 
    public Pagereference checkExistingCustomer(){
        if(checkOsiaForRefrel(slcdCenter) == true){
            isOsiaApply =  true;
            if(parentAcc.PersonEmail != null){
                List<Account> accList = [SELECT Id,Name FROM Account WHERE PersonEmail =: parentAcc.PersonEmail]; 
                if(accList.size() > 0){
                    //@Juneid 04-Aug-2020 , Through error of Existing user
                    if(String.isNotBlank(uniqueRefCode)){
                        errorMsg = 'System found you as an existing customer and hence the referral cannot be applied';
                        isError = true;
                        return null;
                    }
                }
            }
        }else{
            uniqueRefCode = '';
        }
        return null;
    }
    //@Juneid  05 Aug 2020, This methos is used to check that centaer is osia or not
    public  Boolean checkOsiaForRefrel(string centerName){
        Boolean isOsia = false;
        List<Account> centerList = [SELECT id,name,Country__r.Country_Name__c,Organisation__c,Organisation__r.name FROM Account where id =:centerName];
        if(String.isNotBlank(System.Label.Ossia_Organisation_Name)){
            String osiaName = System.Label.Ossia_Organisation_Name;
            if(centerList.size() > 0){
                centerCountry = centerList[0].Country__r.Country_Name__c;//Storing center country
                if(osiaName == centerList[0].Organisation__r.name){
                    //@Juneid 05 Aug 2020, getting Custtom setting value for osia
                    Ossia_Referral_Discount__c osiaRefSetting = Ossia_Referral_Discount__c.getOrgDefaults();
                    if(osiaRefSetting.Ossia_Referral_Discount__c ==  true)
                        return true;
                    else 
                        return false;
                }
                return true;
            }
        }
        return false;
    }
    //@Juneid 07 Aug 2020 , Send Mail to refrel
    public void sendMailToReffrel(Enrolment__c enrol){
        if(enrol.Id !=Null){
            if(enrol.Referred_by__c !=Null && String.isNotBlank(enrol.Referral_code_used__c)){
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                  //@Juneid 26 Aaug 2020, Orgnization wise templates
                List<EmailTemplate>emailTemplates =  new List<EmailTemplate>();
                if(org == 'osia'){
                     emailTemplates =  [Select Id,name,developerName from EmailTemplate where developerName =:'Ossia_Send_Trial_Referral_Enrollment_Details']; 
                }else{
                    emailTemplates =  [Select Id,name,developerName from EmailTemplate where developerName =:'Send_Trial_Referral_Enrollment_Details']; 
                }
                
                
                if(emailTemplates.size() > 0){
                    Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>();                    
                    List<OrgWideEmailAddress> orgWide=[SELECT Address, DisplayName, Id FROM OrgWideEmailAddress where Address=:Label.Trial_Enrollment_Org_Wide];
                    //@Juneid 06 Aug Aug 2020, This email is sent to reffrel 
                    Messaging.SingleEmailMessage refrenceMail = Messaging.renderStoredEmailTemplate(emailTemplates[0].Id, prsonContactId, enrol.Referred_by__c);
                    
                    if(orgWide.size() > 0)
                        refrenceMail.setOrgWideEmailAddressId(orgWide[0].id);
                    
                    if(prsonContactId !=Null){
                        refrenceMail.setTargetObjectId(prsonContactId);
                        refrenceMail.saveAsActivity = true;
                        refrenceMail.setWhatId(enrol.Referred_by__c);
                        refrenceMail.setTemplateId(emailTemplates[0].Id);
                        emailList.add(refrenceMail); 
                    }
                    
                    if(emailList.size() > 0){
                        Messaging.sendEmail(emailList);
                    }
                }
            }
        }
    }
    
    public Class TrialEnrModel{
        public String  slcdInstrument{get;set;}
        public Integer slcdDuration{get;set;}
        public String  slcdDate{get;set;}
        public Date    slcdDateDt{get;set;}
        public String  slcdFullSlot{get;set;}
        public String  slcdSlot{get;set;}
        public String  slcdTchrId{get;set;}
        public String  slcdTchrName{get;set;}
        public Date    calStartDate{get;set;}
        public Date    calEndDate{get;set;}
        public Account studentAcc{get;set;}
        public String  stuPreExperience{get;set;}
        public String slcdExistingStu{get;set;}
        public Map<Date, List<String>>  timeSlotMap{get;set;}
        public Map<Date, String>  timeSlotStrMap{get;set;}
        public List<TeacherModel> slcdSlotTchrs{get;set;}
        public Map<String,String> existingStuOpt{get;set;}
        public Boolean stuSameAsChild1{get;set;}
        public List<String> instrumentList{get;set;}
        public Map<String,String> disabledInstrument{get;set;}
        public Integer classMinAge{get;set;}
        public Integer classMaxAge{get;set;}
        
        Map<String,Map<String, List<TeacherModel>>> teachModSlotMap;
        public String  slcdLsnType{get;set;}
        public TrialEnrModel(){
            this.slcdInstrument = '';
            this.slcdDuration   = 30;
            this.slcdSlot = '';
            //this.calStartDate   = System.today().toStartofWeek();
            this.calStartDate   = System.today();
            this.calEndDate     = calStartDate.addDays(6);
            this.timeSlotMap    = new Map<Date, List<String>>();
            this.slcdSlotTchrs  = new List<TeacherModel>();
            this.timeSlotStrMap = new Map<Date, String>();
            this.existingStuOpt = new Map<String,String>();
            
            this.teachModSlotMap= new Map<String,Map<String, List<TeacherModel>>>();
            this.studentAcc     = new Account();
            this.stuSameAsChild1= false;
            this.instrumentList = new List<String>();
            this.disabledInstrument = new Map<String,String>();
            this.slcdLsnType    = 'Individual';
            this.classMinAge    = 0; 
            this.classMaxAge    = 0;
        }
    }
    /*
public class TimeSlotModelCntrl{
public List<TeacherModel> teachModList{get;set;}        
Map<String, List<TeacherModel>> teachModSlotMap;

public TimeSlotModelCntrl(){
teachModList  = new List<TeacherModel>();
teachModSlotMap = new Map<String, List<TeacherModel>>();
}
}*/
    
    
    public class TeacherModel{
        public String tecId{get;set;}
        public String tecName{get;set;}
        public String teacBio{get;set;}
        public String teacBioDescribe{get;set;}
        public String highestQualification{get;set;}
        public List<String> highestQualificationLst{get;set;}
        
        public String attachmentId{get;set;}
        
        public TeacherModel(String tecId,String tecName,String teacBioCon,String highestQualification, List<String> highestQualificationLst){
            this.tecId   = tecId;
            this.tecName = tecName;
            this.teacBio = teacBioCon;
            this.teacBioDescribe = teacBioCon;
            this.highestQualification = highestQualification;
            this.highestQualificationLst = highestQualificationLst;
        }
    }
}