public class DefaultRosteringSetupController{
public Rostering_Setting__c settings {get;set;}
public List<Account> centreList {get;set;}
    
    public DefaultRosteringSetupController(){
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
        List<Rostering__c>  rosteringList  = [SELECT Id, Name, Shift__c, Employee__r.Name,Effective_Date__c, Employee__c,Centre__c, Additional_Work_Day__c,Notes__c,Work_Day__c FROM Rostering__c WHERE Effective_Date__c >= : startDate AND Effective_Date__c < : endDate];
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
            //Commented by @arpit on 28th November 2019
            /*if(employeeDateLeaveMap.containsKey(ro.Employee__c)){
                List<Leave_Request__c> epReqList = employeeDateLeaveMap.get(ro.Employee__c);
                for(Leave_Request__c le : epReqList ){
                    if(ro.Effective_Date__c >= le.Leave_Start_Date__c && ro.Effective_Date__c <= le.Leave_End_Date__c ){
                        type = le.RecordType.Name;
                    }
                }
            }*/
            if(String.isBlank(type)) rosterings.add(new EventData(ro));
        }
        return rosterings;
    }
    
    public class EventData{
        public Rostering__c rostering{ get; set; }
        public EventData(Rostering__c rostering){
            this.rostering = rostering;
        }
    }
}