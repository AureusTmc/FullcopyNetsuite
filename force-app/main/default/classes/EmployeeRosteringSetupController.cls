public class EmployeeRosteringSetupController{
    public List<Account> centreList {get;set;}
    public Account employeeDetails {get;set;}
    public Integer removeIndex {get;set;}
    public Integer editIndex {get;set;}
    public RosteringSetup rosteringSetupObject {get;set;}
    public List<RosteringRelatedList> existingRosteringList {get;set;}
    public Boolean isError {get;set;}
    public Boolean isDuplicate {get;set;}
    public String rosteringId {get;set;}
    private Map<String, Decimal> assignedEmployeeDetailsMap = new Map<String, Decimal>();
    public String updateDate {get;set;}
    public String updateResourceId {get;set;}
    public String UpdateId {get;set;}
    public String uptoDate{get;set;}
    public Boolean isDefaultCentre{get;set;}
    public Rostering_Setting__c settings {get;set;}
    public String searchString{get;set;}
    public String workDayOldValue{get;set;}
    public String endDateOfRostering {get;set;}
    public String rosteringShift{get;set;}
    public EmployeeRosteringSetupController(){
        getCentreList();
        rosteringSetupObject = new RosteringSetup();
        existingRosteringList = new List<RosteringRelatedList>();
        employeeDetails = new Account();
        isError = false;
        isDuplicate = false;
        
        settings = Rostering_Setting__c.getValues('Rostering Default');
        
        List<Rostering__c> rList = [SELECT Id,Effective_Date__c FROM Rostering__c ORDER BY Effective_Date__c DESC LIMIT 1];
        endDateOfRostering = system.now().addMonths(3).format('yyyy-MM-dd');
        if(rList != null && !rList.isEmpty()){
            DateTime dt = (DateTime) rList.get(0).Effective_Date__c ;
            endDateOfRostering = dt.format('yyyy-MM-dd');
        }
    } 
    
    // get all center list 
    public void getCentreList(){
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
		
		system.debug('centreList'+centreList);

    }
    
    // remove assigned employee to display list
    public void removeAssignEmployee(){
        if(removeIndex != null && removeIndex > -1 && removeIndex < existingRosteringList.size()){
            existingRosteringList.get(removeIndex).isDeleted = true;
        }
    }
    
    public void validateOnWorkDayChange(){
        if(String.isNotBlank(workDayOldValue) && editIndex != null && editIndex > -1 && editIndex < existingRosteringList.size()){
            isDuplicate = false;
            RosteringRelatedList rrl = existingRosteringList.get(editIndex);
            List<RosteringRelatedList> temp = new List<RosteringRelatedList>();
            temp.addAll(existingRosteringList);
            existingRosteringList.remove(editIndex);
            setupDuplicateData();
            existingRosteringList = temp;
            Boolean duplicate = validateDuplicate(rrl.roster);
            if(duplicate){
                isDuplicate = duplicate;
                rrl.roster.Work_Day__c  = workDayOldValue;
                existingRosteringList[editIndex] = rrl;
            }
            workDayOldValue = '';
            editIndex = -1;
        }
    }
    
    // remove assigned employee to display list
    public void editAssignEmployee(){
        if(editIndex != null && editIndex > -1 && editIndex < existingRosteringList.size()){
            date effDate = rosteringSetupObject.rosteringSetupObject.Effective_Date__c;
            rosteringSetupObject.rosteringSetupObject = existingRosteringList.get(editIndex).roster;
            rosteringSetupObject.rosteringSetupObject.Effective_Date__c = effDate;
            
            List<Account> accountList = [SELECT Id,Name FROM Account WHERE Id = : rosteringSetupObject.rosteringSetupObject.Employee__c ];
            if(accountList != null && !accountList.isEmpty()){
                employeeDetails = accountList.get(0);
            }
            existingRosteringList.remove(editIndex );
            editIndex = -1;
        }
    }
    
    // setup the rostering data
    public void setupRosteringData(){
        system.debug('@@setupRosteringData');
        existingRosteringList = new List<RosteringRelatedList>();
        isError = false;
        isDuplicate = false;
        if(rosteringSetupObject.dateString != null){
            String ctr = rosteringSetupObject.rosteringSetupObject.Centre__c;
            System.debug('ctr '+ctr);
            rosteringSetupObject.rosteringSetupObject = new Rostering__c();
            rosteringSetupObject.rosteringSetupObject.Centre__c = ctr;
            rosteringSetupObject.rosteringSetupObject.Effective_Date__c = Date.valueOf(rosteringSetupObject.dateString);
        }
        system.debug('@@rosteringSetupObject'+rosteringSetupObject);
        getRostering();
    }
    // show Rostering records 
    public void getRostering(){
        system.debug('@@@rosteringSetupObject.rosteringSetupObject.Effective_Date__c'+rosteringSetupObject.rosteringSetupObject.Effective_Date__c);
        system.debug('@@@rosteringSetupObject.rosteringSetupObject.Centre__c'+rosteringSetupObject.rosteringSetupObject.Centre__c);
        if(rosteringSetupObject.rosteringSetupObject.Effective_Date__c != null && rosteringSetupObject.rosteringSetupObject.Centre__c != null){
            List<Rostering__c> existingList = [SELECT Id,Employee__r.Name,Shift__c, Additional_Work_Day__c, Notes__c, 
                                                Centre__c,Effective_Date__c,Work_Day__c
                                                FROM Rostering__c 
                                                WHERE Effective_Date__c = : rosteringSetupObject.rosteringSetupObject.Effective_Date__c];//AND Centre__c = : rosteringSetupObject.rosteringSetupObject.Centre__c
            system.debug('@@@existingList'+existingList);
            for(Rostering__c ro : existingList ){
                existingRosteringList.add(new RosteringRelatedList(ro,''));
            }
        }
         system.debug('@@@existingRosteringList'+existingRosteringList);
    }
    public Boolean validateRestering(){
        if(String.isNotBlank(rosteringSetupObject.rosteringSetupObject.Employee__c) && String.isNotBlank(rosteringSetupObject.rosteringSetupObject.Shift__c) && String.isNotBlank(rosteringSetupObject.rosteringSetupObject.Work_Day__c)){
            return false;
        }
        return true;
    }
    public Boolean validateDuplicate(Rostering__c rost){
        string key = rost.Employee__c+''+rost.Effective_Date__c;
        system.debug('@@assignedEmployeeDetailsMap'+assignedEmployeeDetailsMap);
        if(assignedEmployeeDetailsMap.containsKey(key)){
            // Calculation of total day value.
            system.debug('@@assignedEmployeeDetailsMap.get(key)'+assignedEmployeeDetailsMap.get(key));
            Decimal dayVal = assignedEmployeeDetailsMap.get(key);
            if(rost.Work_Day__c != null && rost.Work_Day__c.equalsignorecase('Full Day')){
                dayVal += 1;
            }else if(rost.Work_Day__c != null && rost.Work_Day__c.equalsignorecase('Half Day')){
                dayVal += 0.5;
            }
            if(dayVal > 1){
                return true;
            }
        }
        return false;
    }
    
    public void setupDuplicateData(){
        assignedEmployeeDetailsMap = new Map<String, Decimal>();
        system.debug('@existingRosteringList'+existingRosteringList);
        for(RosteringRelatedList rrl : existingRosteringList){
            // Not included deleted record for day calculaton work.
            if(!rrl.isDeleted ){
                string key = rrl.roster.Employee__c+''+rrl.roster.Effective_Date__c;
                //string key = rrl.roster.Employee__c+''+rrl.roster.Centre__c+''+rrl.roster.Effective_Date__c;
                if(!assignedEmployeeDetailsMap.containsKey(key)){
                    assignedEmployeeDetailsMap.put(key, 0);
                }
                decimal dayVal = assignedEmployeeDetailsMap.get(key);
                if(rrl.roster.Work_Day__c != null && rrl.roster.Work_Day__c.equalsignorecase('Full Day'))  dayVal += 1;
                else if(rrl.roster.Work_Day__c != null && rrl.roster.Work_Day__c.equalsignorecase('Half Day'))  dayVal += 0.5;
                else if(rrl.roster.Work_Day__c == null)  dayVal += 1;
                assignedEmployeeDetailsMap.put(key, dayVal);
            }
        }
    }
    
    public void addRosteringSetup(){
        isError = validateRestering();
        system.debug('@@@validateRestering'+isError);
        if(!isError){
            if(rosteringSetupObject.dateString != null){
                rosteringSetupObject.rosteringSetupObject.Additional_Work_Day__c = true;
                String empName = '';
                if(String.isNotBlank(rosteringSetupObject.rosteringSetupObject.Employee__c)){
                    List<Account> empDetails = [SELECT Id, Name FROM Account Where Id = : rosteringSetupObject.rosteringSetupObject.Employee__c];
                    if(!empDetails.isEmpty()) empName = empDetails.get(0).Name;
                }
                if(String.IsNotBlank(rosteringSetupObject.dateString)) rosteringSetupObject.rosteringSetupObject.Effective_Date__c = Date.valueOf(rosteringSetupObject.dateString);
                // record ready to add, Lets check duplicate 
                setupDuplicateData();
                system.debug('@@@rosteringSetupObject.rosteringSetupObject'+rosteringSetupObject.rosteringSetupObject);
                isDuplicate = validateDuplicate(rosteringSetupObject.rosteringSetupObject);
                // is this record duplicate
                if(!isDuplicate){
                    Rostering__c rost = rosteringSetupObject.rosteringSetupObject.clone(false, false, false, false);
                    if(rosteringSetupObject.rosteringSetupObject.id != null) rost.Id = rosteringSetupObject.rosteringSetupObject.Id;
                    system.debug(rost );
                    existingRosteringList.add(new RosteringRelatedList(rost , empName));
                    rosteringSetupObject.rosteringSetupObject = new Rostering__c ();
                }
            }
        }
        system.debug('@@@@addRosteringSetup -->rosteringSetupObject -->'+rosteringSetupObject);
    }
    
    public String saveRosteringSetup(){
        List<Rostering__c> insertRosteringList = new List<Rostering__c>();
        List<Rostering__c> deleteRosteringList = new List<Rostering__c>();
        List<Additional_Leave__c> insertAdditionalLeaveList = new List<Additional_Leave__c>();
        Set<Id> employeeIdSet = new Set<Id>();
        system.debug('@@@@existingRosteringList'+existingRosteringList);
        system.debug('@@@rosteringSetupObject'+rosteringSetupObject);
        for(RosteringRelatedList rrl : existingRosteringList){
            System.debug('rosteringSetupObject.rosteringSetupObject.Centre__c '+rosteringSetupObject.rosteringSetupObject.Centre__c);
            System.debug('rrl.roster.Centre__c '+rrl.roster.Centre__c);
            if(!rrl.isDeleted && rosteringSetupObject.rosteringSetupObject.Centre__c == rrl.roster.Centre__c ){
                insertRosteringList.add(rrl.roster);
                if(rrl.roster.Additional_Work_Day__c ){
                    Decimal day = 0;
                    if(rrl.roster.Work_Day__c.equalsignorecase('Full Day')) day =  1 ;
                    else if(rrl.roster.Work_Day__c.equalsignorecase('Half Day')) day =  0.5;
                    insertAdditionalLeaveList.add(new Additional_Leave__c(
                        No_of_Days__c = day,
                        Rostering__r = rrl.roster,
                        Type__c = 'Leave'
                    ));
                    
                    if(rrl.roster.Employee__c != null) employeeIdSet.add(rrl.roster.Employee__c);
                }
            }else if(rrl.isDeleted && String.isNotBlank(rrl.roster.Id)){
                deleteRosteringList.add(rrl.roster);
            }
        }
        //system.debug('@@@employeeIdSet'+employeeIdSet);
        Map<Id, List<Leave_Entitlement__c>> availableLeaveEntitlementMap = getLeaveEntitlementByEmployeeId(employeeIdSet);
        system.debug('@@@getLeaveEntitlementByEmployeeId'+availableLeaveEntitlementMap);
        system.debug('@@@insertRosteringList'+insertRosteringList);
        if(!insertRosteringList.isEmpty()){
            system.debug('@@@insertRosteringList'+insertRosteringList);
            upsert insertRosteringList;
            
            List<Additional_Leave__c> insertAddLeaveList = new List<Additional_Leave__c>();
            //system.debug('@@@@insertAdditionalLeaveList'+insertAdditionalLeaveList);
            for(Additional_Leave__c al: insertAdditionalLeaveList){
                Id leaveEntid = null;
                if(availableLeaveEntitlementMap.containsKey(al.Rostering__r.Employee__c)){
                    for(Leave_Entitlement__c le: availableLeaveEntitlementMap.get(al.Rostering__r.Employee__c)){
                        if(le.Start_Date__c <= al.Rostering__r.Effective_Date__c && le.End_Date__c >= al.Rostering__r.Effective_Date__c){
                            leaveEntid = le.Id;
                        }
                    }
                }
                if(leaveEntid != null ){
                    al.Leave_Entitlement__c = leaveEntid ;
                    al.Rostering__c = al.Rostering__r.Id;
                    insertAddLeaveList.add(al);
                }
               // system.debug('@@@@insertAddLeaveList'+insertAddLeaveList);
                if(insertAddLeaveList  != null && !insertAddLeaveList.isEmpty()){
                    upsert insertAddLeaveList ;
                }
            }
        }
        if(!deleteRosteringList.isEmpty()){
            // delete the additional leave if rostering removed .
            List<Additional_Leave__c> additionalLeaveList = [SELECT Id FROM Additional_Leave__c WHERE Rostering__c IN: deleteRosteringList];
            system.debug('@@deleteRosteringList'+deleteRosteringList);
            delete deleteRosteringList;
            //system.debug('@@additionalLeaveList'+additionalLeaveList);
            if(additionalLeaveList != null && !additionalLeaveList.isEmpty()){
                delete additionalLeaveList ;
            }
        }
        return null;
    }    
    
    public Map<Id, List<Leave_Entitlement__c>> getLeaveEntitlementByEmployeeId(Set<Id> employeeIdSet){
        Map<Id, List<Leave_Entitlement__c>> retunMap = new Map<Id, List<Leave_Entitlement__c>>();
        for(Leave_Entitlement__c le: [SELECT Id, Employee__c, Start_Date__c, End_Date__c  FROM Leave_Entitlement__c WHERE Employee__c IN: employeeIdSet]){
            if(!retunMap.containsKey(le.Employee__c )){
                retunMap.put(le.Employee__c, new List<Leave_Entitlement__c>());
            }
            retunMap.get(le.Employee__c).add(le);
        }
        return retunMap;
    }
    
    @RemoteAction
    public static List<EventData> getAssignedEmployee(String sDate) {
        Date startDate = Date.valueOf(sDate);
        Date endDate = startDate.addDays(7);
        
        //@Arpit on 28th November 2019
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
        List<EventData> rosterings = new List<EventData>();
        
        List<Rostering__c>  rosteringList  = [SELECT Id, Name, Shift__c, Employee__r.Name,Effective_Date__c, Employee__c,Centre__c,
                                                Additional_Work_Day__c,Notes__c,Work_Day__c ,Centre__r.Organisation__c
                                                FROM Rostering__c 
                                                WHERE Effective_Date__c >= : startDate 
                                                AND Effective_Date__c < : endDate];
        Set<Id> employeeIdSet = new Set<Id>();
        for(Rostering__c ro : rosteringList  ){
            employeeIdSet.add(ro.Employee__c);
        }
        
        Map<Id,List<Leave_Request__c>> employeeDateLeaveMap = new Map<Id,List<Leave_Request__c>>();
        for(Leave_Request__c le : [SELECT Id, Employee__c,Leave_Start_Date__c, Leave_End_Date__c, RecordType.Name 
                                    FROM Leave_Request__c 
                                    WHERE Leave_End_Date__c >= : startDate
                                    AND Leave_Start_Date__c <= : endDate
                                    AND Employee__c IN : employeeIdSet 
                                    AND (Status__c = : 'Approved' 
                                        OR RecordType.Name = 'Sick Leave'
                                    )]){
            if(!employeeDateLeaveMap.containsKey(le.Employee__c)){
                employeeDateLeaveMap.put(le.Employee__c, new List<Leave_Request__c>());
            }
            employeeDateLeaveMap.get(le.Employee__c).add(le);
        }
        
        //List<EventData> rosterings = new List<EventData>();
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
            //rosterings.add(new EventData(ro, type));
            
            system.debug('@@@rosterings'+rosterings);

            // Arpit 2-Dec-2019 :check organization public hoilday  
            if(!(mapOfHolidays.containsKey(ro.Centre__r.Organisation__c) && mapOfHolidays.get(ro.Centre__r.Organisation__c).contains(ro.Effective_Date__c))){
                    
                    EventData event = new EventData();
                    event.id = ro.Id;
                    event.resourceId = ro.Centre__c;
                	event.resourceIdCustom = ro.Centre__c;
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
                        if(type != '' && type != null && type != 'undefined'){
                            event.description = type ;
                            if(type == 'Sick Leave'){
                                className = 'fullday_Sick_Leave';
                            }else{
                                className = 'fullday_Other_Leave';
                            }
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
                        if(type != '' && type != null && type != 'undefined'){
                            event.description = type ;
                            if(type == 'Sick Leave'){
                                className = 'halfday_Sick_Leave';
                            }else{
                                className = 'halfday_Other_Leave';
                            }
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
                         if(type != '' && type != null && type != 'undefined'){
                            event.description = type ;
                            if(type == 'Sick Leave'){
                                className = 'fullday_Sick_Leave';
                            }else{
                                className = 'fullday_Other_Leave';
                            }
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
                         if(type != '' && type != null && type != 'undefined'){
                            event.description = type ;
                            if(type == 'Sick Leave'){
                                className = 'halfday_Sick_Leave';
                            }else{
                                className = 'halfday_Other_Leave';
                            }
                        }
                        event.className = className;
                        event.additional = false;
                    }
                    rosterings.add(event);
                }else if((mapOfHolidays.containsKey(ro.Centre__r.Organisation__c) && mapOfHolidays.get(ro.Centre__r.Organisation__c).contains(ro.Effective_Date__c))){ 
                    EventData event = new EventData();
                    event.id = ro.Id;
                    event.resourceId = ro.Centre__c;
                    event.resourceIdCustom = ro.Centre__c;
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
    
    public void updateCalendarEvent() {
        if (string.isNotBlank(updateDate)) {
            isDuplicate = false;
            Date eventDate = Date.valueOf(updateDate);
            Date eventUptoDate = Date.valueOf(uptoDate);
            system.debug('@@@eventDate'+eventDate);
            system.debug('@@@eventUptoDate'+eventUptoDate);
            List<Rostering__c> oldRostDataList = [SELECT Id, Centre__c, Effective_Date__c,Employee__c, Notes__c,Work_Day__c,
                                                    Additional_Work_Day__c  FROM Rostering__c WHERE Id = : updateId];
            if(!oldRostDataList.isEmpty()){
                String oldCentre = oldRostDataList.get(0).Centre__c;
                DateTime rosteringDateFrom = oldRostDataList.get(0).Effective_Date__c != null ? DateTime.newInstance(oldRostDataList.get(0).Effective_Date__c, Time.newInstance(0, 0, 0, 0)) : null;
                String dayOfWeek = rosteringDateFrom != null ? rosteringDateFrom.format('EEEE') : '';
                
                system.debug('@@@oldRostDataList'+oldRostDataList);
                Integer days = oldRostDataList.get(0).Effective_Date__c.daysBetween(eventDate);
                system.debug('@@@days'+days);
                List<Rostering__c>  rosteringList  = new List<Rostering__c>();
                rosteringList  = [SELECT Id, Centre__c, Effective_Date__c,Employee__c, Notes__c,Work_Day__c,Additional_Work_Day__c  
                                    FROM Rostering__c 
                                    WHERE (Id IN : oldRostDataList 
                                            OR (Effective_Date__c >= : eventDate 
                                                AND Effective_Date__c <=: eventUptoDate
                                                AND Centre__c = : oldRostDataList.get(0).Centre__c
                                                AND Employee__c = : oldRostDataList.get(0).Employee__c
                                                )
                                            )
                                            AND Additional_Work_Day__c  = false];
                                            system.debug('@@@rosteringList'+rosteringList);
                List<Rostering__c> updateList = new List<Rostering__c>();
                if(!rosteringList.isEmpty()){
                    Set<String> duplicateStringSet = new Set<String>();
                    List<Rostering__c> existingList = [SELECT Id,Employee__r.Name,Shift__c, Notes__c, Centre__c,Effective_Date__c,
                                                        Work_Day__c,Additional_Work_Day__c 
                                                        FROM Rostering__c 
                                                        WHERE Effective_Date__c <=: eventUptoDate
                                                         AND Effective_Date__c >=: eventDate 
                                                         AND Centre__c !=: oldCentre 
                                                         AND Additional_Work_Day__c  = false]; // for specific centre 
                    existingRosteringList = new List<RosteringRelatedList>();
                    for(Rostering__c ro : existingList ){
                        existingRosteringList.add(new RosteringRelatedList(ro,''));
                    }
                    setupDuplicateData();
                    
                    for(Rostering__c roster : rosteringList){
                        roster.Centre__c = updateResourceId;
                        DateTime rosteringDateRecord = roster.Effective_Date__c != null ? DateTime.newInstance(roster.Effective_Date__c, Time.newInstance(0, 0, 0, 0)) : null;
                        if(rosteringDateRecord  != null && dayOfWeek.equalsignorecase(rosteringDateRecord.format('EEEE'))){ //isDefaultCentre || 
                            roster.Effective_Date__c = roster.Effective_Date__c.addDays(days);
                            Boolean duplicate = validateDuplicate(roster);
                            if(duplicate) isDuplicate = duplicate;
                            if(rosteringShift != null && !String.isBlank(rosteringShift)){
                                roster.Shift__c = rosteringShift;
                            }
                            updateList.add(roster);
                        }
                    }
                    system.debug('isDefaultCentre'+isDefaultCentre);
                    system.debug('is listc'+(!oldRostDataList.isEmpty()));
                    if(isDefaultCentre && !oldRostDataList.isEmpty()){
                        system.debug('asdoldRostDataList.get(0).Effective_Date__c =='+oldRostDataList.get(0).Effective_Date__c);
                        List<Employee_Work_Week__c> workWeekList = [SELECT Id, Name, Employee__c, Effective_Date__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Working_Days_in_a_Week__c, Sunday__c, Monday_Note__c, Saturday_Note__c, Thursday_Note__c, Sunday_Note__c, Tuesday_Note__c, Wednesday_Note__c, Friday_Note__c, Wednesday_Shift__c, Tuesday_Shift__c, Friday_Shift__c, Thursday_Shift__c, Sunday_Shift__c, Monday_Shift__c, Saturday_Shift__c, Monday_Centre__c, Saturday_Centre__c, Sunday_Centre__c, Thursday_Centre__c, Tuesday_Centre__c, Friday_Centre__c, Wednesday_Centre__c 
                                                                    FROM Employee_Work_Week__c 
                                                                    WHERE Employee__c =: oldRostDataList.get(0).Employee__c AND 
                                                                        Effective_Date__c <=: oldRostDataList.get(0).Effective_Date__c
                                                                        ORDER By Effective_Date__c DESC LIMIT 1];
                        List<Employee_Work_Week__c> workWeekFutureList = [SELECT Id, Name, Employee__c, Effective_Date__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Working_Days_in_a_Week__c, Sunday__c, Monday_Note__c, Saturday_Note__c, Thursday_Note__c, Sunday_Note__c, Tuesday_Note__c, Wednesday_Note__c, Friday_Note__c, Wednesday_Shift__c, Tuesday_Shift__c, Friday_Shift__c, Thursday_Shift__c, Sunday_Shift__c, Monday_Shift__c, Saturday_Shift__c, Monday_Centre__c, Saturday_Centre__c, Sunday_Centre__c, Thursday_Centre__c, Tuesday_Centre__c, Friday_Centre__c, Wednesday_Centre__c 
                                                                        FROM Employee_Work_Week__c 
                                                                        WHERE Employee__c =: oldRostDataList.get(0).Employee__c AND 
                                                                            Effective_Date__c >=: oldRostDataList.get(0).Effective_Date__c
                                                                            ORDER By Effective_Date__c];
                                
                        if(!workWeekFutureList.isEmpty()) workWeekList.addAll(workWeekFutureList);
                        for(Employee_Work_Week__c eww : workWeekList ){
                            if(dayOfWeek.equalsignorecase('Monday') && String.isNotBlank(eww.Monday__c) && !eww.Monday__c.equalsignorecase('Rest Day')){
                                eww.Monday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Monday_Shift__c = rosteringShift;
                            }else if(dayOfWeek.equalsignorecase('Saturday') && String.isNotBlank(eww.Saturday__c) && !eww.Saturday__c.equalsignorecase('Rest Day')){
                                eww.Saturday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Saturday_Shift__c = rosteringShift;
                            }else if(dayOfWeek.equalsignorecase('Sunday') && String.isNotBlank(eww.Sunday__c) && !eww.Sunday__c.equalsignorecase('Rest Day')){
                                eww.Sunday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Sunday_Shift__c = rosteringShift;
                            }else if(dayOfWeek.equalsignorecase('Friday') && String.isNotBlank(eww.Friday__c) && !eww.Friday__c.equalsignorecase('Rest Day')){
                                eww.Friday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Friday_Shift__c = rosteringShift;
                            }else if(dayOfWeek.equalsignorecase('Thursday') && String.isNotBlank(eww.Thursday__c) && !eww.Thursday__c.equalsignorecase('Rest Day')){
                                eww.Thursday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Thursday_Shift__c = rosteringShift;
                            }else if(dayOfWeek.equalsignorecase('Tuesday') && String.isNotBlank(eww.Tuesday__c) && !eww.Tuesday__c.equalsignorecase('Rest Day')){
                                eww.Tuesday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Tuesday_Shift__c = rosteringShift;
                            }else if(dayOfWeek.equalsignorecase('Wednesday') && String.isNotBlank(eww.Wednesday__c) && !eww.Wednesday__c.equalsignorecase('Rest Day')){
                                eww.Wednesday_Centre__c = updateResourceId;
                                if(rosteringShift != null && !String.isBlank(rosteringShift)) eww.Wednesday_Shift__c = rosteringShift;
                            }
                            
                        }
                        system.debug('@@@workWeekList'+workWeekList);
                        if(!workWeekList.isEmpty()){
                            update workWeekList ;
                        }
                          
                    }
                    system.debug('@@@updateList *** '+updateList);
                    if(!updateList.isEmpty() && !isDuplicate){
                        update updateList;
                    }
                }
            }
        }
        rosteringShift = '';
    }
    
    public void afterUpdateEvent(){
        if(isDefaultCentre){
            List<Rostering__c> oldRostDataList = [SELECT Id, Centre__c, Effective_Date__c,Employee__c, Notes__c,Work_Day__c,Additional_Work_Day__c  FROM Rostering__c WHERE Id = : updateId];
            if(!oldRostDataList.isEmpty()){
                String empId = oldRostDataList.get(0).Employee__c;
                String query = 'Select Id, Name, Main_Centre__c FROM Account WHERE Employee_Status__c in (\'Probation\',\'Confirm\') and (recordType.Name=\'Employee\' or recordType.Name=\'Teacher\') AND Id = : empId ';
                List<sObject> aList = Database.query(query);
                EmployeeRosteringBatchHandler.generateRostering(aList, null,  oldRostDataList.get(0).Effective_Date__c);
            }
            isDefaultCentre = false;
        }
    }
    
    public class RosteringRelatedList{
        public String employeeName {get;set;}
        public Rostering__c roster {get;set;}
        public Boolean isDeleted {get;set;}
        
        public RosteringRelatedList(Rostering__c roster, String employeeName){
            this.isDeleted = false;
            this.roster = roster;
            this.employeeName = employeeName;
            if(String.isBlank(this.employeeName) && String.isNotBlank(roster.Employee__r.Name)) this.employeeName = roster.Employee__r.Name;
        }
    }
    // Rostering setup class used for hold comman data of rostering
    public class RosteringSetup{
        public Rostering__c rosteringSetupObject { get; set; }
        public String dateString {get;set;}
        public List<SelectOption> shifts {get;set;}
        public List<SelectOption> workDays {get;set;}
        public RosteringSetup(){
            rosteringSetupObject = new Rostering__c ();
            shifts = getShifts();
            workDays = getWorkDays();
        }
        
        public List<SelectOption> getShifts() {
            List<SelectOption> options = new List<SelectOption>();
        
            Schema.DescribeFieldResult fieldResult = Rostering__c.Shift__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            for( Schema.PicklistEntry f : ple){
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            }       
            return options;
        }
        
        public List<SelectOption> getWorkDays() {
            List<SelectOption> options = new List<SelectOption>();
        
            Schema.DescribeFieldResult fieldResult = Rostering__c.Work_Day__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            for( Schema.PicklistEntry f : ple){
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            }       
            return options;
        }
    }
    /*public class EventData{
        public Rostering__c rostering{ get; set; }
        public String leaveType{get;set;}
        public EventData(Rostering__c rostering, String leaveType){
            this.leaveType = leaveType;
            this.rostering = rostering;
        }
    }*/
    public class EventData{
        Public String id;
        Public String resourceId;
        Public String title;
        Public Date start;
        Public String description;
        Public String className; 
        Public Boolean additional;
        Public String resourceIdCustom;
        /*public Rostering__c rostering{ get; set; }
        public EventData(Rostering__c rostering){
            this.rostering = rostering;
        }*/
    }
    
    @RemoteAction
    public static List<Account> getRemoteSearchResult(String searchString) {
        Id teacherRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        searchString = searchString.toLowerCase()+'%';
        List<Account> accontList = [SELECT Id, Name, Employee_Nationality__c 
                   FROM Account WHERE Name LIKE : searchString AND RecordTypeId =: teacherRecordTypeId LIMIT 50];
        return accontList;
    }
}