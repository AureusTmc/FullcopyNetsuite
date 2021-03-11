/*
    Name : WaitingEnrolmentListCtrl
    Desription :  a.	Identify all those enrolment whose prefferred time slots are free
    Author : Nishi Jain
    Date : 15-Feb-2021
	Test class 	: AutomatingMakeupEnrolmentTest
	page class  :CreateNewMakeupBookings
	component	:WaitListingEnrolmentListCMP
*/
public with sharing class WaitingEnrolmentListCtrl {
    public Datetime enrolmentEffectiveDate{get;set;}
    public string bookingDate{get;set;}
    public string prefferedDate{get;set;}
    public String weekday{get;set;}
    public String enrolmentId{get;set;}
    public String relatedCenterId{get;set;}
    public Boolean isOssiaOrg{get;set;}
     public Boolean isError{get;set;}
     public Boolean isSucess{get;set;}
    public String errorMessage{get;set;}
    public String selectedtimeslotRealTime{get;set;}
    public String selectedtimeSlot{get;set;}
    public String selectedduration{get;set;}
    List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
    Enrolment__c objEnrolment = new Enrolment__c();
    List<Booking__c> listOfBooking = new List<Booking__c>();
    Booking__c objBooking = new Booking__c();
   public WaitingEnrolmentListCtrl() {
        listOfEnrolment = new List<Enrolment__c>();
        isError = false;
        isOssiaOrg = false;
        isSucess = false;
    }
   
    public List<PrefferdEnrolment>  getlistOfPrefferdEnrolments(){
        listOfEnrolment = new List<Enrolment__c>();
        isError = false;
        isOssiaOrg = false;
        isSucess = false;
        system.debug('enrolmentId'+relatedCenterId);
        //enrolmentEffectiveDate =system.now().addDays(integer.valueOf(label.Waiting_Enrolment_Notification_Days));
        List<PrefferdEnrolment> listOfprefferdEnrolments = new List<PrefferdEnrolment>(); 
        if(string.isNotBlank(relatedCenterId)){
            Account objCenter = [select id,Organisation__r.Name,Waitlisting_Date__c from account  where id=:relatedCenterId];
            if(string.isnotBlank(ApexPages.currentPage().getParameters().get('prefferedDate'))){
                string prefferedDay  = ApexPages.currentPage().getParameters().get('prefferedDate').replaceAll('/','-');
               enrolmentEffectiveDate = Datetime.newInstance(date.newInstance(integer.valueOf(prefferedDay.split('-')[2]) , integer.valueOf(prefferedDay.split('-')[1]), integer.valueOf(prefferedDay.split('-')[0])),system.now().time());
             }else{
               // enrolmentEffectiveDate =system.now().addDays(integer.valueOf(label.Waiting_Enrolment_Notification_Days));
               enrolmentEffectiveDate = Datetime.newInstance(objCenter.Waitlisting_Date__c,system.now().time());
            }
            weekday = enrolmentEffectiveDate.format('EEEE');
            bookingDate = enrolmentEffectiveDate.format('dd, MMM yyyy');
            listOfEnrolment = getEnrolmentList(relatedCenterId,enrolmentEffectiveDate);
            system.debug('getEnrolmentList.'+getEnrolmentList.size()> 0);
            if(listOfEnrolment != null && listOfEnrolment.size()>0 ){
                listOfprefferdEnrolments = getlistOfWaitingEnrolments(relatedCenterId,enrolmentEffectiveDate,listOfEnrolment);
                system.debug('listOfprefferdEnrolments'+listOfprefferdEnrolments);
                if(listOfprefferdEnrolments == null || listOfprefferdEnrolments.size() == 0){
                    isError = true;
                    errorMessage ='There is no preferred enrolment time slots found.';
                }
                if(objCenter.Organisation__r.Name == System.Label.Ossia_Organisation_Name){
                    isOssiaOrg= true;
                } 
            }else{
                isError = true;
                errorMessage ='There is no preferred enrolment time slots found.';
            }
        }else{
            isError = true;
            errorMessage ='Related Center Not Found';
        }
        system.debug('isError'+isError);
        system.debug('errorMessage'+errorMessage);
        return listOfprefferdEnrolments;//mapOfavailTimeslots;
    }
 
    public List<PrefferdEnrolment> getlistOfWaitingEnrolments(string centerId,datetime enrolmentEffectiveDate,List<Enrolment__c> listOfPrefferedEnrolment){
        set<string> preferredTeacherDays = new set<string>(); 
        //set<string> preferredEnrolmentLessonDays = new set<string> (); 
        set<string> setofCenterIds = new set<string>();
        list<string> listOfTeacherWithDuration = new list<string>();
        List<Enrolment__c> listOfPrefferedRegularEnrolment = new List<Enrolment__c>();
        List<Enrolment__c> listOfPrefferedTrailEnrolment = new List<Enrolment__c>();
        List<PrefferdEnrolment> listOfprefferdEnrolmentList = new List<PrefferdEnrolment>();
        for(Enrolment__c objEnrolment: listOfPrefferedEnrolment){
            preferredTeacherDays.add(objEnrolment.Preferred_Teacher__c);
            //preferredEnrolmentLessonDays.add(objEnrolment.Preferred_Day__c);
            setofCenterIds.add(objEnrolment.Center__c);
            if(string.isNotBlank(objEnrolment.Package__c) && objEnrolment.Package__r.Duration__c != null){
                listOfTeacherWithDuration.add(objEnrolment.Package__r.Duration__c);
            }
            if(objEnrolment.Type__c == ConstantsClass.typeTrial && (objEnrolment.Stage__c =='Requested' && objEnrolment.Stage__c == 'Booked')){
                listOfPrefferedTrailEnrolment.add(objEnrolment);
            }else{
                listOfPrefferedRegularEnrolment.add(objEnrolment);
            }
        }
        Map<string,MakeupEnrolmentBatchHelper.MakeupAvailMinDetails> mapOfMakeupAvailMinRegularDetails = MakeupEnrolmentBatchHelper.getMultipleTeacherWorkingHourTimeSlotList(setofCenterIds ,preferredTeacherDays,new set<string>{ enrolmentEffectiveDate.format('E')},listOfTeacherWithDuration,enrolmentEffectiveDate,false);
        Map<string,MakeupEnrolmentBatchHelper.MakeupAvailMinDetails> mapOfMakeupAvailMinTrailDetails = MakeupEnrolmentBatchHelper.getMultipleTeacherWorkingHourTimeSlotList(setofCenterIds ,preferredTeacherDays,new set<string>{ enrolmentEffectiveDate.format('E')},listOfTeacherWithDuration,enrolmentEffectiveDate,true);
        
        if((mapOfMakeupAvailMinRegularDetails != null && mapOfMakeupAvailMinRegularDetails.size() > 0) || (mapOfMakeupAvailMinTrailDetails != null && mapOfMakeupAvailMinTrailDetails.size() > 0)){
            system.debug('@mapOfMakeupAvailMinRegularDetails'+mapOfMakeupAvailMinRegularDetails);
            system.debug('@mapOfMakeupAvailMinTrailDetails'+mapOfMakeupAvailMinTrailDetails);
            Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails> mapOfEnrolmentDetails = new Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails>();
            if(mapOfMakeupAvailMinRegularDetails != null && mapOfMakeupAvailMinRegularDetails.size() > 0 && listOfPrefferedRegularEnrolment != null && listOfPrefferedRegularEnrolment.size() > 0 ){
                mapOfEnrolmentDetails.putAll(MakeupEnrolmentBatchHelper.sendPreferredEnrolmentNotification(listOfPrefferedRegularEnrolment,mapOfMakeupAvailMinRegularDetails,listOfTeacherWithDuration,enrolmentEffectiveDate));
            }
            if(mapOfMakeupAvailMinTrailDetails != null && mapOfMakeupAvailMinTrailDetails.size() > 0 && listOfPrefferedTrailEnrolment != null && listOfPrefferedTrailEnrolment.size() > 0){
                mapOfEnrolmentDetails.putAll(MakeupEnrolmentBatchHelper.sendPreferredEnrolmentNotification(listOfPrefferedTrailEnrolment,mapOfMakeupAvailMinTrailDetails,listOfTeacherWithDuration,enrolmentEffectiveDate));
            } 
            system.debug('@mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
            if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                system.debug('mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
                // we get templete according to organisation
                Set<string> availabletime =new Set<string>() ;
                Set<string>  availableMakeupTimeSlot =new Set<string>() ;
                if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                    List<Enrolment__c> updateEnrolments= new  List<Enrolment__c>();
                    for(MakeupEnrolmentBatchHelper.EnrolmentDetails objEnrolmentDetails: mapOfEnrolmentDetails.values()){
                        if(objEnrolmentDetails.mapOfavailTimeslots != null && objEnrolmentDetails.mapOfavailTimeslots.size() > 0){
                            DateTime enrolmentBeforeStartTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolmentDetails.objEnrolment.Preferred_Start_Time__c);
                            DateTime enrolmentBeforeEndTime = DateTime.newInstance(enrolmentEffectiveDate.date(),  objEnrolmentDetails.objEnrolment.Preferred_End_time__c);
                            listOfprefferdEnrolmentList.add(new PrefferdEnrolment(enrolmentBeforeStartTime.format('h:mm a'),enrolmentBeforeEndTime.format('h:mm a'),objEnrolmentDetails.objEnrolment));
                                   
                        }
                    }
                }
            }
        }
        return listOfprefferdEnrolmentList;
    }

    public class PrefferdEnrolment{
        public string enrolmentStartTime{get;set;}
        public string enrolmentEndTime{get;set;}
        public Enrolment__c objEnrolment{get;set;}
        public PrefferdEnrolment(string enrolmentStartTime,string enrolmentEndTime,Enrolment__c objEnrolment){
            this.enrolmentStartTime = enrolmentStartTime;
            this.enrolmentEndTime = enrolmentEndTime;
            this.objEnrolment = objEnrolment;
        }
     }
  
    public List<Enrolment__c> getEnrolmentList(string centerId,datetime enrolmentEffectiveDate){
        Set<String>enrolStatus = New Set<String>{'Emailed'};
        Set<String>  enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.typeTrial}; 
        Set<String>  enroledStage = New Set<String>{ConstantsClass.enroledStatus,ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment,'Requested','Booked'};
        String weekday = enrolmentEffectiveDate.format('EEEE');
        string queryString = 'SELECT Id,Name,Student__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__r.name ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
        queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
        queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId ,Trial_Start_Time__c FROM Enrolment__c ';
        queryString+= ' WHERE Type__c In: enrolTypes ';
        queryString+= ' AND Waitlist_Status__c In: enrolStatus ';
        queryString+= ' AND Stage__c In: enroledStage ';
        queryString+= ' AND Preferred_Teacher__c != null ';
        queryString+= ' AND Preferred_End_time__c != null ';
        queryString+= ' AND Preferred_Start_Time__c != null ';
        queryString+= ' AND Preferred_Day__c != null ';
        queryString+= ' AND Preferred_Day__c =: weekday ';
        if(string.isNotBlank(centerId)){
            queryString+= ' AND Center__c =:centerId ';
        }
        return Database.query(queryString);
    }
   
}