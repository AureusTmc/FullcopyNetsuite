public without sharing class FifthLessonPageForPortalController{
    public String fifthLessonId{get;set;}
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    public Fifth_Lesson__c fifthLesson{get;set;}
    public String startTime{get;set;} 
    public Decimal totalFee{get;set;} 
    public Decimal packageUnitFee{get;set;} 
    public Decimal taxRate{get;set;}  
    public String type{get;set;}    
    public boolean makeUpButtonDisaleFlag{get;set;}
    public boolean actionRequiredFlag{get;set;}
    public faq_link_for_portal__c faqlink{get;set;}
    public FifthLessonPageForPortalController(){
        faqlink = faq_link_for_portal__c.getValues('link_name');
        fifthLesson = new Fifth_Lesson__c();
        fifthLessonId = ApexPages.currentPage().getParameters().get('id');
        System.debug('@@@@'+fifthLessonId);
        if(String.isNotBlank(fifthLessonId)){
            List<Fifth_Lesson__c> fifthLessonList = [SELECT id,parent__r.Available_Make_up_Units__c,Booking_Day__c,Student__r.name,Booking_Date__c,Package__r.instrument__c,package__r.location__r.Country__r.tax_rate__c,package__r.Unit_Fee__c,Teacher_Account__r.Name,Start_Time__c,Duration__c,Center__r.Name FROM Fifth_Lesson__c WHERE id =: fifthLessonId AND  IsActive__c =: true];
            system.debug(' #### '+fifthLessonList);
            if(fifthLessonList.size() > 0){
                date cdate = Date.today();
                fifthLesson = fifthLessonList.get(0);                
                startTime = DateTime.newInstance(fifthLesson.Booking_Date__c, fifthLesson.Start_Time__c).format('h:mm a'); 
                packageUnitFee = BillingUtility.roundOffAmount(fifthLesson.package__r.unit_fee__c);                           
                taxRate = BillingUtility.roundOffAmount((fifthLesson.package__r.location__r.Country__r.tax_rate__c * fifthLesson.package__r.unit_fee__c)/100);
                totalFee = BillingUtility.roundOffAmount(taxRate + fifthLesson.package__r.unit_fee__c);
                if(fifthLesson.Booking_Date__c.month() == System.today().month() && fifthLesson.Booking_Date__c.year() == System.today().year()){
                    actionRequiredFlag = true;
                }else{
                    actionRequiredFlag = false;
                }
                system.debug('@@@@ '+fifthLesson);
                if(fifthLesson.duration__c <= fifthLesson.parent__r.Available_Make_up_Units__c){
                    makeUpButtonDisaleFlag = false;
                }else{
                    makeUpButtonDisaleFlag = true;
                }
            }else{
                errorMsg = 'Fifth Booking not found! Please contact your Center Admin.';
                isError = true;
            }    
        }else{
            errorMsg = 'Fifth Booking not found! Please contact your Center Admin.';
            isError = true;
        }
        
    }
    public void createBookingRecord(){
        System.debug('fifthLessonId = '+fifthLessonId);
        System.debug('type = '+type);
        if(String.isNotBlank(fifthLessonId) && String.isNotBlank(type)){
            String isLessonIdExist = FifthLessonController.bookingConvert(fifthLessonId,'',type,false);
            System.debug('isLessonIdExist = '+isLessonIdExist);
            //query booking id of newly created booking through fifthlesson and create app feed record
            if(String.isNotBlank(isLessonIdExist)){
                String newBookingId = getBookingIdOfFifthLesson(fifthLessonId);
                if(String.isNotBlank(newBookingId)){
                    List<booking__c> newCreatedBookingList = getNewlyCreatedBooking(newBookingId);
                    if(newCreatedBookingList.size() > 0){
                        createAppFeedRecord(newCreatedBookingList,type);      
                    }
                }
            }
            if(String.isNotBlank(isLessonIdExist) && type == 'placeholder'){
                errorMsg = 'Your 5th booking has been cancelled successfully!<br/> We are processing your request, you will be directed to lessons view in a few seconds!';
                isError = true;
            }else if(String.isNotBlank(isLessonIdExist) && type == 'makeup'){
                errorMsg = 'Your Make-up booking has been created successfully!<br/> We are processing your request, you will be directed to lessons view in a few seconds!';
                isError = true;
            }else if(String.isNotBlank(isLessonIdExist) && type == 'adhoc'){
                errorMsg = 'Your Ad-hoc booking has been created successfully!<br/> We are processing your request, you will be directed to lessons view in a few seconds!';
                isError = true;
            }            
        }
    }
    private String getBookingIdOfFifthLesson(String bookingId){
        List<fifth_lesson__c> fifthLessonList = [SELECT id,booking__c FROM fifth_lesson__c WHERE id =: bookingId];
        //if(fifthLessonList.size() > 0){
        return fifthLessonList.get(0).booking__c;
        //}
        //return '';
    }
    private List<booking__c> getNewlyCreatedBooking(String newBookingId){
        //if(String.isNotBlank(newBookingId)){
        List<booking__c> newBookingList = [SELECT id,Parent__c,Student__c,Center__r.Location__c,Teacher_Account__c,Instrument__c,Center__c,Booking_Date__c,Location__c,Start_Time__c FROM booking__c where id =: newBookingId];
        //}        
        return newBookingList;
        
    }
    private void createAppFeedRecord(List<booking__c> newCreatedBookingList,String type){
        Savepoint sp = Database.setSavepoint();
        try{
            String appFeedType;        
            if(type == 'placeholder'){
                appFeedType = '5th Lesson - CX';
            }else if(type == 'makeup'){
                appFeedType = '5th Lesson - MU';
            }else{
                appFeedType = '5th Lesson - AH';
            }
            List<App_Feeds__c> listOfApp_Feeds = new  List<App_Feeds__c>();
            for(Booking__c objBooking: newCreatedBookingList){
                String instrument;
                if(type == 'makeup'){
                    instrument = 'Make-up';
                }else if(type == 'adhoc'){
                    instrument = 'Ad-hoc';
                }else{
                    instrument = objBooking.instrument__c;
                }
                listOfApp_Feeds.add(new app_feeds__c(Parent__c = objBooking.Parent__c,
                                   Student__c = objBooking.Student__c,
                                   Teacher__c  =objBooking.Teacher_Account__c,
                                   Type__c = appFeedType,
                                   Instrument__c = instrument,
                                   Center__c = objBooking.Center__c,
                                   Booking_Id__c = objBooking.id,
                                   Booking_Date__c = objBooking.Booking_Date__c,
                                   Location__c = objBooking.Center__r.Location__c,
                                   Booking_Time__c = objBooking.Start_Time__c));
                if(listOfApp_Feeds.size() > 0){
                    insert listOfApp_Feeds;
                }                   
            }            
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError = true; 
            return;           
        }   
    }
}