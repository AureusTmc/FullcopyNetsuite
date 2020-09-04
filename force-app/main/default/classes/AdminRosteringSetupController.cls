public class AdminRosteringSetupController{
public Rostering_Setting__c settings {get;set;}
public List<Account> centreList {get;set;}
    
    public AdminRosteringSetupController(){
        settings = Rostering_Setting__c.getValues('Rostering Default');
        Set<String> setOfCentreIds = new Set<String>();
        for(String id : System.Label.Centre_to_Exclude_in_Rostering.split(',')){
            setOfCentreIds.add(id);
        }
        Id centreRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        //centreList = [SELECT Id, Name FROM Account WHERE RecordTypeId = : centreRecordTypeId AND Id NOT IN : setOfCentreIds];
		
		centreList = new List<Account>();
        
        Account hqCentre = new Account();
        for(Account acc: [SELECT Id, Name FROM Account WHERE RecordTypeId = : centreRecordTypeId AND Id NOT IN : setOfCentreIds]){
            if(acc.Name=='Aureus HQ'){
                hqCentre = acc;
            }else{
                centreList.add(acc);
            }
        }
        
        if(hqCentre!=null && hqCentre.Id!=null){
            centreList.add(hqCentre);
        }
    }
    
    @RemoteAction
    public static List<EventData> getAssignedEmployee(String sDate) {


        Date startDate = Date.valueOf(sDate);
        Date endDate = startDate.addDays(7);

         //@Arpit on 29th November 2019
        Map<String, Set<Date>> mapOfHolidays = new Map<String, Set<Date>>();
        Map<String, String> mapOfHolidayNames = new Map<String, String>();

        for(Public_Holiday__c holiday : [SELECT Id,Name, Public_Holiday_Date__c, Organisation__c, Organisation_Status__c FROM Public_Holiday__c WHERE Organisation_Status__c = 'Closed' AND Public_Holiday_Date__c >= :startDate AND Public_Holiday_Date__c < :endDate]){
            mapOfHolidayNames.put(holiday.Organisation__c+'-'+holiday.Public_Holiday_Date__c, holiday.Name);
            if(mapOfHolidays.containsKey(holiday.Organisation__c)){
                Set<Date> dateOfHolidays = mapOfHolidays.get(holiday.Organisation__c);
                dateOfHolidays.add(holiday.Public_Holiday_Date__c);
                mapOfHolidays.put(holiday.Organisation__c, dateOfHolidays);
            }else{
                mapOfHolidays.put(holiday.Organisation__c, new Set<Date> {holiday.Public_Holiday_Date__c});
            }
        }

        System.debug('@@@mapOfHolidays'+mapOfHolidays);
         //----------------------------------------------//

        List<Rostering__c>  rosteringList  = [SELECT Id, Name, Shift__c, Employee__r.Name,Effective_Date__c, Employee__c,Centre__c, Additional_Work_Day__c,Notes__c,Work_Day__c, Centre__r.Organisation__c FROM Rostering__c WHERE Effective_Date__c >= : startDate AND Effective_Date__c < : endDate];
        Set<Id> employeeIdSet = new Set<Id>();
        for(Rostering__c ro : rosteringList  ){
            employeeIdSet.add(ro.Employee__c);
        }
        
        Map<Id,List<Leave_Request__c>> employeeDateLeaveMap = new Map<Id,List<Leave_Request__c>>();
        for(Leave_Request__c le : [SELECT Id, Employee__c,Leave_Start_Date__c, Leave_End_Date__c, RecordType.Name FROM Leave_Request__c WHERE Leave_End_Date__c >= : startDate AND Leave_Start_Date__c <= : endDate AND Employee__c IN : employeeIdSet AND (Status__c = : 'Approved' OR RecordType.Name = 'Sick Leave')]){
            if(!employeeDateLeaveMap.containsKey(le.Employee__c)){
                employeeDateLeaveMap.put(le.Employee__c, new List<Leave_Request__c>());
            }
            employeeDateLeaveMap.get(le.Employee__c).add(le);
        } 
        
        List<EventData> rosterings = new List<EventData>();
        for(Rostering__c ro : rosteringList  ){
            String type = '';
            if(employeeDateLeaveMap.containsKey(ro.Employee__c)){
                List<Leave_Request__c> epReqList = employeeDateLeaveMap.get(ro.Employee__c);
                for(Leave_Request__c le : epReqList ){
                    if(ro.Effective_Date__c >= le.Leave_Start_Date__c && ro.Effective_Date__c <= le.Leave_End_Date__c ){
                        type = le.RecordType.Name;
                    }
                }
            }
            /*if(String.isBlank(type)) {
                rosterings.add(new EventData(ro));

            }*/
            if(String.isBlank(type) && !(mapOfHolidays.containsKey(ro.Centre__r.Organisation__c) && mapOfHolidays.get(ro.Centre__r.Organisation__c).contains(ro.Effective_Date__c))){
                
                EventData event = new EventData();
                event.id = ro.Id;
                event.resourceId = ro.Centre__c;
                event.start = ro.Effective_Date__c;
                event.title = ro.Employee__r.Name;
                event.description = ro.Notes__c; 
                if(ro.Additional_Work_Day__c && ro.Work_Day__c == 'Full Day'){
                    String className = 'fullday_';
                    if(ro.Shift__c == 'Regular Hours'){
                        className += 'Regular_Hours';
                    }else if(ro.Shift__c == 'Opening Hours'){
                        className += 'Opening_Hours';
                    }else if(ro.Shift__c == 'Closing Hours'){
                        className += 'Closing_Hours';
                    }else if(ro.Shift__c == 'Exam Day'){
                        className += 'Exam_Day';
                    }else{
                        className = 'event-highlight_fullday';
                    }
                    event.className = className;
                    event.additional = true;
                }
                if(ro.Additional_Work_Day__c && ro.Work_Day__c == 'Half Day'){
                    String className = 'halfday_';
                    if(ro.Shift__c == 'Regular Hours'){
                        className += 'Regular_Hours';
                    }else if(ro.Shift__c == 'Opening Hours'){
                        className += 'Opening_Hours';
                    }else if(ro.Shift__c == 'Closing Hours'){
                        className += 'Closing_Hours';
                    }else if(ro.Shift__c == 'Exam Day'){
                        className += 'Exam_Day';
                    }else{
                        className = 'event-highlight_halfday';
                    }
                    
                    event.className = className;
                    event.additional = true;
                }
                
                if(!ro.Additional_Work_Day__c && ro.Work_Day__c == 'Full Day'){
                    String className = 'fullday_';
                    if(ro.Shift__c == 'Regular Hours'){
                        className += 'Regular_Hours';
                    }else if(ro.Shift__c == 'Opening Hours'){
                        className += 'Opening_Hours';
                    }else if(ro.Shift__c == 'Closing Hours'){
                        className += 'Closing_Hours';
                    }else if(ro.Shift__c == 'Exam Day'){
                        className += 'Exam_Day';
                    }else{
                        className = 'event-not-highlight_fullday';
                    }
                    
                    event.className = className;
                    event.additional = false;
                }
                if(!ro.Additional_Work_Day__c && ro.Work_Day__c == 'Half Day'){
                    String className = 'halfday_';
                    if(ro.Shift__c == 'Regular Hours'){
                        className += 'Regular_Hours';
                    }else if(ro.Shift__c =='Opening Hours'){
                        className += 'Opening_Hours';
                    }else if(ro.Shift__c == 'Closing Hours'){
                        className += 'Closing_Hours';
                    }else if(ro.Shift__c == 'Exam Day'){
                        className += 'Exam_Day';
                    }else{
                        className = 'event-not-highlight_halfday';
                    }
                    event.className = className;
                    event.additional = false;
                }
                rosterings.add(event);
            }else if(String.isBlank(type) && (mapOfHolidays.containsKey(ro.Centre__r.Organisation__c) && mapOfHolidays.get(ro.Centre__r.Organisation__c).contains(ro.Effective_Date__c))){ 
                EventData event = new EventData();
                event.id = ro.Id;
                event.resourceId = ro.Centre__c;
                event.start = ro.Effective_Date__c;
                if(mapOfHolidayNames.containsKey(ro.Centre__r.Organisation__c + '-' +ro.Effective_Date__c)){
                    event.description = mapOfHolidayNames.get(ro.Centre__r.Organisation__c + '-' +ro.Effective_Date__c);
                }
                
                event.title = ro.Employee__r.Name;
                event.className = 'event-public-holiday';
                event.additional = false;
                rosterings.add(event);
            }
            
        }
        return rosterings;
    }

    public class EventData{
        Public String id;
        Public String resourceId;
        Public String title;
        Public Date start;
        Public String description;
        Public String className; 
        Public Boolean additional;
        /*public Rostering__c rostering{ get; set; }
        public EventData(Rostering__c rostering){
            this.rostering = rostering;
        }*/
    }
}