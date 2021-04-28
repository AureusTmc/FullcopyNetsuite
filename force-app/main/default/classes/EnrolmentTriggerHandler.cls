public class EnrolmentTriggerHandler {
    public static Boolean isFirstTime = True;
    
    //Delete booking on enrolment cancellation
    public static void DelBookingCancellation(list<Enrolment__c> enr){
        if(!enr.isEmpty()){
            list<booking__c> bkngList = [select id from Booking__c where Enrolment__c in:enr];
            if(bkngList.size()>0){
                delete bkngList; 
            }
        }
    }


    // start: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id not found then 
    //we added resource Id using teacher Working hrs.
    public static void populateResourceInEnrolment(List<Enrolment__c> filterTeacherEnrolment,Set<String> teacherIds,Set<String> centerIds,Set<String> bookingDays,
    Boolean isInsert,Map<string,Boolean> filterChangeEnrolmentMap){
        Map<string, List<Teacher_Working_Hour__c>> mapOfTeachWorkHrs = new Map<string, List<Teacher_Working_Hour__c>>();
        List<Teacher_Working_Hour__c> listOfTeacerWorkingHrs = new List<Teacher_Working_Hour__c>();
        if(filterTeacherEnrolment != null && filterTeacherEnrolment.size() > 0){
           
            for(Teacher_Working_Hour__c  objTeacerHrs :  [SELECT Active__c, Break_Time__c, Center_Name__c, End_Time__c, 
                                                        Remarks__c, Start_Time__c, 
                                                        Teacher_Name__c, Working_Day__c, Is_Booking_Booking_created__c, 
                                                        Centre__c, Resource__c, Name, Id FROM Teacher_Working_Hour__c
                                                        Where Active__c = true
                                                        And Break_Time__c = false
                                                        And Center_Name__c In:centerIds
                                                        And Teacher_Name__c in:teacherIds
                                                        And Working_Day__c in:bookingDays]){
                listOfTeacerWorkingHrs = new List<Teacher_Working_Hour__c>();
                if(mapOfTeachWorkHrs.containsKey(objTeacerHrs.Teacher_Name__c)){
                    listOfTeacerWorkingHrs =  mapOfTeachWorkHrs.get(objTeacerHrs.Teacher_Name__c);
                }
                listOfTeacerWorkingHrs.add(objTeacerHrs);
                mapOfTeachWorkHrs.put(objTeacerHrs.Teacher_Name__c,listOfTeacerWorkingHrs);
            }
            system.debug('mapOfTeachWorkHrs'+mapOfTeachWorkHrs);
            if(mapOfTeachWorkHrs != null && mapOfTeachWorkHrs.size() >0){
                for(Enrolment__c enr  : filterTeacherEnrolment){
                    enr.Resource__c =null;
                    if(mapOfTeachWorkHrs.containsKey(enr.Teacher__c)){
                        listOfTeacerWorkingHrs = mapOfTeachWorkHrs.get(enr.Teacher__c);
                        for(Teacher_Working_Hour__c  objTeacerHrs :listOfTeacerWorkingHrs){
                            string bookingDay ='';
                            if(isInsert && enr.Trial_Date__c != null && enr.Trial_Start_Time__c != null){
                                bookingDay = DateTime.newInstance(enr.Trial_Date__c, enr.Trial_Start_Time__c).format('EEE');
                                if(bookingDay.equalsIgnoreCase(objTeacerHrs.Working_Day__c) &&
                                   enr.Center__c == objTeacerHrs.Center_Name__c &&
                                   enr.Trial_Start_Time__c >= objTeacerHrs.Start_Time__c
                                   && enr.Trial_Start_Time__c <= objTeacerHrs.End_Time__c){
                                       enr.Resource__c = objTeacerHrs.Resource__c;
                                   }
                            }else if(filterChangeEnrolmentMap.containsKey(enr.Id) && filterChangeEnrolmentMap.get(enr.Id) == true && enr.Lessons_Start_Date__c != null && enr.Lesson_Start_time__c != null){
                                bookingDay = DateTime.newInstance(enr.Lessons_Start_Date__c, enr.Lesson_Start_time__c).format('EEE');
                                if(bookingDay.equalsIgnoreCase(objTeacerHrs.Working_Day__c) &&
                                   enr.Center__c == objTeacerHrs.Center_Name__c &&
                                   enr.Lesson_Start_time__c >= objTeacerHrs.Start_Time__c
                                   && enr.Lesson_Start_time__c <= objTeacerHrs.End_Time__c){
                                       enr.Resource__c = objTeacerHrs.Resource__c;
                                   }
                            } else If(filterChangeEnrolmentMap.containsKey(enr.Id) && filterChangeEnrolmentMap.get(enr.Id)== false && string.isNotBlank(enr.Lesson_Day__c )&& enr.Lesson_Start_time__c != null){
                                    bookingDay = enr.Lesson_Day__c.left(3);
                                if(bookingDay.equalsIgnoreCase(objTeacerHrs.Working_Day__c) &&
                                   enr.Center__c == objTeacerHrs.Center_Name__c &&
                                   enr.Lesson_Start_time__c >= objTeacerHrs.Start_Time__c
                                   && enr.Lesson_Start_time__c <= objTeacerHrs.End_Time__c){
                                       enr.Resource__c = objTeacerHrs.Resource__c;
                                   }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    // end: Nishi- 4-Aug-2020: for if enrolment created or updated and resource id not found then 
    //we added resource Id using teacher Working hrs.

    //start: 5-aug-2020:nishi: for  rollup referredBy Ids in refral (account) we update total referred ids and enrollled referred id  
     //commented by nishi: 7-aug: for deploy Only resource CHnages
    public static void rollUpreferredByIdsTotalEnrolment(Set<String> referredByIds){
         Map<String, String> mapOfTotalEnrolledReferredByIdsAggregate = new Map<String, String>();
         System.debug('@@@referredByIds'+referredByIds);
         for( AggregateResult agrResult :[SELECT Count(Id) totalreffrel,Referred_by__c  
                                         FROM Enrolment__c where 
                                         Referred_by__c IN:referredByIds  GROUP By Referred_by__c ]){
             Decimal totalreffrel = (Decimal)agrResult.get('totalreffrel');
             String referralId = (String) agrResult.get('Referred_by__c'); 
             if(String.isNotBlank(referralId)){
                 string totalTrialReffrelenrolment =mapOfTotalEnrolledReferredByIdsAggregate.containsKey(referralId)
                 ? mapOfTotalEnrolledReferredByIdsAggregate.get(referralId) : '0-0';
                 Decimal totalReffrelEnrolment = decimal.valueOf(totalTrialReffrelenrolment.split('-')[0]);
                 if(totalreffrel!= NULL){
                     totalReffrelEnrolment += totalreffrel;
                 }
                 totalTrialReffrelenrolment = totalReffrelEnrolment+'-'+ totalTrialReffrelenrolment.split('-')[1];
                mapOfTotalEnrolledReferredByIdsAggregate.put(referralId, totalTrialReffrelenrolment);
             }                               
         }
         for( AggregateResult agrResult :[SELECT Count(Id) totalreffrel,Referred_by__c  
                                         FROM Enrolment__c where 
                                        Referred_by__c IN:referredByIds 
                                         and Stage__c=:ConstantsClass.enroledStatus
                                        and type__C =:ConstantsClass.enrolRegularStatus
                                         GROUP By Referred_by__c ]){
             Decimal totalreffrel = (Decimal)agrResult.get('totalreffrel');
            String referralId = (String) agrResult.get('Referred_by__c'); 
            if(String.isNotBlank(referralId)){
                 string totalEnrolledReffrelEnrolment =mapOfTotalEnrolledReferredByIdsAggregate.containsKey(referralId)
                                     ? mapOfTotalEnrolledReferredByIdsAggregate.get(referralId) : '0-0';
                 Decimal totalReffrelEnrolment = decimal.valueOf(totalEnrolledReffrelEnrolment.split('-')[1]);
                 if(totalreffrel!= NULL){
                     totalReffrelEnrolment += totalreffrel;
                 }
                totalEnrolledReffrelEnrolment = totalEnrolledReffrelEnrolment.split('-')[0]+'-'+totalReffrelEnrolment;
                 mapOfTotalEnrolledReferredByIdsAggregate.put(referralId, totalEnrolledReffrelEnrolment);
             }                               
         }
         System.debug('@@@mapOfTotalEnrolledReferredByIdsAggregate'+mapOfTotalEnrolledReferredByIdsAggregate);
         if(mapOfTotalEnrolledReferredByIdsAggregate != null && mapOfTotalEnrolledReferredByIdsAggregate.size() > 0){
             List<Account> listOfAccountsToUpdate = new List<Account>();
             for(String referralId : mapOfTotalEnrolledReferredByIdsAggregate.keySet()){
                 string totalEnrolledReffrelEnrolment = mapOfTotalEnrolledReferredByIdsAggregate.get(referralId);
                Account objAcc = new Account(Id =referralId, No_of_Referrals_requested_for_Trials__c = decimal.valueOf(totalEnrolledReffrelEnrolment.split('-')[0]),
                 // added by jatin:18-dec-2019: for add makeupmins for group type booking 
                 No_of_Referrals_enrolled__c =  decimal.valueOf(totalEnrolledReffrelEnrolment.split('-')[1]));
                listOfAccountsToUpdate.add(objAcc);
             }
            System.debug('@@@listOfAccountsToUpdate'+listOfAccountsToUpdate);
             if(listOfAccountsToUpdate.size() > 0){
                 update listOfAccountsToUpdate;
             }
         }

     }
     //commented by nishi: 7-aug: for deploy Only resource CHnages
  //end: 5-aug-2020:nishi: for  rollup referredBy Ids in refral (account) we update total referred ids and enrollled referred id  

    //Lead conversion process, When trial booking created
    public static void leadConversionForTrialEnrl(List<Enrolment__c> processEnrList, Set<Id> parIds){
        /*Map<Id,Account> accMap = new Map<Id,Account>([SELECT Id, Name, Lead__c FROM Account 
WHERE Id IN: parIds AND Lead__c != null AND Lead__r.IsConverted = False]);
*/
        Map<Id,Account> accMap = new Map<Id,Account>([SELECT Id, Name, Lead__c, Lead__r.IsConverted,
                                                      (SELECT Id,CaseNumber FROM Cases WHERE RecordType.Name = 'Sales Enquiry' 
                                                       AND CreatedBy.Name LIKE 'B2BMA%' ORDER By CreatedDate desc LIMIT 5) 
                                                      FROM Account 
                                                      WHERE Id IN: parIds]);
        List<Opportunity> newOppList = new List<Opportunity>();
       // List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for(Enrolment__c enrol: processEnrList){
            if(accMap.get(enrol.Parent__c) != null){
                Account parAcc = accMap.get(enrol.Parent__c);
                //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
               /* if(parAcc.Lead__c != null && !(parAcc.Lead__r.IsConverted)){
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(parAcc.Lead__c);
                    lc.setAccountId(parAcc.Id);
                    lc.convertedStatus = 'Qualified';
                    leadConverts.add(lc);
                }else */if(parAcc.Cases.size() > 0){
                    Opportunity opp = EnrolmentTriggerHandler.fillOpportunity(enrol);
                    opp.Name = parAcc.Name;
                    newOppList.add(opp);
                    enrol.Opportunity__r = opp;
                }
            }
        }
        
        //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
        /*if(leadConverts.size() > 0){
            Map<Id, Database.LeadConvertResult> accConResMap = new Map<Id, Database.LeadConvertResult>();
            if(leadConverts.size() > 0){
                Database.LeadConvertResult[] lcrList = Database.convertLead(leadConverts);
                for(Database.LeadConvertResult lcr : lcrList){
                    if(lcr.isSuccess())
                        accConResMap.put(lcr.getAccountId(), lcr);          
                }
            }
            
            
            Set<Id> cnvrtdOppIds = new Set<Id>();
            for(Enrolment__c enrol: processEnrList){
                if(accConResMap.containsKey(enrol.Parent__c)){
                    Database.LeadConvertResult lcr = accConResMap.get(enrol.Parent__c);
                    enrol.Lead__c = lcr.getLeadId();
                    enrol.Opportunity__c = lcr.getOpportunityId();
                    
                    cnvrtdOppIds.add(lcr.getOpportunityId());
                }
            }
            
            //Updating Opportunity with trial request
            if(cnvrtdOppIds.size() > 0){
                List<Opportunity> updOppList = new List<Opportunity>();
                for(Id oppId : cnvrtdOppIds){
                    updOppList.add(new Opportunity(Id = oppId, StageName = 'Trial Requested'));
                }
                
                if(updOppList.size() > 0)
                    update updOppList;
            }
        }*/
        
        if(newOppList.size() > 0)
            insert newOppList;
        
        for(Enrolment__c enrol: processEnrList){
            Account parAcc = accMap.get(enrol.Parent__c);
            Boolean isTrialFromB2bmaUser = false;
            //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
            //if(parAcc != null && parAcc.Lead__c == null && parAcc.Cases.size() > 0)
            if(parAcc != null && parAcc.Cases.size() > 0)
                isTrialFromB2bmaUser = true;
            
            if(isTrialFromB2bmaUser && enrol.Opportunity__r.Id != null)
                enrol.Opportunity__c = enrol.Opportunity__r.Id;
        }
    }
    
    public static Opportunity fillOpportunity(Enrolment__c enrol){
        Opportunity opp = new Opportunity();
        opp.AccountId = enrol.Parent__c;
        opp.CloseDate = currQuarterLastDate();
        opp.StageName = 'Trial Requested';
        return opp;
    }
    
    
    public static Date currQuarterLastDate(){
        Integer FiscalYearStartMonthIndex = 1;
        
        // find end of first quarter of current year
        Date quarterEnd = Date.newInstance(system.today().year(), FiscalYearStartMonthIndex, 1).addMonths(3).addDays(-1);
        
        // if we are past the current quarter, move to the next one.
        while (system.today() >= quarterEnd) {
            quarterEnd = quarterEnd.addMonths(3);
        }
        
        Integer yearT = quarterEnd.year();
        Integer monthT = quarterEnd.month();
        Date dt = date.newinstance(yearT, monthT, date.daysInMonth(yearT, monthT));
        return dt;
    }
    
    //By Rajesh (Date 6-4-2019), This process is used to manage case(Sales Enquiry)
    public static void manageSalesEnquiryCase(List<Enrolment__c> processEnrList,boolean isSalesEnquiry){
        Map<Id, Case> accCaseMap      = new Map<Id, Case>();
        
        //Filling case account map
        for(Enrolment__c enrol: processEnrList)
            accCaseMap.put(enrol.Parent__c, null);      
        Map<Id, Enrolment__c> enrMap = new Map<Id, Enrolment__c>([SELECT Id,Referred_by__c, Parent__r.FirstName, Parent__r.LastName, Parent__r.PersonEmail, Parent__r.PersonMobilePhone, CreatedBy.Name,Stage__c,
                                                                  Student__r.FirstName, Student__r.LastName, Student__r.Gender__c, Student__r.PersonBirthdate, Center__c,Center__r.Location__c,
                                                                  Parent__r.UTM_Campaign__pc,Parent__r.UTM_Content__pc,Parent__r.UTM_Medium__pc,Parent__r.UTM_Source__pc,Parent__r.UTM_Term__pc,
                                                                  Parent__r.Pardot_Source__pc,Parent__r.UTM_Adgroup__pc
                                                                  FROM Enrolment__c 
                                                                  WHERE Id IN:processEnrList]);
        //added by nishi: 28-apr-2021: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
        String salesRecName =isSalesEnquiry ? ConstantsClass.caseSalesEnqRecTypeName  :ConstantsClass.InstrumentRentalEnquiryRecordType;
       
        for(Case c : [SELECT Id, Status, AccountId FROM Case 
                      WHERE AccountId IN: accCaseMap.keySet() AND Status !=: ConstantsClass.ClosedStatus AND
                      //RecordType.Name =:  ConstantsClass.caseSalesEnqRecTypeName
                      RecordType.Name =: salesRecName 
                      AND Enrolment__c = null ORDER BY CreatedDate DESC]){
                          if(accCaseMap.get(c.AccountId) == null)
                              accCaseMap.put(c.AccountId, c);          
                      }
        
        List<Case> insCaseList = new List<Case>();
        List<Case> updCaseList = new List<Case>();       
        Set<Id> caseIds = new  Set<Id>();
        for(Enrolment__c enrol: processEnrList){
            Enrolment__c enrParenInfo = enrMap.get(enrol.Id);
            Case salesEnqCase = fillCase(enrol, enrParenInfo,isSalesEnquiry);
            
            if(accCaseMap.get(enrol.Parent__c) != null){
                if(!caseIds.contains(accCaseMap.get(enrol.Parent__c).Id)){
                    salesEnqCase.Id  = accCaseMap.get(enrol.Parent__c).Id;
                    caseIds.add(accCaseMap.get(enrol.Parent__c).Id); // added by nishi: 25-nov-2020: for updated case uniqueness
                    // salesEnqCase.Stage__c       = 'Trial Requested';    
                    //salesEnqCase.Opportunity__c = enrol.Opportunity__c;
                    //salesEnqCase.Enrolment__c   = enrol.Id; 
                    updCaseList.add(salesEnqCase);
                }
            }else{
                salesEnqCase.Type = isSalesEnquiry ? ''  :'Piano Rental Enquiry';
                salesEnqCase.AccountId      = enrol.Parent__c;  
                salesEnqCase.Status         = ConstantsClass.NewStatus;
                salesEnqCase.Priority       = 'High';
                salesEnqCase.Form_Name__c   = enrol.Form_Name__c;
                //@Juneid 12 Aug 2020, Update Case fileds for Refferal case
                if(enrol.Referred_by__c != Null){
                    salesEnqCase.Form_Name__c = 'Refer-a-Friend';
                    salesEnqCase.Pardot_Source__c = 'Refer-a-Friend';
                }
                insCaseList.add(salesEnqCase);
            }
        }
        
        if(updCaseList.size() > 0)
            update updCaseList;
        
        if(insCaseList.size() > 0){
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            Database.insert(insCaseList, dmo);
        }
    }

    // jatin: 16-Jan-2020 :Create Fields for Aggrement Id in Enrolment object. 
    //if  Delivery date is change then Create PandaDoc Dodument for get customer signature and update New_document_Id value in Aggrement_Id field. 
    @future(callout=true)
    public static void processEnrPandaDocList(Set<String> enrolmentIds){
        map<String,PandaDocUtility.CreateDocument> documentDetails = PianoRentalHelperController.signAgreement(enrolmentIds,'Rental Aggrement');
         system.debug('documentDetails'+documentDetails);
        map<string,string> mapOfaggrementId = new Map<string,string>();
         for(string enrolmentId : documentDetails.keySet()){
            mapOfaggrementId.put(enrolmentId,documentDetails.get(enrolmentId).id);  
        }
        map<String,PandaDocUtility.Document> document = PianoRentalHelperController.waitAgreement(mapOfaggrementId);
        system.debug('@@@document'+document);
        //map<string,PandaDocUtility.CreateDocument> sendDocument =EnrolmentRetalPandaDocController.sendAgreement(documentDetails);
        // if document id created then we update New_document_Id value in Aggrement_Id field
        List<Enrolment__c> listOfEnrolment =  new List<Enrolment__c>();
        if(documentDetails != null && documentDetails.size() >0){
            for(Enrolment__c objEnrolment : [SELECT Id,Aggrement_Id__c 
                                             FROM Enrolment__c 
                                             WHERE Id =: mapOfaggrementId.KeySet()]){
                                                 if(documentDetails.containsKey(objEnrolment.id)){
                                                     listOfEnrolment.add(new Enrolment__c(id= objEnrolment.id,Aggrement_Id__c = mapOfaggrementId.get(objEnrolment.id)));
                                                 }
                                             }
            system.debug('listOfEnrolment'+listOfEnrolment);
            if(listOfEnrolment != null && listOfEnrolment.size() > 0 ){
                update listOfEnrolment;
            }
            system.debug('listOfEnrolment'+listOfEnrolment);
        }
        
    }
    
    public static Case fillCase(Enrolment__c l, Enrolment__c enrParenInfo,Boolean isSalesEnquiery){
         //added by nishi: 28-apr-2021: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
        String salesRecName =isSalesEnquiery ? ConstantsClass.caseSalesEnqRecTypeName  :ConstantsClass.InstrumentRentalEnquiryRecordType;
        String salesRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(salesRecName).getRecordTypeId();
         //added by nishi: 28-apr-2021:end: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
         
        Case cas = new Case(RecordTypeId = salesRecId);
        cas.Subject        = salesRecName;
        cas.Stage__c       = isSalesEnquiery? 'Trial Requested' :enrParenInfo.Stage__c;  // 28-Apr-2021:added by Nishi: need to build this functionality from enrolment as per discussion with Rajesh or Alex 
                                                                                       
      //  if(enrParenInfo.Stage__c == ConstantsClass.enrollmentPianoViewingBookedStage)
        //    cas.Stage__c       = ConstantsClass.enrollmentPianoViewingBookedStage; 
        cas.Student_Name__c= l.Student__c;
        cas.Opportunity__c = l.Opportunity__c;
        cas.Enrolment__c   = l.Id;
        cas.Trial_Date__c  = l.Trial_Date__c;
        cas.Centre_Name__c = l.Center__c;
        cas.Instrument__c  = l.Instrument__c;
        cas.Learning_Style__c = l.Learning_Style__c;
        cas.Origin         = l.Source_Type__c;
        cas.First_Name__c = enrParenInfo.Parent__r.FirstName;
        cas.Last_Name__c  = enrParenInfo.Parent__r.LastName;
        cas.Email__c      = enrParenInfo.Parent__r.PersonEmail;
        cas.Mobile__c     = enrParenInfo.Parent__r.PersonMobilePhone;
        cas.Student_First_Name__c = enrParenInfo.Student__r.FirstName;
        cas.Student_Last_Name__c  = enrParenInfo.Student__r.LastName;
        cas.Birthdate__c          = enrParenInfo.Student__r.PersonBirthdate;
        cas.Student_Gender__c     = enrParenInfo.Student__r.Gender__c;
        cas.Location__c           = enrParenInfo.Center__r.Location__c;        
        //Added by Rajesh on 5th Aug 2020. As per discussion with Prashant and Gandhi
        cas.UTM_Campaign__c = enrParenInfo.Parent__r.UTM_Campaign__pc;
		cas.UTM_Content__c  = enrParenInfo.Parent__r.UTM_Content__pc;
        cas.UTM_Medium__c = enrParenInfo.Parent__r.UTM_Medium__pc;
        cas.UTM_Source__c = enrParenInfo.Parent__r.UTM_Source__pc;
        cas.UTM_Term__c   = enrParenInfo.Parent__r.UTM_Term__pc; 
        cas.Pardot_Source__c = enrParenInfo.Parent__r.Pardot_Source__pc;
        cas.UTM_Adgroup__c= enrParenInfo.Parent__r.UTM_Adgroup__pc;
        return cas;
    }
    
    
    //@By Rajesh(Date 03-04-2019), Update Lead Case and opportunity stages for the Sales enquiry process
    public static void updateStatusForSalesProcess(List<Enrolment__c> enrList,Boolean isSalesEnquiery){
        Map<String, String> salesProcessStatusMap = ConstantsClass.salesProcessStatusMap; 
         //added by nishi: 28-apr-2021: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
        String salesRecName =isSalesEnquiery ? ConstantsClass.caseSalesEnqRecTypeName  :ConstantsClass.InstrumentRentalEnquiryRecordType;
        String salesRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(salesRecName).getRecordTypeId();
         //added by nishi: 28-apr-2021:end: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
       
        Map<Id, Id> enrSalesEnqCaseMap = new Map<Id, Id>();
       
        for(Case c: [SELECT Id,Enrolment__c FROM Case 
                        WHERE Enrolment__c IN: enrList 
                         AND RecordType.Name =: salesRecName // AND RecordType.Name =: ConstantsClass.caseSalesEnqRecTypeName
                        ORDER BY CreatedDate DESC]){
            if(!enrSalesEnqCaseMap.containsKey(c.Enrolment__c))
                enrSalesEnqCaseMap.put(c.Enrolment__c, c.Id);
        }
        
        Map<Id,Enrolment__c> enrMap = new Map<Id,Enrolment__c>();
        for(Enrolment__c enr : enrList){
            //comment/update on 1st july 2020, Need to manage revenue on case as well As per discussion with Gandi,Prashant and Anuj
            //if(enr.Opportunity__c != null && enr.Stage__c == 'Enrolled')
            if(enr.Stage__c == 'Enrolled')
            	enrMap.put(enr.Id, null);
        }
        
        //Map<Id,Decimal> enrRegPrgSumMap = new Map<Id,Decimal>();
        if(enrMap.size() > 0){
            enrMap = new Map<Id,Enrolment__c>([SELECT Id, Parent__r.PersonContactId FROM Enrolment__c WHERE Id IN: enrMap.keySet() AND Parent__r.PersonContactId != null]);
            //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
            /* 
            Set<String> lineItmType = new Set<String>{'Registration Fees','Program Fees'};
                for(Invoice_Line_Item__c invLnItm : [SELECT Id, Name, Enrolment__c, Amount__c FROM Invoice_Line_Item__c 
                                                     WHERE Enrolment__c IN: enrMap.keySet() AND Remarks__c IN:lineItmType 
                                                     AND Amount__c > 0]){
                                                         Decimal tempAmt = invLnItm.Amount__c;                                     
                                                         if(enrRegPrgSumMap.containsKey(invLnItm.Enrolment__c))
                                                             tempAmt += enrRegPrgSumMap.get(invLnItm.Enrolment__c);
                                                         enrRegPrgSumMap.put(invLnItm.Enrolment__c, tempAmt);                                     
                                                     }*/
        }
        List<Opportunity> oppUpdList = new List<Opportunity>();
        List<Case> caseUpdList       = new List<Case>();
        List<OpportunityContactRole> newcrolelist = new List<OpportunityContactRole>();
        List<Lead> leadUpdList       = new List<Lead>();
        for(Enrolment__c enr : enrList){
            String mapkey = isSalesEnquiery ? enr.Type__c +' '+enr.Stage__c :enr.Stage__c;
            
            //Commented or Added by Rajesh on (17-06-2020), need to build trial lost functionality on enrolment instead of case as per discussion with Ashish or Alex instead of case    Lost' by Rajesh on (17-06-2020), need to build this functionality from enrolment as per discussion with Ashish or Alex instead of case   
          //  if(mapkey != ConstantsClass.trialLost && salesProcessStatusMap.containsKey(mapkey)){
           if(salesProcessStatusMap.containsKey(mapkey)){
                String statusVal = salesProcessStatusMap.get(mapkey);
                if(enr.Opportunity__c != null){
                    if(enr.Stage__c == 'Enrolled'){
                        //oppUpdList.add(new Opportunity(Id = enr.Opportunity__c, StageName = 'Closed Won'));
                        Opportunity opp = new Opportunity(Id = enr.Opportunity__c, StageName = 'Closed Won');
                        
                        //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
                       // if(enrRegPrgSumMap.containsKey(enr.Id))
                         //   opp.Amount = enrRegPrgSumMap.get(enr.Id);
                        
                        if(enrMap.get(enr.Id) != null && enrMap.get(enr.Id).Parent__r.PersonContactId != null){
                            OpportunityContactRole oppcrole = new OpportunityContactRole();
                            oppcrole.OpportunityId = enr.Opportunity__c;
                            oppcrole.ContactId = enrMap.get(enr.Id).Parent__r.PersonContactId;
                            newcrolelist.add(oppcrole);   
                        }
                        oppUpdList.add(opp);
                    //Added 'Trial Lost' by Rajesh on (17-06-2020), need to build this functionality from enrolment as per discussion with Ashish or Alex instead of case   
                    }else if(mapkey != ConstantsClass.trialLost){
                        oppUpdList.add(new Opportunity(Id = enr.Opportunity__c, StageName = 'Closed Lost'));
                    }else{
                        oppUpdList.add(new Opportunity(Id = enr.Opportunity__c, StageName = statusVal));
                    }
                }
                
                if(enrSalesEnqCaseMap.containsKey(enr.Id)){
                     //Commented or Added by Rajesh on (17-06-2020), case status to be marked as closed when trial enrolment transferred as per discussion with Ashish or Alex on (17-06-2020)                    Case c = new Case(Id = enrSalesEnqCaseMap.get(enr.Id), Stage__c = statusVal, Lesson_Start_Date__c = enr.Lessons_Start_Date__c);
                    Case c = new Case(Id = enrSalesEnqCaseMap.get(enr.Id), Stage__c = statusVal, Lesson_Start_Date__c = enr.Lessons_Start_Date__c);
                    //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
                    //Added by Rajesh on 1st july 2020, To manage revenue on case as well
                   // if(enrRegPrgSumMap.containsKey(enr.Id))
                    //    c.Revenue__c = enrRegPrgSumMap.get(enr.Id);
                    if(enr.Stage__c == 'Transferred')
                        c.Status = 'Closed';
                    //caseUpdList.add(new Case(Id = enrSalesEnqCaseMap.get(enr.Id), Stage__c = statusVal, Lesson_Start_Date__c = enr.Lessons_Start_Date__c));
                    caseUpdList.add(c);
                }
                //Added by Rajesh on (17-06-2020), need to build trial lost functionality on enrolment instead of case as per discussion with Ashish or Alex instead of case    Lost' by Rajesh on (17-06-2020), need to build this functionality from enrolment as per discussion with Ashish or Alex instead of case   
                if(enr.Lead__c != null && mapkey != ConstantsClass.trialLost){
                   leadUpdList.add(new Lead(Id = enr.Lead__c, Status = statusVal));
                }
            }
        }
        
        if(oppUpdList.size() > 0)
            update oppUpdList;
        
        if(caseUpdList.size() > 0)
            update caseUpdList;
        
        if(leadUpdList.size() > 0)
            update leadUpdList;
        
        if(newcrolelist.size() > 0)
            insert newcrolelist;
        
        //Added by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
        if(enrMap.size() > 0){
            updateCaseOppRevenue(enrMap.keySet(), enrSalesEnqCaseMap);
        }
        /*
Map<Id, Id> leadSalesEnqCaseMap = new Map<Id, Id>();
for(Case c: [SELECT Id,Lead__c FROM Case WHERE Lead__c IN: leadIds AND RecordType.Name =: ConstantsClass.caseSalesEnqRecTypeName ORDER BY CreatedDate DESC]){
if(!leadSalesEnqCaseMap.containsKey(c.Lead__c))
leadSalesEnqCaseMap.put(c.Lead__c, c.Id);
}

List<Opportunity> oppUpdList = new List<Opportunity>();
List<Case> caseUpdList       = new List<Case>();
for(Enrolment__c enr : enrList){
String mapkey = enr.Type__c +' '+enr.Stage__c;

if(mapkey != ConstantsClass.trialLost && salesProcessStatusMap.containsKey(mapkey)){
String statusVal = salesProcessStatusMap.get(mapkey);
oppUpdList.add(new Opportunity(Id = enr.Opportunity__c, StageName = statusVal));    

if(leadSalesEnqCaseMap.containsKey(enr.Lead__c)){
caseUpdList.add(new Case(Id = leadSalesEnqCaseMap.get(enr.Lead__c), Stage__c = statusVal));
}
}
}

if(oppUpdList.size() > 0)
update oppUpdList;

if(caseUpdList.size() > 0)
update caseUpdList; */           
    }
    
    //Commented by Rajesh on 6th July 2020, We are not using lead concept for this we are using pardot. So its commented discusseion with Prashant Bhuttan
    @future
    public static void updateCaseOppRevenue(Set<Id> enrIds, Map<Id, Id> enrSalesEnqCaseMap){
        Map<Id,Decimal> enrRegPrgSumMap = new Map<Id,Decimal>();
        Set<String> lineItmType = new Set<String>{'Registration Fees','Program Fees'};
        for(Invoice_Line_Item__c invLnItm : [SELECT Id, Name, Enrolment__c, Amount__c FROM Invoice_Line_Item__c 
                                             WHERE Enrolment__c IN: enrIds AND Remarks__c IN:lineItmType 
                                                   AND Amount__c > 0]){
            Decimal tempAmt = invLnItm.Amount__c;                                     
        	if(enrRegPrgSumMap.containsKey(invLnItm.Enrolment__c))
                tempAmt += enrRegPrgSumMap.get(invLnItm.Enrolment__c);
            enrRegPrgSumMap.put(invLnItm.Enrolment__c, tempAmt);                                     
        }
        
        List<Opportunity> oppUpdList = new List<Opportunity>();
        List<Case> caseUpdList       = new List<Case>();
        for(Enrolment__c enr: [SELECT Id,Name,Opportunity__c FROM Enrolment__c WHERE Id IN:enrIds]){
           
            if(enrRegPrgSumMap.get(enr.Id) != null){
                if(enr.Opportunity__c != null)
        			oppUpdList.add(new Opportunity(Id = enr.Opportunity__c, Amount = enrRegPrgSumMap.get(enr.Id)));
                
                if(enrSalesEnqCaseMap.containsKey(enr.Id))
                    caseUpdList.add(new Case(Id = enrSalesEnqCaseMap.get(enr.Id),  Revenue__c = enrRegPrgSumMap.get(enr.Id)));
            }
        }
                               
        if(oppUpdList.size() > 0)
            update oppUpdList;
        
        if(caseUpdList.size() > 0)
            update caseUpdList;
    }
    
    
    //this method is used to change the booking after package upgrade and degrade
    /*public static void ProcessBookingAfterPackageChange(Map<String,Enrolment__c> mapOfEnrolment,Map<String,String> mapOfOldEnrolPackage,  Map<String, String> mapOfNewTeachers, Map<String, Time> mapOfNewStartTime){
System.debug('ProcessTrigger');
Map<String, List<Booking__c>> mapOfEnrolBookings =
updateEnrolBooking(mapOfEnrolment, mapOfOldEnrolPackage, mapOfNewTeachers, mapOfNewStartTime);        

}*/
    public static void processCancellation(Map<String,Enrolment__c> mapOfEnrolment){
        //System.debug('ProcessTrigger');
        /*Map<String, List<Booking__c>> mapOfEnrolBookings =*/ 
        //updateEnrolBooking(mapOfEnrolment,mapOfOldEnrolPackage);        
        //DELETE fetchFutureBookings(mapOfEnrolment);
        updateSubsLineItem(mapOfEnrolment,new Map<String,Package__c>(),TRUE);
    }
    /*private static void updateEnrolBooking(Map<String,Enrolment__c> mapOfEnrolment,Map<String,String> mapOfOldEnrolPackage, Map<String, String> mapOfNewTeachers, Map<String, Time> mapOfNewStartTime){
System.debug('updateEnrolBooking');
Map<String,List<Booking__c>> mapOfEnrolBookings = new Map<String,List<Booking__c>>();
//Map<String,Enrolment__c> mapOfEnrolment = getMapOfEnrolments(setOfEnrolIds);
List<Booking__c> listOfBookingToUpd = new List<Booking__c>();
Map<String,Package__c> mapOfPackage = getMapOfPackage(getPakcageIdSet(mapOfEnrolment,mapOfOldEnrolPackage));
for(Booking__c objBooking : [SELECT Id,End_Time__c,Start_Time__c, Package__c, Package__r.Duration__c, Enrolment__c,Booking_Date__c FROM Booking__c WHERE RecordType.Name =: ConstantsClass.recordTypeLesson
AND Enrolment__c IN :mapOfEnrolment.keySet() AND Booking_Date__c >= today AND (Type__c =: ConstantsClass.typeRegular OR IS_Fifth_Booking__c = TRUE)
AND Status__c !=: ConstantsClass.statusCanceled]){
System.debug('booking in trigger'+objBooking);
if(mapOfEnrolment.containsKey(objBooking.Enrolment__c) && (objBooking.booking_date__c >= mapOfEnrolment.get(objBooking.Enrolment__c).Effective_Date__c)){                          
System.debug('inside yes');
Enrolment__c objEnrol = mapOfEnrolment.get(objBooking.Enrolment__c);
if(mapOfOldEnrolPackage.size() > 0){
Package__c newPackage = mapOfPackage.get(objEnrol.Package__c);
Package__c oldPackage = mapOfPackage.get(mapOfOldEnrolPackage.get(objBooking.Enrolment__c));
objBooking.Package__c = objEnrol.Package__c;
objBooking.End_Time__c = objBooking.Start_Time__c.addMinutes(Integer.valueOf(newPackage.Duration__c));                   
}
if(mapOfNewTeachers.size() > 0){
if(mapOfNewTeachers.containsKey(objBooking.Enrolment__c)){
objBooking.Teacher_Account__c = mapOfNewTeachers.get(objBooking.Enrolment__c);
}
}
if(mapOfNewStartTime.size() > 0){
if(mapOfNewStartTime.containsKey(objBooking.Enrolment__c)){
Package__c objPack = mapOfPackage.get(objEnrol.Package__c);
objBooking.Start_Time__c = mapOfNewStartTime.get(objBooking.Enrolment__c);
objBooking.end_Time__c = objBooking.Start_Time__c.addMinutes(Integer.valueOf(objPack.Duration__c));
}
}
listOfBookingToUpd.add(objBooking);
}
}
if(listOfBookingToUpd.size() > 0){
System.debug('listOfBookingToUpd'+listOfBookingToUpd.size());
UPDATE listOfBookingToUpd;
updateSubsLineItem(mapOfEnrolment,mapOfPackage,false);
// UPDATE mapOfEnrolBookings.values();
}
// return mapOfEnrolBookings;
}*/
    
    /*private static Set<String> getPakcageIdSet(Map<String,Enrolment__c> mapOfEnrolment,Map<String,String> mapOfOldEnrolPackage){
Set<String> setOfPackageId = new Set<String>();
setOfPackageId.addAll(mapOfOldEnrolPackage.values());
for(String key : mapOfEnrolment.keySet()){
setOfPackageId.add(mapOfEnrolment.get(key).Package__c);
}
return setOfPackageId;
}*/
    private static Map<String,Package__c> getMapOfPackage(Set<String> setOfPackageIds){
        return new Map<String,Package__c>([SELECT Id,Duration__c,Package_Fee__c FROM Package__c WHERE Id IN: setOfPackageIds 
                                           AND Duration__c != 'Trial' AND Duration__c != NULL]);
        
    }
    private static void updateSubsLineItem(Map<String,Enrolment__c> mapOfEnrolment,Map<String,Package__c> mapOfPackage,Boolean isCancel){
        //System.debug('updateSubsLineItem');
        List<Subscription_Line_Item__c> listOfSubsLineItem = new List<Subscription_Line_Item__c>();
        for(Subscription_Line_Item__c objSubsLineItem : [SELECT Id,Plan_Package__c,Enrolment__c  FROM Subscription_Line_Item__c WHERE 
                                                         Enrolment__c In:mapOfEnrolment.keySet()]){
                                                             if(isCancel){
                                                                 objSubsLineItem.Status__c = ConstantsClass.statusInActive;            
                                                             }else{
                                                                 Package__c objPackage = mapOfPackage.get(mapOfEnrolment.get(objSubsLineItem.Enrolment__c).Package__c);
                                                                 objSubsLineItem.Plan_Package__c  = objPackage.Id;
                                                                 objSubsLineItem.Amount__c = objPackage.Package_Fee__c;
                                                             }
                                                             listOfSubsLineItem.add(objSubsLineItem);
                                                         }
        System.debug('listOfSubsLineItem '+listOfSubsLineItem);
        if(listOfSubsLineItem.size() > 0){
            UPDATE listOfSubsLineItem;
        }
    }
    
    /*private static List<Booking__c> fetchFutureBookings(Map<String,Enrolment__c> mapOfEnrolment){
List<Booking__c> listOfBookings = new List<Booking__c>();
for(Booking__c objBooking : [SELECT Id,End_Time__c,Start_Time__c, Package__c,Enrolment__c,Booking_Date__c FROM Booking__c WHERE RecordType.Name =: ConstantsClass.recordTypeLesson
AND Enrolment__c IN :mapOfEnrolment.keySet() AND Booking_Date__c >= today AND (Type__c =: ConstantsClass.typeRegular OR IS_Fifth_Booking__c = TRUE)
]){
//System.debug('booking in trigger'+objBooking);
if(mapOfEnrolment.containsKey(objBooking.Enrolment__c) && (objBooking.booking_date__c >= mapOfEnrolment.get(objBooking.Enrolment__c).Effective_Date__c)){                          
listOfBookings.add(objBooking);
}
}
return listOfBookings;
}
*/
    public static void updateBookingOfEnrolment(Map<String, Enrolment__c> enrolmentMap){        
        List<Booking__c> bookingsList = new List<Booking__c>();     
        Map<String, Enrolment__c> mapToUpdateSubsLineItem = new Map<String, Enrolment__c>();        
        Set<String> packageIds = new Set<String>();     
        Map<String, Package__c> packageMap = new Map<String, Package__c>();     
        if(enrolmentMap.size() > 0){        
            for(String enrolId : enrolmentMap.keySet()){        
                packageIds.add(enrolmentMap.get(enrolId).Package__c);       
            }       
            if(packageIds.size() > 0){      
                packageMap  = getMapOfPackage(packageIds);                  
            }       
            
            /*for(Booking__c bookingObj : [SELECT Id, End_Time__c, Start_Time__c, Package__c, Package__r.Duration__c, Enrolment__c, Booking_Date__c, Teacher_Account__c FROM Booking__c WHERE RecordType.Name =: ConstantsClass.recordTypeLesson      
AND Enrolment__c IN : enrolmentMap.keySet() AND Booking_Date__c >= TODAY AND (Type__c =: ConstantsClass.typeRegular OR IS_Fifth_Booking__c = TRUE)      
AND Status__c !=: ConstantsClass.statusCanceled]){      
if(enrolmentMap.containsKey(bookingObj.Enrolment__c)){      
if(enrolmentMap.get(bookingObj.Enrolment__c).effective_Date__c <= bookingObj.Booking_Date__c){      
bookingObj.Teacher_Account__c = enrolmentMap.get(bookingObj.Enrolment__c).Teacher__c;       
if(enrolmentMap.get(bookingObj.Enrolment__c).Package__c != bookingObj.Package__c){      
mapToUpdateSubsLineItem.put(enrolmentMap.get(bookingObj.Enrolment__c).Id, enrolmentMap.get(bookingObj.Enrolment__c));       
}       
bookingObj.Package__c = enrolmentMap.get(bookingObj.Enrolment__c).Package__c;       
bookingObj.Start_Time__c = enrolmentMap.get(bookingObj.Enrolment__c).Lesson_Start_time__c;      
if(packageMap.containsKey(enrolmentMap.get(bookingObj.Enrolment__c).Package__c)){       
bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(Integer.valueOf(packageMap.get(enrolmentMap.get(bookingObj.Enrolment__c).Package__c).Duration__c));        
}       
bookingsList.add(bookingObj);       
}       


}           
}       
}       

if(bookingsList.size() > 0){        
update bookingsList;        
}*/ 
        }    
        if(enrolmentMap.size() > 0 && packageMap.size() > 0){     
            updateSubsLineItem(enrolmentMap, packageMap ,false);     
        }       
    } 
    
    // 
    public static void updatetotalEnrolment(List<Enrolment__c> enrolList){
        
        set<Id> Ids = new set<Id>();
        //List<Account> accountList = new List<Account>();
        List<Account> accList= new List<Account>();
        
        Map<String, Integer> mapOfEnrolCount = new Map<String, Integer>();
        
        for(Enrolment__c enrObj:enrolList){
            if(enrObj.Center__c != null){
                Ids.add(enrObj.Center__c);
            }
        }
        system.debug('----->'+Ids);
        if(Ids.size() > 0){
            List<AggregateResult> AggregateResultList = [select Center__c center, Count(Id) total from Enrolment__c
                                                         where Center__c IN: Ids AND 
                                                         Type__c =: ConstantsClass.enrolRegularStatus
                                                         and (Stage__c =: ConstantsClass.enroledStatus or 
                                                              ( Stage__c =: ConstantsClass.enrollmentStageCancelled
                                                               and Package_Process_Type__c =: ConstantsClass.enrollmentProcessCancelType
                                                               and Package_Process_Status__c =: ConstantsClass.enrollmentProcessPendingStatus)) GROUP BY Center__c];
            for(AggregateResult result : AggregateResultList){
                mapOfEnrolCount.put(String.valueOf(result.get('center')), (Integer)result.get('total'));
            }
        }
        
        for(String accId : mapOfEnrolCount.keySet()){
            accList.add(new Account(Id = accId, Total_Enrolment__c = mapOfEnrolCount.get(accId)));
        }
        //accountList=[select Id,Total_Enrolment__c,(select Id from Enrolments3__r where Type__c='Regular' and (Stage__c ='Enrolled' or ( Stage__c='Cancelled' and Package_Process_Type__c='Cancellation' and Package_Process_Status__c='Pending')) )  from Account where Id in:Ids];
        
        /*for(Account accObj:accountList){
system.debug('====>'+accObj.Enrolments3__r.size());
accObj.Total_Enrolment__c=accObj.Enrolments3__r.size();
accList.add(accObj);
}*/
        
        try{
            if(accList.size()>0){
                update accList;
            }   
        }Catch(Exception e){
            System.debug('Exception :'+e.getMessage());
        }
    }
    // added by Jatin:27-Dec-2019 :For calculate group type enrolment check CLass Id is exist or not
    // if find classId  then update '# of units' field in class object
    public static void updateClassTotalEnrolment(set<Id> Ids){
        Map<String, Integer> mapOfEnrolCount = new Map<String, Integer>();
        List<Class__c> classList= new List<Class__c>();
        if(Ids != null && Ids.size() > 0){
            for(String classId : Ids){
                mapOfEnrolCount.put(classId,0);
            }
            List<string>  enrolPackageProcessType   = new List<String>{ConstantsClass.enrollmentProcessUpgradeType,ConstantsClass.enrollmentProcessChanged};
                List<AggregateResult> AggregateResultList = [select Class__c classes, Count(Id) total 
                                                             FROM Enrolment__c  
                                                             WHERE  Class__c IN: Ids
                                                             AND (Stage__c =: ConstantsClass.enroledStatus 
                                                                  OR (Package_Process_Type__c != null  
                                                                      AND (   (Package_Process_Type__c =: ConstantsClass.enrollmentProcessCancelType
                                                                               AND Package_Process_Status__c =: ConstantsClass.enrollmentProcessPendingStatus
                                                                              ) OR 
                                                                           (Package_Process_Type__c IN: enrolPackageProcessType
                                                                            AND Package_Process_Status__c =: ConstantsClass.enrollmentProcessCompletedStatus
                                                                           )
                                                                          )
                                                                     )
                                                                 ) GROUP BY Class__c];
            for(AggregateResult result : AggregateResultList){
                mapOfEnrolCount.put(String.valueOf(result.get('classes')), (Integer)result.get('total'));
            }
            system.debug('@@@mapOfEnrolCount'+mapOfEnrolCount);
            if(mapOfEnrolCount != null && mapOfEnrolCount.size() > 0){
                for(String classId : mapOfEnrolCount.keySet()){
                    classList.add(new Class__c(Id = classId, Total_Enrolment__c = mapOfEnrolCount.get(classId)));
                }
            }
            system.debug('@@@classList'+classList);
            try{
                if(classList.size()>0){
                    update classList;
                }   
            }Catch(Exception e){
                System.debug('Exception :'+e.getMessage());
            }
        }
        
    }
    
    //  jatin: 30-Dec-2019 : for Rental invoice will be generated and sent to the customer 
    //via email along with the confirmed timeslot
    public static void  generateRentalInvoice(Set<String> enrolmentIds){
        Map<String,Invoice__c> mapOfInvoice = New Map<String,Invoice__c>();
        Map<String,List<Invoice_Line_Item__c>> mapOfInvoiceLineItem = New Map<String,List<Invoice_Line_Item__c>>();
        List<Invoice_Line_Item__c> listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
        system.debug('enrolmentIds'+enrolmentIds); 
        list<Subscription_Line_Item__c> listOfSubsLineItem = new LIst<Subscription_Line_Item__c>();
        Set<string> invIds = new Set<string>();
        Set<String> parentIds = new Set<String>();
        map<Id,string> subscriptionupdateMap = new  map<Id,string> ();
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        for(Enrolment__c objEnrolment :  PianoRentalHelperController.getRentalEnrolmentList(enrolmentIds)){
            if(string.isNotBlank(objEnrolment.center__r.id) && string.isNotBlank(objEnrolment.center__r.country__r.id) &&
                objEnrolment.Subscription_Line_Items__r != null && objEnrolment.Subscription_Line_Items__r.size() >0){
                    date subscriptionNextBilldate = date.newInstance(objEnrolment.Final_Delivery_date__c.addMonths(1).year(),objEnrolment.Final_Delivery_date__c.addMonths(1).month(),1);
                    Enrolment__c objNewEnrolment = new Enrolment__c(id= objEnrolment.id,Rental_Start_date__c = objEnrolment.Final_Delivery_date__c.addDays(1));
                    listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
                    Country__c countryObj = objEnrolment.center__r.country__r;
                    if(objEnrolment.Subscription_Line_Items__r[0].Amount__c != null && objEnrolment.Final_Delivery_date__c != null){
                        Integer remainingDays = date.daysInMonth(objEnrolment.Final_Delivery_date__c.year(), objEnrolment.Final_Delivery_date__c.month()) - objEnrolment.Final_Delivery_date__c.AddDays(-1).day();
                        system.debug(remainingDays);
                        
                        Decimal rentalTotalAmount = remainingDays * (objEnrolment.Subscription_Line_Items__r[0].Amount__c /  date.daysInMonth(objEnrolment.Final_Delivery_date__c.year(), objEnrolment.Final_Delivery_date__c.month()));
                        system.debug(rentalTotalAmount);
                        
                        Subscription_Line_Item__c  objSubLineItem = objEnrolment.Subscription_Line_Items__r[0];
                        if(string.isNotBlank(objEnrolment.Parent__c)){
                            parentIds.add(objEnrolment.Parent__c);
                        }
                        Invoice__c objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objEnrolment.Parent__c,ConstantsClass.dueStatus);
                        objInvoice.Center__c = objEnrolment.Center__c;
                        objInvoice.Invoice_Type__c =ConstantsClass.recurringInvoiceType;
                        // 10-Feb:2020:jatin: update invoice date
                       // objInvoice.Invoice_Date__c =objEnrolment.Final_Delivery_date__c;
                       // objInvoice.Due_Date__c=objEnrolment.Final_Delivery_date__c;
                        mapOfInvoice.put(objEnrolment.Id,objInvoice);
                        // 4-Mar-2021: Aureus Q1 2021: piano rental : If we found Free_Rental_Month__c then we create all invoices as per months and added Complimentary discount invoice line items  
                        if(objEnrolment.Free_Rental_Month__c != null && objEnrolment.Free_Rental_Month__c > 0){
                            date freeRentalExpirationDate = Datetime.newInstance(objEnrolment.Final_Delivery_date__c,time.newInstance(0, 0,0,0)).addMonths(integer.valueOf(objEnrolment.Free_Rental_Month__c)).date();
                            objNewEnrolment.Free_Rental_Expiration_Date__c = freeRentalExpirationDate;
                            subscriptionNextBilldate = date.newInstance(freeRentalExpirationDate.addMonths(1).year(),freeRentalExpirationDate.addMonths(1).month(),1);
                            Date effectiveFreeRentalDate = objNewEnrolment.Free_Rental_Expiration_Date__c.AddDays(-1);  //15- apr 
                            Date startFreeRentalDate = objEnrolment.Final_Delivery_date__c;  //15- apr 
                            Integer startmonth =0;
                            while(startFreeRentalDate <= effectiveFreeRentalDate){
                                system.debug('startFreeRentalDate'+startFreeRentalDate);
                                date invoicedate = objEnrolment.Final_Delivery_date__c;
                                date lastdate = date.newInstance(invoicedate.year(), invoicedate.month(),date.daysInMonth(invoicedate.year(), invoicedate.month()));
                                if(startFreeRentalDate !=  objEnrolment.Final_Delivery_date__c){
                                    invoicedate=  date.newInstance(startFreeRentalDate.addmonths(1).year(), startFreeRentalDate.addmonths(1).month(),1);
                                    lastdate = date.newInstance(invoicedate.year(), invoicedate.month(),date.daysInMonth(invoicedate.year(), invoicedate.month()));
                                    listOfInvoiceLineItem.add(createInvoiceLineItem(objEnrolment,objSubLineItem.Id, objEnrolment.Subscription_Line_Items__r[0].Amount__c , countryObj.Tax_Rate__c, false,'Rental Invoice',
                                    invoicedate,invoicedate,lastdate));
                                      if(effectiveFreeRentalDate != NULL && invoicedate.daysBetween(effectiveFreeRentalDate) > 0 ){
                                        if((effectiveFreeRentalDate >= invoicedate || effectiveFreeRentalDate.month() < invoicedate.month()) && effectiveFreeRentalDate <= lastDate){
                                            rentalTotalAmount = effectiveFreeRentalDate.day() * ( objEnrolment.Subscription_Line_Items__r[0].Amount__c  /  date.daysInMonth(effectiveFreeRentalDate.year(), effectiveFreeRentalDate.month()));
                                            listOfInvoiceLineItem.add(createInvoiceLineItem(objEnrolment,objSubLineItem.Id, rentalTotalAmount, countryObj.Tax_Rate__c, true,'Complimentary Rental Invoice',
                                            invoicedate,invoicedate,effectiveFreeRentalDate));
                                        }else{
                                            listOfInvoiceLineItem.add(createInvoiceLineItem(objEnrolment,objSubLineItem.Id,objEnrolment.Subscription_Line_Items__r[0].Amount__c , countryObj.Tax_Rate__c, 
                                            true,'Complimentary Rental Invoice',invoicedate,invoicedate,lastdate));
                                        }
                                    }  
                                }else{
                                    listOfInvoiceLineItem.add(createInvoiceLineItem(objEnrolment,objSubLineItem.Id, rentalTotalAmount, countryObj.Tax_Rate__c, false,'Rental Invoice',
                                        objEnrolment.Final_Delivery_date__c,objEnrolment.Final_Delivery_date__c,lastdate));
                                    listOfInvoiceLineItem.add(createInvoiceLineItem(objEnrolment,objSubLineItem.Id, rentalTotalAmount, countryObj.Tax_Rate__c, true,'Complimentary Rental Invoice',
                                    objEnrolment.Final_Delivery_date__c,objEnrolment.Final_Delivery_date__c,lastdate));
                                }
                                startFreeRentalDate=lastdate;
                            }
                        }
                        // 4-Mar-2021: Aureus Q1 2021: piano rental : If we found Free_Rental_Month__c then we create all invoices as per months and added Complimentary discount invoice line items
                        else{
                            listOfInvoiceLineItem.add(createInvoiceLineItem(objEnrolment,objSubLineItem.Id, rentalTotalAmount, countryObj.Tax_Rate__c, false,'Rental Invoice',
                            objEnrolment.Final_Delivery_date__c,objEnrolment.Final_Delivery_date__c,objEnrolment.Final_Delivery_date__c.addDays(remainingDays)));
                        }
                        
                        mapOfInvoiceLineItem.put(objEnrolment.Id,listOfInvoiceLineItem);

                        system.debug('mapOfInvoice'+mapOfInvoice); 
                        system.debug('mapOfInvoiceLineItem'+mapOfInvoiceLineItem);

                        // 5-Feb:2020: for update subscription_line_item next bill date and start date
                        //Start:added by nishi: 27-Jul-2020: for already subscription start date and next bill date exist then we 
                         // added subscription Next bill date as a line Item date.
                       
                        if(objSubLineItem.Subscription__r.Next_Bill_Date__c != null 
                        && objSubLineItem.Subscription__r.Subscription_Start_Date__c != null){
                            system.debug('subscriptionNextBilldate'+subscriptionNextBilldate);
                            system.debug('objSubLineItem.Subscription__r.Next_Bill_Date__c'+objSubLineItem.Subscription__r.Next_Bill_Date__c);
                            if(objSubLineItem.Subscription__r.Next_Bill_Date__c > subscriptionNextBilldate){
                                subscriptionupdateMap.put(objSubLineItem.Subscription__c,objSubLineItem.Subscription__r.Subscription_Start_Date__c+'#'+subscriptionNextBilldate);
                            }
                            listOfSubsLineItem.add(new Subscription_Line_Item__c(id=objSubLineItem.id,
                                Next_Bill_Date__c =  subscriptionNextBilldate,
                                Subscription_Start_Date__c =  objEnrolment.Final_Delivery_date__c.addDays(1)));
                        }  //ENd:added by nishi: 27-Jul-2020: for already subscription start date and next bill date exist then we 
                        else{
                            subscriptionupdateMap.put(objSubLineItem.Subscription__c,objEnrolment.Final_Delivery_date__c.addDays(1)+'#'+subscriptionNextBilldate);
                            listOfSubsLineItem.add(new Subscription_Line_Item__c(id=objSubLineItem.id,
                                Next_Bill_Date__c =  subscriptionNextBilldate,//date.newInstance(objEnrolment.Final_Delivery_date__c.addMonths(1).year(),objEnrolment.Final_Delivery_date__c.addMonths(1).month(),1),
                                Subscription_Start_Date__c =  objEnrolment.Final_Delivery_date__c.addDays(1)));    
                        }
                       system.debug('@@listOfSubsLineItem'+listOfSubsLineItem);
                        //10-Feb-2020: add Rental start date 
                        listOfEnrolment.add(objNewEnrolment);
                    }           
                }
        } 
        system.debug('mapOfInvoice'+mapOfInvoice); 
        system.debug('mapOfInvoiceLineItem'+mapOfInvoiceLineItem);
         //10-Feb-2020: update enrolment  
        if(listOfEnrolment != null && listOfEnrolment.size() > 0){
            UPDATE listOfEnrolment;
        }
        if(mapOfInvoice != null && mapOfInvoice.size() > 0){
            insert mapOfInvoice.values();
            system.debug('mapOfInvoice'+mapOfInvoice);
            Map<String,String> mapOfInvoiceId = new  Map<String,String>();
            List<Invoice_Line_Item__c> listOfInsertInvoiceLineItem = new List<Invoice_Line_Item__c>();
            if(mapOfInvoiceLineItem != null && mapOfInvoiceLineItem.Size() > 0){
                for(string  enrolmentId : mapOfInvoiceLineItem.keyset()){
                    for(Invoice_Line_Item__c inlineItemForChange  : mapOfInvoiceLineItem.get(enrolmentId)){
                        if(mapOfInvoice.containsKey(enrolmentId)){
                            inlineItemForChange.Invoice__c = mapOfInvoice.get(enrolmentId).id;
                            mapOfInvoiceId.put(mapOfInvoice.get(enrolmentId).id,enrolmentId); 
                        }
                        listOfInsertInvoiceLineItem.add(inlineItemForChange);
                    }
                }
                Insert  listOfInsertInvoiceLineItem;
            }
            system.debug('mapOfInvoiceLineItem'+mapOfInvoiceLineItem);
             // 5-Feb:2020: for update subscription_line_item or subscription next bill date and start date
            if(listOfSubsLineItem != null && listOfSubsLineItem.size() > 0){
                update listOfSubsLineItem;
            }
            system.debug('W@@listOfSubsLineItem'+listOfSubsLineItem);
            system.debug('W@@subscriptionMap'+subscriptionupdateMap);
            if(subscriptionupdateMap != null && subscriptionupdateMap.size() > 0){
                List<Subscription__c> listOfSubscription = new List<Subscription__c>();
                for(Id subscriptionId :subscriptionupdateMap.keySet()){
                    listOfSubscription.add(new Subscription__c(id= subscriptionId, 
                                            Subscription_Start_Date__c = date.valueOf(subscriptionupdateMap.get(subscriptionId).split('#')[0]),
                                            Next_Bill_Date__c = date.valueOf(subscriptionupdateMap.get(subscriptionId).split('#')[1])));
                }
                if(listOfSubscription != null && listOfSubscription.size() > 0){
                    update listOfSubscription;
                }
                system.debug('W@@listOfSubscription'+listOfSubscription);
            }
            
           // Nishi: 15-Feb-2021: We have given Complimentary Loan Discount. We offer a rental period so we create an invoice but the invoice amount is adjusted in the credit memo so we created an invoice of 0 amount.   
            // List<Credit_Memo__c> listOfCreditMemos  =PaymentComponentController.generateCreditMemoQuery(parentIds);
            // if(listOfCreditMemos != null && listOfCreditMemos.size()>0){
            //     Date lastDate = listOfCreditMemos[0].Credit_Memo_Date__c;
            //     adjustCreditMemoDeposit( mapOfInvoiceId, parentIds, lastDate, true);
            // }
            // Nishi: 15-Feb-2021: We have given Complimentary Loan Discount. We offer a rental period so we create an invoice but the invoice amount is adjusted in the credit memo so we created an invoice of 0 amount.                                                    
            getPaymentForInvoices(mapOfInvoiceId);  
            
        }
        
    }

    private static Invoice_Line_Item__c createInvoiceLineItem(enrolment__c objEnrolment,string subLineItemId,Decimal rentalTotalAmount,Decimal taxRate, boolean isDiscount,
    string remarks,date invoiceDate,date startDateterm,date endDateterm){
        Invoice_Line_Item__c inlineItemForChange = new Invoice_Line_Item__c();
        inlineItemForChange.Enrolment__c = objEnrolment.id;
        inlineItemForChange.Subscription_Line_Item__c = subLineItemId;
        if(rentalTotalAmount > 0){
            inlineItemForChange.Amount__c = BillingUtility.roundOffAmount(isDiscount ?  rentalTotalAmount * -1: rentalTotalAmount);                                                               
        } 
        inlineItemForChange.Is_Discount__c= isDiscount;
        inlineItemForChange.Package__c = objEnrolment.Package__c;
        inlineItemForChange.Is_Deposit__c = false;        
        inlineItemForChange.Remarks__C = remarks;       
        inlineItemForChange.Teacher_Id__c = objEnrolment.Teacher__c;   
        inlineItemForChange.Term_Start_Date__c = startDateterm;
        inlineItemForChange.Term_End_Date__c= endDateterm;    
        if(taxRate >  0 && rentalTotalAmount > 0 ){
            Double gstAmount = BillingUtility.roundOffAmount(Double.valueOf(rentalTotalAmount) * (taxRate / 100));
            inlineItemForChange.gst_Amount__c = BillingUtility.roundOffAmount(isDiscount ?  gstAmount * -1: gstAmount);    
        }
        inlineItemForChange.month__c = invoiceDate;
        return inlineItemForChange;
    }
    @future (callout=true)
    public static void getPaymentForInvoices(Map<String,String> mapOfInvoiceId){
        if(mapOfInvoiceId != null && mapOfInvoiceId.size() > 0){
            PianoRentalHelperController.getPaymentForInvoices(mapOfInvoiceId,'Instrument_Delivery_Confirmation'); 
        } 
    }
    
    // Nishi: 15-Feb-2021: We have given Complimentary Loan Discount. We offer a rental period so we create an invoice but the invoice amount is adjusted in the credit memo so we created an invoice of 0 amount.   
    Private static void adjustCreditMemoDeposit(Map<String,String> mapOfInvoiceId,Set<String> setOfParentIds,
    Date lastDate, boolean isGetTotalAmount){
         List<Invoice__c> listOfInv = new List<Invoice__c>();
        Map<String, Date> mapOfParentEnrolmentLastDate = new Map<String, Date>();
        //@Jatin on 21st Nov 2019 commented due to refund record not created
        //Map<String, Set<String>> mapOfParentEnrolments = new Map<String, Set<String>>();
        for(Invoice__c invoiceObj : [SELECT Id, Name,Parent_Account__c,Total_Amount__c, Remarks__c,Invoice_Date__c,Parent_Account__r.Centre_Name__c,
        Center__r.Country__r.Tax_Rate__c,Credit_Memo_Amount__c,Balance_Amount__c,
                                            (SELECT Id, Enrolment__r.id,Enrolment__r.Package_Process_Type__c ,
                                            Enrolment__r.Effective_Date__c ,Package__c
                                            FROM Invoice_Line_Items__r) 
                                        FROM Invoice__c 
                                    WHERE Id IN : mapOfInvoiceId.keySet()]){
            listOfInv.add(invoiceObj);
            for(Invoice_Line_Item__c  lineItemObj : invoiceObj.Invoice_Line_Items__r){
                if(mapOfParentEnrolmentLastDate.containsKey(invoiceObj.Parent_Account__c) && 
                    mapOfParentEnrolmentLastDate.get(invoiceObj.Parent_Account__c) < lineItemObj.Enrolment__r.Effective_Date__c){
                    mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                }else if(String.isNotBlank(lineItemObj.Enrolment__c) && lineItemObj.Enrolment__r.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType 
                            && lineItemObj.Enrolment__r.Effective_Date__c != NULL){
                    mapOfParentEnrolmentLastDate.put(invoiceObj.Parent_Account__c, lineItemObj.Enrolment__r.Effective_Date__c);
                }
            }
        }
        Map<String, Boolean> mapOfActiveParent = new Map<String, Boolean>();
        mapOfActiveParent = BillingUtility.checkParentHasMultipleEnrolments(setOfParentIds, lastDate);
        Map<String,List<Credit_Memo__c>> mapOfParentCreditMemo = BillingUtility.getParentCreditMemo(setOfParentIds,lastDate);
        BillingUtility.adjustPendingCreditMemoDeposit(listOfInv, mapOfInvoiceId.keySet(), setOfParentIds, mapOfParentEnrolmentLastDate,isGetTotalAmount,mapOfParentCreditMemo,mapOfActiveParent);
    }
    
}