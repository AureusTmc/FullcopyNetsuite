/*
Name        :    ReenrolmentProcessController
Date        :    3 Mar 2021
Author      :
Description :    This controller is used for Re-enrolment
                    Parent to click on the link on email then we will open a new page with the list of active and cancelled enrolments with the following information:
                    Enrolment no
                    Student name
                    Teacher name
                    Day and Timeslot
                    Package
                    Status
                    Parent can click on the Re-enrol button for the enrolment to be resumed.

*/
public with Sharing class ReenrolmentProcessController{
    public List<Enrolment__c> listOfEnrolment{get;set;}
    public Map<Id,Enrolment__c> mapOfEnrolment{get;set;}
    public String enrolmentId{get;set;}
    public Account parentAcc{get;set;}
    public Boolean isOssiaOrg{get;set;}
    public boolean isError{get;set;}
    public string  errorMsg{get;set;}
    public ReenrolmentProcessController(ApexPages.StandardController sc){
        isOssiaOrg = false;
        isError = false;
        parentAcc = (Account)sc.getRecord();
        parentAcc = [SELECT Id,Parent__c,Centre_Name__r.Organisation__r.Name, Centre_Name__c,Stripe_Customer_Id__c,PersonEmail FROM Account WHERE Id=: parentAcc.id];
        listOfEnrolment = new List<Enrolment__c>();
        mapOfEnrolment = new Map<Id,Enrolment__c>();
        if(string.isNotBlank(parentAcc.Centre_Name__c) && string.isNotBlank(parentAcc.Centre_Name__r.Organisation__c) && System.Label.Ossia_Organisation_Name == parentAcc.Centre_Name__r.Organisation__r.Name){
            isOssiaOrg= true;
        }
        if(string.isNotBlank(parentAcc.id)){
            set<String> enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus};
            mapOfEnrolment = new Map<Id,Enrolment__c>([SELECT Id, Name, Center__r.Organisation__c,Center__r.Name,Center__c, Lesson_Day__c, Lesson_Start_time__c, Package__r.name,Package__c, 
                                Parent__r.name,Parent__c, Student__r.name,Student__c, Teacher__r.name, Teacher__c, type__C,Stage__c ,Center__r.Country__r.Name,
                                student__r.Learning_Style__c,Parent__r.Learning_Style__c,Previous_Experience_if_any__c,I_want_to_receive_latest_newsletter__c,
                                Center__r.Organisation__r.Name
                                FROM Enrolment__c
                                where Parent__c =:parentAcc.id
                                AND Type__c In: enrolTypes ]);
            listOfEnrolment = mapOfEnrolment.values();
        }
    }

    public Pagereference redirectToEnrolmentProcess(){
        isError = false;
        //string pageRef ='/apex/enrolmentprocess_ipad';
        if(mapOfEnrolment.containsKey(enrolmentId)){
            // string orgType ='aureus';
            // if(String.isNotBlank(mapOfEnrolment.get(enrolmentId).Center__r.Organisation__r.name) && 
            //         mapOfEnrolment.get(enrolmentId).Center__r.Organisation__r.name == Label.Ossia_Organisation_Name)
            //     orgType = 'ossia';
            // else 
            //     orgType ='aureus';
            // pageRef += '?currentOrg='+mapOfEnrolment.get(enrolmentId).Center__r.Organisation__c+'&orgType='+orgType+'&slcdCenter='+mapOfEnrolment.get(enrolmentId).Center__c+'&countryCode='+mapOfEnrolment.get(enrolmentId).Center__r.Country__r.Name;
            // pageRef += '&teahcerId='+mapOfEnrolment.get(enrolmentId).Teacher__c+'&packageId='+mapOfEnrolment.get(enrolmentId).Package__c+'&StudentId='+(string.isNotBlank(mapOfEnrolment.get(enrolmentId).Student__c) ? mapOfEnrolment.get(enrolmentId).Student__c :'');
            // pageRef += '&Parent__c='+mapOfEnrolment.get(enrolmentId).Parent__c+'&lessonday='+mapOfEnrolment.get(enrolmentId).Lesson_Day__c+'&time='+mapOfEnrolment.get(enrolmentId).Lesson_Start_time__c;
            // pageRef += '&pagetype=reenrolment';
            return saveTrialData(mapOfEnrolment.get(enrolmentId));
        }else{
            isError = true;
            errorMsg = 'Enrolment Id not found';
        }
        return null;
    }
    
    public Pagereference saveTrialData(Enrolment__c objenrolment){
        PageReference pageRef;
        Savepoint sp = Database.setSavepoint();
        Boolean isExisting = true;
        isError = false;
        errorMsg = '';
        try{
             string orgType ='aureus';
            if(String.isNotBlank(mapOfEnrolment.get(enrolmentId).Center__r.Organisation__r.name) && 
                    mapOfEnrolment.get(enrolmentId).Center__r.Organisation__r.name == Label.Ossia_Organisation_Name)
                orgType = 'ossia';
            else 
                orgType ='aureus';
            string slcdCenter = objenrolment.Center__c;
            //Fill Parent and Upasert parent record
            if(!test.isRunningTest()){
                parentAcc.Centre_Name__c = slcdCenter;
            }
            List<Account> centrList  = [SELECT Id, Name, Location__c,Organisation__c, Country__r.name,Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: slcdCenter];
            if(centrList.size() > 0){
                parentAcc.Location__c = centrList.get(0).Location__c;
               // To do some sharing seeting stuff as per Ashish ji discussion
                if(centrList.get(0).Country__r.Country_Name__c != null)
                    parentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
            }
            //Check that customer is already exist or not on the bases of email
            upsert parentAcc;
            List<Account> stuList = new List<Account>();
            List<Enrolment__c> enrList = new List<Enrolment__c>();
            Account studentAcc = new  Account();
            if(string.isNotBlank(objenrolment.student__c)){
                //Fill Student Details
                studentAcc.id = objenrolment.student__c;  
                if(!test.isRunningTest()){
                    studentAcc.Centre_Name__c = slcdCenter;
                }
                if(centrList.size() > 0){
                    studentAcc.Location__c = centrList.get(0).Location__c;
                    if(centrList.get(0).Country__r.Country_Name__c != null)
                        studentAcc.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                }   
                stuList.add(studentAcc);    
            }
                //Fill Enrolment details
                Enrolment__c enrl  = new Enrolment__c();
                enrl.Parent__c     = parentAcc.Id;
                enrl.Learning_Style__c = objenrolment.student__r.Learning_Style__c;
                enrl.Student__r    = studentAcc;
                enrl.Type__c       = objenrolment.Type__c == ConstantsClass.typeRegular ?  ConstantsClass.typeTrial : ConstantsClass.enrolGroupType;
                enrl.Stage__c      = ConstantsClass.PendingEnrolment;
                //enrl.Trial_Date__c = system.today();                    
                //Filling start time
                //enrl.Trial_Start_Time__c = system.now().time();
                
                 // added by nishi: 28-Sep-2020: for stop active process builer validations
                if(!test.isRunningTest()){
                    enrl.Center__c     = slcdCenter;
                }
                enrl.Previous_Experience_if_any__c  = objenrolment.Previous_Experience_if_any__c;
                enrl.Cancellation_Policy_Agreed__c  = true;
                enrl.I_want_to_receive_latest_newsletter__c = objenrolment.I_want_to_receive_latest_newsletter__c;
                enrl.Student__c = objenrolment.Student__c;
                enrl.teacher__c = objenrolment.teacher__c;
                enrl.package__c = objenrolment.package__c;
                enrl.Lesson_Day__c = objenrolment.Lesson_Day__c;
                enrl.Lesson_Start_time__c = objenrolment.Lesson_Start_time__c;
                //enrl.Lessons_Start_Date__c  = system.today();
                datetime lessondate = system.now();
                for(integer i=1;i<=7;i++){
                    if(lessondate.format('EEEE') == objenrolment.Lesson_Day__c){
                        break;
                    }else{
                        lessondate = system.now().addDays(i);
                    }
                }
                enrl.Lessons_Start_Date__c  = lessondate.date();  
                enrList.add(enrl);
            
            
            if(stuList.size() > 0){
                system.debug('stuList'+stuList);
                upsert stuList;
            }
           
            
            insert enrList;
            String userName = UserInfo.getUserName();
            if(userName.contains('site')){
                pageRef = new PageReference('/enrolmentprocess_ipad');
            }else{
                pageRef = new PageReference('/apex/enrolmentprocess_ipad?'+'currentOrg='+objenrolment.Center__r.Organisation__c+'&'+'orgType='+orgType);//+'&'+'pagetype=reEnrolment'
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
    
}